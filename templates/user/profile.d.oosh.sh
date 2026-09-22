# oosh — host-wide login-shell bootstrap. MANAGED FILE: written by install
# state 34 (root.profile.dropin.installed) and by `oo profile.fix`; both
# overwrite it. Source: templates/user/profile.d.oosh.sh (oosh repo).
#
# /etc/profile loops `for i in /etc/profile.d/*.sh`, so this is what makes
# `env -i sh -l` come up as an oosh shell. POSIX sh; it runs for EVERY login
# on this host: never `exit` (it would close the login shell), never `return`
# (not every /etc/profile sources this from a function), every path guarded.
#
# 1. $HOME — `env -i` drops it and every anchor hangs off it. Derive it:
#    getent (Linux/NSS) -> dscl (macOS) -> /etc/passwd. On failure fall
#    through silently; the user gets a plain login shell. DELIBERATELY
#    DUPLICATED in init/oosh, which runs before oosh exists; neither file may
#    source a shared helper. test.install T-HOME-RECOVERY-NSS runs BOTH blocks.
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
  fi
  unset _oosh_user _oosh_home
fi
# END homeRecovery
# 2. An oosh user has ~/config/user.env — the anchors, the env chain and the
#    PATH prepend, as data. A user without one is left exactly as found.
if [ -n "${HOME-}" ] && [ -f "$HOME/config/user.env" ]; then
  . "$HOME/config/user.env"
fi
:
