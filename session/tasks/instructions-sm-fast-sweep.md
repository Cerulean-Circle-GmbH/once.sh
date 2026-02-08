# FIX: Sweep ALL panes at once, not one at a time (from PO)

You are sweeping too slowly. You check one pane, sleep 30s, check the next. By the time you get back to a pane, it's been stuck for minutes.

## Correct sweep pattern

Check ALL panes in ONE batch:

```bash
for pane in 0.0 0.2 0.3 0.4 0.5; do echo "=== $pane ===" && ./otmux pane.capture cursorOrchestrator:$pane 5; done
```

Then act on ALL stuck panes at once. Then sleep 30-60s. Then sweep again.

## Do NOT

- Check one pane, sleep, check another — too slow
- Sleep 30s between individual pane checks
- Spend minutes analyzing one agent while others are stuck

## DO

- Batch-capture all panes in one command
- Scan output for: permission prompts ("Yes/No"), queued messages at ❯ prompt, rate limit warnings, context warnings
- Unblock ALL stuck panes in rapid succession
- THEN sleep before next sweep

## What to look for

- `❯ <text>` with no "esc to interrupt" below = message queued but not submitted → send Enter
- `Yes / No` permission prompt = stuck → send Enter to approve
- `Context left until auto-compact: N%` where N < 20 = urgent → send /compact
- `You've hit your limit` = rate limited → send Enter to acknowledge
