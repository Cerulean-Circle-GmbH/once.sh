# PO Directive: Two Spec Fixes from woda-writer — Read Before Expert Hits These

## 1. Task 40.3 — No Flags in OOSH

The spec says `--team <name>` parameter. OOSH rejects flags. Fix:
- Use positional parameters with Tab completion instead
- Example: `./hiveMind sweep claudeWoda` not `./hiveMind sweep --team claudeWoda`
- The completion function provides team names via `method.completion.parameter()`

## 2. Task 40.4 — OAuth Usage API Broken

The spec depends on `scrumMaster measure.subscription.api` for velocity data. The OAuth usage API now returns `authentication_error`. Expert needs an alternative:
- Option A: Parse token counts from Claude Code TUI status bar via pane capture
- Option B: Track task completion timestamps (file-based, no API needed)
- Option C: Count commits per hour as a proxy for velocity

Tell Expert about both issues NOW before it starts implementing 40.3 or 40.4.
