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
somewhere to go. Scripts without a `<script>.start` dispatcher — such as `debug` — are not
method-scripts and deliberately have no marker.

### oo.test.new

Creates a test file for a script.

```bash
oo test.new myscript
```

Creates `test/test.myscript` from `templates/code/newScriptTest`.

### oo.test.platform.new

Creates a platform invariant test: a post-install check that runs on a real machine.

```bash
oo test.platform.new <scope> <aspect>
oo test.platform.new shared layout
```

Creates `test/test.platform.<scope>.<aspect>.invariant` from `templates/code/newPlatformInvariantTest`, executable. `<scope>` and `<aspect>` are camelCase words (letters and digits only). It refuses to overwrite a file that exists. Replace the `INVARIANT` blocks in the new file, then run it with `./test.suite run platform.<scope>.<aspect>.invariant 1`. Tab completion offers `shared` for the scope, and `config`, `oosh`, `layout` for the aspect.

## Version Control

### oo.mode

With no argument, shows current branch status and git remote configuration.
With a branch, switches `~/oosh` to that branch's folder under the base —
cloning it first when the folder is missing.

```bash
oo mode
# Output:
# git branch is: * dev
# OOSH_MODE=dev

oo mode dev        # switch to the dev folder
oo mode testing    # cloned into <base>/testing first if it is not there
```

The branch is an **argument**, not part of the method name — `oo.mode()` takes
`<?branch>`. Tab completion offers the available branch folders.

### The clone layout

Every `oo mode*` verb assumes one on-disk shape, and it is a **contract**, not a
convention. Since the ogit plan (design:
[spec § 2](superpowers/specs/2026-09-23-ogit-clones-per-branch-design.md)) every
folder is an **independent clone** — the linked-worktree layout it replaced is
described under [§ Converting between the layouts](#converting-between-the-layouts):

```
<base>/            ← "the base": group dev, setgid (g+ws) — new folders inherit the group
├── main/          ← clone of main. Always present: it is how the base is found
├── dev/           ← clone of dev.     .git is a DIRECTORY, origin = GitHub
├── testing/       ← clone of testing  (created on demand: oo checkout testing)
├── prod/          ← clone of prod
└── my.thing/      ← clone of feature/my-thing (prefix stripped, / → .)
```

Each folder has its own `.git` **directory**, `origin` on GitHub, and is checked
out on the branch its name says. Each `.git` is group-shared:
`core.sharedRepository=group`, group `dev`, g+w and setgid (`ogit repo.share`).

**The `main/` rule.** `main/` is load-bearing. `oo.mode.base.get` has four
strategies and the ones that work without an environment variable key on a
directory **named** `main`: a sibling `main/` with a `.git` directory, or being
`main/` itself (the worktree-list strategy still matches a host that has not
been converted). A layout with no `main/` is undetectable — which is exactly
the bug [item 7](research/2026-09-16-item7-oo-mode-setup.md) fixed. Nothing
ever removes `main/`.

`$OOSH_COMPONENTS_DIR` is the fourth route, and it is **process-scoped only**:
`config` excludes it from every save on purpose. Do not rely on it surviving a
shell. Build the layout instead.

**New folders are always clones under the base.** `oo checkout <version>` and
`oo mode <branch>` (for a folder that is missing) clone into `<base>/<dir>` via
`private.oo.branch.clone.ensure` — the same helper install state 31 uses — and
then share and trust the new folder. Without a base both refuse with
`no components base — run oo mode.setup`; there is no "clone beside `~/oosh`"
mode any more. An existing folder is never cloned over: a clone on the right
branch is kept, a linked worktree from an older install is left alone with a
pointer to `ogit worktree.remove`, anything else refuses. Install state 31
builds `main/` and the branch folder with `private.oo.shared.tree.ensure`, on
the same helper: a re-run keeps what is there and makes what is missing, so a
half-made first run heals; the local copy of `~/oosh` runs only when `main/`
could really not be cloned.

**Trust is per folder.** git's `safe.directory` is per repository, so every
folder under the base needs its own entry for every user who touches it
(otherwise `fatal: detected dubious ownership`). `ogit safeDirectory.ensure
<?base>` adds them for the calling user; `oo update`, `oo user.fix` /
`config init.user` and `user.oosh.install` run it for you; install state 31
trusts every folder for root, shares each one, and sets group `dev` + setgid on
the base.

**Reporting.** `ogit layout.status` prints one line per folder — `clone` or
`worktree`, dirty/ahead/behind counts, `shared=` `setgid=` `trusted=` — and
returns 1 on a mixed layout. The platform test
`./test.suite run platform.shared.layout.invariant 1` asserts the whole
contract (every folder a trusted, shared clone; the base group `dev` with
setgid) and names the recovery command for each failure.

### Converting between the layouts

A host installed before the clone layout still has `main/` as the only
repository and the other folders as **linked worktrees** of it (`.git` is a
FILE: `gitdir: …/main/.git/worktrees/dev`). Install and `oo update` never
convert it — conversion is an explicit, user-run step:

```bash
ogit layout.status            # see what you have
ogit worktree.remove     # every linked worktree → an independent clone
ogit worktree.restore    # the exact reverse, if you need the old layout back
```

Both are gated: they refuse, naming the folder and the fix, on a dirty folder,
an unpushed one, one without an upstream, or a detached one — before touching
anything. Gitignored files are carried across, and a copy is kept under
`~/.oosh.backups/<UTC-stamp>-ogit-<folder>` (root's `$HOME` under sudo).
`worktree.restore` additionally refuses when `main/` holds unpushed commits on
a local branch it would reset. On a shared tree they ask for sudo by themselves
(no `sudo` in front — sudo's PATH has no oosh). The step-by-step runbook is
[ogit.md § Migrating a host from worktrees to clones](ogit.md#migrating-a-host-from-worktrees-to-clones).

### oo.mode.setup

Converts a plain clone into that layout and points `~/oosh` at it.

```bash
oo mode.setup                 # base defaults to the clone's parent directory
oo mode.setup /var/dev/trees  # or name the base explicitly
```

It copies the clone to `<base>/main`, makes `<base>/<branch>` an independent
clone of it (origin re-pointed at `main/`'s origin, group-shared), and only
then removes the original — never before: a failed branch clone leaves the
original, and `~/oosh` with it, as they were (T-SETUP-SAFE-SWAP). An original
that already sits at `<base>/<branch>` is kept as that clone. It **checks that
`oo.mode.base.get` can find the base with `OOSH_COMPONENTS_DIR` unset** before
it touches `~/oosh`. If that check fails it stops with the layout built and the
old symlink intact.

"Already set up" is a property of the layout, not of what is checked out
(`private.oo.layout.folder.check`, T-SETUP-LAYOUT-EXISTS):

| `~/oosh`'s folder | what `oo mode.setup` does |
|---|---|
| directly under a base whose `main/` is a repository (`.git` a directory or a file), and it is `main/`, carries the name of a branch `main/` knows, or its branch has its own folder beside it | nothing — rc 0 "already set up", whatever branch or detached HEAD is checked out, clones and linked worktrees alike |
| a plain source tree (anywhere else) that fails ogit's gate — uncommitted change, no upstream, unpushed commit, a stash, another unpushed branch, a tag `main/` lacks (`private.oo.source.consume.gate` = `private.ogit.folder.gate` + `private.ogit.clone.gate`) | refuses with rc 7, RESULT names the folder and what would be lost; nothing is built, `~/oosh` unchanged (T-SETUP-SOURCE-GATE) |
| a plain source tree that passes the gate | builds `main/` + `<branch>/`, removes the source last, re-points `~/oosh` |
| … and the branch clone fails | rc 4; the source and `~/oosh` stay as they were, a re-run finishes the layout (T-SETUP-SAFE-SWAP) |

The consume step itself never removes `main/`, the branch folder or any folder
of the layout, and re-runs the gate right before it removes anything. It refuses
rather than guessing when `<base>/main` exists but is not a repository, when the
source has no detectable branch, or when `~/oosh` is a real directory rather
than a symlink.

The layout itself is built by `private.oo.shared.tree.from.local` — the same
helper install state 31 uses, so there is one definition of "canonical".

### oo.mode.base.get / oo.mode.base.set

`oo mode.base.get` prints the components base, or returns 1 when no layout is
detectable. `oo mode.base.set <path>` sets it **for the current process only** —
it is not persisted, whatever its output suggests. For a base that survives the
shell, run `oo mode.setup`.

### oo.checkout

Bring a remote branch onto this machine — always as its own clone under the
components base.

```bash
oo checkout testing              # → <base>/testing
oo checkout feature/my-thing     # → <base>/my.thing   (prefix stripped, / → .)
```

The directory name is derived, not copied: a leading `test/`, `feature/` or
`bugfix/` is stripped and the remaining slashes become dots, so
`feature/my-thing` lands at `my.thing` and `oo mode my.thing` works.

It needs a base — see [§ The clone layout](#the-clone-layout). It fetches,
clones `<version>` from the existing checkout's `origin` URL into
`<base>/<dir>` (`private.oo.branch.clone.ensure`, the helper install state 31
uses), then shares the folder (`ogit repo.share`) and trusts it for you
(`ogit safeDirectory.add`). Without a base it refuses with
`no components base — run oo mode.setup` — the old "plain clone beside
`~/oosh`" mode is gone. `oo checkout testing` is the prerequisite for the first
`promote testing` on a host without a `testing/` folder
([promote.md § Where the merge happens](promote.md#where-the-merge-happens--each-stage-in-its-own-folder)).

**It does not pull.** A branch that is already present is reported and left
alone, with a pointer to `oo update`. That is deliberate: pulling belongs to
`oo update` and merging belongs to `promote` / `oo stage`, and conflating them
here meant `oo checkout dev` silently fetched and merged `origin/dev` — a
surprise from a command whose name says checkout. The one thing it *will*
change is a folder whose git branch has drifted from its directory name: it
checks the branch out again to realign them, which is what `oo mode` assumes.

`create.result` on every branch and `return $(result)` at the end, so it can be
chained and its status trusted. On a failed clone `ogit repo.clone` removes
the half-made directory it created, and never one it did not.

### oo.use

Run one command from another branch **without switching**.

```bash
oo use main ossh status          # run main's ossh, stay on dev
oo use testing test.suite core 1
```

The branch directory is found under the components base, falling back to a
sibling of `~/oosh`. The command is then executed with `OOSH_DIR` pointed at
that branch — a scoped child-process override, which is the one sanctioned
exception to the `OOSH_DIR` anchor rule (`oosh-dir-exception` in the code;
[config.md § The anchor rule](config.md#the-anchor-rule)). There is no symlink alternative
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
exactly-one-match refusal come for free. Where a definition ends is
`private.oo.method.end.get`'s: a one-liner (`x.completion.y() { echo a; }`)
ends on its own line, a signature with a one-line body (`x() # doc` then
`{ …; }`) on that body line, a block on its first `}` line. "The first `}`
line" alone ran a `{ …; }` body on into the next method and deleted it
(`private.oo.safeDirectory.add` took `oo.remote.update`,
T-METHOD-DELETE-ONE-LINE). When another definition or the `### new.method`
marker comes before any end, the definition is left as it is and the tool
says so — it never guesses.

**It does not delete the test case.** A test case has no delimiters — a
`test.case` line, a call and one or more `expect`s, freely interleaved with
fixtures — so guessing its extent would silently eat assertions. Test
references and private helpers named after the method are **reported** instead,
for you to remove deliberately.

A legacy `private.` helper whose name carries no script segment
(`private.update.config` lived in `path`, but nothing in the name said so) is
out of its reach; remove one of those with the command this is built on:
`replace block <file> "<its first line>" "}" by ""`.

### The `replace` verbs

`oo method.new` and `oo method.delete` edit scripts through `replace`. It picks what to
change, then `by <newText>` writes the result to `<file>.new`; `replace diff`,
`replace commit` (the file becomes `<file>.bak`) and `replace rollback` finish the
transaction. Both write the content into a NEW file first and give it the original's
whole mode and group afterwards (`private.replace.copy.make`: the kernel getter
`private.this.path.stat.get <file> mode` + `chmod`, `chgrp` when the caller may), then
swap names — so a read-only 0444 / 0555 file commits too, a running script keeps
reading the old inode (the `.bak`), and no `cp -p` (BusyBox: "can't preserve
ownership") is involved (T-REPLACE-COMMIT-READ-ONLY). Every `rm` of a `.bak` / `.new`
is `rm -f`: a read-only one must not ask on a terminal.

| Verb | What it matches |
|---|---|
| `replace within <file> <text>` | a substring, on every line |
| `replace line <file> <exactLine>` | a whole line, exactly one match, else it refuses |
| `replace lines <file> <exactLine>` | every whole line equal to it, identical duplicates too; none is a refusal (T-REPLACE-LINES) |
| `replace block <file> <startLine> <endLine>` | the block between two whole lines, inclusive; `by ""` deletes it |
| `replace word <file> <word>` | every WHOLE-WORD occurrence on every line |

`replace word` renames an identifier. A hit counts only when the characters around
it are not letters, digits, `_` or `.`, so `debug.step`, `step.x`, `stepping` and
`my_step` are other words. A rerun matches nothing, so it is safe to repeat. It
refuses (rc 1) when the file has no whole-word match.

```bash
replace word some.File.txt step by debug.step   # step -> debug.step, once
replace commit some.File.txt
```

### The rest of the mode family

Short, because each one does what its name says — but they were undocumented,
so `oo <TAB>` offered verbs with nothing behind them.

| Verb | What it does |
|---|---|
| `oo mode.list` | the branch folders under the base, with each one's git status (for the layout itself: `ogit layout.status`) |
| `oo branch.list <?source:all>` | the branch folders under the base plus local git branches (`local`), or remote ones (`remote`) — `all` (the default) merges them |
| `oo mode.align` | checks the git branch out again to match the folder's directory name, for a tree that has drifted. `oo checkout` does the same repair for a branch it is asked to bring in |
| `oo mode.stage <stage>` | promote a stage forward (`dev` → `testing` → `prod`). An alias of `oo stage`; the pipeline itself is [§ Promotion Commands](#promotion-commands-via-oo-wrappers) and lives in `promote` |
| `oo prereqs.install` | install the install-time prereqs locally — `git`, `curl`, and `bash` 4+ when the running shell is older. Called by `init/oosh` through `ossh prereqs.install`; you rarely type it |
### oo.update

Pulls the latest changes from GitHub through a gate, then heals.

```bash
oo update
```

Its signature line is `oo.update() # # updates oosh environment: pulls the latest changes through a gate (fetch + fast-forward), then heals; rc 1 when the pull was refused, RESULT names the one command to run #` —
no parameters, the empty parameter field kept and the trailing ` #` that `this.help` and `c2` read.

**The pull gate.** `oo update` used to run a plain `git pull`, which on a tree that
had diverged from origin *merged* origin into it. It is now a **fetch and a
fast-forward**, never a merge, and it runs only when nothing is in the way
(`private.oo.update.pull.gate`, read-only). Each refused state names the **one
command to run**:

| State of the tree | `RESULT` says |
|---|---|
| a merge is in progress | `run: ogit merge.abort <dir>` |
| a cherry-pick is in progress | `run: ogit commit.pick.abort <dir>` |
| a rebase is in progress | `run: git -C <dir> rebase --abort` |
| conflict markers are committed (a file holding all three marker kinds — one kind alone is no conflict) | `run: oo heal` |
| uncommitted changes | `run: ogit status.show short <dir>` |
| detached HEAD | `run: ogit branch.checkout <branch> <dir>` |
| diverged from `origin/<branch>` | `run: oo heal` |
| not a repository | `run: oo heal` |

`private.oo.update.pull` then fetches `origin`. When that fails (a shared clone fetching over an SSH alias
the user does not have) it falls back to `OOSH_REPO` over HTTPS — fetching the branch into `FETCH_HEAD`,
never merging, the configured remote unchanged. After the fetch it checks that the branch exists on
origin (`origin has no branch <b> — <dir> is not pulled`) and fast-forwards only.
A refusal is rc 1 with the reason in `RESULT`.

**The heal steps run regardless of the pull.** Refused or not, `oo update` goes on with the steps a broken
computer needs most: it re-applies the canonical `~/config` + `~/oosh` symlinks through
`config init.user $USER` (idempotent — a no-op when they are canonical, silent before
`developking` exists), and it calls `private.oo.heal.shell`, the shell step `oo heal` runs for every user:
git trust of every folder under the base and no dead `safe.directory` entry, the oosh `.bashrc` and the
session files, no retired login drop-in, the launcher, and no frozen `PATH` line in `~/.once`. As root on an
installed computer it also writes the shared `odocker.env`, and it corrects a guessed computer name.

**A markers refusal loads no script.** When the tree has committed conflict markers, the scripts in it do
not parse, so the steps that load `config`, `user` or `odocker` are skipped (a warning says so and names
`oo heal`); `oo`'s own steps run.

This catches the case where `init/oosh` has been re-run out of band (e.g. a curl one-liner from the README)
and clobbered the symlinks — `oo mode <TAB>` would otherwise show nothing. See
[Repair toolkit](repair-toolkit.md) for the full primitive set.

### oo.heal

Brings **this computer** from any prior state to the standard dev model, so that `oo mode <branch>` works.

```bash
oo heal [<branch>] [all]      # <?branch> <?who:$USER> — a user name or all
oo heal.status [<branch>] [all]   # read-only: what oo heal would do
```

`oo heal.status` reads and never writes. For `developking`, a missing home (or user) is printed `[heal] developking: its home comes with the system step, then ~/oosh and ~/config are linked` — the system step makes it — while any other user without a home is `[left] <user>: no home known — not healed`. Each line it prints is `[ok]` (canonical), `[heal]` (`oo heal` changes it), `[left]` (`oo heal` reports it, you act)
or `[keep]` (an old backup, kept). A canonical folder git refuses for the one who runs it (dubious ownership, e.g.
root reading a clone another user made) is printed
`[heal] <branch>: <dir> is owned by <owner> and not yet trusted for <me> — oo heal trusts the base's folders first and then judges it`,
never as an aside prediction. rc 1 when anything is not canonical, and `RESULT` names the command: `not canonical — run: oo heal <branch> <who>`.
`<branch>` defaults to the branch of the tree running the heal, else `$OOSH_BRANCH`, else `dev`. The tree
running the heal is its temporary copy, which belongs to the user the heal runs as (`cp -R`, no `-p`), so git
reads it even when another user owns the tree it was started from — root's bare `oo heal` from test's clone
went to `dev` while the copy kept test as its owner. `<who>`
defaults to the calling user, and `oo heal all` (a first argument of `all`) means every user.

**Three entry forms, one heal.** All end in `oo heal` of a tree:

| Form | Use it when |
|---|---|
| `oo heal [<branch>] [all]` | oosh runs on this machine |
| `ossh heal <host> [<user>\|all] [<branch>]` | healing a remote host from here — see [ossh.md](ossh.md#healing-a-remote-host-ossh-heal) |
| `curl -fsSL https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/<branch>/init/oosh \| sh -s -- heal [<branch>] [all]` | oosh is missing, old or broken |

The curl form has a wget twin and an `sh -c` twin:

```bash
curl -fsSL https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/dev/init/oosh | sh -s -- heal dev all
wget -qO- https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/dev/init/oosh | sh -s -- heal dev all
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/dev/init/oosh)" sh heal
```

The `sh -c` form needs the extra `sh` before `heal`: the first word after the command string is `$0`, so
`sh -c "$(curl …)" heal` runs the script with **no** arguments (`$0` = `heal`) and does an install, not a heal.
The curl form runs `init/oosh`'s heal arm, which clones `<branch>` fresh into a temporary folder and runs
*that* tree's `oo heal` — it never touches `~/oosh`, so it works when `~/oosh` is the broken tree
(see [install-bootstrap.md § The heal arm](install-bootstrap.md#the-heal-arm)).

**The owner's rules.**

- The target is the **standard dev model**: the canonical base (`<basehome>/shared/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/Once.sh`)
  with `main/` and `<branch>/` as clean clones of origin (healing to `main` also ensures `dev/`, so `oo mode` has a second folder), group `dev` with setgid, `developking` with a home,
  the `sharedConfig`, the launcher `/usr/local/bin/this` (and, where the empty shell `env -i sh` has no `/usr/local/bin` on its PATH — BusyBox on Alpine — the link `/usr/bin/this` to it, `private.oo.launcher.link.get`), and `~/oosh` → `<base>/<branch>`, `~/config` →
  `sharedConfig` for each healed user. The canonical base is **built fresh** from origin, over HTTPS.
- **Foreign folders are untouched and reported.** A `~/oosh` that points outside the base is relinked to the
  base; the folder it pointed to is left alone, its git state reported (`[left] … untouched`). A foreign tree git
  refuses to read for the healer (another owner, git's `safe.directory`) is never trusted and never called "not a
  repository": `[left] <user> tree <dir>: foreign tree, left untouched (not probed: owned by <owner>, …)`.
- **The base's folders are trusted before they are judged.** Once, before the diagnosis (which judges them already),
  the heal trusts every branch folder under the base for the user it runs as (`private.oo.heal.base.trust` →
  `ogit.safeDirectory.ensure <base>`, git's `safe.directory`; root's `~/.gitconfig` under `all`), so a clean clone
  another user made (`oo checkout` as that user) is kept or fast-forwarded — as root it used to read "not a
  repository" and was moved aside.
- **A broken canonical folder is moved, never deleted.** A `main/` or `<branch>/` with a merge in progress,
  committed conflict markers, uncommitted changes, a detached HEAD, a diverged history, another branch
  checked out, or a symlink is moved whole to `<base>.aside/<name>.orig.<ts>` (a sibling of the base, never taken
  for a branch folder; the kernel's `private.this.entry.aside <path> <?ts> <?asideDir>`, which also bumps a taken stamp) and cloned again; the heal then reports `rc 1` so you look at it. The tree the heal
  itself runs from is never moved. A clean clone that is only behind is fast-forwarded; a linked worktree is
  converted with `ogit worktree.remove` when its gate lets it — after `private.ogit.worktree.upstream.ensure`: a worktree that
  tracks nothing gets `origin/<branch>` when origin has the branch, otherwise it is left with the gate's reason (`tracks no upstream`).
  The conversion of a shared base needs root: without it (a one-user heal, no working `sudo -n`) the worktrees are left with
  `sudo -H $OOSH_DIR/ogit worktree.remove <base>` (the resolved tree path), never a password prompt. A folder that is no repository and not empty
  stops the heal (rc 2): move it away and run again.
- **A real `~/config` is kept** as `~/config.orig.<ts>` and linked to the `sharedConfig`; an allow-listed few
  values are imported from it — `LOG_LEVEL` and the computer name `OOSH_SSH_CONFIG_HOST` — only into empty values;
  `PATH`, `HOME`, `LOG_DEVICE`, `OOSH_DIR`, `OOSH_MODE` and `CONFIG_CHAIN_*` are never carried
  (`private.config.orig.import`, [config.md](config.md)). Old formats in a real `~/config` (a `PATH` or
  `HOME` export, `LOG_DEVICE=/dev/stdout`, `CONFIG_CHAIN_*`) are reported, never carried over.
- **Info notes.** Two findings are reports, not repairs, and each ends the heal with rc 1 so you see them
  (`private.oo.heal.note … info`): the **legacy `ssh.*` backup folders** in the home (`user ssh.backup.migrate`
  deals with them) and a **login shell that is not bash** — `private.oo.heal.login.shell.check <user>` reads
  the shell from the user database and never changes it:
  `[left] <user> login shell /bin/zsh — oo lives in bash: type bash first, or chsh -s <bash>` (on macOS the
  Homebrew bash is named when it is there). The Mac procedure: open a new terminal, type `bash`, then
  `oo mode dev`. `oo heal.status` shows the shell line too.
- **A re-login is a note at rc 0.** A user the heal put into group `dev` needs one new login for the group to
  take effect; the summary says `<user> is in group dev now — log out and in once (group dev)` as a healed line.
  Root gets no such note.
- **Folders are finished by their owner.** `private.oo.heal.folder.finish <dir>` closes each cloned or kept folder: root or the
  folder's owner runs the full `ogit folder.finish` (shared, trusted); anyone else only adds the safe directory
  (`ogit safeDirectory.add`) — sharing is the owner's — and a folder not shared with group `dev` yet is left with
  `ogit repo.share <dir>` (rc 1). A one-user heal therefore never runs `chmod` on folders it does not own.
- **State 99 on green.** When every step and the verify are green — whatever the info notes say — the install
  state machine `SETUP_SERVER` is set to 99 (created first when missing) **in the sharedConfig**
  (`private.oo.heal.state.finish <configPath>`, read back with `state.of`; the heal's own `CONFIG_PATH` is a
  scratch folder), so `ossh install` skips the computer and `oo state` agrees. The rc stays 1 while an info note
  stands: 99 says the install is done, rc 1 says something is left for you. When 99 cannot be written the
  summary says so and the rc is 1. So rc 1 with **only report items** (legacy `ssh.*` folders, a folder moved aside, a foreign
  tree, a non-bash login shell) still reaches install state 99, and the rc line then ends with `install state 99`
  (`something is left for you — the lines marked left above; install state 99`); a rc 1 with a step left does not.
  `os platform.heal.test` reads exactly that line for its second heal.
- **Never automatic.** The heal runs only when invoked — never at shell start (the May-8 rule).
- **`oo mode` is not called.** The heal leaves `~/oosh` on `<base>/<branch>` and writes `OOSH_MODE=<branch>` into the
  user's session files and `~/.config/oosh/mode-env.bash` (`private.oo.mode.env.write`, the file `oo mode`
  writes too), so `oo mode <branch>` afterwards says "already current".

**Order.** `diagnose` (read-only, printed first — the same lines as `oo heal.status`) → the **privilege
decision** (once, below) → `system` (group `dev`, `developking` and its home, the base with group `dev` and
setgid, the launcher, no retired drop-in) → `code` (`main/` and `<branch>/`, plus `dev/` when `<branch>` is
`main`) → `config` (the `sharedConfig` is *made* when missing, then `config init.shared`; it is still empty) →
`user(s)` (`config init.user <user> <base>/<branch>`, a real `~/config` kept aside and queued, then as that
user the session files, `mode-env.bash` and the shell step) → `env` (`private.oo.heal.env`, once, in fresh
processes: `config init.env` **fills** the `sharedConfig`, THEN the queued imports of the kept `~/config`
folders run, then `config validate required`) → `verify` → `summary` (one line per step: `healed`, `left`,
`cannot`). The import comes after `config init.env` because it writes into `log.env` and `oosh.env` only
when they exist, and on a `sharedConfig` the heal just made they exist only after `init.env`
(T-OO-HEAL-USER-REAL-CONFIG).

**The privilege rule.** `private.oo.heal.root.need <base> <branch>` is computed **first** and names what needs
root: `group-dev`, `developking`, `developking-home`, `base`, `launcher`, `drop-in`, `worktrees`. Every need except `worktrees` stops a heal without root before any change (rc 2). `worktrees` alone does not: the code step
leaves the conversion with `sudo -H $OOSH_DIR/ogit worktree.remove <base>` (the resolved tree path). Then
`private.oo.heal.privilege.ensure <need>` decides **once**, before anything changes:

- **Nothing needs root** (the need is empty — a user healing their own canonical account): sudo is **not asked
  at all**, no prompt, no password typed for nothing (`OOSH_HEAL_ROOT=no`). Root itself is always `yes`.
- **Interactive** — stdin is a terminal and neither `OOSH_NO_INSTALL` nor `OOSH_HEAL_NONINTERACTIVE` is set:
  when root is needed the heal may ask for the sudo password **once**, up front (`sudo -v`) and then runs on the
  cached credential.
- **Otherwise** (CI, `os platform.test`, a script, a pipe) only `sudo -n` is used, for `$SUDO` and for `sudo`
  itself in that process, so nothing can stop at a password prompt. When root is needed and unavailable the
  heal ends with **rc 2 before any change**: `needs root (<what>) — run: sudo -H <tree>/oo heal <branch>` — the full
  path of the tree the heal came from (`OOSH_HEAL_TREE`), because sudo's `secure_path` has no `~/oosh` and
  `sudo -H oo …` is `sudo: oo: command not found`.
- A user who needs no root part heals their own account without sudo. So the one prompt exists only when a step
  needs root, and then `oo heal` needs either a terminal for it or passwordless sudo.

**The clean re-exec, from a copy.** Every form ends in **one clean process** (`private.oo.heal.env.clean`):
`oo heal` copies its own tree to a world-readable `/tmp/oosh-heal.*/t` (the layout of the curl form) and runs
that copy through `env -i`, so `oo heal` typed from a real `~/oosh` never moves the tree it runs from and the
as-user hops can read it; the clean process removes its own copy when it exits (`private.oo.heal.copy.trap`, an
`EXIT` trap that keeps the heal's rc) — under sudo the copy is root's, and a `sudo -n rm` afterwards failed once the
timestamp had expired during a long heal. The process keeps only `HOME`, `USER`, `LOGNAME`,
`TERM`, `LANG`, `LC_ALL`, `LOG_LEVEL`, `OOSH_REPO`, `SSH_AUTH_SOCK`, the six proxy variables (`http_proxy`,
`https_proxy`, `no_proxy` and their upper-case twins), `OOSH_NO_INSTALL` and `OOSH_HEAL_NONINTERACTIVE`, and
sets `OOSH_HEAL_CLEAN=1`, `OOSH_HEAL_TREE=<the tree it came from>` (named in the sudo recoveries), `OOSH_DIR=<the copy>` and `PATH` to the copy plus the system directories.
`SUDO_USER` is **dropped on purpose** (the user hop trusts the folders itself); the login that invoked sudo
goes in as `OOSH_HEAL_LOGIN`, used by `all` only. `CONFIG` is set to a file that **does not exist** (`<tree>/.heal.noconfig`), so the cold
start of `this` never sources an old `~/config/user.env` — the Mac's old one exported `PATH` with `.`,
`HOME` and `LOG_DEVICE=/dev/stdout`. `CONFIG_PATH` is a **scratch folder in the copy** (`<tree>/.heal.config`):
loading `config` runs `config.init` (it makes `$CONFIG_PATH` and touches `error.txt` in it), which on `~/config`
made the heal a `~/config` of its own that the user step then kept aside as a fake `config.orig` — and wrote
into a real one before it was kept aside. Every step names the folders it writes (the sharedConfig, the homes),
never the process's `CONFIG_PATH`. A copy under `$TMPDIR` is recognised as the heal's own tree too. The bash that runs the heal is the bash the process was started with
(`$BASH`), not the system's 3.2 on macOS.

**One umask for the shared places.** The clean process sets `umask 002` once (`oo.heal`, after the re-exec, so
sudo's own umask does not override it): what root writes into the shared places — the base's clones, the env
files, the loggers' `result.txt` / `error.txt`, the state machine in the sharedConfig — is group-writable the
first time (root's umask is 022 and sudo ORs 022 in; on the macOS VM every other user of group dev got
`Permission denied` on the shared `error.txt`). No finish pass normalises it afterwards. The heal's umask never
leaks into a home: a `--global` git write (root's `~/.gitconfig`, `safe.directory`) runs with umask 022
(`private.ogit.git.run`), and every as-user hop starts with `umask 022` (`private.this.as.user.preamble.get`),
after which the hop's own `source this` applies this's policy (`private.this.umask.apply`) — 002 for a member of
dev and for a user whose `~/config` is the group-dev sharedConfig, as in their login shells (root and every healed
user), anyone else keeps 022 (sshd's StrictModes, a person's dotfiles). The config's group counts, not only the
process's groups: a root heal's process started before its own system step created group dev, and root's hop runs
in that process's credentials — on the macOS VM it wrote the sharedConfig's colour files, `result.txt` and
`error.txt` 644 and every user failed the configLayout invariant. `verify`'s hop starts with an explicit `umask 002`: it writes the sharedConfig's loggers on
purpose, and `sudo -H -u` (macOS) ORs 022 in for a user whose process is not in dev yet.

**Return codes.** `0` healed and every invariant PASS or NOT CHECKED; `1` something is left for you (the lines
marked `left` — a folder moved aside, the info notes above — or a FAIL from verify); `2` cannot heal (the line marked `cannot` — no root, no source for the clones,
a folder in the way).

**The summary lines.** One line per step. The ones to know: `users: healed: <names>`;
`<user> is in group dev now — log out and in once (group dev)` (a note at rc 0, none for root; the group takes
effect after the next login, and `verify` marks an invariant that fails only for that reason NOT CHECKED, never
FAIL; `verify` runs the **heal tree's** platform invariants as each user, not those of whatever branch the user's `~/oosh` pointed to before, so an old branch without those tests is still verified);
`developking created (admin, password = developking — state 31 precedent)` when the heal had to create
`developking`; the legacy `ssh.*` backup folders as `[left]` with `user ssh.backup.migrate`; and a login shell other than bash
as `[left]` with the way into bash (both info notes, see above). Path or
bundle origins of a healed folder are re-pointed to the canonical URL; the source of the clones is
`$OOSH_REPO` (a URL, a path or a bundle) else the canonical URL.

**Verify** runs the four platform invariants as the healed user, in a fresh process, from their `~/oosh`:
`configLayout`, `layout`, `boot` and `oosh` (`./test.suite run platform.shared.<name>.invariant 1`). One line
each: `PASS`, `FAIL <invariant> <user>: <its recovery>` (rc 1; the recovery is quoted without the colour escapes of the
loggers — `private.oo.heal.text.plain`, the one strip, also used for `config validate required`) or `NOT CHECKED <invariant> <user>: <why>`,
which does not fail the heal. It says NOT CHECKED when the invariant file is not in the branch, and when
another user's invariants would have to run without being root.

**`all`** heals every user — root, `developking`, every person's account whose own home holds `~/oosh` or `~/config`, and the
login user that invoked sudo (`OOSH_HEAL_LOGIN`; `private.oo.heal.users.list`) — and needs root. As a user who may sudo, `oo heal all` (or `oo heal <branch> all`) **runs itself as root**: the one
clean re-exec is started through `sudo -H` (`sudo -H env -i … <copy>/oo heal <branch> all`, `private.oo.heal.sudo.get`)
with root's `HOME`, `USER` and `LOGNAME` and the user as `OOSH_HEAL_LOGIN`; with a terminal sudo asks for the password
**once** (`sudo -v`, skipped when sudo needs none) and the whole heal runs as root, so `private.oo.heal.privilege.ensure`
asks nothing more. Without a terminal (or with `OOSH_NO_INSTALL` / `OOSH_HEAL_NONINTERACTIVE`) only `sudo -n` is tried;
when it gives no root the heal stops with **rc 2** before anything runs and names a command that works, with the
full path of the tree: `sudo -H /home/<you>/…/<branch>/oo heal <branch> all` (sudo's `secure_path` has no `~/oosh`).
A person's account is the four rules of `private.user.account.heals.is`: root or a uid of at least `UID_MIN` (`/etc/login.defs`, else 1000; 501 on macOS — `private.user.uid.min.get`), a login shell that is not `nologin` or `false`, a home it owns (not `/`, `/nonexistent`, `/var/empty`) and `~/oosh` or `~/config` in it. `oo heal all` is for people: system accounts are skipped, and `[skip]` lines show each one once. A system account that sees one anyway — AlmaLinux's `operator` has uid 11, `/sbin/nologin` and root's home `/root` — is not healed; the diagnosis names it once: `[skip] operator: system account (uid 11, /sbin/nologin, home /root)`.
A user who is already canonical keeps their branch under `all`, except the healer and the login that ran sudo (`OOSH_HEAL_LOGIN`): they move to `<branch>`, so the second heal finds `oo heal` from root's `~/oosh` (`private.oo.heal.user.keep.check`). A branch folder is kept only when its tree can carry the model the heal heals to: its `config` defines `config.session.save` and its `this` has the clean boot (the `derivedHome` assignment that derives HOME in an `env -i` start) — `private.oo.heal.tree.carries.model`, which reads both as text and runs nothing of the old tree. Otherwise that user moves to `<branch>` too, and the diagnosis and the `healed user` line say why: `canonical → <folder> — its tree predates the heal (no config.session.save, no clean boot) — linked to <branch>`. The reason: every as-user step loads its functions from the user's own tree, so a kept tree older than the clean boot left that user with an `env -i bash` without HOME (a shell that cannot start) and, without their `user.session.env`, blocked the shared `user.env` switch for every user — the Ubuntu gate on 26d15a4 kept three users on `platform-test-26d15a4` and every user failed configLayout. When `config init.user` fails for a user, the heal shows its own reason (`config init.user <user> <dir> failed: <reason>`), never "run it to see why". Healing a named user other than yourself
needs root too (it is refused with `sudo -H <tree>/oo heal <branch> <user>`, no sudo re-run). `sudo -H <tree>/oo heal <branch>` is also what is named when the system part needs root.

**Worked example — a machine on an old branch.** The tree on this machine predates the heal, so the curl
form fetches the heal from the branch itself:

```bash
curl -fsSL https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/dev/init/oosh | sh -s -- heal dev all
# open a new terminal, then:
oo mode dev          # "already current" — the heal left ~/oosh on <base>/dev
```

### oo.user.fix

Repair the current user's `~/config` + `~/oosh` symlinks to the
canonical shared tree. Thin alias for [`config init.user`](config.md).

```bash
oo user.fix              # repair this user (= $USER)
oo user.fix developking  # repair another user (requires root)
```

`oo user.fix` takes **one** argument, the username. `config init.user`'s second parameter
(`<sharedOosh>`, the `~/oosh` target) is the heal's, not this command's.

Handles real-dir → symlink conversion (preserves originals as
`oosh.orig.<ts>` / `config.orig.<ts>`), ownership, branch detection,
and `dev`-group membership. Idempotent — calling it on an
already-correct layout is a no-op. Naming follows the OOSH
`noun.verb` convention and the existing `ossh.rights.fix` /
`ossh.folder.fix` per-scope pattern. See
[Repair toolkit](repair-toolkit.md) for related primitives.

### The retired login drop-in

`boot` is gone — a shell starts from `~/config/user.env` (see
[config.md § The PATH line](config.md#the-path-line)) — and with it the former
`boot.fix` and `boot.status` methods and the host-wide drop-in they installed (`/etc/oosh/boot`,
`/etc/profile.d/oosh.sh`). `oo update` removes that drop-in from a host that still
has one (`private.oo.dropin.remove`; only an `oosh.sh` that names the boot path is
touched), and install state 34 does the same on a fresh install. Removing it needs
write access to `/etc`, so `oo update` may ask for the sudo password once.

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

Discovery only **records**: it sets `OOSH_PM` (and the `OS_CMD_*` group/user
commands it knows) and saves them — it runs no package manager and no `sudo`.
It used to run `$SUDO apt-get update` on an apt host, and `private.user.init`
discovers whenever `os.commands.env` is incomplete, so merely sourcing `user`
asked for a sudo password (T-OO-PM-DISCOVER-RECORDS, T-USER-SOURCE-NO-SUDO).
The package lists are refreshed by `oo cmd`, before its first real install.

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

A command that is already there costs one `command -v`: no package manager, not
even its discovery. Under `OOSH_NO_INSTALL` (every test run) nothing is installed
or refreshed. Otherwise `oo cmd` discovers the package manager if `OOSH_PM` is
empty and, on apt, refreshes the package lists **once** before the first real
install — a fresh apt image has empty lists (T-OO-CMD-REFRESH-ONCE). Once means
`OOSH_APT_UPDATED`, which `init/oosh` exports after its own `apt-get update` — run only when it must install `git` or bash 4+, and flagged only after a refresh that worked — and
`oo cmd` exports after one **that worked** — a failed refresh is retried by the
next `oo cmd` — so the `oo cmd` children of an install do not refresh again
(`config save` never persists it). There is no other marker: the old
`OOSH_PM_UPDATED` was set before the refresh ran and `config save` harvested it
into the shared `oosh.env`, which made every later shell skip the refresh for
good (T-OO-CMD-REFRESH-MARKER). dnf, yum, apk and brew get no refresh before an
install; an explicit `oo cmd update` on dnf/yum runs `makecache` each time.

Special cases:
- `update` - Refreshes the package-manager cache (`apt-get update` / `dnf makecache` / `yum makecache`), once per process chain as above
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

**A test run installs nothing.** Under `OOSH_NO_INSTALL` (test.suite exports it for every test
file) a missing `<cmd>` is refused: rc 1, `$RESULT` `<cmd> missing — a test run installs nothing`,
a warning, no package manager and no sudo. A present one is still rc 0. `oo.cmd` is the one door
every install goes through, so it owns this rule (T-CMD-NO-INSTALL; see
[test-suite.md](test-suite.md#a-test-run-installs-nothing)).

**BusyBox wget** (alpine) is present but too limited, so `oo cmd wget` upgrades it to full wget —
through the same refusal and the same package-manager check as any install: nothing under
`OOSH_NO_INSTALL`, nothing when no package manager is known (never a bare `sudo wget`). The stub
works, so both answer rc 0 with a warning (T-CMD-NO-INSTALL-BUSYBOX).

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
| `oo tmp.cleanup.testing` | **Retired.** It used to remove oosh *and SSH keys* and `developking` with `sudo rm -rf`. It refuses now (rc 1) and points at `oo deinstall`, which keeps everything as `.orig.<ts>` |
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

Takes oosh off this home. It **asks first and deletes nothing**.

```bash
oo deinstall          # asks on the terminal; type the word deinstall
oo deinstall --yes    # no question
```

The question is read from the terminal (`/dev/tty`), not from stdin, so a piped `yes` cannot answer it;
anything but the word `deinstall` refuses (rc 1, nothing changed). Then, through `private.this.entry.aside`,
the kernel's one move-aside:

- `~/config`, `~/init`, `~/.once`, `~/.bashrc` and `~/oosh` are taken off — a symlink is removed, a real entry is
  **kept as `<name>.orig.<ts>`** (one timestamp for the run, never nested). `~/oosh` goes **last**, because the
  scripts the command still needs come through it.
- The installer stays reachable: `init/oosh` is copied to `~/install.oosh`; an older `~/install.oosh` is kept
  as `install.oosh.orig.<ts>`.
- The `.bashrc` from before oosh is restored with `cp -p` from `~/.bashrc.pre-oosh` (else from
  `~/.bashrc.bak.without.completion`).
- `RESULT` lists what was kept and names the way back: `reinstall with: ~/install.oosh`.

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
| 34 | root.boot.path.installed | removes the retired login drop-in (see [The retired login drop-in](#the-retired-login-drop-in)) |
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
| `$OOSH_APT_UPDATED` | apt package lists refreshed in this process chain — exported only after a refresh that worked, never saved by `config save` |
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
| `private.oo.method.end.get <file> <startLine>` | The line that closes the definition starting at `<startLine>`; empty when another definition or the marker comes first — `oo method.delete` refuses then |
| `private.oo.path.sudo.get <path> <?mode>` | The one privilege rule: nothing when this user may write `<path>` (its nearest existing parent while it is not there) or is root (`$SUDO` empty); else `$SUDO`, or `sudo -n ` in mode `quiet`, which never asks for a password. `oo update`'s drop-in cleanup and launcher install use quiet (T-OO-PATH-SUDO-GET, T-OO-PRIVILEGE-QUIET) |
| `private.oo.pm.install.prefix.get <?pmCmd>` | What goes in front of the package-manager command: the sudo decision — none for brew (Homebrew refuses root; root under sudo hops back to `$SUDO_USER`), none for root (`$SUDO` empty), else `$SUDO` — and the non-interactive env of `private.oo.pm.env.get`. `oo.cmd` and `oo.prereqs.install` both use it (T-OO-PM-INSTALL-PREFIX-GET) |
| `private.oo.heal.env.clean <?branch> <?who> <?tree>` | Runs `oo heal` again in one clean process from a world-readable copy of `<tree>` under `/tmp/oosh-heal.*`, owned by the user that process runs as (`env -i`, the carried list above, `OOSH_HEAL_CLEAN=1`, `OOSH_HEAL_LOGIN`, `CONFIG` naming a file that is not there, `CONFIG_PATH` a scratch folder `<copy>/.heal.config`); that process removes its copy on exit; plain bash, called before `this` is loaded |
| `private.oo.heal.copy.trap` | In the clean process (`OOSH_HEAL_CLEAN=1`) whose `OOSH_DIR` is `<copy>/t`, `<copy>` a `/tmp/oosh-heal.*` folder: removes `<copy>` on `EXIT`, the rc kept; nothing anywhere else; called by `oo.heal` |
| `private.oo.heal.path.system.get` | The system `PATH` of a clean process (`/usr/local`, `/usr`, `/` `bin` and `sbin`; Homebrew's `/opt/homebrew` on macOS); silent getter |
| `private.oo.heal.branch.get` | The branch `oo heal` heals to by default: the branch of the tree running it (the clean step's copy, the runner's own), else `$OOSH_BRANCH`, else `dev`; silent getter |
| `private.oo.heal.basehome.get` | The folder the homes live in: the parent of `developking`'s home, else `/Users` (macOS) or `/home`; silent getter |
| `private.oo.heal.path.get <basehome> <which>` | `base` (the components base, `private.config.shared.oosh.base.get`) or `sharedConfig` (`private.config.shared.config.get`) under `<basehome>`, in the file system's letter case; before developking exists the fallback is `<basehome>/shared` through `private.this.path.case.get`; silent getter |
| `private.oo.heal.root.check` | Predicate: this process may act as root — decided once by `private.oo.heal.privilege.ensure` |
| `private.oo.heal.privilege.ensure <?need>` | Decides once, before anything changes, whether the heal may act as root: with an empty `<need>` (from `private.oo.heal.root.need`) sudo is not asked at all; else interactive may ask `sudo -v` once, non-interactive is `sudo -n` only (`$SUDO` and `sudo` itself); sets `OOSH_HEAL_ROOT` and `OOSH_HEAL_INTERACTIVE` |
| `private.oo.heal.root.need <base> <branch>` | What of the heal needs root, space-separated (`group-dev developking developking-home base launcher drop-in worktrees`); silent getter; `worktrees` alone does not stop a one-user heal |
| `private.oo.heal.system.diagnose <base> <branch>` | Read-only lines of the system part (`[ok]`/`[heal]`/`[left]`); rc 1 when anything is not canonical |
| `private.oo.heal.user.diagnose <user> <home> <base> <branch>` | Read-only lines of one home: `~/oosh` (canonical, foreign, worktree, plain-clone, plain-dir, none), `~/config`, old env formats, `.bashrc`, `~/.once`, legacy `ssh.*` folders, dead `safe.directory` entries, `mode-env.bash`, self-links, old backups |
| `private.oo.heal.base.trust <base>` | Trusts every branch folder under `<base>` for the user the heal runs as (`ogit.safeDirectory.ensure`), so the gate judges a clone another user made as a repository; nothing when `<base>` does not exist |
| `private.oo.heal.sudo.get <who>` | The sudo words the clean re-exec starts with: nothing as root or for one user; `sudo -H` after one `sudo -v` with a terminal, `sudo -n -H` without; rc 2 when no root; plain bash, silent getter |
| `private.oo.heal.folder.gate <dir> <branch>` | What the heal does with a canonical folder: `missing`, `keep`, `fastforward`, `aside`, `worktree` or `occupied`; read-only, built on the same probes as the pull gate |
| `private.oo.heal.folder.finish <dir>` | Finishes a folder the code step cloned or kept: root or its owner runs `ogit folder.finish`; anyone else only `ogit safeDirectory.add`, and a folder not shared with group `dev` is left with `ogit repo.share <dir>` (rc 1); rc 1 for a missing `<dir>` |
| `private.oo.heal.folder.aside <dir>` | Moves a canonical folder, whole, to `<base>.aside/<name>.orig.<ts>` through `private.this.entry.aside`; never deletes; refuses the tree the heal runs from; `RESULT` = the new path |
| `private.oo.heal.system <branch>` | The system part: group `dev`, `developking` and its home, the shared base, the launcher, no retired drop-in; rc 2 when root is needed and not there |
| `private.oo.heal.code <base> <branch>` | `main/` and `<branch>/` (and `dev/` when `<branch>` is `main`) as clean clones, every origin re-pointed to the canonical URL; aside, fast-forward, worktree upstream (`private.ogit.worktree.upstream.ensure`) and conversion; offline the tree running the heal is the source; rc 1 left for you, rc 2 no source |
| `private.oo.heal.config <sharedConfig>` | Makes the `sharedConfig` when missing (owner `developking`; the env step fills it), then `config init.shared`; rc 2 when it cannot be made |
| `private.oo.heal.config.load <probeFn>` | Loads config through `private.this.script.load` unless `<probeFn>` is a function already and keeps the heal's CONFIG guard; rc 0 when `<probeFn>` is a function afterwards |
| `private.oo.heal.config.guard` | In the clean process, points `CONFIG` at the missing file again after loading config moved it to `~/config/user.env`; nothing outside the heal |
| `private.oo.heal.user <user> <base> <branch> <sharedConfig> <?keep>` | Heals one user: `config init.user` (rc 1 with its own reason when it fails), the import from a kept `~/config`, then as the user the session files, `mode-env.bash` and the shell step; removes old self-links |
| `private.oo.heal.tree.carries.model <tree>` | rc 0 when the branch folder `<tree>` can carry the model (its `config` defines `config.session.save`, its `this` has the clean boot `derivedHome`); rc 1 `its tree predates the heal (no …)`; read as text |
| `private.oo.heal.shell <?home> <?base> <?load>` | The shell step `oo update` and `oo heal` share (git trust, `.bashrc`, session files, retired drop-in, launcher, `~/.once`); `load no` skips what loads config or user |
| `private.oo.heal.env <sharedConfig>` | Once: `config init.env` in a fresh process (its own reason travels with the note: the last three `REFUSING` / `could NOT derive` / `ERROR` lines, T-OO-HEAL-ENV-INIT-REASON), then the queued imports of the kept `~/config` folders (`private.config.orig.import`), then `config validate required` in a fresh process |
| `private.oo.heal.fresh.run <home> <command>` | Runs `<command>` in a fresh process of this user (`env -i`, `HOME=<home>`, `~/oosh` first on the system `PATH`); prints its output; rc of the command |
| `private.oo.heal.users.list <?which:heal>` | The users `oo heal all` heals, one per line (`private.user.account.heals.is`); `skip`: one `[skip] <user>: <why>` line per account that sees `~/oosh` or `~/config` and is not healed; silent getter |
| `private.oo.launcher.link.get <?target> <?emptyPath>` | The second name an empty shell needs for the launcher: `PREFIX/bin/this` for a target `PREFIX/local/bin/this` whose directory is not on the PATH of `env -i sh` (BusyBox: `/sbin:/usr/sbin:/bin:/usr/bin`); nothing on glibc distributions and macOS; silent getter. `private.oo.install.launcher` makes the link (a link of its own, never over a real file) and `private.oo.heal.root.need` names it under `launcher` |
| `private.oo.heal.verify <user> <home>` | Runs the four invariants as `<user>`: `PASS` / `FAIL` / `NOT CHECKED` lines |
| `private.oo.heal.note <rc> <step> <text> <?kind:step>` | Adds one summary line and raises the heal's rc; `kind` `info` is a report only (legacy `ssh.*` folders, a non-bash login shell): it raises the rc but not the rc of the steps that decides state 99 |
| `private.oo.heal.summary <?sharedConfig>` | Prints the summary, one line per step, and the rc; when the steps and verify are green (info notes aside) the install state goes to 99 in `<sharedConfig>` |
| `private.oo.heal.state.finish <configPath>` | Sets `SETUP_SERVER` to 99 in `<configPath>` (the sharedConfig; creating the machine when missing), checked with `state.of`; rc 1 when it cannot |
| `private.oo.heal.login.shell.check <user>` | rc 0 when the login shell of `<user>` is bash (or unknown); rc 1 and a `RESULT` naming the way into bash otherwise — reported, never changed |
| `private.oo.heal.text.plain` | A filter: stdin to stdout without the colour escapes of the oosh loggers and `test.suite`; the one strip for the lines the heal quotes from another process |
| `private.oo.state.machine.create <?machine>` | Creates the install state machine with every state of the install lane, standing at `setup`; `private.init.state.machine` and the heal both call it |
| `private.oo.update.pull.gate <?dir>` | rc 0 when `<dir>` may be pulled; else rc 1 and the one command to run in `RESULT` |
| `private.oo.update.pull <?dir>` | The pull through the gate: fetch (HTTPS fallback) and fast-forward, never a merge |
| `private.oo.update.markers.get <?dir>` | `file:line` of committed conflicts (a file holding all three marker kinds); silent getter |
| `private.oo.answer.get <prompt> <?device>` | Writes the prompt to the terminal and echoes the one line typed there; nothing and rc 1 on end of input; silent getter (`oo deinstall`'s question) |
| `private.oo.mode.env.write <branch> <?oldBranch>` | Writes `~/.config/oosh/mode-env.bash` (`hash -r`, `OOSH_MODE`, and a PATH repair only when `<oldBranch>` differs); `oo mode` and the heal both call it |
| `private.oo.shared.base.ensure <basehome> <?owner>` | Creates the shared base directories install state 31 needs; the state and the heal call it |
| `private.oo.shared.base.share <base>` | Gives the base group `dev` and setgid (only when a `dev` group exists; the base only, never recursive) |
| `private.oo.shared.dir.ensure <dir> <?owner>` | Creates the missing segments with the dev-group policy (group `dev`, mode 2775 when a `dev` group exists); an existing directory is never changed |
| `private.oo.shared.config.ensure <sharedConfig> <rootConfig> <?userConfig>` | Seeds the shared config once and links the user config to it; an existing one is never copied into, but the installing state machine is carried in every run |
| `private.oo.shared.config.state.carry <sharedConfig> <rootConfig> <?userConfig>` | Carries `stateMachines` and `current.state.machine.env` into the shared config, the old ones kept as `.orig.<ts>`; a missing shared `stateMachines` folder is created through `private.oo.shared.dir.ensure` (group `dev`, 2775) |
| `private.oo.path.writable.is <path>` | Predicate: may this user write `<path>`, or its nearest existing parent — the probe behind `private.oo.path.sudo.get`, separate so a test can answer "cannot write" for root too |

`private.oo.entry.aside` is gone: the one move-aside is the kernel's `private.this.entry.aside <path> <?ts> <?asideDir>` ([oosh-architecture.md § Kernel helpers](oosh-architecture.md#kernel-helpers)), shared by `symlink.with.backup`, `oo deinstall` and the heal.

## See Also

- [Promotion Pipeline (promote)](promote.md)
- [OS & Platform Testing (os)](os.md)
- [Log System Documentation](log.md)
- [Config System Documentation](config.md)
- [Debug System Documentation](debug.md)
- [State Machine Documentation](state.md)
- [Wiki Index](wiki-index.md)
