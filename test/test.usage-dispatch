#!/usr/bin/env bash
# T-USAGE-DISPATCH — FAILABLE RED on the DEPLOYED /root/oosh/otmux. Every method ADVERTISED in
# otmux's usage() block MUST dispatch (resolve to a defined otmux.<method>()). The method list is
# DERIVED FROM the usage block — no hand-kept list — so an advertised-but-undispatched method
# (currently pane.zoom / pane.splitH / session.new / splitH / command / selectWindow / selectPane)
# is caught automatically. RED = usage promises a method the dispatcher can't deliver.
level=$1; [ -z "$level" ] && level=1
echo "starting: T-USAGE-DISPATCH <LOG_LEVEL=$level> (FAILABLE — advertised must dispatch)"
source this
source test.suite
export LOG_DEVICE=/dev/null
log.level $level

# OOSH_DIR is pinned to the deployed tree by this:199 invariant — exactly what we want to gate.
OTMUX="$OOSH_DIR/otmux"
test.case $level "PRE: deployed otmux under test" echo "$OTMUX"
[ -f "$OTMUX" ] && expect.pass "gating $OTMUX" || { expect.fail "no otmux at $OTMUX"; test.suite.save.results; exit 1; }

# DERIVE the advertised method list FROM the usage() block ($this <method> invocations).
ADVERTISED=$(sed -n '/^otmux.usage()/,/^}/p' "$OTMUX" | grep -oE '\$this [a-zA-Z][a-zA-Z0-9._]*' | awk '{print $2}' | sort -u)
test.case $level "PRE: derived >=1 advertised method from usage()" echo "$(printf '%s ' $ADVERTISED)"
[ -n "$ADVERTISED" ] && expect.pass "derived: $(printf '%s ' $ADVERTISED)" || { expect.fail "usage() parse empty"; test.suite.save.results; exit 1; }

# (1) STRUCTURAL: every advertised method has a dispatch target otmux.<method>().
UND=""
for m in $ADVERTISED; do grep -qE "^otmux\.${m}\(\)" "$OTMUX" || UND="$UND $m"; done
test.case $level "(1) every ADVERTISED method dispatches (defined otmux.<m>())" echo "undispatched:${UND:-none}"
[ -z "$UND" ] && expect.pass "all advertised methods dispatch" \
              || expect.fail "RED: advertised-but-UNDISPATCHED:${UND} — usage promises what the dispatcher lacks (no hand-list; derived from usage)"

# (2) BEHAVIORAL spot-check: calling an advertised-undispatched method yields the this-dispatch
# FAILURE signature (command not found / usage-not-found), NOT a silent success. Pick the first
# undispatched one (side-effect-free: it can't run — it isn't defined).
PROBE=$(printf '%s\n' $UND | head -1)
if [ -n "$PROBE" ]; then
  ERRF="${TMPDIR:-/tmp}/test.usage.err.$$"
  "$OTMUX" "$PROBE" >"$ERRF.out" 2>"$ERRF.err"   # stdout+stderr to separate files, no stream-merge
  OUT=$(cat "$ERRF.out" "$ERRF.err" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g'); rm -f "$ERRF.out" "$ERRF.err"
  test.case $level "(2) calling advertised '$PROBE' surfaces the dispatch failure (not silent)" echo "$OUT"
  echo "$OUT" | grep -qiE 'command not found|no such file|\.usage: command|unknown' \
    && expect.pass "RED-evidence: '$PROBE' advertised but this-dispatch fails ('command not found' class)" \
    || expect.fail "'$PROBE' neither dispatched nor cleanly errored: $OUT"
else
  test.case $level "(2) behavioral probe (skipped — nothing undispatched)" echo skip; expect.pass "skipped"
fi

echo "=================================================================="
echo "  FAILABLE RED: usage-derived dispatch parity — advertised == dispatchable."
echo "  Fix: define the missing otmux.<m>() (or remove from usage). No hand-kept list."
echo "=================================================================="
test.suite.save.results
