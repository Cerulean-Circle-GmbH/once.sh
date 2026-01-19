# OOSH - Object Oriented Shell

## Agent Per-Prompt Checklist

Before responding, especially as context grows:

- [ ] **Run tests/commands in tmux lower pane** (see Tmux Workflow below)
- [ ] **Update `.claude/settings.json` permissions** for any new commands used
- [ ] Update `sessions/agent.context.md` if goals change
- [ ] Keep output clean (no debug pollution)

**Context file:** `sessions/agent.context.md`
**Permissions:** `.claude/settings.json` → `permissions.allow[]`

---

## Tmux Workflow (MANDATORY)

**All Task agents, tests, and long-running commands MUST run in the tmux lower pane.**

### Setup
```bash
./claudeFlow tmux.init    # Creates main (top 70%) + task (bottom 30%)
```

### Running commands in lower pane
```bash
tmux send-keys -t %28 "./test.suite run state 1" Enter
sleep 5
tmux capture-pane -t %28 -p | tail -30   # Capture output
```

### Navigation
- `Ctrl+b ↑/↓` - Switch between panes
- `./claudeFlow tmux.main` - Focus main pane
- `./claudeFlow tmux.lower` - Focus task pane

### Why?
- User can see task progress in real-time
- Main Claude session stays responsive
- Visual separation of concerns

---

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

## State Machine Tool

The `state` tool manages multi-step workflows with validation and branching.

### Current Machine Concept

The state tool tracks a "current machine". Once set, commands operate on it:
```bash
state of PDCA              # Sets PDCA as current machine
state current              # Shows current machine info (machine, state, stateValue, etc.)
state list                 # Lists states of current machine
state next                 # Advances current machine
```

### Command Calling Convention

**Command line** (space notation):
```bash
state machine.create PDCA scrumMaster
state add planning silent
```

**Inside scripts** after sourcing (dot notation):
```bash
source $OOSH_DIR/state
state.machine.create PDCA scrumMaster
state.add planning silent
```

### State Machine Workflow

1. **Create**: `state machine.create PDCA scrumMaster` - creates PDCA, associates script, sets as current
2. **Add states**: `state add planning silent` - adds to current machine, sequentially from slot [11]
3. **Add transitions**: `state add 20 silent` - number value creates jump to state ID 20
4. **Start**: `state machine.start scrumMaster` - starts CURRENT machine, validates script has `private.check.*`
5. **Advance**: `state next` - advances current machine, calls `private.check.<statename>`

### The private.check Pattern

Each state can have a validation function:
```bash
private.check.<statename>() {
  local script=$1; shift
  local stageTo=$1; shift
  local stateFound=$1; shift

  # Return message to continue normally:
  create.result 0 "success"
  return $(result)

  # Or return state ID to branch:
  create.result 0 30  # Jump to state [30]
  return $(result)
}
```

### State Machine Files

- `$CONFIG_PATH/stateMachines/<name>.states.env` - Machine definition
- `$CONFIG_PATH/current.state.machine.env` - Currently selected machine cache

### Key Commands

| Command | Description |
|---------|-------------|
| `state list.machines` | List all machines |
| `state of <machine>` | Select machine as current |
| `state current` | Show current machine info |
| `state name <?machine>` | Get current state name |
| `state id <?machine>` | Get current state ID |
| `state set <?machine> <state>` | Set state directly |
| `state diagnose` | Full diagnostic output |

See [docs/state.md](docs/state.md) for complete documentation.

## File Locations

- `~/config/user.env` - Main user configuration
- `~/.bashrc` - Modified to source oosh on shell start
- `$OOSH_DIR/templates/` - Script and config templates
- `$OOSH_DIR/test/` - Test suite
- `$CONFIG_PATH/stateMachines/` - State machine definitions
