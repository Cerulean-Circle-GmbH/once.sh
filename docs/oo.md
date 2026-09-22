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
oo method.new myscript.mymethod

# Update oosh from GitHub
oo update

# Check current mode/branch
oo mode
```

## OOSH Lifecycle

The recommended development workflow:

```
1. oo mode dev        → Switch to dev branch for development
2. oo update          → Pull latest changes from GitHub
3. [develop]          → Make your changes
4. oo commit          → Commit and push to dev branch
5. oo dev.to.testing  → Promote dev to testing (gated by core tests)
6. oo testing.to.prod → Promote testing to prod (gated by platform tests)
7. oo mode dev        → Return to dev for next cycle
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

### oo.method.new

Adds a new method to an existing script, and its test case to that script's test file, from
`templates/code/newMethod` and `templates/code/newMethodTest`. Interactive.

```bash
oo method.new myscript.mymethod
oo method.new myscript.certificates.update.run    # every dot segment is part of the method name
oo method.new private.myscript.mymethod           # a private method goes into myscript
```

**A private method's script is the SECOND segment.** `private.config.variables.list` is a method of
`config`, not of a file called `private`. Until 2026-09-17 the tool split on the first segment,
aimed at `$OOSH_DIR/private` and refused with rc 3 — so it could not create a private method at
all, and every one in the tree was hand-written. Private methods also get **no completion stub**:
they are never dispatched from the command line, and `test/test.completion.audit` skips `private*`
for the same reason.

Five prompts, in order, all asked **before** any file is touched:

| Prompt | Lands in |
|---|---|
| Parameters, e.g. `<branch> <?force:no>` | the method **docstring**, and one completion stub per parameter |
| One-line description | the method **docstring** |
| Test description | the `test.case` label |
| Test arguments | the call under test |
| Expected `$RESULT` | the `expect` |

**The docstring is the single source.** `this.help` renders it and `c2` completes from it, so a
method without one does not appear in help and does not tab-complete — the Method Structure
Standard in [oosh-architecture.md](oosh-architecture.md) calls that broken. The tool therefore also
emits a `myscript.mymethod.completion.<param>()` per parameter, or the documented empty form
`myscript.mymethod.completion() { :; }` for a method that takes none. Fill in the candidates; the
stub is a placeholder, not an answer.

**It does not touch the usage table.** Scripts like `oo`, `user` and `line` carry a hand-written
`METHOD / DESCRIPTION` table in their `usage()`, above the `this.help` call that renders the same
information from docstrings. Generating a row there would put the description in two places and let
them drift. Until 2026-09-16 the tool tried, looking for a dash pattern the script template does not
contain, and mangled the Examples block into `mymethod------` while dropping the description
entirely.

**Insertion is a whole-line, exactly-one-match transaction** (`replace line`, not `replace within`).
The `### new.method` and `### test.method` markers must each appear exactly once as a line of their
own; the tool refuses and changes nothing otherwise. A substring search would rewrite the marker
text wherever else it appears — including inside this tool's own source.

Requires the markers to be present. `templates/code/newScript` and `templates/code/newScriptTest`
carry them, and each template re-emits the marker after what it inserts, so the next call has
somewhere to go. Scripts without a `<script>.start` dispatcher — `debug` — are not
method-scripts and deliberately have no marker.

### oo.test.new

Creates a test file for a script.

```bash
oo test.new myscript
```

Creates `test/test.myscript` from `templates/code/newScriptTest`.

## Version Control

### oo.mode

With no argument, shows current branch status and git remote configuration.
With a branch, switches to that branch's worktree.

```bash
oo mode
# Output:
# git branch is: * dev
# OOSH_MODE=dev

oo mode dev        # switch to the dev worktree
oo mode testing
```

The branch is an **argument**, not part of the method name — `oo.mode()` takes
`<?branch>`. Tab completion offers the available worktree branches.

### The worktree layout

Every `oo mode*` verb assumes one on-disk shape, and it is a **contract**, not a
convention:

```
<base>/
├── main/          ← the repository. .git is a real DIRECTORY
├── dev/           ← a linked worktree. .git is a FILE: "gitdir: …/main/.git/worktrees/dev"
└── prod/          ← likewise
```

`main` is load-bearing. `oo.mode.base.get` has four strategies and the three that
work without an environment variable all key on a directory **named** `main`:
the first worktree in `git worktree list` being called `main`, a sibling `main/`
next to a linked worktree, or being `main/` itself. A layout with no `main/` is
undetectable — which is exactly the bug
[item 7](research/2026-09-16-item7-oo-mode-setup.md) fixed.

`$OOSH_COMPONENTS_DIR` is the fourth route, and it is **process-scoped only**:
`config` excludes it from every save on purpose. Do not rely on it surviving a
shell. Build the layout instead.

### oo.mode.setup

Converts a plain clone into that layout and points `~/oosh` at it.

```bash
oo mode.setup                 # base defaults to the clone's parent directory
oo mode.setup /var/dev/trees  # or name the base explicitly
```

It copies the clone to `<base>/main`, verifies that copy is a real repository,
removes the original, adds `<base>/<branch>` as a worktree, and **checks that
`oo.mode.base.get` can find the base with `OOSH_COMPONENTS_DIR` unset** before
it touches `~/oosh`. If that check fails it stops with the layout built and the
old symlink intact.

It is a no-op when `<base>/main` already exists as a repository, and it refuses
rather than guessing when `<base>/main` exists but is not one, when the source
has no detectable branch, or when `~/oosh` is a real directory rather than a
symlink.

The layout itself is built by `private.oo.shared.tree.from.local` — the same
helper install state 31 uses, so there is one definition of "canonical".

### oo.mode.base.get / oo.mode.base.set

`oo mode.base.get` prints the components base, or returns 1 when no layout is
detectable. `oo mode.base.set <path>` sets it **for the current process only** —
it is not persisted, whatever its output suggests. For a base that survives the
shell, run `oo mode.setup`.

### oo.checkout

Bring a remote branch onto this machine — as a worktree when the canonical
layout is there, as a plain clone when it is not.

```bash
oo checkout testing              # → <base>/testing
oo checkout feature/my-thing     # → <base>/my.thing   (prefix stripped, / → .)
```

The directory name is derived, not copied: a leading `test/`, `feature/` or
`bugfix/` is stripped and the remaining slashes become dots, so
`feature/my-thing` lands at `my.thing` and `oo mode my.thing` works.

Which mode it takes depends on `oo.mode.base.get` — see
[§ The worktree layout](#the-worktree-layout). With a base it runs
`git worktree add` under it; without one it clones as a sibling of `~/oosh`,
taking the remote URL from the existing checkout.

**It does not pull.** A branch that is already present is reported and left
alone, with a pointer to `oo update`. That is deliberate: pulling belongs to
`oo update` and merging belongs to `promote` / `oo stage`, and conflating them
here meant `oo checkout dev` silently fetched and merged `origin/dev` — a
surprise from a command whose name says checkout. The one thing it *will*
change is a worktree whose git branch has drifted from its directory name: it
checks the branch out again to realign them, which is what `oo mode` assumes.

`create.result` on every branch and `return $(result)` at the end, so it can be
chained and its status trusted. On a failed clone it removes the half-made
directory rather than leaving one behind.

### oo.use

Run one command from another branch **without switching**.

```bash
oo use main ossh status          # run main's ossh, stay on dev
oo use testing test.suite core 1
```

The branch directory is found under the worktree base, falling back to a
sibling of `~/oosh`. The command is then executed with `OOSH_DIR` pointed at
that branch — a scoped child-process override, which is the one sanctioned
exception to the `OOSH_DIR` anchor rule (`oosh-dir-exception` in the code;
[oosh-architecture.md § Sanctioned exceptions](oosh-architecture.md#sanctioned-exceptions)). There is no symlink alternative
by design: the symlink is what `oo mode` moves, and `use` must not move it.

Its exit status is **the command's own**, deliberately — it is a runner, so a
failure in the target branch has to reach you unchanged. A missing branch or a
missing command is a refusal with `create.result` before anything runs.

It exports the logging stubs before handing over, because older branches call
`console.log` / `important.log` during their own bootstrap. `info.log` is
pointedly **not** exported — `log` uses its existence as a bootstrap guard, so
exporting it would stop the target branch loading its own logging.

### oo.method.delete

Remove a method from a script, with its completion functions.

```bash
oo method.delete path.status         # the method and every path.status.completion.*
```

The counterpart of [`oo method.new`](#oomethodnew), and it exists for the same
reason: a method is a **block**, not a line — its docstring, its body and one
completion function per parameter. Deleting one by hand takes the body and
leaves the rest orphaned, which is how `path` came to carry completion
functions for verbs it no longer had.

Built on `replace block`, so the `.bak`/`.new` transaction and the
exactly-one-match refusal come for free. It handles the one-liner completion
form (`x.completion.y() { echo a; }` has no closing brace *line*, so the block
form alone would run past it).

**It does not delete the test case.** A test case has no delimiters — a
`test.case` line, a call and one or more `expect`s, freely interleaved with
fixtures — so guessing its extent would silently eat assertions. Test
references and private helpers named after the method are **reported** instead,
for you to remove deliberately.

A legacy `private.` helper whose name carries no script segment
(`private.update.config` lived in `path`, but nothing in the name said so) is
out of its reach; remove one of those with the command this is built on:
`replace block <file> "<its first line>" "}" by ""`.

### The rest of the mode family

Short, because each one does what its name says — but they were undocumented,
so `oo <TAB>` offered verbs with nothing behind them.

| Verb | What it does |
|---|---|
| `oo mode.list` | the branches available as worktrees, with each one's git status |
| `oo branch.list <?source:all>` | branches from `worktrees`, local `git`, and/or `remote` — `all` merges them |
| `oo mode.align` | checks the git branch out again to match the worktree's directory name, for a tree that has drifted. `oo checkout` does the same repair for a branch it is asked to bring in |
| `oo mode.stage <stage>` | promote a stage forward (`dev` → `testing` → `prod`). An alias of `oo stage`; the pipeline itself is [§ Promotion Commands](#promotion-commands-via-oo-wrappers) and lives in `promote` |
| `oo prereqs.install` | install the install-time prereqs locally — `git`, `curl`, and `bash` 4+ when the running shell is older. Called by `init/oosh` through `ossh prereqs.install`; you rarely type it |
### oo.update

Pulls latest changes from GitHub, then self-heals user symlinks.

```bash
oo update
```

After a successful `git pull`, `oo update` delegates to
`config init.user $USER` to re-apply the canonical `~/config` +
`~/oosh` symlinks. This catches the case where `init/oosh` has been
re-run out of band (e.g. a curl one-liner from the README) and
clobbered the symlinks — `oo mode <TAB>` would otherwise show
nothing. The heal is idempotent (no-op when symlinks are already
canonical) and silenced during the pre-install bootstrap when
`developking` doesn't yet exist. See
[Repair toolkit](repair-toolkit.md) for the full primitive set.

### oo.user.fix

Repair the current user's `~/config` + `~/oosh` symlinks to the
canonical shared tree. Thin alias for [`config init.user`](config.md).

```bash
oo user.fix              # repair this user (= $USER)
oo user.fix developking  # repair another user (requires root)
```

Handles real-dir → symlink conversion (preserves originals as
`oosh.orig.<ts>` / `config.orig.<ts>`), ownership, branch detection,
and `dev`-group membership. Idempotent — calling it on an
already-correct layout is a no-op. Naming follows the OOSH
`noun.verb` convention and the existing `ossh.rights.fix` /
`ossh.folder.fix` per-scope pattern. See
[Repair toolkit](repair-toolkit.md) for related primitives.

### oo.profile.fix

Install or repair the login-shell drop-in `/etc/profile.d/oosh.sh` (from
`templates/user/profile.d.oosh.sh`) — the one thing that makes `env -i sh -l`
come up as an oosh shell. `/etc/profile` loops `for i in /etc/profile.d/*.sh`,
so the drop-in is read on every login; it recovers `$HOME` from the password
database and then sources `~/config/user.env`, which carries the anchors, the
env chain and the PATH prepend as data.

```bash
oo profile.status              # read-only report first
oo profile.fix                 # install or repair the drop-in
oo profile.fix <profileDir>    # a fixture path, for tests
```

`<?profileDir:/etc/profile.d>` is optional. Written during install by state
**`34 root.profile.dropin.installed`**; because the state-machine declaration
is frozen per host at first install, `oo profile.fix` is the only way onto
hosts that already exist. `$SUDO` is used internally — run `oo profile.fix`,
not `sudo oo profile.fix`; it fails loudly before creating anything when sudo
is absent. Idempotent, never auto-triggered. On a host without
`/etc/profile.d` (macOS) it skips and says so. See also
[Repair toolkit](repair-toolkit.md).

### oo.profile.status

Read-only report on the drop-in — present, readable, and whether it sources
`~/config/user.env` — with the recovery command when not. Same optional
parameter as `oo profile.fix`. Emits on plain stdout, so it answers at any log
level; rc 0 only when the drop-in is healthy.

### oo.safeDirectory.prune

Remove entries from git's global `safe.directory` list whose paths
no longer exist on disk.

```bash
oo safeDirectory.prune
```

Walks `git config --global --get-all safe.directory`, drops entries
pointing at paths that no longer exist (typical sources: `/tmp/...`
test fixtures, removed worktrees, stale install dirs), and leaves
real paths untouched. Idempotent — a clean list logs *"No stale
entries to prune"* at log level ≥ 4 and exits 0.

Honours `$GIT_CONFIG_GLOBAL` so tests and ad-hoc scripts can
sandbox without touching the user's real `~/.gitconfig` (the
sandbox pattern is the reason this primitive exists — see
[Repair toolkit](repair-toolkit.md) §Cursor / VS Code branches
missing).

The primitive is **explicit and read-then-rewrite**. There is
deliberately no auto-invocation from shell startup or from
read-only methods such as `oo.mode.list` — repair belongs to
explicit primitives per the post-May-8 architectural rule (see
[`migration/env-files.md`](migration/env-files.md)).

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

The two-argument form installs a package whose name differs from the command:

```bash
oo cmd sshd openssh-server   # command is sshd, package is openssh-server
```

Special cases:
- `update` - Refreshes the package-manager cache (`apt-get update` / `dnf makecache` / `yum makecache`)
- `errno` - Installs python3
- `eamd`, `oosh`, `once` - Loads from the ONCE repository; fails naming `once` when it is not installed
- `mkcert` - Delegates to `once.su.mkcert.install`; fails naming it when undefined
- `brew` - Bootstraps Homebrew on macOS only

**Result contract.** `oo cmd` returns **0 only when `<cmd>` is on PATH afterwards** — it captures the
package manager's exit status *and* re-verifies with `private.oo.cmd.verify`, because a package
manager reporting success is not the same as the command being usable (the macOS
installed-but-not-on-PATH case). `$RESULT` carries the reason on failure. Callers may branch on it:

```bash
oo cmd rsync || warn.log "rsync is not available"
```

Until 2026-09-15 it always returned 0 — its last statement was a bare `RETURN=$1` assignment, so its
exit status was that of a variable assignment whatever the package manager did, and every caller
that checked it was dead code.

**From inside a script, source `oo` and call `oo.cmd`**, not `oo cmd`: the exit status crosses a
subprocess boundary but `$RESULT` (the reason) does not. `ossh.prereqs.install` and `ossh.status`
do it this way.

**Chaining limit.** `<packageName>` is optional and positional, so `oo cmd X cmd Y` cannot chain —
the second `cmd` is read as X's package name. Use one `oo cmd` per line.

### oo.cmd.find

Searches apt repositories for a command. The method is `oo.cmd.find` — this
section said `oo.find.cmd` for as long as it has existed, which is a verb that
has never dispatched.

```bash
oo cmd.find htpasswd
```

### Deprecated and dangerous verbs

Tab completion offers these. They are listed here so nobody discovers what they
do by running one.

| Verb | Status |
|---|---|
| `oo tmp.cleanup.testing` | **DESTRUCTIVE.** Removes oosh *and SSH keys* from the machine completely. It exists for tearing down a throwaway test host. Never run it on a machine you care about |
| `oo install.dev` | **Deprecated.** The old GitHub-keys install path. Use `init/oosh` (the curl one-liner) or `ossh install <host>` |
| `oo install.dev.keys` | **Deprecated**, same family |
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
| 31 | root.shared.dev.folder.created | Shared tree, developking, dev repo |
| 32 | root.dev.keys.installed | Deploy keys |
| 33 | root.installation.done | root bashrc + login shell |
| 34 | root.profile.dropin.installed | `/etc/profile.d/oosh.sh` login-shell drop-in (see [`oo.profile.fix`](#ooprofilefix)) |
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
oo method.new mycmd.hello
oo method.new mycmd.goodbye

# Run tests
test.suite run mycmd

# Enable completion
reconfigure
```

### Setting Up Development Environment

```bash
# Switch to dev mode
oo mode dev

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
| `private.oo.cmd.verify` | Predicate: is `<cmd>` on PATH after an install attempt; reason (incl. the macOS installed-but-not-on-PATH diagnostic) in `$RESULT`, never logged by itself — the caller logs it once at its own severity |

## See Also

- [Promotion Pipeline (promote)](promote.md)
- [OS & Platform Testing (os)](os.md)
- [Log System Documentation](log.md)
- [Config System Documentation](config.md)
- [Debug System Documentation](debug.md)
- [State Machine Documentation](state.md)
- [Wiki Index](wiki-index.md)
