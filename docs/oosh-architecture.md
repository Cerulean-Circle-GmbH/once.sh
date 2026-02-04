# OOSH Architecture - Complete Reference

**Purpose:** Comprehensive OOSH framework documentation
**Location:** `/var/dev/Workspaces/2cuGitHub/once.sh/`

For detailed tool documentation, see [docs/wiki-index.md](wiki-index.md).

---

## Overview - Object-Oriented Shell

OOSH achieves pseudo-object-oriented programming in Bash through **naming conventions** and a **method dispatch system**:

| OOP Concept | OOSH Implementation |
|-------------|---------------------|
| **Class** | Script file (e.g., `config`, `log`, `state`) |
| **Instance** | The script itself when sourced or executed |
| **Methods** | Functions named `scriptname.methodname()` |
| **Constructor** | `scriptname.start()` entry point |
| **Private methods** | Functions prefixed `private.` |
| **Inheritance** | Sourcing other scripts to access their methods |

### Method Naming Convention

```bash
scriptname.method()           # Public API method
scriptname.method.completion.param()  # Tab completion for param
private.helper()              # Internal/private function
```

### Calling Convention

```bash
# CLI (space notation) - executes as subprocess:
./config set VAR value
./state machine.create PDCA

# Inside script (dot notation) - same shell context:
source $OOSH_DIR/config
config.set VAR value
```

---

## Bootstrap System

### Script Entry Point Pattern

Every oosh script ends with this bootstrap pattern:

```bash
#!/usr/bin/env bash

scriptname.method() # <param> # description
{
  # implementation
}

scriptname.start()
{
  source this          # Load oosh kernel
  this.start "$@"      # Dispatch to methods
}

scriptname.start "$@"  # Entry point
```

### Sourcing Order and Dependencies

When a script like `myScript` boots, dependencies load in this order:

```
1. myScript.start "$@"
   │
2. source this                    # OOSH kernel
   │
   ├─ this.init                   # Initialize environment
   │   ├─ Sets OOSH_DIR, OOSH_PROMPT
   │   └─ source $CONFIG          # Load user.env
   │       ├─ export PATH=...
   │       ├─ source log.env      # Log configuration
   │       └─ source oosh.env     # OOSH configuration
   │
   └─ Defines: this.start, this.call, this.load, this.functionExists
   │
3. this.start "$@"                # Dispatch command
   │
4. this.call "method" args        # Resolve and call method
   │
   ├─ Try: method()               # Global function?
   ├─ Try: myScript.method()      # Prefixed function?
   └─ Try: this.load method       # Load from file?
```

### How Debug and Log Boot Correctly

When a script needs `debug` and `log`:

```bash
# Example: myScript sources debug
source $OOSH_DIR/debug

# debug internally sources log (if not loaded):
# debug line 1: source $OOSH_DIR/log

# log provides: info.log, error.log, debug.log, etc.
# debug provides: step(), stackTrace(), setTrap(), etc.

# Dependency chain:
# myScript → debug → log → (log.env for colors/levels)
```

The sourcing is **idempotent** - sourcing the same script twice doesn't duplicate functions because bash simply redefines them.

---

## Core Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        OOSH ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Script File: /path/to/oosh/myScript                           │
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

---

## The Bootstrap System (this)

The file `this` is the OOSH kernel. It provides:

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

### Method Dispatch Chain

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

---

## Key Scripts Reference

| Script | Purpose |
|--------|---------|
| `this` | Core runtime, `this.start()` dispatches commands to methods |
| `oo` | Framework lifecycle, `oo new`, `oo update`, `oo release` |
| `config` | Configuration persistence to `~/config/user.env` |
| `path` | PATH manipulation (`path add`, `path list`, `path remove`) |
| `log` | Logging with levels 1-7 (`console.log`, `info.log`, `error.log`) |
| `debug` | Step debugger, stack traces, trap handlers |
| `line` | Pipe-friendly text processing (`line.split`, `line.join`, `line.filter`) |
| `loop` | List/array operations (`loop list PATH print`) |
| `check` | Validation framework with auto-fix |
| `ossh` | SSH key/config management |
| `state` | State machine for multi-step workflows |
| `user` | User and SSH identity management |

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
export PATH="/root/.local/bin:/root/oosh:..."

source $CONFIG_PATH/log.env
source $CONFIG_PATH/oosh.env
```

---

## Result System

Functions communicate results via variables:

```bash
create.result 0 "success message"
return $(result)
# Caller reads $RESULT and $RETURN_VALUE
```

| Variable | Purpose |
|----------|---------|
| `RETURN_VALUE` | Numeric exit code (like `$?`) |
| `RESULT` | String result from function |
| `RETURN` | Next argument marker for chaining |

---

## Logging System

### Log Levels

| Level | Functions Available |
|-------|---------------------|
| 0 | (silent) |
| 1 | `error.log` |
| 2 | `warn.log`, `important.log` |
| 3 | `console.log`, `success.log` (default) |
| 4 | `info.log` |
| 5 | `debug.log`, `stop.log` (breakpoints) |
| 6+ | Full trace with PS4 |

### Usage

```bash
./log level 5              # Set to debug level
console.log "message"      # Always shows (level > 2)
info.log "message"         # Level > 3
debug.log "message"        # Level > 4
error.log "message"        # Error output
```

See [docs/log.md](log.md) for complete documentation.

---

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `OOSH_DIR` | Root oosh directory | `/root/oosh` |
| `CONFIG` | Path to user.env | `~/config/user.env` |
| `CONFIG_PATH` | Config directory | `~/config` |
| `LOG_LEVEL` | Logging verbosity (0-6) | `3` |
| `LOG_DEVICE` | Log output device | `/dev/tty` |
| `OOSH_PROMPT` | PS1 prefix indicator | `"oosh "` |
| `OOSH_MODE` | Operation mode | `"dev"` |

---

## Completion System

Defined in `templates/user/2c.intsall`:

### Comment Syntax for Completion

```bash
# Format: # <required-param> <?optional-param> # description

myScript.copy() # <source> <dest> <?flags> # copy files from source to dest
{
  # The comment above generates tab completion info
  # <> = required parameter
  # <?> = optional parameter
}

# Custom completion for specific parameter
myScript.copy.completion.flags() {
  echo "-r"
  echo "-v"
  echo "-f"
}
```

---

## Creating New Scripts

```bash
./oo new myscript                    # Create new oosh script from template
./oo new.method myscript.mymethod    # Add method to script
./oo new.test myscript               # Create test file
```

See [docs/oo.md](oo.md) for complete documentation.

---

## Test System

```bash
./test.suite run scriptname 1        # Run tests for script (level 1)
./test.suite all                     # Run all tests
```

### Test Pattern

```bash
source test.suite $*

test.case - "T1: description" \
  scriptname.method args

if [ condition ]; then
  create.result 0 "success message"
else
  create.result 1 "failure details"
fi
expect 0 "success message" "full description"
```

---

## Headless/Non-TTY Usage

The logging system writes to `/dev/tty` by default. For scripts/CI:

```bash
export LOG_DEVICE=/dev/stderr
# or
export LOG_LEVEL=0
```

---

## File Locations

```
$OOSH_DIR/
├── this              # OOSH kernel - bootstrap and dispatch
├── log               # Logging system
├── debug             # Step debugger and traps
├── config            # Configuration management
├── state             # State machine
├── oo                # Framework management
├── line              # Line/string utilities
├── loop              # Loop utilities
├── ng/               # Next-gen commands
│   └── c2            # Completion discovery tool
├── init/             # Initialization scripts
├── external/         # External tool integrations
├── test/             # Test files
├── docs/             # Documentation
└── templates/
    ├── code/         # Script templates
    └── user/
        └── 2c.intsall  # Completion system setup
```

---

## Debugging

```bash
# Increase log level
./log level 5

# Enable step debugging
export STEP_DEBUG=ON
source debug
setTrap

# Check function existence
type -t scriptname.method

# List all script methods
compgen -A function | grep "^scriptname\."
```

See [docs/debug.md](debug.md) for complete documentation.

---

## Quick Command Reference

```bash
# Run a method
./scriptname methodname arg1 arg2

# Get help/usage
./scriptname
./scriptname usage

# Check if oosh is loaded
echo $OOSH_DIR

# Reload configuration
source ~/.bashrc

# Check log level
echo $LOG_LEVEL
```

---

## See Also

- [Wiki Index](wiki-index.md) - All documentation links
- [Log System](log.md) - Logging levels and functions
- [Debug System](debug.md) - Step debugger and traps
- [Config System](config.md) - Environment persistence
- [OO Framework](oo.md) - Script creation
- [State Machine](state.md) - Multi-step workflows
