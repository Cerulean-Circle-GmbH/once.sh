# ossh — SSH Management for oosh

The `ossh` script wraps SSH operations following oosh conventions: key management, config generation, remote installation, and multi-hop connections.

## Overview

- Manages SSH keys, configs, and connections via oosh methods
- Installs oosh on remote hosts over SSH
- Supports multi-hop connections via ProxyJump keyword
- Naming: `tmux→otmux, ssh→ossh, docker→odocker`

## Quick Start

```bash
# Create SSH config for a host
ossh config.create myhost user@hostname:port
ossh config.show.last
ossh config.save.last

# Push your SSH key (for password-less login)
ossh key.push myhost

# Install oosh on the remote host
ossh install myhost username
```

## SSH Config Management

### Creating Configs

```bash
# Two-argument form: alias + URL
ossh config.create myserver admin@192.168.1.100:22

# Single-argument form: auto-derives alias from URL
ossh config.create admin@192.168.1.100

# With specific identity file
ossh config.create myserver admin@192.168.1.100 ~/.ssh/id_ed25519

# With ProxyJump for multi-hop connections (key auto-detected)
ossh config.create myvm admin@192.168.64.5 proxyJump macstudio

# With both explicit key and ProxyJump
ossh config.create myvm admin@192.168.64.5 ~/.ssh/id_ed25519 proxyJump macstudio
```

### Preview, Save, and List

```bash
# Show the last generated config block
ossh config.show.last

# Save it to ~/.ssh/config
ossh config.save.last

# List all configured hosts
ossh list
```

### Generated Config Format

```
Host myserver
 User admin
 Port 22
 HostName 192.168.1.100
 IdentityFile ~/.ssh/id_ed25519
```

With ProxyJump:

```
Host myvm
 User admin
 Port 22
 HostName 192.168.64.5
 IdentityFile ~/.ssh/id_ed25519
 ProxyJump macstudio
```

## ProxyJump — Multi-Hop SSH

ProxyJump connects to a final destination through an intermediate "jump host". Use this when the target machine is on a private network only reachable from the jump host.

### How It Works

```
Your machine  ──SSH──>  Jump host  ──tunnel──>  Target machine
(Ubuntu VM)             (Mac Studio)             (tart VM)
                        public IP                private IP
                        home.donges.it:9922      192.168.64.5
```

Without ProxyJump, `192.168.64.5` is unreachable — it is on the Mac Studio's internal network. ProxyJump automates the connection:

1. SSH connects to the jump host
2. From there, opens a tunnel to the target
3. Your session flows through the tunnel transparently

### Setup

Create the jump host config first (it must exist before you reference it):

```bash
ossh config.create macstudio donges@home.donges.it:9922
ossh config.show.last
ossh config.save.last
```

Then create the target config with the `proxyJump` keyword:

```bash
ossh config.create tart_sequoia admin@192.168.64.5 proxyJump macstudio
ossh config.show.last
ossh config.save.last
```

The `proxyJump` keyword tells ossh to add a `ProxyJump macstudio` line to the SSH config. SSH resolves `macstudio` by looking up `Host macstudio` in the same `~/.ssh/config` file — that is why the jump host config must be created and saved first.

Now all ossh commands reach the target through the jump host:

```bash
ossh key.push tart_sequoia      # pushes key through macstudio
ossh install tart_sequoia admin  # installs oosh through macstudio
ossh login tart_sequoia          # interactive login through macstudio
```

### When to Use ProxyJump

- VMs behind a host (tart/UTM VMs on a Mac Studio)
- Docker containers accessed through a remote host
- Servers on private networks reachable only from a bastion/gateway
- Any target where you need to hop through an intermediate machine

## Key Management

```bash
# Create a new SSH key pair
ossh id.create mykey

# List available keys
ossh list.ids

# Push a key to a remote host
ossh key.push myhost

# Push SSH config to a remote host
ossh config.push myhost
```

## Remote Installation

```bash
# Install oosh on a remote host
ossh install myhost

# Install and set up a specific user
ossh install myhost username
```

What happens during install:

1. Opens persistent SSH connection (password entered once)
2. Transfers `init/oosh` bootstrap script
3. Runs remote installer (installs bash 4+, git, etc.)
4. Sets up worktree for current branch
5. Copies deploy key for GitHub access (if available)
6. Creates user account and symlinks
7. Sets login shell to bash 4+

### Deploy Key

If `~/.ssh/deploy_keys/2cuGitHub` exists on your machine, `ossh install` automatically:

- Copies the key to the remote host's shared SSH directory
- Creates the `2cuGitHub` SSH config alias (pointing to github.com)
- Adds github.com to known_hosts
- Copies everything to all user accounts

This enables `oo update` and `oo checkout` on the remote host.

## Hardening

`ossh.harden` is invoked **after** `ossh install` finishes, on Debian/Ubuntu
remotes only. It applies a standard baseline: unattended-upgrades,
fail2ban, UFW, and an opinionated sshd_config. User creation and SSH-key
distribution are deliberately **not** repeated here — `ossh install` did
that already; `ossh.harden` only adds the security layers.

```bash
ossh install myhost admin        # sets up users, keys, shared-oosh infrastructure
ossh harden  myhost              # locks the box down (no AllowUsers yet — safe default)
```

Each concern is also callable standalone:

| Method | What it does |
|---|---|
| `ossh.harden <host>` | Orchestrator: packages → unattended-upgrades → fail2ban → firewall → sshd. Does **not** touch `AllowUsers`. |
| `ossh.harden.packages <host>` | `apt update && apt dist-upgrade -y && apt install unattended-upgrades fail2ban ufw htop nano bzip2` |
| `ossh.harden.unattended.upgrades <host>` | Writes `/etc/apt/apt.conf.d/20auto-upgrades` + `/etc/apt/apt.conf.d/51-oosh-unattended-upgrades` (auto-remove kernels/deps, reboot at 02:30) |
| `ossh.harden.fail2ban <host>` | Writes `/etc/fail2ban/jail.local` with `[sshd]` block, enables + restarts |
| `ossh.harden.firewall <host> <?extraPorts>` | UFW default deny-in/allow-out + OpenSSH + any optional extras (e.g. `"8080/tcp 8443/tcp"`) |
| `ossh.harden.sshd <host>` | sshd_config hardening toggles. Reloads sshd (existing sessions survive). |
| `ossh.harden.sshd.allowusers <host> <users>` | **Opt-in only.** Appends `AllowUsers`. Include every user who needs SSH access — unlisted users will be locked out. |

### Preflight safety gate

Every `ossh.harden.*` method runs `private.ossh.harden.preflight` first,
which refuses to proceed if:
- The caller cannot SSH in `BatchMode` (only password auth works — hardening would lock them out).
- The remote isn't Linux, or its `/etc/os-release` ID isn't `debian`/`ubuntu`.

### Intentional non-goals

- **No user creation.** `ossh install`'s `user.create` + `install.user.remote` covered this.
- **No NOPASSWD sudoers drop-in.** One-liner if you need it: `echo "<user> ALL=(ALL) NOPASSWD:ALL" | ssh <host> sudo tee /etc/sudoers.d/<user>-nopasswd`.
- **No `AllowUsers` in the orchestrator.** Dangerous default; opt-in via `.sshd.allowusers`.

## Shared SSH Config

For multi-user environments (containers, shared servers):

```bash
# Create shared SSH config with GitHub deploy key
ossh config.shared.create

# Link a user's SSH config to the shared config
ossh config.shared.link username
```

The shared config lives in the platform-appropriate shared home directory — `/home/shared/.ssh/` on Linux, `/Users/shared/.ssh/` on macOS. Paths are detected automatically using `dirname "$HOME"`.

## Method Reference

| Method | Description |
|--------|-------------|
| `ossh config.create` | Create SSH config entry |
| `ossh config.show.last` | Show last generated config |
| `ossh config.save.last` | Save last config to ~/.ssh/config |
| `ossh config.push` | Push SSH config to remote host |
| `ossh config.shared.create` | Create shared SSH config |
| `ossh config.shared.link` | Link user to shared config |
| `ossh install` | Install oosh on remote host |
| `ossh login` | Interactive SSH login |
| `ossh key.push` | Push SSH key to remote host |
| `ossh id.create` | Create new SSH key pair |
| `ossh list` | List configured hosts |
| `ossh list.ids` | List available key identities |
| `ossh harden` | Harden Debian/Ubuntu remote (orchestrator; no AllowUsers) |
| `ossh harden.packages` | Install the hardening package set |
| `ossh harden.unattended.upgrades` | Enable + configure unattended-upgrades |
| `ossh harden.fail2ban` | Enable fail2ban with [sshd] jail |
| `ossh harden.firewall` | Configure UFW (default deny in / allow out + OpenSSH + optional extra ports) |
| `ossh harden.sshd` | Harden sshd_config (no AllowUsers) |
| `ossh harden.sshd.allowusers` | **Opt-in** AllowUsers restriction |

## See Also

- [odocker](odocker.md) — Docker container management
- [Architecture](oosh-architecture.md) — OOSH framework overview
- [Branching](branching.md) — Branch and worktree management
