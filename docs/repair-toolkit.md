# Repair toolkit

OOSH ships explicit, idempotent repair primitives for the
post-install drift modes most likely to bite: user symlinks, shared
config perms, SSH rights, SSH layout, and the fixed system boot path. Each primitive has a
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
| [`oo boot.fix`](oo.md#oobootfix) | `/etc/oosh/boot` **and** `/etc/profile.d/oosh.sh` — the fixed host-wide path to `boot`, and the login-shell drop-in that sources it | `. /etc/oosh/boot` says "cannot open"; `env -i sh -l` does not come up as an oosh shell; host installed before install state 34 (`root.boot.path.installed`). `oo boot.status` reports first. Needs root, or `dev` + sudo |
| [`ossh rights.fix`](ossh.md) | `~/.ssh` file modes (600 private, 644 public, 700 dirs) | After SSH client complains about world-readable keys |
| [`ossh folder.fix [strict]`](ossh.md) | `~/.ssh` tree layout (WODA Host blocks, IdentityFile paths, GitHub Host) | After `ssh: Bad configuration option`, missing `2cuGitHub` alias, drag-in legacy artifacts |
| [`oo safeDirectory.prune`](oo.md#oosafedirectoryprune) | Stale entries in `git config --global safe.directory` | After many test runs or repeated installs bloated `~/.gitconfig`; symptom: Cursor / VS Code Source Control panel + branch picker empty |

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
| `oo mode <TAB>` empty | `oo user.fix` |
| `OOSH_DIR=/var/<user>/oosh` (private clone resolved) | `oo user.fix` |
| `~/oosh` is a real directory not a symlink | `oo user.fix` |
| `~/config` not a symlink | `oo user.fix` |
| `Permission denied` writing to `~/config/*.env` | `config init.shared` |
| `sharedConfig` owned by `root:root` or mode `0775` | `config init.shared` |
| `. /etc/oosh/boot` → `cannot open` / `No such file` | `oo boot.fix` |
| Host was installed before state 34 (`root.boot.path.installed`) | `oo boot.fix` |
| `/etc/oosh/boot` exists but dangles, or is a copy instead of a symlink | `oo boot.fix` |
| `env -i sh -l` does not come up as an oosh shell | `oo boot.fix` (the `/etc/profile.d/oosh.sh` drop-in is missing) |
| `/etc/profile.d/oosh.sh` missing, or it names the wrong path | `oo boot.fix` |
| `env -i sh` cannot bootstrap oosh at all | nothing can — see below. Use `. /etc/oosh/boot`, `env -i ENV=/etc/oosh/boot sh`, or `env -i sh -l` |
| `Permissions … are too open` from ssh client | `ossh rights.fix` |
| `ssh: Could not resolve hostname 2cuGitHub` | `ossh folder.fix` |
| Legacy `~/.ssh/2cuGitHub` host block | `ossh folder.fix strict` |

## `oo boot.fix` — why it exists and what it does not promise

`boot` recovers `$HOME` from the password database, so it survives `env -i` —
but only once it is *reached*. With `HOME` unset, dash and ash leave `~`
**literal**, so `. ~/oosh/boot` cannot work in exactly the empty-environment
case `boot` exists to survive (bash falls back to the password database, which
is why nobody noticed). `/etc/oosh/boot` is the fixed path that collapses that
to one command for any user, in any shell, with no environment at all. See
[`boot.md` § The tilde caveat](boot.md).

It is a separate primitive because the existing five cannot absorb it:
`oo user.fix` / `config init.user` are per-user scope and run as the user,
`config init.shared` is host scope but owns `sharedConfig` perms only, and
`ossh rights.fix` / `folder.fix` are `~/.ssh`-only.

**It is not a convenience.** The state-machine declaration is frozen per host at
first install, so an already-installed host will *never* run state 34.
`oo boot.fix` is the only way the fixed path reaches hosts that already exist.

`$SUDO` is used internally, so `oo boot.fix` — not `sudo oo boot.fix` — is the
one command that works whether you are already root or a `dev` member with
sudo. If neither applies it fails loudly naming both, and creates nothing.
Like every primitive here it is **not** auto-triggered: `oo update` runs as an
ordinary user with no sudo.

### Recovery commands — what to type when you have nothing

| Command | Recovers? | Why |
|---|---|---|
| `. /etc/oosh/boot` | **yes** | the explicit form; works in every shell, login or not |
| `env -i ENV=/etc/oosh/boot sh` | **yes** | `$ENV` is a POSIX `sh`'s `~/.bashrc`; this hands the hook back |
| `env -i sh -l` | **yes** | `/etc/profile` loops `/etc/profile.d/*.sh`, and `oo boot.fix` puts `oosh.sh` there |
| `env -i sh` | **no** | `$ENV` is a non-login `sh`'s *only* rc hook, and `env -i` is what erased it |

**Bare `env -i sh` cannot be repaired into self-recovering**, by `oo boot.fix` or by
anything else: there is no hook left to point at `boot`. If that is the shell you are
in, type one of the first three. Two caveats on the `$ENV` form: it is honoured by
**interactive** shells only (do not add `-c`), and bash honours it only when invoked as
`sh` — never under its own name, and never with an explicit `--posix`. Full detail and
the measurements in [`boot.md` § The three recovery routes](boot.md).

The `/etc/profile.d/oosh.sh` half is **Linux-only by fact**: macOS has no
`/etc/profile.d`, so `oo boot.fix` skips it there and says so. That is not a failure —
the other routes still work. The drop-in is guarded twice (the boot path must be
readable, and the caller must actually have `~/oosh` unless `HOME` is unset), so a
login by somebody who has never heard of oosh is a silent no-op.

> **Trust.** `/etc/oosh/boot` points at **dev-group-writable** content: install
> state 31 runs `chmod -R g+w` on the shared tree, so any member of `dev` can
> edit the file it resolves to, and anyone who sources it — root included —
> executes it. This is the *same* trust model as root's existing `~/oosh`, which
> is already a symlink into that same tree; what changed is only that the path
> now *looks* root-owned. Do not treat `/etc/oosh/boot` as
> trusted-because-`/etc`: it is exactly as trusted as the `dev` group.
| `~/.ssh/id_ed25519.previous` / `.bak.*` cruft | `ossh folder.fix strict` |
| Cursor / VS Code Source Control panel and branch picker stay empty although `git branch` works in the terminal; `git config --global --get-all safe.directory \| wc -l` is large (many stale `/tmp/...` entries) | `oo safeDirectory.prune` |

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
