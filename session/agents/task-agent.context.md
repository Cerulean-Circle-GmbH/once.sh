# Task Agent Context — saved 2026-02-04

## Role

Task Agent for OOSH hiveMind team. I am the **team task board** — I own all task file creation, track status, and report to the Orchestrator.

## SKILL.md Location

`/Users/Shared/Workspaces/AI/Claude/.claude/agents/task-agent/SKILL.md`

## Task File Location

`/Users/Shared/Workspaces/AI/Claude/session/tasks/`

Naming pattern: `Task.{N}.{YYYYMMDDHHMM}.md` (dot separators)

## Critical Rule: No Garbled Messages

**3 words max** in hiveMind send / otmux send. Task files contain details — agents read the file, not the message. See `session/tasks/instructions-taskagent-no-garbled.md` (in dev.claude path).

## Current Board Status

### Done (18 tasks)
- TASK-10 through TASK-17 (legacy naming)
- Task.18 (agent.send, d93fa89)
- Task.19 (file-based comms, d3ddafb/b1e5abb)
- Task.20 (session ID fix, e2b5515)
- Task.22 (context schema CMM3, 7afef99/a351e09)
- Task.23 (auto save CMM3, 9f1180b)
- Task.25 (naming audit CMM3, 04a6587)
- Task.26 (claudeCode status fix, 2eeafbd)
- Task.28 (otmux tree, b9c2989)

### Partially Done (2 tasks)
- Task.24 (Deterministic Recovery CMM3): Steps 1,4 done (c87e96d, Tester PASS). Steps 2-3 pending Agent Trainer SKILL.md updates.
- Task.27 (ScrumMaster Measurement CMM4): Steps 1-8 done (4ae6e56, 14/14 tests). Steps 9-10 pending Trainer + Tester.

### Active
- Task.21 (Task Board Setup) — this session

## Team Status

- Orchestrator: pane 0.0
- Product Owner: pane 0.1
- Agent Trainer: pane 0.2 — has pending work on Task.24 (steps 2-3) and Task.27 (step 9)
- Task Agent (me): pane 0.3
- Expert: pane 0.4 — finished Task.27, pushed 4ae6e56
- Tester: pane 0.5 — at 95% limit, needs reset
- ScrumMaster: pane 0.6

## Recovery Steps

1. Re-read SKILL.md at `/Users/Shared/Workspaces/AI/Claude/.claude/agents/task-agent/SKILL.md`
2. Read this context file
3. Read garbled message instructions at `components/OOSH/dev.claude/session/tasks/instructions-taskagent-no-garbled.md`
4. Check `session/tasks/` for any new task files
5. Report board status to Orchestrator if requested
6. Follow up on Task.24 and Task.27 remaining steps with Agent Trainer
