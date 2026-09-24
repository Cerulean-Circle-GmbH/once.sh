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
scrumMaster.context.measure() # <agentName> <?session> # measure context

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

There are **two forms**, and `c2` tries them in this order for the parameter under the cursor
(`ng/c2` `c2.completion.discover` → `private.call.custom.completion`):

| Step | Function | Form | Use it for |
|------|----------|------|------------|
| 1 | `script.method.completion()` | method catch-all | runs first for EVERY position of that method; only the empty `{ :; }` form is safe on a method with parameters (empty output falls through) |
| 2 | `script.method.completion.paramName()` | **method completion** | a parameter that belongs to this method (`from`, `range`, `a`), or a *specialisation* of a shared type |
| 3 | `script.parameter.completion.paramName()` | **parameter completion** | a **domain type** shared by every method with a parameter of that name (`container`, `image`, `branch`, `dir`) |
| 4 | the signature's `<?param:default>` | default | nothing written |

The model is `odocker`: `odocker.parameter.completion.container` (running containers) is the
default for every `<container>`; `odocker.log.completion.container` specialises it to ALL
containers. Both call a **private list getter** (`private.odocker.container.list.all`), never
each other. A shared completer named after one method's parameter (`a`, `to`) is wrong: it
silently applies to every future method that happens to use the name. An empty method completer
cannot *suppress* a shared one — empty output falls through to step 3.

1. **One completion function per completable parameter** — method form or parameter form, as above
2. **Name must exactly match** the parameter: `script.method.completion.paramName()` / `script.parameter.completion.paramName()`
3. **Output**: one completion candidate per line to stdout; never `create.result` (it runs in completion subshells)
4. **No-param methods**: `oo method.new` generates the empty `script.method.completion() { :; }`; keep it (harmless — it falls through)
5. **Private methods**: no completion needed (not user-facing)
6. **No unpaired `'` in a docstring.** `c2` parses the signature line through `line.unquote`; an
   apostrophe (`<dir>'s repository`) swallows the rest of the line and the parameters are misread,
   so none of them completes. Paired quotes (`'all'`) are fine. Check a script with
   `./c2 signature.validate <script>` (T11 tracks the 37 existing offenders outside `ogit`).

```bash
# Method with two completable params — two completion functions
odocker.run() # <image> <?name> # run container from image
{ ... }
odocker.run.completion.image() {
  docker images --format '{{.Repository}}:{{.Tag}}' | grep -v '<none>'
}
# <?name> has no completion — user types it freely

# A domain type shared by every method with a <container> parameter …
odocker.parameter.completion.container() { private.odocker.container.list.running; }
# … and one method that needs a different set specialises it
odocker.log.completion.container() { private.odocker.container.list.all; }

# No-parameter method — the empty completion oo method.new generates
odocker.ps() # # list running containers
{ ... }
odocker.ps.completion() { :; }
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

An interactive login shell boots by sourcing **`~/config/user.env`** (from
`bashrcTemplate`). That file *is* the boot: its first lines are the anchors
(`OOSH_DIR`, `CONFIG_PATH`, `CONFIG_FILE`, `CONFIG`, `OOSH_USER_CONFIG_PATH`),
the PATH prepend and `BASH_FILE` — pure `export` data, written by `config save`
— and then the `. $CONFIG_PATH/oosh.env` / `. $CONFIG_PATH/log.env` chain. The
bashrc then sources `log` (which sources `this`) and calls `log.session.save`.
See [config.md](config.md) § *user.env is the boot*. A script invoked directly
boots via `source this`:

```
1. myScript.start "$@"
   │
2. source this                    # OOSH kernel
   │
   ├─ cold start (file scope)     # only when CONFIG is empty
   │   └─ . ~/config/user.env     # the boot, as data: anchors, PATH, then
   │       ├─ . oosh.env          #   OOSH configuration
   │       └─ . log.env           #   Log configuration (no per-user chain)
   │   (`log` creates and sources $OOSH_USER_CONFIG_PATH/log.session.env itself)
   │
   ├─ private.this.path.dedup     # the PATH line is data and cannot guard itself
   ├─ this.init                   # re-sources $CONFIG for executed scripts,
   │                              #   saving/restoring PATH and the anchors
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

## The anchors are data

The per-user path anchors are **constants**, and they live as `export` lines at
the head of `~/config/user.env` — written unexpanded, so `$HOME` resolves in
whichever shell sources the file.

```sh
export OOSH_DIR="$HOME/oosh"        # this IS ~/oosh
export CONFIG_PATH="$HOME/config"   # this IS ~/config
```

They are written `"$HOME/oosh"` / `"$HOME/config"` rather than `~/oosh` because
a tilde inside quotes does **not** expand (`OOSH_DIR="~/oosh"` would be seven
literal characters and break every path built from it). `$HOME/oosh` and
`~/oosh` are the same path; `$HOME/oosh` is the form that is safe in POSIX `sh`
and in every quoting context.

### The path-anchor rule

**`OOSH_DIR` is always `~/oosh`** — the user's `oosh` symlink, never the branch
worktree it happens to point at, never a `BASH_SOURCE`/`$0` walk, never
`oo.mode.base.get`.

**`CONFIG_PATH` is always `~/config`** — the user's `config` symlink, never the
shared `sharedConfig` directory it points at.

#### Why that makes it simple

Because the value is the symlink, `OOSH_DIR` is a **constant**. Switching
branches (`oo mode`) moves only what `~/oosh` *points at*; the variable itself
never changes. A constant needs setting in exactly **one** place, so:

- **The `user.env` anchor lines are the single setter** for both. Everything
  else just reads them. `config`'s `private.config.anchor.lines.get` is the one
  emitter that writes those lines; `init/oosh` seeds a byte-identical copy at
  install time (`BEGIN`/`END userEnvSeed`) because POSIX `sh` cannot call the
  bash function.
- The only other assignments are same-literal *fallbacks* for contexts that
  reach a script before any `user.env` was sourced: `this`'s file-scope block
  (`OOSH_DIR`), and `: ${CONFIG_PATH:=$HOME/config}` in `this`, `log` and
  `ossh`.
- `oo.mode`, `oo.mode.setup` and install state 31 do **not** export it —
  repointing the symlink *is* the switch. `mode-env.bash` (written by `oo.mode`
  for the `ooShim` to source into the parent shell) carries only `OOSH_MODE`,
  `hash -r` and the PATH rewrite.
- `ossh.start` uses the same literal. It used to derive from `$0`, which is the
  *host* process whenever `ossh` is **sourced** (`myId`, `config`, `user`,
  `test.ossh`) and so yielded the caller's directory.

#### When you need the physical directory

Resolve it **at that spot** with the portable helper
`private.this.path.canonical` (in `this`) — never bake the resolution into
`OOSH_DIR`. The consumers that do:

| Site | Why it needs the physical path |
|---|---|
| install state 31 `ln -s … oosh` | linking `$OOSH_DIR` itself would create `~/oosh -> ~/oosh` ("Too many levels of symbolic links") |
| install state 31 `OOSH_MODE` | the branch name is `basename` of the *worktree*, not of the symlink |
| `config.init.user` | decides "are we under the shared tree?" with a string-prefix test |
| `promote` | `git worktree list` reports physical paths; a mismatch would stash the same directory twice |
| `oo.mode.base.get` | strategies 3/4 do `dirname`/`basename` — `dirname ~/oosh` is just `$HOME` |

Everything else works fine through the symlink and is deliberately left alone:
every `git -C "$OOSH_DIR" …`, every `$OOSH_DIR/<file>` and
`$CONFIG_PATH/<file>` path join, `private.ensure.groupWrite "$CONFIG_PATH/…"`,
and `ln -s "$path/$class" "$OOSH_DIR/external/$class"`. `CONFIG_PATH` needs
**no** point-of-use fixes at all — nothing in the tree does
`dirname`/`basename`/prefix arithmetic on it, only `-d` / `-f` / `-z` tests,
which all follow a symlink.

#### Sanctioned exceptions

Each is marked in-code with `# <anchor>-exception: <reason>` — or, for a whole
file, `# <anchor>-exception-file: <reason>` — where the slug is the variable
name lower-cased with `_` becoming `-`: `oosh-dir-exception`,
`config-path-exception`.

**`OOSH_DIR`:**

| Site | Why |
|---|---|
| `config`'s anchor-line emitter | it writes the persisted **data** form of the constant — the value *is* `$HOME/oosh`, emitted unexpanded for the sourcing shell |
| `this` file scope | the last-resort fallback before any `user.env` exists (mid-install): the same literal, never a `BASH_SOURCE`/`$0` walk |
| `oo.use` | runs one command **from another branch without switching** — a scoped child-process override; no symlink alternative by design |
| `ossh` remote invoke | a string executed on a **remote** host whose `~/oosh` does not exist yet |
| `user.oosh.install` sub-shell | installs **another user** before their `~/oosh` exists |
| `init/oosh` (file-wide) | the installer runs **before** `~/oosh` exists (it may start from a clone or a ZIP); it self-corrects by moving the repo to `$HOME/oosh`, and `unset`s `OOSH_DIR` before handing off to the login shell |

**`CONFIG_PATH`:**

| Site | Why |
|---|---|
| `config`'s anchor-line emitter, and `init/oosh`'s seed copy | the same persisted data form |
| `this` file scope | defaults the anchor **before** sourcing `user.env`, so a pre-migration file whose `. $CONFIG_PATH/oosh.env` chain has nothing to anchor still resolves |
| `config file <path>` | the one method whose *job* is to leave `~/config` — it points the session at an arbitrary config file, so `CONFIG_PATH` must come from that path |
| install state 31 (×2) | builds the shared tree **before** `~/config` is a symlink to it, so it must name the target directly |
| `this.init` save/restore | restores the value the shell already had across a mid-session `source "$CONFIG"` — a restore, not a new anchor |
| `test.suite.config.isolate` / `.restore` | points one test file at a fixture instead of the site-wide `~/config`, and puts the inherited value back afterwards |

A self-assignment (`CONFIG_PATH=$CONFIG_PATH`, as in `config`'s and
`test.suite`'s usage banners) is not an assignment site — it is a no-op, and a
marker comment there would be *printed to the user*.

#### Enforcement

**`this anchor.validate <all|OOSH_DIR|CONFIG_PATH>`**, with
`this.oosh.dir.validate` and `this.config.path.validate` as the per-anchor
forms. (In an oosh shell `this` is itself a function, so call the method
directly; as a script it is `./this anchor.validate`.) One `git grep` per anchor
over the tracked tree (`docs/`, `test/`, `.claude/` and `*.md`/`*.json`
excluded), classifying every assignment as conforming / exception / violation,
echoing its verdict to stdout (so it survives any `LOG_LEVEL`) and returning
rc 1 on any violation. Covered by `test.this` `T-OOSH-DIR-*` /
`T-CONFIG-PATH-*` — including *planted* violations, so the guard is proven to
fail, and proven to be per-anchor (an `oosh-dir` marker does not exempt a
`CONFIG_PATH` line).

> A shell opened **before** a `config save` on this host still holds whatever
> anchors it booted with. `. ~/config/user.env`, or simply a new shell, fixes
> it.

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
| `this.path.add` | Prepends a directory to **this process's** PATH, de-duping by whole segment. A session-scoped helper — the PATH itself is owned by the `user.env` anchor lines ([config.md](config.md) § *The PATH-writer rule*) |

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
| `path` | PATH reporting and session-local edits (`path list`, `path env`, `path prepend`, `path remove`) plus `path validate`, the PATH-writer sweep. There is no `path add` |
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

Env files are **pure data** — only `export KEY="VALUE"` and `.`-chain lines, no
logic. `config.validate` enforces the no-logic rule.

`user.env` is also the **boot**: the anchors and the PATH prepend are the first
lines of it, written unexpanded so `$HOME` resolves in the sourcing shell. One
shared file is therefore correct for every user on the host.

```bash
# ~/config/user.env  — the anchors, then the POSIX `.` source chain
export OOSH_DIR="$HOME/oosh"
export CONFIG_PATH="$HOME/config"
export CONFIG_FILE="user.env"
export CONFIG="$CONFIG_PATH/$CONFIG_FILE"
export OOSH_USER_CONFIG_PATH="$HOME/.config/oosh"
export PATH="$HOME/oosh:$HOME/oosh/ng:$PATH"
export BASH_FILE="/usr/local/bin/bash"

. $CONFIG_PATH/oosh.env
. $CONFIG_PATH/log.env
```

`oosh.env` and `log.env` are pure `export` data with no chain of their own:

```bash
# ~/config/log.env  (shared)
export LOG_LEVEL="1"
export LOG_LEVEL_RESET="1"
```

The per-user `LOG_NAME`/`LOG_DEVICE`/`LOG_LIVE` live in
`$OOSH_USER_CONFIG_PATH/log.session.env`, which **`log` creates and sources
itself** (the file-scope block at the top of `log`) — the shared `log.env` does not chain it, because a
missing per-user file in a shared chain line aborts dash outright.

Note POSIX `.` (not the bash `source` builtin): every shell sources these files
directly, including a `/bin/sh` login shell and `ossh exec` on Debian, so they
must parse under dash/ash.

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
| `OOSH_DIR` | Root oosh directory — **always** `~/oosh`, the symlink itself (see [The anchors are data](#the-anchors-are-data)) | `~/oosh` |
| `CONFIG` | Path to user.env | `~/config/user.env` |
| `CONFIG_PATH` | Config directory | `~/config` |
| `LOG_LEVEL` | Logging verbosity (0-6) | `3` |
| `LOG_DEVICE` | Log output device | `/dev/tty` |
| `OOSH_PROMPT` | PS1 prefix indicator | `"oosh "` |
| `OOSH_MODE` | Operation mode | `"dev"` |

---

## Completion System

Defined in `templates/user/c2.install`:

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
./oo method.new myscript.mymethod    # Add method to script
./oo test.new myscript               # Create test file
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
        └── c2.install  # Completion system setup
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

## Cross-Platform Install Heals

Two non-obvious dual-site defenses are applied during install. Both are intentional and **must not** be removed by future cleanups thinking they're redundant.

### Alpine / busybox-suid

Naked alpine images ship `/bin/busybox` (which `/bin/su` symlinks to) at mode `0755`. busybox-su needs the binary suid for non-root identity switches; without it, `user login <user>` from a regular user's shell fails with `su: must be suid to work properly`. Real alpine deployments typically ship busybox suid by default — the naked image is the unusual case.

The heal is applied at **both** install entry points:

| Site | Path covered | Why both |
|---|---|---|
| `init/oosh:171–178` | curl one-liner + drag-and-drop. Runs locally as root after `init/oosh`'s sudo re-exec. | Curl-bootstrap doesn't go through `ossh prereqs.install`. Without this site, `user login` would fail post-install on those entry paths. |
| `ossh.prereqs.install` (ossh:2210–2217) | `ossh install <host>` (caller-driven). Runs over ssh+sudo on the remote. | The platform test exercises this path and depends on the heal happening before the `terminal` modifier drops into `bash-user`. |

Both fire under `ossh install <host>` (init/oosh runs on the remote regardless of caller). `chmod u+s` on an already-suid file is a no-op, so the idempotent overlap is intentional.

Verified by `T-OSSH-PREREQS-APK-BUSYBOX-SUID` (test/test.ossh) and `T-INIT-ALPINE-BUSYBOX-SUID` (test/test.install).

### `$SUDO` triple-defense

`$SUDO` is set in **three** places, each covering a distinct code path:

| Site | Path covered |
|---|---|
| `bashrcTemplate:21–25` | Interactive + non-interactive bash that sources bashrc (Debian's `SSH_SOURCE_BASHRC` patch covers ssh-with-command on Ubuntu/Debian/Alma). |
| `this`, the file-scope `# Ensure $SUDO is set` block | Every oosh script invocation that **didn't** go through bashrc — specifically ssh-with-command on Alpine/musl whose bash lacks the `SSH_SOURCE_BASHRC` patch. Self-heals via `id -u`. |
| `bashrcTemplate`, the PS1 conditional (`if [ "$USER" = "root" ]` near the prompt) | Colours the root prompt. It tests `$USER`, not `$SUDO`, and exports nothing — listed because it is the third place a reader will find the root/non-root split. |

Each defends a different code path; same-named variable, different sources of truth.

Verified by `T-THIS-SUDO-SELF-HEAL` (test/test.oo).

### `LOG_LIVE` per-user anchor

In multi-user installs (`~/config` is a shared symlink), the per-user log vars
must never leak into the shared config. `LOG_LIVE` (and `LOG_NAME`/`LOG_DEVICE`)
live in the **per-user** `$OOSH_USER_CONFIG_PATH/log.session.env` (default
`~/.config/oosh/log.session.env`), not in the shared `~/config/log.env`;
`config.save` filters them out of the shared tier. See [Log System](log.md) and
[config.md § two config tiers](config.md) for the read+write defenses.

---

## See Also

- [Wiki Index](wiki-index.md) - All documentation links
- [Log System](log.md) - Logging levels and functions
- [Debug System](debug.md) - Step debugger and traps
- [Config System](config.md) - Environment persistence
- [OO Framework](oo.md) - Script creation
- [State Machine](state.md) - Multi-step workflows
