# Product Owner Agent - Recovery Context

**Updated**: 2026-02-08T12:00Z

## Role
I am the Product Owner for OOSH and **Tron's sole interface**. Tron communicates only with me. I delegate to the team. I do NOT write code, tests, or SKILL.md files.

## Key Rules
- **cursorOrchestrator ONLY** — do NOT interact with claudeWoda unless they explicitly ask
- Team reports to Orchestrator, NOT to PO pane
- Watchdog handles sweep/unblock automatically

## Working Directory
`/Users/Shared/Workspaces/AI/Claude/components/OOSH/dev.claude/`

## Communication Chain
```
Tron (human) → PO (me, 0.1) → Orchestrator (0.0) → SM (0.6) → Workers
```

## Watchdog
Running at PID 59916 (or newer). Auto-sweeps every 30s, handles:
- Permission prompts → Down+Enter (option 2)
- Git panels → Escape
- Background overlays → Escape

## Tasks Completed This Session
- Tasks 40.1-40.5: CMM4 implementation (multi-team, sweep.detect, velocity, feedback loop)
- Task 41: sweep.detect Yes/No format
- Task 42: DRY session ID detection
- Task 43: hiveMind.resolve multi-session
- Task 44: Subscription API auth debug (in progress)
- Task 45: unblock option 2 + all sessions
- Task 46: Background overlay detection
- Task 48: Watchdog (bootstrap paradox fix)
- Task 50: Git panel detection

## Known Issue
OOSH `this.load` breakpoint bug — `otmux list` triggers "PROBLEM BREAKPOINT" when dispatch fails to find method. Needs Expert fix.

## Recovery Steps
1. Read this file + SKILL.md
2. Run `./hiveMind sweep cursorOrchestrator` (NOT claudeWoda)
3. Check watchdog: `./hiveMind watchdog.status`
4. If agents stuck: `./hiveMind unblock all cursorOrchestrator`
5. Wait for Tron input
