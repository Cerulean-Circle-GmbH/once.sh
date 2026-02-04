#!/bin/bash
# Restart hiveMind team after subscription limit reset
# Usage: ./session/restart-team.sh [--test]
# --test: dry run, prints what would be sent without sending

OOSH_DIR="/Users/Shared/Workspaces/AI/Claude/components/OOSH/dev.claude"
SESSION="cursorOrchestrator"
TEST_MODE="${1:-}"

# Fail fast if tmux session doesn't exist (avoids hang from send-keys to missing session)
if [ "$TEST_MODE" != "--test" ] && ! tmux -u has-session -t "$SESSION" 2>/dev/null; then
  echo "Error: tmux session '$SESSION' not found. Start the hiveMind team first (e.g. hiveMind team.setup.full)."
  exit 1
fi

send() {
  local pane="$1" msg="$2"
  if [ "$TEST_MODE" = "--test" ]; then
    echo "[DRY RUN] Would send to $pane: $msg"
  else
    "$OOSH_DIR/otmux" send "${SESSION}:${pane}" "$msg" Enter
    echo "[SENT] $pane: $msg"
    sleep 2
  fi
}

echo "=== hiveMind Team Restart ==="
echo "Session: $SESSION"
echo "Time: $(date)"
echo ""

# Resume Orchestrator
send 0.0 'Subscription limit has reset. Read session/agent.context.md and resume operations. Check all agents via ScrumMaster.'

# Resume ScrumMaster
send 0.6 'Subscription limit has reset. Read session/agents/scrum-master.context.md and .claude/agents/scrum-master/SKILL.md then resume monitoring all agent panes. Do not wait for further instructions.'

echo ""
echo "=== Restart complete ==="
