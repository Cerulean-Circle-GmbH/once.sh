# Hand-off: drop `claudeCode`'s python3 hard-dep

**Owner:** Marcel Donges
**Origin:** Hannes Nortje, 2026-05-27 (session: `ossh_certicate.update_run`)
**Status:** Open — awaiting Marcel
**Reference audit:** `docs/python.md`

## Title

`claudeCode` — drop python3 hard-dep in JSONL-parsing functions

## Summary

Three `claudeCode` functions hard-require `python3` with no fallback. This violates the OOSH rule *"outside otest, python should not be a dependency, but nice to use if it is installed."* On a host without `python3` they silently return `unknown` (the `2>/dev/null` swallows everything).

Apply the same migration pattern seen in `debug`'s commit `d1c6ce0` (Hannes Nortje, May 2026) — make `python3` optional, primary path is bash / jq / pure-bash.

## Scope — 116 lines of inline Python across three functions

| Function | File:Line | Inline Python | What it computes |
| --- | --- | --- | --- |
| `private.claudeCode.context.from.jsonl` | `claudeCode:1058–1079` | 22 lines | Remaining context % from JSONL token-usage stream |
| `private.claudeCode.velocity.calculate` | `claudeCode:1281–1336` | 56 lines | Token-growth rate + ETA to compaction |
| `claudeCode.context.dashboard` | `claudeCode:1372–1409` | 38 lines | Per-session dashboard row (uses `JSONL_FILE` env var) |

All three iterate a JSONL file, filter `type == 'assistant'`, extract `usage.input_tokens` + `usage.cache_creation_input_tokens` + `usage.cache_read_input_tokens` + `timestamp`, and compute over them. The logic is well within `jq`'s wheelhouse; the math (epoch diff, percentage, rate) is bash-doable.

## Origin (introducing commits)

- **`894a618`** (2026-02-08, Marcel Donges) — *Task 58: Programmatic context.read via JSONL token counting*
- **`b2f6892`** (2026-02-08, Marcel Donges) — *Improvement #9: Context velocity tracking — tokens/hr + time-until-compact*
- `1410a19` (2026-03-09, Marcel Donges) — Phase 5 split (Python carried through, not added)
- `cf727c5` (2026-03-09, Marcel Donges) — camelCase rename refactor (cosmetic; current `git blame` lands here)

All on the `dev → testing → prod` line.

## Precedent — the canonical fix to copy

**`d1c6ce0`** (2026-05-08, Hannes Nortje) — *fix(debug): errno() bash-only — drop python3 hard-dep + auto-install from ERR trap*

Same kind of inline `python3 -c "..."`; replaced with `command -v` guard plus pure-bash fallback. The before/after diff is the template for this work. See `debug:259–295` for the post-fix shape.

## Suggested fallback policy — Marcel picks one

| Option | Shape | LOC estimate | Trade-off |
| --- | --- | --- | --- |
| **(a) Pure bash** (matches `debug` precedent) | Use `grep`/`awk`/`sed` on JSONL. `python3` becomes optional, used only if present. | ~80–120 LOC | Zero external dep; somewhat fragile against unusual JSON whitespace/escaping but the fields are simple (numeric + ISO timestamp) |
| **(b) `jq` preferred, `python3` fallback** | Mirror `scrumMaster`'s pattern with preference order flipped. `command -v jq` → jq path → else `command -v python3` → python path → else `unknown`. | ~50 LOC | Smallest diff; adds implicit `jq` expectation |
| **(c) Either-or** | Try `jq` → try `python3` → return `unknown`. No prescriptive preference. | ~60 LOC | Cleanest; treats both as equal nice-to-haves |

## Acceptance criteria

1. With `python3` removed from `$PATH`, all three functions still produce sensible output on a real JSONL file. Easy local test:

   ```bash
   PATH=$(echo "$PATH" | tr ':' '\n' | grep -v python | paste -sd:) bash -c \
     'claudeCode context.read; claudeCode context.dashboard'
   ```

2. `./test.suite core 1` remains all-green (no regression in adjacent tests).
3. With `python3` present, behaviour matches today's output byte-for-byte (or with a documented improvement).
4. No silent failure to `unknown` if **any** fallback tool is available.

## Related references

- `docs/python.md` — full Python audit; this is items **#10, #11, #12** under the methodology audit (⚠️ smell, hard-dep)
- `debug:259–295` — the precedent pattern (post-`d1c6ce0`)
- `scrumMaster:1225–1234, 1271–1308` — secondary reference (jq-vs-python3 if/elif idiom already in tree, just with preference order opposite of what's wanted here)
- This session's plan: `/home/hannesn/.claude/plans/inherited-meandering-sundae.md`
