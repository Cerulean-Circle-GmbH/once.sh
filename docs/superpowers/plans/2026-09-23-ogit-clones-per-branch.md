# `ogit` + clone-per-branch layout — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `ogit`, the odocker-style git wrapper that becomes the only caller of the `git` binary in the oosh tree, then use it to replace the git-worktree layout under `…/Once.sh/` with one independent clone per branch folder — reversibly.

**Architecture:** Two phases, two pushes. Phase 1 is a pure refactor: `ogit` (15 nouns, `ogit.<noun>.<verb>`, `<?dir:$OOSH_DIR>` last) plus every raw `git` call in bash-mode scripts moved behind it, guarded by a production tree validator (`ogit caller.validate`); behaviour and the worktree layout stay identical. Phase 2 changes behaviour: `ogit worktree.remove/restore/layout.status`, state 31 clones per folder with per-folder permissions and trust, `oo mode`/`oo checkout` always clone, `promote` merges in the target's own folder.

**Tech Stack:** bash 4+ (macOS bash 3.2 must still parse), OOSH kernel (`this`, `log`, `test.suite`, `oo method.new`), git ≥ 2.28 (the floor is `git init -b`, used by the fixtures; `worktree`, `--show-current`, `get-url`, `--absolute-git-dir` are all older), draw.io for the tree diagram.

**Spec:** `docs/superpowers/specs/2026-09-23-ogit-clones-per-branch-design.md` (read it first; this plan implements it section by section). Method tree: `docs/puml/ogit.tree/ogit.tree.drawio`.

---

## 0. Methodology first

The contract for every edit in this plan: **100 % OOSH philosophy and methodology, template-conformant, oosh commands before bash — and missing oosh commands are created first** (Task M, before Task 1). Audited against `docs/oosh-architecture.md`, `docs/oo.md`, `docs/test-suite.md`, `docs/state.md`, `docs/log.md`, `templates/code/*` and the live tree at 9b69114. Line references below are to that tree (`this`/`oo`/`promote` unchanged since 8c46828).

### 0.1 Which oosh command performs each class of edit

| Class of edit | oosh command / template | Standard (citation) |
|---|---|---|
| New script + its test file | `oo new ogit` (templates `newScript` + `newScriptTest`; creates **both** — no `oo test.new` needed) | oo.md § oo.new; oo:20-40 |
| Every new method, public or private (ogit, `this`, oo, promote, config, user) | `printf '%s\n' <params> <desc> <testDesc> <testArgs> <expected> \| LOG_LEVEL=1 ./oo method.new <script.noun.verb>` — inserts at `### new.method`, stub test at `### test.method`, completion stubs per param | oo.md § oo.method.new; oo:66-218 |
| Completion stubs | the stubs `method.new` generates are **replaced**, never duplicated; shared candidates live in `ogit.parameter.completion.<param>` (c2 falls back to it, ng/c2:483,518) — no per-method wrapper that only forwards | oosh-architecture.md § Method Structure 189-195; test/test.completion.audit |
| Replacing a whole existing method body (aliases in `this`, `oo`, `promote`) | `replace block <file> "<signature line>" "}" by "<new body>"` → `replace commit` → `replace cleanup` | replace:8, 44, 213 |
| Removing a moved method | `oo method.delete <script.method>` (then remove its reported tests) | oo.md § oo.method.delete; oo:3032 |
| Single call-site rewrites (≈220, each different) | Edit tool, one file per commit; not a repeated structural edit, so no bulk command is warranted | memory rule 8 applies to *identical* edits only |
| Group-write on a tree | `private.ensure.sharedTree <dir>` (chgrp dev + g+w, `$SUDO` only when not owner) | this:420-466 |
| Group existence | `private.this.group.exists dev` | this:181 |
| Canonical paths | `private.this.path.canonical <path>` (never `cd && pwd -P`, never `readlink -f`) | this:200; test-suite.md § portability |
| Running as another user | `private.as.user <u> bash -c "$(private.this.as.user.preamble.get <u> "$(user.get home <u>)" <sharedOosh>)"$'\n'"<cmd>"` | user:927, this:1098, user:526 |
| Fixture dirs / config isolation in tests | `test.suite.fixture.make <label>`; `test.suite.config.isolate` where a script can persist | test.suite:841, 871 |
| Git binary missing | `oo cmd git` (named in the error) | oo:2590 |
| Status/answer output | plain `echo` for getters and `.status` answers; `success.log`/`important.log` for mutator progress; `create.result` + `error.log "$RESULT"` on failure | log.md 418-432; memory `feedback_status_command_output_idiom` |
| Install behaviour | only inside `private.check.root.shared.dev.folder.created` (state 31) with its `[n/5: …]` step labels and `create.result 1 "state 31 step n/5 failed: …"` | state.md; oo:1819-2350; memory `feedback_state_machine_owns_install` |
| Tree sweeps | production validator in the shape of `path.validate` / `private.this.anchor.validate.one` / `test.suite.portability.validate` (one `git grep`, OK:/INVALID: verdict, comment-anchored markers, 5-line window, `-exception-file:` anchored) | path:8-129; this:227-314; test.suite:1227-1400 |
| Docs pages | follow `docs/odocker.md` / `docs/oo.md` shape; register in `docs/wiki-index.md` Infrastructure Tools, `CLAUDE.md` wrapper table, `docs/repair-toolkit.md` tables | wiki-index.md 34-41; repair-toolkit.md 14-25, 74-95 |

### 0.2 What was searched for and REJECTED (with reason)

| Candidate | Why rejected |
|---|---|
| `this.load <fn> <script>` as the ogit loader | It *calls* the method, overwrites `This`, and returns `result save` — dispatch machinery, not a source-once loader (this:551-578) |
| `line.count` / `line.select` / `line.find` inside ogit getters | Getters run in c2 completion subshells where `line` may not be loaded; recent kernel validators (path, this, test.suite) use raw `grep`/`sed -n` for the same reason. `line.count` also counts blank lines (different semantics) |
| `private.oo.cmd.verify` for "git present" | private to `oo`; ogit keeps one local check (`ogit.binary.check`, Task 11), and `private.ogit.require` is its fail-loud twin |
| `check user X exists … call` DSL | ends in `exit`; wrong shape inside a method (check:203) |
| `chown -R developking:dev` (the first draft of Task 20) | policy is chgrp dev + g+w + setgid, **not** recursive chown — pinned by `T-STATE-31-CHOWN-NOT-RECURSIVE` (test/test.install:406-412) |
| `tar` for carrying ignored files | no tar anywhere in the tree by design (user:1464-1466); the sanctioned shape is a timestamped **directory** copy as in `user ssh.backup` |
| test-only sweep `test.ogit.rawGitCalls` (the first draft of Task 13) | duplicates the validator family and drops its safeguards (see 0.4-1) |
| `oo mode.base.get` subprocess as default base | spawns a whole `oo`; use `oo.mode.base.get` when `type -t` finds it, else the command |
| A docs-page generator | one page; follows the existing pattern; not a repeated edit |

### 0.3 Missing oosh commands — created FIRST (Task M, before Task 1)

Each via `oo method.new`, with docstring, completion (public only) and a `test.suite` case.

| New method | Script | Replaces | Used by |
|---|---|---|---|
| `private.this.script.load <script> <probeFn>` | `this` | a script-specific ogit loader (and, later, the 11 inline `type -t … \|\| source` copies — follow-up ticket, not this plan). Saves/restores `This` around the source (sourcing re-runs `this.start`, this:1263) | every consumer of `ogit.*`: first line of the method is `private.this.script.load ogit ogit.branch.get` |
| `private.this.path.case.get <path>` | `this` | the 3 hand-copies of the `osascript POSIX path` case-canonicalisation (oo:2154, oo:2168, user:1071); echoes input unchanged without osascript | state 31 trust loop (Task 22), user.oosh.install hop (Tasks 17, 23) |
| `oo test.platform.new <scope> <aspect>` | `oo` | copying `templates/code/newPlatformInvariantTest` by hand (no generator exists) | Task 25 `test.platform.shared.layout.invariant` |
| add `ogit` to `IN_SCOPE_SCRIPTS` | `test/test.completion.audit:39-41` | — (as written the audit never checks ogit) | every ogit Task |

ogit-internal helpers (created in the Task that first needs them, via `oo method.new`):

| Helper | Task | Replaces |
|---|---|---|
| `ogit.branch.upstream.set <ref> <?dir>` | 4 | raw `git branch -u` inside ogit, and the gate message that told users to type it |
| `<?scope:any>` on `ogit.config.get` (`any` = global then repo, `local` = repo only) | 10 | the raw `git config --get core.sharedRepository` in `layout.status` |
| `private.ogit.base.folders.list <base>` (skips symlinks, dot-dirs, non-repos — like oo:1093-1122) | 10 | 4 hand loops: `safeDirectory.ensure`, `layout.status`, `worktree.restore`, the state 31 loop |
| `private.ogit.base.get <?base>` (the 0.4-11 default-base idiom, once) | 10 | 4 copies of `base=$(oo mode.base.get)` in `safeDirectory.ensure`, `layout.status`, `worktree.remove`, `worktree.restore` |
| `private.ogit.worktree.paths.get <?dir>` (space-safe porcelain parse) | 11 | 3 `awk '{print $2}'` copies in `worktree.find` / `worktree.remove` |
| `ogit.caller.validate <?treeRoot:$OOSH_DIR>` | 13 | the test-only sweep — now a production validator in the `path.validate` shape |
| `private.ogit.folder.ignored.save <folder> <stashDir>` / `private.ogit.folder.ignored.restore <stashDir> <folder>` | 20 | nothing — gitignored files would otherwise be lost by the conversion (spec § 2.1) |

### 0.4 Conformance fixes applied to the snippets below

1. **Sweep → `ogit.caller.validate`** (Task 13) in the validator shape: comment-anchored `# ogit-exception:` on the line or the 5 lines above; `^[[:space:]]*#[[:space:]]*ogit-exception-file:`; exclusions `':!ogit' ':!docs' ':!test' ':!.claude' ':!old' ':!restore' ':!*.md' ':!*.json'`; no unanchored `echo |printf |\.log` filter (it let `x=$(git …); echo` through); the empty-`files.list` guard (test.suite:1261-1274) so dubious ownership cannot make it pass silently. The tests call it on `$OOSH_DIR` and on a planted fixture.
2. **Completion**: no per-method wrapper that only forwards; the shared block `ogit.parameter.completion.{dir,targetDir,path,base,startPoint,commit,branch,ref,tag,remote}` (+ `to,a,b,range,paths,pathspecs,asEmail,treeRoot`) serves every method; only method-specific enumerations stay per method (`source`, `format`, `scope`, `side`, `tags`, `prune`, `pattern`, `key`, `file`); no `completion.message() { :; }` (message is exempt). Free params that cannot be completed (`limit`, `asName`) go into `EXEMPT_PARAMS` with a reason (Task M). `./test.suite run completion.audit 1` is in every ogit Task's Run step.
3. `private.ogit.dir` subshell → inline `local dir="${n:-${OOSH_DIR:-.}}"` (this:905 idiom) in every body.
4. `ogit.repo.share` → `private.ensure.sharedTree "$gitDir"` (chgrp dev + g+w) + the setgid `find` (the one piece with no helper — `sharedTree` deliberately sets no SGID) + `core.sharedRepository` via git.
5. `private.ogit.folder.finish` → gate on `private.this.group.exists dev`, `ogit.repo.share`, no recursive chown; SUDO_USER trust via the preamble hop (0.1).
6. State 31 replacement keeps the `[5/5: …]` labels and `create.result 1 "state 31 step 5/5 failed: …"`; drops the old `cd main … cd ..`.
7. `private.oo.shared.tree.from.local` clone keeps the `origin/$branch` fallback (`ogit.branch.check "$branch" main || ogit.branch.reset "$branch" "origin/$branch" main`, then `ogit.branch.checkout main main`) before cloning from `main/`; osascript idiom → `private.this.path.case.get`.
8. Mutator progress lines in `worktree.remove/restore` → `success.log`; final verdict via `create.result`.
9. Tests: `local GIT_CONFIG_GLOBAL=…; export GIT_CONFIG_GLOBAL` (restored on return) instead of export/unset; same for `OOSH_COMPONENTS_DIR`/`OOSH_DIR` in test.promote; no redundant `cd && pwd -P` (fixture paths are canonical).
10. Docstring form is the generator's `# <p> # d #` inside ogit.
11. `cd … && pwd -P` in bodies → `private.this.path.canonical`; `oo mode.base.get` subprocess defaults → `{ [ "$(type -t oo.mode.base.get)" = function ] && oo.mode.base.get; } || oo mode.base.get`.

Correctness defects of the first draft, fixed in the snippets: `local` lines whose trailing word made them commands (`remote.pull`, `commit.count`, `remote.fetch`, `remote.push`); `repo.clone` deleting a pre-existing folder on failure; `index.add all` with no dir staging a file named `all`; the Task 7 test case redefining the Task 2 fixture helper `test.ogit.commit`; the undated fixture seed breaking the tag-date sort; `branch.compare` a `:` stub with a test that could not fail; `<?dir>` not last in `remote.fetch`/`remote.pull`; the git floor (2.28, not 2.20); two missing sites (`myId`, `Install oosh.command`, Task 17).

---

## 0.5 Orientation for the implementing agent (read before Task M)

**Where you are.** `/home/shared/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/Once.sh/dev` is a git **worktree** of `../main`, on branch `dev`; `~/oosh` is a symlink to it (`readlink -f ~/oosh`). Run everything from there. Read `CLAUDE.md`, `docs/oosh-architecture.md` (§ Naming Standard, § Method Structure Standard, § The anchors are data), `docs/oo.md` (§ oo.method.new, § The worktree layout), `docs/test-suite.md`, `docs/odocker.md` (the model for `docs/ogit.md`).

**House rules that this plan relies on (all enforced by existing tests):**
1. Every method is `script.noun.verb()` with a docstring `# <params> # description #` on the signature line; camelCase, dots, no underscores, no dashes. Optional params `<?name:default>`. Public methods get `script.method.completion.<param>()`; private (`private.script.*`) do not.
2. **Create methods with `oo method.new`, never by hand.** It is interactive (five `read` prompts) and pipe-drivable:
   ```bash
   printf '%s\n' '<url> <branch> <targetDir>' 'clone <url> at <branch> into <targetDir>' \
     'T-OGIT-REPO-CLONE: clones a branch into a fresh dir' 'x y z' 'cloned' \
     | LOG_LEVEL=1 ./oo method.new ogit.repo.clone
   ```
   It inserts the method above `### new.method` in `ogit` and a stub test above `### test.method` in `test/test.ogit`. Replace the stub body/test with the code in this plan (the template body is a placeholder). The template indents with ONE space; keep it.
3. **Getters answer on stdout and never call `create.result`** (they are consumed as `$(...)` and by tab completion; `create.result` inside a completion path breaks c2). Mutators `create.result N "msg"` then `return $(result)`.
4. **Red first.** Write the test, run it, watch it fail for the right reason, then implement. Run tests in the existing tmux pane: `tmux send-keys -t oosh:1.1 'clear; ./test.suite run ogit 1' Enter`, then `tmux capture-pane -t oosh:1.1 -p`. Never pipe oosh test output through `| tail` / `2>&1`.
5. Validators that must stay green after every task: `LOG_LEVEL=1 ./path validate`, `LOG_LEVEL=1 ./this anchor.validate all`, `LOG_LEVEL=1 ./config validate user`, `LOG_LEVEL=1 ./test.suite portability.validate`, and — from Task 17 on, when it turns green — `LOG_LEVEL=1 ./ogit caller.validate` (Task 13 creates it RED on purpose). Full gate: `./test.suite core 1` (not `all`).
6. Commit per task, message `type(scope): what — why`, ending with the attribution line the session gives you. Do not push until the plan says so. No promotion to testing/prod.
7. Install fixes go INTO the failing state machine state (`private.check.<state>` in `oo`), never into `ossh.install.finish.local`.
8. `GIT_CONFIG_GLOBAL` must be honoured by anything that touches `--global` (tests sandbox with it).
9. Sourcing: `source this` inside a script's `start()` is the pattern; `this.start` returns immediately when the script is being sourced (`this.isSourced`), so `source ogit` from another script defines the functions and runs nothing. Verify once in Task 1.
10. Reserved dispatch words (no method may be named): `start`, `help*`, `restart`, `localInstall`.
11. Positional optional parameters are skipped with an empty string: `ogit remote.push "" no "$dir"`.
12. **Loading ogit from another script:** the first line of every method that calls `ogit.*` is `private.this.script.load ogit ogit.branch.get` (Task M; a `type -t` check — cheap). No per-script loader copies, no file-scope `source ogit` (file scope runs before `source this` has put the tree on PATH). Inside `ogit` itself the same loader brings in `user` where a body needs `private.as.user` / `user.get`. The loader sources `"$OOSH_DIR/<script>"`, so a test that re-points `OOSH_DIR` at a fixture calls it **before** doing so.
13. **Completion:** shared candidates live in `ogit.parameter.completion.<param>` (Task 3); a method carries its own `ogit.<method>.completion.<param>` only for an enumeration specific to it. Every ogit Task's Run step includes `./test.suite run completion.audit 1` (ogit is in its scope since Task M). A new non-exempt parameter gets a completer or goes into `EXEMPT_PARAMS` with its reason.

**Phase gates.** Phase 1 ends with core green + `os platform.test ubuntu_24_04` + push. Phase 2 ends with core green + all three platform installs + the manual migration of this host.

---

## 1. File structure

| File | Responsibility | Phase |
|---|---|---|
| `ogit` (new, from `oo new ogit`) | the only git caller: 15 nouns, § 3.3 of the spec; completers; `ogit.usage`; `ogit.start` | 1 (+ layout methods in 2) |
| `test/test.ogit` (new, created together with `ogit` by `oo new ogit`) | fixture helpers, one case per method, `T-OGIT-ONLY-CALLER` (calls `ogit.caller.validate`) + its planted-violation twin | 1, 2 |
| `this` | Task M: `private.this.script.load`, `private.this.path.case.get`; `this.git.branch.short` / `this.git.commits.count` become delegating aliases via `private.this.script.load ogit ogit.branch.get`; `private.this.anchor.validate.one` uses `ogit.repo.grep` | 1 |
| `oo` | Task M: `oo.test.platform.new`; safeDirectory methods become aliases; all raw git → ogit; Phase 2: state 31, `shared.tree.from.local`, `oo.mode`, `oo.checkout`, `oo.update` | 1, 2 |
| `test/test.completion.audit` | Task M: `ogit` in `IN_SCOPE_SCRIPTS`; `limit`, `asName` exempt with reason | 1 |
| `promote` | all raw git → ogit; `promote.branch.alignment` alias; Phase 2: merge in target folder | 1, 2 |
| `config`, `user`, `ossh`, `osshLayout`, `os`, `path`, `test.suite`, `claudeCode`, `hiveMind`, `scrumMaster`, `context`, `agentRoom`, `snet`, `otest`, `myId`, `Install oosh.command` | raw git → ogit (function form, or command form in hops/remote strings); exception markers | 1 |
| `test/test.oo`, `test/test.ossh`, `test/test.promote`, `test/test.this` | re-aimed grep-pins (1); worktree fixtures rewritten to clones (2) | 1, 2 |
| `test/test.platform.shared.layout.invariant` (new, generated by `oo test.platform.new shared layout`) | real-host clone-layout invariant | 2 |
| `docs/ogit.md` (new), `docs/wiki-index.md`, `CLAUDE.md`, `docs/oo.md`, `docs/branching.md`, `docs/promote.md`, `docs/repair-toolkit.md`, `docs/oosh-architecture.md`, `docs/research/2026-09-22-worktrees-vs-version-convention.md` | docs | 1, 2 |

---

## Batches and stop points

**Stop after every batch** and wait for the user's go. Pushes and platform tests always wait for the user — **ask before every push**. `sessions/agent.context.md` is updated at every batch end. No promotion to testing/prod.

| Batch | Content | Gate |
|---|---|---|
| 0 | This plan doc (+ spec § 2.1 ignored-files line) patched with § 0 | user reviews the patched plan |
| M | Task M: `private.this.script.load`, `private.this.path.case.get`, `oo test.platform.new`, completion-audit scope | this / oo / completion.audit suites |
| 1 | Tasks 1-2: `oo new ogit`, header/helpers/usage, sourced guard, fixtures | ogit suite |
| 2 | Tasks 3-11: the 15 nouns (+ the ogit helpers of § 0.3), one commit per Task | ogit, oo, completion.audit |
| 3 | Tasks 12-13: aliases via `replace block`; `ogit.caller.validate` RED ≈260 | `T-OGIT-ONLY-CALLER-REJECTS` green |
| 4 | Tasks 14-17: call-site migration file by file (+ `myId`, `Install oosh.command`) | each suite; `ogit caller.validate` OK |
| 5 | Task 18: docs/ogit.md, wiki, CLAUDE.md, architecture; `./test.suite core 1` | **ask before push**; then `os platform.test ubuntu_24_04` |
| 6 | Tasks 19-21: layout.status, worktree.remove/restore with the ignored-file carry | ogit suite |
| 7 | Tasks 22-23: state 31 + shared.tree.from.local clone; oo mode/checkout clone; trust ensure | oo / config / user / install suites |
| 8 | Task 24: promote merges in the target folder | promote suite |
| 9 | Task 25: invariant test via `oo test.platform.new`, docs, core gate | **ask before push**; ubuntu, alpine, tart macOS |
| 10 | Host migration — **user-run** runbook (Task 25) | user executes |

---

# PHASE 1 — `ogit` becomes the only git caller (behaviour identical)

### Task M: Missing oosh commands first

**Files:** `this`, `test/test.this`, `oo`, `test/test.oo`, `test/test.completion.audit`

Every later Task calls these (§ 0.3), so they exist before `ogit` does. Each method is created with the pipe-driven `oo method.new` (rule 2 of § 0.5), then its stub body and stub test are replaced with the code below. Red first, as everywhere.

- [x] **Step 1: `private.this.script.load` — scaffold**

```bash
cd ~/oosh && printf '%s\n' '<script> <probeFn>' \
  'source $OOSH_DIR/<script> into this shell once, unless <probeFn> is already a function; This is saved and restored around the source; rc 0 when <probeFn> is a function afterwards' \
  'T-THIS-SCRIPT-LOAD: sources a script once and keeps This' 'ogit ogit.branch.get' '' \
  | LOG_LEVEL=1 ./oo method.new private.this.script.load
```
(Private: no completion stubs are generated, by design.)

- [x] **Step 2: Test (RED)** — replace the stub case in `test/test.this`:

```bash
test.this.scriptLoad() {
  local fx bad="" savedThis="$This"; fx=$(test.suite.fixture.make scriptload)
  # The fixture script clobbers This at file scope, as this.start does when a real script is sourced.
  printf '%s\n' 'This=clobbered' 'fx.probe() { echo probed; }' > "$fx/fxScript"
  local OOSH_DIR="$fx"
  private.this.script.load fxScript fx.probe || bad="$bad rc=$?"
  [ "$(type -t fx.probe)" = function ] || bad="$bad not-loaded"
  [ "$This" = "$savedThis" ] || bad="$bad This-clobbered=[$This]"
  printf '%s\n' 'fx.probe() { echo reloaded; }' > "$fx/fxScript"
  private.this.script.load fxScript fx.probe || bad="$bad second-rc=$?"
  [ "$(fx.probe)" = probed ] || bad="$bad sourced-twice"
  private.this.script.load nosuch nosuch.probe && bad="$bad missing-script-passed"
  unset -f fx.probe; rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "script.load sources once, keeps This, rc 1 when the probe stays undefined" || create.result 1 "script.load:$bad"
  return $(result)
}
test.case $level "T-THIS-SCRIPT-LOAD: private.this.script.load sources a script once and keeps This" test.this.scriptLoad
expect 0 "script.load sources once, keeps This, rc 1 when the probe stays undefined" "the one lazy loader every ogit consumer uses"
```
Run `./test.suite run this 1` → FAIL (stub).

- [x] **Step 3: Implement** in `this` (a predicate: rc only, no `create.result` — it runs inside completion paths too):

```bash
private.this.script.load() # <script> <probeFn> # source $OOSH_DIR/<script> into this shell once, unless <probeFn> is already a function; This is saved and restored around the source; rc 0 when <probeFn> is a function afterwards #
{
 # Lazy, because <script> sources `this` and every consumer (oo, promote, …)
 # may itself be merely sourced by the ooShim or a test. Not this.load: that
 # one CALLS the method and overwrites This (this:551-578). Sourcing re-runs
 # this.start (this:1263), which points This at the sourced file — restore it,
 # or the caller's own dispatch/help would describe the wrong script.
 [ "$(type -t "$2")" = function ] && return 0
 local savedThis="$This"
 source "$OOSH_DIR/$1" >/dev/null 2>&1
 This="$savedThis"
 [ "$(type -t "$2")" = function ]
}
```
Run → PASS. **Commit** `feat(this): private.this.script.load — one lazy source-once loader that keeps This`.

- [x] **Step 4: `private.this.path.case.get` — scaffold, test (RED), implement**

```bash
printf '%s\n' '<path>' \
  'echo <path> in the file system canonical letter case (macOS: osascript POSIX path, trailing / dropped); echo <path> unchanged when osascript is absent or fails' \
  'T-THIS-PATH-CASE-GET: without osascript the input comes back unchanged' '/Some/Mixed/Case' '' \
  | LOG_LEVEL=1 ./oo method.new private.this.path.case.get
```
Test (replace the stub case in `test/test.this`):

```bash
test.this.pathCaseGet() {
  local bad="" out
  # No osascript on PATH (Linux always; macOS with PATH emptied) → the input, verbatim.
  out=$(PATH=/nonexistent private.this.path.case.get "/Some/Mixed Case/dir")
  [ "$out" = "/Some/Mixed Case/dir" ] || bad="$bad no-osascript=[$out]"
  private.this.path.case.get "" >/dev/null && bad="$bad empty-passed"
  case "$OSTYPE" in
    darwin*) out=$(private.this.path.case.get /users); [ "$out" = /Users ] || bad="$bad darwin-case=[$out]" ;;
  esac
  [ -z "$bad" ] && create.result 0 "path.case.get: input unchanged without osascript; canonical case on macOS" || create.result 1 "path.case.get:$bad"
  return $(result)
}
test.case $level "T-THIS-PATH-CASE-GET: private.this.path.case.get echoes the input without osascript" test.this.pathCaseGet
expect 0 "path.case.get: input unchanged without osascript; canonical case on macOS" "safe.directory is a string match on a case-insensitive FS"
```
Implement in `this`, next to `private.this.path.canonical` (a getter — no `create.result`):

```bash
private.this.path.case.get() # <path> # echo <path> in the file system canonical letter case (macOS: osascript POSIX path, trailing / dropped); echo <path> unchanged when osascript is absent or fails #
{
 # macOS HFS+/APFS is case-insensitive, but git's safe.directory is a string
 # match: /Users/shared and /Users/Shared are one inode, two strings. Moved
 # from the three hand-copies at oo:2154, oo:2168 and user:1071 (their call
 # sites move in Tasks 17, 22 and 23).
 local p="$1" r=""
 [ -z "$p" ] && return 1
 if command -v osascript >/dev/null 2>&1; then
   r=$(osascript -e "POSIX path of (POSIX file \"$p\" as alias)" 2>/dev/null | sed 's:/$::')
 fi
 printf '%s\n' "${r:-$p}"
}
```
Run `./test.suite run this 1` → PASS. **Commit** `feat(this): private.this.path.case.get — the macOS canonical-case idiom, once`.

- [x] **Step 5: `oo test.platform.new` — scaffold, test (RED), implement**

```bash
printf '%s\n' '<scope> <aspect>' \
  'generate test/test.platform.<scope>.<aspect>.invariant from templates/code/newPlatformInvariantTest; refuses an existing file' \
  'T-OO-TEST-PLATFORM-NEW: generates a platform invariant test from the template' 'fx layout' 'created test/test.platform.fx.layout.invariant' \
  | LOG_LEVEL=1 ./oo method.new oo.test.platform.new
```
Test (replace the stub case in `test/test.oo`) — in a fixture tree, never in the real `test/`:

```bash
test.oo.testPlatformNew() {
  local fx bad="" t; fx=$(test.suite.fixture.make platformnew)
  mkdir -p "$fx/templates/code" "$fx/test"
  cp "$OOSH_DIR/templates/code/newPlatformInvariantTest" "$fx/templates/code/"
  local OOSH_DIR="$fx"
  t="$fx/test/test.platform.fx.layout.invariant"
  oo.test.platform.new fx layout >/dev/null 2>&1 || bad="$bad rc=$?"
  [ -x "$t" ] || bad="$bad not-created"
  grep -q '^TEST_CATEGORY=platform' "$t" 2>/dev/null || bad="$bad category"
  grep -q 'platform\.fx\.layout:' "$t" 2>/dev/null || bad="$bad not-substituted"
  grep -qE '<scope>|<aspect>' "$t" 2>/dev/null && bad="$bad placeholder-left"
  printf 'mine\n' > "$t"
  oo.test.platform.new fx layout >/dev/null 2>&1 && bad="$bad overwrite-passed"
  [ "$(cat "$t")" = mine ] || bad="$bad overwrote-existing"
  oo.test.platform.new 'fx/x' layout >/dev/null 2>&1 && bad="$bad bad-name-passed"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "test.platform.new: generated from the template, refuses to overwrite or a bad name" || create.result 1 "test.platform.new:$bad"
  return $(result)
}
test.case $level "T-OO-TEST-PLATFORM-NEW: oo test.platform.new generates a platform invariant test" test.oo.testPlatformNew
expect 0 "test.platform.new: generated from the template, refuses to overwrite or a bad name" "platform invariants come from the template, not by hand"
```
Implement in `oo` (replace the generated completion stubs with these two):

```bash
oo.test.platform.new() # <scope> <aspect> # generate test/test.platform.<scope>.<aspect>.invariant from templates/code/newPlatformInvariantTest; refuses an existing file #
{
  local scope="$1" aspect="$2"
  if [ -z "$scope" ] || [ -z "$aspect" ]; then
    create.result 1 "oo test.platform.new requires <scope> <aspect>"; error.log "$RESULT"; return $(result)
  fi
  # camelCase segments only: the name becomes a file name and a sed replacement.
  case "$scope$aspect" in
    *[!A-Za-z0-9]*) create.result 1 "oo test.platform.new: <scope> and <aspect> are camelCase words, got '$scope' '$aspect'"; error.log "$RESULT"; return $(result) ;;
  esac
  local template="$OOSH_DIR/templates/code/newPlatformInvariantTest"
  local target="$OOSH_DIR/test/test.platform.$scope.$aspect.invariant"
  if [ ! -f "$template" ]; then create.result 1 "oo test.platform.new: template missing: $template"; error.log "$RESULT"; return $(result); fi
  if [ -e "$target" ]; then create.result 1 "oo test.platform.new: refusing to overwrite $target"; error.log "$RESULT"; return $(result); fi
  if sed -e "s/<scope>/$scope/g" -e "s/<aspect>/$aspect/g" "$template" > "$target" && chmod +x "$target"; then
    success.log "created test/test.platform.$scope.$aspect.invariant — replace its INVARIANT blocks, then: ./test.suite run platform.$scope.$aspect.invariant 1"
    create.result 0 "created test/test.platform.$scope.$aspect.invariant"
  else
    rm -f "$target"
    create.result 1 "oo test.platform.new: could not write $target"; error.log "$RESULT"
  fi
  return $(result)
}
oo.test.platform.new.completion.scope()  { echo shared; }
oo.test.platform.new.completion.aspect() { echo config; echo oosh; echo layout; }
```
(`rm -f "$target"` only on the failure branch, and only after the existence refusal above — so it can only remove what this call wrote.) Run `./test.suite run oo 1` → PASS. **Commit** `feat(oo): oo test.platform.new — generate platform invariant tests from the template`.

- [x] **Step 6: completion audit covers ogit** — in `test/test.completion.audit`, add `ogit` to `IN_SCOPE_SCRIPTS` (lines 39-41; the loop skips a script that does not exist yet, so this is safe before Task 1) and append ` limit asName ` to the single-line `EXEMPT_PARAMS`, with a comment above it: `# limit: a number of commits (ogit commit.log.show); asName: free-text bot display name (ogit identity)`. The remaining free ogit params get shared completers in Task 3 (`asEmail` → the configured email, `range` → refs, `paths`/`pathspecs` → files, `treeRoot` → `$OOSH_DIR`).

Run `./test.suite run completion.audit 1` → PASS (unchanged count until ogit exists). **Commit** `test(completion.audit): ogit in scope; limit and asName exempt with reason`.

- [x] **Step 7: Gate** — `./test.suite run this 1`, `./test.suite run oo 1`, validators (rule 5) → green. Allow-list any new command in `.claude/settings.json`. **Stop (Batch M).**

---

### Task 1: Scaffold `ogit` and `test/test.ogit`

**Files:**
- Create: `ogit` and `test/test.ogit` (both via `oo new ogit` — it runs the `newScript` and `newScriptTest` templates)

- [x] **Step 1: Scaffold with the OOSH tool**

```bash
cd ~/oosh && LOG_LEVEL=1 ./oo new ogit && ls -l ogit test/test.ogit
```
Expected: both files exist, `ogit` executable, each carries its marker (`### new.method` / `### test.method`).

- [x] **Step 2: Header, banners, usage**

Replace the top of `ogit` (keep the template's commented `#clear`/`PS4` lines) so it reads:

```bash
#!/usr/bin/env bash
#clear
#export PS4='\e[90m+${LINENO} in ${#BASH_SOURCE[@]}>${FUNCNAME[0]}:${BASH_SOURCE[@]##*/} \e[0m'
#set -x

# ogit - git wrapper for oosh
# No flags, positional params only. Following: tmux→otmux, ssh→ossh, docker→odocker, git→ogit
#
# THE ONLY CALLER of the git binary in this tree (ogit caller.validate; T-OGIT-ONLY-CALLER).
# Nouns are git objects, verbs are actions, qualifiers are parameters
# (docs/superpowers/specs/2026-09-23-ogit-clones-per-branch-design.md § 3).
# Every method takes <?dir:$OOSH_DIR> LAST — resolved inline as
# `local dir="${N:-${OOSH_DIR:-.}}"` — and runs `git -C "$dir" …`, never `cd`.
# Variadic exceptions, where <?dir> precedes the list: repo.grep, index.add, diff.check, raw.
# Getters answer on stdout with no create.result; mutators create.result + return $(result).

# ─────────────────────────────────────────────────────────────────────────────
# PRIVATE HELPERS
# ─────────────────────────────────────────────────────────────────────────────

private.ogit.require() # # rc 0 when the git binary is present; error.log + create.result 127 when it is not #
{
 command -v git >/dev/null 2>&1 && return 0
 create.result 127 "ogit: git is not installed — run \`oo cmd git\`"
 error.log "$RESULT"
 return 127
}

private.ogit.identity() # <?asEmail> <?asName> # fill the array OGIT_IDENTITY with the -c flags for a bot commit/merge (empty when no email) — arrays, because a name like "oosh promote" has a space #
{
 OGIT_IDENTITY=()
 [ -n "$1" ] && OGIT_IDENTITY=(-c "user.email=$1" -c "user.name=${2:-$1}" -c commit.gpgsign=false)
 return 0
}

### new.method
```

Replace `ogit.usage` examples with one line per noun:

```bash
ogit.usage()
{
  local this=${0##*/}
  echo "You started"
  echo "$0

  Usage:
  $this: command   Parameter and Description"
  this.help
  echo "

  Examples
    $this repo.clone git@github.com:Cerulean-Circle-GmbH/once.sh.git dev /tmp/dev
    $this branch.get
    $this branch.list all
    $this remote.pull
    $this commit.log.show dev..testing 20 oneline
    $this status.show short
    $this tag.latest.get
    $this safeDirectory.ensure
    $this worktree.find prod
    $this layout.status
    $this caller.validate
    ----------
  "
}
```

- [x] **Step 3: Verify the sourced guard**

```bash
bash -c 'source ~/oosh/ogit; type -t ogit.usage; echo "rc=$?"'
```
Expected: `function` and `rc=0`, no usage text printed (because `this.start` returns on `this.isSourced`). If usage prints, add to `ogit.start` before `this.start`: `this.isSourced "${FUNCNAME[1]}" && return 0` — and record why in a comment.

- [x] **Step 4: Completion is automatic — prove it**

```bash
./ng/c2 function.completion ./ogit
```
Expected: `usage` (only). Later tasks add methods.

- [x] **Step 5: Commit**

```bash
git add ogit test/test.ogit && git commit -m "feat(ogit): scaffold the git wrapper (oo new ogit) — header, helpers, usage"
```

---

### Task 2: Test fixture helper + assertion idiom in `test/test.ogit`

**Files:**
- Modify: `test/test.ogit` (above `### test.method`)

- [x] **Step 1: Add the fixture helper and a smoke case**

Insert after `source ogit` (the template sources the script under test; keep `TEST_CATEGORY=core`):

```bash
# ============================================================================
# Fixture: a work clone with one commit on dev, tracking a bare origin.
# Raw git is allowed in test/ (fixtures); everything under test goes through ogit.
# ============================================================================
test.ogit.fixture() { # <label> # echo <fx>; <fx>/work is the clone, <fx>/origin.git its origin
  local fx; fx=$(test.suite.fixture.make "$1") || return 1
  git init -q --bare -b dev "$fx/origin.git"
  git init -q -b dev "$fx/work"
  git -C "$fx/work" remote add origin "$fx/origin.git"
  printf 'seed\n' > "$fx/work/file"
  git -C "$fx/work" add file
  # The seed is tick 0 of the clock test.ogit.commit advances, so every
  # date-sorted answer (tag.list) is deterministic, whatever today's date is.
  GIT_COMMITTER_DATE="@1700000000 +0000" GIT_AUTHOR_DATE="@1700000000 +0000" \
    git -C "$fx/work" -c user.email=t@t -c user.name=t commit -q -m seed
  git -C "$fx/work" push -q -u origin dev
  echo "$fx"
}

test.ogit.commit() { # <work> <message> # one more commit on the fixture (raw git, fixture side); each commit is one minute later than the previous, so date-sorted answers are deterministic
  TEST_OGIT_TICK=$(( ${TEST_OGIT_TICK:-0} + 1 ))
  printf '%s\n' "$2" >> "$1/file"
  git -C "$1" add file
  GIT_COMMITTER_DATE="@$((1700000000 + TEST_OGIT_TICK * 60)) +0000" GIT_AUTHOR_DATE="@$((1700000000 + TEST_OGIT_TICK * 60)) +0000" \
    git -C "$1" -c user.email=t@t -c user.name=t commit -q -m "$2"
}

test.ogit.fixtureWorks() {
  local fx; fx=$(test.ogit.fixture smoke)
  local n; n=$(git -C "$fx/work" rev-list --count HEAD)
  local up; up=$(git -C "$fx/work" rev-parse --abbrev-ref @{u})
  rm -rf "$fx"
  if [ "$n" = 1 ] && [ "$up" = "origin/dev" ]; then create.result 0 "fixture: one commit, tracking origin/dev"
  else create.result 1 "fixture broken: commits=$n upstream=$up"; fi
  return $(result)
}
test.case $level "T-OGIT-FIXTURE: the fixture clone tracks its bare origin" test.ogit.fixtureWorks
expect 0 "fixture: one commit, tracking origin/dev" "every ogit case builds on this shape"
```

- [x] **Step 2: Run** `./test.suite run ogit 1` → PASS (fixture only; the template's own "test start" case may print usage — that is expected).
- [x] **Step 3: Commit** `git add test/test.ogit && git commit -m "test(ogit): fixture helper — work clone tracking a bare origin"`

---

### Task 3: `repo` noun

(`private.ogit.gitdir` — shown in Task 19 — is needed by `repo.share`; create it here, in the PRIVATE HELPERS section, with `oo method.new private.ogit.gitdir`.)

**Files:** `ogit`, `test/test.ogit`

For each method: scaffold with `oo method.new` (params / description exactly as the signature below), replace the stub body, replace the stub test with the case shown, run RED, implement, run GREEN, commit. Bodies:

- [x] **Step 1: Tests (RED)** — add to `test/test.ogit`:

```bash
test.ogit.repo() {
  local fx bad=""; fx=$(test.ogit.fixture repo)
  ogit.repo.check "$fx/work" || bad="$bad check-repo-rc=$?"
  ogit.repo.check "$fx" && bad="$bad check-nonrepo-passed"
  [ "$(ogit.repo.root.get "$fx/work")" = "$fx/work" ] || bad="$bad root=$(ogit.repo.root.get "$fx/work")"
  ogit.repo.clone "$fx/origin.git" dev "$fx/clone" >/dev/null 2>&1 || bad="$bad clone-rc=$?"
  [ -d "$fx/clone/.git" ] && [ "$(git -C "$fx/clone" branch --show-current)" = dev ] || bad="$bad clone-shape"
  ogit.repo.clone "$fx/origin.git" nosuch "$fx/clone2" >/dev/null 2>&1 && bad="$bad clone-bad-branch-passed"
  [ -e "$fx/clone2" ] && bad="$bad clone-left-halfmade-dir"
  # never clone over — and never delete — a folder this call did not create
  mkdir -p "$fx/occupied"; printf 'keep\n' > "$fx/occupied/mine"
  ogit.repo.clone "$fx/origin.git" dev "$fx/occupied" >/dev/null 2>&1 && bad="$bad clone-over-nonempty-passed"
  [ "$(cat "$fx/occupied/mine" 2>/dev/null)" = keep ] || bad="$bad clone-destroyed-existing-dir"
  [ "$(ogit.repo.files.list "$fx/work")" = file ] || bad="$bad files=$(ogit.repo.files.list "$fx/work")"
  [ "$(ogit.repo.grep '^seed' "$fx/work")" = "file:1:seed" ] || bad="$bad grep=$(ogit.repo.grep '^seed' "$fx/work")"
  ogit.repo.share "$fx/work" >/dev/null 2>&1 || bad="$bad share-rc=$?"
  [ "$(git -C "$fx/work" config --get core.sharedRepository)" = group ] || bad="$bad share-config"
  [ -g "$fx/work/.git/objects" ] || bad="$bad share-setgid"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "repo: clone, check, root.get, files.list, grep, share behave" || create.result 1 "repo:$bad"
  return $(result)
}
test.case $level "T-OGIT-REPO: repo.clone/check/root.get/files.list/grep/share" test.ogit.repo
expect 0 "repo: clone, check, root.get, files.list, grep, share behave" "the repo noun"
```

- [x] **Step 2: Run** → FAIL (`ogit.repo.check: command not found` or the stub's RESULT).

- [x] **Step 3: Implement** (scaffold each with `oo method.new`, then paste; delete every completion stub the generator made for a parameter the shared block below covers):

```bash
ogit.repo.clone()     # <url> <branch> <targetDir> # clone <url> at <branch> into <targetDir>; refuses a non-empty <targetDir>; on failure removes only a dir this call created #
{
 private.ogit.require || return $(result)
 local url="$1" branch="$2" target="$3"
 if [ -z "$url" ] || [ -z "$branch" ] || [ -z "$target" ]; then
   create.result 1 "ogit.repo.clone requires <url> <branch> <targetDir>"; error.log "$RESULT"; return $(result)
 fi
 # Never clone over, and never delete, a folder this call did not make: a
 # re-run of state 31 over an existing dev/ must not lose it.
 if [ -e "$target" ] && [ -n "$(ls -A "$target" 2>/dev/null)" ]; then
   create.result 1 "ogit.repo.clone: $target exists and is not empty — refusing to clone over it"; error.log "$RESULT"; return $(result)
 fi
 local created=no
 [ -e "$target" ] || created=yes
 if git clone -b "$branch" "$url" "$target"; then
   create.result 0 "cloned $branch into $target"
 else
   [ "$created" = yes ] && rm -rf "$target" 2>/dev/null
   create.result 1 "clone of $branch from $url failed"; error.log "$RESULT"
 fi
 return $(result)
}

ogit.repo.check()     # <?dir:$OOSH_DIR> # rc 0 when <dir> is inside a git repository #
{
 local dir="${1:-${OOSH_DIR:-.}}"
 git -C "$dir" rev-parse --git-dir >/dev/null 2>&1
}

ogit.repo.root.get()     # <?dir:$PWD> # echo the toplevel of the repository containing <dir> #
{
 git -C "${1:-$PWD}" rev-parse --show-toplevel 2>/dev/null
}

ogit.repo.share()     # <?dir:$OOSH_DIR> # make <dir>'s repository group-writable: dev group + g+w (private.ensure.sharedTree), setgid on every .git dir, core.sharedRepository group #
{
 private.ogit.require || return $(result)
 local dir="${1:-${OOSH_DIR:-.}}"
 local gitDir
 gitDir=$(private.ogit.gitdir "$dir")
 if [ -z "$gitDir" ]; then create.result 1 "ogit.repo.share: $dir is not a repository"; error.log "$RESULT"; return $(result); fi
 # chgrp dev + g+w is the kernel's job (this:420; it skips cleanly on a
 # single-user host without a dev group). setgid is NOT — sharedTree
 # deliberately sets none on config trees — so it is the one piece done here.
 if private.ensure.sharedTree "$gitDir" \
    && find "$gitDir" -type d -exec chmod g+s {} + 2>/dev/null \
    && git -C "$dir" config core.sharedRepository group 2>/dev/null; then
   create.result 0 "shared: $dir"
 else
   create.result 1 "ogit.repo.share: could not set group mode on $gitDir"; error.log "$RESULT"
 fi
 return $(result)
}

ogit.repo.grep()     # <pattern> <?dir:$OOSH_DIR> <?pathspecs...> # git grep -nE <pattern> over the tracked files of <dir> (the tree sweeps); variadic, so <?dir> precedes <pathspecs> #
{
 local pattern="$1"
 local dir="${2:-${OOSH_DIR:-.}}"
 if [ $# -ge 2 ]; then shift 2; else shift; fi
 git -C "$dir" grep -nE "$pattern" -- "$@" 2>/dev/null
}

ogit.repo.files.list()     # <?dir:$OOSH_DIR> # echo the tracked files of <dir>, one per line #
{
 local dir="${1:-${OOSH_DIR:-.}}"
 git -C "$dir" ls-files 2>/dev/null
}
```

Also add the shared completers near the bottom (before `ogit.start`). c2 falls back to `ogit.parameter.completion.<param>` when no method-specific completer exists (ng/c2:483,518), and the completion audit accepts it — so **no method carries a wrapper that only forwards here**:

```bash
# ─────────────────────────────────────────────────────────────────────────────
# SHARED PARAMETER COMPLETION — c2 falls back to these for every method
# (ng/c2:483,518). Direct git / filesystem, no create.result (c2 rule).
# A method keeps its own .completion.<param> only for an enumeration of its own.
# ─────────────────────────────────────────────────────────────────────────────
ogit.parameter.completion.dir()        { compgen -d "$1"; }
ogit.parameter.completion.targetDir()  { compgen -d "$1"; }
ogit.parameter.completion.path()       { compgen -d "$1"; }
ogit.parameter.completion.base()       { compgen -d "$1"; }
ogit.parameter.completion.treeRoot()   { echo "$OOSH_DIR"; }
ogit.parameter.completion.branch()     { ogit.branch.list all; }
ogit.parameter.completion.ref()        { ogit.branch.list all; ogit.tag.list; }
ogit.parameter.completion.startPoint() { ogit.parameter.completion.ref "$@"; }
ogit.parameter.completion.commit()     { ogit.parameter.completion.ref "$@"; }
ogit.parameter.completion.to()         { ogit.parameter.completion.ref "$@"; }
ogit.parameter.completion.a()          { ogit.parameter.completion.ref "$@"; }
ogit.parameter.completion.b()          { ogit.parameter.completion.ref "$@"; }
ogit.parameter.completion.range()      { ogit.parameter.completion.ref "$@"; }
ogit.parameter.completion.tag()        { ogit.tag.list; }
ogit.parameter.completion.remote()     { git -C "${OOSH_DIR:-.}" remote 2>/dev/null; }
ogit.parameter.completion.paths()      { compgen -f "$1"; }
ogit.parameter.completion.pathspecs()  { compgen -f "$1"; }
ogit.parameter.completion.asEmail()    { ogit.config.email.get; }
```
(`ogit.branch.list` / `ogit.tag.list` / `ogit.config.email.get` arrive in Tasks 4, 9 and 10; until then the completer prints nothing — fine. `from`, `url`, `pattern`, `message`, `format`, `key`, `value`, `args` are already in `EXEMPT_PARAMS`; `limit`, `asName` since Task M.)

- [x] **Step 4: Run** → PASS; `./test.suite run completion.audit 1` → PASS. `./ng/c2 function.completion ./ogit repo` lists the six methods.
- [x] **Step 5: Commit** `git add ogit test/test.ogit && git commit -m "feat(ogit): repo noun — clone, check, root.get, share, grep, files.list"`

---

### Task 4: `branch` noun

**Files:** `ogit`, `test/test.ogit`

- [x] **Step 1: Tests (RED)**

```bash
test.ogit.branch() {
  local fx bad="" out; fx=$(test.ogit.fixture branch); local w="$fx/work"
  [ "$(ogit.branch.get "$w")" = dev ] || bad="$bad get=$(ogit.branch.get "$w")"
  git -C "$w" checkout -q -b heads/origin/testing 2>/dev/null
  [ "$(ogit.branch.get "$w")" = testing ] || bad="$bad get-strips=$(ogit.branch.get "$w")"
  git -C "$w" checkout -q dev; git -C "$w" branch -q -D heads/origin/testing
  git -C "$w" branch -q feature/x
  out=$(ogit.branch.list local "$w" | tr '\n' ' ')
  case "$out" in *"dev "*"feature/x "*|*"feature/x "*"dev "*) ;; *) bad="$bad list-local=[$out]" ;; esac
  out=$(ogit.branch.list remote "$w" | tr '\n' ' ')
  [ "$out" = "dev " ] || bad="$bad list-remote=[$out]"
  out=$(ogit.branch.list all "$w" | grep -c .)
  [ "$out" = 2 ] || bad="$bad list-all-count=$out"
  ogit.branch.check dev "$w" || bad="$bad check-dev"
  ogit.branch.check nosuch "$w" && bad="$bad check-nosuch-passed"
  out=$(ogit.branch.find HEAD "$w" | tr '\n' ' ')
  case "$out" in *dev*) ;; *) bad="$bad find=[$out]" ;; esac
  ogit.branch.checkout feature/x "$w" >/dev/null 2>&1 && [ "$(git -C "$w" branch --show-current)" = feature/x ] || bad="$bad checkout"
  ogit.branch.upstream.set origin/dev "$w" >/dev/null 2>&1 || bad="$bad upstream-rc=$?"
  [ "$(git -C "$w" rev-parse --abbrev-ref '@{u}' 2>/dev/null)" = origin/dev ] || bad="$bad upstream"
  ogit.branch.reset dev origin/dev "$w" >/dev/null 2>&1 && [ "$(git -C "$w" branch --show-current)" = dev ] || bad="$bad reset"
  test.ogit.commit "$w" two
  # a real verdict, not "non-empty": origin/dev lacks the one commit dev just got
  ogit.branch.compare dev origin/dev "$w" >/dev/null
  [ "$RESULT" = "1 commits behind dev" ] || bad="$bad compare=[$RESULT]"
  ogit.branch.compare dev dev "$w" >/dev/null
  [ "$RESULT" = "up to date with dev" ] || bad="$bad compare-same=[$RESULT]"
  git -C "$w" checkout -q feature/x
  ogit.branch.merge dev "t@t" "t t" "$w" >/dev/null 2>&1 || bad="$bad merge-rc=$?"
  [ "$(git -C "$w" rev-parse feature/x)" = "$(git -C "$w" rev-parse dev)" ] || bad="$bad merge-ff"
  git -C "$w" checkout -q dev; test.ogit.commit "$w" three; git -C "$w" checkout -q feature/x
  ogit.branch.fastForward dev "$w" >/dev/null 2>&1 || bad="$bad ff-rc=$?"
  [ "$(git -C "$w" rev-parse feature/x)" = "$(git -C "$w" rev-parse dev)" ] || bad="$bad ff-sha"
  test.ogit.commit "$w" diverge; git -C "$w" checkout -q dev; test.ogit.commit "$w" other
  ogit.branch.fastForward feature/x "$w" >/dev/null 2>&1 && bad="$bad ff-diverged-passed"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "branch: get/list/check/find/checkout/upstream.set/reset/compare/merge behave" || create.result 1 "branch:$bad"
  return $(result)
}
test.case $level "T-OGIT-BRANCH: the branch noun" test.ogit.branch
expect 0 "branch: get/list/check/find/checkout/upstream.set/reset/compare/merge behave" "the branch noun"
```

- [x] **Step 2: Run** → FAIL (functions missing).

- [x] **Step 3: Implement.** `ogit.branch.compare` counts with `ogit.commit.count`, so create `ogit.commit.count` **here** (`oo method.new ogit.commit.count`, body from Task 7); Task 7 then only adds its assertions.

```bash
ogit.branch.get()     # <?dir:$OOSH_DIR> # echo the current branch of <dir>, sanitised (refs/heads/, refs/remotes/origin/, heads/origin/, origin/ stripped); empty when detached or not a repo #
{
 # Moved from this.git.branch.short (this:903). Degenerate names like
 # heads/origin/dev come from `git worktree add <path> heads/origin/dev` or
 # `checkout -b origin/dev`; callers concatenate `origin/` onto the answer.
 local dir="${1:-${OOSH_DIR:-.}}"
 local b
 b=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
 b="${b#refs/heads/}"; b="${b#refs/remotes/origin/}"; b="${b#heads/origin/}"; b="${b#origin/}"
 printf '%s' "$b"
}

ogit.branch.list()     # <?source:local> <?dir:$OOSH_DIR> # echo branch names one per line: local, remote (cached origin/* refs, offline) or all #
{
 local source="${1:-local}"
 local dir="${2:-${OOSH_DIR:-.}}"
 case "$source" in
   local)  git -C "$dir" branch --format='%(refname:short)' 2>/dev/null ;;
   remote) git -C "$dir" for-each-ref refs/remotes/origin --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||' | grep -vx HEAD ;;
   all)    { ogit.branch.list local "$dir"; ogit.branch.list remote "$dir"; } | sort -u ;;
   *) return 1 ;;
 esac
}
ogit.branch.list.completion.source() { echo local; echo remote; echo all; }

ogit.branch.check()     # <ref> <?dir:$OOSH_DIR> # rc 0 when <ref> resolves in <dir> #
{
 local dir="${2:-${OOSH_DIR:-.}}"
 git -C "$dir" rev-parse --verify --quiet "$1" >/dev/null 2>&1
}

ogit.branch.find()     # <commit> <?dir:$OOSH_DIR> # echo every branch (local and remote) containing <commit> #
{
 local dir="${2:-${OOSH_DIR:-.}}"
 git -C "$dir" branch -a --contains "$1" --format='%(refname:short)' 2>/dev/null
}

ogit.branch.checkout()     # <ref> <?dir:$OOSH_DIR> # check <ref> out in <dir> #
{
 private.ogit.require || return $(result)
 local dir="${2:-${OOSH_DIR:-.}}"
 if git -C "$dir" checkout "$1" 2>/dev/null; then create.result 0 "checked out $1"
 else create.result 1 "could not check out $1 in $dir"; fi
 return $(result)
}

ogit.branch.upstream.set()     # <ref> <?dir:$OOSH_DIR> # make the current branch of <dir> track <ref> (e.g. origin/dev) #
{
 private.ogit.require || return $(result)
 local ref="$1"
 local dir="${2:-${OOSH_DIR:-.}}"
 if [ -z "$ref" ]; then create.result 1 "ogit.branch.upstream.set requires <ref>"; error.log "$RESULT"; return $(result); fi
 if git -C "$dir" branch -q -u "$ref" 2>/dev/null; then create.result 0 "$(ogit.branch.get "$dir") tracks $ref"
 else create.result 1 "could not set the upstream of $dir to $ref"; fi
 return $(result)
}

ogit.branch.reset()     # <branch> <startPoint> <?dir:$OOSH_DIR> # create or reset <branch> at <startPoint> and check it out (checkout -B) #
{
 private.ogit.require || return $(result)
 local dir="${3:-${OOSH_DIR:-.}}"
 if git -C "$dir" checkout -B "$1" "$2" >/dev/null 2>&1; then create.result 0 "$1 reset to $2"
 else create.result 1 "could not reset $1 to $2"; fi
 return $(result)
}

ogit.branch.compare()     # <from> <to> <?dir:$OOSH_DIR> # symmetric branch comparison; RESULT = up to date with <from> | <from> merged in | N commits behind <from> | diverged: N behind <from> (moved verbatim from promote.branch.alignment) #
{
  # Moved verbatim from promote.branch.alignment (promote:277-316 at 8c46828);
  # the only change is the count call: this.git.commits.count "$OOSH_DIR" A B
  # → ogit.commit.count A B "$dir". The four verdict strings are pinned by
  # test.promote (T-PROMOTE-BRANCH-ALIGN-*) — do not reword them.
  local from="$1"
  local to="$2"
  local dir="${3:-${OOSH_DIR:-.}}"
  if [ -z "$from" ] || [ -z "$to" ]; then
    create.result 1 "ogit.branch.compare requires <from> <to>"
    error.log "$RESULT"
    return $(result)
  fi

  # Verdict is from <to>'s perspective relative to <from>:
  #   behindCount = commits on <from> not on <to>  (commits <to> is behind <from> by)
  #   aheadCount  = commits on <to> not on <from>  (commits <to> is ahead of <from> by)
  local behindCount aheadCount
  ogit.commit.count "$to"   "$from" "$dir"; behindCount="$RESULT"
  ogit.commit.count "$from" "$to"   "$dir"; aheadCount="$RESULT"

  if [ "$behindCount" = "0" ] && [ "$aheadCount" = "0" ]; then
    create.result 0 "up to date with $from"
  elif [ "$behindCount" = "0" ]; then
    # <to> contains every commit of <from> plus its own. Post-promote
    # steady state: <from> has been successfully merged into <to>, plus
    # bookkeeping commits (the merge commit + OOSH_SELF_BRANCH rewrite).
    # The bookkeeping count is not actionable — the timestamp on the <to>
    # line shows when the merge happened.
    create.result 0 "$from merged in"
  elif [ "$aheadCount" = "0" ]; then
    create.result 0 "$behindCount commits behind $from"
  else
    # Diverged: <from> advanced past where <to>'s last merge picked it up,
    # AND <to> has its own bookkeeping commits from prior promotes. The
    # ahead-count is just history (bookkeeping); only the behind-count is
    # actionable — that's how far <to> needs to catch up via `oo stage
    # <from>`. See docs/promote.md for the full state vocabulary.
    create.result 0 "diverged: $behindCount behind $from"
  fi
  return $(result)
}

ogit.branch.fastForward()     # <ref> <?dir:$OOSH_DIR> # fast-forward the current branch of <dir> to <ref>; rc 1 (nothing changed) when it has diverged #
{
 private.ogit.require || return $(result)
 local dir="${2:-${OOSH_DIR:-.}}"
 if git -C "$dir" merge --ff-only "$1" >/dev/null 2>&1; then create.result 0 "fast-forwarded to $1"; else create.result 1 "$dir has diverged from $1 — no fast-forward"; fi
 return $(result)
}

ogit.branch.merge()     # <ref> <?asEmail> <?asName> <?dir:$OOSH_DIR> # merge <ref> into the current branch of <dir> (--no-edit); with <asEmail>/<asName> the merge commit carries that identity and no gpg signing #
{
 private.ogit.require || return $(result)
 local ref="$1"
 local dir="${4:-${OOSH_DIR:-.}}"
 private.ogit.identity "$2" "$3"
 if git -C "$dir" "${OGIT_IDENTITY[@]}" merge "$ref" --no-edit 2>/dev/null; then
   create.result 0 "merged $ref"
 else
   create.result 1 "merge of $ref failed in $dir — conflicts? see ogit conflict.list"
 fi
 return $(result)
}
```
(No per-method completers: `dir`, `ref`, `branch`, `startPoint`, `commit`, `to`, `asEmail` come from the shared block; `from` is exempt; `asName` exempt since Task M.)

- [x] **Step 4: Run** `./test.suite run ogit 1` and `./test.suite run completion.audit 1` → PASS. Commit: `feat(ogit): branch noun — compare moved in with its body; upstream.set`.

---

### Task 5: `merge` and `conflict` nouns

- [x] **Step 1: Test (RED)** — a fixture with a real conflict:

```bash
test.ogit.mergeConflict() {
  local fx bad="" w; fx=$(test.ogit.fixture conflict); w="$fx/work"
  git -C "$w" checkout -q -b other; printf 'theirs\n' > "$w/file"; git -C "$w" -c user.email=t@t -c user.name=t commit -qam theirs
  git -C "$w" checkout -q dev; printf 'ours\n' > "$w/file"; git -C "$w" -c user.email=t@t -c user.name=t commit -qam ours
  local base; base=$(ogit.merge.base.get dev other "$w")
  [ "$base" = "$(git -C "$w" rev-parse dev~1)" ] || bad="$bad base=$base"
  ogit.branch.merge other t@t t "$w" >/dev/null 2>&1 && bad="$bad conflicting-merge-passed"
  [ "$(ogit.conflict.list "$w")" = file ] || bad="$bad list=$(ogit.conflict.list "$w")"
  ogit.conflict.resolve file theirs "$w" >/dev/null 2>&1 || bad="$bad resolve-rc=$?"
  [ "$(cat "$w/file")" = theirs ] || bad="$bad resolved-content"
  [ -z "$(ogit.conflict.list "$w")" ] || bad="$bad still-conflicted"
  ogit.merge.abort "$w" >/dev/null 2>&1 || bad="$bad abort-rc=$?"
  [ "$(cat "$w/file")" = ours ] || bad="$bad abort-content"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "merge.base.get, conflict.list, conflict.resolve, merge.abort behave" || create.result 1 "merge/conflict:$bad"
  return $(result)
}
test.case $level "T-OGIT-MERGE-CONFLICT: merge and conflict nouns" test.ogit.mergeConflict
expect 0 "merge.base.get, conflict.list, conflict.resolve, merge.abort behave" "promote's conflict path"
```

- [x] **Step 2: Implement**

```bash
ogit.merge.abort()     # <?dir:$OOSH_DIR> # abort the merge in progress in <dir> #
{
 private.ogit.require || return $(result)
 local dir="${1:-${OOSH_DIR:-.}}"
 if git -C "$dir" merge --abort 2>/dev/null; then create.result 0 "merge aborted"; else create.result 1 "no merge to abort in $dir"; fi
 return $(result)
}

ogit.merge.base.get()     # <a> <b> <?dir:$OOSH_DIR> # echo the merge base commit of <a> and <b> #
{
 local dir="${3:-${OOSH_DIR:-.}}"
 git -C "$dir" merge-base "$1" "$2" 2>/dev/null
}

ogit.conflict.list()     # <?dir:$OOSH_DIR> # echo the conflicted paths of the merge in progress, one per line #
{
 local dir="${1:-${OOSH_DIR:-.}}"
 git -C "$dir" diff --name-only --diff-filter=U 2>/dev/null
}

ogit.conflict.resolve()     # <file> <?side:theirs> <?dir:$OOSH_DIR> # resolve <file>'s conflict by taking <side> (theirs = the merged-in branch, ours = the current one) and stage it #
{
 private.ogit.require || return $(result)
 local side="${2:-theirs}"
 local dir="${3:-${OOSH_DIR:-.}}"
 case "$side" in theirs|ours) ;; *) create.result 1 "ogit.conflict.resolve: side must be theirs or ours"; error.log "$RESULT"; return $(result) ;; esac
 if git -C "$dir" checkout "--$side" -- "$1" 2>/dev/null && git -C "$dir" add -- "$1" 2>/dev/null; then create.result 0 "took $side for $1"
 else create.result 1 "could not resolve $1"; fi
 return $(result)
}
ogit.conflict.resolve.completion.file() { ogit.conflict.list; }
ogit.conflict.resolve.completion.side() { echo theirs; echo ours; }
```

- [x] **Step 3: Run** `ogit` and `completion.audit` suites → PASS. **Commit** `feat(ogit): merge and conflict nouns`.

---

### Task 6: `remote` noun

- [x] **Step 1: Test (RED)**

```bash
test.ogit.remote() {
  local fx bad="" w o; fx=$(test.ogit.fixture remote); w="$fx/work"; o="$fx/origin.git"
  [ "$(ogit.remote.url.get origin "$w")" = "$o" ] || bad="$bad url=$(ogit.remote.url.get origin "$w")"
  [ "$(ogit.remote.branch.list origin "$w")" = dev ] || bad="$bad branches=$(ogit.remote.branch.list origin "$w")"
  test.ogit.commit "$w" two
  ogit.remote.push dev no "$w" >/dev/null 2>&1 || bad="$bad push-rc=$?"
  [ "$(git -C "$o" rev-parse dev)" = "$(git -C "$w" rev-parse dev)" ] || bad="$bad push-sha"
  git -C "$w" tag v0.0.1
  ogit.remote.push dev yes "$w" >/dev/null 2>&1 && git -C "$o" rev-parse -q --verify v0.0.1 >/dev/null || bad="$bad push-tags"
  local c; c=$(test.suite.fixture.make remoteclone); git clone -q "$o" "$c/w" 2>/dev/null
  test.ogit.commit "$c/w" three; git -C "$c/w" push -q origin dev
  ogit.remote.fetch no "$w" >/dev/null 2>&1 || bad="$bad fetch-rc=$?"
  [ "$(git -C "$w" rev-parse origin/dev)" = "$(git -C "$c/w" rev-parse dev)" ] || bad="$bad fetch-ref"
  ogit.remote.pull "" "" "$w" >/dev/null 2>&1 || bad="$bad pull-rc=$?"
  [ "$(git -C "$w" rev-parse dev)" = "$(git -C "$c/w" rev-parse dev)" ] || bad="$bad pull-sha"
  ogit.remote.url.set "$fx/elsewhere.git" origin "$w" >/dev/null 2>&1 || bad="$bad url-set-rc"
  [ "$(ogit.remote.url.get origin "$w")" = "$fx/elsewhere.git" ] || bad="$bad url-set"
  rm -rf "$fx" "$c"
  [ -z "$bad" ] && create.result 0 "remote: url.get/branch.list/fetch/pull/push behave" || create.result 1 "remote:$bad"
  return $(result)
}
test.case $level "T-OGIT-REMOTE: the remote noun" test.ogit.remote
expect 0 "remote: url.get/branch.list/fetch/pull/push behave" "the remote noun"
```

- [x] **Step 2: Implement**

```bash
ogit.remote.url.get()     # <?remote:origin> <?dir:$OOSH_DIR> # echo the URL of <remote>, empty when there is none #
{
 local dir="${2:-${OOSH_DIR:-.}}"
 git -C "$dir" remote get-url "${1:-origin}" 2>/dev/null
}

ogit.remote.branch.list()     # <?remote:origin> <?dir:$OOSH_DIR> # echo the branches <remote> has right now (ls-remote — needs the network); empty when unreachable #
{
 local dir="${2:-${OOSH_DIR:-.}}"
 git -C "$dir" ls-remote --heads "${1:-origin}" 2>/dev/null | sed 's|.*refs/heads/||'
}

ogit.remote.url.set()     # <url> <?remote:origin> <?dir:$OOSH_DIR> # point <remote> of <dir> at <url> #
{
 private.ogit.require || return $(result)
 local dir="${3:-${OOSH_DIR:-.}}"
 if git -C "$dir" remote set-url "${2:-origin}" "$1" 2>/dev/null; then create.result 0 "${2:-origin} → $1"; else create.result 1 "could not set ${2:-origin} to $1"; fi
 return $(result)
}

ogit.remote.fetch()     # <?prune:no> <?dir:$OOSH_DIR> # fetch origin into <dir>; prune=yes drops deleted remote branches #
{
 private.ogit.require || return $(result)
 local dir="${2:-${OOSH_DIR:-.}}"
 local prune=""
 [ "$1" = yes ] && prune="--prune"
 if git -C "$dir" fetch $prune origin 2>/dev/null; then create.result 0 "fetched origin into $dir"
 else create.result 1 "fetch from origin failed in $dir"; fi
 return $(result)
}
ogit.remote.fetch.completion.prune() { echo no; echo yes; }

ogit.remote.pull()     # <?url> <?branch> <?dir:$OOSH_DIR> # pull into <dir>; with <url> <branch> pull that branch from that URL instead of the tracking remote (oo.update's https fallback) #
{
 private.ogit.require || return $(result)
 local url="$1"
 local branch="$2"
 local dir="${3:-${OOSH_DIR:-.}}"
 local rc
 if [ -n "$url" ]; then git -C "$dir" pull "$url" "$branch"; rc=$?; else git -C "$dir" pull; rc=$?; fi
 if [ "$rc" = 0 ]; then create.result 0 "pulled into $dir"; else create.result "$rc" "pull failed in $dir (rc=$rc)"; fi
 return $(result)
}

ogit.remote.push()     # <?branch> <?tags:no> <?dir:$OOSH_DIR> # push <branch> (default: the tracking branch) to origin; tags=yes pushes tags too #
{
 private.ogit.require || return $(result)
 local branch="$1"
 local dir="${3:-${OOSH_DIR:-.}}"
 local tags=""
 [ "$2" = yes ] && tags="--tags"
 local rc
 if [ -n "$branch" ]; then git -C "$dir" push origin "$branch" $tags 2>/dev/null; rc=$?
 else git -C "$dir" push $tags 2>/dev/null; rc=$?; fi
 if [ "$rc" = 0 ]; then
   create.result 0 "pushed ${branch:-tracking branch}${tags:+ with tags}"
 else
   create.result 1 "push of ${branch:-tracking branch} rejected — pull/resolve first"
 fi
 return $(result)
}
ogit.remote.push.completion.tags()   { echo no; echo yes; }
```
(`remote`, `branch`, `dir` come from the shared block; `url` is exempt.)

- [x] **Step 3: Run** `ogit` and `completion.audit` suites → PASS. **Commit** `feat(ogit): remote noun`.

---

### Task 7: `index` and `commit` nouns

- [ ] **Step 1: Test (RED)**

(The case is `test.ogit.commitNoun`, NOT `test.ogit.commit`: that name is the Task 2 fixture helper, and redefining it would break every later case that adds a commit.)

```bash
test.ogit.commitNoun() {
  local fx bad="" w n; fx=$(test.ogit.fixture commit); w="$fx/work"
  printf 'x\n' > "$w/new"; printf 'y\n' >> "$w/file"
  ogit.index.add updated "$w" >/dev/null 2>&1 || bad="$bad add-updated-rc"
  git -C "$w" diff --cached --name-only | grep -qx new && bad="$bad add-updated-took-new"
  ogit.index.add all "$w" >/dev/null 2>&1; git -C "$w" diff --cached --name-only | grep -qx new || bad="$bad add-all-missed-new"
  ogit.commit.create "two files" t@t t "$w" >/dev/null 2>&1 || bad="$bad commit-rc=$?"
  [ "$(git -C "$w" log -1 --format=%an)" = t ] || bad="$bad commit-identity"
  [ "$(git -C "$w" log -1 --format=%s)" = "two files" ] || bad="$bad commit-message"
  ogit.commit.count origin/dev dev "$w" >/dev/null; [ "$RESULT" = 1 ] || bad="$bad count=$RESULT"
  case "$(ogit.commit.show HEAD "$w")" in *"two files"*) ;; *) bad="$bad show" ;; esac
  n=$(ogit.commit.log.show "" 1 oneline "$w" | grep -c .); [ "$n" = 1 ] || bad="$bad log-limit=$n"
  case "$(ogit.commit.log.show origin/dev..dev "" oneline "$w")" in *"two files"*) ;; *) bad="$bad log-range" ;; esac
  [ "$(ogit.commit.log.show "" 1 '%an' "$w")" = t ] || bad="$bad log-format"
  # scope alone, no dir: the dir defaults to $OOSH_DIR and nothing named "all" is staged
  printf 'z\n' > "$w/third"
  ( OOSH_DIR="$w"; ogit.index.add all >/dev/null 2>&1 )
  git -C "$w" diff --cached --name-only | grep -qx third || bad="$bad add-all-without-dir"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "index.add, commit.create/count/show/log.show behave" || create.result 1 "index/commit:$bad"
  return $(result)
}
test.case $level "T-OGIT-COMMIT: index and commit nouns" test.ogit.commitNoun
expect 0 "index.add, commit.create/count/show/log.show behave" "index and commit nouns"
```

- [ ] **Step 2: Implement**

```bash
ogit.index.add()     # <?scope:all> <?dir:$OOSH_DIR> <?paths...> # stage: all (-A), updated (-u, tracked files only), or the given <paths>; variadic, so <?dir> precedes <paths> #
{
 private.ogit.require || return $(result)
 local scope="${1:-all}"
 local dir="${2:-${OOSH_DIR:-.}}"
 # scope, then dir, then paths: `shift 2` with a single argument shifts nothing
 # and would stage a file literally named "all".
 shift
 [ $# -gt 0 ] && shift
 local rc
 if [ $# -gt 0 ]; then git -C "$dir" add -- "$@"; rc=$?
 elif [ "$scope" = updated ]; then git -C "$dir" add -u; rc=$?
 else git -C "$dir" add -A; rc=$?; fi
 if [ "$rc" = 0 ]; then create.result 0 "staged ${*:-$scope}"; else create.result 1 "add failed in $dir"; fi
 return $(result)
}
ogit.index.add.completion.scope() { echo all; echo updated; }

ogit.commit.create()     # <?message> <?asEmail> <?asName> <?dir:$OOSH_DIR> # commit the index of <dir>; no <message> opens the editor; <asEmail>/<asName> give a bot identity without gpg signing #
{
 private.ogit.require || return $(result)
 local msg="$1"
 local dir="${4:-${OOSH_DIR:-.}}"
 private.ogit.identity "$2" "$3"
 local rc
 if [ -n "$msg" ]; then git -C "$dir" "${OGIT_IDENTITY[@]}" commit -q -m "$msg"; rc=$?
 else git -C "$dir" "${OGIT_IDENTITY[@]}" commit; rc=$?; fi
 if [ "$rc" = 0 ]; then create.result 0 "committed: ${msg:-(editor)}"; else create.result 1 "commit failed in $dir (nothing staged?)"; fi
 return $(result)
}

ogit.commit.show()     # <ref> <?dir:$OOSH_DIR> # show commit <ref> #
{
 local dir="${2:-${OOSH_DIR:-.}}"
 git -C "$dir" show "$1" 2>/dev/null
}

# ogit.commit.count already exists — created in Task 4 because
# ogit.branch.compare counts with it (body as it stood here). Do not add it
# again; this Task only adds its assertion (the `count=` line above).

ogit.commit.log.show()     # <?range> <?limit> <?format> <?dir:$OOSH_DIR> # git log of <range> (default HEAD), at most <limit> commits; <format> is oneline or a --pretty=format: string #
{
 local range="$1" limit="$2" format="$3"
 local dir="${4:-${OOSH_DIR:-.}}"
 local -a args=()
 [ -n "$limit" ] && args+=("-$limit")
 case "$format" in "") ;; oneline) args+=(--oneline) ;; *) args+=("--pretty=format:$format") ;; esac
 git -C "$dir" log "${args[@]}" ${range:+"$range"} 2>/dev/null
}
ogit.commit.log.show.completion.format() { echo oneline; echo '%h %ci'; }
```
(No `completion.message() { :; }` — `message` is exempt. `ref`, `to`, `range`, `paths`, `asEmail` come from the shared block; `from`, `limit`, `asName` are exempt.)

- [ ] **Step 3: Run** `ogit` and `completion.audit` suites → PASS. **Commit** `feat(ogit): index and commit nouns`.

---

### Task 8: `status` and `diff` nouns

- [ ] **Step 1: Test (RED)**

```bash
test.ogit.status() {
  local fx bad="" w; fx=$(test.ogit.fixture status); w="$fx/work"
  ogit.status.check "$w" || bad="$bad clean-check-rc"
  [ -z "$(ogit.status.show porcelain "$w")" ] || bad="$bad clean-porcelain"
  case "$(ogit.status.show short "$w")" in "## dev...origin/dev"*) ;; *) bad="$bad short=[$(ogit.status.show short "$w")]" ;; esac
  printf 'z\n' >> "$w/file"
  ogit.status.check "$w" && bad="$bad dirty-check-passed"
  ogit.diff.check "$w" && bad="$bad diff-check-passed"
  ogit.diff.check "$w" README || bad="$bad diff-check-limited-to-untouched-path-reported-dirty"
  [ "$(ogit.status.show porcelain "$w")" = " M file" ] || bad="$bad porcelain=[$(ogit.status.show porcelain "$w")]"
  git -C "$w" -c user.email=t@t -c user.name=t commit -qam z
  case "$(ogit.diff.show origin/dev dev stat "$w")" in *"file | 1 +"*) ;; *) bad="$bad diff-stat=[$(ogit.diff.show origin/dev dev stat "$w")]" ;; esac
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "status.show/check and diff.check/show behave" || create.result 1 "status/diff:$bad"
  return $(result)
}
test.case $level "T-OGIT-STATUS: status and diff nouns" test.ogit.status
expect 0 "status.show/check and diff.check/show behave" "status and diff nouns"
```
- [ ] **Step 2: Implement**

```bash
ogit.status.show()     # <?format:short> <?dir:$OOSH_DIR> # working-tree status: short (--short --branch) or porcelain #
{
 local dir="${2:-${OOSH_DIR:-.}}"
 case "${1:-short}" in
   porcelain) git -C "$dir" status --porcelain 2>/dev/null ;;
   *)         git -C "$dir" status --short --branch 2>/dev/null ;;
 esac
}
ogit.status.show.completion.format() { echo short; echo porcelain; }

ogit.status.check()     # <?dir:$OOSH_DIR> # rc 0 when the working tree and the index of <dir> are clean #
{
 local dir="${1:-${OOSH_DIR:-.}}"
 git -C "$dir" diff --quiet 2>/dev/null && git -C "$dir" diff --cached --quiet 2>/dev/null
}

ogit.diff.check()     # <?dir:$OOSH_DIR> <?paths...> # rc 0 when <paths> (default: everything) have no unstaged changes; variadic, so <?dir> comes first #
{
 local dir="${1:-${OOSH_DIR:-.}}"
 [ $# -gt 0 ] && shift
 git -C "$dir" diff --quiet -- "$@" 2>/dev/null
}

ogit.diff.show()     # <a> <b> <?format:stat> <?dir:$OOSH_DIR> # diff between <a> and <b> (three-dot); format stat or full #
{
 local dir="${4:-${OOSH_DIR:-.}}"
 case "${3:-stat}" in
   stat) git -C "$dir" diff --stat "$1...$2" 2>/dev/null ;;
   *)    git -C "$dir" diff "$1...$2" 2>/dev/null ;;
 esac
}
ogit.diff.show.completion.format() { echo stat; echo full; }
```

- [ ] **Step 3: Run** `ogit` and `completion.audit` suites → PASS. **Commit** `feat(ogit): status and diff nouns`.

---

### Task 9: `tag` and `stash` nouns

- [ ] **Step 1: Test (RED)**

```bash
test.ogit.tagStash() {
  local fx bad="" w; fx=$(test.ogit.fixture tagstash); w="$fx/work"
  ogit.tag.create v1.0.0 HEAD "$w" >/dev/null 2>&1 || bad="$bad create-rc"
  test.ogit.commit "$w" two; ogit.tag.create v1.0.10 HEAD "$w" >/dev/null 2>&1
  test.ogit.commit "$w" three; ogit.tag.create v1.0.9 HEAD "$w" >/dev/null 2>&1
  ogit.tag.check v1.0.0 "$w" || bad="$bad check"
  ogit.tag.check v9 "$w" && bad="$bad check-missing-passed"
  [ "$(ogit.tag.latest.get 'v*' "$w")" = v1.0.10 ] || bad="$bad latest=$(ogit.tag.latest.get 'v*' "$w")"
  [ "$(ogit.tag.list 'v*' "$w" | head -1)" = v1.0.9 ] || bad="$bad list-by-date=$(ogit.tag.list 'v*' "$w" | head -1)"
  printf 'w\n' >> "$w/file"
  ogit.stash.push "promote: pre-merge stash" "$w" >/dev/null 2>&1 || bad="$bad stash-push-rc"
  ogit.status.check "$w" || bad="$bad stash-left-dirty"
  [ "$(ogit.stash.top.get "$w")" = "On dev: promote: pre-merge stash" ] || bad="$bad top=[$(ogit.stash.top.get "$w")]"
  ogit.stash.pop "$w" >/dev/null 2>&1 || bad="$bad stash-pop-rc"
  ogit.status.check "$w" && bad="$bad pop-did-not-restore"
  [ -z "$(ogit.stash.top.get "$w")" ] || bad="$bad top-after-pop"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "tag.create/check/latest.get/list and stash.push/pop/top.get behave" || create.result 1 "tag/stash:$bad"
  return $(result)
}
test.case $level "T-OGIT-TAG-STASH: tag and stash nouns" test.ogit.tagStash
expect 0 "tag.create/check/latest.get/list and stash.push/pop/top.get behave" "tag and stash nouns"
```

- [ ] **Step 2: Implement**

```bash
ogit.tag.list()     # <?pattern> <?dir:$OOSH_DIR> # echo tags matching <pattern> (default all), newest creation date first #
{
 local dir="${2:-${OOSH_DIR:-.}}"
 git -C "$dir" tag -l ${1:+"$1"} --sort=-creatordate 2>/dev/null
}
ogit.tag.list.completion.pattern() { echo 'v*'; echo 'testing-*'; }

ogit.tag.check()     # <tag> <?dir:$OOSH_DIR> # rc 0 when <tag> exists #
{
 local dir="${2:-${OOSH_DIR:-.}}"
 git -C "$dir" rev-parse --verify --quiet "refs/tags/$1" >/dev/null 2>&1
}

ogit.tag.latest.get()     # <?pattern:v*> <?dir:$OOSH_DIR> # echo the highest tag matching <pattern> by version sort #
{
 local dir="${2:-${OOSH_DIR:-.}}"
 git -C "$dir" tag -l "${1:-v*}" --sort=-version:refname 2>/dev/null | head -1
}
ogit.tag.latest.get.completion.pattern() { echo 'v*'; echo 'testing-*'; }

ogit.tag.create()     # <tag> <?ref:HEAD> <?dir:$OOSH_DIR> # create lightweight <tag> at <ref> #
{
 private.ogit.require || return $(result)
 local dir="${3:-${OOSH_DIR:-.}}"
 if git -C "$dir" tag "$1" "${2:-HEAD}" 2>/dev/null; then create.result 0 "tagged $1"; else create.result 1 "could not tag $1 (exists?)"; fi
 return $(result)
}

ogit.stash.push()     # <message> <?dir:$OOSH_DIR> # stash the working tree of <dir> under <message> #
{
 private.ogit.require || return $(result)
 local dir="${2:-${OOSH_DIR:-.}}"
 if git -C "$dir" stash push -q -m "$1" 2>/dev/null; then create.result 0 "stashed: $1"; else create.result 1 "stash push failed"; fi
 return $(result)
}

ogit.stash.pop()     # <?dir:$OOSH_DIR> # pop the top stash of <dir> #
{
 private.ogit.require || return $(result)
 local dir="${1:-${OOSH_DIR:-.}}"
 if git -C "$dir" stash pop -q 2>/dev/null; then create.result 0 "stash popped"; else create.result 1 "stash pop failed (nothing stashed, or conflicts)"; fi
 return $(result)
}

ogit.stash.top.get()     # <?dir:$OOSH_DIR> # echo the message of stash@{0}, empty when the stack is empty #
{
 local dir="${1:-${OOSH_DIR:-.}}"
 git -C "$dir" stash list --format=%s -1 2>/dev/null
}
```
(`tag.list` sorts by creator date; for lightweight tags that is the commit date — which is why both fixtures date the seed at tick 0.)

- [ ] **Step 3: Run** `ogit` and `completion.audit` suites → PASS. **Commit** `feat(ogit): tag and stash nouns`.

---

### Task 10: `config` and `safeDirectory` nouns (moved from `oo`)

**Files:** `ogit`, `test/test.ogit`, `oo:397-461`, `test/test.oo` (the safeDirectory cases: search `safeDirectory` in test.oo and move them to test.ogit with the method names renamed)

- [ ] **Step 1: Test (RED)** — sandboxed via `GIT_CONFIG_GLOBAL`:

```bash
test.ogit.trust() {
  local fx bad="" w; fx=$(test.ogit.fixture trust); w="$fx/work"
  # local + export: the sandbox is this function's; the caller's value (or its absence) comes back on return
  local GIT_CONFIG_GLOBAL="$fx/gitconfig"; export GIT_CONFIG_GLOBAL; : > "$GIT_CONFIG_GLOBAL"
  ogit.config.set user.email me@fx "$w" >/dev/null 2>&1 || bad="$bad set-rc"
  [ "$(ogit.config.get user.email any "$w")" = me@fx ] || bad="$bad get=$(ogit.config.get user.email any "$w")"
  [ "$(ogit.config.email.get "$w")" = me@fx ] || bad="$bad email"
  git config --global user.email glob@fx
  [ "$(ogit.config.get user.email any "$w")" = glob@fx ] || bad="$bad get-any-not-global-first"
  [ "$(ogit.config.get user.email local "$w")" = me@fx ] || bad="$bad get-local=$(ogit.config.get user.email local "$w")"
  git config --global --unset user.email
  ogit.safeDirectory.add "$w" >/dev/null 2>&1; ogit.safeDirectory.add "$w" >/dev/null 2>&1
  [ "$(ogit.safeDirectory.list | grep -cx "$w")" = 1 ] || bad="$bad add-not-idempotent"
  mkdir -p "$fx/base/main/.git" "$fx/base/prod/.git" "$fx/base/notarepo" "$fx/base/.hidden/.git"
  ln -s "$fx/base/main" "$fx/base/alias"
  [ "$(private.ogit.base.folders.list "$fx/base" | tr '\n' ' ')" = "$fx/base/main $fx/base/prod " ] || bad="$bad folders=[$(private.ogit.base.folders.list "$fx/base" | tr '\n' ' ')]"
  ogit.safeDirectory.ensure "$fx/base" >/dev/null 2>&1 || bad="$bad ensure-rc"
  ogit.safeDirectory.list | grep -qx "$fx/base/main" || bad="$bad ensure-main"
  ogit.safeDirectory.list | grep -qx "$fx/base/prod" || bad="$bad ensure-prod"
  ogit.safeDirectory.list | grep -qx "$fx/base/notarepo" && bad="$bad ensure-took-nonrepo"
  ogit.safeDirectory.list | grep -qE "^$fx/base/(alias|\.hidden)$" && bad="$bad ensure-took-symlink-or-dotdir"
  ogit.safeDirectory.add "$fx/gone" >/dev/null 2>&1
  ogit.safeDirectory.prune >/dev/null 2>&1
  ogit.safeDirectory.list | grep -qx "$fx/gone" && bad="$bad prune-kept-missing"
  ogit.safeDirectory.list | grep -qx "$w" || bad="$bad prune-dropped-existing"
  ogit.safeDirectory.clear >/dev/null 2>&1; [ -z "$(ogit.safeDirectory.list)" ] || bad="$bad clear"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "config.get/set/email.get and safeDirectory.add/list/ensure/prune/clear behave" || create.result 1 "trust:$bad"
  return $(result)
}
test.case $level "T-OGIT-TRUST: config and safeDirectory nouns (sandboxed GIT_CONFIG_GLOBAL)" test.ogit.trust
expect 0 "config.get/set/email.get and safeDirectory.add/list/ensure/prune/clear behave" "config and safeDirectory nouns"
```

- [ ] **Step 2: Implement** (with the two private helpers § 0.3 assigns to this Task: `private.ogit.base.folders.list` — the one base-folder loop, reused by Tasks 19, 21, 22 — and `private.ogit.base.get`, the one default-base resolver, reused by Tasks 19-21):

```bash
private.ogit.base.get() # <?base> # echo <base>, else the components base: oo.mode.base.get when it is loaded in this shell, else the oo command #
{
 # Not `oo mode.base.get` unconditionally: that spawns a whole oo. Inside an
 # oo process (state 31, oo.update, the ooShim) the function is right here.
 if [ -n "$1" ]; then printf '%s\n' "$1"; return 0; fi
 { [ "$(type -t oo.mode.base.get)" = function ] && oo.mode.base.get; } 2>/dev/null || oo mode.base.get 2>/dev/null
}

private.ogit.base.folders.list() # <base> # echo every repository folder directly under <base> (a .git dir or file), one per line; symlinks and dot-dirs skipped (the oo:1093-1122 rules) #
{
 local base="$1" d
 { [ -n "$base" ] && [ -d "$base" ]; } || return 0
 for d in "$base"/*/; do
   d="${d%/}"
   [ -L "$d" ] && continue
   case "${d##*/}" in .*) continue ;; esac
   [ -e "$d/.git" ] || continue
   printf '%s\n' "$d"
 done
}

ogit.config.get()     # <key> <?scope:any> <?dir:$OOSH_DIR> # echo <key>: scope any = the global git config, else <dir>'s repository config; scope local = <dir>'s repository config only #
{
 local key="$1"
 local scope="${2:-any}"
 local dir="${3:-${OOSH_DIR:-.}}"
 case "$scope" in
   local) git -C "$dir" config --local --get "$key" 2>/dev/null ;;
   *)     git config --global --get "$key" 2>/dev/null || git -C "$dir" config --get "$key" 2>/dev/null ;;
 esac
}
ogit.config.get.completion.key()   { echo user.email; echo user.name; echo core.sharedRepository; }
ogit.config.get.completion.scope() { echo any; echo local; }

ogit.config.set()     # <key> <value> <?dir:$OOSH_DIR> # set <key> in <dir>'s repository config #
{
 private.ogit.require || return $(result)
 local dir="${3:-${OOSH_DIR:-.}}"
 if git -C "$dir" config "$1" "$2" 2>/dev/null; then create.result 0 "$1=$2"; else create.result 1 "could not set $1"; fi
 return $(result)
}
ogit.config.set.completion.key() { echo user.email; echo user.name; echo core.sharedRepository; }

ogit.config.email.get()     # <?dir:$OOSH_DIR> # echo the committer email: global user.email, else <dir>'s #
{
 ogit.config.get user.email any "$1"
}

ogit.safeDirectory.list()     # # echo the global safe.directory entries, one per line (honours GIT_CONFIG_GLOBAL) #
{
 git config --global --get-all safe.directory 2>/dev/null
}
ogit.safeDirectory.list.completion() { :; }

ogit.safeDirectory.add()     # <path> # add <path> to the global safe.directory list once (moved from private.oo.safeDirectory.add) #
{
 private.ogit.require || return $(result)
 if [ -z "$1" ]; then create.result 1 "ogit.safeDirectory.add: <path> required"; error.log "$RESULT"; return $(result); fi
 if ogit.safeDirectory.list | grep -qFx "$1"; then create.result 0 "already present: $1"
 elif git config --global --add safe.directory "$1"; then create.result 0 "added: $1"
 else create.result 1 "could not add safe.directory $1"; fi
 return $(result)
}

ogit.safeDirectory.clear()     # # remove every global safe.directory entry #
{
 git config --global --unset-all safe.directory 2>/dev/null
 create.result 0 "safe.directory cleared"; return $(result)
}
ogit.safeDirectory.clear.completion() { :; }

ogit.safeDirectory.prune()     # # drop global safe.directory entries whose paths no longer exist (moved from oo.safeDirectory.prune) #
{
 # A long list with stale /tmp/* paths makes the VS Code / Cursor git extension
 # hang validating each entry, leaving Source Control empty.
 local entry pruned=0; local -a kept=()
 while IFS= read -r entry; do
   [ -z "$entry" ] && continue
   if [ -e "$entry" ]; then kept+=("$entry"); else pruned=$((pruned + 1)); fi
 done < <(ogit.safeDirectory.list)
 if [ "$pruned" -gt 0 ]; then
   ogit.safeDirectory.clear >/dev/null
   local k; for k in "${kept[@]}"; do git config --global --add safe.directory "$k"; done
   console.log "Pruned $pruned stale safe.directory entries; ${#kept[@]} preserved"
 else
   info.log "No stale safe.directory entries to prune (${#kept[@]} present)"
 fi
 create.result 0 "pruned=$pruned kept=${#kept[@]}"; return $(result)
}
ogit.safeDirectory.prune.completion() { :; }

ogit.safeDirectory.ensure()     # <?base:$(oo.mode.base.get)> # one global safe.directory entry per repository folder under <base>, for the calling user; idempotent #
{
 private.ogit.require || return $(result)
 local base
 base=$(private.ogit.base.get "$1")
 if [ -z "$base" ] || [ ! -d "$base" ]; then create.result 1 "ogit.safeDirectory.ensure: no base (pass <base> or fix oo mode.base.get)"; error.log "$RESULT"; return $(result); fi
 local d added=0
 while IFS= read -r d; do
   ogit.safeDirectory.add "$d" >/dev/null || return $(result)
   case "$RESULT" in added:*) added=$((added + 1)) ;; esac
 done < <(private.ogit.base.folders.list "$base")
 create.result 0 "safe.directory ensured under $base ($added added)"; return $(result)
}
```
(`path` and `base` come from the shared block.)

- [ ] **Step 3: Aliases in `oo`** — replace the two bodies at `oo:397-461` with `replace block oo "<signature line>" "}" by "<new body>"` → `replace commit oo` → `replace cleanup oo` (§ 0.1), so they read:

```bash
oo.safeDirectory.prune() # # remove git safe.directory entries whose paths no longer exist on disk (delegates to ogit safeDirectory.prune)
{ private.this.script.load ogit ogit.branch.get; ogit.safeDirectory.prune "$@"; }

private.oo.safeDirectory.add() # <path> # idempotently add path to git's global safe.directory list (delegates to ogit safeDirectory.add)
{ private.this.script.load ogit ogit.branch.get; ogit.safeDirectory.add "$@"; }
```
`private.this.script.load` is the ONE loader, in the kernel since **Task M** — no ogit-specific loader is created. Rule 12 of § 0.5 applies to every consumer script from here on. Move the safeDirectory tests from `test/test.oo` to `test/test.ogit` (rename the method calls); keep in `test.oo` one case `T-SAFEDIR-DELEGATES` that asserts `declare -f oo.safeDirectory.prune | grep -q ogit.safeDirectory.prune`.

- [ ] **Step 4: Run** `./test.suite run ogit 1`, `./test.suite run oo 1` and `./test.suite run completion.audit 1` → PASS. **Commit** `feat(ogit): config and safeDirectory nouns — moved from oo, oo delegates`.

---

### Task 11: `worktree`, `binary`, `raw`

- [ ] **Step 1: Test (RED)**

```bash
test.ogit.worktree() {
  local fx bad="" w; fx=$(test.ogit.fixture worktree); w="$fx/work"
  git -C "$w" branch -q prod
  ogit.worktree.add prod "$fx/prod" origin/dev "$w" >/dev/null 2>&1 || bad="$bad add-rc=$?"
  [ -f "$fx/prod/.git" ] || bad="$bad add-shape"
  ogit.worktree.list "$w" | grep -qx "worktree $fx/prod" || bad="$bad list"
  [ "$(ogit.worktree.find prod "$w")" = "$fx/prod" ] || bad="$bad find=[$(ogit.worktree.find prod "$w")]"
  [ -z "$(ogit.worktree.find nosuch "$w")" ] || bad="$bad find-nosuch"
  [ "$(private.ogit.worktree.paths.get "$w" | tr '\n' ' ')" = "$fx/work $fx/prod " ] || bad="$bad paths=[$(private.ogit.worktree.paths.get "$w" | tr '\n' ' ')]"
  # a folder name with a space: the porcelain parse must not split it
  git -C "$w" branch -q spaced
  ogit.worktree.add spaced "$fx/with space" origin/dev "$w" >/dev/null 2>&1
  [ "$(ogit.worktree.find spaced "$w")" = "$fx/with space" ] || bad="$bad find-space=[$(ogit.worktree.find spaced "$w")]"
  ogit.worktree.delete "$fx/with space" "$w" >/dev/null 2>&1
  printf 'dirty\n' >> "$fx/prod/file"
  ogit.worktree.delete "$fx/prod" "$w" >/dev/null 2>&1 && bad="$bad delete-dirty-passed"
  git -C "$fx/prod" checkout -q -- file
  ogit.worktree.delete "$fx/prod" "$w" >/dev/null 2>&1 || bad="$bad delete-rc=$?"
  [ -e "$fx/prod" ] && bad="$bad delete-left-folder"
  ogit.worktree.prune "$w" >/dev/null 2>&1; [ "$(ogit.worktree.list "$w" | grep -c '^worktree ')" = 1 ] || bad="$bad prune"
  ogit.binary.check || bad="$bad binary"
  [ "$(ogit.raw "$w" rev-parse --abbrev-ref HEAD)" = dev ] || bad="$bad raw"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "worktree.add/list/find/delete/prune, binary.check, raw behave" || create.result 1 "worktree:$bad"
  return $(result)
}
test.case $level "T-OGIT-WORKTREE: worktree noun, binary.check, raw" test.ogit.worktree
expect 0 "worktree.add/list/find/delete/prune, binary.check, raw behave" "worktree noun"
```

- [ ] **Step 2: Implement**

```bash
private.ogit.worktree.paths.get() # <?dir:$OOSH_DIR> # echo the folder of every worktree of <dir>'s repository (the main one first), one per line; a path with spaces stays whole #
{
 # The one porcelain parse. `awk '{print $2}'` cut a path at its first space.
 local dir="${1:-${OOSH_DIR:-.}}"
 local l
 while IFS= read -r l; do
   case "$l" in 'worktree '*) printf '%s\n' "${l#worktree }" ;; esac
 done < <(ogit.worktree.list "$dir")
}

ogit.worktree.add()     # <branch> <targetDir> <startPoint> <?dir:$OOSH_DIR> # add <targetDir> as a linked worktree of <dir> with <branch> (re)created at <startPoint> #
{
 private.ogit.require || return $(result)
 local dir="${4:-${OOSH_DIR:-.}}"
 if git -C "$dir" worktree add -B "$1" "$2" "$3" 2>/dev/null && [ -d "$2" ]; then create.result 0 "worktree $2 on $1"
 else create.result 1 "git worktree add failed for $1 → $2"; fi
 return $(result)
}

ogit.worktree.list()     # <?dir:$OOSH_DIR> # git worktree list --porcelain of <dir>'s repository #
{
 local dir="${1:-${OOSH_DIR:-.}}"
 git -C "$dir" worktree list --porcelain 2>/dev/null
}

ogit.worktree.find()     # <branch> <?dir:$OOSH_DIR> # echo the folder that has <branch> checked out: a linked worktree of <dir>'s repository (Phase 2 adds the sibling clone <base>/<branch>); empty when none #
{
 local wt
 while IFS= read -r wt; do
   # symbolic-ref --short answers X exactly when the porcelain says "branch refs/heads/X".
   if [ "$(git -C "$wt" symbolic-ref -q --short HEAD 2>/dev/null)" = "$1" ]; then printf '%s\n' "$wt"; return 0; fi
 done < <(private.ogit.worktree.paths.get "$2")
 return 0
}

ogit.worktree.delete()     # <path> <?dir:$OOSH_DIR> # unregister and delete the linked worktree at <path> from <dir>'s repository (refuses a dirty one — gate first) #
{
 private.ogit.require || return $(result)
 local dir="${2:-${OOSH_DIR:-.}}"
 if git -C "$dir" worktree remove "$1" 2>/dev/null; then create.result 0 "worktree $1 removed"; else create.result 1 "git worktree remove $1 failed (dirty, or not a linked worktree)"; fi
 return $(result)
}

ogit.worktree.prune()     # <?dir:$OOSH_DIR> # drop worktree registrations whose folders are gone #
{
 private.ogit.require || return $(result)
 local dir="${1:-${OOSH_DIR:-.}}"
 git -C "$dir" worktree prune 2>/dev/null; create.result 0 "worktrees pruned"; return $(result)
}

# ogit.binary.check already exists — created in Task 1 (35d44b7) so that
# private.ogit.require could delegate to it from the start. Do not add it again.

ogit.raw()     # <dir> <args...> # run git -C <dir> <args...> verbatim — the documented last resort; every use needs a comment saying why no method fits; variadic, so <dir> comes first #
{
 private.ogit.require || return $(result)
 local dir="$1"
 shift
 git -C "$dir" "$@"
}
```
(`branch`, `targetDir`, `startPoint`, `path`, `dir` come from the shared block; `args` is exempt.)

- [ ] **Step 3: Run** `ogit` and `completion.audit` suites → PASS. **Commit** `feat(ogit): worktree noun (add/list/find/delete/prune), binary.check, raw`.

---

### Task 12: Aliases in `this` and `promote`; re-aim the grep-pins

**Files:** `this:903-943`, `promote:277-316`, `test/test.ossh:715-750`, `test/test.this:194-254`, `test/test.promote` (alignment cases)

- [ ] **Step 1: Test (RED)** in `test/test.this`: replace the `this.git.commits.count` cases' direct expectations with one delegation case:

```bash
test.this.gitAliasesDelegate() {
  local bad=""
  declare -f this.git.branch.short | grep -q 'ogit.branch.get'    || bad="$bad branch.short"
  declare -f this.git.commits.count | grep -q 'ogit.commit.count' || bad="$bad commits.count"
  local fx; fx=$(test.suite.fixture.make alias); git init -q -b dev "$fx"; git -C "$fx" -c user.email=t@t -c user.name=t commit -q --allow-empty -m seed
  [ "$(this.git.branch.short "$fx")" = dev ] || bad="$bad branch.short-answer"
  this.git.commits.count "$fx" dev dev >/dev/null; [ "$RESULT" = 0 ] || bad="$bad commits.count-answer=$RESULT"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "this.git.* delegate to ogit and still answer" || create.result 1 "aliases:$bad"
  return $(result)
}
test.case $level "T-THIS-GIT-ALIASES: this.git.branch.short / commits.count delegate to ogit" test.this.gitAliasesDelegate
expect 0 "this.git.* delegate to ogit and still answer" "callers outside this tree keep working"
```

- [ ] **Step 2: Implement in `this`** (replace `this.git.branch.short` and `this.git.commits.count` bodies with `replace block this "<signature line>" "}" by "<new body>"` → `replace commit this` → `replace cleanup this`; keep their docstrings and completions; `private.this.script.load` exists since Task M):

```bash
this.git.branch.short() # <?gitDir:$OOSH_DIR> # print the sanitised short branch name of <gitDir> (delegates to ogit branch.get)
{ private.this.script.load ogit ogit.branch.get; ogit.branch.get "$@"; }

this.git.commits.count() # <gitDir> <fromRef> <toRef> # count commits in <toRef> not in <fromRef>; RESULT = count (delegates to ogit commit.count)
{ private.this.script.load ogit ogit.branch.get; ogit.commit.count "$2" "$3" "$1"; }
```
Note the argument order flip: `this.git.commits.count <gitDir> <from> <to>` → `ogit.commit.count <from> <to> <dir>`.

- [ ] **Step 3: `promote.branch.alignment`** becomes the alias `{ private.this.script.load ogit ogit.branch.get; ogit.branch.compare "$1" "$2" "$OOSH_DIR"; }` (via `replace block promote …`, keeping its docstring). The body already lives in `ogit.branch.compare` since Task 4 — nothing to paste.

- [ ] **Step 4: Re-aim pins**
  - `test/test.ossh:720-735` (T-BRANCH-SHORT-STRIP-*): `BRANCH_BODY=$(declare -f ogit.branch.get 2>/dev/null)` after `private.this.script.load ogit ogit.branch.get` — the four `${b#…}` strips are asserted there.
  - `test/test.ossh:738-748` (T-BRANCH-SHORT-CALLER): accept either name: `grep -qE 'this\.git\.branch\.short|ogit\.branch\.get'`.
  - `test/test.promote` alignment cases: call `promote.branch.alignment` as before (alias) — they should pass unchanged; if a case greps the body, point it at `ogit.branch.compare`.

- [ ] **Step 5: Run** `this`, `ossh`, `promote`, `ogit` suites → PASS. Re-check `test/test.this:212-254` (T-GIT-COUNT-*) explicitly: `this.git.commits.count` always prefixed `refs/heads/`, `ogit.commit.count` does so only for bare names — the cases (and promote:293-294) pass bare names, so the answers must be identical. **Commit** `refactor(this,promote): git wrappers delegate to ogit; pins re-aimed`.

---

### Task 13: `ogit caller.validate` — the sweep as a production validator, and its planted twin

**Files:** `ogit`, `test/test.ogit`

The sweep is **not** a test-only helper: it is a validator in the family of `path.validate` (path:8-129), `private.this.anchor.validate.one` (this:227-314) and `test.suite.portability.validate` (test.suite:1227-1400) — read those three first and mirror their shape. The tests only call it.

- [ ] **Step 1: Scaffold**

```bash
printf '%s\n' '<?treeRoot:$OOSH_DIR>' \
  'verify ogit is the only caller of the git binary in the tracked tree: every other raw git call carries a comment-anchored ogit-exception marker; echo an OK:/INVALID: verdict; rc 1 on any violation' \
  'T-OGIT-ONLY-CALLER: no raw git invocation outside ogit' '' '' \
  | LOG_LEVEL=1 ./oo method.new ogit.caller.validate
```
Delete the generated `ogit.caller.validate.completion.treeRoot` stub — `ogit.parameter.completion.treeRoot` (Task 3) serves it.

- [ ] **Step 2: Tests (RED)** — replace the stub case in `test/test.ogit`:

```bash
# ============================================================================
# T-OGIT-ONLY-CALLER: no raw `git` invocation outside ogit (ogit caller.validate)
# ============================================================================
test.ogit.onlyCaller() {
  local out rc
  out=$(ogit.caller.validate "$OOSH_DIR"); rc=$?
  if [ "$rc" = 0 ]; then create.result 0 "ogit is the only git caller"
  else create.result 1 "$out — the sites are listed by: LOG_LEVEL=1 ./ogit caller.validate"; fi
  return $(result)
}
test.case $level "T-OGIT-ONLY-CALLER: no raw git invocation outside ogit (marked exceptions aside)" test.ogit.onlyCaller
expect 0 "ogit is the only git caller" "D2 of the 2026-09-23 design"

# The validator must be able to fail: planted violations in one fixture tree,
# only sanctioned exceptions in another, and a tree git cannot read at all.
test.ogit.onlyCallerRejects() {
  local bad="" out rc fx1 fx2 fx3
  fx1=$(test.suite.fixture.make plantbad); git init -q "$fx1"
  printf '%s\n' '#!/usr/bin/env bash' 'x=$(git rev-parse HEAD)' > "$fx1/planted"
  # a marker inside a STRING is not a comment, and an echo on the same line excuses nothing
  printf '%s\n' '#!/usr/bin/env bash' 'echo "ogit-exception: a string"; y=$(git log -1)' > "$fx1/fake"
  # a marker six lines above is outside the 5-line window
  printf '%s\n' '#!/usr/bin/env bash' '# ogit-exception: too far above' 'a=1' 'b=2' 'c=3' 'd=4' 'e=5' 'git status' > "$fx1/far"
  git -C "$fx1" add planted fake far; git -C "$fx1" -c user.email=t@t -c user.name=t commit -q -m plant
  out=$(ogit.caller.validate "$fx1"); rc=$?
  [ "$rc" = 1 ] || bad="$bad planted-rc=$rc"
  case "$out" in "INVALID: "*"3 violation(s), 0 exception(s)"*) ;; *) bad="$bad planted=[$out]" ;; esac

  fx2=$(test.suite.fixture.make plantok); git init -q "$fx2"
  # the marker three lines above counts (5-line window); the file marker counts anywhere
  printf '%s\n' '#!/usr/bin/env bash' '# ogit-exception: fixture proves the 5-line window' 'a=1' 'b=2' 'y=$(git status)' > "$fx2/excused"
  printf '%s\n' '#!/usr/bin/env bash' '# ogit-exception-file: fixture proves the file marker' 'git fetch origin' > "$fx2/filemarked"
  git -C "$fx2" add excused filemarked; git -C "$fx2" -c user.email=t@t -c user.name=t commit -q -m excuse
  out=$(ogit.caller.validate "$fx2"); rc=$?
  [ "$rc" = 0 ] || bad="$bad excused-rc=$rc"
  case "$out" in "OK: "*"2 exception(s)"*) ;; *) bad="$bad excused=[$out]" ;; esac

  # no repository: reading nothing must not report OK
  fx3=$(test.suite.fixture.make plantnone); printf 'git status\n' > "$fx3/loose"
  out=$(ogit.caller.validate "$fx3"); rc=$?
  [ "$rc" = 2 ] || bad="$bad unreadable-rc=$rc"
  case "$out" in "INVALID: cannot read"*) ;; *) bad="$bad unreadable=[$out]" ;; esac

  rm -rf "$fx1" "$fx2" "$fx3"
  [ -z "$bad" ] && create.result 0 "caller.validate rejects planted calls, honours comment-anchored markers, refuses an unreadable tree" || create.result 1 "caller.validate:$bad"
  return $(result)
}
test.case $level "T-OGIT-ONLY-CALLER-REJECTS: caller.validate catches planted raw git and honours ogit-exception" test.ogit.onlyCallerRejects
expect 0 "caller.validate rejects planted calls, honours comment-anchored markers, refuses an unreadable tree" "a validator that cannot fail proves nothing"
```

- [ ] **Step 3: Implement** in `ogit`:

```bash
ogit.caller.validate()     # <?treeRoot:$OOSH_DIR> # verify ogit is the only caller of the git binary in the tracked tree: every other raw git call carries a comment-anchored ogit-exception marker; echo an OK:/INVALID: verdict; rc 1 on any violation #
{
  # THE RULE (D2 of docs/superpowers/specs/2026-09-23-ogit-clones-per-branch-design.md):
  # ogit is the single caller of the git binary. Every other invocation is a
  # violation unless it carries `# ogit-exception: <reason>` on the line or in
  # the 5 lines above it (these calls often sit inside a heredoc or a `bash -c`
  # string, where the marker cannot go on the line), or
  # `# ogit-exception-file: <reason>` anywhere in the file (init/oosh, init/once,
  # Install oosh.command — they run before oosh exists).
  #
  # Sibling of path.validate and private.this.anchor.validate.one, same shape:
  # one scan of the tracked tree, markers anchored to a COMMENT, the verdict
  # echoed to stdout (it survives any LOG_LEVEL — the status-output idiom),
  # each violation named by error.log, create.result / return $(result).
  local treeRoot="${1:-$OOSH_DIR}"
  if [ ! -d "$treeRoot" ]; then
    error.log "ogit.caller.validate: no such directory: $treeRoot"
    echo "INVALID: no such directory: $treeRoot"
    create.result 2 "no such directory: $treeRoot"
    return $(result)
  fi

  # A sweep that reads nothing reports OK: no repository, or git's "dubious
  # ownership" refusal (root in a container against an oosh-user tree), both
  # come back empty — indistinguishable from a clean tree. Prove git can see
  # the files BEFORE trusting that it found nothing in them (test.suite:1261-1274).
  if [ -z "$(ogit.repo.files.list "$treeRoot" | head -1)" ]; then
    error.log "ogit.caller.validate: git cannot list tracked files under $treeRoot — no repository, or ownership refused (ogit safeDirectory.ensure). A sweep that reads nothing reports OK, so this is a failure, not a pass."
    echo "INVALID: cannot read $treeRoot through git — no tracked files visible"
    create.result 2 "git sees no tracked files under $treeRoot"
    return $(result)
  fi

  # ONE scan of the tracked tree. Excluded on purpose, as in path.validate:
  #   ogit                                  — it IS the caller
  #   docs/  test/  .claude/  *.md  *.json  — prose, fixtures, tool config
  #   old/  restore/                        — the legacy graveyards
  # init/oosh, init/once and Install oosh.command are NOT excluded here: they
  # carry `# ogit-exception-file:`, so the reason lives in the file itself.
  # The leading class keeps ogit, .git, digit, _git and path/git out; a word
  # after the whitespace is required, so prose like "git." never matches.
  local matches
  matches=$(ogit.repo.grep '(^|[^A-Za-z0-9_./-])git[[:space:]]+[a-z-]+' "$treeRoot" \
              ':!ogit' ':!docs' ':!test' ':!.claude' ':!old' ':!restore' ':!*.md' ':!*.json')

  local exceptions=0 violations=0
  local match file lineNo content trimmed prevLine windowFrom
  while IFS= read -r match; do
    [ -z "$match" ] && continue
    file="${match%%:*}"
    content="${match#*:}"
    lineNo="${content%%:*}"
    content="${content#*:}"

    # A line that only TALKS about git is not an invocation.
    trimmed="${content#"${content%%[![:space:]]*}"}"
    case "$trimmed" in '#'*) continue ;; esac

    # Sanctioned exception, anchored to a COMMENT so a marker only counts where
    # a human wrote one: on the line, file-wide, or in the 5 lines above.
    if printf '%s' "$content" | grep -qE '#[[:space:]]*ogit-exception:'; then
      exceptions=$((exceptions + 1)); continue
    fi
    if grep -qE '^[[:space:]]*#[[:space:]]*ogit-exception-file:' "$treeRoot/$file" 2>/dev/null; then
      exceptions=$((exceptions + 1)); continue
    fi
    prevLine=""
    if [ "$lineNo" -gt 1 ]; then
      windowFrom=$((lineNo - 5))
      [ "$windowFrom" -lt 1 ] && windowFrom=1
      prevLine=$(sed -n "${windowFrom},$((lineNo - 1))p" "$treeRoot/$file" 2>/dev/null)
    fi
    if printf '%s' "$prevLine" | grep -qE '#[[:space:]]*ogit-exception:'; then
      exceptions=$((exceptions + 1)); continue
    fi

    error.log "ogit.caller.validate: $file:$lineNo calls git directly — use an ogit method: $trimmed"
    violations=$((violations + 1))
  done <<< "$matches"

  if [ "$violations" -gt 0 ]; then
    error.log "ogit.caller.validate: $violations violation(s); ${YELLOW}ogit${NORMAL} is the only git caller (docs/ogit.md). Call the ogit method, or mark a genuine exception with '# ogit-exception: <reason>'"
    echo "INVALID: git callers in $treeRoot — $violations violation(s), $exceptions exception(s)"
    create.result 1 "git callers: violations found"
    return $(result)
  fi
  echo "OK: git callers in $treeRoot — only ogit, $exceptions exception(s), 0 violations"
  create.result 0 "git callers: 0 violations"
  return $(result)
}
```
(Not filtered, on purpose: `echo |printf |\.log` on the line. The first draft dropped those lines unanchored, which let `x=$(git …); echo` through. A printed hint that names a git command gets a marker, like `myId:84` in Task 17.)

- [ ] **Step 4: Run** `./test.suite run ogit 1` → `T-OGIT-ONLY-CALLER` FAILS with `INVALID: … ≈260 violation(s)` (≈220 outside `init/oosh`/`init/once`, which get their file markers in Task 17; counted at 9b69114 with the pattern above, printed hints included — this is the RED that Tasks 14-17 turn green; `LOG_LEVEL=1 ./ogit caller.validate` lists them); `-REJECTS` PASSES. `./test.suite run completion.audit 1` → PASS. **Commit** `feat(ogit): caller.validate — the only-caller rule as a production validator, red against the current tree`.

---

### Task 14: Migrate `this`, `path`, `test.suite`, `config`, `os`, `claudeCode`, `osshLayout`

Each site: replace the call, keep behaviour, run that file's tests. The command form is needed only where a function is not in scope; everywhere else the method that calls `ogit.*` starts with `private.this.script.load ogit ogit.branch.get` (the kernel loader from Task M).

| Site | Before | After |
|---|---|---|
| this:246 `private.this.anchor.validate.one` | `git -C "$treeRoot" grep -nE "$pattern" -- <pathspecs>` | `private.this.script.load ogit ogit.branch.get; ogit.repo.grep "$pattern" "$treeRoot" <pathspecs>` |
| path:54 `path.validate` | `git -C "$treeRoot" grep -nE 'PATH=' -- …` | `private.this.script.load ogit ogit.branch.get; ogit.repo.grep '(^\|[^A-Za-z0-9_])PATH=' "$treeRoot" …` (keep the exact pattern that is there) |
| test.suite:1269 | `git -C "$root" ls-files \| head -1` | `ogit.repo.files.list "$root" \| head -1` |
| test.suite:1310 | `git -C … grep -nE "$pattern" …` | `ogit.repo.grep "$pattern" "$root" …` |
| config:280, user:973 | already `this.git.branch.short` | unchanged (alias) |
| os:107 | `git rev-parse --abbrev-ref HEAD` | `ogit.branch.get "$PWD"` |
| claudeCode:1439, 1503 | `git rev-parse --show-toplevel` | `ogit.repo.root.get` |
| osshLayout:47-49 | `command -v git`, `git config --global user.email \|\| git config user.email` | `ogit.binary.check`, `ogit.config.email.get "$PWD"` |

- [ ] Run: `./test.suite run this 1; run path 1; run test.suite 1; run config 1; run os 1; run claudeCode 1; run osshLayout 1` → PASS; `./path validate`, `./this anchor.validate all`, `./test.suite portability.validate` → OK; `LOG_LEVEL=1 ./ogit caller.validate` → the violation count drops by these sites.
- [ ] Commit `refactor: this/path/test.suite/os/claudeCode/osshLayout call ogit`.

---

### Task 15: Migrate `oo` (≈50 sites, behaviour identical)

**Files:** `oo`; tests `test/test.oo`

Every method below that calls `ogit.*` gets `private.this.script.load ogit ogit.branch.get` as its first line. The ooShim (which sources `this` and `oo`, then calls `oo.mode`) needs no change: the loader inside `oo.mode` does the work.

| Line(s) | Before | After |
|---|---|---|
| 253 `oo.commit` | `git branch \| line find "\*"` | `ogit.branch.get` (compare to `dev`) |
| 257-259 | `git add *; git commit; git push` | `ogit.index.add all; ogit.commit.create; ogit.remote.push` — note: `add *` skipped dotfiles, `all` uses `-A`; verify `git status` shows only ignored dotfiles before committing this change |
| 274, 288, 291 `oo.update` | `git pull`; `git symbolic-ref --short HEAD`; `git pull $url $branch` | `ogit.remote.pull "" "" "$OOSH_DIR"`; `ogit.branch.get`; `ogit.remote.pull "$fallbackUrl" "$branch" "$OOSH_DIR"` |
| 540 `oo.mode.base.get` | `git -C "$ooshDir" worktree list --porcelain \| head -1 \| sed …` | `ogit.worktree.list "$ooshDir" \| head -1 \| sed 's/^worktree //'` |
| 627, 629 `oo.mode.list` | `(cd "$dir" && git status --short --branch)` | `ogit.status.show short "$dir"` (T-MODE-NOLEAK must still pass: no safe.directory writes) |
| 673, 681, 683 `oo.branch.list` | `branch --format`, `fetch origin`, `branch -r` | `ogit.branch.list local`, `ogit.remote.fetch no "$OOSH_DIR"`, `ogit.branch.list remote` |
| 740, 745 `oo.mode` | `status --short --branch`, `branch --show-current` | `ogit.status.show short "$current_target"`, `ogit.branch.get "$current_target"` |
| 792 | `git branch -r \| … grep -Fx "origin/$branch"` | `ogit.branch.list remote "$current_target" \| grep -Fx "$branch"` (then `remote_branch="origin/$branch"`) |
| 802 | `git worktree add -B … "$target_dir" "$remote_branch"` | `ogit.worktree.add "${remote_branch#origin/}" "$target_dir" "$remote_branch" "$current_target"` — keep the error text `git worktree add failed for` (test.oo:470 pins it) |
| 893, 910 `oo.mode.align` | `branch --show-current`, `checkout` | `ogit.branch.get`, `ogit.branch.checkout` |
| 1160, 1165 `oo.checkout` | `branch --show-current`, `checkout "$dirName"` | `ogit.branch.get "$targetDir"`, `ogit.branch.checkout "$dirName" "$targetDir"` |
| 1189, 1191 | `fetch origin`, `worktree add -B "$dirName" "$targetDir" "origin/$version"` | `ogit.remote.fetch no "$oosh"`, `ogit.worktree.add "$dirName" "$targetDir" "origin/$version" "$oosh"` |
| 1203, 1228, 1230 | `remote get-url origin`, `fetch origin`, `clone "$repoUrl" -b "$version" "$targetDir"` | `ogit.remote.url.get origin "$oosh"`, `ogit.remote.fetch no "$oosh"`, `ogit.repo.clone "$repoUrl" "$version" "$targetDir"` (it removes a half-made dir it created itself, and refuses a non-empty target — drop the `rm -rf`) |
| 1256, 1260 completion | `ls-remote --heads origin`, `for-each-ref refs/remotes/origin` | `ogit.remote.branch.list origin "$oosh"`, fallback `ogit.branch.list remote "$oosh"` — re-aim test.oo:2179-2184 to grep for `ogit.remote.branch.list` and `ogit.branch.list remote` |
| 1357-1408 `oo.branches.check` | `fetch --prune`, `show`, `branch -a --contains`, `log -1 --pretty=format:…`, `merge-base`, `diff --stat A...B` | `ogit.remote.fetch yes "$OOSH_DIR"`, `ogit.commit.show`, `ogit.branch.find`, `ogit.commit.log.show "$bl" 1 '%cn/%cr/%H'`, `ogit.merge.base.get`, `ogit.diff.show "$bl" "$base" stat` |
| 1668-1701 `private.oo.shared.tree.from.local` | `rev-parse --verify`, `checkout -B`, `checkout main`, `rev-parse --git-dir`, `worktree add` ×2 | `ogit.branch.check main main`, `ogit.branch.check origin/main main`, `ogit.branch.reset main origin/main main`, `ogit.branch.checkout main main`, `ogit.repo.check main`, `ogit.worktree.add "$branch" "../$branch" "$branch" main \|\| ogit.worktree.add "$branch" "../$branch" "origin/$branch" main` |
| 2022, 2051, 2065 state 31 | `git clone git@github.com:… main`, `git fetch origin`, `git worktree add -B …` | `ogit.repo.clone git@github.com:Cerulean-Circle-GmbH/once.sh.git main main`, `ogit.remote.fetch no "$PWD"`, `ogit.worktree.add "$OOSH_BRANCH" "../$OOSH_BRANCH" "origin/$OOSH_BRANCH" "$PWD"` (keep the `RETURN_VALUE` checks and messages) |
| 2146 | `git -C "$_wt" config core.sharedRepository group` | `ogit.config.set core.sharedRepository group "$_wt"` |
| 2152-2170 | the `osascript POSIX path` canonical-case idiom, twice | `resolvedOoshDir=$(private.this.path.case.get "$onceShBase/${OOSH_BRANCH}")`, `resolvedMainDir=$(private.this.path.case.get "$onceShBase/main")` (Task M; same answer) |
| 2539 `oo.install.dev` | `call git clone git@github.com:…` inside the `check … call` DSL | `call ogit repo.clone git@github.com:… <branch> <dir>` |
| 418-457 | done in Task 10 | — |

- [ ] Run `./test.suite run oo 1` → PASS (fix any re-aimed pin listed above). Also `LOG_LEVEL=1 ./ogit caller.validate` shrinks by ≈76 (oo's non-comment hits at 9b69114).
- [ ] Commit `refactor(oo): every git call goes through ogit`.

---

### Task 16: Migrate `promote` (≈55 sites, behaviour identical)

**Files:** `promote`; tests `test/test.promote`

Every `private.check.*` and `promote.*` method below that calls `ogit.*` gets `private.this.script.load ogit ogit.branch.get` as its first line (promote is also merely sourced by test.promote).

| Line(s) | Before | After |
|---|---|---|
| 263-265 `promote.status` | `log -1 --format='%h %ci' refs/heads/X` | `ogit.commit.log.show refs/heads/X 1 '%h %ci' "$OOSH_DIR"` |
| 325, 329 `promote.report` | `tag -l 'testing-*' --sort=-creatordate --format=…` | `ogit.tag.list 'testing-*'` / `'v*'` (then format with `ogit.commit.log.show <tag> 1 '<format>'` if the original `--format` printed more than the name — check promote:325-333 and keep the output identical) |
| 489 | `status --porcelain` | `ogit.status.show porcelain "$OOSH_DIR"` |
| 611, 869 | `log --oneline testing..dev` / `prod..testing` | `ogit.commit.log.show testing..dev "" oneline "$OOSH_DIR"` |
| 628, 643-652 `rewrite.self.branch` | `branch --show-current`, `diff --quiet -- files`, `add files`, `-c … commit -m … -q` | `ogit.branch.get "$dir"`, `ogit.diff.check "$dir" init/oosh "Install oosh.command"`, `ogit.index.add all "$dir" init/oosh "Install oosh.command"`, `ogit.commit.create "chore(promote): …" oosh-promote@local "oosh promote" "$dir"` |
| 660 `find.worktree` | body | `ogit.worktree.find "$branch" "$ooshDir"` |
| 682, 684 `push.source.branch` | `remote get-url origin`, `push origin $b` | `[ -n "$(ogit.remote.url.get origin "$ooshDir")" ] \|\| return 0`; `ogit.remote.push "$sourceBranch" no "$ooshDir"` |
| 706-735 conflict helper | `branch --show-current`, `diff --name-only --diff-filter=U`, `checkout --theirs`, `add`, `-c … commit` | `ogit.branch.get`, `ogit.conflict.list`, `ogit.conflict.resolve "$f" theirs`, `ogit.commit.create "Merge …" oosh-promote@local "oosh promote" "$dir"` |
| 751-792, 893-960 both merges | `diff --quiet`, `stash push -q -m`, `stash pop -q`, `checkout X`, `-c … merge X --no-edit`, `merge --abort` | `ogit.diff.check "$OOSH_DIR"`, `ogit.stash.push "promote: pre-merge stash" "$OOSH_DIR"`, `ogit.stash.pop "$OOSH_DIR"`, `ogit.branch.checkout testing "$OOSH_DIR"`, `ogit.branch.merge dev oosh-promote@local "oosh promote" "$mergeDir"`, `ogit.merge.abort "$mergeDir"` |
| 809, 814 | `tag -l "$tag" \| grep -q`, `tag "$tag"` | `ogit.tag.check "$tag" "$OOSH_DIR"`, `ogit.tag.create "$tag" HEAD "$OOSH_DIR"` |
| 829, 1024 | `push origin testing --tags` | `ogit.remote.push testing yes "$OOSH_DIR"` |
| 830, 1025 | `checkout dev` | `ogit.branch.checkout dev "$OOSH_DIR"` (test.promote:494 greps `checkout dev` — still matches) |
| 832-833, 1027-1028 | `stash list \| head -1 \| grep -q "promote: pre-merge stash"` then pop | `case "$(ogit.stash.top.get "$OOSH_DIR")" in *"promote: pre-merge stash"*) ogit.stash.pop "$OOSH_DIR" ;; esac` |
| 976, 1009 | `tag -l 'v*' --sort=-version:refname \| head -1`, `tag "$newTag" prod` | `ogit.tag.latest.get 'v*' "$OOSH_DIR"`, `ogit.tag.create "$newTag" prod "$OOSH_DIR"` |
| `GIT_PAGER` save/restore (218-331) | keep | keep (not an invocation) |

- [ ] Run `./test.suite run promote 1` → PASS. Commit `refactor(promote): every git call goes through ogit`.

---

### Task 17: Migrate `user`, `ossh`, `hiveMind`, `scrumMaster`, `context`, `agentRoom`, `snet`, `otest`, `myId`, `Install oosh.command`

| Site | After |
|---|---|
| user:1070, 1075 (`private.as.user $u git config --global --add safe.directory …`) | command form through the as-user preamble: `private.as.user "$username" bash -c "$(private.this.as.user.preamble.get "$username" "$targetHome" "$sharedOosh")"$'\n'"'$sharedOosh/ogit' safeDirectory.add '$sharedOosh'"`; the osascript canonical-case variant becomes `canonicalOosh=$(private.this.path.case.get "$sharedOosh")` (Task M) and, when it differs, the same hop with `'$canonicalOosh'` (Task 23 folds both into one `safeDirectory.ensure` hop) |
| user:1154 | `_ownerEmail=$(private.as.user "$username" bash -c "$(private.this.as.user.preamble.get "$username" "$targetHome" "$sharedOosh")"$'\n'"'$sharedOosh/ogit' config.email.get" 2>/dev/null) \|\| true` |
| ossh:580-581 | `private.this.script.load ogit ogit.branch.get; ogit.config.email.get "$PWD"` |
| ossh:640 (remote jump host) | `ossh.exec "$jumpHost" "command -v ogit >/dev/null 2>&1 && ogit config.email.get \|\| git config --global user.email \|\| git config user.email"` with `# ogit-exception: jump host may have no oosh` on the line above |
| ossh:1180, 1187 | `ogit.binary.check`, `ogit.remote.url.get origin "$repo"` |
| hiveMind ×11 `rev-parse --show-toplevel` | `private.this.script.load ogit ogit.branch.get; ogit.repo.root.get` |
| hiveMind:1753 (remote) | `ossh exec "$host" "~/oosh/ogit remote.pull"` |
| hiveMind:4060-4069 auto.commit | `ogit.status.check && return 0`; `ogit.index.add updated`; `ogit.commit.create "$msg"`; `ogit.remote.push "" no "$dir" &` |
| hiveMind:4126-4208, scrumMaster:643-741, 1444 | `ogit.branch.get`, `ogit.commit.log.show "" 1 oneline`, `ogit.status.check`, `ogit.commit.log.show "" 5 oneline`, `ogit.commit.log.show --since=midnight "" oneline \| wc -l` (pass `--since=midnight` as `<range>`) |
| hiveMind:4888-4889, 5102-5103 | `ogit.index.add all "$ws" <files>`; `ogit.commit.create "<msg>" "" "" "$ws"` (note `add -f` at 4888: use `ogit.raw "$ws" add -f <file>` with a comment, or drop `-f` if the file is not ignored — check `.gitignore` first) |
| scrumMaster:14 (source-time) | `: ${SCRUMMASTER_METRICS_DIR:=}` at file scope and resolve lazily in `private.scrumMaster.metrics.dir.get` → `ogit.repo.root.get`; grep every reader of `SCRUMMASTER_METRICS_DIR` and route through that getter |
| context ×5 | `ogit.repo.root.get` |
| agentRoom:158, 177 | `ogit.repo.clone https://github.com/baryhuang/claude-code-by-agents.git main "$dir"`, `ogit.remote.pull "" "" "$dir"` |
| snet:56 | `ogit.remote.pull "" "" "$PWD"` |
| otest:120-125, 409 | `ogit.branch.get`, `ogit.branch.checkout`, `ogit.branch.merge`, `ogit.remote.push`, `ogit.branch.list local` — on the EAMD.ucp repo dir |
| otest:131 (docker container) | keep raw; `# ogit-exception: runs inside a container without oosh` on the line above |
| myId:84 (`myId.create.github.deploy.key`) | the one hit is inside a multi-line `echo "check out with … git clone \"$sshConfigName.$idName:$project\""` — a **printed hint** for the user, not an invocation. Keep it; put `# ogit-exception: printed hint for the user, not an invocation` on its own line directly above the `echo "check out with` line (the `git clone` line is then inside the 5-line window) |
| `Install oosh.command` | read it: a macOS double-click wrapper that runs `./init/oosh` or downloads it with curl/wget/fetch — it runs **before bash-mode oosh exists**, so it can never call ogit. Today it has **no** git invocation (only `github.com` URLs, which the pattern does not match); mark it anyway so a future call is judged by its stated reason: `# ogit-exception-file: macOS double-click installer wrapper, runs before oosh exists` as the second line (after the shebang) |
| init/oosh, init/once | `# ogit-exception-file: POSIX sh, runs before bash and oosh exist` / `# ogit-exception-file: legacy once framework, out of scope` as the second line of each file |

- [ ] Run the suites of every touched script (`user`, `ossh`, `hiveMind`, `scrumMaster`, `context`, `agentRoom`, `snet`, `otest`, `myId`, `install`) → PASS. `LOG_LEVEL=1 ./ogit caller.validate` → `OK: git callers in … — only ogit, N exception(s), 0 violations`; `./test.suite run ogit 1` → `T-OGIT-ONLY-CALLER` PASSES. From here on `./ogit caller.validate` is one of the validators of rule 5. Commit `refactor: remaining scripts call ogit; caller.validate green`.

---

### Task 18: Docs, core gate, platform gate, push (end of Phase 1)

- [ ] **`docs/ogit.md`** shaped like `docs/odocker.md`: `# ogit — Git Wrapper for oosh`, `## Overview` (naming line `git→ogit`, the only-caller rule and its validator `ogit caller.validate`, `<?dir>` last — with the variadic exceptions `repo.grep`, `index.add`, `diff.check`, `raw`, where `<?dir>` precedes the list —, positional skipping with `""`, getters vs mutators, `ogit-exception` / `ogit-exception-file` markers and the 5-line window), `## Quick Start`, `## Methods` with one `| Method | Parameters | Description |` table per noun (copy the signatures from this plan), `## Layout` (Phase 2 fills it; for now: "worktrees today, see spec"), `## Troubleshooting` (dubious ownership → `ogit safeDirectory.ensure`; git missing → `oo cmd git`), `## See Also`. Embed the tree: `![ogit method tree](puml/ogit.tree/ogit.tree.drawio)` link.
- [ ] `docs/wiki-index.md`: `- [Git Wrapper (ogit)](ogit.md) - every git call in oosh; branch/remote/commit/tag/stash/trust nouns; worktree↔clone layout` under Infrastructure Tools. `CLAUDE.md` wrapper table: `| ogit | git | ogit branch.get, ogit remote.pull, ogit safeDirectory.ensure, ogit layout.status |`. `docs/oosh-architecture.md` § Key Scripts: `| ogit | The only git caller; docs/ogit.md |`.
- [ ] `./test.suite core 1` → all green (1 intentional meta-failure). Validators OK, including `./ogit caller.validate` and `./test.suite run completion.audit 1`.
- [ ] Commit `docs(ogit): docs/ogit.md, wiki, CLAUDE.md`. **Stop (Batch 5) and ask before pushing.** On the user's go: push `dev`; `os platform.test ubuntu_24_04` → PASS ×4 users.
- [ ] Record in `sessions/agent.context.md`: Phase 1 done, commit range, gate results.

---

# PHASE 2 — clone per branch folder

### Task 19: `ogit layout.status`

**Files:** `ogit`, `test/test.ogit`

- [ ] **Step 1: Fixture for a base** (add to test.ogit):

```bash
test.ogit.base() { # <label> <?shape:worktree> # echo <base> holding main + dev + prod as linked worktrees (shape worktree) or as clones (shape clone), all tracking <base>/origin.git; each folder ignores ignored.txt
  local fx; fx=$(test.suite.fixture.make "$1"); local base="$fx/Once.sh"; mkdir -p "$base"
  git init -q --bare -b main "$fx/origin.git"
  git init -q -b main "$base/main"; git -C "$base/main" remote add origin "$fx/origin.git"
  printf 'seed\n' > "$base/main/file"; printf 'ignored.txt\n' > "$base/main/.gitignore"
  git -C "$base/main" add file .gitignore
  # tick 0 of test.ogit.commit's clock, as in test.ogit.fixture
  GIT_COMMITTER_DATE="@1700000000 +0000" GIT_AUTHOR_DATE="@1700000000 +0000" \
    git -C "$base/main" -c user.email=t@t -c user.name=t commit -q -m seed
  git -C "$base/main" push -q -u origin main
  local b; for b in dev prod; do
    git -C "$base/main" branch -q "$b" main; git -C "$base/main" push -q origin "$b"
    if [ "${2:-worktree}" = clone ]; then git clone -q -b "$b" "$fx/origin.git" "$base/$b"
    else git -C "$base/main" worktree add -q "$base/$b" "$b" >/dev/null 2>&1; git -C "$base/$b" branch -q -u "origin/$b"; fi
  done
  echo "$base"
}
```

- [ ] **Step 2: Test (RED)**

```bash
test.ogit.layoutStatus() {
  local base bad="" out; base=$(test.ogit.base layoutwt)
  out=$(ogit.layout.status "$base")
  printf '%s\n' "$out" | grep -qE '^main[[:space:]]+clone' || bad="$bad main-line"
  printf '%s\n' "$out" | grep -qE '^dev[[:space:]]+worktree[[:space:]]+dirty 0[[:space:]]+ahead 0[[:space:]]+behind 0' || bad="$bad dev-line=[$(printf '%s\n' "$out" | grep '^dev')]"
  printf 'x\n' >> "$base/prod/file"; test.ogit.commit "$base/dev" local
  out=$(ogit.layout.status "$base")
  printf '%s\n' "$out" | grep -qE '^prod[[:space:]]+worktree[[:space:]]+dirty 1' || bad="$bad prod-dirty"
  printf '%s\n' "$out" | grep -qE '^dev[[:space:]]+worktree[[:space:]]+dirty 0[[:space:]]+ahead 1' || bad="$bad dev-ahead"
  ogit.layout.status "$base" >/dev/null || bad="$bad consistent-worktree-layout-rc=$?"
  # a mixed layout: prod becomes a clone while dev is still a worktree
  git -C "$base/prod" checkout -q -- file; git -C "$base/main" worktree remove "$base/prod"; git clone -q -b prod "$(dirname "$base")/origin.git" "$base/prod"
  ogit.layout.status "$base" >/dev/null && bad="$bad mixed-layout-rc0"
  rm -rf "$(dirname "$base")"
  base=$(test.ogit.base layoutcl clone)
  ogit.layout.status "$base" >/dev/null || bad="$bad clone-layout-rc=$?"
  rm -rf "$(dirname "$base")"
  [ -z "$bad" ] && create.result 0 "layout.status reports shape, dirty, ahead, behind per folder; rc 1 on a mixed layout" || create.result 1 "layout.status:$bad"
  return $(result)
}
test.case $level "T-OGIT-LAYOUT-STATUS: per-folder shape and freshness, rc 1 when mixed" test.ogit.layoutStatus
expect 0 "layout.status reports shape, dirty, ahead, behind per folder; rc 1 on a mixed layout" "the read-only view of the base"
```

- [ ] **Step 3: Implement**

```bash
private.ogit.gitdir() # <?dir:$OOSH_DIR> # echo the absolute .git directory of <dir>'s repository #
{
 local dir="${1:-${OOSH_DIR:-.}}"
 git -C "$dir" rev-parse --absolute-git-dir 2>/dev/null
}

private.ogit.folder.shape() # <folder> # echo worktree | clone | missing for <folder> #
{
 if   [ -f "$1/.git" ]; then echo worktree
 elif [ -d "$1/.git" ]; then echo clone
 else echo missing; fi
}

ogit.layout.status()     # <?base:$(oo mode.base.get)> # one line per folder under <base>: shape (worktree|clone), dirty/ahead/behind counts, shared/setgid/trusted; rc 1 when the folders are not all the same shape #
{
 # Status idiom: the answer is plain echo, never behind console.log.
 local base
 base=$(private.ogit.base.get "$1")
 if [ -z "$base" ] || [ ! -d "$base" ]; then echo "no base"; create.result 1 "ogit.layout.status: no base"; return $(result); fi
 local d name shape dirty ahead behind shared setgid trusted shapes="" rc=0
 while IFS= read -r d; do
   name="${d##*/}"
   shape=$(private.ogit.folder.shape "$d")
   shapes="$shapes $shape"
   dirty=$(ogit.status.show porcelain "$d" | grep -c .)
   if ogit.branch.check '@{u}' "$d"; then
     ogit.commit.count '@{u}' HEAD "$d" >/dev/null; ahead="$RESULT"
     ogit.commit.count HEAD '@{u}' "$d" >/dev/null; behind="$RESULT"
   else ahead='?'; behind='?'; fi
   # the folder's OWN repository value, not the global one (scope local, Task 10)
   [ "$(ogit.config.get core.sharedRepository local "$d")" = group ] && shared=group || shared=no
   [ -g "$(private.ogit.gitdir "$d")" ] && setgid=yes || setgid=no
   ogit.safeDirectory.list | grep -qFx "$d" && trusted=yes || trusted=no
   printf '%-14s %-9s dirty %-3s ahead %-3s behind %-3s shared=%s setgid=%s trusted=%s\n' "$name" "$shape" "$dirty" "$ahead" "$behind" "$shared" "$setgid" "$trusted"
 done < <(private.ogit.base.folders.list "$base")
 # main is always a clone; the OTHER folders must all share one shape.
 case "$shapes" in *worktree*clone*|*clone*worktree*) [ "$(printf '%s\n' $shapes | grep -c clone)" = 1 ] || rc=1 ;; esac
 if [ "$rc" = 0 ]; then create.result 0 "layout under $base is consistent"
 else create.result 1 "mixed layout under $base — finish ogit worktree.remove or worktree.restore"; fi
 return $(result)
}
```
(The "mixed" rule: `main` is a clone by definition, so a consistent worktree layout is `clone` + N×`worktree`, a consistent clone layout is all `clone`. Exactly one `clone` among worktrees → consistent; otherwise mixed. The folder loop is `private.ogit.base.folders.list` (Task 10): symlinks, dot-dirs and non-repositories never appear. `base` comes from the shared completer.) Every git call here is an ogit method or inside `ogit`, so `caller.validate` is satisfied.

- [ ] **Step 4: Run** `ogit` and `completion.audit` suites → PASS. **Commit** `feat(ogit): layout.status`.

---

### Task 20: `ogit worktree.remove` (worktrees → clones)

`git worktree remove` deletes the folder **with its gitignored files** (`dev/sessions/agent.context.md` on this host is one), and the folder gate does not see them. The conversion therefore carries them across (spec § 2.1): before a folder is touched its `!!` paths are copied into a timestamped backup directory `$HOME/.oosh.backups/<UTC-stamp>-ogit-<folder>` (the `user ssh.backup` shape — a directory, no tar), and copied back once the new folder is finished. The backup is kept; on any failure its path is in the recovery message. Tracked dirty work is still refused by the gate (D4).

- [ ] **Step 1: Test (RED)**

```bash
test.ogit.worktreeRemove() {
  local base bad="" fx; base=$(test.ogit.base wtrm); fx=$(dirname "$base")
  # local + export: sandboxed global git config, and the carry's backups land in the fixture, not in the real $HOME
  local GIT_CONFIG_GLOBAL="$fx/gitconfig"; export GIT_CONFIG_GLOBAL; : > "$GIT_CONFIG_GLOBAL"
  local HOME="$fx/home"; mkdir -p "$HOME"
  # an ignored file is not "dirty" to the gate — and must survive the conversion
  printf 'mine\n' > "$base/dev/ignored.txt"
  # refuse: dirty
  printf 'x\n' >> "$base/dev/file"
  ogit.worktree.remove "$base" >/dev/null 2>&1 && bad="$bad dirty-not-refused"
  case "$RESULT" in *dev*) ;; *) bad="$bad dirty-not-named=[$RESULT]" ;; esac
  [ -f "$base/dev/.git" ] || bad="$bad dirty-run-touched-dev"
  git -C "$base/dev" checkout -q -- file
  # refuse: unpushed
  test.ogit.commit "$base/prod" local
  ogit.worktree.remove "$base" >/dev/null 2>&1 && bad="$bad ahead-not-refused"
  case "$RESULT" in *prod*) ;; *) bad="$bad ahead-not-named=[$RESULT]" ;; esac
  git -C "$base/prod" push -q origin prod
  # convert
  ogit.worktree.remove "$base" >/dev/null 2>&1 || bad="$bad convert-rc=$?"
  [ -d "$base/dev/.git" ] && [ -d "$base/prod/.git" ] || bad="$bad not-clones"
  [ "$(git -C "$base/dev" branch --show-current)" = dev ] || bad="$bad dev-branch"
  [ "$(git -C "$base/prod" rev-parse HEAD)" = "$(git -C "$fx/origin.git" rev-parse prod)" ] || bad="$bad prod-content"
  [ "$(cat "$base/dev/ignored.txt" 2>/dev/null)" = mine ] || bad="$bad ignored-file-lost"
  ls -d "$HOME/.oosh.backups/"*-ogit-dev >/dev/null 2>&1 || bad="$bad no-ignored-backup"
  if private.this.group.exists dev; then
    [ "$(git -C "$base/dev" config --get core.sharedRepository)" = group ] || bad="$bad shared"
  fi
  ogit.safeDirectory.list | grep -qFx "$base/dev" || bad="$bad trusted"
  [ -z "$(git -C "$base/main" worktree list --porcelain | grep -c '^worktree ' | grep -vx 1)" ] || bad="$bad main-still-lists-worktrees"
  ogit.worktree.remove "$base" >/dev/null 2>&1 || bad="$bad second-run-rc=$?"
  ogit.layout.status "$base" >/dev/null || bad="$bad layout-not-consistent"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "refuses dirty and unpushed by name; converts clean worktrees to trusted, shared clones; carries ignored files; idempotent" || create.result 1 "worktree.remove:$bad"
  return $(result)
}
test.case $level "T-OGIT-WORKTREE-REMOVE: worktrees become independent clones, safely" test.ogit.worktreeRemove
expect 0 "refuses dirty and unpushed by name; converts clean worktrees to trusted, shared clones; carries ignored files; idempotent" "D1 + D4 of the design, § 2.1 ignored-file carry"
```

- [ ] **Step 2: Implement** (the two carry helpers of § 0.3 first, via `oo method.new`):

```bash
private.ogit.folder.ignored.save() # <folder> <stashDir> # copy every gitignored path of <folder> into <stashDir>, keeping relative paths; RESULT = the number carried; rc 1 when a copy fails (RESULT names <stashDir>) #
{
 local folder="$1" stash="$2"
 local p n=0
 local -a paths=()
 # `!! <path>` entries are the ignored ones; -z keeps odd names whole. A fully
 # ignored directory is one entry ending in /.
 while IFS= read -r -d '' p; do
   case "$p" in '!! '*) paths+=("${p#!! }") ;; esac
 done < <(git -C "$folder" status --porcelain --ignored -z 2>/dev/null)
 if [ ${#paths[@]} = 0 ]; then create.result 0 "0"; return $(result); fi
 if ! mkdir -p "$stash" || ! chmod 700 "$stash"; then
   create.result 1 "ogit: cannot create the backup $stash — nothing in $folder was touched"; return $(result)
 fi
 for p in "${paths[@]}"; do
   p="${p%/}"
   if mkdir -p "$stash/$(dirname "$p")" && cp -Rp "$folder/$p" "$stash/$(dirname "$p")/"; then
     success.log "carrying ignored ${folder##*/}/$p"
     n=$((n + 1))
   else
     create.result 1 "ogit: could not back up $folder/$p — nothing in $folder was touched; the partial backup is in $stash"; return $(result)
   fi
 done
 create.result 0 "$n"
 return $(result)
}

private.ogit.folder.ignored.restore() # <stashDir> <folder> # copy everything saved in <stashDir> back into <folder>, keeping relative paths; the backup itself is kept #
{
 local stash="$1" folder="$2"
 if [ ! -d "$stash" ]; then create.result 0 "no ignored files to carry"; return $(result); fi
 # `<stash>/.` copies the CONTENTS, dotfiles included, into the existing folder.
 if cp -Rp "$stash/." "$folder/"; then
   success.log "ignored files carried into $folder (backup kept: $stash)"
   create.result 0 "restored from $stash"
 else
   create.result 1 "ogit: could not copy the ignored files back into $folder — they are safe in $stash; copy them by hand: cp -Rp '$stash/.' '$folder/'"
 fi
 return $(result)
}

private.ogit.folder.gate() # <folder> # rc 0 when <folder> is clean, has an upstream and is not ahead of it; RESULT names the folder and the fix otherwise #
{
 local d="$1" name="${1##*/}" n
 n=$(ogit.status.show porcelain "$d" | grep -c .)
 if [ "$n" != 0 ]; then create.result 1 "$name has $n uncommitted change(s) — commit or stash them in $d first"; return $(result); fi
 if ! ogit.branch.check '@{u}' "$d"; then create.result 1 "$name tracks no upstream — set it with: ogit branch.upstream.set origin/<branch> $d, then ogit remote.push <branch> no $d"; return $(result); fi
 ogit.commit.count '@{u}' HEAD "$d" >/dev/null; n="$RESULT"
 if [ "${n:-0}" != 0 ]; then create.result 1 "$name is $n commit(s) ahead of its upstream — push it first"; return $(result); fi
 create.result 0 "$name is clean and pushed"
 return $(result)
}

private.ogit.folder.finish() # <folder> # after a clone/worktree lands under the base: shared group mode (ogit repo.share, when a dev group exists), trust for the caller and — under sudo — for the person who typed the command; no ownership change #
{
 # No chown: the policy is chgrp dev + g+w + setgid, never a recursive chown
 # (T-STATE-31-CHOWN-NOT-RECURSIVE, test/test.install:406-412). A single-user
 # host without a dev group has nothing to share with; trust is still added.
 if private.this.group.exists dev; then
   ogit.repo.share "$1" >/dev/null || return $(result)
 fi
 ogit.safeDirectory.add "$1" >/dev/null || return $(result)
 # Under sudo the entry above is ROOT's; the person who typed the command needs
 # one too. Through the as-user preamble (this:1098), and with the PHYSICAL
 # shared tree: root's $OOSH_DIR is /root/oosh, unreadable to that user.
 if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != root ]; then
   local sharedOosh
   sharedOosh=$(private.this.path.canonical "$OOSH_DIR")
   if private.this.script.load user private.as.user; then
     private.as.user "$SUDO_USER" bash -c "$(private.this.as.user.preamble.get "$SUDO_USER" "$(user.get home "$SUDO_USER")" "$sharedOosh")"$'\n'"'$sharedOosh/ogit' safeDirectory.add '$1'" >/dev/null 2>&1 \
       || warn.log "ogit: could not add $1 to $SUDO_USER's safe.directory — they run: ogit safeDirectory.ensure"
   else
     warn.log "ogit: user script not loadable — $SUDO_USER runs: ogit safeDirectory.ensure"
   fi
 fi
 create.result 0 "finished: $1"
 return $(result)
}

ogit.worktree.remove()     # <?base:$(oo mode.base.get)> # turn every linked worktree of <base>/main into an independent clone of the same branch, carrying its gitignored files across; refuses on a dirty or unpushed folder; idempotent; run with sudo on a shared tree #
{
 private.ogit.require || return $(result)
 local base
 base=$(private.ogit.base.get "$1")
 if [ ! -d "$base/main/.git" ]; then create.result 1 "ogit.worktree.remove: no repository at $base/main"; error.log "$RESULT"; return $(result); fi
 local url
 url=$(ogit.remote.url.get origin "$base/main")
 if [ -z "$url" ]; then create.result 1 "ogit.worktree.remove: $base/main has no origin"; error.log "$RESULT"; return $(result); fi
 # Gate EVERY folder before touching ANY: main, then each linked worktree.
 local -a folders=() branches=()
 local wt branch mainPhys
 mainPhys=$(private.this.path.canonical "$base/main")
 while IFS= read -r wt; do
   [ "$wt" = "$mainPhys" ] && continue
   folders+=("$wt")
 done < <(private.ogit.worktree.paths.get "$base/main")
 private.ogit.folder.gate "$base/main" || { error.log "$RESULT"; return $(result); }
 for wt in "${folders[@]}"; do
   private.ogit.folder.gate "$wt" || { error.log "$RESULT"; return $(result); }
   branch=$(ogit.branch.get "$wt")
   [ -n "$branch" ] || { create.result 1 "${wt##*/} is detached — check a branch out first"; error.log "$RESULT"; return $(result); }
   branches+=("$branch")
 done
 if [ ${#folders[@]} = 0 ]; then create.result 0 "no linked worktrees under $base — nothing to remove"; success.log "$RESULT"; return $(result); fi
 local i stash keep
 for i in "${!folders[@]}"; do
   wt="${folders[$i]}"; branch="${branches[$i]}"
   stash="$HOME/.oosh.backups/$(date -u +%Y%m%dT%H%M%SZ)-ogit-${wt##*/}"
   [ -e "$stash" ] && stash="$stash.$$"
   private.ogit.folder.ignored.save "$wt" "$stash" || { error.log "$RESULT"; return $(result); }
   keep=""; [ -d "$stash" ] && keep=" — its ignored files are kept in $stash"
   ogit.worktree.delete "$wt" "$base/main" >/dev/null \
     || { create.result 1 "worktree delete of $wt failed — stop; nothing after this folder was touched$keep"; error.log "$RESULT"; return $(result); }
   ogit.repo.clone "$url" "$branch" "$wt" >/dev/null 2>&1 \
     || { create.result 1 "${wt##*/}: worktree removed but clone of $branch failed — recover with: ogit repo.clone $url $branch $wt$keep"; error.log "$RESULT"; return $(result); }
   private.ogit.folder.finish "$wt" || { error.log "$RESULT$keep"; return $(result); }
   private.ogit.folder.ignored.restore "$stash" "$wt" || { error.log "$RESULT"; return $(result); }
   success.log "${wt##*/}: worktree → clone ($branch)"
 done
 ogit.worktree.prune "$base/main" >/dev/null
 create.result 0 "${#folders[@]} folder(s) converted to clones under $base"
 return $(result)
}
```
(`base` comes from the shared completer. The porcelain parse is `private.ogit.worktree.paths.get` — paths with spaces stay whole.)

- [ ] **Step 3: Run** `ogit` and `completion.audit` suites → PASS. **Commit** `feat(ogit): worktree.remove — linked worktrees become independent clones, gated, ignored files carried`.

---

### Task 21: `ogit worktree.restore` (clones → worktrees)

- [ ] **Step 1: Test (RED)**

```bash
test.ogit.worktreeRestore() {
  local base bad="" fx; base=$(test.ogit.base clrs clone); fx=$(dirname "$base")
  local GIT_CONFIG_GLOBAL="$fx/gitconfig"; export GIT_CONFIG_GLOBAL; : > "$GIT_CONFIG_GLOBAL"
  local HOME="$fx/home"; mkdir -p "$HOME"
  printf 'mine\n' > "$base/dev/ignored.txt"
  test.ogit.commit "$base/dev" local
  ogit.worktree.restore "$base" >/dev/null 2>&1 && bad="$bad ahead-not-refused"
  case "$RESULT" in *dev*) ;; *) bad="$bad ahead-not-named" ;; esac
  git -C "$base/dev" push -q origin dev
  ogit.worktree.restore "$base" >/dev/null 2>&1 || bad="$bad restore-rc=$?"
  [ -f "$base/dev/.git" ] && [ -f "$base/prod/.git" ] || bad="$bad not-worktrees"
  [ "$(git -C "$base/dev" rev-parse HEAD)" = "$(git -C "$fx/origin.git" rev-parse dev)" ] || bad="$bad dev-content"
  [ "$(git -C "$base/main" worktree list --porcelain | grep -c '^worktree ')" = 3 ] || bad="$bad main-lists"
  [ "$(cat "$base/dev/ignored.txt" 2>/dev/null)" = mine ] || bad="$bad ignored-file-lost"
  ogit.worktree.restore "$base" >/dev/null 2>&1 || bad="$bad second-run-rc"
  # round trip — the ignored file survives both directions
  ogit.worktree.remove "$base" >/dev/null 2>&1 || bad="$bad roundtrip-remove"
  [ -d "$base/dev/.git" ] || bad="$bad roundtrip-shape"
  [ "$(cat "$base/dev/ignored.txt" 2>/dev/null)" = mine ] || bad="$bad roundtrip-ignored-file-lost"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "clones become linked worktrees again, gated, idempotent, round-trippable, ignored files carried" || create.result 1 "worktree.restore:$bad"
  return $(result)
}
test.case $level "T-OGIT-WORKTREE-RESTORE: the reverse conversion, and the round trip" test.ogit.worktreeRestore
expect 0 "clones become linked worktrees again, gated, idempotent, round-trippable, ignored files carried" "reversibility is the promise"
```

- [ ] **Step 2: Implement**

```bash
ogit.worktree.restore()     # <?base:$(oo mode.base.get)> # turn every sibling clone of <base>/main (same origin) back into a linked worktree of main, carrying its gitignored files across; refuses on a dirty or unpushed folder; idempotent; run with sudo on a shared tree #
{
 private.ogit.require || return $(result)
 local base
 base=$(private.ogit.base.get "$1")
 if [ ! -d "$base/main/.git" ]; then create.result 1 "ogit.worktree.restore: no repository at $base/main"; error.log "$RESULT"; return $(result); fi
 local url
 url=$(ogit.remote.url.get origin "$base/main")
 local d branch
 local -a folders=() branches=()
 while IFS= read -r d; do
   [ "${d##*/}" = main ] && continue
   [ -d "$d/.git" ] || continue                                   # worktrees (.git file) are already done
   [ "$(ogit.remote.url.get origin "$d")" = "$url" ] || continue   # a foreign clone is not ours
   private.ogit.folder.gate "$d" || { error.log "$RESULT"; return $(result); }
   branch=$(ogit.branch.get "$d")
   [ -n "$branch" ] || { create.result 1 "${d##*/} is detached — check a branch out first"; error.log "$RESULT"; return $(result); }
   folders+=("$d"); branches+=("$branch")
 done < <(private.ogit.base.folders.list "$base")
 private.ogit.folder.gate "$base/main" || { error.log "$RESULT"; return $(result); }
 if [ ${#folders[@]} = 0 ]; then create.result 0 "no sibling clones under $base — nothing to restore"; success.log "$RESULT"; return $(result); fi
 ogit.remote.fetch no "$base/main" >/dev/null || { error.log "$RESULT"; return $(result); }
 local i stash keep
 for i in "${!folders[@]}"; do
   d="${folders[$i]}"; branch="${branches[$i]}"
   stash="$HOME/.oosh.backups/$(date -u +%Y%m%dT%H%M%SZ)-ogit-${d##*/}"
   [ -e "$stash" ] && stash="$stash.$$"
   private.ogit.folder.ignored.save "$d" "$stash" || { error.log "$RESULT"; return $(result); }
   keep=""; [ -d "$stash" ] && keep=" — its ignored files are kept in $stash"
   rm -rf "$d" || { create.result 1 "could not remove $d$keep"; error.log "$RESULT"; return $(result); }
   ogit.worktree.add "$branch" "$d" "origin/$branch" "$base/main" >/dev/null \
     || { create.result 1 "${d##*/}: clone removed but worktree add failed — recover with: ogit worktree.add $branch $d origin/$branch $base/main$keep"; error.log "$RESULT"; return $(result); }
   ogit.branch.upstream.set "origin/$branch" "$d" >/dev/null
   private.ogit.folder.finish "$d" || { error.log "$RESULT$keep"; return $(result); }
   private.ogit.folder.ignored.restore "$stash" "$d" || { error.log "$RESULT"; return $(result); }
   success.log "${d##*/}: clone → worktree ($branch)"
 done
 ogit.repo.share "$base/main" >/dev/null
 create.result 0 "${#folders[@]} folder(s) restored as worktrees of $base/main"
 return $(result)
}
```
Also extend `ogit.worktree.find` (Task 11) with the clone case, and test it in `T-OGIT-WORKTREE` with a `test.ogit.base … clone` fixture:

```bash
ogit.worktree.find()     # <branch> <?dir:$OOSH_DIR> # echo the folder that has <branch> checked out: a linked worktree of <dir>'s repository, else the sibling clone <base>/<branch> when it is on <branch>; empty when none #
{
 local dir="${2:-${OOSH_DIR:-.}}"
 local wt
 while IFS= read -r wt; do
   if [ "$(git -C "$wt" symbolic-ref -q --short HEAD 2>/dev/null)" = "$1" ]; then printf '%s\n' "$wt"; return 0; fi
 done < <(private.ogit.worktree.paths.get "$dir")
 # The base is the parent of THIS repository when a sibling main/ exists — derived
 # from <dir>, not from oo mode.base.get, so a fixture never resolves to the real tree.
 local self base
 self=$(private.this.path.canonical "$dir") || return 0
 base=$(dirname "$self")
 if [ -d "$base/main/.git" ] && [ -d "$base/$1/.git" ] && [ "$(ogit.branch.get "$base/$1")" = "$1" ]; then printf '%s\n' "$base/$1"; fi
 return 0
}
```

- [ ] **Step 3: Run** `ogit` and `completion.audit` suites → PASS. **Commit** `feat(ogit): worktree.restore (ignored files carried); worktree.find knows sibling clones`.

---

### Task 22: Install state 31 clones per folder; `private.oo.shared.tree.from.local` clones

**Files:** `oo` (state 31 body at the sites migrated in Task 15; `private.oo.shared.tree.from.local`), `test/test.oo` (T-SHARED-TREE-*)

- [ ] **Step 1: Tests (RED)** — rewrite the four `T-SHARED-TREE-*` cases (test.oo:2192-2416) to assert the clone shape: replace every `[ -f "$fixture/dev/.git" ] && grep -q gitdir: …` with `[ -d "$fixture/dev/.git" ]` and add `[ "$(git -C "$fixture/dev" remote get-url origin)" = "$(git -C "$fixture/main" remote get-url origin)" ]`. Run `./test.suite run oo 1` → those four FAIL.

- [ ] **Step 2: `private.oo.shared.tree.from.local`** — replace step 3 (the `worktree add` pair) with:

```bash
  # 3. The active branch as an INDEPENDENT CLONE beside main/ (clone layout,
  #    2026-09-23 design). Cloned from main/ (offline-safe), so main/ must hold
  #    a LOCAL <branch>: when only origin/<branch> exists (the source was a
  #    clone of another branch), create it from there first — the fallback the
  #    old `worktree add … "$branch" || worktree add … "origin/$branch"` pair
  #    had — and put main/ back on main. Then origin is re-pointed at main/'s
  #    origin so the clone pulls from GitHub like every folder.
  if [ "$branch" != "main" ]; then
    if ! ogit.branch.check "$branch" main; then
      ogit.branch.reset "$branch" "origin/$branch" main >/dev/null \
        || { error.log "private.oo.shared.tree.from.local: neither $branch nor origin/$branch exists in main/"; return 1; }
    fi
    ogit.branch.checkout main main >/dev/null \
      || warn.log "private.oo.shared.tree.from.local: could not put main/ back on main (no local main — see step 2)"
    local originUrl
    originUrl=$(ogit.remote.url.get origin main)
    ogit.repo.clone "$(pwd)/main" "$branch" "$branch" >/dev/null \
      || { error.log "private.oo.shared.tree.from.local: clone of $branch from main/ failed — $RESULT"; return 1; }
    if [ -n "$originUrl" ]; then
      ogit.remote.url.set "$originUrl" origin "$branch" >/dev/null || { error.log "private.oo.shared.tree.from.local: $RESULT"; return 1; }
    fi
    ogit.repo.share "$branch" >/dev/null
  fi
```
(The function keeps its `return 1` / `error.log` contract — its callers, state 31 and `oo mode.setup`, test `$?`.)

- [ ] **Step 3: State 31** — the install lives in `private.check.root.shared.dev.folder.created` (state 31) and nowhere else (rule 7). Replace the "Creating worktree" branch (oo:2049-2071 at 8c46828, migrated in Task 15) — the old `cd main` … `cd ..` go with it — with:

```bash
      else
        # ─── state 31 [5/5: dev.repo.cloned] — the branch as its OWN clone beside
        # main/ (clone layout, 2026-09-23 design). Absolute target, no cd.
        # Defence in depth: an older caller may send a polluted $OOSH_BRANCH
        # like "heads/origin/dev" — strip it before it names a folder.
        OOSH_BRANCH="${OOSH_BRANCH#refs/heads/}"
        OOSH_BRANCH="${OOSH_BRANCH#refs/remotes/origin/}"
        OOSH_BRANCH="${OOSH_BRANCH#heads/origin/}"
        OOSH_BRANCH="${OOSH_BRANCH#origin/}"
        important.log "state 31 [5/5: dev.repo.cloned]: cloning ${OOSH_BRANCH} beside main/ in $onceShBase"
        if ! ogit.repo.clone git@github.com:Cerulean-Circle-GmbH/once.sh.git "${OOSH_BRANCH}" "$onceShBase/${OOSH_BRANCH}"; then
          error.log "state 31 [5/5: dev.repo.cloned]: clone of ${OOSH_BRANCH} into $onceShBase failed — $RESULT"
          create.result 1 "state 31 step 5/5 failed: clone of ${OOSH_BRANCH} failed"
          return $(result)
        fi
      fi
```
and the permission block (oo:2144-2171) with:

```bash
    # Each folder is its own repository now: shared mode, setgid, g+w and the
    # caller's trust PER FOLDER (ogit repo.share / safeDirectory.add), not on
    # main/.git only. The base itself gets group dev + setgid (on this host it
    # is root:dev WITHOUT setgid), so a folder added later by oo checkout /
    # oo mode inherits the group. Re-runs are idempotent.
    if private.this.group.exists dev; then
      if ! { chgrp dev "$onceShBase" && chmod g+ws "$onceShBase"; }; then
        error.log "state 31 [5/5: dev.repo.cloned]: cannot set group dev + setgid on $onceShBase"
        create.result 1 "state 31 step 5/5 failed: base $onceShBase is not group dev + setgid"
        return $(result)
      fi
    fi
    local _wt
    while IFS= read -r _wt; do
      if ! ogit.repo.share "$_wt" >/dev/null; then
        error.log "state 31 [5/5: dev.repo.cloned]: ogit repo.share $_wt failed — $RESULT"
        create.result 1 "state 31 step 5/5 failed: $_wt is not group-shared"
        return $(result)
      fi
      # macOS: safe.directory is a string match on a case-insensitive FS (Task M helper)
      ogit.safeDirectory.add "$(private.this.path.case.get "$_wt")" >/dev/null
    done < <(private.ogit.base.folders.list "$onceShBase")
```
(`private.ogit.base.folders.list` is the Task 10 loop — symlinks, dot-dirs and non-repositories are skipped. The pinned checks further down at oo:2300-2340, labelled `[5/5: dev.repo.cloned]`, stay as they are; only their `check git clone/worktree-add logs` hint becomes `check the ogit repo.clone log above`.)

- [ ] **Step 4: Run** `./test.suite run oo 1` and `./test.suite run install 1` (T-STATE-31-CHOWN-NOT-RECURSIVE must still pass) → PASS. Commit `feat(oo): install state 31 and shared.tree.from.local produce the clone layout with per-folder permissions and a setgid base`.

---

### Task 23: `oo mode`, `oo checkout` always clone; `oo update` and `config init.user` ensure trust

**Files:** `oo` (`oo.mode` missing-folder block, `oo.checkout`, `oo.update`), `config` (`config.init.user`), `user` (`user.oosh.install`), tests in `test/test.oo`, `test/test.config`

- [ ] **Step 1: Tests (RED)**
  - test.oo T-MODE-COMPLETION-WORKTREE (316-358), T-MODE-COMPLETION-LAZY-USERENV-* (485-663), T-SETUP-4 (1449-1501), T-BASE-GET-WORKTREE (1508-1540): build their fixtures with `test.ogit.base <label> clone` semantics (copy the helper into test.oo as `test.oo.base`) and assert `-d "$fx/dev/.git"`; T-SETUP-4's "dev/.git is a file containing gitdir:" becomes "dev/.git is a directory".
  - New `T-CHECKOUT-CLONES-UNDER-BASE`: with a clone-layout fixture and `OOSH_COMPONENTS_DIR="$base"`, `OOSH_DIR="$base/dev"`, `oo.checkout prod` (branch exists on the fixture origin) creates `$base/prod` with a `.git` directory, `core.sharedRepository=group`, and `safe.directory` (sandboxed `GIT_CONFIG_GLOBAL`).
  - New `T-UPDATE-ENSURES-TRUST` (test.oo): after `oo.update` on the fixture, every folder under the base is in `ogit safeDirectory.list` (mock the pull with `ogit.remote.pull() { create.result 0 mocked; }` inside a subshell).
  - test.config: extend T87/T-INIT-USER (or add `T89`): `declare -f config.init.user | grep -q 'ogit.safeDirectory.ensure'`.

- [ ] **Step 2: Implement**
  - `oo.mode` missing folder (oo:792-815): replace the `worktree add` with
    ```bash
    console.log "Cloning $remote_branch into $target_dir..."
    local originUrl
    originUrl=$(ogit.remote.url.get origin "$current_target")
    if ! ogit.repo.clone "$originUrl" "${remote_branch#origin/}" "$target_dir" >/dev/null; then
      error.log "git worktree add failed for $remote_branch → $target_dir"   # message kept: test.oo:470 pins the text; reword the pin and this line together to "clone failed for" in the same commit
      create.result 1 "clone failed"; return $(result)
    fi
    ogit.repo.share "$target_dir" >/dev/null; ogit.safeDirectory.add "$target_dir" >/dev/null
    ```
    (Do the rename: message `clone failed for`, pin updated in test.oo:470.)
  - `oo.checkout`: delete the "Worktree mode" branch; the single path is: `base=$(oo.mode.base.get)` (fail loud if none: `create.result 1 "no components base — run oo mode.setup"`); `targetDir="$base/$dirName"`; the existing-folder branch unchanged (align via `ogit.branch.checkout`); else `ogit.remote.fetch no "$oosh"`, `ogit.repo.clone "$(ogit.remote.url.get origin "$oosh")" "$version" "$targetDir"`, `ogit.repo.share "$targetDir"`, `ogit.safeDirectory.add "$targetDir"`. Docstring: `# <version> # clone a remote branch as <base>/<dirName>`.
  - `oo.update`: after the pull and before `private.oo.update.heal.symlinks`: `ogit.safeDirectory.ensure >/dev/null || warn.log "oo update: could not ensure safe.directory — $RESULT"`.
  - `config.init.user`: after the log.env migration block: `private.this.script.load ogit ogit.branch.get && ogit.safeDirectory.ensure "$(dirname "$sharedOosh")" >/dev/null || warn.log "config.init.user: $RESULT"` (for the *caller*); and inside the as-user hop (it already uses `private.this.as.user.preamble.get`), after `private.config.bashrc.ensure`: `'$sharedOosh/ogit' safeDirectory.ensure '$(dirname "$sharedOosh")' >/dev/null` (for the *target*).
  - `user.oosh.install` (Task 17 sites): replace the two `safeDirectory.add` hops (as-computed + canonical case) with one hop through the preamble: `private.as.user "$username" bash -c "$(private.this.as.user.preamble.get "$username" "$targetHome" "$sharedOosh")"$'\n'"'$sharedOosh/ogit' safeDirectory.ensure '$(private.this.path.case.get "$(dirname "$sharedOosh")")'"` — the case-canonical base keeps the macOS string-match fix the old second hop existed for.

- [ ] **Step 3: Run** oo, config, user suites → PASS. Commit `feat(oo,config,user): oo mode/checkout clone under the base; trust ensured by oo update, config init.user, user.oosh.install`.

---

### Task 24: `promote` merges in the target's own folder

**Files:** `promote` (`private.check.merged.to.testing`, `private.check.merged.to.prod`, `testing.pushed`, `prod.pushed`, `prod.tagged`), `test/test.promote`

- [ ] **Step 1: Test (RED)** — new fixture: a base with `dev` and `testing` clones of one bare origin (`test.ogit.base` shape clone, plus a `testing` branch), `OOSH_COMPONENTS_DIR="$base"`, `OOSH_DIR="$base/dev"`, one extra commit on dev:

```bash
test.promote.mergeInTargetFolder() {
  local base fx bad=""; base=$(test.promote.base mit); fx=$(dirname "$base")   # copy test.ogit.base into test.promote as test.promote.base, adding a testing branch/clone
  # load ogit BEFORE re-pointing OOSH_DIR: the loader sources "$OOSH_DIR/ogit" (rule 12)
  private.this.script.load ogit ogit.branch.get
  # local + export: both anchors are this function's; the caller's values come back on return
  local OOSH_COMPONENTS_DIR="$base"; export OOSH_COMPONENTS_DIR
  local OOSH_DIR="$base/dev"; export OOSH_DIR
  printf 'new\n' >> "$base/dev/file"; git -C "$base/dev" -c user.email=t@t -c user.name=t commit -qam new
  private.check.merged.to.testing promote testing 14 >/dev/null 2>&1 || bad="$bad rc=$? result=[$RESULT]"
  [ "$(git -C "$base/testing" branch --show-current)" = testing ] || bad="$bad testing-folder-branch"
  git -C "$base/testing" log --oneline | grep -q new || bad="$bad merge-not-in-testing-folder"
  [ "$(git -C "$base/dev" branch --show-current)" = dev ] || bad="$bad dev-folder-moved"
  [ "$(git -C "$fx/origin.git" rev-parse dev)" = "$(git -C "$base/dev" rev-parse dev)" ] || bad="$bad source-not-pushed"
  rm -rf "$base/testing"
  private.check.merged.to.testing promote testing 14 >/dev/null 2>&1 && bad="$bad missing-target-not-refused"
  case "$RESULT" in *"oo checkout testing"*) ;; *) bad="$bad refusal-names-no-fix=[$RESULT]" ;; esac
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "the merge lands in testing's own folder; dev's folder is untouched; a missing target folder is refused with the fix" || create.result 1 "promote:$bad"
  return $(result)
}
test.case $level "T-PROMOTE-MERGE-IN-TARGET-FOLDER: dev→testing merges inside <base>/testing" test.promote.mergeInTargetFolder
expect 0 "the merge lands in testing's own folder; dev's folder is untouched; a missing target folder is refused with the fix" "clone layout: each stage folder is its own repository"
```

- [ ] **Step 2: Implement** — one helper replaces both merge bodies:

```bash
private.promote.merge.into.folder() # <source> <target> # push <source>; in <target>'s own folder: fetch, fast-forward <target> to origin/<target>, merge origin/<source> as the promote bot; rewrite OOSH_SELF_BRANCH there; RESULT tells #
{
 private.this.script.load ogit ogit.branch.get
 local source="$1" target="$2" dir
 if ! private.promote.push.source.branch "$OOSH_DIR" "$source"; then
   create.result 1 "Failed to push $source to origin — pull/resolve manually before promoting"; return $(result)
 fi
 dir=$(ogit.worktree.find "$target" "$OOSH_DIR")
 if [ -z "$dir" ]; then
   create.result 1 "no folder holds branch $target — run: oo checkout $target"; return $(result)
 fi
 local stashed=no
 if ! ogit.diff.check "$dir"; then ogit.stash.push "promote: pre-merge stash" "$dir" >/dev/null && stashed=yes; fi
 ogit.remote.fetch no "$dir" >/dev/null || { create.result 1 "fetch failed in $dir"; return $(result); }
 if ! ogit.branch.fastForward "origin/$target" "$dir" >/dev/null; then
   [ "$stashed" = yes ] && ogit.stash.pop "$dir" >/dev/null
   create.result 1 "$target in $dir has diverged from origin/$target — reconcile it by hand"; return $(result)
 fi
 if ogit.branch.merge "origin/$source" oosh-promote@local "oosh promote" "$dir" >/dev/null; then
   private.promote.rewrite.self.branch "$dir"
   [ "$stashed" = yes ] && ogit.stash.pop "$dir" >/dev/null
   create.result 0 "Merged $source into $target (in $dir)"
 elif private.promote.try.resolve.self.branch.conflict "$dir" "$source"; then
   important.log "Auto-resolved OOSH_SELF_BRANCH drift in known files; merge completed"
   private.promote.rewrite.self.branch "$dir"
   [ "$stashed" = yes ] && ogit.stash.pop "$dir" >/dev/null
   create.result 0 "Merged $source into $target (auto-resolved OOSH_SELF_BRANCH drift)"
 else
   error.log "Merge conflict — aborting"
   ogit.merge.abort "$dir" >/dev/null
   [ "$stashed" = yes ] && ogit.stash.pop "$dir" >/dev/null
   create.result 1 "Merge failed — resolve conflicts manually in $dir"
 fi
 return $(result)
}
```
Then:
- `private.check.merged.to.testing` body → `private.promote.merge.into.folder dev testing; return $(result)` (keep the `<script> <stageTo> <stateFound>` shifts).
- `private.check.merged.to.prod` body → `private.promote.merge.into.folder testing prod; return $(result)`.
- `testing.tagged` / `prod.tagged`: tag in the target folder: `dir=$(ogit.worktree.find testing "$OOSH_DIR")`, `ogit.tag.create "$tag" testing "$dir"`; `ogit.tag.check` / `ogit.tag.latest.get` on `$dir`.
- `testing.pushed` / `prod.pushed`: `ogit.remote.push testing yes "$dir"`; no `checkout dev` any more (the dev folder never left dev) — update `test.promote.noModeWrite` (test.promote:494-499), which pinned `checkout dev`, to pin "no `branch.checkout`" instead; drop the stash-pop tail (stashes are popped in the helper).
- `promote.status` / `branch.alignment`: read refs from the target folders (`ogit.commit.log.show refs/heads/testing 1 '%h %ci' "$(ogit.worktree.find testing …)"`), falling back to `$OOSH_DIR` when no folder exists.

- [ ] **Step 3: Run** `./test.suite run promote 1` → PASS. Commit `feat(promote): merge in the target stage's own folder; refuse when the folder is missing`.

---

### Task 25: Platform invariant, docs, gates, migration

- [ ] **`test/test.platform.shared.layout.invariant`** — generate it, never copy the template by hand: `cd ~/oosh && LOG_LEVEL=1 ./oo test.platform.new shared layout` (Task M). Then replace its four INVARIANT blocks: INVARIANT-0 `oo mode.base.get` succeeds; INVARIANT-1 every folder under the base has a `.git` **directory** (`ogit layout.status` rc 0 and no `worktree` line); INVARIANT-2 each has `core.sharedRepository=group` and a setgid `.git` (parse `shared=group setgid=yes` from `ogit layout.status`); INVARIANT-3 each is trusted for the caller (`trusted=yes`), recovery `oo update`. Each `expect.fail` names the command (`sudo ogit worktree.remove`, `ogit repo.share <dir>`, `oo update`). Add INVARIANT-4: the base directory itself is group `dev` with setgid (`[ -g "$base" ]`), recovery `sudo chgrp dev <base> && sudo chmod g+ws <base>` (state 31 sets it, Task 22). Keep `expect.pass` / `expect.fail` (never `expect 0 "*"`), as the template says.
- [ ] Docs: `docs/oo.md` § The worktree layout → "The clone layout" (the tree from spec § 2, the `main/` rule, `oo checkout` always clones under the base, `ogit worktree.remove/restore`); `docs/branching.md` and `docs/promote.md`: merge happens in `<base>/<target>`, prerequisites (`oo checkout testing`), the refusal; `docs/repair-toolkit.md` rows: `ogit layout.status`, `ogit safeDirectory.ensure`, `sudo ogit worktree.remove`; `docs/ogit.md` § Layout filled; `docs/research/2026-09-22-worktrees-vs-version-convention.md` gets a top note: "**Superseded 2026-09-23** by the ogit design (link); the user decided for clones."; `docs/oosh-architecture.md` § Sanctioned exceptions: `oo.use` wording still holds.
- [ ] Gates: `./test.suite core 1` green; validators OK (rule 5, including `./ogit caller.validate`); `os platform.test ubuntu_24_04`, `alpine`, and the macOS gate (per memory `reference_tart_macos_gate`) all PASS — fresh installs now produce clones; inside `terminal notests`: `ogit layout.status` shows all `clone`, `./test.suite run platform.shared.layout.invariant 1` PASS.
- [ ] **Stop (Batch 9) and ask before pushing.** On the user's go: push `dev`, then the three platform gates above.
- [ ] **Migrate this host** — a **user-run** runbook (Batch 10), documented in `docs/ogit.md` § Layout, never automatic:
  1. `ogit layout.status` — expect `main clone`, `dev worktree`, `prod worktree`, all `dirty 0`, `ahead 0`. Anything else: commit/push first (the conversion refuses anyway, naming the folder).
  2. Backup is **automatic**: gitignored files (on this host `dev/sessions/agent.context.md`) are carried across and a copy is kept under `$HOME/.oosh.backups/<UTC-stamp>-ogit-<folder>` (under sudo: root's `$HOME`). Note the paths it reports.
  3. `sudo ogit worktree.remove`; `ogit layout.status` (all `clone`, `shared=group setgid=yes trusted=yes`); `cat dev/sessions/agent.context.md` is intact.
  4. Base setgid check: `ls -ld <base>` shows group `dev` and `s` in the group bits; if not (this host's base is `root:dev` without setgid until a state 31 re-run): `sudo chgrp dev <base> && sudo chmod g+ws <base>`.
  5. `env -i HOME=$HOME bash -l -c 'oo mode.list'`; `oo mode prod && oo mode dev`.
  6. **`oo checkout testing` before the first promote** — this host has no `testing/` folder, and promote now merges in `<base>/testing` and refuses without it. Then `promote status`.
  7. Prove reversibility once: `sudo ogit worktree.restore`, `ogit layout.status`, `sudo ogit worktree.remove` — `sessions/agent.context.md` still intact after the round trip.
- [ ] Record in `sessions/agent.context.md`; add memory: "layout is clones per folder since <commit>; `ogit worktree.restore` reverses".

---

## Self-review checklist (done by the plan author; re-run by the implementer at the end)

- **Methodology (§ 0):** every new method via `oo method.new` (Task M first — `private.this.script.load`, `private.this.path.case.get`, `oo test.platform.new`, completion-audit scope); no per-method forwarding completers, the shared `ogit.parameter.completion.*` block instead, `completion.audit` green per ogit Task; no `private.ogit.dir` subshell — inline `local dir="${N:-${OOSH_DIR:-.}}"`; no `cd && pwd -P` in bodies (`private.this.path.canonical`); no `oo mode.base.get` subprocess default (`private.ogit.base.get`); no recursive chown; getters without `create.result`, every mutator branch with `create.result` + `return $(result)`; tests sandbox with `local X=…; export X`.
- **Spec coverage:** § 2 layout → Tasks 19-23, 25; § 2.1 conversions (incl. the ignored-file carry) → Tasks 20-21; § 3.1-3.2 shape/conventions → Task 1; § 3.3 catalogue → Tasks 3-11 (`ogit.remote.url.set`, `ogit.branch.fastForward`, `ogit.worktree.delete`, `ogit.worktree.prune`, `ogit.conflict.resolve <file> <?side>` are already in spec § 3.3 and the tree); § 3.4 aliases → Tasks 10, 12; § 3.5 → Tasks 15-16 keep porcelain verbs; § 3.6 exceptions → Tasks 13 (`ogit caller.validate`), 17; § 4 permissions/trust → Tasks 20-23; § 5 caller changes → Tasks 22-24; § 6 tests/docs/rollout → Tasks 13, 18, 25.
- **Invariants (spec § 7):** `path validate` / `anchor.validate` / `portability.validate` after every task; `main/` always present; `ogit caller.validate` green from Task 17 on (and able to fail: T-OGIT-ONLY-CALLER-REJECTS); install fixes only in state 31's body, with its `[5/5: …]` labels; no automatic conversion; gitignored files survive both conversions; a pre-existing non-empty folder is never cloned over or deleted by `ogit.repo.clone`.
- **Correctness fixes carried in the snippets:** split `local` declarations (`remote.pull/fetch/push`, `commit.count`); `repo.clone` refuses a non-empty target and removes only what it created; `index.add` shifts scope, then dir; the Task 7 case is `test.ogit.commitNoun`; both fixtures date the seed at tick 0; `branch.compare` has its real body from Task 4, with a verdict test; `<?dir>` last in `remote.fetch <?prune> <?dir>` / `remote.pull <?url> <?branch> <?dir>` and every call updated; git ≥ 2.28.
- **Known judgement calls for the implementer:** `oo.commit`'s `add *` → `index.add all` (dotfiles); `hiveMind:4888 add -f`; the `promote.report` tag format (keep output identical); `scrumMaster:14` lazy default; whether `ossh:640` keeps the raw fallback; `myId:84` — a printed hint, marked with `# ogit-exception:` (or reworded to name an ogit command); `Install oosh.command` carries an `ogit-exception-file:` marker although it has no git call today; `private.ogit.folder.finish` skips `ogit.repo.share` on a host without a dev group (the Task 20 test asserts `shared` only when the group exists); the carry keeps its backup directory after success (it is a backup — nothing cleans `~/.oosh.backups` automatically); `ogit.worktree.find` compares `symbolic-ref --short HEAD` per worktree instead of parsing `branch refs/heads/…` lines — same answer, space-safe. Decide, note the decision in the commit message, move on.
- **Hand-off for the next agent:** start at Batch M (§ Batches and stop points); § 0 is the contract, this doc is the tick-off list (`- [ ]` → `- [x]` per step). Stop after every batch; ask before every push; memory `feedback_oosh_methodology` governs every edit.
