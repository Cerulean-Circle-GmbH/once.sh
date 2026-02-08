# Task Agent: Plan claudeCode.model Methods

**From**: PO research findings via Orchestrator
**Priority**: High

## Research Findings

Claude Code supports model switching:

1. **--model flag** at startup: `claude --model opus` or `claude --model sonnet` or `claude --model haiku`
2. **/model slash command** during session: `/model opus`, `/model sonnet`, `/model haiku`

Aliases: `opus`, `sonnet`, `haiku` (no need for full model IDs)

## Your Task

Create a task file planning `claudeCode.model` methods for the OOSH wrapper. Methods to plan:

| Method | Purpose |
|--------|---------|
| `claudeCode.model` | Get current model (if detectable) |
| `claudeCode.model.set <model>` | Send /model command to switch model in running session |
| `claudeCode.model.list` | List available model aliases |
| `claudeCode.start` update | Add optional `--model <alias>` parameter |

## Considerations

- Model detection: May need to parse TUI status bar or send `/model` with no args
- Tab completion: `claudeCode.model.set.completion.model()` should return `opus sonnet haiku`
- Integration: `hiveMind agent.bootstrap` could accept model parameter

## Output

Write task file to: `session/tasks/Task.49.claudeCode-model-methods.md`

Include:
- Problem statement
- Proposed methods with signatures
- Acceptance criteria
- Dependencies (if any)
