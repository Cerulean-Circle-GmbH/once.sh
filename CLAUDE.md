# OOSH - Object Oriented Shell

## Context Warning - MANDATORY

**When Claude Code shows a context low warning:**

1. **STOP** all other tasks immediately
2. **UPDATE** `sessions/agent.context.md` with:
   - Completed work this session
   - Pending tasks / current state
   - Key decisions made
   - Any blockers or questions
3. **THEN** proceed with `/compact` or continue

This ensures session state is preserved before context is lost.

---

## Must-Read Documentation

**Read these first for OOSH understanding:**

| Priority | File | Content |
|----------|------|---------|
| 1 | [docs/oosh-architecture.md](docs/oosh-architecture.md) | Complete OOSH reference - OOP concepts, bootstrap, patterns |
| 2 | [docs/wiki-index.md](docs/wiki-index.md) | All documentation links |
| 3 | `sessions/agent.context.md` | Current goals, recent work, recovery steps |

**Tool documentation (read as needed):**
- [docs/log.md](docs/log.md) - Logging system
- [docs/debug.md](docs/debug.md) - Step debugger, traps
- [docs/config.md](docs/config.md) - Configuration persistence
- [docs/state.md](docs/state.md) - State machines
- [docs/oo.md](docs/oo.md) - Script creation

---

## OOSH Wrappers

These scripts wrap external tools with oosh method syntax for easier use:

| Wrapper | Wraps | Common Methods |
|---------|-------|----------------|
| `claudeCode` | Claude Code CLI | `claudeCode session`, `claudeCode resume` |
| `claudeFlow` | Claude Flow orchestration | `claudeFlow tmux.init`, `claudeFlow list`, `claudeFlow swarm.status` |
| `otmux` | tmux terminal multiplexer | `otmux new`, `otmux list`, `otmux attach` |

**Usage pattern:**
```bash
./claudeFlow tmux.init          # Initialize tmux workspace
./claudeFlow list               # List all Claude sessions on host
./claudeFlow list --json        # JSON output
./otmux list                    # List tmux sessions
```

---

## Agent Per-Prompt Checklist

- [ ] **Run tests/commands in tmux lower pane** (see below)
- [ ] **Update `.claude/settings.json` permissions** for any new commands used
- [ ] Update `sessions/agent.context.md` if goals change
- [ ] Keep output clean (no debug pollution)

**Context file:** `sessions/agent.context.md`
**Permissions:** `.claude/settings.json` → `permissions.allow[]`

---

## Tmux Workflow (MANDATORY)

**All Task agents, tests, and long-running commands MUST run in the tmux lower pane.**

```bash
# Setup
./claudeFlow tmux.init    # Creates main (top 70%) + task (bottom 30%)

# Run in lower pane
tmux send-keys -t %28 "./test.suite run state 1" Enter
sleep 5
tmux capture-pane -t %28 -p | tail -30   # Capture output

# Navigation
# Ctrl+b ↑/↓ - Switch between panes
# ./claudeFlow tmux.main - Focus main pane
# ./claudeFlow tmux.lower - Focus task pane
```
