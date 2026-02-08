# Expert: Task 40.1 — hiveMind Multi-Team Support

**Parent**: Task.40.cmm4-context-aware-team.md
**Your design plan**: session/tasks/task40-expert-plan.md (section 1)
**Priority**: High — unlocks all other 40.x subtasks
**Commit**: 3adc032 is your latest (Task 41+42). Build on that.

## What to Build

Per your own design plan, the key insight: session prefix already partitions `/tmp/hivemind.roles`. No new registry files needed.

### 1. `hiveMind.team.list`
- List unique session names from `/tmp/hivemind.roles`
- `cut -d: -f1 /tmp/hivemind.roles | sort -u`
- Tab completion: reuse `tmux list-sessions -F "#{session_name}"`

### 2. `hiveMind.team.status <?session>`
- Already exists but enhance: when called with NO argument, show one-line summary per team (agent count, active/idle)
- When called WITH session arg, show detailed per-pane status (current behavior)
- Format for no-arg:
  ```
  cursorOrchestrator  7 agents  (5 active, 2 idle)
  claudeWoda          2 agents  (1 active, 1 idle)
  ```

### 3. Tab completion for team-aware commands
- `hiveMind.team.list.completion.session()` — reuse tmux list-sessions
- `hiveMind.team.status.completion.session()` — reuse tmux list-sessions
- Verify existing completions on `hiveMind sweep`, `hiveMind send`, `hiveMind unblock` offer session names

### 4. Verify registration works cross-team
- `hiveMind register claudeWoda:0.0 woda-writer` should work already
- Test manually: register a fake claudeWoda entry, confirm `team.list` shows it, confirm `team.status` lists it

## NOT in Scope (later subtasks)
- sweep.detect improvements (40.2)
- Velocity measurement (40.4)
- Feedback loops (40.5)

## Acceptance Criteria
- [ ] `hiveMind team.list` lists all registered team sessions
- [ ] `hiveMind team.status` (no arg) shows summary for all teams
- [ ] `hiveMind team.status cursorOrchestrator` shows per-pane details
- [ ] Tab completion works for team.list and team.status session parameter
- [ ] Cross-team registration works (`hiveMind register claudeWoda:0.0 woda-writer`)
- [ ] `hiveMind sweep claudeWoda` works if that session exists
- [ ] Syntax check: `bash -n hiveMind` passes

## When Done
Commit and report: `Task 40.1 done`
