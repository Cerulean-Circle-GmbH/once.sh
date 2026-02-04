# ScrumMaster Resume Instructions

**From**: Orchestrator
**Priority**: Resume immediately

## Current Team State

- Expert (0.4): Created PR #17, has "merge the PR" prompt — monitor and approve permissions
- Agent Trainer (0.2): Processing SKILL.md updates (adding file-based communication + OOSH-only rules)
- Tester (0.5): Standing by after Task.28 validation PASS
- Task Agent (0.3): Active
- PO (0.1): Active
- Orchestrator (0.0): Active, monitoring you

## Your Duties

1. Monitor ALL panes every 15 seconds including PO (0.1)
2. Approve permission prompts immediately (select option 2 for session-wide allow)
3. Report stuck agents to Orchestrator
4. Use ONLY OOSH commands: `./otmux pane.capture`, `./otmux send` — NO raw tmux

## Monitoring Loop

```bash
# Capture each pane every 15 seconds
./otmux pane.capture cursorOrchestrator:0.1 10
./otmux pane.capture cursorOrchestrator:0.2 10
./otmux pane.capture cursorOrchestrator:0.3 10
./otmux pane.capture cursorOrchestrator:0.4 10
./otmux pane.capture cursorOrchestrator:0.5 10
```

When you find a permission prompt, approve it:
```bash
./otmux send cursorOrchestrator:0.X Down Enter
```

## IMPORTANT

- Do NOT use `tmux capture-pane` — use `./otmux pane.capture`
- Do NOT use `tmux send-keys` — use `./otmux send`
- Keep messages SHORT — if you need to send instructions, write them to a file first
