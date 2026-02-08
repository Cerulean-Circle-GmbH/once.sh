# Task 42: DRY Session ID Detection for hiveMind/otmux/claudeCode

**From**: Product Owner (Tron directive)
**For**: Task Agent (queue), Expert (implement when velocity allows), Tester (validate)
**Priority**: Medium — queue behind Task 41 (day-one fix)
**Status**: Done (commit 3adc032, combined with Task 41)

## Problem

`hiveMind team.status` shows Claude Code session IDs inconsistently. Sometimes they appear, sometimes not. The root cause: session ID detection is reimplemented in multiple places across `claudeCode`, `otmux`, and `hiveMind`. Each implementation has different logic, different edge cases, different failure modes.

Example — `hiveMind team.status claudeWoda` output:
```
claudeWoda
├── 0.0  woda-writer (active)
```
Missing: session ID for woda-writer's Claude Code instance.

## Directive: DRY

**Do Not Repeat Yourself.** Find the ONE method that detects/stores Claude Code session IDs and make otmux and hiveMind reuse it. Do not reimplement detection logic in three places.

## Design Guidance

1. **One source of truth**: `claudeCode session.id <pane>` (or similar) — a single method that reliably gets the session ID for a Claude Code instance running in a tmux pane
2. **hiveMind reuses it**: `hiveMind team.status` calls `claudeCode session.id` instead of its own parsing
3. **otmux reuses it**: If otmux needs session IDs, it calls the same method
4. **Consistent storage**: Session IDs stored in the role registry (`/tmp/hivemind.roles` or `~/config/`) so they're always available without re-detection

## Acceptance Criteria

- [ ] One canonical method for session ID detection (in `claudeCode`)
- [ ] `hiveMind team.status` consistently shows session IDs for all agents
- [ ] `hiveMind team.status claudeWoda` shows session IDs for woda-writer and scribe
- [ ] No duplicate session ID detection logic across scripts
- [ ] Tab completion works for session IDs where relevant

## Constraint

Token limits are close. Do NOT implement now. Queue this with the Task Agent. SM will signal when velocity allows implementation.
