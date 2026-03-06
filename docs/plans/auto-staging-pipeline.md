# Plan: Automated Branch Staging Pipeline

**Created:** 2026-03-05
**Status:** Draft - Pending Review
**Owner:** Hannes / Marcel
**Branch:** hannes-v2 (230 commits ahead of main)

## Background

Main branch has not been updated by Hannes. All active development is on `hannes-v2`. We need a structured branching strategy and an automated pipeline that promotes code through stages (dev -> test -> prod), gated by install tests passing on all supported platforms.

## Current State

- `main` — stale
- `hannes-v2` — active development, 230+ commits ahead
- `dev`, `dev.claude` — older dev branches
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
  - **Decision:** Option B — `dev` / `test` / `prod`. `main` stays as-is (legacy).
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
  - Flow diagram: dev -> test -> prod
  - Rules for each branch (who merges, when, etc.)
  - Feature branch conventions
- [x] 1.6 Create the new branches in git: archived old `dev` → `archive/dev-old`, renamed `hannes-v2` → `dev`, created `test` and `prod` from dev HEAD
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

- [ ] 2.1 Audit current package manager support in `oo` (lines ~1420-1428):
  - `brew` (macOS)
  - `apt-get` (Ubuntu/Debian)
  - `dnf` (RHEL 8+, AlmaLinux, Fedora)
  - `yum` (RHEL 7, CentOS 7)
  - `apk` (Alpine)
- [ ] 2.2 Decide which of these are "must pass" vs "best effort":
  - [ ] Ubuntu (which versions? 22.04? 24.04?)
  - [ ] Debian (which versions?)
  - [ ] RHEL/AlmaLinux (8? 9?)
  - [ ] Alpine (which version?)
  - [ ] macOS (which versions? Intel? ARM?)
  - [ ] Bash 4 compatibility (relevant for older systems)
  - [ ] Windows/WSL (test/windows branch exists — is this supported?)
  - [ ] iSH (test/ish branch exists — iOS terminal, is this supported?)
- [ ] 2.3 For each supported platform, specify:
  - OS name and minimum version
  - Package manager
  - Bash version required
  - Docker image to use (for Linux platforms)
  - Test method (Docker, SSH, VM, CI runner)

### Implementation Steps

- [ ] 2.4 Create `config/platforms` (machine-readable) listing all platforms:
  ```bash
  # Format: name:docker_image:package_manager
  # or a shell array the staging script can source
  PLATFORMS=(
    "ubuntu-24.04:ubuntu:24.04:apt-get"
    "almalinux-9:almalinux:9:dnf"
    "alpine-3.19:alpine:3.19:apk"
    # macOS handled separately (no Docker)
  )
  ```
- [ ] 2.5 Document the matrix in `docs/supported-platforms.md`
- [ ] 2.6 Add platform info to README or link from there

### Done When

- Clear, documented list of platforms that gate promotion
- Machine-readable platform list usable by the staging script

---

## Ticket 3: Create Platform Install Test Infrastructure

**Priority:** High — the build work
**Depends on:** Ticket 2 (platform matrix)
**Estimated effort:** Medium-Large

### Goal

For each supported platform, create a reproducible environment that can:
1. Start clean (no prior oosh)
2. Install oosh from a given branch
3. Run tests
4. Report pass/fail

### 3A: Docker-based Linux Platforms

- [ ] 3.1 Create directory structure:
  ```
  docker/
    platforms/
      ubuntu-24.04/Dockerfile
      almalinux-9/Dockerfile
      alpine-3.19/Dockerfile
      ...
  ```
- [ ] 3.2 Write base Dockerfile template with:
  - [ ] Clean OS install
  - [ ] Required base packages (git, bash, curl)
  - [ ] Non-root test user (to test multi-user install)
  - [ ] No pre-installed oosh
- [ ] 3.3 Create `ubuntu-24.04/Dockerfile`:
  - [ ] FROM ubuntu:24.04
  - [ ] Install git, bash, curl, sudo
  - [ ] Create test user with sudo access
  - [ ] Verify bash version
- [ ] 3.4 Create `almalinux-9/Dockerfile`:
  - [ ] FROM almalinux:9
  - [ ] Install git, bash, curl, sudo
  - [ ] Create test user with sudo access
- [ ] 3.5 Create `alpine-3.19/Dockerfile` (if Alpine is in matrix):
  - [ ] FROM alpine:3.19
  - [ ] Install git, bash, curl, sudo
  - [ ] Create test user
- [ ] 3.6 Add additional platform Dockerfiles as per platform matrix

### 3B: Install Test Script

- [ ] 3.7 Create `docker/install-test.sh` — the script that runs inside each container:
  ```bash
  #!/usr/bin/env bash
  # Inputs: OOSH_BRANCH (branch to install from)
  # Outputs: exit 0 on success, exit 1 on failure

  # 1. Clone the repo at the specified branch
  # 2. Run the install process (oo install or init/oosh)
  # 3. Verify oosh is functional (source this, basic method calls)
  # 4. Run test.suite all 1
  # 5. Report results
  ```
- [ ] 3.8 Test the script manually on each platform:
  - [ ] Ubuntu
  - [ ] AlmaLinux
  - [ ] Alpine
- [ ] 3.9 Create `docker/run-platform-test.sh` — host-side script that:
  - [ ] Builds the Docker image for a given platform
  - [ ] Runs the container with the install test
  - [ ] Captures exit code and logs
  - [ ] Cleans up the container

### 3C: macOS Testing (if in matrix)

- [ ] 3.10 Decide macOS test approach:
  - Option A: Dedicated Mac host tested via `ossh`
  - Option B: GitHub Actions macOS runner
  - Option C: Manual testing checklist
  - **Decision:** ____________
- [ ] 3.11 Implement chosen approach
- [ ] 3.12 Document how to run macOS install test

### 3D: Integration

- [ ] 3.13 Create `docker/test-all-platforms.sh` that:
  - [ ] Reads platform matrix from `config/platforms`
  - [ ] Runs install test on each platform
  - [ ] Collects results into a summary
  - [ ] Exits 0 only if ALL platforms pass
  - [ ] Prints clear report:
    ```
    Platform Install Test Results
    ============================
    ubuntu-24.04    PASS
    almalinux-9     PASS
    alpine-3.19     FAIL (test.install failed, see logs/alpine-3.19.log)
    ```
- [ ] 3.14 Test the full pipeline end-to-end

### Done When

- Can run a single command to test install on all supported Linux platforms
- Each platform test starts clean, installs, and runs tests
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
  - Option B: Add methods to `oo` (e.g., `oo stage.test`, `oo stage.prod`)
  - Option C: `oStage` (new standalone script)
  - **Decision:** ____________

### Implementation: Core Methods

- [ ] 4.2 Create script skeleton with `source this` and method stubs
- [ ] 4.3 Implement `<script>.status`:
  - Show current state of dev, test, prod branches
  - Show commit difference between branches
  - Show last promotion date (from git tags or config)
  ```
  Branch Status
  =============
  dev  (hannes-v2)  829a74b  2026-03-05
  test              —        not yet created
  prod (main)       3768e1c  2025-xx-xx (142 commits behind dev)
  ```
- [ ] 4.4 Implement `<script>.platform.test <platform>`:
  - Run install test on a single platform
  - Uses infrastructure from Ticket 3
  - Returns pass/fail
- [ ] 4.5 Implement `<script>.platform.test.all`:
  - Run install test on all platforms in the matrix
  - Parallel execution where possible
  - Collect and display results
- [ ] 4.6 Implement `<script>.stage.test`:
  - Pre-check: current branch must be dev
  - Step 1: Run `test.suite all 1` — abort if fails
  - Step 2: Run platform install tests on all platforms — abort if any fail
  - Step 3: Merge dev into test branch (fast-forward or merge commit)
  - Step 4: Tag the test branch (e.g., `test-2026-03-05` or semver)
  - Step 5: Report success/failure
- [ ] 4.7 Implement `<script>.stage.prod`:
  - Pre-check: current branch must be test (or specify which test tag)
  - Step 1: Verify test branch has already passed all platform tests
  - Step 2: Merge test into prod
  - Step 3: Tag the prod branch (e.g., `v2.0.0`)
  - Step 4: Report success
- [ ] 4.8 Implement `<script>.report`:
  - Show last test run results per platform
  - Show promotion history

### Implementation: Completion and Help

- [ ] 4.9 Add tab completion for all methods
- [ ] 4.10 Add parameter completions:
  - `platform.test` completes platform names from matrix
  - `stage.test` / `stage.prod` no params needed
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

- Single command promotes dev -> test or test -> prod
- Promotion is gated by test suite + platform install tests
- Clear reporting of pass/fail
- Tab completion works for all methods
- Safety checks prevent accidental bad merges

---

## Ticket 5: Initial Promotion — hannes-v2 to Prod

**Priority:** Medium — first real use of the pipeline
**Depends on:** Tickets 1-4 (or can be done manually as bootstrap)
**Estimated effort:** Variable (depends on how many issues surface)

### Goal

Get the prod branch up to date with hannes-v2 for the first time. This validates the entire pipeline.

### Pre-work

- [ ] 5.1 Run `test.suite all 1` on hannes-v2 — fix any failures
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
  - `oRelease stage.test` (if test branch is in the model)
  - `oRelease stage.prod` (promote to prod)
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

- Prod branch contains all 230+ commits from hannes-v2
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
  - Trigger: PR to test or prod branch
  - Matrix strategy: one job per platform
  - Each job: build Docker image, run install test
  - Gate: PR cannot merge unless all platforms pass
- [ ] 6.3 Create `.github/workflows/promote.yml` (optional):
  - Trigger: manual dispatch or schedule
  - Runs full staging pipeline
  - Creates PR from dev -> test or test -> prod
- [ ] 6.4 Add status badges to README
- [ ] 6.5 Configure branch protection rules:
  - [ ] test branch: require CI pass before merge
  - [ ] prod branch: require CI pass + approval before merge

### Done When

- Pushing to dev automatically runs tests
- PRs to test/prod are gated by platform install tests
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

- All scripts should follow oosh conventions: `source this`, method signatures with `#` comments, tab completion
- The staging script should use `odocker` wrapper where applicable for Docker operations
- Consider using `ossh` for remote platform testing (macOS, real hardware)
- Keep install test logs for debugging failed promotions
- The pipeline should be usable manually (CLI) even if CI is added later
