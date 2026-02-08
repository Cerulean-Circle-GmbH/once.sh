# PO Directive: Stop Using otmux Directly — Use hiveMind

## Problem

Agents keep using raw otmux commands with hardcoded pane numbers:
```bash
./otmux send cursorOrchestrator:0.4 Enter     # BAD — hardcoded pane
./otmux pane.capture cursorOrchestrator:0.4 10 # BAD — hardcoded pane
```

This breaks when panes are renumbered, added, or removed. It also bypasses the role registry.

## Rule: Use hiveMind for ALL agent communication

hiveMind resolves agent names to panes. Use it instead of otmux:

| Instead of (BAD) | Use (GOOD) |
|-------------------|------------|
| `./otmux send cursorOrchestrator:0.4 "msg" Enter` | `./hiveMind send oosh-expert "msg"` |
| `./otmux pane.capture cursorOrchestrator:0.4 10` | `./hiveMind monitor oosh-expert` |
| `./otmux send cursorOrchestrator:0.6 "" Enter` | `./hiveMind send scrum-master "" Enter` |

## Why

1. **Pane numbers change** — panes get added, removed, renumbered. Hardcoded `0.4` breaks.
2. **Role registry** — hiveMind knows which name maps to which pane. otmux doesn't.
3. **Fewer permissions** — hiveMind commands can be whitelisted once in settings.json.
4. **Self-explaining** — `hiveMind send oosh-expert` is readable. `otmux send cursorOrchestrator:0.4` is not.
5. **First principles** — OOSH wraps tools. hiveMind wraps otmux for agent communication. Use the wrapper.

## Missing hiveMind methods

If hiveMind is missing a method you need, tell the Task Agent to create a task for it. Do NOT fall back to raw otmux. Examples of methods that may be needed:

- `hiveMind monitor <name> [lines]` — capture pane output by agent name
- `hiveMind approve <name>` — send Enter to approve permission prompt
- `hiveMind sweep` — batch monitor all agents (from previous directive)
- `hiveMind unblock <name|all>` — detect and fix blockers

## Enforcement

SM: flag any agent using `./otmux send cursorOrchestrator:0.X` directly. Remind them to use hiveMind.

This is a first-principles violation — same as using raw tmux instead of otmux.
