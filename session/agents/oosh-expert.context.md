# OOSH Expert Agent — Session Context

**Updated**: 2026-02-01T18:30Z
**Role**: OOSH Expert (implementation & architecture)
**Pane**: 0.4 in cursorOrchestrator (team layout: 7 panes)

## Recovery Steps
1. Read this file first
2. Read `.claude/agents/oosh-expert/SKILL.md` at `/Users/Shared/Workspaces/AI/Claude/.claude/agents/oosh-expert/SKILL.md`
3. Read `docs/oosh-architecture.md` for framework reference
4. Check with Agent Teacher for next task

## Completed Work This Session

### Task 2: Fix test/test.hiveMind path issues (DONE — commit 94b8360)
- Added `WORKSPACE_ROOT="${OOSH_DIR}/../../.."` to resolve `.claude/agents/` and `.cursor/skills/` paths

### Task 3: Naming conventions (DONE — commit 94b8360)
- Added `HIVEMIND_WINDOW_NAME`, `private.hiveMind.pane.identify()`, `otmux.pane.title`
- All panes get title + `HIVEMIND_ROLE` env var

### Task 4: Product Owner restructuring (DONE — commit 602d03f)
- Product Owner: first-principles guardian with usability contract
- Script Product Owner: ownership contract (not a role)
- SKILL.md files outside repo at `/Users/Shared/Workspaces/AI/Claude/.claude/agents/`

### Task 5: hiveMind.monitor() (DONE — commit acfde4b)
- Captures last N lines from each pane, dynamic pane list, skips own pane

### Task 6: Bash 3.2 fix + missing methods + PO protocol (DONE — commit 4ce4ca2)
- **Bash 3.2**: Replaced `declare -A HIVEMIND_ROLE_PROMPTS` with `private.hiveMind.get.role.prompt()` case function. All 11 read sites updated. Tests updated.
- **Missing methods**: Added `hiveMind.workers()`, `hiveMind.queen()` stubs. Fixed `hiveMind.list()` and `hiveMind.status()` to guard `agentRoom` with `command -v`.
- **PO Protocol**: Added PO Instantiation Protocol section to agent-teacher SKILL.md (outside repo).

### Task 6 regression: HIVEMIND_AGENTS_DIR path fix (DONE — commit 4ba8523)
- Changed from relative `.claude/agents` to `${OOSH_DIR}/../../../.claude/agents`
- Added fallback in `hiveMind.start()` after `source this`

### otmux session.details (DONE — commit 6837270)
- New method `otmux session.details <session>` — shows windows, panes, titles, commands, dimensions

### Task 7: Fix 4 failing hiveMind tests (DONE — commits 2d9aefb, c2f169e, 4e7b298)
- Added `hiveMind.focus.completion.agentId()` and `hiveMind.spawn.completion.type()`
- Tests 1 & 3 skip gracefully when agentRoom backend not running
- Guard uses output text `grep "not running"` (exit code was unreliable)

### Task 8: Agent navigation by name & tree status (DONE — commits c2c326f, 39353cf)
- **Part A**: `hiveMind team.status` tree output (├──/└── format)
- **Part B**: Agent name registry — file-based at `/tmp/hivemind.roles` (pane titles unreliable — Claude Code overwrites them)
- **Part C**: otmux wrappers — `pane.capture <target> <?lines>`, `pane.send`, enhanced `pane.list <?session>`
- **Part D**: Name resolution — `hiveMind resolve <name>`, `hiveMind send <name> <msg>`, `hiveMind monitor <name>`
- **Part E**: Simplified `hiveMind status` — one-line overview with pane/agent counts
- **UX Fix**: Replaced pane-title-based role lookup with `/tmp/hivemind.roles` registry file
  - `private.hiveMind.registry.set/get/find/list` helpers
  - `private.hiveMind.pane.identify()` writes to registry on assignment
  - `hiveMind.resolve` and `hiveMind.team.status` read from registry

### Task 8 final: Claude Code session ID in team.status (DONE — commit fdfe480)
- New helper `private.hiveMind.pane.session.id()` — resolves session UUID per pane via TTY→PID→command line/lsof chain
- `hiveMind team.status` now shows `[shortId]` (first 8 chars) next to each Claude-running pane
- Detects Claude via both `claude*` and version-string patterns (`[0-9].[0-9]*` — tmux reports Claude version as pane_current_command)
- Session ID discovery: Method 1 parses `--resume <UUID>` from ps; Method 2 reads `~/.claude/tasks/<UUID>/` from lsof

### Task 9: Create Agent Trainer role (DONE — commit de0a992)
- Created `.claude/agents/agent-trainer/SKILL.md` at workspace root (outside repo)
- Role: continuously improve ALL agent SKILL.md files based on team learnings
- Boundaries: ONLY writes agent definition files, does NOT implement/test/architect
- Added `agent-trainer` to `private.hiveMind.get.role.prompt()` case function in hiveMind
- Created `.cursor/skills/agent-trainer` symlink pointing to `../../.claude/agents/agent-trainer`
- Agent Trainer SKILL.md later updated (by Agent Trainer) with OOSH-Only Rule: never use raw tmux, always use `./otmux` and `./hiveMind` wrappers

### ScrumMaster verification: hiveMind.send and hiveMind.monitor (DONE — no changes needed)
- Verified `hiveMind.send()` calls `hiveMind.resolve()` → `private.hiveMind.registry.find()` → `/tmp/hivemind.roles`
- Verified `hiveMind.monitor()` calls `hiveMind.resolve()` for name-based lookup
- Both fully pane-agnostic via registry. No hard-coded pane numbers anywhere.

### Rename agent-teacher registry key to orchestrator (DONE — commit 40e6ffb)
- Consolidated `orchestrator|oosh-orchestrator|agent-teacher` into single case entry with backward-compatible aliases
- All `pane.identify` calls and role prompts now use `"orchestrator"` as registry key
- Directory remains `.claude/agents/agent-teacher/` unchanged
- Updated `spawn.completion.type`, `workers`, `panes`, `roles` display
- Added `agent-trainer` to completion and pane filter lists

### Task 10: Fix otmux sendEnter TUI reliability (DONE — commit 9ec0742)
- **otmux.sendEnter()**: Split into two `send-keys` calls — literal text (`-l` flag) + 50ms delay + Enter separately
  - `-l` flag prevents tmux key name interpretation in message text (e.g., "Escape" or "Up" sent as literal text)
  - 50ms delay between text and Enter gives Claude Code TUI time to process
  - Guards empty text (sends Enter only when no text)
- **New otmux.sendKeys()**: Sends each key argument separately with 50ms inter-key delays
  - Designed for TUI interactions: `./otmux sendKeys <pane> Down Enter`
  - Also available as `./otmux send.tui <pane> Down Enter`
  - ScrumMaster should use this for Claude Code permission/accept-edits prompts

### Task 11: Fix hiveMind send exit code 1 (DONE — commit 9ec0742)
- **Root cause 1**: `info.log` at end of `hiveMind.send()` leaked its exit code — added explicit `return 0`
- **Root cause 2**: `hiveMind.resolve()` lacked explicit `return 0` on success — added it
- **Root cause 3**: After registry rename, `hiveMind send agent-teacher` failed because registry has `orchestrator`
  - Added `private.hiveMind.resolve.alias()` — maps `agent-teacher`/`oosh-orchestrator` → `orchestrator`
  - `hiveMind.resolve()` now falls back to alias lookup when direct registry search fails

### Task 12: Fix hiveMind team.status fake idle detection (DONE — commit 3c8fc00)
- **Problem**: `team.status()` used `pane_active` (tmux pane focus) — all non-focused panes showed "idle" regardless of real activity
- **Fix**: New `private.hiveMind.pane.activity()` helper (hiveMind:171-202) captures last 5 lines of pane content and detects:
  - `permission` — Both "Allow" and "Deny" present (Claude Code tool approval dialog)
  - `idle` — Last non-empty line is input prompt (`>` or `❯`)
  - `active` — Default (generating text, running tools, streaming)
  - `unknown` — Empty pane or capture failed
- Removed unused `pane_active` from tmux format string and read statement
- `permission` state is key for ScrumMaster — shows which panes are blocked on approval

### Task 15: hiveMind send/send.enter pair (DONE — commit 461c6e1)
- Split `hiveMind.send()` into two methods mirroring the otmux send/sendEnter pattern:
  - `hiveMind.send()` — raw keys via `./otmux send` (no Enter appended)
  - `hiveMind.send.enter()` — literal text + Enter via `./otmux sendEnter`
- Both resolve agent name via `hiveMind.resolve()` with completion functions
- Updated `hiveMind.broadcast()` to use `send.enter`
- Fixed `hiveMind.task()` raw `tmux send-keys` → `./otmux sendEnter` (OOSH-Only violation)

### Task 15 additions: task-agent role (DONE — commit 461c6e1)
- Added `task-agent` to `private.hiveMind.get.role.prompt()` case function
- Added to `hiveMind.spawn.completion.type()`
- Added to `hiveMind.panes()` filter grep
- Added to `hiveMind.roles()` display

### Task 16: object.verb notation refactor (DONE — commit 461c6e1)
- `hiveMind.createPane()` → `hiveMind.pane.create()` (definition + 2 callers + error msg + usage text)
- `hiveMind.sendEnter()` → `hiveMind.send.enter()` (definition + 1 caller + error msg + usage text)
- Updated all usage/help text and examples in `hiveMind.usage()`

## Current Team Layout (7 panes)
```
/tmp/hivemind.roles:
cursorOrchestrator:0.0|orchestrator
cursorOrchestrator:0.1|product-owner
cursorOrchestrator:0.2|agent-trainer
cursorOrchestrator:0.3|task-agent
cursorOrchestrator:0.4|oosh-expert      <- this agent
cursorOrchestrator:0.5|oosh-tester
cursorOrchestrator:0.6|scrum-master
```

## Key Architecture Decisions
- **Role registry**: `/tmp/hivemind.roles` — format `session:window.pane|role` per line. Survives Claude Code title overwrites. Written by `private.hiveMind.pane.identify()`, read by `resolve`, `team.status`, `status`. Registry key for Agent Teacher is `orchestrator` (not `agent-teacher`); directory remains `agent-teacher/`.
- **Alias resolution**: `private.hiveMind.resolve.alias()` maps legacy names to canonical registry keys. `hiveMind.resolve()` tries direct lookup first, then alias fallback.
- **Session ID discovery**: `private.hiveMind.pane.session.id()` uses TTY→PID mapping, then checks `--resume` flag in command line, then `lsof` for `~/.claude/tasks/<UUID>/` directory.
- **TUI key sending**: `otmux.sendKeys()` / `otmux.send.tui()` sends keys with 50ms inter-key delays for Claude Code TUI reliability. `otmux.sendEnter()` uses `-l` literal flag + split calls.
- **Bash 3.2**: No `declare -A` — use `private.hiveMind.get.role.prompt()` case function instead.
- **HIVEMIND_AGENTS_DIR**: Computed from `${OOSH_DIR}/../../../.claude/agents` (workspace root is 3 levels up from dev.claude).
- **Activity detection**: `private.hiveMind.pane.activity()` captures pane content (last 5 lines) and pattern-matches for permission prompts, idle prompt, or defaults to active. Used by `team.status()`.
- **send/send.enter pair**: `hiveMind.send()` sends raw keys (no Enter) via `./otmux send`. `hiveMind.send.enter()` sends text+Enter via `./otmux sendEnter`. Mirrors the otmux send/sendEnter pattern.
- **object.verb naming**: All public methods use dot notation. camelCase → dot: `createPane` → `pane.create`, `sendEnter` → `send.enter`.
- **agentRoom guards**: Always check both `command -v agentRoom` AND `agentRoom backend.status` output text.

## Key Rules
- **OOSH-Only**: Never use raw `tmux` commands. Always use `./otmux` and `./hiveMind` wrappers.

## Git Status
- Branch: `dev.claude` — up to date with `origin/dev.claude`
- Latest commit: `461c6e1`
- `session/` directory tracked in git

## Next Tasks (assigned by Agent Teacher)
1. ~~**Fix hiveMind team.status fake idle status**~~ — DONE (commit 3c8fc00)
2. ~~**hiveMind sendEnter command**~~ — DONE (commit 461c6e1)
3. ~~**Object.verb notation enforcement**~~ — DONE (commit 461c6e1)
4. ~~**Add task-agent to hiveMind**~~ — DONE (commit 461c6e1)
5. Awaiting next assignment from Orchestrator

## Pending (not yet assigned)
- Log level fixes NOT implemented (documented in `docs/log-levels-and-testing.md`)
- ossh tests NOT written for config.create fixes
- ScrumMaster noted: `hiveMind.agent.bootstrap()` uses `--dangerously-skip-permissions` at line ~967 — violates NO-SKIP-PERMISSIONS rule
