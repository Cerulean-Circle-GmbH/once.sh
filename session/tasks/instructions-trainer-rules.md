# Instruction: Agent Trainer — Reinforce Two Rules in All SKILL.md Files

**From**: Orchestrator (PO directive)
**To**: Agent Trainer (0.2)
**Priority**: IMMEDIATE

## Rules to Reinforce

### Rule 1: No Garbled Messages

Messages sent between agents via otmux lose their spaces. All agents must follow file-based communication:

- Write detailed instructions to files in `session/tasks/`
- Send only SHORT notifications like: `Read session/tasks/<filename>.md`
- NEVER send long multi-word instructions via `./otmux send` or `./hiveMind send`

Add this to ALL SKILL.md files under Communication section.

### Rule 2: OOSH Commands Only (No Raw tmux)

All agents must use OOSH wrappers, never raw tmux:

| Forbidden | Required |
|-----------|----------|
| `tmux capture-pane -t <pane> ...` | `./otmux pane.capture <pane> <lines>` |
| `tmux send-keys -t <pane> ...` | `./otmux send <pane> <keys>` |
| `tmux split-window` | `./otmux splitV` or `./otmux splitH` |
| `tmux new-session` | `./otmux new <name>` |

This rule already exists in some SKILL.md files but must be reinforced in ALL of them, especially scrum-master/SKILL.md.

## Action Required

1. Update ALL 7 SKILL.md files in `.claude/agents/`
2. Add or reinforce both rules above
3. Commit changes
