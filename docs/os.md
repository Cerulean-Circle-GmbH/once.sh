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
| `os platform.test` | `<platform> <?terminal> <?notests> <?branch>` | Test oosh installation on a single platform. Pass `terminal` to open interactive session after tests, `notests` to skip Phase B, `<branch>` (a branch on origin) to install an older ref first (see [Installing an older ref first](#installing-an-older-ref-first)). Arguments are positional: an empty placeholder keeps its place, so `os platform.test ubuntu_24_04 "" notests` runs without tests and without a terminal |
| `os platform.test.all` | | Test all platforms, report summary. Exit 0 only if all must-pass platforms pass |
| `os platform.heal.test` | `<platform> <oldRef> <?breakages...:all>` | Install an old ref, break it the ways real machines are broken, heal once, check everything (see [The heal scenario](#the-heal-scenario-os-platformhealtest)). `terminal` keeps the container, `pipe` runs the pure pipe form too |

### Platform test building blocks

`os platform.test` is three private methods in a row, so a scenario test (`os platform.heal.test`, [below](#the-heal-scenario-os-platformhealtest)) can reuse any of them:

| Method | What it does |
|---|---|
| `private.os.platform.container.up <platform> <image> <port>` | steps 1-6 and the first install: a fresh container from `<image>` on ssh `<port>`, the ssh config and ControlMaster, the pushed key, `NOPASSWD` sudo for `test`, `ossh install` of `test`, then sshd and the ControlMaster settled; rc 1 when the image cannot be built |
| `private.os.platform.users.install <platform>` | Phase A for the other users: `oosh-user` through `user create`, `bash-user` through `useradd`/`adduser`, both with `NOPASSWD` sudo, then `ossh install <platform> bash-user` from the caller; failures are logged, not fatal |
| `private.os.platform.gate.run <platform> <user> <?log>` | Phase B for ONE user (`test`, `root`, `oosh-user`, `bash-user`): `test.suite gate 1` (core plus the platform invariants) through `private.os.platform.user.run`, teed into `<log>` (default `private.os.platform.gate.log.get <user> <platform>`); rc is that user's gate rc |
| `private.os.platform.user.run <platform> <user> <command> <log>` | Runs any `<command>` as one of the four users through the transport that fits (`ossh exec` for `test`, `sudo bash -lc` for `root`, `runuser` or `sudo -H -u` for the others), from the user's home, teed into `<log>`; rc is the command's. `gate.run` and the heal scenario share it |

`private.os.platform.gate.log.get <user> <platform>` echoes `/tmp/oosh-platform-test-<user>-<platform>.log` (a silent getter; `gate.run` and `platform.test` share it). `private.os.platform.socket.remove <port>` removes the stale ControlMaster socket `/tmp/ossh-test@localhost:<port>` (silent, idempotent) and is a method of its own so tests can stub it instead of deleting a live socket.

### Installing an older ref first

`os platform.test <platform> "" "" <branch>` takes a **branch on origin** of this repo. `<branch>` is exported as `OSSH_INSTALL_BRANCH` to the two install steps only (`ossh install` of `test` in `container.up`, of `bash-user` in `users.install`; a prefix assignment, so it lives for that one call). `ossh install` honours it: it pushes **that ref's own `init/oosh`** and hands the remote installer that branch ([ossh.md § Remote Installation](ossh.md#remote-installation)). macOS refuses a `<branch>` (the CI workflow installs its own branch).

Before anything starts, the era gate `private.os.platform.branch.gate <branch> <?dir>` reads `init/oosh` of the ref through `ogit.file.show` and refuses a ref whose installer lacks the `mode root` contract, i.e. older than commit `b8b90b82` (older refs use `mode ssh` and rsync, which the current `ossh install` cannot drive). It accepts only `origin/<branch>`: the container clones from origin, so a local-only branch, or a stale local branch of the same name, must not pass, and a commit sha cannot be cloned. The gate reads the remote-tracking ref of the local repo, which can be stale until the next fetch. A sha is the scenario test's job: `os platform.heal.test` pushes it as the temporary branch `platform-test-<sha>` first.

### The heal scenario (`os platform.heal.test`)

```bash
os platform.heal.test <platform> <oldRef> <?breakages...:all>
```

The proof `oo heal` needs before it touches a real machine: an OLD install, broken the ways the real machines
are broken, healed **once**, then everything that checks an install. `<platform>` is a Docker platform (a
native one is refused); `<oldRef>` is a branch on origin or a commit sha; `<breakages>` are the names below
(default and `all`: every one). The words **`terminal`** (keep the container for a look inside) and **`pipe`**
(also run the pure pipe form once) may stand among the breakages. The heal under test is **this tree**:
`OOSH_HEAL_LOCAL=1 ossh heal` ships this tree's `init/oosh` and a bundle of its branch
([ossh.md](ossh.md#healing-a-remote-host-ossh-heal)). Docker port 8022, as `platform.test`.

**The flow.**

1. Parse the arguments (`private.os.platform.heal.breakage.list.get` keeps the fixed order, rc 1 on an unknown name) and the platform.
   The tree under test must be **clean and committed**: a dirty `dev.heal` tree is refused (`ogit.status.check`,
   "commit first") before anything is pushed, because the heal ships the committed branch (`OOSH_HEAL_LOCAL=1`'s
   bundle) while the breakages and the checks are the working tree's `os`.
2. `private.os.platform.ref.branch.ensure <ref>`: a branch on origin is used as it is (one fetch on a miss);
   a commit sha of this repo that an origin branch already holds is pushed as the **flat** temporary branch
   `platform-test-<sha>` (`ogit.remote.push` with the refspec `<sha>:refs/heads/platform-test-<sha>`, so no local
   branch is made and this tree does not move). A sha in no origin branch is refused — a local-only commit never
   reaches GitHub through a test. The name is flat because the old install makes `<base>/<branch>` and `OOSH_MODE`
   of the branch name, which a slash would split. A trap on INT and TERM is set here: on Ctrl-C the temporary
   branch is dropped, the container removed and the run **exits 130**.
3. The era gate (`private.os.platform.branch.gate`) refuses a ref older than the `mode root` installer contract.
4. `private.os.platform.container.up` with `OSSH_INSTALL_BRANCH` set, then `private.os.platform.users.install`:
   `test`, `root`, `oosh-user` and `bash-user` are installed at the OLD ref.
5. The breakages, each as root in the container. A breakage that fails ends the run at once with `FAIL: heal … (breakage <name> failed — log: …)`, rc 1, before the heal: a shape that did not come about proves nothing.
6. One heal: `OOSH_HEAL_LOCAL=1 ossh heal <platform> all <branch>`. Its rc 1 is no failure (it moves broken
   canonical folders aside and says so, and reports info notes such as legacy `ssh.*` folders or a non-bash login
   shell); rc 2 or an ssh failure is. The log of the heal is read: a `FAIL <invariant> <user>:` line of its own
   verify **fails the run**; `NOT CHECKED` lines are only counted and shown as a warning. With `pipe`, the pure pipe
   form runs once more as `test` through `ossh heal.pipe` (`private.os.platform.heal.pipe.run`; [ossh.md](ossh.md#healing-a-remote-host-ossh-heal)).
7. `private.os.platform.gate.run` four times (`test`, `root`, `oosh-user`, `bash-user`), with
   `private.os.platform.shared.config.repair` after root's run.
8. The idempotence invariant (`test.suite run platform.shared.idempotence.invariant 1`) as root and as `bash-user`.
9. The second heal (`private.os.platform.heal.second.run`): a snapshot of what `oo heal` owns, `<base>/<branch>/oo heal <branch> all`
   as root (the base through root's `~/oosh`: the `oo` on root's PATH may be an older branch without `oo heal`), a snapshot again — rc 0, or rc 1 whose rc line ends in `install state 99` (reports only: `oo heal` writes it only when every step and verify is green, so a rc 1 with a step left still fails), and snapshots that differ in nothing but **same-content rewrites** (every
   `oo heal` ends in `config init.env`, which writes the shared env files again). Those rewrites are reported as a
   WARNING, exactly as the idempotence invariant accepts them: the comparison goes through the invariant's own
   helpers (`test.platform.shared.idempotence.volatile.without`, which also leaves `result.env` out, and
   `.compare` / `.unaccepted`). Any other difference fails and is printed.
10. The foreign check (`private.os.platform.heal.foreign.check`, only when `foreign.symlink` ran): `/opt/foreign`
    has the same entries and checksums and nothing newer than the marker; git's stat cache `.git/index` is
    ignored (a `git status` refreshes it without changing a byte of the tree).
11. The verdict line `PASS: heal <platform> <oldRef> (breakages=<rc> heal=<rc> verify=<n> [pipe=<rc>] test=<rc>
    root=<rc> oosh-user=<rc> bash-user=<rc> idempotence=<rc> second-heal=<rc> foreign=<rc|skipped>)` or `FAIL:` with
    the first FAIL lines of the logs. PASS needs `breakages=0`, `heal` 0 or 1 (rc ≥ 2 fails), `verify=0` (the count
    of red verify lines), `pipe` 0 when run, and 0 for every other field (`foreign` may be `skipped`). Then
    `private.os.platform.ref.branch.drop` deletes a `platform-test-*` branch on origin (as `refs/heads/<name>`, so a
    tag of the same name is left standing; any other branch is left alone) and, unless `terminal`, the container is
    removed. On PASS the logs are removed too.

**The breakages**, applied in this fixed order whatever order is typed
(`private.os.platform.heal.breakage.names.get`). Each is an idempotent POSIX sh arm run as root
(`private.os.platform.heal.breakage.script.get`): it looks first, says `already` and changes nothing when its
shape is there. The container is disposable, so an arm may delete.

| Name | What it does | Where |
|---|---|---|
| `eraB.config` | The MacStudio's era-B `~/config` (mode `mcdonges.latest`, from `test/fixtures/heal/eraB.config`), `/Users/donges` rewritten to the home | `test` |
| `root.clone` | `~/oosh` a real clone of the old ref with an `oosh.orig.<ts>`, `~/config` a real copy with `OOSH_MODE="oosh"` | `root` |
| `foreign.symlink` | `~/oosh` points to a clone outside the base (`/opt/foreign/OOSH/x`); its checksums and a marker are recorded | `bash-user` |
| `devhome.missing` | `developking`'s home removed, the user stays in `/etc/passwd` | system |
| `boot.era` | The boot-era `.bashrc` (`test/fixtures/heal/boot.era/bashrc`), the T9 drop-in `/etc/profile.d/oosh.sh` and `/etc/oosh/boot` | `oosh-user`, system |
| `no.bashrc` | `~/.bashrc` moved to `.bashrc.pre-oosh` | `root` |
| `safe.directory.stale` | Dead `safe.directory` entries (`/Users/Shared/...`) in `.gitconfig` | `root` |
| `ssh.legacy` | Legacy `ssh.original` and `ssh.<user>.<host>.for.<host>` folders | `root` |
| `state.30` | The install state machine set back to `SETUP_SERVER` 30 | `root` |
| `launcher.missing` | `/usr/local/bin/this` removed | system |
| `worktree.layout` | `<base>/testing` becomes a linked worktree at `origin/testing`, tracking it — the shape the old install left | base |
| `missing.branch` | `<base>/<branch>` removed | base |
| `diverged` | A local commit origin lacks, and an `origin/<branch>` the folder lacks | `<base>/<branch>` |
| `markers.committed` | Conflict markers committed in `this`, `log`, `oo` and `config` (the Mac's 6 Oct shape) | `<base>/<branch>` |
| `merge.conflict` | A half-done merge: `MERGE_HEAD` set, markers in `heal.conflict.txt` | `<base>/<branch>` |
| `dirty` | An uncommitted change in `os` | `<base>/<branch>` |
| `detached` | `HEAD` detached (through `update-ref`, last: a merge in progress refuses a checkout); `oosh-user`'s `~/oosh` is pointed at the broken folder, as the Mac's one user lives in it | `<base>/<branch>`, `oosh-user` |
| `user.clone` | `<base>/<branch>` rebuilt as a **healthy** clean clone of the branch, owned by `test` (group of the base, setgid, cloned as `test` from the installed tree), not trusted by root (no `safe.directory` entry); HEAD, owner and inode are recorded in `/opt/user.clone.heal.rec` — the shape `oo checkout <branch>` leaves. The heal must **keep** it: the check fails the run on a `<base>.aside/<branch>.orig.*` entry, a changed owner or HEAD, or a missing folder | `<base>/<branch>`, `test` |

**What a PASS still shows as `[left]`.** These are reports, not failures, and they stand on every heal (the second one too): root's legacy `ssh.*` folders (`ssh.backup.migrate` moves them; the heal never does), the old-format `user.env` values of a real `~/config` that are never carried over, foreign trees left untouched (`foreign.symlink`), and a canonical folder moved aside to `<base>.aside/<name>.orig.<ts>` for you to look at.

**Results so far.** ubuntu_24_04, 2026-10-07: `dev eraB.config` PASS, `dev foreign.symlink` PASS, `51d7fb3 all pipe` PASS. After the Linux gates, 2026-10-08:

| Platform | Ref | Result | What the gate taught |
|---|---|---|---|
| debian_12 | 51d7fb3 | PASS | bash 5.1 cannot parse a `{ case` with a bare pattern inside `$( … )`: `portability.validate` refuses it (`private.test.suite.case.comsub.is`) |
| almalinux_9 | 51d7fb3 | PASS | `oo heal all` heals people only: the system account `operator` (uid 11, `/sbin/nologin`, home `/root`) is `[skip]`, not healed (`private.user.account.heals.is`) |
| alpine_3_19 | 51d7fb3 | PASS | BusyBox's empty-shell PATH lacks `/usr/local/bin`: the launcher gets the link `/usr/bin/this` (`private.oo.launcher.link.get`); its `setsid` knows no `-w`, so the no-tty probe uses `setsid -w` only where it exists |
| ubuntu_24_04 | 26d15a4 | PASS | `config init.env`'s guard judges a loss by variable name over user/oosh/log `.env` and skips the never-persist names (`private.config.variable.persisted.is`: `OOSH_APT_UPDATED`, `OOSH_CLEAN_ENV`); the heal's env note carries its reason |

**The transport** (`private.os.platform.user.run`): `runuser` gets `env HOME=~<user>` (it keeps the caller's environment, so HOME would stay the ssh login's), root runs through `sudo -H`, and every command starts with `unset SUDO_USER SUDO_UID SUDO_GID SUDO_COMMAND` — `ogit.folder.finish` in the gates' fixtures trusts folders for `$SUDO_USER`, which filled the login's `.gitconfig`.

**Who moves.** Under `oo heal <branch> all` only the healer and the login that ran sudo move to `<branch>` (`private.oo.heal.user.keep.check`); `oosh-user`, `bash-user` and `developking` keep their installed branch, so a check of the scenario must not expect them on `<branch>`.

The folder arms build on one another in this order: `missing.branch` clears `<base>/<branch>`; `diverged`
clones it again from the installed tree and commits on it; `markers.committed` commits on it; `merge.conflict`
leaves a merge in progress; `dirty` changes a file the merge does not touch. `user.clone` stands apart: it rebuilds
the folder as a healthy clone owned by `test`, so it comes last, is **left out of `all`** (name it to run it) and
is refused together with `missing.branch`, `diverged`, `markers.committed`, `merge.conflict`, `dirty` or `detached`
(`private.os.platform.heal.breakage.list.get`). After the second heal `private.os.platform.heal.user.clone.check`
fails the run (`user-clone=1` in the verdict line, log step `user-clone`) when that clone was moved aside or its
owner or HEAD changed. The fixture files travel as text
inside the one script (`private.os.platform.heal.fixture.script.get`, `private.os.platform.root.script.run`).

**Logs.** `private.os.platform.heal.log.get <step> <platform>` is `/tmp/oosh-heal-test-<step>-<platform>.log` for
the steps `breakages`, `heal`, `pipe`, `test`, `root`, `oosh-user`, `bash-user`, `idempotence-root`,
`idempotence-bash-user`, `second-heal`, `foreign` and `user-clone`. They are emptied at the start and removed on PASS.

**The C2 preconditions.** The tree is clean and committed (see step 1), and `<healBranch>` — the branch of this
tree — exists on origin; else the idempotence invariant's `oo update` row is NOT CHECKED and `idempotence=1`.

**The C2 command lines** (inside the disposable containers only, never on a real host):

```bash
os platform.heal.test ubuntu_24_04 26d15a4 all pipe     # the full scenario on the first platform, pipe form included
os platform.heal.test ubuntu_24_04 51d7fb3              # all breakages, an older ref
os platform.heal.test debian_12 51d7fb3
os platform.heal.test almalinux_9 51d7fb3
os platform.heal.test alpine_3_19 51d7fb3
os platform.heal.test ubuntu_24_04 51d7fb3 all terminal  # keep the container: ossh exec.tty ubuntu_24_04 'sudo -i'
```

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
