# Agent Trainer — Session Context

**Updated**: 2026-02-01
**Role**: Agent Trainer (SKILL.md maintenance only)
**Pane**: assigned dynamically via hiveMind

## Recovery Steps
1. Read this file first
2. Read `.claude/agents/agent-trainer/SKILL.md` at `/Users/Shared/Workspaces/AI/Claude/.claude/agents/agent-trainer/SKILL.md`
3. Read `CLAUDE.md`
4. Check with Orchestrator for pending improvement tasks

## Completed Work This Session

### Task 1: Fix pane number inconsistencies (DONE)
- Verified canonical layout from `hiveMind team.setup.full`: 0.0=Orchestrator, 0.1=ScrumMaster, 0.2=Expert, 0.3=Tester
- Fixed agent-teacher (Expert 0.1->0.2, Tester 0.2->0.3, SM 0.3->0.1)
- Fixed scrum-master (removed phantom TestShell at 0.1, SM 0.4->0.1)
- Fixed oosh-expert (self 0.1->0.2, SM 0.3->0.1)
- Fixed oosh-tester (self 0.2->0.3, SM 0.3->0.1)
- Added runtime resolution notes (`hiveMind resolve <name>`) to all files

### Task 2: Propagate key learnings (DONE)
- Bash 3.2 compatibility added to: oosh-expert, oosh-tester, developer
- Pane title registry added to: agent-teacher, oosh-expert, oosh-tester, developer
- agentRoom exit codes added to: agent-teacher, scrum-master
- OOSH_DIR workspace path added to: oosh-expert, oosh-tester, developer
- LOG_DEVICE troubleshooting added to: developer
- OOSH-Only Rule (no raw tmux) added to ALL 8 files
- Converted 12 raw tmux examples to otmux/hiveMind wrappers

### Task 3: Add Communication sections (DONE)
- Added to: oosh-expert, oosh-tester, developer, product-owner
- Each section defines: receives from, reports to, coordinates with, do-not rules

### Task 4: Add agent-trainer to team table (DONE)
- Added as on-demand role in agent-teacher team table

### Task 5: Enrich developer SKILL.md (DONE)
- Added tmux workflow section with otmux/hiveMind examples
- Added verification step to workflow
- Added log.md and log-levels-and-testing.md to key docs

### Task 6: Add pane registry to scrum-master (DONE)
- Added /tmp/hivemind.roles reference in Key Platform Learnings section

### Task 7: No Skip Permissions rule (DONE)
- Added `## No Skip Permissions (MANDATORY)` to ALL 8 files
- Role-tailored messaging (ScrumMaster detects violations, PO flags in audits)
- Added to agent-trainer Key Learnings to Propagate list
- Noted hiveMind code needs flag removed (action item for Expert)

### Task 8: Rename Agent Teacher to Orchestrator (DONE)
- Updated agent-teacher/SKILL.md: name, title, description, communication chain
- Added Communication Chain: User -> PO -> Orchestrator -> ScrumMaster -> Workers
- Replaced all "Agent Teacher" references across ALL 8 files (replace_all)
- Updated `hiveMind send agent-teacher` -> `hiveMind send orchestrator` in scrum-master
- Updated scrum-master communication chain to include PO quality gate
- Role directory: self-reference now `orchestrator` (directory still `agent-teacher/`)

### Git Setup
- Initialized workspace root repo at `/Users/Shared/Workspaces/AI/Claude/`
- .gitignore: excludes components/ (nested repos), .cursor/ (symlinks), session/ (transient)
- Commit c4ba649: Initial commit with all 8 SKILL.md files + hooks + settings
- Commit f55cd4e: Orchestrator rename across all files

## Pending
- Expert needs to update hiveMind code: register `orchestrator` instead of `agent-teacher`
- Expert needs to remove `--dangerously-skip-permissions` from hiveMind team setup functions
- Standing by for SKILL.md improvement tasks from Orchestrator

## Key Files
- All SKILL.md files: `/Users/Shared/Workspaces/AI/Claude/.claude/agents/*/SKILL.md`
- Workspace git repo: `/Users/Shared/Workspaces/AI/Claude/.git/`
- This context file: `session/agents/agent-trainer.context.md`
