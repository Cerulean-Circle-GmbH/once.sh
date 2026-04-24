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
7. **Phase A — installs:**
   - `ossh install <platform> test` — root + test initial install
   - `ossh exec <platform> "user create oosh-user password oosh-user"` — creates oosh-user
   - Raw `useradd -m -G sudo bash-user` + NOPASSWD sudoers snippet — creates bash-user
   - `ossh install <platform> bash-user` — caller-initiated install for bash-user
8. **Phase B — tests** (skipped when `notests` modifier is passed):
   - `ossh exec <platform> "test.suite core 1"` → `test` log
   - `ossh exec.tty <platform> "sudo bash -lc '… test.suite core 1'"` → `root` log
   - `ossh exec.tty <platform> "sudo runuser -u oosh-user -- bash -lc 'test.suite core 1'"` → `oosh-user` log
   - `ossh exec.tty <platform> "sudo runuser -u bash-user -- bash -lc 'test.suite core 1'"` → `bash-user` log
9. `terminal` modifier drops into an interactive `bash-user` shell before cleanup (same last-user-created convention as before)
10. `ossh connection.close` + container cleanup

> **Why `sudo runuser -u <user> -- bash -lc …` for the two new users?** `user.login` itself (`env -i su - "$1"`) is interactive and can't be fed a command. `sudo runuser -u <user> -- bash -lc …` is functionally identical — login-shell (`-lc`), fresh env, explicit user-switch — and scripts cleanly over one ssh-tt session. `runuser` is util-linux and ships by default on every Linux target in the platform matrix.

Non-interactive `ssh-keygen` (`-N ''`) is handled in `user`/`ossh` so key generation never prompts.

### macOS Testing (CI)

macOS is tested via GitHub Actions (`macos-test.yml`):

1. `os platform.test macos` triggers the workflow via `gh` CLI
2. Watches the run and reports PASS/FAIL
3. Requires `gh` CLI authenticated (`gh auth login`)

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
