# Tester: Validate Task 40.3 — Tab Completion for Team Selection

**Wait for**: Expert reports "Task 40.3 done"

## Tests

### Test 1: team methods complete
```bash
./c2 function.completion ./hiveMind team
# Should list team.list, team.status, and any new team methods
```

### Test 2: sweep session completion
```bash
./c2 function.completion ./hiveMind sweep
# Should offer session names (cursorOrchestrator, etc.)
```

### Test 3: send completion
```bash
./c2 function.completion ./hiveMind send
# Should offer agent names
```

### Test 4: Positional args, no flags
```bash
# Verify no --team flags in hiveMind
grep -n '\-\-team' hiveMind
# Should return nothing — OOSH uses positional args
```

### Test 5: Syntax check
```bash
bash -n hiveMind && echo "PASS" || echo "FAIL"
```

## When Done
Report: `Task 40.3 validation: PASS/FAIL`
