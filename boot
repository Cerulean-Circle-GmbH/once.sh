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

# ── 0. $HOME ────────────────────────────────────────────────────────────────
# EVERY anchor below hangs off $HOME, and `env -i` drops it (T3). DERIVE it —
# getent (Linux/NSS) -> dscl (macOS) -> /etc/passwd — rather than refuse; a HOME
# that is SET but not a directory gets the same treatment. Refuse only when all
# three come up empty, and by `return`, never `exit`: boot is SOURCED.
# DELIBERATELY DUPLICATED in init/oosh, which runs before oosh exists; neither
# file may source a shared helper. docs/boot.md § Why no-HOME needed fixing.
# BEGIN homeRecovery
if [ -z "$HOME" ] || [ ! -d "$HOME" ]; then
  _oosh_user=$(id -un 2>/dev/null)
  _oosh_home=""
  if [ -n "$_oosh_user" ]; then
    if command -v getent >/dev/null 2>&1; then
      # `head -1` is load-bearing: getent prints one line PER NSS SOURCE, so a
      # user present in both `files` and LDAP/SSSD yields two. Without it the
      # cut returns two lines, _oosh_home is non-empty so both fallbacks are
      # skipped, and `[ -d ]` on the two-line string fails — refusing while
      # holding a perfectly good home on line 1.
      _oosh_home=$(getent passwd "$_oosh_user" 2>/dev/null | head -1 | cut -d: -f6)
    fi
    if [ -z "$_oosh_home" ] && command -v dscl >/dev/null 2>&1; then
      # macOS returns TWO paths in one field for root ("/var/root
      # /private/var/root"); take the first — same as private.get.home.darwin.
      _oosh_home=$(dscl . -read "/Users/$_oosh_user" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
    fi
    if [ -z "$_oosh_home" ] && [ -r /etc/passwd ]; then
      _oosh_home=$(awk -F: -v u="$_oosh_user" '$1 == u { print $6; exit }' /etc/passwd)
    fi
  fi
  if [ -n "$_oosh_home" ] && [ -d "$_oosh_home" ]; then
    HOME="$_oosh_home"
    export HOME
    unset _oosh_user _oosh_home
  else
    echo "oosh boot: \$HOME is unset or not a directory, and no home could be" >&2
    echo "oosh boot: derived for '${_oosh_user:-?}' from getent, dscl or /etc/passwd." >&2
    echo "oosh boot: re-run with HOME set, e.g. HOME=/home/you sh -c '. ~/oosh/boot'" >&2
    unset _oosh_user _oosh_home
    return 1 2>/dev/null || exit 1
  fi
fi
# END homeRecovery

# ── 1. Anchors ──────────────────────────────────────────────────────────────
# OOSH_DIR is ALWAYS ~/oosh (the boss ruling) — the symlink path ITSELF, never
# its resolved target. That makes it a CONSTANT: switching branches only moves
# what ~/oosh points at, so the value never changes and this is the ONE place
# that sets it (see docs/boot.md "The OOSH_DIR rule"). Written "$HOME/oosh"
# because a tilde inside quotes does not expand. Code that genuinely needs the
# PHYSICAL directory resolves it at that spot (private.this.path.canonical).
export OOSH_DIR="$HOME/oosh"
# CONFIG_PATH follows the same rule for the same reason: it is ALWAYS ~/config,
# the per-user symlink itself, not the shared sharedConfig dir it points at.
# boot used to be the ONLY place that resolved it — config, log, ossh and this
# all already default to the literal — so the variable had two different values
# depending on which entry point ran. It is a constant now, set only here.
export CONFIG_PATH="$HOME/config"
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

# ── 4. Logging primitives + per-user session config (bash, non-POSIX only) ──
# Give console.log / info.log / error.log (and the per-user LOG_DEVICE/LOG_LIVE
# re-anchor) to contexts that never run `this` (CI steps, `ssh exec`).
# Idempotent — `this` sources log again later, a no-op the second time. Then
# log.session.save writes LOG_NAME / LOG_DEVICE / LOG_LIVE to the user's
# private ~/.config/oosh/log.session.env — per-user, no leak into shared log.env.
#
# `log` uses dotted function names, so it can only be sourced INTO a bash that
# is NOT in POSIX mode — both halves are load-bearing. macOS /bin/sh IS bash
# (3.2) in POSIX mode: $BASH_VERSION is set, a dotted name is not a valid
# identifier there, and A PARSE ERROR IN A SOURCED FILE UNDER POSIX MODE KILLS
# THE SHELL. So the guard is "bash AND NOT posix", read from $SHELLOPTS with
# `case` (parseable by dash/ash). A POSIX-mode shell comes up anchored but
# without the log functions — strictly better than a dead shell, and nothing
# below this block uses them. `bash --posix` reproduces it on Linux
# (test.config T70). ONE `if`, not two `&&` lists: an `&&` list whose first
# test is false yields status 1, which made a successful POSIX-sh boot exit 1
# (see section 5). Full account and measurements: docs/boot.md § The guard.
_oosh_posix=no
case ":$SHELLOPTS:" in
  *:posix:*) _oosh_posix=yes ;;
esac
if [ -n "$BASH_VERSION" ] && [ "$_oosh_posix" = no ]; then
  [ -f "$OOSH_DIR/log" ] && . "$OOSH_DIR/log"
  type log.session.save >/dev/null 2>&1 && log.session.save >/dev/null 2>&1
fi
unset _oosh_posix

# ── 5. Exit status ───────────────────────────────────────────────────────────
# boot succeeded — say so explicitly. Callers BRANCH on this status
# (`[ -f ~/oosh/boot ] && . ~/oosh/boot || <degrade>` in ossh exec / exec.tty
# and the user rootkey pushes), so the last statement here must never be a
# conditional list. `:` is rc 0 in every shell, sourced or executed.
:
