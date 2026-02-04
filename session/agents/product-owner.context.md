# Product Owner Agent - Recovery Context

## Role
I am the Product Owner for OOSH. I pass user directives to the Orchestrator (0.0) and keep him unblocked. I do NOT write code, tests, tasks, or SKILL.md files. I only talk to the Orchestrator. My SKILL.md is at `/Users/Shared/Workspaces/AI/Claude/.claude/agents/product-owner/SKILL.md`.

## Working Directory
`/Users/Shared/Workspaces/AI/Claude/components/OOSH/dev.claude/`

## Communication Chain
```
User (human) → PO (me, 0.1) → Orchestrator (0.0) → Scrum Master (0.6) → Workers
```
- I only talk to the Orchestrator
- Orchestrator's #1 priority: prevent context loss on himself and Scrum Master
- Scrum Master's #1 priority: monitor the Orchestrator, then all other agents
- Scrum Master monitors ALL panes including mine for permission prompts

## OOSH Commands Only
| Action | Command |
|--------|---------|
| Send message | `./otmux send <pane> "message" Enter` |
| Send Enter | `./otmux send <pane> "" Enter` |
| Check pane | `./otmux pane.capture <pane> <lines>` |
| Team status | `./hiveMind team.status` |
| Session tree | `./otmux tree` |
| Send to agent by name | `./hiveMind send <name> "message"` |

**NEVER use raw tmux commands.**
**NOTE: `./otmux sendEnter` may be broken — use `./otmux send <pane> "" Enter` instead.**

## Current Team Layout (cursorOrchestrator)
| Pane | Role | Status |
|------|------|--------|
| 0.0 | Orchestrator | Active, compacts frequently |
| 0.1 | Product Owner (me) | Active |
| 0.2 | Agent Trainer | Standing by |
| 0.3 | Task Agent | Active, tracks task board |
| 0.4 | OOSH Expert | Active, implementing tasks |
| 0.5 | OOSH Tester | Active, validating |
| 0.6 | Scrum Master | Active, monitoring all panes |
| 0.7 | Unregistered shell | Needs cleanup or assignment |

## Other tmux Sessions
Run `./otmux tree` to see all sessions. There are 6 total including cursorOrchestrator, __test_existing_25450, claudeWoda, agent, cursorCLI, test_yourself.

## Completed This Session
1. Bootstrapped as PO, read SKILL.md and architecture docs
2. Established communication chain: User → PO → Orchestrator → SM → Workers
3. Taught Orchestrator his priorities (prevent context loss, monitor SM)
4. Orchestrator renamed from agent-teacher (commit f55cd4e)
5. Requested Task Agent role — created at 0.3
6. Fixed multiple stuck prompts across agents (ongoing issue)
7. Directed: object.verb naming convention for all public methods
8. Directed: file-based task communication (task.md is main comms, not messages)
9. Directed: quota monitoring and speed throttling
10. Directed: manual compact (no auto-compact without saving context)
11. Directed: Ctrl+C enforcement chain (PO→Orchestrator, Orchestrator→SM, SM→Workers)
12. Directed: DRY violation detection added to Tester responsibilities
13. Directed: claudeCode helper methods for session ID detection
14. Directed: otmux.tree command — DONE (Task.28, commit b9c2989)
15. Directed: cryptic no-space message formatting fix (Orchestrator AND Task Agent)
16. Directed: session naming via /rename for all Claude sessions
17. Directed: hiveMind sendEnter command (name-based, pane-independent)
18. Directed: hiveMind team.status fake status replacement with real detection
19. Cron job for 7pm Berlin team restart — script was never created (bug found by PO)

## Known Issues
- Pane titles get overwritten by Claude Code subagents (shows task names instead of role names)
- otmux sendEnter may be broken — use `./otmux send <pane> "" Enter` as workaround
- hiveMind send sometimes returns exit code 1
- Orchestrator and Task Agent keep sending cryptic no-space messages despite repeated warnings
- Orchestrator compacts very frequently (burns context fast)
- Pane 0.7 unregistered shell — needs cleanup

## Open Tasks
Task files are at `/Users/Shared/Workspaces/AI/Claude/session/tasks/`. Run `ls` there to see current tasks. Task Agent at 0.3 has the live task board.

## Recovery Steps
1. Read this file
2. Read `/Users/Shared/Workspaces/AI/Claude/.claude/agents/product-owner/SKILL.md`
3. Run `./hiveMind team.status` to see current team
4. Run `./otmux tree` to see all sessions
5. Check Orchestrator (0.0): `./otmux pane.capture cursorOrchestrator:0.0 10`
6. Send Enter if stuck: `./otmux send cursorOrchestrator:0.0 "" Enter`
7. Wait for user input — pass directives to Orchestrator only
