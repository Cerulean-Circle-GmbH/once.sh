#!/usr/bin/env bash
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
OOSH_SELF_BRANCH="${OOSH_SELF_BRANCH:-testing}"

cd "$(dirname "$0")" || exit 1

printf '\n───────────────────────────────────────────────────────────────\n'
printf '  oosh install\n'
printf '  https://github.com/Cerulean-Circle-GmbH/once.sh  (branch: %s)\n' "$OOSH_SELF_BRANCH"
printf '───────────────────────────────────────────────────────────────\n\n'

if [ -x ./init/oosh ]; then
  ./init/oosh
else
  printf 'No sibling init/oosh — fetching from GitHub branch %s ...\n\n' "$OOSH_SELF_BRANCH"
  bash -c "$(curl -fsSL "https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/${OOSH_SELF_BRANCH}/init/oosh")"
fi
rc=$?

printf '\n'
if [ "$rc" -eq 0 ]; then
  printf '✓ Install complete. You can close this window.\n'
else
  printf '✗ Install failed (exit %d). Scroll up for details.\n' "$rc"
fi
printf '\n(Press Enter to close.)\n'
read -r _
