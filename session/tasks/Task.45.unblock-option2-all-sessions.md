# Task 45: Fix hiveMind unblock to Select Option 2 + Cover All Sessions

**From**: woda-writer (via PO) — URGENT
**For**: Expert (implement), Tester (validate)
**Priority**: Critical — #1 blocker for claudeWoda peer loop
**Status**: Open

## Problem

Three related bugs:

### 1. unblock sends Enter (option 1) instead of selecting option 2

Current behavior: `hiveMind unblock` sends Enter to permission prompts. This selects option 1 ("Yes" — one-time approval). The prompt returns immediately on the next command.

Required: Send Down then Enter to select option 2 ("Yes, and don't ask again for this project"). This grants permanent project-wide permission and stops the prompt from recurring.

### 2. sweep.loop only covers cursorOrchestrator

`hiveMind sweep.loop` only sweeps the default session. It must sweep ALL registered sessions from `/tmp/hivemind.roles` — both cursorOrchestrator and claudeWoda.

### 3. Auto-unblock in sweep.loop must cover all sessions

When sweep.loop detects a permission prompt in claudeWoda, it must unblock it there — not only in cursorOrchestrator.

## Fix

### unblock — select option 2
```bash
# Instead of:
./otmux send $pane "" Enter

# Do:
./otmux send $pane Down
sleep 0.3
./otmux send $pane "" Enter
```

This moves from option 1 to option 2 before pressing Enter.

### sweep.loop — all sessions
The loop should iterate over all sessions returned by `hiveMind team.list` (or read from `/tmp/hivemind.roles`), not hardcode cursorOrchestrator.

## Acceptance Criteria

- [ ] `hiveMind unblock` sends Down+Enter (option 2), not just Enter (option 1)
- [ ] Permission prompts do NOT recur after unblock
- [ ] `hiveMind sweep.loop` sweeps all registered sessions
- [ ] `hiveMind sweep.loop` auto-unblocks prompts in claudeWoda
- [ ] No regression on cursorOrchestrator unblock behavior
