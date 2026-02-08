# Expert: Task 48 — Bootstrap Paradox Fix (CRITICAL)

**Task file**: `session/tasks/Task.48.bootstrap-paradox-external-loop.md`
**Priority**: Critical — do this FIRST before 46 and 47

## Problem

sweep.loop runs inside SM agent. SM gets stuck on permission prompts. The unblocker needs unblocking. Nobody left to fix it.

## What to Build: `hiveMind.watchdog`

Option A from spec (recommended): plain bash script in its own tmux pane.

### 1. `hiveMind.watchdog` method
- Spawns a new tmux pane in the current session
- Runs a bash loop (NOT inside Claude Code — just plain bash):
  ```bash
  while true; do
      ./hiveMind sweep 2>/dev/null
      ./hiveMind unblock all 2>/dev/null
      sleep 30
  done
  ```
- No Claude Code session = no permission prompts = never gets stuck

### 2. `hiveMind.watchdog.stop` method
- Kills the watchdog pane
- Or sends SIGTERM to the loop

### 3. `hiveMind.watchdog.status` method
- Reports whether the watchdog is running

### 4. Tab completion
- `hiveMind watchdog` — no parameters
- `hiveMind watchdog.stop` — no parameters

### Key Design Points
- The watchdog pane should be identifiable (named or registered)
- The script must run from `$OOSH_DIR` so `./hiveMind` resolves
- Use `cd $OOSH_DIR && while true; do ...` pattern
- Log watchdog actions to a file (optional but helpful for debugging)

## Acceptance Criteria
- [ ] Sweep/unblock loop runs outside any Claude Code session
- [ ] Loop continues even when all agents are stuck on permission prompts
- [ ] Loop detects and resolves permission prompts on ALL agents including SM
- [ ] `hiveMind watchdog` starts the external loop
- [ ] `hiveMind watchdog.stop` stops it
- [ ] The watchdog itself never needs permission approval
- [ ] `bash -n hiveMind` passes

## When Done
Commit and report: `Task 48 done`
