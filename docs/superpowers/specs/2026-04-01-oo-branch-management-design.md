# Design: In-Container OO Branch Management

**Date:** 2026-04-01
**Status:** Approved
**Scope:** `oo use`, `oo checkout`, `oo mode`, tab completion, consistency checks

## Problem Statement

Five related tickets around `oo` branch management that share a root cause: branch discovery and switching assumes a worktree-based environment, breaking in plain-clone setups (e.g. Docker containers).

### Tickets

1. **oo use** — needs to work in both worktree and plain-clone environments
2. **oo checkout** — needs to work in both environments, using `git worktree add` or `git clone` as appropriate
3. **Fix oo use Tab Completion** — directory listings ("grunge") appear instead of branch names when worktree base is missing
4. **oo checkout Improvements** — tab completion should fetch and display all remote branches (prod, test, dev)
5. **Consistency Check** — `oo mode` should detect when git branch differs from worktree directory name

## Approach: Unified Branch Discovery

Rather than patching each ticket independently, introduce `oo.branch.list` as a single source of truth for available branches. All completion functions and branch-related methods delegate to it.

## Design

### 1. `oo.branch.list` — Unified Branch Discovery

```bash
oo.branch.list() # <?source:all> # list available branches from worktrees, local git, and/or remote
```

**Behavior:**

- `oo branch.list` / `oo branch.list all` — returns deduplicated union of:
  1. Worktree directories (if worktree structure exists via `oo.mode.base.get`)
  2. Local git branches (`git branch --format='%(refname:short)'`)
  3. Remote branches (runs `git fetch` first, then `git branch -r --format`)
- `oo branch.list local` — worktrees + local git branches only
- `oo branch.list remote` — remote branches only (with fetch)

**Output format:** One branch name per line, stripped of `origin/` prefix and `refs/heads/`, sorted, deduplicated.

**Completion:**

```bash
oo.branch.list.completion.source() {
  echo "all"
  echo "local"
  echo "remote"
}
```

### 2. Completion Fixes — Eliminating the "Grunge"

**Root cause:** `oo.use.completion.branch()` calls `oo.mode.base.get` which fails in plain-clone environments. Returns nothing. Bash falls back to default file completion.

**Fix:** All branch-related completion functions call `oo.branch.list` instead of reimplementing discovery. Return sentinel `;` when no results, preventing bash file-completion fallback.

| Function | Current Implementation | New Implementation |
|----------|----------------------|-------------------|
| `oo.use.completion.branch()` | `ls` on worktree base dirs | `oo.branch.list local` |
| `oo.use.completion.command()` | `PARAM_branch` from config, `ls` branch dir | No change (works correctly) |
| `oo.checkout.completion.version()` | `git ls-remote --heads` (no fetch) | `oo.branch.list remote` |
| `oo.mode.completion.branch()` | Loops worktree dirs | `oo.branch.list local` |
| `oo.parameter.completion.branch()` | `git branch --format` | `oo.branch.list local` |

### 3. `oo.checkout` — Dual-Mode (Worktree + Clone)

**Current:** Always uses `git clone -b <version>`.

**New:** Auto-detect environment:

```
if oo.mode.base.get succeeds (worktree structure exists):
    git fetch origin
    git worktree add -B <branchName> "$base/<dirName>" "origin/<version>"
else (plain clone):
    git fetch origin (if remote exists)
    git clone -b <version> <repo_url> <target_dir>
```

**Directory naming** unchanged — strip `test/`, `feature/`, `bugfix/` prefixes, convert remaining slashes to dots.

**Additional improvements:**

- Run `git fetch origin` before checkout in both modes
- After success, print: `"Use 'oo mode <branchName>' to switch to it"`
- If branch already exists locally, do `git pull` (existing behavior preserved)

### 4. Consistency Check — Mode vs Git Branch Mismatch

**Where:** `oo.mode()` with no arguments (status display).

**Logic:** After resolving current mode, compare directory name against `git branch --show-current`:

```bash
local dirName=$(basename "$actualPath")
local gitBranch=$(git -C "$actualPath" branch --show-current 2>/dev/null)

if [ -n "$gitBranch" ] && [ "$gitBranch" != "$dirName" ]; then
    warn.log "Git branch is '$gitBranch' but worktree directory is '$dirName'"
    console.log "  To fix: oo checkout $dirName"
fi
```

**Example output when mismatched:**

```
Mode: dev
Path: /path/to/worktrees/dev
Worktree base: /path/to/worktrees
Git branch is 'prod' but worktree directory is 'dev'
  To fix: oo checkout dev
## prod...origin/prod
```

Warning only — does not block operations.

**Clarification on the fix command:** `oo checkout dev` in this context means "ensure the `dev` branch is checked out in the current worktree directory." When `oo.checkout` detects it is being asked to check out a branch that matches the current worktree directory name, it should run `git checkout <branchName>` inside that directory rather than creating a new clone/worktree. This is the "already exists locally" path — aligning the git branch to the directory name.

### 5. Testing

All tests in `/home/hannesn/oosh/test/test.oo`, following existing patterns.

| Test ID | Description |
|---------|-------------|
| T-BRANCH-1 | `oo.branch.list` returns local branches in plain clone |
| T-BRANCH-2 | `oo.branch.list` returns worktree dirs when worktrees exist |
| T-BRANCH-3 | `oo.branch.list` deduplicates across sources |
| T-BRANCH-4 | `oo.branch.list remote` includes remote branches |
| T-CONSIST-1 | `oo.mode` detects git-branch vs directory-name mismatch |
| T-CONSIST-2 | `oo.mode` shows no warning when aligned |
| T-COMP-1 | `oo.use.completion.branch` returns branches, not file listings |
| T-COMP-2 | `oo.checkout.completion.version` returns remote branches |
| T-CHECKOUT-1 | `oo.checkout` uses `git worktree add` when worktree structure exists |
| T-CHECKOUT-2 | `oo.checkout` uses `git clone` when no worktree structure |

## Files Modified

| File | Changes |
|------|---------|
| `oo` | Add `oo.branch.list`, update `oo.checkout`, update `oo.mode`, update all completion functions |
| `test/test.oo` | Add T-BRANCH-*, T-CONSIST-*, T-COMP-*, T-CHECKOUT-* test cases |

## OOSH Compliance

- All new methods follow `script.verb` / `script.noun.verb` naming
- Parameters are camelCase
- Completion functions match parameter names exactly
- Uses `create.result` / `return $(result)` pattern
- Suggests oosh commands (not raw git) in user-facing messages
- DRY: single `oo.branch.list` method replaces multiple inline implementations
