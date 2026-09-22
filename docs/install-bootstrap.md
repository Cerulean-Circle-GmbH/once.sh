# The install bootstrap: `init/oosh` re-execs clean

`init/oosh` is the installer — it runs before oosh exists, so it is POSIX `sh`. Two of its
blocks are **deliberately duplicated**, each with a different twin, because neither twin
may source a shared helper:

| Block | Twin | Why it cannot be shared |
|---|---|---|
| `BEGIN`/`END homeRecovery` | `templates/user/profile.d.oosh.sh`, the login-shell drop-in | one runs before oosh exists, the other runs for **every** login on the host — including users who have never heard of oosh |
| `BEGIN`/`END userEnvSeed` | `config`'s `private.config.anchor.lines.get` | POSIX `sh` cannot call a bash function, and this runs before there is an oosh to call |

`test.install` **T-HOME-RECOVERY-NSS** runs *both* recovery blocks against a stub, and
**T-INIT-SEEDS-USER-ENV** pins the seed to the emitter. This page documents the installer's
**clean-environment guarantee**: the `env -i` self-re-exec (the `cleanEnv` block), what is
carried, what is seeded, and why. For the data those seeds write see
[config.md § user.env is the boot](config.md#userenv-is-the-boot); for the design record see
[the clean-environment spec](superpowers/specs/2026-09-14-clean-environment-guarantee-design.md).


## The clean re-exec

The guarantee that the installer runs in a clean environment used to come from a shebang:

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
| `USER`, `LOGNAME` | login sets them, **bash does not** — `env -i bash` arrives with both empty. Install state 13 (`private.check.priviledges.checked`) routes root vs user on `$USER`, so a root install with no later sudo hop was routed into the user lane. `this` now heals `USER` from `id -un` exactly as it heals `$SUDO`; the re-exec carries both for every non-oosh child |

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
the command `''` ("error: cannot run : No such file or directory"), which made install state 31's
ssh clone fail silently on every install through the re-exec. Each variable is therefore
tested with `${VAR+set}` and appended only when the caller has it; POSIX `sh` has no arrays,
so the `env` argument list is assembled in `"$@"`. Pinned by **T-INIT-CLEAN-ENV-ABSENT**.

`TERM` is the **sole exception** and gets `${TERM:-dumb}`. Measured: bash turns an *unset* `TERM`
into `dumb` but leaves an *empty* one empty, and `tput` errors on empty while accepting `dumb`. So
`${TERM:-}` would be strictly **worse** than dropping `TERM` altogether. `${TERM:-dumb}` reproduces
the unset behaviour exactly and carries a real terminal when there is one.

## `PATH` and `user.env` are seeded, not carried — and not "re-derived"

`env -i` leaves `PATH` unset, so the
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

### The `user.env` seed

The same word, one level up. `env -i` leaves the re-exec'd installer with no oosh anchors
at all, and the login shell it eventually `exec`s needs them — so `init/oosh` **writes**
them, rather than carrying them:

```sh
# BEGIN userEnvSeed
if [ ! -f "$HOME/config/user.env" ]; then
  mkdir -p "$HOME/config"
  …
  {
    echo 'export OOSH_DIR="$HOME/oosh"'
    echo 'export CONFIG_PATH="$HOME/config"'
    …
  } > "$HOME/config/user.env"
fi
# END userEnvSeed
```

Three properties are load-bearing:

- **Only when absent.** The `[ ! -f ]` guard means a re-install never clobbers a host's
  existing `user.env`; the install's own `config save` rewrites it properly later.
- **Byte-identical to `config`'s emitter.** POSIX `sh` cannot call
  `private.config.anchor.lines.get`, so the lines are duplicated. `test.install`
  **T-INIT-SEEDS-USER-ENV** pins the two copies together — a change to one that is not
  made to the other fails the suite.
- **`$HOME`-relative, written unexpanded.** The installer runs as root, or as the
  installing user, into a config directory that is usually shared. An expanded
  `/root/oosh` here would be the leak the whole design exists to prevent.

After that the final `exec "${BASH_FILE:-bash}" -l` needs to carry nothing: the new login
shell sources `~/config/user.env` and picks up its own anchors and its own PATH.

Still deliberately *not* carried: `BASH_FILE` and `SUDO` (recomputed, more correctly, from scratch
— Phase A may have just installed a newer bash that a stale `BASH_FILE` would shadow),
`INSTALL_LOG`/`OOSH_APT_UPDATED` (set downstream of the re-exec, so nothing is lost), and
`GIT_ASKPASS` (it names a helper *binary*, which the seeded `PATH` may no longer resolve — it would
fail confusingly rather than cleanly — and it drives an interactive credential prompt that an
unattended installer cannot answer anyway).

> Guarded by `test.install` **T-INIT-HOME-RECOVERY**, **T-HOME-RECOVERY-NSS** (a two-line `getent`
> answer still recovers line 1's home — asserted by running *both* recovery blocks with a stub),
> **T-INIT-CLEAN-ENV** (re-exec present, guarded, names an interpreter, no `env -S`),
> **T-INIT-CLEAN-ENV-CARRY** (`SUDO_USER`, `OOSH_REPO`, `USER` and `LOGNAME` actually cross),
> **T-INIT-CLEAN-ENV-ABSENT** (an unset `GIT_SSH_COMMAND` reaches the child unset, a set one verbatim),
> **T-INIT-CLEAN-ENV-EXEC** (survives a mode-644 `$0`, keeps a deliberate bash, forwards `-x`),
> **T-INIT-CLEAN-ENV-PATH** (`/opt/homebrew/bin` is on the child's `PATH`) and
> **T-INIT-CLEAN-ENV-PASSTHROUGH** (`LOG_LEVEL` crosses; `TERM` defaults to `dumb`, not empty).
> The probe deliberately runs at `mktemp`'s mode 600 — the one permission the real
> `ossh.prereqs.install` call site grants, and no more.

