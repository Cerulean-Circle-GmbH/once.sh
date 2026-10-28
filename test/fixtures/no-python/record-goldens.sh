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
# Several sites try jq BEFORE python (claudeCode.session.name Method 1, list.json, ...): with jq on
# PATH the golden would record jq, not the python we are replacing.
command -v jq >/dev/null 2>&1 && { echo "REFUSE: jq is on PATH — jq-first sites would record jq, not python" >&2; exit 2; }
. "$HERE/fixture-lib.sh"

# SCRATCH-LOCATION LAW: sandbox under the RECORDED TREE's own test/gen, FIXED name, wiped per run.
# (Not under this worktree: its path carries a session uuid that ps-based uuid detection would pick up.)
SBX="$TREE/test/gen/t-no-python-goldens"
rm -rf "$SBX"; mkdir -p "$SBX/config" "$SBX/.claude/projects"
trap 'np.sweep; rm -rf "$SBX"' EXIT
rm -rf "$OUT"; mkdir -p "$OUT"
: > "$OUT/NONDETERMINISTIC"
export TZ=UTC

# call <script> <function> <args...> : stdout + rc of the real OOSH function, sandboxed
call(){
  local s="$1" fn="$2"; shift 2
  ( export HOME="$SBX" CONFIG_PATH="$SBX/config" HIVEMIND_REGISTRY="$SBX/config/hivemind.roles.env" LOG_DEVICE=/dev/null
    unset CLAUDE_MAX_TOKENS_DEFAULT
    source "$TREE/$s" >/dev/null 2>&1
    "$fn" "$@" 2>/dev/null; echo "rc=$?" ) | sed "s|$SBX|<SBX>|g"
}
# store <goldenRelPath> <outputA> <outputB> : write only when both runs agree
store(){
  if [ "$2" != "$3" ]; then echo "$1" >> "$OUT/NONDETERMINISTIC"; return; fi
  mkdir -p "$OUT/$(dirname "$1")"; printf '%s\n' "$2" > "$OUT/$1"
}
# record <goldenRelPath> <script> <function> <args...>
record(){
  local rel="$1"; shift
  store "$rel" "$(call "$@")" "$(call "$@")"
}
# known.wrong <goldenRelPath> <ruling> <newContent> : replace a recorded cell, keep the old value on record
: > "$OUT/KNOWN-WRONG"
known.wrong(){
  local rel="$1" ruling="$2" new="$3" old
  old=$(cat "$OUT/$rel" 2>/dev/null)
  [ "$old" = "$new" ] && return 0
  { echo "== $rel  [$ruling]"; echo "OLD (python, known-wrong): $(printf '%s' "$old" | tr '\n' ' ')"
    echo "NEW (golden):              $(printf '%s' "$new" | tr '\n' ' ')"; } >> "$OUT/KNOWN-WRONG"
  printf '%s\n' "$new" > "$OUT/$rel"
}
# amend.r1 <goldenRelPath> <script> <function> <args-on-zero-stripped-fixture...> (ruling R1)
amend.r1(){
  local rel="$1"; shift
  local a b; a=$(call "$@"); b=$(call "$@")
  [ "$a" != "$b" ] && { echo "$rel(R1)" >> "$OUT/NONDETERMINISTIC"; return; }
  known.wrong "$rel" "R1 only total>0 records count" "$a"
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
  # R1: the zero-stripped twin defines the CORRECT value; where it differs the raw cell is KNOWN-WRONG.
  z="$SBX/nozero/$n.jsonl"; mkdir -p "$SBX/nozero"; np.strip.zero "$f" > "$z"; touch "$z"
  amend.r1 "swipe.ctx/$n.200.out"            scrumMaster private.scrumMaster.swipe.ctx "$z" 200
  amend.r1 "swipe.ctx/$n.1000.out"           scrumMaster private.scrumMaster.swipe.ctx "$z" 1000
  amend.r1 "max.tokens.for.jsonl/$n.out"     claudeCode  private.claudeCode.max.tokens.for.jsonl "$z"
  amend.r1 "context.from.jsonl/$n.out"       claudeCode  private.claudeCode.context.from.jsonl "$z"
  amend.r1 "velocity.calculate/$n.out"       claudeCode  private.claudeCode.velocity.calculate "$z"
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

# ══ BATCH 2 ══════════════════════════════════════════════════════════════════════════════
# ── creds + expiry (scrumMaster:1710/1711/1728). SECURITY: the token is NEVER written — the golden
#    holds sha256(stdout) only. Fake tokens anyway; the rule is the rule.
authsha(){ ( export HOME="$SBX" CONFIG_PATH="$SBX/config" LOG_DEVICE=/dev/null
  source "$TREE/scrumMaster" >/dev/null 2>&1
  o=$(private.scrumMaster.subscription.auth 2>/dev/null); rc=$?
  if [ -n "$o" ]; then echo "stdout.sha256=$(printf '%s' "$o" | sha256sum | cut -c1-64)"; else echo "stdout=<empty>"; fi
  echo "rc=$rc" ); }
for f in "$IN"/creds/*.json "$IN/creds/9-no-file"; do
  n=$(basename "$f" .json); rm -f "$SBX/.claude/.credentials.json"; mkdir -p "$SBX/.claude"
  [ -f "$f" ] && cp "$f" "$SBX/.claude/.credentials.json"
  store "subscription.auth/$n.out" "$(authsha)" "$(authsha)"
done
rm -f "$SBX/.claude/.credentials.json"

# ── pane-arg hiveMind sites (7484/7496 live.jsonl, 7569 denom, 7647 from.jsonl.reading) ──
np.build.projects "$SBX"
np.plant.panes "$SBX"
for p in 0.0 0.1 0.2 0.3; do
  record "context.live.jsonl/pane$p.out"           hiveMind private.hiveMind.context.live.jsonl "$NP_SESS:$p"
  record "context.denom.for.target/pane$p.out"     hiveMind private.hiveMind.context.denom.for.target "$NP_SESS:$p"
  record "context.from.jsonl.reading/pane$p.out"   hiveMind private.hiveMind.context.from.jsonl.reading "$NP_SESS:$p"
done

# ── claudeCode.session.name — custom-title (claudeCode:1351; Method 2 is ruled DELETE: no index fixture) ──
for sid in 31 32 33 34 35 36 99; do
  record "session.name/sid$sid.out" claudeCode claudeCode.session.name "33333333-cccc-4ccc-8ccc-0000000000$sid"
done

# ── hiveMind.roles.list.uuids (3031) — real verb, read-only ──
for r in fxnp-alpha fxnp-beta fxnp-none; do
  record "roles.list.uuids/$r.out" hiveMind hiveMind.roles.list.uuids "$r"
done

# ── hiveMind.agent.fork.best picker (3193). The VERB forks (spawns claude) — never call it. Its
#    picker is a QUOTED heredoc (<< 'EOF': no bash interpolation, env ROLE only), so running the
#    extracted program text is byte-faithful. Golden = stdout + stderr (the user-visible table) + rc.
awk '/picked=\$\(ROLE="\$role" python3 << .EOF./{f=1; next} f && /^EOF$/{exit} f' "$TREE/hiveMind" > "$SBX/forkbest.py"
[ -s "$SBX/forkbest.py" ] || { echo "INSTRUMENT FAILURE: fork.best picker not extracted from $TREE/hiveMind" >&2; exit 3; }
pick(){ ( export HOME="$SBX" ROLE="$1"; o=$(python3 "$SBX/forkbest.py" 2>"$SBX/fb.err"); rc=$?
  echo "$o"; echo "--stderr--"; cat "$SBX/fb.err"; echo "rc=$rc" ) | sed "s|$SBX|<SBX>|g"; }
for r in fxnp-fork fxnp-small fxnp-none; do
  store "fork.best.picker/$r.out" "$(pick "$r")" "$(pick "$r")"
done
np.sweep

# ── Hand amendments (rulings that a mechanical twin cannot express). Each file under amend/ is the
#    CORRECT golden for the same relative path; the recorded python value goes to KNOWN-WRONG.
#    A stale amendment (its golden path no longer recorded) is an instrument failure.
if [ -d "$HERE/amend" ]; then
  while IFS= read -r a; do
    rel="${a#$HERE/amend/}"; rel="${rel%.ruling}"
    case "$a" in *.ruling) continue ;; esac
    [ -f "$OUT/$rel" ] || { echo "INSTRUMENT FAILURE: amendment $rel has no recorded golden" >&2; exit 3; }
    known.wrong "$rel" "$(cat "$a.ruling" 2>/dev/null || echo 'hand amendment')" "$(cat "$a")"
  done < <(find "$HERE/amend" -type f -name '*.out' | sort)
fi

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
