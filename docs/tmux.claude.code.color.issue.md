# Claude Code Color Issue in tmux

## Problem

Claude Code displays in black and white instead of colors when running inside tmux on macOS Terminal.app.

## Root Cause

Two environment variables were causing the issue:

### 1. `NO_COLOR` Environment Variable

A shell configuration file (`~/config/setup.color.env`) defined:

```bash
NO_COLOR=${ESC}"0m"
```

This was intended as a "reset color" escape sequence variable, but **any** non-empty `NO_COLOR` environment variable triggers the [no-color.org](https://no-color.org) standard, which tells CLI applications to disable all colors.

### 2. Missing `FORCE_COLOR`

Even after fixing `NO_COLOR`, Claude Code still didn't show colors because it needs explicit color forcing in some terminal environments.

## Solution

### Fix 1: Rename NO_COLOR Variable

In `~/config/setup.color.env`, renamed:

```bash
# Before (problematic)
NO_COLOR=${ESC}"0m"

# After (fixed)
COLOR_RESET=${ESC}"0m"
```

### Fix 2: Set FORCE_COLOR=1

Added to `~/.tmux.conf`:

```bash
# Set color environment variables for Claude Code and other apps
set-environment -g COLORTERM truecolor
set-environment -g FORCE_COLOR 1
```

Added to `otmux` script:

```bash
# Ensure color support for Claude Code and other modern CLI apps
export FORCE_COLOR=1
export COLORTERM=truecolor
```

### Fix 3: Start Claude Code with Color Environment

When starting Claude Code in tmux, use:

```bash
FORCE_COLOR=1 COLORTERM=truecolor claude
```

Or with the full unset for safety:

```bash
unset NO_COLOR; export FORCE_COLOR=1 COLORTERM=truecolor; claude
```

## Verification

Test if terminal supports colors:

```bash
# In a tmux pane shell:
echo "TERM=$TERM"           # Should be xterm-256color
echo "COLORTERM=$COLORTERM" # Should be truecolor
echo "FORCE_COLOR=$FORCE_COLOR" # Should be 1
tput colors                 # Should output 256
```

Test actual color output:

```bash
echo -e "\e[31mRED\e[0m \e[32mGREEN\e[0m \e[34mBLUE\e[0m"
```

## Environment Variables Summary

| Variable | Value | Purpose |
|----------|-------|---------|
| `TERM` | `xterm-256color` | Terminal type with 256 color support |
| `COLORTERM` | `truecolor` | Indicates true color (24-bit) support |
| `FORCE_COLOR` | `1` | Forces color output in Node.js apps |
| `NO_COLOR` | (unset) | Must be unset - any value disables colors |

## Files Modified

1. `~/config/setup.color.env` - Renamed `NO_COLOR` to `COLOR_RESET`
2. `~/.tmux.conf` - Added `FORCE_COLOR` and `COLORTERM` environment settings
3. `otmux` - Added color environment exports

## Related Links

- [no-color.org](https://no-color.org) - NO_COLOR standard
- [FORCE_COLOR](https://force-color.org) - FORCE_COLOR standard
