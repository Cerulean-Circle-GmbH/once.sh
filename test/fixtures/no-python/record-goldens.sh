#!/usr/bin/env bash
# no-python burn-down, STEP 0 instrument (design session/tasks/no-python-in-oosh.design.md §3/§6.0).
# Records the OUTPUT of every OLD python path on FROZEN fixtures as committed GOLDEN files, BEFORE the
# python is removed. After removal, the replacement must reproduce each golden byte-for-byte.
#
#   record-goldens.sh <?TREE>     TREE = OOSH tree that STILL has the python (default /root/oosh)
#
# Guards (each one prevents a golden that silently records the wrong thing):
#   - refuses if python3 is absent: the sites fall back to jq -> the golden would be jq's, not python's
#   - refuses if TREE's scripts contain no python3 call (already burned down -> nothing to record)
#   - touches every input first: context.from.jsonl returns 'stale' for files older than 600s
#   - runs every call TWICE; differing output => listed in golden/NONDETERMINISTIC, no golden written
#   - sandbox HOME/CONFIG_PATH: nothing reads or writes the live ~/.claude or ~/config
# Output: golden/<function>/<fixture>[.<arg>].out = stdout + a final "rc=N" line; golden/MANIFEST.
# NO `set -u`: the call subshells INHERIT it and sourcing an OOSH script then aborts on its first
# unset variable — silently, before the function or the rc line run (= every golden empty, measured).
HERE=$(cd "$(dirname "$0")" && pwd)
TREE="${1:-/root/oosh}"
IN="$HERE/inputs"; OUT="$HERE/golden"
command -v python3 >/dev/null 2>&1 || { echo "REFUSE: python3 absent — goldens would record the jq fallback" >&2; exit 2; }
grep -q 'python3' "$TREE/claudeCode" "$TREE/scrumMaster" 2>/dev/null || { echo "REFUSE: no python3 in $TREE — nothing left to record" >&2; exit 2; }

# SCRATCH-LOCATION LAW: sandbox under the component's own test/gen, FIXED name, wiped per run.
SBX="$(cd "$HERE/../.." && pwd)/gen/t-no-python-goldens"
rm -rf "$SBX"; mkdir -p "$SBX/config" "$SBX/.claude/projects"
trap 'rm -rf "$SBX"' EXIT
rm -rf "$OUT"; mkdir -p "$OUT"
: > "$OUT/NONDETERMINISTIC"

# call <script> <function> <args...> : stdout + rc of the real OOSH function, sandboxed
call(){
  local s="$1" fn="$2"; shift 2
  ( export HOME="$SBX" CONFIG_PATH="$SBX/config" LOG_DEVICE=/dev/null
    unset CLAUDE_MAX_TOKENS_DEFAULT
    source "$TREE/$s" >/dev/null 2>&1
    "$fn" "$@" 2>/dev/null; echo "rc=$?" )
}
# record <goldenRelPath> <script> <function> <args...>
record(){
  local rel="$1"; shift
  local a b
  a=$(call "$@"); b=$(call "$@")
  if [ "$a" != "$b" ]; then echo "$rel" >> "$OUT/NONDETERMINISTIC"; return; fi
  mkdir -p "$OUT/$(dirname "$rel")"; printf '%s\n' "$a" > "$OUT/$rel"
}

# ── P1 family: JSONL usage sites (batch 1) ────────────────────────────────────────────────
for f in "$IN"/jsonl/*.jsonl; do
  touch "$f"
  n=$(basename "$f" .jsonl)
  record "swipe.ctx/$n.200.out"              scrumMaster private.scrumMaster.swipe.ctx "$f" 200
  record "swipe.ctx/$n.1000.out"             scrumMaster private.scrumMaster.swipe.ctx "$f" 1000
  record "max.tokens.for.jsonl/$n.out"       claudeCode  private.claudeCode.max.tokens.for.jsonl "$f"
  record "context.from.jsonl/$n.out"         claudeCode  private.claudeCode.context.from.jsonl "$f"
  record "velocity.calculate/$n.out"         claudeCode  private.claudeCode.velocity.calculate "$f"
done

# ── usage API parser: prints the SUBSCRIPTION_* variables it sets ─────────────────────────
subparse(){ ( export HOME="$SBX" CONFIG_PATH="$SBX/config" LOG_DEVICE=/dev/null
  source "$TREE/scrumMaster" >/dev/null 2>&1
  private.scrumMaster.subscription.parse "$(cat "$1")" 2>/dev/null; rc=$?
  for v in FIVE_HOUR_UTIL FIVE_HOUR_RESETS SEVEN_DAY_UTIL SEVEN_DAY_RESETS OPUS_UTIL OPUS_RESETS SONNET_UTIL SONNET_RESETS EXTRA_ENABLED; do
    eval "printf 'SUBSCRIPTION_%s=[%s]\n' $v \"\${SUBSCRIPTION_$v-<unset>}\""
  done; echo "rc=$rc" ); }
for f in "$IN"/usage-api/*.json; do
  n=$(basename "$f" .json); a=$(subparse "$f"); b=$(subparse "$f")
  if [ "$a" != "$b" ]; then echo "subscription.parse/$n.out" >> "$OUT/NONDETERMINISTIC"; continue; fi
  mkdir -p "$OUT/subscription.parse"; printf '%s\n' "$a" > "$OUT/subscription.parse/$n.out"
done

# INSTRUMENT GUARD: a golden without its final rc= line means the call never ran (source died,
# function undefined) — that is NOT a recording. Fail loudly and leave no goldens behind.
broken=$(find "$OUT" -name '*.out' -exec sh -c 'tail -1 "$1" | grep -q "^rc=[0-9]" || echo "$1"' _ {} \;)
if [ -n "$broken" ]; then
  echo "INSTRUMENT FAILURE: $(echo "$broken" | grep -c .) golden(s) without rc= line, e.g. ${broken%%$'\n'*}" >&2
  rm -rf "$OUT"; exit 3
fi

{ echo "recorded: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "tree: $TREE @ $(git -C "$TREE" rev-parse --short HEAD 2>/dev/null)"
  echo "python: $(python3 --version 2>&1)"
  echo "goldens: $(find "$OUT" -name '*.out' | wc -l)"
  echo "nondeterministic: $(grep -c . "$OUT/NONDETERMINISTIC")"; } > "$OUT/MANIFEST"
cat "$OUT/MANIFEST"
