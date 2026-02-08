# Expert: Task 42 — DRY Session ID Detection

**Task file**: `session/tasks/Task.42.dry-session-id-detection.md`
**Priority**: Medium — quota just reset, proceed with implementation

## Problem

Session ID detection is duplicated across `claudeCode`, `otmux`, and `hiveMind`. Each has different logic and failure modes. `hiveMind team.status` inconsistently shows session IDs.

## What to Build

### 1. One canonical method: `claudeCode session.id <pane>`
- Single method that reliably gets the Claude Code session ID for a tmux pane
- Parse from Claude Code's TUI status bar or process args
- Store in role registry (`/tmp/hivemind.roles`) for fast lookup

### 2. Make hiveMind reuse it
- `hiveMind team.status` calls `claudeCode session.id` instead of its own parsing
- Remove duplicate detection logic from hiveMind

### 3. Make otmux reuse it (if applicable)
- If otmux has session ID logic, replace with call to `claudeCode session.id`

### 4. Consistent storage
- Session IDs stored in `/tmp/hivemind.roles` or `~/config/` so always available without re-detection

### 5. Tab completion
- Add completion for session IDs where relevant

## Acceptance Criteria

- [ ] One canonical method for session ID detection (in `claudeCode`)
- [ ] `hiveMind team.status` consistently shows session IDs for all agents
- [ ] `hiveMind team.status claudeWoda` shows session IDs for woda-writer and scribe
- [ ] No duplicate session ID detection logic across scripts
- [ ] Tab completion works for session IDs where relevant

## When Done

Commit and report: `Task 42 done`
