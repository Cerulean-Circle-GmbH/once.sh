# odocker — Docker Wrapper for oosh

The `odocker` script wraps Docker commands following oosh conventions: positional parameters, tab completion, method signatures with descriptions.

## Overview

- Manages Docker images and containers via oosh methods
- Dockerfiles live in `DockerWorkspaces` (EAMD convention), referenced via `$ODOCKER_WORKSPACES`
- Naming: `tmux→otmux, ssh→ossh, docker→odocker`

## Configuration

```bash
# Set DockerWorkspaces path (persists in ~/config/user.env)
odocker workspace.set "/path/to/DockerWorkspaces"

# Show current workspace directory
odocker workspace.get

# Default (if not set): /var/dev/EAMD.ucp/.../DockerWorkspaces
```

## Quick Start

```bash
# List available workspaces
odocker workspace.list

# Build an image from a workspace
odocker build nakedUbuntu/24.04

# Run container with SSH for remote access (default ports)
odocker run.sshd naked_ubuntu_24_04

# Run a second container with offset 1000 (ports shift: 9022, 9080, ...)
odocker run.sshd naked_ubuntu_24_04 second_container 1000

# Or use SSH port directly — offset is derived automatically
odocker run.sshd naked_ubuntu_24_04 second_container 9022

# Reset: stop old container, clear SSH key, start fresh
odocker reset naked_ubuntu_24_04

# Then use ossh to install oosh into the container
ossh config.create mycontainer test@localhost:8022
ossh config.save.last
ossh push.key mycontainer
ossh install mycontainer test
ossh login mycontainer
```

## Port Mapping

Commands `run.sshd`, `up`, and `reset` accept an optional `<?portOrOffset:0>` parameter that controls host port mappings. It accepts **either** a port offset or an SSH port number:

- **Offset** (< 1024): added to all default host ports
- **SSH port** (>= 1024): offset is derived automatically as `sshPort - 8022`

### Default ports (offset 0)

| Host port | Container port | Service |
|-----------|---------------|---------|
| 8022 | 22 | SSH |
| 8080 | 8080 | HTTP |
| 8443 | 8443 | HTTPS |
| 5001 | 5001 | App |
| 5002 | 5002 | App |
| 5005 | 5005 | App |

### Examples

| Input | Type | Offset | SSH | HTTP | HTTPS |
|-------|------|--------|-----|------|-------|
| (none) | offset | 0 | 8022 | 8080 | 8443 |
| `1000` | offset | 1000 | 9022 | 9080 | 9443 |
| `9022` | SSH port | 1000 | 9022 | 9080 | 9443 |
| `11022` | SSH port | 3000 | 11022 | 11080 | 11443 |

### Running multiple containers

```bash
# First container — default ports
odocker up naked_ubuntu_24_04

# Second container — all ports shifted by 1000
odocker up naked_ubuntu_24_04 1000

# Or equivalently, specify the SSH port directly
odocker up naked_ubuntu_24_04 9022
```

## Methods

### Workspace Management

| Method | Parameters | Description |
|--------|-----------|-------------|
| `workspace.get` | | Show current Docker workspaces directory |
| `workspace.set <path>` | directory path | Set and persist Docker workspaces directory |
| `workspace.list` | | List all Dockerfile workspaces and their build status |

### Build

| Method | Parameters | Description |
|--------|-----------|-------------|
| `build <workspace>` | workspace path (e.g., `nakedUbuntu/24.04`) | Build image from DockerWorkspaces directory |
| `build.all` | | Build all workspaces that have a Dockerfile |
| `rebuild <workspace>` | workspace path | Remove old image and rebuild from Dockerfile |

### Run

| Method | Parameters | Description |
|--------|-----------|-------------|
| `run <image>` | image name, optional container name | Run container interactively |
| `run.sshd <image>` | image name, optional name, optional `<?portOrOffset:0>` | Run container detached with port mappings (see [Port Mapping](#port-mapping)) |
| `reset <image>` | image name, optional `<?portOrOffset:0>` | Stop container, remove it, clear host key, start fresh |

### Container Operations

| Method | Parameters | Description |
|--------|-----------|-------------|
| `exec <container>` | container name, optional shell (default: bash) | Shell into running container |
| `enter <container>` | container name, optional shell (default: bash) | Enter a running container (alias for exec) |
| `create <image>` | image name, optional container name | Create container without starting |
| `stop <container>` | container name | Stop a running container |
| `rm <container>` | container name | Remove a stopped container |
| `log <container>` | container name, optional line count (default: 50) | Show container logs |

### Image Operations

| Method | Parameters | Description |
|--------|-----------|-------------|
| `list` | | List all Docker images |
| `rmi <image>` | image name | Remove an image |
| `file.find <containerOrImage>` | container or image name | Find the Dockerfile that built a container or image |

### Docker Compose

| Method | Parameters | Description |
|--------|-----------|-------------|
| `compose` | optional service name | Show compose status or service details |
| `up <container>` | container/image/service, optional `<?portOrOffset:0>` | Start a container, run an image (with port mappings), or start a compose service |
| `down <container>` | container or service name | Stop a container or compose service |

### Status & Maintenance

| Method | Parameters | Description |
|--------|-----------|-------------|
| `ps` | | List running containers |
| `list.running` | | List running containers (alias for ps) |
| `container.list` | | List all containers (running and stopped) |
| `image.list` | | List all images |
| `status` | | Show Docker overview: images, containers, disk usage |
| `lifecycle` | | Check health of containers, images, and compose services |
| `disk` | | Show Docker disk usage details |
| `prune` | optional container name | Remove a stopped container and its image, or prune all if no arg |
| `prune.all` | | Full system prune including unused images and volumes |

## Workspace Naming Convention

Workspaces in DockerWorkspaces follow camelCase directory naming. The image tag is derived automatically:

| Workspace path | Image tag |
|---------------|-----------|
| `nakedUbuntu/24.04` | `naked_ubuntu_24_04` |
| `nakedAlma/9.sshd` | `naked_alma_9_sshd` |
| `nakedDebian/12` | `naked_debian_12` |
| `nakedAlpine/3.19` | `naked_alpine_3_19` |

## Typical Workflow: Platform Install Test

```bash
# 1. Build the image (once)
odocker build nakedUbuntu/24.04

# 2. Reset and start fresh container
odocker reset naked_ubuntu_24_04

# 3. Configure SSH access via ossh
ossh config.create ubuntu24 test@localhost:8022
ossh config.save.last
ossh push.key ubuntu24

# 4. Install oosh remotely
ossh install ubuntu24 test

# 5. Login and verify
ossh login ubuntu24

# 6. When done, clean up
odocker stop <container_name>
odocker rm <container_name>
```

## See Also

- [Supported Platforms](supported-platforms.md)
- [Branching Strategy](branching.md)
- [Config System](config.md)
