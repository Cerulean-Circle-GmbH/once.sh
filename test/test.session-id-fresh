#!/usr/bin/env bash
# T-SESSION-ID-FRESH — RED-FIRST: claudeCode.session.id must return the CURRENT session uuid
# after a fork/rewind, NOT a stale cached one. Today session.id is cache-first (claudeCode:~1191):
# it returns sessions.env's stored uuid BEFORE the authoritative live fallback (session.current),
# so a forked/rewound pane whose cache wasn't refreshed yields the OLD uuid → callers read the
# wrong JSONL (context.read, delivery). Fix: validate the cached sid against the live session
# (or prefer session.current when they disagree). RED = cache wins over the live truth.
level=$1; [ -z "$level" ] && level=1
echo "starting: T-SESSION-ID-FRESH <LOG_LEVEL=$level> (RED-FIRST — cache-first returns stale)"
source this
source test.suite
source claudeCode
export LOG_DEVICE=/dev/null
log.level $level

# Pick a REAL live claude pane (session.current only resolves a genuine agent).
RP="${SESSION_TEST_PANE:-}"
if [ -z "$RP" ]; then
  RP=$(hiveMind protected.live.tupleset 2>/dev/null | awk -F'|' '$7=="agent"{print $2":"$3; exit}')
fi
if [ -z "$RP" ]; then
  test.case $level "T-SESSION-ID-FRESH (skipped — no live claude pane)" echo skip; expect.pass "skipped"; test.suite.save.results; exit 0
fi

LIVE=$(claudeCode.session.current "$RP" 2>/dev/null)   # authoritative CURRENT uuid
test.case $level "PRE: live session.current resolves for $RP" echo "live=$LIVE"
[ -n "$LIVE" ] && expect.pass "live uuid=$LIVE" || { expect.fail "no live uuid"; test.suite.save.results; exit 1; }

# Isolate the cache: point HIVEMIND_SESSIONS at a scratch file holding a STALE (bogus-old) uuid
# for this pane — simulating a fork/rewind that changed the real uuid but left the cache behind.
D="${TMPDIR:-/tmp}/test.sid.$$"; rm -rf "${TMPDIR:-/tmp}/test.sid."* 2>/dev/null; mkdir -p "$D"
trap 'rm -rf "${TMPDIR:-/tmp}/test.sid."* 2>/dev/null' EXIT
STALE="00000000-dead-4beef-0000-staleolduuid0"
export HIVEMIND_SESSIONS="$D/hivemind.sessions.env"
printf '%s|%s|stale-role\n' "$RP" "$STALE" > "$HIVEMIND_SESSIONS"

GOT=$(claudeCode.session.id "$RP" 2>/dev/null)
echo "  cache(stale)=$STALE  live(current)=$LIVE  session.id returned=$GOT"
test.case $level "session.id returns the CURRENT uuid after a stale cache, not the cached old one" echo "got=$GOT"
if [ "$GOT" = "$LIVE" ]; then
  expect.pass "session.id == live current uuid (fresh, cache validated)"
elif [ "$GOT" = "$STALE" ]; then
  expect.fail "RED: session.id returned the STALE cached uuid ($STALE) — cache-first ignores the fork/rewind (claudeCode:~1191)"
else
  expect.fail "session.id returned '$GOT' (neither live nor stale — investigate)"
fi

echo "=================================================================="
echo "  RED-FIRST: cache-first must yield to the live current uuid on disagreement."
echo "=================================================================="
test.suite.save.results
