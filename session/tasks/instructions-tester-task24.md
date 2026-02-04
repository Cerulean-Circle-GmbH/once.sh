# Task.24 Step 4: Tester Validation — Deterministic Agent Recovery

**From**: Orchestrator
**Task File**: session/tasks/Task.24.202602031154.md
**What to validate**: `context.recover` method (commit c87e96d)

## What Was Implemented

Expert added `context.recover <role>` to the `context` script. It enforces an identical post-compact recovery sequence for all agent roles:
- Displays context inline
- Prints SKILL.md and architecture paths
- Transitions lifecycle to active
- Outputs a numbered recovery checklist

Files changed: `context` (+79 lines), `docs/context-schema.md` (+29 lines)

## Validation Steps

### 1. Method exists and runs
```bash
./context recover orchestrator
./context recover oosh-expert
./context recover scrum-master
```
Each should produce output without errors.

### 2. Output includes required elements
For each role, verify the output contains:
- Context file contents (from `session/agents/<role>.context.md`)
- Path to SKILL.md for that role
- Path to architecture docs
- Lifecycle state transition
- Numbered recovery checklist

### 3. Fallback behavior
```bash
# Test with HIVEMIND_ROLE set
HIVEMIND_ROLE=oosh-tester ./context recover
```
Should use the environment variable when no argument is given.

### 4. Error handling
```bash
./context recover nonexistent-role
```
Should produce a clear error message, not crash.

### 5. Tab completion
```bash
./c2 function.completion ./context recover
```
Should list available roles.

### 6. Acceptance criteria check
- [ ] Recovery sequence is ordered, non-optional steps
- [ ] Recovery method callable by any agent post-compact
- [ ] All agents follow the same recovery path (no agent-specific logic)

## Report Results

Report PASS or FAIL with details to Orchestrator.
