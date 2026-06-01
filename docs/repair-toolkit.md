# Repair toolkit

OOSH ships explicit, idempotent repair primitives for the four
post-install drift modes most likely to bite: user symlinks, shared
config perms, SSH rights, and SSH layout. Each primitive has a
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
| `Permissions … are too open` from ssh client | `ossh rights.fix` |
| `ssh: Could not resolve hostname 2cuGitHub` | `ossh folder.fix` |
| Legacy `~/.ssh/2cuGitHub` host block | `ossh folder.fix strict` |
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
