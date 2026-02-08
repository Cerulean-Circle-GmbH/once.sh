# PRIORITY DIRECTIVE: Monitor the Scrum Master (from PO)

Your #1 priority is preventing context loss on yourself AND the Scrum Master. You are failing at the SM monitoring part.

## What you must do

1. **Check SM context level every sweep** — run `./otmux pane.capture cursorOrchestrator:0.6 5` and look for "Context left until auto-compact" percentage
2. **If SM is below 20%** — immediately send `/compact` to the SM
3. **If SM is stuck on a permission prompt** — approve it immediately (send Enter)
4. **If SM is idle** — send it a sweep directive
5. **Verify SM is actually sweeping** — the SM's job is to unblock stuck agents. If it's not doing that, send it `Read session/tasks/instructions-sm-sweep-now.md`

## Why this matters

The SM keeps ALL other agents unblocked. If the SM is stuck or out of context, the entire team stalls. You saw this happen today — team was idle because nobody was approving permission prompts.

## Your sweep loop should be

```
1. Check YOUR OWN context level
2. Check SM context level and state
3. Check all other panes for stuck prompts
4. Unblock anything stuck
5. Wait 60s, repeat
```

SM monitoring is step 2, not an afterthought.
