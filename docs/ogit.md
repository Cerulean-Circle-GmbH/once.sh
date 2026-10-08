# ogit — Git Wrapper for oosh

The `ogit` script wraps git following oosh conventions: positional parameters, tab completion, method signatures with descriptions. It is **the only caller of the git binary in the oosh tree** — every other script asks `ogit` for a branch, a pull, a commit or a trust entry instead of running `git` itself, so git behaviour, error reporting and multi-user trust live in one place.

## Overview

- Naming: `tmux→otmux, ssh→ossh, docker→odocker, git→ogit`
- Every method is `ogit.<noun>.<verb>`: nouns are git objects (`repo`, `branch`, `remote`, `commit`, `tag`, `stash`, `safeDirectory`, `worktree`, …), verbs are actions, qualifiers are parameters. The catalogue and its reasoning are in the [design spec](superpowers/specs/2026-09-23-ogit-clones-per-branch-design.md) § 3.

### The only-caller rule (D2)

`ogit` is the single caller of git (decision D2 of the spec). The rule is enforced by a production validator in the shape of `path validate`:

```bash
ogit caller.validate            # sweeps $OOSH_DIR
ogit caller.validate /some/tree # sweeps another checkout
```

It scans the tracked files once and echoes a verdict on stdout — `OK: git callers in <tree> — only ogit, N exception(s), 0 violations` or `INVALID: git callers in <tree> — N violation(s), M exception(s)` — and returns rc 1 on any violation. Each violation is named as `file:line` by `error.log`.

A raw git call is allowed only when it carries a comment-anchored marker:

| Marker | Where | Use |
|--------|-------|-----|
| `# ogit-exception: <reason>` | on the same line, or within the **5 lines above** it (calls inside a heredoc or a `bash -c` string cannot carry it on the line) | one sanctioned call |
| `# ogit-exception-file: <reason>` | on its own comment line, anywhere in the file | a whole file that runs before oosh exists (`init/oosh`, `init/once`, `Install oosh.command`) |

A raw git call is any of four spellings: `git <subcommand>`; the binary by its path, `/usr/bin/git <subcommand>`; a lookup used as the command, `"$(command -v git)" <subcommand>` or `$(which git) <subcommand>`; and the assignment of the binary to a variable, `GIT=$(command -v git)`, `gitBin=/usr/bin/git` — the later call through `$GIT` cannot be seen, so the assignment is what counts. A presence check such as `[ -x "$(command -v git)" ]` is no call.

Excluded from the sweep: `ogit` itself, `docs/`, `test/`, `.claude/`, `old/`, `restore/`, `*.md`, `*.json`. Lines that are only comments never count. If git cannot list any tracked files (no repository, nothing tracked, or a "dubious ownership" refusal) the validator reports `INVALID` with rc 2, never a silent `OK` — the kernel's `private.this.tree.tracked.check`, the guard all four tree validators share; the sweep itself is `private.this.marker.sweep` ([oosh-architecture.md § Kernel helpers](oosh-architecture.md#kernel-helpers)).

### Conventions

- **`<?dir:$OOSH_DIR>` is always the last parameter.** Every method runs `git -C "$dir" …`, never `cd`. The variadic exceptions are `repo.grep`, `index.add`, `diff.check` and `raw`: there `<?dir>` (or `<dir>`) **precedes** the list, because a list has to come last.
- **Skipping an optional positional:** pass an empty string — `ogit remote.push "" no "$dir"` pushes the tracking branch, without tags, in `$dir`.
- **Getters vs mutators.**
  - *Getters* (`*.get`, `*.list`, `*.check`, `*.show`, `branch.find`, …) answer on stdout or by rc, never call `create.result`, and are silent (git stderr goes to `/dev/null`). That makes them safe inside tab completion and `$( … )`.
  - *Mutators* (`branch.checkout`, `remote.pull`, `commit.create`, `safeDirectory.add`, …) call `create.result` and `return $(result)`. They run git through `private.ogit.git.run`, which keeps git's stderr; on failure `RESULT` is the ogit message followed by ` — git: <git's own error text>`, e.g. `could not check out feature/x in /home/…/dev — git: error: pathspec 'feature/x' did not match any file(s) known to git`. In a shared repository (`core.sharedRepository` set) git runs with umask 002 — git does not apply the setting to every file it writes (FETCH_HEAD, COMMIT_EDITMSG, a checked-out work-tree file). `private.ogit.umask.get` makes that decision once; a `--global` write (a person's own `~/.gitconfig`) runs with umask 022, whatever the caller's (`oo heal`'s clean process runs with 002); `commit.create` with the editor (which needs the terminal, so its output is not captured) applies the same umask.
  - A mutator that finds no git binary fails with rc 127 and ``ogit: git is not installed — run `oo cmd git` ``.
- Some getters return their answer in `RESULT` rather than on stdout; the tables say so (`commit.count`, `branch.compare`).

### Using ogit from another script

Inside a method of another script, load ogit lazily as the **first line** of the method, then call `ogit.*` as functions:

```bash
my.method() # <?dir:$OOSH_DIR> # … #
{
 private.this.script.load ogit ogit.branch.get
 local branch; branch=$(ogit.branch.get "$1")
 …
}
```

`private.this.script.load` sources `$OOSH_DIR/ogit` once (only when `ogit.branch.get` is not yet a function) and restores `This` afterwards. Never `source ogit` at file scope.

Where functions do not travel — `bash -c` strings, `private.as.user` hops, remote command strings — use the **command form**: `"$OOSH_DIR/ogit" <method> <params…>`.

The folder helpers the converters use are kernel methods, shared with other scripts: `private.this.folder.entries.copy <from> <to>` (each entry, dotfiles included — never `<from>/.`) and `private.this.folder.share <dir> <?setgid:yes>` (group dev, g+w, setgid — only the entries not shared yet; never chown). `odocker workspace.seed` uses the same two.

### Completion

`ogit` follows [oosh-architecture.md § Completion Function Rules](oosh-architecture.md#completion-function-rules):

- **Parameter completion** (`ogit.parameter.completion.<param>`) holds only the **domain types** shared by every method with that parameter name: `dir targetDir path base branch ref tag remote paths pathspecs asEmail`, and `startPoint commit from to a b range`, which answer like `ref`.
- **Method completion** (`ogit.<method>.completion.<param>`) holds a method's own parameters (`treeRoot`) and method-specific enumerations (`source`, `format`, `scope`, `side`, `tags`, `prune`, `pattern`, `key`, `file`).
- Both call private list getters, never each other. Docstrings carry no unpaired apostrophe; check with `./c2 signature.validate ogit`.

![ogit method tree](puml/ogit.tree/ogit.tree.drawio)

## Quick Start

```bash
# Which branch is this checkout on? (empty when detached)
ogit branch.get

# Local, cached remote, or all branch names
ogit branch.list all

# Pull the tracking branch into $OOSH_DIR, or into another folder
ogit remote.pull
ogit remote.pull "" "" ~/oosh

# Is the working tree clean?
ogit status.check && echo clean
ogit status.show

# Is a merge, rebase or cherry-pick in progress? (RESULT: none | merge | rebase | pick)
ogit merge.check ~/oosh

# Fetch a branch from a URL into FETCH_HEAD, no remote, no merge (RESULT = sha)
ogit remote.fetch.url https://github.com/Cerulean-Circle-GmbH/once.sh.git dev ~/oosh

# Read a file as it is at a ref, without a checkout
ogit file.show origin/dev init/oosh ~/oosh

# A bare repository with dev as its initial branch
ogit repo.init /tmp/fixture.git yes dev

# Where do dev and main stand relative to each other? (answer in RESULT)
ogit branch.compare main dev

# Latest release tag
ogit tag.latest.get

# Trust every repository folder under the base for the calling user
ogit safeDirectory.ensure

# Which folder has a branch checked out?
ogit worktree.find dev

# Prove no script calls git directly
ogit caller.validate
```

## Methods

Parameters are copied from the signatures in `ogit`; `<?name:default>` is optional.

### repo

| Method | Parameters | Description |
|--------|-----------|-------------|
| `repo.clone` | `<url> <branch> <targetDir>` | clone `<url>` at `<branch>` into `<targetDir>`; refuses a non-empty `<targetDir>`; on failure removes only a dir this call created |
| `repo.check` | `<?dir:$OOSH_DIR>` | rc 0 when `<dir>` is inside a git repository |
| `repo.root.get` | `<?dir:$PWD>` | echo the toplevel of the repository containing `<dir>` |
| `repo.share` | `<?dir:$OOSH_DIR>` | make the repository of `<dir>` group-writable: the kernel's share primitive on its `.git` with setgid (`private.this.folder.share <gitDir> yes`: group dev, g+w, setgid dirs), then `core.sharedRepository group`. Only what is not shared yet is touched — the entries `private.this.share.pending.list` names are handed to chgrp and chmod, never `-R`: chmod and chgrp on another user's file fail even when nothing would change, so an owner's repo.share failed after root's heal had fast-forwarded the clone and written root-owned (but right) objects into it. An entry of another owner that is right is no error; rc 1 only when something is wrong and not the caller's to change, naming `sudo -H $OOSH_DIR/ogit repo.share <dir>`; idempotent |
| `folder.finish` | `<folder>` | everything a new branch folder under the base needs: `repo.share` (.git) and `private.this.folder.share <folder> yes` (the WORKING TREE: group dev, g+w, setgid dirs; both also run without a dev group, where only setgid is set and group and g+w stay as they are — only the entries not shared yet; one still wrong and not the caller's names `sudo -H $OOSH_DIR/ogit folder.finish <folder>`), then `safeDirectory.add`, and under sudo the trust entry of the person who typed the command; no ownership change. `oo checkout`, `oo mode`, `oo mode.setup` and install state 31 call it, so does `worktree.remove` / `worktree.restore` |
| `repo.grep` | `<pattern> <?dir:$OOSH_DIR> <?pathspecs...>` | `git grep -nE <pattern>` over the tracked files of `<dir>` (the tree sweeps); variadic, so `<?dir>` precedes `<pathspecs>` |
| `repo.files.list` | `<?dir:$OOSH_DIR>` | echo the tracked files of `<dir>`, one per line |
| `repo.init` | `<dir> <?bare:no> <?branch:main>` | initialise a repository in `<dir>` (`bare=yes` for a bare one) with `<branch>` as its initial branch; git creates a missing parent. The branch name is checked first (`check-ref-format --branch`), so an invalid one is refused before anything is created; whether git knows `-b` is decided before `init` runs (a git older than 2.28 gets a plain init, then `symbolic-ref HEAD`), so a real failure never triggers a second run; rc 1 with git's reason when it cannot |
| `bundle.heads.create` | `<out> <dir> <heads...>` | write ONE bundle to `<out>` (`-` = stdout) whose `refs/heads/<name>` point at `<ref>` (a local branch, `origin/<b>` or a sha) of `<dir>`; `origin/main` travels as `main`, so a per-branch clone without a local `main` still ships both heads. The heads are first fetched under their new names into a private bare repository, which is then bundled; rc 1 and the reason when a ref is unknown. `ossh heal`'s `OOSH_HEAL_LOCAL=1` bundle (`main` and `<branch>`) is made this way |

### file

| Method | Parameters | Description |
|--------|-----------|-------------|
| `file.show` | `<ref> <path> <?dir:$OOSH_DIR>` | echo the content of `<path>` at `<ref>` in `<dir>` (`cat-file blob`, so a directory is refused, not listed); rc 1 and nothing when the ref or the path does not exist, or the path is a directory; git's reason reaches RESULT. `<ref>` completes through the shared `ogit.parameter.completion.ref`; `<path>` completes from the tracked files of the current tree |
| `file.history.blobs.get` | `<path> <?count:200> <?dir:$OOSH_DIR>` | echo the blob ids `<path>` had in the last `<count>` commits of `<dir>` that changed it, newest first, one per line, from one `git log --raw`; a deletion is no blob and is skipped; nothing and rc 1 on a tree git refuses, a bad count or no path; a getter, no RESULT |
| `file.hash.get` | `<file>` | echo the git blob id of a working file (`git hash-object`); nothing and rc 1 when `<file>` is no regular file; a getter, no RESULT |

### branch

| Method | Parameters | Description |
|--------|-----------|-------------|
| `branch.get` | `<?dir:$OOSH_DIR>` | echo the current branch of `<dir>`, sanitised (`refs/heads/`, `refs/remotes/origin/`, `heads/origin/`, `origin/` stripped); empty when detached or not a repo |
| `branch.list` | `<?source:local> <?dir:$OOSH_DIR>` | echo branch names one per line: `local`, `remote` (cached origin/* refs, offline) or `all` |
| `branch.check` | `<ref> <?dir:$OOSH_DIR>` | rc 0 when `<ref>` resolves in `<dir>` — the one existence check (`ossh`, `os platform.test` and `oo update` ask it); pass `origin/<name>` for a branch that exists only on origin, `refs/remotes/origin/<name>` to be exact |
| `branch.find` | `<commit> <?dir:$OOSH_DIR>` | echo every branch (local and remote) containing `<commit>` |
| `branch.checkout` | `<ref> <?dir:$OOSH_DIR>` | check `<ref>` out in `<dir>` |
| `branch.upstream.set` | `<ref> <?dir:$OOSH_DIR>` | make the current branch of `<dir>` track `<ref>` (e.g. `origin/dev`) |
| `branch.reset` | `<branch> <startPoint> <?dir:$OOSH_DIR>` | create or reset `<branch>` at `<startPoint>` and check it out (`checkout -B`) |
| `branch.compare` | `<from> <to> <?dir:$OOSH_DIR>` | symmetric branch comparison; RESULT = `up to date with <from>` \| `<from> merged in` \| `N commits behind <from>` \| `diverged: N behind <from>` (moved verbatim from `promote.branch.alignment`) |
| `branch.fastForward` | `<ref> <?dir:$OOSH_DIR>` | fast-forward the current branch of `<dir>` to `<ref>`; rc 1 (nothing changed) when it has diverged |
| `branch.merge` | `<ref> <?asEmail> <?asName> <?dir:$OOSH_DIR>` | merge `<ref>` into the current branch of `<dir>` (`--no-edit`); with `<asEmail>`/`<asName>` the merge commit carries that identity and no gpg signing |
| `branch.adopt` | `<ref> <?message> <?asEmail> <?asName> <?dir:$OOSH_DIR>` | make the current branch of `<dir>` a merge of itself and `<ref>` whose content is exactly the tree of `<ref>` (`commit-tree`, then `branch.fastForward`); refuses a dirty tree and a ref that does not resolve; nothing to do when the branch already contains `<ref>` |

`branch.adopt` exists for a promotion after tree-reset rollbacks (30 Sep 2026: prod and testing each got a commit whose tree is an older one): their merge base is still the regression both left, so a 3-way merge conflicts everywhere although the intent — the target becomes the content of the source — is plain; adopt records that intent as one merge commit, with the full history and no force push.

### merge

| Method | Parameters | Description |
|--------|-----------|-------------|
| `merge.abort` | `<?dir:$OOSH_DIR>` | abort the merge in progress in `<dir>` |
| `merge.base.get` | `<a> <b> <?dir:$OOSH_DIR>` | echo the merge base commit of `<a>` and `<b>` |
| `merge.check` | `<?dir:$OOSH_DIR>` | is an operation in progress in `<dir>`? RESULT = `none` (rc 0), or `merge` \| `rebase` \| `pick` with rc 1; rc 2 when `<dir>` is not a repository. Probe order: `rebase-merge`, `rebase-apply`, `MERGE_HEAD`, `CHERRY_PICK_HEAD`, `sequencer` — the outer rebase first, because a `rebase -r` stopped on a merge commit has a `MERGE_HEAD` inside `rebase-merge`. git names the files (`--git-path`), so a linked worktree or a separate git dir is found too. `<dir>` completes through the shared `ogit.parameter.completion.dir` |

### conflict

| Method | Parameters | Description |
|--------|-----------|-------------|
| `conflict.list` | `<?dir:$OOSH_DIR>` | echo the conflicted paths of the merge in progress, one per line |
| `conflict.resolve` | `<file> <?side:theirs> <?dir:$OOSH_DIR>` | resolve the conflict of `<file>` by taking `<side>` (`theirs` = the merged-in branch, `ours` = the current one) and stage it |

### remote

| Method | Parameters | Description |
|--------|-----------|-------------|
| `remote.url.get` | `<?remote:origin> <?dir:$OOSH_DIR>` | echo the URL of `<remote>`, empty when there is none |
| `remote.branch.list` | `<?remote:origin> <?dir:$OOSH_DIR>` | echo the branches `<remote>` has right now (`ls-remote` — needs the network); empty when unreachable |
| `remote.url.set` | `<url> <?remote:origin> <?dir:$OOSH_DIR>` | point `<remote>` of `<dir>` at `<url>` |
| `remote.fetch` | `<?prune:no> <?dir:$OOSH_DIR>` | fetch origin into `<dir>`; `prune=yes` drops deleted remote branches |
| `remote.pull` | `<?url> <?branch> <?dir:$OOSH_DIR>` | pull into `<dir>`; with `<url> <branch>` pull that branch from that URL instead of the tracking remote (the https fallback of `oo.update`) |
| `remote.fetch.url` | `<url> <branch> <?dir:$OOSH_DIR>` | fetch `<branch>` from `<url>` into `FETCH_HEAD` of `<dir>` without adding a remote and without merging; RESULT = the fetched commit sha, rc from git. The fetch half of the HTTPS fallback of `oo update` (the pull is: fetch, then verify the ref exists, then fast-forward only — `oo update`'s gate refuses first, and nothing is ever merged). `<url>` completes with the origin URL, `<branch>` with the cached origin branches, `<dir>` through the shared `ogit.parameter.completion.dir` |
| `remote.push` | `<?branchOrRefspec> <?tags:no> <?dir:$OOSH_DIR>` | push `<branch>` (default: the tracking branch) to origin; `tags=yes` pushes tags too. Never forced, never a deletion: a spelling that starts with `-`, `+` or `:`, ends in `:` or has an empty source is refused (rc 1) before git is asked. `<branch>` otherwise goes to `git push origin` as it is, so a refspec works: `ogit remote.push <sha>:refs/heads/platform-test-<sha>` makes the remote branch at that commit without a local branch (how `os platform.heal.test` ships a sha) |
| `remote.branch.delete` | `<branch> <?remote:origin> <?dir:$OOSH_DIR>` | delete `<branch>` on `<remote>` (`push --delete`); refuses `dev`, `testing`, `prod` and `main` without asking the remote; rc 1 and the reason when git refuses. How the platform test removes the temporary branch it shipped |

### index

| Method | Parameters | Description |
|--------|-----------|-------------|
| `index.add` | `<?scope:all> <?dir:$OOSH_DIR> <?paths...>` | stage: `all` (`-A`), `updated` (`-u`, tracked files only), or the given `<paths>`; variadic, so `<?dir>` precedes `<paths>` |
| `index.remove` | `<path> <?dir:$OOSH_DIR>` | remove `<path>` from the index and the working tree of `<dir>` (`git rm`); rc 1 when git refuses (not tracked, local changes) — `RESULT` carries git's reason |

### commit

| Method | Parameters | Description |
|--------|-----------|-------------|
| `commit.count` | `<from> <to> <?dir:$OOSH_DIR>` | RESULT = number of commits in `<to>` that are not in `<from>` (`refs/heads/` when bare names); `"0"` when a ref is missing |
| `commit.create` | `<?message> <?asEmail> <?asName> <?dir:$OOSH_DIR>` | commit the index of `<dir>`; no `<message>` opens the editor; `<asEmail>`/`<asName>` give a bot identity without gpg signing |
| `commit.show` | `<ref> <?dir:$OOSH_DIR>` | show commit `<ref>` |
| `commit.log.show` | `<?range> <?limit> <?format> <?dir:$OOSH_DIR>` | git log of `<range>` (default `HEAD`), at most `<limit>` commits; `<format>` is `oneline` or a `--pretty=format:` string |
| `commit.pick` | `<commit> <?asEmail> <?asName> <?dir:$OOSH_DIR>` | cherry-pick `<commit>` onto the current branch of `<dir>` with `-x`; on a conflict rc 1, the pick stays in progress and RESULT names the conflicted paths |
| `commit.pick.continue` | `<?asEmail> <?asName> <?dir:$OOSH_DIR>` | finish the pick in progress in `<dir>` after its conflicts are resolved and staged; keeps the picked message; `<asEmail>`/`<asName>` give a bot identity |
| `commit.pick.abort` | `<?dir:$OOSH_DIR>` | abort the pick in progress in `<dir>`; the tree is back to what it was before the pick |

### status

| Method | Parameters | Description |
|--------|-----------|-------------|
| `status.show` | `<?format:short> <?dir:$OOSH_DIR>` | working-tree status: `short` (`--short --branch`) or `porcelain` |
| `status.check` | `<?dir:$OOSH_DIR>` | rc 0 when the working tree and the index of `<dir>` are clean |

### diff

| Method | Parameters | Description |
|--------|-----------|-------------|
| `diff.check` | `<?dir:$OOSH_DIR> <?paths...>` | rc 0 when `<paths>` (default: everything) have no unstaged changes; variadic, so `<?dir>` comes first |
| `diff.show` | `<a> <b> <?format:stat> <?dir:$OOSH_DIR>` | diff between `<a>` and `<b>` (three-dot); format `stat` or `full` |

### tag

| Method | Parameters | Description |
|--------|-----------|-------------|
| `tag.list` | `<?pattern> <?dir:$OOSH_DIR>` | echo tags matching `<pattern>` (default all), newest creation date first |
| `tag.check` | `<tag> <?dir:$OOSH_DIR>` | rc 0 when `<tag>` exists |
| `tag.latest.get` | `<?pattern:v*> <?dir:$OOSH_DIR>` | echo the highest tag matching `<pattern>` by version sort |
| `tag.create` | `<tag> <?ref:HEAD> <?dir:$OOSH_DIR>` | create lightweight `<tag>` at `<ref>` |

### stash

| Method | Parameters | Description |
|--------|-----------|-------------|
| `stash.push` | `<message> <?dir:$OOSH_DIR>` | stash the working tree of `<dir>` under `<message>` |
| `stash.pop` | `<?dir:$OOSH_DIR>` | pop the top stash of `<dir>` |
| `stash.top.get` | `<?dir:$OOSH_DIR>` | echo the message of `stash@{0}`, empty when the stack is empty |
| `stash.drop` | `<?dir:$OOSH_DIR>` | drop the top stash of `<dir>`; rc 1 `no stash to drop in <dir>` on an empty stack. The follow-up to a `stash.pop` that conflicted: git wrote the markers into the work tree and kept the stash — after the resolve the change is in the tree, and popping again would re-apply it (T-OGIT-STASH-DROP) |

### config

| Method | Parameters | Description |
|--------|-----------|-------------|
| `config.get` | `<key> <?scope:any> <?dir:$OOSH_DIR>` | echo `<key>`: scope `any` = the global git config, else the repository config of `<dir>`; scope `local` = the repository config of `<dir>` only |
| `config.set` | `<key> <value> <?dir:$OOSH_DIR>` | set `<key>` in the repository config of `<dir>` |
| `config.email.get` | `<?dir:$OOSH_DIR>` | echo the committer email: global `user.email`, else the one of the repository of `<dir>` |

### safeDirectory

| Method | Parameters | Description |
|--------|-----------|-------------|
| `safeDirectory.list` | | echo the global `safe.directory` entries, one per line (honours `GIT_CONFIG_GLOBAL`) |
| `safeDirectory.add` | `<path>` | add `<path>` to the global `safe.directory` list once, in the letter case of the file system: git matches the entry as a string, and macOS spells `/Users/Shared` where a caller may say `/Users/shared` — `private.this.path.case.get` folds it here, so `ensure`, the converters and every caller get the same spelling; `layout.status` compares the folded spelling for `trusted=` |
| `safeDirectory.prune` | | drop global `safe.directory` entries whose paths no longer exist (moved from `oo.safeDirectory.prune`): in place, one `--unset-all` per stale value (anchored, regex-escaped — old git has no `--fixed-value`), so a kept entry is never absent; a second run changes nothing. There is no `safeDirectory.clear`: a one-word wipe of every entry is not a method |
| `safeDirectory.ensure` | `<?base:$(oo.mode.base.get)>` | one global `safe.directory` entry per repository folder under `<base>`, for the calling user; idempotent |

### worktree

| Method | Parameters | Description |
|--------|-----------|-------------|
| `worktree.add` | `<branch> <targetDir> <startPoint> <?dir:$OOSH_DIR>` | add `<targetDir>` as a linked worktree of `<dir>` with `<branch>` (re)created at `<startPoint>` |
| `worktree.list` | `<?dir:$OOSH_DIR>` | `git worktree list --porcelain` of the repository of `<dir>` |
| `worktree.find` | `<branch> <?dir:$OOSH_DIR>` | echo the folder that has `<branch>` checked out: a linked worktree of the repository of `<dir>`, else the sibling clone `<base>/<branch>` when it is on `<branch>`; empty when none |
| `worktree.delete` | `<path> <?dir:$OOSH_DIR>` | unregister and delete the linked worktree at `<path>` from the repository of `<dir>` (refuses a dirty one — gate first) |
| `worktree.prune` | `<?dir:$OOSH_DIR>` | drop worktree registrations whose folders are gone |
| `worktree.remove` | `<?base:$(oo mode.base.get)>` | turn every linked worktree of `<base>/main` into an independent clone of the same branch, carrying its gitignored files across; first gives a worktree that tracks nothing, and whose branch origin has, that upstream (`private.ogit.worktree.upstream.ensure`, also in a sudo re-run); refuses on a dirty or unpushed folder; idempotent; run with sudo on a shared tree — see [§ Layout](#layout) |
| `private.ogit.worktree.upstream.ensure` | `<?base:$(oo mode.base.get)>` | give every linked worktree of `<base>/main` that is on a branch, tracks nothing and whose branch origin has (`refs/remotes/origin/<branch>` in `main`) that upstream, so `worktree.remove` can convert it; a branch origin lacks keeps none and its gate names it. RESULT names what was set; rc 1 when `<base>/main` is no repository. `worktree.remove` calls it itself before its gate |
| `worktree.restore` | `<?base:$(oo mode.base.get)>` | the reverse: every sibling clone of `<base>/main` (same origin) back into a linked worktree of `main`; same gates, same carry |

### layout

| Method | Parameters | Description |
|--------|-----------|-------------|
| `layout.status` | `<?base:$(oo mode.base.get)>` | one line per folder under `<base>`: shape (`worktree`/`clone`), dirty/ahead/behind counts, `shared=` `setgid=` `trusted=`; rc 1 when the folders other than `main/` are not all the same shape |

### binary / raw

| Method | Parameters | Description |
|--------|-----------|-------------|
| `binary.check` | | rc 0 when the git binary is on PATH |
| `raw` | `<dir> <args...>` | run `git -C <dir> <args...>` verbatim — the documented last resort; every use needs a comment saying why no method fits; variadic, so `<dir>` comes first |

### caller

| Method | Parameters | Description |
|--------|-----------|-------------|
| `caller.validate` | `<?treeRoot:$OOSH_DIR>` | verify ogit is the only caller of the git binary in the tracked tree: every other raw git call carries a comment-anchored ogit-exception marker; echo an `OK:`/`INVALID:` verdict; rc 1 on any violation |

## Layout

**The clone layout** (decision D1, built in Phase 2 of the plan): one independent clone per branch folder under the components base — `main/`, `dev/`, `testing/`, `prod/` and feature folders, each with its own `.git` **directory**, `origin` on GitHub, checked out on the branch its name says, group-shared (`core.sharedRepository=group`, group `dev`, g+w, setgid — `ogit repo.share`) and trusted per folder (`ogit safeDirectory.ensure`). The base itself is group `dev` with setgid. `main/` is always present — it is how `oo mode.base.get` finds the base. The contract, and how `oo checkout` / `oo mode` / install state 31 build it, is [oo.md § The clone layout](oo.md#the-clone-layout).

```bash
ogit layout.status            # one line per folder: shape, dirty/ahead/behind, shared= setgid= trusted=
```

```
dev            clone     dirty 0   ahead 0   behind 0   shared=group setgid=yes trusted=yes
main           clone     dirty 0   ahead 0   behind 8   shared=group setgid=yes trusted=yes
prod           clone     dirty 0   ahead 0   behind 0   shared=group setgid=yes trusted=yes
```

`layout.status` returns 1 on a **mixed** layout (the folders other than `main/` not all the same shape) — the sign of a conversion that stopped half-way. A host installed before the clone layout shows `main` as `clone` and every other folder as `worktree`; that is consistent (rc 0) but old, and `test.platform.shared.layout.invariant` fails it.

**The converters.** Nothing converts a host automatically — not install, not `oo update`. Two explicit, idempotent methods do, in both directions:

| Command | Does |
|---|---|
| `ogit worktree.remove <?base>` | every linked worktree of `<base>/main` → an independent clone of the same branch |
| `ogit worktree.restore <?base>` | every sibling clone of `<base>/main` with the same origin → a linked worktree of `main` again |

Their gates, checked for **every** folder (and `main/`) **before any folder is touched** — each refusal names the folder and the fix:

- **dirty** — `<folder> has N uncommitted change(s) — commit or stash them in <dir> first`;
- **no upstream** — `<folder> tracks no upstream — set it with: ogit branch.upstream.set origin/<branch> <dir>, …`;
- **unpushed** — `<folder> is N commit(s) ahead of its upstream — push it first`;
- **detached** — `<folder> is detached — check a branch out first`;
- `worktree.restore` only: **unpushed commits on a `main/` local branch** it would reset — `main/ has N unpushed commit(s) on its local <branch> branch, which restore would reset — push it or delete it in <base>/main first`.
- `worktree.restore` only: **refs the clone owns** (`private.ogit.clone.gate`) — restore deletes the clone, and every ref in it goes too: a **stash** (`<folder> holds a stash (…) that restore would delete — pop or drop it…`), **another local branch** that its cached `origin/<branch>` lacks or is behind (`<folder> has N unpushed commit(s) on its local branch <b> — push it … or delete it first`), a **tag** that `main/` does not have. A linked worktree shares its refs with `main/`, so `worktree.remove` does not need this gate.

**Ignored files are carried.** A folder's gitignored files (on a dev host e.g. `sessions/`) are copied before the folder is removed and copied into the new folder once it is finished. The copy is a **backup that is kept**: `$HOME/.oosh.backups/<UTC-stamp>-ogit-<folder>` — under `sudo` that is root's `$HOME`. Nothing deletes it; remove it yourself once you are satisfied.

**They ask for sudo by themselves.** The folders of a shared tree belong to different users of the `dev` group, and the converters delete and recreate them — so when you do not own the base, a folder or its `.git`, `ogit worktree.remove` / `ogit worktree.restore` re-run themselves through sudo (by the canonical path of `ogit` with the base already resolved: sudo's `PATH` has no oosh) and your password is asked (`private.ogit.sudo.rerun` says "via sudo (enter your password if asked)"; when `private.this.sudo.prompt.is` says sudo cannot ask (`$SUDO` carries `-n`, or the `sudo` function adds it), as under `oo heal` without a terminal, it says "via sudo -n (no password prompt)" instead). On a tree you own (a single-user host) they run directly. Under sudo each new folder is trusted for root **and** for the user who typed the command (`SUDO_USER`); other users get their entries from `oo update` / `oo user.fix`. `<base>` Tab-completes to the components base.

## Migrating a host from worktrees to clones

A **user-run** runbook — never automatic. It is written for a dev host installed before the clone layout (`main/` a clone, `dev/` and `prod/` linked worktrees, no `testing/`); on any host the steps are the same.

**Before you start:** stop other shells, agents and editors that work inside `dev/` or `prod/` (their working directory is deleted and recreated), and push everything — the conversion refuses a dirty or unpushed folder.

No `sudo` in front: the converters ask for it themselves when the tree is shared (see above). Keep the base in a variable for the checks:

```bash
cd ~/oosh
base=$(oo mode.base.get)      # e.g. /home/shared/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/Once.sh
```

**1. Look first.**

```bash
ogit layout.status "$base"
```

Expect `main clone`, `dev worktree`, `prod worktree`, every line `dirty 0` and `ahead 0` (`behind` does not matter). Anything else: commit and push in that folder first (`oo commit`, `ogit remote.push <branch> no <dir>`). The conversion would refuse anyway, naming the folder.

**2. Ignored files are backed up automatically.** `dev/sessions/` (with `sessions/agent.context.md`) is gitignored: `worktree.remove` copies it into `/root/.oosh.backups/<UTC-stamp>-ogit-dev`, recreates `dev/` as a clone and copies it back. Nothing to do — just note the backup path it reports.

**3. Convert.**

```bash
ogit worktree.remove          # asks for your sudo password on a shared tree
```

Expect, per folder, `carrying ignored dev/sessions` then `dev: worktree → clone (dev)` and `prod: worktree → clone (prod)`, and finally `2 folder(s) converted to clones under <base>`. A refusal stops before anything is touched — fix what it names and re-run. Your shell's working directory was the old `dev/`: re-enter it with `cd ~/oosh`.

**4. Check.**

```bash
cd ~/oosh
ogit layout.status "$base"
cat sessions/agent.context.md        # intact
```

Expect every line `clone … shared=group setgid=yes trusted=yes`. `trusted=no` for you: `oo update` (or `ogit safeDirectory.ensure "$base"`). `shared=no` / `setgid=no`: `sudo ./ogit repo.share "$base/<folder>"`.

**5. The base setgid.**

```bash
stat -c '%A %G' "$base"              # macOS: stat -f '%Sp %Sg' "$base"
```

Expect group `dev` and an `s` in the group bits (`drwxrwsr-x dev`). A base from an older install is `root:dev` without setgid; fix it once:

```bash
sudo chgrp dev "$base" && sudo chmod g+ws "$base"
```

**6. Login shells and mode switching.**

```bash
env -i HOME=$HOME bash -l -c 'oo mode.list'     # dev, main, prod listed, no "unsafe ownership"
oo mode prod && oo mode dev
```

**7. Before the first promote: the `testing/` folder.** `promote` merges in `<base>/testing` and refuses without it (`no folder holds branch testing — run: oo checkout testing`).

```bash
oo checkout testing                  # → <base>/testing, cloned, shared, trusted
promote status
```

**8. Optional — prove it is reversible.**

```bash
ogit worktree.restore                # dev, prod, testing → worktrees of main again
cd ~/oosh; ogit layout.status "$base" # main clone, the rest worktree
ogit worktree.remove                 # and back to clones
cd ~/oosh && cat sessions/agent.context.md   # still intact after the round trip
```

`worktree.restore` also refuses when `main/` holds unpushed commits on a local branch it would reset.

**9. The platform invariant.**

```bash
./test.suite run platform.shared.layout.invariant 1     # → PASS
```

Before the migration it fails INVARIANT-1 (`linked worktree(s) … dev prod`) and, on an older base, INVARIANT-4 (base setgid) — each FAIL line carries its recovery command.

### If something goes wrong

- **Every refusal names the folder and the command that fixes it** — a dirty, unpushed, upstream-less or detached folder stops the conversion before anything is touched. Fix, then re-run: both converters are idempotent and skip folders that are already done.
- **`worktree.remove` needs no network and no GitHub credentials** (root has none): it clones each branch from `<base>/main` — a worktree's branch is a local branch of main, already proven clean and pushed — into `<base>/.ogit-<folder>.new`, points it at main's origin URL, and only then removes the worktree and moves the clone into place. A clone that cannot be made changes nothing; a leftover `.ogit-<folder>.new` is named and must be removed before a re-run. (Until 2026-09-25 it removed the worktree first and cloned from the GitHub URL as root — on a real host that failed and left the folder missing; recover then with `git clone -b <branch> <url> <dir>` as your own user.)
- **A failure mid-way** (e.g. a `worktree.restore` whose worktree could not be added after its clone was removed) says so and prints the exact recovery command, e.g. `ogit worktree.add <branch> <dir> origin/<branch> <base>/main`. `ogit layout.status` then reports a mixed layout (rc 1) until you finish it — run the recovery command, then the converter again.
- **The backup under `~/.oosh.backups/` is never deleted** (under sudo: `/root/.oosh.backups/`). If ignored files did not come back, copy each entry yourself — e.g. `sudo cp -Rp /root/.oosh.backups/<stamp>-ogit-dev/sessions <base>/dev/` — never the backup dir itself (`…/<stamp>-ogit-dev/.`): `cp -Rp` would copy its private `700 root` mode onto the folder and lock everyone else out. If a folder did end up unreadable: `sudo chgrp -R dev <base>/<folder> && sudo chmod -R g+rwX,o+rX <base>/<folder> && sudo find <base>/<folder> -type d -exec chmod g+s {} +`.
- **Run the converters from anywhere** — even from inside the folder they replace (`~/oosh` = `dev/`); global git config runs at `/`, so a deleted working directory no longer matters. Afterwards `cd ~/oosh` again in every shell that stood in a converted folder.
- **Committed work is never at risk**: the gate refuses anything that is not on origin, so every branch can always be re-cloned from GitHub.

## Troubleshooting

### `fatal: detected dubious ownership in repository`

The folder belongs to another user of the shared tree and is not in your global `safe.directory` list. Trust every repository folder under the base for yourself:

```bash
ogit safeDirectory.ensure
ogit safeDirectory.list      # check the entries
ogit safeDirectory.prune     # drop entries whose folders are gone
```

`oo update` and `oo user.fix` run `ogit safeDirectory.ensure` for you; `ogit layout.status` shows `trusted=` per folder.

### git is not installed

Mutators fail with rc 127 and name the fix:

```bash
oo cmd git
```

### A mutator failed

Read `RESULT` — git's own reason is appended after ` — git: `:

```bash
ogit branch.checkout feature/x || echo "$RESULT"
```

### A script calls git directly

```bash
ogit caller.validate
```

names each violation as `file:line`. Replace the call with the matching `ogit` method (or `ogit raw <dir> …` with a comment saying why no method fits), or — for a genuine exception — mark it with `# ogit-exception: <reason>` on the line or within the 5 lines above.

## See Also

- [Design spec: ogit and the clone-per-branch layout](superpowers/specs/2026-09-23-ogit-clones-per-branch-design.md)
- [Implementation plan](superpowers/plans/2026-09-23-ogit-clones-per-branch.md)
- [oosh-architecture.md § Completion Function Rules](oosh-architecture.md#completion-function-rules)
- [Repair Toolkit](repair-toolkit.md)
- [Wiki Index](wiki-index.md)
- [ogit method tree](puml/ogit.tree/ogit.tree.drawio)
