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
| `$HOME/.config/oosh/log.session.env` | **Per-user** log identity/session (`LOG_NAME`, `LOG_LIVE`, and `LOG_DEVICE` only when it is a file chosen with `log device <file>` — saved by that command, kept by every new terminal, removed by `log device <terminal>`; a terminal is never saved. An interactive terminal always logs to itself; the saved file is for processes without a terminal. A saved `LOG_LIVE` is not taken by the next shell — see [log.md](log.md)) |
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
| `log.env` | `. $HOME/.config/oosh/log.session.env` | `LOG_NAME`, `LOG_LIVE`, `LOG_DEVICE` (only a file chosen with `log device <file>`, kept until `log device <terminal>`) | `config session.save` writes it; `config save` writes the saving
user's; `config init.user` and the install create it for every user, filled in
their own hop (`private.config.session.file.ensure`). The ensure creates and
**first**-fills only — an empty `user.session.env` or a missing `oosh.session.env`;
an empty `oosh.session.env` is legal (no branch derivable) and is left alone. One
`config save` writes each session file once (T-CONFIG-SESSION-WRITES-ONCE).

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
| A bare computer | The short host name (`private.this.host.name.get short`: the `hostname` program, else bash's `$HOSTNAME` — AlmaLinux minimal has no `hostname`; T-CONFIG-HOST-NAME-NO-HOSTNAME). |
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
later reaches the shell after `config session.save` (starting `this` or `log` saves
too — before it puts the session-only `~/oosh/init` and `~/oosh/external` on PATH,
which a login PATH never carries; T-THIS-START-SESSION-PATH).
`.bashrc`, `source this` and the remote prelude (`ossh.remote.prelude.get`) all
read it. It cannot guard itself, so `this` drops repeated segments on every
`source this` (`private.this.path.dedup`, T-THIS-PATH-NO-GROWTH).

Before a shared config is switched (*The switch and its gate*, below), the
shared `user.env` still carries the old shared line written by
`private.config.path.line.get` — every segment under the saver's home as
`$HOME/…`, `:$PATH` last. The same segment rules apply, and a segment holding
`$ " \` or a backtick is dropped there too — checked on the raw segment, before
the `$HOME` rewrite adds its own `$` (T-CONFIG-PATH-LINE-NO-CODE): every user's
shell executes that line.

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
| `~/config` target (`…/sharedConfig/`) and its directories | `developking:dev` (directories: per-creator) | `2775` — group `dev`, `g+w`, setgid |
| files in `sharedConfig/` | per-creator | group `dev` (inherited through the setgid directory), `g+w` |
| `oosh.env` | **pure data** — only `export OOSH_*="…"` lines; no self-anchor | written by `config save oosh OOSH`: **every** `OOSH_*` variable, a value under the saving user's home written `"$HOME/…"` (the config is shared). Only `OOSH_BRANCH` and `OOSH_REPO` are left out — install input, not state. |
| `user.env` | **pure data** — the `CONFIG_*` anchors, `BASH_FILE`, then `. $CONFIG_PATH/oosh.env` and `. $CONFIG_PATH/log.env`, last `. $HOME/.config/oosh/user.session.env` | written by `config save` — what `.bashrc` and `source this` start a shell from (the MacStudio model); see *Saving Configuration* below. |

The four `config init.*` repair methods plus `init.full` (which composes them)
mirror install state 31 (the `config save` call, then the group `dev`, `g+w` and
setgid step on `$CONFIG_PATH`). Both share it through the kernel's one share
primitive, `private.this.folder.share <dir> yes`: only the entries
`private.this.share.pending.list` names (not group `dev`, not `g+w`, a directory
without setgid) are handed to `chgrp` and `chmod` — never `-R` — so an entry
another user owns that is already right is no error. The directories get setgid
(2775), so a file root creates in the sharedConfig is group `dev`; the oosh
writers keep calling `private.ensure.groupWrite` for `g+w`, and `oo heal`'s clean
process writes with umask 002 ([oo.md](oo.md#ooheal)).

State 31 creates the shared config once and never copies into an existing one — but on
every run it carries the **installing state machine** (`stateMachines/` and
`current.state.machine.env` of the user's config, else root's) into an existing
`sharedConfig`, the old ones kept as `.orig.<ts>` (`private.oo.shared.config.state.carry`,
called from `private.oo.shared.config.ensure`). A real `~/config` is kept as
`config.orig.<ts>` through `private.this.symlink.with.backup`, never nested.

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
Shares the `sharedConfig/` with group `dev`: its directories `2775` (group `dev`,
`g+w`, setgid), its files group `dev` and `g+w` — only the entries not shared yet
(`private.this.folder.share <sharedConfig> yes`); an entry still wrong afterwards
that is not the caller's to change is named, rc 1. It removes any
self-referential symlink at `sharedConfig/sharedConfig`
(`private.this.selfLoop.remove`). The same calls as install state 31. Idempotent.

```bash
./config init.shared
```

#### `config.init.user [<username>] [<sharedOosh>]`
Ensures `<user>`'s `~/config` and `~/oosh` symlinks point at the canonical
shared targets and are owned `<user>:<user>`. Pre-existing real `~/config` /
`~/oosh` directories are renamed to `~/config.orig.<timestamp>` (data
preserved, never deleted). Installs `templates/user/bashrcTemplate` if the
OOSH section is missing from `~/.bashrc` (with a one-shot `~/.bashrc.pre-oosh`
backup). Adds `<user>` to group `dev` if not already a member.
It loads `ogit` for the branch-folder check and **fails loudly** when it cannot (rc 1, `RESULT` names
`$OOSH_DIR/ogit`). The shared config path is `private.config.shared.config.get`, so a case-different
spelling of the same folder never reads as a wrong link. The symlink hop passes no stamp: the kernel's
`private.this.symlink.with.backup` stamps a free `.orig.<ts>` itself (no `date` in `config`).
The symlink hop runs AS `<user>` and loads the shared tree's `this` through
`private.this.as.user.preamble.get`, like the later hops. It used to source the
caller's `$OOSH_DIR`, which the caller expands: root's 0700 `/root/oosh` or a
temp clone the target cannot read.

**`<sharedOosh>` names the `~/oosh` target.** Without it the target is the first
that resolves: the tree running the command (when it sits under the shared
components base), the link `~/oosh` already is, then the branch of `$OOSH_MODE`
or the git branch, else `dev`. `oo heal` names the branch folder it heals to, so
the link that is there no longer wins over it. The explicit target must be a
branch folder the base lists — a clone directly under the components base, no
symlink (`private.ogit.base.folders.list`; the base is
`private.config.shared.oosh.base.get`). It is canonicalised to the file system's
letter case first (`/Users/shared` and `/Users/Shared` are one folder on macOS).
Anything else is refused: rc 1, `config.init.user: <path> is not a branch folder
under <base> — nothing changed`, and no link is touched. Tab completion of
`<sharedOosh>` offers exactly those branch folders, and `<username>` completes
from `user.list`.

```bash
./config init.user                          # self
./config init.user bob                      # bob (caller must be root or sudoer)
./config init.user bob <base>/dev           # bob, ~/oosh → <base>/dev (a branch folder of the base)
```

`oo user.fix` takes the username only; `<sharedOosh>` belongs to the heal.

#### `config.init.env`
Regenerates `user.env`, `oosh.env`, and `log.env` by calling `config save`
(no args) — the same flow the install uses at `oo:1456`. **Backs up all three
first, outside the config:** `<name>.env.bak.<timestamp>` in a private temp
directory (`private.this.temp.dir.get config.init.env`, mode 700), never in the
shared config every user sources; removed when the run lost nothing, kept and
named in the refusal otherwise. Caller's shell must have `OOSH_DIR`
and the relevant `OOSH_*`/`LOG_*` vars set — true for any normal `./config`
invocation, but under `sudo` use `sudo -E` to preserve env.

It **refuses to worsen** them: a variable exported in a backup and in none of the env files
the regenerated `user.env` chains (`. $CONFIG_PATH/<name>.env`, read by
`private.config.chain.names.get`; without a chain, every `*.env` of the config) is a loss, and
then all three backups go back (`REFUSING — the regenerated files lost: …; restored user/oosh/log,
backups kept in <dir>`, rc 1). A variable that only moved files is no loss — an old user.env's
`OOSH_DIR` now lives in `oosh.env`, its `ODOCKER_WORKSPACES` in the chained `odocker.env`
(T-CONFIG-INIT-ENV-MIGRATED-NAME) — and neither are the retired names
(`private.config.variable.retired.is`: PATH and OOSH_MODE, now in the per-user session files,
`OOSH_USER_CONFIG_PATH`, removed 2026-10-01, and the old `OOSH_CONFIG_VERSION` stamp) and every
name `config save` never persists (e.g. `OOSH_APT_UPDATED`, `OOSH_CLEAN_ENV`, which an older `oosh.env` carried) (`private.config.variable.persisted.is`, the one list of § Excluded variables) (T-CONFIG-INIT-ENV-OLD-USER-ENV).

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
| `OOSH_CLEAN_ENV`, `OOSH_APT_UPDATED` | **One-run gates** of `init/oosh`, exported during the install. Saved, a later `init/oosh` run from a normal shell skipped its clean-environment restart and its package-list refresh. T-CONFIG-CMD-SAVE-OOSH |
| `LOG_NAME`, `LOG_DEVICE`, `LOG_LIVE` | **Per-user session values** — only in each user's `log.session.env`, never the shared `log.env`. T-CONFIG-CMD-SAVE-LOG |
| `OOSH_MODE` (once switched) | **Per user** — the branch the user's own `~/oosh` points at, in their `oosh.session.env`. Decided below the `case` by the layout: before the switch it stays in the shared `oosh.env`, which other users still read. T29, T-CONFIG-CMD-SAVE-OOSH |
| `ODOCKER_SG` | **Runtime marker** of odocker's one `sg` re-run (the socket group a shell does not know yet). T-CONFIG-ODOCKER-SG-NOT-SAVED |
| `ODOCKER_SOCKET` | **Test/override knob** of `private.odocker.socket.get`. One user's export must not reach the shared `odocker.env` through `odocker workspace.set`. T-CONFIG-ODOCKER-SG-NOT-SAVED |
| `OOSH_BRANCH` | Install **input** — the branch the operator asked for. State that must be **derived, never remembered**: persisting it closed a loop (`oosh.env` seeds a shell → the shell saves → the value is written back) in which nothing consults the checkout, and left `private.oo.install.branch.get` answering `prod` on a `dev` box. **T7.** The branch a host is **on** is `OOSH_MODE`, derived from the canonical `~/oosh`. |
| `OOSH_REPO` | Install **input** — the **source** of the install's clones (a fork, a path, the bundle `ossh install` ships with `OSSH_INSTALL_LOCAL=1`, removed when the install returns). The origin of every folder is the canonical SSH URL whatever the source (owner decision 1), so a persisted value is at best a stale path: a fresh local install wrote the removed bundle path into `oosh.env`. |

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
| `OOSH_MODE` | `oosh.session.env` (per user — `private.config.required.file.path.get`) | `basename` of the canonical `~/oosh` |
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
Adds a config file as a source in user.env. The per-user session chain `. $HOME/.config/oosh/user.session.env` stays the last line: the new line goes in before it, in place (T-CONFIG-ADD-CHAIN-LAST).

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
| `private.config.variables.list` | `<envPrefix> <?sessionSplit>` → one persistable variable NAME per line (`compgen -v`, shape gates, exclusion list); `sessionSplit` (`yes`/`no`) is the layout a full `config save` decided and hands down (`private.config.save oosh OOSH <sessionSplit> <ooshSplit>`), empty reads it off `user.env` |
| `private.config.save` | `<?name> <?ENV_PREFIX> <?sessionSplit> <?ooshSplit>` → the work of `config.save`; the public `config save <?name> <?ENV_PREFIX>` takes no layout — only a full save hands it to its nested oosh save |
| `private.config.variable.persisted.is` | `<name>` → rc 0 when `config save` persists the variable, rc 1 for the never-persist names (`*INSTALL*`, `OOSH_BRANCH`, `ODOCKER_*`, `OOSH_SHLVL`/`STATUS`/`PROMPT`/`CONFIG_NEEDS_SAVE`, `OOSH_CLEAN_ENV`, `OOSH_APT_UPDATED`, `OOSH_USER_CONFIG_PATH`, `LOG_NAME`/`DEVICE`/`LIVE`, `SUDO_*`); silent predicate; the one list `config save` and the init.env guard share |
| `private.config.variable.retired.is` | `<name>` → rc 0 for a name an old env file exported that the shared env files keep no more (PATH, OOSH_MODE, `OOSH_USER_CONFIG_PATH`, `OOSH_CONFIG_VERSION`); silent predicate; the `config init.env` guard counts no loss of one |
| `private.config.variable.export.line` | `<variableName>` → one `export NAME="value"` line; rc 1 for unset, array, or an ANSI-C-quoted value |
| `private.config.variables.export` | `<envPrefix> <?sessionSplit>` → the whole body of a generated env file |
| `private.config.string.upper` | `<string>` → upper-cased, without the bash-4 `${var^^}` operator |
| `private.config.required.variables.get` | the required-variable table, as data |
| `private.config.file.resolve` | the effective file for the current `$CONFIG_FILE` |
| `private.config.env.lines.drop` | `<file> <prefix…>` → drops every line starting with a prefix, in place (owner, group, mode kept); an unchanged file is not rewritten; rc 1 + `RESULT` when the file cannot be written |
| `private.config.env.line.append` | `<file> <line>` → appends the line unless it is already there, in place; rc 1 + `RESULT` when the file cannot be written |
| `private.config.env.line.set` | `<file> <name> <line>` → sets the definition of `<name>` in an env file to `<line>`, in place: every `export NAME=`, `export declare NAME=` and `declare -x NAME=` line leaves (the shapes `private.config.env.value.read` reads), `<line>` goes in before the trailing chain block (the `.` and `source` lines at the end), one read and one write (owner, group, mode kept); an unchanged file is not rewritten; rc 1 + `RESULT` when the file cannot be written or `<name>` is no variable name (digits first, or anything but letters, digits and `_`) |
| `private.config.env.value.read` | `<file> <name>` → the value of the last `export NAME=` or `declare -x NAME=` line, read as data and never sourced, one pair of enclosing quotes taken off; rc 1 when there is no such line; silent |
| `private.config.env.names.read` | `<file>` → the name of every variable an `export NAME=` or `declare -x NAME=` line assigns, once each, in order, read as data and never sourced; silent |
| `private.config.host.name.valid` | `<name>` → rc 0 when `<name>` can be the computer name: letters, digits, `-` and `_`, starting with a letter or digit, no dot, at most 63 characters |
| `private.config.shared.oosh.base.get` | the components base the branch folders sit in — the parent of developking's home + `/shared/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/Once.sh`, in the file system's letter case; the one base of `config init.user`'s `<sharedOosh>` check and of its completion; nothing and rc 1 when developking has no home; silent |
| `private.config.shared.config.get` | the shared config directory — the parent of developking's home + `/shared/EAMD.ucp/Scenarios/localhost/EAM/1_infrastructure/Once.sh/sharedConfig`, in the file system's letter case — the letter case of its longest existing prefix, so a path the install has not made yet still gets `/Users/Shared` on macOS (`private.this.path.case.get`, T-CONFIG-SHARED-PATH-CASE-MISSING-CHILD), as does the oosh base, the sibling of `private.config.shared.oosh.base.get`; the one sharedConfig of `config init.shared`, `config init.user` and the heal (`private.oo.heal.path.get`); nothing and rc 1 when developking has no home; silent. A literal lowercase `shared` linked `~/config` as `/Users/shared/…` on macOS (`/Users/Shared`), so every run found the link wrong and relinked it |
| `private.config.orig.import` | `<origDir> <sharedConfig>` → carries an allow-listed few values from a kept-aside `~/config` into the shared config (see below) |

**`private.config.orig.import`** is what `oo heal` calls (`private.oo.heal.env`) for each real `~/config` that
`config init.user` kept as `config.orig.<ts>` — after `config init.env` has filled the shared config, because it
writes into `log.env` and `oosh.env` only when they exist. The old files (`user.env`, `oosh.env`, `log.env` of
`<origDir>`) are read as **data** through `private.config.env.names.read` and
`private.config.env.value.read` — nothing is sourced, because old files may hold code, and
nothing in `<origDir>` is written. The last assignment of a name wins across the three files.

- **Allow-list:** `LOG_LEVEL` (only a level `log.level` offers) goes to the shared `log.env`;
  `OOSH_SSH_CONFIG_HOST` (the computer name — the router domain taken off through
  `private.config.host.name.get`, and it must pass `private.config.host.name.valid`) goes to the shared
  `oosh.env`. There is no e-mail variable in the config model, so none is carried.
- **Never-list:** `PATH`, `HOME`, `LOG_DEVICE`, `OOSH_DIR`, `OOSH_MODE` and `CONFIG_CHAIN_*` are skipped,
  with one summary line. Every other variable gets one info line (`skipped NAME (not carried over)`).
- **Only into empty values.** A value the shared config already has is kept (a missing line counts as
  empty). The line is rendered by `private.this.env.export.line.get` and written by
  `private.config.env.line.set`, so the chain block stays last.
- **RESULT:** `imported: <names or none> | skipped: <count>`. rc 1 for a missing argument (the error is logged, not only returned); rc 2 and
  `cannot write <file> …` when a write failed — the convention of the migrates.

`config` also leans on the kernel's helpers (full list:
[oosh-architecture.md § Kernel helpers](oosh-architecture.md#kernel-helpers)):
`private.this.env.export.line.get` renders every value `private.config.variable.export.line`
writes, `private.this.host.name.get` names the computer, `private.this.file.same` decides
whether a user's `.bashrc` differs from their branch's template, and
`private.this.path.stat.get` reads owners, groups and modes (`config init.check`,
`private.config.linked.homes.get`). The others listed there — `private.this.container.is`,
`private.this.group.create`, `private.this.group.name.get`, `private.this.temp.dir.get` —
serve odocker, os and c2.

The last two are how the migrates (`private.config.log.chain.migrate`,
`private.config.user.session.migrate`, `private.config.oosh.session.migrate`) edit the
shared env files: the chain line goes on first, then the old lines leave, and a failed
write is never a silent success. The migrates answer in one convention: **rc 2** + `RESULT`
`cannot write <file>` for a write that failed, **rc 1** only for a closed gate
(T-CONFIG-MIGRATE-WRITE-FAIL). `config init.user` warns the `RESULT` of a failed write
(visible at the default log level), keeps its info line with `run: sudo oo update` for a
closed gate, and answers rc 1 with a result that names what could not be written
(T-CONFIG-INIT-USER-WRITE-FAIL); `config save` warns too and goes on
(T-CONFIG-SAVE-MIGRATE-WRITE-FAIL). They write in
place, not through `replace commit`: that puts a new file under the name, so a
dev-group user who is not the owner would become the shared file's owner.

The getters of the table above (`private.config.variables.list`, `private.config.variable.export.line`,
`private.config.variables.export`, `private.config.string.upper`, `private.config.required.variables.get`,
`private.config.env.value.read`, `private.config.env.names.read`, `private.config.shared.oosh.base.get`,
`private.config.shared.config.get`, `private.config.host.name.get`) are consumed as `$(…)`, so none calls `create.result` — it runs
in a subshell and the result could never reach the caller. The first three (the generators of an env file's
body) are additionally **silent by contract**: their only caller runs inside
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

A value holding a command substitution `$(` or a backtick is **refused** too. Bash would
escape it and nothing would run, but `config.validate` rejects every line that holds one —
env files are pure data and the validator has no exception — so the writer
(`private.this.env.export.line.get`) gives way, and `config save` never reports its own
file INVALID. A refused variable is not written, and `config save` says so with an error
line naming it. Everything else round-trips as given in bash and every POSIX `sh`: spaces,
quotes, a backslash, `$NAME` or `${NAME}` as literal text (T77,
T-CONFIG-WRITER-VALIDATOR-AGREE). A saved PATH segment is stricter still: one holding any
`$ " \` or backtick is dropped (`private.config.path.segments.get`).

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
