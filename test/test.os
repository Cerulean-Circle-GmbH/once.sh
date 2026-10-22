#!/usr/bin/env bash
#clear
#export PS4='\e[90m+${LINENO} in ${#BASH_SOURCE[@]}>${FUNCNAME[0]}:${BASH_SOURCE[@]##*/} \e[0m'
#set -x

TEST_CATEGORY=core

level=$1
if [ -z "$level" ]; then
  level=1
else 
  # remove the level parameter
  shift
fi

#echo "sourcing init"
source this
source test.suite

log.level $level
info.log "starting: ${BASH_SOURCE[@]##*/} <LOG_LEVEL=$1>"

completionArray=(once config list file ite)
source oo

test.case $level "os info runs" \
   os info
expect 0 "*" "os info"

source $OOSH_DIR/os

# ─────────────────────────────────────────────────────────────────────────────
# T-OS-CHECK-ENV-LINUX-MUSL : os.check.env's case "$OSTYPE" must match linux*
# (not narrowly linux-gnu*) so Alpine's linux-musl resolves to OOSH_OS=linux-gnu.
# Without this, downstream methods using os.check.env silently skip the
# alpine branch — symptom: "could not determine OS... please contribute".
# Bug history: pre-b7d500d the pattern was linux-gnu* and alpine fell through.
# ─────────────────────────────────────────────────────────────────────────────
test.case $level "T-OS-CHECK-ENV-LINUX-MUSL: os.check.env recognises linux-musl as a linux variant" \
  echo "(grep os for the case statement)"
OS_CHECK_ENV_BODY=$(declare -f os.check.env 2>/dev/null)
if printf "%s" "$OS_CHECK_ENV_BODY" | grep -qE 'linux\*\)' \
   && ! printf "%s" "$OS_CHECK_ENV_BODY" | grep -qE 'linux-gnu\*\)'; then
  expect.pass "os.check.env matches linux* (covers linux-gnu, linux-musl, future variants)"
else
  expect.fail "os.check.env still uses narrow linux-gnu* pattern — alpine's linux-musl will fall through to 'could not determine OS'"
fi


console.log "
Test: private.os.release.get
===================================================================="

# T-OS-RELEASE-GET: one value of an os-release file, quotes removed, the file never run
# Moved from odocker (private.odocker.os.release.get read only /etc/os-release
# and had no test). <file> lets the test use a fixture.
test.os.releaseGet() {
  local fx bad="" got; fx=$(test.suite.fixture.make osrelease)
  printf '%s\n' 'PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"' 'NAME="Debian GNU/Linux"' 'ID=debian' \
    "VERSION_CODENAME='bookworm'" 'HOME_URL="https://www.debian.org/"' 'QUOTED="a \"b\" \$c"' 'EVIL=$(touch '"$fx"'/ran)' > "$fx/os-release"
  got=$(private.os.release.get ID "$fx/os-release") || bad="$bad id-rc"
  [ "$got" = debian ] || bad="$bad id=[$got]"
  got=$(private.os.release.get PRETTY_NAME "$fx/os-release"); [ "$got" = "Debian GNU/Linux 12 (bookworm)" ] || bad="$bad double=[$got]"
  got=$(private.os.release.get VERSION_CODENAME "$fx/os-release"); [ "$got" = bookworm ] || bad="$bad single=[$got]"
  got=$(private.os.release.get QUOTED "$fx/os-release"); [ "$got" = 'a "b" $c' ] || bad="$bad escaped=[$got]"
  private.os.release.get EVIL "$fx/os-release" >/dev/null; [ -e "$fx/ran" ] && bad="$bad file-was-run"
  got=$(private.os.release.get NAME "$fx/os-release"); [ "$got" = "Debian GNU/Linux" ] || bad="$bad name=[$got]"
  got=$(private.os.release.get VERSION_ID "$fx/os-release"); [ "$?" = 1 ] && [ -z "$got" ] || bad="$bad missing-key=[$? $got]"
  got=$(private.os.release.get ID "$fx/none"); [ "$?" = 1 ] && [ -z "$got" ] || bad="$bad missing-file=[$got]"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "values with and without quotes; rc 1 for a missing key or file; the file is never run" || create.result 1 "os release:$bad"
  return $(result)
}
test.case $level "T-OS-RELEASE-GET: one value of an os-release file, quotes removed, the file never run" test.os.releaseGet
expect 0 "values with and without quotes; rc 1 for a missing key or file; the file is never run" \
  "the os-release reader lived in odocker, had no test and read only /etc/os-release"

# T-OS-SERVICE: os service.on / service.off — one way to switch a system service on (now and at boot) or off
# Linux: systemd, else OpenRC, else SysV `service` (odocker's engine start
# style); macOS: the system launch daemon <label>. su/setup called systemctl
# and launchctl raw (2026-10-14). Stand-ins on PATH log their arguments.
test.os.service() {
  local fx bad="" got; fx=$(test.suite.fixture.make osservice); mkdir -p "$fx/bin"
  local c; for c in systemctl rc-update rc-service service launchctl; do
    printf '%s\n' '#!/bin/sh' 'echo "${0##*/} $*" >> "$FX/log"' 'case " $T_FAIL " in *" ${0##*/} "*) exit 1 ;; esac' 'exit 0' > "$fx/bin/$c"
  done
  chmod +x "$fx/bin/"*
  test.os.service.run() { # <OSTYPE> <T_FAIL> <method> <name>
    : > "$fx/log"
    got=$(export FX="$fx" PATH="$fx/bin:$PATH" T_FAIL="$2"; OSTYPE="$1"; SUDO=""; "$3" "$4" >/dev/null 2>&1; echo "$?|$RESULT")
    echo "$got|$(tr '\n' ';' < "$fx/log")"
  }
  got=$(test.os.service.run linux-gnu "" os.service.on smbd)
  case "$got" in "0|smbd is on|systemctl enable --now smbd;") ;; *) bad="$bad systemd=[$got]" ;; esac
  got=$(test.os.service.run linux-gnu "systemctl" os.service.on smbd)
  case "$got" in "0|smbd is on|systemctl enable --now smbd;rc-update add smbd default;rc-service smbd start;") ;; *) bad="$bad openrc=[$got]" ;; esac
  got=$(test.os.service.run linux-gnu "systemctl rc-update rc-service" os.service.on smbd)
  case "$got" in "0|smbd is on|"*"service smbd start;") ;; *) bad="$bad sysv=[$got]" ;; esac
  got=$(test.os.service.run linux-gnu "systemctl rc-update rc-service service" os.service.on smbd)
  case "$got" in "1|smbd could not be switched on|"*) ;; *) bad="$bad none=[$got]" ;; esac
  got=$(test.os.service.run linux-gnu "" os.service.off smbd)
  case "$got" in "0|smbd is off|systemctl disable --now smbd;") ;; *) bad="$bad off=[$got]" ;; esac
  got=$(test.os.service.run darwin23 "" os.service.on com.apple.smbd)
  case "$got" in "0|com.apple.smbd is on|launchctl enable system/com.apple.smbd;launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.smbd.plist;") ;; *) bad="$bad mac=[$got]" ;; esac
  got=$(test.os.service.run darwin23 "" os.service.off com.apple.smbd)
  case "$got" in "0|com.apple.smbd is off|launchctl bootout system/com.apple.smbd;launchctl disable system/com.apple.smbd;") ;; *) bad="$bad mac-off=[$got]" ;; esac
  got=$(test.os.service.run linux-gnu "" os.service.on "")
  case "$got" in "1|"*"<service> required"*"|") ;; *) bad="$bad no-name=[$got]" ;; esac
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "systemd, OpenRC or SysV on Linux, launchd on macOS; rc 1 naming the service when none works" || create.result 1 "os service:$bad"
  return $(result)
}
test.case $level "T-OS-SERVICE: os service.on / service.off switch a system service on (now and at boot) or off" test.os.service
expect 0 "systemd, OpenRC or SysV on Linux, launchd on macOS; rc 1 naming the service when none works" \
  "su/setup called systemctl and launchctl raw; oosh had no service method"

# T-OS-SYSTEMD-IS: rc 0 only when systemd runs this computer (a container has none)
test.os.systemdIs() {
  local fx bad=""; fx=$(test.suite.fixture.make ossystemd); mkdir -p "$fx/bin" "$fx/run/systemd/system"
  printf '%s\n' '#!/bin/sh' 'exit 0' > "$fx/bin/systemctl"; chmod +x "$fx/bin/systemctl"
  ( PATH="$fx/bin:$PATH"; private.os.systemd.is "$fx" ) || bad="$bad running-rc1"
  ( PATH="$fx/bin:$PATH"; private.os.systemd.is "$fx/nowhere" ) && bad="$bad no-run-dir-rc0"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "systemd only when its run directory is there" || create.result 1 "systemd is:$bad"
  return $(result)
}
test.case $level "T-OS-SYSTEMD-IS: rc 0 only when systemd runs this computer" test.os.systemdIs
expect 0 "systemd only when its run directory is there" "su/setup had its own systemd check"

# T-OS-PLATFORM-MOVED: the platform tests live in the platform script; os keeps wrappers
# The boss (2026-10-22): no private.this.script.load. os.platform.* made the low
# script os load odocker and ossh; they moved up into platform (option 3, as
# config's repair moved to oo). `os platform.*` stay and run the command.
test.os.platformMoved() {
  local fx bad="" out code; fx=$(test.suite.fixture.make osplatformmoved)
  out=$( FX="$fx"
    platform() { echo "platform $*" >> "$FX/log"; }
    os.platform.test ubuntu_24_04 terminal notests; os.platform.test.all; os.platform.list; os.platform.parse.check almalinux_9 /x
    cat "$FX/log" | tr '\n' '|' )
  [ "$out" = "platform test ubuntu_24_04 terminal notests|platform test.all|platform list|platform parse.check almalinux_9 /x|" ] || bad="$bad wrappers=[$out]"
  # the code without comments and without os.usage (its example names ossh.service.status, as Marcel's)
  code=$(awk '/^os\.usage\(\)/{u=1} u&&/^}/{u=0;next} !u' "$OOSH_DIR/os" | command grep -v '^\s*#')
  case "$code" in *odocker*) bad="$bad os-knows-odocker" ;; esac
  case "$code" in *ossh*) bad="$bad os-knows-ossh" ;; esac
  command grep -qE '^private\.os\.platform' "$OOSH_DIR/os" && bad="$bad private-left"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "os platform.* run the platform command; os knows no odocker or ossh" || create.result 1 "platform moved:$bad"
  return $(result)
}
test.case $level "T-OS-PLATFORM-MOVED: os platform.* run the platform command; os knows no odocker or ossh" test.os.platformMoved
expect 0 "os platform.* run the platform command; os knows no odocker or ossh" \
  "os (the low script) loaded odocker and ossh for the platform tests"

### test.method

test.suite.save.results

