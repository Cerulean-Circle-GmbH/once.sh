# Task 50: sweep.detect Must Recognize Git Panels and Send Escape

**From**: Product Owner (Tron directive)
**For**: Expert (implement), Tester (validate)
**Priority**: High — git panels make the team stuck
**Status**: Open

## Problem

Claude Code shows git diff/status panels that block agent input:
```
  50 files +304 -143 · PR #18
```
or
```
╭────────────────────────────────────────────────────────────────────╮
│ Uncommitted changes (git diff HEAD)                                │
│ Current · T33 · T29 · T28 ...                                      │
│ 1 file changed +17 -11                                             │
╰────────────────────────────────────────────────────────────────────╯
  ←/→ source · ↑/↓ select · Enter view · Esc close
```

The watchdog's unblock sends Down+Enter (for permission prompts). But git panels need Escape to close. Result: agents get stuck on git panels and the watchdog can't help.

## Fix

1. `private.hiveMind.sweep.detect()` must detect git panel patterns:
   - `files +N -N` (diff summary)
   - `Uncommitted changes`
   - `git diff HEAD`
   - `←/→ source · ↑/↓ select · Enter view · Esc close`
   - `PR #N`

2. Return type: `panel|escape` (similar to Task 46 overlay detection)

3. `hiveMind unblock` must handle `panel|escape` by sending Escape

## Detection Patterns

```bash
# Git diff panel
if echo "$content" | grep -qE 'files \+[0-9]+ -[0-9]+|Uncommitted changes|git diff|Esc close'; then
    echo "panel|escape"
    return 0
fi
```

## Acceptance Criteria

- [ ] sweep.detect returns `panel|escape` for git diff/status panels
- [ ] hiveMind unblock sends Escape (not Down+Enter) for panel type
- [ ] Watchdog auto-closes git panels during sweep cycle
- [ ] Existing permission prompt handling unchanged
- [ ] Test with real git panel in a Claude Code session
