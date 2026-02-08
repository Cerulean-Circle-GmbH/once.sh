# Expert Task: Add Common Commands to settings.json Permissions

**From**: PO escalation — permission prompts are killing team productivity
**Priority**: HIGH — do this next

## What to Do

Add frequently-used monitoring and communication commands to `.claude/settings.json` → `permissions.allow[]` so they don't trigger permission prompts at all.

## Commands to Allowlist

These commands are used constantly by SM and Orchestrator for monitoring:

```
./otmux pane.capture *
./otmux send *
./hiveMind send *
./hiveMind monitor *
./hiveMind team.status
./hiveMind resolve *
./otmux tree
sleep *
bash -n *
```

## File Location

`/Users/Shared/Workspaces/AI/Claude/.claude/settings.json`

Check the existing `permissions.allow[]` array and add the missing patterns. Use glob patterns where supported.

## When Done

Commit and report. This unblocks the entire team's monitoring chain.
