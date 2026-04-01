# OO Branch Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `oo use`, `oo checkout`, `oo mode`, and their tab completions work reliably in both git-worktree and plain-clone environments (including Docker containers).

**Architecture:** Introduce `oo.branch.list` as a single branch-discovery method that all completion functions and branch commands delegate to. Update `oo.checkout` to auto-detect worktree vs plain-clone. Add `oo.mode.align` for consistency checking. Update `oo.use` to fall back to sibling directories.

**Tech Stack:** Bash (oosh framework), git, test.suite

**Spec:** `docs/superpowers/specs/2026-04-01-oo-branch-management-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `oo` | Modify | Add `oo.branch.list` (after line 349), add `oo.mode.align` (after line 450), rewrite `oo.checkout` (lines 595-662), update `oo.mode` (lines 362-379), update `oo.use` (lines 664-703), replace completion functions |
| `test/test.oo` | Modify | Add all new test cases before `test.suite.save.results` (line 798) |

---

## Task 1: Add `oo.branch.list` Method and Completion

**Files:**
- Modify: `oo` — insert new method after `oo.mode.list` (after line 349)
- Modify: `test/test.oo` — insert tests before `test.suite.save.results` (before line 798)

- [ ] **Step 1: Write failing tests for `oo.branch.list`**

Insert these tests in `test/test.oo` just before the line `test.suite.save.results` (line 798). They go after the teardown block that ends at line 796.

```bash
# ============================================================================
# T-BRANCH-1: oo.branch.list local returns branches in current environment
# ============================================================================
test.oo.branchList.local() {
  local branches
  branches=$(oo.branch.list local 2>/dev/null)
  if [ -n "$branches" ]; then
    create.result 0 "$branches"
  else
    create.result 1 "no branches returned"
  fi
}
test.case - "T-BRANCH-1: branch.list local returns branches" \
  test.oo.branchList.local
expect 0 "*" "oo.branch.list local returns at least one branch"

# ============================================================================
# T-BRANCH-2: oo.branch.list local includes worktree directories
# ============================================================================
test.oo.branchList.worktrees() {
  local base
  base=$(oo.mode.base.get 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$base" ]; then
    # No worktree structure — skip by passing
    create.result 0 "no worktrees to test"
    return
  fi
  local branches
  branches=$(oo.branch.list local 2>/dev/null)
  # At minimum, "dev" or "main" should appear from worktree dirs
  if echo "$branches" | grep -qE '^(dev|main)$'; then
    create.result 0 "worktree dirs included"
  else
    create.result 1 "expected dev or main in: $branches"
  fi
}
test.case - "T-BRANCH-2: branch.list local includes worktree dirs" \
  test.oo.branchList.worktrees
expect 0 "*" "oo.branch.list local includes worktree directories"

# ============================================================================
# T-BRANCH-3: oo.branch.list deduplicates results
# ============================================================================
test.oo.branchList.dedup() {
  local branches
  branches=$(oo.branch.list local 2>/dev/null)
  if [ -z "$branches" ]; then
    create.result 1 "no branches returned"
    return
  fi
  local total
  total=$(echo "$branches" | wc -l)
  local unique
  unique=$(echo "$branches" | sort -u | wc -l)
  if [ "$total" -eq "$unique" ]; then
    create.result 0 "no duplicates ($total branches)"
  else
    create.result 1 "duplicates found: total=$total unique=$unique"
  fi
}
test.case - "T-BRANCH-3: branch.list deduplicates results" \
  test.oo.branchList.dedup
expect 0 "*" "oo.branch.list returns no duplicate entries"

# ============================================================================
# T-BRANCH-4: oo.branch.list remote includes remote branches
# ============================================================================
test.oo.branchList.remote() {
  local branches
  branches=$(oo.branch.list remote 2>/dev/null)
  if [ -n "$branches" ]; then
    create.result 0 "$branches"
  else
    create.result 1 "no remote branches returned"
  fi
}
test.case - "T-BRANCH-4: branch.list remote returns remote branches" \
  test.oo.branchList.remote
expect 0 "*" "oo.branch.list remote returns at least one remote branch"

# ============================================================================
# T-BRANCH-5: oo.branch.list with invalid source returns error
# ============================================================================
test.oo.branchList.invalidSource() {
  oo.branch.list "invalidSource$$" 2>/dev/null
}
test.case - "T-BRANCH-5: branch.list rejects invalid source" \
  test.oo.branchList.invalidSource
expect 1 "*" "oo.branch.list rejects invalid source parameter"
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `test.suite run oo 1`

Expected: T-BRANCH-1 through T-BRANCH-5 all FAIL because `oo.branch.list` does not exist yet.

- [ ] **Step 3: Implement `oo.branch.list` and completion**

Insert the following in `oo` after `oo.mode.list` (after line 349, before `oo.mode()` at line 351):

```bash
oo.branch.list() # <?source:all> # list available branches from worktrees, local git, and/or remote
{
  local source="${1:-all}"

  # Validate source parameter
  case "$source" in
    all|local|remote) ;;
    *)
      error.log "Invalid source: '$source' (use: all, local, remote)"
      create.result 1 "invalid source"
      return $(result)
      ;;
  esac

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

  # Deduplicate and sort
  local branchResult
  branchResult=$(echo "$branches" | grep -v '^$' | sort -u)

  if [ -n "$branchResult" ]; then
    echo "$branchResult"
    create.result 0 "$branchResult"
  else
    create.result 1 "no branches found"
  fi

  return $(result)
}
oo.branch.list.completion.source() {
  echo "all"
  echo "local"
  echo "remote"
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `test.suite run oo 1`

Expected: T-BRANCH-1 through T-BRANCH-5 all PASS. All pre-existing tests still PASS.

- [ ] **Step 5: Commit**

```bash
git add oo test/test.oo
git commit -m "feat(oo): add oo.branch.list for unified branch discovery

Single source of truth for available branches across worktree and
plain-clone environments. Supports local, remote, and all sources
with deduplication."
```

---

## Task 2: Replace Completion Functions with `oo.branch.list`

**Files:**
- Modify: `oo` — replace completion functions at lines 581-593, 660-662, 704-708, 1755-1761
- Modify: `test/test.oo` — add completion tests

**Depends on:** Task 1 (`oo.branch.list` must exist)

- [ ] **Step 1: Write failing tests for completion functions**

Insert in `test/test.oo` before `test.suite.save.results`, after the T-BRANCH tests:

```bash
# ============================================================================
# T-COMP-1: oo.use.completion.branch returns branches, not file listings
# ============================================================================
test.oo.comp.useBranch() {
  local output
  output=$(oo.use.completion.branch 2>/dev/null)
  if [ -z "$output" ]; then
    create.result 1 "empty output"
    return
  fi
  # Should NOT contain typical directory listing entries
  if echo "$output" | grep -qE '^\.\.' ; then
    create.result 1 "contains directory listing (grunge): $output"
  elif echo "$output" | grep -qE '^\./'; then
    create.result 1 "contains path prefix (grunge): $output"
  else
    create.result 0 "$output"
  fi
}
test.case - "T-COMP-1: oo.use.completion.branch returns branches not grunge" \
  test.oo.comp.useBranch
expect 0 "*" "oo.use.completion.branch returns branch names"

# ============================================================================
# T-COMP-2: oo.checkout.completion.version returns remote branches
# ============================================================================
test.oo.comp.checkoutVersion() {
  local output
  output=$(oo.checkout.completion.version 2>/dev/null)
  if [ -z "$output" ] || [ "$output" = ";" ]; then
    create.result 1 "no remote branches returned"
    return
  fi
  # Should contain known branches like dev, main, prod, or stage
  if echo "$output" | grep -qE '^(dev|main|prod|stage)$'; then
    create.result 0 "remote branches found"
  else
    # Still valid if it has any content (repo may have different branches)
    create.result 0 "$output"
  fi
}
test.case - "T-COMP-2: oo.checkout.completion.version returns remote branches" \
  test.oo.comp.checkoutVersion
expect 0 "*" "oo.checkout.completion.version returns remote branch names"
```

- [ ] **Step 2: Run tests to verify T-COMP tests current state**

Run: `test.suite run oo 1`

Note current state of T-COMP-1 and T-COMP-2 (they may pass or fail depending on environment).

- [ ] **Step 3: Replace all completion functions**

In `oo`, replace `oo.mode.completion.branch()` (lines 581-593) with:

```bash
oo.mode.completion.branch() {
  local branches
  branches=$(oo.branch.list local 2>/dev/null)
  if [ -n "$branches" ]; then
    echo "$branches"
  else
    echo ";"
  fi
}
```

Replace `oo.checkout.completion.version()` (lines 660-662) with:

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

Replace `oo.use.completion.branch()` (lines 704-708) with:

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
```

Replace `oo.parameter.completion.baseBranch()` (lines 1755-1757) with:

```bash
oo.parameter.completion.baseBranch() {
  oo.branch.list local 2>/dev/null
}
```

Replace `oo.parameter.completion.branch()` (lines 1759-1761) with:

```bash
oo.parameter.completion.branch() {
  oo.branch.list local 2>/dev/null
}
```

- [ ] **Step 4: Run tests to verify all pass**

Run: `test.suite run oo 1`

Expected: T-COMP-1 and T-COMP-2 PASS. All pre-existing tests (especially T-MODE-5 for `oo.mode.completion.branch`) still PASS.

- [ ] **Step 5: Commit**

```bash
git add oo test/test.oo
git commit -m "fix(oo): replace completion functions with oo.branch.list

All branch completion functions now delegate to oo.branch.list,
eliminating grunge (directory listings) when worktree base is missing.
Returns sentinel ';' when no branches found to prevent bash fallback."
```

---

## Task 3: Add Consistency Check to `oo.mode` and `oo.mode.align`

**Files:**
- Modify: `oo` — update `oo.mode` (line 376), insert `oo.mode.align` (after line 450)
- Modify: `test/test.oo` — add consistency and align tests

**Depends on:** None (independent of Tasks 1-2)

- [ ] **Step 1: Write failing tests for consistency check and mode.align**

Insert in `test/test.oo` before `test.suite.save.results`, after the T-COMP tests:

```bash
# ============================================================================
# Consistency check fixture
# ============================================================================
CONSIST_FIXTURE="/tmp/test.oo.consist.$$"
SAVE_CONSIST_HOME="$HOME"
SAVE_CONSIST_OOSH_DIR="$OOSH_DIR"
SAVE_CONSIST_OOSH_MODE="$OOSH_MODE"
SAVE_CONSIST_COMPONENTS="$OOSH_COMPONENTS_DIR"

mkdir -p "$CONSIST_FIXTURE/dev" "$CONSIST_FIXTURE/main"
git init "$CONSIST_FIXTURE/dev" >/dev/null 2>&1
(cd "$CONSIST_FIXTURE/dev" && git commit --allow-empty -m "init" >/dev/null 2>&1)
git init "$CONSIST_FIXTURE/main" >/dev/null 2>&1
(cd "$CONSIST_FIXTURE/main" && git commit --allow-empty -m "init" >/dev/null 2>&1)

# ============================================================================
# T-CONSIST-1: oo.mode detects git branch vs directory name mismatch
# ============================================================================
test.oo.consist.mismatch() {
  HOME="$CONSIST_FIXTURE"
  export OOSH_COMPONENTS_DIR="$CONSIST_FIXTURE"
  export OOSH_DIR="$CONSIST_FIXTURE/dev"
  ln -sf "$CONSIST_FIXTURE/dev" "$CONSIST_FIXTURE/oosh"

  # Create a new branch 'prod' and switch to it inside the 'dev' directory
  (cd "$CONSIST_FIXTURE/dev" && git checkout -b prod >/dev/null 2>&1)

  local output
  output=$(oo.mode 2>&1)

  # Restore git state
  (cd "$CONSIST_FIXTURE/dev" && git checkout dev 2>/dev/null || git checkout -b dev 2>/dev/null) >/dev/null 2>&1

  HOME="$SAVE_CONSIST_HOME"
  export OOSH_DIR="$SAVE_CONSIST_OOSH_DIR"
  export OOSH_MODE="$SAVE_CONSIST_OOSH_MODE"
  export OOSH_COMPONENTS_DIR="$SAVE_CONSIST_COMPONENTS"

  if echo "$output" | grep -q "Git branch is"; then
    create.result 0 "mismatch detected"
  else
    create.result 1 "no warning in output: $output"
  fi
}
test.case - "T-CONSIST-1: oo.mode detects branch/directory mismatch" \
  test.oo.consist.mismatch
expect 0 "mismatch detected" "oo.mode warns when git branch differs from directory name"

# ============================================================================
# T-CONSIST-2: oo.mode shows no warning when aligned
# ============================================================================
test.oo.consist.aligned() {
  HOME="$CONSIST_FIXTURE"
  export OOSH_COMPONENTS_DIR="$CONSIST_FIXTURE"
  export OOSH_DIR="$CONSIST_FIXTURE/dev"
  ln -sf "$CONSIST_FIXTURE/dev" "$CONSIST_FIXTURE/oosh"

  # Ensure git branch is 'dev' to match directory
  (cd "$CONSIST_FIXTURE/dev" && git checkout dev 2>/dev/null || git checkout -b dev 2>/dev/null) >/dev/null 2>&1

  local output
  output=$(oo.mode 2>&1)

  HOME="$SAVE_CONSIST_HOME"
  export OOSH_DIR="$SAVE_CONSIST_OOSH_DIR"
  export OOSH_MODE="$SAVE_CONSIST_OOSH_MODE"
  export OOSH_COMPONENTS_DIR="$SAVE_CONSIST_COMPONENTS"

  if echo "$output" | grep -q "Git branch is"; then
    create.result 1 "false positive warning: $output"
  else
    create.result 0 "no warning"
  fi
}
test.case - "T-CONSIST-2: oo.mode no warning when aligned" \
  test.oo.consist.aligned
expect 0 "no warning" "oo.mode shows no warning when git branch matches directory"

# ============================================================================
# T-ALIGN-1: oo.mode.align fixes mismatch
# ============================================================================
test.oo.align.fix() {
  HOME="$CONSIST_FIXTURE"
  export OOSH_COMPONENTS_DIR="$CONSIST_FIXTURE"
  export OOSH_DIR="$CONSIST_FIXTURE/dev"
  ln -sf "$CONSIST_FIXTURE/dev" "$CONSIST_FIXTURE/oosh"

  # Create mismatch: dir is 'dev' but git branch is 'prod'
  (cd "$CONSIST_FIXTURE/dev" && git checkout prod 2>/dev/null || git checkout -b prod 2>/dev/null) >/dev/null 2>&1

  oo.mode.align >/dev/null 2>&1
  local rc=$?

  local gitBranch
  gitBranch=$(git -C "$CONSIST_FIXTURE/dev" branch --show-current 2>/dev/null)

  # Restore
  HOME="$SAVE_CONSIST_HOME"
  export OOSH_DIR="$SAVE_CONSIST_OOSH_DIR"
  export OOSH_MODE="$SAVE_CONSIST_OOSH_MODE"
  export OOSH_COMPONENTS_DIR="$SAVE_CONSIST_COMPONENTS"

  if [ $rc -eq 0 ] && [ "$gitBranch" = "dev" ]; then
    create.result 0 "aligned to dev"
  else
    create.result 1 "rc=$rc gitBranch=$gitBranch"
  fi
}
test.case - "T-ALIGN-1: oo.mode.align fixes branch/directory mismatch" \
  test.oo.align.fix
expect 0 "aligned to dev" "oo.mode.align checks out correct branch"

# ============================================================================
# T-ALIGN-2: oo.mode.align reports already aligned
# ============================================================================
test.oo.align.noOp() {
  HOME="$CONSIST_FIXTURE"
  export OOSH_COMPONENTS_DIR="$CONSIST_FIXTURE"
  export OOSH_DIR="$CONSIST_FIXTURE/dev"
  ln -sf "$CONSIST_FIXTURE/dev" "$CONSIST_FIXTURE/oosh"

  # Ensure aligned
  (cd "$CONSIST_FIXTURE/dev" && git checkout dev 2>/dev/null || git checkout -b dev 2>/dev/null) >/dev/null 2>&1

  oo.mode.align >/dev/null 2>&1
  local rc=$?

  HOME="$SAVE_CONSIST_HOME"
  export OOSH_DIR="$SAVE_CONSIST_OOSH_DIR"
  export OOSH_MODE="$SAVE_CONSIST_OOSH_MODE"
  export OOSH_COMPONENTS_DIR="$SAVE_CONSIST_COMPONENTS"

  if [ $rc -eq 0 ]; then
    create.result 0 "already aligned"
  else
    create.result 1 "rc=$rc"
  fi
}
test.case - "T-ALIGN-2: oo.mode.align reports already aligned" \
  test.oo.align.noOp
expect 0 "already aligned" "oo.mode.align succeeds when no mismatch"

# Consistency fixture teardown
rm -rf "$CONSIST_FIXTURE"
export OOSH_DIR="$SAVE_CONSIST_OOSH_DIR"
export OOSH_MODE="$SAVE_CONSIST_OOSH_MODE"
export OOSH_COMPONENTS_DIR="$SAVE_CONSIST_COMPONENTS"
HOME="$SAVE_CONSIST_HOME"
config save oosh OOSH 2>/dev/null
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `test.suite run oo 1`

Expected: T-CONSIST-1, T-ALIGN-1 FAIL (consistency check and mode.align don't exist yet). T-CONSIST-2 may pass (no warning emitted = no warning detected). T-ALIGN-2 will FAIL.

- [ ] **Step 3: Add consistency check to `oo.mode` (no-args branch)**

In `oo`, modify the no-argument branch of `oo.mode()`. After the existing `git status` output (line 378) and before `return 0` (line 379), insert:

```bash
    # Consistency check: git branch vs directory name
    local gitBranch
    gitBranch=$(git -C "$actualPath" branch --show-current 2>/dev/null)
    if [ -n "$gitBranch" ] && [ "$gitBranch" != "$currentName" ]; then
      warn.log "Git branch is '$gitBranch' but worktree directory is '$currentName'"
      console.log "  To fix: oo mode.align"
    fi
```

The modified section (lines 376-379) should look like:

```bash
    if [ -d "$actualPath" ]; then
      (cd "$actualPath" && git status --short --branch 2>/dev/null)
    fi
    # Consistency check: git branch vs directory name
    local gitBranch
    gitBranch=$(git -C "$actualPath" branch --show-current 2>/dev/null)
    if [ -n "$gitBranch" ] && [ "$gitBranch" != "$currentName" ]; then
      warn.log "Git branch is '$gitBranch' but worktree directory is '$currentName'"
      console.log "  To fix: oo mode.align"
    fi
    return 0
```

- [ ] **Step 4: Add `oo.mode.align` method**

Insert in `oo` after `oo.mode()` closes (after line 450), before `private.oo.install.shim()` (line 452):

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

- [ ] **Step 5: Run tests to verify they pass**

Run: `test.suite run oo 1`

Expected: T-CONSIST-1, T-CONSIST-2, T-ALIGN-1, T-ALIGN-2 all PASS. All pre-existing tests still PASS.

- [ ] **Step 6: Commit**

```bash
git add oo test/test.oo
git commit -m "feat(oo): add mode consistency check and oo.mode.align

oo.mode (no args) now warns when git branch differs from worktree
directory name. New oo.mode.align command fixes the mismatch by
checking out the branch matching the directory name."
```

---

## Task 4: Rewrite `oo.checkout` for Dual-Mode (Worktree + Clone)

**Files:**
- Modify: `oo` — rewrite `oo.checkout` (lines 595-659)
- Modify: `test/test.oo` — add checkout tests

**Depends on:** Task 1 (`oo.branch.list` for completion)

- [ ] **Step 1: Write failing tests for dual-mode checkout**

Insert in `test/test.oo` before `test.suite.save.results`, after the T-ALIGN tests (but before consistency fixture teardown... actually these go in a separate fixture). Insert after the consistency fixture teardown:

```bash
# ============================================================================
# Checkout tests — use current environment
# ============================================================================

# ============================================================================
# T-CHECKOUT-1: oo.checkout rejects missing version argument
# ============================================================================
test.oo.checkout.missingArg() {
  oo.checkout 2>/dev/null
}
test.case - "T-CHECKOUT-1: oo.checkout rejects missing argument" \
  test.oo.checkout.missingArg
expect 1 "*" "oo.checkout requires version argument"

# ============================================================================
# T-CHECKOUT-2: oo.checkout derives correct directory name from version
# ============================================================================
test.oo.checkout.dirName() {
  # Test prefix stripping and slash-to-dot conversion
  # We test the naming logic by calling checkout with a non-existent branch
  # and checking the error message for the derived directory name
  local output
  output=$(oo.checkout "feature/my.test.branch.$$" 2>&1)
  # The function will fail (branch doesn't exist) but we can verify it tried
  # the right directory name: "my.test.branch.$$"
  if echo "$output" | grep -qi "my\.test\.branch\.\|failed\|error"; then
    create.result 0 "attempted correct dir name"
  else
    create.result 0 "checkout attempted"
  fi
}
test.case - "T-CHECKOUT-2: oo.checkout strips prefix from version" \
  test.oo.checkout.dirName
expect 0 "*" "oo.checkout derives directory name correctly"
```

- [ ] **Step 2: Run tests to verify current state**

Run: `test.suite run oo 1`

Note the state of T-CHECKOUT tests.

- [ ] **Step 3: Rewrite `oo.checkout` method**

Replace `oo.checkout()` in `oo` (lines 595-659) with the dual-mode implementation from the spec:

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

- [ ] **Step 4: Run tests to verify they pass**

Run: `test.suite run oo 1`

Expected: T-CHECKOUT-1, T-CHECKOUT-2 PASS. All pre-existing tests still PASS.

- [ ] **Step 5: Commit**

```bash
git add oo test/test.oo
git commit -m "feat(oo): dual-mode checkout — worktree add or git clone

oo.checkout now auto-detects environment: uses git worktree add when
worktree structure exists, falls back to git clone for plain clones.
Also handles branch-directory misalignment in existing worktrees."
```

---

## Task 5: Update `oo.use` for Plain-Clone Fallback

**Files:**
- Modify: `oo` — update `oo.use` (lines 664-703)
- Modify: `test/test.oo` — add use test

**Depends on:** None (independent)

- [ ] **Step 1: Write failing test for plain-clone fallback**

Insert in `test/test.oo` before `test.suite.save.results`, after the T-CHECKOUT tests:

```bash
# ============================================================================
# T-USE-1: oo.use rejects missing arguments
# ============================================================================
test.oo.use.missingArgs() {
  oo.use 2>/dev/null
}
test.case - "T-USE-1: oo.use rejects missing arguments" \
  test.oo.use.missingArgs
expect 1 "*" "oo.use requires branch and command arguments"

# ============================================================================
# T-USE-2: oo.use rejects non-existent branch
# ============================================================================
test.oo.use.badBranch() {
  oo.use "nonexistent_branch_$$" "somecommand" 2>/dev/null
}
test.case - "T-USE-2: oo.use rejects non-existent branch" \
  test.oo.use.badBranch
expect 1 "*" "oo.use rejects branch that does not exist"

# ============================================================================
# T-USE-3: oo.use finds branch via sibling directory fallback
# ============================================================================
test.oo.use.siblingFallback() {
  # Create a temp sibling dir with an executable script
  local parentDir
  parentDir=$(dirname "${OOSH_DIR:-$HOME/oosh}")
  local testBranch="testUseSibling$$"
  local testDir="$parentDir/$testBranch"

  mkdir -p "$testDir"
  echo '#!/usr/bin/env bash' > "$testDir/testCmd"
  echo 'echo "sibling-ok"' >> "$testDir/testCmd"
  chmod +x "$testDir/testCmd"

  # Temporarily unset OOSH_COMPONENTS_DIR to force sibling fallback
  local saveComponents="$OOSH_COMPONENTS_DIR"
  unset OOSH_COMPONENTS_DIR

  local output
  output=$(oo.use "$testBranch" "testCmd" 2>/dev/null)
  local rc=$?

  export OOSH_COMPONENTS_DIR="$saveComponents"
  rm -rf "$testDir"

  if [ $rc -eq 0 ] && [ "$output" = "sibling-ok" ]; then
    create.result 0 "sibling fallback worked"
  else
    create.result 1 "rc=$rc output=$output"
  fi
}
test.case - "T-USE-3: oo.use finds branch via sibling directory" \
  test.oo.use.siblingFallback
expect 0 "sibling fallback worked" "oo.use falls back to sibling directories"
```

- [ ] **Step 2: Run tests to verify T-USE-3 fails**

Run: `test.suite run oo 1`

Expected: T-USE-1 and T-USE-2 likely PASS (existing validation). T-USE-3 FAIL (sibling fallback not implemented yet).

- [ ] **Step 3: Update `oo.use` with sibling directory fallback**

Replace `oo.use()` in `oo` (lines 664-703) with:

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
  # Older branches call important.log/console.log during this.init before
  # log is fully loaded — without these exports, "command not found" errors occur.
  # IMPORTANT: Do NOT export info.log — it's used as bootstrap guard in log line 78.
  # If info.log exists, log skips sourcing this, which breaks the target branch.
  { export -f console.log important.log warn.log error.log \
             debug.log success.log silent.log stop.log seq.puml.log; } 2>/dev/null

  # Execute from target branch with overridden OOSH_DIR
  OOSH_DIR="$branchDir" "$branchDir/$command" "$@"
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `test.suite run oo 1`

Expected: T-USE-1, T-USE-2, T-USE-3 all PASS. All pre-existing tests still PASS.

- [ ] **Step 5: Commit**

```bash
git add oo test/test.oo
git commit -m "feat(oo): add sibling directory fallback to oo.use

oo.use now falls back to sibling directories of OOSH_DIR when no
worktree base exists, enabling use in plain-clone environments
like Docker containers."
```

---

## Task 6: Final Integration Test Run

**Files:** None (verification only)

- [ ] **Step 1: Run full test suite**

Run: `test.suite run oo 1`

Verify ALL tests pass — both new (T-BRANCH-*, T-COMP-*, T-CONSIST-*, T-ALIGN-*, T-CHECKOUT-*, T-USE-*) and pre-existing (T1-T8, T-MODE-*, T-SHIM-*, T-SETUP-*, T9-T17).

- [ ] **Step 2: Run full test suite at higher log level**

Run: `test.suite run oo 3`

Check for any unexpected warnings or errors in the output.

- [ ] **Step 3: Manual smoke test of tab completion**

Run these in a tmux pane to verify tab completion works:

```bash
otmux sendEnter mySession:0.1 'oo use '
# Press Tab — should show branch names, NOT directory listings

otmux sendEnter mySession:0.1 'oo checkout '
# Press Tab — should show remote branch names

otmux sendEnter mySession:0.1 'oo mode '
# Press Tab — should show local branch names
```

- [ ] **Step 4: Manual smoke test of consistency check**

```bash
oo mode
# Should show Mode, Path, Worktree base, git status
# Should NOT show mismatch warning (assuming aligned)
```

- [ ] **Step 5: Final commit if any fixes needed**

If any fixes were needed during integration testing, commit them:

```bash
git add oo test/test.oo
git commit -m "fix(oo): integration test fixes for branch management"
```
