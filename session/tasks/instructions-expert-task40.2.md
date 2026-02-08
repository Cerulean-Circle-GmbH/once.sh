# Expert: Task 40.2 — sweep.detect Improvements

**Parent**: Task 40 CMM4 | **Depends on**: 40.1 (done, 1fe680f)
**Your design plan**: session/tasks/task40-expert-plan.md (section 2)
**Priority**: High — blocks 40.5 (feedback loop)

## What to Build

Expand `private.hiveMind.sweep.detect()` to recognize all Claude Code dialog formats. Per your design plan, add these detections BEFORE the idle/queued/active fallthrough:

| Pattern | Detection Type | Action |
|---------|---------------|--------|
| `⏵⏵ accept edits` | accept-edits | enter |
| `Context left until auto-compact: N%` | context-warning | none (log only) |
| `Do you want to proceed?` + numbered options | choice-prompt | none (needs human) |
| bare `$` prompt (no `❯`) | shell-escaped | none (agent left Claude) |
| `Compacted` or `auto-compact` in last lines | just-compacted | none (info only) |
| `rate limit` or `Rate limit` | rate-limit | (already exists, verify) |

### Implementation Notes
- Order by specificity: most specific patterns first
- `accept-edits`: `grep -q '⏵⏵ accept'` — action is Enter (same as permission)
- `context-warning`: `grep -oE 'auto-compact: [0-9]+%'` — extract %, log if <= 20%
- `shell-escaped`: last line is `$` with no `❯` — distinct from idle
- Keep `unblock.pane` simple: only act on enter/escape actions, log-only for others
- Detection must work across both teams (cursorOrchestrator and claudeWoda)

## Acceptance Criteria
- [ ] sweep.detect returns correct type for each new pattern
- [ ] unblock only acts on actionable states (permission, accept-edits)
- [ ] Existing detections (permission Allow/Deny, Yes/No from Task 41) still work
- [ ] `bash -n hiveMind` passes

## When Done
Commit and report: `Task 40.2 done`
