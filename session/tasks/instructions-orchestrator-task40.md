# PO Directive: Task 40 — CMM4 Context-Aware Team

## New Communication Model

Tron now talks only to me (PO). I delegate to you. This is the chain:

```
Tron → PO (0.1) → Orchestrator (0.0) → SM (0.6) → Workers
```

The claudeWoda session (woda-writer + wodaScribe) is also part of our team now. Two sessions, one team.

## The Goal

Build a **CMM4 context-aware Claude team** using only OOSH. Full details in:
`/Users/Shared/Workspaces/AI/Claude/session/tasks/Task.40.cmm4-context-aware-team.md`

## Immediate Priorities (quota-aware)

We are at **85% five_hour, 33% seven_day**. The velocity goal says: reach 90% of 7-day limit on day 7, not day 2. So:

1. **Do NOT burn tokens now.** Pace the work across the week.
2. **Expert**: Plan hiveMind improvements (multi-team support, tab completion, sweep.detect) — planning only, no implementation until quota recovers
3. **Task Agent**: Break Task 40 into subtasks with estimates
4. **Tester**: Stand by (throttled)
5. **SM**: Continue observe-only sweeps at 60s intervals
6. **woda-writer**: Already working on the CMM4 journey story — let them continue

## Key Deliverables

| Deliverable | Owner | Priority |
|-------------|-------|----------|
| hiveMind multi-team support | Expert | High |
| hiveMind sweep.detect all dialog formats | Expert | High |
| Tab completion for team selection | Expert | Medium |
| Velocity measurement method | Expert + Task Agent | Medium |
| CMM4 feedback loop design | Orchestrator + SM | High |

## What NOT to Do

- Don't start implementing until five_hour quota recovers below 50%
- Don't let agents burn context on planning loops — write plans to files
- Don't ignore woda-writer — they document the journey and their chapters validate our CMM level
