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

Excluded from the sweep: `ogit` itself, `docs/`, `test/`, `.claude/`, `old/`, `restore/`, `*.md`, `*.json`. Lines that are only comments never count. If git cannot list any tracked files (no repository, or a "dubious ownership" refusal) the validator reports `INVALID`, never a silent `OK`.

### Conventions

- **`<?dir:$OOSH_DIR>` is always the last parameter.** Every method runs `git -C "$dir" …`, never `cd`. The variadic exceptions are `repo.grep`, `index.add`, `diff.check` and `raw`: there `<?dir>` (or `<dir>`) **precedes** the list, because a list has to come last.
- **Skipping an optional positional:** pass an empty string — `ogit remote.push "" no "$dir"` pushes the tracking branch, without tags, in `$dir`.
- **Getters vs mutators.**
  - *Getters* (`*.get`, `*.list`, `*.check`, `*.show`, `branch.find`, …) answer on stdout or by rc, never call `create.result`, and are silent (git stderr goes to `/dev/null`). That makes them safe inside tab completion and `$( … )`.
  - *Mutators* (`branch.checkout`, `remote.pull`, `commit.create`, `safeDirectory.add`, …) call `create.result` and `return $(result)`. They run git through `private.ogit.git.run`, which keeps git's stderr; on failure `RESULT` is the ogit message followed by ` — git: <git's own error text>`, e.g. `could not check out feature/x in /home/…/dev — git: error: pathspec 'feature/x' did not match any file(s) known to git`.
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

### Completion

`ogit` follows [oosh-architecture.md § Completion Function Rules](oosh-architecture.md#completion-function-rules):

- **Parameter completion** (`ogit.parameter.completion.<param>`) holds only the **domain types** shared by every method with that parameter name: `dir targetDir path base branch ref tag remote paths pathspecs asEmail`.
- **Method completion** (`ogit.<method>.completion.<param>`) holds a method's own parameters (`from`, `to`, `a`, `b`, `range`, `startPoint`, `commit`, `treeRoot`), method-specific enumerations (`source`, `format`, `scope`, `side`, `tags`, `prune`, `pattern`, `key`, `file`) and specialisations (`worktree.delete <path>` offers only linked worktrees).
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
| `repo.share` | `<?dir:$OOSH_DIR>` | make the repository of `<dir>` group-writable: dev group + g+w (`private.ensure.sharedTree`), setgid on every .git dir, `core.sharedRepository group` |
| `repo.grep` | `<pattern> <?dir:$OOSH_DIR> <?pathspecs...>` | `git grep -nE <pattern>` over the tracked files of `<dir>` (the tree sweeps); variadic, so `<?dir>` precedes `<pathspecs>` |
| `repo.files.list` | `<?dir:$OOSH_DIR>` | echo the tracked files of `<dir>`, one per line |

### branch

| Method | Parameters | Description |
|--------|-----------|-------------|
| `branch.get` | `<?dir:$OOSH_DIR>` | echo the current branch of `<dir>`, sanitised (`refs/heads/`, `refs/remotes/origin/`, `heads/origin/`, `origin/` stripped); empty when detached or not a repo |
| `branch.list` | `<?source:local> <?dir:$OOSH_DIR>` | echo branch names one per line: `local`, `remote` (cached origin/* refs, offline) or `all` |
| `branch.check` | `<ref> <?dir:$OOSH_DIR>` | rc 0 when `<ref>` resolves in `<dir>` |
| `branch.find` | `<commit> <?dir:$OOSH_DIR>` | echo every branch (local and remote) containing `<commit>` |
| `branch.checkout` | `<ref> <?dir:$OOSH_DIR>` | check `<ref>` out in `<dir>` |
| `branch.upstream.set` | `<ref> <?dir:$OOSH_DIR>` | make the current branch of `<dir>` track `<ref>` (e.g. `origin/dev`) |
| `branch.reset` | `<branch> <startPoint> <?dir:$OOSH_DIR>` | create or reset `<branch>` at `<startPoint>` and check it out (`checkout -B`) |
| `branch.compare` | `<from> <to> <?dir:$OOSH_DIR>` | symmetric branch comparison; RESULT = `up to date with <from>` \| `<from> merged in` \| `N commits behind <from>` \| `diverged: N behind <from>` (moved verbatim from `promote.branch.alignment`) |
| `branch.fastForward` | `<ref> <?dir:$OOSH_DIR>` | fast-forward the current branch of `<dir>` to `<ref>`; rc 1 (nothing changed) when it has diverged |
| `branch.merge` | `<ref> <?asEmail> <?asName> <?dir:$OOSH_DIR>` | merge `<ref>` into the current branch of `<dir>` (`--no-edit`); with `<asEmail>`/`<asName>` the merge commit carries that identity and no gpg signing |

### merge

| Method | Parameters | Description |
|--------|-----------|-------------|
| `merge.abort` | `<?dir:$OOSH_DIR>` | abort the merge in progress in `<dir>` |
| `merge.base.get` | `<a> <b> <?dir:$OOSH_DIR>` | echo the merge base commit of `<a>` and `<b>` |

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
| `remote.push` | `<?branch> <?tags:no> <?dir:$OOSH_DIR>` | push `<branch>` (default: the tracking branch) to origin; `tags=yes` pushes tags too |

### index

| Method | Parameters | Description |
|--------|-----------|-------------|
| `index.add` | `<?scope:all> <?dir:$OOSH_DIR> <?paths...>` | stage: `all` (`-A`), `updated` (`-u`, tracked files only), or the given `<paths>`; variadic, so `<?dir>` precedes `<paths>` |

### commit

| Method | Parameters | Description |
|--------|-----------|-------------|
| `commit.count` | `<from> <to> <?dir:$OOSH_DIR>` | RESULT = number of commits in `<to>` that are not in `<from>` (`refs/heads/` when bare names); `"0"` when a ref is missing |
| `commit.create` | `<?message> <?asEmail> <?asName> <?dir:$OOSH_DIR>` | commit the index of `<dir>`; no `<message>` opens the editor; `<asEmail>`/`<asName>` give a bot identity without gpg signing |
| `commit.show` | `<ref> <?dir:$OOSH_DIR>` | show commit `<ref>` |
| `commit.log.show` | `<?range> <?limit> <?format> <?dir:$OOSH_DIR>` | git log of `<range>` (default `HEAD`), at most `<limit>` commits; `<format>` is `oneline` or a `--pretty=format:` string |

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
| `safeDirectory.add` | `<path>` | add `<path>` to the global `safe.directory` list once (moved from `private.oo.safeDirectory.add`) |
| `safeDirectory.clear` | | remove every global `safe.directory` entry |
| `safeDirectory.prune` | | drop global `safe.directory` entries whose paths no longer exist (moved from `oo.safeDirectory.prune`) |
| `safeDirectory.ensure` | `<?base:$(oo.mode.base.get)>` | one global `safe.directory` entry per repository folder under `<base>`, for the calling user; idempotent |

### worktree

| Method | Parameters | Description |
|--------|-----------|-------------|
| `worktree.add` | `<branch> <targetDir> <startPoint> <?dir:$OOSH_DIR>` | add `<targetDir>` as a linked worktree of `<dir>` with `<branch>` (re)created at `<startPoint>` |
| `worktree.list` | `<?dir:$OOSH_DIR>` | `git worktree list --porcelain` of the repository of `<dir>` |
| `worktree.find` | `<branch> <?dir:$OOSH_DIR>` | echo the folder that has `<branch>` checked out: a linked worktree of the repository of `<dir>` (Phase 2 adds the sibling clone `<base>/<branch>`); empty when none |
| `worktree.delete` | `<path> <?dir:$OOSH_DIR>` | unregister and delete the linked worktree at `<path>` from the repository of `<dir>` (refuses a dirty one — gate first) |
| `worktree.prune` | `<?dir:$OOSH_DIR>` | drop worktree registrations whose folders are gone |

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

Today: `main/` is a clone and the other branch folders are linked worktrees of it (`ogit worktree.list`, `ogit worktree.find <branch>`). Phase 2 of the plan converts them to independent clones per folder (`ogit worktree.remove` / `worktree.restore`, `ogit layout.status`) — see the [spec](superpowers/specs/2026-09-23-ogit-clones-per-branch-design.md) § 2. Those three methods do not exist yet.

The target (decision D1) is one independent clone per branch folder under the base — `main/`, `dev/`, `testing/`, `prod/` and feature folders, each with its own `.git` directory, `origin` on GitHub, checked out on the branch its name says. Phase 1 (decision D3) moved every git call behind `ogit` with behaviour unchanged; Phase 2 switches the layout, and refuses to convert a dirty or unpushed folder (decision D4).

## Troubleshooting

### `fatal: detected dubious ownership in repository`

The folder belongs to another user of the shared tree and is not in your global `safe.directory` list. Trust every repository folder under the base for yourself:

```bash
ogit safeDirectory.ensure
ogit safeDirectory.list      # check the entries
ogit safeDirectory.prune     # drop entries whose folders are gone
```

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
