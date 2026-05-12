# Env-file evolution: from `main` baseline to `dev`

A reference for understanding how `~/config/user.env`, `~/config/oosh.env`, and `~/config/log.env` are generated, why the `dev` versions look the way they do, and how an older host running pre-April-2026 code differs.

This document compares two ground-truth captures: the `main` branch (HEAD `c30787b`, March 2026; the same env-file generation logic lives on `test/macos.latest`) and `dev` (HEAD `beba799`, May 2026).

---

## What changed in one paragraph

The `main` baseline persists **absolute paths captured at install time** — `CONFIG="/home/test/config/user.env"`, `OOSH_DIR="/home/test/oosh"`, `LOG_DEVICE="/dev/stdout"`, `LOGNAME="test"`, the full `PATH`. That works for a single-user Docker container but breaks the moment a real install symlinks `~/config` and `~/oosh` to a **shared directory** where multiple users source the same files: user-A's persisted `/home/A/...` becomes user-B's `EACCES`. `dev` inverts the model: per-user paths are **re-anchored at every shell init** via two self-anchor lines — `: ${CONFIG_PATH:="${BASH_SOURCE[0]%/*}"}` at the top of `user.env` and `: ${OOSH_DIR:="$(cd "$HOME/oosh" 2>/dev/null && pwd -P || echo "$HOME/oosh")"}` at the top of `oosh.env` — and `config.save` actively **strips** the volatile absolutes (`CONFIG=`, `CONFIG_PATH=`, `OOSH_DIR=`, `LOG_LIVE=`, `LOG_DEVICE=`, `OOSH_COMPONENTS_DIR=`, `INSTALL`) so they can never leak between users. What survives the filter is portable per-install state: `OOSH_BRANCH`, `OOSH_MODE`, `OOSH_OS`, `OOSH_PM`, `OOSH_PROMPT`, `OOSH_SHLVL`, `OOSH_STATUS`, `OOSH_SSH_CONFIG_HOST`, `LOG_LEVEL`, `LOG_LEVEL_RESET`, `BASH_FILE`, `CONFIG_FILE`. Non-interactive shells (CI, `ssh exec`, completion) that don't run `this` get working defaults via the self-anchors. Brew bash on macOS gets PATH priority through a separate block at the bottom of `oosh.env`. Shared installs work without cross-user leaks, and a small `config.init.{shared,user,check,env,full}` family of repair primitives exists to recover hosts whose env files pre-date the fixes.

> If you only read one section of this document, read the next one. The two self-anchor lines are the centrepiece of the entire shift.

---

## The two self-anchor lines, line by line

These two lines are why everything else works. They make the env files **sourceable from anywhere** without any prior environment setup — solving the fundamental bootstrap problem of "how does a file tell you where it is without already being told where it is".

### 1. `: ${CONFIG_PATH:="${BASH_SOURCE[0]%/*}"}` — top of `user.env`

```bash
: ${CONFIG_PATH:="${BASH_SOURCE[0]%/*}"}
export BASH_FILE="/usr/bin/bash"
export CONFIG_FILE="user.env"
source $CONFIG_PATH/log.env
source $CONFIG_PATH/oosh.env
```

Breaking the first line into pieces:

- **`:`** — the shell's *null command*. It evaluates its arguments (with all expansion and side effects) but does nothing with the result. It's the idiomatic way to trigger parameter expansion for its side effects without calling `true` (which would fork on some shells) or `echo` (which would print).
- **`${CONFIG_PATH:=…}`** — POSIX parameter expansion with the **assign-default** operator. The behaviour is:
  - If `CONFIG_PATH` is unset *or* empty → assign the default value to `CONFIG_PATH` *and* substitute it.
  - If `CONFIG_PATH` is already set to a non-empty value → leave it alone; just substitute it.
  - The key word is *assign*: this is the only `${…}` form that has a side effect on the variable. `${VAR:-default}` (single dash) only substitutes; `${VAR:=default}` (equals sign) substitutes *and* mutates. We need the mutation so that the next line (`source $CONFIG_PATH/log.env`) sees the resolved value.
- **`${BASH_SOURCE[0]%/*}`** — the default value, computed only if needed. Two pieces:
  - **`BASH_SOURCE[0]`** is a bash-specific array containing the call stack of currently-sourcing files. Index `0` is the file being sourced *right now*. When `~/.bashrc` does `source ~/config/user.env`, `BASH_SOURCE[0]` inside `user.env` is the absolute path to `user.env` itself.
  - **`%/*`** is POSIX parameter-expansion *suffix-removal*. It strips the shortest match of `/*` from the end of the value — effectively, it removes the trailing `/filename` and leaves the directory. So `/home/alice/config/user.env` becomes `/home/alice/config`. This is `dirname` done with pure shell-builtin expansion: no `fork()`, no `exec()`, no subshell.

**What the whole line achieves.** A shell that sources `user.env` with `CONFIG_PATH` unset will, in one line, derive `CONFIG_PATH` from the *file's own filesystem location* — and that derived value will be exactly what's needed for the very next line, `source $CONFIG_PATH/log.env`, to succeed. The file becomes self-describing: drop it anywhere, source it, and the rest of the chain works.

**What it specifically prevents.** Before this line existed (added in `099bb7b`, 2026-04-27), a shell that hadn't run `config.init` first would have `CONFIG_PATH` unset, making `source $CONFIG_PATH/log.env` expand to `source /log.env` — "No such file or directory". The whole sourcing chain collapsed. This bit non-interactive shells (CI, `ssh exec`) and any script that wanted to bootstrap from `user.env` without going through `this`. The self-anchor closes that hole.

**Why these specific primitives.** `$0` inside a sourced file is the *outer* shell name (`bash`, `-bash`) — useless for locating the file. `$PWD` is the caller's working directory, also useless. Only `BASH_SOURCE[0]` reliably gives the path of the file currently being sourced. The `%/*` form is a deliberate choice over `$(dirname "$BASH_SOURCE[0]")` because the latter forks a process every time `user.env` is sourced, and `user.env` is sourced on every interactive shell startup.

**Caveat.** `BASH_SOURCE` is a bash-specific array. A strict POSIX shell that sourced this file would see `BASH_SOURCE[0]` as unset and the self-anchor would fail. In practice this isn't an issue: the file uses `export` syntax throughout, and oosh's whole environment requires bash 4+. The first line is bash-only by design.

### 2. `: ${OOSH_DIR:="$(cd "$HOME/oosh" 2>/dev/null && pwd -P || echo "$HOME/oosh")"}` — top of `oosh.env`

```bash
: ${OOSH_DIR:="$(cd "$HOME/oosh" 2>/dev/null && pwd -P || echo "$HOME/oosh")"}
export declare OOSH_BRANCH="prod"
...
[ -f "$OOSH_DIR/log" ] && source "$OOSH_DIR/log"
```

Same `:` null command and same `${OOSH_DIR:=…}` assign-default operator as the user.env line. The interesting part is the default value:

- **`$(cd "$HOME/oosh" 2>/dev/null && pwd -P || echo "$HOME/oosh")`** — a command substitution that either resolves the real path of `~/oosh` or falls back to the literal string `$HOME/oosh`.
  - **`cd "$HOME/oosh" 2>/dev/null`** attempts to change directory into the user's `oosh` symlink, sending any error (e.g. directory doesn't exist) to `/dev/null`. The `cd` happens in a *subshell* (because we're inside `$(...)`), so it doesn't affect the calling shell's working directory.
  - **`&& pwd -P`** runs only if `cd` succeeded. `pwd -P` prints the **physical** path — symlinks resolved. So if `~/oosh` is a symlink to `/home/shared/EAMD.ucp/.../Once.sh/dev`, `pwd -P` returns the real path, not the symlink.
  - **`|| echo "$HOME/oosh"`** runs only if `cd` failed (i.e. `~/oosh` doesn't exist yet — fresh box, mid-install). Falls back to the literal `~/oosh` path as a best-effort. The system may not be functional yet at this point, but at least `OOSH_DIR` has *a* value rather than being empty.

**Why resolve the symlink with `pwd -P`?** The user's `~/oosh` is almost always a symlink to a shared install dir like `/home/shared/EAMD.ucp/.../Once.sh/dev`. Without `pwd -P`, `OOSH_DIR` would be `/home/alice/oosh` (the symlink) rather than the real path. That looks fine until `bashrcTemplate`'s auto-sync logic later compares paths or re-creates symlinks — at which point a self-referential symlink (`/home/alice/oosh` → `/home/alice/oosh`) can be created. `pwd -P` collapses the indirection up front. This particular tightening came in `f4966bd` (2026-04-27); the earlier form just used the symlink path literally.

**Why the fallback at all?** On a fresh, mid-install box `~/oosh` may not yet exist. Without the fallback, `OOSH_DIR` would be empty, and the trailing `[ -f "$OOSH_DIR/log" ] && source "$OOSH_DIR/log"` would evaluate `[ -f /log ]` and silently skip. That's fine *during* install, but the moment install completes and the user's first real shell starts, having a stale empty `OOSH_DIR` cached from the install-time source would cause confusion. The fallback ensures the value is *always* at least plausible, even on first boot.

### Why the order matters

Both self-anchors come **first** in their respective files, before any `export` line. That ordering is critical: the moment the parser starts evaluating the file, it needs `CONFIG_PATH` (in `user.env`) or `OOSH_DIR` (in `oosh.env`) to be set, because the next lines reference them. If the self-anchors came after the exports, those references would expand against the un-anchored values and the chain would break for non-interactive shells.

### The whole sourcing flow

This is what the self-anchors are protecting. The user's `~/.bashrc` template does:

```text
~/.bashrc
└── source ~/config/user.env
    ├── (self-anchor sets CONFIG_PATH from BASH_SOURCE[0])
    ├── source $CONFIG_PATH/log.env       ← needs CONFIG_PATH resolved
    └── source $CONFIG_PATH/oosh.env      ← needs CONFIG_PATH resolved
        ├── (self-anchor sets OOSH_DIR from $HOME/oosh)
        ├── (PATH builder block — see further down)
        └── source $OOSH_DIR/log          ← needs OOSH_DIR resolved
```

Each link in the chain depends on a path resolved by the previous one. The self-anchors guarantee that the FIRST file (`user.env`) can bootstrap the chain with no environment input — and the SECOND file (`oosh.env`) does the same independently, so even a script that sources `oosh.env` alone (bypassing `user.env`) still works.

---

## Ground-truth captures

### `main` baseline (single-user Docker container, `OOSH_DIR=/home/test/oosh`)

```env
# ~/config/user.env
export BASH_FILE="/usr/bin/bash"
export PATH="/home/test/oosh:/home/test/oosh:/usr/local/sbin:..."
export declare CONFIG="/home/test/config/user.env"
export declare CONFIG_FILE="user.env"
export declare CONFIG_PATH="/home/test/config"
export declare ERROR_CODE_RECONFIG="117"
source $CONFIG_PATH/log.env
source $CONFIG_PATH/oosh.env

# ~/config/log.env
export declare HUSHLOGIN="FALSE"
export declare LOGNAME="test"
export declare LOG_DEVICE="/dev/stdout"
export declare LOG_LEVEL="3"

# ~/config/oosh.env
export declare OOSH_DIR="/home/test/oosh"
export declare OOSH_PM="apt-get -y install"
export declare OOSH_PROMPT="oosh "
export declare OOSH_SHLVL="4"
export declare OOSH_STATUS="0: started in shell level: 1"
```

### `dev` (shared-install host, `OOSH_DIR=/home/shared/.../Once.sh/dev`)

```env
# ~/config/user.env
: ${CONFIG_PATH:="${BASH_SOURCE[0]%/*}"}
export BASH_FILE="/usr/bin/bash"
export CONFIG_FILE="user.env"
source $CONFIG_PATH/log.env
source $CONFIG_PATH/oosh.env

# ~/config/log.env
export declare LOG_LEVEL="3"
export declare LOG_LEVEL_RESET="3"

# ~/config/oosh.env
: ${OOSH_DIR:="$(cd "$HOME/oosh" 2>/dev/null && pwd -P || echo "$HOME/oosh")"}
export declare OOSH_BRANCH="prod"
export declare OOSH_MODE="released"
export declare OOSH_OS="linux-gnu"
export declare OOSH_PM="apt-get -y install"
export declare OOSH_PROMPT="oosh "
export declare OOSH_SHLVL="5"
export declare OOSH_SSH_CONFIG_HOST="hannesn-VirtualBox"
export declare OOSH_STATUS="0: started in shell level: 2"
# Ensure OOSH_DIR is in PATH
if [ -n "$OOSH_DIR" ] && [[ ":$PATH:" != *":$OOSH_DIR:"* ]]; then
  export PATH="$OOSH_DIR:$OOSH_DIR/ng:$PATH"
fi
# Ensure BASH_FILE directory is first in PATH (e.g. brew bash on macOS)
if [ -n "$BASH_FILE" ]; then
  _bashDir="$(dirname "$BASH_FILE")"
  if [[ "$PATH" != "$_bashDir:"* ]]; then
    export PATH="$_bashDir:$PATH"
  fi
fi
[ -f "$OOSH_DIR/log" ] && source "$OOSH_DIR/log"
```

---

## The PATH-anchoring block at the bottom of `oosh.env`

`oosh.env` is sourced from the user's `~/.bashrc` template **before** the `this` script runs. Without these lines, a non-interactive shell (CI step, `ssh user@host 'command'`, a subprocess) sources `oosh.env`, sets `$OOSH_DIR`, and then immediately fails to find `oo`, `os`, `ossh`, `c2`, `config`, `log`, `user`, etc. — because `OOSH_DIR` is not on `$PATH`. With these lines, every shell that sources `oosh.env` is ready to run oosh commands immediately, interactive or not. Introduced by `ac302d8` (2026-03-17, `fix(config): append PATH builder to oosh.env so non-interactive shells work`).

### First conditional — OOSH on PATH

```bash
if [ -n "$OOSH_DIR" ] && [[ ":$PATH:" != *":$OOSH_DIR:"* ]]; then
  export PATH="$OOSH_DIR:$OOSH_DIR/ng:$PATH"
fi
```

- `[ -n "$OOSH_DIR" ]` — only act if `OOSH_DIR` resolved. The self-anchor at the top of the file guarantees this in almost all cases; the guard is defensive in case `$HOME/oosh` doesn't exist on a fresh box.
- `[[ ":$PATH:" != *":$OOSH_DIR:"* ]]` — idempotency guard. The wrapping colons on both sides ensure exact-segment match, so `/foo/bar/oosh` doesn't false-match `/foo/bar/oosh-tools`. Without this guard, re-sourcing the file (which happens on `exec bash`, mode switches, recursive shells) would keep prepending the same dirs and grow `$PATH` indefinitely.
- `export PATH="$OOSH_DIR:$OOSH_DIR/ng:$PATH"` — prepends **two** directories: the top-level oosh dir (where `oo`, `os`, `ossh`, `config`, `this`, `user`, `line`, `log` live as scripts) and `ng/` (the "next-gen" subdir, e.g. `ng/c2`). Both must be ahead of `$PATH` so oosh's own scripts win against any system command of the same name.

### Second conditional — brew bash first

```bash
if [ -n "$BASH_FILE" ]; then
  _bashDir="$(dirname "$BASH_FILE")"
  if [[ "$PATH" != "$_bashDir:"* ]]; then
    export PATH="$_bashDir:$PATH"
  fi
fi
```

- **The problem this solves.** macOS ships bash 3.2 at `/bin/bash` (Apple won't upgrade because of GPLv3). OOSH requires bash 4+, and parts of `dev` require bash 5 (`${var^^}` upper-casing, for example). Users install bash via Homebrew → `/opt/homebrew/bin/bash` (Apple Silicon) or `/usr/local/bin/bash` (Intel). The install pipeline records the chosen interpreter as `$BASH_FILE`. **But** macOS's `path_helper` (run by `/etc/profile`) appends `/opt/homebrew/bin` at the **end** of `$PATH`, so `/bin/bash` wins any naked `bash` lookup. This block forces brew bash to win.
- `_bashDir="$(dirname "$BASH_FILE")"` — derive the directory holding the right `bash` binary at runtime. The leading underscore signals "internal/throwaway"; not exported.
- `[[ "$PATH" != "$_bashDir:"* ]]` — strictly checks `_bashDir` is **first**, not just present. This is the key difference from the OOSH check above. `path_helper` may have already added the brew dir somewhere in PATH; what matters for `#!/usr/bin/env bash` shebangs and naked `bash` invocations is which one comes first.
- `export PATH="$_bashDir:$PATH"` — prepend. Note this runs AFTER the OOSH block, so the final ordering is `$_bashDir : $OOSH_DIR : $OOSH_DIR/ng : <rest>`. Brew bash wins lookups for `bash`; OOSH scripts win for everything else.

The block evolved in two steps:

- `065f432` (2026-03-23, `refactor(init,config): replace hardcoded brew PATH with dynamic BASH_FILE`) introduced the dynamic `_bashDir` form, replacing a hardcoded `/opt/homebrew/bin`.
- `d2b9c81` (2026-04-16, `fix(config): ensure BASH_FILE dir is first in PATH, not just present`) tightened the check from "present anywhere" to "first" after a real macOS install was observed picking up `/bin/bash` because `path_helper` had appended brew at the end.

### Trailing `source` line

```bash
[ -f "$OOSH_DIR/log" ] && source "$OOSH_DIR/log"
```

A non-interactive shell that only sources `~/.bashrc` (e.g. a CI subprocess) won't have any `log.*` functions (`console.log`, `info.log`, `error.log`) because `this` hasn't run. Scripts that call those functions would silently no-op or fail with "command not found". Sourcing `$OOSH_DIR/log` directly gives those shells working logging primitives without depending on `this`.

Introduced by `c0b0a35` (2026-04-28, `fix(config.save): filter LOG_DEVICE; oosh.env auto-sources $OOSH_DIR/log for non-bashrc contexts`) — same commit that filtered `LOG_DEVICE`, deliberately bundled because the filter would otherwise have left non-bashrc shells without functioning log.

---

## Why `log.env` shrank

| Var | `main` | `dev` | Reason |
|---|---|---|---|
| `LOG_LEVEL` | `3` | `3` | The one genuinely user-configurable knob. Default `3` = "normal". Persisted on both. |
| `LOG_LEVEL_RESET` | absent | `3` | **Added on dev.** A "known-good restore value" for the debug command and test helpers that temporarily raise `LOG_LEVEL` (e.g. to 6 for trace) and then restore. Without it, callers had to hardcode `3` everywhere; now there's a single source of truth. Added by `39b0406` (2026-02-26). |
| `LOG_DEVICE` | `/dev/stdout` | filtered | **Removed on dev.** Per-session (`/dev/tty` for interactive shells, empty for non-tty subprocesses, varies by terminal). Persisting one user's value pollutes others' shells and breaks non-tty paths. Removed by `c0b0a35` (2026-04-28). The `oosh.env` auto-source of `$OOSH_DIR/log` provides working defaults instead. |
| `LOGNAME` | `test` | not captured | **Implicitly filtered by a stricter regex.** The `main` `config.save` grep was `" ${name}"` (loose substring). `declare -x LOGNAME="test"` contains ` LOGNAME` which contains ` LOG`, so it matched. Dev's grep is `" ${name}[_=]"` — requires a `_` or `=` immediately after `LOG`. `LOGNAME` has `N` after `LOG`, so it no longer matches. `LOGNAME` is a shell-builtin per-user identity var; persisting it across users is wrong. Tightened along with `b7f8b7c` (2026-04-27). |
| `HUSHLOGIN` | `FALSE` | not captured | Same mechanism — `HUSHLOGIN` was captured by `main`'s loose ` LOG` grep via the `LOGIN` substring; the stricter `[_=]` constraint on dev excludes it. `HUSHLOGIN` is a login-shell-managed variable that shouldn't be persisted. |

Net effect: `main`'s `log.env` had four entries, three of which leaked unrelated session state into shared config. `dev`'s has two, both genuinely configurable. The shrinkage isn't loss of functionality — it's an explicit "stop persisting things that aren't yours to persist". The `oosh.env` auto-source of `$OOSH_DIR/log` plus the in-`config.init` re-anchoring of `LOG_DEVICE` mean every shell still gets working logging without the file recording per-session noise.

---

## Per-difference attribution

Every visible difference between the two captures, mapped to the commit that introduced it on `dev`. All 15 SHAs verified present on `origin/dev`.

| Difference | Commit | Date | Subject (verbatim) | Why |
|---|---|---|---|---|
| `: ${CONFIG_PATH:="${BASH_SOURCE[0]%/*}"}` self-anchor at top of `user.env` | `099bb7b` | 2026-04-27 | `fix(config.save): self-anchor user.env via ${BASH_SOURCE} so it's sourceable without CONFIG_PATH` | Non-interactive shells (CI, `ssh exec`) that don't run `this` can resolve `$CONFIG_PATH` from the file's own location. |
| `: ${OOSH_DIR:=…}` self-anchor at top of `oosh.env` | `3596235` | 2026-04-27 | `fix(config.save): self-anchor OOSH_DIR in oosh.env so completion works in non-this contexts` | `bashrcTemplate` sources `oosh.env` BEFORE `this` runs; completion and log loading would break without an `OOSH_DIR` fallback. |
| OOSH_DIR anchor uses `cd … && pwd -P` (resolve symlink) | `f4966bd` | 2026-04-27 | `fix(config.save): resolve $HOME/oosh symlink in OOSH_DIR self-anchor (no self-loop)` | Prevents self-referential symlinks when `bashrcTemplate` auto-syncs. |
| `grep -v 'CONFIG='`, `'CONFIG_PATH='`, `'OOSH_DIR='`, `'OOSH_COMPONENTS_DIR='` in `config.save` | `b7f8b7c` | 2026-04-27 | `fix(config + ossh): drop persisted absolute paths; brew prereqs install bash + paths.d` | Stop leaking any one user's absolute home path into shared `user.env`. |
| `grep -v 'LOG_DEVICE='` in `config.save` | `c0b0a35` | 2026-04-28 | `fix(config.save): filter LOG_DEVICE; oosh.env auto-sources $OOSH_DIR/log for non-bashrc contexts` | `LOG_DEVICE` is per-session; persisting one user's value pollutes others. |
| PATH-builder block (`# Ensure OOSH_DIR is in PATH …`) in `oosh.env` | `ac302d8` | 2026-03-17 | `fix(config): append PATH builder to oosh.env so non-interactive shells work` | CI / `ssh exec` / subprocesses no longer rely on persisted PATH. |
| Dynamic `_bashDir` block based on `BASH_FILE` | `065f432` | 2026-03-23 | `refactor(init,config): replace hardcoded brew PATH with dynamic BASH_FILE` | No hardcoded `/opt/homebrew/bin`; works for any brew install location. |
| Strict-position check (`_bashDir` is FIRST in PATH) | `d2b9c81` | 2026-04-16 | `fix(config): ensure BASH_FILE dir is first in PATH, not just present` | macOS `path_helper` appends `/opt/homebrew/bin` at the end; brew bash must win lookups. |
| `LOG_LEVEL_RESET="3"` in `log.env` | `39b0406` | 2026-02-26 | `fix(oo): reset LOG_LEVEL to 3 in shared config after root install` | Root's quiet-mode install was persisting `LOG_LEVEL=1`, muting output for other users. |
| `config.init.{shared,user,check,full}` repair primitives | `920ff00` | 2026-04-30 | `feat(config): add init.{shared,user,check,full} repair primitives` | One-shot tools to repair tampered/corrupted layouts (symlinks, group ownership) without auto-fixing on every startup. |
| `config.init.env` env-file regenerator | `0631f7e` | 2026-04-30 | `feat(config): add init.env (env-file regen); revert SGID 2775 to match install` | Manually regenerate `user.env` + `oosh.env` + `log.env` via `config.save`; backs up `user.env` first. |
| Ownership repair → drop saga (Bug 1/2/3) | `21e737c` → `468d5a2` → `03fe62b` | 2026-05-07 → 2026-05-08 | `fix(install): root-cause WODA propagation + ~/config ownership for non-root users` → `fix(config.init): chown -h on symlinks (no clobber of sharedConfig)` → `revert(config.init): drop ownership-repair block (back to testing's form)` | Three-step debug: the install's symlink layout makes the in-`config.init` repair branch never fire correctly. Canonical ownership is the install's job; repair is `config init.shared` / `config init.user`'s job. |
| Minimal `init/oosh` + new `ossh.prereqs.install` | `014cf5d` | 2026-05-08 | `refactor(init/oosh,ossh): minimal init/oosh + new ossh.prereqs.install local mode` | Two-phase architecture: `init/oosh` shrinks to POSIX `sh` (pre-clone only); `ossh prereqs.install` runs post-clone for rsync/tree etc. |

`OOSH_BRANCH`, `OOSH_MODE`, `OOSH_OS`, `OOSH_SSH_CONFIG_HOST` in dev's `oosh.env` are NOT filtered by `config.save` because they're meaningful per-install state (which release line this user is on, what host this is). They get written when `oo mode <name>` switches mode (`oo:1486` etc. calls `config save oosh OOSH`). Their presence on dev and absence on `main` reflects the install pipeline maturing — not a save-filter difference.

---

## Chronological timeline

| Phase | When | Key commit(s) | Outcome |
|---|---|---|---|
| Early hardening | 2026-02-26 | `39b0406` | `LOG_LEVEL=3` reset in shared `log.env` so root's quiet install doesn't mute users. |
| Non-interactive shell fix | 2026-03-17 | `ac302d8` | PATH-builder appended to `oosh.env` so CI/subprocess shells work without persisted PATH. |
| macOS brew bash support | 2026-03-23 + 2026-04-16 | `065f432` + `d2b9c81` | Dynamic `_bashDir` from `BASH_FILE`, ensured FIRST in PATH (defeats `path_helper`). |
| Absolute-path leak fix (Phase A.1a) | 2026-04-27 | `b7f8b7c` + `099bb7b` + `3596235` + `f4966bd` | Strip CONFIG/CONFIG_PATH/OOSH_DIR/OOSH_COMPONENTS_DIR; self-anchor `user.env` + `oosh.env`; resolve symlinks. |
| LOG_DEVICE leak fix (Phase A.1b) | 2026-04-28 | `c0b0a35` | `LOG_DEVICE` filtered; `oosh.env` now sources `$OOSH_DIR/log` for non-bashrc defaults. |
| Repair primitives | 2026-04-30 | `920ff00` + `0631f7e` | `config init.{shared,user,check,env,full}` — explicit one-shot repair, no implicit fixups on shell startup. |
| Ownership debug saga (Bug 1→2→3) | 2026-05-07 → 2026-05-08 | `21e737c` → `468d5a2` → `03fe62b` | Tried to fix sudo-chain ownership inside `config.init`; broke shared dir; reverted. Recovery is now `config init.shared`. |
| Install architecture refactor | 2026-05-08 | `014cf5d` | Minimal POSIX `init/oosh`; `ossh prereqs.install` local mode handles rsync/tree etc. |

---

## Why `main` / `test/macos.latest` weren't simply merged

The older branches were never targets for these fixes — they pre-date the **shared-install model** that `dev` was hardened for. Their env files persist absolute single-user paths like `CONFIG=/home/test/config/user.env`, correct for a single-user Docker container but actively broken the moment two users share the same `~/config` symlink. Merging them backward would erase the entire April–May fix series (self-anchors, `config.save` filters, the `config.init.*` repair family, the ownership-saga conclusion) and re-introduce `EACCES` leaks on every multi-user host.

---

## Common questions

**Why is `OOSH_BRANCH=prod` saved at all?** Because `oo mode <name>` deliberately calls `config save oosh OOSH` to persist which release line the user is on. It's not a leak; the filter intentionally allows it. Filtering only removes per-machine absolutes, not per-user choices.

**What about pre-fix damaged installs?** Any install done before 2026-05-08 may have `sharedConfig` as `<user>:root 0775` instead of `developking:dev 2775`. Recovery is `config init.shared` (or the manual `chown -R developking:dev <path>; chmod -R g+w <path>` from the body of `03fe62b`'s commit message).

**Why is the repair `config init.*` explicit rather than automatic?** The May 8 saga proved that auto-repair on every shell startup (the deleted block in `03fe62b`) is fragile and clobbers shared state under sudo chains. The repair primitives now run only when called.

**How do I verify a given host's env files are 'current'?** Three indicators:

- `head -1 ~/config/user.env` should show `: ${CONFIG_PATH:="${BASH_SOURCE[0]%/*}"}`.
- `head -1 ~/config/oosh.env` should show `: ${OOSH_DIR:="$(cd "$HOME/oosh"…`.
- `grep CONFIG_PATH= ~/config/user.env` should return **empty** (it's filtered out).

If any of those fail, the env files are from before April 27, 2026 and should be regenerated with `config init.env`.

**What about the legacy `export declare X=` malformation?** Fixed in `bf69c59` and `beba799` (May 11–12, 2026). Today's `config.save` emits clean `export X=` lines, and `config.set` normalises legacy lines on update. Existing installs heal lazily as users `config.set` things, or instantly via `config init.env`.

**Is there a similar migration path for a drifted `~/.ssh`?** Yes — see [`docs/ossh.md` § Repairing a Broken `~/.ssh`](../ossh.md#repairing-a-broken-ssh). Use `ossh folder.fix.check` to inspect drift read-only, then `ossh folder.fix` (or `ossh folder.fix strict` to also prune known-stale legacy files) to converge to canonical. Same idempotent design as `config init.env` for env files.

---

## Files involved

- `config` — `config.save` filter pipeline (L540–550), `config.get` (L868), `config.set` (L883), `config.init.{shared,user,check,env,full}` (L195–462).
- `templates/user/bashrcTemplate` — the user bashrc that sources `oosh.env` first (before `this`), hence why `oosh.env` needs a self-anchor and the PATH-builder block.
- `~/config/user.env`, `~/config/oosh.env`, `~/config/log.env` — the runtime artifacts on each install.

## Verification commands

```bash
head -1 ~/config/user.env                                         # expect: : ${CONFIG_PATH:="${BASH_SOURCE[0]%/*}"}
head -1 ~/config/oosh.env                                         # expect: : ${OOSH_DIR:="$(cd "$HOME/oosh"…
grep -E '^export (declare )?CONFIG_PATH=' ~/config/user.env       # expect: empty (filtered)
grep -E '^export (declare )?OOSH_DIR='    ~/config/oosh.env       # expect: empty (filtered)
grep LOG_LEVEL_RESET ~/config/log.env                             # expect: present on dev, absent on main
```

If those match, the host is on the new model. If not, run `config init.env` to regenerate.
