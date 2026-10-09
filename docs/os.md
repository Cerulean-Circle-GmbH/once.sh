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
| `os platform.heal.test` | `<platform> <oldRef> <?breakages...:all>` | Install an old ref, break it the ways real machines are broken, heal once, check everything (see [The heal scenario](#the-heal-scenario-os-platformhealtest)). `terminal` keeps the container, `pipe` runs the pure pipe form too, `compare` diffs the healed machine with a fresh install of the branch |

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

Without `<branch>` the containers install the branch of this tree **from origin** — a branch that is not pushed, or is pushed behind the local one, is not what runs. `OSSH_INSTALL_LOCAL=1 os platform.test <platform>` installs this tree instead: the working-tree `init/oosh` and a bundle of the committed branch ([ossh.md § Installing this tree](ossh.md#installing-this-tree-ossh_install_local1)).

Before anything starts, the era gate `private.os.platform.branch.gate <branch> <?dir>` reads `init/oosh` of the ref through `ogit.file.show` and refuses a ref whose installer lacks the `mode root` contract, i.e. older than commit `b8b90b82` (older refs use `mode ssh` and rsync, which the current `ossh install` cannot drive). It accepts only `origin/<branch>`: the container clones from origin, so a local-only branch, or a stale local branch of the same name, must not pass, and a commit sha cannot be cloned. The gate reads the remote-tracking ref of the local repo, which can be stale until the next fetch. A sha is the scenario test's job: `os platform.heal.test` pushes it as the temporary branch `platform-test-<sha>` first.

### The heal scenario (`os platform.heal.test`)

```bash
os platform.heal.test <platform> <oldRef> <?breakages...:all>
```

The proof `oo heal` needs before it touches a real machine: an OLD install, broken the ways the real machines
are broken, healed **once**, then everything that checks an install. `<platform>` is a Docker platform (a
native one is refused); `<oldRef>` is a branch on origin or a commit sha; `<breakages>` are the names below
(default and `all`: every one). The words **`terminal`** (keep the container for a look inside), **`compare`** (step 11) and **`pipe`**
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
   `<oldRef>` must not be the branch under test: an install of the heal's own branch would be healed by the same code and prove nothing (rc 1, "give an older ref").
3. The era gate (`private.os.platform.branch.gate`) refuses a ref older than the `mode root` installer contract.
4. `private.os.platform.container.up` with `OSSH_INSTALL_BRANCH` set, then `private.os.platform.users.install`:
   `test`, `root`, `oosh-user` and `bash-user` are installed at the OLD ref.
5. The breakages, each as root in the container. A breakage that fails ends the run at once with `FAIL: heal … (breakage <name> failed — log: …)`, rc 1, before the heal: a shape that did not come about proves nothing.
6. One heal: `OOSH_HEAL_LOCAL=1 ossh heal <platform> all <branch>`. Its rc 1 is no failure when it is reports only
   (it moves broken canonical folders aside and says so, and reports info notes such as legacy `ssh.*` folders or a
   non-bash login shell): the rc line ends in `install state 99`, read by `private.os.platform.heal.reports.only.is`,
   the same predicate the second heal uses. Any other rc 1, rc 2 or an ssh failure fails. The log of the heal is read:
   a `FAIL <invariant> <user>:` line of its own verify **fails the run**, and so does a `NOT CHECKED` line unless its
   reason is the re-login that group `dev` needs (`group dev takes effect after a re-login`, shown as a warning); the
   count of the others is the `not-checked` field of the verdict.
   **The expect check** runs right after it: `private.os.platform.heal.check <platform> expect <branch> <breakages>`,
   see **The checks** below. With `pipe`, the pure pipe form runs once more as `test` through `ossh heal.pipe`
   (`private.os.platform.heal.pipe.run`; [ossh.md](ossh.md#healing-a-remote-host-ossh-heal)).
7. `private.os.platform.gate.run` four times (`test`, `root`, `oosh-user`, `bash-user`), with
   `private.os.platform.shared.config.repair` after root's run.
8. The idempotence invariant (`test.suite run platform.shared.idempotence.invariant 1`) as root and as `bash-user`.
9. The second heal (`private.os.platform.heal.second.run`): a snapshot of what `oo heal` owns, the command of
   `private.os.platform.heal.second.command.get <branch>` as root (`<base>/<branch>/oo heal <branch> all`, the base
   through the `~/oosh` of root: the `oo` on the PATH of root may be an older branch without `oo heal`), a snapshot again — rc 0, or rc 1 reports only (the first heal's reading), and snapshots that differ in nothing but **same-content rewrites of the shared env files**. The snapshot holds the entries of `<base>`, `<base>/main` and `<base>/<branch>`, the `*.env` files of the sharedConfig, its `stateMachines/*` files by content only (the heal writes the machine file again on every green run, the same bytes), the number of entries of `<base>.aside` (a heal that moves a folder aside on every run adds one each time), the launcher and drop-in, and the homes of the five users. Every `oo heal` ends in `config init.env`, which writes the shared env files again; a rewrite of a `*.env` file of the sharedConfig or of `~/.config/oosh` is reported as a WARNING, exactly as the idempotence invariant accepts it, through the `<?pathGlob>` of `test.platform.shared.idempotence.unaccepted rewritten` (`*/sharedConfig/*.env|*/.config/oosh/*.env`). A rewrite of anything else, a folder cloned again among it, is a change. The comparison goes through the invariant's own helpers (`volatile.without`, which also leaves `result.env` out, `.compare` and `.unaccepted`). Any other difference fails and is printed.
10. The foreign check (`private.os.platform.heal.check <platform> foreign`, only when `foreign.symlink` ran): `/opt/foreign`
    has the same entries and checksums and nothing newer than the marker; git's stat cache `.git/index` is
    ignored (a `git status` refreshes it without changing a byte of the tree).
11. **The compare step** (with the word `compare`, after every check above passed — else `compare=skipped`): `private.os.platform.heal.compare.run <platform> <branch>` installs the same branch **fresh** in a second container (port `private.os.platform.heal.compare.port.get`, 9022; ssh alias `<platform>_fresh`; `container.up` and `users.install` with `OSSH_INSTALL_LOCAL=1`, so the unpushed branch installs from this tree), reads both through `private.os.platform.heal.compare.snapshot.take` (the script of `private.os.platform.heal.compare.snapshot.script.get <branch>` as root) — the healed machine right after the heal, with the expect check, before the gates write into it (log step `compare-healed`), the fresh one right after its install — owner, group, mode and content of what the install and the heal own (links, the values of env files, `.gitconfig`, `.once` and ssh config, checksums of files; generated ssh keys named, the deploy key summed), the base itself, and the origin, branch and HEAD of `main/` and `<branch>/` (another folder of the base is what a user or an old install kept, no install shape), the `safe.directory` set of the system and of each user, each user's shell and groups — with the host name and the alias masked, and leaves out what the idempotence invariant leaves out (log files, `result.env`). What the heal keeps by the owner's rule — `<base>.aside` entries, `*.orig.*` copies, another folder of the base and a trust entry naming one — is printed as `kept by the heal: <path>` and counted (`kept=<n>` in the verdict line), never a failure. A difference on the list of `private.os.platform.heal.compare.known.get` (a pattern and its reason: the PATH the install writes into a user's `user.session.env`, a dev bug followed up separately; the owner of the base an old install made) prints as `WARN compare: known: …` and does not fail; **any other line that differs fails** (`compare=1`, the lines in the log step `compare`). The compare installs the commit the heal shipped: a branch that moved since the heal is refused, so commit nothing while a run runs. The second container is always removed. It runs before the user.clone second pass, which rebuilds `<base>/<branch>`.
12. **The user.clone second pass.** `user.clone` rebuilds `<base>/<branch>` and is left out of `all`. When the other
    steps all passed and `user.clone` was not named, the run applies it on the healed machine, runs the second-heal
    command once more and checks the clone (`private.os.platform.heal.check <platform> user.clone <branch>`); a failed
    arm, a heal that is not rc 0 or reports only, or a red check fails the run (`user-clone=1`). A run of named breakages has no second pass.
13. The verdict line `PASS: heal <platform> <oldRef> (heal=<rc> verify=<n> not-checked=<n> [pipe=<rc>] expect=<rc> test=<rc>
    root=<rc> oosh-user=<rc> bash-user=<rc> idempotence=<rc> second-heal=<rc> foreign=<rc|skipped> [compare=<rc|skipped> kept=<n>] [user-clone=<rc>])` or `FAIL:` with
    the first FAIL lines of the logs and the folder of the logs. PASS needs `heal` 0, or 1 as reports only (rc ≥ 2 and any other rc 1 fail),
    `verify=0` (the count of red verify lines), `not-checked=0` (the NOT CHECKED lines whose reason is not the re-login),
    `pipe`, `compare` and `user-clone` 0 when run, and 0 for every other field (`foreign` may be `skipped`). Then
    `private.os.platform.ref.branch.drop` deletes a `platform-test-*` branch on origin (as `refs/heads/<name>`, so a
    tag of the same name is left standing; any other branch is left alone) and, unless `terminal`, the container is
    removed. On PASS the folder of the logs is removed too. A breakage that fails ends the run before the heal with its own `FAIL` line.

**The breakages**, applied in this fixed order whatever order is typed
(`private.os.platform.heal.breakage.names.get`). Each is an idempotent POSIX sh arm run as root
(`private.os.platform.heal.breakage.script.get`): it looks first, says `already` and changes nothing when its
shape is there. The container is disposable, so an arm may delete.

**The arm prelude** (`private.os.platform.heal.remote.preamble.get`): every arm, check and snapshot starts with
the same POSIX sh text, so no arm carries its own copy of these helpers:

- `say` / `fail` — the arm's line, and its exit 1;
- `rgit` — git with `safe.directory=*` and a test identity for this call only;
- `home_of <user>` — the home from `/etc/passwd`;
- `as_user <user> <cmd...>` — the transport of `private.os.platform.user.run` from inside the root script: `runuser` with the HOME of the user, else `sudo -H -u` (busybox has no `runuser`); its stdin is closed, so a command run as a user never reads the rest of the script;
- `owner_of`, `gid_of`, `inode_of <path>` — GNU `stat`, else its BSD twin, the one place the arms read these;
- `move_aside <path> <tag>` — a link is removed, anything else is moved to `<path>.before-<tag>`;
- `installed`, `clone_installed <dir> <branch>`, `branch_dir_ensure` — the installed tree of `test`, a clone of it, the canonical folder `<base>/<branch>` as such a clone;
- `foreign_sums` — the entries and checksums of `/opt/foreign` (its `.git/index` left out).

**The checks** are script getters, `private.os.platform.heal.<name>.check.script.get <args...>`
(`expect <branch> <breakages...>`, `foreign`, `user.clone <branch>`), run by one runner, `private.os.platform.heal.check <platform> <name> <args...>`,
as root through `private.os.platform.root.script.run`; its RESULT is `<name> check on <platform>: rc <rc>`.

**The expect check** asserts what the heal left. Every line of its output is `expect <block>: …`, a wrong shape
`expect <block>: FAILED — …`, rc 1 on any. The blocks of every heal:

| Block | What it asserts |
|---|---|
| `origin` | the configured `remote.origin.url` (`git config --get`, not `get-url`, which a host `insteadOf` rewrites) of `<base>/main` and `<base>/<branch>` is `git@github.com:Cerulean-Circle-GmbH/once.sh.git` (`private.oo.repo.url.get`) |
| `ssh` | `~developking/.ssh/id_rsa` owned by developking; root's `~/.ssh/config` with `Host github.com`, `IdentityFile ~/.ssh/ids/ssh.developking/id_rsa`, `IdentitiesOnly yes`; root's `~/.ssh/ids/ssh.developking/id_rsa`; `<basehome>/shared/.ssh/config` with `Host github.com` and `known_hosts` with github.com; `~/init` of root → `~/oosh/init`; root's login shell bash |
| `launcher` | `/usr/local/bin/this`, and `/usr/bin/this` where an empty shell has no `/usr/local/bin` on its PATH (Alpine) |
| `links` | `~/oosh` and `~/config` of test, root, oosh-user, bash-user and developking: `~/config` is the sharedConfig; test and root (the healer and the login that ran sudo) are on `<base>/<branch>`; every other user is on `<base>/<branch>` or on a tree that carries the model (`config.session.save`, the clean boot — `private.oo.heal.user.keep.check`'s rule, read as text), else the user kept a tree that predates the heal; a link outside the base fails |

and the blocks of a breakage, only when that breakage ran: `eraB.config` (test's `config.orig.<ts>`, `OOSH_SSH_CONFIG_HOST` and `LOG_LEVEL` imported into the sharedConfig), `root.clone` (the real clone and config kept as `oosh.orig.<ts>` and `config.orig.<ts>`), `devhome.missing` (developking's home back, owned by developking), `boot.era` (oosh-user's `.bashrc` not of the boot era, no retired drop-in), `no.bashrc`, `safe.directory.stale` (no `/Users/Shared` entry in root's `.gitconfig`), `ssh.legacy` (the legacy folder reported and left), `state.30` (`SETUP_SERVER` at 99 in the sharedConfig), `worktree.layout` (`<base>/testing` no linked worktree), `aside` (for `diverged`, `markers.committed`, `merge.conflict`, `dirty`, `detached`: an entry `<base>.aside/<branch>.orig.<ts>` holds the arm's marker) and `folder` (after a folder breakage `<base>/<branch>` is a clean clone on the branch: no merge, no markers, no diverged history).

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
| `state.30` | The install state set back to `SETUP_SERVER` 30 in the sharedConfig: `stateMachines/SETUP_SERVER.states.env` (`SETUP_SERVER_STATE_ID=30`) and the cache `current.state.machine.env` (`state=30`) | system |
| `launcher.missing` | `/usr/local/bin/this` removed | system |
| `worktree.layout` | `<base>/testing` becomes a linked worktree at `origin/testing`, tracking it — the shape the old install left | base |
| `missing.branch` | `<base>/<branch>` removed | base |
| `diverged` | A local commit origin lacks, and an `origin/<branch>` the folder lacks | `<base>/<branch>` |
| `markers.committed` | Conflict markers committed in `this`, `log`, `oo` and `config` (the Mac's 6 Oct shape) | `<base>/<branch>` |
| `merge.conflict` | A half-done merge: `MERGE_HEAD` set, markers in `heal.conflict.txt` | `<base>/<branch>` |
| `dirty` | An uncommitted change in `os` | `<base>/<branch>` |
| `detached` | `HEAD` detached (through `update-ref`, last: a merge in progress refuses a checkout); `oosh-user`'s `~/oosh` is pointed at the broken folder, as the Mac's one user lives in it | `<base>/<branch>`, `oosh-user` |
| `user.clone` | `<base>/<branch>` rebuilt as a **healthy** clean clone of the branch, owned by `test` (group of the base, setgid, cloned as `test` from the installed tree), not trusted by root (no `safe.directory` entry); HEAD, owner and inode are recorded in `/opt/user.clone.heal.rec` — the shape `oo checkout <branch>` leaves. The heal must **keep** it (kept, fast-forwarded: a HEAD that is a child of the recorded one is expected): the check fails the run on a `<base>.aside/<branch>.orig.*` entry, a changed owner, a HEAD that is no fast-forward of the record, or a missing folder | `<base>/<branch>`, `test` |

**What a PASS still shows as `[left]`.** These are reports, not failures, and they stand on every heal (the second one too): root's legacy `ssh.*` folders (`ssh.backup.migrate` moves them; the heal never does), the old-format `user.env` values of a real `~/config` that are never carried over, foreign trees left untouched (`foreign.symlink`), and a canonical folder moved aside to `<base>.aside/<name>.orig.<ts>` for you to look at.

**The transport** (`private.os.platform.user.run`): `runuser` gets `env HOME=~<user>` (it keeps the caller's environment, so HOME would stay the ssh login's), root runs through `sudo -H`, and every command starts with `unset SUDO_USER SUDO_UID SUDO_GID SUDO_COMMAND` — `ogit.folder.finish` in the gates' fixtures trusts folders for `$SUDO_USER`, which filled the login's `.gitconfig`.

**Who moves** under `oo heal <branch> all` is [oo.md § oo.heal](oo.md#ooheal)'s rule (`all`, `private.oo.heal.user.keep.check`): the healer (root) and the login that ran sudo (`test`) move to `<base>/<branch>`; `oosh-user`, `bash-user` and `developking` keep their canonical tree only when it carries the model (`config.session.save` and the clean boot), and the installed old ref does not, so they move too. The expect check asserts exactly that: a user outside `<base>/<branch>` must be on a tree that carries the model.

The folder arms build on one another in this order: `missing.branch` clears `<base>/<branch>`; `diverged`
clones it again from the installed tree and commits on it; `markers.committed` commits on it; `merge.conflict`
leaves a merge in progress; `dirty` changes a file the merge does not touch. `user.clone` stands apart: it rebuilds
the folder as a healthy clone owned by `test`, so it comes last, is **left out of `all`** (name it to run it) and
is refused together with `missing.branch`, `diverged`, `markers.committed`, `merge.conflict`, `dirty` or `detached`
(`private.os.platform.heal.breakage.list.get`). After the second heal `private.os.platform.heal.check <platform> user.clone <branch>`
fails the run (`user-clone=1` in the verdict line, log step `user-clone`) when that clone was moved aside or its
owner changed or the HEAD is no fast-forward of the record. The fixture files travel as text
inside the one script (`private.os.platform.heal.fixture.script.get`, `private.os.platform.root.script.run`).

**Logs.** The logs of a run are one folder, made by `private.this.temp.dir.get oosh-heal-test` under `TMPDIR` (else `/tmp`) and
named in `OOSH_HEAL_TEST_LOGS`; `private.os.platform.heal.log.get <step> <platform>` is `oosh-heal-test-<step>-<platform>.log` in it
for the steps `breakages`, `heal`, `expect`, `pipe`, `test`, `root`, `oosh-user`, `bash-user`, `idempotence-root`,
`idempotence-bash-user`, `second-heal`, `foreign`, `user-clone-heal`, `user-clone`, and with `compare` `compare-install`, `compare-healed`, `compare-fresh` and `compare`. The folder is removed on PASS; on a FAIL, a failed
breakage, or Ctrl-C, SIGTERM or a hangup (the run ends 130, the branch dropped, the container removed) its path is printed (`logs: <folder>`).

**The C2 preconditions.** The tree is clean and committed (see step 1), and `<healBranch>` — the branch of this
tree — exists on origin; else the idempotence invariant's `oo update` row is NOT CHECKED and `idempotence=1`.

**The C2 command lines** (inside the disposable containers only, never on a real host):

```bash
# compare=0: no line differs but kept ones (kept=<n> is expected: the folders the breakages moved aside) and WARN lines of the known list
os platform.heal.test ubuntu_24_04 51d7fb3 all pipe compare  # the full scenario: pipe form and the fresh-install compare included
os platform.heal.test debian_12 51d7fb3 all pipe compare
os platform.heal.test almalinux_9 51d7fb3 all pipe compare
os platform.heal.test alpine_3_19 51d7fb3 all pipe compare
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

**The heal phase (H.1–H.5, between Phase A and Phase B).** The install is broken four ways with the arms of [the heal scenario](#the-heal-scenario-os-platformhealtest) — `root.clone`, `safe.directory.stale`, `launcher.missing`, `markers.committed`, the text of `private.os.platform.heal.breakage.script.get` written to files and run by root, so Linux and macOS run one text (the prelude finds macOS users through `dscl` when `/etc/passwd` lacks them); then healed once as `runner` through the curl form (`cat init/oosh | OOSH_REPO=<bundle of this checkout> sh -s -- heal <branch> all`: rc 0, or rc 1 as reports only, read by `private.os.platform.heal.reports.only.is`), `oo heal.status` rc 0, a second heal that changes nothing (`private.os.platform.heal.second.run macos <branch>`), and a one-user `OOSH_HEAL_LOCAL=1 ossh heal.pipe` as `test`. The `chown -R runner:staff /Users/shared` that masks runner's not-yet-effective group `dev` runs only after these checks, for the gates.

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
