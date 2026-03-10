# Plan: Automated Branch Staging Pipeline

**Created:** 2026-03-05
**Status:** In Progress — Tickets 1-3 done, Ticket 4 next
**Last Updated:** 2026-03-10
**Owner:** Hannes / Marcel
**Branch:** dev (formerly hannes-v2)

## Background

Main branch has not been updated by Hannes. All active development is on `dev` (formerly `hannes-v2`). We need a structured branching strategy and an automated pipeline that promotes code through stages (dev -> stage -> prod), gated by install tests passing on all supported platforms.

## Current State

- `main` — stale
- `dev` — active development (renamed from `hannes-v2`)
- `stage` — staging branch (new)
- `prod` — production branch (new)
- `dev.claude` — **merged into `dev`** on 2026-03-10 (58 commits: backup, claudeCode, hiveMind, otmux improvements)
- Platform test branches exist: `test/macos`, `test/ish`, `test/windows`, `stable/bash4` — likely obsolete, candidates for deletion
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
  - **Decision:** `dev` / `stage` / `prod`. `main` stays as-is (legacy). Originally considered `test` instead of `stage`, renamed to avoid conflict with `test/*` remote branches.
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
- [x] 3.4 Build all platform images via `odocker build`:
  - [x] `odocker build nakedUbuntu/24.04` — 218MB
  - [x] `odocker build nakedDebian/12` — 172MB
  - [x] `odocker build nakedAlma/9.sshd` — 229MB
  - [x] `odocker build nakedAlpine/3.19` — 15.7MB

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
- [x] 3.9a Added tests for new methods to `test/test.odocker` (reset, rebuild, completions)
- [x] 3.9b Added tests for new methods to `test/test.ossh` (known.hosts.remove, completion, graceful handling)
- [x] 3.9c Strengthened workspace tests in `test/test.odocker`:
  - `ODOCKER_WORKSPACES` resolves to an existing directory
  - All must-pass platform Dockerfiles exist (nakedUbuntu/24.04, nakedDebian/12, nakedAlma/9.sshd, nakedAlpine/3.19)
  - Image name derivation verified for all must-pass platforms
  - Workspace completion now fails (not silently passes) when workspaces are missing

### 3C: Platform Install Test Methods in `os`

**Design decision:** Platform testing belongs in `os` — the OS/platform script. `os` already
exists with OS detection methods (`os.check`, `os.check.env`, `os.info`). Platform testing
extends this existing responsibility. The oosh philosophy is "a script can call a script" —
each script is a class with single responsibility. OS/platform concerns live in `os`, not
in `oo` (the lifecycle manager). Existing patterns confirm this: `ossh` sources `os` for
OS-specific method resolution, `user` calls `os.check` for platform-specific getters.

The delegation chain: `oo promote.stage` → `os platform.test.all` → `odocker` + `ossh`
(all via CLI calls, the script-calls-script pattern).

Uses `odocker reset` + `ossh install` workflow — treats containers like remote servers.

- [x] 3.10 Add `os.platform.test <platform>` method to `os`:
  - Reads platform config from `defaults/platforms.env` + `~/config/platforms.env`
  - Resolves platform name to Docker image and workspace
  - Private helpers:
    - `private.os.platform.load` — loads platform config (defaults + overrides)
    - `private.os.platform.parse` — parses `PLATFORM_*` env vars into fields
    - `private.os.platform.names` — returns list of platform names
    - `private.os.platform.image.from.workspace` — derives image tag from workspace path
    - `private.os.platform.cleanup` — stops/removes container by SSH port
  - Steps:
    1. `odocker reset <image>` — fresh container with SSH
    2. `ossh config.create <platform> test@localhost:8022` — configure SSH
    3. `ossh config.save.last` — persist SSH config
    4. `ossh push.key <platform>` — push SSH key
    5. `ossh install <platform> test` — install oosh via SSH
    6. `ossh exec <platform> "test.suite all 1"` — run tests remotely
    7. Capture results, cleanup container via `private.os.platform.cleanup`
    8. Report pass/fail using `console.log` / `error.log`
  - Completion: `os.platform.test.completion.platform()` — lists platform names from matrix
  - Also updated `defaults/platforms.env` format to include workspace field
- [x] 3.11 Add `os.platform.test.all` method to `os`:
  - Reads platform matrix from `defaults/platforms.env` + `~/config/platforms.env`
  - Runs `os.platform.test` on each platform sequentially
  - Skips native platforms automatically
  - Collects results, prints summary table
  - Exits 0 only if all must-pass platforms pass; best-effort failures don't block
- [x] 3.12 Add `os.platform.list` method to `os`:
  - Reads platform matrix, displays formatted table with PLATFORM, WORKSPACE, PM, TIER columns
- [x] 3.13 Add platform tests to `test/test.os`:
  - Test `private.os.platform.load` config loading
  - Test `private.os.platform.names` name listing (verifies all must-pass platforms)
  - Test `private.os.platform.parse` field extraction (ubuntu, alpine, macos, unknown)
  - Test `private.os.platform.image.from.workspace` (matches odocker logic)
  - Test `os platform.list` runs without error
  - Test `os platform.test` requires parameter
  - Test `os platform.test macos` skips native
  - Test completion function exists
  - Fixed pre-existing test failure (old test passed log level as method name)
  - Added `TEST_CATEGORY=core` and missing `test.suite.save.results`
  - All 15 assertions pass, `test.suite core 1` passes (223/223 + 1 intentional meta-test)
- [x] 3.14 Test manually on each must-pass platform:
  - Prerequisite fixes applied: odocker snake_case→camelCase, port-passing bug fixed, os uses root SSH
  - All 4 platforms pass 218/219 assertions (1 intentional meta-test failure)
  - Verified 2026-03-10 after dev.claude merge
  - [x] Ubuntu 24.04
  - [x] Debian 12
  - [x] AlmaLinux 9
  - [x] Alpine 3.19

### 3D: macOS Testing

- [ ] 3.15 Decide macOS test approach:
  - Option A: Dedicated Mac host tested via `ossh`
  - Option B: GitHub Actions macOS runner
  - Option C: Manual testing checklist
  - **Decision:** ____________
- [ ] 3.16 Implement chosen approach
- [ ] 3.17 Document how to run macOS install test

### Done When

- `odocker reset <image>` replaces manual container reset workflow
- `os platform.test <platform>` tests a single platform via `odocker` + `ossh`
- `os platform.test.all` tests all must-pass platforms, reports results
- All Docker operations go through `odocker`, all SSH through `ossh`
- Methods follow oosh conventions: signatures, completion, help
- Platform tests in `test/test.os`
- Results are clear and actionable

---

## Ticket 4: Release Pipeline in `oo` with PROMOTE State Machine

**Priority:** High — ties everything together
**Depends on:** Tickets 1, 2, 3
**Estimated effort:** Medium

### Goal

Add promotion methods to `oo` (the framework lifecycle manager) backed by a `PROMOTE`
state machine. No new script — `oo` already owns create, update, commit, release.

### Design Decision

- [x] 4.1 Decide where methods live:
  - ~~Option A: `oRelease` (new standalone script)~~
  - **Option B: Add methods to `oo`** — `oo promote.stage`, `oo promote.prod`, etc.
  - ~~Option C: `oStage` (new standalone script)~~
  - **Decision:** Option B. `oo` is the lifecycle manager. Release/promote is lifecycle.
    The existing `oo.release` and `oo.stage.to.prod` are already in `oo`.
    Platform methods live in `os` (the OS/platform script), promote methods in `oo`.
    `oo` delegates to `os` for platform testing via CLI (script-calls-script pattern).

### PROMOTE State Machine Design

The promotion pipeline uses the oosh `state` machine framework — the same system
used by `SETUP_SERVER` in `oo`. Multiple state machines coexist independently.
Each lives in its own file (`$CONFIG_PATH/stateMachines/PROMOTE.states.env`).
The `state of PROMOTE` selector is temporary — no conflict with other machines.

**Machine: PROMOTE**

Created by `private.init.promote.state.machine` in `oo`, following the same pattern
as `private.init.state.machine` for `SETUP_SERVER`.

```
Standard template states (from state.machine.create):
[0]  not.installed
[1]  initialized
[2]  setup
[3]  all.states.added
[4]  started
[5]  = 11                         # transition → first custom state

Custom states:
[11] promote.started              # PROMOTE_TARGET set (stage or prod)
[12] target.checked               # Validates source branch, branches:
                                  #   stage → [20], prod → [30]

Stage promotion path (dev → stage):
[20] uncommitted.checked          # No dirty working tree
[21] test.suite.passed            # test.suite all 1 passes
[22] platform.tests.passed        # All must-pass platforms pass
[23] confirmation.received        # User confirms merge (diff stats shown)
[24] merged.to.stage              # git merge dev into stage
[25] stage.tagged                 # Tag: stage-YYYY-MM-DD
[26] stage.pushed                 # git push origin stage + tags
[27] = 99                         # transition → finished

Prod promotion path (stage → prod):
[30] stage.verified               # Stage has passed all tests
[31] confirmation.received.prod   # User confirms merge
[32] merged.to.prod               # git merge stage into prod
[33] prod.tagged                  # Tag: vX.Y.Z (semver)
[34] prod.pushed                  # git push origin prod + tags
[35] = 99                         # transition → finished

[99]  finished
[100] = 6                         # transition → cleanup
```

**Branching logic** (in `private.check.target.checked`):
- `PROMOTE_TARGET=stage` → return state ID `20` (stage path)
- `PROMOTE_TARGET=prod` → return state ID `30` (prod path)
- This uses the state machine's native branching — same pattern as
  `private.check.priviledges.checked` in `SETUP_SERVER`.

**Resumability:**
Each `state.next` advances the state and calls `private.check.<stateName>()`.
If a check fails (e.g., platform tests fail at [22]), the machine stays at [22].
Next time `oo promote.stage` runs, it detects the machine at [22] and resumes.
This avoids re-running slow platform tests that already passed.

```bash
# First run — platform tests fail at [22]:
oo promote.stage
# ✓ [20] uncommitted.checked
# ✓ [21] test.suite.passed
# ✗ [22] platform.tests.passed — Alpine failed

# Fix the Alpine issue, run again:
oo promote.stage
# Resumes at [22]:
# ✓ [22] platform.tests.passed
# ✓ [23] confirmation.received
# ✓ [24] merged.to.stage
# ...
# ✓ [99] finished

# Force fresh start:
oo promote.stage reset
```

### Implementation: State Machine Setup

- [ ] 4.2 Add `private.init.promote.state.machine` to `oo`:
  - Creates PROMOTE machine with `state.machine.create PROMOTE oo`
  - Adds all custom states via `state.add`
  - Follows same pattern as `private.init.state.machine` for SETUP_SERVER
- [ ] 4.3 Add `private.check.*` functions to `oo` for each state:
  - `private.check.promote.started` — verify PROMOTE_TARGET is set
  - `private.check.target.checked` — validate source branch, return branch state ID
  - `private.check.uncommitted.checked` — `git status --porcelain` is empty
  - `private.check.test.suite.passed` — run `test.suite all 1`, gate on result
  - `private.check.platform.tests.passed` — run `os platform.test.all` (delegates to `os`), gate on result
  - `private.check.confirmation.received` — show diff stats, prompt yes/no
  - `private.check.merged.to.stage` — `git checkout stage && git merge dev`
  - `private.check.stage.tagged` — `git tag stage-$(date +%Y-%m-%d)`
  - `private.check.stage.pushed` — `git push origin stage --tags`
  - `private.check.stage.verified` — verify stage passed (check tag or config)
  - `private.check.confirmation.received.prod` — show diff stats, prompt yes/no
  - `private.check.merged.to.prod` — `git checkout prod && git merge stage`
  - `private.check.prod.tagged` — prompt for version, `git tag vX.Y.Z`
  - `private.check.prod.pushed` — `git push origin prod --tags`

### Implementation: Public Methods

- [ ] 4.4 Add `oo.promote.stage` method:
  - Creates PROMOTE machine if not exists
  - Sets `PROMOTE_TARGET=stage`
  - If machine is finished or on prod path → reset to [11]
  - If machine is on stage path → resume from current state
  - If `reset` argument → always reset to [11]
  - Loops `state.next` until finished or failure
- [ ] 4.5 Add `oo.promote.prod` method:
  - Same pattern as promote.stage but `PROMOTE_TARGET=prod`
- [ ] 4.6 Update existing `oo.release`:
  - Currently calls `oo.stage.to.prod` directly
  - Update to call `oo.promote.stage` (release = promote to stage)
  - Keep as convenience alias
- [ ] 4.7 Update existing `oo.stage.to.prod`:
  - Currently does raw commit + merge + push
  - Update to call `oo.promote.prod`
  - Keep for backward compatibility
- [ ] 4.8 Add `oo.promote.status` method:
  - Show current PROMOTE machine state
  - Show dev/stage/prod branch status and commit differences:
    ```
    PROMOTE state: [22] platform.tests.passed (in progress)

    Branch Status
    =============
    dev    8e16e6b  2026-03-06
    stage  8e16e6b  2026-03-06 (0 commits behind dev)
    prod   8e16e6b  2026-03-06 (0 commits behind stage)
    ```
- [ ] 4.9 Add `oo.promote.report` method:
  - Show last test run results per platform
  - Show promotion history (from git tags)

### Implementation: Platform Management Methods (in `os`)

Platform management is an OS concern — these methods live in `os`, not `oo`.

- [ ] 4.10a Add `os.platform.list`:
  - Show all platforms with their tier (must-pass / best-effort)
- [ ] 4.10b Add `os.platform.tier <platform> <tier>`:
  - Move a platform between tiers (must-pass / best-effort)
  - Updates via `config save platforms PLATFORM` → `~/config/platforms.env`
- [ ] 4.10c Add `os.platform.add <name> <dockerImage> <packageManager> <tier>`:
  - Add a new platform to the matrix
- [ ] 4.10d Add `os.platform.remove <platform>`:
  - Remove a platform from the matrix

### Implementation: Completion and Help

- [ ] 4.11 Add tab completion for all new methods:
  - In `oo`: `oo.promote.stage.completion` — no params (or `reset`)
  - In `oo`: `oo.promote.prod.completion` — no params (or `reset`)
  - In `os`: `os.platform.test.completion.platform` — platform names from matrix
  - In `os`: `os.platform.tier.completion.platform` — platform names
  - In `os`: `os.platform.tier.completion.tier` — `must-pass` / `best-effort`
- [ ] 4.12 All methods have `# <param> # description` doc comments

### Testing

- [ ] 4.13 Add tests:
  - In `test/test.os` — platform tests:
    - Test `os.platform.list` output
    - Test `os.platform.test` argument handling
    - Test `os.platform.tier` tier changes
    - Test `os.platform.add` / `os.platform.remove`
  - In `test/test.oo` — promote/state tests:
    - Test `oo.promote.status` output
    - Test PROMOTE state machine creation
    - Test `private.check.*` functions individually
    - Test merge logic using temp branches (isolated)
- [ ] 4.14 Run full `test.suite all 1` including new tests

### Done When

- `oo promote.stage` promotes dev → stage, gated by tests + platform tests
- `oo promote.prod` promotes stage → prod, gated by verification
- PROMOTE state machine tracks progress and enables resume after failure
- `oo promote.status` shows pipeline state and branch diffs
- `os platform.test <platform>` tests a single platform end-to-end
- `os platform.list` shows platform matrix with tiers
- `os platform.tier/add/remove` manage the platform matrix
- All methods have tab completion and help text
- Platform tests in `test/test.os`, promote/state tests in `test/test.oo`
- Existing `oo release` and `oo stage.to.prod` updated as wrappers

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
- [ ] 5.2 Run `os platform.test` on each platform — fix any failures:
  - [ ] Ubuntu 24.04
  - [ ] Debian 12
  - [ ] AlmaLinux 9
  - [ ] Alpine 3.19
- [ ] 5.3 Fix any install issues discovered during platform testing
- [ ] 5.4 Re-run `os platform.test.all` after fixes

### Promotion

- [ ] 5.5 Promote using the pipeline:
  - `oo promote.stage` (promote dev to stage)
  - `oo promote.prod` (promote stage to prod)
- [ ] 5.6 Tag the release:
  - [ ] Choose version scheme (semver? date-based?)
  - [ ] Tag applied automatically by PROMOTE state machine
- [ ] 5.7 Verify prod branch is correct:
  - [ ] `test.suite all 1` passes on prod branch
  - [ ] Install from prod branch works on at least one platform
- [ ] 5.8 Push prod branch and tags to origin (done by state machine)

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
  - Runs full staging pipeline via `oo promote.stage` / `oo promote.prod`
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

- Platform methods live in `os` — the OS/platform script. `oo` delegates to `os` for platform testing (script-calls-script pattern).
- The `os` script already provides OS detection (`os.check`, `os.check.env`) — platform testing extends this existing responsibility
- Promote/lifecycle methods live in `oo` — the framework lifecycle manager
- All methods follow oosh conventions: `source this`, method signatures with `#` comments, tab completion
- All Docker operations use `odocker` — never raw `docker` commands
- All SSH operations use `ossh` — never raw `ssh` commands
- Dockerfiles live in `DockerWorkspaces` (EAMD convention), not in the oosh repo
- Use `ossh` for remote platform testing (macOS, real hardware)
- Use `config save/get/set` for persistent configuration (oosh config convention)
- PROMOTE state machine follows the same pattern as SETUP_SERVER in `oo`
- The pipeline is resumable — failed promotions resume from the failing step
- The pipeline should be usable manually (CLI) even if CI is added later
