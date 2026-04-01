# Design: ossh install — Shared SSH Config and Secure Deploy Key

**Date:** 2026-04-01
**Status:** Approved
**Scope:** `ossh install`, shared SSH config, deploy key distribution, multi-user access

## Problem Statement

After Docker container creation and oosh installation via `ossh install`:
1. The container has SSH keys (`~/.ssh/id_rsa`) but NO `~/.ssh/config`
2. The git remote uses `2cuGitHub:Cerulean-Circle-GmbH/once.sh.git` (SSH alias)
3. SSH can't resolve `2cuGitHub` because there's no config mapping it to `github.com`
4. Result: `oo update`, `git pull`, `git fetch` all fail in containers
5. The existing `developking.ssh/id_rsa` key in the repo is not authorized on GitHub
6. SSH config is not shared across container users (dev, test, root)

### Tickets

1. **Automate SSH config generation** (IP, Port, User) so oosh install works seamlessly
2. **Ensure .ssh/config is linked or copied** to shared host config across users (Dev, Test, Root)

## Approach: Shared Config + Secure Deploy Key

Create a shared SSH config at `/home/shared/.ssh/config` with the `2cuGitHub` alias, distribute a secure deploy key (never committed to git), and symlink all users to the shared config.

## Design

### 1. Secure Deploy Key Distribution

**Key generation (one-time, manual on host):**

```bash
ssh-keygen -t ed25519 -f ~/.ssh/deploy_keys/2cuGitHub -C "deploy@2cuGitHub" -N ""
```

- Public key added to GitHub as deploy key (via `gh api` or web UI)
- Private key stays at `~/.ssh/deploy_keys/2cuGitHub` on the host — never committed to git
- Host path `~/.ssh/deploy_keys/` is outside the repo, never tracked

**During `ossh install`:**

- Copy deploy key from host `~/.ssh/deploy_keys/2cuGitHub` to container's `/home/shared/.ssh/2cuGitHub`
- `/home/shared/.ssh/` is a mounted volume — key persists across container restarts
- All users (dev, test, root) access the same key via the shared config

**Security:**
- Private key never committed to any git repo
- Stored only on the host and in container's shared volume
- The existing `templates/user/developking.ssh/` keys are not authorized anywhere and pose no security risk

### 2. Shared SSH Config — Reusing Existing oosh Methods

The SSH config block is generated using the **existing** oosh SSH config pipeline:

1. `ossh config.create 2cuGitHub git@github.com:22 /home/shared/.ssh/2cuGitHub` — writes Host block to `$CONFIG_PATH/result.txt` via `private.config.create()`
2. `ossh config.save.last /home/shared/.ssh/config` — appends from `result.txt` to shared config (with built-in duplicate detection)

**Idempotency** via existing `ossh config.get`:

```bash
if ! ossh config.get 2cuGitHub /home/shared/.ssh/config; then
  ossh config.create 2cuGitHub git@github.com:22 "$sharedDir/2cuGitHub"
  ossh config.save.last "$sharedDir/config"
fi
```

This reuses three existing oosh methods (`ossh.config.create`, `ossh.config.save.last`, `ossh.config.get`) instead of writing raw SSH config blocks with `echo`.

**known_hosts:**

- Pre-populate with `ssh-keyscan github.com >> /home/shared/.ssh/known_hosts`
- Symlink or append to each user's `~/.ssh/known_hosts`

### 3. User Symlinks

For each user (dev, test, root), during `ossh install`:

- If `~/.ssh/config` doesn't exist: `ln -s /home/shared/.ssh/config ~/.ssh/config`
- If `~/.ssh/config` already exists: append the `2cuGitHub` block using `ossh config.get` (idempotency check) + `ossh config.save.last` (append)
- Same approach for `known_hosts`

### 4. New oosh Methods

**`ossh.config.shared.create`** — creates shared SSH config and deploys the key:

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
  if ! ossh config.get 2cuGitHub "$sharedDir/config" 2>/dev/null; then
    ossh config.create 2cuGitHub git@github.com:22 "$deployKeyDst"
    ossh config.save.last "$sharedDir/config"
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

**`ossh.config.shared.link`** — links a user's SSH config to the shared config:

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
    if ! ossh config.get 2cuGitHub "$userSshDir/config" 2>/dev/null; then
      ossh config.create 2cuGitHub git@github.com:22 "$sharedDir/2cuGitHub"
      ossh config.save.last "$userSshDir/config"
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

**Integration into `ossh install`:**

After SSH keys are transferred to the container, add to `ossh.install.finish.local()` or the appropriate installation step:

```bash
# Set up shared SSH config for GitHub access
ossh config.shared.create
# Link for all container users
ossh config.shared.link dev
ossh config.shared.link test
ossh config.shared.link root
```

### 5. Testing

Tests in `test/test.ossh`, following existing oosh test patterns.

| Test ID | Description |
|---------|-------------|
| T-SHARED-1 | `ossh.config.shared.create` creates directory and config file |
| T-SHARED-2 | `ossh.config.shared.create` is idempotent (running twice doesn't duplicate) |
| T-SHARED-3 | `ossh.config.shared.create` sets correct permissions (700 dir, 600 files) |
| T-SHARED-4 | `ossh.config.shared.link` creates symlink for current user |
| T-SHARED-5 | `ossh.config.shared.link` appends if config already exists (doesn't overwrite) |
| T-SHARED-6 | Shared config contains valid `2cuGitHub` Host block (verified via `ossh config.get`) |

All tests use temp directories as fixtures to avoid touching real `~/.ssh` or `/home/shared/.ssh`.

## Files Modified

| File | Changes |
|------|---------|
| `ossh` | Add `ossh.config.shared.create` + completion, `ossh.config.shared.link` + completions, integrate into `ossh.install` |
| `test/test.ossh` | Add T-SHARED-1 through T-SHARED-6 test cases |

## Prerequisites (Manual, One-Time)

1. Generate deploy key: `ssh-keygen -t ed25519 -f ~/.ssh/deploy_keys/2cuGitHub -C "deploy@2cuGitHub" -N ""`
2. Add public key to GitHub: `gh api repos/Cerulean-Circle-GmbH/once.sh/keys --method POST -f title="2cuGitHub-deploy" -f key="$(cat ~/.ssh/deploy_keys/2cuGitHub.pub)" -F read_only=false`

## OOSH Compliance Checklist

- [x] All new methods follow `script.noun.verb` naming pattern
- [x] All parameter names are camelCase (sharedDir, user)
- [x] Completion function exists for each completable parameter
- [x] Completion function names match parameter names exactly
- [x] Uses `create.result` / `return $(result)` pattern throughout
- [x] All user-facing output uses oosh logging (`success.log`, `info.log`, `error.log`)
- [x] Reuses existing oosh methods: `ossh config.create`, `ossh config.save.last`, `ossh config.get`
- [x] Idempotency via `ossh config.get` (not raw `grep`)
- [x] Tests follow existing `test.ossh` patterns
- [x] No private keys committed to git
- [x] Local variables are camelCase (sharedDir, deployKeySrc, deployKeyDst, targetUser, userHome, userSshDir)
