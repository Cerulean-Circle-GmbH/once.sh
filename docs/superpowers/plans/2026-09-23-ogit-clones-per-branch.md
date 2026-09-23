# `ogit` + clone-per-branch layout — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `ogit`, the odocker-style git wrapper that becomes the only caller of the `git` binary in the oosh tree, then use it to replace the git-worktree layout under `…/Once.sh/` with one independent clone per branch folder — reversibly.

**Architecture:** Two phases, two pushes. Phase 1 is a pure refactor: `ogit` (15 nouns, `ogit.<noun>.<verb>`, `<?dir:$OOSH_DIR>` last) plus every raw `git` call in bash-mode scripts moved behind it, guarded by a tree sweep; behaviour and the worktree layout stay identical. Phase 2 changes behaviour: `ogit worktree.remove/restore/layout.status`, state 31 clones per folder with per-folder permissions and trust, `oo mode`/`oo checkout` always clone, `promote` merges in the target's own folder.

**Tech Stack:** bash 4+ (macOS bash 3.2 must still parse), OOSH kernel (`this`, `log`, `test.suite`, `oo method.new`), git ≥ 2.20, draw.io for the tree diagram.

**Spec:** `docs/superpowers/specs/2026-09-23-ogit-clones-per-branch-design.md` (read it first; this plan implements it section by section). Method tree: `docs/puml/ogit.tree/ogit.tree.drawio`.

---

## 0. Orientation for the implementing agent (read before Task 1)

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
5. Validators that must stay green after every task: `LOG_LEVEL=1 ./path validate`, `LOG_LEVEL=1 ./this anchor.validate all`, `LOG_LEVEL=1 ./config validate user`. Full gate: `./test.suite core 1` (not `all`).
6. Commit per task, message `type(scope): what — why`, ending with the attribution line the session gives you. Do not push until the plan says so. No promotion to testing/prod.
7. Install fixes go INTO the failing state machine state (`private.check.<state>` in `oo`), never into `ossh.install.finish.local`.
8. `GIT_CONFIG_GLOBAL` must be honoured by anything that touches `--global` (tests sandbox with it).
9. Sourcing: `source this` inside a script's `start()` is the pattern; `this.start` returns immediately when the script is being sourced (`this.isSourced`), so `source ogit` from another script defines the functions and runs nothing. Verify once in Task 1.
10. Reserved dispatch words (no method may be named): `start`, `help*`, `restart`, `localInstall`.
11. Positional optional parameters are skipped with an empty string: `ogit remote.push "" no "$dir"`.

**Phase gates.** Phase 1 ends with core green + `os platform.test ubuntu_24_04` + push. Phase 2 ends with core green + all three platform installs + the manual migration of this host.

---

## 1. File structure

| File | Responsibility | Phase |
|---|---|---|
| `ogit` (new, from `oo new ogit`) | the only git caller: 15 nouns, § 3.3 of the spec; completers; `ogit.usage`; `ogit.start` | 1 (+ layout methods in 2) |
| `test/test.ogit` (new, from `oo test.new ogit`) | fixture helper, one case per method, `T-OGIT-ONLY-CALLER` sweep + planted violation | 1, 2 |
| `this` | `this.git.branch.short` / `this.git.commits.count` become delegating aliases via `private.this.ogit.load`; `private.this.anchor.validate.one` uses `ogit.repo.grep` | 1 |
| `oo` | safeDirectory methods become aliases; all raw git → ogit; Phase 2: state 31, `shared.tree.from.local`, `oo.mode`, `oo.checkout`, `oo.update` | 1, 2 |
| `promote` | all raw git → ogit; `promote.branch.alignment` alias; Phase 2: merge in target folder | 1, 2 |
| `config`, `user`, `ossh`, `osshLayout`, `os`, `path`, `test.suite`, `claudeCode`, `hiveMind`, `scrumMaster`, `context`, `agentRoom`, `snet`, `otest` | raw git → ogit (function form, or command form in hops/remote strings); exception markers | 1 |
| `test/test.oo`, `test/test.ossh`, `test/test.promote`, `test/test.this` | re-aimed grep-pins (1); worktree fixtures rewritten to clones (2) | 1, 2 |
| `test/test.platform.shared.layout.invariant` (new) | real-host clone-layout invariant | 2 |
| `docs/ogit.md` (new), `docs/wiki-index.md`, `CLAUDE.md`, `docs/oo.md`, `docs/branching.md`, `docs/promote.md`, `docs/repair-toolkit.md`, `docs/oosh-architecture.md`, `docs/research/2026-09-22-worktrees-vs-version-convention.md` | docs | 1, 2 |

---

# PHASE 1 — `ogit` becomes the only git caller (behaviour identical)

### Task 1: Scaffold `ogit` and `test/test.ogit`

**Files:**
- Create: `ogit` (via `oo new ogit`), `test/test.ogit` (via `oo test.new ogit`)

- [ ] **Step 1: Scaffold with the OOSH tool**

```bash
cd ~/oosh && LOG_LEVEL=1 ./oo new ogit && ls -l ogit test/test.ogit
```
Expected: both files exist, `ogit` executable, each carries its marker (`### new.method` / `### test.method`).

- [ ] **Step 2: Header, banners, usage**

Replace the top of `ogit` (keep the template's commented `#clear`/`PS4` lines) so it reads:

```bash
#!/usr/bin/env bash
#clear
#export PS4='\e[90m+${LINENO} in ${#BASH_SOURCE[@]}>${FUNCNAME[0]}:${BASH_SOURCE[@]##*/} \e[0m'
#set -x

# ogit - git wrapper for oosh
# No flags, positional params only. Following: tmux→otmux, ssh→ossh, docker→odocker, git→ogit
#
# THE ONLY CALLER of the git binary in this tree (test.ogit T-OGIT-ONLY-CALLER).
# Nouns are git objects, verbs are actions, qualifiers are parameters
# (docs/superpowers/specs/2026-09-23-ogit-clones-per-branch-design.md § 3).
# Every method takes <?dir:$OOSH_DIR> LAST and runs `git -C "$dir" …`, never `cd`.
# Getters answer on stdout with no create.result; mutators create.result + return $(result).

# ─────────────────────────────────────────────────────────────────────────────
# PRIVATE HELPERS
# ─────────────────────────────────────────────────────────────────────────────

private.ogit.dir() # <?dir> # echo the repository a method acts on: <dir>, else $OOSH_DIR, else . #
{
 printf '%s' "${1:-${OOSH_DIR:-.}}"
}

private.ogit.require() # # rc 0 when the git binary is present; error.log + create.result 127 when it is not #
{
 command -v git >/dev/null 2>&1 && return 0
 create.result 127 "ogit: git is not installed — run \`oo cmd git\`"
 error.log "$RESULT"
 return 127
}

private.ogit.identity() # <?asEmail> <?asName> # echo the -c identity flags for a bot commit/merge, or nothing #
{
 [ -n "$1" ] || return 0
 printf '%s' "-c user.email=$1 -c user.name=${2:-$1} -c commit.gpgsign=false"
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
    ----------
  "
}
```

- [ ] **Step 3: Verify the sourced guard**

```bash
bash -c 'source ~/oosh/ogit; type -t ogit.usage; echo "rc=$?"'
```
Expected: `function` and `rc=0`, no usage text printed (because `this.start` returns on `this.isSourced`). If usage prints, add to `ogit.start` before `this.start`: `this.isSourced "${FUNCNAME[1]}" && return 0` — and record why in a comment.

- [ ] **Step 4: Completion is automatic — prove it**

```bash
./ng/c2 function.completion ./ogit
```
Expected: `usage` (only). Later tasks add methods.

- [ ] **Step 5: Commit**

```bash
git add ogit test/test.ogit && git commit -m "feat(ogit): scaffold the git wrapper (oo new ogit) — header, helpers, usage"
```

---

### Task 2: Test fixture helper + assertion idiom in `test/test.ogit`

**Files:**
- Modify: `test/test.ogit` (above `### test.method`)

- [ ] **Step 1: Add the fixture helper and a smoke case**

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
  git -C "$fx/work" -c user.email=t@t -c user.name=t commit -q -m seed
  git -C "$fx/work" push -q -u origin dev
  echo "$fx"
}

test.ogit.commit() { # <work> <message> # one more commit on the fixture (raw git, fixture side)
  printf '%s\n' "$2" >> "$1/file"
  git -C "$1" add file
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

- [ ] **Step 2: Run** `./test.suite run ogit 1` → PASS (fixture only; the template's own "test start" case may print usage — that is expected).
- [ ] **Step 3: Commit** `git add test/test.ogit && git commit -m "test(ogit): fixture helper — work clone tracking a bare origin"`

---

### Task 3: `repo` noun

**Files:** `ogit`, `test/test.ogit`

For each method: scaffold with `oo method.new` (params / description exactly as the signature below), replace the stub body, replace the stub test with the case shown, run RED, implement, run GREEN, commit. Bodies:

- [ ] **Step 1: Tests (RED)** — add to `test/test.ogit`:

```bash
test.ogit.repo() {
  local fx bad=""; fx=$(test.ogit.fixture repo)
  ogit.repo.check "$fx/work" || bad="$bad check-repo-rc=$?"
  ogit.repo.check "$fx" && bad="$bad check-nonrepo-passed"
  [ "$(ogit.repo.root.get "$fx/work")" = "$(cd "$fx/work" && pwd -P)" ] || bad="$bad root=$(ogit.repo.root.get "$fx/work")"
  ogit.repo.clone "$fx/origin.git" dev "$fx/clone" >/dev/null 2>&1 || bad="$bad clone-rc=$?"
  [ -d "$fx/clone/.git" ] && [ "$(git -C "$fx/clone" branch --show-current)" = dev ] || bad="$bad clone-shape"
  ogit.repo.clone "$fx/origin.git" nosuch "$fx/clone2" >/dev/null 2>&1 && bad="$bad clone-bad-branch-passed"
  [ -e "$fx/clone2" ] && bad="$bad clone-left-halfmade-dir"
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

- [ ] **Step 2: Run** → FAIL (`ogit.repo.check: command not found` or the stub's RESULT).

- [ ] **Step 3: Implement** (scaffold each with `oo method.new`, then paste):

```bash
ogit.repo.clone()     # <url> <branch> <targetDir> # clone <url> at <branch> into <targetDir>; removes a half-made dir on failure #
{
 private.ogit.require || return $(result)
 local url="$1" branch="$2" target="$3"
 if [ -z "$url" ] || [ -z "$branch" ] || [ -z "$target" ]; then
   create.result 1 "ogit.repo.clone requires <url> <branch> <targetDir>"; error.log "$RESULT"; return $(result)
 fi
 if git clone -b "$branch" "$url" "$target"; then
   create.result 0 "cloned $branch into $target"
 else
   rm -rf "$target" 2>/dev/null
   create.result 1 "clone of $branch from $url failed"; error.log "$RESULT"
 fi
 return $(result)
}
ogit.repo.clone.completion.branch() { ogit.parameter.completion.branch "$@"; }
ogit.repo.clone.completion.targetDir() { compgen -d "$1"; }

ogit.repo.check()     # <?dir:$OOSH_DIR> # rc 0 when <dir> is inside a git repository #
{
 git -C "$(private.ogit.dir "$1")" rev-parse --git-dir >/dev/null 2>&1
}
ogit.repo.check.completion.dir() { compgen -d "$1"; }

ogit.repo.root.get()     # <?dir:$PWD> # echo the toplevel of the repository containing <dir> #
{
 git -C "${1:-$PWD}" rev-parse --show-toplevel 2>/dev/null
}
ogit.repo.root.get.completion.dir() { compgen -d "$1"; }

ogit.repo.share()     # <?dir:$OOSH_DIR> # make <dir>'s repository group-writable: core.sharedRepository group, setgid + g+w on .git #
{
 private.ogit.require || return $(result)
 local dir; dir=$(private.ogit.dir "$1")
 local gitDir; gitDir=$(git -C "$dir" rev-parse --absolute-git-dir 2>/dev/null)
 if [ -z "$gitDir" ]; then create.result 1 "ogit.repo.share: $dir is not a repository"; error.log "$RESULT"; return $(result); fi
 git -C "$dir" config core.sharedRepository group \
   && find "$gitDir" -type d -exec chmod g+s {} + \
   && chmod -R g+w "$gitDir" \
   && create.result 0 "shared: $dir" \
   || { create.result 1 "ogit.repo.share: could not set group mode on $gitDir"; error.log "$RESULT"; }
 return $(result)
}
ogit.repo.share.completion.dir() { compgen -d "$1"; }

ogit.repo.grep()     # <pattern> <?dir:$OOSH_DIR> <?pathspecs...> # git grep -nE <pattern> over the tracked files of <dir> (the tree sweeps) #
{
 local pattern="$1" dir; dir=$(private.ogit.dir "$2"); shift 2 2>/dev/null
 git -C "$dir" grep -nE "$pattern" -- "$@" 2>/dev/null
}

ogit.repo.files.list()     # <?dir:$OOSH_DIR> # echo the tracked files of <dir>, one per line #
{
 git -C "$(private.ogit.dir "$1")" ls-files 2>/dev/null
}
ogit.repo.files.list.completion.dir() { compgen -d "$1"; }
```

Also add the shared completers near the bottom (before `ogit.start`), used by every noun:

```bash
# ─────────────────────────────────────────────────────────────────────────────
# SHARED PARAMETER COMPLETION — direct git, no create.result (c2 rule)
# ─────────────────────────────────────────────────────────────────────────────
ogit.parameter.completion.branch() { ogit.branch.list all; }
ogit.parameter.completion.ref()    { ogit.branch.list all; ogit.tag.list; }
ogit.parameter.completion.tag()    { ogit.tag.list; }
ogit.parameter.completion.remote() { git -C "${OOSH_DIR:-.}" remote 2>/dev/null; }
ogit.parameter.completion.dir()    { compgen -d "$1"; }
```
(`ogit.branch.list` / `ogit.tag.list` arrive in Tasks 4 and 9; until then the completer prints nothing — fine.)

- [ ] **Step 4: Run** → PASS. `./ng/c2 function.completion ./ogit repo` lists the six methods.
- [ ] **Step 5: Commit** `git add ogit test/test.ogit && git commit -m "feat(ogit): repo noun — clone, check, root.get, share, grep, files.list"`

---

### Task 4: `branch` noun

**Files:** `ogit`, `test/test.ogit`

- [ ] **Step 1: Tests (RED)**

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
  ogit.branch.reset dev origin/dev "$w" >/dev/null 2>&1 && [ "$(git -C "$w" branch --show-current)" = dev ] || bad="$bad reset"
  test.ogit.commit "$w" two
  [ "$(ogit.branch.compare origin/dev dev "$w" >/dev/null; echo "$RESULT")" != "" ] || bad="$bad compare-empty"
  git -C "$w" checkout -q feature/x
  ogit.branch.merge dev t@t t "$w" >/dev/null 2>&1 || bad="$bad merge-rc=$?"
  [ "$(git -C "$w" rev-parse feature/x)" = "$(git -C "$w" rev-parse dev)" ] || bad="$bad merge-ff"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "branch: get/list/check/find/checkout/reset/compare/merge behave" || create.result 1 "branch:$bad"
  return $(result)
}
test.case $level "T-OGIT-BRANCH: the branch noun" test.ogit.branch
expect 0 "branch: get/list/check/find/checkout/reset/compare/merge behave" "the branch noun"
```

- [ ] **Step 2: Run** → FAIL (functions missing).

- [ ] **Step 3: Implement**

```bash
ogit.branch.get()     # <?dir:$OOSH_DIR> # echo the current branch of <dir>, sanitised (refs/heads/, refs/remotes/origin/, heads/origin/, origin/ stripped); empty when detached or not a repo #
{
 # Moved from this.git.branch.short (this:903). Degenerate names like
 # heads/origin/dev come from `git worktree add <path> heads/origin/dev` or
 # `checkout -b origin/dev`; callers concatenate `origin/` onto the answer.
 local b; b=$(git -C "$(private.ogit.dir "$1")" rev-parse --abbrev-ref HEAD 2>/dev/null)
 b="${b#refs/heads/}"; b="${b#refs/remotes/origin/}"; b="${b#heads/origin/}"; b="${b#origin/}"
 printf '%s' "$b"
}
ogit.branch.get.completion.dir() { compgen -d "$1"; }

ogit.branch.list()     # <?source:local> <?dir:$OOSH_DIR> # echo branch names one per line: local, remote (cached origin/* refs, offline) or all #
{
 local source="${1:-local}" dir; dir=$(private.ogit.dir "$2")
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
 git -C "$(private.ogit.dir "$2")" rev-parse --verify --quiet "$1" >/dev/null 2>&1
}
ogit.branch.check.completion.ref() { ogit.parameter.completion.ref "$@"; }

ogit.branch.find()     # <commit> <?dir:$OOSH_DIR> # echo every branch (local and remote) containing <commit> #
{
 git -C "$(private.ogit.dir "$2")" branch -a --contains "$1" --format='%(refname:short)' 2>/dev/null
}

ogit.branch.checkout()     # <ref> <?dir:$OOSH_DIR> # check <ref> out in <dir> #
{
 private.ogit.require || return $(result)
 if git -C "$(private.ogit.dir "$2")" checkout "$1" 2>/dev/null; then create.result 0 "checked out $1"
 else create.result 1 "could not check out $1 in $(private.ogit.dir "$2")"; fi
 return $(result)
}
ogit.branch.checkout.completion.ref() { ogit.parameter.completion.ref "$@"; }

ogit.branch.reset()     # <branch> <startPoint> <?dir:$OOSH_DIR> # create or reset <branch> at <startPoint> and check it out (checkout -B) #
{
 private.ogit.require || return $(result)
 if git -C "$(private.ogit.dir "$3")" checkout -B "$1" "$2" >/dev/null 2>&1; then create.result 0 "$1 reset to $2"
 else create.result 1 "could not reset $1 to $2"; fi
 return $(result)
}
ogit.branch.reset.completion.branch() { ogit.parameter.completion.branch "$@"; }
ogit.branch.reset.completion.startPoint() { ogit.parameter.completion.ref "$@"; }

ogit.branch.compare()     # <from> <to> <?dir:$OOSH_DIR> # RESULT = the alignment verdict of <to> against <from> (moved verbatim from promote.branch.alignment) #
{
 # PASTE promote.branch.alignment's body (promote:277-316 at 8c46828) here
 # UNCHANGED except: `this.git.commits.count "$OOSH_DIR" A B` → `ogit.commit.count A B "$dir"`
 # with `local dir; dir=$(private.ogit.dir "$3")` first. The four verdict strings
 # ("up to date with …", "… merged in", "N commits behind …", "diverged: …") are
 # pinned by test.promote — do not reword them.
 :
}
ogit.branch.compare.completion.from() { ogit.parameter.completion.branch "$@"; }
ogit.branch.compare.completion.to()   { ogit.parameter.completion.branch "$@"; }

ogit.branch.merge()     # <ref> <?asEmail> <?asName> <?dir:$OOSH_DIR> # merge <ref> into the current branch of <dir> (--no-edit); with <asEmail>/<asName> the merge commit carries that identity and no gpg signing #
{
 private.ogit.require || return $(result)
 local ref="$1" dir; dir=$(private.ogit.dir "$4")
 # $(private.ogit.identity) is unquoted on purpose: it is zero or six words.
 if git -C "$dir" $(private.ogit.identity "$2" "$3") merge "$ref" --no-edit 2>/dev/null; then
   create.result 0 "merged $ref"
 else
   create.result 1 "merge of $ref failed in $dir — conflicts? see ogit conflict.list"
 fi
 return $(result)
}
ogit.branch.merge.completion.ref() { ogit.parameter.completion.ref "$@"; }
```

- [ ] **Step 4: Run** → PASS. Commit: `feat(ogit): branch noun`.

---

### Task 5: `merge` and `conflict` nouns

- [ ] **Step 1: Test (RED)** — a fixture with a real conflict:

```bash
test.ogit.mergeConflict() {
  local fx bad="" w; fx=$(test.ogit.fixture conflict); w="$fx/work"
  git -C "$w" checkout -q -b other; printf 'theirs\n' > "$w/file"; git -C "$w" -c user.email=t@t -c user.name=t commit -qam theirs
  git -C "$w" checkout -q dev; printf 'ours\n' > "$w/file"; git -C "$w" -c user.email=t@t -c user.name=t commit -qam ours
  local base; base=$(ogit.merge.base.get dev other "$w")
  [ "$base" = "$(git -C "$w" rev-parse dev~1)" ] || bad="$bad base=$base"
  ogit.branch.merge other t@t t "$w" >/dev/null 2>&1 && bad="$bad conflicting-merge-passed"
  [ "$(ogit.conflict.list "$w")" = file ] || bad="$bad list=$(ogit.conflict.list "$w")"
  ogit.conflict.resolve.theirs file "$w" >/dev/null 2>&1 || bad="$bad resolve-rc=$?"
  [ "$(cat "$w/file")" = theirs ] || bad="$bad resolved-content"
  [ -z "$(ogit.conflict.list "$w")" ] || bad="$bad still-conflicted"
  ogit.merge.abort "$w" >/dev/null 2>&1 || bad="$bad abort-rc=$?"
  [ "$(cat "$w/file")" = ours ] || bad="$bad abort-content"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "merge.base.get, conflict.list, conflict.resolve.theirs, merge.abort behave" || create.result 1 "merge/conflict:$bad"
  return $(result)
}
test.case $level "T-OGIT-MERGE-CONFLICT: merge and conflict nouns" test.ogit.mergeConflict
expect 0 "merge.base.get, conflict.list, conflict.resolve.theirs, merge.abort behave" "promote's conflict path"
```

- [ ] **Step 2: Implement**

```bash
ogit.merge.abort()     # <?dir:$OOSH_DIR> # abort the merge in progress in <dir> #
{
 private.ogit.require || return $(result)
 if git -C "$(private.ogit.dir "$1")" merge --abort 2>/dev/null; then create.result 0 "merge aborted"; else create.result 1 "no merge to abort in $(private.ogit.dir "$1")"; fi
 return $(result)
}
ogit.merge.abort.completion.dir() { compgen -d "$1"; }

ogit.merge.base.get()     # <a> <b> <?dir:$OOSH_DIR> # echo the merge base commit of <a> and <b> #
{
 git -C "$(private.ogit.dir "$3")" merge-base "$1" "$2" 2>/dev/null
}
ogit.merge.base.get.completion.a() { ogit.parameter.completion.ref "$@"; }
ogit.merge.base.get.completion.b() { ogit.parameter.completion.ref "$@"; }

ogit.conflict.list()     # <?dir:$OOSH_DIR> # echo the conflicted paths of the merge in progress, one per line #
{
 git -C "$(private.ogit.dir "$1")" diff --name-only --diff-filter=U 2>/dev/null
}
ogit.conflict.list.completion.dir() { compgen -d "$1"; }

ogit.conflict.resolve.theirs()     # <file> <?dir:$OOSH_DIR> # resolve <file>'s conflict by taking the merged-in side and stage it #
{
 private.ogit.require || return $(result)
 local dir; dir=$(private.ogit.dir "$2")
 if git -C "$dir" checkout --theirs -- "$1" 2>/dev/null && git -C "$dir" add -- "$1" 2>/dev/null; then create.result 0 "took theirs for $1"
 else create.result 1 "could not resolve $1"; fi
 return $(result)
}
ogit.conflict.resolve.theirs.completion.file() { ogit.conflict.list; }
```

- [ ] **Step 3: Run → PASS. Commit** `feat(ogit): merge and conflict nouns`.

---

### Task 6: `remote` noun

- [ ] **Step 1: Test (RED)**

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
  ogit.remote.fetch "$w" >/dev/null 2>&1 || bad="$bad fetch-rc=$?"
  [ "$(git -C "$w" rev-parse origin/dev)" = "$(git -C "$c/w" rev-parse dev)" ] || bad="$bad fetch-ref"
  ogit.remote.pull "$w" >/dev/null 2>&1 || bad="$bad pull-rc=$?"
  [ "$(git -C "$w" rev-parse dev)" = "$(git -C "$c/w" rev-parse dev)" ] || bad="$bad pull-sha"
  rm -rf "$fx" "$c"
  [ -z "$bad" ] && create.result 0 "remote: url.get/branch.list/fetch/pull/push behave" || create.result 1 "remote:$bad"
  return $(result)
}
test.case $level "T-OGIT-REMOTE: the remote noun" test.ogit.remote
expect 0 "remote: url.get/branch.list/fetch/pull/push behave" "the remote noun"
```

- [ ] **Step 2: Implement**

```bash
ogit.remote.url.get()     # <?remote:origin> <?dir:$OOSH_DIR> # echo the URL of <remote>, empty when there is none #
{
 git -C "$(private.ogit.dir "$2")" remote get-url "${1:-origin}" 2>/dev/null
}
ogit.remote.url.get.completion.remote() { ogit.parameter.completion.remote "$@"; }

ogit.remote.branch.list()     # <?remote:origin> <?dir:$OOSH_DIR> # echo the branches <remote> has right now (ls-remote — needs the network); empty when unreachable #
{
 git -C "$(private.ogit.dir "$2")" ls-remote --heads "${1:-origin}" 2>/dev/null | sed 's|.*refs/heads/||'
}
ogit.remote.branch.list.completion.remote() { ogit.parameter.completion.remote "$@"; }

ogit.remote.fetch()     # <?dir:$OOSH_DIR> <?prune:no> # fetch origin into <dir>; prune=yes drops deleted remote branches #
{
 private.ogit.require || return $(result)
 local dir; dir=$(private.ogit.dir "$1") prune=""; [ "$2" = yes ] && prune="--prune"
 if git -C "$dir" fetch $prune origin 2>/dev/null; then create.result 0 "fetched origin into $dir"
 else create.result 1 "fetch from origin failed in $dir"; fi
 return $(result)
}
ogit.remote.fetch.completion.dir()   { compgen -d "$1"; }
ogit.remote.fetch.completion.prune() { echo no; echo yes; }

ogit.remote.pull()     # <?dir:$OOSH_DIR> <?url> <?branch> # pull into <dir>; with <url> <branch> pull that branch from that URL instead of the tracking remote (oo.update's https fallback) #
{
 private.ogit.require || return $(result)
 local dir; dir=$(private.ogit.dir "$1") rc
 if [ -n "$2" ]; then git -C "$dir" pull "$2" "$3"; rc=$?; else git -C "$dir" pull; rc=$?; fi
 [ "$rc" = 0 ] && create.result 0 "pulled into $dir" || create.result "$rc" "pull failed in $dir (rc=$rc)"
 return $(result)
}
ogit.remote.pull.completion.dir()    { compgen -d "$1"; }
ogit.remote.pull.completion.branch() { ogit.parameter.completion.branch "$@"; }

ogit.remote.push()     # <?branch> <?tags:no> <?dir:$OOSH_DIR> # push <branch> (default: the tracking branch) to origin; tags=yes pushes tags too #
{
 private.ogit.require || return $(result)
 local branch="$1" dir; dir=$(private.ogit.dir "$3") tags=""; [ "$2" = yes ] && tags="--tags"
 if [ -n "$branch" ]; then git -C "$dir" push origin "$branch" $tags 2>/dev/null; else git -C "$dir" push $tags 2>/dev/null; fi \
   && create.result 0 "pushed ${branch:-tracking branch}${tags:+ with tags}" \
   || create.result 1 "push of ${branch:-tracking branch} rejected — pull/resolve first"
 return $(result)
}
ogit.remote.push.completion.branch() { ogit.parameter.completion.branch "$@"; }
ogit.remote.push.completion.tags()   { echo no; echo yes; }
```

- [ ] **Step 3: Run → PASS. Commit** `feat(ogit): remote noun`.

---

### Task 7: `index` and `commit` nouns

- [ ] **Step 1: Test (RED)**

```bash
test.ogit.commit() {
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
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "index.add, commit.create/count/show/log.show behave" || create.result 1 "index/commit:$bad"
  return $(result)
}
test.case $level "T-OGIT-COMMIT: index and commit nouns" test.ogit.commit
expect 0 "index.add, commit.create/count/show/log.show behave" "index and commit nouns"
```

- [ ] **Step 2: Implement**

```bash
ogit.index.add()     # <?scope:all> <?dir:$OOSH_DIR> <?paths...> # stage: all (-A), updated (-u, tracked files only), or the given <paths> #
{
 private.ogit.require || return $(result)
 local scope="${1:-all}" dir; dir=$(private.ogit.dir "$2"); shift 2 2>/dev/null
 if [ $# -gt 0 ]; then git -C "$dir" add -- "$@"
 elif [ "$scope" = updated ]; then git -C "$dir" add -u
 else git -C "$dir" add -A; fi \
   && create.result 0 "staged ${*:-$scope}" || create.result 1 "add failed in $dir"
 return $(result)
}
ogit.index.add.completion.scope() { echo all; echo updated; }

ogit.commit.create()     # <?message> <?asEmail> <?asName> <?dir:$OOSH_DIR> # commit the index of <dir>; no <message> opens the editor; <asEmail>/<asName> give a bot identity without gpg signing #
{
 private.ogit.require || return $(result)
 local msg="$1" dir; dir=$(private.ogit.dir "$4")
 if [ -n "$msg" ]; then git -C "$dir" $(private.ogit.identity "$2" "$3") commit -q -m "$msg"
 else git -C "$dir" $(private.ogit.identity "$2" "$3") commit; fi \
   && create.result 0 "committed: ${msg:-(editor)}" || create.result 1 "commit failed in $dir (nothing staged?)"
 return $(result)
}
ogit.commit.create.completion.message() { :; }

ogit.commit.show()     # <ref> <?dir:$OOSH_DIR> # show commit <ref> #
{
 git -C "$(private.ogit.dir "$2")" show "$1" 2>/dev/null
}
ogit.commit.show.completion.ref() { ogit.parameter.completion.ref "$@"; }

ogit.commit.count()     # <from> <to> <?dir:$OOSH_DIR> # RESULT = number of commits in <to> that are not in <from> (refs/heads/ when bare names); "0" when a ref is missing #
{
 # Moved from this.git.commits.count (this:921). The refs may legitimately not
 # exist on test rigs without remotes — empty counts as 0.
 if [ -z "$1" ] || [ -z "$2" ]; then create.result 1 "ogit.commit.count requires <from> <to>"; error.log "$RESULT"; return $(result); fi
 local dir; dir=$(private.ogit.dir "$3") from="$1" to="$2" n
 case "$from" in */*) ;; *) from="refs/heads/$from" ;; esac
 case "$to"   in */*) ;; *) to="refs/heads/$to" ;; esac
 n=$(git -C "$dir" rev-list --count "$from..$to" 2>/dev/null)
 create.result 0 "${n:-0}"
 return $(result)
}
ogit.commit.count.completion.from() { ogit.parameter.completion.branch "$@"; }
ogit.commit.count.completion.to()   { ogit.parameter.completion.branch "$@"; }

ogit.commit.log.show()     # <?range> <?limit> <?format> <?dir:$OOSH_DIR> # git log of <range> (default HEAD), at most <limit> commits; <format> is oneline or a --pretty=format: string #
{
 local range="$1" limit="$2" format="$3" dir; dir=$(private.ogit.dir "$4")
 local -a args=()
 [ -n "$limit" ] && args+=("-$limit")
 case "$format" in "") ;; oneline) args+=(--oneline) ;; *) args+=("--pretty=format:$format") ;; esac
 git -C "$dir" log "${args[@]}" ${range:+"$range"} 2>/dev/null
}
ogit.commit.log.show.completion.format() { echo oneline; echo '%h %ci'; }
```

- [ ] **Step 3: Run → PASS. Commit** `feat(ogit): index and commit nouns`.

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
 local dir; dir=$(private.ogit.dir "$2")
 case "${1:-short}" in
   porcelain) git -C "$dir" status --porcelain 2>/dev/null ;;
   *)         git -C "$dir" status --short --branch 2>/dev/null ;;
 esac
}
ogit.status.show.completion.format() { echo short; echo porcelain; }

ogit.status.check()     # <?dir:$OOSH_DIR> # rc 0 when the working tree and the index of <dir> are clean #
{
 local dir; dir=$(private.ogit.dir "$1")
 git -C "$dir" diff --quiet 2>/dev/null && git -C "$dir" diff --cached --quiet 2>/dev/null
}
ogit.status.check.completion.dir() { compgen -d "$1"; }

ogit.diff.check()     # <?dir:$OOSH_DIR> <?paths...> # rc 0 when <paths> (default: everything) have no unstaged changes #
{
 local dir; dir=$(private.ogit.dir "$1"); shift 2>/dev/null
 git -C "$dir" diff --quiet -- "$@" 2>/dev/null
}
ogit.diff.check.completion.dir() { compgen -d "$1"; }

ogit.diff.show()     # <a> <b> <?format:stat> <?dir:$OOSH_DIR> # diff between <a> and <b> (three-dot); format stat or full #
{
 local dir; dir=$(private.ogit.dir "$4")
 case "${3:-stat}" in
   stat) git -C "$dir" diff --stat "$1...$2" 2>/dev/null ;;
   *)    git -C "$dir" diff "$1...$2" 2>/dev/null ;;
 esac
}
ogit.diff.show.completion.a() { ogit.parameter.completion.ref "$@"; }
ogit.diff.show.completion.b() { ogit.parameter.completion.ref "$@"; }
ogit.diff.show.completion.format() { echo stat; echo full; }
```

- [ ] **Step 3: Run → PASS. Commit** `feat(ogit): status and diff nouns`.

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
 git -C "$(private.ogit.dir "$2")" tag -l ${1:+"$1"} --sort=-creatordate 2>/dev/null
}
ogit.tag.list.completion.pattern() { echo 'v*'; echo 'testing-*'; }

ogit.tag.check()     # <tag> <?dir:$OOSH_DIR> # rc 0 when <tag> exists #
{
 git -C "$(private.ogit.dir "$2")" rev-parse --verify --quiet "refs/tags/$1" >/dev/null 2>&1
}
ogit.tag.check.completion.tag() { ogit.parameter.completion.tag "$@"; }

ogit.tag.latest.get()     # <?pattern:v*> <?dir:$OOSH_DIR> # echo the highest tag matching <pattern> by version sort #
{
 git -C "$(private.ogit.dir "$2")" tag -l "${1:-v*}" --sort=-version:refname 2>/dev/null | head -1
}
ogit.tag.latest.get.completion.pattern() { echo 'v*'; echo 'testing-*'; }

ogit.tag.create()     # <tag> <?ref:HEAD> <?dir:$OOSH_DIR> # create lightweight <tag> at <ref> #
{
 private.ogit.require || return $(result)
 if git -C "$(private.ogit.dir "$3")" tag "$1" "${2:-HEAD}" 2>/dev/null; then create.result 0 "tagged $1"; else create.result 1 "could not tag $1 (exists?)"; fi
 return $(result)
}
ogit.tag.create.completion.ref() { ogit.parameter.completion.ref "$@"; }

ogit.stash.push()     # <message> <?dir:$OOSH_DIR> # stash the working tree of <dir> under <message> #
{
 private.ogit.require || return $(result)
 if git -C "$(private.ogit.dir "$2")" stash push -q -m "$1" 2>/dev/null; then create.result 0 "stashed: $1"; else create.result 1 "stash push failed"; fi
 return $(result)
}
ogit.stash.push.completion.message() { :; }

ogit.stash.pop()     # <?dir:$OOSH_DIR> # pop the top stash of <dir> #
{
 private.ogit.require || return $(result)
 if git -C "$(private.ogit.dir "$1")" stash pop -q 2>/dev/null; then create.result 0 "stash popped"; else create.result 1 "stash pop failed (nothing stashed, or conflicts)"; fi
 return $(result)
}
ogit.stash.pop.completion.dir() { compgen -d "$1"; }

ogit.stash.top.get()     # <?dir:$OOSH_DIR> # echo the message of stash@{0}, empty when the stack is empty #
{
 git -C "$(private.ogit.dir "$1")" stash list --format=%s -1 2>/dev/null
}
ogit.stash.top.get.completion.dir() { compgen -d "$1"; }
```

- [ ] **Step 3: Run → PASS. Commit** `feat(ogit): tag and stash nouns`.

---

### Task 10: `config` and `safeDirectory` nouns (moved from `oo`)

**Files:** `ogit`, `test/test.ogit`, `oo:397-461`, `test/test.oo` (the safeDirectory cases: search `safeDirectory` in test.oo and move them to test.ogit with the method names renamed)

- [ ] **Step 1: Test (RED)** — sandboxed via `GIT_CONFIG_GLOBAL`:

```bash
test.ogit.trust() {
  local fx bad="" w; fx=$(test.ogit.fixture trust); w="$fx/work"
  export GIT_CONFIG_GLOBAL="$fx/gitconfig"; : > "$GIT_CONFIG_GLOBAL"
  ogit.config.set user.email me@fx "$w" >/dev/null 2>&1 || bad="$bad set-rc"
  [ "$(ogit.config.get user.email "$w")" = me@fx ] || bad="$bad get=$(ogit.config.get user.email "$w")"
  [ "$(ogit.config.email.get "$w")" = me@fx ] || bad="$bad email"
  ogit.safeDirectory.add "$w" >/dev/null 2>&1; ogit.safeDirectory.add "$w" >/dev/null 2>&1
  [ "$(ogit.safeDirectory.list | grep -cx "$w")" = 1 ] || bad="$bad add-not-idempotent"
  mkdir -p "$fx/base/main/.git" "$fx/base/prod/.git" "$fx/base/notarepo"
  ogit.safeDirectory.ensure "$fx/base" >/dev/null 2>&1 || bad="$bad ensure-rc"
  ogit.safeDirectory.list | grep -qx "$fx/base/main" || bad="$bad ensure-main"
  ogit.safeDirectory.list | grep -qx "$fx/base/prod" || bad="$bad ensure-prod"
  ogit.safeDirectory.list | grep -qx "$fx/base/notarepo" && bad="$bad ensure-took-nonrepo"
  ogit.safeDirectory.add "$fx/gone" >/dev/null 2>&1
  ogit.safeDirectory.prune >/dev/null 2>&1
  ogit.safeDirectory.list | grep -qx "$fx/gone" && bad="$bad prune-kept-missing"
  ogit.safeDirectory.list | grep -qx "$w" || bad="$bad prune-dropped-existing"
  ogit.safeDirectory.clear >/dev/null 2>&1; [ -z "$(ogit.safeDirectory.list)" ] || bad="$bad clear"
  unset GIT_CONFIG_GLOBAL; rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "config.get/set/email.get and safeDirectory.add/list/ensure/prune/clear behave" || create.result 1 "trust:$bad"
  return $(result)
}
test.case $level "T-OGIT-TRUST: config and safeDirectory nouns (sandboxed GIT_CONFIG_GLOBAL)" test.ogit.trust
expect 0 "config.get/set/email.get and safeDirectory.add/list/ensure/prune/clear behave" "config and safeDirectory nouns"
```

- [ ] **Step 2: Implement**

```bash
ogit.config.get()     # <key> <?dir:$OOSH_DIR> # echo <key> from the global git config, else from <dir>'s repository config #
{
 git config --global --get "$1" 2>/dev/null || git -C "$(private.ogit.dir "$2")" config --get "$1" 2>/dev/null
}
ogit.config.get.completion.key() { echo user.email; echo user.name; echo core.sharedRepository; }

ogit.config.set()     # <key> <value> <?dir:$OOSH_DIR> # set <key> in <dir>'s repository config #
{
 private.ogit.require || return $(result)
 if git -C "$(private.ogit.dir "$3")" config "$1" "$2" 2>/dev/null; then create.result 0 "$1=$2"; else create.result 1 "could not set $1"; fi
 return $(result)
}
ogit.config.set.completion.key() { echo user.email; echo user.name; echo core.sharedRepository; }

ogit.config.email.get()     # <?dir:$OOSH_DIR> # echo the committer email: global user.email, else <dir>'s #
{
 ogit.config.get user.email "$1"
}
ogit.config.email.get.completion.dir() { compgen -d "$1"; }

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
ogit.safeDirectory.add.completion.path() { compgen -d "$1"; }

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
 local base="$1" d added=0
 [ -n "$base" ] || base=$(oo mode.base.get 2>/dev/null)
 if [ -z "$base" ] || [ ! -d "$base" ]; then create.result 1 "ogit.safeDirectory.ensure: no base (pass <base> or fix oo mode.base.get)"; error.log "$RESULT"; return $(result); fi
 for d in "$base"/*/; do
   d="${d%/}"
   [ -e "$d/.git" ] || continue
   ogit.safeDirectory.add "$d" >/dev/null || return $(result)
   case "$RESULT" in added:*) added=$((added + 1)) ;; esac
 done
 create.result 0 "safe.directory ensured under $base ($added added)"; return $(result)
}
ogit.safeDirectory.ensure.completion.base() { compgen -d "$1"; }
```

- [ ] **Step 3: Aliases in `oo`** — replace the bodies at `oo:397-461` with:

```bash
oo.safeDirectory.prune() # # remove git safe.directory entries whose paths no longer exist on disk (delegates to ogit safeDirectory.prune)
{ private.oo.ogit.load; ogit.safeDirectory.prune "$@"; }

private.oo.safeDirectory.add() # <path> # idempotently add path to git's global safe.directory list (delegates to ogit safeDirectory.add)
{ private.oo.ogit.load; ogit.safeDirectory.add "$@"; }

private.oo.ogit.load() # # source ogit once into this shell (oo is sourced by tests and by the ooShim, so this cannot be at file scope) #
{ [ "$(type -t ogit.safeDirectory.add)" = function ] || source "$OOSH_DIR/ogit" >/dev/null 2>&1; }
```
Place `private.oo.ogit.load` via `oo method.new private.oo.ogit.load`. Move the safeDirectory tests from `test/test.oo` to `test/test.ogit` (rename the method calls); keep in `test.oo` one case `T-SAFEDIR-DELEGATES` that asserts `declare -f oo.safeDirectory.prune | grep -q ogit.safeDirectory.prune`.

- [ ] **Step 4: Run** `./test.suite run ogit 1` and `./test.suite run oo 1` → PASS. **Commit** `feat(ogit): config and safeDirectory nouns — moved from oo, oo delegates`.

---

### Task 11: `worktree`, `binary`, `raw`

- [ ] **Step 1: Test (RED)**

```bash
test.ogit.worktree() {
  local fx bad="" w; fx=$(test.ogit.fixture worktree); w="$fx/work"
  git -C "$w" branch -q prod
  ogit.worktree.add prod "$fx/prod" origin/dev "$w" >/dev/null 2>&1 || bad="$bad add-rc=$?"
  [ -f "$fx/prod/.git" ] || bad="$bad add-shape"
  ogit.worktree.list "$w" | grep -q "^worktree $(cd "$fx/prod" && pwd -P)$" || bad="$bad list"
  [ "$(ogit.worktree.find prod "$w")" = "$(cd "$fx/prod" && pwd -P)" ] || bad="$bad find=[$(ogit.worktree.find prod "$w")]"
  [ -z "$(ogit.worktree.find nosuch "$w")" ] || bad="$bad find-nosuch"
  ogit.binary.check || bad="$bad binary"
  [ "$(ogit.raw "$w" rev-parse --abbrev-ref HEAD)" = dev ] || bad="$bad raw"
  rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "worktree.add/list/find, binary.check, raw behave" || create.result 1 "worktree:$bad"
  return $(result)
}
test.case $level "T-OGIT-WORKTREE: worktree noun, binary.check, raw" test.ogit.worktree
expect 0 "worktree.add/list/find, binary.check, raw behave" "worktree noun"
```

- [ ] **Step 2: Implement**

```bash
ogit.worktree.add()     # <branch> <targetDir> <startPoint> <?dir:$OOSH_DIR> # add <targetDir> as a linked worktree of <dir> with <branch> (re)created at <startPoint> #
{
 private.ogit.require || return $(result)
 if git -C "$(private.ogit.dir "$4")" worktree add -B "$1" "$2" "$3" 2>/dev/null && [ -d "$2" ]; then create.result 0 "worktree $2 on $1"
 else create.result 1 "git worktree add failed for $1 → $2"; fi
 return $(result)
}
ogit.worktree.add.completion.branch() { ogit.parameter.completion.branch "$@"; }
ogit.worktree.add.completion.targetDir() { compgen -d "$1"; }
ogit.worktree.add.completion.startPoint() { ogit.parameter.completion.ref "$@"; }

ogit.worktree.list()     # <?dir:$OOSH_DIR> # git worktree list --porcelain of <dir>'s repository #
{
 git -C "$(private.ogit.dir "$1")" worktree list --porcelain 2>/dev/null
}
ogit.worktree.list.completion.dir() { compgen -d "$1"; }

ogit.worktree.find()     # <branch> <?dir:$OOSH_DIR> # echo the folder that has <branch> checked out: a linked worktree of <dir>'s repository (Phase 2 adds the sibling clone <base>/<branch>); empty when none #
{
 ogit.worktree.list "$2" | awk -v ref="refs/heads/$1" '/^worktree / { wt=$2; next } $1 == "branch" && $2 == ref { print wt; exit }'
}
ogit.worktree.find.completion.branch() { ogit.parameter.completion.branch "$@"; }

ogit.binary.check()     # # rc 0 when the git binary is on PATH #
{
 command -v git >/dev/null 2>&1
}
ogit.binary.check.completion() { :; }

ogit.raw()     # <dir> <args...> # run git -C <dir> <args...> verbatim — the documented last resort; every use needs a comment saying why no method fits #
{
 private.ogit.require || return $(result)
 local dir="$1"; shift
 git -C "$dir" "$@"
}
ogit.raw.completion.dir() { compgen -d "$1"; }
```

- [ ] **Step 3: Run → PASS. Commit** `feat(ogit): worktree noun, binary.check, raw`.

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

- [ ] **Step 2: Implement in `this`** (replace `this.git.branch.short` and `this.git.commits.count` bodies; keep their docstrings and completions):

```bash
private.this.ogit.load() # # source ogit once into this shell; this cannot source it at file scope (ogit sources this) #
{ [ "$(type -t ogit.branch.get)" = function ] || source "$OOSH_DIR/ogit" >/dev/null 2>&1; }

this.git.branch.short() # <?gitDir:$OOSH_DIR> # print the sanitised short branch name of <gitDir> (delegates to ogit branch.get)
{ private.this.ogit.load; ogit.branch.get "$@"; }

this.git.commits.count() # <gitDir> <fromRef> <toRef> # count commits in <toRef> not in <fromRef>; RESULT = count (delegates to ogit commit.count)
{ private.this.ogit.load; ogit.commit.count "$2" "$3" "$1"; }
```
Note the argument order flip: `this.git.commits.count <gitDir> <from> <to>` → `ogit.commit.count <from> <to> <dir>`.

- [ ] **Step 3: `promote.branch.alignment`** becomes `{ private.promote.ogit.load; ogit.branch.compare "$1" "$2" "$OOSH_DIR"; }` with `private.promote.ogit.load` defined like `private.oo.ogit.load` (via `oo method.new`). Paste the original body into `ogit.branch.compare` (Task 4 placeholder) now.

- [ ] **Step 4: Re-aim pins**
  - `test/test.ossh:720-735` (T-BRANCH-SHORT-STRIP-*): `BRANCH_BODY=$(declare -f ogit.branch.get 2>/dev/null)` after `private.this.ogit.load` — the four `${b#…}` strips are asserted there.
  - `test/test.ossh:738-748` (T-BRANCH-SHORT-CALLER): accept either name: `grep -qE 'this\.git\.branch\.short|ogit\.branch\.get'`.
  - `test/test.promote` alignment cases: call `promote.branch.alignment` as before (alias) — they should pass unchanged; if a case greps the body, point it at `ogit.branch.compare`.

- [ ] **Step 5: Run** `this`, `ossh`, `promote`, `ogit` suites → PASS. **Commit** `refactor(this,promote): git wrappers delegate to ogit; pins re-aimed`.

---

### Task 13: The sweep — `T-OGIT-ONLY-CALLER` and its planted twin

**Files:** `test/test.ogit`

- [ ] **Step 1: Write the sweep as an ogit method?** No — it is a test-only rule. Add to `test/test.ogit`:

```bash
# ============================================================================
# T-OGIT-ONLY-CALLER: no raw `git` invocation outside ogit
# ============================================================================
# Exceptions carry `# ogit-exception: <reason>` on the line or the line above,
# or `# ogit-exception-file: <reason>` anywhere in the file (init/oosh,
# init/once). test/, docs/, old/, restore/, .github/, .claude/ and *.md are out
# of scope; ogit itself is the caller.
test.ogit.rawGitCalls() { # <?treeRoot:$OOSH_DIR> # echo file:line:text of every raw git call that is neither ogit nor excepted
  local root="${1:-$OOSH_DIR}" hit file line prev
  git -C "$root" grep -nE '(^|[^A-Za-z0-9_./-])git[[:space:]]+[a-z-]+' -- \
      ':!ogit' ':!init/oosh' ':!init/once' ':!test' ':!old' ':!restore' ':!docs' ':!.github' ':!.claude' ':!*.md' 2>/dev/null \
    | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' \
    | grep -vE '(echo |printf |\.log |die |User git|for pkg in|compgen -W|ogit-exception)' \
    | while IFS= read -r hit; do
        file="${hit%%:*}"; line="${hit#*:}"; line="${line%%:*}"
        grep -q 'ogit-exception-file:' "$root/$file" && continue
        prev=$(sed -n "$((line - 1))p" "$root/$file")
        case "$prev" in *ogit-exception:*) continue ;; esac
        printf '%s\n' "$hit"
      done
}

test.ogit.onlyCaller() {
  local hits; hits=$(test.ogit.rawGitCalls)
  if [ -z "$hits" ]; then create.result 0 "ogit is the only git caller"; else create.result 1 "raw git outside ogit:
$hits"; fi
  return $(result)
}
test.case $level "T-OGIT-ONLY-CALLER: no raw git invocation outside ogit (marked exceptions aside)" test.ogit.onlyCaller
expect 0 "ogit is the only git caller" "D2 of the 2026-09-23 design"

# The sweep must be able to fail: plant a violation in a fixture tree and watch it.
test.ogit.onlyCallerRejects() {
  local fx; fx=$(test.suite.fixture.make plant); git init -q "$fx"
  printf '%s\n' '#!/usr/bin/env bash' 'x=$(git rev-parse HEAD)' > "$fx/planted"
  printf '%s\n' '# ogit-exception: fixture proves the marker' 'y=$(git status)' > "$fx/excused"
  git -C "$fx" add planted excused; git -C "$fx" -c user.email=t@t -c user.name=t commit -q -m plant
  local hits; hits=$(test.ogit.rawGitCalls "$fx"); rm -rf "$fx"
  case "$hits" in
    planted:2:*) [ "$(printf '%s\n' "$hits" | grep -c .)" = 1 ] && create.result 0 "the sweep finds a planted call and honours the marker" || create.result 1 "unexpected hits: $hits" ;;
    *) create.result 1 "the sweep missed the planted call: [$hits]" ;;
  esac
  return $(result)
}
test.case $level "T-OGIT-ONLY-CALLER-REJECTS: the sweep catches a planted raw git and honours ogit-exception" test.ogit.onlyCallerRejects
expect 0 "the sweep finds a planted call and honours the marker" "a sweep that cannot fail proves nothing"
```

- [ ] **Step 2: Run** → `T-OGIT-ONLY-CALLER` FAILS listing ~150 sites (this is the RED that Tasks 14-18 turn green); `-REJECTS` PASSES. **Commit** `test(ogit): the only-caller sweep, red against the current tree`.

---

### Task 14: Migrate `this`, `path`, `test.suite`, `config`, `os`, `claudeCode`, `osshLayout`

Each site: replace the call, keep behaviour, run that file's tests. The command form is needed only where a function is not in scope; in these files `ogit` functions are loaded with a `private.<script>.ogit.load` helper (create one per script with `oo method.new`, same one-liner as `private.oo.ogit.load`; in `this` use `private.this.ogit.load` from Task 12).

| Site | Before | After |
|---|---|---|
| this:246 `private.this.anchor.validate.one` | `git -C "$treeRoot" grep -nE "$pattern" -- <pathspecs>` | `private.this.ogit.load; ogit.repo.grep "$pattern" "$treeRoot" <pathspecs>` |
| path:54 `path.validate` | `git -C "$treeRoot" grep -nE 'PATH=' -- …` | `private.path.ogit.load; ogit.repo.grep '(^\|[^A-Za-z0-9_])PATH=' "$treeRoot" …` (keep the exact pattern that is there) |
| test.suite:1269 | `git -C "$root" ls-files \| head -1` | `ogit.repo.files.list "$root" \| head -1` |
| test.suite:1310 | `git -C … grep -nE "$pattern" …` | `ogit.repo.grep "$pattern" "$root" …` |
| config:280, user:973 | already `this.git.branch.short` | unchanged (alias) |
| os:107 | `git rev-parse --abbrev-ref HEAD` | `ogit.branch.get "$PWD"` |
| claudeCode:1439, 1503 | `git rev-parse --show-toplevel` | `ogit.repo.root.get` |
| osshLayout:47-49 | `command -v git`, `git config --global user.email \|\| git config user.email` | `ogit.binary.check`, `ogit.config.email.get "$PWD"` |

- [ ] Run: `./test.suite run this 1; run path 1; run test.suite 1; run config 1; run os 1; run claudeCode 1; run osshLayout 1` → PASS; `./path validate`, `./this anchor.validate all` → OK.
- [ ] Commit `refactor: this/path/test.suite/os/claudeCode/osshLayout call ogit`.

---

### Task 15: Migrate `oo` (≈50 sites, behaviour identical)

**Files:** `oo`; tests `test/test.oo`

Add `private.oo.ogit.load` calls at the top of each affected public method (or once in `oo.start` after `source this`: `source ogit` — preferred, since `oo` always sources `this` first; the ooShim sources `oo` and then needs `ogit` too: add `source "$dir/ogit"` next to its `source "$dir/oo"` line in `templates/user/ooShim`).

| Line(s) | Before | After |
|---|---|---|
| 253 `oo.commit` | `git branch \| line find "\*"` | `ogit.branch.get` (compare to `dev`) |
| 257-259 | `git add *; git commit; git push` | `ogit.index.add all; ogit.commit.create; ogit.remote.push` — note: `add *` skipped dotfiles, `all` uses `-A`; verify `git status` shows only ignored dotfiles before committing this change |
| 274, 288, 291 `oo.update` | `git pull`; `git symbolic-ref --short HEAD`; `git pull $url $branch` | `ogit.remote.pull "$OOSH_DIR"`; `ogit.branch.get`; `ogit.remote.pull "$OOSH_DIR" "$fallbackUrl" "$branch"` |
| 540 `oo.mode.base.get` | `git -C "$ooshDir" worktree list --porcelain \| head -1 \| sed …` | `ogit.worktree.list "$ooshDir" \| head -1 \| sed 's/^worktree //'` |
| 627, 629 `oo.mode.list` | `(cd "$dir" && git status --short --branch)` | `ogit.status.show short "$dir"` (T-MODE-NOLEAK must still pass: no safe.directory writes) |
| 673, 681, 683 `oo.branch.list` | `branch --format`, `fetch origin`, `branch -r` | `ogit.branch.list local`, `ogit.remote.fetch "$OOSH_DIR"`, `ogit.branch.list remote` |
| 740, 745 `oo.mode` | `status --short --branch`, `branch --show-current` | `ogit.status.show short "$current_target"`, `ogit.branch.get "$current_target"` |
| 792 | `git branch -r \| … grep -Fx "origin/$branch"` | `ogit.branch.list remote "$current_target" \| grep -Fx "$branch"` (then `remote_branch="origin/$branch"`) |
| 802 | `git worktree add -B … "$target_dir" "$remote_branch"` | `ogit.worktree.add "${remote_branch#origin/}" "$target_dir" "$remote_branch" "$current_target"` — keep the error text `git worktree add failed for` (test.oo:470 pins it) |
| 893, 910 `oo.mode.align` | `branch --show-current`, `checkout` | `ogit.branch.get`, `ogit.branch.checkout` |
| 1160, 1165 `oo.checkout` | `branch --show-current`, `checkout "$dirName"` | `ogit.branch.get "$targetDir"`, `ogit.branch.checkout "$dirName" "$targetDir"` |
| 1189, 1191 | `fetch origin`, `worktree add -B "$dirName" "$targetDir" "origin/$version"` | `ogit.remote.fetch "$oosh"`, `ogit.worktree.add "$dirName" "$targetDir" "origin/$version" "$oosh"` |
| 1203, 1228, 1230 | `remote get-url origin`, `fetch origin`, `clone "$repoUrl" -b "$version" "$targetDir"` | `ogit.remote.url.get origin "$oosh"`, `ogit.remote.fetch "$oosh"`, `ogit.repo.clone "$repoUrl" "$version" "$targetDir"` (it removes the half-made dir itself — drop the `rm -rf`) |
| 1256, 1260 completion | `ls-remote --heads origin`, `for-each-ref refs/remotes/origin` | `ogit.remote.branch.list origin "$oosh"`, fallback `ogit.branch.list remote "$oosh"` — re-aim test.oo:2179-2184 to grep for `ogit.remote.branch.list` and `ogit.branch.list remote` |
| 1357-1408 `oo.branches.check` | `fetch --prune`, `show`, `branch -a --contains`, `log -1 --pretty=format:…`, `merge-base`, `diff --stat A...B` | `ogit.remote.fetch "$OOSH_DIR" yes`, `ogit.commit.show`, `ogit.branch.find`, `ogit.commit.log.show "$bl" 1 '%cn/%cr/%H'`, `ogit.merge.base.get`, `ogit.diff.show "$bl" "$base" stat` |
| 1668-1701 `private.oo.shared.tree.from.local` | `rev-parse --verify`, `checkout -B`, `checkout main`, `rev-parse --git-dir`, `worktree add` ×2 | `ogit.branch.check main main`, `ogit.branch.check origin/main main`, `ogit.branch.reset main origin/main main`, `ogit.branch.checkout main main`, `ogit.repo.check main`, `ogit.worktree.add "$branch" "../$branch" "$branch" main \|\| ogit.worktree.add "$branch" "../$branch" "origin/$branch" main` |
| 2022, 2051, 2065 state 31 | `git clone git@github.com:… main`, `git fetch origin`, `git worktree add -B …` | `ogit.repo.clone git@github.com:Cerulean-Circle-GmbH/once.sh.git main main`, `ogit.remote.fetch "$PWD"`, `ogit.worktree.add "$OOSH_BRANCH" "../$OOSH_BRANCH" "origin/$OOSH_BRANCH" "$PWD"` (keep the `RETURN_VALUE` checks and messages) |
| 2146 | `git -C "$_wt" config core.sharedRepository group` | `ogit.config.set core.sharedRepository group "$_wt"` |
| 2539 `oo.install.dev` | `call git clone git@github.com:…` inside the `check … call` DSL | `call ogit repo.clone git@github.com:… <branch> <dir>` |
| 418-457 | done in Task 10 | — |

- [ ] Run `./test.suite run oo 1` → PASS (fix any re-aimed pin listed above). Also `T-OGIT-ONLY-CALLER` shrinks by ~50.
- [ ] Commit `refactor(oo): every git call goes through ogit`.

---

### Task 16: Migrate `promote` (≈55 sites, behaviour identical)

**Files:** `promote`; tests `test/test.promote`

Add `source ogit` in `promote.start` after `source this` (promote is also sourced by test.promote: keep `private.promote.ogit.load` from Task 12 for the sourced path).

| Line(s) | Before | After |
|---|---|---|
| 263-265 `promote.status` | `log -1 --format='%h %ci' refs/heads/X` | `ogit.commit.log.show refs/heads/X 1 '%h %ci' "$OOSH_DIR"` |
| 325, 329 `promote.report` | `tag -l 'testing-*' --sort=-creatordate --format=…` | `ogit.tag.list 'testing-*'` / `'v*'` (then format with `ogit.commit.log.show <tag> 1 '<format>'` if the original `--format` printed more than the name — check promote:325-333 and keep the output identical) |
| 489 | `status --porcelain` | `ogit.status.show porcelain "$OOSH_DIR"` |
| 611, 869 | `log --oneline testing..dev` / `prod..testing` | `ogit.commit.log.show testing..dev "" oneline "$OOSH_DIR"` |
| 628, 643-652 `rewrite.self.branch` | `branch --show-current`, `diff --quiet -- files`, `add files`, `-c … commit -m … -q` | `ogit.branch.get "$dir"`, `ogit.diff.check "$dir" init/oosh "Install oosh.command"`, `ogit.index.add all "$dir" init/oosh "Install oosh.command"`, `ogit.commit.create "chore(promote): …" oosh-promote@local "oosh promote" "$dir"` |
| 660 `find.worktree` | body | `ogit.worktree.find "$branch" "$ooshDir"` |
| 682, 684 `push.source.branch` | `remote get-url origin`, `push origin $b` | `[ -n "$(ogit.remote.url.get origin "$ooshDir")" ] \|\| return 0`; `ogit.remote.push "$sourceBranch" no "$ooshDir"` |
| 706-735 conflict helper | `branch --show-current`, `diff --name-only --diff-filter=U`, `checkout --theirs`, `add`, `-c … commit` | `ogit.branch.get`, `ogit.conflict.list`, `ogit.conflict.resolve.theirs "$f"`, `ogit.commit.create "Merge …" oosh-promote@local "oosh promote" "$dir"` |
| 751-792, 893-960 both merges | `diff --quiet`, `stash push -q -m`, `stash pop -q`, `checkout X`, `-c … merge X --no-edit`, `merge --abort` | `ogit.diff.check "$OOSH_DIR"`, `ogit.stash.push "promote: pre-merge stash" "$OOSH_DIR"`, `ogit.stash.pop "$OOSH_DIR"`, `ogit.branch.checkout testing "$OOSH_DIR"`, `ogit.branch.merge dev oosh-promote@local "oosh promote" "$mergeDir"`, `ogit.merge.abort "$mergeDir"` |
| 809, 814 | `tag -l "$tag" \| grep -q`, `tag "$tag"` | `ogit.tag.check "$tag" "$OOSH_DIR"`, `ogit.tag.create "$tag" HEAD "$OOSH_DIR"` |
| 829, 1024 | `push origin testing --tags` | `ogit.remote.push testing yes "$OOSH_DIR"` |
| 830, 1025 | `checkout dev` | `ogit.branch.checkout dev "$OOSH_DIR"` (test.promote:494 greps `checkout dev` — still matches) |
| 832-833, 1027-1028 | `stash list \| head -1 \| grep -q "promote: pre-merge stash"` then pop | `case "$(ogit.stash.top.get "$OOSH_DIR")" in *"promote: pre-merge stash"*) ogit.stash.pop "$OOSH_DIR" ;; esac` |
| 976, 1009 | `tag -l 'v*' --sort=-version:refname \| head -1`, `tag "$newTag" prod` | `ogit.tag.latest.get 'v*' "$OOSH_DIR"`, `ogit.tag.create "$newTag" prod "$OOSH_DIR"` |
| `GIT_PAGER` save/restore (218-331) | keep | keep (not an invocation) |

- [ ] Run `./test.suite run promote 1` → PASS. Commit `refactor(promote): every git call goes through ogit`.

---

### Task 17: Migrate `user`, `ossh`, `hiveMind`, `scrumMaster`, `context`, `agentRoom`, `snet`, `otest`

| Site | After |
|---|---|
| user:1070, 1075 (`private.as.user $u git config --global --add safe.directory …`) | command form through the as-user preamble: `private.as.user "$username" bash -c "$(private.this.as.user.preamble.get "$username" "$targetHome" "$sharedOosh")
    '$sharedOosh/ogit' safeDirectory.add '$sharedOosh'"` (and the osascript canonical-case variant the same way) |
| user:1154 | `_ownerEmail=$(private.as.user "$username" bash -c "$(private.this.as.user.preamble.get …)
    '$sharedOosh/ogit' config.email.get" 2>/dev/null) \|\| true` |
| ossh:580-581 | `ogit.config.email.get "$PWD"` (ossh.start already sources this; add `source ogit` there) |
| ossh:640 (remote jump host) | `ossh.exec "$jumpHost" "command -v ogit >/dev/null 2>&1 && ogit config.email.get \|\| git config --global user.email \|\| git config user.email"` with `# ogit-exception: jump host may have no oosh` on the line above |
| ossh:1180, 1187 | `ogit.binary.check`, `ogit.remote.url.get origin "$repo"` |
| hiveMind ×11 `rev-parse --show-toplevel` | `ogit.repo.root.get` (hiveMind sources this; add `source ogit` in `hiveMind.start`) |
| hiveMind:1753 (remote) | `ossh exec "$host" "~/oosh/ogit remote.pull"` |
| hiveMind:4060-4069 auto.commit | `ogit.status.check && return 0`; `ogit.index.add updated`; `ogit.commit.create "$msg"`; `ogit.remote.push "" no "$dir" &` |
| hiveMind:4126-4208, scrumMaster:643-741, 1444 | `ogit.branch.get`, `ogit.commit.log.show "" 1 oneline`, `ogit.status.check`, `ogit.commit.log.show "" 5 oneline`, `ogit.commit.log.show --since=midnight "" oneline \| wc -l` (pass `--since=midnight` as `<range>`) |
| hiveMind:4888-4889, 5102-5103 | `ogit.index.add all "$ws" <files>`; `ogit.commit.create "<msg>" "" "" "$ws"` (note `add -f` at 4888: use `ogit.raw "$ws" add -f <file>` with a comment, or drop `-f` if the file is not ignored — check `.gitignore` first) |
| scrumMaster:14 (source-time) | `: ${SCRUMMASTER_METRICS_DIR:=}` at file scope and resolve lazily in `private.scrumMaster.metrics.dir.get` → `ogit.repo.root.get`; grep every reader of `SCRUMMASTER_METRICS_DIR` and route through that getter |
| context ×5 | `ogit.repo.root.get` |
| agentRoom:158, 177 | `ogit.repo.clone https://github.com/baryhuang/claude-code-by-agents.git main "$dir"`, `ogit.remote.pull "$dir"` |
| snet:56 | `ogit.remote.pull "$PWD"` |
| otest:120-125, 409 | `ogit.branch.get`, `ogit.branch.checkout`, `ogit.branch.merge`, `ogit.remote.push`, `ogit.branch.list local` — on the EAMD.ucp repo dir |
| otest:131 (docker container) | keep raw; `# ogit-exception: runs inside a container without oosh` on the line above |
| init/oosh, init/once | `# ogit-exception-file: POSIX sh, runs before bash and oosh exist` / `# ogit-exception-file: legacy once framework, out of scope` as the second line of each file |

- [ ] Run the suites of every touched script (`user`, `ossh`, `hiveMind`, `scrumMaster`, `context`, `agentRoom`, `snet`, `otest`, `install`) → PASS. `./test.suite run ogit 1` → `T-OGIT-ONLY-CALLER` PASSES (zero hits). Commit `refactor: remaining scripts call ogit; sweep green`.

---

### Task 18: Docs, core gate, platform gate, push (end of Phase 1)

- [ ] **`docs/ogit.md`** shaped like `docs/odocker.md`: `# ogit — Git Wrapper for oosh`, `## Overview` (naming line `git→ogit`, the only-caller rule, `<?dir>` last, getters vs mutators, `ogit-exception` markers), `## Quick Start`, `## Methods` with one `| Method | Parameters | Description |` table per noun (copy the signatures from this plan), `## Layout` (Phase 2 fills it; for now: "worktrees today, see spec"), `## Troubleshooting` (dubious ownership → `ogit safeDirectory.ensure`; git missing → `oo cmd git`), `## See Also`. Embed the tree: `![ogit method tree](puml/ogit.tree/ogit.tree.drawio)` link.
- [ ] `docs/wiki-index.md`: `- [Git Wrapper (ogit)](ogit.md) - every git call in oosh; branch/remote/commit/tag/stash/trust nouns; worktree↔clone layout` under Infrastructure Tools. `CLAUDE.md` wrapper table: `| ogit | git | ogit branch.get, ogit remote.pull, ogit safeDirectory.ensure, ogit layout.status |`. `docs/oosh-architecture.md` § Key Scripts: `| ogit | The only git caller; docs/ogit.md |`.
- [ ] `./test.suite core 1` → all green (1 intentional meta-failure). Validators OK.
- [ ] Commit `docs(ogit): docs/ogit.md, wiki, CLAUDE.md`; push `dev`; `os platform.test ubuntu_24_04` → PASS ×4 users.
- [ ] Record in `sessions/agent.context.md`: Phase 1 done, commit range, gate results.

---

# PHASE 2 — clone per branch folder

### Task 19: `ogit layout.status`

**Files:** `ogit`, `test/test.ogit`

- [ ] **Step 1: Fixture for a base** (add to test.ogit):

```bash
test.ogit.base() { # <label> <?shape:worktree> # echo <base> holding main + dev + prod as linked worktrees (shape worktree) or as clones (shape clone), all tracking <base>/origin.git
  local fx; fx=$(test.suite.fixture.make "$1"); local base="$fx/Once.sh"; mkdir -p "$base"
  git init -q --bare -b main "$fx/origin.git"
  git clone -q "$fx/origin.git" "$base/main" 2>/dev/null; git -C "$base/main" checkout -q -b main 2>/dev/null
  printf 'seed\n' > "$base/main/file"; git -C "$base/main" add file; git -C "$base/main" -c user.email=t@t -c user.name=t commit -q -m seed
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
private.ogit.folder.shape() # <folder> # echo worktree | clone | missing for <folder> #
{
 if   [ -f "$1/.git" ]; then echo worktree
 elif [ -d "$1/.git" ]; then echo clone
 else echo missing; fi
}

ogit.layout.status()     # <?base:$(oo mode.base.get)> # one line per folder under <base>: shape (worktree|clone|missing), dirty/ahead/behind counts, shared/setgid/trusted; rc 1 when the folders are not all the same shape #
{
 # Status idiom: the answer is plain echo, never behind console.log.
 local base="$1"; [ -n "$base" ] || base=$(oo mode.base.get 2>/dev/null)
 if [ -z "$base" ] || [ ! -d "$base" ]; then echo "no base"; create.result 1 "ogit.layout.status: no base"; return $(result); fi
 local d name shape dirty ahead behind shared setgid trusted shapes="" rc=0
 for d in "$base"/*/; do
   d="${d%/}"; name="${d##*/}"
   shape=$(private.ogit.folder.shape "$d")
   [ "$shape" = missing ] && continue
   shapes="$shapes $shape"
   dirty=$(ogit.status.show porcelain "$d" | grep -c .)
   ahead=$(git -C "$d" rev-list --count @{u}..HEAD 2>/dev/null || echo '?')
   behind=$(git -C "$d" rev-list --count HEAD..@{u} 2>/dev/null || echo '?')
   [ "$(git -C "$d" config --get core.sharedRepository 2>/dev/null)" = group ] && shared=group || shared=no
   [ -g "$(git -C "$d" rev-parse --absolute-git-dir 2>/dev/null)" ] && setgid=yes || setgid=no
   ogit.safeDirectory.list | grep -qFx "$d" && trusted=yes || trusted=no
   printf '%-14s %-9s dirty %-3s ahead %-3s behind %-3s shared=%s setgid=%s trusted=%s\n' "$name" "$shape" "$dirty" "$ahead" "$behind" "$shared" "$setgid" "$trusted"
 done
 # main is always a clone; the OTHER folders must all share one shape.
 case "$shapes" in *worktree*clone*|*clone*worktree*) [ "$(printf '%s\n' $shapes | grep -c clone)" = 1 ] || rc=1 ;; esac
 [ "$rc" = 0 ] && create.result 0 "layout under $base is consistent" || create.result 1 "mixed layout under $base — finish ogit worktree.remove or worktree.restore"
 return $(result)
}
ogit.layout.status.completion.base() { compgen -d "$1"; }
```
(The "mixed" rule: `main` is a clone by definition, so a consistent worktree layout is `clone` + N×`worktree`, a consistent clone layout is all `clone`. Exactly one `clone` among worktrees → consistent; otherwise mixed.) The `rev-list --count @{u}..HEAD` lines are the one place `ogit` calls git for counts on another folder; they are inside `ogit`, so the sweep is satisfied.

- [ ] **Step 4: Run → PASS. Commit** `feat(ogit): layout.status`.

---

### Task 20: `ogit worktree.remove` (worktrees → clones)

- [ ] **Step 1: Test (RED)**

```bash
test.ogit.worktreeRemove() {
  local base bad="" fx; base=$(test.ogit.base wtrm); fx=$(dirname "$base")
  export GIT_CONFIG_GLOBAL="$fx/gitconfig"; : > "$GIT_CONFIG_GLOBAL"
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
  [ "$(git -C "$base/dev" config --get core.sharedRepository)" = group ] || bad="$bad shared"
  ogit.safeDirectory.list | grep -qFx "$base/dev" || bad="$bad trusted"
  [ -z "$(git -C "$base/main" worktree list --porcelain | grep -c '^worktree ' | grep -vx 1)" ] || bad="$bad main-still-lists-worktrees"
  ogit.worktree.remove "$base" >/dev/null 2>&1 || bad="$bad second-run-rc=$?"
  ogit.layout.status "$base" >/dev/null || bad="$bad layout-not-consistent"
  unset GIT_CONFIG_GLOBAL; rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "refuses dirty and unpushed by name; converts clean worktrees to trusted, shared clones; idempotent" || create.result 1 "worktree.remove:$bad"
  return $(result)
}
test.case $level "T-OGIT-WORKTREE-REMOVE: worktrees become independent clones, safely" test.ogit.worktreeRemove
expect 0 "refuses dirty and unpushed by name; converts clean worktrees to trusted, shared clones; idempotent" "D1 + D4 of the design"
```

- [ ] **Step 2: Implement**

```bash
private.ogit.folder.gate() # <folder> # rc 0 when <folder> is clean, has an upstream and is not ahead of it; RESULT names the folder and the fix otherwise #
{
 local d="$1" name="${1##*/}" n
 n=$(ogit.status.show porcelain "$d" | grep -c .)
 if [ "$n" != 0 ]; then create.result 1 "$name has $n uncommitted change(s) — commit or stash them in $d first"; return 1; fi
 if ! git -C "$d" rev-parse --abbrev-ref @{u} >/dev/null 2>&1; then create.result 1 "$name tracks no upstream — push it (git -C $d push -u origin <branch>) first"; return 1; fi
 n=$(git -C "$d" rev-list --count @{u}..HEAD 2>/dev/null)
 if [ "${n:-0}" != 0 ]; then create.result 1 "$name is $n commit(s) ahead of its upstream — push it first"; return 1; fi
 return 0
}

private.ogit.folder.finish() # <folder> # after a clone/worktree lands under the base: shared mode, tree ownership, trust for the caller #
{
 ogit.repo.share "$1" >/dev/null || return $(result)
 if [ "$(id -u)" = 0 ] && id developking >/dev/null 2>&1; then chown -R developking:dev "$1" 2>/dev/null; fi
 ogit.safeDirectory.add "$1" >/dev/null
 return 0
}

ogit.worktree.remove()     # <?base:$(oo mode.base.get)> # turn every linked worktree of <base>/main into an independent clone of the same branch; refuses on a dirty or unpushed folder; idempotent; run with sudo on a shared tree #
{
 private.ogit.require || return $(result)
 local base="$1"; [ -n "$base" ] || base=$(oo mode.base.get 2>/dev/null)
 if [ ! -d "$base/main/.git" ]; then create.result 1 "ogit.worktree.remove: no repository at $base/main"; error.log "$RESULT"; return $(result); fi
 local url; url=$(ogit.remote.url.get origin "$base/main")
 if [ -z "$url" ]; then create.result 1 "ogit.worktree.remove: $base/main has no origin"; error.log "$RESULT"; return $(result); fi
 # Gate EVERY folder before touching ANY: main, then each linked worktree.
 local -a folders=() branches=()
 local wt branch mainPhys; mainPhys=$(cd "$base/main" && pwd -P)
 while IFS= read -r wt; do
   [ "$wt" = "$mainPhys" ] && continue
   folders+=("$wt")
 done < <(ogit.worktree.list "$base/main" | awk '/^worktree /{print $2}')
 private.ogit.folder.gate "$base/main" || { error.log "$RESULT"; return $(result); }
 for wt in "${folders[@]}"; do
   private.ogit.folder.gate "$wt" || { error.log "$RESULT"; return $(result); }
   branch=$(ogit.branch.get "$wt")
   [ -n "$branch" ] || { create.result 1 "${wt##*/} is detached — check a branch out first"; error.log "$RESULT"; return $(result); }
   branches+=("$branch")
 done
 if [ ${#folders[@]} = 0 ]; then create.result 0 "no linked worktrees under $base — nothing to remove"; echo "$RESULT"; return $(result); fi
 local i
 for i in "${!folders[@]}"; do
   wt="${folders[$i]}"; branch="${branches[$i]}"
   git -C "$base/main" worktree remove "$wt" >/dev/null 2>&1 \
     || { create.result 1 "git worktree remove $wt failed — stop; nothing after this folder was touched"; error.log "$RESULT"; return $(result); }
   ogit.repo.clone "$url" "$branch" "$wt" >/dev/null 2>&1 \
     || { create.result 1 "${wt##*/}: worktree removed but clone of $branch failed — recover with: ogit repo.clone $url $branch $wt"; error.log "$RESULT"; return $(result); }
   private.ogit.folder.finish "$wt" || return $(result)
   echo "${wt##*/}: worktree → clone ($branch)"
 done
 git -C "$base/main" worktree prune >/dev/null 2>&1
 create.result 0 "${#folders[@]} folder(s) converted to clones under $base"
 return $(result)
}
ogit.worktree.remove.completion.base() { compgen -d "$1"; }
```

- [ ] **Step 3: Run → PASS. Commit** `feat(ogit): worktree.remove — linked worktrees become independent clones, gated`.

---

### Task 21: `ogit worktree.restore` (clones → worktrees)

- [ ] **Step 1: Test (RED)**

```bash
test.ogit.worktreeRestore() {
  local base bad="" fx; base=$(test.ogit.base clrs clone); fx=$(dirname "$base")
  export GIT_CONFIG_GLOBAL="$fx/gitconfig"; : > "$GIT_CONFIG_GLOBAL"
  test.ogit.commit "$base/dev" local
  ogit.worktree.restore "$base" >/dev/null 2>&1 && bad="$bad ahead-not-refused"
  case "$RESULT" in *dev*) ;; *) bad="$bad ahead-not-named" ;; esac
  git -C "$base/dev" push -q origin dev
  ogit.worktree.restore "$base" >/dev/null 2>&1 || bad="$bad restore-rc=$?"
  [ -f "$base/dev/.git" ] && [ -f "$base/prod/.git" ] || bad="$bad not-worktrees"
  [ "$(git -C "$base/dev" rev-parse HEAD)" = "$(git -C "$fx/origin.git" rev-parse dev)" ] || bad="$bad dev-content"
  [ "$(git -C "$base/main" worktree list --porcelain | grep -c '^worktree ')" = 3 ] || bad="$bad main-lists"
  ogit.worktree.restore "$base" >/dev/null 2>&1 || bad="$bad second-run-rc"
  # round trip
  ogit.worktree.remove "$base" >/dev/null 2>&1 || bad="$bad roundtrip-remove"
  [ -d "$base/dev/.git" ] || bad="$bad roundtrip-shape"
  unset GIT_CONFIG_GLOBAL; rm -rf "$fx"
  [ -z "$bad" ] && create.result 0 "clones become linked worktrees again, gated, idempotent, round-trippable" || create.result 1 "worktree.restore:$bad"
  return $(result)
}
test.case $level "T-OGIT-WORKTREE-RESTORE: the reverse conversion, and the round trip" test.ogit.worktreeRestore
expect 0 "clones become linked worktrees again, gated, idempotent, round-trippable" "reversibility is the promise"
```

- [ ] **Step 2: Implement**

```bash
ogit.worktree.restore()     # <?base:$(oo mode.base.get)> # turn every sibling clone of <base>/main (same origin) back into a linked worktree of main; refuses on a dirty or unpushed folder; idempotent; run with sudo on a shared tree #
{
 private.ogit.require || return $(result)
 local base="$1"; [ -n "$base" ] || base=$(oo mode.base.get 2>/dev/null)
 if [ ! -d "$base/main/.git" ]; then create.result 1 "ogit.worktree.restore: no repository at $base/main"; error.log "$RESULT"; return $(result); fi
 local url; url=$(ogit.remote.url.get origin "$base/main")
 local d branch; local -a folders=() branches=()
 for d in "$base"/*/; do
   d="${d%/}"
   [ "${d##*/}" = main ] && continue
   [ -d "$d/.git" ] || continue                                   # worktrees (.git file) are already done
   [ "$(ogit.remote.url.get origin "$d")" = "$url" ] || continue   # a foreign clone is not ours
   private.ogit.folder.gate "$d" || { error.log "$RESULT"; return $(result); }
   branch=$(ogit.branch.get "$d")
   [ -n "$branch" ] || { create.result 1 "${d##*/} is detached — check a branch out first"; error.log "$RESULT"; return $(result); }
   folders+=("$d"); branches+=("$branch")
 done
 private.ogit.folder.gate "$base/main" || { error.log "$RESULT"; return $(result); }
 if [ ${#folders[@]} = 0 ]; then create.result 0 "no sibling clones under $base — nothing to restore"; echo "$RESULT"; return $(result); fi
 ogit.remote.fetch "$base/main" >/dev/null || return $(result)
 local i
 for i in "${!folders[@]}"; do
   d="${folders[$i]}"; branch="${branches[$i]}"
   rm -rf "$d" || { create.result 1 "could not remove $d"; error.log "$RESULT"; return $(result); }
   ogit.worktree.add "$branch" "$d" "origin/$branch" "$base/main" >/dev/null \
     || { create.result 1 "${d##*/}: clone removed but worktree add failed — recover with: ogit worktree.add $branch $d origin/$branch $base/main"; error.log "$RESULT"; return $(result); }
   git -C "$d" branch -q -u "origin/$branch" 2>/dev/null
   private.ogit.folder.finish "$d" || return $(result)
   echo "${d##*/}: clone → worktree ($branch)"
 done
 ogit.repo.share "$base/main" >/dev/null
 create.result 0 "${#folders[@]} folder(s) restored as worktrees of $base/main"
 return $(result)
}
ogit.worktree.restore.completion.base() { compgen -d "$1"; }
```
Also extend `ogit.worktree.find` (Task 11) with the clone case, and test it in `T-OGIT-WORKTREE` with a `test.ogit.base … clone` fixture:

```bash
ogit.worktree.find()     # <branch> <?dir:$OOSH_DIR> # echo the folder that has <branch> checked out: a linked worktree of <dir>'s repository, else the sibling clone <base>/<branch> when it is on <branch>; empty when none #
{
 local hit; hit=$(ogit.worktree.list "$2" | awk -v ref="refs/heads/$1" '/^worktree / { wt=$2; next } $1 == "branch" && $2 == ref { print wt; exit }')
 if [ -n "$hit" ]; then printf '%s\n' "$hit"; return 0; fi
 local base; base=$(oo mode.base.get 2>/dev/null)
 [ -n "$base" ] && [ -d "$base/$1/.git" ] && [ "$(ogit.branch.get "$base/$1")" = "$1" ] && printf '%s\n' "$(cd "$base/$1" && pwd -P)"
}
```

- [ ] **Step 3: Run → PASS. Commit** `feat(ogit): worktree.restore; worktree.find knows sibling clones`.

---

### Task 22: Install state 31 clones per folder; `private.oo.shared.tree.from.local` clones

**Files:** `oo` (state 31 body at the sites migrated in Task 15; `private.oo.shared.tree.from.local`), `test/test.oo` (T-SHARED-TREE-*)

- [ ] **Step 1: Tests (RED)** — rewrite the four `T-SHARED-TREE-*` cases (test.oo:2192-2416) to assert the clone shape: replace every `[ -f "$fixture/dev/.git" ] && grep -q gitdir: …` with `[ -d "$fixture/dev/.git" ]` and add `[ "$(git -C "$fixture/dev" remote get-url origin)" = "$(git -C "$fixture/main" remote get-url origin)" ]`. Run `./test.suite run oo 1` → those four FAIL.

- [ ] **Step 2: `private.oo.shared.tree.from.local`** — replace step 3 (the `worktree add` pair) with:

```bash
  # 3. The active branch as an INDEPENDENT CLONE beside main/ (clone layout,
  #    2026-09-23 design). Cloned from main/ (offline-safe), then origin
  #    re-pointed at main/'s origin so it pulls from GitHub like every folder.
  if [ "$branch" != "main" ]; then
    local originUrl; originUrl=$(ogit.remote.url.get origin main)
    ogit.repo.clone "$(pwd)/main" "$branch" "$branch" >/dev/null \
      || { error.log "private.oo.shared.tree.from.local: clone of $branch from main/ failed"; return 1; }
    [ -n "$originUrl" ] && git -C "$branch" remote set-url origin "$originUrl"   # ogit-exception: no method for set-url yet; add ogit.remote.url.set if a second caller appears
    ogit.repo.share "$branch" >/dev/null
  fi
```
(Better: add `ogit.remote.url.set <url> <?remote:origin> <?dir>` via `oo method.new` with a one-line test, and use it — do that instead of the exception.)

- [ ] **Step 3: State 31** — replace the "Creating worktree" branch (oo:2049-2071 at 8c46828, migrated in Task 15) with:

```bash
      else
        important.log "<oo> Cloning branch ${OOSH_BRANCH} beside main/"
        OOSH_BRANCH="${OOSH_BRANCH#refs/heads/}"; OOSH_BRANCH="${OOSH_BRANCH#refs/remotes/origin/}"
        OOSH_BRANCH="${OOSH_BRANCH#heads/origin/}"; OOSH_BRANCH="${OOSH_BRANCH#origin/}"
        ogit.repo.clone git@github.com:Cerulean-Circle-GmbH/once.sh.git "${OOSH_BRANCH}" "${OOSH_BRANCH}"
        RETURN_VALUE=$?
        if ! [ "$RETURN_VALUE" = "0" ]; then
          error.log "state 31: clone of ${OOSH_BRANCH} failed (rc=$RETURN_VALUE) in $(pwd)"
          return $RETURN_VALUE
        fi
      fi
```
and the permission block (oo:2144-2171) with:

```bash
    # Each folder is its own repository now: shared mode, setgid, g+w and the
    # caller's trust PER FOLDER (ogit repo.share / safeDirectory.add), not on
    # main/.git only. Re-runs are idempotent.
    for _wt in "$onceShBase"/*/; do
      _wt="${_wt%/}"
      [ -e "$_wt/.git" ] || continue
      ogit.repo.share "$_wt" >/dev/null || { error.log "state 31: ogit repo.share $_wt failed — $RESULT"; return 1; }
      local resolvedDir="$_wt"
      if command -v osascript >/dev/null 2>&1; then
        resolvedDir=$(osascript -e "POSIX path of (POSIX file \"$_wt\" as alias)" 2>/dev/null | sed 's:/$::') || resolvedDir="$_wt"
      fi
      ogit.safeDirectory.add "$resolvedDir" >/dev/null
    done
```

- [ ] **Step 4: Run** `./test.suite run oo 1` → PASS. Commit `feat(oo): install state 31 and shared.tree.from.local produce the clone layout with per-folder permissions`.

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
    local originUrl; originUrl=$(ogit.remote.url.get origin "$current_target")
    if ! ogit.repo.clone "$originUrl" "${remote_branch#origin/}" "$target_dir" >/dev/null; then
      error.log "git worktree add failed for $remote_branch → $target_dir"   # message kept: test.oo:470 pins the text; reword the pin and this line together to "clone failed for" in the same commit
      create.result 1 "clone failed"; return $(result)
    fi
    ogit.repo.share "$target_dir" >/dev/null; ogit.safeDirectory.add "$target_dir" >/dev/null
    ```
    (Do the rename: message `clone failed for`, pin updated in test.oo:470.)
  - `oo.checkout`: delete the "Worktree mode" branch; the single path is: `base=$(oo.mode.base.get)` (fail loud if none: `create.result 1 "no components base — run oo mode.setup"`); `targetDir="$base/$dirName"`; the existing-folder branch unchanged (align via `ogit.branch.checkout`); else `ogit.remote.fetch "$oosh"`, `ogit.repo.clone "$(ogit.remote.url.get origin "$oosh")" "$version" "$targetDir"`, `ogit.repo.share "$targetDir"`, `ogit.safeDirectory.add "$targetDir"`. Docstring: `# <version> # clone a remote branch as <base>/<dirName>`.
  - `oo.update`: after the pull and before `private.oo.update.heal.symlinks`: `ogit.safeDirectory.ensure >/dev/null || warn.log "oo update: could not ensure safe.directory — $RESULT"`.
  - `config.init.user`: after the log.env migration block: `ogit.safeDirectory.ensure "$(dirname "$sharedOosh")" >/dev/null || warn.log "config.init.user: $RESULT"` (for the *caller*); and inside the as-user hop, after `private.config.bashrc.ensure`: `'$sharedOosh/ogit' safeDirectory.ensure '$(dirname "$sharedOosh")' >/dev/null` (for the *target*). `config` loads ogit via `private.config.ogit.load` (`oo method.new`).
  - `user.oosh.install` (Task 17 sites): replace the two `safeDirectory.add` hops with one `'$sharedOosh/ogit' safeDirectory.ensure '$(dirname "$sharedOosh")'` hop.

- [ ] **Step 3: Run** oo, config, user suites → PASS. Commit `feat(oo,config,user): oo mode/checkout clone under the base; trust ensured by oo update, config init.user, user.oosh.install`.

---

### Task 24: `promote` merges in the target's own folder

**Files:** `promote` (`private.check.merged.to.testing`, `private.check.merged.to.prod`, `testing.pushed`, `prod.pushed`, `prod.tagged`), `test/test.promote`

- [ ] **Step 1: Test (RED)** — new fixture: a base with `dev` and `testing` clones of one bare origin (`test.ogit.base` shape clone, plus a `testing` branch), `OOSH_COMPONENTS_DIR="$base"`, `OOSH_DIR="$base/dev"`, one extra commit on dev:

```bash
test.promote.mergeInTargetFolder() {
  local base fx bad=""; base=$(test.promote.base mit); fx=$(dirname "$base")   # copy test.ogit.base into test.promote as test.promote.base, adding a testing branch/clone
  export OOSH_COMPONENTS_DIR="$base"; local savedDir="$OOSH_DIR"; export OOSH_DIR="$base/dev"
  printf 'new\n' >> "$base/dev/file"; git -C "$base/dev" -c user.email=t@t -c user.name=t commit -qam new
  private.check.merged.to.testing promote testing 14 >/dev/null 2>&1 || bad="$bad rc=$? result=[$RESULT]"
  [ "$(git -C "$base/testing" branch --show-current)" = testing ] || bad="$bad testing-folder-branch"
  git -C "$base/testing" log --oneline | grep -q new || bad="$bad merge-not-in-testing-folder"
  [ "$(git -C "$base/dev" branch --show-current)" = dev ] || bad="$bad dev-folder-moved"
  [ "$(git -C "$fx/origin.git" rev-parse dev)" = "$(git -C "$base/dev" rev-parse dev)" ] || bad="$bad source-not-pushed"
  rm -rf "$base/testing"
  private.check.merged.to.testing promote testing 14 >/dev/null 2>&1 && bad="$bad missing-target-not-refused"
  case "$RESULT" in *"oo checkout testing"*) ;; *) bad="$bad refusal-names-no-fix=[$RESULT]" ;; esac
  export OOSH_DIR="$savedDir"; unset OOSH_COMPONENTS_DIR; rm -rf "$fx"
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
 ogit.remote.fetch "$dir" >/dev/null || { create.result 1 "fetch failed in $dir"; return $(result); }
 if ! git -C "$dir" merge --ff-only "origin/$target" >/dev/null 2>&1; then   # ogit-exception: add ogit.branch.fastForward <ref> if a second caller appears
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
(Implement `ogit.branch.fastForward <ref> <?dir>` properly via `oo method.new` — `git merge --ff-only` — with a test in test.ogit, rather than the exception; the plan shows the exception only so the shape is clear.)

Then:
- `private.check.merged.to.testing` body → `private.promote.merge.into.folder dev testing; return $(result)` (keep the `<script> <stageTo> <stateFound>` shifts).
- `private.check.merged.to.prod` body → `private.promote.merge.into.folder testing prod; return $(result)`.
- `testing.tagged` / `prod.tagged`: tag in the target folder: `dir=$(ogit.worktree.find testing "$OOSH_DIR")`, `ogit.tag.create "$tag" testing "$dir"`; `ogit.tag.check` / `ogit.tag.latest.get` on `$dir`.
- `testing.pushed` / `prod.pushed`: `ogit.remote.push testing yes "$dir"`; no `checkout dev` any more (the dev folder never left dev) — update `test.promote.noModeWrite` (test.promote:494-499), which pinned `checkout dev`, to pin "no `branch.checkout`" instead; drop the stash-pop tail (stashes are popped in the helper).
- `promote.status` / `branch.alignment`: read refs from the target folders (`ogit.commit.log.show refs/heads/testing 1 '%h %ci' "$(ogit.worktree.find testing …)"`), falling back to `$OOSH_DIR` when no folder exists.

- [ ] **Step 3: Run** `./test.suite run promote 1` → PASS. Commit `feat(promote): merge in the target stage's own folder; refuse when the folder is missing`.

---

### Task 25: Platform invariant, docs, gates, migration

- [ ] **`test/test.platform.shared.layout.invariant`** from `templates/code/newPlatformInvariantTest`: INVARIANT-0 `oo mode.base.get` succeeds; INVARIANT-1 every folder under the base has a `.git` **directory** (`ogit layout.status` rc 0 and no `worktree` line); INVARIANT-2 each has `core.sharedRepository=group` and a setgid `.git` (parse `shared=group setgid=yes` from `ogit layout.status`); INVARIANT-3 each is trusted for the caller (`trusted=yes`), recovery `oo update`. Each `expect.fail` names the command (`sudo ogit worktree.remove`, `ogit repo.share <dir>`, `oo update`).
- [ ] Docs: `docs/oo.md` § The worktree layout → "The clone layout" (the tree from spec § 2, the `main/` rule, `oo checkout` always clones under the base, `ogit worktree.remove/restore`); `docs/branching.md` and `docs/promote.md`: merge happens in `<base>/<target>`, prerequisites (`oo checkout testing`), the refusal; `docs/repair-toolkit.md` rows: `ogit layout.status`, `ogit safeDirectory.ensure`, `sudo ogit worktree.remove`; `docs/ogit.md` § Layout filled; `docs/research/2026-09-22-worktrees-vs-version-convention.md` gets a top note: "**Superseded 2026-09-23** by the ogit design (link); the user decided for clones."; `docs/oosh-architecture.md` § Sanctioned exceptions: `oo.use` wording still holds.
- [ ] Gates: `./test.suite core 1` green; validators OK; `os platform.test ubuntu_24_04`, `alpine`, and the macOS gate (per memory `reference_tart_macos_gate`) all PASS — fresh installs now produce clones; inside `terminal notests`: `ogit layout.status` shows all `clone`, `./test.suite run platform.shared.layout.invariant 1` PASS.
- [ ] Push `dev`.
- [ ] **Migrate this host** (user-run, documented, not automatic): `ogit layout.status` (expect `main clone`, `dev worktree`, `prod worktree`, all clean/ahead 0); `sudo ogit worktree.remove`; `ogit layout.status` (all clone); `env -i HOME=$HOME bash -l -c 'oo mode.list'`; `oo mode prod && oo mode dev`; `promote status`; then prove reversibility once: `sudo ogit worktree.restore`, `ogit layout.status`, `sudo ogit worktree.remove`.
- [ ] Record in `sessions/agent.context.md`; add memory: "layout is clones per folder since <commit>; `ogit worktree.restore` reverses".

---

## Self-review checklist (done by the plan author; re-run by the implementer at the end)

- **Spec coverage:** § 2 layout → Tasks 19-23, 25; § 2.1 conversions → Tasks 20-21; § 3.1-3.2 shape/conventions → Task 1; § 3.3 catalogue → Tasks 3-11 (plus `ogit.remote.url.set` and `ogit.branch.fastForward` added in Tasks 22/24 — add them to spec § 3.3 and the drawio JSON when you land them); § 3.4 aliases → Tasks 10, 12; § 3.5 → Tasks 15-16 keep porcelain verbs; § 3.6 exceptions → Tasks 13, 17; § 4 permissions/trust → Tasks 20-23; § 5 caller changes → Tasks 22-24; § 6 tests/docs/rollout → Tasks 13, 18, 25.
- **Invariants (spec § 7):** `path validate` / `anchor.validate` after every task; `main/` always present; sweep green from Task 17 on; install fixes only in state 31's body; no automatic conversion.
- **Known judgement calls for the implementer:** `oo.commit`'s `add *` → `index.add all` (dotfiles); `hiveMind:4888 add -f`; the `promote.report` tag format (keep output identical); `scrumMaster:14` lazy default; whether `ossh:640` keeps the raw fallback. Decide, note the decision in the commit message, move on.
