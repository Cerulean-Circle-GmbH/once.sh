#!/usr/bin/env bash
# T-COMPOSER-STATE — RED-FIRST: otmux composer.state <pane> must be a RADICAL-OOP METHOD (not a
# -e flag) returning a SEMANTIC state: 'ghost' for a dim ESC[2m suggested-prompt, 'staged' for
# real typed text, 'empty' for a clean prompt. The dim-test lives INSIDE otmux (capture-with-escapes
# + classify); the test asserts the SEMANTIC return string, NEVER raw ANSI. RED = method absent /
# doesn't discriminate the ghost (a driver mis-reads a dim suggestion as staged text → false 'busy').
level=$1; [ -z "$level" ] && level=1
echo "starting: T-COMPOSER-STATE <LOG_LEVEL=$level> (RED-FIRST — composer.state not implemented)"
source this
source test.suite
export LOG_DEVICE=/dev/null
log.level $level

FX_PREFIX="fxcomp_"
sweep_fx() { tmux list-sessions -F '#{session_name}' 2>/dev/null | grep "^${FX_PREFIX}" | while IFS= read -r s; do tmux kill-session -t "$s" 2>/dev/null; done; }
sweep_fx                                   # PRE-RUN sweep (kill-safe, idempotent)
trap sweep_fx EXIT
plant() { local tag="$1"; shift; local s="${FX_PREFIX}${tag}_$$"
  tmux kill-session -t "$s" 2>/dev/null
  tmux new-session -d -s "$s" -x 120 -y 8 2>/dev/null || { echo ""; return 1; }
  local scr=""; local l; for l in "$@"; do scr="${scr}${l}\n"; done
  tmux send-keys -t "$s" "clear; printf '%b' '${scr}'; exec cat" Enter 2>/dev/null
  sleep 0.4; echo "${s}:0.0"; }

if [ -z "$TMUX" ] && ! tmux list-sessions >/dev/null; then
  test.case $level "T-COMPOSER-STATE (skipped — no tmux)" echo skip; expect.pass skipped; test.suite.save.results; exit 0
fi

TITLE='────────────────────── role@host ──'
SEP='─────────────────────────────────────'
# render the composer chrome with a given input-line body (arg $1 = what follows the ❯)
comp() { plant "$1" "$TITLE" "$2" "$SEP" '  auto mode on · for agents'; }

# ESC[2m = dim (the ghost suggested-prompt); ESC[0m resets.
GHOST_PANE=$(comp ghost '❯ \033[2mtry: read session/tasks/foo.md\033[0m')
STAGED_PANE=$(comp staged '❯ read session/tasks/foo.md')
EMPTY_PANE=$(comp empty '❯ ')

assert_state() { # <name> <pane> <want>
  local name="$1" pane="$2" want="$3" got
  got=$(otmux composer.state "$pane" 2>/dev/null)
  test.case $level "$name: composer.state -> '$want' (got '$got')" echo "$got"
  if [ "$got" = "$want" ]; then expect.pass "$name = $want (semantic return)"
  else expect.fail "RED: want '$want', got '$got' — composer.state absent/undiscriminating (dim-test must live inside otmux)"; fi
}

echo; echo "===== composer.state semantic returns (ghost / staged / empty) ====="
assert_state "GHOST"  "$GHOST_PANE"  "ghost"
assert_state "STAGED" "$STAGED_PANE" "staged"
assert_state "EMPTY"  "$EMPTY_PANE"  "empty"

echo; echo "===== it is a METHOD, not a -e flag (radical-OOP) ====="
test.case $level "composer.state is a defined otmux method" echo "checking"
if grep -qE '^otmux\.composer\.state\(\)' "${OOSH_DIR}/otmux" 2>/dev/null; then
  expect.pass "otmux.composer.state() defined"
else
  expect.fail "RED: otmux.composer.state() not defined — the dim/ghost discrimination must be an OWNED method"
fi

echo "=================================================================="
echo "  RED-FIRST: ghost vs staged is the driver-safety discriminator (a dim suggestion is NOT staged)."
echo "=================================================================="
sweep_fx
test.suite.save.results
