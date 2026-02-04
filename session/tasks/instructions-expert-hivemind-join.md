# Task: Implement hiveMind join <name> with Tab Completion

**From**: Orchestrator (PO directive)
**To**: Expert (0.4)
**Priority**: HIGH

## Problem

When an agent's Claude session exits (crashes, compact loop, manual exit), we need to rejoin their session. Currently there is no way to:
1. Know which Claude session ID belongs to which agent role
2. Resume a session by role name instead of UUID

The PO just exited and couldn't find their session. We had to grep JSONL files manually.

## Required: hiveMind.join

```bash
# Usage
./hiveMind join <role-name>

# Example
./hiveMind join product-owner
# → Resolves pane from /tmp/hivemind.roles
# → Finds the most recent Claude session for that pane/role
# → Runs: claude --resume <session-id> in that pane
```

## Implementation Plan

### 1. hiveMind.join method
```bash
hiveMind.join() # <name> # rejoin an agent's Claude session by role name
{
  local name="$1"
  local target=$(./hiveMind resolve "$name")
  # Find session ID — check session files for role mentions
  # or store session IDs in /tmp/hivemind.roles when teaching
  local session_id=$(private.find.session "$name")
  # Send resume command to the pane (use -l for literal text!)
  tmux send-keys -t "$target" -l "claude --resume $session_id"
  sleep 0.05
  tmux send-keys -t "$target" Enter
}
```

### 2. Tab completion for role names
```bash
hiveMind.join.completion.name() {
  ./hiveMind role.list
}
```

### 3. Session ID tracking
When teaching a role (`hiveMind role.teach`), store the session ID:
- Read it from the pane after Claude starts
- Or store in `/tmp/hivemind.sessions` mapping role → session UUID

### 4. Bug fix: hiveMind send garbles spaces
`hiveMind send` uses `tmux send-keys` WITHOUT the `-l` flag, causing spaces to be stripped. Fix it to use `-l` like `otmux send.enter` does. This is the ROOT CAUSE of all garbled messages from agents using hiveMind send.

## Acceptance Criteria

- [ ] `./hiveMind join product-owner` resumes the PO's session in the correct pane
- [ ] Tab completion lists all role names
- [ ] Session IDs tracked across teaches/restarts
- [ ] `./hiveMind send` fixed to preserve spaces (use `-l` flag)
- [ ] Works after pane layout changes (uses resolve, not hardcoded addresses)
