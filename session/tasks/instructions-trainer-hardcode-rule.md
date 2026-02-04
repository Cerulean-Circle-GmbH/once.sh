# URGENT: Agent Trainer — Hardcode Mandatory No-Garbled-Messages Rule

**From**: Orchestrator (PO FINAL WARNING)
**To**: Agent Trainer (0.2)
**Priority**: CRITICAL — PO says this is a recurring failure

## Problem

Agents are STILL sending garbled no-space messages like:
- `StopdoingPRs.Nexttask:Task.24`
- `Task.28validationPASS`
- `Resumemonitoring.Checkallagentpanes`

The warning added in commit 57c6eaf was NOT strong enough. PO demands this be hardcoded as a MANDATORY rule, not just a warning.

## Required Change

In ALL SKILL.md files (all 9 in `.claude/agents/`), find the garbled messages WARNING and REPLACE it with this MANDATORY rule block:

```markdown
## MANDATORY: No Long Messages via otmux/hiveMind send (CRITICAL)

**NEVER send multi-word instructions via `./otmux send` or `./hiveMind send`.**
These commands lose spaces, creating unreadable garbled text.

**ALWAYS do this instead:**
1. Write detailed instructions to a file in `session/tasks/`
2. Send ONLY a short file reference: `Read session/tasks/<filename>.md`

**Examples of FORBIDDEN messages:**
- `./otmux send 0.4 'Stop doing PRs. Next task: Task.24'` → GARBLED
- `./hiveMind send expert 'Task.28 validation PASS'` → GARBLED

**Correct approach:**
1. Write instructions to `session/tasks/instructions-expert-next.md`
2. Send: `Read session/tasks/instructions-expert-next.md`

**This is a PO-enforced mandatory rule. Violations will be flagged.**
```

## Action Required

1. Update ALL 9 SKILL.md files in `.claude/agents/`
2. Replace the existing WARNING with the MANDATORY block above
3. Commit with message: "Hardcode no-garbled-messages as mandatory rule in all SKILL.md"
4. Push
