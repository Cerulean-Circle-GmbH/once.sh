#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# PreCompact Hook — Validate agent context before /compact
# ─────────────────────────────────────────────────────────────────────────────
#
# Standalone script (no OOSH bootstrap needed).
# Called by Claude Code before /compact runs.
#
# Checks:
#   1. HIVEMIND_ROLE is set
#   2. Context file exists at session/agents/<role>.context.md
#   3. Required sections present (Updated, Recovery Steps, Completed Work)
#
# Always exits 0 — PreCompact cannot block, only warn.
# ─────────────────────────────────────────────────────────────────────────────

ROLE="${HIVEMIND_ROLE:-}"

if [ -z "$ROLE" ]; then
  echo "PreCompact: HIVEMIND_ROLE not set — skipping context check"
  exit 0
fi

# Resolve project directory (CLAUDE_PROJECT_DIR or script location)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
CONTEXT_FILE="$PROJECT_DIR/session/agents/${ROLE}.context.md"

if [ ! -f "$CONTEXT_FILE" ]; then
  echo "PreCompact WARNING: Context file missing: $CONTEXT_FILE"
  echo "  Save your context before compacting!"
  echo "  Run: ./context lifecycle.save $ROLE"
  exit 0
fi

# Check required sections
MISSING=0

if ! head -6 "$CONTEXT_FILE" | grep -q '^\*\*Updated\*\*:'; then
  echo "PreCompact WARNING: Missing **Updated** metadata"
  MISSING=$((MISSING + 1))
fi

if ! grep -q '^## Recovery' "$CONTEXT_FILE"; then
  echo "PreCompact WARNING: Missing ## Recovery Steps section"
  MISSING=$((MISSING + 1))
fi

if ! grep -q '^## Completed' "$CONTEXT_FILE"; then
  echo "PreCompact WARNING: Missing ## Completed Work section"
  MISSING=$((MISSING + 1))
fi

if [ $MISSING -gt 0 ]; then
  echo "PreCompact WARNING: Context file has $MISSING issue(s)"
  echo "  Update your context file before compacting!"
  echo "  Run: ./context lifecycle.save $ROLE"
else
  echo "PreCompact: Context validated for role '$ROLE'"
fi

exit 0
