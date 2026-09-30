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
The one bash-only thing — the `log` framework script — is sourced under a guard
and simply skipped otherwise (oosh needs bash 4+ to actually run; the `env -i sh`
bootstrap re-execs into bash immediately).

### The guard is "bash **and not** POSIX mode"

`[ -n "$BASH_VERSION" ]` alone is the wrong question, and asking it that way was a
real bug (fixed 2026-09-14, `test.config` **T70**). **On macOS `/bin/sh` IS bash 3.2**:
`$BASH_VERSION` is set, so the old guard sourced `log` — but that shell runs with
`posix` on, where a **dotted function name is not a valid identifier**, and `log` is
built from dotted names (`log.device`, `log.level`, …). Worse, **a parse error in a
sourced file under POSIX mode kills the shell**, not just the `source`. Measured (the run
is recorded on the T9 card): under `/bin/sh` the sourced `log` failed to parse and the
shell died with rc 2 before the next command ran; `/bin/bash` and Homebrew bash booted
the same file cleanly.

Same binary, same file — only POSIX mode differs. It is the same failure class as
**T3** (a sourced `boot` killing its caller) reached by another route.

So the guard tests both halves, through `$SHELLOPTS` (which bash keeps current, so a
runtime `set -o posix` is caught too) with a `case`, keeping the file parseable by
dash/ash for T40's four-shell lint:

```sh
_oosh_posix=no
case ":$SHELLOPTS:" in *:posix:*) _oosh_posix=yes ;; esac
if [ -n "$BASH_VERSION" ] && [ "$_oosh_posix" = no ]; then …
```

**Under POSIX mode `boot` skips `log` and carries on.** Every anchor and the PATH block
are set *before* that point, so a POSIX-mode shell still comes up fully anchored and
`boot` still returns 0 — it just has **no log functions** (`console.log`, `error.log`,
…). That is the correct trade; killing the shell is not. `bash --posix` reproduces the
whole thing on Linux, which is what T70 drives.

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
6. **Logging primitives** (**bash, and not in POSIX mode** — see
   [the guard](#the-guard-is-bash-and-not-posix-mode)): source `log`, then
   `log.session.save` writes the per-user `LOG_NAME`/`LOG_DEVICE`/`LOG_LIVE` to
   `log.session.env`. Both live in **one `if`**, not two `&&` lists — see
   [Guarantees](#guarantees). Skipped, not fatal, in every other shell.
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

### The PATH-writer rule (and its only exceptions)

**`boot` is the single builder of `PATH`.** Everything else either delegates to
it, or is a documented degrade branch that says so in the code.

The anchor rule above and this one are enforced the same way, but they are not
the same kind of rule, and the difference is the whole design:

| | `OOSH_DIR` / `CONFIG_PATH` | `PATH` |
|---|---|---|
| what it is | a **constant** — `$HOME/oosh`, `$HOME/config` | an **accumulation** |
| so "conforming" means | the value equals the constant | **the writer is `boot`** |
| the validator is | a value check | a **writer sweep** |

There is no value to test a `PATH` against, so the rule can only be about *who
may write it*. Every `PATH=` or `export PATH=` assignment in the tracked tree
outside `boot` is a violation unless it carries a marker:

```sh
# path-exception: <reason>            # this line, or one of the five above it
# path-exception-file: <reason>       # anywhere in the file — the whole file
```

The five-line window exists because these assignments often sit inside a
heredoc, an `ssh` command string or a `bash -c` string, where the marker cannot
go on the line itself. The slug is derived from the variable name exactly as
the anchor markers are (`PATH` → `path-exception`), so this is no new syntax.

#### Who is exempt, and why

| Kind | Sites | Why |
|---|---|---|
| **whole file** | `init/oosh` | the installer runs **before `~/oosh` exists**, so `boot` — which lives inside it — cannot be sourced yet. It builds brew-bash-first and hands a clean environment to the login shell |
| **whole file** | `init/once` | the superseded ONCE installer, kept for history. Still *tracked* (committed before `once` entered `.gitignore`), so the sweep sees it |
| degrade branch | `ossh` ×2, `user` ×3, `templates/user/bashrcTemplate`, and seven CI steps | `. ~/oosh/boot || export PATH=~/oosh:~/oosh/ng:$PATH` — boot first, bare prepend only if it is missing. See *Cross-branch note* below |
| remote / sudo string | `ossh`, `user` ×2, `hiveMind` ×3 | executed on **another host** or **as another user**, where `boot` has not run |
| sourced-without-boot | `ossh.start`, `this` (file scope and `this.path.add`) | `ossh` and `this` are *sourced* by scripts that never reach `boot`; both prepends are colon-anchored |
| repair, not build | `oo.mode` ×2, `this.init` | rewriting a branch name already in PATH, or saving and restoring PATH across a mid-session `source "$CONFIG"` |
| session scope | `oo` (brew, `ONCE_LOAD_DIR`), `claudeCode`, `path.append`/`prepend`/`remove` | deliberately affects only the running shell, and says so in its docstring |
| diagnostics | `debug`'s `p`, two banners, `path.env` | they **print** `PATH=`; they do not set it |

Enforced by **`path validate [<treeRoot>]`** — one `git grep` over the tracked
tree (`docs/`, `test/`, `.claude/`, `*.md`, `*.json` excluded as for the
anchors, plus `old/` and `restore/`, the legacy graveyards), classifying every
assignment as conforming / exception / violation, echoing its verdict to stdout
so it survives any `LOG_LEVEL`, and returning rc 1 on any violation. Covered by
`test.path` `T-PATH-VALIDATE-*`, including *planted* violations, so the guard
is proven to fail — and proven not to mistake `CONFIG_PATH=` or
`OSSH_CONTROL_PATH=` for `PATH=`.
## Guarantees

The contract `boot` keeps, and that callers may rely on (settled by ticket **T3**,
"`env -i sh` SAFETY, shall boot correctly"):

| | |
|---|---|
| **Sourced, never executed** | `. ~/oosh/boot` / `source ~/oosh/boot`. Every call site sources it. It sets variables in *your* shell — running it as a program would set them in a process that immediately exits. |
| **Exit status is meaningful** | **0** on success, **non-zero** on refusal. Callers branch on it — `ossh exec` / `ossh exec.tty` and the three `user` rootkey pushes all do `[ -f ~/oosh/boot ] && . ~/oosh/boot \|\| export PATH=…`. So the last statement in `boot` must never be a conditional list (see below). |
| **Recovers `$HOME`** | `env -i` drops it, so `boot` looks it up in the password database (`getent` → `dscl` → `/etc/passwd`) and exports it — which is what lets `env -i sh` boot correctly *once `boot` is reached*. A `HOME` that is *set but not a directory* (a removed user, an inherited container env) is treated the same way. Only if no home can be found at all does `boot` print a diagnostic and `return` non-zero. |
| **Proven shells** | `sh`, `dash`, `busybox ash`, `bash`, and **POSIX-mode bash** (`bash --posix`, `set -o posix`, macOS `/bin/sh`) — and under `env -i`, with or without `HOME`, **when sourced by absolute path**: use `. /etc/oosh/boot`. Two caveats below: with `HOME` unset, `~` is not a path a POSIX shell can resolve, so `. ~/oosh/boot` is the everyday form, not the recovery form; and a POSIX-mode shell comes up **anchored but without the log functions**. |
| **Never kills the caller** | `boot` is sourced, so it must not be able to end the shell that sourced it. It `return`s rather than `exit`s (T51), and it refuses to source `log` into a shell that cannot parse it — in POSIX mode a parse error in a sourced file is fatal to the shell (T70). |

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
the table above — correct for everyday use, and what every call site uses — is exactly the form
that cannot work in the empty-environment case `boot` exists to survive. Chicken-and-egg: the
thing that would recover `HOME` sits behind a path that needs `HOME`.

So there is a fixed, host-wide path. **One command, any user, any shell, no environment at all**
(in POSIX-mode shells — macOS `/bin/sh` — anchored but without the log functions; see
[the guard section](#the-guard-is-bash-and-not-posix-mode) and [macOS](#macos--what-actually-applies-there)):

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

### The three recovery routes

`. /etc/oosh/boot` always works, but somebody has to *type* it. Two of the three
routes below need no typing at all. Measured in a container, and this is the whole
table — nothing here is aspirational:

| Command | Recovers? | Why |
|---|---|---|
| `env -i sh` | **no** | `ENV=[]` — `$ENV` is a non-login POSIX `sh`'s **only** rc hook, and `env -i` is precisely what erased it. There is nothing left to hook. |
| `env -i ENV=/etc/oosh/boot sh` | **yes** | that same hook, handed back. `$ENV` is `sh`'s `~/.bashrc`. |
| `env -i sh -l` | **yes** | a login shell reads `/etc/profile`, which loops `/etc/profile.d/*.sh` — and `/etc/profile.d/oosh.sh` is installed alongside the symlink. |
| `. /etc/oosh/boot` | **yes** | the explicit form. Works in every shell, login or not, with or without the two above — **degraded, not broken, in POSIX mode**: anchors yes, log functions no (see the guard section). |

**Bare `env -i sh` can never self-recover, and no future change will make it.** A
non-login POSIX `sh` reads exactly one startup file, the one named by `$ENV`;
`/etc/profile` is login-only; `~/.bashrc` is bash-only. `env -i` clears the
environment, so the one hook is gone before the shell starts. Proven with dash's own
tracing: `env -i sh -lxc ':'` traces through `/etc/profile` (`id -u`,
`[ 1003 -eq 0 ]`, `PS1=$`, `[ -d /etc/profile.d ]`), while `env -i sh -xc ':'` shows
only `+ :`. If you have no environment *and* have not typed anything, nothing can run.

#### `/etc/profile.d/oosh.sh` — the login route

Created by the **same** install state `34 root.boot.path.installed` and healed by the
**same** `oo boot.fix` as `/etc/oosh/boot`; `oo boot.status` reports on both. The `.sh`
suffix is load-bearing — `/etc/profile`'s glob is `/etc/profile.d/*.sh`, and any other
name is simply never read.

It is **Linux-only, by fact rather than by choice**: macOS has no `/etc/profile.d` at
all (its `/etc/profile` runs `path_helper` and sources `/etc/bashrc`, and globs
nothing), so a file there would never be read. On such a host the drop-in is a
**graceful skip** — state 34 still succeeds, the symlink is still created, and the
other two routes are unaffected.

It runs for **every** login shell on the box, including users who have never heard of
oosh, so it is guarded twice and both guards matter:

```sh
if [ -r "/etc/oosh/boot" ]; then                      # 1
  if [ -z "${HOME-}" ] || [ -d "$HOME/oosh" ]; then   # 2
    . "/etc/oosh/boot"
  fi
fi
:
```

1. **The target must exist and be readable.** `-r` follows the symlink, so a missing
   *or dangling* `/etc/oosh/boot` is a silent no-op — never an error at somebody's
   login prompt.
2. **The caller must actually have an oosh install** — *unless* `HOME` is unset, which
   is the `env -i sh -l` recovery case this route exists for, and where `boot` derives
   `HOME` from the password database itself. Without this guard every non-oosh user on
   the host would get a nonexistent `$HOME/oosh` prepended to `PATH` **and** an empty
   `~/.config/oosh` created in their home, just for logging in. The guard lives here
   rather than in `boot` on purpose: `boot`'s own behaviour is unchanged for every
   existing call sites and for anyone who types `. /etc/oosh/boot` deliberately; what
   must not regress is the *passive* login of somebody who never asked for oosh.

No `exit` (it would close the login shell), no `return` (not every `/etc/profile`
sources it from a function), and a trailing `:` so a `boot` that legitimately refuses
cannot hand a non-zero status to the login shell.

#### `$ENV` — the hand-it-back route

```sh
env -i ENV=/etc/oosh/boot sh
```

Two caveats, both measured, both easy to get wrong when quoting this:

- **`$ENV` is honoured by *interactive* shells only.** `env -i ENV=… sh -c '…'` does
  **not** source it. Do not add a `-c`.
- **bash under its own name ignores `$ENV` entirely** — it is a POSIX-mode feature
  there. Invoked as `sh` (the RHEL/Alma `/bin/sh`) bash *does* read `$ENV`, and works,
  because it enters POSIX mode only **after** the startup file is read, so it gets the
  log functions too. An explicit `bash --posix` reads `$ENV` with POSIX mode **already
  active**: it recovers the anchors and stays alive, but `boot` skips `log`, so that
  shell has no log functions. It used to be worse — bash rejected every dotted function
  name in `log` and the shell *died*; that is the bug T70 fixes.

Guarded by `test.config` **T68** (the `$ENV` route and both of those negatives) and
`test.oo` **T-BOOTPATH-PROFILED-\*** (the drop-in's content and guards, against a fixture);
the deployed files are proved by `test.platform.boot.system.path.invariant`.

#### macOS — what actually applies there

Three facts about macOS (measured; the T9 card records the run), and they
change which route you should reach for:

1. **`/bin/sh` on macOS is bash 3.2 in POSIX mode.** Not dash. `$BASH_VERSION` is set and
   `SHELLOPTS` contains `posix`. `. /etc/oosh/boot` under it recovers every anchor and
   returns 0, but that shell gets **no log functions** — see the guard section above. Before
   the T70 fix the shell died instead.
2. **There is no `/etc/profile.d` on macOS at all**, so the login-shell route
   (`/etc/profile.d/oosh.sh`, `env -i sh -l`) is **Linux-only**. State 34 still creates
   `/etc/oosh/boot` — confirmed on the VM, pointing into `/Users/shared/…` — and then
   *gracefully skips* the drop-in. Do not expect a macOS login shell to self-recover through it.
3. **For macOS, the reliable recovery is bash**, not `sh`:

   ```sh
   bash -c '. /etc/oosh/boot; …'          # /bin/bash 3.2 — anchors + log functions
   /opt/homebrew/bin/bash -c '. /etc/oosh/boot; …'   # brew bash 5.x, what oosh actually wants
   ```

   Both measured rc 0 with `HOME`, `OOSH_DIR` and `CONFIG_PATH` all recovered. `. /etc/oosh/boot`
   from `/bin/sh` is safe and gives you a working `PATH` — use it to *reach* oosh, then run
   oosh commands, which re-exec under bash themselves.

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

`boot` recovering `$HOME` makes `env -i sh` *survivable*. The guarantee that the installer
itself runs in a clean environment is a separate thing — the `env -i` self-re-exec in
`init/oosh`, what it carries, what it seeds, and the per-variable audit — and it has its
own page: [install-bootstrap.md](install-bootstrap.md).

## Idempotent

Safe to source repeatedly (mode switches, `exec bash`, nested shells): nothing
double-applies. The PATH statement needs one qualification, because the two
blocks are not guarded the same way and only one of them is idempotent.

**Block 1, `$OOSH_DIR` (`boot:103-109`) — segment-idempotent.** Its guard is
`case ":$PATH:" in *":$OOSH_DIR:"*`, a true exact-segment test, so a PATH that
already carries `~/oosh` anywhere is neither moved nor grown. `test.config`
T74 pins this behaviourally: source `boot` twice in a clean sub-shell, and
`$OOSH_DIR` appears exactly once and the second source changes nothing.

**Block 2, `$BASH_FILE` (`boot:110-117`) — deliberately not.** Its guard is
`case "$PATH" in "$_oosh_bashdir:"*`, anchored to the **front of PATH only**,
so if that directory is present but not first it is prepended again. That is
the point of the block: on macOS, brew bash has to beat the `/bin/bash` that
`path_helper` appends, and re-asserting first position is how. The case is
reachable — block 1 prepending `$OOSH_DIR` pushes the bash directory back one
place — so re-sourcing `boot` with `BASH_FILE` set **can** grow PATH by one
entry. That is the lesser of the two evils on a Mac: the behaviour stays, and
this paragraph is the correction to the claim that used to stand here.

## Cross-branch note

`boot` exists on `dev`. Until it is promoted, `testing`/`prod`/`main` have no
`boot`, so callers that source it carry a fallback: `ossh exec`, the `user`
rootkey pushes, and `bashrcTemplate` do `. ~/oosh/boot || export PATH=~/oosh:…`
(or an `elif [ -d ~/oosh ]` PATH branch) so they still work when `boot` is
absent. (Promotion is owned by the release process, not by this work.)

## It is not an OOSH method-script

`boot` has no `boot.start`, no `noun.verb` methods, and is POSIX `sh` — that is
deliberate (the dash/ash requirement). Its tests live in `test/test.config`
(T74 PATH idempotency — behavioural, replacing a second test that also called
itself T24 and could not fail; T31 the OOSH_DIR/CONFIG_PATH constants, T40 POSIX-sh/ash lint,
T49-T52 the guarantees above, T44
`OOSH_USER_CONFIG_PATH`, T45 session touch-guard, T47 dash sources a generated
chain, T65-T68 `$HOME` recovery and the fixed-path routes, T70 POSIX-mode bash —
the macOS `/bin/sh` case).

## See also
- [config.md](config.md) — the two config tiers and `config.save` generation
- [log.md](log.md) — `LOG_NAME`/`LOG_DEVICE`/`LOG_LIVE` and the session chain
- [install-bootstrap.md](install-bootstrap.md) — `init/oosh`'s clean-environment re-exec
- [migration/env-files.md](migration/env-files.md) — the pure-data migration
- [research/review-2026-09-09-boot-loader-pure-env-files.md](research/review-2026-09-09-boot-loader-pure-env-files.md)
- [puml/bootstrap.sequence.drawio](puml/bootstrap.sequence.drawio) — **the** bootstrap sequence
  diagram, and the single source of truth for it. Six lanes: install from GitHub, local
  `init/oosh`, the login-shell `.bashrc → boot` path this page describes, reconfigure-and-exit,
  remote install, de-install. Open it in [diagrams.net](https://app.diagrams.net).
  `puml/bootstrap.sequence.puml` and the `.svg`/`.eps` beside it are the **superseded** pre-`boot`
  version, kept for history and marked as such in their own header — do not read them for the
  current mechanism.
