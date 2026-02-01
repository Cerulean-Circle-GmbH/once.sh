# ScrumMaster Context State

**Session**: cursorOrchestrator
**Updated**: 2026-02-01T18:15Z
**Role**: ScrumMaster
**Pane**: 0.6 (TMUX_PANE=%17)

## Current Team Layout (7 panes)

| Pane | Role | Registry Name | Status |
|------|------|---------------|--------|
| 0.0 | Orchestrator | orchestrator | Active [5b6cced8] |
| 0.1 | Product Owner | product-owner | Active, STAND DOWN sent |
| 0.2 | Agent Trainer | agent-trainer | Just compacted [f0facde3], STAND DOWN sent |
| 0.3 | Task Agent | task-agent | NEW — bootstrapped this turn, reading SKILL.md, STAND DOWN sent |
| 0.4 | Expert | oosh-expert | Active [a536512e], stalled on "commit and push", STAND DOWN sent |
| 0.5 | Tester | oosh-tester | Just compacted (was at 7%), at shell prompt |
| 0.6 | ScrumMaster | scrum-master | Me, standing down |

## STAND DOWN Active

**92% subscription limit reached.** All agents told to STOP. Resets 7pm Berlin time.
Only essential operations: approve permissions, save context.

## Registry Name Change

Pane 0.0 was renamed from `agent-teacher` to `orchestrator` in both:
- `/tmp/hivemind.roles` registry
- hiveMind code (commit 40e6ffb)
- All 8 SKILL.md files (commit f55cd4e)

Use `./hiveMind send orchestrator` NOT `agent-teacher`.

## Completed This Session

1. Agent Trainer completed all 7 SKILL.md improvement tasks
2. OOSH-Only Rule added to all 8 SKILL.md files
3. NO-SKIP-PERMISSIONS rule added to all 8 SKILL.md files
4. Communication sections added to 6/6 relevant agents
5. Orchestrator rename propagated across all files and code
6. hiveMind registry keys updated (agent-teacher -> orchestrator)
7. Communication chain: User -> PO -> Orchestrator -> ScrumMaster -> Workers
8. Expert verified hiveMind send/monitor are fully pane-agnostic
9. PO bootstrapped at pane 0.1
10. Expert fixed otmux sendEnter (-l flag + separate Enter + sleep) - commit 9ec0742
11. Expert fixed hiveMind send exit code 1 (added return 0) - commit 9ec0742
12. Expert added otmux send.keys helper for TUI interactions
13. Role violation caught: Agent Trainer tried to run tests, corrected
14. Expert compacted at 7% and recovered successfully
15. Agent Trainer added Context Preservation to all 8+ SKILL.md files
16. Agent Trainer created Task Agent SKILL.md (.claude/agents/task-agent/SKILL.md)
17. Expert fixed hiveMind team.status with real activity detection (commit 3c8fc00)
18. **Task Agent bootstrapped at pane 0.3** — registry updated, Claude started, SKILL.md read approved
19. Tester verified team.status fix (both checks pass, 180/181 tests, no regressions)
20. Tester compacted at 7% context
21. Agent Trainer compacted at 9% context

## Pending (when STAND DOWN lifts)

- **Expert tasks** (from Orchestrator):
  1. Implement `hiveMind sendEnter` command (name resolution + sendEnter like hiveMind send)
  2. Refactor all public OOSH methods to object.verb notation (non-matching become private)
  3. Add `task-agent` to hiveMind role prompt case function
- **Agent Trainer task**: Add save-before-compact rule to ALL SKILL.md files (PO critical rule — no auto-compact without saving)
- **Tester task**: Validate Expert's object.verb refactoring
- **Task Agent**: Complete bootstrap — needs first directive from PO
- **Code issue found**: `hiveMind.agent.bootstrap()` uses `--dangerously-skip-permissions` at line 967 — violates NO-SKIP-PERMISSIONS rule. Expert must fix.
- **Tester needs resume** after compact (at shell prompt)

## PO Critical Rules (NEW)

1. All agents must save context BEFORE compacting
2. No agent should auto-compact without saving
3. Agent Trainer must add this to all SKILL.md files

## Key Rules

- **OOSH-Only**: Never raw tmux. Use ./hiveMind send/monitor/resolve and ./otmux
- **NO-SKIP-PERMISSIONS**: Never use --dangerously-skip-permissions
- **Monitoring hierarchy**: Orchestrator monitors ONLY me. I monitor all others.
- **Permission approval**: `./otmux sendKeys <pane> Down Enter` for option 2. `./otmux sendEnter <pane> ''` for option 1.
- **Role enforcement**: Agent Trainer = SKILL.md only. Expert = code. Tester = tests. Task Agent = task files only.

## Recovery Steps

1. Read this file
2. Read `.claude/agents/scrum-master/SKILL.md` at `/Users/Shared/Workspaces/AI/Claude/.claude/agents/scrum-master/SKILL.md`
3. Read `/tmp/hivemind.roles` for current pane layout
4. Check if STAND DOWN is still active (subscription limit)
5. If active: only approve permissions, save context
6. If lifted: resume monitoring all agent panes, delegate pending tasks
7. Report status to Orchestrator via `./hiveMind send orchestrator`
