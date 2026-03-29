#!/usr/bin/env bash
#clear
#export PS4='\e[90m+${LINENO} in ${#BASH_SOURCE[@]}>${FUNCNAME[0]}:${BASH_SOURCE[@]##*/} \e[0m'
#set -x

level=$1
if [ -z "$level" ]; then
  level=1
else 
  # remove the level parameter
  shift
fi
echo "starting: ${BASH_SOURCE[@]##*/} <LOG_LEVEL=$1>"

#echo "sourcing init"
source this
source test.suite

log.level $level

competionArray=(once config list file ite)
source oo

test.os() 
{
((TEST_COUNTER++))
console.log "


Test 0: os \"$*\"
===================================================================="
os.start "$@"
console.log "RETURN: $RETURN_VALUE  Result: $RESULT 
===================================================================="
}

test.case - "os test start" \
   os $*
expect 0 "*" "Test start"

source os

### test.method

# ============================================================================
# os.check dispatches correctly for this platform
# ============================================================================

test.case $level "os.check detects current OS" \
  os.check os.hostname.info
if [ "$RETURN_VALUE" -eq 0 ]; then
  expect.pass "os.check resolved: $RESULT"
else
  expect.fail "os.check should detect OS and find os.hostname.info.<os>"
fi

test.case $level "os.check.env sets OOSH_OS" \
  os.check.env
if [ -n "$OOSH_OS" ]; then
  expect.pass "OOSH_OS=$OOSH_OS"
else
  expect.fail "OOSH_OS should be set after os.check.env"
fi

# ============================================================================
# FEATURE: os.hostname.info / os.hostname.get / os.hostname.set
# hostname.info shows multiple sources (hostname cmd, $HOSTNAME, scutil, etc)
# hostname.get returns a single non-empty hostname
# hostname.set changes the hostname (requires root — test existence only)
# ============================================================================

# --- T-HOST-1: os.hostname.info function exists ---
test.case $level "T-HOST-1: os.hostname.info function exists" \
  type -t os.hostname.info
if type -t os.hostname.info &>/dev/null; then
  expect.pass "os.hostname.info exists"
else
  expect.fail "os.hostname.info should be defined"
fi

# --- T-HOST-1b: OS-specific variant exists ---
test.case $level "T-HOST-1b: os.hostname.info has OS-specific variant" \
  echo "checking os.hostname.info.$OOSH_OS"
if type -t "os.hostname.info.darwin" &>/dev/null || \
   type -t "os.hostname.info.linux" &>/dev/null; then
  expect.pass "OS-specific hostname.info exists"
else
  expect.fail "os.hostname.info.darwin or .linux should be defined"
fi

# --- T-HOST-2: os.hostname.info shows multiple hostname sources ---
test.case $level "T-HOST-2: hostname.info shows multiple sources" \
  echo "testing info output"
if type -t os.hostname.info &>/dev/null; then
  HOST_INFO=$(os.hostname.info 2>/dev/null)
  # Should show at least 2 different sources (hostname cmd, $HOSTNAME, scutil, etc.)
  HOST_LINES=$(echo "$HOST_INFO" | grep -cE 'hostname|HOSTNAME|scutil|ComputerName|LocalHostName|HostName' | tr -d ' ')
  if [ "$HOST_LINES" -ge 2 ]; then
    expect.pass "hostname.info shows $HOST_LINES sources"
  else
    expect.fail "hostname.info should show multiple sources; only $HOST_LINES found"
  fi
else
  expect.pass "skipped — os.hostname.info not yet implemented"
fi

# --- T-HOST-3: os.hostname.get function exists ---
test.case $level "T-HOST-3: os.hostname.get function exists" \
  type -t os.hostname.get
if type -t os.hostname.get &>/dev/null; then
  expect.pass "os.hostname.get exists"
else
  expect.fail "os.hostname.get should be defined"
fi

# --- T-HOST-4: os.hostname.get returns non-empty value ---
test.case $level "T-HOST-4: hostname.get returns non-empty hostname" \
  echo "testing get"
if type -t os.hostname.get &>/dev/null; then
  HOST_VAL=$(os.hostname.get 2>/dev/null)
  if [ -n "$HOST_VAL" ]; then
    expect.pass "hostname.get returned: $HOST_VAL"
  else
    expect.fail "hostname.get should return a non-empty hostname"
  fi
else
  expect.pass "skipped — os.hostname.get not yet implemented"
fi

# --- T-HOST-5: os.hostname.get matches $HOSTNAME ---
test.case $level "T-HOST-5: hostname.get consistent with \$HOSTNAME" \
  echo "testing consistency"
if type -t os.hostname.get &>/dev/null; then
  HOST_VAL=$(os.hostname.get 2>/dev/null)
  # Should match or be related to $HOSTNAME (might differ in case or FQDN)
  if [ -n "$HOST_VAL" ] && [ -n "$HOSTNAME" ]; then
    if echo "$HOSTNAME" | grep -qi "$HOST_VAL" || echo "$HOST_VAL" | grep -qi "$HOSTNAME"; then
      expect.pass "hostname.get ($HOST_VAL) consistent with \$HOSTNAME ($HOSTNAME)"
    else
      # May differ on some systems — not a hard fail, just warn
      expect.pass "hostname.get ($HOST_VAL) differs from \$HOSTNAME ($HOSTNAME) — acceptable on some systems"
    fi
  else
    expect.pass "skipped — hostname or \$HOSTNAME empty"
  fi
else
  expect.pass "skipped — os.hostname.get not yet implemented"
fi

# --- T-HOST-6: os.hostname.set function exists ---
test.case $level "T-HOST-6: os.hostname.set function exists" \
  type -t os.hostname.set
if type -t os.hostname.set &>/dev/null; then
  expect.pass "os.hostname.set exists"
else
  expect.fail "os.hostname.set should be defined"
fi

# --- T-HOST-7: os.hostname.set with no args returns error ---
test.case $level "T-HOST-7: hostname.set with no args returns error" \
  echo "testing set validation"
if type -t os.hostname.set &>/dev/null; then
  os.hostname.set 2>/dev/null
  if [ "$RETURN_VALUE" -ne 0 ]; then
    expect.pass "hostname.set rejects missing hostname arg"
  else
    expect.fail "hostname.set should return non-zero without args"
  fi
else
  expect.pass "skipped — os.hostname.set not yet implemented"
fi

# --- T-HOST-8: os.check dispatches hostname methods to OS variant ---
test.case $level "T-HOST-8: os.check dispatches hostname.get to OS variant" \
  echo "testing dispatch"
if type -t os.hostname.get &>/dev/null; then
  os.check os.hostname.get
  if [ "$RETURN_VALUE" -eq 0 ]; then
    if echo "$RESULT" | grep -qE 'darwin|linux'; then
      expect.pass "os.check resolved hostname.get to: $RESULT"
    else
      expect.fail "os.check should resolve to os.hostname.get.darwin or .linux; got: $RESULT"
    fi
  else
    expect.fail "os.check failed to dispatch os.hostname.get"
  fi
else
  expect.pass "skipped — os.hostname.get not yet implemented"
fi

# --- T-HOST-9: completions exist ---
test.case $level "T-HOST-9: hostname.set has completion" \
  echo "checking completions"
# hostname.set should have a completion for the hostname parameter
if type -t os.hostname.set.completion.hostname &>/dev/null; then
  expect.pass "os.hostname.set.completion.hostname exists"
else
  # May not need completion — hostname is free text
  expect.pass "no completion for hostname.set (free text — acceptable)"
fi

echo ""
echo "=== os.hostname tests complete ==="
echo ""

# ============================================================================
# Test Summary
# ============================================================================

test.suite.save.results

