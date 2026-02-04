# Instruction: ScrumMaster — Use OOSH Commands Only

**From**: Orchestrator
**To**: ScrumMaster (0.6)
**Priority**: IMMEDIATE — PO violation

## Problem

You are using raw tmux commands instead of OOSH wrappers. This violates the OOSH-Only rule.

## Violations Found

| You are using | You MUST use instead |
|---------------|---------------------|
| `tmux capture-pane -t <pane> -p -S -15` | `./otmux pane.capture <pane> 15` |
| `tmux send-keys -t <pane> Down Enter` | `./otmux send <pane> Down Enter` |
| `tmux send-keys -t <pane> Enter` | `./otmux send <pane> Enter` |
| `tmux send-keys -t <pane> Escape` | `./otmux send <pane> Escape` |

## Why

Raw tmux bypasses logging, naming, and the role registry. OOSH wrappers maintain consistency. This is a MANDATORY rule — no exceptions.

## Action Required

1. Stop using ANY raw tmux commands immediately
2. Replace all `tmux capture-pane` with `./otmux pane.capture`
3. Replace all `tmux send-keys` with `./otmux send`
4. Continue monitoring all panes including PO (0.1)
