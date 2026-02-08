# Tester: Validate Task 40.2 — sweep.detect Improvements

**Wait for**: Expert reports "Task 40.2 done"

## Tests

### Test 1: New detection types exist
```bash
grep -n 'accept-edits\|context-warning\|choice-prompt\|shell-escaped\|just-compacted' hiveMind | head -10
# Should show new detection patterns in sweep.detect
```

### Test 2: accept-edits detection works
```bash
# Check current agents — many show "accept edits on"
./hiveMind sweep 2>/dev/null | grep -c 'accept edits'
# sweep.detect should classify these as accept-edits
```

### Test 3: Existing detections preserved
```bash
# Permission Allow/Deny and Yes/No (Task 41) must still work
grep -n 'Allow.*Deny\|Do you want to proceed' hiveMind | head -5
```

### Test 4: unblock only acts on actionable states
```bash
# unblock should handle permission + accept-edits, skip context-warning/shell-escaped
grep -A 5 'unblock.*pane\|enter.*action' hiveMind | head -20
```

### Test 5: Syntax check
```bash
bash -n hiveMind && echo "PASS" || echo "FAIL"
```

## When Done
Report: `Task 40.2 validation: PASS/FAIL`
