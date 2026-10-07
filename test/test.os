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

source os

# ─────────────────────────────────────────────────────────────────────────────
# Test: private.os.platform.load populates PLATFORM_* vars
# ─────────────────────────────────────────────────────────────────────────────
source $OOSH_DIR/os
private.os.platform.load
if [ -n "$PLATFORM_ubuntu_24_04" ]; then
  expect.pass "platform.load populates PLATFORM_ubuntu_24_04"
else
  expect.fail "platform.load did not populate PLATFORM_ubuntu_24_04"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Test: private.os.platform.names returns known platforms
# ─────────────────────────────────────────────────────────────────────────────
_NAMES=$(private.os.platform.names)
_FOUND_ALL=true
for _P in ubuntu_24_04 debian_12 almalinux_9 alpine_3_19 macos; do
  if ! echo "$_NAMES" | grep -q "$_P"; then
    expect.fail "platform.names missing: $_P"
    _FOUND_ALL=false
  fi
done
if [ "$_FOUND_ALL" = true ]; then
  expect.pass "platform.names includes all must-pass platforms"
fi
unset _NAMES _FOUND_ALL _P

# ─────────────────────────────────────────────────────────────────────────────
# Test: private.os.platform.parse extracts fields correctly
# ─────────────────────────────────────────────────────────────────────────────
private.os.platform.parse ubuntu_24_04
if [ "$PLATFORM_WORKSPACE" = "nakedUbuntu/24.04" ] && \
   [ "$PLATFORM_BASE_IMAGE" = "ubuntu:24.04" ] && \
   [ "$PLATFORM_PM" = "apt-get" ] && \
   [ "$PLATFORM_TIER" = "must-pass" ]; then
  expect.pass "parse ubuntu_24_04: all fields correct"
else
  expect.fail "parse ubuntu_24_04: ws=$PLATFORM_WORKSPACE img=$PLATFORM_BASE_IMAGE pm=$PLATFORM_PM tier=$PLATFORM_TIER"
fi

private.os.platform.parse alpine_3_19
if [ "$PLATFORM_WORKSPACE" = "nakedAlpine/3.19" ] && \
   [ "$PLATFORM_PM" = "apk" ] && \
   [ "$PLATFORM_TIER" = "must-pass" ]; then
  expect.pass "parse alpine_3_19: fields correct"
else
  expect.fail "parse alpine_3_19: ws=$PLATFORM_WORKSPACE pm=$PLATFORM_PM tier=$PLATFORM_TIER"
fi

private.os.platform.parse macos
if [ "$PLATFORM_WORKSPACE" = "native" ] && \
   [ "$PLATFORM_PM" = "brew" ] && \
   [ "$PLATFORM_TIER" = "must-pass" ]; then
  expect.pass "parse macos: fields correct"
else
  expect.fail "parse macos: ws=$PLATFORM_WORKSPACE pm=$PLATFORM_PM tier=$PLATFORM_TIER"
fi

private.os.platform.parse nonexistent_platform_xyz 2>/dev/null
if [ $? -eq 1 ]; then
  expect.pass "parse unknown platform returns error"
else
  expect.fail "parse unknown platform should return 1"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Test: private.os.platform.image.from.workspace matches odocker logic
# ─────────────────────────────────────────────────────────────────────────────
declare -A _WS_EXPECT=(
  ["nakedUbuntu/24.04"]="naked_ubuntu_24_04"
  ["nakedDebian/12"]="naked_debian_12"
  ["nakedAlma/9.sshd"]="naked_alma_9_sshd"
  ["nakedAlpine/3.19"]="naked_alpine_3_19"
)
for ws in "${!_WS_EXPECT[@]}"; do
  RESULT=$(private.os.platform.image.from.workspace "$ws")
  if [ "$RESULT" = "${_WS_EXPECT[$ws]}" ]; then
    expect.pass "image from workspace $ws → $RESULT"
  else
    expect.fail "image from workspace $ws: expected ${_WS_EXPECT[$ws]}, got: $RESULT"
  fi
done
unset _WS_EXPECT

# ─────────────────────────────────────────────────────────────────────────────
# Test: os platform.list runs without error
# ─────────────────────────────────────────────────────────────────────────────
test.case $level "os platform.list runs" \
  os platform.list
if [ "$RETURN_VALUE" -eq 0 ]; then
  expect.pass "os platform.list exits 0"
else
  expect.fail "os platform.list exits $RETURN_VALUE (expected 0)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Test: os platform.test without args returns error
# ─────────────────────────────────────────────────────────────────────────────
test.case $level "os platform.test requires parameter" \
  os platform.test
if [ "$RETURN_VALUE" -eq 1 ]; then
  expect.pass "os platform.test without args exits 1"
else
  expect.fail "os platform.test without args exits $RETURN_VALUE (expected 1)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Test: private.os.platform.test.ci function is defined
# ─────────────────────────────────────────────────────────────────────────────
if type private.os.platform.test.ci >/dev/null 2>&1; then
  expect.pass "private.os.platform.test.ci is defined"
else
  expect.fail "private.os.platform.test.ci should be defined"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Test: macos routes to CI (workspace=native), without triggering actual CI
# ─────────────────────────────────────────────────────────────────────────────
private.os.platform.parse macos
if [ "$PLATFORM_WORKSPACE" = "native" ]; then
  expect.pass "macos routes to CI (workspace=native, not Docker)"
else
  expect.fail "macos should have workspace=native, got: $PLATFORM_WORKSPACE"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Test: missing gh CLI triggers auto-install attempt
# ─────────────────────────────────────────────────────────────────────────────
_AUTO_OUTPUT=$(
  emptyDir=$(mktemp -d)
  PATH="$emptyDir"
  private.os.platform.test.ci macos 2>&1
  rmdir "$emptyDir" 2>/dev/null
)
if echo "$_AUTO_OUTPUT" | grep -q "oo: command not found"; then
  expect.pass "missing gh CLI triggers auto-install (oo cmd gh attempted)"
else
  expect.fail "missing gh CLI should trigger auto-install, got: $_AUTO_OUTPUT"
fi
unset _AUTO_OUTPUT

# ─────────────────────────────────────────────────────────────────────────────
# Test: completion function exists
# ─────────────────────────────────────────────────────────────────────────────
if type os.platform.test.completion.platform >/dev/null 2>&1; then
  expect.pass "os.platform.test.completion.platform is defined"
else
  expect.fail "os.platform.test.completion.platform should be defined"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Test: terminal completion function exists
# ─────────────────────────────────────────────────────────────────────────────
if type os.platform.test.completion.terminal >/dev/null 2>&1; then
  expect.pass "os.platform.test.completion.terminal is defined"
else
  expect.fail "os.platform.test.completion.terminal should be defined"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Test: terminal completion returns "terminal"
# ─────────────────────────────────────────────────────────────────────────────
_TERMINAL_COMP=$(os.platform.test.completion.terminal)
if echo "$_TERMINAL_COMP" | grep -q "terminal"; then
  expect.pass "terminal completion suggests 'terminal'"
else
  expect.fail "terminal completion should suggest 'terminal', got: $_TERMINAL_COMP"
fi
unset _TERMINAL_COMP

# ─────────────────────────────────────────────────────────────────────────────
# Test: os.platform.test signature includes terminal parameter
# ─────────────────────────────────────────────────────────────────────────────
_SIG=$(grep "^os.platform.test()" "$OOSH_DIR/os" 2>/dev/null)
if echo "$_SIG" | grep -q "terminal"; then
  expect.pass "os.platform.test signature includes terminal parameter"
else
  expect.fail "os.platform.test signature should include terminal parameter"
fi
unset _SIG

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


console.log "
Test: private.os.platform.container.up
===================================================================="

test.case - "T-OS-CONTAINER-UP-ARGS: container.up refuses a call without platform" \
   private.os.platform.container.up 
expect 1 "private.os.platform.container.up requires <platform> <image> <port>"


console.log "
Test: private.os.platform.users.install
===================================================================="

test.case - "T-OS-USERS-INSTALL-ARGS: users.install refuses a call without platform" \
   private.os.platform.users.install 
expect 1 "private.os.platform.users.install requires <platform>"


console.log "
Test: private.os.platform.gate.run
===================================================================="

test.case - "T-OS-GATE-RUN-ARGS: gate.run refuses a call without platform" \
   private.os.platform.gate.run 
expect 1 "private.os.platform.gate.run requires <platform> <user>"

# T-OS-PLATFORM-TEST-SPLIT: platform.test is orchestration over three reusable private methods
test.os.platformSplit() {
  local bad="" m
  for m in private.os.platform.container.up private.os.platform.users.install private.os.platform.gate.run; do
    type "$m" >/dev/null 2>&1 || bad="$bad missing:$m"
  done
  local body; body=$(declare -f os.platform.test)
  for m in container.up users.install gate.run; do
    printf '%s' "$body" | grep -q "private.os.platform.$m" || bad="$bad not-called:$m"
  done
  private.os.platform.gate.run p nobody >/dev/null 2>&1; [ $? = 1 ] || bad="$bad gate.run-accepts-unknown-user"
  os.platform.test no_such_platform_xyz >/dev/null 2>&1; [ $? = 1 ] || bad="$bad unknown-platform-not-refused"
  private.os.platform.branch.gate no-such-ref-xyz >/dev/null 2>&1; [ $? = 1 ] || bad="$bad unknown-branch-not-refused"
  type os.platform.test.completion.branch >/dev/null 2>&1 || bad="$bad no-branch-completion"
  [ -z "$bad" ] && create.result 0 "container.up, users.install and gate.run exist, platform.test calls them, an unknown platform and an unknown user are refused" || create.result 1 "split:$bad"
  return $(result)
}
test.case $level "T-OS-PLATFORM-TEST-SPLIT: platform.test is built from container.up, users.install and gate.run" test.os.platformSplit
expect 0 "container.up, users.install and gate.run exist, platform.test calls them, an unknown platform and an unknown user are refused" \
  "the 250-line platform.test could not be reused by a scenario test"


console.log "
Test: private.os.platform.branch.gate
===================================================================="

test.case - "T-OS-PLATFORM-TEST-BRANCH-ERA-ARGS: branch.gate refuses a call without branch" \
   private.os.platform.branch.gate 
expect 1 "private.os.platform.branch.gate requires <branch>"

# T-OS-PLATFORM-TEST-BRANCH-ERA: platform.test <branch> refuses a ref whose init/oosh is older than the
# mode-root installer contract (b8b90b82). The gate alone is exercised, on a fixture repo with two
# versions of init/oosh — no docker, no network, no real history.
test.os.branchEra() {
  local fx bad="" old new msg rc; fx=$(test.suite.fixture.make branchera)
  mkdir -p "$fx/repo/init" || return 1
  private.this.script.load ogit ogit.repo.init || return 1
  private.this.script.load ogit ogit.raw || return 1
  ogit.repo.init "$fx/repo" >/dev/null
  printf '%s\n' '#!/usr/bin/env -iS bash' '# ./oosh mode ssh <host>' > "$fx/repo/init/oosh"
  ogit.index.add all "$fx/repo" >/dev/null && ogit.commit.create old t@t t "$fx/repo" >/dev/null
  old=$(ogit.commit.log.show HEAD 1 %H "$fx/repo")
  printf '%s\n' '#!/usr/bin/env bash' "  [ \"\$1\" = \"root\" ] || die \"only 'mode root' is supported (got '\$1')\"" > "$fx/repo/init/oosh"
  ogit.index.add all "$fx/repo" >/dev/null && ogit.commit.create new t@t t "$fx/repo" >/dev/null
  new=$(ogit.commit.log.show HEAD 1 %H "$fx/repo")
  private.os.platform.branch.gate "$old" "$fx/repo" >/dev/null 2>&1; rc=$?; msg="$RESULT"
  [ $rc = 1 ] || bad="$bad old-rc=$rc"
  case "$msg" in *"$old"*"b8b90b82"*"mode ssh"*) ;; *) bad="$bad old-msg=[$msg]" ;; esac
  case "$msg" in *eraB*platform.heal.test*) ;; *) bad="$bad old-msg-lacks-eraB" ;; esac
  private.os.platform.branch.gate "$new" "$fx/repo" >/dev/null 2>&1; rc=$?; [ $rc = 0 ] || bad="$bad new-rc=$rc"
  private.os.platform.branch.gate HEAD "$fx/repo" >/dev/null 2>&1; rc=$?; [ $rc = 0 ] || bad="$bad head-rc=$rc"
  # ogit.raw: no ogit method creates a remote-tracking ref in a fixture without a remote
  ogit.raw "$fx/repo" update-ref refs/remotes/origin/feat "$new"
  private.os.platform.branch.gate feat "$fx/repo" >/dev/null 2>&1; rc=$?; [ $rc = 0 ] || bad="$bad remote-only-branch-rc=$rc"
  private.os.platform.branch.gate no/such-ref "$fx/repo" >/dev/null 2>&1; rc=$?; msg="$RESULT"
  [ $rc = 1 ] || bad="$bad missing-rc=$rc"
  case "$msg" in *no/such-ref*) ;; *) bad="$bad missing-msg=[$msg]" ;; esac
  private.os.platform.branch.gate --upload-pack=x "$fx/repo" >/dev/null 2>&1; [ $? = 1 ] || bad="$bad dash-ref-accepted"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "an init/oosh without the mode root contract and a missing ref are refused with rc 1, a ref with it passes" || create.result 1 "branch era:$bad"
  return $(result)
}
test.case $level "T-OS-PLATFORM-TEST-BRANCH-ERA: platform.test <branch> refuses refs older than the mode-root installer contract" test.os.branchEra
expect 0 "an init/oosh without the mode root contract and a missing ref are refused with rc 1, a ref with it passes" \
  "refs before b8b90b82 use mode ssh and cannot be driven by the current ossh install"

# T-OS-PLATFORM-TEST-STUBBED: the orchestration with every outside world stubbed (no docker, no ssh).
# Stubs record their calls in $OS_T_REC; ossh install records OSSH_INSTALL_BRANCH as it sees it.
test.os.stubs.set() {
  OS_T_REC=$(test.suite.fixture.make osrec)/rec; : > "$OS_T_REC"
  odocker()   { echo "odocker $*" >> "$OS_T_REC"; }
  docker()    { echo "docker $*" >> "$OS_T_REC"; return 0; }
  sshpass()   { echo "sshpass $*" >> "$OS_T_REC"; }
  ssh()       { echo "ssh $*" >> "$OS_T_REC"; }
  sleep()     { :; }
  ossh()      { echo "ossh $* branch=[${OSSH_INSTALL_BRANCH-unset}]" >> "$OS_T_REC"; }
  private.os.platform.sshd.reload() { echo "sshd.reload $*" >> "$OS_T_REC"; }
  # the live ControlMaster socket of a real os platform.test on this host must stay
  private.os.platform.socket.remove() { echo "socket.remove $*" >> "$OS_T_REC"; }
}
test.os.stubs.unset() {
  unset -f odocker docker sshpass ssh sleep ossh private.os.platform.sshd.reload private.os.platform.socket.remove
  source "$OOSH_DIR/os"
  rm -rf "$(dirname "$OS_T_REC")"; unset OS_T_REC
}
test.os.containerUp() {
  # isolated from the caller: own HOME, no inherited branch or control path
  local fx; fx=$(test.suite.fixture.make osup)
  local HOME="$fx" OSSH_CONTROL_PATH OSSH_INSTALL_BRANCH; unset OSSH_INSTALL_BRANCH OSSH_CONTROL_PATH
  local bad="" rec
  test.os.stubs.set
  private.os.platform.container.up p img 9022 >/dev/null 2>&1 || bad="$bad rc=$?"
  rec=$(cat "$OS_T_REC")
  case "$rec" in *"odocker reset img 9022"*) ;; *) bad="$bad reset-lacks-port" ;; esac
  case "$rec" in *"sshd.reload 9022"*) ;; *) bad="$bad sshd.reload-lacks-port" ;; esac
  case "$rec" in *"ossh install p test"*) ;; *) bad="$bad no-install-for-test" ;; esac
  case "$rec" in *"socket.remove 9022"*) ;; *) bad="$bad socket-not-removed-through-method" ;; esac
  test.os.stubs.unset
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "the ssh port given reaches odocker reset and sshd.reload, and test gets installed" || create.result 1 "container.up:$bad"
  return $(result)
}
test.case $level "T-OS-CONTAINER-UP-PORT: container.up hands the port it was given to odocker reset and sshd.reload" test.os.containerUp
expect 0 "the ssh port given reaches odocker reset and sshd.reload, and test gets installed" \
  "container.up used an undefined \$port: sshd.reload did nothing"

# T-OS-PLATFORM-TEST-BRANCH-ENV gates HEAD of the REAL repo ($OOSH_DIR): its init/oosh must carry the mode root contract.
test.os.platformTestBranch() {
  # isolated from the caller: own HOME, no inherited branch or control path
  local fx; fx=$(test.suite.fixture.make osbranch)
  local HOME="$fx" OSSH_CONTROL_PATH OSSH_INSTALL_BRANCH; unset OSSH_INSTALL_BRANCH OSSH_CONTROL_PATH
  local bad="" rec rc
  test.os.stubs.set
  os.platform.test ubuntu_24_04 "" notests HEAD >/dev/null 2>&1; rc=$?
  rec=$(cat "$OS_T_REC")
  [ $rc = 0 ] || bad="$bad rc=$rc"
  case "$rec" in *"ossh install ubuntu_24_04 test"*) ;; *) bad="$bad no-install-test" ;; esac
  [ "$(printf '%s\n' "$rec" | grep '^ossh install' | grep -vc 'branch=\[HEAD\]')" = 0 ] || bad="$bad install-without-branch"
  [ "$(printf '%s\n' "$rec" | grep -c '^ossh install')" = 2 ] || bad="$bad installs=$(printf '%s\n' "$rec" | grep -c '^ossh install')"
  [ -z "${OSSH_INSTALL_BRANCH+x}" ] || bad="$bad branch-leaked-after"
  # empty placeholders must not swallow the later parameters: notests skips every gate run
  case "$rec" in *"test.suite gate"*) bad="$bad notests-ignored-gate-ran" ;; esac
  : > "$OS_T_REC"
  os.platform.test ubuntu_24_04 "" notests >/dev/null 2>&1
  [ "$(grep '^ossh install' "$OS_T_REC" | grep -vc 'branch=\[unset\]')" = 0 ] || bad="$bad branch-set-without-param"
  # a failing container.up ends platform.test with rc 1, whatever it returned; and no ossh install follows
  : > "$OS_T_REC"
  private.os.platform.container.up() { create.result 1 "stubbed failure"; return 99; }
  os.platform.test ubuntu_24_04 "" notests >/dev/null 2>&1; rc=$?
  [ $rc = 1 ] || bad="$bad containerup-fail-rc=$rc"
  grep -q '^ossh install' "$OS_T_REC" && bad="$bad install-after-fail"
  # branch on macos is refused, the CI is not started
  private.os.platform.test.ci() { echo "ci called" >> "$OS_T_REC"; }
  os.platform.test macos "" "" HEAD >/dev/null 2>&1; rc=$?
  [ $rc = 1 ] || bad="$bad macos-branch-rc=$rc"
  grep -q "ci called" "$OS_T_REC" && bad="$bad macos-ci-started"
  test.os.stubs.unset
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "OSSH_INSTALL_BRANCH is <branch> inside both ossh install calls and gone afterwards; empty placeholders keep notests; container.up failing gives rc 1; macos refuses a branch" || create.result 1 "platform.test stubbed:$bad"
  return $(result)
}
test.case $level "T-OS-PLATFORM-TEST-BRANCH-ENV: OSSH_INSTALL_BRANCH lives for the two ossh install calls only; an empty placeholder no longer swallows notests" test.os.platformTestBranch
expect 0 "OSSH_INSTALL_BRANCH is <branch> inside both ossh install calls and gone afterwards; empty placeholders keep notests; container.up failing gives rc 1; macos refuses a branch" \
  "os platform.test p \"\" notests used to run the tests: an empty argument was not shifted"

# the getter is silent by contract (consumed as $(...)): the test reads its output
test.os.gateLogGet() {
  local got bad=""
  got=$(private.os.platform.gate.log.get root ubuntu_24_04)
  [ "$got" = /tmp/oosh-platform-test-root-ubuntu_24_04.log ] || bad="$bad path=[$got]"
  private.os.platform.gate.log.get root >/dev/null 2>&1 && bad="$bad missing-platform-accepted"
  [ -z "$bad" ] && create.result 0 "/tmp/oosh-platform-test-root-ubuntu_24_04.log" || create.result 1 "gate.log.get:$bad"
  return $(result)
}
test.case $level "T-OS-GATE-LOG-GET: the gate log path of a user and platform" test.os.gateLogGet
expect 0 "/tmp/oosh-platform-test-root-ubuntu_24_04.log" "one getter for gate.run and platform.test"


console.log "
Test: private.os.platform.socket.remove
===================================================================="

test.os.socketRemove() {
  local s=/tmp/ossh-test@localhost:59999 bad=""
  : > "$s"
  private.os.platform.socket.remove 59999 || bad="$bad rc"
  [ -e "$s" ] && bad="$bad still-there"
  private.os.platform.socket.remove 59999 || bad="$bad missing-not-idempotent"
  private.os.platform.socket.remove >/dev/null 2>&1 && bad="$bad no-port-accepted"
  [ -z "$bad" ] && create.result 0 "removed" || create.result 1 "socket.remove:$bad"
  return $(result)
}
test.case $level "T-OS-SOCKET-REMOVE: the socket of a port is removed and a missing one is no error" test.os.socketRemove
expect 0 "removed" "the removal must be a stubbable method, tests must not touch a live socket"

### test.method

test.suite.save.results

