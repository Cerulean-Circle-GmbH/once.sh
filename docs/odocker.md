# odocker — Docker Wrapper for oosh

The `odocker` script wraps Docker commands following oosh conventions: positional parameters, tab completion, method signatures with descriptions.

## Overview

- Manages Docker images and containers via oosh methods
- Dockerfiles live in `DockerWorkspaces` (EAMD convention), referenced via `$ODOCKER_WORKSPACES`
- Naming: `tmux→otmux, ssh→ossh, docker→odocker`

### Prerequisites are installed on first use

`odocker` runs `docker` and lays its tables out with `column`. A minimal system
— a platform container, or a bare computer — has neither. So the first `odocker`
method that runs Docker installs what is missing through `oo cmd`, with the
package of this package manager (`private.odocker.prereq.package.get`; `oo cmd`
itself knows no per-platform names). Which Docker depends on the computer:

- **A container whose host's socket is mounted** (`/var/run/docker.sock`,
  `private.odocker.socket.get`): only the Docker **client** — it talks to the
  host's Docker.
- **A bare computer** (no socket): the Docker **engine**, installed on this
  computer and started (`private.odocker.engine.start`): systemd, else OpenRC
  (Alpine), else a SysV `service` — then up to five seconds for the socket,
  which OpenRC and SysV starts make only after they return
  (T-ODOCKER-ENGINE-START-WAIT); on macOS **colima**, the Docker VM
  (`colima start`).
- **A container without the host's socket** (`private.this.container.is`:
  `/.dockerenv` or `/run/.containerenv`): only the **client** — no engine can
  start in a container — and a warning that no docker socket is mounted and the
  container must be started with the `docker` option (as
  `odocker reset <image> <port> docker` does); the called method still runs
  (T-THIS-CONTAINER-IS, T-ODOCKER-PREREQ-CONTAINER-NO-SOCKET, -ENGINE-SUPPORTED).

| | apt (Ubuntu/Debian) | apk (Alpine) | dnf / yum (Alma/RHEL) | brew (macOS) |
|---|---|---|---|---|
| `docker` — client | `docker-ce-cli` | `docker-cli` | `docker-ce-cli` | `docker` |
| `docker` — engine | `docker.io` | `docker` | `docker-ce docker-ce-cli containerd.io` | `colima docker` |
| `column` | `bsdextrautils` | `util-linux-misc` | `util-linux` | part of macOS |

On apt (the client) and dnf/yum, Docker's own repository is added first
(`private.odocker.docker.repo.add`): Debian 12's `docker.io` is Docker 20.10,
too old for a current host's Docker ("client version 1.41 is too old",
T-ODOCKER-DOCKER-REPO-APT). It is added **once**: when its file is there
(`/etc/apt/sources.list.d/docker.list`, `/etc/yum.repos.d/docker-ce.repo`)
nothing is downloaded, written or updated. The key (apt) or the `.repo` file
(dnf/yum) is downloaded to a temporary file first; a failed or empty download
leaves nothing behind and answers rc 1 — an empty key used to break every later
`apt-get update`. Any other package manager has no Docker repository (rc 1).
The optional `<root>` (default `/`) lets the test work on a fixture. The engine packages create
the group `docker`; the socket access below adds the user to it (colima's socket
belongs to the user — no group). T-ODOCKER-PREREQ-PACKAGE-ENGINE, -ENGINE-START,
-PREREQ-MODE.

**A Mac that is itself a VM** (a tart VM) cannot run colima — it has no
virtualization (`kern.hv_support`), so nothing is installed there and odocker
says why (`private.odocker.engine.supported`, T-ODOCKER-ENGINE-SUPPORTED,
-PREREQ-NO-ENGINE). A missing prerequisite is a **warning**: a method that needs
no docker (the picker of `odocker up`) still runs, a docker call fails on its own
(T-ODOCKER-START-CONTINUES). **During a test run nothing is installed**:
`test.suite` exports `OOSH_NO_INSTALL=1`, and a started odocker then installs
nothing and changes no group or config (T-ODOCKER-START-NO-INSTALL). The
socket odocker looks for is `$ODOCKER_SOCKET`, else `/var/run/docker.sock`
(T-ODOCKER-SOCKET-ENV) — how a test gives a started odocker a socket of its own.

Only a **started** method that runs Docker does this: Tab completion and the
tests *source* `odocker`, and `usage`, `help` and the `workspace` methods need
no Docker (T-ODOCKER-PREREQ-START). In a platform container the host's Docker
socket is mounted (`private.odocker.docker.socket.opt` mounts the socket odocker
found, `private.odocker.socket.get`), so the CLI talks to the
host's daemon. The socket keeps the **host's** group number, so a non-root user
there got `permission denied`: `private.odocker.socket.access.ensure` creates a
group with that number when there is none (`docker`, or `dockerhost` when
`docker` has another number), adds the user (`id -un`) to it, and the started
call runs once more through `sg <group>`, so the new membership counts at once —
only while the membership is pending: in the group database, not yet in this
process (`private.user.group.member.pending`, T-USER-GROUP-MEMBER-PENDING). A
process that has the group already gets no `sg` and no "log out and back in":
docker fails there for another reason, and RESULT says so. The group
is found and made with kernel methods only — a started odocker has sourced
nothing but `this`: `private.this.group.name.get <gid>` (getent, else
`/etc/group`, `dscl` on macOS) and `private.this.group.create <name> <gid>`
(`groupadd -g`, `addgroup -g`, `dseditgroup -i`, through `$SUDO`;
T-THIS-GROUP-NAME-GET, -GROUP-CREATE-GID, T-ODOCKER-SOCKET-GROUP-ENSURE). The
socket itself is never changed — no odocker method runs `chgrp` or `sudo` on it
(T-ODOCKER-SOCKET-ACCESS, -SG, -NEVER-CHANGED). Alpine (BusyBox) has no
`sg`, and no package provides one: there odocker says the membership counts from
the next login (T-ODOCKER-NO-SG-NEXT-LOGIN). So that it rarely comes to that,
**the install already adds every user to the socket's group** when a socket is
mounted (`private.odocker.socket.group.ensure`, T-USER-INSTALL-SOCKET-GROUP) —
also when the image ships a docker program; the local group `docker` only
without a socket (T-USER-INSTALL-SOCKET-GROUP-OVER-DOCKER).

## Configuration

### `DockerWorkspaces` is an external prerequisite

**No Dockerfile ships with oosh.** `find . -name Dockerfile` in this repository
returns nothing. The workspaces tree lives in **EAMD.ucp**
(`donges/eamd.ucp.git`) — a different repository. **Every install creates the
root** — `DockerWorkspaces` beside the Once.sh components, shared with group
`dev` — and the shared `$CONFIG_PATH/odocker.env` that names it, chained from
`user.env` (`private.odocker.workspaces.install`; `oo update` as root heals an
older host; an existing value is kept). But the root starts **empty**: `odocker
build` / `odocker workspace.list` / `os platform.test` (when it has to build an
image, `os:212-220`) will say so.

That is expected, not a defect: seed the root from an existing tree, point oosh at a checkout, or start an empty root.

```bash
odocker workspace.seed /path/to/old/DockerWorkspaces           # create beside Once.sh, copy the old tree in, share, set
odocker workspace.set /path/to/EAMD.ucp/.../DockerWorkspaces   # existing tree
odocker workspace.init /path/to/new/DockerWorkspaces           # create, then set
```

With no path, `init`, `set` and `seed` use the default: `DockerWorkspaces` beside
the Once.sh components base (`oo mode.base.get`) — on a shared host
`/home/shared/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces`.
On a layout without a `main/` folder, where `oo mode.base.get` has no answer, the
default is still `DockerWorkspaces` beside the `Once.sh` folder that holds
`~/oosh` — one rule, `private.odocker.workspaces.default.get`, for `init`, `seed`
and the install (T-WS-DEFAULT-NO-MAIN). The install keeps an existing value,
else runs `odocker workspace.init` and shares the root with group dev; a failing
`workspace.init` is its answer. `/var/dev` is history.

`workspace.set` **refuses** a directory that is not there; `workspace.init`
creates it first, which is the difference between the two verbs. `workspace.seed`
creates it too and copies an existing root in (`private.this.folder.entries.copy`),
then shares it with group dev (`private.this.folder.share`) — only into a root that
holds no workspace yet, so a rerun never overwrites; the source is only read.

To check a machine is ready to build platform images:

```bash
./test.suite run platform.odocker.workspaces.invariant 1
```

It asserts the root exists, that every **must-pass** platform in
`defaults/platforms.env` has a Dockerfile, that the enumerator finds something,
and that `workspace.get` agrees. It is `TEST_CATEGORY=platform`, so it never runs
as part of `test.suite core` — a machine without the tree is not a broken oosh.

```bash
# Set DockerWorkspaces path. Canonicalised to absolute before being
# persisted in $CONFIG_PATH/odocker.env, which user.env sources on
# every shell startup. Relative paths (e.g. "./workspaces") are resolved
# against the current cwd, not stored verbatim. With no argument it
# resets to the default: DockerWorkspaces beside the Once.sh base (oo mode.base.get).
odocker workspace.set "/path/to/DockerWorkspaces"
odocker workspace.set                               # reset to default

# Show current workspace directory (and its persistence location)
odocker workspace.get

# Default (if not set): <parent of oo mode.base.get>/DockerWorkspaces, e.g.
# /home/shared/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces
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

| Input | Type | Offset | SSH | HTTP | HTTPS | 5001 |
|-------|------|--------|-----|------|-------|------|
| (none) | offset | 0 | 8022 | 8080 | 8443 | 5001 |
| `1000` | offset | 1000 | 9022 | 9080 | 9443 | 6001 |
| `9022` | SSH port | 1000 | 9022 | 9080 | 9443 | 6001 |
| `6022` | SSH port | -2000 | 6022 | 6080 | 6443 | 3001 |
| `11022` | SSH port | 3000 | 11022 | 11080 | 11443 | 8001 |

### Running multiple containers

```bash
# First container — default ports
odocker up naked_ubuntu_24_04

# Second container — all ports shifted by 1000
odocker up naked_ubuntu_24_04 1000

# Or equivalently, specify the SSH port directly
odocker up naked_ubuntu_24_04 9022
```

## Docker Socket

**Every container odocker starts has the socket.** `run`, `run.sshd`, `up`,
`reset` and `clone` always mount the socket odocker found
(`private.odocker.docker.socket.opt`: `$(private.odocker.socket.get)` →
`/var/run/docker.sock`), with or without the option. The optional last `docker`
parameter only decides whether the Docker client is installed in the new
container (`odocker install`). It does so for `run.sshd`, and for `up`, `reset`
and `clone` when they start the container through `run.sshd` (an image that
exposes port 22). `run` takes the parameter but installs nothing. So does `up`
or `clone` of an image without port 22. Run `odocker install <container>` there
yourself.

This allows the container to control the host's Docker daemon.

`odocker install <container>` has **one** implementation of the install and of
the socket's group. It takes one of two paths:

- **A container with oosh** (`~/oosh/odocker` there): it runs
  `odocker prereqs.install` in the container through the prelude
  (`ossh.remote.prelude.get`). The container installs and groups itself with the
  very methods a started odocker uses:
  - `private.odocker.prereqs.ensure`: the package table and Docker's
    repository.
  - `private.odocker.socket.group.ensure`: the socket's group, else `docker`,
    else `dockerhost`. An existing group is never renumbered.

  Every user with uid 1000 and up joins that group (T-ODOCKER-INSTALL-OOSH).
  `odocker prereqs.install <?user>` is a command of its own too: typed in a
  container, it installs what odocker needs there and joins the socket's group.
  It does nothing under `OOSH_NO_INSTALL` (T-ODOCKER-PREREQS-INSTALL).
- **A container without oosh** (a naked ubuntu, debian or almalinux image)
  takes the raw path, `private.odocker.container.prereqs.install`:
  - **Packages:** the names come from the same table, asked on the host with
    the container's package manager. apt runs non-interactively.
  - **Docker's repository:** `docker-ce-cli` (apt, dnf/yum) comes from it, so
    `private.odocker.container.repo.add` adds it first, from the host:
    - The data is the same as the local add, from `private.odocker.docker.repo.get`.
      It uses the container's `ID` and `VERSION_CODENAME` (its `/etc/os-release`,
      read with `private.os.release.get`) and the container's `dpkg`
      architecture, never the host's.
    - The download is the same too, `private.odocker.docker.repo.download <url> <file>`.
      It runs on the host, because a naked image may have no curl. The file
      (and the container's os-release) lie in one private directory from the
      kernel's `private.this.temp.dir.get`, removed on every exit path.
    - The key and the list (apt) or the `.repo` file (dnf/yum) are then written
      into the container with `docker exec -i … sh -c 'cat > <file>'`. apt
      first gets `ca-certificates`. Then the container's own `apt-get update`
      and the install run.
    - When the marker file is already in the container, nothing is downloaded
      or written.
    - A failed download writes nothing into the container and answers rc 1,
      naming why.
  - **Alpine:** `docker-cli` from apk, no repository.
  - **The socket's group:** the same group rule as above (T-ODOCKER-INSTALL-RAW,
    T-ODOCKER-DOCKER-REPO-GET).

### Usage

```bash
# Create container with Docker access
odocker up naked_ubuntu_24_04:latest 0 docker

# Standalone install (container must already have socket mounted)
odocker install festive_einstein

# Verify Docker works inside the container
docker exec festive_einstein docker ps
```

### Security Note

The Docker socket gives the container root-level access to the host's Docker daemon. Only use on trusted containers.

## Methods

### Workspace Management

| Method | Parameters | Description |
|--------|-----------|-------------|
| `workspace.get <?path>` | directory path (optional) | With no argument: show the current Docker workspaces directory, where it is persisted, **and whether it is usable** — rc 1 when it is not. With a path: report whether **that** path would be a usable root. A reporter only; it never sets, persists or creates |
| `workspace.init <?path>` | directory path (optional — defaults to `DockerWorkspaces` beside the Once.sh base) | **Create** the directory if it is absent, then hand over to `workspace.set`. Idempotent. The verb to use on a fresh host, where `workspace.set` would refuse because the directory is not there yet |
| `workspace.seed <from> <?path>` | an existing workspaces root; directory path (optional — the same default) | **Create** the root (via `workspace.init`), copy `<from>` in when the root holds no workspace yet, share it with group dev, set it. Refuses a `<from>` without Dockerfiles (rc 3). Idempotent; never overwrites; `<from>` is only read |
| `workspace.set <?path>` | directory path (optional — defaults to `DockerWorkspaces` beside the Once.sh base) | Set workspace dir — canonicalised to absolute and persisted in `$CONFIG_PATH/odocker.env` (registered via `config add`). Calling with no args resets to that default |
| `workspace.list` | | List all Dockerfile workspaces and their build status |

> **Which verb:** `init` creates and sets, `set` sets an existing directory and
> refuses a missing one, `get` only reports. `set`'s refusal is deliberate — a
> typo must not persist a path that is not there — which is why `init` exists.
>
> **Persistence:** `workspace.set` stores the setting in `$CONFIG_PATH/odocker.env`
> and registers it with `config add` so every new shell inherits the value.
> Legacy installs that had `ODOCKER_WORKSPACES=` in `user.env` are migrated on
> the next `workspace.set` call — no dead keys are left behind.

### Build

| Method | Parameters | Description |
|--------|-----------|-------------|
| `build <workspace>` | workspace path (e.g., `nakedUbuntu/24.04`) | Build image from DockerWorkspaces directory |
| `build.all` | | Build all workspaces that have a Dockerfile |
| `rebuild <workspace>` | workspace path | Remove old image and rebuild from Dockerfile |

### Run

| Method | Parameters | Description |
|--------|-----------|-------------|
| `run <image>` | image name, optional name, optional `docker` | Run container interactively |
| `run.sshd <image>` | image name, optional name, optional `<?portOrOffset:0>`, optional `docker` | Run container detached with port mappings (see [Port Mapping](#port-mapping)) |
| `reset <image>` | image name, optional `<?portOrOffset:0>`, optional `docker`, optional name | Stop container, remove it, clear host key, start fresh — named `<name>`, else Docker's random name |

### Container Operations

| Method | Parameters | Description |
|--------|-----------|-------------|
| `exec <container>` | container name, optional shell (default: bash) | Shell into running container (interactive `-it`) |
| `exec.command <container> <command...>` | container name, command to run | Run a non-interactive command inside a running container (no TTY); for scripts/state machines |
| `enter <container>` | container name, optional shell (default: bash) | Enter a running container (alias for exec) |
| `create <image>` | image name, optional container name | Create container without starting |

A container `run`, `run.sshd` or `create` starts **without a name** keeps
Docker's **random name** — but odocker learns it before the container starts:
an empty `docker create` lets Docker pick it, the entry is removed again, and
the container starts with that name — passed as the **host name** too, like
every given name. So the container knows its name from the first second, and
the oosh install inside names the computer by it
(`[oosh xenodochial_brown] bash-user@xenodochial_brown`), not by its ID. A container
started by plain `docker run` learns its name once odocker has installed the
docker program there (T-ODOCKER-CONTAINER-NAME-NEW, -UNNAMED-GETS-NAME,
-START-NAME-REFRESH).
| `clone <container>` | container name, optional `<?portOrOffset:0>`, optional `docker` | Clone a container with its filesystem state onto different ports |
| `install <container>` | container name | Install Docker CLI inside a running container (requires Docker socket mount): `odocker prereqs.install` there when it has oosh |
| `prereqs.install <?user>` | user (optional) | Install what odocker needs on this computer and join the docker socket's group: `<user>`, else every user as root, else this user; nothing under `OOSH_NO_INSTALL` |
| `stop <container>` | container name | Stop a running container |
| `container.remove <container>` | container name | Remove a stopped container (old name: `rm`, still works) |
| `log <container>` | container name, optional line count (default: 50) | Show container logs |

### Image Operations

| Method | Parameters | Description |
|--------|-----------|-------------|
| `list` | | List all Docker images |
| `image.remove <image>` | image name | Remove an image (old name: `rmi`, still works) |
| `file.find <containerOrImage>` | container or image name | Find the Dockerfile that built a container or image |

### Docker Compose

| Method | Parameters | Description |
|--------|-----------|-------------|
| `compose` | optional service name | Show compose status or service details |
| `up <container>` | container/image/service, optional `<?portOrOffset:0>`, optional `docker` | Start a container, run an image (with port mappings), or start a compose service |
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

## Container Names

A container started without `--name` gets Docker's random name as its name and host name (`private.odocker.container.name.new`). How oosh uses it as the computer's name: [config.md § The computer's name](config.md#the-computers-name).

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
odocker container.remove <container_name>      # old name: `odocker rm` still works
```

## Troubleshooting

### Docker Socket Permission Denied

If you see `permission denied while trying to connect to the Docker daemon socket`, your user is not yet in the group that owns the socket.

odocker never changes the socket itself (no `chgrp`, no systemd override — see the section on the socket above). What to do:

1. Run the odocker command again. `private.odocker.socket.access.ensure` finds or creates a group with the socket's group number, adds you to it, and runs the call through `sg` so the new membership counts at once.
2. Where there is no `sg` (Alpine), odocker says so: log out and back in. The membership counts from the next login.
3. To see what is going on:
```bash
stat -c '%G (%g) %A' /var/run/docker.sock   # the socket's group and mode
id -nG                                       # your groups in this shell
getent group <group>                         # who is a member of that group
```
If you are listed in `getent` but your group is missing from `id -nG`, the membership is new: log in again.

## See Also

- [Supported Platforms](supported-platforms.md)
- [Branching Strategy](branching.md)
- [Config System](config.md)
