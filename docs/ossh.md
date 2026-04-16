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

## See Also

- [odocker](odocker.md) — Docker container management
- [Architecture](oosh-architecture.md) — OOSH framework overview
- [Branching](branching.md) — Branch and worktree management
