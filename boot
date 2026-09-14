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
# EVERY anchor below hangs off $HOME — and `env -i` drops it, which is exactly
# the "env -i sh … shall boot correctly" case. So DERIVE it from the password
# database rather than give up: that is precisely what bash itself does for `~`
# when HOME is unset, and it is what makes
#   env -i sh -c '. /path/to/oosh/boot'
# come out with a working oosh instead of OOSH_DIR=/oosh and CONFIG_PATH=/config.
#
# A HOME that is SET but not a directory (a removed user, a container that
# inherited the builder's) is the same broken input and gets the same treatment.
#
# Three-way lookup, same split the rest of the tree uses (see this:126-134):
# getent (Linux/NSS) → dscl (macOS) → /etc/passwd (minimal images with neither).
# Only if all three come up empty do we refuse — and then by `return`, never
# `exit`, because boot is SOURCED and exit would close the user's terminal.
if [ -z "$HOME" ] || [ ! -d "$HOME" ]; then
  _oosh_user=$(id -un 2>/dev/null)
  _oosh_home=""
  if [ -n "$_oosh_user" ]; then
    if command -v getent >/dev/null 2>&1; then
      _oosh_home=$(getent passwd "$_oosh_user" 2>/dev/null | cut -d: -f6)
    fi
    if [ -z "$_oosh_home" ] && command -v dscl >/dev/null 2>&1; then
      # macOS returns TWO paths in one field for root ("/var/root
      # /private/var/root"), so take the first — same as private.get.home.darwin.
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
    echo "oosh boot: derived for '${_oosh_user:-?}' from getent/dscl//etc/passwd." >&2
    echo "oosh boot: re-run with HOME set, e.g. HOME=/home/you sh -c '. ~/oosh/boot'" >&2
    unset _oosh_user _oosh_home
    return 1 2>/dev/null || exit 1
  fi
fi

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

# ── 1b. RESTORE MODE ─────────────────────────────────────────────────────────
# T3's card: "env -i sh. SAVETY...shall boot correctly" — env INITIATE. On a box
# whose ANCHORS are wrong (~/oosh missing, dangling, or a real directory; ~/config
# gone) no oosh command is reachable, so the repair has to come from here.
#
# Two routes, because a SOURCED script cannot know its own path under POSIX sh
# ($0 is the shell name) — only bash has BASH_SOURCE. An EXECUTED script's $0 IS
# its path, in every shell, including under `env -i`:
#
#   . <tree>/boot     bash, sourced   -> repairs, and THIS shell comes up working
#   <tree>/boot       any shell, run  -> repairs the box; start a new shell
#
# Cheap: two file tests on a healthy box, then nothing. Only when an anchor is
# actually broken do we hand off to `config env.init`, which owns the repair.
# Invoked as a COMMAND (config is bash, this may be dash) and by absolute path,
# since PATH is not built yet.
#
# oosh-dir-exception: recovery anchors to the tree boot was RUN FROM, not to
# ~/oosh — on a broken box ~/oosh is precisely what cannot be trusted.
if [ -z "$OOSH_BOOT_NO_RECONSTRUCT" ]; then
  _oosh_self=""
  case "$0" in
    */boot|boot) [ -f "$0" ] && _oosh_self="$0" ;;
  esac
  # Guarded so dash never EVALUATES the bashism (it parses fine either way).
  if [ -z "$_oosh_self" ] && [ -n "$BASH_VERSION" ]; then
    _oosh_self="${BASH_SOURCE[0]}"
  fi
  if [ -n "$_oosh_self" ]; then
    _oosh_selfdir=$(cd "$(dirname "$_oosh_self")" 2>/dev/null && pwd -P)
    # If we were reached THROUGH ~/oosh, that anchor works by definition — this
    # is an ordinary boot, not a rescue. Skipping here also keeps restore out of
    # the installer's way: during install ~/oosh is legitimately mid-flight, and
    # a login shell sourcing ~/oosh/boot must not start repairing underneath it.
    _oosh_home_real=$(cd "$HOME/oosh" 2>/dev/null && pwd -P)
    if [ -n "$_oosh_home_real" ] && [ "$_oosh_selfdir" = "$_oosh_home_real" ]; then
      _oosh_selfdir=""
    fi
    # Trigger on ~/oosh ONLY — the anchor whose breakage makes oosh unreachable
    # and so makes this entry point necessary at all. A missing ~/config with a
    # working ~/oosh is NOT boot's business: oosh commands still run there, so
    # `config init.user` (its owner) can be invoked normally. Keeping the trigger
    # to one anchor also keeps boot from becoming a second install path — a box
    # that simply has not been set up for this user must pass through silently.
    if [ ! -f "$HOME/oosh/this" ]; then
      # ...and are we standing in a real oosh tree to anchor TO?
      if [ -n "$_oosh_selfdir" ] && [ -f "$_oosh_selfdir/this" ] \
         && [ -f "$_oosh_selfdir/config" ] && [ -f "$_oosh_selfdir/oo" ]; then
        # PATH first: config.start does `source this`, which resolves via PATH.
        # Without this it fails with "this: No such file or directory" — and a
        # host test can MASK that, because bash's `source` also searches the
        # current directory, so running from inside the tree makes it pass.
        PATH="$_oosh_selfdir:$_oosh_selfdir/ng:$PATH" \
          "$_oosh_selfdir/config" env.init "$_oosh_selfdir"
      fi
    fi
    unset _oosh_selfdir _oosh_home_real
  fi
  unset _oosh_self
fi

# ── 2. Source the config ─────────────────────────────────────────────────────
# Source ONLY user.env — it chains `source $CONFIG_PATH/oosh.env` /
# `log.env` itself (config.add appends those), so this one line stands up the
# whole config (single source of truth, no double-sourcing). CONFIG_PATH is
# already set above, so the chain resolves. Guarded: a missing file on a
# fresh/partial install is a silent no-op, not an error.
[ -f "$CONFIG_PATH/user.env" ] && . "$CONFIG_PATH/user.env"

# ── 2b. Source the PER-USER session file ─────────────────────────────────────
# LOG_NAME / LOG_DEVICE / LOG_LIVE are per-user, so they live in the user's OWN
# $OOSH_USER_CONFIG_PATH, never in the shared config. boot sources that file
# HERE, directly — the SHARED log.env does NOT chain it.
#
# It used to: config.save appended `. $OOSH_USER_CONFIG_PATH/log.session.env` to
# the shared log.env. That put a PER-USER reference inside a SHARED file, and a
# cross-user sub-shell that inherited someone else's OOSH_USER_CONFIG_PATH then
# resolved it to THEIR directory — "/root/.config/oosh/log.session.env:
# Permission denied" all over the install log. Shared files now hold only shared
# data, so that whole class of breakage is gone. (Old installs may still carry
# the stale line; it is harmless — pure data, sourced twice at worst — and the
# next `config save` regenerates log.env without it.)
[ -f "$OOSH_USER_CONFIG_PATH/log.session.env" ] && . "$OOSH_USER_CONFIG_PATH/log.session.env"

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

# ── 4. Logging primitives + per-user session config (bash only) ──────────────
# Give console.log / info.log / error.log (and the per-user LOG_DEVICE/LOG_LIVE
# re-anchor) to contexts that never run `this` (CI steps, `ssh exec`). This is
# the line that used to be generated at the bottom of oosh.env. Idempotent —
# `this` sources log again later, a no-op the second time. Then log.session.save
# writes LOG_NAME / LOG_DEVICE / LOG_LIVE to the user's private
# ~/.config/oosh/log.session.env — per-user, no leak into the shared log.env.
#
# `log` (like every oosh framework script) uses dotted function names and other
# bash features, so it can only be sourced INTO a bash shell. Guard on
# $BASH_VERSION: under a bare POSIX `sh` (the `env -i sh -c "$(curl init/oosh)"`
# bootstrap, which re-execs into bash almost immediately) we simply skip it —
# oosh requires bash 4+ to run anyway. This keeps `boot` sourceable under
# dash/ash without a "Bad function name" error.
#
# ONE `if`, not two `&&` lists: an `&&` list whose first test is false yields
# status 1, and under sh/dash/ash $BASH_VERSION is ALWAYS empty — which made a
# perfectly successful POSIX-sh boot exit 1 (see section 5).
if [ -n "$BASH_VERSION" ]; then
  [ -f "$OOSH_DIR/log" ] && . "$OOSH_DIR/log"
  type log.session.save >/dev/null 2>&1 && log.session.save >/dev/null 2>&1

  # ── 4b. SAFETY NET: reconstruct a missing shared config ────────────────────
  # Every source above is `[ -f … ] &&`-guarded, so a missing config is silently
  # SKIPPED — you get a shell that looks fine and has no environment.
  #
  # The check here is three `[ -f ]` tests: free, and on a healthy shell that is
  # ALL that runs — no subprocess, no cost. Only when something is actually
  # missing do we hand off to `config reconstruct`, which owns the decision:
  # rebuild when all three are gone (nothing to destroy), otherwise REPORT and
  # name `config init.env`, because regenerating a populated sharedConfig would
  # stamp THIS shell's values onto every user who symlinks to it.
  #
  # Invoked as a COMMAND, not sourced: sourcing `config` runs its top level,
  # which has side effects (it will create $CONFIG_PATH). A subprocess keeps
  # boot's shell clean.
  #
  # An absent $CONFIG_PATH is left alone — not installed is not broken, and
  # install belongs to the state machine, not to boot. The per-user session file
  # needs no repair either: log.session.save above rewrites it every shell.
  #
  # OOSH_BOOT_NO_RECONSTRUCT=1 opts out — for the install pipeline (which owns
  # its own repair) and for fixtures that must not heal the tree under test.
  if [ -z "$OOSH_BOOT_NO_RECONSTRUCT" ] && [ -d "$CONFIG_PATH" ]; then
    if [ ! -f "$CONFIG_PATH/user.env" ] || [ ! -f "$CONFIG_PATH/oosh.env" ] \
       || [ ! -f "$CONFIG_PATH/log.env" ]; then
      [ -x "$OOSH_DIR/config" ] && "$OOSH_DIR/config" reconstruct
    fi
  fi
fi

# ── 5. Exit status ───────────────────────────────────────────────────────────
# boot succeeded — say so explicitly. Callers BRANCH on this status
# (`[ -f ~/oosh/boot ] && . ~/oosh/boot || <degrade>` in ossh exec / exec.tty
# and the user rootkey pushes), so the last statement here must never be a
# conditional list. `:` is rc 0 in every shell, sourced or executed.
:
