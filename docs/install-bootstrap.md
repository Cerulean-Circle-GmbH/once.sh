# The install bootstrap: `init/oosh` re-execs clean

`init/oosh` is the installer — it runs before oosh exists, so it is POSIX `sh` and
self-contained, including its `$HOME` recovery block (its twin in `boot` went with
`boot`). This page documents its **clean-environment guarantee**: the `env -i`
self-re-exec (the `cleanEnv` block), what is carried, what is seeded, and why.
The file serves **four delivery paths** — the curl one-liner, `ossh install <host>` (which copies it over),
drag-and-drop, and the **heal** (`curl … | sh -s -- heal`, see [The heal arm](#the-heal-arm)). For how a shell starts once installed see [config.md § The PATH line](config.md#the-path-line); for the design record see
[the clean-environment spec](superpowers/specs/2026-09-14-clean-environment-guarantee-design.md).


## The clean re-exec

Recovering `$HOME` makes an `env -i` start *survivable*. The guarantee that the installer runs in
a clean environment is a separate thing. It cannot come from a shebang (`#!/usr/bin/env -iS …`):
BusyBox `env` (Alpine) has no `-S`. `init/oosh` establishes it itself, immediately after the branch default:

```sh
if [ -z "$OOSH_CLEAN_ENV" ] && [ -f "$0" ] && [ -r "$0" ]; then
  _oosh_sh=sh
  if [ -n "$BASH_VERSION" ]; then _oosh_sh="${BASH:-bash}"; fi
  _oosh_x=""
  case "$-" in *x*) _oosh_x="-x" ;; esac
  exec env -i PATH=… HOME="$HOME" OOSH_CLEAN_ENV=1 … "$_oosh_sh" $_oosh_x "$0" "$@"
fi
```

**It names an interpreter, never a bare `"$0"`** — as do all three other `exec`s in the file. A
bare `"$0"` goes to the *kernel*, which requires the execute bit and re-reads the shebang. That
breaks three real call sites: `ossh.prereqs.install` (`scp -q` with no `-p`, then `bash
/tmp/oosh-init.$$`, whose comment promises it works "even if … isn't executable" — a kernel exec
dies there at exit 126 with a bare `env:` message); README's `env -i sh -x init/oosh` debugging
recipe (the shebang re-read **drops `-x`**, producing a debug log with no trace in it — hence
`$_oosh_x`); and `macos-test.yml`'s deliberate `/opt/homebrew/bin/bash` (silently downgraded —
hence the `$BASH_VERSION` check). `-r` rather than only `-f` because an interpreter must *read*
`$0`; the execute bit is deliberately not required.

`-S` existed only because a *shebang* can pass a single argument; doing it inside the script lifts
that constraint. BusyBox rejects `env -S` but accepts `env -i VAR=val cmd`, so this is portable.
`$0` is a readable file only when the script is executed — in the curl-pipe path `$0` is `sh` and
there is nothing to re-exec, so that path skips. `OOSH_CLEAN_ENV` makes it fire exactly once.

**Placement is load-bearing.** It must come *after* `: ${OOSH_BRANCH:=$OOSH_SELF_BRANCH}`: `env -i`
wipes `OOSH_SELF_BRANCH`, which is not carried, so re-execing any earlier silently resolves the
branch to `dev` and discards a caller's override.

**Anything the installer reads but never sets must be named in the carry list.**

The guarantee is therefore **not "empty"**. It is *deterministic for oosh, pass-through for the
tools oosh calls*. `env -i` strips not only what `init/oosh` itself reads, but the environment
handed to **every child it spawns** — `this call ossh prereqs.install`, `install.continue.local`,
`user oosh.install`, every `git clone`, the Homebrew `curl`, `sudo`, and the final
`exec "${BASH_FILE:-bash}" -l`. A strictly clean environment sabotages all of those.

Two groups, with **two different justifications**. They look alike in the `exec` line and must not
be collapsed: someone auditing "does `init/oosh` read this?" would correctly conclude Group 1 is
load-bearing and *wrongly* conclude Group 2 is removable.

**Group 1 — oosh's own state.** Carried because *this script* reads it.

| Carried | Why |
|---|---|
| `HOME` | every anchor hangs off it |
| `OOSH_CLEAN_ENV` | the once-only sentinel; without it the re-exec loops |
| `OOSH_BRANCH` | the caller's branch choice |
| `OOSH_NO_AUTORUN` | sourcing/test guard |
| `SUDO_USER` | assigned nowhere in the file. `sudo ./init/oosh` would otherwise lose the invoker, and the post-install `user oosh.install "$SUDO_USER"` silently never runs |
| `OOSH_REPO` | assigned nowhere in the file. A fork or private-repo override would otherwise fall back to public GitHub with no error |
| `USER`, `LOGNAME` | login sets them, **bash does not** — `env -i bash` arrives with both empty. Install state 13 (`private.check.priviledges.checked`) routes root vs user on `$USER`, so a root install with no later sudo hop was routed into the user lane. `this` now heals `USER` from `id -un` exactly as it heals `$SUDO`; the re-exec carries both for every non-oosh child |
| `TMPDIR` | read by the heal arm (`${TMPDIR:-/tmp}`): the folder its fresh clone is made under. Carried only when the caller has one |
| `OOSH_HEAL_NONINTERACTIVE`, `OOSH_NO_INSTALL` | read by `oo heal` (`private.oo.heal.privilege.ensure`): either one makes the heal non-interactive, so it never stops at a password prompt. The heal arm hands them on to the child `oo heal` (`env OOSH_HEAL_NONINTERACTIVE=1 …`) when set |

**Group 2 — pass-through.** `init/oosh` reads **none** of these. They are carried for the children.

| Carried | Why |
|---|---|
| `LOG_LEVEL` | `this` does `[ -z "$LOG_LEVEL" ] && export LOG_LEVEL=3`, so it is an inherited knob. Only `mode root` has a positional argument for it, so on the drag-and-drop and direct paths env is the **only** lever — without it `LOG_LEVEL=6 ./init/oosh` installs at 3 in silence |
| `TERM` | the success path ends in `exec "${BASH_FILE:-bash}" -l`; without it the user lands in a shell with no line editing and no colour |
| `LANG`, `LC_ALL` | the installer prints `═ ─ ✓` box-drawing throughout; the C locale mangles it |
| `http_proxy`, `https_proxy`, `no_proxy` | nothing in the tree sets these, so env is the only channel. Behind a corporate proxy the install otherwise dies at the first `git clone` |
| `SSH_AUTH_SOCK` | we carry `OOSH_REPO` precisely so a private-repo override works, then would wipe the agent socket that authenticates the clone. Carrying one without the other is incoherent |
| `GIT_SSH_COMMAND` | the same argument one step further: a private fork cloned with an explicit key (`GIT_SSH_COMMAND="ssh -i ~/.ssh/deploy_key"`) is the same use case as one cloned via the agent |

**`${VAR:-}` — and the one exception.** Every pass-through uses `${VAR:-}` so an *absent* variable
stays absent-in-effect rather than becoming a spurious empty value that shadows a downstream
default. That property was checked per variable, not assumed: `LOG_LEVEL` is tested with
`[ -z ... ]`; POSIX `setlocale` ignores an empty `LANG`/`LC_ALL`; OpenSSH tests `SSH_AUTH_SOCK` for
empty explicitly; an empty proxy variable reads as "no proxy".

**Only set variables are carried.** `env -i VAR= cmd` does not leave `VAR` absent — it *sets*
it to the empty string, and empty is not unset: git runs a set-but-empty `GIT_SSH_COMMAND` as
the command `''` ("error: cannot run : No such file or directory"), and install state 31's ssh clone
fails silently. Each variable is therefore
tested with `${VAR+set}` and appended only when the caller has it; POSIX `sh` has no arrays,
so the `env` argument list is assembled in `"$@"`. Pinned by **T-INIT-CLEAN-ENV-ABSENT**.

`TERM` is the **sole exception** and gets `${TERM:-dumb}`. Measured: bash turns an *unset* `TERM`
into `dumb` but leaves an *empty* one empty, and `tput` errors on empty while accepting `dumb`. So
`${TERM:-}` would be strictly **worse** than dropping `TERM` altogether. `${TERM:-dumb}` reproduces
the unset behaviour exactly and carries a real terminal when there is one.

## `PATH` is seeded, not carried — and not "re-derived"

`env -i` leaves `PATH` unset, so the
child falls back to its compiled-in default — measured as
`/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`. That contains `/usr/local/bin` but
**not** `/opt/homebrew/bin`.

On an Apple-Silicon Mac that *already* has Homebrew this is fatal and does not recover:
`oosh_pm_detect` finds no package manager → the Darwin branch runs the full Homebrew installer over
`curl` → as root that aborts with *"Don't run this as root!"* → `die "Homebrew bootstrap failed"`.
The `eval "$(/opt/homebrew/bin/brew shellenv)"` that would have rescued `PATH` sits **inside that
same failure branch**, after the installer has already run, so it is never reached. Nothing in the
re-exec discovers brew; the Homebrew prepend lives in Phase A's `brewPath` block (see below),
and Phase B keeps only the current-bash-dir prepend. Intel Macs escape only because their brew lives
in `/usr/local/bin`.

So `PATH` is **seeded to a fixed, known-good list** rather than carried:

```sh
PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
```

Seeding is not the same as carrying. The caller's `PATH` is still discarded; what changes is that
the child gets a value that is *constant regardless of who invoked us*. That determinism is the
point of the guarantee — carrying the caller's `PATH` would surrender it.

Still deliberately *not* carried: `BASH_FILE` and `SUDO` (recomputed, more correctly, from scratch
— Phase A may have just installed a newer bash that a stale `BASH_FILE` would shadow),
`INSTALL_LOG`/`OOSH_APT_UPDATED` (set downstream of the re-exec, so nothing is lost), and
`GIT_ASKPASS` (it names a helper *binary*, which the seeded `PATH` may no longer resolve — it would
fail confusingly rather than cleanly — and it drives an interactive credential prompt that an
unattended installer cannot answer anyway).

> Guarded by `test.install` **T-INIT-HOME-RECOVERY**, **T-HOME-RECOVERY-NO-GETENT** (the home
> comes from the shell's own `~user`, then `dscl`, then `/etc/passwd` — no `getent` at runtime;
> asserted by running *both* recovery blocks with a stub `getent` that must never be asked),
> **T-INIT-CLEAN-ENV** (re-exec present, guarded, names an interpreter, no `env -S`),
> **T-INIT-CLEAN-ENV-CARRY** (`SUDO_USER`, `OOSH_REPO`, `USER` and `LOGNAME` actually cross),
> **T-INIT-CLEAN-ENV-ABSENT** (an unset `GIT_SSH_COMMAND` reaches the child unset, a set one verbatim),
> **T-INIT-CLEAN-ENV-EXEC** (survives a mode-644 `$0`, keeps a deliberate bash, forwards `-x`),
> **T-INIT-CLEAN-ENV-PATH** (`/opt/homebrew/bin` is on the child's `PATH`) and
> **T-INIT-CLEAN-ENV-PASSTHROUGH** (`LOG_LEVEL` crosses; `TERM` defaults to `dumb`, not empty).
> The probe deliberately runs at `mktemp`'s mode 600 — the one permission the real
> `ossh.prereqs.install` call site grants, and no more.

## The Homebrew `PATH` prepend (`brewPath`)

The seeded `PATH` above belongs to the clean re-exec. The pipe form (`curl … | sh -s -- …`) has no
clean re-exec — `$0` is `sh` — so it keeps the **caller's** `PATH`, which on a Mac account (an ssh login
of a second user) may lack `/opt/homebrew/bin` and so `brew` and its bash 5. The `brewPath` block in Phase A,
before the package-manager detection and the bash 4+ check, puts them there: on Darwin only, it prepends `/opt/homebrew/bin`, then
`/usr/local/bin`, each only when the directory exists and is not already on `PATH`. Phase B's own
prepend is reduced to the directory of the `bash` already found. On macOS `sh` is itself bash 3.2: the
file form re-execs under a bash 4+, the heal does not need to (see below).

> Guarded by **T-INIT-PHASE-A-BREW-PATH**, which runs the extracted blocks under `sh` with `uname`
> stubbed and asserts the resulting `PATH`.

## The heal arm

`init/oosh heal [<branch>] [all]` is the installer's fourth delivery path: it does not install, it hands
over to a **fresh clone's `oo heal`** ([oo.md § oo.heal](oo.md#ooheal) has the heal itself). It is the form
for a computer where `~/oosh` is missing, old or broken.

```bash
curl -fsSL https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/<branch>/init/oosh | sh -s -- heal [<branch>] [all]
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/<branch>/init/oosh)" sh heal
```

**Never `sh -c "$(curl …)" heal`**: after the command string the first word is `$0`, so the script would
start with *no* arguments and run an install. The extra `sh` makes `heal` the first argument. (In the pipe
form `sh -s -- heal` the arguments are positional as usual.) On macOS `sh` is bash 3.2: the file form
re-execs under a bash 4+, the heal does not need to.

**The arguments are read before Phase A.** The `healArgs` block, right after `# END cleanEnv`, records
`_heal`, `OOSH_BRANCH` and `_hw` (the user, or `all`) and leaves `"$@"` untouched, so every re-exec
carries the arguments intact and Phase A's step 4 already knows it is a heal; the arm itself reads the
recorded values. The block is a size-exception block too. **Step 4 never hands over or pre-clones for a
heal**: the arm is POSIX `sh`, and the child `oo heal` runs under the `bash` that `command -v bash`
finds after `brewPath` (and Phase B's current-bash-dir prepend) has put the right directory first, so
no temp directory is made to leak, and a heal never turns into a plain install of `OOSH_SELF_BRANCH`.

> Guarded by **T-INIT-HEAL-EARLY-PARSE**, **T-INIT-PIPE-HEAL-ARGS-SURVIVE** and
> **T-INIT-REEXEC-KEEPS-ARGS**.

**The launcher.** The tree the arm hands over to installs the launcher `/usr/local/bin/this` (`private.oo.install.launcher`); where the empty shell `env -i sh` has no `/usr/local/bin` on its PATH — BusyBox on Alpine — it also links `/usr/bin/this` to it (`private.oo.launcher.link.get`), so `this` is found there too.

**Position.** The arm sits after the `git` and bash 4+ checks and **before** the sudo check
(`# BEGIN healArm` … `# END healArm`): healing one's own account needs no sudo, so a user on a machine without
sudo can heal. Phase A's package-list refresh runs only when it must install `git` or bash, for the same
reason.

**The contract.**

- **Arguments:** `all` means every user; any other word is the branch, with a leading `origin/` stripped. The
  default branch is `OOSH_SELF_BRANCH`, so the one-liner of the prod branch heals to prod. An empty argument or
  one starting with `-` is refused (`heal: bad argument`); `id -un` failing is refused too.
- **A fresh temp clone.** `mktemp -d` makes `oosh-heal.XXXXXX` under `$TMPDIR` (else `/tmp`), mode `755`, and
  `git clone -b <branch> $OOSH_REPO` (default: the public HTTPS URL) goes into `t` beneath it, reading
  `/dev/null`; then `chmod -R go+rX` on it, so another user's hop can read it. For `all` the folder is
  always under `/tmp`, because every user's hop must reach it. The clone is **never** `~/oosh`.
- **No sudo in the arm — `all` included.** The arm runs `env OOSH_REPO=… bash <clone>/oo heal <branch> <who>`
  as the caller. Root is the clone's decision, made **once**: its `oo heal` (`private.oo.heal.env.clean`) knows
  the clone by its temp layout (`private.oo.heal.temp.tree.check`), makes no second copy, and for `all` as a
  user starts its one clean process through `private.oo.heal.sudo.get` — `sudo -H` after one password prompt
  with a terminal, `sudo -n -H` without one. When root cannot be had it ends with **rc 2 before anything
  runs** and names the curl form run as root (`curl -fsSL <init/oosh> | sudo sh -s -- heal <branch> all`;
  the clone itself is gone when the arm ends). The privilege rule is written once, in
  [oo.md § The privilege rule](oo.md#ooheal). Guarded by **T-INIT-HEAL-ARM-HANDOVER-NO-SUDO** and
  **T-OO-HEAL-ARM-TREE-NO-COPY**.
- **stdin.** In the pipe form stdin *is* the script, so the child must never read it: it reads `/dev/tty`
  when there is a terminal (so its `oo heal` can ask for the sudo password), else `/dev/null` — and then
  only `sudo -n` is tried (**T-INIT-HEAL-ARM-NO-TTY**).
- **The non-interactive flags travel.** `OOSH_HEAL_NONINTERACTIVE` and `OOSH_NO_INSTALL` are handed to the
  child with `env`, like `OOSH_REPO`; the clean process of `oo heal` keeps them.
- **The child's rc is kept** (`exit "$_hr"`): 0 healed, 1 something is left for you, 2 cannot heal.
- **One owner of the cleanup: the clean process.** A clone under `/tmp` (always for `all`) is removed by the
  clean process itself when it exits (`private.oo.heal.copy.trap`, the same matcher) — as root under sudo, so
  no second sudo is needed. The arm's `rm -rf` afterwards is only the **fallback**: for a run that never
  reached the clean process (rc 2 before it) and for a one-user clone under a `$TMPDIR` outside `/tmp` (the
  clean process runs under `env -i` without `TMPDIR`). It is tried as the user, then, for `all`, with
  `sudo -n` — never a prompt; when neither works the arm says `remove <dir> yourself` and still exits with
  the child's rc.

The child is `oo heal` of the clone, which re-runs itself once in a clean process (`env -i`).

**The size exception.** The cap on `init/oosh` stays 700 lines for everything else, but the heal arm is
all-or-nothing and has to live in the one file the curl form fetches. Its block says why on the line after
`# BEGIN healArm` (`# size-exception: …`) and **leaves the count**; a block without that reason line counts
fully (`homeRecovery`, `cleanEnv` and `brokenTree` count). **T-INIT-SIZE-CAP** prints both numbers —
now `init/oosh is 715 lines, 691 counted (cap 700; 24 lines in size-exception blocks)`. The count is the awk pass of `test.install.sizeCapCheck`: every `# BEGIN <name>` whose next line is a non-empty `# size-exception:` reason, through its `# END <name>`, markers included, leaves the 715 raw lines (`healArm` and `healArgs` are such blocks).

## The `brokenTree` check

After the `OOSH_DIR` resolve (the `~/oosh` link, then the clone layout), and before
anything is reused, the installer looks at the tree it is about to use (the
`brokenTree` block). It refuses to reuse an `$OOSH_DIR` whose `.git` **directory**
has a `MERGE_HEAD` (a merge in progress) or a `HEAD` that is not a `ref: ` line (a
detached HEAD): its conflicted files would otherwise be executed. It dies with
the message `existing <dir> is mid-merge or detached and is not reused` and the
one command to run, which is the heal: `curl -fsSL https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/<OOSH_SELF_BRANCH>/init/oosh | sh -s -- heal`.

The block reads `.git/MERGE_HEAD` and `.git/HEAD` itself (the read of `HEAD` is guarded, so an unreadable one
does not end the installer under `set -e`; it is then no `ref: ` line and the tree counts as broken) and never calls `git`:
the tree may belong to another user, and `git` would answer "dubious ownership",
which must not be mistaken for a broken tree. A `.git` **file** (a linked
worktree) is not a directory and passes.
