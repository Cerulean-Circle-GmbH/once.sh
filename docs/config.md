# Config System Documentation

The `config` script provides persistent environment configuration management for oosh, storing variables in `~/config/` directory.

## Overview

The config system supports:
- **Environment variable persistence** to `~/config/user.env`
- **Multiple named config files** for different purposes
- **Variable filtering** by prefix (e.g., OOSH_*, LOG_*)
- **Get/Set operations** for individual variables
- **Config discovery** listing all config files

## Quick Start

```bash
# Initialize config (done automatically by oosh)
./config init

# Save current environment
./config save

# List current config
./config list

# Get/set individual variables
./config get LOG_LEVEL
./config set LOG_LEVEL 5
```

## Configuration Files

| File | Purpose |
|------|---------|
| `~/config/user.env` | Main user configuration (default) |
| `~/config/oosh.env` | OOSH-specific variables |
| `~/config/log.env` | Logging configuration |
| `~/config/<name>.env` | Custom named configs |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `$CONFIG` | `~/config/user.env` | Full path to current config file |
| `$CONFIG_PATH` | `~/config` | Config directory path |
| `$CONFIG_FILE` | `user.env` | Current config filename |

## Commands

### Initialization

#### `config.init`
Initializes the config environment. Creates `~/config/` directory if needed.

```bash
./config init
```

### Saving Configuration

#### `config.save [name] [PREFIX]`
Saves environment variables to a config file.

```bash
# Save to user.env (default)
./config save

# Save OOSH_* variables to oosh.env
./config save oosh OOSH

# Save custom prefix to custom.env
./config save myconfig MYAPP
```

Without parameters, saves:
- All CONFIG_* variables (except per-user dynamic paths — see *Excluded variables* below)
- BASH_FILE
- Then calls `config.save oosh` and `config.save log`

**PATH is intentionally NOT saved** — it must be built dynamically at login by `bashrcTemplate` (`this.path.add` + `OOSH_DIR` guard). Saving root's PATH would overwrite the user's PATH in subprocesses.

**Excluded variables.** `config.save` skips per-user dynamic paths so they don't leak from one user's saved config into another user's environment. The `~/config` symlink usually points at a shared location (`…sharedConfig/`), so a value written by root would otherwise be sourced verbatim by every other user — typically pointing at a path they can't access (EACCES). The exclusion list:

| Variable | Why excluded | Re-derived at shell init by |
|---|---|---|
| `LOG_INSTALL`, `INSTALL_LOG`, etc. | Install-only state — must not persist into user sessions | (none — only set during install) |
| `LOG_LIVE` | `~/config/log.live.out` is per-user; saving root's path EACCES-cascades | `log:21-23` (re-anchored at every bashrc) |
| `CONFIG_PATH` | `$HOME/config` — per-user | `this:209` (`: ${CONFIG_PATH:=$HOME/config}`) |
| `CONFIG` | `$CONFIG_PATH/user.env` — per-user | `config:183` (derived from CONFIG_PATH) |
| `OOSH_DIR` | per-user oosh tree path | `this:40-49` (resolved from script location) |
| `OOSH_COMPONENTS_DIR` | `/tmp/test.oo.*` transient test path — pure noise | (none — set per test run) |

If you add a new persisted env var that resolves to an absolute per-user path, extend the same exclusion filter at `config:265`.

### Listing Configuration

#### `config.list [name]`
Lists the content of a config file.

```bash
# List user.env (default)
./config list

# List specific config
./config list oosh
./config list log
```

### Getting/Setting Variables

#### `config.get <variable>`
Gets an environment variable value.

```bash
./config get LOG_LEVEL
./config get OOSH_DIR
```

#### `config.set <variable> <value>`
Sets or adds an environment variable in the config.

```bash
./config set LOG_LEVEL 5
./config set MY_CUSTOM_VAR "some value"
```

If the variable exists, it's updated. If not, it's appended.

### Managing Config Files

#### `config.file [name|reset]`
Sets or displays the current config file.

```bash
# Show current config file
./config file

# Switch to different config
./config file myconfig.env

# Reset to user.env
./config file reset
```

#### `config.check.file <name>`
Checks if a config file exists and sets it as current.

```bash
./config check.file oosh
# Returns: 0 if exists, 1 if not
```

#### `config.delete <name>`
Deletes a config file.

```bash
./config delete myconfig
# Deletes ~/config/myconfig.env
```

### Adding Configs

#### `config.add <name>`
Adds a config file as a source in user.env.

```bash
./config add oosh
# Appends: source $CONFIG_PATH/oosh.env to user.env
```

#### `config.update <name> [PREFIX]`
Convenience function that saves and adds a config.

```bash
./config update oosh OOSH
# Equivalent to:
#   config.save oosh OOSH
#   config.add oosh
```

### Maintenance

#### `config.clean`
Removes duplicate lines and cleans up the config file.

```bash
./config clean
```

#### `config.discover`
Lists existing config files and their location.

```bash
./config discover
# Output:
# /home/user/config
# user.env
# oosh.env
# log.env
```

### Advanced

#### `config.edit [name]`
Opens config file in vim for editing.

```bash
./config edit
./config edit oosh
```

#### `config.location <path|reset>`
Sets config location to a different path.

```bash
./config location /custom/path/my.env
./config location reset
```

#### `config.ssh.set.config.host <hostname>`
Sets the SSH config host name for prompts.

```bash
./config ssh.set.config.host myserver
```

#### `config.bash.minimal.version <version>`
Sets minimum bash version requirement.

```bash
./config bash.minimal.version 5
```

## Usage Examples

### Initial Setup

```bash
# First time setup (usually done by init/oosh)
./config init
./config save
```

### Custom Application Config

```bash
# Create a config for your app
export MYAPP_DEBUG=1
export MYAPP_SERVER="localhost"
export MYAPP_PORT=8080

# Save all MYAPP_* variables
./config save myapp MYAPP

# Add to user.env so it loads on shell start
./config add myapp

# Verify
./config list myapp
```

### Updating a Variable

```bash
# Set a new value
./config set LOG_LEVEL 5

# Verify the change
./config get LOG_LEVEL

# Apply changes to current shell
source $CONFIG
```

### Backup and Restore

```bash
# Backup current config
cp $CONFIG $CONFIG.backup

# After changes, restore if needed
cp $CONFIG.backup $CONFIG
source $CONFIG
```

## Internal Functions

These functions are used internally and generally not called directly:

| Function | Description |
|----------|-------------|
| `config.path.create` | Creates directory paths (deprecated) |
| `config.folder.create` | Creates single directory (deprecated) |
| `config.string.quote` | Quotes strings for command line |
| `config.info.log` | Logs config at info level |
| `config.completion.*` | Tab completion helpers |

## File Format

Config files use standard bash export format:

```bash
export VARIABLE_NAME="value"
export ANOTHER_VAR="another value"
source $CONFIG_PATH/other.env
```

## Completion Support

The config script provides tab completion for:
- Config file names (list, edit, delete)
- Environment variables (get, set)

## Testing

The config system has tests in `test/test.config`:

```bash
./test.suite run config 1
```

## See Also

- [Log System Documentation](log.md)
- [State Machine Documentation](state.md)
- [Wiki Index](wiki-index.md)
