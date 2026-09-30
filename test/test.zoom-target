#!/usr/bin/env bash
# T-ZOOM-TARGET — RED-FIRST guard for the otmux.zoom target-fix (trainer doc 60bc6af5).
# Today otmux.zoom() = `resize-pane -Z` (NO -t) → zooms the CALLER's pane only, so a remote
# rewind-driver can't zoom a TARGET → the target's below-frame /rewind confirm-menu stays
# unreadable-by-label → blind-select = revert. Fix: otmux.zoom <?target> resolves + `-t`s the
# NAMED pane; no-arg still zooms the caller. Assertions:
#   (1) otmux.zoom <target> zooms the NAMED pane, not the caller   — RED now (arg ignored)
#   (2) BACKWARD-COMPAT: no-arg still zooms the caller
#   (3) TOGGLE preserved: zoom then zoom again → unzoomed
#   (4) target-format guarded like send.raw (bad target → error, no wrong-pane zoom, no crash)
# Commands are driven FROM a fixture pane (caller=fxzoom:0.0), never the tester's own pane.
level=$1; [ -z "$level" ] && level=1
echo "starting: T-ZOOM-TARGET <LOG_LEVEL=$level> (RED-FIRST — fails until otmux.zoom takes a target)"
source this
source test.suite
export LOG_DEVICE=/dev/null
log.level $level

WT="${OOSH_DIR:-/root/oosh}"
FX_PREFIX="fxzoom_"
D="${TMPDIR:-/tmp}/test.zoom.$$"
sweep_fixtures() { tmux list-sessions -F '#{session_name}' 2>/dev/null | grep "^${FX_PREFIX}" | while IFS= read -r s; do tmux kill-session -t "$s" 2>/dev/null; done; rm -rf "${TMPDIR:-/tmp}/test.zoom."* 2>/dev/null; }
sweep_fixtures                       # PRE-RUN sweep (kill-safe, idempotent)
trap sweep_fixtures EXIT
mkdir -p "$D"

if [ -z "$TMUX" ] && ! tmux list-sessions >/dev/null; then
  test.case $level "T-ZOOM-TARGET (skipped — no tmux server)" echo skip; expect.pass "skipped"; test.suite.save.results; exit 0
fi

S="${FX_PREFIX}$$"
tmux new-session -d -s "$S" -x 100 -y 30 2>/dev/null
tmux split-window -v -t "$S:0" 2>/dev/null      # now $S:0.0 (top) + $S:0.1 (bottom)
sleep 0.3

# run a command IN a fixture pane (caller = that pane), wait for its completion marker
run_in() { # <pane> <cmd> <tag>
  local pane="$1" cmd="$2" tag="$3"; rm -f "$D/$tag"
  tmux send-keys -t "$pane" "PATH=$WT:\$PATH; $cmd; touch $D/$tag" Enter
  local i=0; while [ ! -f "$D/$tag" ] && [ "$i" -lt 25 ]; do sleep 0.2; i=$((i+1)); done
}
zoomed_flag() { tmux display-message -t "$S:0.0" -p '#{window_zoomed_flag}' 2>/dev/null; }
active_pane() { tmux list-panes -t "$S" -F '#{pane_index} #{pane_active}' 2>/dev/null | awk '$2==1{print $1; exit}'; }
# reset: unzoom if needed, THEN make the CALLER (0.0) the active pane so the TARGET (0.1) is
# non-active — this is what makes caller≠target meaningful. Current `resize-pane -Z` (no -t)
# zooms the ACTIVE pane, so with active=caller a target-arg that's IGNORED can't zoom 0.1 (RED);
# only the -t fix reaches 0.1. Without this control the split's new-pane-active masks the bug.
unzoom() {
  [ "$(zoomed_flag)" = "1" ] && tmux resize-pane -Z -t "$S:$(active_pane)" 2>/dev/null
  tmux select-pane -t "$S:0.0" 2>/dev/null      # caller=active=0.0, target 0.1 non-active
  sleep 0.2
}

echo; echo "===== (1) otmux.zoom <target> zooms the NAMED pane (not the caller) ====="
unzoom
run_in "$S:0.0" "otmux zoom $S:0.1" z1        # caller=0.0, target=0.1
zf=$(zoomed_flag); ap=$(active_pane)
echo "  after zoom $S:0.1 from caller 0.0 → zoomed_flag=$zf zoomed_pane=$ap (want 1 and 1)"
test.case $level "(1) TARGET zoom: named pane 0.1 is the zoomed one, not caller 0.0" echo "flag=$zf pane=$ap"
{ [ "$zf" = "1" ] && [ "$ap" = "1" ]; } && expect.pass "target 0.1 zoomed (remote driver can zoom a target)" \
  || expect.fail "RED: caller-zoomed or none (flag=$zf pane=$ap) — otmux.zoom ignores the target arg (no -t)"
unzoom

echo; echo "===== (2) BACKWARD-COMPAT: no-arg zooms the CALLER ====="
unzoom
run_in "$S:0.0" "otmux zoom" z2               # caller=0.0, no arg → caller should zoom
zf=$(zoomed_flag); ap=$(active_pane)
test.case $level "(2) no-arg zoom: caller 0.0 zoomed" echo "flag=$zf pane=$ap"
{ [ "$zf" = "1" ] && [ "$ap" = "0" ]; } && expect.pass "no-arg zooms caller 0.0 (backward-compat)" \
  || expect.fail "no-arg regressed (flag=$zf pane=$ap)"
unzoom

echo; echo "===== (3) TOGGLE preserved (zoom → zoom again → unzoomed) ====="
unzoom
run_in "$S:0.0" "otmux zoom" z3a; f1=$(zoomed_flag)
run_in "$S:0.0" "otmux zoom" z3b; f2=$(zoomed_flag)
test.case $level "(3) toggle: zoomed then unzoomed" echo "after1=$f1 after2=$f2"
{ [ "$f1" = "1" ] && [ "$f2" = "0" ]; } && expect.pass "toggle intact (1→0)" || expect.fail "toggle broken (after1=$f1 after2=$f2)"
unzoom

echo; echo "===== (4) target-format guarded like send.raw (bad target → error, no wrong zoom) ====="
unzoom
run_in "$S:0.0" "otmux zoom no.such:99.99 ; echo rc=\$? > $D/rc4" z4
rc4=$(sed 's/rc=//' "$D/rc4" 2>/dev/null); zf=$(zoomed_flag)
test.case $level "(4) bad target → non-zero rc + nothing zoomed (guarded)" echo "rc=$rc4 flag=$zf"
{ [ "$zf" != "1" ] && { [ -z "$rc4" ] || [ "$rc4" != "0" ]; }; } && expect.pass "bad target rejected, no wrong-pane zoom" \
  || expect.fail "bad target NOT guarded (rc=$rc4 flag=$zf) — mirror send.raw's private.resolve.target guard"
unzoom

echo
echo "=================================================================="
echo "  T-ZOOM-TARGET RED-FIRST: (1)+(4) are the fix spec (target param + guard);"
echo "  (2)+(3) are the backward-compat/toggle anchors that must stay green."
echo "  Real acceptance (manual): after a remote zoom of a SHORT target, its /rewind"
echo "  confirm-menu options render on-frame/readable-by-label."
echo "=================================================================="
sweep_fixtures
test.suite.save.results
