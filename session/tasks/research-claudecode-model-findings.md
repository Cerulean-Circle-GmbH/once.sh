# Research Findings: Claude Code Model Selection

**From**: Product Owner (research complete)
**For**: Task Agent (create implementation tasks)
**Date**: 2026-02-06

## Summary

Claude Opus 4.6 released. Researched all methods to change models in Claude Code CLI.

## Existing OOSH Support

`claudeCode` wrapper already has model methods (lines 199-229):
- `./claudeCode opus 'prompt'` — uses Opus (now 4.6)
- `./claudeCode sonnet 'prompt'` — uses Sonnet 4.5
- `./claudeCode haiku 'prompt'` — uses Haiku 4.5

**The `opus` alias auto-updates** — already points to 4.6. No urgent changes needed.

## Gaps for Task Agent to Plan

| Gap | Method to Add | Priority |
|-----|---------------|----------|
| Query current model | `claudeCode model.get` | Low |
| Set session default | `claudeCode model.set <alias>` | Low |
| Opus effort level | `claudeCode effort <low\|medium\|high>` | Medium |
| Model info | `claudeCode model.info` — show available models | Low |

## Available Methods (for reference)

| Method | Syntax | Scope |
|--------|--------|-------|
| Slash command | `/model opus` | Current session |
| CLI flag | `claude --model opus` | Single session |
| Environment | `ANTHROPIC_MODEL=opus` | All sessions |
| Settings | `.claude/settings.json` | Project/global |

## Environment Variables

- `ANTHROPIC_MODEL` — default model
- `CLAUDE_CODE_EFFORT_LEVEL` — Opus reasoning effort (low/medium/high)
- `CLAUDE_CODE_SUBAGENT_MODEL` — model for subagents

## Recommendation

Low priority. Existing `./claudeCode opus` works for Opus 4.6. Add effort level method if Opus 4.6 features are needed. Queue behind Tasks 46-48.
