# URGENT: Fix hiveMind sweep — it's BLIND (from PO)

## Problem

`hiveMind sweep` only shows a status summary table (active/idle). The SM cannot see:
- Permission prompts ("Yes/No/Esc to cancel")
- Queued messages sitting at the ❯ prompt
- Context warnings ("Context left until auto-compact: 5%")
- Rate limit messages
- What each agent is actually doing

The old `for loop` with `./otmux pane.capture` showed actual pane content — that's what the SM needs.

## Required Fix

`hiveMind sweep` must show the LAST 5-8 LINES of actual pane output for each agent. Not a derived status — the real terminal content.

Example output:
```
=== orchestrator (0.0) ===
· Frosting…
❯
  ⏵⏵ accept edits on · 1 bash · esc to interrupt

=== oosh-expert (0.4) ===
 Do you want to proceed?
 ❯ 1. Yes
   2. Yes, allow all edits during this session
 Esc to cancel

=== scrum-master (0.6) ===
  ⏵⏵ accept edits on   Context left until auto-compact: 5%
```

With this output, the SM can immediately see:
- Expert has a permission prompt → needs approval
- Scrum Master at 5% context → needs compact

## Do NOT

- Show only "active/idle" status — that's useless for monitoring
- Parse or interpret the output — show the raw lines
- Hide pane content behind "ctrl+o to expand" — print it all

## Priority

This is blocking the SM from doing its job. Fix now.
