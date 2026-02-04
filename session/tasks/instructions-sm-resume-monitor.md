# ScrumMaster Post-Compact Resume: Monitor ALL Panes

**From**: Orchestrator
**Priority**: IMMEDIATE — PO directive

## Your #1 Job Right Now

Monitor ALL panes every 15 seconds for permission prompts. PO (0.1) is compacting and MUST be unblocked when stuck.

## Monitoring Loop

Capture each pane, check for stuck prompts, approve immediately:

```bash
./otmux pane.capture cursorOrchestrator:0.0 10
./otmux pane.capture cursorOrchestrator:0.1 10
./otmux pane.capture cursorOrchestrator:0.2 10
./otmux pane.capture cursorOrchestrator:0.3 10
./otmux pane.capture cursorOrchestrator:0.4 10
./otmux pane.capture cursorOrchestrator:0.5 10
```

## When You See a Stuck Prompt

- Permission prompt (❯ with options): `./otmux send cursorOrchestrator:0.X Down Enter`
- "accept edits on": already auto-accepting, no action needed
- Idle prompt (❯) with no activity: check if agent needs a task

## Rules

- Use ONLY `./otmux pane.capture` — never `tmux capture-pane`
- Use ONLY `./otmux send` — never `tmux send-keys`
- Keep messages to 3 words max — write details to files
- PO pane (0.1) is PRIORITY during compact
