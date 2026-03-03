# otmux Auto-Install tmux on First Call

## Problem

When tmux is not installed and a user runs any otmux command, it fails with an unhelpful error. The `otmux.install()` method exists but must be called explicitly.

## Design

Add a pre-flight tmux check to `otmux.start()` that auto-installs tmux if missing.

### Behavior

1. Every `otmux` invocation checks `command -v tmux` (~1ms, negligible)
2. If tmux is found, proceed normally (no change to current behavior)
3. If tmux is missing, call existing `otmux.install` which:
   - Runs `oo cmd tmux` (oosh-idiomatic package install)
   - Verifies installation
   - Initializes config via `otmux.config.init`
4. If install fails, bail out with non-zero exit

### Implementation

**File:** `otmux`, inside `otmux.start()` (line ~2216)

```bash
otmux.start()
{
  source this

  # Auto-install tmux if missing
  if ! command -v tmux &>/dev/null; then
    otmux.install || return 1
  fi

  if [ -z "$1" ]; then
    otmux.status
    return 0
  fi

  this.start "$@"
}
```

### Tests

**File:** `test/test.otmux`, append T9 and T10 following existing T5-T8 grep pattern.

- **T9:** Verify `otmux.start` contains `command -v tmux` guard
- **T10:** Verify `otmux.install` function is defined

### OOSH Conformance

- Uses `oo cmd tmux` via existing `otmux.install()` for package management
- Uses `command -v` for existence check (same pattern as `oo.cmd` internally)
- Guard clause in `start()` entry point (single point of change)
- No new functions or files — reuses existing infrastructure
