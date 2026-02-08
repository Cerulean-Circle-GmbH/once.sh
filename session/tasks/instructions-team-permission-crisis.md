# ESCALATION: Permission Prompts Are Killing the Team (from PO)

## The Problem

Permission prompts are the #1 cause of team stalls. Every agent gets stuck on "Do you want to proceed? Yes/No" prompts. The monitoring chain fails because:

1. **SM gets stuck** on its own permission prompts while trying to monitor others
2. **Orchestrator doesn't notice** because it's idle instead of watching the SM
3. **PO has to manually unblock everyone** — this defeats the purpose of having a monitoring chain

This happened repeatedly today. The entire team was idle multiple times because nobody was approving prompts.

## Root Cause

Claude Code requires permission approval for bash commands and file edits. Every agent hits these constantly. The SM can't monitor if it's also stuck on its own permissions.

## Required Fix — TWO changes needed

### 1. Orchestrator: ACTIVELY monitor the SM (not passively)

Do NOT sit idle waiting for messages. Run a monitoring loop:
```
while true:
  capture SM pane
  if SM has permission prompt → approve it
  if SM is idle → send sweep directive
  sleep 30
```

The Orchestrator MUST keep the SM unblocked at all times. This is priority #1.

### 2. SM and Orchestrator: Use "Yes, allow all edits during this session" (option 2)

When you see a permission prompt with option 2 "Yes, allow all edits during this session", SELECT OPTION 2 by pressing down-arrow then Enter. This prevents the same permission from blocking you again.

For bash commands: select "Yes, and don't ask again for [command]" (also option 2).

This drastically reduces future permission interruptions.

### 3. Expert: Add common commands to .claude/settings.json permissions

The Expert should add frequently-used commands to `.claude/settings.json` → `permissions.allow[]` so they don't trigger prompts at all. Commands like:
- `./otmux pane.capture *`
- `./otmux send *`
- `./hiveMind send *`
- `./hiveMind monitor *`
- `./hiveMind team.status`

## This is a governance failure

The SM's job is to keep the team unblocked. The Orchestrator's job is to keep the SM unblocked. Both are failing. Fix this NOW or the team cannot function.
