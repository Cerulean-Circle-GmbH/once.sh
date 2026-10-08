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

# T-OS-PLATFORM-TEST-SPLIT: platform.test is orchestration over three reusable private methods.
# With the three stubbed to record their arguments (and ossh, docker, the cleanup and the
# shared config repair silent), os platform.test calls container.up with the image and the port, then
# users.install, then gate.run for the four users in their order.
test.os.platformSplit() {
  local bad="" m rec fx
  for m in private.os.platform.container.up private.os.platform.users.install private.os.platform.gate.run; do
    type "$m" >/dev/null 2>&1 || bad="$bad missing:$m"
  done
  fx=$(test.suite.fixture.make ossplit)
  (
    HOME="$fx"; OS_T_REC="$fx/rec"; unset OSSH_INSTALL_BRANCH OSSH_CONTROL_PATH
    odocker() { :; }; docker() { :; }; ossh() { :; }; ssh() { :; }; sleep() { :; }
    private.os.platform.container.up()        { echo "container.up $*" >> "$OS_T_REC"; create.result 0 up; }
    private.os.platform.users.install()       { echo "users.install $*" >> "$OS_T_REC"; }
    private.os.platform.gate.run()            { echo "gate.run $*" >> "$OS_T_REC"; return 0; }
    private.os.platform.shared.config.repair() { :; }
    private.os.platform.cleanup()             { :; }
    os.platform.test ubuntu_24_04 >/dev/null 2>&1
    grep -E '^(container.up|users.install|gate.run) ' "$OS_T_REC" > "$fx/calls"
  )
  rec=$(tr '\n' '|' < "$fx/calls" 2>/dev/null)
  case "$rec" in
    "container.up ubuntu_24_04 "*" 8022|users.install ubuntu_24_04|gate.run ubuntu_24_04 test|gate.run ubuntu_24_04 root|gate.run ubuntu_24_04 oosh-user|gate.run ubuntu_24_04 bash-user|") ;;
    *) bad="$bad calls=[$rec]" ;;
  esac
  rm -rf "$fx"
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
  # ogit.raw: no ogit method creates a remote-tracking ref in a fixture without a remote
  ogit.raw "$fx/repo" update-ref refs/remotes/origin/oldb "$old"
  ogit.raw "$fx/repo" update-ref refs/remotes/origin/feat "$new"
  private.os.platform.branch.gate oldb "$fx/repo" >/dev/null 2>&1; rc=$?; msg="$RESULT"
  [ $rc = 1 ] || bad="$bad old-rc=$rc"
  case "$msg" in *oldb*"b8b90b82"*"mode ssh"*) ;; *) bad="$bad old-msg=[$msg]" ;; esac
  case "$msg" in *eraB*platform.heal.test*) ;; *) bad="$bad old-msg-lacks-eraB" ;; esac
  private.os.platform.branch.gate feat "$fx/repo" >/dev/null 2>&1; rc=$?; [ $rc = 0 ] || bad="$bad origin-branch-rc=$rc"
  # a sha is the scenario test's job (platform-test-<sha>): refused before anything starts
  private.os.platform.branch.gate "$new" "$fx/repo" >/dev/null 2>&1; rc=$?; msg="$RESULT"
  [ $rc = 1 ] || bad="$bad sha-rc=$rc"
  case "$msg" in *"platform.heal.test"*"platform-test-"*) ;; *) bad="$bad sha-msg=[$msg]" ;; esac
  # a branch that exists only locally is not what the container clones
  private.os.platform.branch.gate "$(ogit.branch.get "$fx/repo")" "$fx/repo" >/dev/null 2>&1; rc=$?
  [ $rc = 1 ] || bad="$bad local-only-rc=$rc"
  private.os.platform.branch.gate no/such-ref "$fx/repo" >/dev/null 2>&1; rc=$?; msg="$RESULT"
  [ $rc = 1 ] || bad="$bad missing-rc=$rc"
  case "$msg" in *no/such-ref*) ;; *) bad="$bad missing-msg=[$msg]" ;; esac
  private.os.platform.branch.gate --upload-pack=x "$fx/repo" >/dev/null 2>&1; [ $? = 1 ] || bad="$bad dash-ref-accepted"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "an old origin branch, a sha, a local-only and a missing branch are refused with rc 1, an origin branch with the mode root contract passes" || create.result 1 "branch era:$bad"
  return $(result)
}
test.case $level "T-OS-PLATFORM-TEST-BRANCH-ERA: platform.test <branch> refuses refs older than the mode-root installer contract" test.os.branchEra
expect 0 "an old origin branch, a sha, a local-only and a missing branch are refused with rc 1, an origin branch with the mode root contract passes" \
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

# T-OS-PLATFORM-TEST-BRANCH-ENV stubs the gate (T-OS-PLATFORM-TEST-BRANCH-ERA tests it on a fixture).
test.os.platformTestBranch() {
  # isolated from the caller: own HOME, no inherited branch or control path
  local fx; fx=$(test.suite.fixture.make osbranch)
  local HOME="$fx" OSSH_CONTROL_PATH OSSH_INSTALL_BRANCH; unset OSSH_INSTALL_BRANCH OSSH_CONTROL_PATH
  local bad="" rec rc
  test.os.stubs.set
  private.os.platform.branch.gate() { echo "gate $*" >> "$OS_T_REC"; return 0; }
  os.platform.test ubuntu_24_04 "" notests feat >/dev/null 2>&1; rc=$?
  rec=$(cat "$OS_T_REC")
  [ $rc = 0 ] || bad="$bad rc=$rc"
  case "$rec" in *"ossh install ubuntu_24_04 test"*) ;; *) bad="$bad no-install-test" ;; esac
  [ "$(printf '%s\n' "$rec" | grep '^ossh install' | grep -vc 'branch=\[feat\]')" = 0 ] || bad="$bad install-without-branch"
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
  os.platform.test macos "" "" feat >/dev/null 2>&1; rc=$?
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

console.log "
Test: os platform.heal.test — the breakages
===================================================================="

# T-OS-HEAL-BREAKAGE-NAMES: every breakage the scenario names has an arm of its own, the
# arms parse as POSIX sh, all expands to the full list in the order of application, and
# an unknown name is refused before anything starts. No container: the scripts are text.
test.os.healBreakageNames() {
  local bad="" names n script preamble list want
  names=$(private.os.platform.heal.breakage.names.get)
  for n in merge.conflict markers.committed dirty detached diverged eraB.config root.clone \
           foreign.symlink missing.branch devhome.missing boot.era no.bashrc worktree.layout \
           safe.directory.stale ssh.legacy state.30 launcher.missing user.clone; do
    printf '%s\n' "$names" | grep -qxF "$n" || bad="$bad not-named:$n"
  done
  [ "$(printf '%s\n' "$names" | wc -l | tr -d ' ')" = 18 ] || bad="$bad count=$(printf '%s\n' "$names" | wc -l)"
  # no breakage name starts with private.: the prefix is reserved for helpers (T-PRIVATE-CALLS-DEFINED)
  printf '%s\n' "$names" | grep -q '^private\.' && bad="$bad private-prefix"
  preamble=$(private.os.platform.heal.remote.preamble.get dev.heal) || bad="$bad no-preamble"
  for n in $names; do
    if ! script=$(private.os.platform.heal.breakage.script.get "$n" dev.heal); then bad="$bad no-arm:$n"; continue; fi
    # an arm of its own: more than the N line and the preamble, and it says what it did
    [ "${#script}" -gt $(( ${#preamble} + ${#n} + 40 )) ] || bad="$bad empty-arm:$n"
    case "$script" in *"N='$n'"*"say "*) ;; *) bad="$bad no-say:$n" ;; esac
    printf '%s\n' "$script" | sh -n 2>/dev/null || bad="$bad sh-n:$n"
    if command -v dash >/dev/null 2>&1; then printf '%s\n' "$script" | dash -n 2>/dev/null || bad="$bad dash-n:$n"; fi
  done
  # the arms reproduce the real shapes: era-B values of the user, a live T9 drop-in, a user in
  # the broken tree, the foreign index settled and left out of the sums
  script=$(private.os.platform.heal.breakage.script.get eraB.config dev.heal)
  case "$script" in *'s#/var/folders/sanitised/T/#/tmp/#'*'USER="test"'*) ;; *) bad="$bad eraB-tmpdir-user" ;; esac
  script=$(private.os.platform.heal.breakage.script.get boot.era dev.heal)
  case "$script" in *"s#@SYSTEM_PATH@#/etc/oosh#g"*) ;; *) bad="$bad boot-era-placeholder" ;; esac
  script=$(private.os.platform.heal.breakage.script.get detached dev.heal)
  case "$script" in *'ln -sfn "$D" "$u/oosh"'*) ;; *) bad="$bad nobody-in-the-broken-tree" ;; esac
  script=$(private.os.platform.heal.breakage.script.get foreign.symlink dev.heal)
  case "$script" in *"status --porcelain"*"foreign_sums >"*) ;; *) bad="$bad foreign-index-not-settled" ;; esac
  case "$script" in *"! -path '*/.git/index'"*) ;; *) bad="$bad foreign-index-in-sums" ;; esac
  private.os.platform.heal.breakage.script.get no.such.breakage dev.heal >/dev/null 2>&1 && bad="$bad unknown-has-arm"
  private.os.platform.heal.breakage.script.get dirty -x >/dev/null 2>&1 && bad="$bad dash-branch-accepted"
  # user.clone is the last name (it rebuilds <base>/<branch> and cannot stand with the other folder arms)
  [ "$(printf '%s\n' "$names" | tail -n 1)" = user.clone ] || bad="$bad user.clone-not-last"
  script=$(private.os.platform.heal.breakage.script.get user.clone dev.heal)
  case "$script" in *'as_user test git clone -q'*) ;; *) bad="$bad user.clone-not-cloned-by-test" ;; esac
  case "$script" in *"/opt/user.clone.heal.rec"*) ;; *) bad="$bad user.clone-no-record" ;; esac
  case "$script" in *'as_user test git config --global --add safe.directory "$src" '*'as_user test git config --global --add safe.directory "$src/.git" '*'as_user test git clone -q "$src" "$D"'*) ;; *) bad="$bad user.clone-source-not-trusted-in-test-config" ;; esac
  case "$script" in *'--unset-all safe.directory "^$src'*'--unset-all safe.directory "^$src/.git'*) ;; *) bad="$bad user.clone-trust-not-put-back" ;; esac
  case "$script" in *"as_user test git -c"*) bad="$bad user.clone-command-line-trust" ;; esac
  case "$script" in *'rm -rf "$D"'*'|| { rm -rf "$D"; fail'*) ;; *) bad="$bad user.clone-leaves-folder-on-failure" ;; esac
  # one transport and one move-aside, both of the preamble: no arm has its own
  case "$script" in *"as_test"*|*"runuser -u test"*|*"sudo -H -u test"*) bad="$bad user.clone-own-transport" ;; esac
  for n in eraB.config:'move_aside "$c" eraB' root.clone:'move_aside "$r/oosh" private-clone' foreign.symlink:'move_aside "$u/oosh" foreign'; do
    script=$(private.os.platform.heal.breakage.script.get "${n%%:*}" dev.heal)
    case "$script" in *"${n#*:}"*) ;; *) bad="$bad no-move-aside:${n%%:*}" ;; esac
    case "${script#*"$preamble"}" in *".before-"*) bad="$bad own-move-aside:${n%%:*}" ;; esac
  done
  # all is every name but user.clone: its folder is rebuilt, the other folder arms would break it again
  want=$(printf '%s\n' "$names" | grep -vxF user.clone | tr '\n' ' '); want="${want% }"
  private.os.platform.heal.breakage.list.get >/dev/null 2>&1; [ "$RESULT" = "$want" ] || bad="$bad default=[$RESULT]"
  private.os.platform.heal.breakage.list.get all >/dev/null 2>&1; [ "$RESULT" = "$want" ] || bad="$bad all=[$RESULT]"
  private.os.platform.heal.breakage.list.get detached eraB.config detached >/dev/null 2>&1
  [ "$RESULT" = "eraB.config detached" ] || bad="$bad order=[$RESULT]"
  private.os.platform.heal.breakage.list.get detached user.clone eraB.config >/dev/null 2>&1 && bad="$bad user.clone-with-detached-accepted"
  case "$RESULT" in *user.clone*detached*|*detached*user.clone*) ;; *) bad="$bad user.clone-conflict-unnamed=[$RESULT]" ;; esac
  private.os.platform.heal.breakage.list.get user.clone eraB.config >/dev/null 2>&1; [ "$RESULT" = "eraB.config user.clone" ] || bad="$bad user.clone-order=[$RESULT]"
  private.os.platform.heal.breakage.list.get eraB.config bogus >/dev/null 2>&1; [ $? = 1 ] || bad="$bad unknown-accepted"
  case "$RESULT" in *bogus*) ;; *) bad="$bad unknown-unnamed=[$RESULT]" ;; esac
  for n in '*' 'dirt?' 'state.[3]0' ''; do
    private.os.platform.heal.breakage.list.get "$n" >/dev/null 2>&1 && bad="$bad pattern-accepted:[$n]"
  done
  [ -z "$bad" ] && create.result 0 "18 breakages, each its own POSIX sh arm; all is every one but user.clone in the order of application; unknown names refused" || create.result 1 "breakage names:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-BREAKAGE-NAMES: every breakage maps to an arm, all expands to the full list, an unknown name is refused" test.os.healBreakageNames
expect 0 "18 breakages, each its own POSIX sh arm; all is every one but user.clone in the order of application; unknown names refused" \
  "the scenario test needs the real machines' shapes, each reproducible on its own"

# T-OS-HEAL-PRELUDE-HELPERS: the helpers every arm gets from the preamble, run under sh on a
# fixture. as_user <user> <cmd...>: runuser with the HOME of <user> from /etc/passwd where
# runuser exists, else sudo -H -u (the transport of private.os.platform.user.run, from inside a
# root script); stubs print the call. move_aside <path> <tag>: a link is removed, an entry is
# moved to <path>.before-<tag>, nothing there is left alone.
test.os.healPreludeHelpers() {
  local fx bad="" preamble out
  fx=$(test.suite.fixture.make healprelude)
  mkdir -p "$fx/bin"; ln -s "$(command -v awk)" "$fx/bin/awk"
  preamble=$(private.os.platform.heal.remote.preamble.get dev.heal) || bad="$bad no-preamble"
  out=$(printf '%s\n%s\n' "$preamble" 'runuser() { echo "runuser $*"; }; PATH="'"$fx/bin"'"; as_user root echo hi' | sh 2>&1)
  [ "$out" = "runuser -u root -- env HOME=$(awk -F: '$1 == "root" { print $6; exit }' /etc/passwd) echo hi" ] || bad="$bad runuser=[$out]"
  out=$(printf '%s\n%s\n' "$preamble" 'sudo() { echo "sudo $*"; }; PATH="'"$fx/bin"'"; as_user root echo hi' | sh 2>&1)
  [ "$out" = "sudo -H -u root echo hi" ] || bad="$bad sudo=[$out]"
  mkdir -p "$fx/d" "$fx/t"; : > "$fx/t/kept"; ln -s "$fx/t" "$fx/l"
  out=$(printf '%s\n%s\n' "$preamble" "move_aside '$fx/l' x && move_aside '$fx/d' x && move_aside '$fx/none' x && echo ok" | sh 2>&1)
  [ "$out" = ok ] || bad="$bad move-aside-rc=[$out]"
  [ -e "$fx/l" ] || [ -L "$fx/l" ] && bad="$bad link-left"
  [ -f "$fx/t/kept" ] || bad="$bad link-target-touched"
  [ -d "$fx/d.before-x" ] && [ ! -e "$fx/d" ] || bad="$bad entry-not-moved"
  [ -e "$fx/none.before-x" ] && bad="$bad nothing-moved"
  printf '%s\n' "$preamble" | sh -n 2>/dev/null || bad="$bad sh-n"
  if command -v dash >/dev/null 2>&1; then printf '%s\n' "$preamble" | dash -n 2>/dev/null || bad="$bad dash-n"; fi
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "as_user through runuser with the user's HOME, else sudo -H -u; move_aside removes a link and moves an entry to .before-<tag>" || create.result 1 "prelude helpers:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-PRELUDE-HELPERS: the arm prelude's as_user and move_aside, run under sh with stubs" test.os.healPreludeHelpers
expect 0 "as_user through runuser with the user's HOME, else sudo -H -u; move_aside removes a link and moves an entry to .before-<tag>" \
  "one transport and one move-aside for every breakage arm"

# T-OS-HEAL-FIXTURE-SCRIPT: a fixture folder or file travels as quoted here-documents and
# arrives byte for byte — $HOME, backticks and quotes in it are not expanded.
test.os.healFixtureScript() {
  local fx bad="" script
  fx=$(test.suite.fixture.make healfixture)
  script=$(private.os.platform.heal.fixture.script.get eraB.config "$fx/config") || bad="$bad folder-rc"
  ( cd "$fx" && printf '%s\n' "$script" | sh ) || bad="$bad folder-run"
  diff -r "$OOSH_DIR/test/fixtures/heal/eraB.config" "$fx/config" >/dev/null 2>&1 || bad="$bad folder-differs"
  script=$(private.os.platform.heal.fixture.script.get boot.era/bashrc '$t/bashrc') || bad="$bad file-rc"
  ( t="$fx"; export t; printf '%s\n' "$script" | sh ) || bad="$bad file-run"
  private.this.file.same "$OOSH_DIR/test/fixtures/heal/boot.era/bashrc" "$fx/bashrc" || bad="$bad file-differs"
  private.os.platform.heal.fixture.script.get no.such.fixture "$fx/x" >/dev/null && bad="$bad missing-fixture-accepted"
  private.os.platform.heal.fixture.script.get eraB.config >/dev/null && bad="$bad no-target-accepted"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "the eraB.config folder and the boot-era .bashrc arrive byte for byte" || create.result 1 "fixture script:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-FIXTURE-SCRIPT: a heal fixture travels inside the breakage script and arrives byte for byte" test.os.healFixtureScript
expect 0 "the eraB.config folder and the boot-era .bashrc arrive byte for byte" \
  "the breakage script is the one thing that reaches the container"

# T-OS-HEAL-BREAKAGE-APPLY: the arm runs as root through ossh exec, base64 in the command
# line (no quoting of the script, no stdin through the ossh command); an unknown breakage
# never reaches ossh.
test.os.healBreakageApply() {
  local fx; fx=$(test.suite.fixture.make healapply)
  local HOME="$fx" OSSH_INSTALL_BRANCH; unset OSSH_INSTALL_BRANCH
  local bad="" rec encoded want rc
  test.os.stubs.set
  private.os.platform.heal.breakage.apply p dirty dev.heal >/dev/null 2>&1; rc=$?
  [ "$rc" = 0 ] || bad="$bad rc=$rc"
  rec=$(grep '^ossh exec p ' "$OS_T_REC")
  case "$rec" in *"| base64 -d | sudo sh -s"*) ;; *) bad="$bad not-root-sh=[$rec]" ;; esac
  encoded=$(printf '%s\n' "$rec" | sed -n 's/^ossh exec p echo \([A-Za-z0-9+\/=]*\) | base64 -d | sudo sh -s.*/\1/p')
  want=$(private.os.platform.heal.breakage.script.get dirty dev.heal)
  [ -n "$encoded" ] && [ "$(printf '%s' "$encoded" | base64 -d)" = "$want" ] || bad="$bad script-differs"
  : > "$OS_T_REC"
  private.os.platform.heal.breakage.apply p no.such.breakage dev.heal >/dev/null 2>&1; rc=$?
  [ "$rc" = 1 ] || bad="$bad unknown-rc=$rc"
  [ -s "$OS_T_REC" ] && bad="$bad unknown-reached-ossh"
  private.os.platform.heal.breakage.apply p >/dev/null 2>&1; [ $? = 1 ] || bad="$bad no-name-accepted"
  private.os.platform.root.script.run p zsh 'true' >/dev/null 2>&1; [ $? = 1 ] || bad="$bad other-shell-accepted"
  test.os.stubs.unset
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "the arm reaches sudo sh -s byte for byte; an unknown breakage never reaches ossh" || create.result 1 "breakage apply:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-BREAKAGE-APPLY: a breakage runs as root in the container through ossh exec" test.os.healBreakageApply
expect 0 "the arm reaches sudo sh -s byte for byte; an unknown breakage never reaches ossh" \
  "the breakage must not depend on the oosh under test"

console.log "
Test: private.os.platform.ref.branch.ensure / drop
===================================================================="

# T-OS-REF-BRANCH: a branch on origin is used as it is; a sha travels as platform-test-<sha>
# (flat: the old install makes <base>/<branch> and OOSH_MODE from it),
# pushed at that commit, and is dropped afterwards; nothing else is ever deleted. A bare
# repository replaces GitHub (raw git on the fixture side, as test.ogit.fixture).
test.os.refBranch() {
  local fx bad="" w rc sha old
  fx=$(test.suite.fixture.make refbranch); w="$fx/work"
  local HOME="$fx/home" GIT_CONFIG_GLOBAL="$fx/home/.gitconfig"; mkdir -p "$HOME"; : > "$GIT_CONFIG_GLOBAL"; export HOME GIT_CONFIG_GLOBAL
  git init -q --bare -b dev "$fx/origin.git"
  git init -q -b dev "$w"; git -C "$w" remote add origin "$fx/origin.git"
  printf 'one\n' > "$w/file"; git -C "$w" add file; git -C "$w" -c user.email=t@t -c user.name=t commit -q -m one
  old=$(git -C "$w" rev-parse --short=7 HEAD)
  printf 'two\n' >> "$w/file"; git -C "$w" -c user.email=t@t -c user.name=t commit -q -am two
  git -C "$w" push -q -u origin dev
  # a branch on origin: itself, nothing pushed
  private.os.platform.ref.branch.ensure dev "$w" >/dev/null 2>&1; rc=$?
  [ "$rc" = 0 ] && [ "$RESULT" = dev ] || bad="$bad branch=[$rc $RESULT]"
  [ "$(git -C "$fx/origin.git" for-each-ref --format=x refs/heads | wc -l | tr -d ' ')" = 1 ] || bad="$bad branch-pushed-something"
  # a commit no origin branch holds is never pushed (a local-only sha must not reach GitHub)
  printf 'three\n' >> "$w/file"; git -C "$w" -c user.email=t@t -c user.name=t commit -q -am three
  private.os.platform.ref.branch.ensure "$(git -C "$w" rev-parse --short=7 HEAD)" "$w" >/dev/null 2>&1; [ $? = 1 ] || bad="$bad local-only-sha-accepted"
  [ "$(git -C "$fx/origin.git" for-each-ref --format=x refs/heads | wc -l | tr -d ' ')" = 1 ] || bad="$bad local-only-sha-pushed"
  # a sha: platform-test-<sha> on origin at that commit, cached as origin/platform-test-<sha>
  private.os.platform.ref.branch.ensure "$old" "$w" >/dev/null 2>&1; rc=$?
  [ "$rc" = 0 ] && [ "$RESULT" = "platform-test-$old" ] || bad="$bad sha=[$rc $RESULT]"
  sha=$(git -C "$fx/origin.git" rev-parse -q --verify "refs/heads/platform-test-$old")
  [ -n "$sha" ] && [ "$sha" = "$(git -C "$w" rev-parse "$old")" ] || bad="$bad not-at-sha=[$sha]"
  git -C "$w" rev-parse -q --verify "refs/remotes/origin/platform-test-$old" >/dev/null || bad="$bad not-cached"
  git -C "$w" rev-parse -q --verify "refs/heads/platform-test-$old" >/dev/null && bad="$bad local-branch-made"
  # again: the same branch, rc 0
  private.os.platform.ref.branch.ensure "$old" "$w" >/dev/null 2>&1; [ $? = 0 ] || bad="$bad again-rc"
  # neither a branch nor a commit; a leading dash
  private.os.platform.ref.branch.ensure no-such-ref "$w" >/dev/null 2>&1; [ $? = 1 ] || bad="$bad unknown-accepted"
  private.os.platform.ref.branch.ensure deadbeefdeadbeef "$w" >/dev/null 2>&1; [ $? = 1 ] || bad="$bad unknown-sha-accepted"
  private.os.platform.ref.branch.ensure --all "$w" >/dev/null 2>&1; [ $? = 1 ] || bad="$bad dash-accepted"
  # drop: only platform-test-*; dev and a slashed name stay; a same-named tag does not make the delete ambiguous
  private.os.platform.ref.branch.drop "platform-test/$old" "$w" >/dev/null 2>&1; [ $? = 0 ] || bad="$bad slashed-not-left-alone"
  git -C "$w" tag "platform-test-$old" "$old"; git -C "$w" push -q origin "refs/tags/platform-test-$old"
  private.os.platform.ref.branch.drop dev "$w" >/dev/null 2>&1; rc=$?
  [ "$rc" = 0 ] && git -C "$fx/origin.git" rev-parse -q --verify refs/heads/dev >/dev/null || bad="$bad dev-touched=[$rc]"
  private.os.platform.ref.branch.drop "platform-test-$old" "$w" >/dev/null 2>&1; [ $? = 0 ] || bad="$bad drop-rc=[$RESULT]"
  git -C "$fx/origin.git" rev-parse -q --verify "refs/heads/platform-test-$old" >/dev/null && bad="$bad not-dropped"
  # the delete names refs/heads/<branch>: the tag of the same name stays
  private.os.platform.ref.branch.drop "platform-test-$old" "$w" >/dev/null 2>&1
  git -C "$fx/origin.git" rev-parse -q --verify "refs/tags/platform-test-$old" >/dev/null || bad="$bad tag-deleted"
  private.os.platform.ref.branch.drop >/dev/null 2>&1; [ $? = 1 ] || bad="$bad drop-no-branch-accepted"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "a branch on origin as it is; a sha origin holds as platform-test-<sha> at that commit, dropped afterwards; a local-only sha refused; nothing else deleted" || create.result 1 "ref branch:$bad"
  return $(result)
}
test.case $level "T-OS-REF-BRANCH: a sha travels as the temporary branch platform-test-<sha>" test.os.refBranch
expect 0 "a branch on origin as it is; a sha origin holds as platform-test-<sha> at that commit, dropped afterwards; a local-only sha refused; nothing else deleted" \
  "the container clones a branch: git clone -b takes no sha"

console.log "
Test: os platform.heal.test — the heal run and its checks
===================================================================="

# T-OS-USER-RUN: one transport per user for any command — gate.run is that transport with
# test.suite gate 1; a command that would break out of the single quotes is refused.
test.os.userRun() {
  local fx; fx=$(test.suite.fixture.make userrun)
  local HOME="$fx" OSSH_INSTALL_BRANCH; unset OSSH_INSTALL_BRANCH
  local bad="" rec rc
  test.os.stubs.set
  private.os.platform.user.run p test "oo heal dev all" "$fx/t.log" >/dev/null 2>&1 || bad="$bad test-rc"
  private.os.platform.user.run p root "oo heal dev all" "$fx/r.log" >/dev/null 2>&1 || bad="$bad root-rc"
  private.os.platform.user.run p bash-user "test.suite run platform.shared.idempotence.invariant 1" "$fx/b.log" >/dev/null 2>&1 || bad="$bad bash-user-rc"
  rec=$(cat "$OS_T_REC")
  case "$rec" in *"ossh exec p oo heal dev all"*) ;; *) bad="$bad test-transport" ;; esac
  # each user in THEIR home: runuser keeps the caller's HOME — the gates of
  # oosh-user and bash-user wrote their fixtures' git trust into the
  # .gitconfig of test, and the second heal pruned it (second-heal=1)
  case "$rec" in *"ossh exec.tty p sudo -H bash -lc 'cd /root 2>/dev/null || cd /tmp; "*"oo heal dev all'"*) ;; *) bad="$bad root-transport" ;; esac
  case "$rec" in *"sudo runuser -u bash-user -- env HOME=\"\$(eval echo ~bash-user)\" bash -c"*"test.suite run platform.shared.idempotence.invariant 1'"*) ;; *) bad="$bad bash-user-transport" ;; esac
  case "$rec" in *"sudo -H -u bash-user bash -c"*) ;; *) bad="$bad bash-user-sudo-transport" ;; esac
  # nobody acts for the ssh login: sudo's SUDO_USER=test made ogit.folder.finish
  # in the gates' fixtures trust them in the .gitconfig of test
  # (root, runuser and the sudo -H -u fallback: three lines)
  [ "$(grep -c "cd /tmp; unset SUDO_USER SUDO_UID SUDO_GID SUDO_COMMAND; " "$OS_T_REC")" = 3 ] || bad="$bad sudo-user-kept"
  [ -f "$fx/t.log" ] && [ -f "$fx/r.log" ] && [ -f "$fx/b.log" ] || bad="$bad no-logs"
  private.os.platform.user.run p root "echo 'x'" "$fx/q.log" >/dev/null 2>&1; [ $? = 1 ] || bad="$bad quote-accepted"
  private.os.platform.user.run p nobody "true" "$fx/n.log" >/dev/null 2>&1; [ $? = 1 ] || bad="$bad unknown-user-accepted"
  private.os.platform.user.run p root "true" >/dev/null 2>&1; [ $? = 1 ] || bad="$bad no-log-accepted"
  # gate.run: test.suite gate 1 through user.run, into the default or the given log
  : > "$OS_T_REC"
  private.os.platform.user.run() { echo "user.run $*" >> "$OS_T_REC"; return 0; }
  private.os.platform.gate.run p oosh-user >/dev/null 2>&1
  private.os.platform.gate.run p root "$fx/g.log" >/dev/null 2>&1
  grep -qxF "user.run p oosh-user test.suite gate 1 $(private.os.platform.gate.log.get oosh-user p)" "$OS_T_REC" || bad="$bad gate-default-log"
  grep -qxF "user.run p root test.suite gate 1 $fx/g.log" "$OS_T_REC" || bad="$bad gate-given-log"
  test.os.stubs.unset
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "test through ossh exec, root through sudo bash -lc, the others through runuser; gate.run is user.run with test.suite gate 1" || create.result 1 "user.run:$bad"
  return $(result)
}
test.case $level "T-OS-USER-RUN: any command as test, root, oosh-user or bash-user, the transport of the gate" test.os.userRun
expect 0 "test through ossh exec, root through sudo bash -lc, the others through runuser; gate.run is user.run with test.suite gate 1" \
  "the heal test runs the idempotence invariant and oo heal through the gate's transport"

# the getter is silent by contract (consumed as $(...)): the test reads its output
test.os.healLogGet() {
  local got bad=""
  got=$(OOSH_HEAL_TEST_LOGS= TMPDIR=/t private.os.platform.heal.log.get second-heal ubuntu_24_04)
  [ "$got" = /t/oosh-heal-test-second-heal-ubuntu_24_04.log ] || bad="$bad path=[$got]"
  # one folder per run (private.this.temp.dir.get oosh-heal-test): the steps' logs are in it
  got=$(OOSH_HEAL_TEST_LOGS=/run/one TMPDIR=/t private.os.platform.heal.log.get expect ubuntu_24_04)
  [ "$got" = /run/one/oosh-heal-test-expect-ubuntu_24_04.log ] || bad="$bad run-folder=[$got]"
  private.os.platform.heal.log.get root >/dev/null 2>&1 && bad="$bad missing-platform-accepted"
  private.os.platform.heal.log.get '../x' p >/dev/null 2>&1 && bad="$bad slash-accepted"
  [ -z "$bad" ] && create.result 0 "the log of a step is in the folder of the run, else in TMPDIR" || create.result 1 "heal.log.get:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-LOG-GET: the log of a step of the heal test" test.os.healLogGet
expect 0 "the log of a step is in the folder of the run, else in TMPDIR" "one getter for the logs of os platform.heal.test"

# T-OS-HEAL-REMOTE-SCRIPTS: the snapshot (bash, the invariant's helpers) and the foreign
# check (sh) run as root; the snapshot keeps only what follows its begin line, without \r.
test.os.healRemoteScripts() {
  local fx; fx=$(test.suite.fixture.make healremote)
  local HOME="$fx" OSSH_INSTALL_BRANCH; unset OSSH_INSTALL_BRANCH
  local bad="" rec encoded got
  test.os.stubs.set
  ossh() { echo "ossh $*" >> "$OS_T_REC"; printf 'motd noise\nOOSH_HEAL_SNAPSHOT_BEGIN\r\n/a\t1/2\t3 4\r\n'; }
  got=$(private.os.platform.heal.snapshot.get p dev.heal)
  [ "$got" = "$(printf '/a\t1/2\t3 4')" ] || bad="$bad snapshot=[$got]"
  rec=$(grep '^ossh exec p ' "$OS_T_REC" | tail -1)
  case "$rec" in *"| base64 -d | sudo bash -s"*) ;; *) bad="$bad snapshot-not-root-bash" ;; esac
  encoded=$(printf '%s\n' "$rec" | sed -n 's/^ossh exec p echo \([A-Za-z0-9+\/=]*\) | base64 -d.*/\1/p')
  got=$(printf '%s' "$encoded" | base64 -d)
  printf '%s\n' "$got" | bash -n 2>/dev/null || bad="$bad snapshot-bash-n"
  case "$got" in *"TEST_PLATFORM_IDEMPOTENCE_HELPERS_ONLY=1"*"test.platform.shared.idempotence.snapshot"*) ;; *) bad="$bad snapshot-not-the-invariant-helper" ;; esac
  private.os.platform.heal.snapshot.get p >/dev/null 2>&1 && bad="$bad snapshot-no-branch-accepted"
  : > "$OS_T_REC"
  ossh() { echo "ossh $*" >> "$OS_T_REC"; }
  private.os.platform.heal.check p foreign >/dev/null 2>&1 || bad="$bad foreign-rc"
  rec=$(grep '^ossh exec p ' "$OS_T_REC" | tail -1)
  case "$rec" in *"| base64 -d | sudo sh -s"*) ;; *) bad="$bad foreign-not-root-sh" ;; esac
  encoded=$(printf '%s\n' "$rec" | sed -n 's/^ossh exec p echo \([A-Za-z0-9+\/=]*\) | base64 -d.*/\1/p')
  got=$(printf '%s' "$encoded" | base64 -d)
  printf '%s\n' "$got" | sh -n 2>/dev/null || bad="$bad foreign-sh-n"
  case "$got" in *"/opt/foreign.heal.sums"*"-newer /opt/foreign.heal.marker"*) ;; *) bad="$bad foreign-not-sums-and-marker" ;; esac
  case "$got" in *"-newer /opt/foreign.heal.marker ! -path '*/.git/index' ! -path '*/.git'"*) ;; *) bad="$bad foreign-newer-counts-git-cache" ;; esac
  private.os.platform.heal.check >/dev/null 2>&1 && bad="$bad check-no-platform-accepted"
  private.os.platform.heal.check p >/dev/null 2>&1 && bad="$bad check-no-name-accepted"
  # one runner for every check: the user.clone check is its script getter's text, as root in sh
  : > "$OS_T_REC"
  private.os.platform.heal.check p user.clone dev.heal >/dev/null 2>&1 || bad="$bad user-clone-rc"
  case "$RESULT" in "user.clone check on p: rc 0") ;; *) bad="$bad user-clone-result=[$RESULT]" ;; esac
  rec=$(grep '^ossh exec p ' "$OS_T_REC" | tail -1)
  case "$rec" in *"| base64 -d | sudo sh -s"*) ;; *) bad="$bad user-clone-not-root-sh" ;; esac
  encoded=$(printf '%s\n' "$rec" | sed -n 's/^ossh exec p echo \([A-Za-z0-9+\/=]*\) | base64 -d.*/\1/p')
  [ "$(printf '%s' "$encoded" | base64 -d)" = "$(private.os.platform.heal.user.clone.check.script.get dev.heal)" ] || bad="$bad user-clone-not-its-getter"
  # and so is the expect check: its text, as root in sh, with the branch and the breakages that ran
  : > "$OS_T_REC"
  private.os.platform.heal.check p expect dev.heal dirty detached >/dev/null 2>&1 || bad="$bad expect-rc"
  case "$RESULT" in "expect check on p: rc 0") ;; *) bad="$bad expect-result=[$RESULT]" ;; esac
  rec=$(grep '^ossh exec p ' "$OS_T_REC" | tail -1)
  case "$rec" in *"| base64 -d | sudo sh -s"*) ;; *) bad="$bad expect-not-root-sh" ;; esac
  encoded=$(printf '%s\n' "$rec" | sed -n 's/^ossh exec p echo \([A-Za-z0-9+\/=]*\) | base64 -d.*/\1/p')
  [ "$(printf '%s' "$encoded" | base64 -d)" = "$(private.os.platform.heal.expect.check.script.get dev.heal dirty detached)" ] || bad="$bad expect-not-its-getter"
  # an unknown check, a bad name or a bad argument of the getter never reaches ossh
  : > "$OS_T_REC"
  private.os.platform.heal.check p no.such >/dev/null 2>&1 && bad="$bad unknown-check-accepted"
  private.os.platform.heal.check p 'user.clone;x' >/dev/null 2>&1 && bad="$bad bad-name-accepted"
  private.os.platform.heal.check p user.clone -x >/dev/null 2>&1 && bad="$bad bad-branch-accepted"
  grep -q '^ossh ' "$OS_T_REC" && bad="$bad refused-check-reached-ossh"
  test.os.stubs.unset
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "snapshot as root in bash with the invariant's helper, noise and \\r dropped; foreign check as root in sh against the recorded sums and marker" || create.result 1 "remote scripts:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-REMOTE-SCRIPTS: the snapshot and the foreign check run as root in the container" test.os.healRemoteScripts
expect 0 "snapshot as root in bash with the invariant's helper, noise and \\r dropped; foreign check as root in sh against the recorded sums and marker" \
  "the second heal and the foreign tree are judged inside the container"

# T-OS-HEAL-SECOND-RUN: the second heal passes only with rc 0 AND the same snapshot before
# and after; every difference is named.
test.os.healSecondRun() {
  local fx; fx=$(test.suite.fixture.make healsecond)
  local HOME="$fx" OSSH_INSTALL_BRANCH; unset OSSH_INSTALL_BRANCH
  local bad="" rc
  test.os.stubs.set
  OS_T_SNAP_N=0; OS_T_HEAL_RC=0; OS_T_SNAP_AFTER="/b	1/1	1 1
/s/sharedConfig/log.env	7/7	1 1"
  private.os.platform.heal.snapshot.get() {
    OS_T_SNAP_N=$((OS_T_SNAP_N + 1)); echo "snapshot $*" >> "$OS_T_REC"
    if [ $((OS_T_SNAP_N % 2)) = 1 ]; then printf '/b\t1/1\t1 1\n/s/sharedConfig/log.env\t7/7\t1 1\n'; else printf '%s\n' "$OS_T_SNAP_AFTER"; fi
  }
  private.os.platform.user.run() { echo "user.run $*" >> "$OS_T_REC"; return "$OS_T_HEAL_RC"; }
  private.os.platform.heal.second.run p dev.heal >/dev/null 2>&1; rc=$?
  [ "$rc" = 0 ] || bad="$bad same-rc=$rc [$RESULT]"
  # from the tree that carries the heal — root's ~/oosh may be the installed
  # older branch, which has no oo heal (rc 127 in the first container gate)
  [ "$(sed -n 2p "$OS_T_REC")" = "user.run p root $(private.os.platform.heal.second.command.get dev.heal) $(private.os.platform.heal.log.get second-heal p)" ] || bad="$bad not-heal-all-as-root-from-the-branch=[$(sed -n 2p "$OS_T_REC")]"
  [ "$(sed -n 1p "$OS_T_REC")" = "snapshot p dev.heal" ] && [ "$(sed -n 3p "$OS_T_REC")" = "snapshot p dev.heal" ] || bad="$bad not-snapshot-heal-snapshot"
  OS_T_SNAP_AFTER="/b	9/9	1 1
/s/sharedConfig/log.env	7/7	1 1"
  private.os.platform.heal.second.run p dev.heal >/dev/null 2>&1; rc=$?
  [ "$rc" = 1 ] || bad="$bad changed-rc=$rc"
  case "$RESULT" in *"changed: /b"*) ;; *) bad="$bad changed-unnamed=[$RESULT]" ;; esac
  # a same-content rewrite of a shared env file is accepted as the idempotence invariant accepts it: a WARNING
  OS_T_SNAP_AFTER="/b	1/1	1 1
/s/sharedConfig/log.env	7/7	2 2"
  private.os.platform.heal.second.run p dev.heal >/dev/null 2>&1; rc=$?
  [ "$rc" = 0 ] || bad="$bad rewritten-rc=$rc"
  case "$RESULT" in *WARNING*"rewritten: /s/sharedConfig/log.env"*) ;; *) bad="$bad rewritten-no-warning=[$RESULT]" ;; esac
  # any other rewrite, a folder cloned again among them, is a change: the heal must not do it twice
  OS_T_SNAP_AFTER="/b	1/1	2 2
/s/sharedConfig/log.env	7/7	1 1"
  private.os.platform.heal.second.run p dev.heal >/dev/null 2>&1; rc=$?
  [ "$rc" = 1 ] || bad="$bad recloned-folder-accepted-rc=$rc"
  case "$RESULT" in *"rewritten: /b"*) ;; *) bad="$bad recloned-folder-unnamed=[$RESULT]" ;; esac
  # result.env (result save, on every this.call) is left out in one place, the invariant's
  OS_T_SNAP_AFTER="/b	1/1	1 1
/s/sharedConfig/log.env	7/7	1 1
/s/result.env	5/5	9 9"
  private.os.platform.heal.second.run p dev.heal >/dev/null 2>&1; [ $? = 0 ] || bad="$bad result-env-counted"
  OS_T_SNAP_AFTER="/b	1/1	1 1
/s/sharedConfig/log.env	7/7	1 1
/c	1/1	1 1"
  private.os.platform.heal.second.run p dev.heal >/dev/null 2>&1; [ $? = 1 ] || bad="$bad added-accepted"
  OS_T_SNAP_AFTER="/b	1/1	1 1
/s/sharedConfig/log.env	7/7	1 1"; OS_T_HEAL_RC=1
  private.os.platform.heal.second.run p dev.heal >/dev/null 2>&1; [ $? = 1 ] || bad="$bad heal-rc1-accepted"
  [ -z "${TEST_SHARED_TIER_WRITER+x}" ] || bad="$bad invariant-globals-leaked"
  # the idempotence invariant's helpers are sourced once, in one subshell
  [ "$(declare -f private.os.platform.heal.second.run | grep -c '\. "$OOSH_DIR/test/test.platform.shared.idempotence.invariant"')" = 1 ] || bad="$bad invariant-sourced-more-than-once"
  rm -f "$(private.os.platform.heal.log.get second-heal p)"
  test.os.stubs.unset
  unset OS_T_SNAP_N OS_T_HEAL_RC OS_T_SNAP_AFTER
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "rc 0 and the same snapshot pass, a same-content rewrite with a WARNING; a change, an addition or rc 1 fail and are named" || create.result 1 "second heal:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-SECOND-RUN: a second oo heal must end rc 0 and change nothing but same-content rewrites" test.os.healSecondRun
expect 0 "rc 0 and the same snapshot pass, a same-content rewrite with a WARNING; a change, an addition or rc 1 fail and are named" \
  "the heal is idempotent or it is no heal"

# T-OS-HEAL-SECOND-RUN-REPORTS: a second heal whose rc 1 comes only from reports (legacy ssh.*
# folders, a zsh login — reported, never changed; owner decision 9) passes: its summary ends
# "rc 1: …; install state 99", which the heal writes only when every step and verify is green.
# Gate 3b (2026-10-07): ssh.legacy made every second heal rc 1 with nothing changed. A rc 1 with
# a step left (no "install state 99") still fails.
test.os.healSecondRunReports() {
  local fx; fx=$(test.suite.fixture.make healsecondrep)
  local HOME="$fx" OSSH_INSTALL_BRANCH; unset OSSH_INSTALL_BRANCH
  local bad="" rc
  test.os.stubs.set
  private.os.platform.heal.snapshot.get() { printf '/b\t1/1\t1 1\n'; }
  private.os.platform.user.run() { printf '%s\r\n' "$OS_T_HEAL_LINE" > "$4"; return 1; }
  OS_T_HEAL_LINE="rc 1: something is left for you — the lines marked left above; install state 99"
  private.os.platform.heal.second.run p dev.heal >/dev/null 2>&1; rc=$?
  [ "$rc" = 0 ] || bad="$bad reports-rc=$rc [$RESULT]"
  case "$RESULT" in *report*) ;; *) bad="$bad reports-unnamed=[$RESULT]" ;; esac
  OS_T_HEAL_LINE="rc 1: something is left for you — the lines marked left above"
  private.os.platform.heal.second.run p dev.heal >/dev/null 2>&1; rc=$?
  [ "$rc" = 1 ] || bad="$bad left-step-accepted"
  rm -f "$(private.os.platform.heal.log.get second-heal p)"
  test.os.stubs.unset
  unset OS_T_HEAL_LINE
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "rc 1 with install state 99 (reports only) passes; rc 1 with a step left fails" || create.result 1 "second heal reports:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-SECOND-RUN-REPORTS: a second heal left with reports only (install state 99) passes" test.os.healSecondRunReports
expect 0 "rc 1 with install state 99 (reports only) passes; rc 1 with a step left fails" \
  "gate 3b: legacy ssh.* folders are reported on every heal, so the second heal could never pass"

# T-OS-HEAL-PIPE-RUN: the pure pipe form through the public ossh heal.pipe with the local
# bundle (OOSH_HEAL_LOCAL=1 for that call only); its rc comes back, its ssh -tt \r is gone
# from the log; no private method of ossh is called from os.
test.os.healPipeRun() {
  local fx; fx=$(test.suite.fixture.make healpipe)
  local HOME="$fx" OSSH_INSTALL_BRANCH OOSH_HEAL_LOCAL; unset OSSH_INSTALL_BRANCH OOSH_HEAL_LOCAL
  local bad="" rec rc log
  test.os.stubs.set
  OS_T_PIPE_RC=0
  ossh() { echo "ossh $* local=[${OOSH_HEAL_LOCAL-unset}]" >> "$OS_T_REC"; printf 'healed\r\n'; return "$OS_T_PIPE_RC"; }
  log=$(private.os.platform.heal.log.get pipe p)
  private.os.platform.heal.pipe.run p dev.heal >/dev/null 2>&1; rc=$?
  [ "$rc" = 0 ] || bad="$bad rc=$rc"
  rec=$(cat "$OS_T_REC")
  [ "$rec" = "ossh heal.pipe p dev.heal local=[1]" ] || bad="$bad not-the-public-call=[$rec]"
  [ "$(cat "$log" 2>/dev/null)" = healed ] || bad="$bad log-not-clean"
  [ -z "${OOSH_HEAL_LOCAL+x}" ] || bad="$bad local-leaked"
  OS_T_PIPE_RC=1
  private.os.platform.heal.pipe.run p dev.heal >/dev/null 2>&1; [ $? = 1 ] || bad="$bad rc-not-returned"
  private.os.platform.heal.pipe.run p >/dev/null 2>&1; [ $? = 1 ] || bad="$bad no-branch-accepted"
  case "$(declare -f private.os.platform.heal.pipe.run)" in *private.ossh.*) bad="$bad private-ossh-call" ;; esac
  rm -f "$log"
  test.os.stubs.unset
  unset OS_T_PIPE_RC
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "OOSH_HEAL_LOCAL=1 ossh heal.pipe <platform> <branch>, its rc returned, its log without \\r" || create.result 1 "pipe form:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-PIPE-RUN: the pure pipe form of the heal runs once through ossh heal.pipe" test.os.healPipeRun
expect 0 "OOSH_HEAL_LOCAL=1 ossh heal.pipe <platform> <branch>, its rc returned, its log without \\r" \
  "the curl form reads the script from stdin; os calls no private method of ossh"

console.log "
Test: os.platform.heal.test
===================================================================="

test.case - "T-OS-HEAL-TEST-ARGS: platform.heal.test refuses a call without <platform> <oldRef>" \
   os.platform.heal.test ubuntu_24_04
expect 1 "Usage: os platform.heal.test <platform> <oldRef> <?breakages...:all> — words terminal and pipe may stand among the breakages"

# T-OS-HEAL-TEST-ORDER: the orchestration with every step stubbed (no docker, no ssh, no
# push): parse → ref.branch.ensure → era gate → container.up (OSSH_INSTALL_BRANCH) →
# users.install → breakages → heal → gates → idempotence → second heal → foreign →
# result → ref.branch.drop → cleanup; a failing container.up stops with rc 1 and still
# drops the temporary branch; so do a failing step after the heal and Ctrl-C; a dirty tree
# is refused before anything is pushed; the heal's rc 1 passes, rc 2 and a FAIL line of its
# verify fail.
test.os.healTest.stubs.set() {
  test.os.stubs.set
  OS_T_GATE=0
  private.os.platform.parse()            { echo "parse $*" >> "$OS_T_REC"; PLATFORM_WORKSPACE=nakedUbuntu/24.04; return 0; }
  private.os.platform.ref.branch.ensure() { echo "ensure $*" >> "$OS_T_REC"; create.result 0 "platform-test-$1"; }
  private.os.platform.branch.gate()      { echo "gate $*" >> "$OS_T_REC"; create.result "$OS_T_GATE" "gate"; return "$OS_T_GATE"; }
  private.os.platform.container.up()     { echo "container.up $* branch=[${OSSH_INSTALL_BRANCH-unset}]" >> "$OS_T_REC"; return 0; }
  private.os.platform.users.install()    { echo "users.install $* branch=[${OSSH_INSTALL_BRANCH-unset}]" >> "$OS_T_REC"; return 0; }
  private.os.platform.heal.breakage.apply() { echo "breakage $2 $3" >> "$OS_T_REC"; return 0; }
  private.os.platform.heal.pipe.run()    { echo "pipe $*" >> "$OS_T_REC"; return 0; }
  private.os.platform.gate.run()         { echo "gate.run $2" >> "$OS_T_REC"; return 0; }
  private.os.platform.shared.config.repair() { echo "repair" >> "$OS_T_REC"; }
  private.os.platform.user.run()         { echo "user.run $2 $3" >> "$OS_T_REC"; case "$3" in *" heal "*" all") return "${OS_T_USER_RUN_RC:-0}" ;; esac; return 0; }
  private.os.platform.heal.second.run()  { echo "second $*" >> "$OS_T_REC"; return 0; }
  private.os.platform.heal.check() {
    case "$2" in
      expect)     echo "expect $1 ${*:3}" >> "$OS_T_REC"; return "${OS_T_EXPECT_RC:-0}" ;;
      foreign)    echo "foreign $1" >> "$OS_T_REC"; return 0 ;;
      user.clone) echo "user-clone $1 $3" >> "$OS_T_REC"; return "${OS_T_USERCLONE_RC:-0}" ;;
    esac
    return 9
  }
  private.os.platform.ref.branch.drop()  { echo "drop $*" >> "$OS_T_REC"; return 0; }
  private.os.platform.cleanup()          { echo "cleanup $*" >> "$OS_T_REC"; }
  ogit.status.check()                    { return "${OS_T_DIRTY:-0}"; }
  ossh() {
    echo "ossh $* local=[${OOSH_HEAL_LOCAL-unset}]" >> "$OS_T_REC"
    [ "$1" = heal ] || return 0
    [ -n "$OS_T_HEAL_OUT" ] && printf '%s\n' "$OS_T_HEAL_OUT"
    return "${OS_T_HEAL_RC:-0}"
  }
}
test.os.healTestOrder() {
  local fx; fx=$(test.suite.fixture.make healorder)
  local HOME="$fx" OSSH_INSTALL_BRANCH OOSH_HEAL_LOCAL TMPDIR="$fx/tmp"; unset OSSH_INSTALL_BRANCH OOSH_HEAL_LOCAL
  mkdir -p "$TMPDIR"
  local bad="" rc out got want hb p=heal_test_stub n names traps second reports
  private.this.script.load ogit ogit.branch.get
  # HOME is the fixture: its global git config must trust this tree, or git
  # refuses a tree another user owns (the user test in a platform container,
  # the tree root's) and os platform.heal.test stops at "detached HEAD". git
  # checks the physical path: ~/oosh is a link.
  ogit.safeDirectory.add "$(private.this.path.canonical "$OOSH_DIR")" >/dev/null 2>&1
  hb=$(ogit.branch.get "$OOSH_DIR")
  names=$(private.os.platform.heal.breakage.names.get)
  second=$(private.os.platform.heal.second.command.get "$hb")
  reports="rc 1: something is left for you — the lines marked left above; install state 99"
  test.os.healTest.stubs.set
  traps=$(trap -p INT TERM HUP)
  out=$(os.platform.heal.test "$p" 26d15a4 2>&1); rc=$?
  [ "$rc" = 0 ] || bad="$bad rc=$rc"
  want="parse $p
ensure 26d15a4
gate platform-test-26d15a4
container.up $p naked_ubuntu_24_04 8022 branch=[platform-test-26d15a4]
users.install $p branch=[platform-test-26d15a4]"
  for n in $names; do
    [ "$n" = user.clone ] || want="$want
breakage $n $hb"
  done
  want="$want
ossh heal $p all $hb local=[1]
expect $p $hb $(printf '%s\n' "$names" | grep -vxF user.clone | tr '\n' ' ' | sed 's/ $//')
gate.run test
gate.run root
repair
gate.run oosh-user
gate.run bash-user
user.run root test.suite run platform.shared.idempotence.invariant 1
repair
user.run bash-user test.suite run platform.shared.idempotence.invariant 1
second $p $hb
foreign $p
breakage user.clone $hb
user.run root $second
user-clone $p $hb
drop platform-test-26d15a4
ossh connection.close $p local=[unset]
cleanup 8022"
  got=$(cat "$OS_T_REC")
  [ "$got" = "$want" ] || bad="$bad order:$(diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") | grep '^[<>]' | head -3 | tr '\n' '|')"
  case "$out" in *"PASS: heal $p 26d15a4 (heal=0 verify=0 not-checked=0 expect=0 test=0 root=0 oosh-user=0 bash-user=0 idempotence=0 second-heal=0 foreign=0 user-clone=0)"*) ;; *) bad="$bad no-pass-line=[$out]" ;; esac
  case "$out" in *breakages=*) bad="$bad breakages-field-back" ;; esac
  [ -z "${OSSH_INSTALL_BRANCH+x}" ] && [ -z "${OOSH_HEAL_LOCAL+x}" ] || bad="$bad env-leaked"
  # the logs of the run are one folder under the temp dir: gone on PASS, never written in the repository
  [ "$(ls -A "$TMPDIR" | grep -c '^oosh-heal-test\.')" = 0 ] || bad="$bad logs-left-on-pass=[$(ls -A "$TMPDIR")]"
  os.platform.heal.test "$p" 26d15a4 dirty >/dev/null 2>&1
  [ "$(trap -p INT TERM HUP)" = "$traps" ] || bad="$bad traps-not-restored"
  # a subset, pipe and terminal: only that breakage, the expect check, then the pipe form, no foreign check, no second pass, the container stays
  : > "$OS_T_REC"
  os.platform.heal.test "$p" 26d15a4 dirty pipe terminal >/dev/null 2>&1 || bad="$bad subset-rc"
  [ "$(grep -c '^breakage ' "$OS_T_REC")" = 1 ] && grep -qx "breakage dirty $hb" "$OS_T_REC" || bad="$bad subset-breakages"
  [ "$(grep -n '' "$OS_T_REC" | grep -A2 '^[0-9]*:ossh heal ' | sed -n 2p | cut -d: -f2-)" = "expect $p $hb dirty" ] || bad="$bad expect-not-after-heal"
  [ "$(grep -n '' "$OS_T_REC" | grep -A2 '^[0-9]*:ossh heal ' | sed -n 3p | cut -d: -f2-)" = "pipe $p $hb" ] || bad="$bad pipe-not-after-expect"
  grep -q '^foreign ' "$OS_T_REC" && bad="$bad foreign-without-breakage"
  grep -q '^user-clone ' "$OS_T_REC" && bad="$bad user-clone-without-breakage"
  grep -q '^cleanup ' "$OS_T_REC" && bad="$bad terminal-cleaned-up"
  grep -q '^drop platform-test-26d15a4' "$OS_T_REC" || bad="$bad terminal-no-drop"
  # user.clone typed: its check runs after the second heal, its rc is the user-clone field, a red check fails the run, and there is no second pass
  : > "$OS_T_REC"
  out=$(os.platform.heal.test "$p" 26d15a4 user.clone 2>&1) || bad="$bad user-clone-rc"
  [ "$(grep -n '' "$OS_T_REC" | grep -A1 '^[0-9]*:second ' | sed -n 2p | cut -d: -f2-)" = "user-clone $p $hb" ] || bad="$bad user-clone-not-after-second"
  [ "$(grep -c '^breakage user.clone' "$OS_T_REC")" = 1 ] || bad="$bad user-clone-second-pass-after-typed"
  case "$out" in *"foreign=skipped user-clone=0)"*) ;; *) bad="$bad user-clone-field" ;; esac
  OS_T_USERCLONE_RC=1
  out=$(os.platform.heal.test "$p" 26d15a4 user.clone 2>&1) && bad="$bad user-clone-red-passed"
  case "$out" in *"FAIL: heal $p 26d15a4 ("*"user-clone=1)"*) ;; *) bad="$bad user-clone-fail-line" ;; esac
  # the second pass of a full run: a red check of it fails the run, a heal that ends rc 2 too, a rc 1 with reports only does not
  : > "$OS_T_REC"
  out=$(os.platform.heal.test "$p" 26d15a4 2>&1) && bad="$bad second-pass-red-passed"
  case "$out" in *"FAIL: heal $p 26d15a4 ("*"user-clone=1)"*) ;; *) bad="$bad second-pass-fail-line" ;; esac
  unset OS_T_USERCLONE_RC
  OS_T_USER_RUN_RC=2
  out=$(os.platform.heal.test "$p" 26d15a4 2>&1) && bad="$bad second-pass-heal-rc2-passed"
  unset OS_T_USER_RUN_RC
  # a subset ends without the second pass
  : > "$OS_T_REC"
  os.platform.heal.test "$p" 26d15a4 dirty >/dev/null 2>&1 || bad="$bad subset-fail"
  grep -q '^breakage user.clone' "$OS_T_REC" && bad="$bad second-pass-on-a-subset"
  # a failed breakage ends the run before the heal: rc 1, no heal, the branch dropped, the container removed, the logs kept and named
  rm -rf "${TMPDIR:?}"/oosh-heal-test.*
  : > "$OS_T_REC"
  private.os.platform.heal.breakage.apply() { echo "breakage $2 $3" >> "$OS_T_REC"; [ "$2" != dirty ]; }
  out=$(os.platform.heal.test "$p" 26d15a4 dirty detached 2>&1); rc=$?
  [ "$rc" = 1 ] || bad="$bad breakage-fail-rc=$rc"
  grep -q '^ossh heal ' "$OS_T_REC" && bad="$bad heal-after-failed-breakage"
  grep -q '^breakage detached' "$OS_T_REC" && bad="$bad breakages-went-on"
  grep -q '^drop platform-test-26d15a4' "$OS_T_REC" && grep -q '^cleanup 8022' "$OS_T_REC" || bad="$bad breakage-fail-no-drop-or-cleanup"
  case "$out" in *"FAIL: heal $p 26d15a4 (breakage dirty failed"*) ;; *) bad="$bad breakage-fail-line=[$out]" ;; esac
  [ "$(ls -A "$TMPDIR" | grep -c '^oosh-heal-test\.')" = 1 ] || bad="$bad breakage-fail-logs-not-kept"
  case "$out" in *"$TMPDIR/oosh-heal-test."*) ;; *) bad="$bad breakage-fail-logs-not-named=[$out]" ;; esac
  rm -rf "${TMPDIR:?}"/oosh-heal-test.*
  private.os.platform.heal.breakage.apply() { echo "breakage $2 $3" >> "$OS_T_REC"; return 0; }
  # a failing container.up: rc 1, the temporary branch dropped, nothing installed, no logs folder left
  : > "$OS_T_REC"
  private.os.platform.container.up() { echo "container.up" >> "$OS_T_REC"; create.result 1 "stubbed"; return 99; }
  os.platform.heal.test "$p" 26d15a4 >/dev/null 2>&1; rc=$?
  [ "$rc" = 1 ] || bad="$bad up-fail-rc=$rc"
  grep -q '^users.install' "$OS_T_REC" && bad="$bad installed-after-fail"
  grep -q '^drop platform-test-26d15a4' "$OS_T_REC" || bad="$bad up-fail-no-drop"
  [ "$(ls -A "$TMPDIR" | grep -c '^oosh-heal-test\.')" = 0 ] || bad="$bad up-fail-logs-folder-left"
  private.os.platform.container.up()     { echo "container.up $* branch=[${OSSH_INSTALL_BRANCH-unset}]" >> "$OS_T_REC"; return 0; }
  # the era gate refuses: dropped, no container
  : > "$OS_T_REC"; OS_T_GATE=1
  os.platform.heal.test "$p" b492b2e >/dev/null 2>&1; [ $? = 1 ] || bad="$bad era-rc"
  grep -q '^container.up' "$OS_T_REC" && bad="$bad era-container"
  grep -q '^drop platform-test-b492b2e' "$OS_T_REC" || bad="$bad era-no-drop"
  [ "$(ls -A "$TMPDIR" | grep -c '^oosh-heal-test\.')" = 0 ] || bad="$bad era-logs-folder-left"
  # an unknown breakage: refused before anything starts
  : > "$OS_T_REC"; OS_T_GATE=0
  os.platform.heal.test "$p" 26d15a4 bogus >/dev/null 2>&1; [ $? = 1 ] || bad="$bad unknown-rc"
  [ -s "$OS_T_REC" ] && bad="$bad unknown-started"
  # the ref under test is the branch under test: the heal would be tested against itself
  : > "$OS_T_REC"
  out=$(os.platform.heal.test "$p" "$hb" 2>&1); rc=$?
  [ "$rc" = 1 ] || bad="$bad same-ref-rc=$rc"
  grep -qE '^(ensure|container\.up|users\.install)' "$OS_T_REC" && bad="$bad same-ref-started"
  case "$out" in *"older ref"*) ;; *) bad="$bad same-ref-unnamed=[$out]" ;; esac
  # the heal's rc 1 passes when it is reports only (install state 99), as in the second heal; any other rc 1, rc 2 fail
  OS_T_HEAL_RC=1; OS_T_HEAL_OUT=$(printf '%s\r' "$reports")
  out=$(os.platform.heal.test "$p" 26d15a4 dirty 2>&1) || bad="$bad heal-rc1-reports-failed"
  case "$out" in *"PASS: heal $p 26d15a4 (heal=1 verify=0 not-checked=0 expect=0 "*) ;; *) bad="$bad heal-rc1-line=[$out]" ;; esac
  OS_T_HEAL_OUT="rc 1: something is left for you — the lines marked left above"
  os.platform.heal.test "$p" 26d15a4 dirty >/dev/null 2>&1 && bad="$bad heal-rc1-step-left-passed"
  OS_T_HEAL_OUT=""
  os.platform.heal.test "$p" 26d15a4 dirty >/dev/null 2>&1 && bad="$bad heal-rc1-silent-passed"
  OS_T_HEAL_RC=2
  os.platform.heal.test "$p" 26d15a4 dirty >/dev/null 2>&1 && bad="$bad heal-rc2-passed"
  # a red verify of the heal fails the run; a NOT CHECKED fails it too unless the reason is the re-login of group dev
  OS_T_HEAL_RC=0; OS_T_HEAL_OUT=$(printf '  PASS layout root\r\n  FAIL boot root: run oo heal\r\n  NOT CHECKED oosh bash-user: no sudo\r')
  out=$(os.platform.heal.test "$p" 26d15a4 dirty 2>&1) && bad="$bad verify-fail-passed"
  case "$out" in *"FAIL: heal $p 26d15a4 (heal=0 verify=1 not-checked=1 "*) ;; *) bad="$bad verify-line=[$out]" ;; esac
  OS_T_HEAL_OUT=$(printf '  NOT CHECKED oosh bash-user: only root runs another user invariants\r')
  out=$(os.platform.heal.test "$p" 26d15a4 dirty 2>&1) && bad="$bad not-checked-passed"
  case "$out" in *"not-checked=1 "*) ;; *) bad="$bad not-checked-line=[$out]" ;; esac
  OS_T_HEAL_OUT=$(printf '  NOT CHECKED oosh bash-user: group dev takes effect after a re-login (rc 1)\r')
  out=$(os.platform.heal.test "$p" 26d15a4 dirty 2>&1) || bad="$bad relogin-failed"
  case "$out" in *"not-checked=0 "*) ;; *) bad="$bad relogin-counted=[$out]" ;; esac
  OS_T_HEAL_OUT=""
  # the expect check red fails the run, named in the line
  OS_T_EXPECT_RC=1
  out=$(os.platform.heal.test "$p" 26d15a4 dirty 2>&1) && bad="$bad expect-red-passed"
  case "$out" in *"FAIL: heal $p 26d15a4 ("*" expect=1 "*) ;; *) bad="$bad expect-fail-line=[$out]" ;; esac
  unset OS_T_EXPECT_RC
  # a failing step after the heal: FAIL, the branch dropped, the container removed, the logs kept and named
  : > "$OS_T_REC"
  private.os.platform.gate.run() { echo "gate.run $2" >> "$OS_T_REC"; [ "$2" != root ]; }
  out=$(os.platform.heal.test "$p" 26d15a4 dirty 2>&1) && bad="$bad gate-fail-passed"
  grep -q '^drop platform-test-26d15a4' "$OS_T_REC" && grep -q '^cleanup 8022' "$OS_T_REC" || bad="$bad gate-fail-no-drop-or-cleanup"
  case "$out" in *"logs: $TMPDIR/oosh-heal-test."*) ;; *) bad="$bad gate-fail-logs-not-named=[$out]" ;; esac
  rm -rf "${TMPDIR:?}"/oosh-heal-test.*
  private.os.platform.gate.run() { echo "gate.run $2" >> "$OS_T_REC"; return 0; }
  # a dirty tree: the committed branch would ship, not what is tested — refused before the push
  : > "$OS_T_REC"; OS_T_DIRTY=1
  os.platform.heal.test "$p" 26d15a4 dirty >/dev/null 2>&1; [ $? = 1 ] || bad="$bad dirty-accepted"
  grep -q '^ensure' "$OS_T_REC" && bad="$bad dirty-pushed"
  OS_T_DIRTY=0
  # Ctrl-C, SIGTERM and a hangup after the push: the trap drops the temporary branch and removes the container, the run ends 130
  for n in INT TERM HUP; do
    : > "$OS_T_REC"
    eval "private.os.platform.users.install() { echo \"users.install\" >> \"\$OS_T_REC\"; kill -$n \"\$BASHPID\"; }"
    ( os.platform.heal.test "$p" 26d15a4 dirty >/dev/null 2>&1 ); rc=$?
    [ "$rc" = 130 ] || bad="$bad $n-rc=$rc"
    grep -q '^drop platform-test-26d15a4' "$OS_T_REC" && grep -q '^cleanup 8022' "$OS_T_REC" || bad="$bad $n-no-drop-or-cleanup"
    grep -q '^breakage ' "$OS_T_REC" && bad="$bad $n-went-on"
  done
  rm -rf "${TMPDIR:?}"/oosh-heal-test.*
  test.os.stubs.unset
  unset -f ogit.status.check
  unset OS_T_HEAL_RC OS_T_HEAL_OUT OS_T_DIRTY
  unset OS_T_GATE
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "parse, ensure, gate, container.up, users.install, breakages, heal, expect, gates, idempotence, second heal, foreign, the user.clone second pass, drop, cleanup; a failing container.up still drops the branch" || create.result 1 "heal test order:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-TEST-ORDER: os platform.heal.test runs its steps in order and always drops its temporary branch" test.os.healTestOrder
expect 0 "parse, ensure, gate, container.up, users.install, breakages, heal, expect, gates, idempotence, second heal, foreign, the user.clone second pass, drop, cleanup; a failing container.up still drops the branch" \
  "the scenario test proves the heal before it touches a real machine"

# T-OS-HEAL-TEST-COMPLETION: platforms, remote branches, and the breakage words with all, terminal and pipe
test.os.healTestCompletion() {
  local bad="" got
  got=$(os.platform.heal.test.completion.platform); printf '%s\n' "$got" | grep -qx ubuntu_24_04 || bad="$bad platform"
  got=$(os.platform.heal.test.completion.breakages)
  for w in all terminal pipe eraB.config detached user.clone; do printf '%s\n' "$got" | grep -qxF "$w" || bad="$bad breakages:$w"; done
  type os.platform.heal.test.completion.oldRef >/dev/null 2>&1 || bad="$bad no-oldRef"
  [ -z "$bad" ] && create.result 0 "completion: platforms, remote branches, breakages" || create.result 1 "completion:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-TEST-COMPLETION: platform.heal.test completes its parameters with real candidates" test.os.healTestCompletion
expect 0 "completion: platforms, remote branches, breakages" "every public parameter completes"

# T-OS-HEAL-BREAKAGE-WORKTREE-TRACKS: the worktree.layout arm makes <base>/testing the way the old
# install did — a linked worktree of main at origin/testing, tracking it. Gate 3 (2026-10-07): the
# arm hung testing on main's HEAD with no upstream; ogit worktree.remove refused it ("testing tracks
# no upstream") and the layout invariant failed for every user. The arm runs on a fixture base: the
# one B= line of the preamble is replaced, and the run is refused unless that took.
test.os.healBreakageWorktreeTracks() {
  local fx bad="" script B out
  fx=$(test.suite.fixture.make healwtarm); B="$fx/Once.sh"; mkdir -p "$B"
  git init -q --bare -b main "$fx/origin.git"
  git init -q -b main "$B/main"; git -C "$B/main" remote add origin "$fx/origin.git"
  printf 'seed\n' > "$B/main/file"; git -C "$B/main" add file
  git -C "$B/main" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m seed
  git -C "$B/main" push -q -u origin main; git -C "$B/main" push -q origin main:testing
  # main moves on: its HEAD is not origin/testing any more
  printf 'more\n' >> "$B/main/file"
  git -C "$B/main" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -am more
  git -C "$B/main" push -q origin main
  script=$(private.os.platform.heal.breakage.script.get worktree.layout dev.heal | sed "s#^B=.*#B='$B'#")
  if [ "$(printf '%s\n' "$script" | grep -c '^B=')" = 1 ] && printf '%s\n' "$script" | grep -qxF "B='$B'"; then
    out=$(printf '%s\n' "$script" | sh 2>&1) || bad="$bad rc=[$out]"
    [ -f "$B/testing/.git" ] || bad="$bad not-a-worktree"
    [ "$(git -C "$B/testing" rev-parse --abbrev-ref '@{u}' 2>/dev/null)" = origin/testing ] || bad="$bad no-upstream"
    [ "$(git -C "$B/testing" rev-parse HEAD 2>/dev/null)" = "$(git -C "$fx/origin.git" rev-parse testing)" ] || bad="$bad not-at-origin-testing"
    out=$(printf '%s\n' "$script" | sh 2>&1)
    case "$out" in *already*) ;; *) bad="$bad second-run=[$out]" ;; esac
  else
    bad="$bad base-not-replaced"
  fi
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "testing a linked worktree at origin/testing, tracking it; a second run says already" || create.result 1 "worktree arm:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-BREAKAGE-WORKTREE-TRACKS: the worktree.layout arm makes testing a worktree tracking origin/testing, as the old install did" test.os.healBreakageWorktreeTracks
expect 0 "testing a linked worktree at origin/testing, tracking it; a second run says already" \
  "gate 3: a worktree without upstream is not the old layout, and the heal rightly refused it"

# T-OS-HEAL-USER-CLONE-CHECK: the check of the user.clone breakage, on fixture folders (no
# container). A healthy clone a user made must still be there after the heal: the same owner and
# the same HEAD as recorded, and no <base>.aside/<branch>.orig.* entry. The script is the check's
# own text with B and the record file pointed at the fixture.
test.os.healUserCloneCheck() {
  local fx bad="" B script me head out
  fx=$(test.suite.fixture.make healuserclone); B="$fx/Once.sh"
  me=$(id -un)
  git init -q -b dev.heal "$B/dev.heal"
  git -C "$B/dev.heal" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q --allow-empty -m seed
  head=$(git -C "$B/dev.heal" rev-parse HEAD)
  script=$(private.os.platform.heal.user.clone.check.script.get dev.heal | sed -e "s#^B=.*#B='$B'#" -e "s#^REC=.*#REC='$fx/rec'#")
  if [ "$(printf '%s\n' "$script" | grep -c '^B=')" != 1 ] || [ "$(printf '%s\n' "$script" | grep -c '^REC=')" != 1 ]; then
    bad="$bad base-or-record-not-replaced"
  else
    printf '%s\n' "$script" | sh -n 2>/dev/null || bad="$bad sh-n"
    # nothing recorded: red
    printf '%s\n' "$script" | sh >/dev/null 2>&1 && bad="$bad nothing-recorded-passed"
    # untouched: same owner, same HEAD, no aside entry
    printf '%s %s %s\n' "$head" "$me" "$(ls -di "$B/dev.heal" | awk '{print $1}')" > "$fx/rec"
    out=$(printf '%s\n' "$script" | sh 2>&1) || bad="$bad untouched-red=[$out]"
    # moved aside: an entry of the branch in <base>.aside
    mkdir -p "$B.aside/dev.heal.orig.20261008-120000"
    out=$(printf '%s\n' "$script" | sh 2>&1) && bad="$bad aside-passed"
    case "$out" in *dev.heal.orig.20261008-120000*) ;; *) bad="$bad aside-unnamed=[$out]" ;; esac
    rm -rf "$B.aside"
    # an entry of another branch is no entry of this one
    mkdir -p "$B.aside/other.orig.20261008-120000"
    printf '%s\n' "$script" | sh >/dev/null 2>&1 || bad="$bad other-aside-red"
    rm -rf "$B.aside"
    # the owner changed (the record names another owner than the folder has now)
    printf '%s %s %s\n' "$head" "nobody-heal-test" "1" > "$fx/rec"
    out=$(printf '%s\n' "$script" | sh 2>&1) && bad="$bad owner-changed-passed"
    case "$out" in *owner*) ;; *) bad="$bad owner-unnamed=[$out]" ;; esac
    # HEAD moved
    printf '%s %s %s\n' "0000000000000000000000000000000000000000" "$me" "1" > "$fx/rec"
    printf '%s\n' "$script" | sh >/dev/null 2>&1 && bad="$bad head-moved-passed"
    # the heal's fast-forward: the recorded HEAD is an ancestor of the new one — kept
    git -C "$B/dev.heal" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q --allow-empty -m ahead
    printf '%s %s %s\n' "$head" "$me" "1" > "$fx/rec"
    out=$(printf '%s\n' "$script" | sh 2>&1) || bad="$bad fast-forward-red=[$out]"
    case "$out" in *"fast-forward"*) ;; *) bad="$bad fast-forward-unsaid=[$out]" ;; esac
    # a rewritten history: the recorded HEAD is on a branch the new HEAD does not contain
    git -C "$B/dev.heal" -c user.email=t@t -c user.name=t -c commit.gpgsign=false checkout -q -b other "$head"
    git -C "$B/dev.heal" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q --allow-empty -m side
    printf '%s %s %s\n' "$(git -C "$B/dev.heal" rev-parse HEAD)" "$me" "1" > "$fx/rec"
    git -C "$B/dev.heal" checkout -q dev.heal
    printf '%s\n' "$script" | sh >/dev/null 2>&1 && bad="$bad divergent-passed"
    # the folder gone
    printf '%s %s %s\n' "$head" "$me" "1" > "$fx/rec"
    mv "$B/dev.heal" "$fx/gone"
    printf '%s\n' "$script" | sh >/dev/null 2>&1 && bad="$bad folder-gone-passed"
  fi
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "the kept clone passes; an aside entry of the branch, another owner, a divergent HEAD and a missing folder fail; a fast-forward passes" || create.result 1 "user.clone check:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-USER-CLONE-CHECK: the user.clone check fails on an aside entry or an owner change and passes on an untouched clone" test.os.healUserCloneCheck
expect 0 "the kept clone passes; an aside entry of the branch, another owner, a divergent HEAD and a missing folder fail; a fast-forward passes" \
  "bug of 2026-10-08: as root git's dubious ownership made the heal move a healthy user clone aside"

# T-IDEMPOTENCE-UNACCEPTED-GLOB: a rewrite of the same content is accepted only under the shared
# env files (the glob), never for a folder that was cloned again (new inode and mtime, same
# "content") nor for a state file; a content change is unaccepted whatever its path.
test.os.idempotenceUnacceptedGlob() {
  local fx bad="" out glob='/x/S/*.env|/x/h/.config/oosh/*.env'
  fx=$(test.suite.fixture.make idemglob)
  printf '/x/S/log.env\tabc\t1 100\n/x/S/oosh.env\tabd\t2 100\n/x/S/stateMachines/A.states.env\tdef\t3 100\n/x/h/.config/oosh/oosh.env\tg\t4 100\n/x/B/dev.heal\tpresent\t10 100\n/x/B/dev.heal/f\t1/1\t11 100\n' > "$fx/before"
  printf '/x/S/log.env\tabc\t1 200\n/x/S/oosh.env\tchanged\t2 200\n/x/S/stateMachines/A.states.env\tdef\t3 200\n/x/h/.config/oosh/oosh.env\tg\t4 200\n/x/B/dev.heal\tpresent\t20 200\n/x/B/dev.heal/f\t1/1\t21 200\n' > "$fx/after"
  out=$( TEST_PLATFORM_IDEMPOTENCE_HELPERS_ONLY=1
    . "$OOSH_DIR/test/test.platform.shared.idempotence.invariant" || exit 9
    test.platform.shared.idempotence.compare "$fx/before" "$fx/after" | test.platform.shared.idempotence.unaccepted rewritten "$glob" )
  case "$out" in *"rewritten: /x/B/dev.heal ("*) ;; *) bad="$bad recloned-folder-accepted=[$out]" ;; esac
  case "$out" in *"rewritten: /x/B/dev.heal/f ("*) ;; *) bad="$bad file-of-recloned-accepted" ;; esac
  case "$out" in *"rewritten: /x/S/stateMachines/A.states.env ("*) ;; *) bad="$bad state-file-accepted" ;; esac
  case "$out" in *"changed: /x/S/oosh.env ("*) ;; *) bad="$bad content-change-accepted" ;; esac
  case "$out" in *"rewritten: /x/S/log.env"*|*"rewritten: /x/h/.config/oosh/oosh.env"*) bad="$bad env-rewrite-unaccepted=[$out]" ;; esac
  [ "$(printf '%s\n' "$out" | grep -c .)" = 4 ] || bad="$bad count=$(printf '%s\n' "$out" | grep -c .)"
  # no glob: every rewrite is accepted (config save); a dash accepts nothing
  out=$( TEST_PLATFORM_IDEMPOTENCE_HELPERS_ONLY=1
    . "$OOSH_DIR/test/test.platform.shared.idempotence.invariant" || exit 9
    test.platform.shared.idempotence.compare "$fx/before" "$fx/after" | test.platform.shared.idempotence.unaccepted rewritten )
  [ "$(printf '%s\n' "$out" | grep -c .)" = 1 ] && case "$out" in "changed: /x/S/oosh.env ("*) ;; *) false ;; esac || bad="$bad no-glob=[$out]"
  out=$( TEST_PLATFORM_IDEMPOTENCE_HELPERS_ONLY=1
    . "$OOSH_DIR/test/test.platform.shared.idempotence.invariant" || exit 9
    test.platform.shared.idempotence.compare "$fx/before" "$fx/after" | test.platform.shared.idempotence.unaccepted - )
  [ "$(printf '%s\n' "$out" | grep -c .)" = 6 ] || bad="$bad dash-count=$(printf '%s\n' "$out" | grep -c .)"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "a same-content rewrite is accepted under the shared env files only; a re-cloned folder, a state file and a content change are unaccepted" || create.result 1 "unaccepted glob:$bad"
  return $(result)
}
test.case $level "T-IDEMPOTENCE-UNACCEPTED-GLOB: a rewrite is accepted only for the paths of the glob" test.os.idempotenceUnacceptedGlob
expect 0 "a same-content rewrite is accepted under the shared env files only; a re-cloned folder, a state file and a content change are unaccepted" \
  "E1: the second heal accepted every rewrite, a folder cloned again too"


# T-OS-HEAL-EXPECT-CHECK: the post-heal check of the scenario, as root in sh. Its text runs here on
# a fixture machine that is healed (a passwd of its own, a base, a sharedConfig, five homes, the
# ssh setup, the launcher, a clone of the branch, the aside entry of every folder breakage); the
# lines of the script naming the machine (passwd, B, S, DK, LAUNCHER, LAUNCHER2, BOOT, DROPIN) are
# pointed at the fixture, and the run is refused unless each replacement took. Then one thing at
# a time is broken and the check must name it.
test.os.healExpectFixture() { # <dir> # build the healed fixture machine under <dir>
  local fx="$1" url=git@github.com:Cerulean-Circle-GmbH/once.sh.git u d
  local B="$fx/base/Once.sh" S="$fx/sc" D="$fx/base/Once.sh/dev.heal"
  local g=(git -c user.email=t@t -c user.name=t -c commit.gpgsign=false)
  mkdir -p "$B" "$S/stateMachines" "$fx/home/shared/.ssh" "$fx/bin"
  : > "$fx/passwd"
  for u in root test oosh-user bash-user developking; do
    mkdir -p "$fx/home/$u"
    printf '%s:x:1:1::%s/home/%s:/bin/bash\n' "$u" "$fx" "$u" >> "$fx/passwd"
  done
  for d in main dev.heal kept old; do
    "${g[@]}" init -q -b "$d" "$B/$d"
    "${g[@]}" -C "$B/$d" remote add origin "$url"
    case "$d" in
      old) printf 'seed\n' > "$B/$d/file" ;;
      *)   printf 'config.session.save() { :; }\n' > "$B/$d/config"; printf '  derivedHome=x\n' > "$B/$d/this" ;;
    esac
    "${g[@]}" -C "$B/$d" add . && "${g[@]}" -C "$B/$d" commit -q -m seed
  done
  mkdir -p "$B/testing/.git"
  for u in root test oosh-user bash-user developking; do
    ln -s "$D" "$fx/home/$u/oosh"; ln -s "$S" "$fx/home/$u/config"
  done
  # eraB.config, root.clone, devhome.missing, no.bashrc, ssh.legacy
  mkdir -p "$fx/home/test/config.orig.20261008-120000" "$fx/home/root/config.orig.20261008-120000" \
           "$fx/home/root/oosh.orig.20260910-093000" "$fx/home/root/oosh.orig.20261008-120000" "$fx/home/root/ssh.original"
  printf 'export OOSH_SSH_CONFIG_HOST="mac"\n' > "$S/oosh.env"
  printf 'export LOG_LEVEL="3"\n' > "$S/log.env"
  : > "$fx/home/root/.bashrc"; : > "$fx/home/root/.gitconfig"; printf "# oosh\n" > "$fx/home/oosh-user/.bashrc"
  # the ssh setup of decision 4
  mkdir -p "$fx/home/developking/.ssh" "$fx/home/root/.ssh/ids/ssh.developking"
  : > "$fx/home/developking/.ssh/id_rsa"; : > "$fx/home/root/.ssh/ids/ssh.developking/id_rsa"
  printf 'Host github.com\n  IdentityFile ~/.ssh/ids/ssh.developking/id_rsa\n  IdentitiesOnly yes\n' > "$fx/home/root/.ssh/config"
  printf 'Host github.com\n  IdentityFile ~/.ssh/id_rsa\n' > "$fx/home/shared/.ssh/config"
  printf 'github.com ssh-ed25519 AAAA\n' > "$fx/home/shared/.ssh/known_hosts"
  ln -s "$fx/home/root/oosh/init" "$fx/home/root/init"
  printf '#!/bin/sh\n' > "$fx/bin/this"; chmod 755 "$fx/bin/this"; ln -s "$fx/bin/this" "$fx/bin/this2"
  printf 'SETUP_SERVER_STATE_ID=99\nSETUP_SERVER_CUSTOM_SCRIPT=oo\n' > "$S/stateMachines/SETUP_SERVER.states.env"
  # the aside entry the heal made of the broken folder: every marker of the folder arms
  d="$B.aside/dev.heal.orig.20261008-120000"
  "${g[@]}" init -q -b dev.heal "$d"
  printf 'x\n' > "$d/os"; printf '<<<<<<< HEAD\n>>>>>>> origin/dev\n' > "$d/this"
  "${g[@]}" -C "$d" add . && "${g[@]}" -C "$d" commit -q -m 'conflict markers committed'
  printf '# heal test: an uncommitted change\n' >> "$d/os"
  printf 'ours\n' > "$d/heal.conflict.txt"
  "${g[@]}" -C "$d" update-ref refs/heal-test/diverged HEAD
  "${g[@]}" -C "$d" rev-parse HEAD > "$d/.git/MERGE_HEAD"
  "${g[@]}" -C "$d" update-ref --no-deref HEAD "$("${g[@]}" -C "$d" rev-parse HEAD)"
}
test.os.healExpectScript() { # <dir> <breakages...> # the expect check of dev.heal pointed at the fixture <dir>
  local fx="$1"; shift
  private.os.platform.heal.expect.check.script.get dev.heal "$@" | sed \
    -e "s#/etc/passwd#$fx/passwd#g" -e "s#^B=.*#B='$fx/base/Once.sh'#" -e "s#^S=.*#S='$fx/sc'#" \
    -e "s#^DK=.*#DK='$(id -un)'#" -e "s#^LAUNCHER=.*#LAUNCHER='$fx/bin/this'#" -e "s#^LAUNCHER2=.*#LAUNCHER2='$fx/bin/this2'#" \
    -e "s#^BOOT=.*#BOOT='$fx/etc/oosh/boot'#" -e "s#^DROPIN=.*#DROPIN='$fx/etc/profile.d/oosh.sh'#"
}
test.os.healExpectBroken() { # <fx> <block> <label> # run the check on the fixture, it must end rc 1 naming <block>; echo the fault for the caller
  local fx="$1" block="$2" label="$3" out rc
  out=$(test.os.healExpectScript "$fx" $(private.os.platform.heal.breakage.names.get | grep -vxF user.clone) | sh 2>&1); rc=$?
  [ "$rc" = 1 ] || { echo " $label-rc=$rc"; return 0; }
  case "$out" in *"expect $block: FAILED"*) ;; *) echo " $label-unnamed=[$out]" ;; esac
  return 0
}
test.os.healExpectCheck() {
  local fx bad="" names script out rc n B S D g
  fx=$(test.suite.fixture.make healexpect)
  B="$fx/base/Once.sh"; S="$fx/sc"; D="$B/dev.heal"
  g=(git -c user.email=t@t -c user.name=t -c commit.gpgsign=false)
  test.os.healExpectFixture "$fx"
  names=$(private.os.platform.heal.breakage.names.get | grep -vxF user.clone | tr '\n' ' ')
  # shellcheck disable=SC2086 # the names are words
  script=$(test.os.healExpectScript "$fx" $names)
  for n in B S DK LAUNCHER LAUNCHER2 BOOT DROPIN; do
    [ "$(printf '%s\n' "$script" | grep -c "^$n='")" = 1 ] || bad="$bad not-pointed:$n"
  done
  printf '%s\n' "$script" | grep -q "$fx/passwd" || bad="$bad passwd-not-pointed"
  printf '%s\n' "$script" | sh -n 2>/dev/null || bad="$bad sh-n"
  if command -v dash >/dev/null 2>&1; then printf '%s\n' "$script" | dash -n 2>/dev/null || bad="$bad dash-n"; fi
  case "$script" in *"git@github.com:Cerulean-Circle-GmbH/once.sh.git"*) ;; *) bad="$bad no-ssh-origin" ;; esac
  case "$script" in *"config --get remote.origin.url"*) ;; *) bad="$bad origin-not-the-configured-url" ;; esac
  # the healed machine passes, and says nothing failed
  out=$(printf '%s\n' "$script" | sh 2>&1); rc=$?
  [ "$rc" = 0 ] || bad="$bad healed-red=[$out]"
  case "$out" in *FAILED*) bad="$bad healed-says-failed" ;; esac
  # one thing broken at a time: the check names it (the line says: expect <block>: FAILED)
  "${g[@]}" -C "$D" remote set-url origin https://github.com/Cerulean-Circle-GmbH/once.sh.git
  bad="$bad$(test.os.healExpectBroken "$fx" origin https-origin)"
  "${g[@]}" -C "$D" remote set-url origin git@github.com:Cerulean-Circle-GmbH/once.sh.git
  mv "$fx/home/root/.ssh/config" "$fx/home/root/.ssh/config.x"; bad="$bad$(test.os.healExpectBroken "$fx" ssh no-root-ssh-config)"; mv "$fx/home/root/.ssh/config.x" "$fx/home/root/.ssh/config"
  rm "$fx/home/shared/.ssh/known_hosts"; bad="$bad$(test.os.healExpectBroken "$fx" ssh no-shared-known-hosts)"; printf 'github.com x\n' > "$fx/home/shared/.ssh/known_hosts"
  rm "$fx/home/root/init"; bad="$bad$(test.os.healExpectBroken "$fx" ssh no-init-link)"; ln -s "$fx/home/root/oosh/init" "$fx/home/root/init"
  rm "$fx/home/developking/.ssh/id_rsa"; bad="$bad$(test.os.healExpectBroken "$fx" ssh no-deploy-key)"; : > "$fx/home/developking/.ssh/id_rsa"
  mv "$fx/bin/this" "$fx/bin/this.x"; bad="$bad$(test.os.healExpectBroken "$fx" launcher no-launcher)"; mv "$fx/bin/this.x" "$fx/bin/this"
  rm "$fx/bin/this2"; bad="$bad$(test.os.healExpectBroken "$fx" launcher no-second-launcher-name)"; ln -s "$fx/bin/this" "$fx/bin/this2"
  # who moves: the healer and the login always to the branch; the others to the branch unless their tree carries the model
  rm "$fx/home/test/oosh"; ln -s "$B/kept" "$fx/home/test/oosh"; bad="$bad$(test.os.healExpectBroken "$fx" links test-not-on-branch)"
  rm "$fx/home/test/oosh"; ln -s "$D" "$fx/home/test/oosh"
  rm "$fx/home/oosh-user/oosh"; ln -s "$B/old" "$fx/home/oosh-user/oosh"; bad="$bad$(test.os.healExpectBroken "$fx" links kept-a-tree-that-predates-the-heal)"
  rm "$fx/home/oosh-user/oosh"; ln -s "$B/kept" "$fx/home/oosh-user/oosh"
  out=$(printf '%s\n' "$script" | sh 2>&1) || bad="$bad kept-a-tree-that-carries-the-model-red=[$out]"
  rm "$fx/home/oosh-user/oosh"; ln -s "$D" "$fx/home/oosh-user/oosh"
  rm "$fx/home/bash-user/oosh"; ln -s /opt/foreign/OOSH/x "$fx/home/bash-user/oosh"; bad="$bad$(test.os.healExpectBroken "$fx" links foreign-link-kept)"
  rm "$fx/home/bash-user/oosh"; ln -s "$D" "$fx/home/bash-user/oosh"
  rm "$fx/home/developking/config"; bad="$bad$(test.os.healExpectBroken "$fx" links developking-no-config)"; ln -s "$S" "$fx/home/developking/config"
  # the per-breakage blocks
  printf 'SETUP_SERVER_STATE_ID=30\n' > "$S/stateMachines/SETUP_SERVER.states.env"; bad="$bad$(test.os.healExpectBroken "$fx" state.30 state-30-left)"
  printf 'SETUP_SERVER_STATE_ID=99\n' > "$S/stateMachines/SETUP_SERVER.states.env"
  mv "$B.aside" "$B.aside.x"; bad="$bad$(test.os.healExpectBroken "$fx" aside no-aside-entry)"; mv "$B.aside.x" "$B.aside"
  rmdir "$fx/home/test/config.orig.20261008-120000"; bad="$bad$(test.os.healExpectBroken "$fx" eraB.config no-config-orig)"; mkdir "$fx/home/test/config.orig.20261008-120000"
  : > "$S/oosh.env"; bad="$bad$(test.os.healExpectBroken "$fx" eraB.config host-not-imported)"; printf 'export OOSH_SSH_CONFIG_HOST="mac"\n' > "$S/oosh.env"
  rmdir "$fx/home/root/oosh.orig.20261008-120000"; bad="$bad$(test.os.healExpectBroken "$fx" root.clone real-clone-not-kept)"; mkdir "$fx/home/root/oosh.orig.20261008-120000"
  printf 'x\n' >> "$D/this"; bad="$bad$(test.os.healExpectBroken "$fx" folder dirty-folder-left)"; "${g[@]}" -C "$D" checkout -q -- this
  rmdir "$B/testing/.git"; : > "$B/testing/.git"; bad="$bad$(test.os.healExpectBroken "$fx" worktree.layout worktree-left)"; rm "$B/testing/.git"; mkdir "$B/testing/.git"
  mkdir -p "$fx/etc/oosh"; ln -s "$D/boot" "$fx/etc/oosh/boot"; bad="$bad$(test.os.healExpectBroken "$fx" boot.era drop-in-left)"; rm "$fx/etc/oosh/boot"
  printf '[safe]\n\tdirectory = /Users/Shared/EAMD.ucp/x\n' > "$fx/home/root/.gitconfig"; bad="$bad$(test.os.healExpectBroken "$fx" safe.directory.stale stale-safe-directory)"; : > "$fx/home/root/.gitconfig"
  # a breakage that did not run is not asserted
  printf 'SETUP_SERVER_STATE_ID=30\n' > "$S/stateMachines/SETUP_SERVER.states.env"
  out=$(test.os.healExpectScript "$fx" dirty | sh 2>&1) || bad="$bad unrun-breakage-asserted=[$out]"
  out=$(test.os.healExpectScript "$fx" | sh 2>&1) || bad="$bad no-breakage-red=[$out]"
  # the aside entry of a folder breakage
  out=$(test.os.healExpectScript "$fx" merge.conflict | sh 2>&1) || bad="$bad aside-with-markers-red=[$out]"
  rm -f "$B.aside/dev.heal.orig.20261008-120000/.git/MERGE_HEAD"
  out=$(test.os.healExpectScript "$fx" merge.conflict | sh 2>&1) && bad="$bad merge-marker-missing-passed"
  # refusals: no branch, a dash, an unknown breakage
  private.os.platform.heal.expect.check.script.get >/dev/null 2>&1 && bad="$bad no-branch-accepted"
  private.os.platform.heal.expect.check.script.get -x dirty >/dev/null 2>&1 && bad="$bad dash-branch-accepted"
  private.os.platform.heal.expect.check.script.get dev.heal bogus >/dev/null 2>&1 && bad="$bad unknown-breakage-accepted"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "the healed fixture passes; the origin, the ssh setup, the launcher, the links, the state and the markers of each breakage are named when broken; a breakage that did not run is not asserted" || create.result 1 "expect check:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-EXPECT-CHECK: the post-heal check names what is not the shape the heal leaves" test.os.healExpectCheck
expect 0 "the healed fixture passes; the origin, the ssh setup, the launcher, the links, the state and the markers of each breakage are named when broken; a breakage that did not run is not asserted" \
  "E2: the scenario checked that the heal ran, not what it left"

# T-OS-HEAL-SNAPSHOT-ADDITIONS: the snapshot of the second heal also holds the number of entries of
# <base>.aside (a heal that moves a folder aside every run shows) and the state machine files of the
# sharedConfig by content (the heal writes the machine file again on every green run, the same
# bytes). The snapshot script is the one the runner sends; it runs here as root would, on a fixture
# machine: the passwd, B and S lines pointed at the fixture, a copy of the invariant in <base>/<branch>.
test.os.healSnapshotAdditions() {
  local fx bad="" script encoded out B S
  fx=$(test.suite.fixture.make healsnap)
  local HOME="$fx/home/test" OSSH_INSTALL_BRANCH; unset OSSH_INSTALL_BRANCH
  B="$fx/base/Once.sh"; S="$fx/sc"
  test.os.healExpectFixture "$fx"
  mkdir -p "$B/dev.heal/test" "$S/stateMachines" "$B.aside/b.orig.1"
  cp "$OOSH_DIR/test/test.platform.shared.idempotence.invariant" "$B/dev.heal/test/"
  test.os.stubs.set
  ossh() { echo "ossh $*" >> "$OS_T_REC"; }
  private.os.platform.heal.snapshot.get p dev.heal >/dev/null 2>&1
  encoded=$(grep '^ossh exec p ' "$OS_T_REC" | tail -1 | sed -n 's/^ossh exec p echo \([A-Za-z0-9+\/=]*\) | base64 -d.*/\1/p')
  script=$(printf '%s' "$encoded" | base64 -d | sed -e "s#/etc/passwd#$fx/passwd#g" -e "s#^B=.*#B='$B'#" -e "s#^S=.*#S='$S'#")
  test.os.stubs.unset
  [ "$(printf '%s\n' "$script" | grep -c "^B='$B'$")" = 1 ] || bad="$bad base-not-pointed"
  out=$(printf '%s\n' "$script" | bash 2>&1)
  case "$out" in *"$(printf '%s\t2 entries\t-' "$B.aside")"*) ;; *) bad="$bad aside-count-missing" ;; esac
  case "$out" in *"$(printf '%s\t' "$S/stateMachines/SETUP_SERVER.states.env")"*) ;; *) bad="$bad state-file-missing" ;; esac
  printf '%s\n' "$out" | grep -F "$S/stateMachines/SETUP_SERVER.states.env" | awk -F '\t' '$3 != "-" { f = 1 } END { exit f }' || bad="$bad state-file-stamped"
  printf '%s\n' "$out" | grep -F "$S/log.env" | awk -F '\t' '$3 == "-" { f = 1 } END { exit f }' || bad="$bad env-file-not-stamped"
  rmdir "$B.aside/b.orig.1"
  out=$(printf '%s\n' "$script" | bash 2>&1)
  case "$out" in *"$(printf '%s\t1 entries\t-' "$B.aside")"*) ;; *) bad="$bad aside-count-not-counting" ;; esac
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "the snapshot holds the entry count of the aside folder and the state files by content" || create.result 1 "snapshot additions:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-SNAPSHOT-ADDITIONS: the snapshot counts the aside entries and holds the state machine files" test.os.healSnapshotAdditions
expect 0 "the snapshot holds the entry count of the aside folder and the state files by content" \
  "E1: a heal that moves a folder aside on every run, or loses its state, passed the second heal"

# T-OS-HEAL-BREAKAGE-STATE30: the state.30 arm writes the state file of the sharedConfig (the one
# the heal sets to 99 and oo state reads), and the cache of the current machine there; a second run
# says already; with no machine file it writes one.
test.os.healBreakageState30() {
  local fx bad="" script out S f
  fx=$(test.suite.fixture.make healstate30)
  S="$fx/sc"; mkdir -p "$S/stateMachines"
  f="$S/stateMachines/SETUP_SERVER.states.env"
  printf 'SETUP_SERVER_STATES=([1]="a" [2]="b")\nSETUP_SERVER_STATE_ID=99\nSETUP_SERVER_CUSTOM_SCRIPT=oo\n' > "$f"
  printf 'machine=SETUP_SERVER\nstateID=SETUP_SERVER_STATE_ID\nstate=99\nstateScript=oo\n' > "$S/current.state.machine.env"
  script=$(private.os.platform.heal.breakage.script.get state.30 dev.heal | sed -e "s#/etc/passwd#$fx/passwd#g" -e "s#^S=.*#S='$S'#")
  [ "$(printf '%s\n' "$script" | grep -c "^S='$S'$")" = 1 ] || bad="$bad sharedconfig-not-pointed"
  : > "$fx/passwd"
  out=$(printf '%s\n' "$script" | sh 2>&1) || bad="$bad rc=[$out]"
  grep -qx 'SETUP_SERVER_STATE_ID=30' "$f" || bad="$bad state-id-not-30=[$(cat "$f")]"
  grep -q 'SETUP_SERVER_STATES=(\[1\]="a" \[2\]="b")' "$f" || bad="$bad states-lost"
  grep -qx 'SETUP_SERVER_CUSTOM_SCRIPT=oo' "$f" || bad="$bad script-lost"
  grep -qx 'state=30' "$S/current.state.machine.env" || bad="$bad cache-not-30"
  grep -qx 'machine=SETUP_SERVER' "$S/current.state.machine.env" || bad="$bad cache-machine-lost"
  [ ! -e "$fx/home" ] || bad="$bad wrote-a-home-config"
  out=$(printf '%s\n' "$script" | sh 2>&1) || bad="$bad second-rc"
  case "$out" in *already*) ;; *) bad="$bad second-not-already=[$out]" ;; esac
  rm -f "$f" "$S/current.state.machine.env"
  out=$(printf '%s\n' "$script" | sh 2>&1) || bad="$bad missing-rc=[$out]"
  grep -qx 'SETUP_SERVER_STATE_ID=30' "$f" 2>/dev/null || bad="$bad missing-not-written"
  grep -qx 'state=30' "$S/current.state.machine.env" 2>/dev/null || bad="$bad missing-cache-not-written"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "SETUP_SERVER 30 in the machine file and the cache of the sharedConfig, kept states, a second run says already" || create.result 1 "state.30 arm:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-BREAKAGE-STATE30: the state.30 arm sets the state of the sharedConfig, not a copy in a home" test.os.healBreakageState30
expect 0 "SETUP_SERVER 30 in the machine file and the cache of the sharedConfig, kept states, a second run says already" \
  "E3: the arm wrote root's ~/config, the heal reads the sharedConfig: the scenario never started from state 30"

# T-OS-HEAL-SECOND-COMMAND-GET: the second heal is one text, run from the tree that carries the heal
# (root's ~/oosh may be an older branch without oo heal): the dirname of root's ~/oosh, the branch
# folder, oo heal <branch> all. Run here with a stub readlink and a recording oo.
test.os.healSecondCommandGet() {
  local fx bad="" cmd out
  fx=$(test.suite.fixture.make healcommand)
  mkdir -p "$fx/bin" "$fx/base/old" "$fx/base/dev.heal"
  printf '#!/bin/sh\necho "%s"\n' "$fx/base/old" > "$fx/bin/readlink"; chmod 755 "$fx/bin/readlink"
  printf '#!/bin/sh\necho "oo $*"\n' > "$fx/base/dev.heal/oo"; chmod 755 "$fx/base/dev.heal/oo"
  cmd=$(private.os.platform.heal.second.command.get dev.heal) || bad="$bad rc"
  out=$(PATH="$fx/bin:$PATH" sh -c "$cmd" 2>&1)
  [ "$out" = "oo heal dev.heal all" ] || bad="$bad runs=[$out]"
  case "$cmd" in *"'"*) bad="$bad single-quote" ;; esac
  printf '%s\n' "$cmd" | sh -n 2>/dev/null || bad="$bad sh-n"
  private.os.platform.heal.second.command.get >/dev/null 2>&1 && bad="$bad no-branch-accepted"
  private.os.platform.heal.second.command.get -x >/dev/null 2>&1 && bad="$bad dash-accepted"
  private.os.platform.heal.second.command.get 'a b' >/dev/null 2>&1 && bad="$bad space-accepted"
  private.os.platform.heal.second.command.get "a'b" >/dev/null 2>&1 && bad="$bad quote-accepted"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "the second heal runs <base>/<branch>/oo heal <branch> all from the dirname of root's ~/oosh; a bad branch is refused" || create.result 1 "second command:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-SECOND-COMMAND-GET: the command of the second heal is one text" test.os.healSecondCommandGet
expect 0 "the second heal runs <base>/<branch>/oo heal <branch> all from the dirname of root's ~/oosh; a bad branch is refused" \
  "item 5: the text was written in the runner and again in its test"

# T-OS-HEAL-REPORTS-ONLY-IS: a heal that ends rc 1 with only reports says so in its rc line, "install
# state 99"; the first heal and the second read it through this one predicate.
test.os.healReportsOnlyIs() {
  local fx bad="" log
  fx=$(test.suite.fixture.make healreports); log="$fx/h.log"
  printf 'oo heal — summary\r\nrc 1: something is left for you — the lines marked left above; install state 99\r\n' > "$log"
  private.os.platform.heal.reports.only.is "$log" || bad="$bad reports-not-seen"
  printf 'rc 1: something is left for you — the lines marked left above\n' > "$log"
  private.os.platform.heal.reports.only.is "$log" && bad="$bad step-left-accepted"
  printf 'rc 2: cannot heal — no root; install state 99\n' > "$log"
  private.os.platform.heal.reports.only.is "$log" && bad="$bad rc2-accepted"
  printf 'rc 0: healed — every invariant PASS or NOT CHECKED, install state 99; oo mode <branch> works\n' > "$log"
  private.os.platform.heal.reports.only.is "$log" && bad="$bad rc0-accepted"
  : > "$log"
  private.os.platform.heal.reports.only.is "$log" && bad="$bad empty-accepted"
  private.os.platform.heal.reports.only.is "$fx/none.log" && bad="$bad missing-accepted"
  private.os.platform.heal.reports.only.is >/dev/null 2>&1 && bad="$bad no-log-accepted"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "only a rc 1 line ending in install state 99 is reports only" || create.result 1 "reports only:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-REPORTS-ONLY-IS: a rc 1 line ending in install state 99 is reports only" test.os.healReportsOnlyIs
expect 0 "only a rc 1 line ending in install state 99 is reports only" \
  "E3: the first heal took any rc 1, the second only the rc line"

# T-OS-HEAL-ARM-TWINS: the preamble reads the owner, the group and the inode of a path in one place
# with the GNU stat and its BSD twin; its as_user closes stdin, so a command run as a user never
# eats the rest of the script the root shell is reading.
test.os.healArmTwins() {
  local fx bad="" preamble out
  fx=$(test.suite.fixture.make healtwins)
  : > "$fx/f"
  preamble=$(private.os.platform.heal.remote.preamble.get dev.heal)
  out=$(printf '%s\n%s\n' "$preamble" "owner_of '$fx/f'; gid_of '$fx/f'; inode_of '$fx/f'" | sh 2>&1)
  [ "$out" = "$(id -un)
$(id -g)
$(ls -di "$fx/f" | awk '{ print $1 }')" ] || bad="$bad twins=[$out]"
  out=$(printf 'LEAK\n' | sh -c "$preamble
PATH=/nonexistent; runuser() { echo \"runuser \$*\"; cat; }; PATH=/usr/bin:/bin; as_user root echo hi" 2>&1)
  case "$out" in *LEAK*) bad="$bad as_user-reads-stdin" ;; esac
  out=$(printf 'LEAK\n' | sh -c "$preamble
sudo() { echo \"sudo \$*\"; cat; }; command() { return 1; }; as_user root echo hi" 2>&1)
  case "$out" in *LEAK*) bad="$bad as_user-sudo-reads-stdin" ;; esac
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "owner_of, gid_of and inode_of agree with ls and id; as_user does not read stdin" || create.result 1 "arm twins:$bad"
  return $(result)
}
test.case $level "T-OS-HEAL-ARM-TWINS: owner_of, gid_of, inode_of and an as_user that leaves stdin alone" test.os.healArmTwins
expect 0 "owner_of, gid_of and inode_of agree with ls and id; as_user does not read stdin" \
  "item 5: a command run as a user inside the root script read the script itself"

# T-OS-CLEANUP-ODOCKER: the container on a port is found and removed through odocker only: the list
# of odocker.container.list names it by its published port, odocker.stop and odocker.container.remove
# end it; no docker call of os.
test.os.cleanupOdocker() {
  local fx bad="" rec id
  fx=$(test.suite.fixture.make oscleanup)
  OS_T_REC="$fx/rec"; : > "$OS_T_REC"
  odocker.container.list() {
    printf 'CONTAINER ID  NAMES  IMAGE  STATUS  PORTS\n'
    printf 'aaa111  other  img  Up 2 minutes  9022->22/tcp\n'
    printf 'bbb222  quirky_name  img  Up 2 minutes  8022->22/tcp  8080->80/tcp\n'
    printf 'ccc333  gone  img  Exited (0) 3 minutes ago  8023->22/tcp\n'
  }
  odocker.stop() { echo "stop $*" >> "$OS_T_REC"; }
  odocker.container.remove() { echo "remove $*" >> "$OS_T_REC"; }
  docker() { echo "docker $*" >> "$OS_T_REC"; }
  id=$(private.os.platform.container.id 8022)
  [ "$id" = bbb222 ] || bad="$bad id=[$id]"
  [ -z "$(private.os.platform.container.id 8080)" ] && bad="$bad second-port-missed"
  [ -z "$(private.os.platform.container.id 80)" ] || bad="$bad container-port-matched"
  [ -z "$(private.os.platform.container.id 802)" ] || bad="$bad prefix-matched"
  private.os.platform.cleanup 8022
  [ "$(cat "$OS_T_REC")" = "stop bbb222
remove bbb222" ] || bad="$bad cleanup=[$(cat "$OS_T_REC")]"
  : > "$OS_T_REC"
  private.os.platform.cleanup 9999
  [ -s "$OS_T_REC" ] && bad="$bad nothing-to-clean-called=[$(cat "$OS_T_REC")]"
  unset -f odocker.container.list odocker.stop odocker.container.remove docker
  unset OS_T_REC
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "the container of a port is found in the odocker list and ended with odocker stop and container.remove" || create.result 1 "cleanup:$bad"
  return $(result)
}
test.case $level "T-OS-CLEANUP-ODOCKER: cleanup ends the container of a port through odocker only" test.os.cleanupOdocker
expect 0 "the container of a port is found in the odocker list and ended with odocker stop and container.remove" \
  "item 5: os called docker stop and docker rm itself"

# T-OS-DOCSTRING-NO-APOSTROPHE: no docstring of os (public or private) holds an apostrophe; c2
# splits the line at it.
test.os.docstringNoApostrophe() {
  local hits
  hits=$(grep -nE "^[A-Za-z0-9_.]+\(\)[[:space:]]+#.*'" "$OOSH_DIR/os" | cut -d: -f1 | tr '\n' ' ')
  [ -z "$hits" ] && create.result 0 "no apostrophe in a docstring of os" || create.result 1 "apostrophe in the docstring at line $hits"
  return $(result)
}
test.case $level "T-OS-DOCSTRING-NO-APOSTROPHE: no apostrophe in a docstring of os" test.os.docstringNoApostrophe
expect 0 "no apostrophe in a docstring of os" "c2 parses the signature line and splits it at an apostrophe"

### test.method

test.suite.save.results

