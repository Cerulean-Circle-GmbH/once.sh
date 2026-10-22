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
`apt-get update`. A write that fails removes **only what this call wrote**: a
key at Docker's documented `/etc/apt/keyrings/docker.asc` that was there before
(a person's own setup) stays. An `apt-get update` that fails after a good write
(another repository, a mirror) keeps the key and the list and answers rc 1,
"added, but the package lists could not be refreshed: …" — the caller warns and
goes on, and the next call finds the list and does nothing
(T-ODOCKER-DOCKER-REPO-CLEANUP; the container add the same, T-ODOCKER-INSTALL-RAW).
Any other package manager has no Docker repository (rc 1).
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
socket is mounted (`private.odocker.docker.socket.opt` mounts the daemon's
`/var/run/docker.sock`, see Docker Socket below), so the CLI talks to the
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

**Never the group of root.** A socket owned by `root:root` — Docker Desktop's
socket seen from a container, a rootful podman or snap socket, a host without a
`docker` group — has group number 0 (`root`, `wheel` on macOS). Membership there
is far more than Docker access, so `private.odocker.socket.gid.check` refuses
number 0: `socket.group.ensure` answers rc 1 and the access of a started odocker,
`odocker prereqs.install`, the install (`user`) and the raw path of
`odocker install` add nobody. RESULT says why and what to do: the owner of the
socket on the host gives it a docker group of its own (T-ODOCKER-SOCKET-GID-CHECK,
T-ODOCKER-SOCKET-GROUP-ROOT, T-USER-INSTALL-SOCKET-GROUP-ROOT).

## Configuration

### `DockerWorkspaces` is an external prerequisite

**No Dockerfile ships with oosh.** `find . -name Dockerfile` in this repository
returns nothing. The workspaces tree lives in **EAMD.ucp**
(`donges/eamd.ucp.git`) — a different repository. **Every install creates the
root** — `DockerWorkspaces` beside the Once.sh components, shared with group
`dev` — and the shared `$CONFIG_PATH/odocker.env` that names it, chained from
`user.env` (`odocker.workspace.install`; `oo update` as root heals an
older host; an existing value is kept). But the root starts **empty**: `odocker
build` / `odocker workspace.list` / `os platform.test` (when it has to build an
image, `os:212-220`) will say so.

That is expected, not a defect: seed the root from an existing tree, point oosh at a checkout, or start an empty root.

```bash
odocker workspace.seed                                         # fetch the tree from WODA.test (ossh), else test.wo-da.de (wget)
odocker workspace.seed /path/to/old/DockerWorkspaces           # or from a local tree (also: a Host, a URL)
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
creates it too, fills it and shares it with group dev (`private.this.folder.share`).

### `odocker workspace.seed <?from> <?path>`

Fills the root (default: `DockerWorkspaces` beside the Once.sh base — `/home/shared/…` on Linux,
`/Users/shared/…` on macOS) with the whole Docker workspaces tree, as `ls` shows it on the server:
the image families, `WODA/`, `old/`, `plantuml/`, `structr/` and the READMEs. Where from:

| `<from>` | Source |
|---|---|
| — (none) | the Host **WODA.test** over ossh (`private.odocker.workspaces.source.host.get`, `ODOCKER_SEED_HOST`) — the root the Host names itself (`…host.path.get`: its own `odocker workspace.get`, else the old layout `/var/dev/EAMD.ucp/…/DockerWorkspaces` where that exists — WODA.test today); when that Host is missing or allows no key login: **`https://test.wo-da.de/EAMD.ucp/…/DockerWorkspaces`** with wget (`…source.url.get`, `ODOCKER_SEED_URL`) |
| a Host of `~/.ssh/config` | that Host, the same path, no fallback |
| `http(s)://…` | that URL with wget, no fallback |
| a folder | that local tree, only read; rc 2 when it is missing, rc 3 without a Dockerfile |

The URL is a public directory listing of the very folder on WODA.test (nginx `/EAMD.ucp/` → the ONCE
server on `:8080`, which serves `/var/dev/EAMD.ucp`). Over ossh the tree comes as one `tar` stream
(`private.odocker.workspaces.fetch.ssh`, a key login checked first with BatchMode — no password
prompt, no rsync or oosh needed there); over HTTPS with `wget -r -l inf -np -nH --cut-dirs=…
-R "index.html*"` (`…fetch.url`, wget installed through `oo cmd wget`), the listing pages left out.
Every route lands in a temp folder first — a local `<from>` is copied there, it is only read — so a
failed fetch is rc 1 and creates no root. **`.backup.env` files are taken out there and never
copied or compared**: they are the server's backup settings (`BACKUP_TARGET=root@WODA.prod:…`), and
oosh's `backup` run in the local tree would read them (user decision 2026-10-19). A local
`.backup.env` in the root stays as it is.

The two routes do not give the same tree (lab 2026-10-19): over ossh it is the exact copy — 142
files and the 10 symlinks (`minimalLinux/eamd -> /var/dev/…` and the like, dangling on any other
host), the dotfiles (`.env`) included — except `.backup.env`. Over HTTPS the web server follows the
symlinks and hands out copies of their targets, does not list dotfiles, and leaves out a link
whose target it does not serve (`minimalLinux/debug.self.sh`): 148 files, no symlinks. Symlinks
are kept as symlinks and compared by their target (`private.odocker.workspaces.entry.same`;
`private.this.folder.entries.copy` copies a dangling one since 2026-10-19).

Then `private.odocker.workspaces.merge` fills the root unit by unit — a unit is a top-level file
(`README.txt`) or a second-level entry (`nakedUbuntu/24.04`, `WODA/2.0.0`) with all below it:

| Here | Then |
|---|---|
| missing | copied in — **added** |
| every file of the source unit the same | nothing — **unchanged** |
| different | `Overwrite <unit> (differs from <source>)? [y/N]` on the terminal; `y` copies the source files over the local ones (files only here stay) — **overwritten**, else **kept**; without a terminal always kept |
| only here (e.g. `nakedUbuntu/26.04.root`) | never touched |

RESULT: `seeded <root> from <source>: N added, M overwritten, K kept, U unchanged — kept (differ):
…` (T-WS-SEED, T-WS-SEED-SOURCES, T-WS-SEED-MERGE). Until 2026-10-19 `<from>` had to be a local folder
and a root that held any workspace was never written to.

### `odocker workspace.push <?toHost> <?image> <?path>`

The twin of `seed`: brings the workspaces of **this** computer to the source every `seed` reads —
by default WODA.test (`…source.host.get`), into the root the Host names itself (`…host.path.get`, see below). Until
2026-10-21 oosh could only fetch, so a changed Dockerfile (the naked images with
`--no-install-recommends`, no Python) never reached WODA.test.

```bash
odocker workspace.push                 # this computer's DockerWorkspaces → WODA.test
odocker workspace.push WODA.test nakedUbuntu/24.04 # only this image (also: naked_ubuntu_24_04)
odocker workspace.push WODA.test nakedUbuntu        # the whole family, all its versions
odocker workspace.push WODA.test all /path/to/DockerWorkspaces
```

`<image>` (default `all`) limits the push to one image: its folder (`nakedUbuntu/24.04`), its image
name (`naked_ubuntu_24_04`, the tag rule odocker builds with) or a whole family (`nakedUbuntu`); Tab
offers all three. Only those units are compared and asked about. An image that is not in the
root, one outside it (`../…`) or one of `old/` is refused with rc 2 before anything is fetched
(T-WS-PUSH-IMAGE); RESULT then says `… for nakedUbuntu/24.04: …`.

**Where on the Host** (push and seed alike, `private.odocker.workspaces.host.path.get`, user
2026-10-21): the Host names its root itself — one ssh call runs its own `~/oosh/odocker
workspace.get` (`/home/shared/…` on Linux, `/Users/shared/…` on macOS, or what `workspace.set` made
it). Only when that gives no folder there — no oosh, an old one, or a broken odocker — the old
layout `/var/dev/EAMD.ucp/…/DockerWorkspaces` is taken, and only where it exists (WODA.test today,
`…legacy.path.get`). Otherwise rc 1: "<host> names no Docker workspaces root", nothing is copied.
The former override `ODOCKER_SEED_PATH` is gone (T-WS-HOST-PATH).

The Host tree is fetched first, as `seed` fetches it (only read, into a temp folder), and every
unit here is compared with it — the same units as `seed`:

| On the Host | Then |
|---|---|
| missing | sent — **added** |
| every file of the unit here the same | nothing — **unchanged**, not sent |
| different | the `diff` of each differing file, then `Overwrite WODA.test:<unit> (differs from the one here)? [y/N]`; `y` sends it — **overwritten**, else **kept**; without a terminal always kept |
| only on the Host | never touched — push removes nothing |

**Never sent:** `.claude/`, `.backup.env`, `*.bak` and the whole `old/` family
(`private.odocker.workspaces.push.filter`). What goes, goes as one `tar` over one ssh call; on the
Host it is unpacked without the owners of this computer and given the owner of the Host root
(`donges:dev` on WODA.test), the units and their family folders only — as root owner and group; a login that is not root cannot give files away, so it sets the group only (a fresh root is `root:dev`) and a family folder only when it is its own. A Host whose root is still empty (freshly installed) gets every image (T-WS-PUSH-EMPTY-HOST). It does **not** commit: on
WODA.test the files land in the EAMD.ucp checkout (`test/WODA245`) as changes, and `seed` reads them
from there at once. rc 1 when the Host is no Host here, allows no key login or the copy fails —
nothing is sent; rc 3 when `<path>` holds no Dockerfile workspace. RESULT: `pushed to
<host>:<path>: N added, M overwritten, K kept, U unchanged`, or `nothing to push to …`
(T-WS-PUSH-ONLY-DIFFERENCES, T-WS-PUSH-ASKS, T-WS-PUSH-SKIPS, T-WS-PUSH-NO-HOST).

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

# A container with ssh, ready to use, in one command: started, the Host
# <name> in ~/.ssh/config (test@localhost:8022+offset), your key pushed
odocker container.ssh.start naked_ubuntu_24_04 boxone 10
ossh login boxone                      # no password

# … and with oosh installed for test, in one command
odocker container.oosh.install naked_debian_12 boxtwo 20
ossh login boxtwo                      # lands in [oosh boxtwo] test@<id>

# The same steps by hand
ossh config.create mycontainer test@localhost:8022
ossh config.save.last
ossh key.push mycontainer
ossh install mycontainer test
ossh login mycontainer
```

### A container with ssh, ready to use

`odocker container.ssh.start <image> <?name> <?portOrOffset:0> <?user> <?password>` and
`odocker container.oosh.install` (same parameters) do the steps above in one go:

1. the image must start sshd (it exposes `22/tcp`); Tab after `<image>` offers only such images;
2. the ssh port is `8022+offset`, and five more ports move with it (8080, 8443, 5001, 5002, 5005) — offsets
   10 apart never overlap; a port **another** container uses is refused (odocker reset would
   remove it); the same `<name>` again replaces that container and its Host block;
3. the container starts (`run.sshd`), the old Host `<name>` and the old host key of the port go, the
   new Host is created and saved (`ossh config.create` + `config.save.last`);
4. the first login uses `<password>` once (sshpass, retried until sshd answers), your key is pushed
   (`ossh key.push`) — from then on no password;
5. `container.oosh.install` adds: sudo without a password for `<user>` (root needs none), `ossh install
   <name> <user>`, sshd re-exec after an in-place openssh upgrade, a fresh connection for the new groups.

Without `<name>` the container gets Docker's random name, and the Host the same one. Without `<user>`
the command asks the image: `test` when it has that user, else `root`; the password defaults to the user
name — `test`/`test` for the naked images, `root`/`root` for `naked_ubuntu_26_04_root`. A given `<user>`
the image does not have is refused before anything starts, and a first login that fails removes the
container and the new Host again. `os platform.test` uses the same building blocks
(`private.odocker.container.*`).

**Removing.** `odocker container.remove <name>` (after `odocker stop <name>`) and `odocker prune <name>` also remove
the Host `<name>` and the host key of its port — but only when that Host points at this container
(`HostName localhost`, `Port` = its ssh port). A Host of the same name that points elsewhere, e.g. a server, is
kept, and so is the Host of a container that could not be removed.

A container that went another way (a plain `docker rm`, the platform test's cleanup, a docker restart) leaves its
Host behind. `odocker container.ssh.prune` removes those: every Host pointing at `localhost:<port>` (not 22) where no
container publishes `<port>` and none has its name, with its host key. Every other Host stays, and when docker does
not answer nothing is removed.

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
`reset` and `clone` always mount the daemon's socket
(`private.odocker.docker.socket.opt`: `-v /var/run/docker.sock:/var/run/docker.sock`),
with or without the option. The source of that mount is **always the constant
`/var/run/docker.sock`**, never `private.odocker.socket.get`: the Docker daemon
resolves it on its own host (or in colima's VM on a Mac), where the socket is
`/var/run/docker.sock` whatever path this client reaches it by (`ODOCKER_SOCKET`,
`~/.colima/…/docker.sock`, a container where the host's socket is mounted
elsewhere). With the client's path Docker creates an empty directory on the host
and mounts that — the new container has no socket (T-ODOCKER-SOCKET-NEVER-CHANGED). The optional last `docker`
parameter only decides whether the Docker client is installed in the new
container (`odocker install`). It does so for `run.sshd`, and for `up`, `reset`
and `clone` when they start the container through `run.sshd` (an image that
exposes port 22). `run` takes the parameter but installs nothing. So does `up`
or `clone` of an image without port 22. Run `odocker install <container>` there
yourself.

This allows the container to control the host's Docker daemon.

`odocker install <container>` has **one** implementation of the install and of
the socket's group. It takes one of two paths:

- **A container with oosh** (`~/oosh/odocker` there, and it defines
  `odocker.prereqs.install()` — asked with `grep` through `docker exec`; an
  older oosh without it takes the raw path, T-ODOCKER-INSTALL-OOSH-OLD): it runs
  `odocker prereqs.install` in the container through the prelude
  (`ossh.remote.prelude.get`). The container installs and groups itself with the
  very methods a started odocker uses:
  - `private.odocker.prereqs.ensure`: the package table and Docker's
    repository.
  - `private.odocker.socket.group.ensure`: the socket's group, else `docker`,
    else `dockerhost`. An existing group is never renumbered.

  Every user with uid 1000 and up joins that group (T-ODOCKER-INSTALL-OOSH;
  the accounts come from `private.odocker.passwd.users.get`).
  `odocker prereqs.install <?user>` is a command of its own too: typed in a
  container, it installs what odocker needs there and joins the socket's group.
  It does nothing under `OOSH_NO_INSTALL` (T-ODOCKER-PREREQS-INSTALL). **Every
  account only in a container:** on a bare computer the socket's group is the
  local `docker` group, which is as good as root, so as root without `<user>`
  only the person who ran `sudo` (`$SUDO_USER`, not root) joins it — else nobody,
  and RESULT says to name the user (T-ODOCKER-PREREQS-INSTALL-WHO).
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
    - The download is the same too, `private.odocker.docker.repo.download <url> <file>`, which calls `private.this.url.download` (the one checked download).
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
    T-ODOCKER-DOCKER-REPO-GET). After a create the group of the socket's number
    is read back from the container: a group of that name with another number
    (an image committed on another host) is a loud rc 1 naming group and number,
    and nobody joins. A member is left alone; a join that fails is reported
    with rc 1 (T-ODOCKER-INSTALL-RAW-VERIFIED).

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
| `workspace.seed <?from> <?path>` | a folder, an ossh Host or a URL (optional — default WODA.test, else test.wo-da.de); directory path (optional — the same default) | **Create** the root (via `workspace.init`), add what is missing from the source, ask before overwriting a differing unit, share it with group dev, set it. Refuses a local `<from>` that is missing (rc 2) or without Dockerfiles (rc 3); rc 1 when nothing could be fetched. See [workspace.seed](#odocker-workspaceseed-from-path) |
| `workspace.push <?toHost> <?image> <?path>` | an ossh Host (optional — default WODA.test); an image folder, image name or family (optional — default all); the local root (optional — default `$ODOCKER_WORKSPACES`) | **Push** this computer's workspaces to the source `seed` reads: a missing unit added, a differing one only after a yes (its diff shown), nothing removed; `.claude`, `.backup.env`, `*.bak`, `old/` never sent. See [workspace.push](#odocker-workspacepush-tohost-image-path) |
| `workspace.set <?path>` | directory path (optional — defaults to `DockerWorkspaces` beside the Once.sh base) | Set workspace dir — canonicalised to absolute and persisted in `$CONFIG_PATH/odocker.env` (registered via `config add`). Calling with no args resets to that default |
| `workspace.list` | | List all Dockerfile workspaces and their build status |

> **Which verb:** `init` creates and sets, `set` sets an existing directory and
> refuses a missing one, `get` only reports. `set`'s refusal is deliberate — a
> typo must not persist a path that is not there — which is why `init` exists.
>
> **Persistence:** `workspace.set` stores the setting in `$CONFIG_PATH/odocker.env`
> and registers it with `config add` so every new shell inherits the value.
> Legacy installs that had `ODOCKER_WORKSPACES=` in `user.env` are migrated on
> the next `workspace.set` call — no dead keys are left behind. Its rc is the
> save's: when `odocker.env` does not hold the value afterwards (read back — the
> save itself answers 0 when it cannot write the file) or the chain line in
> `user.env` cannot be added, `workspace.set` answers rc 1, and so do
> `workspace.init` and the install's `odocker.workspace.install`
> (T-WS-SET-SAVE-FAILS).

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
| `container.ip.get <container>` | container name | Echo the IP address of a running container on its first network (a container from `odocker run` publishes no port — reach its sshd here); rc 1 when it has none (T-ODOCKER-CONTAINER-IP-GET) |
| `image.command <image> <command...>` | image, command to run | Run one command in a throwaway container of `<image>` (removed afterwards), stdin passed in, rc the command's; `os platform.parse.check` streams a tree in this way (T-ODOCKER-IMAGE-COMMAND) |
| `enter <container>` | container name, optional shell (default: bash) | Enter a running container (alias for exec) |
| `create <image>` | image name, optional container name | Create container without starting |

A container `run`, `run.sshd` or `create` starts **without a name** keeps
Docker's **random name** — but odocker learns it before the container starts:
an empty `docker create` lets Docker pick it, the entry is removed again, and
the container starts with that name. Only `--name` is given: the **host name stays
the container ID**, and the oosh install inside reads the name through the mounted
socket. The prompt pairs them as `odocker status` does — the name in `[]`, the ID
after `@`: `[oosh xenodochial_brown] bash-user@bbefafb7d5e3` (2026-10-19,
T-ODOCKER-RUN-NO-HOSTNAME, T-USER-PROMPT-HOST-NAME; until then `--hostname` gave
the name twice). A container started by plain `docker run` learns its name once
odocker has installed the docker program there; without a socket it shows its ID
in both places (T-ODOCKER-CONTAINER-NAME-NEW, -UNNAMED-GETS-NAME,
-START-NAME-REFRESH).
| `clone <container>` | container name, optional `<?portOrOffset:0>`, optional `docker` | Clone a container with its filesystem state onto different ports |
| `install <container>` | container name | Install Docker CLI inside a running container (requires Docker socket mount): `odocker prereqs.install` there when it has oosh |
| `prereqs.install <?user>` | user (optional) | Install what odocker needs on this computer and join the docker socket's group: `<user>`, else as root every user in a container and the one who ran `sudo` on a computer, else this user; nothing under `OOSH_NO_INSTALL` |
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

A container started without `--name` gets Docker's random name as its name (`private.odocker.container.name.new`); its host name stays the ID. How oosh uses it as the computer's name: [config.md § The computer's name](config.md#the-computers-name).

## Typical Workflow: Platform Install Test

```bash
# 1. Build the image (once)
odocker build nakedUbuntu/24.04

# 2. Reset and start fresh container
odocker reset naked_ubuntu_24_04

# 3. Configure SSH access via ossh
ossh config.create ubuntu24 test@localhost:8022
ossh config.save.last
ossh key.push ubuntu24

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

4. If `stat` shows the group `root` (`wheel`, number 0), odocker adds nobody to it and says so: on the host, give the socket a docker group of its own (`groupadd docker; chgrp docker /var/run/docker.sock`, or the daemon's `group` setting) — never put users in the group of root.

### macOS over ssh — "keychain cannot be accessed"

Docker Desktop's `~/.docker/config.json` has `"credsStore": "desktop"`: every registry access asks the macOS
login keychain, even for a public image. In an ssh session (`ossh login macstudio`) the keychain is locked and
macOS allows no password dialog, so a build that needs its base image failed:
`error getting credentials … keychain cannot be accessed because the current session does not allow user interaction`
(the Mac Studio, `odocker build nakedUbuntu/26.04.root`, 2026-10-22). Linux has no keychain.

Every odocker call that reaches the registry goes through `private.odocker.docker.registry`: `build` (and
`build.all`, `rebuild`, `os platform.test`), the compose `up`, and the pull of a missing image that `run`,
`run.sshd`, `image.command` and `container.create` do first (`private.odocker.image.local.ensure` — `odocker run`
is interactive, its own output cannot be read). On macOS, and only after that error:

1. **Without the keychain, no password:** the same call again with a docker config of its own
   (`private.odocker.docker.config.keyless`): the real `config.json` with `"credsStore": ""` and an empty
   `https://index.docker.io/v1/` entry in `auths`, links to `contexts`, `cli-plugins` and `buildx`. Public images
   then pull anonymously — Docker Hub and ghcr.io alike (proven on the Mac; an empty `credsStore` alone still asked
   the keychain). The real `~/.docker/config.json` is never changed.
2. **Only a private image** still lacking credentials: on a terminal odocker runs
   `security unlock-keychain ~/Library/Keychains/login.keychain-db` — you type your Mac password — and the call once
   more. Without a terminal it stops with rc 1 and names that command.

Off macOS, after success or after any other error the call runs once, as before; Docker keeps its terminal there
(T-ODOCKER-KEYCHAIN-AVOID, -UNLOCK, -ONLY-MAC, T-ODOCKER-IMAGE-LOCAL-ENSURE).

## See Also

- [Supported Platforms](supported-platforms.md)
- [Branching Strategy](branching.md)
- [Config System](config.md)

<!-- BEGIN generated: oosh method matrix (oosh-architect) -->
## `odocker` — method matrix (origin/dev ↔ origin/test/mcdonges.latest)

Generated by oosh-architect from the branch sources (2026-10-20). Indexes: [methods-index.md](methods-index.md) · [object-verb-index.md](object-verb-index.md) · [parameter.md](parameter.md).

**Decomposition** — every method is `odocker.<object>.<verb>[.<more.words>]`. One method = one row.
`object`/`verb` are left **blank when unchanged from the row above** (objects are never repeated).
The **script name is the root object** — `odocker` acts on `container`, `image`, `volume` … so a method is
an object CHAIN ending in a verb: **`object.object.verb`**. The object column shows the full chain.
The **verb is identified semantically** (a real action word), not by position; OOSH's normalized form puts
the **verb last** (e.g. `authorized.keys.update`), so segments before it are the object, after it `more.words`.
An **adverbial modifier** directly before the verb belongs to the verb, not the object —
`otmux.window.aggressive.resize` is object `otmux.window` + verb `aggressive.resize`.
An **empty verb** means the name carries **no action at all** — the chain never reaches a verb
(an `object.verb` naming gap, listed in [verb-audit.md](verb-audit.md)).

| object | verb | more.words | all parameter | origin/test/mcdonges.latest | origin/dev |
|---|---|---|---|---|---|
| **=== public ===** | | | | | |
| `odocker` | `build` |  | `# <workspace> # build image from DockerWorkspaces directory` | `odocker.build` | `odocker.build` |
|  |  | `all` | `# # build all workspaces that have a Dockerfile` | `odocker.build.all` ✅ | `odocker.build.all` ✅ |
|  | `clone` |  | `# <container> <?portOrOffset:0> <?docker> # clone a container with its filesystem state onto different ports` | `odocker.clone` ✅ | `odocker.clone` ✅ |
|  | `compose` |  | `# <?service> # show compose status or service details` | `odocker.compose` ✅ | `odocker.compose` ✅ |
|  | `create` |  | `# <image> <?name> # create container without starting` | `odocker.create` | `odocker.create` |
|  | `down` |  | `# <container> # stop a container or compose service` | `odocker.down` ✅ | `odocker.down` ✅ |
|  | `enter` |  | `# <container> <?shell:bash> # enter a running container` | `odocker.enter` ✅ | `odocker.enter` ✅ |
|  | `exec` |  | `# <container> <?shell> # exec into running container` | `odocker.exec` ✅ | `odocker.exec` ✅ |
|  |  | `command` | `# <container> <command...> # run a non-interactive command inside a running container (no TTY)` |  | `odocker.exec.command` |
|  | `install` |  | `# <container> # install Docker CLI inside a running container` | `odocker.install` | `odocker.install` |
|  | `list` |  | `# # list images` | `odocker.list` ✅ | `odocker.list` ✅ |
|  |  | `running` | `# # list running containers` | `odocker.list.running` ✅ | `odocker.list.running` ✅ |
|  | `log` |  | `# <container> <?lines:50> # show container logs` | `odocker.log` ✅ | `odocker.log` ✅ |
|  | `prune` |  | `# <container> # remove a stopped container and its image` | `odocker.prune` ✅ | `odocker.prune` ✅ |
|  |  | `all` | `# # full system prune including unused images and volumes` | `odocker.prune.all` ✅ | `odocker.prune.all` ✅ |
|  | `rebuild` |  | `# <workspace> # remove old image and rebuild from Dockerfile` | `odocker.rebuild` | `odocker.rebuild` |
|  | `reset` |  | `# <image> <?portOrOffset:0> <?docker> <?name> # stop container, remove it, clear host key, start fresh (offset or SSH port) — named <name>, else a random Docker name; as name and host name #` | `odocker.reset` | `odocker.reset` |
|  | `rm` |  | `# <container> # [deprecated: use odocker.container.remove] remove a stopped container` | `odocker.rm` | `odocker.rm` |
|  | `rmi` |  | `# <image> # [deprecated: use odocker.image.remove] remove an image` | `odocker.rmi` | `odocker.rmi` |
|  | `run` |  | `# <image> <?name> <?docker> # run container from image` | `odocker.run` | `odocker.run` |
|  |  | `sshd` | `# <image> <?name> <?portOrOffset:0> <?docker> # run container with port mappings (offset or SSH port, e.g. 1000 or 9022)` | `odocker.run.sshd` | `odocker.run.sshd` |
|  | `stop` |  | `# <container> # stop a running container` | `odocker.stop` ✅ | `odocker.stop` ✅ |
|  | `up` |  | `# <container> <?portOrOffset:0> <?docker> # start a container, run an image, or start a compose service (offset or SSH port)` | `odocker.up` ✅ | `odocker.up` ✅ |
| `odocker.container` | `list` |  | `# # list all containers` | `odocker.container.list` ✅ | `odocker.container.list` ✅ |
|  | `remove` |  | `# <container> # remove a stopped container` |  | `odocker.container.remove` |
| `odocker.container.ip` | `get` |  | `# <container> # echo the IP address of the running <container> on its first network; rc 1 + RESULT without <container> or when docker gives none #` |  | `odocker.container.ip.get` |
| `odocker.disk` |  |  | `# # show Docker disk usage details` | `odocker.disk` ✅ | `odocker.disk` ✅ |
| `odocker.file` | `find` |  | `# <?containerOrImage> # find Dockerfile that built a container or image; with no arg, lists all containers + images as a discovery aid` | `odocker.file.find` | `odocker.file.find` |
| `odocker.image` | `list` |  | `# # list all images` | `odocker.image.list` ✅ | `odocker.image.list` ✅ |
|  | `remove` |  | `# <image> # remove an image` |  | `odocker.image.remove` |
| `odocker.image.command` |  |  | `# <image> <command...> # run one command in a throwaway container of <image> (removed afterwards), its stdin passed in; rc is that of the command` |  | `odocker.image.command` |
| `odocker.lifecycle` |  |  | `# # check health of containers, images, and compose services` | `odocker.lifecycle` ✅ | `odocker.lifecycle` ✅ |
| `odocker.prereqs` | `install` |  | `# <?user> # install what odocker needs here and join the group of the docker socket: <user>, else as root every user (uid 1000 and up) in a container and on a computer the one who ran sudo, else this user; nothing under OOSH_NO_INSTALL; idempotent #` |  | `odocker.prereqs.install` |
| `odocker.ps` |  |  | `# # list running containers` | `odocker.ps` ✅ | `odocker.ps` ✅ |
| `odocker.status` |  |  | `# # show Docker overview: images, containers, disk usage` | `odocker.status` ✅ | `odocker.status` ✅ |
| `odocker.workspace` | `get` |  | `# <?path:$ODOCKER_WORKSPACES> # report the Docker workspaces root and whether it is usable; with a path, report whether that one would be` | `odocker.workspace.get` | `odocker.workspace.get` |
|  | `init` |  | `# <?path:$(oo mode.base.get)/../DockerWorkspaces> # create the Docker workspaces directory if it is absent, share it with group dev, then set it for every user of this host (shared $CONFIG_PATH/odocker.env); idempotent #` |  | `odocker.workspace.init` |
|  | `list` |  | `# # list all Dockerfile workspaces and their build status` | `odocker.workspace.list` ✅ | `odocker.workspace.list` ✅ |
|  | `seed` |  | `# <?from> <?path:$(oo mode.base.get)/../DockerWorkspaces> # fill the Docker workspaces root from <from> — a folder, an ossh Host or a URL — by default from WODA.test over ossh, else from test.wo-da.de with wget: what is missing is added, a differing image folder is overwritten only after a yes, then it is shared with group dev and set #` |  | `odocker.workspace.seed` |
|  | `set` |  | `# <?path:$(oo mode.base.get)/../DockerWorkspaces> # set Docker workspaces directory for every user of this host (shared $CONFIG_PATH/odocker.env, persisted there)` | `odocker.workspace.set` | `odocker.workspace.set` |
| **=== private ===** | | | | | |
| `odocker` | `compose` | `file.in` |  | `private.odocker.compose.file.in` ✅ | `private.odocker.compose.file.in` ✅ |
|  |  | `services` |  | `private.odocker.compose.services` ✅ | `private.odocker.compose.services` ✅ |
|  | `ensure` | `socket.access` |  | `private.odocker.ensure.socket.access` |  |
|  | `resolve` | `image` |  | `private.odocker.resolve.image` ✅ | `private.odocker.resolve.image` ✅ |
| `odocker.compose.file` | `find` |  |  | `private.odocker.compose.file.find` ✅ | `private.odocker.compose.file.find` ✅ |
| `odocker.container` | `list` | `all` |  | `private.odocker.container.list.all` ✅ | `private.odocker.container.list.all` ✅ |
|  |  | `findable` |  |  | `private.odocker.container.list.findable` |
|  |  | `running` |  | `private.odocker.container.list.running` ✅ | `private.odocker.container.list.running` ✅ |
| `odocker.container.name` |  |  |  | `private.odocker.container.name` ✅ | `private.odocker.container.name` ✅ |
|  | `new` |  | `# <image> # echo Docker's own random name for a new container of <image>, known before it starts: an empty 'docker create' names it, the entry is removed again; nothing when create fails #` |  | `private.odocker.container.name.new` |
| `odocker.container.ports` |  |  |  | `private.odocker.container.ports` ✅ | `private.odocker.container.ports` ✅ |
| `odocker.container.prereqs` | `install` |  | `# <container> # install the Docker client and column in a running <container> that has no oosh, with the package names of private.odocker.prereq.package.get, and add its users to the group of the docker socket without renumbering a group; rc 1 naming what failed #` |  | `private.odocker.container.prereqs.install` |
| `odocker.container.repo` | `add` |  | `# <container> <pm> # add the package repository of Docker to a running <container> without oosh: the data of private.odocker.docker.repo.get from the os-release and architecture of the container, downloaded on this host, written into the container; nothing when its marker is there; rc 1 naming why #` |  | `private.odocker.container.repo.add` |
| `odocker.docker.repo` | `add` |  | `# <?root:/> # add the own package repository of Docker for this package manager — apt (Debian, Ubuntu) and dnf/yum — where docker-ce-cli and docker-ce come from; nothing when it is there; <root> lets a test use a fixture; rc 1 naming what is missing #` |  | `private.odocker.docker.repo.add` |
|  | `download` |  | `# <url> <file> # download <url> to <file> of this host: rc 0 and RESULT the file; rc 1 naming why when curl fails or the download is empty, and no file left #` |  | `private.odocker.docker.repo.download` |
|  | `get` |  | `# <field> <pm> <?osRelease:/etc/os-release> <?arch> # echo one field of the package repository of Docker for package manager <pm>: marker (the file that marks it present), url (what is downloaded), file (where the download goes), line (apt: the source line from ID, VERSION_CODENAME of <osRelease> and <arch>); rc 1 and nothing when <pm> has none or apt lacks a value #` |  | `private.odocker.docker.repo.get` |
| `odocker.docker.socket.opt` |  |  |  | `private.odocker.docker.socket.opt` | `private.odocker.docker.socket.opt` |
| `odocker.engine.supported` |  |  | `#  # rc 0 when this computer can run the Docker engine: Linux outside a container, a Mac only with virtualization (kern.hv_support 1); rc 1 naming why not #` |  | `private.odocker.engine.supported` |
| `odocker.env.chained` |  |  | `#  # rc 0 when $CONFIG_PATH/user.env chains odocker.env with the exact line config add writes (the dot form, or the legacy source form); a comment or another file that merely mentions odocker.env does not count #` |  | `private.odocker.env.chained` |
| `odocker.image` | `list` |  |  | `private.odocker.image.list` ✅ | `private.odocker.image.list` ✅ |
|  |  | `findable` |  |  | `private.odocker.image.list.findable` |
|  | `resolve` | `from.workspace` |  | `private.odocker.image.resolve.from.workspace` ✅ | `private.odocker.image.resolve.from.workspace` ✅ |
| `odocker.passwd.users` | `get` |  | `# <?passwd:/etc/passwd> # echo the accounts of people in <passwd>, one per line: user number 1000 up to 65533 (65534 is nobody) #` |  | `private.odocker.passwd.users.get` |
| `odocker.port.offset` |  |  |  | `private.odocker.port.offset` | `private.odocker.port.offset` |
| `odocker.prereq.package` | `get` |  | `# <cmd> <?mode:client> # echo the package that provides <cmd> (docker or column) for the package manager in OOSH_PM — for docker the client, or with mode engine the Docker engine of a bare computer (colima on macOS); the command name itself when none is known #` |  | `private.odocker.prereq.package.get` |
| `odocker.prereqs` | `ensure` |  | `#  # install what odocker needs and the system lacks — docker and column — through oo cmd with the package of this package manager; rc 1 naming what is still missing #` |  | `private.odocker.prereqs.ensure` |
| `odocker.socket` | `get` |  | `#  # echo the docker socket of this host: $ODOCKER_SOCKET, else /var/run/docker.sock — mounted from the host in a container, the engine's own on a computer that runs Docker #` |  | `private.odocker.socket.get` |
| `odocker.socket.access` | `ensure` |  | `# <?socket:/var/run/docker.sock> # make the mounted docker socket usable for this user: a group with its GID, created when missing, with this user in it; rc 0, and RESULT sg:<group> when the membership is new to this shell; rc 1 when it cannot #` |  | `private.odocker.socket.access.ensure` |
| `odocker.socket.gid` | `check` |  | `# <gid> # rc 0 when users may join the group with number <gid> that owns the docker socket; rc 1 for 0, the group of root (root, wheel), with RESULT saying that no user is added to it and that the owner of the socket on the host must give it a docker group #` |  | `private.odocker.socket.gid.check` |
| `odocker.socket.group` | `ensure` |  | `# <?socket:$(private.odocker.socket.get)> # find the group that owns the docker socket's number, or create one for it — docker, or dockerhost when docker has another number; RESULT is its name, rc 1 when it cannot or when it is the group of root (number 0) #` |  | `private.odocker.socket.group.ensure` |
| `odocker.workspace` | `list` |  |  | `private.odocker.workspace.list` ✅ | `private.odocker.workspace.list` ✅ |
| `odocker.workspaces` | `fetch` | `ssh` | `# <host> <stage> # copy the Docker workspaces folder of <host> into the empty folder <stage> with tar over one ssh call — rc 1 + RESULT when <host> is no Host here, allows no key login or the copy fails #` |  | `private.odocker.workspaces.fetch.ssh` |
|  |  | `url` | `# <url> <stage> # download the Docker workspaces tree under <url> into the empty folder <stage> with wget, the listing pages left out — rc 1 + RESULT when wget is missing or the download gives no Dockerfile #` |  | `private.odocker.workspaces.fetch.url` |
|  | `install` |  | `# <?path> # give this host its Docker workspaces root and the shared odocker.env that names it: keep an existing value, else create <path> (default beside the Once.sh base), share it with group dev and set it; idempotent #` |  | `odocker.workspace.install` |
|  | `merge` |  | `# <stage> <root> <?source> # put every unit of <stage> — a top-level file or a second-level entry — into <root>: a missing one copied, an identical one left, a differing one overwritten only after a yes on the terminal, an entry only in <root> untouched — RESULT counts added, overwritten, kept and unchanged #` |  | `private.odocker.workspaces.merge` |
| `odocker.workspaces.default` | `get` |  | `#  # the Docker workspaces root beside the Once.sh components base: <parent of oo mode.base.get>/DockerWorkspaces, else beside the Once.sh folder that holds ~/oosh; rc 1 when neither is detectable #` |  | `private.odocker.workspaces.default.get` |
| `odocker.workspaces.entry.same` |  |  | `# <sourceEntry> <localEntry> # rc 0 when <localEntry> is the same as <sourceEntry> — a symlink by its target, a file by its bytes — rc 1 when it differs or is missing #` |  | `private.odocker.workspaces.entry.same` |
| `odocker.workspaces.merge.answer` | `get` |  | `# <unit> <source> # echo y or n — the answer on the terminal to Overwrite <unit> (differs from <source>)? [y/N] — n without a terminal or for any other answer #` |  | `private.odocker.workspaces.merge.answer.get` |
| `odocker.workspaces.mine` |  |  | `# <dir> # rc 0 when the caller may share <dir> without sudo: it owns <dir>, or it is root #` |  | `private.odocker.workspaces.mine` |
| `odocker.workspaces.source.host` | `get` |  | `#  # echo the ossh Host workspace.seed fetches from first — ODOCKER_SEED_HOST, else WODA.test #` |  | `private.odocker.workspaces.source.host.get` |
| `odocker.workspaces.legacy.path` | `get` |  | `#  # echo the folder of the OLD layout, where a Host without a usable odocker keeps its Docker workspaces — WODA.test today #` |  | `private.odocker.workspaces.legacy.path.get` |
| `odocker.workspaces.host.path` | `get` |  | `# <host> # echo the Docker workspaces root of <host> as the Host itself names it — its own odocker workspace.get, else the old layout where that folder exists there — nothing and rc 1 when it names none #` |  | `private.odocker.workspaces.host.path.get` |
| `odocker.workspaces.source.url` | `get` |  | `#  # echo the URL workspace.seed downloads from when the Host cannot be used — ODOCKER_SEED_URL, else https://test.wo-da.de/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces #` |  | `private.odocker.workspaces.source.url.get` |
<!-- END generated: oosh method matrix -->
