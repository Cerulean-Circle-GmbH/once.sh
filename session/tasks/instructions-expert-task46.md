# Expert: Task 46 — sweep.detect Background Tasks Overlay

**Task file**: `session/tasks/Task.46.sweep-detect-background-overlay.md`
**Priority**: High — do AFTER Task 48

## Problem

Claude Code's "Background tasks" overlay panel gets misidentified. `unblock` sends Down+Enter (for permissions) when it should send Escape to close the overlay.

## What to Build

### 1. New detection in `private.hiveMind.sweep.detect()`

Add BEFORE permission detection (overlay is more specific):
```bash
if echo "$content" | grep -q 'Background tasks'; then
    echo "overlay|escape"
    return 0
fi
```

### 2. Update `unblock.pane` to handle overlay type

The action for `overlay` should send Escape instead of Down+Enter:
- `permission|enter` → Down Enter (existing)
- `overlay|escape` → Escape (new)
- `accept-edits|enter` → Enter (existing from 40.2)

## Acceptance Criteria
- [ ] sweep.detect returns `overlay|escape` for background tasks panel
- [ ] hiveMind unblock sends Escape (not Down+Enter) for overlay type
- [ ] Existing permission prompt handling unchanged
- [ ] `bash -n hiveMind` passes

## When Done
Commit and report: `Task 46 done`
