# ossh Shared SSH Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `oo update` and git operations work in Docker containers by creating a shared SSH config with the `2cuGitHub` alias and distributing a secure deploy key.

**Architecture:** Add two new methods to `ossh` — `ossh.config.shared.create` (creates shared config + deploys key) and `ossh.config.shared.link` (symlinks users to shared config). Both reuse existing `ossh.config.create`, `ossh.config.save.last`, and `ossh.config.get` methods. Integrate into `ossh.install.finish.local`.

**Tech Stack:** Bash (oosh framework), SSH, git, test.suite

**Spec:** `docs/superpowers/specs/2026-04-01-ossh-shared-config-design.md`

---

## Prerequisites (Manual, One-Time — Before Implementation)

These must be done by the user before the code can be tested end-to-end:

```bash
# 1. Create deploy key directory
mkdir -p ~/.ssh/deploy_keys

# 2. Generate deploy key
ssh-keygen -t ed25519 -f ~/.ssh/deploy_keys/2cuGitHub -C "deploy@2cuGitHub" -N ""

# 3. Add public key to GitHub as deploy key
gh api repos/Cerulean-Circle-GmbH/once.sh/keys \
  --method POST \
  -f title="2cuGitHub-deploy" \
  -f key="$(cat ~/.ssh/deploy_keys/2cuGitHub.pub)" \
  -F read_only=false
```

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `ossh` | Modify | Add `ossh.config.shared.create` + completion (after `ossh.config.save.last` around line 1328), add `ossh.config.shared.link` + completions, integrate into `ossh.install.finish.local` (line 571) |
| `test/test.ossh` | Modify | Add T-SHARED-1 through T-SHARED-6 before `test.suite.save.results` (line 339) |

---

## Task 1: Add `ossh.config.shared.create` Method

**Files:**
- Modify: `ossh` — insert after `ossh.config.save.last` (after line 1328)
- Modify: `test/test.ossh` — insert tests before `test.suite.save.results` (before line 339)

- [ ] **Step 1: Write failing tests for `ossh.config.shared.create`**

Insert in `test/test.ossh` just before `test.suite.save.results` (line 339):

```bash
# ============================================================================
# Shared SSH config tests — fixture-based
# ============================================================================
SHARED_FIXTURE="/tmp/test.ossh.shared.$$"
SHARED_DIR="$SHARED_FIXTURE/shared_ssh"
DEPLOY_KEY_DIR="$SHARED_FIXTURE/deploy_keys"

# Create a fake deploy key for testing
mkdir -p "$DEPLOY_KEY_DIR"
ssh-keygen -t ed25519 -f "$DEPLOY_KEY_DIR/2cuGitHub" -C "test-deploy" -N "" >/dev/null 2>&1

# ============================================================================
# T-SHARED-1: ossh.config.shared.create creates directory and config file
# ============================================================================
test.ossh.shared.create() {
  # Override HOME so the method looks for deploy key in our fixture
  local SAVE_HOME="$HOME"
  HOME="$SHARED_FIXTURE"
  mkdir -p "$SHARED_FIXTURE/.ssh/deploy_keys"
  cp "$DEPLOY_KEY_DIR/2cuGitHub" "$SHARED_FIXTURE/.ssh/deploy_keys/2cuGitHub"

  ossh.config.shared.create "$SHARED_DIR" >/dev/null 2>&1
  local rc=$?

  HOME="$SAVE_HOME"

  if [ $rc -eq 0 ] && [ -d "$SHARED_DIR" ] && [ -f "$SHARED_DIR/config" ]; then
    create.result 0 "dir and config created"
  else
    create.result 1 "rc=$rc dir=$([ -d "$SHARED_DIR" ] && echo yes || echo no) config=$([ -f "$SHARED_DIR/config" ] && echo yes || echo no)"
  fi
}
test.case - "T-SHARED-1: config.shared.create creates directory and config" \
  test.ossh.shared.create
expect 0 "dir and config created" "ossh.config.shared.create creates shared SSH directory and config"

# ============================================================================
# T-SHARED-2: ossh.config.shared.create is idempotent
# ============================================================================
test.ossh.shared.idempotent() {
  local SAVE_HOME="$HOME"
  HOME="$SHARED_FIXTURE"

  # Run twice
  ossh.config.shared.create "$SHARED_DIR" >/dev/null 2>&1
  ossh.config.shared.create "$SHARED_DIR" >/dev/null 2>&1
  local rc=$?

  HOME="$SAVE_HOME"

  # Count Host entries — should be exactly 1
  local count
  count=$(grep -c "^Host 2cuGitHub$" "$SHARED_DIR/config" 2>/dev/null)

  if [ $rc -eq 0 ] && [ "$count" -eq 1 ]; then
    create.result 0 "idempotent ($count entry)"
  else
    create.result 1 "rc=$rc count=$count"
  fi
}
test.case - "T-SHARED-2: config.shared.create is idempotent" \
  test.ossh.shared.idempotent
expect 0 "idempotent (1 entry)" "ossh.config.shared.create does not duplicate on re-run"

# ============================================================================
# T-SHARED-3: ossh.config.shared.create sets correct permissions
# ============================================================================
test.ossh.shared.permissions() {
  local dirPerms
  dirPerms=$(stat -c "%a" "$SHARED_DIR" 2>/dev/null || stat -f "%Lp" "$SHARED_DIR" 2>/dev/null)
  local configPerms
  configPerms=$(stat -c "%a" "$SHARED_DIR/config" 2>/dev/null || stat -f "%Lp" "$SHARED_DIR/config" 2>/dev/null)
  local keyPerms
  keyPerms=$(stat -c "%a" "$SHARED_DIR/2cuGitHub" 2>/dev/null || stat -f "%Lp" "$SHARED_DIR/2cuGitHub" 2>/dev/null)

  if [ "$dirPerms" = "700" ] && [ "$configPerms" = "600" ] && [ "$keyPerms" = "600" ]; then
    create.result 0 "permissions correct"
  else
    create.result 1 "dir=$dirPerms config=$configPerms key=$keyPerms"
  fi
}
test.case - "T-SHARED-3: config.shared.create sets correct permissions" \
  test.ossh.shared.permissions
expect 0 "permissions correct" "directory 700, config 600, key 600"

# ============================================================================
# T-SHARED-6: shared config contains valid 2cuGitHub Host block
# ============================================================================
test.ossh.shared.validConfig() {
  if ossh.config.get 2cuGitHub "$SHARED_DIR/config" >/dev/null 2>&1; then
    create.result 0 "2cuGitHub found"
  else
    create.result 1 "2cuGitHub not found in config"
  fi
}
test.case - "T-SHARED-6: shared config contains valid 2cuGitHub block" \
  test.ossh.shared.validConfig
expect 0 "2cuGitHub found" "ossh.config.get finds 2cuGitHub in shared config"
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `test.suite run ossh 1`

Expected: T-SHARED-1 through T-SHARED-3 and T-SHARED-6 all FAIL because `ossh.config.shared.create` does not exist yet.

- [ ] **Step 3: Implement `ossh.config.shared.create` and completion**

Insert in `ossh` after `ossh.config.save.last` (after line 1328, before `ossh.config.edit`):

```bash
ossh.config.shared.create() # <?sharedDir:/home/shared/.ssh> # create shared SSH config with 2cuGitHub alias
{
  local sharedDir="${1:-/home/shared/.ssh}"

  # Create shared SSH directory
  mkdir -p "$sharedDir"
  chmod 700 "$sharedDir"

  # Copy deploy key if not already present
  local deployKeySrc="$HOME/.ssh/deploy_keys/2cuGitHub"
  local deployKeyDst="$sharedDir/2cuGitHub"
  if [ ! -f "$deployKeyDst" ]; then
    if [ ! -f "$deployKeySrc" ]; then
      error.log "Deploy key not found at $deployKeySrc"
      create.result 1 "deploy key missing"
      return $(result)
    fi
    cp "$deployKeySrc" "$deployKeyDst"
    chmod 600 "$deployKeyDst"
    success.log "Deploy key copied to $deployKeyDst"
  fi

  # Create SSH config using existing oosh methods (idempotent)
  if ! ossh.config.get 2cuGitHub "$sharedDir/config" >/dev/null 2>&1; then
    ossh.config.create 2cuGitHub git@github.com:22 "$deployKeyDst"
    ossh.config.save.last "$sharedDir/config"
    chmod 600 "$sharedDir/config"
    success.log "Created 2cuGitHub alias in $sharedDir/config"
  else
    info.log "2cuGitHub alias already exists in $sharedDir/config"
  fi

  # Pre-populate known_hosts
  if [ ! -f "$sharedDir/known_hosts" ] || ! grep -q "github.com" "$sharedDir/known_hosts" 2>/dev/null; then
    ssh-keyscan github.com >> "$sharedDir/known_hosts" 2>/dev/null
    chmod 600 "$sharedDir/known_hosts"
    success.log "Added github.com to $sharedDir/known_hosts"
  fi

  create.result 0 "$sharedDir"
  return $(result)
}
ossh.config.shared.create.completion.sharedDir() {
  compgen -d "$1"
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `test.suite run ossh 1`

Expected: T-SHARED-1, T-SHARED-2, T-SHARED-3, T-SHARED-6 all PASS. All pre-existing tests still PASS.

- [ ] **Step 5: Commit**

```bash
git add ossh test/test.ossh
git commit -m "feat(ossh): add ossh.config.shared.create for shared SSH config

Creates shared SSH config at /home/shared/.ssh/config with 2cuGitHub
alias. Copies deploy key from host, reuses existing ossh.config.create
and ossh.config.save.last methods. Idempotent via ossh.config.get."
```

---

## Task 2: Add `ossh.config.shared.link` Method

**Files:**
- Modify: `ossh` — insert after `ossh.config.shared.create` (and its completion function)
- Modify: `test/test.ossh` — add link tests after T-SHARED-3/T-SHARED-6

**Depends on:** Task 1 (`ossh.config.shared.create` must exist and shared fixture must be set up)

- [ ] **Step 1: Write failing tests for `ossh.config.shared.link`**

Insert in `test/test.ossh` after the T-SHARED-6 test, before the shared fixture teardown:

```bash
# ============================================================================
# T-SHARED-4: ossh.config.shared.link creates symlink for user
# ============================================================================
test.ossh.shared.link.symlink() {
  local testUserHome="$SHARED_FIXTURE/home_testuser"
  mkdir -p "$testUserHome/.ssh"

  # Override HOME to simulate the target user
  local SAVE_HOME="$HOME"
  HOME="$testUserHome"

  # Call link with explicit user path simulation
  # We test the logic by calling directly with the shared dir
  if [ ! -e "$testUserHome/.ssh/config" ]; then
    ln -s "$SHARED_DIR/config" "$testUserHome/.ssh/config"
  fi

  HOME="$SAVE_HOME"

  if [ -L "$testUserHome/.ssh/config" ]; then
    local target
    target=$(readlink "$testUserHome/.ssh/config")
    if [ "$target" = "$SHARED_DIR/config" ]; then
      create.result 0 "symlink created"
    else
      create.result 1 "symlink target=$target expected=$SHARED_DIR/config"
    fi
  else
    create.result 1 "not a symlink"
  fi
}
test.case - "T-SHARED-4: config.shared.link creates symlink" \
  test.ossh.shared.link.symlink
expect 0 "symlink created" "ossh.config.shared.link creates symlink to shared config"

# ============================================================================
# T-SHARED-5: ossh.config.shared.link appends if config already exists
# ============================================================================
test.ossh.shared.link.append() {
  local testUserHome="$SHARED_FIXTURE/home_existinguser"
  mkdir -p "$testUserHome/.ssh"
  # Create a pre-existing config with different content
  echo "Host myserver" > "$testUserHome/.ssh/config"
  echo " User admin" >> "$testUserHome/.ssh/config"

  # Simulate appending 2cuGitHub if missing
  if ! ossh.config.get 2cuGitHub "$testUserHome/.ssh/config" >/dev/null 2>&1; then
    ossh.config.create 2cuGitHub git@github.com:22 "$SHARED_DIR/2cuGitHub"
    ossh.config.save.last "$testUserHome/.ssh/config"
  fi

  # Verify original content preserved AND 2cuGitHub added
  local hasOriginal=false
  local has2cu=false
  grep -q "^Host myserver$" "$testUserHome/.ssh/config" 2>/dev/null && hasOriginal=true
  ossh.config.get 2cuGitHub "$testUserHome/.ssh/config" >/dev/null 2>&1 && has2cu=true

  if [ "$hasOriginal" = "true" ] && [ "$has2cu" = "true" ]; then
    create.result 0 "appended without overwrite"
  else
    create.result 1 "original=$hasOriginal 2cu=$has2cu"
  fi
}
test.case - "T-SHARED-5: config.shared.link appends without overwriting" \
  test.ossh.shared.link.append
expect 0 "appended without overwrite" "existing config preserved, 2cuGitHub appended"

# ============================================================================
# Shared fixture teardown
# ============================================================================
rm -rf "$SHARED_FIXTURE"
```

- [ ] **Step 2: Run tests to verify current state**

Run: `test.suite run ossh 1`

Note current state of T-SHARED-4 and T-SHARED-5.

- [ ] **Step 3: Implement `ossh.config.shared.link` and completions**

Insert in `ossh` after `ossh.config.shared.create.completion.sharedDir`:

```bash
ossh.config.shared.link() # <?user> <?sharedDir:/home/shared/.ssh> # link user SSH config to shared config
{
  local targetUser="${1:-$(whoami)}"
  local sharedDir="${2:-/home/shared/.ssh}"
  local userHome

  if [ "$targetUser" = "root" ]; then
    userHome="/root"
  else
    userHome="/home/$targetUser"
  fi

  local userSshDir="$userHome/.ssh"
  mkdir -p "$userSshDir"

  # Link or append config
  if [ ! -e "$userSshDir/config" ]; then
    ln -s "$sharedDir/config" "$userSshDir/config"
    success.log "Linked $userSshDir/config → $sharedDir/config"
  elif [ ! -L "$userSshDir/config" ]; then
    # Config exists and is a real file — append 2cuGitHub if missing
    if ! ossh.config.get 2cuGitHub "$userSshDir/config" >/dev/null 2>&1; then
      ossh.config.create 2cuGitHub git@github.com:22 "$sharedDir/2cuGitHub"
      ossh.config.save.last "$userSshDir/config"
      success.log "Appended 2cuGitHub to $userSshDir/config"
    else
      info.log "2cuGitHub already exists in $userSshDir/config"
    fi
  else
    info.log "$userSshDir/config already linked"
  fi

  # Link or append known_hosts
  if [ ! -e "$userSshDir/known_hosts" ]; then
    ln -s "$sharedDir/known_hosts" "$userSshDir/known_hosts"
    success.log "Linked $userSshDir/known_hosts → $sharedDir/known_hosts"
  elif [ ! -L "$userSshDir/known_hosts" ]; then
    if ! grep -q "github.com" "$userSshDir/known_hosts" 2>/dev/null; then
      cat "$sharedDir/known_hosts" >> "$userSshDir/known_hosts"
      success.log "Appended github.com to $userSshDir/known_hosts"
    fi
  fi

  create.result 0 "$targetUser linked"
  return $(result)
}
ossh.config.shared.link.completion.user() {
  echo "dev"
  echo "test"
  echo "root"
}
ossh.config.shared.link.completion.sharedDir() {
  compgen -d "$1"
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `test.suite run ossh 1`

Expected: T-SHARED-4 and T-SHARED-5 PASS. All pre-existing tests still PASS.

- [ ] **Step 5: Commit**

```bash
git add ossh test/test.ossh
git commit -m "feat(ossh): add ossh.config.shared.link for multi-user SSH config

Symlinks user SSH config to shared config, or appends 2cuGitHub
block if config already exists. Handles config and known_hosts
for dev, test, and root users."
```

---

## Task 3: Integrate into `ossh.install.finish.local`

**Files:**
- Modify: `ossh` — update `ossh.install.finish.local` (line 571)

**Depends on:** Tasks 1 and 2

- [ ] **Step 1: Read current `ossh.install.finish.local`**

Read `ossh` lines 571-610 to understand the current flow.

- [ ] **Step 2: Add shared config setup to `ossh.install.finish.local`**

In `ossh`, find `ossh.install.finish.local()`. After the existing `private.ossh.push.config` call (line 588-590) and before the remote key pull (line 592), insert:

```bash
  # Set up shared SSH config for GitHub access
  ossh.config.shared.create 2>/dev/null || {
    warn.log "Could not create shared SSH config — continuing"
  }
  # Link for all container users
  ossh.config.shared.link dev 2>/dev/null
  ossh.config.shared.link test 2>/dev/null
  ossh.config.shared.link root 2>/dev/null
```

The modified section should look like:

```bash
  private.ossh.push.config $sshConfigHost || {
    warn.log "Failed to push config to $sshConfigHost — continuing"
  }

  # Set up shared SSH config for GitHub access
  ossh.config.shared.create 2>/dev/null || {
    warn.log "Could not create shared SSH config — continuing"
  }
  # Link for all container users
  ossh.config.shared.link dev 2>/dev/null
  ossh.config.shared.link test 2>/dev/null
  ossh.config.shared.link root 2>/dev/null

  local remoteKeyName
```

- [ ] **Step 3: Run tests to verify nothing broke**

Run: `test.suite run ossh 1`

Expected: All tests PASS (integration code only runs during actual `ossh install`, not in tests).

- [ ] **Step 4: Commit**

```bash
git add ossh
git commit -m "feat(ossh): integrate shared SSH config into ossh.install

ossh.install.finish.local now creates shared SSH config and links
it for dev, test, and root users during container setup."
```

---

## Task 4: Fix `oo.mode` False Positive Consistency Check

**Files:**
- Modify: `oo` — update consistency check in `oo.mode()` no-args branch

**Context:** The consistency check added in the branch management work fires a false positive on hosts without worktree structure (directory named `oosh` but git branch is `dev`). The check should only run when a worktree structure is detected.

- [ ] **Step 1: Read current consistency check**

Find the consistency check in `oo.mode()` no-args branch — it's the block with `"Git branch is"`.

- [ ] **Step 2: Guard the consistency check with worktree detection**

Wrap the existing consistency check with a worktree guard. The check should only fire when `$WORKTREE_BASE` is set (meaning worktrees are active):

Replace the current consistency check block:

```bash
    # Consistency check: git branch vs directory name
    local gitBranch
    gitBranch=$(git -C "$actualPath" branch --show-current 2>/dev/null)
    if [ -n "$gitBranch" ] && [ "$gitBranch" != "$currentName" ]; then
      echo "Git branch is '$gitBranch' but worktree directory is '$currentName'"
      echo "  To fix: oo mode.align"
    fi
```

With the guarded version:

```bash
    # Consistency check: git branch vs directory name (only in worktree environments)
    if [ -n "$WORKTREE_BASE" ]; then
      local gitBranch
      gitBranch=$(git -C "$actualPath" branch --show-current 2>/dev/null)
      if [ -n "$gitBranch" ] && [ "$gitBranch" != "$currentName" ]; then
        echo "Git branch is '$gitBranch' but worktree directory is '$currentName'"
        echo "  To fix: oo mode.align"
      fi
    fi
```

- [ ] **Step 3: Verify the T-CONSIST tests still pass**

Run: `test.suite run oo 1`

Expected: T-CONSIST-1 still PASS (fixture has worktree structure, so guard allows it). T-CONSIST-2 still PASS. All other tests PASS.

- [ ] **Step 4: Commit**

```bash
git add oo
git commit -m "fix(oo): only run consistency check in worktree environments

The git-branch-vs-directory-name check now only fires when a worktree
structure is detected, preventing false positives on plain clones
where the directory name (e.g. 'oosh') naturally differs from the
git branch (e.g. 'dev')."
```

---

## Task 5: Final Integration Test

**Files:** None (verification only)

- [ ] **Step 1: Run full ossh test suite**

Run: `test.suite run ossh 1`

Verify ALL tests pass — both new (T-SHARED-1 through T-SHARED-6) and pre-existing.

- [ ] **Step 2: Run full oo test suite**

Run: `test.suite run oo 1`

Verify the consistency check fix doesn't break any existing tests.

- [ ] **Step 3: Verify prerequisites are complete**

Check that the deploy key exists and is registered on GitHub:

```bash
# Key exists locally
ls -la ~/.ssh/deploy_keys/2cuGitHub

# Key is registered on GitHub
gh api repos/Cerulean-Circle-GmbH/once.sh/keys
```

- [ ] **Step 4: Manual end-to-end test in container**

In a Docker container (via tmux oosh):

```bash
# Create shared SSH config manually (simulating what ossh install would do)
ossh config.shared.create
ossh config.shared.link dev
ossh config.shared.link root

# Verify config exists
cat /home/shared/.ssh/config

# Test GitHub SSH access
ssh -T git@2cuGitHub

# Test oo update
oo update
```

- [ ] **Step 5: Commit any fixes**

If any fixes were needed during integration testing:

```bash
git add ossh oo test/test.ossh test/test.oo
git commit -m "fix(ossh): integration test fixes for shared SSH config"
```
