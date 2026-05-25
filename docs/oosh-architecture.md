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
| **Private methods** | `private.script.method()` — hidden from completion AND CLI |
| **Protected methods** | `script.protected.method()` — hidden from completion, callable via CLI |
| **Inheritance** | Sourcing other scripts to access their methods |

### Method Visibility Levels

| Prefix | Tab Completion | CLI Callable | Use Case |
|--------|---------------|-------------|----------|
| (none) | YES | YES | Public API (`hiveMind resolve`) |
| `script.protected.method` | NO | YES | Inter-script events (`hiveMind protected.session.renamed`) |
| `private.script.method` | NO | NO | Internal helpers (`private.hiveMind.agents.discover`) |

### Completion System (Two Types)

| Type | Trigger | How It Works |
|------|---------|-------------|
| **Method completion** | `script [Tab]` | c2 scans script for `scriptname.method()` signatures, filters out `private.`, `.protected.`, and `.completion` |
| **Parameter completion** | `script method [Tab]` | c2 calls `scriptname.method.completion.paramName()` which returns one value per line |

```bash
# Method completion example: hiveMind [Tab]
# c2 scans hiveMind for all public method signatures
# Returns: resolve, send, panes, team.status, agent.monitor, ...

# Parameter completion example: hiveMind resolve [Tab]
# c2 finds hiveMind.resolve has param <agentName>
# Calls hiveMind.resolve.completion.agentName()
# Returns: oosh-expert, oosh-tester, scrum-master, ...
```

### OOSH Naming Standard (MANDATORY)

**One rule: camelCase + dots. No dashes. No underscores. Everywhere.**

This applies to method names, parameter names, variable names, completion
functions, and private helpers. Dashes are a bash syntax error in identifiers.
Underscores are banned for consistency — OOSH uses dots for hierarchy and
camelCase for multi-word names.

#### Method Names: `script.methodName`

Dots separate hierarchy levels. Multi-word segments use camelCase.

```bash
# CORRECT
odocker.file.find()                    # dot-separated hierarchy, camelCase
hiveMind.team.context.status()         # deep hierarchy is fine
scrumMaster.subscription()             # camelCase script name
private.odocker.resolve.image()        # private prefix + dots

# WRONG
odocker.file-find()                    # dash in method name
hive_mind.agent_status()               # underscores
odocker.FILE.FIND()                    # uppercase segments
```

#### Parameter Names: `<camelCase>`

OOSH converts `<paramName>` to bash variable `PARAM_paramName`. Dashes crash bash.
Underscores technically work but are banned for consistency.

```bash
# CORRECT
odocker.file.find() # <containerOrImage> # find Dockerfile
odocker.run() # <image> <?name> # run container
scrumMaster.measure.context() # <agentName> <?session> # measure context

# WRONG — all of these break OOSH or violate convention
odocker.file.find() # <container-or-image> # CRASH: PARAM_container-or-image
ossh.key.create() # <ssh-dir> # CRASH: PARAM_ssh-dir
myScript.run() # <agent_name> # BANNED: use agentName
myScript.find() # <3letterCode> # CRASH: cannot start with number
```

#### Completion Functions: `script.method.completion.paramName`

Must exactly match the parameter name from the method signature.

```bash
# CORRECT — paramName matches in signature and completion function
odocker.file.find() # <containerOrImage> # find Dockerfile
odocker.file.find.completion.containerOrImage() {
  docker ps -a --format '{{.Names}}'
  docker images --format '{{.Repository}}:{{.Tag}}'
}

# WRONG — dash in function name is invalid bash
odocker.file.find.completion.container-or-image() { ... }
```

#### Local Variables: camelCase

```bash
# CORRECT
local imageName wsPath totalCount
local isActive=true

# WRONG
local image_name ws_path total_count    # underscores
local image-name                        # bash syntax error
```

#### Summary Table

| Element | Pattern | Example |
|---------|---------|---------|
| Script file | lowercase or camelCase | `odocker`, `scrumMaster`, `hiveMind` |
| Public method | `script.methodName()` | `odocker.file.find()` |
| Private method | `private.script.methodName()` | `private.odocker.resolve.image()` |
| Parameter | `<camelCase>` | `<containerOrImage>` |
| Completion | `script.method.completion.paramName()` | `odocker.file.find.completion.containerOrImage()` |
| Local variable | `camelCase` | `local imageName` |
| Environment var | `UPPER_SNAKE` (bash convention) | `ODOCKER_WORKSPACES` |

**Environment variables are the one exception** — they follow standard bash
convention (`UPPER_SNAKE_CASE`) because they interact with the shell environment.

**Detection commands:**
```bash
# Find dashes in parameter names
grep -E '# <[a-zA-Z0-9]*-' scriptname

# Find dashes in function names
grep -E '^[a-zA-Z].*-.*\(\)' scriptname

# Find underscores in method names (excluding private. and UPPER_CASE)
grep -E '^[a-z].*_.*\(\)' scriptname
```

### Method Structure Standard (MANDATORY)

**Every public method must have: object.verb name, doc comment, typed parameters,
and completion functions. No exceptions.**

OOSH methods are self-documenting. The framework reads the method signature to
generate help text, tab completion, and parameter validation. A method without
its doc comment and completion function is broken — it won't appear in `this.help`
and won't tab-complete.

#### The Three Required Parts

```bash
#  1. METHOD SIGNATURE — object.verb pattern with typed params and doc comment
#     ┌─ script name    ┌─ required param    ┌─ inline doc comment
#     │                  │                    │
odocker.file.find() # <containerOrImage> # find Dockerfile that built a container or image
{                   #                    └─ description shown in this.help output
  local input="$1"
  # ... implementation ...
}

#  2. COMPLETION FUNCTION — one per parameter that needs tab completion
#     Must match: script.method.completion.paramName
#
odocker.file.find.completion.containerOrImage() {
  docker ps -a --format '{{.Names}}'
  docker images --format '{{.Repository}}:{{.Tag}}'
}

#  3. (Optional params get <?name:default> syntax)
odocker.run() # <image> <?name> # run container from image
```

#### Signature Format

```
script.method() # <required> <?optional> <?optionalWithDefault:value> # description
```

| Token | Meaning |
|-------|---------|
| `<param>` | Required parameter — method fails without it |
| `<?param>` | Optional parameter — has a sensible default |
| `<?param:default>` | Optional with explicit default shown in help |
| `# description` | Final `#` starts the help text for `this.help` |

#### Object.Verb Pattern

Method names follow `object.verb` or `object.noun.verb` — the script is the
subject, the method describes what it does to what.

```bash
# CORRECT — object.verb / object.noun.verb
odocker.file.find()           # odocker finds a file
hiveMind.agent.context.status()  # hiveMind reports one agent's context
hiveMind.team.context.status()   # hiveMind reports all agents' context
scrumMaster.velocity()        # scrumMaster reports velocity
config.set()                  # config sets a value
log.level()                   # log sets the level

# WRONG — verb-first, unclear hierarchy, or missing verb
find.dockerfile()             # verb-first, no script prefix
odocker.dockerfile()          # noun without verb — what does it DO?
odocker.do.thing()            # vague verb
```

#### Completion Function Rules

1. **One completion function per completable parameter**
2. **Name must exactly match**: `script.method.completion.paramName()`
3. **Output**: one completion candidate per line to stdout
4. **No-param methods**: use empty completion `script.method.completion() { :; }`
5. **Private methods**: no completion needed (not user-facing)

```bash
# Method with two completable params — two completion functions
odocker.run() # <image> <?name> # run container from image
{ ... }
odocker.run.completion.image() {
  docker images --format '{{.Repository}}:{{.Tag}}' | grep -v '<none>'
}
# <?name> has no completion — user types it freely

# No-parameter method — empty completion
odocker.ps() # # list running containers
{ ... }
# No completion function needed for parameterless methods
```

#### Checklist for Every New Method

- [ ] Name follows `script.verb` or `script.noun.verb` pattern
- [ ] Signature has `# <params> # description` doc comment
- [ ] All parameter names are camelCase (no dashes, no underscores)
- [ ] Completion function exists for each completable parameter
- [ ] Completion function name matches parameter name exactly
- [ ] Method appears in `this.help` output (verify after adding)

**Detection — find methods missing doc comments:**
```bash
# Methods without inline doc comment (missing # ... #)
grep -E '^[a-z].*\(\)\s*$' scriptname    # no comment at all
grep -E '^[a-z].*\(\)\s*#[^#]*$' scriptname  # only one # (missing description)
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
# Format: # <requiredParam> <?optionalParam> # description

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

## State Correctness (Sprint 1)

OOSH manages a substantial cache layer (S1–S10) that mirrors live tmux/process/display truth (L1–L3). State drift between caches and ground truth is the source of many recurring bugs (ghost agents, stale sessions, "Did/you/mean" garbage). Sprint 1 added architectural prevention: event-driven mutations, ingress hardening, and a reconcile cycle that catches anything events miss.

### Canonical references

- **[docs/state-stores.md](state-stores.md)** — S1–S10 definitions: owner script, writer method, format, mutation paths
- **[docs/invariants.md](invariants.md)** — I1–I10 invariants: detector, severity, fix recipe, dispatch table

### Quick map

| Layer | Source of truth | Examples |
|-------|-----------------|----------|
| **L1** tmux | `tmux list-sessions/panes` | Sessions, windows, panes |
| **L2** process | `ps -eo args` filtered for Claude | Live agent PIDs and UUIDs |
| **L3** display | tmux pane titles, screen window labels | What the operator sees |
| **S1–S10** caches | `~/config/hivemind.*.env`, `~/config/tronMonitor.env`, `~/config/otmux.*.env` | What we believe is true |

Caches MUST converge to L1+L2+L3 via:
1. **Event handlers** (SC-B/SC-C) — primary path; mutations fire events; observers update their stores
2. **Ingress triple defense** (SC-E) — every public method validates caller-supplied identifiers at the boundary (regex + pipe-safe + existence check)
3. **Snapshot integrity** (SC-F) — `# version: 1` header + per-row validation guards save/restore
4. **Reconcile cycle** (SC-A/SC-D) — `scrumMaster.cycle` periodically runs `hiveMind consistency.reconcile apply`, fixing whatever events missed

### Commands at a glance

```bash
# Read-only graded audit (I1–I10) — exit code = violation count
hiveMind consistency.audit [<?session>] [<?format:human|json>]

# Interactive y/N applier
hiveMind consistency.fix [<?session>]

# Silent batch reconcile — dry-run by default per U3 PO-lock
hiveMind consistency.reconcile [<?session>] [<?mode:dry-run|apply>]

# Event introspection
hiveMind events.list             # registered events + handler counts
hiveMind events.history [<?N:50>] # tail event log
```

### Adding a new state-mutating method

Read both docs first. Then:

1. Validate identifiers at the ingress boundary — use kernel predicates `this.isPaneTarget` / `this.isSessionName` / `this.isRoleName` / `this.isUuid` / `this.isSshHost` / `this.isPipeSafe`
2. Go through the canonical writer (`private.hiveMind.registry.set`, `private.hiveMind.session.store`, etc.) — NEVER direct-edit env files
3. Emit the appropriate event after mutation (`private.hiveMind.events.emit`)
4. If introducing a new invariant: add `private.hiveMind.reconcile.check.iN` + table row in `docs/invariants.md` + dispatch arm in `private.hiveMind.reconcile.apply` if auto-fixable

---

## See Also

- [Wiki Index](wiki-index.md) - All documentation links
- [Log System](log.md) - Logging levels and functions
- [Debug System](debug.md) - Step debugger and traps
- [Config System](config.md) - Environment persistence
- [OO Framework](oo.md) - Script creation
- [State Machine](state.md) - Multi-step workflows
- [State Stores](state-stores.md) - S1–S10 reference (Sprint 1)
- [State Invariants](invariants.md) - I1–I10 reference (Sprint 1)
