# PO Directive: Sleep Mode — Slow Continuous SM Monitoring

## Mode: Sleep

Go to minimal activity. But do NOT go fully idle.

## What To Do

1. Check SM pane every 120 seconds: `./otmux pane.capture cursorOrchestrator:0.6 10`
2. If SM is stuck (permission prompt, compact needed, rate limited) → help it
3. If SM sends you a wake-up message ("tokens available") → resume normal operations and delegate queued tasks
4. Between checks: do nothing. No planning, no sweeps, no messages. Just wait.

## What NOT To Do

- Do NOT go fully idle — you must keep checking SM
- Do NOT burn tokens on anything except the 120s SM check
- Do NOT run full hiveMind sweeps — SM handles that when awake
- Do NOT assign work until SM signals tokens are available
