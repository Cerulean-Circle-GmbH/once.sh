# OOSH — Claude Code Configuration

Read [PROJECT.md](PROJECT.md) for OOSH conventions, testing, and documentation.

## Context Warning — MANDATORY

When Claude Code shows a context low warning:
1. STOP all tasks immediately
2. UPDATE `sessions/agent.context.md` with completed work, pending tasks, decisions, blockers
3. THEN proceed with `/compact` or continue

## Agent Per-Prompt Checklist

- [ ] Run tests/commands in tmux lower pane
- [ ] Update `.claude/settings.json` permissions for any new commands used
- [ ] Update `sessions/agent.context.md` if goals change
- [ ] Keep output clean (no debug pollution)

## Permissions

Update `.claude/settings.json` → `permissions.allow[]` for any new commands used.

## Logging Troubleshooting

If `console.log` produces no output, check `LOG_DEVICE` — should be `/dev/tty`.
See [docs/log.md](docs/log.md) for details.
