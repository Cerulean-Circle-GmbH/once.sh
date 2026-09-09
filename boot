#!/usr/bin/env sh
# OOSH boot loader — the SINGLE entry point that turns a bare shell into an
# oosh shell. EVERY context sources this: the interactive login shell
# (~/.bashrc), `ossh exec` / `ossh exec.tty`, the `os platform.test` per-user
# runners, `odocker` exec, and CI steps. It owns ALL the bootstrap logic that
# the old design generated INTO the config env files, so those files can stay
# PURE DATA (only `export KEY="VALUE"` lines). See docs/boot.md.
#
# POSIX sh only — NO bashisms (no `[[ ]]`, no arrays). It must source cleanly
# under dash (`ossh exec` on Debian), ash (Alpine/busybox), `env -i sh`, AND
# bash. This is also what makes `env -i sh` boot correctly.
#
# Idempotent: safe to source repeatedly (PATH additions are colon-guarded), so
# re-sourcing on `exec bash`, mode switches, or nested shells never grows PATH
# or double-applies anything.

# ── 1. Anchors ──────────────────────────────────────────────────────────────
# OOSH_DIR is ALWAYS ~/oosh (the boss ruling), resolved to its PHYSICAL target
# via `cd … && pwd -P`. Resolving matters two ways: (a) never anchor to the
# literal "$HOME/oosh" symlink string — that made bashrc's old auto-sync do
# `ln -s $HOME/oosh $HOME/oosh`, a self-referential loop ("Too many levels of
# symbolic links"); (b) it is derived from a FIXED, well-known location, never
# from `oo.mode.base.get` or a BASH_SOURCE walk. On a fresh box where the
# symlink/dir doesn't exist yet, fall back to the unresolved path.
export OOSH_DIR="$(cd "$HOME/oosh" 2>/dev/null && pwd -P || echo "$HOME/oosh")"
export CONFIG_PATH="$(cd "$HOME/config" 2>/dev/null && pwd -P || echo "$HOME/config")"
export CONFIG_FILE="user.env"
export CONFIG="$CONFIG_PATH/$CONFIG_FILE"

# ── 2. Source the config ─────────────────────────────────────────────────────
# Source ONLY user.env — it chains `source $CONFIG_PATH/oosh.env` /
# `log.env` itself (config.add appends those), so this one line stands up the
# whole config (single source of truth, no double-sourcing). CONFIG_PATH is
# already set above, so the chain resolves. Guarded: a missing file on a
# fresh/partial install is a silent no-op, not an error.
[ -f "$CONFIG_PATH/user.env" ] && . "$CONFIG_PATH/user.env"

# ── 3. PATH ──────────────────────────────────────────────────────────────────
# Ensure OOSH_DIR and OOSH_DIR/ng are on PATH so oo/os/ossh/config/this/c2/…
# resolve, and — if BASH_FILE is set — that its directory comes FIRST (brew
# bash on macOS must win over the /bin/bash that path_helper appends). Both
# checks are colon-anchored so they are exact-segment and idempotent.
# (This is the block that used to be generated into oosh.env.)
if [ -n "$OOSH_DIR" ]; then
  case ":$PATH:" in
    *":$OOSH_DIR:"*) : ;;
    *) PATH="$OOSH_DIR:$OOSH_DIR/ng:$PATH" ;;
  esac
  export PATH
fi
if [ -n "$BASH_FILE" ]; then
  _oosh_bashdir="$(dirname "$BASH_FILE")"
  case "$PATH" in
    "$_oosh_bashdir:"*) : ;;
    *) PATH="$_oosh_bashdir:$PATH"; export PATH ;;
  esac
  unset _oosh_bashdir
fi

# ── 4. Logging primitives ────────────────────────────────────────────────────
# Give console.log / info.log / error.log (and the per-user LOG_DEVICE/LOG_LIVE
# re-anchor) to contexts that never run `this` (CI steps, `ssh exec`). This is
# the line that used to be generated at the bottom of oosh.env. Idempotent —
# `this` sources log again later, a no-op the second time.
#
# `log` (like every oosh framework script) uses dotted function names and other
# bash features, so it can only be sourced INTO a bash shell. Guard on
# $BASH_VERSION: under a bare POSIX `sh` (the `env -i sh -c "$(curl init/oosh)"`
# bootstrap, which re-execs into bash almost immediately) we simply skip it —
# oosh requires bash 4+ to run anyway. This keeps `boot` sourceable under
# dash/ash without a "Bad function name" error.
[ -n "$BASH_VERSION" ] && [ -f "$OOSH_DIR/log" ] && . "$OOSH_DIR/log"
