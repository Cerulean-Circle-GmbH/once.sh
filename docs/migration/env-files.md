# Env-file evolution: from `main` baseline to `dev`

A reference for understanding how `~/config/user.env`, `~/config/oosh.env`, and `~/config/log.env` are generated, why the `dev` versions look the way they do, and how an older host running pre-April-2026 code differs.

This document compares two ground-truth captures: the `main` branch (HEAD `c30787b`, March 2026; the same env-file generation logic lives on `test/macos.latest`) and `dev` (HEAD `beba799`, May 2026).

---

## TL;DR

The `main` baseline persists **absolute paths captured at install time** — `CONFIG="/home/test/config/user.env"`, `OOSH_DIR="/home/test/oosh"`, `LOG_DEVICE="/dev/stdout"`, `LOGNAME="test"`, the full `PATH`. That works for a single-user Docker container but breaks the moment a real install symlinks `~/config` and `~/oosh` to a **shared directory** where multiple users source from the same files: user-A's persisted `/home/A/...` becomes user-B's `EACCES`.

`dev` inverts the model. Per-user paths are **re-anchored at every shell init** via parameter-expansion defaults:

- `: ${CONFIG_PATH:="${BASH_SOURCE[0]%/*}"}` at the top of `user.env`
- `: ${OOSH_DIR:="$(cd "$HOME/oosh" 2>/dev/null && pwd -P || echo "$HOME/oosh")"}` at the top of `oosh.env`

And `config.save` actively **strips** volatile absolutes (`CONFIG=`, `CONFIG_PATH=`, `OOSH_DIR=`, `LOG_LIVE=`, `LOG_DEVICE=`, `OOSH_COMPONENTS_DIR=`, `INSTALL`). What survives is portable per-install state: `OOSH_BRANCH`, `OOSH_MODE`, `OOSH_OS`, `OOSH_PM`, `OOSH_PROMPT`, `OOSH_SHLVL`, `OOSH_STATUS`, `OOSH_SSH_CONFIG_HOST`, `LOG_LEVEL`, `LOG_LEVEL_RESET`, `BASH_FILE`, `CONFIG_FILE`.

Non-interactive shells (CI, `ssh exec`, completion) that don't run `this` get working defaults via the self-anchors. Brew bash on macOS gets PATH priority. Shared installs work without cross-user leaks.

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
