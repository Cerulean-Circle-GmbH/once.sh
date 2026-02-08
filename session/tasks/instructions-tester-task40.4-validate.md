# Tester: Validate Task 40.4 — Velocity Measurement

**Wait for**: Expert reports "Task 40.4 done"

## Tests

### Test 1: measure.velocity runs
```bash
./scrumMaster measure.velocity
# Should output env-style velocity snapshot (VELOCITY_* vars)
```

### Test 2: measure.velocity.target runs
```bash
./scrumMaster measure.velocity.target
# Should output burn rate assessment (too_fast/too_slow/on_target)
```

### Test 3: Metrics saved
```bash
ls -la session/metrics/velocity.* 2>/dev/null | tail -3
# Should show velocity metric files after running measure.velocity
```

### Test 4: Burn rate classification
```bash
./scrumMaster measure.velocity.target | grep BURN_RATE
# Should be one of: too_fast, too_slow, on_target
```

### Test 5: Completion exists
```bash
./c2 function.completion ./scrumMaster measure.velocity
# Should show measure.velocity and measure.velocity.target
```

### Test 6: Syntax check
```bash
bash -n scrumMaster && echo "PASS" || echo "FAIL"
```

## When Done
Report: `Task 40.4 validation: PASS/FAIL`
