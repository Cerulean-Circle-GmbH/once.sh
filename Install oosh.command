#!/usr/bin/env bash
# ogit-exception-file: macOS double-click installer wrapper, runs before oosh exists
# macOS drag-and-drop wrapper for oosh install. Two usage modes:
#
#   1. Downloaded standalone (single file in ~/Downloads or wherever).
#      No sibling init/oosh exists → we curl-pipe the one-liner instead.
#
#   2. Inside a clone / extracted ZIP (init/oosh sits next to us).
#      Run the local ./init/oosh directly.
#
# Double-click in Finder → Terminal.app opens, runs the install, keeps
# the window open via `read` so the user sees success/failure.
#
# First-run on macOS may show "cannot be opened because developer cannot
# be verified." Workaround: right-click this file → Open → Open. Once
# approved, double-click works forever after.

# Rewritten by `promote` during dev→testing→prod advancement
# (see private.promote.rewrite.self.branch in promote). Must match the
# same pattern init/oosh uses so the rewriter's regex matches this line.
OOSH_SELF_BRANCH="${OOSH_SELF_BRANCH:-dev}"

cd "$(dirname "$0")" || exit 1

printf '\n───────────────────────────────────────────────────────────────\n'
printf '  oosh install\n'
printf '  https://github.com/Cerulean-Circle-GmbH/once.sh  (branch: %s)\n' "$OOSH_SELF_BRANCH"
printf '───────────────────────────────────────────────────────────────\n\n'

# Fetcher detection, matching the prereq table in README.md. A naked
# ubuntu:24.04 ships none of curl/wget/fetch, and the old one-liner here was
#   sh -c "$(curl -fsSL "$url")"
# — command-substituting a MISSING curl yields the empty string, `sh -c ""`
# exits 0, and this wrapper then printed "✓ Install complete." having
# installed absolutely nothing. Silence plus a green tick is the worst
# failure mode an installer can have, so every step below is checked.
oosh_fetch() { # <url> <destFile> # 0 on a real download, 127 when no fetcher exists
  if   command -v curl  >/dev/null 2>&1; then curl -fsSL "$1" -o "$2"
  elif command -v wget  >/dev/null 2>&1; then wget -q -O "$2" "$1"
  elif command -v fetch >/dev/null 2>&1; then fetch -q -o "$2" "$1"
  else return 127
  fi
}

if [ -x ./init/oosh ]; then
  ./init/oosh
  rc=$?
else
  printf 'No sibling init/oosh — fetching from GitHub branch %s ...\n\n' "$OOSH_SELF_BRANCH"
  url="https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/${OOSH_SELF_BRANCH}/init/oosh"
  tmp="$(mktemp "${TMPDIR:-/tmp}/oosh-init.XXXXXX" 2>/dev/null)" || tmp="${TMPDIR:-/tmp}/oosh-init.$$"

  oosh_fetch "$url" "$tmp"
  fetchRc=$?

  if [ "$fetchRc" -eq 127 ]; then
    printf '✗ No downloader found — oosh needs one of curl, wget or fetch.\n' >&2
    printf '  Install one, then run this file again:\n' >&2
    printf '    Debian/Ubuntu : sudo apt-get update && sudo apt-get -y install curl\n' >&2
    printf '    Alpine        : sudo apk add curl\n' >&2
    printf '    RHEL/Fedora   : sudo dnf -y install curl\n' >&2
    printf '    macOS         : curl ships with the system — check your PATH\n' >&2
    rm -f "$tmp"
    rc=127
  elif [ "$fetchRc" -ne 0 ]; then
    printf '✗ Download failed (exit %d):\n    %s\n' "$fetchRc" "$url" >&2
    printf '  Check the branch name and your network, then run this file again.\n' >&2
    rm -f "$tmp"
    rc="$fetchRc"
  elif [ ! -s "$tmp" ] || [ "$(wc -c < "$tmp" 2>/dev/null || echo 0)" -lt 1024 ]; then
    printf '✗ Downloaded file is too small to be init/oosh (%s bytes):\n    %s\n' \
      "$(wc -c < "$tmp" 2>/dev/null || echo 0)" "$url" >&2
    printf '  GitHub probably served an error page — is branch "%s" real?\n' "$OOSH_SELF_BRANCH" >&2
    rm -f "$tmp"
    rc=1
  else
    # `sh -c "$(cat …)"` on purpose, NOT `sh "$tmp"`: init/oosh branches on
    # whether $0 is a real file (its pre-clone before the sudo re-exec, and
    # its OOSH_DIR derivation). Feeding it the TEXT keeps $0 == "sh" and
    # keeps this path on exactly the branch T-INIT-SUDO-CURL-PIPE covers.
    # Only the FETCH moved out of the substitution — that is the whole fix.
    sh -c "$(cat "$tmp")"
    rc=$?
    rm -f "$tmp"
  fi
fi

printf '\n'
if [ "$rc" -eq 0 ]; then
  printf '✓ Install complete. You can close this window.\n'
else
  printf '✗ Install failed (exit %d). Scroll up for details.\n' "$rc"
fi
printf '\n(Press Enter to close.)\n'
read -r _
# The last command used to be `read`, so this file's exit status was read's,
# never the install's. Keeps the Finder window-hold behaviour above, and makes
# the status real for anything that runs this non-interactively.
exit "$rc"
