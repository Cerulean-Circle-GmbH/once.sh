# Tester: Validate Task 40.1 — hiveMind Multi-Team Support

**Task**: Task 40.1 (subtask of Task 40 CMM4)
**Wait for**: Expert commit (will report "Task 40.1 done")

## What to Test

Expert is adding multi-team awareness to hiveMind. Validate all acceptance criteria:

### Test 1: team.list shows registered sessions
```bash
./hiveMind team.list
# Should show at least "cursorOrchestrator"
```

### Test 2: team.status summary (no arg)
```bash
./hiveMind team.status
# Should show one-line summary per registered team
# Format: session_name  N agents  (X active, Y idle)
```

### Test 3: team.status detailed (with session arg)
```bash
./hiveMind team.status cursorOrchestrator
# Should show per-pane details (existing behavior)
```

### Test 4: Tab completion
```bash
./c2 function.completion ./hiveMind team.list
./c2 function.completion ./hiveMind team.status
# Both should offer session names as completions
```

### Test 5: Cross-team registration
```bash
# Register a fake claudeWoda agent
./hiveMind register claudeWoda:0.0 test-agent
# Verify it shows up
./hiveMind team.list
# Should now show both cursorOrchestrator and claudeWoda
./hiveMind team.status
# Should show both teams
# Clean up
grep -v 'claudeWoda:0.0' /tmp/hivemind.roles > /tmp/hivemind.roles.tmp && mv /tmp/hivemind.roles.tmp /tmp/hivemind.roles
```

### Test 6: Syntax check
```bash
bash -n hiveMind && echo "PASS" || echo "FAIL"
```

### Test 7: Existing functionality not broken
```bash
./hiveMind sweep 2>/dev/null | head -5
# Should still work — shows pane content
```

## When Done
Report: `Task 40.1 validation: PASS/FAIL` with details on each test.
