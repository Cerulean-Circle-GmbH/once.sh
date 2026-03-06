# Plan: Automated Branch Staging Pipeline

**Created:** 2026-03-05
**Status:** Draft - Pending Review
**Owner:** Hannes / Marcel
**Branch:** dev (formerly hannes-v2)

## Background

Main branch has not been updated by Hannes. All active development is on `dev` (formerly `hannes-v2`). We need a structured branching strategy and an automated pipeline that promotes code through stages (dev -> stage -> prod), gated by install tests passing on all supported platforms.

## Current State

- `main` — stale
- `dev` — active development (renamed from `hannes-v2`)
- `stage` — staging branch (new)
- `prod` — production branch (new)
- `dev.claude` — older dev branch
- Platform test branches exist: `test/macos`, `test/ish`, `test/windows`, `stable/bash4`
- Install support: apt-get (Ubuntu/Debian), dnf/yum (RHEL/AlmaLinux), apk (Alpine), brew (macOS)
- Test suite: `test.suite all 1` with 30+ test scripts including `test.install`

---

## Ticket 1: Define and Document Branch Strategy

**Priority:** High — prerequisite for all other tickets
**Estimated effort:** Discussion + documentation (no code)

### Goal

Agree on and document which branches exist, what they mean, and how code flows between them.

### Decisions Required

- [x] 1.1 Decide branch naming:
  - Option A: `dev` / `test` / `main` (main = prod)
  - Option B: `dev` / `test` / `prod` (separate prod branch, main untouched)
  - Option C: `hannes-v2` stays as-is / `staging` / `main` (minimal rename)
  - **Decision:** Option B — `dev` / `stage` / `prod`. `main` stays as-is (legacy). (Originally `test`, renamed to `stage` to avoid conflict with `test/*` remote branches.)
- [x] 1.2 Decide what happens to current `hannes-v2`:
  - Rename to `dev`?
  - Keep as `hannes-v2` and just define it as the dev branch?
  - **Decision:** Rename `hannes-v2` → `dev`. Archive old `dev` branch first.
- [x] 1.3 Decide what happens to current `main`:
  - Becomes prod (update it via first merge)?
  - Archive as `main-legacy` and create fresh prod?
  - **Decision:** Leave `main` as-is. It has no active role; `prod` is the new production branch.
- [x] 1.4 Decide where feature branches fork from:
  - Always from dev?
  - From test for hotfixes?
  - **Decision:** Feature branches from `dev`. Hotfix branches from `prod`, merged back into both `prod` and `dev`.

### Implementation Steps

- [x] 1.5 Create `docs/branching.md` documenting:
  - Branch names and their purpose
  - Flow diagram: dev -> stage -> prod
  - Rules for each branch (who merges, when, etc.)
  - Feature branch conventions
- [x] 1.6 Create the new branches in git: archived old `dev` → `archive/dev-old`, renamed `hannes-v2` → `dev`, created `stage` and `prod` from dev HEAD
- [x] 1.7 Update hardcoded branch references: `oo` stage.to.prod now targets `prod`, worktree setup uses `dev` as base, `ossh` branch checks updated from `main` to `dev`
- [x] 1.8 Update remote tracking: pushed `dev`, `stage`, `prod` to origin with upstream tracking. Renamed `test` → `stage` to avoid conflict with existing `test/*` remote branches.
- [x] 1.9 Communicate branch strategy to all contributors — done via this session with Hannes

### Done When

- Branch strategy is documented in the repo
- All team members know which branch to work on and how promotion works

---

## Ticket 2: Define Supported Platform Matrix

**Priority:** High — prerequisite for install test infrastructure
**Estimated effort:** Research + documentation

### Goal

Nail down exactly which platforms must pass install tests before code can be promoted to prod.

### Research Steps

- [x] 2.1 Audit current package manager support in `oo` (lines ~1420-1431):
  - `brew` (macOS)
  - `apt-get` (Ubuntu/Debian)
  - `dnf` (RHEL 8+, AlmaLinux, Fedora)
  - `yum` (RHEL 7, CentOS 7)
  - `apk` (Alpine, iOS/iSH)
  - `dpkg` (Debian-based, low-level)
  - `pkg` (FreeBSD, Android/Termux)
  - `pacman` (Arch Linux)
  - Note: Windows has no package manager support yet (WSL uses Linux PM, native needs `choco`/`winget`)
- [x] 2.2 Decide which of these are "must pass" vs "best effort":
  - **Must pass (gates promotion):**
    - [x] Ubuntu 24.04 (`apt-get`)
    - [x] Debian 12 (`apt-get`)
    - [x] AlmaLinux 9 (`dnf`)
    - [x] Alpine 3.19 (`apk`)
    - [x] macOS (`brew`) — Intel + ARM
  - **Best effort (tested, doesn't block):**
    - [x] Arch Linux (`pacman`)
    - [x] FreeBSD (`pkg`)
    - [x] Android / Termux (`pkg`)
    - [x] iOS / iSH (`apk`)
    - [x] Windows / WSL (uses Linux PM)
    - [x] CentOS 7 / `yum` — legacy
  - **Not yet supported:** Windows native (`choco`/`winget`) — future work
  - **Note:** Tiers are dynamic — managed via `config/platforms` and oosh methods (see Ticket 4.9a-d)
- [x] 2.3 For each supported platform, specify:
  - OS name and minimum version
  - Package manager
  - Bash version required
  - Docker image to use (for Linux platforms)
  - Test method (Docker, SSH, VM, CI runner)
  - **Findings:**
    - oosh requires Bash 4.0 minimum (`${var^^}` in config, test.suite)
    - All Linux platforms ship Bash 4+ — no issues
    - macOS ships Bash 3.2 (GPLv3 licensing) — **install must auto-install Bash 5 via brew**
    - macOS install flow: detect macOS → ensure brew → `brew install bash` → re-exec under new bash
  - **Must pass platforms:**
    - Ubuntu 24.04 | `apt-get` | Bash 5.2 | `ubuntu:24.04` | Docker
    - Debian 12 | `apt-get` | Bash 5.2 | `debian:12` | Docker
    - AlmaLinux 9 | `dnf` | Bash 5.1 | `almalinux:9` | Docker
    - Alpine 3.19 | `apk` | Bash 5.2 | `alpine:3.19` | Docker
    - macOS | `brew` | 3.2→5.x (auto-install) | N/A | SSH / GitHub Actions / manual
  - **Best effort platforms:**
    - Arch Linux | `pacman` | Bash 5.2+ | `archlinux:latest` | Docker
    - FreeBSD | `pkg` | Bash 5.x (ports) | N/A | VM / jail
    - Android/Termux | `pkg` | Bash 5.x | N/A | Real device
    - iOS/iSH | `apk` | Bash 5.x | N/A | Real device
    - Windows/WSL | Linux PM | Bash 5.x | N/A | Real device / VM
    - CentOS 7 | `yum` | Bash 4.2 | `centos:7` | Docker

### Implementation Steps

- [x] 2.4 Create platform matrix following oosh config conventions:
  - Default platform list in repo: `defaults/platforms.env` (committed, versioned)
  - Uses `PLATFORM_*` env vars: `PLATFORM_<name>="<docker_image>:<pm>:<tier>"`
  - Per-machine overrides via `config save platforms PLATFORM` → `~/config/platforms.env`
  - Staging script loads defaults first, then overrides from config
- [x] 2.5 Document the matrix in `docs/supported-platforms.md`
- [x] 2.6 Add platform info to README — replaced outdated platform list with link to `docs/supported-platforms.md`

### Done When

- Clear, documented list of platforms that gate promotion
- Machine-readable platform list usable by the staging script

---

## Ticket 3: Create Platform Install Test Infrastructure

**Priority:** High — the build work
**Depends on:** Ticket 2 (platform matrix)
**Estimated effort:** Medium

### Goal

For each supported platform, create a reproducible environment that can:
1. Start clean (no prior oosh)
2. Install oosh from a given branch
3. Run tests
4. Report pass/fail

All Docker operations use `odocker`. Dockerfiles live in `DockerWorkspaces` (EAMD convention).

### 3A: DockerWorkspaces Setup

Existing workspaces in `$ODOCKER_WORKSPACES`:
- `nakedUbuntu/24.04` — exists, has SSH + test user
- `nakedAlma/9.sshd` — exists, has SSH + test user
- `nakedAlpine/3.13.2` — exists, but wrong version (need 3.19)

- [x] 3.1 Fix `ODOCKER_WORKSPACES` path:
  - Created symlink `/var/dev` → `/home/hannesn/WODA.2023/_var_dev`
  - Changed default in `odocker` to canonical `/var/dev/EAMD.ucp/.../DockerWorkspaces`
  - Persisted via `config set ODOCKER_WORKSPACES` in `~/config/user.env`
- [x] 3.2 Add missing workspaces to DockerWorkspaces:
  - [x] `nakedDebian/12/Dockerfile` — Debian 12 with SSH + test user
  - [x] `nakedAlpine/3.19/Dockerfile` — Alpine 3.19 with SSH + test user
- [x] 3.3 Verify existing workspaces are minimal (oosh install handles dependencies):
  - [x] `nakedUbuntu/24.04` — minimal, has SSH + sudo only. OK.
  - [x] `nakedAlma/9.sshd` — minimal, has SSH + sudo + wget. OK.
  - Decision: naked images stay minimal. oosh install must bootstrap everything.
- [ ] 3.4 Build all platform images via `odocker build`:
  - [ ] `odocker build nakedUbuntu/24.04`
  - [ ] `odocker build nakedDebian/12`
  - [ ] `odocker build nakedAlma/9.sshd`
  - [ ] `odocker build nakedAlpine/3.19`

### 3B: odocker + ossh Enhancements

Before building the install test, `odocker` and `ossh` need methods that cover the full
container lifecycle without raw commands. Analysis of existing manual workflow revealed gaps.

- [x] 3.5 Add `odocker.reset <workspace_or_image>` method:
  - Stops any container running on the SSH ports (8022 etc.)
  - Removes the stopped container
  - Clears stale SSH host key via `ossh known.hosts.remove`
  - Starts fresh container via `odocker run.sshd`
  - Reports new container name and SSH connection info
  - Tab completion for workspace/image names
  - Replaces the manual 4-line reset block
- [x] 3.6 Add `ossh.known.hosts.remove <host> <?port>` method:
  - Wraps `ssh-keygen -f ~/.ssh/known_hosts -R '[host]:port'`
  - Called by `odocker.reset` automatically
  - Defaults: host=localhost, port=8022
  - Tab completion for hosts
- [x] 3.7 Add `odocker.rebuild <workspace>` method:
  - Removes old image via `odocker rmi`
  - Rebuilds from Dockerfile via `odocker build`
  - Convenience for update-and-rebuild workflow
- [x] 3.8 Created `docs/odocker.md` with all methods, workflow examples, workspace naming convention
- [x] 3.9 Updated `docs/wiki-index.md` with links to odocker, supported-platforms, and branching docs
- [x] 3.9a Added tests for new methods to `test/test.odocker` (reset, rebuild, completions) — 37/37 pass
- [x] 3.9b Added tests for new methods to `test/test.ossh` (known.hosts.remove, completion, graceful handling) — 15/15 pass

### 3C: Install Test Script (oosh style)

Uses `odocker reset` + `ossh install` workflow — treats containers like remote servers.

- [ ] 3.10 Create oosh install test script (e.g., `oInstallTest`) with `source this`:
  - Method: `oInstallTest.run <platform>`:
    1. `odocker reset <platform_image>` — fresh container with SSH
    2. `ossh config.create <platform> test@localhost:8022` — configure SSH
    3. `ossh config.save.last` — persist SSH config
    4. `ossh push.key <platform>` — push SSH key
    5. `ossh install <platform> test` — install oosh via SSH
    6. Verify: run `test.suite all 1` on the remote container
    7. Capture results, stop container via `odocker stop` / `odocker rm`
    8. Report pass/fail using `console.log` / `error.log`
  - Method: `oInstallTest.run.all`:
    - Reads platform matrix from `defaults/platforms.env` + `~/config/platforms.env`
    - Runs install test on each platform sequentially
    - Collects results, prints summary:
      ```
      Platform Install Test Results
      ============================
      ubuntu-24.04    PASS
      almalinux-9     PASS
      alpine-3.19     FAIL (see logs)
      ```
    - Exits 0 only if all must-pass platforms pass
- [ ] 3.11 Add tab completion:
  - `oInstallTest.run` completes platform names from matrix
- [ ] 3.12 Test manually on each must-pass platform:
  - [ ] Ubuntu 24.04
  - [ ] Debian 12
  - [ ] AlmaLinux 9
  - [ ] Alpine 3.19

### 3D: macOS Testing

- [ ] 3.13 Decide macOS test approach:
  - Option A: Dedicated Mac host tested via `ossh`
  - Option B: GitHub Actions macOS runner
  - Option C: Manual testing checklist
  - **Decision:** ____________
- [ ] 3.14 Implement chosen approach
- [ ] 3.15 Document how to run macOS install test

### Done When

- `odocker reset <image>` replaces manual container reset workflow
- `oInstallTest run <platform>` tests a single platform via `odocker` + `ossh`
- `oInstallTest run.all` tests all must-pass platforms, reports results
- All Docker operations go through `odocker`, all SSH through `ossh`
- New methods documented in `docs/`
- Results are clear and actionable

---

## Ticket 4: Build Staging Script (oosh wrapper)

**Priority:** High — ties everything together
**Depends on:** Tickets 1, 2, 3
**Estimated effort:** Medium

### Goal

Create an oosh script that automates branch promotion through the pipeline, following oosh conventions (tab completion, method signatures, help).

### Design

- [ ] 4.1 Decide script name:
  - Option A: `oRelease` (new standalone script)
  - Option B: Add methods to `oo` (e.g., `oo promote.stage`, `oo promote.prod`)
  - Option C: `oStage` (new standalone script)
  - **Decision:** ____________

### Implementation: Core Methods

- [ ] 4.2 Create script skeleton with `source this` and method stubs
- [ ] 4.3 Implement `<script>.status`:
  - Show current state of dev, stage, prod branches
  - Show commit difference between branches
  - Show last promotion date (from git tags or config)
  ```
  Branch Status
  =============
  dev    8e16e6b  2026-03-06
  stage  8e16e6b  2026-03-06 (0 commits behind dev)
  prod   8e16e6b  2026-03-06 (0 commits behind stage)
  ```
- [ ] 4.4 Implement `<script>.platform.test <platform>`:
  - Delegates to `oInstallTest run <platform>` (Ticket 3)
  - Uses `odocker` for all container operations
  - Returns pass/fail
- [ ] 4.5 Implement `<script>.platform.test.all`:
  - Delegates to `oInstallTest run.all` (Ticket 3)
  - Reads platform matrix from `defaults/platforms.env` + `~/config/platforms.env`
  - Collect and display results
- [ ] 4.6 Implement `<script>.promote.stage`:
  - Pre-check: current branch must be dev
  - Step 1: Run `test.suite all 1` — abort if fails
  - Step 2: Run platform install tests on all platforms — abort if any fail
  - Step 3: Merge dev into stage branch (fast-forward or merge commit)
  - Step 4: Tag the stage branch (e.g., `stage-2026-03-06` or semver)
  - Step 5: Report success/failure
- [ ] 4.7 Implement `<script>.promote.prod`:
  - Pre-check: current branch must be stage (or specify which stage tag)
  - Step 1: Verify stage branch has already passed all platform tests
  - Step 2: Merge stage into prod
  - Step 3: Tag the prod branch (e.g., `v2.0.0`)
  - Step 4: Report success
- [ ] 4.8 Implement `<script>.report`:
  - Show last test run results per platform
  - Show promotion history
- [ ] 4.9a Implement `<script>.platform.list`:
  - Show all platforms with their tier (must-pass / best-effort)
- [ ] 4.9b Implement `<script>.platform.tier <platform> <must-pass|best-effort>`:
  - Move a platform between tiers
  - Updates via `config save platforms PLATFORM` → `~/config/platforms.env`
- [ ] 4.9c Implement `<script>.platform.add <name> <docker_image> <package_manager> <tier>`:
  - Add a new platform to the matrix
- [ ] 4.9d Implement `<script>.platform.remove <platform>`:
  - Remove a platform from the matrix

### Implementation: Completion and Help

- [ ] 4.9 Add tab completion for all methods
- [ ] 4.10 Add parameter completions:
  - `platform.test` completes platform names from matrix
  - `promote.stage` / `promote.prod` no params needed
- [ ] 4.11 Add help text to method signatures (the `# comment` convention)

### Implementation: Safety

- [ ] 4.12 Add dry-run mode (`--dry-run` or `--check`):
  - Shows what would happen without actually merging
  - Runs tests but skips the merge step
- [ ] 4.13 Add confirmation prompt before merge:
  - Show diff stats
  - Show platform test results
  - Require explicit "yes" to proceed
- [ ] 4.14 Prevent staging if there are uncommitted changes
- [ ] 4.15 Create git tags for each promotion for rollback tracking

### Testing

- [ ] 4.16 Write `test/test.oRelease` (or equivalent):
  - Test status output
  - Test platform test invocation
  - Test merge logic (using temp branches)
- [ ] 4.17 Add to `test.suite` discovery
- [ ] 4.18 Run full test suite including new tests

### Done When

- Single command promotes dev -> stage or stage -> prod
- Promotion is gated by test suite + platform install tests
- Clear reporting of pass/fail
- Tab completion works for all methods
- Safety checks prevent accidental bad merges

---

## Ticket 5: Initial Promotion — dev to Prod

**Priority:** Medium — first real use of the pipeline
**Depends on:** Tickets 1-4 (or can be done manually as bootstrap)
**Estimated effort:** Variable (depends on how many issues surface)

### Goal

Get the prod branch up to date with dev for the first time. This validates the entire pipeline.

### Pre-work

- [ ] 5.1 Run `test.suite all 1` on dev — fix any failures
  - Current test count: ~305 assertions
  - All must pass
- [ ] 5.2 Run install test on each platform — fix any failures:
  - [ ] Ubuntu 24.04
  - [ ] AlmaLinux 9
  - [ ] Alpine (if in matrix)
  - [ ] macOS (if in matrix)
- [ ] 5.3 Fix any install issues discovered during platform testing
- [ ] 5.4 Re-run full platform test suite after fixes

### Promotion

- [ ] 5.5 Use staging script (Ticket 4) or manual merge:
  - `<script> promote.stage` (promote dev to stage)
  - `<script> promote.prod` (promote stage to prod)
- [ ] 5.6 Tag the release:
  - [ ] Choose version scheme (semver? date-based?)
  - [ ] Create tag (e.g., `v2.0.0` or `2026-03-xx`)
- [ ] 5.7 Verify prod branch is correct:
  - [ ] `test.suite all 1` passes on prod branch
  - [ ] Install from prod branch works on at least one platform
- [ ] 5.8 Push prod branch and tags to origin

### Post-merge

- [ ] 5.9 Update README if it references specific branches
- [ ] 5.10 Notify team that prod is updated
- [ ] 5.11 Archive or clean up stale branches if needed

### Done When

- Prod branch contains all commits from dev
- Install verified on all supported platforms
- Tagged release exists
- Team notified

---

## Ticket 6: CI Integration (Future)

**Priority:** Low — enhancement after manual pipeline works
**Depends on:** Ticket 4
**Estimated effort:** Medium

### Goal

Automate the staging pipeline via CI (GitHub Actions or similar) so tests run automatically on push/PR.

### Steps

- [ ] 6.1 Create `.github/workflows/test.yml`:
  - Trigger: push to dev branch
  - Job: run `test.suite all 1`
  - Report: pass/fail status check
- [ ] 6.2 Create `.github/workflows/platform-install.yml`:
  - Trigger: PR to stage or prod branch
  - Matrix strategy: one job per platform
  - Each job: build Docker image, run install test
  - Gate: PR cannot merge unless all platforms pass
- [ ] 6.3 Create `.github/workflows/promote.yml` (optional):
  - Trigger: manual dispatch or schedule
  - Runs full staging pipeline
  - Creates PR from dev -> stage or stage -> prod
- [ ] 6.4 Add status badges to README
- [ ] 6.5 Configure branch protection rules:
  - [ ] stage branch: require CI pass before merge
  - [ ] prod branch: require CI pass + approval before merge

### Done When

- Pushing to dev automatically runs tests
- PRs to stage/prod are gated by platform install tests
- Branch protection prevents unvalidated merges

---

## Execution Order

```
Ticket 1 ─────┐
               ├──> Ticket 3 ──> Ticket 4 ──> Ticket 5 ──> Ticket 6
Ticket 2 ─────┘
```

Tickets 1 and 2 can be done in parallel (decisions + documentation).
Ticket 3 depends on the platform matrix from Ticket 2.
Ticket 4 depends on all three preceding tickets.
Ticket 5 is the first real validation.
Ticket 6 is a future enhancement.

---

## Notes

- All scripts follow oosh conventions: `source this`, method signatures with `#` comments, tab completion
- All Docker operations use `odocker` — never raw `docker` commands in oosh scripts
- Dockerfiles live in `DockerWorkspaces` (EAMD convention), not in the oosh repo
- Use `ossh` for remote platform testing (macOS, real hardware)
- Use `config save/get/set` for persistent configuration (oosh config convention)
- Keep install test logs for debugging failed promotions
- The pipeline should be usable manually (CLI) even if CI is added later
