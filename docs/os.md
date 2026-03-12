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
| `os platform.test` | `<platform>` | Test oosh installation on a single platform |
| `os platform.test.all` | | Test all platforms, report summary. Exit 0 only if all must-pass platforms pass |

### Platform Test Flow (Docker platforms)

For each Docker-testable platform, `os platform.test` runs:

1. `odocker reset <image>` — Fresh container with SSH access
2. `ossh config.create` / `ossh config.save.last` / `ossh push.key` — SSH setup
3. `ossh install <platform> test` — Install oosh remotely
4. `ossh exec <platform> "test.suite core 1"` — Run tests as user
5. `ossh exec.tty <platform> "sudo ... test.suite core 1"` — Run tests as root
6. Cleanup container

### macOS Testing (CI)

macOS is tested via GitHub Actions (`macos-test.yml`):

1. `os platform.test macos` triggers the workflow via `gh` CLI
2. Watches the run and reports PASS/FAIL
3. Requires `gh` CLI authenticated (`gh auth login`)

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
