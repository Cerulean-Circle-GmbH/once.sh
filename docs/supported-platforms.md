# Supported Platforms

## Requirements

- **Bash 4.0 minimum** — oosh uses `${var^^}` syntax (Bash 4+ feature)
- macOS ships Bash 3.2 — the install process auto-installs Bash 5 via `brew`

## Platform Tiers

**Must pass** — these platforms gate promotion to prod. All must pass install tests before code is promoted.

**Best effort** — tested but failures don't block promotion. These platforms may have limitations or require manual testing.

Tiers are configurable via oosh methods (see `defaults/platforms.env` for the machine-readable matrix).

## Must Pass

| Platform | Package Manager | Bash | Docker Image | Test Method |
|----------|----------------|------|--------------|-------------|
| Ubuntu 24.04 | `apt-get` | 5.2 | `ubuntu:24.04` | Docker |
| Debian 12 | `apt-get` | 5.2 | `debian:12` | Docker |
| AlmaLinux 9 | `dnf` | 5.1 | `almalinux:9` | Docker |
| Alpine 3.19 | `apk` | 5.2 | `alpine:3.19` | Docker |
| macOS | `brew` | 3.2 -> 5.x (auto-install) | N/A | SSH / GitHub Actions / manual |

## Best Effort

| Platform | Package Manager | Bash | Docker Image | Test Method |
|----------|----------------|------|--------------|-------------|
| Arch Linux | `pacman` | 5.2+ | `archlinux:latest` | Docker |
| FreeBSD | `pkg` | 5.x (ports) | N/A | VM / jail |
| Android (Termux) | `pkg` | 5.x | N/A | Real device |
| iOS (iSH) | `apk` | 5.x | N/A | Real device |
| Windows (WSL) | Linux PM | 5.x | N/A | Real device / VM |
| CentOS 7 | `yum` | 4.2 | `centos:7` | Docker |

## Not Yet Supported

| Platform | Gap |
|----------|-----|
| Windows (native) | No `choco`/`winget` integration, path differences, no `sudo` |

## macOS Install Flow

macOS ships Bash 3.2 due to Apple's GPL licensing policy. The oosh install process handles this automatically:

1. Detect macOS (system Bash 3.2)
2. Ensure Homebrew is available — install if missing
3. `brew install bash` (installs Bash 5.x)
4. Re-exec the install under the new bash (`/opt/homebrew/bin/bash` on ARM, `/usr/local/bin/bash` on Intel)
5. Continue with normal oosh install

## Configuration

The platform matrix is stored as environment variables following oosh config conventions:

- **Defaults (in repo):** `defaults/platforms.env`
- **Per-machine overrides:** `~/config/platforms.env` (via `config save platforms PLATFORM`)

Format:
```bash
export PLATFORM_<name>="<docker_image>:<package_manager>:<tier>"
```

## See Also

- [Branching Strategy](branching.md)
- [Config System](config.md)
