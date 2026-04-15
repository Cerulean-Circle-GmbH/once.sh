# Report: Work Completed for AlmaLinux

**Created:** 2026-04-13
**Period:** 2026-02-22 to 2026-04-13 (~7 weeks)
**Authors:** Hannes Nortje, Marcel Donges

---

## Zusammenfassung

AlmaLinux 9 wurde als **Pflicht-Plattform** (must-pass) in die OOSH-Testmatrix aufgenommen. Um sicherzustellen, dass OOSH auf AlmaLinux fehlerfrei installiert, laeuft und getestet werden kann, wurden umfangreiche Arbeiten durchgefuehrt:

- **Paketmanager-Unterstuetzung** fuer dnf/yum (AlmaLinux-Standardwerkzeuge)
- **POSIX-Kompatibilitaet** — Entfernung von GNU-spezifischen Befehlen, die auf AlmaLinux fehlen
- **Docker-Infrastruktur** — neues `odocker`-Skript (~450 Zeilen) + AlmaLinux Docker-Image
- **Installationsprozess** — `ossh install` funktioniert jetzt auf RHEL/AlmaLinux (sudo, TTY, PATH)
- **Benutzerverwaltung** — RHEL-spezifische Gruppenbehandlung (wheel, User Private Groups)
- **Automatisierte Plattformtests** — AlmaLinux wird bei jeder Aenderung automatisch getestet
- **Release-Pipeline** — Kein Code gelangt in Produktion ohne bestandene AlmaLinux-Tests
- **Plattformuebergreifende Verbesserungen** — Shell-Portabilitaet, SSH, Multi-User-Support

**Umfang:** ~250 Commits | 7 Wochen | 25+ Dateien | Ergebnis: AlmaLinux 9 Tests bestanden (362/363)

---

## Work Volume Summary

### Core AlmaLinux Work (Sections 1–7)

| Area | Commits | Files Changed | Period |
|------|---------|---------------|--------|
| Package manager (dnf/yum) | 1 | 5 | Feb 2026 |
| POSIX compatibility | 5 | 14 | Feb–Apr 2026 |
| odocker Docker wrapper | 68 | 3+ (odocker, tests, docs) | Feb–Apr 2026 |
| AlmaLinux Docker image | 1 | 1 | Mar 2026 |
| Installation fixes | 4 | 6 | Mar 2026 |
| User management | 1 | 1 | Mar 2026 |
| Platform test infrastructure | 61 | 10+ | Mar–Apr 2026 |
| Release pipeline | 20+ | 10+ | Mar 2026 |

### Cross-Platform Work Benefiting AlmaLinux (Section 8)

| Area | Commits | Period |
|------|---------|--------|
| Portable sed and shell detection | 1 | Mar 2026 |
| Login shell / environment setup | 6 | Mar 2026 |
| Cross-platform user management | 6 | Mar 2026 |
| Multi-user install support (ossh) | 13 | Mar–Apr 2026 |
| SSH / ControlMaster improvements | 5 | Feb–Mar 2026 |
| Shared SSH config and deploy key | 9 | Apr 2026 |
| Docker socket access | 10 | Apr 2026 |
| Test suite framework improvements | 7 | Feb–Mar 2026 |
| State machine fixes | 4 | Mar 2026 |
| Branching strategy and promote system | 30+ | Mar 2026 |

### Totals

**Directly AlmaLinux-related commits (Sections 1–7):** 14 explicitly mentioning AlmaLinux/RHEL, plus 150+ infrastructure commits
**Cross-platform commits benefiting AlmaLinux (Section 8):** 86+
**Combined total:** 250+ commits
**Total files touched:** 25+
**Period:** 2026-02-22 to 2026-04-13

---

## Summary (English)

AlmaLinux 9 was added as a **must-pass** platform in the OOSH test matrix. To ensure OOSH installs, runs, and tests cleanly on AlmaLinux, extensive work was carried out across the following areas:

**Core AlmaLinux work (Sections 1–7):**

1. **Package manager support** (dnf/yum)
2. **POSIX compatibility** (removal of GNU-specific commands)
3. **Docker infrastructure** (odocker wrapper, AlmaLinux Docker image)
4. **Installation process** (ossh install on RHEL/AlmaLinux)
5. **User management** (user.create on RHEL systems)
6. **Platform test infrastructure** (automated tests on 4 Linux platforms + macOS)
7. **Release pipeline** (promote system with AlmaLinux as a gate)

**Cross-platform work that also applies to AlmaLinux (Section 8):**

8. **Cross-platform improvements** (portable shell, login setup, multi-user install, SSH, Docker socket, test suite, state machine, branching)

---

## 1. Package Manager Support (dnf/yum)

**Date:** 2026-02-27
**Commit:** `d6de39a`

OOSH previously only supported `apt-get` (Debian/Ubuntu) and `brew` (macOS). For AlmaLinux, the entire package manager detection had to be extended:

- **init/oosh** (bootstrap script): Added detection for `dnf` and `yum`
- **oo** (framework core): `oo cmd update` and `oo cmd install` now support dnf/yum
- **ng/c2** (completion system): `c2.install.linux` recognises dnf/yum
- **otest** (test framework): venv setup for RHEL/AlmaLinux
- **claudeFlow**: Install hints for dnf/yum systems

**Files changed:** 5 | **Diff:** +47 / -6

---

## 2. POSIX Compatibility

AlmaLinux 9 (minimal installation) does not include all GNU tools that are available by default on Ubuntu/Debian. The following incompatibilities were fixed:

### 2a. `which` replaced with `command -v`

**Dates:** 2026-02-27 and 2026-03-04
**Commits:** `0f23296`, `dc7e701`

The `which` command is not available on minimal AlmaLinux installations. All occurrences were replaced with the POSIX-standard `command -v`:

- **init/oosh**: 4 replacements — fixes the `sudo: : command not found` error during bootstrap
- **config, debug, loop, ng/c2, state, status, this**: All `which` calls replaced with `command -v`
- Additional fixes: debug step() for non-interactive terminals, state.of shift handling, config.check.file return value

**Files changed:** 9 | **Diff:** +28 / -24

### 2b. moreutils dependency removed

**Date:** 2026-03-03
**Commit:** `8f6784b`

The `moreutils` package (required for the `errno` function) has dependency issues on RHEL/AlmaLinux (requires EPEL, broken Perl dependencies). The `errno` function was replaced with a Python3-based implementation (`os.strerror()` + `errno.errorcode`).

**Files changed:** 4 | **Diff:** +8 / -5

### 2c. POSIX BRE regex fix

**Dates:** 2026-04-01 and 2026-04-13
**Commits:** `848c755`, `applied-now`

AlmaLinux uses strict POSIX BRE in `sed`. The GNU extension `\?` (optional) is not available there and caused `bad regex` errors in the completion system (c2 and 2c). All occurrences were replaced with the POSIX-compatible `?`.

**Files changed:** 2 | **Diff:** +2 / -2

### 2d. Git configuration for containers

**Date:** 2026-04-01
**Commits:** `f81a46b`, `16380b1`

AlmaLinux containers lack global git configuration. Tests that run `git commit` failed with `Author identity unknown`. Fixed by:

- Setting git user identity via `-c user.email` and `-c user.name` flags in test fixtures
- Explicitly creating a `dev` branch (AlmaLinux git creates `master` instead of `main`)

**Files changed:** 1 | **Diff:** +4 / -2

---

## 3. Docker Infrastructure (odocker)

### 3a. odocker — OOSH Docker Wrapper

**Date:** 2026-02-22 (creation) to ongoing
**68 commits** total

A completely new OOSH script `odocker` was developed, encapsulating all Docker operations. This is the foundation for the automated platform test infrastructure:

| Method | Description |
|--------|-------------|
| `odocker build <workspace>` | Build Docker image from Dockerfile |
| `odocker build.all` | Build all workspaces |
| `odocker run.sshd <image>` | Start container with SSH server |
| `odocker reset <image>` | Stop, remove, and restart container |
| `odocker rebuild <workspace>` | Remove image and rebuild |
| `odocker clone <container>` | Clone container (snapshot + duplicate) |
| `odocker up/down <container>` | Start/stop container |
| `odocker enter <container>` | Interactive shell into container |
| `odocker exec <container> <cmd>` | Execute command in container |
| `odocker install <container>` | Install Docker CLI inside a container (auto-detects OS) |
| `odocker install` | Install Docker on host (auto-detects inside/outside Docker) |
| `odocker workspace.list` | Show all Dockerfile workspaces |
| `odocker container.list` | Show running containers |
| `odocker image.list` | Show available images |
| `odocker status` | Docker system status |
| `odocker disk` | Docker disk usage |
| `odocker prune / prune.all` | Cleanup |
| `odocker file.find <image>` | Find Dockerfile in workspace |

**Total scope:** ~450+ lines of code, ~90 test assertions, full tab completion, documentation (`docs/odocker.md`)

### 3b. AlmaLinux Docker Image

**Date:** 2026-03-06
**Commit:** `3f59cf8`

The Docker image `nakedAlma/9.sshd` was set up as a build target:

- **Base:** `almalinux:9` (official AlmaLinux Docker image)
- **Contents:** Minimal installation + SSH server + sudo + wget
- **Size:** 229 MB
- **Build:** `odocker build nakedAlma/9.sshd`

In parallel, images for all must-pass platforms were built:
- nakedUbuntu/24.04 (218 MB)
- nakedDebian/12 (172 MB)
- nakedAlma/9.sshd (229 MB)
- nakedAlpine/3.19 (15.7 MB)

---

## 4. Installation Process (ossh install)

### 4a. RHEL/AlmaLinux installation errors fixed

**Date:** 2026-03-04
**Commit:** `c243b05`

Extensive bug fixes for the OOSH installation process on AlmaLinux:

- **user.create:** Detection of `wheel` vs `sudo` group (AlmaLinux uses `wheel`)
- **ossh install:** Use `sudo` + `/root/config/user.env` for sed path fix
- **ossh install:** Guard for `mv *.public_key` with glob existence check
- **oo state 30:** Guard for stateMachines copy with directory existence check
- **oo state 60:** Guard for once init with `command -v` check
- **user:** Use `rm -f` for authorized_keys to avoid error on fresh installs
- **init/oosh:** Populate USER and BASH_MAJOR_VERSION before status display
- **init/oosh:** Suppress noisy "no OS found" message during bootstrap

**Files changed:** 4 | **Diff:** +43 / -18

### 4b. TTY allocation for remote install

**Date:** 2026-03-09
**Commit:** `16ec820`

`sudo` requires a TTY for password prompts over SSH. The SSH connection was extended with `-tt` (force TTY allocation). Verified on Ubuntu, Debian, AlmaLinux, and Alpine.

**Files changed:** 1 | **Diff:** +8 / -3

### 4c. sudo PATH handling on AlmaLinux

**Dates:** 2026-03-27
**Commits:** `7362817`, `9c76f42`

AlmaLinux's `secure_path` in the sudo configuration overrides PATH. Multiple approaches were tested:
1. `sudo -E` (failed — secure_path overrides PATH)
2. `sudo -i` (failed — starts login shell, but .bashrc is not sourced)
3. **Solution:** `sudo bash -lc` with explicit PATH=~/oosh

**Files changed:** 1 | **Diff:** +3 / -3

---

## 5. User Management on RHEL/AlmaLinux

**Date:** 2026-03-27
**Commit:** `3c65194`

RHEL/AlmaLinux automatically creates a User Private Group (UPG) with the same name as the user during `useradd`. If a group with the same name already exists (e.g., the `dev` group from OOSH), `useradd` fails.

**Solution:** Use `-N` (no UPG creation) and `-g` (use existing group)

**Files changed:** 1 | **Diff:** +4 / -1

---

## 6. Platform Test Infrastructure

### 6a. Supported Platform Matrix

**Date:** 2026-03-06
**Commit:** `5db7742`

Definition of supported platforms with a tier system:

| Platform | Package Manager | Tier |
|----------|----------------|------|
| **Ubuntu 24.04** | apt-get | must-pass |
| **Debian 12** | apt-get | must-pass |
| **AlmaLinux 9** | dnf | **must-pass** |
| **Alpine 3.19** | apk | must-pass |
| **macOS** | brew | must-pass |
| CentOS 7 | yum | best-effort |
| Arch Linux | pacman | best-effort |

Configurable via `defaults/platforms.env` + `~/config/platforms.env`

### 6b. os.platform.test — Automated Platform Tests

**Dates:** 2026-03-09 to 2026-04-02
**61 commits** total

New methods in the `os` script for automated platform testing:

| Method | Description |
|--------|-------------|
| `os platform.test <platform>` | Test a single platform |
| `os platform.test <platform> notests` | Test install only (skip test suite) |
| `os platform.test.all` | Test all must-pass platforms |
| `os platform.list` | Display platform matrix |

**Test flow per platform:**
1. `odocker reset <image>` — fresh container with SSH
2. Create SSH configuration and push key
3. `ossh install <platform>` — install OOSH via SSH
4. `test.suite all 1` — run test suite remotely (skipped with `notests`)
5. Evaluate results and clean up container

The `notests` parameter (`7c196c2`, 2026-04-02) allows testing only the installation process without running the full test suite, useful for rapid iteration during install debugging.

**AlmaLinux test results:** 362/363 assertions passed (1 intentional meta-test failure)

### 6c. Docker CLI Installation in Containers

**Date:** 2026-04-01
**Commit:** `e79174c`

`odocker install <container>` automatically detects the OS inside the container and installs the Docker CLI:
- Alpine: via apk + Docker CE repository
- Debian/Ubuntu: via apt-get + Docker CE repository
- **RHEL/AlmaLinux/Fedora: via dnf + Docker CE repository** (default repos do not include docker-cli)

**Files changed:** 3 | **Diff:** +182 / -25

---

## 7. Release Pipeline with AlmaLinux as Gate

### 7a. Promote System

**Dates:** 2026-03-05 to 2026-03-11

The `promote` script with PROMOTE state machine was developed:

```
dev → stage (gated by core tests)
stage → prod (gated by platform tests on ALL must-pass platforms)
```

**AlmaLinux is a gate for production:** No code can be promoted to `prod` unless the AlmaLinux tests pass.

### 7b. First Release v1.0.0

**Date:** 2026-03-11

First successful promotion through the complete pipeline:
- **dev → stage:** 108 commits, all core tests passed
- **stage → prod:** All 5 platforms passed (Ubuntu, Debian, **AlmaLinux**, Alpine, macOS)
- **Tag:** `v1.0.0`

---

## 8. Cross-Platform Work Benefiting AlmaLinux

The following work was done to support all platforms in the test matrix. While not AlmaLinux-specific, each item directly runs on or applies to AlmaLinux as a must-pass platform. AlmaLinux benefits from every cross-platform fix because it is tested automatically on every promotion cycle.

### 8a. Portable `sed -i` and Shell Detection

**Date:** 2026-03-23
**Commit:** `eb76df4`

GNU `sed -i` (in-place edit) and BSD `sed -i ''` differ in syntax. A portable wrapper was implemented so all in-place edits work on both Linux (including AlmaLinux) and macOS. Also includes dynamic root home detection and macOS shell detection.

**Files changed:** oo, ossh

### 8b. Login Shell and Environment Setup (.bashrc / .bash_profile)

**Dates:** 2026-03-17 to 2026-03-24
**Commits:** `3f691ec`, `70abd31`, `9b396a3`, `c3ad938`, `d1abbbf`, `737cbcd`

Multiple fixes to ensure the OOSH environment loads correctly on login shells across all platforms, including inside AlmaLinux containers:

- Create `.bash_profile` that sources `.bashrc` on login shells
- `.bash_profile` uses `~` instead of escaped `$HOME` for portability
- Bridge `.bash_profile` to `.bashrc` for macOS login shells
- Set bash as login shell during user remote install
- Set root login shell to bash on Alpine
- Restore root login shell setup lost in merge

These ensure that `ossh install` on an AlmaLinux container results in a working OOSH environment for both root and non-root users.

### 8c. Cross-Platform User Management Fixes

**Dates:** 2026-03-09 to 2026-03-23
**Commits:** `6b368a4`, `bcfde06`, `91ad7e8`, `2b4063f`, `075b4a3`, `ca098aa`

The `user.create` function was hardened to work on all platforms:

- Find `useradd`/`groupadd`/`usermod` at `/usr/sbin` on Debian (not in default PATH)
- Detect `useradd` vs `adduser` at runtime instead of relying on OS string matching
- Handle existing group in `adduser` on Alpine
- Alpine compatibility for shebang, sudo, and usermod
- Ensure `/usr/sbin` in PATH for Phase 2 state machine on Debian

AlmaLinux benefits from the runtime detection approach -- `useradd` is found regardless of PATH configuration, and group handling is robust across all RHEL-family systems.

### 8d. Multi-User Install Support (ossh)

**Dates:** 2026-03-26 to 2026-04-02
**Commits:** `2edf910`, `828ca34`, `e1d3cab`, `3ab3038`, `03d43c6`, `3ea16a6`, `7e6f8f1`, `4abc6e9`, `2b157b1`, `3ff0fa0`, `6974f75`, `d3d17fb`, `dc9eb7f`

The ossh install process was extended to support multi-user scenarios, which run on all platforms including AlmaLinux:

- Auto-create user in install if the user does not exist
- Auto-create user + second user test in platform.test
- Root-first platform test with auto-create user
- Configure sshd via `docker exec` before SSH in platform test
- Use `targetHome` in `install.user.remote` for cross-user setup
- Use `sudo -u targetUser` for cross-user home access
- Skip bootstrap if oosh already installed (state [99])
- Skip bootstrap when `~/oosh` directory already exists
- Fix home dir resolution in key push mkdir and awk escaping
- Use `sudo -H -u` in install.user.remote so `~` resolves to target user home
- CI hardening: local sudo for sudoers setup, tolerate connection drops, re-open connections after install

The AlmaLinux platform test uses this full multi-user flow: install as root, then create and install for a second `dev` user.

### 8e. SSH / ControlMaster Improvements for Platform Tests

**Dates:** 2026-02-26 to 2026-03-17
**Commits:** `97d8cce`, `f46df83`, `2c70729`, `9961051`, `d65708a`

SSH session management was improved for reliability during automated platform tests:

- Set `OSSH_CONTROL_PATH` for sshpass and make ssh-keygen non-interactive
- Clean stale ControlMaster socket before sshpass connection
- Use `true` command instead of `-N -f` for sshpass ControlMaster
- Reopen ControlMaster with sshpass after install (group membership refresh)
- Close ControlMaster after install so dev group is active

These fixes prevent SSH session hangs and stale connections during the AlmaLinux (and all other) platform tests.

### 8f. Shared SSH Config and Deploy Key

**Date:** 2026-04-01
**Commits:** `fafbdd2`, `59d6341`, `1b5c427`, `233c62d`, `ba85e25`, `178bb0d`, `11cb876`, `8537ca9`, `4790fae`

A shared SSH configuration system was designed and implemented for multi-user Docker containers:

- Design spec and implementation plan for shared SSH config
- `ossh.config.shared.create` — creates shared SSH config at `/home/shared/.ssh/config`
- `ossh.config.shared.link` — links user SSH config to shared config
- Integration into `ossh.install` — automatically sets up shared config during install
- Execute shared SSH config setup inside container via `ossh exec`
- Copy SSH config per-user instead of symlink (robustness fix)
- Copy deploy key per-user with `~/.ssh/2cuGitHub` identity path

This enables GitHub access from inside Docker containers on all platforms, including AlmaLinux containers where multiple users need SSH access to repositories.

### 8g. Docker Socket Access for Containers

**Dates:** 2026-04-01 to 2026-04-02
**Commits:** `86744e3`, `759168f`, `420ba44`, `3ef277c`, `dda4742`, `f6327a7`, `9a39a65`, `36dda9e`, `87184ef`, `41d0c0e`

Docker-in-Docker support was added to odocker, enabling containers (including AlmaLinux) to manage other Docker containers:

- Add users to docker group for socket access
- Auto-fix Docker socket group ownership before use
- Use `sudo -n` to avoid password prompt on socket fix
- Only check socket access before build/rebuild/reset (performance)
- Suppress oosh logging during docker group setup
- Match socket GID for docker group, handle GID mismatch

### 8h. Test Suite Framework Improvements

**Dates:** 2026-02-25 to 2026-03-19
**Commits:** `edbd6be`, `d956487`, `974554a`, `55979f2`, `f692d9c`, `67acc90`, `541105a`

The test suite itself was improved to run reliably across all platforms:

- Add core/extended test categories (core tests gate promotion)
- Make `test.suite all 1` pass across host, Docker root, and Docker test user
- Use `/tmp` for test.loop temp files to fix permission denied for test user
- Fix test paths to use `$OOSH_DIR` instead of relative `./` paths
- Fix test.suite aggregation, debug toggle, and completions

These fixes directly affect AlmaLinux test runs -- the test suite must produce clean results on AlmaLinux for code to be promoted to production.

### 8i. State Machine Fixes

**Dates:** 2026-03-11 to 2026-03-23
**Commits:** `162e026`, `dbd1431`, `fd4350d`, `90cdaa4`

Critical state machine bugs were discovered and fixed during the first production promotion (which included AlmaLinux):

- Fix sparse array lookup in state machine advancement (discovered during the stage-to-prod promotion that runs AlmaLinux tests)
- Comprehensive state machine fixes across framework and consumers
- Persist state machine files + git `safe.directory` for users
- Add Darwin support for state machine and user management

The sparse array fix (`162e026`) was discovered specifically because the prod promotion path (states [21]-[26]) was unreachable -- a bug found while running AlmaLinux platform tests during the v1.0.0 release.

### 8j. Branching Strategy and Promote System

**Dates:** 2026-03-05 to 2026-03-12
**Key commits:** `8e16e6b`, `e3e09ca`, `5db7742`, `4f74c87`, `a52b9c1`, and 25+ additional commits

The entire branching strategy (dev/stage/prod) and the `promote` script with its PROMOTE state machine were built as the framework within which AlmaLinux testing operates:

- Branch strategy defined and documented: dev -> stage -> prod
- `promote` script created with 15 state machine check functions
- Stage promotion gated by core tests
- **Production promotion gated by platform tests on all must-pass platforms (including AlmaLinux)**
- Resumable pipeline -- failed promotions resume from the failing step
- Skip parameter for manual override
- `promote.status` and `promote.report` for pipeline visibility

AlmaLinux is embedded into this pipeline as an equal gate alongside Ubuntu, Debian, Alpine, and macOS. No code reaches production without passing AlmaLinux tests.

**Total promote-related commits:** 30+

---

## OOSH Core Components Affected

| File | Core (1–7) | Cross-Platform (8) |
|------|------------|---------------------|
| `init/oosh` | Bootstrap: dnf/yum, `command -v`, USER/BASH_MAJOR_VERSION | Login shell setup, brew PATH |
| `oo` | Framework: dnf/yum package manager, state machine guards | Portable `sed -i`, state machine sparse array fix, mode consistency |
| `ossh` | SSH wrapper: TTY allocation, sudo PATH, user.create | Multi-user install, ControlMaster, shared SSH config, deploy key |
| `user` | User management: wheel group, UPG handling, rm -f | Runtime useradd/adduser detection, Alpine group handling |
| `odocker` | **Entirely new** (Docker wrapper) | Docker socket access, Docker-in-Docker |
| `os` | Platform tests, platform matrix loading | Multi-user platform test flow, sshd configuration |
| `promote` | **Entirely new** (release pipeline) | State machine branching, skip parameter, status/report |
| `ng/c2` | Completion: dnf/yum, POSIX regex | — |
| `debug` | Debugger: Python3 errno, non-interactive TTY | — |
| `config` | `command -v` POSIX compatibility | Alpine sed compatibility |
| `state` | `command -v` POSIX compatibility | Sparse array fix, state machine persistence |
| `this` | `command -v` POSIX compatibility | — |
| `claudeFlow` | Install hints for dnf/yum | — |
| `otest` | venv setup for RHEL/AlmaLinux | — |
| `test.suite` | — | Core/extended categories, aggregation fix, cross-user support |
| `defaults/platforms.env` | AlmaLinux as must-pass platform | — |
| `docs/supported-platforms.md` | AlmaLinux documentation | — |
| `docs/odocker.md` | Docker wrapper documentation | Docker socket section |
| `docs/branching.md` | — | Branch strategy documentation |
| `docs/promote.md` | — | Promote script documentation |
| `docs/plans/auto-staging-pipeline.md` | Pipeline plan including AlmaLinux | Full pipeline design |
| `test/test.odocker` | Docker tests (90+ assertions) | Socket access tests |
| `test/test.os` | Platform tests (15+ assertions) | — |
| `test/test.oo` | Framework tests (git/branch fixes) | Mode consistency tests |
| `test/test.promote` | — | Promote state machine tests (14+ assertions) |
| `test/test.ossh` | — | Multi-user install tests, config tests |
