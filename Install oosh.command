#!/usr/bin/env bash
# macOS drag-and-drop wrapper. Double-click in Finder → Terminal.app
# opens, runs the install, keeps the window open so the user sees the
# outcome.
#
# First-run on macOS may show "cannot be opened because developer cannot
# be verified." Workaround: right-click this file → Open → Open.
# Once approved, double-click works forever after.

cd "$(dirname "$0")" || exit 1

printf '\n───────────────────────────────────────────────────────────────\n'
printf '  oosh install\n'
printf '  https://github.com/Cerulean-Circle-GmbH/once.sh\n'
printf '───────────────────────────────────────────────────────────────\n\n'

./init/oosh
rc=$?

printf '\n'
if [ "$rc" -eq 0 ]; then
  printf '✓ Install complete. You can close this window.\n'
else
  printf '✗ Install failed (exit %d). Scroll up for details.\n' "$rc"
fi
printf '\n(Press Enter to close.)\n'
read -r _
