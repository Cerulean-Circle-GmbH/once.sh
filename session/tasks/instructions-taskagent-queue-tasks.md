# Task Agent Directive: Queue Pending Tasks

**From**: PO via Orchestrator
**Priority**: Do this now

Create task files for the following items. Use the naming convention `Task.{N}.{YYYYMMDDHHMM}.md` in `session/tasks/`.

## Tasks to Create

### Task 30: Fix Enter Submission Issue (HIGH PRIORITY)

**Problem**: When sending prompts to agent panes via `./otmux send <pane> 'text' Enter`, the text lands in the Claude Code input bar but Enter does NOT submit it. This happens consistently across ALL panes. The Orchestrator and SM have to send a second `Enter` every time.

**Root cause investigation needed**:
- Is it a timing issue? (text arrives, Enter arrives before text is rendered)
- Is it a Claude Code TUI issue? (Enter key handled differently when input bar has content)
- Does `./otmux send.enter` (which uses `-l` flag) behave differently from `./otmux send ... Enter`?
- Does adding a `sleep 0.1` between text and Enter fix it?

**Assigned to**: oosh-expert
**Test by**: oosh-tester

### Task 31: Add Monitoring Commands to settings.json Permissions

**Problem**: Permission prompts are the #1 cause of team stalls. Common monitoring commands trigger prompts every time.

**Fix**: Add to `.claude/settings.json` → `permissions.allow[]`:
- `./otmux pane.capture *`
- `./otmux send *`
- `./hiveMind send *`
- `./hiveMind monitor *`
- `./hiveMind team.status`
- `./hiveMind resolve *`
- `./otmux tree`
- `sleep *`
- `bash -n *`

**Assigned to**: oosh-expert (already assigned, may be in progress)

### Task 32: Validate otmux pane.lock Feature

**Problem**: Expert implemented `otmux pane.lock` to prevent Claude Code from overwriting tmux pane titles. Needs tester validation.

**Validate**:
- `./otmux pane.lock <pane> <title>` sets title and locks it
- `./otmux pane.unlock <pane>` re-enables renaming
- Title persists after Claude Code runs a Task tool
- Tab completion works
- `./otmux tree` shows clean role names

**Assigned to**: oosh-tester

## Signal when done

For each task file created, signal: `TASK PLAN READY: session/tasks/Task.{N}.{YYYYMMDDHHMM}.md`
