# Task 40 — Expert Design Plan

## 1. Multi-Team Registry

**Current**: Single registry at `/tmp/hivemind.roles` — all panes in one flat file, filtered by session prefix.

**Proposed**: Keep single registry file (simpler), but add explicit team awareness:

- `hiveMind.sweep` already takes `<?session>` — this IS the team selector
- Add `hiveMind.team.list` — list known sessions from registry: `cut -d: -f1 /tmp/hivemind.roles | sort -u`
- Add `hiveMind.team.sweep` alias — `hiveMind sweep <session>` with better discovery
- Tab completion: `hiveMind.sweep.completion.session()` already lists tmux sessions — works as-is
- No need for separate registry files per team — session prefix already partitions

**Registration for claudeWoda**:
- `hiveMind.register` already works with any `session:window.pane` target
- claudeWoda agents call `./hiveMind register claudeWoda:0.0 woda-writer` etc.
- No code change needed for registration

**New methods**:
```
hiveMind.team.list         # list unique session names from registry
hiveMind.team.status       # one-line summary per team (agent count, active/idle)
```

## 2. sweep.detect Improvements

**Current detections** (7 states): permission, rate-limit, autocomplete, idle, queued, active, unknown

**Missing detections** to add:

| Pattern | Detection | Action |
|---------|-----------|--------|
| `⏵⏵ accept edits` | accept-edits | enter |
| `Context left until auto-compact: N%` | context-warning | none (log only) |
| `Do you want to proceed?` + numbered options | choice-prompt | none (needs human) |
| `bash shell` (bare `$` prompt, no `❯`) | shell-escaped | none (agent left Claude) |
| `Compacted` or `auto-compact` in last lines | just-compacted | none (info only) |

**Implementation notes**:
- Add detections BEFORE the idle/queued/active fallthrough
- `accept-edits`: `grep -q '⏵⏵ accept'` — action is Enter (same as permission)
- `context-warning`: `grep -oE 'auto-compact: [0-9]+%'` — extract %, log if <= 20%
- `shell-escaped`: last line is `$` with no `❯` — distinct from idle
- Keep `unblock.pane` simple: only act on enter/escape actions, log-only for others

**sweep.detect will still be used by `hiveMind.unblock`** — the status/action pair drives unblock behavior. But `hiveMind.sweep` now shows raw content (per the fix just committed), so detect is only used by unblock.

## 3. Tab Completion for Team Selection

Already works:
- `hiveMind.sweep.completion.session()` calls `tmux list-sessions -F "#{session_name}"`
- Same completion function reusable for `team.list`, `team.status`

New completions needed:
```
hiveMind.team.list.completion.session()    # reuse: tmux list-sessions
hiveMind.team.status.completion.session()  # reuse: tmux list-sessions
```

No `--team` flag needed — OOSH uses positional args, not flags. `./hiveMind sweep claudeWoda` already works.

## 4. Velocity Measurement

**Concept**: Track token consumption rate vs. progress (tasks completed) over time.

**Data sources**:
- Token consumption: `scrumMaster.measure.subscription.api` (already exists, returns five_hour/seven_day %)
- Task completion: count commits or task files with "done" status
- Time: wall clock since session start

**New methods on scrumMaster**:
```
scrumMaster.measure.velocity           # current velocity snapshot
scrumMaster.measure.velocity.target    # calculate ideal burn rate
```

**Velocity formula**:
```
ideal_daily_rate = 7_day_limit / 7
actual_daily_rate = tokens_used_today / hours_elapsed * 24
velocity_ratio = actual_daily_rate / ideal_daily_rate
```
- `ratio > 1.2` → burning too fast, throttle
- `ratio < 0.8` → underutilizing, can increase
- `0.8 <= ratio <= 1.2` → on target

**Storage**: `session/metrics/velocity.<timestamp>.env` — same pattern as existing metrics

**Dependencies**: Needs `scrumMaster.measure.subscription.api` output (five_hour %, seven_day %) + a baseline timestamp (session start or day start).

## 5. Implementation Order (When Quota Allows)

1. **sweep.detect improvements** — small, high-value, improves unblock accuracy
2. **team.list / team.status** — enables multi-team awareness
3. **velocity measurement** — needs subscription API data, build on existing metrics
4. **claudeWoda registration** — depends on claudeWoda session existing

## 6. Risks

- **Velocity measurement accuracy**: five_hour % resets every 5 hours — not a clean daily metric. May need to sample and accumulate.
- **claudeWoda session**: Doesn't exist yet. Plan assumes it will be created by Orchestrator/PO.
- **sweep.detect false positives**: "Accept edits" pattern could match content in agent output. Keep detections ordered by specificity (most specific first).
