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
{
  local source="${1:-all}"

  local branches=""

  # Worktree directories (if worktree structure exists)
  if [ "$source" = "all" ] || [ "$source" = "local" ]; then
    local base
    base=$(oo.mode.base.get 2>/dev/null)
    if [ $? -eq 0 ] && [ -d "$base" ]; then
      local dir
      for dir in "$base"/*/; do
        [ -L "${dir%/}" ] && continue
        [ -d "$dir/.git" ] || [ -f "$dir/.git" ] || continue
        local dirName
        dirName=$(basename "$dir")
        [[ "$dirName" == .* ]] && continue
        branches="${branches}${dirName}"$'\n'
      done
    fi

    # Local git branches
    local localBranches
    localBranches=$(git -C "${OOSH_DIR:-$HOME/oosh}" branch --format='%(refname:short)' 2>/dev/null)
    if [ -n "$localBranches" ]; then
      branches="${branches}${localBranches}"$'\n'
    fi
  fi

  # Remote branches (with fetch)
  if [ "$source" = "all" ] || [ "$source" = "remote" ]; then
    git -C "${OOSH_DIR:-$HOME/oosh}" fetch origin 2>/dev/null
    local remoteBranches
    remoteBranches=$(git -C "${OOSH_DIR:-$HOME/oosh}" branch -r --format='%(refname:short)' 2>/dev/null \
      | sed 's|^origin/||' \
      | grep -v '^HEAD$')
    if [ -n "$remoteBranches" ]; then
      branches="${branches}${remoteBranches}"$'\n'
    fi
  fi

  # Deduplicate and sort (sort -u is used elsewhere in the codebase)
  local result
  result=$(echo "$branches" | grep -v '^$' | sort -u)

  if [ -n "$result" ]; then
    echo "$result"
    create.result 0 "$result"
  else
    create.result 1 "no branches found"
  fi

  return $(result)
}
```

**Completion:**

```bash
oo.branch.list.completion.source() {
  echo "all"
  echo "local"
  echo "remote"
}
```

**OOSH compliance notes:**
- Follows `script.noun.verb` pattern (`oo.branch.list`)
- Parameter `<?source:all>` is camelCase with default
- Uses `create.result` / `return $(result)` per newMethod template
- Completion function matches parameter name exactly
- Private helper logic is inline (single-use, no abstraction needed)
- Uses `info.log` for progress, not `echo` for diagnostics

### 2. Completion Fixes — Eliminating the "Grunge"

**Root cause:** `oo.use.completion.branch()` calls `oo.mode.base.get` which fails in plain-clone environments. Returns nothing. Bash falls back to default file completion.

**Fix:** All branch-related completion functions call `oo.branch.list` instead of reimplementing discovery. When `oo.branch.list` returns nothing, return sentinel `;` to tell c2 "completion handled, no matches" — preventing bash file-completion fallback.

```bash
oo.use.completion.branch() {
  local branches
  branches=$(oo.branch.list local 2>/dev/null)
  if [ -n "$branches" ]; then
    echo "$branches"
  else
    echo ";"
  fi
}

oo.checkout.completion.version() {
  local branches
  branches=$(oo.branch.list remote 2>/dev/null)
  if [ -n "$branches" ]; then
    echo "$branches"
  else
    echo ";"
  fi
}

oo.mode.completion.branch() {
  local branches
  branches=$(oo.branch.list local 2>/dev/null)
  if [ -n "$branches" ]; then
    echo "$branches"
  else
    echo ";"
  fi
}

oo.parameter.completion.branch() {
  oo.branch.list local 2>/dev/null
}

oo.parameter.completion.baseBranch() {
  oo.branch.list local 2>/dev/null
}
```

| Function | Current Implementation | New Implementation |
|----------|----------------------|-------------------|
| `oo.use.completion.branch()` | `ls` on worktree base dirs | `oo.branch.list local` with `;` fallback |
| `oo.use.completion.command()` | `PARAM_branch` from config, `ls` branch dir | No change (works correctly once branch is selected) |
| `oo.checkout.completion.version()` | `git ls-remote --heads` (no fetch) | `oo.branch.list remote` with `;` fallback |
| `oo.mode.completion.branch()` | Loops worktree dirs | `oo.branch.list local` with `;` fallback |
| `oo.parameter.completion.branch()` | `git branch --format` | `oo.branch.list local` |
| `oo.parameter.completion.baseBranch()` | `git branch --format` | `oo.branch.list local` |

### 3. `oo.checkout` — Dual-Mode (Worktree + Clone)

**Current:** Always uses `git clone -b <version>`.

**New:** Auto-detect environment and use appropriate strategy.

```bash
oo.checkout() # <version> # clone or add worktree for a remote branch
{
  local version="$1"

  if [ -z "$version" ]; then
    error.log "Usage: oo checkout <version>"
    create.result 1 "missing version"
    return $(result)
  fi

  # Derive directory name: strip prefixes, convert slashes to dots
  local dirName="$version"
  dirName="${dirName#test/}"
  dirName="${dirName#feature/}"
  dirName="${dirName#bugfix/}"
  dirName=$(echo "$dirName" | tr '/' '.')

  # Detect environment
  local base
  base=$(oo.mode.base.get 2>/dev/null)
  local hasWorktrees=$?

  if [ $hasWorktrees -eq 0 ] && [ -d "$base" ]; then
    # --- Worktree mode ---
    local targetDir="$base/$dirName"

    if [ -d "$targetDir" ]; then
      # Already exists — check if git branch matches directory name
      local currentGitBranch
      currentGitBranch=$(git -C "$targetDir" branch --show-current 2>/dev/null)

      if [ -n "$currentGitBranch" ] && [ "$currentGitBranch" != "$dirName" ]; then
        # Misaligned: git branch doesn't match directory name — fix it
        info.log "Aligning git branch to directory name: $dirName"
        if git -C "$targetDir" checkout "$dirName" 2>/dev/null; then
          success.log "Aligned branch to '$dirName' in $targetDir"
          create.result 0 "$targetDir"
          return $(result)
        else
          error.log "Failed to checkout branch '$dirName' in $targetDir"
          create.result 1 "checkout failed"
          return $(result)
        fi
      fi

      # Already aligned — pull latest
      info.log "Directory exists, pulling: $targetDir"
      if git -C "$targetDir" pull 2>/dev/null; then
        success.log "Pulled $version in $targetDir"
        create.result 0 "$targetDir"
        return $(result)
      else
        error.log "git pull failed in $targetDir"
        create.result 1 "pull failed"
        return $(result)
      fi
    fi

    # New worktree
    git -C "${OOSH_DIR:-$HOME/oosh}" fetch origin 2>/dev/null
    info.log "Creating worktree for $version at $targetDir"
    if git -C "${OOSH_DIR:-$HOME/oosh}" worktree add -B "$dirName" "$targetDir" "origin/$version" 2>/dev/null; then
      success.log "Created worktree for $version at $targetDir"
      console.log "  Use 'oo mode $dirName' to switch to it"
      create.result 0 "$targetDir"
    else
      error.log "git worktree add failed for '$version'"
      create.result 1 "worktree add failed"
    fi

  else
    # --- Plain clone mode ---
    local repoUrl
    repoUrl=$(git -C "${OOSH_DIR:-$HOME/oosh}" remote get-url origin 2>/dev/null)
    if [ -z "$repoUrl" ]; then
      error.log "Cannot determine git remote URL from ${OOSH_DIR:-$HOME/oosh}"
      create.result 1 "no remote URL"
      return $(result)
    fi

    local targetDir
    targetDir="$(dirname "${OOSH_DIR:-$HOME/oosh}")/$dirName"

    if [ -d "$targetDir" ]; then
      if [ -d "$targetDir/.git" ] || [ -f "$targetDir/.git" ]; then
        info.log "Directory exists, pulling: $targetDir"
        if git -C "$targetDir" pull 2>/dev/null; then
          success.log "Pulled $version in $targetDir"
          create.result 0 "$targetDir"
          return $(result)
        else
          error.log "git pull failed in $targetDir"
          create.result 1 "pull failed"
          return $(result)
        fi
      else
        error.log "Directory exists but is not a git repo: $targetDir"
        create.result 1 "not a git repo"
        return $(result)
      fi
    fi

    # Fetch before clone to ensure branch is available
    git -C "${OOSH_DIR:-$HOME/oosh}" fetch origin 2>/dev/null
    info.log "Cloning $version into $targetDir"
    if git clone "$repoUrl" -b "$version" "$targetDir" 2>/dev/null; then
      success.log "Cloned $version to $targetDir"
      console.log "  Use 'oo mode $dirName' to switch to it"
      create.result 0 "$targetDir"
    else
      error.log "git clone failed for branch '$version'"
      rm -rf "$targetDir" 2>/dev/null
      create.result 1 "clone failed"
    fi
  fi

  return $(result)
}
```

**Completion:**

```bash
oo.checkout.completion.version() {
  local branches
  branches=$(oo.branch.list remote 2>/dev/null)
  if [ -n "$branches" ]; then
    echo "$branches"
  else
    echo ";"
  fi
}
```

### 4. Consistency Check — Mode vs Git Branch Mismatch

**Where:** `oo.mode()` with no arguments (status display).

**New method: `oo.mode.align`** — a dedicated oosh command to fix the mismatch, rather than overloading `oo checkout` semantics.

**In `oo.mode` (no args), add after the existing status output:**

```bash
# Consistency check: git branch vs directory name
local gitBranch
gitBranch=$(git -C "$actualPath" branch --show-current 2>/dev/null)
if [ -n "$gitBranch" ] && [ "$gitBranch" != "$currentName" ]; then
  warn.log "Git branch is '$gitBranch' but worktree directory is '$currentName'"
  console.log "  To fix: oo mode.align"
fi
```

**New method:**

```bash
oo.mode.align() # # align git branch to match the current worktree directory name
{
  local OOSH_LINK="$HOME/oosh"
  local actualPath
  actualPath=$(readlink -f "$OOSH_LINK" 2>/dev/null || echo "$OOSH_DIR")
  local currentName
  currentName=$(basename "$actualPath")

  local gitBranch
  gitBranch=$(git -C "$actualPath" branch --show-current 2>/dev/null)

  if [ -z "$gitBranch" ]; then
    error.log "Cannot determine current git branch in $actualPath"
    create.result 1 "no git branch"
    return $(result)
  fi

  if [ "$gitBranch" = "$currentName" ]; then
    console.log "Already aligned: git branch '$gitBranch' matches directory '$currentName'"
    create.result 0 "already aligned"
    return $(result)
  fi

  warn.log "Git branch is '$gitBranch' but directory is '$currentName'"
  console.log "Checking out '$currentName'..."

  if git -C "$actualPath" checkout "$currentName" 2>/dev/null; then
    success.log "Aligned: git branch now matches directory '$currentName'"
    create.result 0 "$currentName"
  else
    error.log "Failed to checkout '$currentName' — branch may not exist locally"
    console.log "  Try: oo checkout $currentName"
    create.result 1 "checkout failed"
  fi

  return $(result)
}
```

**Example output when mismatched:**

```
Mode: dev
Path: /path/to/worktrees/dev
Worktree base: /path/to/worktrees
Git branch is 'prod' but worktree directory is 'dev'
  To fix: oo mode.align
## prod...origin/prod
```

**OOSH compliance notes:**
- `oo.mode.align` follows `script.noun.verb` pattern
- No parameters — no completion function needed
- Uses `warn.log` (level 2), `console.log` (level 3), `success.log`, `error.log`
- Uses `create.result` / `return $(result)` throughout
- Suggests oosh commands (`oo checkout`) in error messages, never raw `git`
- Warning only in `oo.mode` — does not block operations

### 5. `oo.use` in Plain Clone Environments

**Current:** `oo.use` requires `oo.mode.base.get` to find the worktree base. Fails silently in plain clones.

**Fix:** When no worktree base exists, fall back to looking for sibling directories of `$OOSH_DIR`:

```bash
oo.use() # <branch> <command> # run a command from a specific branch without switching
{
  local branch="$1"
  shift
  local command="$1"
  shift

  if [ -z "$branch" ] || [ -z "$command" ]; then
    error.log "Usage: oo use <branch> <command> [args...]"
    create.result 1 "missing branch or command"
    return $(result)
  fi

  # Try worktree base first, fall back to sibling directories
  local branchDir
  local base
  base=$(oo.mode.base.get 2>/dev/null)
  if [ $? -eq 0 ] && [ -d "$base/$branch" ]; then
    branchDir="$base/$branch"
  elif [ -d "$(dirname "${OOSH_DIR:-$HOME/oosh}")/$branch" ]; then
    branchDir="$(dirname "${OOSH_DIR:-$HOME/oosh}")/$branch"
  else
    error.log "Branch directory '$branch' not found"
    create.result 1 "branch not found"
    return $(result)
  fi

  if [ ! -f "$branchDir/$command" ]; then
    error.log "Command '$command' not found in branch '$branch'"
    create.result 1 "command not found"
    return $(result)
  fi

  # Export logging stubs so target branch bootstrap can call them.
  { export -f console.log important.log warn.log error.log \
             debug.log success.log silent.log stop.log seq.puml.log; } 2>/dev/null

  OOSH_DIR="$branchDir" "$branchDir/$command" "$@"
}
```

### 6. Testing

All tests in `/home/hannesn/oosh/test/test.oo`, following the existing test patterns (helper function + `test.case` + `expect`).

| Test ID | Description |
|---------|-------------|
| T-BRANCH-1 | `oo.branch.list local` returns branches in plain clone (no worktree structure) |
| T-BRANCH-2 | `oo.branch.list local` includes worktree dirs when worktrees exist |
| T-BRANCH-3 | `oo.branch.list` deduplicates (same branch in worktree + git = one entry) |
| T-BRANCH-4 | `oo.branch.list remote` includes remote branches |
| T-BRANCH-5 | `oo.branch.list` with invalid source returns error |
| T-CONSIST-1 | `oo.mode` detects git-branch vs directory-name mismatch (warns) |
| T-CONSIST-2 | `oo.mode` shows no warning when git branch matches directory |
| T-ALIGN-1 | `oo.mode.align` fixes mismatch (git checkout to match dir name) |
| T-ALIGN-2 | `oo.mode.align` reports "already aligned" when no mismatch |
| T-COMP-1 | `oo.use.completion.branch` returns branches, not file listings |
| T-COMP-2 | `oo.checkout.completion.version` returns remote branches |
| T-CHECKOUT-1 | `oo.checkout` uses `git worktree add` when worktree structure exists |
| T-CHECKOUT-2 | `oo.checkout` uses `git clone` when no worktree structure |
| T-USE-1 | `oo.use` finds branch via sibling directory in plain clone |

**Test structure** follows existing `test.oo` pattern:

```bash
# ============================================================================
# T-BRANCH-1: oo.branch.list local returns branches in plain clone
# ============================================================================
test.oo.branchList.local() {
  local branches
  branches=$(oo.branch.list local)
  if [ -n "$branches" ]; then
    create.result 0 "$branches"
  else
    create.result 1 "no branches returned"
  fi
}
test.case - "T-BRANCH-1: branch.list local returns branches" \
  test.oo.branchList.local
expect 0 "*" "oo.branch.list local returns at least one branch"
```

## Files Modified

| File | Changes |
|------|---------|
| `oo` | Add `oo.branch.list` + completion, add `oo.mode.align`, update `oo.checkout` (dual-mode), update `oo.mode` (consistency check), update `oo.use` (plain-clone fallback), update all completion functions |
| `test/test.oo` | Add T-BRANCH-*, T-CONSIST-*, T-ALIGN-*, T-COMP-*, T-CHECKOUT-*, T-USE-* test cases |

## OOSH Compliance Checklist

- [x] All new methods follow `script.verb` / `script.noun.verb` naming pattern
- [x] All parameter names are camelCase (no dashes, no underscores)
- [x] Completion function exists for each completable parameter
- [x] Completion function names match parameter names exactly
- [x] All methods use `create.result` / `return $(result)` per newMethod template
- [x] All user-facing output uses oosh logging (`console.log`, `warn.log`, `error.log`, `success.log`, `info.log`) — no raw `echo` for diagnostics
- [x] All user-facing suggestions reference oosh commands (`oo mode.align`, `oo checkout`) — never raw `git`
- [x] Private helpers use `private.oo.*` prefix (none needed — logic is inline)
- [x] Local variables are camelCase
- [x] Environment variables are UPPER_SNAKE
- [x] Tests follow existing `test.oo` pattern: helper function + `test.case` + `expect`
- [x] DRY: single `oo.branch.list` replaces multiple inline branch-discovery implementations
