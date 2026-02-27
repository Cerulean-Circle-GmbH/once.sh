# Log System Documentation

The `log` script provides a comprehensive logging system for oosh with multiple log levels, live logging, color output, and debugging support.

## Overview

The logging system supports:
- **7 log levels** (0-7) controlling output verbosity
- **Multiple output functions** for different message types
- **Live logging** to files for real-time monitoring
- **Color-coded output** for visual distinction
- **Debug breakpoints** for interactive debugging
- **Capture modes** for logging command output

## Log Levels

| Level | Description | Functions Active |
|-------|-------------|------------------|
| 0 | Silent | None |
| 1 | Errors only | `error.log`, `test.console.log`, `test.success.log`, `error.details.log` |
| 2 | + Warnings | + `warn.log`, `important.log`, `problem.log` |
| 3 | + Console | + `console.log`, `success.log`, `silent.log` (default) |
| 4 | + Stop | + `stop.log` |
| 5 | + Debug | + `debug.log` |
| 6 | + Trace | PS4 tracing enabled |
| 7 | + Step | STEP_DEBUG interactive mode |

## Quick Start

```bash
# Set log level
./log level 3

# Or source and use directly
source log
log.level 5
console.log "This is a message"
error.log "This is an error"
```

## Log Functions

### Output Functions

| Function | Min Level | Color | Description |
|----------|-----------|-------|-------------|
| `error.log` | 1 | Red | Error messages, always visible |
| `warn.log` | 2 | Yellow | Warning messages |
| `important.log` | 2 | Cyan | Important notices |
| `problem.log` | 2 | Red | Problem breakpoints |
| `console.log` | 3 | None | General console output |
| `success.log` | 3 | Green | Success messages |
| `silent.log` | 3 | Gray | Subdued messages |
| `stop.log` | 4 | Green | Breakpoint markers |
| `debug.log` | 5 | Cyan | Debug information |

### Test Functions

| Function | Min Level | Description |
|----------|-----------|-------------|
| `test.console.log` | 1 | Console output for tests (lower threshold) |
| `test.success.log` | 1 | Success output for tests |
| `error.details.log` | 1 | Detailed error information |

## Configuration

### Setting Log Level

```bash
# From command line
./log level 5

# From script
source log
log.level 5

# Toggle between current and previous level
log.level reset
```

### Setting Log Device

```bash
# Output to file instead of /dev/tty
log.device /tmp/my.log

# Check current device
log.device
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LOG_LEVEL` | 3 | Current log verbosity |
| `LOG_DEVICE` | /dev/tty | Output destination |
| `LOG_LIVE` | (unset) | Live log file path |
| `LOG_LEVEL_RESET` | - | Previous level for toggle |
| `STEP_DEBUG` | OFF | Interactive debug mode |

## Live Logging

Live logging writes to a separate file for real-time monitoring in another terminal.

### Setup

```bash
# Set live log file
log.live.file ~/config/live.log

# In another terminal, watch the live log
./log live
```

### Live Log Commands

| Command | Description |
|---------|-------------|
| `log.live` | Tail the LOG_LIVE file |
| `log.live.file <path>` | Set LOG_LIVE path |
| `log.live.result` | Tail ~/config/result.txt |
| `log.live.error` | Tail ~/config/error.txt |

### Clear Commands

| Command | Description |
|---------|-------------|
| `log.clear.liveLog [file]` | Clear live log file |
| `log.clear.screen` | Clear terminal screen |
| `log.clear.scrollbackBuffer` | Clear screen + scrollback |
| `log.clear.all` | Clear all log files |

## Capture Mode

Capture mode logs command output to files for later inspection.

```bash
# Capture output to result.txt
capture.log ./my-command arg1 arg2

# Capture silently (no console output)
capture.log.silent ./my-command arg1 arg2

# Inspect results in another terminal
log.inspect         # Tail result.txt
log.inspect.errors  # Tail error.txt

# Clear result files
clear.resultFiles
```

## Debug Mode

### Breakpoints

```bash
# Set a breakpoint (level > 3)
stop.log "Checkpoint reached"

# Problem breakpoint (level > 1)
problem.log "Something unexpected"
```

When `STEP_DEBUG=ON`, execution pauses at breakpoints with an interactive menu:
- `c` - Continue execution
- `p` - Print PATH
- `ll` - List directory
- `q` - Quit

### Trace Mode

At level 6+, PS4 tracing is enabled showing:
```
source_file -> caller_file: function:line - stack
```

## Colors

Colors are initialized from `$CONFIG_PATH/setup.color.env`. Available color variables:

| Variable | Description |
|----------|-------------|
| `NORMAL` | Reset to default |
| `BOLD` | Bold text |
| `GRAY` | Gray text |
| `BOLD_GREEN` | Bold green |
| `BOLD_RED` | Bold red |
| `BOLD_YELLOW` | Bold yellow |
| `BOLD_CYAN` | Bold cyan |
| `BOLD_WHITE` | Bold white |

Initialize colors manually:
```bash
log.init.colors
```

## Usage Examples

### Basic Logging

```bash
source log
log.level 3

console.log "Starting process..."
success.log "Step 1 complete"
warn.log "Disk space low"
error.log "Failed to connect"
```

### Conditional Debug Output

```bash
# Only shows at level 5+
debug.log "Variable x = $x"

# Only shows at level 4+
stop.log "About to call critical function"
```

### Live Monitoring Setup

```bash
# Terminal 1: Set up live logging
log.live.file /tmp/app.log
./my-long-running-script

# Terminal 2: Watch live output
./log live

# Terminal 3: Watch errors only
./log live.error
```

### Capture and Inspect

```bash
# Run tests and capture output
capture.log ./test.suite all

# In another terminal
log.inspect         # Watch progress
log.inspect.errors  # Watch for failures
```

## Testing

The log system has comprehensive tests in `test/test.log`:

```bash
./test.suite run log 1
```

Tests cover:
- Level setting and thresholds
- All output functions
- Live logging
- Clear functions
- Color initialization

## Troubleshooting

### No Output from console.log or important.log

If `console.log` or `important.log` produce no visible output, check `LOG_DEVICE`:

```bash
# Check current device
echo $LOG_DEVICE

# If it's pointing to a file (e.g., /tmp/test.log.device.12345)
# Reset to terminal:
log device /dev/tty

# Start a new shell to pick up the change
exit
bash
```

**Why this happens:**
- All logging functions write to `$LOG_DEVICE`
- Default is `/dev/tty` (the terminal)
- During testing, it may be redirected to a temp file for capture
- The `log device` command persists to `~/config/log.env`

### Understanding LOG_DEVICE and LOG_LIVE

| Variable | Purpose | Default |
|----------|---------|---------|
| `LOG_DEVICE` | Where log output goes (terminal or file) | `/dev/tty` |
| `LOG_LIVE` | Additional file for live monitoring | (unset) |

The logging functions use `tee` to write to both destinations when `LOG_LIVE` is set:
1. Primary output → `LOG_DEVICE`
2. Duplicate for monitoring → `LOG_LIVE`

### Checking Log Configuration

```bash
# Show all log settings
cat ~/config/log.env

# Key variables to check:
# LOG_DEVICE - should be /dev/tty for terminal output
# LOG_LEVEL - should be 3 (default) for console.log to work
# LOG_LIVE - optional, for real-time file capture
```

### Reset to Defaults

```bash
# Reset log device to terminal
log device /dev/tty

# Reset log level to default
log level 3

# Start fresh shell
exit && bash
```

## Install Logging

Install logging captures a full-density log of every oosh log call during an install, regardless of `LOG_LEVEL`. This is useful for post-mortem debugging of failed installs.

### Default LOG_LEVEL During Install

During installation, `LOG_LEVEL` defaults to **1** (errors only) — keeping the terminal quiet while `LOG_INSTALL` captures everything to file. Interactive sessions default to **3** (set by `this` and `oo`).

To override for a verbose install:

```bash
./ossh install <host> <user> 5    # LOG_LEVEL=5 for debug output
```

### Environment Variable

| Variable | Default | Description |
|----------|---------|-------------|
| `LOG_INSTALL` | (unset) | Path to install log file. When set, all log functions append to this file unconditionally. |

### Lifecycle

```bash
# Start install logging (creates file, sets LOG_INSTALL)
log.install.init ~/config/install.log

# ... run install process ...
# All log functions (console.log, error.log, etc.) automatically
# append full-density entries to $LOG_INSTALL

# Finalize (writes summary, unsets LOG_INSTALL)
log.install.finish
```

### Inspection Methods

| Command | Description |
|---------|-------------|
| `log.install` | View the full install log (`cat`) |
| `log.install.errors` | Show only ERROR lines from the install log |
| `log.install.live` | Follow the install log in real-time (`tail -f`) during an active install |
| `log.install.init [path]` | Start install logging to a file |
| `log.install.finish` | Finalize the install log and report summary |

### Usage Examples

```bash
# After an install completes, view the log
./log install

# Check for errors only
./log install.errors

# During an install, follow in another terminal
./log install.live
```

### Remote Inspection

When using `ossh` to install on remote servers, the install log can be inspected via:

```bash
ossh install.log    # View install log from remote server
```

## See Also

- [State Machine Documentation](state.md)
- [First Principles](first-principles.md)
- [Wiki Index](wiki-index.md)
