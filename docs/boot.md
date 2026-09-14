# The `boot` loader

`$OOSH_DIR/boot` is the **single entry point** that turns a bare shell into an
oosh shell. It owns all the bootstrap logic that used to be generated *into* the
config env files, so those files can stay **pure data** (only `export KEY="VALUE"`
and `. x.env` chain lines — see [config.md](config.md) and
[migration/env-files.md](migration/env-files.md)).

## Why it exists

The old design self-anchored inside `~/config/user.env` (it carried
`export OOSH_DIR=…`, `export CONFIG=…`, a `CONFIG_PATH` fallback, and PATH
wiring). That put **code in data files** — the thing the boss explicitly
rejected — and the `~/oosh` self-anchor once produced a symlink self-loop
("Too many levels of symbolic links"). `boot` moves every bit of that logic into
one reviewed script; the env files became pure, portable data.

## Who sources it

Every context that needs an oosh environment sources `boot`:

- the interactive login shell — `templates/user/bashrcTemplate` does `. "$HOME/oosh/boot"`;
- `ossh exec` / `ossh exec.tty` on a remote host;
- the `os platform.test` per-user runners and `odocker` exec;
- CI steps (e.g. `.github/workflows/macos-test.yml`).

## POSIX-sh only (no bashisms)

`boot` must source cleanly under **dash / ash** (a `/bin/sh` login shell,
`ossh exec` on Debian) as well as bash, and under `env -i sh`. So: no `[[ ]]`,
no arrays, and the **env files it sources must use POSIX `.`, not the bash
`source` builtin** (`config.add` / `config.save` emit `.` — see D1 in
[the 2026-09-09 review](research/review-2026-09-09-boot-loader-pure-env-files.md)).
The one bash-only thing — the `log` framework script — is sourced under a
`[ -n "$BASH_VERSION" ]` guard and simply skipped under a bare `sh` (oosh needs
bash 4+ to actually run; the `env -i sh` bootstrap re-execs into bash immediately).

## What it does, in order

0. **Refuse without a usable `$HOME`.** Every anchor below hangs off it, so an
   unset or stale `HOME` is refused up front rather than half-booted (see
   [Guarantees](#guarantees)).
1. **Anchors.** `OOSH_DIR` is always `~/oosh` and `CONFIG_PATH` is always
   `~/config` — the symlink paths *themselves*, never their resolved targets,
   never from `oo.mode.base.get` (see the rule below). `CONFIG_FILE` =
   `user.env`, `CONFIG` = `CONFIG_PATH` + `CONFIG_FILE`.
2. **`OOSH_USER_CONFIG_PATH`** = `~/.config/oosh` — the per-user (non-shared)
   config dir (see [config.md § two tiers](config.md)). Single source of truth;
   `log`/`config`/`oo` reference the var, not the literal path.
3. **Touch-guard** the per-user `log.session.env` so the next step's chain can
   source it even on a first-ever shell (it is written properly in step 6).
   Its failure used to be *fatal* to the sourcing shell — see [Guarantees](#guarantees).
4. **Source the config.** Only `user.env` — it chains `. $CONFIG_PATH/oosh.env`
   / `log.env` itself, and `log.env` chains `. $OOSH_USER_CONFIG_PATH/log.session.env`.
   One line stands up the whole environment.
5. **PATH.** Put `$OOSH_DIR` and `$OOSH_DIR/ng` on PATH (and `$BASH_FILE`'s dir
   first, so brew bash wins over path_helper's `/bin/bash` on macOS). Colon-
   anchored, so re-sourcing never grows PATH.
6. **Logging primitives** (bash only): source `log`, then `log.session.save`
   writes the per-user `LOG_NAME`/`LOG_DEVICE`/`LOG_LIVE` to `log.session.env`.
   Both live in **one `if`**, not two `&&` lists — see [Guarantees](#guarantees).
7. **Exit 0.** A bare `:` terminates `boot`, so success is never reported as
   failure to the callers that branch on its status.

### The path-anchor rule (and its only exceptions)

**`OOSH_DIR` is always `~/oosh`** — the user's `oosh` symlink, never the branch
worktree it happens to point at, never a `BASH_SOURCE`/`$0` walk, never
`oo.mode.base.get`.

**`CONFIG_PATH` is always `~/config`** — the user's `config` symlink, never the
shared `sharedConfig` directory it points at.

In code those are written `"$HOME/oosh"` / `"$HOME/config"`, because a tilde inside
quotes does **not** expand (`OOSH_DIR="~/oosh"` would be seven literal characters and
break every path built from it). `$HOME/oosh` and `~/oosh` are the same path;
`$HOME/oosh` is the form that is safe in POSIX `sh` and in every quoting context.

```sh
export OOSH_DIR="$HOME/oosh"        # this IS ~/oosh
export CONFIG_PATH="$HOME/config"   # this IS ~/config
```

`CONFIG_PATH` came to the rule second, and for a blunt reason: `boot` was the **only**
place that resolved it. `config`, `log`, `ossh` and `this` all already default to the
literal `$HOME/config`, so the variable had *two different values depending on which
entry point ran* — the shared physical path after `boot`, `~/config` after a bare
`source this` or a mid-install sub-shell. Making `boot` agree with everyone else
removed that split.

#### Why that makes it simple

Because the value is the symlink, `OOSH_DIR` is a **constant**. Switching branches
(`oo mode`) moves only what `~/oosh` *points at*; the variable itself never changes.
A constant needs setting in exactly **one** place, so:

- **`boot` is the single setter** for both. Everything else just reads them.
- For `OOSH_DIR` the one other assignment is a same-literal *fallback* in `this`'s
  top-level block, for contexts that never source `boot` (a bare `source this`, a
  mid-install sub-shell). `CONFIG_PATH` has the same shape of fallback in `this`,
  `log` and `ossh` (`: ${CONFIG_PATH:=$HOME/config}`).
- `oo.mode`, `oo.mode.setup` and install state 31 **no longer export it** — repointing
  the symlink *is* the switch. `mode-env.bash` (written by `oo.mode` for the `ooShim`
  to source into the parent shell) now carries only `OOSH_MODE`, `hash -r` and the
  PATH rewrite.
- `ossh.start` uses the same literal. It used to derive from `$0`, which is the *host*
  process whenever `ossh` is **sourced** (`myId`, `config`, `user`, `test.ossh`) and
  so yielded the caller's directory.

#### When you need the physical directory

Resolve it **at that spot** with the portable helper `private.this.path.canonical`
(`this:144`) — never bake the resolution into `OOSH_DIR`. The consumers that do:

| Site | Why it needs the physical path |
|---|---|
| install state 31 `ln -s … oosh` | linking `$OOSH_DIR` itself would create `~/oosh -> ~/oosh` ("Too many levels of symbolic links") |
| install state 31 `OOSH_MODE` | the branch name is `basename` of the *worktree*, not of the symlink |
| `config.init.user` | decides "are we under the shared tree?" with a string-prefix test |
| `promote` | `git worktree list` reports physical paths; a mismatch would stash the same directory twice |
| `oo.mode.base.get` | strategies 3/4 do `dirname`/`basename` — `dirname ~/oosh` is just `$HOME` |

Everything else works fine through the symlink and is deliberately left alone: every
`git -C "$OOSH_DIR" …`, every `$OOSH_DIR/<file>` and `$CONFIG_PATH/<file>` path join,
`private.ensure.groupWrite "$CONFIG_PATH/…"`, and
`ln -s "$path/$class" "$OOSH_DIR/external/$class"`. `CONFIG_PATH` needed **no**
point-of-use fixes at all — nothing in the tree does `dirname`/`basename`/prefix
arithmetic on it, only `-d` / `-f` / `-z` tests, which all follow a symlink.

#### Sanctioned exceptions

Each is marked in-code with `# <anchor>-exception: <reason>` — or, for a whole file,
`# <anchor>-exception-file: <reason>` — where `<anchor>` is the variable name
lower-cased with `_` → `-`: `oosh-dir-exception`, `config-path-exception`.

**`OOSH_DIR`:**

| Site | Why |
|---|---|
| `oo.use` | runs one command **from another branch without switching** — a scoped child-process override; no symlink alternative by design |
| `ossh` remote invoke | a string executed on a **remote** host whose `~/oosh` does not exist yet |
| `user.oosh.install` sub-shell | installs **another user** before their `~/oosh` exists |
| `init/oosh` (file-wide) | the installer runs **before** `~/oosh` exists (it may start from a clone or a ZIP); it self-corrects by moving the repo to `$HOME/oosh`, and `unset`s `OOSH_DIR` before handing off to the login shell |

**`CONFIG_PATH`:**

| Site | Why |
|---|---|
| `config file <path>` | the one method whose *job* is to leave `~/config` — it points the session at an arbitrary config file, so `CONFIG_PATH` must come from that path |
| install state 31 (×2) | builds the shared tree **before** `~/config` is a symlink to it, so it must name the target directly |

A self-assignment (`CONFIG_PATH=$CONFIG_PATH`, as in `config`'s and `test.suite`'s
usage banners) is not an assignment site — it is a no-op, and a marker comment there
would be *printed to the user*.

Enforced by **`this.anchor.validate <all|OOSH_DIR|CONFIG_PATH>`**, with
`this.oosh.dir.validate` and `this.config.path.validate` as the per-anchor forms.
(In an oosh shell `this` is itself a function, so call the method directly; as a
script it is `./this anchor.validate`.) One `git grep` per anchor over the tracked
tree (`docs/`, `test/`, `.claude/` and `*.md`/`*.json` excluded), classifying every
assignment as conforming / exception / violation, echoing its verdict to stdout (so
it survives any `LOG_LEVEL`) and returning rc 1 on any violation. Covered by
`test.this` T-OOSH-DIR-* / T-CONFIG-PATH-* — including *planted* violations, so the
guard is proven to fail, and proven to be per-anchor (an `oosh-dir` marker does not
exempt a `CONFIG_PATH` line) — and `test.config` T31 asserts both of `boot`'s
literals then delegates the tree sweep to it.

> A shell opened **before** this change still holds the old resolved `OOSH_DIR` /
> `CONFIG_PATH`. `source ~/oosh/boot`, or simply a new shell, fixes it.

## Guarantees

The contract `boot` keeps, and that callers may rely on (settled by ticket **T3**,
"`env -i sh` SAFETY, shall boot correctly"):

| | |
|---|---|
| **Sourced, never executed** | `. ~/oosh/boot` / `source ~/oosh/boot`. All 20 call sites source it. It sets variables in *your* shell — running it as a program would set them in a process that immediately exits. |
| **Exit status is meaningful** | **0** on success, **non-zero** on refusal. Callers branch on it — `ossh exec` / `ossh exec.tty` and the three `user` rootkey pushes all do `[ -f ~/oosh/boot ] && . ~/oosh/boot \|\| export PATH=…`. So the last statement in `boot` must never be a conditional list (see below). |
| **Recovers `$HOME`** | `env -i` drops it, so `boot` looks it up in the password database (`getent` → `dscl` → `/etc/passwd`) and exports it — which is what lets `env -i sh` boot correctly *once `boot` is reached*. A `HOME` that is *set but not a directory* (a removed user, an inherited container env) is treated the same way. Only if no home can be found at all does `boot` print a diagnostic and `return` non-zero. |
| **Proven shells** | `sh`, `dash`, `busybox ash`, `bash` — and under `env -i`, with or without `HOME`, **when sourced by absolute path**: use `. /etc/oosh/boot`. See the caveat below: with `HOME` unset, `~` is not a path a POSIX shell can resolve, so `. ~/oosh/boot` is the everyday form, not the recovery form. |

### The tilde caveat — reaching `boot` is not the same as running it

`boot` recovers `$HOME`. It cannot help you *find* it, because the shell must resolve the path
before `boot` gets to run. Measured in a container:

| Under `env -i` | Result |
|---|---|
| `sh` → `. ~/oosh/boot` | **fails** — `sh: .: cannot open ~/oosh/boot: No such file` |
| `sh` → `. /home/you/oosh/boot` | `rc=0`, all three anchors recovered |
| `bash` → `. ~/oosh/boot` | `rc=0` |

With `HOME` unset, `~` is undefined behaviour in POSIX and dash/ash leave it **literal**; bash
falls back to the password database and expands it anyway. So the `. ~/oosh/boot` form given in
the table above — correct for everyday use, and what all 20 call sites use — is exactly the form
that cannot work in the empty-environment case `boot` exists to survive. Chicken-and-egg: the
thing that would recover `HOME` sits behind a path that needs `HOME`.

So there is a fixed, host-wide path. **One command, any user, any shell, no environment at all:**

```sh
. /etc/oosh/boot
```

`/etc/oosh/boot` is a **symlink** into the shared tree, created by install state
**`34 root.boot.path.installed`** and healed by **`oo boot.fix`** (`oo boot.status` reports on it).
It needs no `HOME`, no `PATH` and no knowledge of which branch you are on: `boot` derives `$HOME`
per caller, so the one canonical copy serves every user on the box — you source the host's
anchoring prologue and then your *own* config and your *own* `log`, from your *own* tree.

> **Trust — read this before treating `/etc/oosh/boot` as root-owned.** It points at
> **dev-group-writable** content: install state 31 runs `chmod -R g+w` on the shared tree, so any
> member of `dev` can edit the file this link resolves to, and anyone who sources it — root
> included — executes it. That trust model is **unchanged** from root's existing `~/oosh`, which is
> already a symlink into the same tree. What changed is only that the path now *looks* root-owned.
> `/etc/oosh/boot` is exactly as trusted as the `dev` group, no more.

**Portable fallbacks**, for a host that has no `/etc/oosh/boot` — a user-rights-only (20-lane)
install never reaches state 34, and a host installed before this landed has not run `oo boot.fix`
yet:

```sh
. /home/you/oosh/boot                                        # if you know your home
. "$(getent passwd "$(id -un)" | head -1 | cut -d: -f6)/oosh/boot"   # if you don't
```

`getent` is Linux/NSS; on macOS use `dscl . -read /Users/$(id -un) NFSHomeDirectory`, or just use
`bash`, which is the system shell there anyway.

On SELinux hosts (Alma/RHEL) the symlink is read through to its target under `/home/shared/...`,
labelled `home_root_t`/`default_t`. Unconfined user shells — the only consumers today — are
unaffected; a *confined* domain sourcing it would be denied.

### Why the exit status needed fixing

`boot` used to end with

```sh
[ -n "$BASH_VERSION" ] && type log.session.save … && log.session.save …
```

Under `sh`/`dash`/`ash` there is no `$BASH_VERSION`, so the `&&` list is false and **`boot`
returned 1 after a completely successful boot**. Every one of the five `|| <degrade>` callers
above therefore took its "boot failed" branch *on success*, on every dash/ash host — which both
made a real failure indistinguishable from a healthy boot and prepended `~/oosh` to PATH a second
time. The bash-only tail now sits in one `if`, and `boot` ends with a bare `:`.

### Why no-`HOME` needed fixing

Every anchor hangs off `$HOME`, and `env -i` drops it. Unguarded, `OOSH_DIR` became `/oosh` and
`CONFIG_PATH` `/config` — and then the `log.session.env` touch-guard tried
`: > /.config/oosh/log.session.env`. **A redirection failure on a special builtin (`:`) is fatal
under POSIX**, so that did not merely warn: it *killed the shell that sourced `boot`*.

An earlier fix refused up front when `$HOME` was missing. That was safe but not sufficient: the
card asks that `env -i sh` **boot correctly**, not that it fail cleanly. So `boot` now recovers
first — `id -un`, then `getent passwd` → `dscl` (macOS) → `/etc/passwd` — and only refuses when no
home can be derived at all. Refusal is still a real outcome, just a much rarer one.

`return` — not `exit` — precisely because `boot` is sourced: `exit` would close the user's terminal.
`init/oosh` is *executed*, so its copy of the same block ends in `exit 1` instead. There are three
behavioural differences in total, all deliberate: the `return`/`exit` split; `init/oosh` also
**announces a successful recovery** on stderr (`boot` stays silent), because the documented
invocation is an `-x` trace captured to a log and an install into an unexpected home must be
visible in it; and the refusal wording differs (`oosh boot:` vs `oosh install:` prefixes, and a
correspondingly different re-run hint). The lookup itself — `id -un`, then
`getent | head -1 | cut` → `dscl` → `/etc/passwd`, and the `[ -d ]` gate — is identical.

> Guarded by `test.config` **T40** (parses under `sh` *and* `ash`), **T50** (exits 0 in every
> shell), **T51** (refuses when no home is derivable), **T52** (`ash` really boots), **T65**
> (recovery across `sh`/`dash`/`bash`/`busybox ash`, stale `HOME`, and a good `HOME` left alone),
> alongside **T49** (the boot-absent fallbacks still exist).

### The other half of T3: `init/oosh` re-execs clean

`boot` recovering `$HOME` makes `env -i sh` *survivable*. The guarantee that the installer runs in
a clean environment is a separate thing, and it used to come from a shebang:

```sh
#!/usr/bin/env -iS HOME=${HOME} sh     # 2024-04-07 (8c277f4) … 2026-03-09 (075b4a3)
```

`075b4a3` removed it for Alpine — BusyBox `env` has no `-S` — and nothing replaced it. `init/oosh`
now re-establishes it itself, immediately after the branch default:

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

**Anything the installer reads but never sets must be named in the carry list.** `init/oosh` was
rewritten three times (`b8b90b8`, `b427809`, `0594657`) during the two years the guarantee was
absent, so no part of the current file had ever run under `env -i`; two variables had grown a
dependency on inheritance:

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
| `OOSH_BRANCH` | the caller's branch choice — `57f0984` fixed exactly this loss |
| `OOSH_NO_AUTORUN` | sourcing/test guard |
| `SUDO_USER` | assigned nowhere in the file. `sudo ./init/oosh` would otherwise lose the invoker, and the post-install `user oosh.install "$SUDO_USER"` silently never runs |
| `OOSH_REPO` | assigned nowhere in the file. A fork or private-repo override would otherwise fall back to public GitHub with no error |

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

`TERM` is the **sole exception** and gets `${TERM:-dumb}`. Measured: bash turns an *unset* `TERM`
into `dumb` but leaves an *empty* one empty, and `tput` errors on empty while accepting `dumb`. So
`${TERM:-}` would be strictly **worse** than dropping `TERM` altogether. `${TERM:-dumb}` reproduces
the unset behaviour exactly and carries a real terminal when there is one.

### `PATH` is seeded, not carried — and not "re-derived"

An earlier revision of this document claimed `PATH` loss "self-heals, at the cost of a redundant
Homebrew probe". **That was wrong**, and the error mattered. `env -i` leaves `PATH` unset, so the
child falls back to its compiled-in default — measured as
`/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`. That contains `/usr/local/bin` but
**not** `/opt/homebrew/bin`.

On an Apple-Silicon Mac that *already* has Homebrew this is fatal and does not recover:
`oosh_pm_detect` finds no package manager → the Darwin branch runs the full Homebrew installer over
`curl` → as root that aborts with *"Don't run this as root!"* → `die "Homebrew bootstrap failed"`.
The `eval "$(/opt/homebrew/bin/brew shellenv)"` that would have rescued `PATH` sits **inside that
same failure branch**, after the installer has already run, so it is never reached. The two
`case ":$PATH:" in` blocks only *prepend* to whatever the shell defaulted to; neither discovers
brew. Intel Macs escape only because their brew lives in `/usr/local/bin`.

So `PATH` is now **seeded to a fixed, known-good list** rather than carried:

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

> Guarded by `test.install` **T-INIT-HOME-RECOVERY**, **T-HOME-RECOVERY-NSS** (the `head -1` that
> stops multi-source `getent` output from defeating recovery, in *both* copies),
> **T-INIT-CLEAN-ENV** (re-exec present, guarded, names an interpreter, no `env -S`),
> **T-INIT-CLEAN-ENV-CARRY** (`SUDO_USER` and `OOSH_REPO` actually cross),
> **T-INIT-CLEAN-ENV-EXEC** (survives a mode-644 `$0`, keeps a deliberate bash, forwards `-x`),
> **T-INIT-CLEAN-ENV-PATH** (`/opt/homebrew/bin` is on the child's `PATH`) and
> **T-INIT-CLEAN-ENV-PASSTHROUGH** (`LOG_LEVEL` crosses; `TERM` defaults to `dumb`, not empty).
> The probe deliberately runs at `mktemp`'s mode 600 — an earlier revision `chmod +x`'d it and so
> granted the one permission the real `ossh.prereqs.install` call site does not, which is why the
> bare-`"$0"` bug survived its first review.

## Idempotent

Safe to source repeatedly (mode switches, `exec bash`, nested shells): PATH
additions are colon-guarded and nothing double-applies.

## Cross-branch note

`boot` exists on `dev`. Until it is promoted, `testing`/`prod`/`main` have no
`boot`, so callers that source it carry a fallback: `ossh exec`, the `user`
rootkey pushes, and `bashrcTemplate` do `. ~/oosh/boot || export PATH=~/oosh:…`
(or an `elif [ -d ~/oosh ]` PATH branch) so they still work when `boot` is
absent. (Promotion is owned by the release process, not by this work.)

## It is not an OOSH method-script

`boot` has no `boot.start`, no `noun.verb` methods, and is POSIX `sh` — that is
deliberate (the dash/ash requirement). Its tests live in `test/test.config`
(T24 PATH idempotency, T31 the OOSH_DIR/CONFIG_PATH constants, T40 POSIX-sh/ash lint,
T49-T52 the guarantees above, T44
`OOSH_USER_CONFIG_PATH`, T45 session touch-guard, T47 dash sources a generated
chain).

## See also
- [config.md](config.md) — the two config tiers and `config.save` generation
- [log.md](log.md) — `LOG_NAME`/`LOG_DEVICE`/`LOG_LIVE` and the session chain
- [migration/env-files.md](migration/env-files.md) — the pure-data migration
- [research/review-2026-09-09-boot-loader-pure-env-files.md](research/review-2026-09-09-boot-loader-pure-env-files.md)
