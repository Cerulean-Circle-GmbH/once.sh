#!/usr/bin/env bash
#clear
#export PS4='\e[90m+${LINENO} in ${#BASH_SOURCE[@]}>${FUNCNAME[0]}:${BASH_SOURCE[@]##*/} \e[0m'
#set -x

TEST_CATEGORY=core

level=$1
if [ -z "$level" ]; then
  level=1
fi
info.log "starting: ${BASH_SOURCE[@]##*/} <LOG_LEVEL=$1>"

#echo "sourcing init"
source this
source test.suite

log.level $level

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
# Test: missing gh CLI gives clear FAIL result
# ─────────────────────────────────────────────────────────────────────────────
(
  emptyDir=$(mktemp -d)
  PATH="$emptyDir"
  private.os.platform.test.ci macos 2>/dev/null
  echo "$RESULT"
  rmdir "$emptyDir"
) | grep -q "FAIL"
if [ $? -eq 0 ]; then
  expect.pass "missing gh CLI returns FAIL result"
else
  expect.fail "missing gh CLI should return FAIL result"
fi

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

### test.method

test.suite.save.results

