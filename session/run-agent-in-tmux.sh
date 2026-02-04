#!/usr/bin/env bash
# Run Cursor agent with env + PTY wrapper so the TUI renders in tmux (fix blank/hang).
# Usage: run-agent-in-tmux.sh
# In tmux: tmux new-session -d -s agent "bash -c 'unset CI; export TERM=xterm-256color COLORTERM=truecolor FORCE_COLOR=1; exec script -q /dev/null \$HOME/.local/bin/agent'"

set -e
AGENT="${HOME}/.local/bin/agent"
[ -x "$AGENT" ] || { echo "agent not found: $AGENT"; exit 1; }

# TUI-friendly env (avoid CI, set terminal type and color)
unset CI
export TERM="${TERM:-xterm-256color}"
export COLORTERM="${COLORTERM:-truecolor}"
export FORCE_COLOR="${FORCE_COLOR:-1}"

# Run agent (script -q forces a PTY; can help TUIs in tmux)
if command -v script &>/dev/null; then
  exec script -q /dev/null "$AGENT"
else
  exec "$AGENT"
fi
