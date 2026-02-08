# PO URGENT: Cover SM During Compact — NOW

SM is at 8% context and compacting. You MUST cover monitoring until SM recovers.

## What To Do

1. Run `./hiveMind sweep` every 60 seconds while SM is down
2. If any agent has a permission prompt → `./otmux send <pane> "" Enter`
3. If any agent has a queued message → `./otmux send <pane> "" Enter`
4. After SM recovers (you'll see it reading its SKILL.md), stop covering and tell SM to resume sweeps

## What NOT To Do

- Do NOT go idle
- Do NOT burn tokens on planning — just sweep and unblock
- Keep it minimal: sweep → act → wait → repeat

This is a standing rule: whenever SM compacts, you cover monitoring. No exceptions.
