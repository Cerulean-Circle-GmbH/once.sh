# `ogit` and the clone-per-branch layout — design

**Written 2026-09-23 · Branch `dev` (`8c46828`) · Status: DESIGN, approved section by section in
session; implementation plan follows in `docs/superpowers/plans/`.**

**Decision (user, 2026-09-23):** git worktrees go. Every branch folder under
`…/Once.sh/` becomes an independent clone, "like before worktrees". A new wrapper script,
`ogit`, modelled on `odocker`, becomes the **only** place in the tree that calls the `git`
binary, and it owns the conversion in both directions (`ogit worktree.remove` /
`ogit worktree.restore`), so the worktree layout can be put back.

This supersedes the verdict of
[research/2026-09-22-worktrees-vs-version-convention.md](../../research/2026-09-22-worktrees-vs-version-convention.md)
§ 2 ("removing worktrees does not make sense"). That document's four objections are answered
in § 5 below; its invariants (§ 6 there) are preserved except the one it lists last ("`main/`
remains the single `.git` holder") — that one is the change.

Grounded by three read-only sweeps (worktree coupling, `odocker` as template, every `git`
invocation in the tree) — citations are `file:line` in `dev` at `8c46828`.

---

## 1. Decisions taken in session

| # | Question | Decision |
|---|---|---|
| D1 | On-disk layout after conversion | **Independent clone per branch folder.** `main`, `dev`, `testing`, `prod` and feature folders each a full clone, own `.git` directory, `origin` = GitHub, checked out on the branch its name says. `main/` stays as an ordinary clone of `main`. |
| D2 | Reach of `ogit` | **`ogit` becomes the only git caller in the tree.** Every raw `git …` in bash-mode scripts moves behind an `ogit.<noun>.<verb>` method. Exceptions are explicit and marked (§ 3.6). |
| D3 | Sequencing | **Two phases.** Phase 1: `ogit` + all call sites moved, behaviour identical, worktrees untouched. Phase 2: the layout switch. Two plans, two reviews, each independently revertable. |
| D4 | Conversion safety | **Refuse on dirty or unpushed folders.** Name the folder and the fix (commit/push or stash); never carry local work across. |

---

## 2. The layout model

```
…/Components/com/ceruleanCircle/EAM/1_infrastructure/Once.sh/     ← "the base", developking:dev, setgid, g+w
├── main/       clone, branch main        (ordinary — keeps base detection and ooShim working)
├── dev/        clone, branch dev
├── testing/    clone, branch testing     (created on demand by oo checkout / promote's refusal)
├── prod/       clone, branch prod
└── my.thing/   clone, branch feature/my-thing   (name derived as oo.checkout does today)
```

- Each folder: `.git` is a **directory**; `remote.origin.url` = `git@github.com:Cerulean-Circle-GmbH/once.sh.git`;
  `core.sharedRepository = group`; setgid + `g+w` on `.git` and everything under it.
- `~/oosh` stays the symlink `oo mode` flips; `~/config` stays branch-independent (`sharedConfig`).
  `OOSH_DIR`/`CONFIG_PATH` doctrine (`this.anchor.validate`) is untouched.
- Base detection (`oo.mode.base.get`, oo:523-579) keeps working: strategy 4 keys on a sibling
  folder literally named `main` with a `.git` directory — a clone satisfies it. Strategies 2/3
  (worktree list, `.git` as file) simply stop matching. `templates/user/ooShim:5-27` likewise
  needs only `$base/main` and accepts `.git` dir or file.
- What a folder means does **not** change: "a directory named `<branch>` holding a checkout of
  `<branch>`". The inventory found that every consumer except the four `git worktree add`
  sites, `promote`'s prod merge and the state-31 permission block already only needs that.

### 2.1 The two conversions (Phase 2)

Both are `ogit` methods, idempotent, run with `sudo` by a dev-group user (the tree is
`developking:dev`; folders may be owned by other users), never triggered by `oo update`
(same doctrine as `oo profile.fix`).

**`ogit worktree.remove <?base>`** — for every linked worktree of `<base>/main`
(`git -C main worktree list --porcelain`):
1. Gate: working tree clean (`status --porcelain` empty, including untracked) **and**
   `ahead 0` of its upstream. Otherwise stop before touching anything, naming the folder and the
   fix. Also refuse if `main` itself is dirty or ahead, and if the branch has no upstream.
2. `git -C main worktree remove <folder>` (the folder is now gone from disk).
3. `ogit repo.clone <originUrl> <branch> <base>/<branch>`.
4. `ogit repo.share <folder>` (§ 4) and `chown -R developking:dev` to match the tree.
5. `ogit safeDirectory.add <folder>` for the calling user (other users get theirs from
   `config init.user`, § 4).
Feature folders (any linked worktree) convert the same way. `main` is left as is. A base with no
linked worktrees is a no-op with rc 0. Report per folder on stdout (status idiom).

**`ogit worktree.restore <?base>`** — the exact reverse: for every clone folder other than
`main` (a sibling with a `.git` directory whose `origin` matches `main`'s): same gate; delete the
folder; `git -C main fetch origin`; `git -C main worktree add -B <branch> ../<branch>
origin/<branch>`; permissions as state 31 does today (setgid/`g+w` on `main/.git`, per-folder
`safe.directory`).

Both conversions carry gitignored files: before a folder is touched, its ignored paths are
copied into a timestamped backup (`$HOME/.oosh.backups/<UTC-stamp>-ogit-<folder>`) and restored
into the new folder once it is finished; tracked dirty work is still refused by the gate (D4).

**`ogit layout.status <?base>`** — read-only, plain `echo`: one line per folder —
`worktree | clone | missing`, `dirty N`, `ahead N`, `behind N`, `shared=group|no`,
`setgid=yes|no`, `trusted=yes|no` (calling user's `safe.directory`). rc 1 when any folder is
not the expected shape for the host (mixed layouts are reported, never silently accepted).

---

## 3. The `ogit` script (Phase 1)

### 3.1 Shape
- Created with `oo new ogit`; every method with `oo method.new ogit.<noun>.<verb>` (test stubs
  land in `test/test.ogit`, created by `oo test.new ogit`).
- Header line as the other wrappers: `# ogit - git wrapper for oosh. No flags, positional params
  only. Following: tmux→otmux, ssh→ossh, docker→odocker, git→ogit`.
- Section banners (`# ─── REPO ───`) per noun; `### new.method` marker; `ogit.usage` via
  `this.help` with one example per noun; `ogit.start() { source this; this.start "$@"; }`;
  last line `ogit.start "$@"`.
- Dual use like `ossh`: **library** (`source ogit` from oo, promote, config, user, this-aliases)
  with no side effects when sourced, and **command** (`ogit remote.pull`, `~/oosh/ogit safeDirectory.add
  …` inside a `private.as.user` hop or a remote ssh string). The implementer verifies how
  `this.start` behaves when a script is sourced with no arguments (c2 sources scripts with
  `completion.discover`; `oo:315` sources `config` with output suppressed) and gives
  `ogit.start` an explicit sourced guard if needed.
- c2 completion is automatic for any script in `$OOSH_DIR` (`templates/user/c2.install:43-69`);
  no registration list.
- Reserved dispatch words (`this:1258`): no method named `start`, `help*`, `restart`,
  `localInstall`; no dashes.

### 3.2 Conventions
- Required parameters first, **`<?dir:$OOSH_DIR>` last**. Every call is `git -C "$dir" …`;
  never `cd`. So `ogit remote.pull` acts on `~/oosh`, `ogit remote.pull <dir>` elsewhere.
- **Getters** answer on stdout, **no `create.result`** (consumed as `$(...)` and by completion —
  the `create.result`-breaks-c2 rule). **Mutators** `create.result N "msg"` + `return $(result)`.
  Exit codes of the underlying git are passed through on mutators.
- One binary guard: `ogit.binary.check` (rc only) and `private.ogit.require` (error.log + rc 127)
  called by every mutator.
- `GIT_CONFIG_GLOBAL` honoured everywhere `--global` is used (test.osshLayout and the
  safeDirectory tests depend on it).
- Bot identity for `promote` is explicit: `ogit.commit.create <message> <asEmail> <asName>` and
  `ogit.branch.merge <ref> <asEmail> <asName>` (`-c user.email -c user.name -c
  commit.gpgsign=false`), not an environment switch.
- `ogit.raw <dir> <args…>` is the documented last resort so the sweep (§ 6) stays absolute.
- Shared completers: `ogit.parameter.completion.branch` (local + `origin/`, via
  `ogit.branch.list all`, no `create.result`), `.dir` (`compgen -d`), `.tag`,
  `.remote`, `.ref` (branches + tags).
- Naming: camelCase, dots, no underscores (`mergeBase`, `safeDirectory`, `takeTheirs`).

### 3.3 Catalogue — every method is `ogit.<noun>.<verb>`

The first draft of this catalogue mixed bare git verbs (`ogit.checkout`, `ogit.pull`), verb
qualifiers (`merge.as`, `push.tags`) and format names in the verb slot (`log.oneline`,
`status.short`). The standard (docs/oosh-architecture.md § Object.Verb Pattern) wants a git
**object** as the noun and an **action** as the verb, with qualifiers as parameters. That is
what follows; the drawing is `docs/puml/ogit.tree/ogit.tree.drawio`. Counts are raw call sites
today (inventory A). Every signature ends with `<?dir:$OOSH_DIR>` unless noted.

**repo**
| Method | Signature | Replaces |
|---|---|---|
| `ogit.repo.clone` | `<url> <branch> <targetDir>` mutator | oo:1230, 2022, 2539, agentRoom:158 |
| `ogit.repo.check` | `<?dir>` rc 0/1 — is a repository | `rev-parse --git-dir` (oo:1688) |
| `ogit.repo.root.get` | `<?dir:$PWD>` → toplevel path | `rev-parse --show-toplevel` ×27 (hiveMind, scrumMaster, context, claudeCode) |
| `ogit.repo.share` | `<?dir>` mutator: `core.sharedRepository group`, setgid + `g+w` on `.git` | oo:2144-2151 (per folder from Phase 2) |
| `ogit.repo.grep` | `<pattern> <?dir> <pathspecs…>` | `git grep -nE` in this:246, path:54, test.suite:1310 |
| `ogit.repo.files.list` | `<?dir>` | `ls-files` (test.suite:1269) |

**branch**
| `ogit.branch.get` | `<?dir>` current branch, sanitised (moves from `this.git.branch.short`, this:903) | 10 callers via alias + `branch --show-current` ×14 |
| `ogit.branch.list` | `<?source:local\|remote\|all> <?dir>` (`remote` = cached `origin/*` refs, offline) | oo:673, 683, 792, 1260, otest:409 |
| `ogit.branch.check` | `<ref> <?dir>` rc — exists | oo:1668-1669 |
| `ogit.branch.find` | `<commit> <?dir>` branches containing | oo:1364 |
| `ogit.branch.checkout` | `<ref> <?dir>` | ×13 |
| `ogit.branch.reset` | `<branch> <startPoint> <?dir>` (`checkout -B`) | oo:1670 |
| `ogit.branch.compare` | `<from> <to> <?dir>` → the alignment verdict (moves from `promote.branch.alignment`, promote:277) | promote alias |
| `ogit.branch.merge` | `<ref> <?asEmail> <?asName> <?dir>` (`--no-edit`; identity flags only when given) | promote:770, 939; otest:124 |
| `ogit.branch.fastForward` | `<ref> <?dir>` rc 1 when diverged | promote (Phase 2 merge-in-folder) |

**merge / conflict**
| `ogit.merge.abort` | `<?dir>` | promote:785, 955 |
| `ogit.merge.base.get` | `<a> <b> <?dir>` | oo:1403 |
| `ogit.conflict.list` | `<?dir>` (`--diff-filter=U`) | promote:709 |
| `ogit.conflict.resolve` | `<file> <?side:theirs> <?dir>` | promote:725 |

**remote**
| `ogit.remote.url.get` | `<?remote:origin> <?dir>` | oo:1203, ossh:1187, promote:682 |
| `ogit.remote.url.set` | `<url> <?remote:origin> <?dir>` | `private.oo.shared.tree.from.local` (Phase 2) |
| `ogit.remote.branch.list` | `<?remote:origin> <?dir>` (`ls-remote --heads`, network) | oo:1256 |
| `ogit.remote.fetch` | `<?dir> <?prune:no>` | ×5 |
| `ogit.remote.pull` | `<?dir> <?url> <?branch>` (url+branch = `oo.update`'s HTTPS fallback) | ×5 |
| `ogit.remote.push` | `<?branch> <?tags:no> <?dir>` | ×4, promote:829, 1024 |

**index / commit**
| `ogit.index.add` | `<?scope:all\|updated> <?dir> <paths…>` | ×7, hiveMind:4061 |
| `ogit.commit.create` | `<?message> <?asEmail> <?asName> <?dir>` (interactive when no message) | ×6, promote:649, 731 |
| `ogit.commit.show` | `<ref> <?dir>` | oo:1359 |
| `ogit.commit.count` | `<from> <to> <?dir>` RESULT = count (moves from `this.git.commits.count`, this:921) | promote:293-294 |
| `ogit.commit.log.show` | `<?range> <?limit> <?format> <?dir>` | ×13 (`log -1`, `log --oneline`) |

**status / diff**
| `ogit.status.show` | `<?format:short\|porcelain> <?dir>` | oo:627, 629, 740; promote:489 |
| `ogit.status.check` | `<?dir>` rc 0 when worktree and index are clean | hiveMind:4060, 4128; scrumMaster:645 |
| `ogit.diff.check` | `<?dir> <?paths…>` rc (`--quiet`) | promote:643, 751, 893, 925 |
| `ogit.diff.show` | `<a> <b> <?format:stat> <?dir>` | oo:1408 |

**tag**
| `ogit.tag.list` | `<?pattern> <?dir>` creatordate-sorted | promote:325, 329 |
| `ogit.tag.check` | `<tag> <?dir>` rc — exists | promote:809 |
| `ogit.tag.latest.get` | `<?pattern:v*> <?dir>` version:refname sort | promote:976 |
| `ogit.tag.create` | `<tag> <?ref:HEAD> <?dir>` | promote:814, 1009 |

**stash**
| `ogit.stash.push` | `<message> <?dir>` | ×3 |
| `ogit.stash.pop` | `<?dir>` | ×11 |
| `ogit.stash.top.get` | `<?dir>` message of `stash@{0}` or empty | promote:832, 1027 |

**config / trust**
| `ogit.config.get` | `<key> <?dir>` (global, else local) | — |
| `ogit.config.set` | `<key> <value> <?dir>` | oo:2146 |
| `ogit.config.email.get` | `<?dir>` | ×6 |
| `ogit.safeDirectory.add` | `<path>` (moves from `private.oo.safeDirectory.add`) | ×4 |
| `ogit.safeDirectory.list` | | oo:418, 454 |
| `ogit.safeDirectory.clear` | | oo:421 |
| `ogit.safeDirectory.prune` | (moves from `oo.safeDirectory.prune`) | alias |
| `ogit.safeDirectory.ensure` | `<?base>` one entry per folder under the base | new (§ 4) |

**worktree / layout**
| `ogit.worktree.add` | `<branch> <targetDir> <startPoint> <?dir>` | oo:802, 1191, 1700-1701, 2065 |
| `ogit.worktree.list` | `<?dir>` porcelain | oo:540 |
| `ogit.worktree.find` | `<branch> <?dir>` → folder holding `<branch>`: a linked worktree of `<dir>`'s repo, else the sibling clone `<base>/<branch>` (base = parent of `<dir>` when `main/` is there) | promote:660 |
| `ogit.worktree.delete` | `<path> <?dir>` (`worktree remove`) | `worktree.remove` (Phase 2) |
| `ogit.worktree.prune` | `<?dir>` | `worktree.remove` (Phase 2) |
| `ogit.worktree.remove` / `ogit.worktree.restore` / `ogit.layout.status` | § 2.1 (Phase 2) | new |

**binary / escape hatch**
| `ogit.binary.check` | rc 0/1 — git present (`private.ogit.require` is its logging twin) | ossh:1180, osshLayout:47 |
| `ogit.raw` | `<dir> <args…>` | the documented last resort |

### 3.4 Moves with delegating aliases
`this.git.branch.short`, `this.git.commits.count`, `oo.safeDirectory.prune`,
`private.oo.safeDirectory.add`, `promote.branch.alignment` become one-line aliases that load
`ogit` lazily (`[ "$(type -t ogit.branch.get)" = function ] || source "$OOSH_DIR/ogit"`) and
delegate. The alias stays so anything outside this tree keeps working; their tests move to
`test.ogit` and the alias tests shrink to "delegates".

### 3.5 Porcelain verbs stay where they are
`oo.commit`, `oo.update`, `oo.branch.list`, `oo.mode*`, `oo.checkout`, `oo.use`,
`oo.branches.check`, `promote.*` remain the user-facing verbs; they call `ogit` methods.
`ogit` is plumbing with completion, not a second `oo`.

### 3.6 Sanctioned exceptions (marked `# ogit-exception: <reason>` on the line or just above)
- `init/oosh` (file-wide `# ogit-exception-file:`): POSIX sh, runs before bash and oosh exist.
- `init/once`: legacy `once` framework with its own `once.git.*`; out of scope, file-wide marker.
- `otest:131`: runs inside a docker container that has no oosh.
- `ossh:640`: jump host may not have oosh — raw git guarded by `command -v ogit`.
- Remote strings where the remote **has** oosh call the command form: `hiveMind:1753` →
  `ossh exec $host "~/oosh/ogit remote.pull"`.
- `private.as.user` hops call the command form: `user:1070,1075,1154` →
  `private.as.user "$u" "$sharedOosh/ogit" safeDirectory.add …` (through the as-user preamble).
- `scrumMaster:14` runs git at **source time**; make the default lazy (resolve in the method that
  needs it) rather than sourcing `ogit` at file scope.

---

## 4. Multi-user, permissions and trust (Phase 2)

Per-repository git state is now per folder, so three things done once on `main/.git` today
(oo:2144-2171) are done per folder, by one method each:

- **`ogit repo.share <dir>`** — `core.sharedRepository group`, setgid on every directory under
  `.git`, `g+w`. Called by state 31 for each folder it creates, by `worktree.remove/restore`,
  by `oo checkout` and by `oo mode`'s folder creation.
- **`ogit safeDirectory.ensure <?base>`** — for the *calling* user, one `safe.directory` entry per
  folder under the base (idempotent, honours `GIT_CONFIG_GLOBAL`). Called from
  `config.init.user` (so `oo update` / `oo user.fix` heal it) and from `user.oosh.install` as
  the new user. `oo mode.list` stays entry-free (T-MODE-NOLEAK).
- **Ownership.** Folders cloned by root during install → `chown -R developking:dev` like the
  tree. Folders cloned later by a dev-group user (`oo checkout`, `oo mode <new>`) are owned by
  that user, group `dev` (setgid inherited from the base). Only `worktree.remove`/`restore` need
  `sudo`.
- **Independence.** Each user pulls the folder they are on; no `oo update` or `promote`
  changes another user's checked-out tree. `testing/` and `prod/` are as fresh as their last
  pull: `promote` pulls them before merging, `ogit layout.status` shows `behind N`.
- Single-user hosts run the same code with a one-member `dev` group.

---

## 5. Caller changes in Phase 2 — and the 09-22 objections answered

| Caller | Change | 09-22 objection it answers |
|---|---|---|
| **State 31** `private.check.root.shared.dev.folder.created` (oo:2021-2073, 2144-2171) | `ogit repo.clone` for the install branch instead of `worktree add`; `ogit repo.share` + `safeDirectory.add` **per folder**. Fix lives in the state; no `finish.local` fixups. | "state 31 sets sharedRepository on main/.git only" |
| **`private.oo.shared.tree.from.local`** (oo:1660-1705) | copy local checkout → `<base>/main`, `ogit repo.clone` the branch folder from it, re-point `origin` to GitHub. | — |
| **`oo mode <missing>`** (oo:792-802), **`oo checkout`** (oo:1189-1239) | always the clone path, under the detected base (today's clone fallback clones into `$HOME`, the wrong place). | "base detection dies" — it doesn't: strategy 4 + `main/` |
| **`oo update`** (oo:270-311) | unchanged scope (pulls `~/oosh`); adds `ogit safeDirectory.ensure`. | "single-fetch model" — accepted: one pull per folder, visible in `layout.status` |
| **`oo branch.list` / `mode.list`** | folder scan (already accepts `.git` dirs) + `ogit branch.list remote`. | — |
| **`promote`** (promote:740-966) | merge **in the target's own folder**: push source → `ogit remote.fetch` in `<base>/<target>` → fast-forward target to `origin/<target>` → `ogit branch.merge origin/<source> <asEmail> <asName>` → tag → `ogit remote.push <target> yes`. `find.worktree` → `ogit worktree.find`. Same shape for both stages (removes today's asymmetry). Absent target folder → refuse, name `oo checkout <target>`. Per-folder stash (no shared stack collisions). | "promote assumes one repo holds all refs" — it fetches now |
| **`ogit worktree.remove`** on existing hosts | user-run, `sudo`, never automatic. Fresh installs produce clones directly. | — |

---

## 6. Testing, docs, rollout

**Phase 1 tests**
- `test/test.ogit` (`oo test.new ogit`, `TEST_CATEGORY=core`): one behavioural case per method on
  a `test.suite.fixture.make` repo + bare origin (shape of test.promote:595-622); red first.
- `T-OGIT-ONLY-CALLER` (in `test.ogit`): `git grep` the tracked tree for raw `git` invocations
  outside `ogit`, `init/oosh`, `init/once`, `test/`, `old/`, `restore/`, `docs/`, `*.md`,
  `.github/`, and lines carrying `# ogit-exception:`; must be empty. Planted-violation twin so
  the sweep is proven to fail (style of `test.this` T-OOSH-DIR-VALIDATE-REJECTS).
- Re-aimed grep-pins (not deleted): `test.oo:2179-2184` (`ls-remote`/`for-each-ref` → the
  `ogit` names), `test.ossh:720-735` (branch.short strips → tested in `test.ogit`),
  `test.ossh:738-748` (T-BRANCH-SHORT-CALLER → callers use `ogit.branch.get` or the alias),
  `test.promote:494-499` (`checkout dev` still matches `ogit.branch.checkout dev`),
  `test.oo:1947-1956` (negative pins re-aimed at `ogit.remote.pull`/`ogit.branch.merge`).
- Gate: host `./test.suite core 1`; `os platform.test ubuntu_24_04` once (oo/promote/user changed).

**Phase 2 tests**
- `T-OGIT-WORKTREE-REMOVE` / `-RESTORE` on a fixture base (`main` + two worktrees; dirty and
  unpushed variants refuse and name the folder; clean ones convert; second run no-op; both
  directions round-trip byte-for-byte on tracked content).
- `T-OGIT-LAYOUT-STATUS` (mixed layout reported, rc 1).
- Rewrite the worktree-fixture tests in `test.oo` to the clone shape: T-SETUP-4 (1449-1501),
  T-BASE-GET-WORKTREE (1508-1540), T-SHARED-TREE-FROM-LOCAL-* (2192-2229),
  T-SHARED-TREE-CONSUME-* (2298-2416), T-MODE-COMPLETION-WORKTREE (316-358),
  T-MODE-COMPLETION-LAZY-USERENV-* (485-663).
- `test.promote`: fixture with a sibling target folder; assert merge lands in the target folder
  and the absent-folder refusal.
- New platform invariant `test.platform.shared.layout.invariant` (from
  `templates/code/newPlatformInvariantTest`): every folder under the base is a clone with
  `sharedRepository=group`, setgid `.git`, and a `safe.directory` entry for the caller.
- Gate: host core → all three platform installs (install path changed) → `sudo ogit
  worktree.remove` on this box → `env -i … bash -l`, `oo mode prod` / `oo mode dev`,
  `promote status`, `ogit layout.status` → `sudo ogit worktree.restore` once to prove the
  round-trip, then `remove` again.

**Docs**
- `docs/ogit.md` shaped like `docs/odocker.md`; wiki-index bullet `- [Git Wrapper (ogit)](ogit.md)`.
- `docs/oo.md` § *The worktree layout* → the clone contract; `docs/branching.md`,
  `docs/promote.md` for the fetch-then-merge-in-folder flow; `docs/repair-toolkit.md` rows for
  `ogit layout.status` / `ogit safeDirectory.ensure`; CLAUDE.md wrapper table gains `ogit`;
  the 09-22 research doc gets a superseded note pointing here;
  `docs/oosh-architecture.md` § Key Scripts gains `ogit`.

**Rollout**
1. Phase 1 lands and is pushed; behaviour identical; core green.
2. Phase 2 lands; fresh installs produce clones.
3. Existing hosts (this box, macstudio, tart VM) migrate by hand: `sudo ogit worktree.remove`.
4. Reversal at any point: `sudo ogit worktree.restore`; Phase 1 alone is a plain revert.

---

## 7. Invariants every change must keep
- `OOSH_DIR` = `~/oosh`, `CONFIG_PATH` = `~/config` literals; `this.anchor.validate` and
  `path validate` green.
- `~/config` branch-independent; only `~/oosh` is branch-specific.
- A sibling folder named `main` with a `.git` directory exists under the base (base detection,
  ooShim).
- No raw `git` outside `ogit` except the marked exceptions (§ 3.6).
- Install fixes live in the failing state; nothing in `finish.local`.
- No automatic layout conversion; no automatic promotion to testing/prod.
