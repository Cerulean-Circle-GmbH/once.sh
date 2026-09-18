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
| `~/config/log.env` | Logging configuration (shared: `LOG_LEVEL`, `LOG_LEVEL_RESET`) |
| `~/config/<name>.env` | Custom named configs |
| `$OOSH_USER_CONFIG_PATH/log.session.env` | **Per-user** log identity/session (`LOG_NAME`, `LOG_DEVICE`, `LOG_LIVE`) |

> **Tests must never write the shared tier.** It is site-wide: a test that reaches `config save`
> rewrites `user.env` / `oosh.env` / `log.env` for every user on the box. Use
> `test.suite.config.isolate` — see [test-suite.md](test-suite.md) § *Isolating a test from the
> shared config*. You will not get away with forgetting: the runner fingerprints those three files
> around every test file, names the offender, restores the tier and fails the run — see
> [test-suite.md](test-suite.md) § *The runner guards the shared config tier*.

### Two config tiers: shared vs per-user

`~/config` (`$CONFIG_PATH`) usually symlinks to one shared `sharedConfig`
directory, so everything in it is **shared across all users** — only site-wide
data belongs there. Anything per-user or per-session lives instead in the
user's private `$OOSH_USER_CONFIG_PATH` (default `~/.config/oosh`, the same dir
`oo` uses for `mode-env.bash`). `config list` reads both tiers by name, so
`config list log.session` shows the per-user `log.session.env`. The per-user
lookup is **read-only** — `config save`/`add`/`delete`/`edit` operate only on
the shared `$CONFIG_PATH` tier.

The two tiers are linked by a source chain, exactly like `user.env` chains
`oosh.env`/`log.env`: the generated shared `log.env` ends with
`source $OOSH_USER_CONFIG_PATH/log.session.env` (the var written **unexpanded**,
so each user loads their OWN file — no leak). So `config list log` shows the
session file nested under it, and — because the chain is sourced at shell init —
the saved per-user `LOG_NAME` (and the rest) are actually **loaded** each login,
not just recorded. `boot` touch-creates the session file before the chain runs,
so a first-ever shell has no missing-source error. See
[Log System Documentation](log.md) for the per-user log vars.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `$CONFIG` | `~/config/user.env` | Full path to current config file |
| `$CONFIG_PATH` | `~/config` | Shared config directory — **always** the `~/config` symlink itself, never the `sharedConfig` it points at (see [boot.md](boot.md)) |
| `$CONFIG_FILE` | `user.env` | Current config filename |
| `$OOSH_USER_CONFIG_PATH` | `~/.config/oosh` | **Per-user** (non-shared) oosh config dir — single source of truth, anchored by `this.init`/`boot` |

## Commands

### Initialization

#### `config.init`
Initializes the config environment. Creates `~/config/` directory if needed.

```bash
./config init
```

### Repair (`config init.*`)

A small family of repair primitives that brings a tampered or partially-set-up
OOSH layout back to the canonical state produced by a fresh `init/oosh` install.
**Fresh installs do not need these** — `init/oosh` (via `oo` state 31 and
`user.oosh.install`) already produces the correct layout. Use these only when
the box has been hand-edited after install (e.g. wrong symlink ownership,
missing `dev`-group ACL on `sharedConfig/`, the self-referential
`sharedConfig/sharedConfig` symlink, etc.) or when bringing a snapshot up to
parity with another machine.

Canonical state (what `init/oosh` produces and what these methods enforce):

| Path | Owner | Mode |
|---|---|---|
| `~/config` symlink | `<user>:<user>` (NOT `<user>:dev`) | symlink |
| `~/oosh` symlink   | `<user>:<user>` | symlink |
| `~/config` target (`…/sharedConfig/`) | `developking:dev` | dir-default + `g+w` (no SGID) |
| files in `sharedConfig/` | per-creator | group `dev`, `g+w` |
| `oosh.env` | **pure data** — only `export OOSH_*="…"` lines; no self-anchor | written by `config save oosh OOSH`. `OOSH_DIR`/`CONFIG_PATH`/`CONFIG` are filtered out on purpose — they are per-user anchors, set by [`boot`](boot.md) — and so is `OOSH_BRANCH`, which is install input rather than state. |
| `user.env` | **pure data** — a `. $CONFIG_PATH/<name>.env` chain, no bootstrap header | written by `config save`. The old self-anchoring header moved into [`boot`](boot.md); see [migration/env-files.md](migration/env-files.md) for what it used to look like and why. |

The four `config init.*` repair methods plus `init.full` (which composes them)
mirror the install steps at `oo:1456` (`config save`) and `oo:1462–1463`
(`chown -R developking:dev` + `chmod -R g+w`). They explicitly do **not** add
SGID 2775 — the dev team rejected that approach (see `oo:1273-1274`); group
ownership on writes is enforced by every writer calling
`private.ensure.groupWrite` (`this:79`).

#### `config.init.full [<username>]`
Repair end-to-end: runs `config.init.shared`, then `config.init.user`, then
`config.init.env` (only for self / root), then `config.init.check`. Defaults to
the calling user. Idempotent.

```bash
./config init.full           # repair self
sudo -E ./config init.full root  # repair root (sudo -E preserves OOSH_DIR/OOSH_MODE for the env-regen step)
./config init.full bob       # repair bob (sudoer caller); env-regen skipped for bob
```

#### `config.init.shared`
Ensures the shared `sharedConfig/` directory has group `dev`, recursively
`g+w`, and removes any self-referential symlink at
`sharedConfig/sharedConfig`. Mirrors install at `oo:1462–1463`. Idempotent.

```bash
./config init.shared
```

#### `config.init.user [<username>]`
Ensures `<user>`'s `~/config` and `~/oosh` symlinks point at the canonical
shared targets and are owned `<user>:<user>`. Pre-existing real `~/config` /
`~/oosh` directories are renamed to `~/config.orig.<timestamp>` (data
preserved, never deleted). Installs `templates/user/bashrcTemplate` if the
OOSH section is missing from `~/.bashrc` (with a one-shot `~/.bashrc.pre-oosh`
backup). Adds `<user>` to group `dev` if not already a member.

```bash
./config init.user           # self
./config init.user bob       # bob (caller must be root or sudoer)
```

#### `config.init.env`
Regenerates `user.env`, `oosh.env`, and `log.env` by calling `config save`
(no args) — the same flow the install uses at `oo:1456`. **Backs up
`user.env` to `user.env.bak.<timestamp>` first** so any hand-edited
customisations (custom non-`CONFIG_*` exports, hand-added source lines beyond
what `config add` writes) are recoverable. Caller's shell must have `OOSH_DIR`
and the relevant `OOSH_*`/`LOG_*` vars set — true for any normal `./config`
invocation, but under `sudo` use `sudo -E` to preserve env.

```bash
./config init.env                 # repair self's env files
sudo -E ./config init.env         # repair from root context (env preserved)
```

If you tampered with `oosh.env` or `user.env`, this is the canonical fix.
After running, `./test.suite run config 1`'s T30/T31 (self-anchor checks)
will pass.

#### `config.init.check [<username>]`
Diagnostic only — never modifies anything, always returns `0`. Reports the
`~/config` symlink owner, the `sharedConfig/` group, presence of any
self-referential symlink, and warns if the user is in `/etc/group`'s `dev`
membership but the *running shell's* active group set doesn't include it (the
classic post-install "log out fully and log back in" condition).

```bash
./config init.check
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

**PATH is intentionally NOT saved** — it is built at login by **`boot`**, which is its single owner (see [boot.md § The PATH-writer rule](boot.md)). Saving root's PATH would overwrite the user's PATH in subprocesses. Note the mechanism: PATH never reaches the *Excluded variables* table below, because `config.save`'s **inclusion gate** only ever considers `CONFIG_*` and `BASH_FILE`. (`bashrcTemplate` has carried no `this.path.add` since the boot-loader migration; its only PATH action is the degrade `elif` for branches that have no `boot` yet.)

**Excluded variables.** `config.save` skips per-user dynamic paths so they don't leak from one user's saved config into another user's environment. The `~/config` symlink usually points at a shared location (`…sharedConfig/`), so a value written by root would otherwise be sourced verbatim by every other user — typically pointing at a path they can't access (EACCES). The exclusion list:

| Variable | Why excluded | Re-derived at shell init by |
|---|---|---|
| `LOG_INSTALL`, `INSTALL_LOG`, etc. | Install-only state — must not persist into user sessions | (none — only set during install) |
| `LOG_NAME` | OOSH log identity (`user@host`) — per-user | `log` top-level (`${LOG_NAME:-user@host}`); persisted per-user in `log.session.env` |
| `LOG_DEVICE` | per-session tty | `this`/`log` (per shell); persisted per-user in `log.session.env` |
| `LOG_LIVE` | `$OOSH_USER_CONFIG_PATH/log.live.out` is per-user; saving root's path EACCES-cascades | `log` (re-anchored at every bashrc); persisted per-user in `log.session.env` |
| `CONFIG_PATH` | `$HOME/config` — per-user | `this` (`: ${CONFIG_PATH:=$HOME/config}`) |
| `OOSH_USER_CONFIG_PATH` | `$HOME/.config/oosh` — per-user | `this`/`boot` (`: ${OOSH_USER_CONFIG_PATH:=$HOME/.config/oosh}`) |
| `CONFIG` | `$CONFIG_PATH/user.env` — per-user | `config` (derived from CONFIG_PATH) |
| `OOSH_DIR` | per-user oosh tree path | `boot`/`this` (resolved from `~/oosh`) |
| `OOSH_COMPONENTS_DIR` | `/tmp/test.oo.*` transient test path — pure noise | (none — set per test run) |
| `OOSH_BRANCH` | Install **input** — the branch the operator asked for. Not a path; excluded for the other reason this list exists: state that must be **derived, never remembered**. Persisting it closed a loop (`oosh.env` seeds a shell → the shell saves → the value is written back) in which nothing consults the checkout, and left `private.oo.install.branch.get` answering `prod` on a `dev` box. **T7.** | not re-derived at shell init at all — the branch a host is **on** is `OOSH_MODE`, derived from the canonical `~/oosh` |

The per-user `LOG_*` vars are deliberately NOT persisted into the shared
`log.env`; they are written to the per-user `$OOSH_USER_CONFIG_PATH/log.session.env`
by `log.session.save` (see [log.md](log.md)). If you add a new persisted env var
that resolves to an absolute per-user path, extend the same exclusion `case` in
`config.save` — and the `for leaker in …` list in `test/test.config` T29, which is the
value-level mirror of that `case` and the only thing that pins it.

### Required variables

The exclusion list above says what must **never** persist. This says what a config must
**carry**. It is declared as data in `config` by `private.config.required.variables.get`
— change both together.

| Variable | Lives in | Re-derived by |
|---|---|---|
| `BASH_FILE` | `user.env` | `command -v bash` |
| `CONFIG_FILE` | `user.env` | `config.init` |
| `OOSH_MODE` | `oosh.env` | `basename` of the canonical `~/oosh` |
| `OOSH_OS` | `oosh.env` | `$OSTYPE`, via `os` |
| `OOSH_PM` | `oosh.env` | `oo pm.discover` |
| `LOG_LEVEL` | `log.env` | defaults to `1` |

```bash
config validate required
```

Reports **every** missing variable, not just the first, and compares the persisted
`OOSH_MODE` against the branch `~/oosh` actually points at. rc 1 on either, verdict on
stdout:

```
INCOMPLETE: /home/you/config — OOSH_MODE=released but ~/oosh is on dev
  repair with: config init.env
```

`config.init.check` runs the same report but **swallows the rc** — it is documented as
never failing its caller. Branch on `config validate required` instead.

**Why this was needed.** `config.init` created a directory and three variables, so on a
missing config it succeeded emptily, leaving `$CONFIG` pointing at a file that did not
exist. `config.validate` checks line *shape* and knows no variable name. Nothing compared
the persisted branch to the checkout, which is how this host ran for weeks with
`OOSH_MODE=released` on a `dev` tree.

**`OOSH_BRANCH` vs `OOSH_MODE`.** They are not two names for one thing.
`OOSH_BRANCH` is the branch the operator **asked for**, meaningful for the length of one
install (`init/oosh`, install state 31) and never persisted. `OOSH_MODE` is the branch the
host **is on**, derived from the canonical `~/oosh` and persisted. When `OOSH_BRANCH` is
empty — which is every shell outside an install — `private.oo.install.branch.get` falls
through to the checkout, which is the answer every caller wants.

### Listing Configuration

#### `config.list [name]`
Lists the content of a config file.

```bash
# List user.env (default)
./config list

# List specific config (shared tier)
./config list oosh
./config list log

# List the per-user tier by name (reads $OOSH_USER_CONFIG_PATH/log.session.env)
./config list log.session
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
Removes duplicate lines while **preserving insertion order** (`awk '!seen[$0]++'`, not `sort -u`). Order matters: the `user.env` bootstrap header — and specifically the `CONFIG_PATH` fallback — must stay above the `source $CONFIG_PATH/*.env` lines, so the file must never be alphabetically re-sorted. Called automatically by `config.add`.

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

#### `config.ssh.host.set <hostname>`
Sets the SSH config host name for prompts.

```bash
./config ssh.host.set myserver
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
| `private.config.variables.list` | `<envPrefix>` → one persistable variable NAME per line (`compgen -v`, shape gates, exclusion list) |
| `private.config.variable.export.line` | `<variableName>` → one `export NAME="value"` line; rc 1 for unset, array, or an ANSI-C-quoted value |
| `private.config.variables.export` | `<envPrefix>` → the whole body of a generated env file |
| `private.config.string.upper` | `<string>` → upper-cased, without the bash-4 `${var^^}` operator |
| `private.config.required.variables.get` | the required-variable table, as data |
| `private.config.file.resolve` | the effective file for the current `$CONFIG_FILE` |

All six are getters consumed as `$(…)`, so none calls `create.result` — it runs
in a subshell and the result could never reach the caller. The first three are
additionally **silent by contract**: their only caller runs inside
`{ … } >$CONFIG`, and `log:35` sets `LOG_DEVICE=/proc/self/fd/1`, so inside that
redirect a single `debug.log` would be written into the generated env file.

## File Format

Config files use standard bash export format:

```bash
export VARIABLE_NAME="value"
export ANOTHER_VAR="another value"
source $CONFIG_PATH/other.env
```

**`export` is mandatory, not decoration.** `boot` sources these files with POSIX
`.`, and a bare `NAME=value` assigns in the sourcing shell but exports nothing to
its children — so `OOSH_MODE` would be set at login and empty in every command
the user then runs.

Note that **`config validate` does not enforce it**: its regex makes the keyword
optional (`^(export[[:space:]]+…)?[A-Za-z_][A-Za-z0-9_]*=`), so a file of bare
assignments validates `OK`. On macOS that is exactly what `config.save` produced
for years — bash 3.2's `declare -p` prints no `declare -x` prefix for the `sed`
to rewrite. The check that does enforce it is the platform test
`test/test.platform.shared.config.env.invariant`.

**How the body is generated.** `config.save` does not parse `declare -p`. It asks
`private.config.variables.list <prefix>` for variable NAMES (`compgen -v`, two
shape gates, then the exclusion list), and renders each one with
`private.config.variable.export.line`, which uses `declare -p <name>` — the
*named* form, the only one that behaves the same on bash 3.2 and bash 5. Bash
does the quoting; nothing in oosh hand-rolls an escaper.

A value that bash renders with ANSI-C quoting (`$'a\nb'` — a newline or a control
character) is **refused, not written**: `$'…'` is a bashism and dash reads it
literally at every `/bin/sh` login. Nothing in the `OOSH_*` / `LOG_*` / `CONFIG_*`
families is meant to hold a newline, so such a value is an upstream bug;
`config validate required` is what reports the variable as missing.

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
