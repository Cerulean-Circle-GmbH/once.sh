# Repair toolkit

OOSH ships explicit, idempotent repair primitives for the
post-install drift modes most likely to bite: user symlinks, shared
config perms, SSH rights, SSH layout, and the login-shell drop-in. Each primitive has a
single, scoped responsibility (per the `noun.verb` convention).
Implicit auto-repair on every shell startup was deliberately removed
after the May-8 sudo-chain incident — see
[`migration/env-files.md`](migration/env-files.md). The primitives
listed here run only when invoked.

## At a glance

| Primitive | Scope | When to use |
|---|---|---|
| [`oo user.fix [user]`](oo.md#oouserfix) | `~/config` + `~/oosh` symlinks for one user | After init/oosh re-run, `oo mode <TAB>` empty, `OOSH_DIR` resolves to a private clone |
| [`config init.user [user]`](config.md) | Same as above (canonical underlying call) | Same; preferred when scripting (explicit naming) |
| [`config init.shared`](config.md) | `sharedConfig` dir mode 2775 + group `dev` | After cross-user perm drift, "Permission denied" on shared config writes |
| [`oo profile.status`](oo.md#ooprofilestatus) | Read-only report on `/etc/profile.d/oosh.sh`: missing, stale (still sources the retired `/etc/oosh/boot`) or OK; N/A on macOS | Before `oo profile.fix`; rc 1 when the drop-in needs repair, no privilege needed |
| [`oo profile.fix`](oo.md#ooprofilefix) | `/etc/profile.d/oosh.sh` — the login-shell drop-in that recovers `$HOME` and sources `~/config/user.env` | `env -i sh -l` does not come up as an oosh shell; host installed before install state 34 (`root.profile.dropin.installed`). `oo profile.status` reports first. Needs root, or `dev` + sudo |
| [`ossh rights.fix`](ossh.md) | `~/.ssh` file modes (600 private, 644 public, 700 dirs) | After SSH client complains about world-readable keys |
| [`ossh folder.fix [strict]`](ossh.md) | `~/.ssh` tree layout (WODA Host blocks, IdentityFile paths, GitHub Host) | After `ssh: Bad configuration option`, missing `2cuGitHub` alias, drag-in legacy artifacts |
| [`oo safeDirectory.prune`](oo.md#oosafedirectoryprune) | Stale entries in `git config --global safe.directory` | After many test runs or repeated installs bloated `~/.gitconfig`; symptom: Cursor / VS Code Source Control panel + branch picker empty |
| `user ssh.backup.status` | Legacy `$HOME/ssh.*` backup directories | A root-owned `ssh.original` or `ssh.<user>.<host>.for.<host>` in your home. Reports only, works unprivileged, rc 1 when it finds any |
| `user ssh.backup.migrate` | The same, acting | Moves them under `~/.ssh.backups/legacy/`. **Moves, never deletes** — they hold private keys. Needs `$SUDO` when they belong to another user |

## How they relate

```text
  ┌────────────────────────────────────────────────────────────┐
  │  user-level layout            shared-host state            │
  │                                                            │
  │  ~/config  ──symlink──┐       /home/shared/…/sharedConfig  │
  │  ~/oosh    ──symlink──┤       /home/shared/…/Once.sh/<br>  │
  │                       │                                    │
  │       ┌───────────────▼───────────────┐                    │
  │       │  oo user.fix                  │                    │
  │       │  = config init.user           │                    │
  │       │  (idempotent)                 │                    │
  │       └───────────────────────────────┘                    │
  │                                                            │
  │  ~/.ssh/ids/…           ┌────────────────────────┐         │
  │  ~/.ssh/config          │  ossh folder.fix       │         │
  │  ~/.ssh/authorized_keys │  ossh rights.fix       │         │
  │                         └────────────────────────┘         │
  │                                                            │
  │       ┌───────────────────────────────┐                    │
  │       │  config init.shared           │                    │
  │       │  → sharedConfig perms 2775    │                    │
  │       │    group dev                  │                    │
  │       └───────────────────────────────┘                    │
  └────────────────────────────────────────────────────────────┘
```

## Auto-trigger surfaces

The repair primitives are *not* run from shell startup, but two
explicit user actions invoke them silently as part of their flow:

- **`oo update`** (every successful `git pull`) calls
  `config init.user $USER` to re-apply symlinks. Idempotent and
  silent when nothing's drifted. This covers the common case
  where init/oosh was re-run out of band — see
  [`oo.md` § `oo.update`](oo.md#ooupdate).
- **`ossh install …`** (state machine state 31) calls
  `private.oo.user.shared.symlinks.ensure` for `$HOME` to set up
  root's symlinks on every install pass. Idempotent.

Outside those two entry points, the user runs the primitives
explicitly when something drifts.

## Diagnostic: which primitive do I need?

| Symptom | Run |
|---|---|
| Root-owned `ssh.*` directories in my home that I cannot read | `user ssh.backup.status`, then `user ssh.backup.migrate` |
| `oo mode <TAB>` empty | `oo user.fix` |
| `OOSH_DIR=/var/<user>/oosh` (private clone resolved) | `oo user.fix` |
| `~/oosh` is a real directory not a symlink | `oo user.fix` |
| `~/config` not a symlink | `oo user.fix` |
| `Permission denied` writing to `~/config/*.env` | `config init.shared` |
| `sharedConfig` owned by `root:root` or mode `0775` | `config init.shared` |
| Host was installed before state 34 (`root.profile.dropin.installed`) | `oo profile.fix` |
| `env -i sh -l` does not come up as an oosh shell | `oo profile.fix` (the `/etc/profile.d/oosh.sh` drop-in is missing) |
| `/etc/profile.d/oosh.sh` missing, or it no longer sources `~/config/user.env` | `oo profile.fix` |
| `env -i sh` cannot bootstrap oosh at all | nothing can — see below. Use `env -i sh -l`, or `. ~/config/user.env` with `HOME` set |
| `config validate required` says `INCOMPLETE … anchor:OOSH_DIR=…` | `config save` — the host's `user.env` predates the anchor lines |
| `test.platform.shared.config.invariant` red after a pull | `config save` |
| a `/bin/sh` login dies at `log.session.env: No such file` | `config save` — the legacy chain line is still in `log.env` |
| `.bashrc` still sources a `boot` that no longer exists | `config init.user <user>` re-templates it |
| `Permissions … are too open` from ssh client | `ossh rights.fix` |
| `ssh: Could not resolve hostname 2cuGitHub` | `ossh folder.fix` |
| Legacy `~/.ssh/2cuGitHub` host block | `ossh folder.fix strict` |
| `~/.ssh/id_ed25519.previous` / `.bak.*` cruft | `ossh folder.fix strict` |
| Cursor / VS Code Source Control panel and branch picker stay empty although `git branch` works in the terminal; `git config --global --get-all safe.directory \| wc -l` is large (many stale `/tmp/...` entries) | `oo safeDirectory.prune` |

## `oo profile.fix` — why it exists and what it does not promise

The bootstrap is DATA in `~/config/user.env`, at a `$HOME`-relative path. A shell that
has `HOME` can always type `. ~/config/user.env`; a shell started by `env -i` has no
`HOME` at all. `/etc/profile.d/oosh.sh` is what closes that gap for LOGIN shells: it
derives `$HOME` (getent → dscl → `/etc/passwd`) and then sources the file.

It is a separate primitive because the existing ones cannot absorb it:
`oo user.fix` / `config init.user` are per-user scope and run as the user,
`config init.shared` is host scope but owns `sharedConfig` perms only, and
`ossh rights.fix` / `folder.fix` are `~/.ssh`-only.

**It is not a convenience.** The state-machine declaration is frozen per host at
first install, so an already-installed host will *never* run state 34.
`oo profile.fix` is the only way the drop-in reaches hosts that already exist.

`$SUDO` is used internally, so `oo profile.fix` — not `sudo oo profile.fix` — is the
one command that works whether you are already root or a `dev` member with
sudo installed. If sudo is absent it fails loudly before creating anything (a user without sudo rights meets sudo's own denial).
Like every primitive here it is **not** auto-triggered: `oo update` runs as an
ordinary user with no sudo.

### Recovery commands — what to type when you have nothing

| Situation | Command |
|---|---|
| `env -i sh -l` does not come up as oosh (Linux) | `oo profile.fix` — needs root, or `dev` + sudo; `$SUDO` is used internally, so do **not** type `sudo oo profile.fix` |
| any shell, `HOME` set | `. ~/config/user.env` — the explicit form, login shell or not |
| a host whose `user.env` predates this change | `config save` — adds the anchor lines, and drops the legacy per-user chain line from `log.env` |
| a user whose `.bashrc` still has the old hook | `config init.user <user>` — re-templates it from `templates/user/bashrcTemplate` |

**Bare `env -i sh` cannot be repaired into self-recovering**, by `oo profile.fix` or by
anything else: `$ENV` is a non-login `sh`'s *only* rc hook and `env -i` is what erased it,
and there is no fixed absolute path left to source by hand — `~/config/user.env` needs a
`$HOME`, and with `HOME` unset a POSIX shell leaves `~` literal. If that is the shell you
are in, add `-l`, or set `HOME` and source the file.

### Migrating a host that predates this

This is the note to read before concluding a host is broken.

A host that pulled this change but has **not re-run `config save`** has a `user.env` with
no anchor lines in it. Two things follow:

- **It still works.** `this` degrades gracefully: at file scope it defaults `CONFIG_PATH`
  and `OOSH_USER_CONFIG_PATH` *before* sourcing the file, so the `. $CONFIG_PATH/oosh.env`
  chain inside it still resolves. `bashrcTemplate`'s `elif [ -d "$HOME/oosh" ]` branch
  covers the case where the file is missing altogether.
- **But it reports red.** `config validate required` returns INCOMPLETE naming each missing
  `anchor:…` line, and the shared-config platform invariant
  (`test.platform.shared.config.invariant`) stays red until the save runs.

The fix is one command: **`config save`**.

One narrow case is worth knowing about, because it is the only one that is not merely
cosmetic. A host whose `log.env` still carries the legacy last line

```sh
. $OOSH_USER_CONFIG_PATH/log.session.env
```

**and** which has never had that per-user file created would abort under dash — a failed
`.` ends a POSIX shell. `config save` fixes that too: it regenerates `log.env` as pure
`export LOG_*` data with no chain line, and `log` creates and sources the per-user file
itself. In practice the window is tiny: any host that has ever been logged into already
has `~/.config/oosh/log.session.env`, and both `this` and `log` touch-guard it anyway.

The drop-in is **Linux-only by fact**: macOS has no `/etc/profile.d`, so
`oo profile.fix` skips it there and says so. That is not a failure — the data route
still works. The drop-in is guarded (`~/config/user.env` must exist), so a login by
somebody who has never heard of oosh is a silent no-op.

> **Trust.** The drop-in sources `~/config/user.env`, which lives in the **dev-group-writable**
> shared config tree: install state 31 runs `chmod -R g+w` on it, so any member of `dev` can edit
> the file every login shell then sources. That trust model is **unchanged** — root's own `~/oosh`
> and `~/config` are already symlinks into the same tree. The drop-in is exactly as trusted as the
> `dev` group, no more.

## Verification: am I healed?

Self-check after running any primitive:

```bash
# User symlinks
ls -la ~/config ~/oosh           # both should be symlinks
oo mode                          # current mode prints; doesn't error
oo mode <TAB><TAB>               # branch list non-empty

# Shared config (run from any dev-group user)
stat -c "%a %G" $(readlink ~/config)   # 2775 dev   (Linux)
stat -f "%Lp %Sg" $(readlink ~/config) # 2775 dev   (macOS)

# SSH
ls -la ~/.ssh                    # private keys 600, dirs 700
ssh -G 2cuGitHub 2>&1 | head -5  # resolves the WODA alias
```

The platform-category test
[`test.platform.shared.oosh.invariant`](../test/test.platform.shared.oosh.invariant)
asserts the user-symlink invariant programmatically. The core test
`T-MODE-COMPLETION-REAL-ENV` (in `test/test.oo`) catches the
"`~/oosh` is a real dir" regression class with a precise diagnostic
that includes the recovery command.

## See also

- [`oo.md`](oo.md) § `oo.user.fix`, `oo.update`
- [`config.md`](config.md) § Repair primitives
- [`ossh.md`](ossh.md) § Repairing `~/.ssh`
- [`migration/env-files.md`](migration/env-files.md) §
  Why explicit rather than automatic
- [`test-suite.md`](test-suite.md) § Diagnostic-rich assertions
