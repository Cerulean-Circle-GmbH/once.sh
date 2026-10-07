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
| `os platform.test` | `<platform> <?terminal> <?notests> <?branch>` | Test oosh installation on a single platform. Pass `terminal` to open interactive session after tests, `notests` to skip Phase B, `<branch>` to install an older ref first (see [Installing an older ref first](#installing-an-older-ref-first)). Arguments are positional: an empty placeholder keeps its place, so `os platform.test ubuntu_24_04 "" notests` runs without tests and without a terminal |
| `os platform.test.all` | | Test all platforms, report summary. Exit 0 only if all must-pass platforms pass |

### Platform test building blocks

`os platform.test` is three private methods in a row, so a scenario test (the coming `os platform.heal.test`) can reuse any of them:

| Method | What it does |
|---|---|
| `private.os.platform.container.up <platform> <image> <port>` | steps 1-6 and the first install: a fresh container from `<image>` on ssh `<port>`, the ssh config and ControlMaster, the pushed key, `NOPASSWD` sudo for `test`, `ossh install` of `test`, then sshd and the ControlMaster settled; rc 1 when the image cannot be built |
| `private.os.platform.users.install <platform>` | Phase A for the other users: `oosh-user` through `user create`, `bash-user` through `useradd`/`adduser`, both with `NOPASSWD` sudo, then `ossh install <platform> bash-user` from the caller; failures are logged, not fatal |
| `private.os.platform.gate.run <platform> <user>` | Phase B for ONE user (`test`, `root`, `oosh-user`, `bash-user`): `test.suite gate 1` (core plus the platform invariants) through the transport that fits the user, teed into the log of `private.os.platform.gate.log.get <user> <platform>`; rc is that user's gate rc |

`private.os.platform.gate.log.get <user> <platform>` echoes `/tmp/oosh-platform-test-<user>-<platform>.log` (a silent getter; `gate.run` and `platform.test` share it). `private.os.platform.socket.remove <port>` removes the stale ControlMaster socket `/tmp/ossh-test@localhost:<port>` (silent, idempotent) and is a method of its own so tests can stub it instead of deleting a live socket.

### Installing an older ref first

`os platform.test <platform> "" "" <branch>` takes a branch name or commit sha of this repo. `<branch>` is exported as `OSSH_INSTALL_BRANCH` to the two install steps only (`ossh install` of `test` in `container.up`, of `bash-user` in `users.install`; a prefix assignment, so it lives for that one call). **Planned:** `ossh install` honours `OSSH_INSTALL_BRANCH` once package B4 lands; until then the variable is set and ignored. macOS refuses a `<branch>` (the CI workflow installs its own branch).

Before anything starts, the era gate `private.os.platform.branch.gate <branch> <?dir>` reads `init/oosh` of the ref through `ogit.file.show` and refuses a ref whose installer lacks the `mode root` contract, i.e. older than commit `b8b90b82` (older refs use `mode ssh` and rsync, which the current `ossh install` cannot drive). It tries `<branch>`, then `origin/<branch>` (what the completion offers), and reads the **local** repo: a local-only sha passes the gate and then fails in the container, which clones from the remote.

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
3. Clean stale ControlMaster socket from any previous run
4. `sshpass` opens a ControlMaster connection (password via `$SSHPASS` env var, runs `true` to avoid background fork race)
5. `ossh push.key` — pushes SSH key, reusing the ControlMaster socket (no password prompt)
6. Configure `NOPASSWD` sudo for `test` on the ephemeral container
7. `ossh prereqs.install <platform>` — installs `curl + git` on the remote (and additionally `bash + shadow + util-linux` on apk hosts like alpine, where the base image ships only busybox + ash)
8. **Phase A — installs:**
   - `ossh install <platform> test` — root + test initial install
   - `ossh exec <platform> "user create oosh-user password oosh-user"` — creates oosh-user
   - Raw `useradd -m -G sudo bash-user` + NOPASSWD sudoers snippet — creates bash-user
   - `ossh install <platform> bash-user` — caller-initiated install for bash-user
9. **Phase B — tests** (skipped when `notests` modifier is passed):
   - `private.os.platform.gate.run <platform> <user>` once per user, each running `test.suite gate 1` (core plus `platform.shared.configLayout.invariant`): `ossh exec` for `test`, `ossh exec.tty` with `sudo bash -lc` for `root`, `sudo runuser -u <user>` (else `sudo -H -u <user>`) for `oosh-user` and `bash-user`; logs per `private.os.platform.gate.log.get`
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
