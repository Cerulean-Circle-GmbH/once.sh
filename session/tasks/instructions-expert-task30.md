# Expert: Task 30 — Fix Enter Submission Issue (HIGH PRIORITY)

**This is the #1 team bottleneck.** Every prompt sent via `./otmux send` requires a second Enter.

## Full spec

Read: `/Users/Shared/Workspaces/AI/Claude/session/tasks/Task.30.202602041507.md`

## Quick summary

`./otmux send <pane> 'text' Enter` delivers text but Enter doesn't submit. Investigate:
1. Timing — does `sleep 0.1` between text and Enter fix it?
2. `-l` flag — does `send.enter` behave differently?
3. Separate calls — does sending text first, then Enter separately work?
4. Claude Code TUI — does it buffer input and ignore rapid Enter?

Fix it in `otmux send` so one call submits reliably. Commit when done.
