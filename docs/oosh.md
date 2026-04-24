# OOSH - Object Oriented Shell

**Purpose:** Quick reference guide for OOSH framework users
**Full Reference:** [oosh-architecture.md](oosh-architecture.md)

---

## What is OOSH?

OOSH (Object Oriented Shell) is a Bash framework that provides:

- **Object-like organization** through naming conventions
- **Method dispatch** via `script.method()` functions
- **Tab completion** for all methods and parameters
- **Consistent CLI patterns** across all tools

---

## Starting an OOSH Shell

After installation, an OOSH shell is any interactive **bash** session — `~/.bashrc`
is what turns a plain bash into an OOSH shell. It sources PATH/config, loads
`_oosh_commands` completions, defines logging functions, and sets `PS1` to the
OOSH prompt.

### From any terminal

```bash
bash              # just type bash — starts an OOSH shell
```

You are in an OOSH shell when you see the prompt:

```
[oosh <hostname>] user@host:~ >
```

and Tab-completion works on OOSH scripts:

```
[oosh MacStudio] donges@MacStudio:~ > otmux <TAB><TAB>
attach      pane.get       send.enter     tree
panes       pane.capture   session.new    tree.detailed
...
```

### From zsh or macOS default-bash (bash 3.2)

macOS ships with zsh as the default shell and bash 3.2 at `/bin/bash`. OOSH needs
bash 5 (installed via homebrew). Starting an OOSH shell from either:

```bash
bash              # picks up homebrew bash 5 via PATH set in ~/.bashrc
```

The first `bash` invocation you see load `finding completions` and `Welcome to
Web 4.0` is the one where OOSH bootstrapped successfully.

### From inside a tmux pane

Same rule: `bash` inside the pane gives you an OOSH shell. This is how
expert/tester shell panes are prepared in a hivemind team.

### From a non-interactive context (scripts, CI, Claude Code Bash tool)

Scripts and the Claude Code Bash tool don't get the `PS1` prompt, but OOSH is
still on `$PATH` via `~/.bashrc`. You can run any OOSH command directly:

```bash
otmux tree            # works — no bash prompt needed
hiveMind resolve ...  # works — PATH already has $OOSH_DIR
```

No `export PATH` or `./scriptname` needed. If PATH is empty (fresh subshell),
source the config explicitly:

```bash
source ~/config/user.env    # loads OOSH_DIR, PATH, log/config env
```

### Troubleshooting

| Symptom | Fix |
|---------|-----|
| `otmux: command not found` | `source ~/config/user.env` or start a new `bash` |
| Prompt doesn't show `[oosh ...]` | You are in zsh or bash 3.2 — type `bash` |
| Tab shows shell commands, not OOSH methods | Completions didn't load; run `bash` again |
| `bash --version` shows `3.2.57` | homebrew bash 5 missing from PATH; source user.env |

---

## Core Concepts

### Classes = Script Files

| Concept | Implementation |
|---------|----------------|
| Class | Script file (e.g., `config`, `log`, `hiveMind`) |
| Method | Function named `scriptname.method()` |
| Private | Function named `private.helper()` |
| Constructor | `scriptname.start()` entry point |

### Calling Methods

```bash
# CLI (space notation):
./scriptname method arg1 arg2

# Inside script (dot notation):
source scriptname
scriptname.method arg1 arg2
```

---

## Method Signature Syntax

```bash
scriptname.method() # <required> <?optional:default> # description
{
  local required="$1"
  local optional="${2:-default}"
}
```

| Syntax | Meaning |
|--------|---------|
| `<param>` | Required parameter |
| `<?param>` | Optional parameter |
| `<?param:value>` | Optional with default |
| `# description` | Help text |

---

## Completion Functions

Provide dynamic completions for parameters:

```bash
# Pattern: scriptname.method.completion.paramName()
hiveMind.focus.completion.agentId() {
  hiveMind.list  # Returns valid agent IDs
}

# For shared parameters across methods:
scriptname.parameter.completion.paramName() {
  echo "option1"
  echo "option2"
}
```

---

## Script Template

Every OOSH script follows this pattern:

```bash
#!/usr/bin/env bash

# Methods
scriptname.method() # <param> # description
{
  # implementation
}

# Entry point
scriptname.start()
{
  source this          # Load OOSH kernel
  this.start "$@"      # Dispatch to methods
}

scriptname.start "$@"  # Bootstrap call
```

---

## Common Tools

| Script | Purpose | Example |
|--------|---------|---------|
| `config` | Configuration persistence | `config set VAR value` |
| `log` | Logging with levels | `info.log "message"` |
| `debug` | Step debugger | `source debug; setTrap` |
| `state` | State machines | `state machine.create PDCA` |
| `otmux` | tmux wrapper | `otmux split` |
| `claudeFlow` | Claude Flow wrapper | `claudeFlow hive.status` |
| `claudeCode` | Claude Code wrapper | `claudeCode list` |
| `hiveMind` | Hive orchestrator | `hiveMind init` |

---

## Logging Levels

```bash
./log level 5          # Set log level

error.log "message"    # Level 1
warn.log "message"     # Level 2
console.log "message"  # Level 3 (default)
info.log "message"     # Level 4
debug.log "message"    # Level 5
```

---

## Creating New Scripts

```bash
./oo new myscript              # Create script from template
./oo new.method myscript.foo   # Add method
./oo new.test myscript         # Create test file
```

---

## Quick Reference

```bash
# Get help
./scriptname                   # Show usage
./scriptname usage             # Same

# Check environment
echo $OOSH_DIR                 # OOSH root directory
echo $LOG_LEVEL                # Current log level

# List methods
compgen -A function | grep "^scriptname\."

# Debug
./log level 5                  # Enable debug output
export STEP_DEBUG=ON           # Enable step debugger
```

---

## See Also

- [Architecture Reference](oosh-architecture.md) - Complete technical details
- [HiveMind](hivemind.md) - Multi-agent orchestration
- [Log System](log.md) - Logging documentation
- [Debug System](debug.md) - Debugging tools
- [State Machine](state.md) - Workflow state management
- [Wiki Index](wiki-index.md) - All documentation
