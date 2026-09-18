# oosh — host-wide login-shell bootstrap. MANAGED FILE: written by install
# state 34 (root.boot.path.installed) and by `oo boot.fix`; both overwrite it.
# Source: templates/user/profile.d.oosh.sh (oosh repo). Ticket T9 — see
# docs/boot.md "The three recovery routes".
#
# /etc/profile loops `for i in /etc/profile.d/*.sh`, so this is what makes
# `env -i sh -l` come up as an oosh shell. Bare `env -i sh` cannot be helped
# from here: a non-login POSIX sh reads only $ENV, and `env -i` is what
# erased it (hand it back with `env -i ENV=@SYSTEM_PATH@/boot sh`).
#
# POSIX sh. This runs for EVERY login shell on this host, including users who
# have never heard of oosh, so it must never break a login:
#   * no `exit` — it would close the login shell;
#   * no `return` — not every /etc/profile sources this from a function;
#   * every path guarded, every failure silent.
#
# TWO guards, both load-bearing:
#   1. the boot path must exist AND be readable. A missing or dangling
#      @SYSTEM_PATH@/boot is a silent no-op, not an error at the login prompt
#      (`-r` follows the symlink, so a dangling link is caught here).
#   2. the caller must actually HAVE an oosh install. Without this, every
#      non-oosh user on the box would get a nonexistent $HOME/oosh prepended
#      to PATH and an empty ~/.config/oosh created in their home just for
#      logging in. The exception is an UNSET $HOME — that is the `env -i sh -l`
#      recovery case this file exists for, and there `boot` derives $HOME from
#      the password database itself.
if [ -r "@SYSTEM_PATH@/boot" ]; then
  if [ -z "${HOME-}" ] || [ -d "$HOME/oosh" ]; then
    . "@SYSTEM_PATH@/boot"
  fi
fi
# boot returns non-zero when it legitimately refuses; a login shell must not
# inherit that as this fragment's status.
:
