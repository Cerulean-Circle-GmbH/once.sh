# Expert Task: Investigate Pane Title Lock

**From**: PO via session naming directive
**Priority**: Medium — after current work clears

## Problem

Claude Code overwrites tmux pane titles with subagent task descriptions. Every time a Task tool runs, the pane title changes. This makes `otmux tree` output unreadable.

## Investigation

Check whether tmux `allow-rename off` per pane prevents Claude Code from overwriting titles.

```bash
# Test: set a title then lock it
tmux select-pane -t cursorOrchestrator:0.4 -T "oosh-expert"
tmux set-option -p -t cursorOrchestrator:0.4 allow-rename off

# Then run something and check if title persists
```

## If It Works

Add an `otmux pane.lock` method that:
1. Sets the pane title via `otmux pane.title <pane> <title>`
2. Disables title renaming for that pane: `tmux set-option -p -t <pane> allow-rename off`
3. Tab completion for pane targets

And an `otmux pane.unlock` to re-enable if needed.

## When Done

Commit and report results.
