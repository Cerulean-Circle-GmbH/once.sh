# Expert: Fix claudeCode session.id for Active Sessions

**Priority**: Urgent — user reported bug
**Issue**: `claudeCode session.id tmpClaude:0.0` returns empty RESULT for active Claude Code instances

## Problem

Current implementation only extracts session ID from:
1. `--resume <UUID>` in process args (only works for resumed sessions)
2. `lsof` looking for `.claude/tasks/` (old format, doesn't work)

Active sessions store their data in `~/.claude/projects/<project-path>/<uuid>.jsonl`. The most recently modified file for the project is the active session.

## Fix: Add Method 3

After the existing two methods fail, add:

```bash
# Method 3: find most recent session file for the project
local cwd
cwd=$(lsof -p "$claude_pid" 2>/dev/null | awk '/cwd/ {print $NF}')
[ -z "$cwd" ] && return 1

# Convert path to project format: /Users/foo/bar → -Users-foo-bar
local project_path
project_path=$(echo "$cwd" | tr '/' '-' | sed 's/^-//')

local projects_dir="$HOME/.claude/projects/$project_path"
[ -d "$projects_dir" ] || return 1

# Find most recently modified .jsonl file
local newest_file
newest_file=$(ls -t "$projects_dir"/*.jsonl 2>/dev/null | head -1)
[ -z "$newest_file" ] && return 1

# Extract UUID from filename (remove path and .jsonl)
sid=$(basename "$newest_file" .jsonl)
[ -n "$sid" ] && echo "$sid" && return 0
```

## Test

```bash
./claudeCode session.id tmpClaude:0.0
# Should return a UUID like: 5b6cced8-3d53-4a36-a913-de2bb33c52a1
```

## Acceptance Criteria

- [ ] `claudeCode session.id <pane>` returns UUID for active Claude Code sessions
- [ ] Works for sessions NOT started with `--resume`
- [ ] Works for sessions started with `--resume` (existing behavior preserved)
- [ ] `bash -n claudeCode` passes

## When Done
Commit and report: `session.id fix done`
