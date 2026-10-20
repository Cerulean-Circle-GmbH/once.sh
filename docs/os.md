# os — OS Detection & Platform Testing

The `os` script provides OS detection and platform install testing for oosh. It detects the running operating system and tests oosh installation across supported platforms via Docker containers and CI workflows.

## Overview

- Detects OS type (macOS, Linux, FreeBSD, Windows variants)
- Tests oosh installation on all supported platforms
- Docker-based testing for Linux platforms via `odocker` + `ossh`
- GitHub Actions CI for macOS testing
- Platform matrix managed via `defaults/platforms.env` with per-machine overrides

## Quick Start

```bash
# Show OS info
os info

# List all platforms with tier info
os platform.list

# Test oosh install on a single platform
os platform.test ubuntu_24_04

# Test all must-pass platforms
os platform.test.all
```

## OS Detection Methods

| Method | Parameters | Description |
|--------|-----------|-------------|
| `os info` | `<?verbose>` | Show OS info (hostname, type, package manager). Add `v` for full `/etc/os-release` |
| `os check` | `<method>` | Detect OS and append `.darwin` or `.linux` to method name. Returns result with resolved method |
| `os check.env` | | Set `$OOSH_OS` environment variable based on detected OS type |
| `private.os.release.get` | `<key> <?file:/etc/os-release>` | Echo one value of an os-release file (`ID`, `VERSION_CODENAME`, `PRETTY_NAME` …), its quotes removed; rc 1 and nothing for a missing key or file. Read line by line, never sourced. `os info` and odocker's `private.odocker.docker.repo.add` (through `private.this.script.load os private.os.release.get`) use it; `<file>` lets a test use a fixture (T-OS-RELEASE-GET) |
| `os service.on` | `<service>` | Switch a system service on, now and at boot: `systemctl enable --now`, else OpenRC (`rc-update add` + `rc-service start`), else SysV `service start` on Linux; on macOS the system launch daemon `<service>` (a label such as `com.apple.smbd`): `launchctl enable` + `bootstrap`, an already loaded daemon counts as on. Through `$SUDO`; rc 1 naming the service when nothing works (T-OS-SERVICE) |
| `os service.off` | `<service>` | The reverse: `systemctl disable --now`, else `rc-service stop` + `rc-update del`, else `service stop`; macOS `launchctl bootout` + `disable` (T-OS-SERVICE) |
| `private.os.systemd.is` | `<?root:/>` | rc 0 when systemd runs this computer: `<root>/run/systemd/system` is there and `systemctl` is on PATH; a container has none (T-OS-SYSTEMD-IS) |

### os.check Pattern

`os.check` enables OS-specific method dispatch — a core oosh pattern:

```bash
source os

if os.check ossh.service.status; then
  # Calls ossh.service.status.darwin on macOS
  # or ossh.service.status.linux on Linux
  $RESULT "$@"
else
  important.log "$RESULT is not supported"
fi
```

### Detected OS Types

| `$OSTYPE` | `$OOSH_OS` | Platform |
|-----------|-----------|----------|
| `darwin*` | `darwin` | macOS |
| `linux-gnu*` | `linux-gnu` | Linux |
| `cygwin` | `cygwin` | Cygwin (Windows) |
| `msys` | `msys` | MSYS/Git Bash (Windows) |
| `win32` | `win32` | Windows native |
| `freebsd` | `freebsd` | FreeBSD |

## Platform Testing Methods

| Method | Parameters | Description |
|--------|-----------|-------------|
| `os platform.list` | | List all platforms with workspace, package manager, and tier |
| `os platform.test` | `<platform> <?terminal>` | Test oosh installation on a single platform. Pass `terminal` to open interactive session after tests |
| `os platform.test.all` | | Test all platforms, report summary. Exit 0 only if all must-pass platforms pass |
| `os platform.parse.check` | `<?platform:almalinux_9> <?dir:$OOSH_DIR>` | `bash -n` every tracked shell file of `<dir>` (first line a `#!…sh`) with the bash of the image of `<platform>`, in a throwaway container (`odocker image.command`); almalinux_9 has the oldest bash oosh runs on (5.1). rc 1 naming each file that does not parse — `test/test.oo` did not load on almalinux_9 (a `case` pattern without its `(` inside `$( ( … ) )`), only a promotion's platform test found it (T-OS-PLATFORM-PARSE-CHECK). Needs the image on this host (`os platform.test <platform>` builds it) |

### Platform Test Flow (Docker platforms)

For each Docker-testable platform, `os platform.test` runs fully automated (no interactive prompts). Every run exercises **4 users** covering every install path we support:

| User | Created via | Install path exercised |
|---|---|---|
| `test` | Image default / target of initial `ossh install <platform> test` | ssh-as-test → state machine + `user.oosh.install test` |
| `root` | Already exists in image | sudo re-exec from test (init/oosh non-root → root branch) |
| `oosh-user` | Inside test session: `user create oosh-user password oosh-user` | oosh-native user creation — `user.create` → `user.oosh.install` as side-effect |
| `bash-user` | Raw `useradd` on remote + caller: `ossh install <platform> bash-user` | caller-initiated install for pre-existing account — `ossh.install.user.remote` |

**Flow:**

1. `odocker reset <image>` — fresh container with SSH access
2. `ossh config.create` / `ossh config.save.last` — SSH config setup (`User=test` convention)
3. Clean stale ControlMaster socket from any previous run: `ossh connection.close`, then remove the socket `private.ossh.control.path.resolved.get` names (`$OSSH_CONTROL_PATH` with `%C` expanded by `ssh -G`; T-OSSH-CONTROL-PATH-RESOLVED-GET)
4. `sshpass` opens a ControlMaster connection (password via `$SSHPASS` env var, runs `true` to avoid background fork race)
5. `ossh key.push` — pushes SSH key, reusing the ControlMaster socket (no password prompt)
6. Configure `NOPASSWD` sudo for `test` on the ephemeral container
7. `ossh prereqs.install <platform>` — installs `curl + git` on the remote (and additionally `bash + shadow + util-linux` on apk hosts like alpine, where the base image ships only busybox + ash)
8. **Phase A — installs:**
   - `ossh install <platform> test` — root + test initial install
   - `ossh exec <platform> "user create oosh-user password oosh-user"` — creates oosh-user
   - Raw `useradd -m -G sudo bash-user` + NOPASSWD sudoers snippet — creates bash-user
   - `ossh install <platform> bash-user` — caller-initiated install for bash-user
9. **Phase B — tests** (skipped when `notests` modifier is passed):
   - `ossh exec <platform> "test.suite core 1"` → `test` log
   - `ossh exec.tty <platform> "sudo bash -lc '… test.suite core 1'"` → `root` log
   - `ossh exec.tty <platform> "sudo runuser -u oosh-user -- bash -lc 'test.suite core 1'"` → `oosh-user` log
   - `ossh exec.tty <platform> "sudo runuser -u bash-user -- bash -lc 'test.suite core 1'"` → `bash-user` log
10. `terminal` modifier drops into an interactive `bash-user` shell before cleanup (same last-user-created convention as before)
11. `ossh connection.close` + container cleanup

> **Why `sudo runuser -u <user> -- bash -lc …` for the two new users?** `user.login` itself (`env -i TERM="$(private.user.login.term.get)" su - "$1"` — a clean environment, TERM kept) is interactive and can't be fed a command. `sudo runuser -u <user> -- bash -lc …` is functionally identical — login-shell (`-lc`), fresh env, explicit user-switch — and scripts cleanly over one ssh-tt session. `runuser` ships from `util-linux` on every Linux target — present in the base image on Debian-derivatives and RHEL, installed by step 7 (`ossh prereqs.install`) on Alpine.

Non-interactive `ssh-keygen` (`-N ''`) is handled in `user`/`ossh` so key generation never prompts.

### macOS Testing (CI)

macOS is tested via GitHub Actions (`macos-test.yml`) — same 4-user matrix as Linux (test → root → oosh-user → bash-user), same Phase A → Phase B contract (all 4 users installed before any test.suite runs).

1. `os platform.test macos` triggers the workflow via `gh` CLI
2. Watches the run and reports PASS/FAIL
3. Requires `gh` CLI authenticated (`gh auth login`)

The macOS workflow follows the same `ossh prereqs.install → ossh install` pattern as Linux. `ossh prereqs.install macos` (called as Phase A.1a-bis) installs `bash + curl + git` via brew and writes `/etc/paths.d/oosh-homebrew` so non-interactive ssh sessions find brew bash. From that point on, `ossh install macos <user>` works identically to its Linux equivalents.

**macOS-specific primitives (same primitives, different name from Linux):**

- **`sysadminctl` instead of `useradd`** — macOS's user-add primitive. `user.create` dispatches to it via the darwin branch at `user:524` (with brew-bash shell selection); raw `bash-user` creation in the workflow uses it directly with default `/bin/bash` (PATH-discoverable brew bash takes over once `/etc/paths.d/oosh-homebrew` is in place).
- **`com.apple.access_ssh` group + `dseditgroup`** — macOS gates SSH access via this group; each new user (oosh-user, bash-user) is added to it after creation.
- **Per-user `ossh config.create macos_<user>` instead of `runuser`** — macOS doesn't ship util-linux's `runuser`. Phase B.3 and B.4 use a separate ossh config alias (`macos_oosh_user`, `macos_bash_user`) so `ossh exec` connects directly as that user via key-based SSH (key already pushed to their `authorized_keys` during their setup phase).
- **Brew bash for root tests** — Phase B.2 uses `sudo -H /opt/homebrew/bin/bash -c` because sudo resets PATH; `path_helper` is per-shell, so `sudo -H bash` would resolve to system `/bin/bash` 3.2 unless we name the brew binary explicitly.

### Interactive Terminal (tmate)

After tests complete, you can open an interactive SSH session on the runner to inspect the oosh installation:

```bash
os platform.test macos terminal
```

This adds a tmate step to the CI workflow. After tests finish:

1. Open the GitHub Actions run in browser (URL printed in terminal)
2. Click the **"Interactive terminal (tmate)"** step
3. Copy the SSH command (e.g. `ssh XKCLq...@nyc1.tmate.io`)
4. Run it in your local terminal

**Important:** tmate starts bash with `--norc --noprofile`, so no startup files are sourced. After connecting, run:

```bash
source ~/.bashrc
```

This loads the full oosh environment (PATH, prompt, completion, colors). Then you can run any oosh command.

The session has a **30-minute timeout** and is restricted to the GitHub user who triggered the workflow.

For Docker platforms, `terminal` opens an interactive SSH session via `ossh exec.tty` after tests — oosh is loaded automatically there.

**Note:** On a real macOS install (not tmate), oosh works automatically. The installer creates `~/.bash_profile` that sources `~/.bashrc`, so Terminal.app loads oosh on every new shell.

## Platform Configuration

### defaults/platforms.env

Platform definitions live in `defaults/platforms.env` (committed to the repo):

```bash
# Format: PLATFORM_<name>="<workspace>:<base_image>:<package_manager>:<tier>"
PLATFORM_ubuntu_24_04="nakedUbuntu/24.04:ubuntu:24.04:apt-get:must-pass"
PLATFORM_macos="native:native:brew:must-pass"
```

Fields:
- **workspace** — DockerWorkspaces relative path, or `native` for non-Docker platforms
- **base_image** — Docker Hub image the Dockerfile is FROM, or `native`
- **package_manager** — System package manager (apt-get, dnf, apk, brew, etc.)
- **tier** — `must-pass` (gates promotion) or `best-effort` (tested, doesn't block)

### Per-machine Overrides

Customize the platform matrix for a specific machine:

```bash
config save platforms PLATFORM
```

This saves overrides to `~/config/platforms.env`, which is loaded after defaults.

### Current Platform Matrix

| Platform | Workspace | PM | Tier |
|----------|-----------|-----|------|
| ubuntu_24_04 | nakedUbuntu/24.04 | apt-get | must-pass |
| debian_12 | nakedDebian/12 | apt-get | must-pass |
| almalinux_9 | nakedAlma/9.sshd | dnf | must-pass |
| alpine_3_19 | nakedAlpine/3.19 | apk | must-pass |
| macos | native | brew | must-pass |
| archlinux | native | pacman | best-effort |
| freebsd | native | pkg | best-effort |
| android_termux | native | pkg | best-effort |
| ios_ish | native | apk | best-effort |
| windows_wsl | native | apt-get | best-effort |
| centos_7 | native | yum | best-effort |

## See Also

- [Promotion Pipeline](promote.md) — Uses platform tests to gate stage→prod promotion
- [Docker Wrapper (odocker)](odocker.md) — Container management for platform testing
- [Supported Platforms](supported-platforms.md) — Detailed platform requirements and versions
- [Branching Strategy](branching.md) — How platform tests fit in the promotion flow

<!-- BEGIN generated: oosh method matrix (oosh-architect) -->
## `os` — method matrix (origin/dev ↔ origin/test/mcdonges.latest)

Generated by oosh-architect from the branch sources (2026-10-20). Indexes: [methods-index.md](methods-index.md) · [object-verb-index.md](object-verb-index.md) · [parameter.md](parameter.md).

**Decomposition** — every method is `os.<object>.<verb>[.<more.words>]`. One method = one row.
`object`/`verb` are left **blank when unchanged from the row above** (objects are never repeated).
The **script name is the root object** — `odocker` acts on `container`, `image`, `volume` … so a method is
an object CHAIN ending in a verb: **`object.object.verb`**. The object column shows the full chain.
The **verb is identified semantically** (a real action word), not by position; OOSH's normalized form puts
the **verb last** (e.g. `authorized.keys.update`), so segments before it are the object, after it `more.words`.
An **empty verb** means the name carries **no action at all** — the chain never reaches a verb
(an `object.verb` naming gap, listed in [verb-audit.md](verb-audit.md)).

| object | verb | more.words | all parameter | origin/test/mcdonges.latest | origin/dev |
|---|---|---|---|---|---|
| **=== public ===** | | | | | |
| `os` | `check` |  | `# <method> # is true if an OS was detected. LOG LEVEL 4 to see output.` | `os.check` | `os.check` |
|  |  | `env` | `# #` | `os.check.env` | `os.check.env` |
| `os.hostname` | `get` |  | `# # return the effective hostname` | `os.hostname.get` |  |
|  | `set` |  | `# <hostname> # set the system hostname (may require sudo)` | `os.hostname.set` |  |
| `os.hostname.info` |  |  | `# # show hostname from all available sources` | `os.hostname.info` |  |
| `os.info` |  |  | `# <verbose:> # shows info abut the running os. add v to get more details` | `os.info` | `os.info` |
| `os.platform` | `list` |  | `# # lists all platforms with tier info` |  | `os.platform.list` |
|  | `test` |  | `# <platform> <?terminal> <?notests> # tests oosh installation on a single platform` |  | `os.platform.test` |
|  |  | `all` | `# # tests all must-pass platforms, reports summary` |  | `os.platform.test.all` |
| `os.platform.parse` | `check` |  | `# <?platform:almalinux_9> <?dir:$OOSH_DIR> # bash -n every tracked shell file of <dir> with the bash of the image of <platform> — almalinux_9 has the oldest bash oosh runs on (5.1); rc 1 naming each file that does not parse` |  | `os.platform.parse.check` |
| `os.service.off` |  |  | `# <service> # switch the system service <service> off, now and at boot: systemd, else OpenRC, else SysV service on Linux; the system launch daemon <service> on macOS; rc 1 naming it when it cannot #` |  | `os.service.off` |
| `os.service.on` |  |  | `# <service> # switch the system service <service> on, now and at boot: systemd, else OpenRC, else SysV service on Linux; on macOS the system launch daemon <service> (a label like com.apple.smbd); rc 1 naming it when it cannot #` |  | `os.service.on` |
| **=== private ===** | | | | | |
| `os.hostname` | `get` | `darwin` | `# # get hostname on macOS — prefer scutil HostName, fall back to ComputerName` | `private.os.hostname.get.darwin` |  |
|  |  | `linux` | `# # get hostname on Linux` | `private.os.hostname.get.linux` |  |
|  | `set` | `darwin` | `# <hostname> # set hostname on macOS via scutil` | `private.os.hostname.set.darwin` |  |
|  |  | `linux` | `# <hostname> # set hostname on Linux` | `private.os.hostname.set.linux` |  |
| `os.hostname.info.darwin` |  |  | `# # show hostname sources on macOS` | `private.os.hostname.info.darwin` |  |
| `os.hostname.info.linux` |  |  | `# # show hostname sources on Linux` | `private.os.hostname.info.linux` |  |
| `os.platform` | `cleanup` |  | `# <port> # stops and removes Docker container on given port` |  | `private.os.platform.cleanup` |
|  | `load` |  | `# # loads platform config from defaults and user overrides` |  | `private.os.platform.load` |
|  | `parse` |  | `# <platform> # parses platform config into PLATFORM_* variables` |  | `private.os.platform.parse` |
|  | `test` | `ci` | `# <platform> <?terminal> <?notests> # triggers CI workflow for native platform testing` |  | `private.os.platform.test.ci` |
| `os.platform.container.id` |  |  | `# <port> # id of the running platform-test container publishing <port> (empty if none)` |  | `private.os.platform.container.id` |
| `os.platform.image` | `exists` |  | `# <imageTag> # rc 0 when the image <imageTag> is on this host` |  | `private.os.platform.image.exists` |
| `os.platform.image.from.workspace` |  |  | `# <workspace> # converts workspace path to Docker image tag` |  | `private.os.platform.image.from.workspace` |
| `os.platform.names` |  |  | `# # returns sorted list of platform names` |  | `private.os.platform.names` |
| `os.platform.shared.config` | `repair` |  | `# <platform> # reset sharedConfig group+perms in <platform>'s container so subsequent unprivileged users can write after root's test.suite left root-owned files there` |  | `private.os.platform.shared.config.repair` |
| `os.platform.sshd` | `reload` |  | `# <port> # re-exec the container's sshd after an in-place openssh upgrade during install` |  | `private.os.platform.sshd.reload` |
| `os.release` | `get` |  | `# <key> <?file:/etc/os-release> # echo one value of the os-release <file> (ID, VERSION_CODENAME, PRETTY_NAME …) with its quotes removed, without running the file; rc 1 and nothing when the key or the file is missing #` |  | `private.os.release.get` |
| `os.service.off.darwin` |  |  | `# <label> # launchctl bootout system/<label>, then disable it; a daemon not loaded is off #` |  | `private.os.service.off.darwin` |
| `os.service.off.linux` |  |  | `# <service> # systemctl disable --now, else rc-service stop + rc-update del, else service stop #` |  | `private.os.service.off.linux` |
| `os.service.on.darwin` |  |  | `# <label> # launchctl enable system/<label>, then bootstrap its LaunchDaemons plist; a daemon already loaded is on #` |  | `private.os.service.on.darwin` |
| `os.service.on.linux` |  |  | `# <service> # systemctl enable --now, else rc-update add + rc-service start, else service start #` |  | `private.os.service.on.linux` |
| `os.shell.files` | `list` |  | `# <dir> # echo the tracked files of <dir> whose first line is a #! naming sh or bash, one per line, relative to <dir>` |  | `private.os.shell.files.list` |
| `os.systemd` | `is` |  | `# <?root:/> # rc 0 when systemd runs this computer: its run directory <root>/run/systemd/system is there and systemctl is on PATH; a container has none #` |  | `private.os.systemd.is` |
<!-- END generated: oosh method matrix -->
