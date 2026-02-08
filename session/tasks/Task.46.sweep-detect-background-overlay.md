# Task 46: sweep.detect Must Recognize Background Tasks Overlay

**From**: woda-writer (Ch7-Ch8 observation, via PO)
**For**: Expert (implement), Tester (validate)
**Priority**: High
**Status**: Open

## Problem

Claude Code shows a "Background tasks" overlay panel:
```
 Background tasks

 No tasks currently running

 ↑/↓ to select · Enter to view · Esc to close
```

`hiveMind unblock` sends Down+Enter (option 2 for permissions). But on a background tasks overlay, Down+Enter does the wrong thing. The correct action is Escape to close the panel.

## Fix

1. `private.hiveMind.sweep.detect()` must detect the background tasks overlay pattern
2. Return a new type: `overlay|escape` (not `permission|enter`)
3. `hiveMind unblock` must handle `overlay|escape` by sending Escape instead of Down+Enter

## Detection Pattern

```bash
if echo "$content" | grep -q 'Background tasks'; then
    echo "overlay|escape"
    return 0
fi
```

## Acceptance Criteria

- [ ] sweep.detect returns `overlay|escape` for background tasks panel
- [ ] hiveMind unblock sends Escape (not Down+Enter) for overlay type
- [ ] Existing permission prompt handling unchanged
- [ ] Test with real background tasks overlay
