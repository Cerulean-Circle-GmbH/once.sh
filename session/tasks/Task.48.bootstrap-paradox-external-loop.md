# Task 48: Bootstrap Paradox — Move sweep.loop Outside Agent Layer

**From**: woda-writer (Ch7-Ch8 observation, via PO)
**For**: Expert (implement), Tester (validate)
**Priority**: Critical — architectural fix
**Status**: Open

## Problem

The bootstrap paradox: `hiveMind sweep.loop` runs inside the scrum-master agent. The SM itself gets stuck on permission prompts. The unblocker needs unblocking. Nobody is left to unblock the unblocker — except the PO (human-adjacent agent) doing it manually.

This is why the monitoring chain keeps breaking.

## Root Cause

The sweep/unblock loop runs in the same process that gets stuck. It's like a watchdog timer running on the same CPU it's supposed to reset.

## Fix

Move the sweep.loop **outside** the Claude Code agent layer. Options:

### Option A: Shell script in a dedicated tmux pane (Recommended)
```bash
#!/bin/bash
# sweep-watchdog.sh — runs in its own tmux pane, no Claude Code, no permissions
while true; do
    ./hiveMind sweep
    ./hiveMind unblock all
    sleep 30
done
```
- Runs as a plain bash script, not inside a Claude Code session
- No permission prompts because it's not an agent
- Can be started with `./otmux send <pane> './sweep-watchdog.sh' Enter`

### Option B: launchd / cron
- System-level timer, survives session crashes
- More complex setup

### Option C: tmux hook
- `tmux set-hook -g pane-focus-in` or periodic hook
- tmux-native, no extra process

## Recommendation

Option A is simplest and follows OOSH patterns. Create `hiveMind.watchdog` method that:
1. Spawns a new tmux pane
2. Runs the sweep/unblock loop as a plain bash script
3. The script has no Claude Code session — just bash calling OOSH commands
4. No permissions needed because it's not an agent

## Acceptance Criteria

- [ ] Sweep/unblock loop runs outside any Claude Code session
- [ ] Loop continues even when all agents are stuck on permission prompts
- [ ] Loop detects and resolves permission prompts on ALL agents including SM
- [ ] `hiveMind watchdog` starts/stops the external loop
- [ ] The watchdog itself never needs permission approval
