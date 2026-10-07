# Repair toolkit

OOSH ships explicit, idempotent repair primitives for the
post-install drift modes most likely to bite: user symlinks, shared
config perms, SSH rights and SSH layout. Each primitive has a
single, scoped responsibility (per the `noun.verb` convention).
Implicit auto-repair on every shell startup was deliberately removed
after the May-8 sudo-chain incident — see
[`migration/env-files.md`](migration/env-files.md). The primitives
listed here run only when invoked.

## At a glance

| Primitive | Scope | When to use |
|---|---|---|
| [`oo heal.status`, then `oo heal [<branch>] [all]`](oo.md#ooheal) | The whole computer: group `dev`, `developking`, the canonical base with `main/` and `<branch>/` as clean clones, the `sharedConfig`, the launcher, and `~/oosh` + `~/config` of every healed user; then a verify of four invariants | **Not sure what is wrong.** `oo heal.status` reads and changes nothing; `oo heal` brings the machine to the standard dev model. Three forms: `oo heal` (oosh runs here), `ossh heal <host> [<user>\|all] [<branch>]` (a remote host), and `curl -fsSL https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/<branch>/init/oosh \| sh -s -- heal [<branch>] [all]` (oosh missing, old or broken). rc 0 healed and verified, 1 something is left for you, 2 cannot heal. **Root:** on a host `oo heal` needs a terminal for the one sudo password prompt (asked once, up front) or passwordless sudo; a non-interactive run (no terminal, `OOSH_NO_INSTALL` or `OOSH_HEAL_NONINTERACTIVE` set) uses `sudo -n` only and ends with rc 2 before any change when root is needed and unavailable |
| [`oo user.fix [user]`](oo.md#oouserfix) | `~/config` + `~/oosh` symlinks for one user | After init/oosh re-run, `oo mode <TAB>` empty, `OOSH_DIR` resolves to a private clone |
| [`config init.user [user]`](config.md) | Same as above (canonical underlying call) | Same; preferred when scripting (explicit naming) |
| [`config init.shared`](config.md) | `sharedConfig` dir mode 2775 + group `dev` | After cross-user perm drift, "Permission denied" on shared config writes |
| [`oo update`](oo.md#the-retired-login-drop-in) | removes the retired `/etc/oosh/boot` link and `/etc/profile.d/oosh.sh` drop-in (boot is gone; a shell starts from `~/config/user.env`) | A host installed before boot was removed still has them. May ask for the sudo password once |
| [`ossh rights.fix`](ossh.md) | `~/.ssh` file modes (600 private, 644 public, 700 dirs) | After SSH client complains about world-readable keys |
| [`ossh folder.fix [strict]`](ossh.md) | `~/.ssh` tree layout (WODA Host blocks, IdentityFile paths, GitHub Host) | After `ssh: Bad configuration option`, missing `2cuGitHub` alias, drag-in legacy artifacts |
| [`oo safeDirectory.prune`](oo.md#oosafedirectoryprune) | Stale entries in `git config --global safe.directory` | After many test runs or repeated installs bloated `~/.gitconfig`; symptom: Cursor / VS Code Source Control panel + branch picker empty |
| [`ogit layout.status [base]`](ogit.md#layout) | Read-only report: one line per branch folder under the components base — `clone`/`worktree`, dirty/ahead/behind, `shared=` `setgid=` `trusted=` | First stop for any branch-folder trouble; rc 1 on a mixed layout. No privilege needed |
| [`ogit safeDirectory.ensure [base]`](ogit.md#safedirectory) | One `safe.directory` entry per branch folder, for the calling user | `fatal: detected dubious ownership`; `layout.status` shows `trusted=no`. `oo update` and `oo user.fix` run it for you |
| [`ogit repo.share <dir>`](ogit.md#repo) | One folder's `.git`: group `dev` + g+w, setgid, `core.sharedRepository=group` | `layout.status` shows `shared=no` or `setgid=no`; another dev user gets "Permission denied" writing objects. `sudo` when you do not own the folder |
| [`ogit worktree.remove [base]`](ogit.md#migrating-a-host-from-worktrees-to-clones) | Converts every linked worktree under the base into an independent clone (gated; ignored files carried, backup kept in `~/.oosh.backups/`) | A host installed before the clone layout (`layout.status` shows `worktree` lines); a half-finished conversion. `ogit worktree.restore` is the reverse |
| `user oosh.install <user>` / `oo user.fix` | Backups, never deletions: a real `~/config` or `~/oosh` is kept as `~/config.orig.<ts>` / `~/oosh.orig.<ts>` through `private.this.symlink.with.backup` | See [Backups](#backups) |
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

- **`oo update`** pulls through a gate (a fetch and a fast-forward, never a merge; a merge or
  rebase in progress, committed conflict markers, uncommitted changes, a detached HEAD or a diverged branch is
  refused with the one command to run) and then, **whether or not the pull happened**, runs the heal
  steps: `config init.user $USER` re-applies the symlinks (idempotent, silent when nothing has drifted —
  the case where init/oosh was re-run out of band), and `private.oo.heal.shell`, the shell step `oo heal` runs
  for every user, covers git trust of every branch folder under the base (`ogit safeDirectory.ensure`, skipped
  quietly when there is no base yet) and no dead `safe.directory` entry, the oosh `.bashrc` and the session
  files, the retired login drop-in, the launcher, and a frozen `PATH` line in `~/.once`. With committed conflict
  markers the steps that load scripts are skipped and `oo heal` is named. See
  [`oo.md` § `oo.update`](oo.md#ooupdate).
- **`ossh install …`** (state machine state 31) calls
  `private.oo.user.shared.symlinks.ensure` for `$HOME` to set up
  root's symlinks on every install pass. Idempotent.

Outside those two entry points (and never at shell start), the user runs the primitives
explicitly when something drifts.

## Backups

The install and the repairs keep what they replace, with a timestamp, and never
delete it. Everywhere the move-aside is the kernel's `private.this.entry.aside`
(`private.this.symlink.with.backup`, `oo deinstall` and the heal share it):

- A real `~/config` or `~/oosh` becomes `<name>.orig.<ts>` (one `<ts>` for both)
  and the symlink takes its place. A backup is **never nested**: when
  `<name>.orig.<ts>` already exists (a second run in the same second) the stamp is
  bumped (`<ts>-1`, `<ts>-2`), so a second run gives a second stamp and a real
  directory is not moved *into* the first backup. A stale symlink that is relinked
  is logged with its old target.
- A `.bashrc` hand-edited after the install is kept as `.bashrc.orig.<ts>` (the very
  first original stays `.bashrc.pre-oosh`); an unchanged repeat adds no copy.
- `oo deinstall` keeps `~/config`, `~/init`, `~/.once`, `~/.bashrc`, `~/oosh` and an older
  `~/install.oosh` the same way, after it asked for the word `deinstall` (or `--yes`).
- A broken **canonical** folder (`main/` or `<branch>/` of the base, with a merge in progress, markers, changes,
  a detached HEAD or a diverged history) is moved by `oo heal` to `<base>.aside/<name>.orig.<ts>` (`private.this.entry.aside <path> <?ts> <?asideDir>`), a sibling of the
  base, so it is never mistaken for a branch folder. It is reported and left for you to look at, never deleted.
- `init/deinstall.oosh` is **retired**: it removed `/home/shared`, `~/oosh`, `~/config` and `developking`
  without asking. It refuses now and points at `oo deinstall`. `oo tmp.cleanup.testing` refuses too.

## Diagnostic: which primitive do I need?

| Symptom | Run |
|---|---|
| I do not know what is wrong with this computer | `oo heal.status` (read-only), then `oo heal` — or, when oosh is missing or broken: `curl -fsSL https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/<branch>/init/oosh \| sh -s -- heal [<branch>] [all]` |
| `oo update` says the pull was refused (merge in progress, conflict markers, diverged, detached, dirty) | the one command its message names; `oo heal` for markers and a diverged tree |
| Root-owned `ssh.*` directories in my home that I cannot read | `user ssh.backup.status`, then `user ssh.backup.migrate` |
| `oo mode <TAB>` empty | `oo user.fix` |
| `config save` says the shared `user.env` keeps its PATH line until every user has `~/.config/oosh/user.session.env` | `sudo oo update` — as root it gives every linked user their file and switches the shared config ([config.md](config.md) § *The switch and its gate*) |
| `. …/user.session.env: not found` / a plain `sh` stops at login | `oo user.fix` (as root: `oo user.fix <user>`) — creates and fills the user's own file |
| `env -i sh`, then `this`: `this: not found` | `sudo oo update` — installs the launcher `/usr/local/bin/this` |
| `env -i sh`, then `bash`: `/config/oosh.env: No such file or directory` | `oo user.fix` — re-installs the `.bashrc` that loads `this` first |
| `OOSH_DIR=/var/<user>/oosh` (private clone resolved) | `oo user.fix` |
| `~/oosh` is a real directory not a symlink | `oo user.fix` |
| `~/config` not a symlink | `oo user.fix` |
| `Permission denied` writing to `~/config/*.env` | `config init.shared` |
| `sharedConfig` owned by `root:root` or mode `0775` | `config init.shared` |
| `/etc/profile.d/oosh.sh` or `/etc/oosh/boot` still present (boot was removed) | `oo update` |
| A shell without `.bashrc` (cron, `ssh host cmd`) has no oosh | `. ~/config/user.env` — or `source ~/oosh/this`, which reads it itself |
| `Permissions … are too open` from ssh client | `ossh rights.fix` |
| `ssh: Could not resolve hostname 2cuGitHub` | `ossh folder.fix` |
| Legacy `~/.ssh/2cuGitHub` host block | `ossh folder.fix strict` |
| `~/.ssh/id_ed25519.previous` / `.bak.*` cruft | `ossh folder.fix strict` |
| `fatal: detected dubious ownership in repository` in a branch folder | `oo update` (runs `ogit safeDirectory.ensure`), or `ogit safeDirectory.ensure` directly |
| `ogit layout.status` shows `worktree` lines (host installed before the clone layout) | `ogit worktree.remove` — runbook: [ogit.md § Migrating a host](ogit.md#migrating-a-host-from-worktrees-to-clones) |
| `ogit layout.status` says `mixed layout` (rc 1) | finish the conversion you started: `ogit worktree.remove` (or `ogit worktree.restore` to go back) |
| `ogit layout.status` shows `shared=no` / `setgid=no` for a folder | `ogit repo.share <base>/<folder>` (with `sudo` when you do not own it) |
| `test.platform.shared.layout.invariant` red | the recovery command in its FAIL line — one of the four rows above, or `sudo chgrp dev <base> && sudo chmod g+ws <base>` for the base |
| `promote` refuses with `no folder holds branch testing` | `oo checkout testing`, then re-run `promote testing` |
| Cursor / VS Code Source Control panel and branch picker stay empty although `git branch` works in the terminal; `git config --global --get-all safe.directory \| wc -l` is large (many stale `/tmp/...` entries) | `oo safeDirectory.prune` |

## Shells start from `~/config/user.env`

There is no `boot` any more, and no host-wide login drop-in. `.bashrc` sources
`~/config/user.env`; a shell that never runs `.bashrc` gets there through
`source ~/oosh/this` or — for commands over ssh, `runuser`/`sudo -u` and
`docker exec` — through `ossh.remote.prelude.get`. If an oosh command is not found,
check the layout with `./test.suite run platform.shared.configLayout.invariant 1`;
`config save` and `config init.user` repair it. See
[config.md § The PATH line](config.md#the-path-line).

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

# Branch folders (the clone layout)
ogit layout.status               # every line: clone, shared=group setgid=yes trusted=yes

# SSH
ls -la ~/.ssh                    # private keys 600, dirs 700
ssh -G 2cuGitHub 2>&1 | head -5  # resolves the WODA alias
```

The platform-category test
[`test.platform.shared.oosh.invariant`](../test/test.platform.shared.oosh.invariant)
asserts the user-symlink invariant programmatically;
[`test.platform.shared.layout.invariant`](../test/test.platform.shared.layout.invariant)
asserts the clone layout (every folder a clone, shared, setgid, trusted;
the base group `dev` with setgid). The core test
`T-MODE-COMPLETION-REAL-ENV` (in `test/test.oo`) catches the
"`~/oosh` is a real dir" regression class with a precise diagnostic
that includes the recovery command.

## See also

- [`oo.md`](oo.md) § `oo.heal`, `oo.update`, `oo.user.fix`, `oo.deinstall`
- [`config.md`](config.md) § Repair primitives
- [`ossh.md`](ossh.md) § Repairing `~/.ssh`
- [`ogit.md`](ogit.md) § Layout, § Migrating a host from worktrees to clones
- [`migration/env-files.md`](migration/env-files.md) §
  Why explicit rather than automatic
- [`test-suite.md`](test-suite.md) § Diagnostic-rich assertions
