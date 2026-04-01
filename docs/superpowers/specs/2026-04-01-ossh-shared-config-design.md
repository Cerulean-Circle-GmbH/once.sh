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

### 2. Shared SSH Config

**Location:** `/home/shared/.ssh/config`

**Content:**

```
Host 2cuGitHub
  User git
  Port 22
  HostName github.com
  IdentityFile /home/shared/.ssh/2cuGitHub
  StrictHostKeyChecking no
```

- `IdentityFile` points to the shared deploy key (not user-specific `~/.ssh/id_rsa`)
- All users use the same authorized key
- `StrictHostKeyChecking no` avoids interactive prompts in automated environments

**known_hosts:**

- Pre-populate with `ssh-keyscan github.com >> /home/shared/.ssh/known_hosts`
- Symlink or append to each user's `~/.ssh/known_hosts`

### 3. User Symlinks

For each user (dev, test, root), during `ossh install`:

- If `~/.ssh/config` doesn't exist: `ln -s /home/shared/.ssh/config ~/.ssh/config`
- If `~/.ssh/config` already exists: append the `2cuGitHub` block (idempotent — check with `grep` first)
- Same approach for `known_hosts`

### 4. New oosh Methods

**`ossh.config.shared.create`** — creates shared SSH config and deploys the key:

```bash
ossh.config.shared.create() # <?sharedDir:/home/shared/.ssh> # create shared SSH config with 2cuGitHub alias
```

- Creates `/home/shared/.ssh/` directory if needed
- Copies deploy key from host `~/.ssh/deploy_keys/2cuGitHub` to `$sharedDir/2cuGitHub` (if not already there)
- Creates `/home/shared/.ssh/config` with `2cuGitHub` Host block (idempotent)
- Runs `ssh-keyscan github.com` into `/home/shared/.ssh/known_hosts`
- Sets permissions: `chmod 700` on dir, `chmod 600` on key and config
- Uses `create.result` / `return $(result)` pattern

**`ossh.config.shared.link`** — links a user's SSH config to the shared config:

```bash
ossh.config.shared.link() # <?user> <?sharedDir:/home/shared/.ssh> # link user SSH config to shared config
```

- If no user specified, uses current user
- Symlinks `~/.ssh/config` → `/home/shared/.ssh/config` (or appends if config already exists)
- Symlinks or appends `known_hosts`
- Uses `create.result` / `return $(result)` pattern

**Integration into `ossh install`:**

- After SSH keys are transferred to the container
- Call `ossh.config.shared.create` to set up shared config + deploy key
- Call `ossh.config.shared.link` for each user (dev, test, root)

### 5. Testing

Tests in `test/test.ossh`, following existing oosh test patterns.

| Test ID | Description |
|---------|-------------|
| T-SHARED-1 | `ossh.config.shared.create` creates directory and config file |
| T-SHARED-2 | `ossh.config.shared.create` is idempotent (running twice doesn't duplicate) |
| T-SHARED-3 | `ossh.config.shared.create` sets correct permissions (700 dir, 600 files) |
| T-SHARED-4 | `ossh.config.shared.link` creates symlink for current user |
| T-SHARED-5 | `ossh.config.shared.link` appends if config already exists (doesn't overwrite) |
| T-SHARED-6 | Shared config contains valid `2cuGitHub` Host block |

All tests use temp directories as fixtures to avoid touching real `~/.ssh` or `/home/shared/.ssh`.

## Files Modified

| File | Changes |
|------|---------|
| `ossh` | Add `ossh.config.shared.create`, `ossh.config.shared.link`, integrate into `ossh.install` |
| `test/test.ossh` | Add T-SHARED-1 through T-SHARED-6 test cases |

## Prerequisites (Manual, One-Time)

1. Generate deploy key: `ssh-keygen -t ed25519 -f ~/.ssh/deploy_keys/2cuGitHub -C "deploy@2cuGitHub" -N ""`
2. Add public key to GitHub: `gh api repos/Cerulean-Circle-GmbH/once.sh/keys --method POST -f title="developking" -f key="$(cat ~/.ssh/deploy_keys/2cuGitHub.pub)" -F read_only=false`

## OOSH Compliance Checklist

- [x] All new methods follow `script.noun.verb` naming pattern
- [x] All parameter names are camelCase
- [x] Completion functions for completable parameters
- [x] Uses `create.result` / `return $(result)` pattern
- [x] All user-facing output uses oosh logging
- [x] Tests follow existing `test.ossh` patterns
- [x] No private keys committed to git
