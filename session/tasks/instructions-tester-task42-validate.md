# Tester: Validate Task 42 — DRY Session ID Detection

**Task file**: `session/tasks/Task.42.dry-session-id-detection.md`

## What to Test

Expert consolidated session ID detection into `claudeCode session.id` and updated `hiveMind team.status` to use it.

### Test 1: Canonical method exists
```bash
./c2 function.completion ./claudeCode session
# Should show session.id among completions
```

### Test 2: session.id returns a value for a known pane
```bash
./claudeCode session.id cursorOrchestrator:0.0
# Should return a session ID or error gracefully
```

### Test 3: team.status shows session IDs
```bash
./hiveMind team.status
# Should show session IDs for active agents (some may show * for stored fallback)
```

### Test 4: No duplicate detection logic
```bash
# Check that hiveMind doesn't have its own session ID parsing (should call claudeCode)
grep -n 'session.id\|lsof.*claude\|--resume' hiveMind | head -20
# The only session ID detection should be calls to claudeCode.session.id
```

### Test 5: Tab completion for session IDs
```bash
./c2 function.completion ./claudeCode session.id
# Should offer pane targets as completions
```

### Test 6: Syntax check
```bash
bash -n claudeCode && echo "PASS" || echo "FAIL"
bash -n hiveMind && echo "PASS" || echo "FAIL"
```

## When Done

Report: `Task 42 validation: PASS/FAIL` with details on each test.
