# Team Recovery Instructions

All agents were idle after rate limits and stuck prompts. PO is bringing the team back up.

## Recovery Steps (every agent)

1. Read your SKILL.md from `.claude/agents/<your-role>/SKILL.md`
2. Read your context file from `session/agents/<your-role>.context.md`
3. Report ready status to the Orchestrator
4. Wait for assignments

## Agent SKILL.md Locations

| Role | SKILL.md |
|------|----------|
| orchestrator | `/Users/Shared/Workspaces/AI/Claude/.claude/agents/agent-teacher/SKILL.md` |
| agent-trainer | `/Users/Shared/Workspaces/AI/Claude/.claude/agents/agent-trainer/SKILL.md` |
| task-agent | `/Users/Shared/Workspaces/AI/Claude/.claude/agents/task-agent/SKILL.md` |
| oosh-expert | `/Users/Shared/Workspaces/AI/Claude/.claude/agents/oosh-expert/SKILL.md` |
| oosh-tester | `/Users/Shared/Workspaces/AI/Claude/.claude/agents/oosh-tester/SKILL.md` |
| scrum-master | `/Users/Shared/Workspaces/AI/Claude/.claude/agents/scrum-master/SKILL.md` |

## Context File Locations

All at: `session/agents/<role>.context.md`

## Priority

Orchestrator recovers first, then Scrum Master, then workers.
