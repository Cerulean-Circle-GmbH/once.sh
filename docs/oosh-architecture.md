# OOSH Architecture - Complete Reference

**Purpose:** Self-training document for context recovery after compression
**Date:** 2026-01-17
**Location:** `/root/oosh/`

---

## Quick Reference - OOSH Essentials

- **OOSH** = "Object-Oriented Shell" - A bash framework making shell scripts behave like objects with methods
- **Core Pattern:** `scriptName.methodName()` functions auto-discovered and callable as `scriptName methodName`
- **Bootstrap File:** `/root/oosh/this` - The kernel that enables all oosh functionality
- **Config Location:** `~/config/user.env` (sourced via `$CONFIG` variable)
- **Key Variable:** `$OOSH_DIR` = `/root/oosh` - Root of all oosh scripts
- **Method Dispatch:** `this.start` → `this.call` → function resolution chain
- **Completion System:** `_oo_completion` in `2c.intsall` - Parses `# comment` annotations for tab completion
- **Logging:** `info.log`, `error.log`, `success.log`, `warn.log`, `debug.log` - Level-controlled output
- **Wrapper Pattern:** Scripts end with `scriptName.start "$@"` which calls `source this` then `this.start`

---

## Table of Contents

1. [Core Architecture](#core-architecture)
2. [The Bootstrap System (this)](#the-bootstrap-system-this)
3. [Method Dispatch Chain](#method-dispatch-chain)
4. [Naming Conventions](#naming-conventions)
5. [Configuration System](#configuration-system)
6. [Logging System](#logging-system)
7. [Completion System](#completion-system)
8. [Creating OOSH Wrappers](#creating-oosh-wrappers)
9. [Key Files Reference](#key-files-reference)
10. [Environment Variables](#environment-variables)

---

## Core Architecture

OOSH transforms bash scripts into "object-like" modules where:

```
┌─────────────────────────────────────────────────────────────────┐
│                        OOSH ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Script File: /root/oosh/myScript                              │
│   ┌─────────────────────────────────────────────────────┐       │
│   │ #!/usr/bin/env bash                                 │       │
│   │                                                     │       │
│   │ myScript.method1() { ... }   ← "Instance methods"   │       │
│   │ myScript.method2() { ... }                          │       │
│   │ myScript.usage() { ... }     ← Help/usage           │       │
│   │                                                     │       │
│   │ myScript.start() {           ← Entry point          │       │
│   │   source this                ← Load oosh kernel     │       │
│   │   this.start "$@"            ← Dispatch to methods  │       │
│   │ }                                                   │       │
│   │                                                     │       │
│   │ myScript.start "$@"          ← Bootstrap call       │       │
│   └─────────────────────────────────────────────────────┘       │
│                                                                 │
│   Invocation: myScript method1 arg1 arg2                        │
│   Resolves to: myScript.method1 arg1 arg2                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Key Principles

1. **Convention over Configuration:** Method names follow `scriptName.methodName` pattern
2. **Self-Documenting:** Comment syntax `# <param> # description` enables auto-completion
3. **Lazy Loading:** Functions loaded on demand via `this.load`
4. **Unified Logging:** All scripts share the same logging infrastructure

---

## The Bootstrap System (this)

The file `/root/oosh/this` is the OOSH kernel. It provides:

### Core Functions

| Function | Purpose |
|----------|---------|
| `this.start` | Main entry point - dispatches commands to methods |
| `this.call` | Resolves and calls `script.method` functions |
| `this.load` | Dynamically loads functions from scripts |
| `this.functionExists` | Checks if a function is defined |
| `this.isSourced` | Detects if script was sourced vs executed |
| `this.init` | Initializes oosh environment |
| `this.path.add` | Adds directories to PATH |

### Bootstrap Sequence

```bash
# When you run: myScript doSomething arg1

1. myScript.start "$@"           # Script's entry point called
   │
2. source this                   # Load oosh kernel
   │
3. this.init                     # Initialize environment
   │  └─ Sets OOSH_DIR, OOSH_PROMPT, etc.
   │  └─ Sources $CONFIG (user.env)
   │
4. this.start "$@"               # Dispatch command
   │
5. this.call "doSomething" arg1  # Resolve method
   │
   ├─ Try: doSomething()         # Global function?
   ├─ Try: myScript.doSomething()# Prefixed function?
   └─ Try: this.load doSomething # Load from file?
```

---

## Method Dispatch Chain

The `this.call` function resolves method calls in this order:

```bash
this.call() {
  local aFunction=$1
  local caller=${BASH_SOURCE[...]}  # Get calling script name

  # Resolution order:

  # 1. Direct function name
  if (this.functionExists $aFunction); then
    $aFunction "$@"
    return
  fi

  # 2. Prefixed with caller name (script.method)
  if (this.functionExists $caller.$aFunction); then
    $caller.$aFunction "$@"
    return
  fi

  # 3. Load from external script
  this.load $aFunction $aShellScript "$@"
}
```

### Example Resolution

```bash
# Command: claudeCode status

claudeCode.start "$@"
  └─ this.start "status"
       └─ this.call "status"
            ├─ status() ?           # No
            ├─ claudeCode.status()  # YES! → Execute
            └─ (not reached)
```

---

## Naming Conventions

### Function Naming

```bash
# Standard method
scriptName.methodName() # <required> <?optional> # Description
{
  # implementation
}

# Completion helper (for tab completion of specific parameter)
scriptName.methodName.completion.paramName() {
  echo "option1"
  echo "option2"
}

# Shorthand alias
scriptName.m() # # shorthand for methodName
{
  scriptName.methodName "$@"
}
```

### Comment Syntax for Completion

```bash
# Format: # <required-param> <?optional-param> # description

myScript.copy() # <source> <dest> <?flags> # copy files from source to dest
{
  # The comment above generates:
  # - Tab completion shows: myScript.copy <source> <dest> <?flags> # copy files...
  # - Parameters in <> are required
  # - Parameters in <?> are optional
}
```

---

## Configuration System

### File Hierarchy

```
~/config/
├── user.env          # Main user configuration (PATH, exports)
├── oosh.env          # OOSH-specific variables
├── log.env           # Logging configuration
├── setup.color.env   # Terminal color definitions
├── result.txt        # Command output capture
└── error.txt         # Error output capture
```

### user.env Structure

```bash
# ~/config/user.env
export BASH_FILE="/usr/local/bin/bash"
export CONFIG="/root/config/user.env"
export CONFIG_FILE="user.env"
export CONFIG_PATH="/root/config"
export PATH="/root/.local/bin:/root/oosh/ng:/root/oosh:.:/root/oosh/init:..."
export OOSH_SSH_CONFIG_HOST="hostname"

source $CONFIG_PATH/log.env
source $CONFIG_PATH/oosh.env
```

### oosh.env Variables

```bash
# ~/config/oosh.env
export OOSH_DIR="/root/oosh"
export OOSH_MODE="dev"
export OOSH_PM="apt-get -y install"      # Package manager
export OOSH_PROMPT="oosh "               # PS1 prefix
export OOSH_SHLVL="4"                    # Shell nesting level
export OOSH_STATUS="0: started in shell level: 1"
```

---

## Logging System

Located in `/root/oosh/log`, provides level-controlled logging:

### Log Levels

| Level | Functions Available |
|-------|---------------------|
| 0 | (silent) |
| 1 | `error.log` |
| 2 | `warn.log`, `important.log`, `problem.log` |
| 3 | `console.log`, `success.log`, `silent.log` (default) |
| 4 | `info.log`, `debug.log` |
| 5 | `stop.log` (breakpoints) |
| 6+ | Full trace with PS4 |

### Log Functions

```bash
error.log "message"      # Red, always shown (level > 0)
warn.log "message"       # Yellow (level > 1)
important.log "message"  # Cyan (level > 1)
success.log "message"    # Green (level > 2)
console.log "message"    # Normal (level > 2)
info.log "message"       # Gray (level > 3)
debug.log "message"      # Cyan (level > 4)
```

### Changing Log Level

```bash
log level 5              # Set to debug level
log level reset          # Toggle back to previous
export LOG_LEVEL=4       # Direct set
```

---

## Completion System

Defined in `/root/oosh/templates/user/2c.intsall`:

### How It Works

```bash
_oo_completion() {
  # 1. Parse current command line
  # 2. Call: $OOSH_DIR/ng/c2 completion.discover ...
  # 3. c2 reads script file, extracts # comments
  # 4. Writes completions to $CONFIG_PATH/completion.result.txt
  # 5. COMPREPLY populated from result file
}

# Registration
complete -F _oo_completion scriptName
```

### Auto-Registration

Scripts in `$OOSH_DIR` are auto-registered:

```bash
add_to_completion() {
  for file in ${path}/*; do
    name=${file##*/}
    if [[ -f "$file" ]]; then
      complete -F _oo_completion $name
    fi
  done
}

add_to_completion ${OOSH_DIR}
add_to_completion ${OOSH_DIR}/external
```

---

## Creating OOSH Wrappers

### Template Structure

```bash
#!/usr/bin/env bash

# ============================================================================
# wrapperName - Description of what this wraps
# ============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# CATEGORY NAME
# ─────────────────────────────────────────────────────────────────────────────

wrapperName.method1() # <required> <?optional> # description
{
  underlying-command subcommand "$@"
}

wrapperName.m1() # # shorthand for method1
{
  wrapperName.method1 "$@"
}

# Completion helper for specific parameter
wrapperName.method1.completion.paramName() {
  echo "value1"
  echo "value2"
}

# ─────────────────────────────────────────────────────────────────────────────
# USAGE
# ─────────────────────────────────────────────────────────────────────────────

wrapperName.usage()
{
  local this=${0##*/}
  echo "Usage documentation here..."
}

# ─────────────────────────────────────────────────────────────────────────────
# BOOTSTRAP
# ─────────────────────────────────────────────────────────────────────────────

wrapperName.start()
{
  source this                    # Load oosh kernel

  if [ -z "$1" ]; then
    wrapperName.status           # Default action
    return 0
  fi

  this.start "$@"                # Dispatch to methods
}

wrapperName.start "$@"           # Entry point
```

### Existing Wrappers

| Wrapper | Wraps | Location |
|---------|-------|----------|
| `claudeCode` | Claude Code CLI | `/root/oosh/claudeCode` |
| `claudeFlow` | Claude Flow orchestration | `/root/oosh/claudeFlow` |
| `otmux` | tmux terminal multiplexer | `/root/oosh/otmux` |

---

## Key Files Reference

### /root/oosh/ Directory Structure

```
/root/oosh/
├── this              # OOSH kernel - bootstrap and dispatch
├── log               # Logging system
├── config            # Configuration management
├── line              # Line/string manipulation utilities
├── loop              # Loop utilities
├── claudeCode        # Claude Code CLI wrapper
├── claudeFlow        # Claude Flow wrapper
├── otmux             # tmux wrapper
├── ng/               # Next-gen commands
│   └── c2            # Completion discovery tool
├── init/             # Initialization scripts
├── external/         # External tool integrations
├── su/               # Superuser-only commands
└── templates/
    └── user/
        └── 2c.intsall  # Completion system setup
```

### Startup Files

```
~/.bashrc
├── Line 8-10: Sets CONFIG variable
├── Line 12-15: Interactive shell guard (IMPORTANT!)
│   └── Non-interactive shells EXIT HERE
├── Line 144-151: Sources $CONFIG (user.env)
└── Line 184: Sources 2c.intsall (completion)

~/config/user.env
├── Exports PATH with oosh directories
├── Sources log.env
└── Sources oosh.env
```

---

## Environment Variables

### Core Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `OOSH_DIR` | Root oosh directory | `/root/oosh` |
| `CONFIG` | Path to user.env | `~/config/user.env` |
| `CONFIG_PATH` | Config directory | `~/config` |
| `LOG_LEVEL` | Logging verbosity (0-6) | `3` |
| `LOG_DEVICE` | Log output device | `/dev/stdout` |
| `OOSH_PROMPT` | PS1 prefix indicator | `"oosh "` |
| `OOSH_MODE` | Operation mode | `"dev"` |

### Return Value Convention

| Variable | Purpose |
|----------|---------|
| `RETURN_VALUE` | Numeric exit code (like `$?`) |
| `RESULT` | String result from function |
| `RETURN` | Next argument marker for chaining |

### Result Functions

```bash
create.result 0 "success message" "$1"  # Set RETURN_VALUE=0, RESULT="success message"
result save                              # Persist result
result.load                              # Retrieve saved result
```

---

## Common Patterns

### Checking Function Existence

```bash
if (this.functionExists myScript.myMethod); then
  myScript.myMethod "$@"
else
  error.log "Method not found"
fi
```

### Sourced vs Executed Detection

```bash
if (this.isSourced); then
  # Script was sourced: `. myScript` or `source myScript`
  return 0
else
  # Script was executed: `./myScript` or `myScript`
  exit 0
fi
```

### Dynamic Method Loading

```bash
this.load methodName scriptFile "$@"
# Loads methodName from scriptFile and executes with args
```

### Path Management

```bash
this.path.add "/new/path"  # Adds to PATH, handles duplicates
```

---

## Debugging Tips

1. **Increase log level:** `log level 5` or `export LOG_LEVEL=5`
2. **Enable trace:** `export SH_OPT="-x"` before running
3. **Check function existence:** `type -t scriptName.methodName`
4. **List all functions:** `compgen -A function | grep scriptName`
5. **View completion results:** `cat $CONFIG_PATH/completion.result.txt`

---

## Quick Command Reference

```bash
# Run a method
scriptName methodName arg1 arg2

# Get help/usage
scriptName
scriptName usage
scriptName help

# Check if oosh is loaded
echo $OOSH_DIR

# Reload configuration
source ~/.bashrc

# Check log level
echo $LOG_LEVEL

# List available methods (after sourcing)
compgen -A function | grep "^scriptName\."
```
