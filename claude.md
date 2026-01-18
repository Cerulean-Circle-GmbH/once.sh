# OOSH - Object Oriented Shell

## Overview

OOSH is a bash framework that provides pseudo-object-oriented programming through naming conventions. Each script acts as a "class" with methods following the pattern `scriptname.methodname()`.

## Architecture

```
init/oosh (bootstrap)
    ↓
this (core runtime, function loading)
    ↓
oo (framework management)
    ↓
config (environment persistence)
    ↓
Individual scripts sourced on-demand
```

## Key Scripts

| Script | Purpose |
|--------|---------|
| `this` | Core runtime, `this.start()` dispatches commands to methods |
| `oo` | Framework lifecycle, `oo new`, `oo update`, `oo release` |
| `config` | Configuration persistence to `~/config/user.env` |
| `path` | PATH manipulation (`path add`, `path list`, `path remove`) |
| `log` | Logging with levels 1-7 (`console.log`, `info.log`, `error.log`) |
| `line` | Pipe-friendly text processing (`line.split`, `line.join`, `line.filter`) |
| `loop` | List/array operations (`loop list PATH print`) |
| `check` | Validation framework with auto-fix |
| `ossh` | SSH key/config management |
| `state` | State machine for multi-step workflows |
| `user` | User and SSH identity management |

## Script Pattern

Every oosh script follows this structure:

```bash
#!/usr/bin/env bash

### new.method

scriptname.method() # <param> # description
{
  local arg1="$1"
  shift
  # ... implementation
}

scriptname.usage()
{
  echo "Usage: ..."
}

scriptname.start()
{
  source this
  this.start "$@"
}

scriptname.start "$@"
```

## Key Patterns

### 1. Self-Sourcing Scripts
Each script sources `this` in its `.start()` function. You call scripts directly:
```bash
./path add /some/path      # NOT: source this && path add
./config save              # The script handles sourcing internally
```

### 2. Function Naming Convention
- `scriptname.method()` - Public API
- `scriptname.method.completion.param()` - Tab completion for param
- `private.helper()` - Internal functions

### 3. Result System
```bash
create.result 0 "success message"
return $(result)
# Caller reads $RESULT and $RETURN_VALUE
```

### 4. Pipe-Friendly Utilities
```bash
echo $PATH | line.split ":" | line.filter "/usr" | line.join ":"
```

## Common Commands

### Path Management
```bash
./path list                    # Show PATH entries
./path add /new/path          # Append to PATH
./path prepend /new/path      # Prepend to PATH
./path remove /old/path       # Remove from PATH
```

### Configuration
```bash
./config save                 # Save current env to ~/config/user.env
./config list                 # Show current config
./config set VAR value        # Set environment variable
./config get VAR              # Get environment variable
```

### Creating New Scripts
```bash
./oo new myscript             # Create new oosh script from template
./oo new.method myscript.mymethod  # Add method to script
```

### Logging
```bash
source log
log.level 5                   # Set verbosity (1-7)
console.log "message"         # Always shows
info.log "message"            # Level > 3
debug.log "message"           # Level > 5
error.log "message"           # Error output
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `$OOSH_DIR` | Installation directory |
| `$CONFIG` | Full path to user.env |
| `$CONFIG_PATH` | Config directory (`~/config`) |
| `$LOG_LEVEL` | Logging verbosity (1-7) |
| `$LOG_DEVICE` | Log output device (default: `/dev/tty`) |

## Adding to PATH Example

To add a directory to PATH permanently:
```bash
cd /path/to/oosh
./path add /root/.local/bin
# This:
# 1. Adds to current $PATH
# 2. Saves to ~/config/user.env via config save
# 3. Tells you to run: reconfigure
```

## Tab Completion

OOSH provides dynamic completion. After installation:
```bash
./oo [TAB]           # Shows all oo methods
./path [TAB]         # Shows all path methods
./config list [TAB]  # Shows config file completions
```

## Headless/Non-TTY Usage

The logging system writes to `/dev/tty` by default. For scripts/CI:
```bash
export LOG_DEVICE=/dev/stderr
# or
export LOG_LEVEL=0
```

## File Locations

- `~/config/user.env` - Main user configuration
- `~/.bashrc` - Modified to source oosh on shell start
- `$OOSH_DIR/templates/` - Script and config templates
- `$OOSH_DIR/test/` - Test suite
