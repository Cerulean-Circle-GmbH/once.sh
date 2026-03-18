# OO Framework Management Documentation

The `oo` script is the management interface for the oosh environment, providing script creation, version control, package management, and installation utilities.

## Overview

The oo framework supports:
- **Script creation** with templates and completion support
- **Git-based version control** with dev/stage/prod workflow
- **Package manager detection** across multiple platforms
- **External script installation** via symlinks
- **Server setup state machine** for automated deployment
- **Promotion pipeline** for gated code promotion

## Quick Start

```bash
# Create a new oosh script
oo new myscript

# Add a method to existing script
oo new.method myscript.mymethod

# Update oosh from GitHub
oo update

# Check current mode/branch
oo mode
```

## OOSH Lifecycle

The recommended development workflow:

```
1. oo mode.dev        → Switch to dev branch for development
2. oo update          → Pull latest changes from GitHub
3. [develop]          → Make your changes
4. oo commit          → Commit and push to dev branch
5. oo dev.to.testing  → Promote dev to testing (gated by core tests)
6. oo testing.to.prod → Promote testing to prod (gated by platform tests)
7. oo mode.dev        → Return to dev for next cycle
```

## Script Creation

### oo.new

Creates a new oosh script from template with completion support.

```bash
oo new myscript
```

This:
1. Creates `$OOSH_DIR/myscript` from `templates/code/newScript`
2. Makes it executable
3. Automatically creates `test/test.myscript`
4. Prompts to run `reconfigure` for completion

### oo.new.method

Adds a new method to an existing script (interactive).

```bash
oo new.method myscript.mymethod
```

Prompts for:
- Method description and parameters
- Test description
- Test parameters
- Expected test result

### oo.new.test

Creates a test file for a script.

```bash
oo new.test myscript
```

Creates `test/test.myscript` from `templates/code/newScriptTest`.

## Version Control

### oo.mode

Shows current branch status and git remote configuration.

```bash
oo mode
# Output:
# git branch is: * dev
# OOSH_MODE=dev
```

### oo.mode.dev

Switches to the dev branch for development.

```bash
oo mode.dev
```

Sets `OOSH_MODE=dev` and saves to config.

### oo.update

Pulls latest changes from GitHub.

```bash
oo update
```

### oo.commit

Commits and pushes changes (requires dev branch).

```bash
oo commit         # Normal commit (dev branch only)
oo commit force   # Force commit (any branch)
```

### oo.release

Delegates to `promote testing` — promotes dev to testing with gated tests.

```bash
oo release
```

This is a legacy alias. Prefer `oo dev.to.testing` for clarity.

### oo.remote.update

Updates oosh on a remote host via SSH.

```bash
oo remote.update myserver
```

### oo.branches.check

Analyzes branch status for a feature branch workflow.

```bash
oo branches.check feature/ dev/neom abc123
```

Parameters:
- `featureBranchPrefix` - Required prefix for branch names
- `baseBranch` - Base branch to compare against
- `startCommit` - Starting commit for branch analysis

## Package Management

### oo.pm

Shows package manager configuration status.

```bash
oo pm
# Output:
# package manager is set:
# for OOSH: apt-get -y install
# for ONCE: apt-get -y install
```

### oo.pm.discover

Detects OS and sets appropriate package manager.

```bash
oo pm.discover
```

Detects and configures:
| Package Manager | OS |
|----------------|-----|
| `brew install` | macOS |
| `apt-get -y install` | Debian/Ubuntu |
| `apk add` | Alpine |
| `dpkg install` | Debian (dpkg) |
| `pkg install` | FreeBSD |
| `pacman -S` | Arch Linux |

### oo.cmd

Ensures a command is installed, installing it if missing.

```bash
oo cmd wget           # Install wget if missing
oo cmd tree           # Install tree if missing
oo cmd errno python3    # Install python3 for errno
```

Special cases:
- `update` - Runs `apt-get update`
- `errno` - Installs python3
- `eamd`, `oosh`, `once` - Loads from ONCE repository

### oo.find.cmd

Searches apt repositories for a command.

```bash
oo find.cmd htpasswd
```

## Installation

### oo.install

Installs an external oosh script as a symlink.

```bash
oo install myscript /path/to/scripts
```

Creates `$OOSH_DIR/external/myscript` → `/path/to/scripts/myscript`

### oo.deinstall

Removes oosh and cleans up configurations.

```bash
oo deinstall
```

**Warning**: This removes:
- `$HOME/oosh`
- `$HOME/config`
- `$HOME/.once`
- Restores original `.bashrc`

## Server Setup State Machine

### oo.state

Initializes or shows the server setup state machine.

```bash
oo state
```

State machine: `SETUP_SERVER`

States include:
| ID | State | Description |
|----|-------|-------------|
| 11 | remote.install.started | Remote install initiated |
| 12 | local.install.started | Local install initiated |
| 13 | priviledges.checked | User/root privileges verified |
| 20 | user.rights.only | User-only installation |
| 21-24 | user.* | User installation steps |
| 30 | root.rights | Root installation |
| 31-34 | root.* | Root installation steps |
| 40+ | shared/headless/once | Advanced setup stages |

## Promotion Pipeline

The promotion pipeline promotes code through stages: dev → testing → prod, gated by tests.
The pipeline is implemented in the `promote` script with a PROMOTE state machine.
`oo` provides thin wrappers that delegate to `promote`.

See [Promotion Pipeline (promote)](promote.md) for full documentation.

### Promotion Commands (via `oo` wrappers)

```bash
oo dev.to.testing         # Promote dev → testing (gated by tests)
oo dev.to.testing reset   # Restart promotion from scratch
oo dev.to.testing yes     # Skip confirmations (PROMOTE_FORCE)
oo testing.to.prod        # Promote testing → prod
oo promote.status         # Show pipeline state and branch diffs
oo promote.report         # Show promotion history from git tags
```

### Legacy Aliases

```bash
oo release                # Alias for dev.to.testing (legacy)
```

### Direct `promote` Usage

```bash
promote testing           # Same as oo dev.to.testing
promote prod              # Same as oo testing.to.prod
promote status            # Pipeline state and branch diffs
promote report            # Promotion history from tags
```

### State Machine

The PROMOTE state machine has two paths:
- **Testing path** [13]-[18]: uncommitted check → core tests → confirmation → merge → tag → push
- **Prod path** [21]-[25]: platform tests → confirmation → merge → tag → push

The pipeline is **resumable** — if a check fails, the machine stays at that state.
Re-running `promote testing` resumes from the failing step.

See [promote.md](promote.md) for the full state machine layout.

## Utility Commands

### oo.su

Switches to root user for privileged operations.

```bash
oo su
```

If not root, attempts `sudo su`.

### oo.usage

Displays help and usage information.

```bash
oo usage
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `$OOSH_DIR` | Installation directory |
| `$OOSH_MODE` | Current mode (dev/released) |
| `$OOSH_PM` | Package manager command |
| `$OOSH_PM_UPDATED` | Package manager update command |
| `$OS_CMD_GROUP_ADD` | Command to add groups |
| `$OS_CMD_USER_ADD` | Command to add users |

## Templates

Templates are located in `$OOSH_DIR/templates/code/`:

| Template | Purpose |
|----------|---------|
| `newScript` | New oosh script template |
| `newScriptTest` | New test script template |
| `newMethod` | Method template for existing scripts |
| `newMethodTest` | Test method template |

## Usage Examples

### Creating a New Command

```bash
# Create script
oo new mycmd

# Add methods
oo new.method mycmd.hello
oo new.method mycmd.goodbye

# Run tests
test.suite run mycmd

# Enable completion
reconfigure
```

### Setting Up Development Environment

```bash
# Switch to dev mode
oo mode.dev

# Pull latest
oo update

# Check status
oo mode

# Make changes...

# Commit when ready
oo commit
```

### Installing Missing Tools

```bash
# Install common tools
oo cmd git
oo cmd curl
oo cmd jq

# Check package manager
oo pm
```

### Installing External Scripts

```bash
# Install script from external location
oo install myexternal /var/dev/myproject

# Now accessible as:
myexternal method args
```

## Private Functions

Internal functions (not for direct use):

| Function | Description |
|----------|-------------|
| `private.init.state.machine` | Creates SETUP_SERVER state machine |
| `private.check.*` | State validation functions |
| `private.test.sudo.priviledges` | Tests sudo access |
| `private.check.pm` | Tests single package manager |
| `private.check.all.pm` | Tests all package managers |
| `private.install.dev.configs` | Installs dev SSH configs |

## See Also

- [Promotion Pipeline (promote)](promote.md)
- [OS & Platform Testing (os)](os.md)
- [Log System Documentation](log.md)
- [Config System Documentation](config.md)
- [Debug System Documentation](debug.md)
- [State Machine Documentation](state.md)
- [Wiki Index](wiki-index.md)
