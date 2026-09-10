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
# OOSH_DIR is ALWAYS ~/oosh (the boss ruling) — the symlink path ITSELF, never
# its resolved target. That makes it a CONSTANT: switching branches only moves
# what ~/oosh points at, so the value never changes and this is the ONE place
# that sets it (see docs/boot.md "The OOSH_DIR rule"). Written "$HOME/oosh"
# because a tilde inside quotes does not expand. Code that genuinely needs the
# PHYSICAL directory resolves it at that spot (private.this.path.canonical).
export OOSH_DIR="$HOME/oosh"
export CONFIG_PATH="$(cd "$HOME/config" 2>/dev/null && pwd -P || echo "$HOME/config")"
export CONFIG_FILE="user.env"
export CONFIG="$CONFIG_PATH/$CONFIG_FILE"
# Per-user (NON-shared) oosh config dir — single source of truth for per-user /
# per-session state (log.session.env, log.live.out, oo's mode-env.bash). Unlike
# CONFIG_PATH (which usually symlinks to a shared sharedConfig), this is always
# the user's own. log/config/oo reference $OOSH_USER_CONFIG_PATH, not the literal.
export OOSH_USER_CONFIG_PATH="$HOME/.config/oosh"

# Ensure the per-user log session file exists BEFORE user.env's chain sources it
# (log.env ends with `source $OOSH_USER_CONFIG_PATH/log.session.env`). It is
# populated properly by log.session.save further down; this just prevents a
# "No such file" error on the very first shell, before it has ever been written.
mkdir -p "$OOSH_USER_CONFIG_PATH" 2>/dev/null
[ -f "$OOSH_USER_CONFIG_PATH/log.session.env" ] || : > "$OOSH_USER_CONFIG_PATH/log.session.env"

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

# ── 5. Materialise the per-user/session log config ───────────────────────────
# Delegate to log's own method (bash only). This writes LOG_NAME / LOG_DEVICE /
# LOG_LIVE to the user's private ~/.config/oosh/log.session.env — per-user, no
# leak into the shared log.env. Once per shell (boot runs once).
[ -n "$BASH_VERSION" ] && type log.session.save >/dev/null 2>&1 && log.session.save >/dev/null 2>&1
