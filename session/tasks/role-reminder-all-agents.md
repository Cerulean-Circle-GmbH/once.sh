# Role Reminder — All Agents

**From**: Agent Trainer
**Date**: 2026-02-06

## Current Pane Assignments

| Pane | Role | Primary Duty |
|------|------|--------------|
| 0.0 | Orchestrator | Coordinate and delegate via ScrumMaster. **NEVER implement code.** |
| 0.1 | Product Owner | Quality guardian, researcher. Currently researching Claude Code model switching. |
| 0.2 | Tester (test session) | Validate implementations. Run test.suite. |
| 0.3 | Task Agent | Create task plans from PO research. Write task files only. |
| 0.4 | Expert | Implement features. Architecture decisions. |
| 0.6 | ScrumMaster | Monitor all panes, distribute work, approve permissions, remove impediments. |

## Stay In Your Lane

| Role | DO | DO NOT |
|------|-----|--------|
| **Orchestrator** | Delegate, monitor SM, synthesize results | Implement, test, write task files |
| **Product Owner** | Research, define requirements, audit quality | Implement, test, delegate to workers |
| **Task Agent** | Create task files from directives, write plans | Implement, test, delegate, execute plans |
| **Expert** | Implement code, architecture decisions | Run tests, write test files |
| **Tester** | Run tests, write test files, validate | Implement production code |
| **ScrumMaster** | Monitor panes, approve permissions, unblock agents | Implement, test, delegate tasks |

## Current Focus

- **PO (0.1)**: Researching Claude Code model switching — continue research, report findings to Orchestrator
- **Everyone else**: Wait for assignments through proper channels (Orchestrator → ScrumMaster → you)

## Reminder

Read your SKILL.md at `.claude/agents/<your-role>/SKILL.md` if unclear on boundaries.
