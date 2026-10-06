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
| `$HOME/.config/oosh/log.session.env` | **Per-user** log identity/session (`LOG_NAME`, `LOG_DEVICE`, `LOG_LIVE`) |
| `$HOME/.config/oosh/user.session.env` | **Per-user** half of `user.env`: the user's real `PATH` (no `$` at all) (`config session.save`) |
| `$HOME/.config/oosh/oosh.session.env` | **Per-user** half of `oosh.env`: `OOSH_MODE`, the branch the user's own `~/oosh` points at (`config session.save`) |

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
user's private `~/.config/oosh` (the same dir
`oo` uses for `mode-env.bash`). `config list` reads both tiers by name, so
`config list log.session` shows the per-user `log.session.env`. The per-user
lookup is **read-only** — `config save`/`add`/`delete`/`edit` operate only on
the shared `$CONFIG_PATH` tier.

The two tiers are linked by a source chain, exactly like `user.env` chains
`oosh.env`/`log.env`: the generated shared `log.env` ends with
`. $HOME/.config/oosh/log.session.env` (written **unexpanded**,
so each user loads their OWN file — no leak). So `config list log` shows the
session file nested under it, and — because the chain is sourced at shell init —
the saved per-user `LOG_NAME` (and the rest) are actually **loaded** each login,
not just recorded. `config save log` and `config init.user` create the session file (`private.config.session.file.ensure`),
so the chain line needs no guard and a first-ever shell has no missing-source error. See
[Log System Documentation](log.md) for the per-user log vars.

**`user.env` forks the same way** (boss, 2026-10-02). The shared `user.env` keeps
what is the same for everyone — the `CONFIG_*` anchors and `BASH_FILE`, in their
`$HOME` form — and its **last** line is `. $HOME/.config/oosh/user.session.env`.
That per-user file holds what belongs to one user only: their **real `PATH`**,
written out in full (no `$HOME`, no `:$PATH` — the file is theirs alone).
Coming last, the personal values win. **`oosh.env` forks the same way:** its last
line is `. $HOME/.config/oosh/oosh.session.env`, which holds `OOSH_MODE` — the
branch **their** `~/oosh` points at — so `config list oosh` shows it nested, as
`config list log` shows `log.session`. One family, one personal file:

| Shared (`~/config`) | last line chains | Personal (`~/.config/oosh`) |
|---|---|---|
| `user.env` | `. $HOME/.config/oosh/user.session.env` | `PATH` |
| `oosh.env` | `. $HOME/.config/oosh/oosh.session.env` | `OOSH_MODE` |
| `log.env` | `. $HOME/.config/oosh/log.session.env` | `LOG_NAME`, `LOG_DEVICE`, `LOG_LIVE` | `config session.save` writes it; `config save` writes the saving
user's; `config init.user` and the install create it for every user, filled in
their own hop (`private.config.session.file.ensure`).

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `$CONFIG` | `~/config/user.env` | Full path to current config file |
| `$CONFIG_PATH` | `~/config` | Shared config directory — **always** the `~/config` symlink itself, never the `sharedConfig` it points at (see [The anchor rule](#the-anchor-rule)) |
| `$CONFIG_FILE` | `user.env` | Current config filename |
| — | `~/.config/oosh` | **Per-user** (non-shared) oosh dir, spelled `$HOME/.config/oosh` directly. The `OOSH_USER_CONFIG_PATH` variable that used to name it was removed 2026-10-01: it was always this value (T44) |

## The anchor rule

**`OOSH_DIR` is always `~/oosh`** — the user's `oosh` symlink, never the branch
folder it happens to point at, never a `BASH_SOURCE`/`$0` walk, never
`oo.mode.base.get`. **`CONFIG_PATH` is always `~/config`** — the user's `config`
symlink, never the shared `sharedConfig` directory it points at. `CONFIG` is
`~/config/user.env`, and the per-user dir is always `~/.config/oosh` (no variable).

In code and in the env files they are written `"$HOME/oosh"` / `"$HOME/config"`,
because a tilde inside quotes does **not** expand, and `$HOME/…` is safe in POSIX
`sh` and in every quoting context.

```sh
export CONFIG_PATH="$HOME/config"   # ~/config/user.env
export OOSH_DIR="$HOME/oosh"        # ~/config/oosh.env
```

**Where they come from.** `config save` writes them as these constants, whatever
the saving shell holds (`private.config.variable.export.line`, pinned by
`test/test.config` T-CONFIG-SAVE-ANCHORS-CONSTANT) — the installer's shell holds
the *resolved* `sharedConfig`, and that must never reach a user. A shell that has
not read `user.env` yet uses the same literals as fallbacks: `this` (file scope,
and `: ${CONFIG_PATH:=$HOME/config}` in `this.init`), `log`, `ossh.start`.
Switching branches (`oo mode`) moves only what `~/oosh` points at; the variable
never changes.

**When you need the physical directory**, resolve it at that spot with the
portable `private.this.path.canonical` — never bake the resolution into the anchor:

| Site | Why it needs the physical path |
|---|---|
| install state 31 `ln -s … oosh` | linking `$OOSH_DIR` itself would create `~/oosh -> ~/oosh` |
| install state 31 `OOSH_MODE` | the branch name is `basename` of the branch folder, not of the symlink |
| `config.init.user` | decides "are we under the shared tree?" with a string-prefix test |
| `promote` | `ogit worktree.find` answers with the physical folder of a stage |
| `oo.mode.base.get` | strategies 3/4 do `dirname`/`basename` — `dirname ~/oosh` is just `$HOME` |

**Sanctioned exceptions** are marked in code with `# <anchor>-exception: <reason>`
(or `# <anchor>-exception-file: <reason>` for a whole file), `<anchor>` being the
variable name lower-cased with `_` → `-`: `oosh-dir-exception`, `config-path-exception`.

| Anchor | Site | Why |
|---|---|---|
| `OOSH_DIR` | `oo.use` | runs one command from another branch without switching — a scoped child-process override |
| `OOSH_DIR` | `ossh` remote invoke | a string executed on a remote host whose `~/oosh` does not exist yet |
| `OOSH_DIR` | `user.oosh.install`, `config.init.user` hops | run as **another user** before their `~/oosh` exists; they source the shared tree |
| `OOSH_DIR` | `init/oosh` (file-wide) | the installer runs before `~/oosh` exists |
| both | `private.config.variable.export.line` | writes the constants as data into the env files |
| `CONFIG_PATH` | `config file <path>` | its job is to point the session at an arbitrary config file |
| `CONFIG_PATH` | install state 31 (×2) | builds the shared tree before `~/config` is a symlink to it |

Enforced by **`this.anchor.validate <all|OOSH_DIR|CONFIG_PATH>`**: one `git grep`
per anchor over the tracked tree (`docs/`, `test/`, `.claude/`, `*.md`, `*.json`
excluded), every assignment classified as conforming / exception / violation, the
verdict echoed to stdout (it survives any `LOG_LEVEL`), rc 1 on any violation.
Covered by `test.this` T-OOSH-DIR-* / T-CONFIG-PATH-* (with planted violations) and
`test.config` T31.

## The computer's name

oosh names the computer for the prompt, the logs and ssh (`private.config.host.name.get`). The name is saved as `OOSH_SSH_CONFIG_HOST` in `oosh.env`.

| Where | Name |
|---|---|
| A container | The container's Docker name, read through the mounted docker socket (`private.config.host.container.name.get`). Inside a container `hostname` is only the start of the container ID, so it is not used. |
| A Mac | The `LocalHostName` (`scutil`), without the router's domain. |
| A bare computer | The short host name (`hostname -s`). |
| None found | `localhost` |

A container started by odocker without a name gets Docker's own random name as its name and host name, so the install knows it from the start (`private.odocker.container.name.new`, see [odocker.md](odocker.md)).

`oo update` calls `private.config.host.name.refresh`. It corrects the saved name when it was only guessed and is wrong now: empty, the raw host name, a container ID, or the name of another container (a cloned image). A name you chose — `config ssh.host.set`, or the alias given to `ossh install` — is kept.

## The PATH line

**No file in the tree builds `PATH`.** A shell's PATH comes from the user's
own `~/.config/oosh/user.session.env`, chained as the shared `user.env`'s last
line, where `config session.save` writes it as one line of data — a snapshot of
the saving shell's PATH, as on the MacStudio, written as the **real path**
(`private.config.path.line.absolute.get`, T-CONFIG-USER-SESSION-PATH-ABSOLUTE):
`~/oosh` and `~/oosh/ng` first, a bash outside `/bin` and `/usr/bin` (brew) next,
trailing slashes dropped, no empty, `.`, relative or transient (`/tmp`,
`.vscode-server`) segment, each segment once — and, because a polluted shell must
not be frozen into the user's PATH, no segment holding `$ " \` or a backtick, no
active `VIRTUAL_ENV` / `CONDA_PREFIX`, no directory that does not exist
(T-CONFIG-USER-SESSION-PATH-FILTERED). No `$` at all, no `:$PATH`:

```sh
export PATH="/home/me/oosh:/home/me/oosh/ng:/opt/homebrew/bin:/home/me/.local/bin:/usr/local/bin:/usr/bin:/bin"
```

The PATH is frozen per user until the next save: a directory the system adds
later reaches the shell after `config session.save` (starting `this` saves too).
`.bashrc`, `source this` and the remote prelude (`ossh.remote.prelude.get`) all
read it. It cannot guard itself, so `this` drops repeated segments on every
`source this` (`private.this.path.dedup`, T-THIS-PATH-NO-GROWTH).

Before a shared config is switched (*The switch and its gate*, below), the
shared `user.env` still carries the old shared line written by
`private.config.path.line.get` — every segment under the saver's home as
`$HOME/…`, `:$PATH` last.

**What oosh cannot reach.** A login file that changes PATH *after* it sourced
`.bashrc` — an installer's `export PATH="$HOME/.local/bin:$PATH"` appended to
`~/.bash_profile` — puts its directory in front again once oosh has finished.
Remove such a line: `user.env`'s PATH line already carries the directory.
`platform.shared.configLayout` invariant 8 checks a login shell for it.

**An empty shell is an oosh shell** (boss, 2026-10-02 — this reverses the
30 Sep decision that a bare `env -i bash` is not one). From `env -i sh` — no
`HOME`, only the system PATH — both `bash` and `this` bring the user back:
`bash` still finds `~/.bashrc` (`~` reads the password database), which hands an
old bash over to `BASH_FILE` and then loads `this` first, and `this` derives
`HOME` from the OS identity; `this` is found on the system PATH as the launcher
`/usr/local/bin/this` (one host-wide command, not a login file). A login file of
the user's own must say `~/.bashrc`, not `$HOME/.bashrc`. `user login <user>`
works as before. `test/test.platform.shared.boot.invariant` checks it on a real machine: from an empty environment, both `bash` and `this` must come up as an oosh shell.

Every `PATH=` / `export PATH=` in the tracked tree is therefore a violation unless
it carries a marker:

```sh
# path-exception: <reason>            # this line, or one of the five above it
# path-exception-file: <reason>       # anywhere in the file — the whole file
```

The five-line window exists because these assignments often sit inside an `ssh`
command string, a `bash -c` string or a heredoc, where the marker cannot go on the
line itself.

| Kind | Sites | Why |
|---|---|---|
| whole file | `init/oosh`, `init/once` | the installer runs before `~/oosh` and `user.env` exist; `init/once` is the superseded ONCE installer, still tracked |
| the data line | `config.save` | writes user.env's PATH line |
| fallback | `ossh.remote.prelude.get`, the `bashrcTemplate` degrade branch, the CI steps | `~/config/user.env` first, a bare prepend only when it is missing (mid-install) |
| remote / sudo string | `ossh`, `user` ×2, `hiveMind` ×3, `this` (as-user preamble) | executed on another host or as another user, where no `user.env` has been read |
| sourced before `user.env` | `ossh.start`, `this` (file scope, `this.path.add`, `private.this.path.dedup`) | colon-anchored or a rewrite of the value already there |
| repair, not build | `oo.mode` ×2, `this.init` | rewriting a branch name already in PATH, or saving and restoring PATH across a mid-session `source "$CONFIG"` |
| session scope | `oo` (brew, `ONCE_LOAD_DIR`), `claudeCode`, `path.append`/`prepend`/`remove` | deliberately affects only the running shell |
| diagnostics | `debug`'s `p`, banners, `path.env` | they print `PATH=`, they do not set it |

Enforced by **`path validate [<treeRoot>]`** — the same sweep as the anchors (plus
`old/` and `restore/` excluded), rc 1 on any violation. Covered by `test.path`
`T-PATH-VALIDATE-*`, including T-PATH-VALIDATE-NO-OWNER (a file named `boot` is no
exception any more).

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
| `oosh.env` | **pure data** — only `export OOSH_*="…"` lines; no self-anchor | written by `config save oosh OOSH`: **every** `OOSH_*` variable, a value under the saving user's home written `"$HOME/…"` (the config is shared). Only `OOSH_BRANCH` is left out — install input, not state. |
| `user.env` | **pure data** — the `CONFIG_*` anchors, `BASH_FILE`, then `. $CONFIG_PATH/oosh.env` and `. $CONFIG_PATH/log.env`, last `. $HOME/.config/oosh/user.session.env` | written by `config save` — what `.bashrc` and `source this` start a shell from (the MacStudio model); see *Saving Configuration* below. |

The four `config init.*` repair methods plus `init.full` (which composes them)
mirror install state 31 (the `config save` call, then the group `dev` and
`chmod -R g+w` steps on `$CONFIG_PATH`). They explicitly do **not** add
SGID 2775 to the files — `private.ensure.sharedTree` sets group and `g+w` only;
group ownership on writes is enforced by every writer calling
`private.ensure.groupWrite`.

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

Without parameters, it writes the whole config the MacStudio way (`test/mcdonges.latest`) — `user.env` is what a shell starts from, there is no `boot`:

```bash
# ~/config/user.env
export CONFIG_PATH="$HOME/config"
export CONFIG_FILE="user.env"
export CONFIG="$HOME/config/user.env"
export BASH_FILE="/usr/bin/bash"
. $CONFIG_PATH/oosh.env
. $CONFIG_PATH/log.env
. $HOME/.config/oosh/user.session.env

# ~/.config/oosh/user.session.env  (per user — config session.save)
export PATH="/home/me/oosh:/home/me/oosh/ng:/home/me/.local/bin:/usr/local/bin:/usr/bin:/bin"

# ~/.config/oosh/oosh.session.env  (per user — config session.save; oosh.env chains it last)
export OOSH_MODE="dev"
```

- `config.save oosh OOSH` → `oosh.env`: **every** `OOSH_*` setting — not the runtime readings of the saving shell (see *Excluded variables*).
- `config.save log LOG` → `log.env`: **every** `LOG_*` setting except the per-user session values (below), and as its **last** line `. $HOME/.config/oosh/log.session.env` — written by every save of `log.env`, exactly once, unguarded.
- `log.env`'s last line spells `$HOME/.config/oosh` directly, so it needs nothing from `oosh.env`. A host's old line (`. $OOSH_USER_CONFIG_PATH/log.session.env`) is rewritten by `config save` and by `oo update` / `oo user.fix` (`private.config.log.chain.migrate`, T-CONFIG-LOG-CHAIN-MIGRATE).
- `ODOCKER_WORKSPACES` is **not** in `user.env`: it lives in `odocker.env` (`odocker workspace.set`), which `user.env` chains. This departs from the MacStudio branch, where `config set` put it into `user.env`.
- `user.env`'s **last** line is `. $HOME/.config/oosh/user.session.env`, exactly once, unguarded; `config save` writes the saving user's file there too (`config session.save`: the real PATH and `OOSH_MODE`). T-CONFIG-USER-SESSION-SPLIT.
- The PATH line is data (`# path-exception:` in the getters); `this` de-duplicates PATH when `user.env` is sourced again.
- **Every other chain is kept.** A line `. $CONFIG_PATH/odocker.env`, or one `config add myapp` appended, is read before `user.env` is rewritten and added back after `oosh.env` and `log.env`, in its order, once — even when its file is missing. A legacy `source $CONFIG_PATH/x.env` line comes back as `. $CONFIG_PATH/x.env` (`private.config.chain.names.get`; T-CONFIG-CMD-SAVE-USER-KEEPS-CHAINS).

**The shared config and `$HOME`.** The `~/config` symlink points at a location shared by every user of the host (`…sharedConfig/`). So a value under the **saving** user's home is never written as that user's absolute path: `private.config.variable.export.line` writes it as `"$HOME/…"` (only the prefix — the rest keeps bash's `declare -p` quoting), and every reader expands it to their own home. `OOSH_DIR="$HOME/oosh"` and `CONFIG_PATH="$HOME/config"` are therefore correct for everyone. (The per-user directory is always `$HOME/.config/oosh`, spelled out where it is chained.) Pinned by `test/test.config` T29 and T-CONFIG-SAVE-PREFIX-OOSH.

**Per-user session values.** `LOG_NAME`, `LOG_DEVICE` and `LOG_LIVE` are **not** saved in the shared `log.env`: a new user would inherit the saver's values. They live only in each user's private `$HOME/.config/oosh/log.session.env` (written by `log.session.save`, see [log.md](log.md)), which `log.env` chains last. Every user has that file: `config init.user` and the install create it with `private.config.session.file.ensure`.

**`config save` typed at the prompt.** `config` then runs as a **child process**: it does not re-read `user.env`, so it saves what the shell **exported**. `test/test.config` T-CONFIG-CMD-SAVE-* run the real executable under `env -i` to pin exactly that.

**Excluded variables.** Three kinds are never persisted — install-time state, runtime readings of the saving shell, and the per-user session values:

| Variable | Why excluded |
|---|---|
| `LOG_INSTALL`, `INSTALL_LOG`, … (`*INSTALL*`) | Install-only state — must not persist into user sessions |
| `SUDO_*` | Injected by sudo for one command |
| `OOSH_SHLVL`, `OOSH_STATUS`, `OOSH_PROMPT`, `OOSH_CONFIG_NEEDS_SAVE` | **Runtime readings** of the one shell that ran the save. Saved, they come back into every new shell and are saved again. T-CONFIG-CMD-SAVE-OOSH |
| `OOSH_CLEAN_ENV`, `OOSH_APT_UPDATED` | **One-run gates** of `init/oosh`, exported during the install. Saved, a later `init/oosh` run from a normal shell skipped its clean-environment restart and its `apt-get update`. T-CONFIG-CMD-SAVE-OOSH |
| `LOG_NAME`, `LOG_DEVICE`, `LOG_LIVE` | **Per-user session values** — only in each user's `log.session.env`, never the shared `log.env`. T-CONFIG-CMD-SAVE-LOG |
| `OOSH_MODE` (once switched) | **Per user** — the branch the user's own `~/oosh` points at, in their `oosh.session.env`. Decided below the `case` by the layout: before the switch it stays in the shared `oosh.env`, which other users still read. T29, T-CONFIG-CMD-SAVE-OOSH |
| `ODOCKER_SG` | **Runtime marker** of odocker's one `sg` re-run (the socket group a shell does not know yet). T-CONFIG-ODOCKER-SG-NOT-SAVED |
| `OOSH_BRANCH` | Install **input** — the branch the operator asked for. State that must be **derived, never remembered**: persisting it closed a loop (`oosh.env` seeds a shell → the shell saves → the value is written back) in which nothing consults the checkout, and left `private.oo.install.branch.get` answering `prod` on a `dev` box. **T7.** The branch a host is **on** is `OOSH_MODE`, derived from the canonical `~/oosh`. |

The list is the `case` in `private.config.variables.list` (`config`); `test/test.config` T29 pins it by value. Change all three together.

### The switch and its gate

A shared config written before the fork switches **once**, and only when no user
would be left without a file: the shared `user.env` chains `user.session.env`
unguarded, and a plain `sh` ends on `.` of a missing file.

- **The gate** (`private.config.session.chain.ready`): every **other** user linked
  to the same `sharedConfig` has a **filled** `user.session.env`. A home the caller
  cannot look into (0750 homes, a non-root caller) is not proven.
- **`config save`** keeps a switched config switched (`private.config.session.split.is`)
  and switches an old one only through the gate. While it is closed it writes the
  old shared layout — the shared PATH line, `OOSH_MODE` in `oosh.env` — and the
  saver's own file (T-CONFIG-USER-SESSION-SAVE-GATED).
- **`sudo oo update`** (or `oo user.fix` as root) is how a multi-user host
  switches: `config init.user` gives every linked user their files, each in their
  own hop (`private.config.session.files.ensure.all`), then
  `private.config.user.session.migrate` switches the shared files in place —
  owner, group and mode kept, idempotent (T-CONFIG-USER-SESSION-MIGRATE) —
  and `private.config.oosh.session.migrate` gives `oosh.env` its chain to
  `oosh.session.env` the same way, through its own gate (every linked user has
  an `oosh.session.env`), then takes the transition copy of `OOSH_MODE` out of
  the users' `user.session.env` (T-CONFIG-OOSH-SESSION-MIGRATE).

### Required variables

The exclusion list above says what must **never** persist. This says what a config must
**carry**. It is declared as data in `config` by `private.config.required.variables.get`
— change both together.

| Variable | Lives in | Re-derived by |
|---|---|---|
| `BASH_FILE` | `user.env` | `command -v bash` |
| `CONFIG_FILE` | `user.env` | `config.init` |
| `OOSH_MODE` | `oosh.session.env` (per user — `private.config.required.file.path`) | `basename` of the canonical `~/oosh` |
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

# List the per-user tier by name (reads $HOME/.config/oosh/log.session.env)
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

**`export` is mandatory, not decoration.** `.bashrc`, `this` and dash/ash shells source these files with POSIX
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
