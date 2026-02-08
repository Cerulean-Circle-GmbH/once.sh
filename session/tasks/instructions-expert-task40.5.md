# Expert: Task 40.5 — Feedback Loop Automation Method

**Protocol**: `session/tasks/Task.40.5.cmm4-feedback-loop.md`
**Priority**: Medium — SM can work without this, but it makes the loop cleaner

## What to Build

### `scrumMaster.measure.evaluate`
A single method that:
1. Runs `measure.subscription.api` (or reads cached result)
2. Runs `measure.velocity`
3. Evaluates thresholds
4. Outputs one-line verdict: `ON_TARGET`, `THROTTLE`, `INCREASE`, `QUOTA_80`, `STAND_DOWN_90`
5. Appends to `session/metrics/alerts.log` if not ON_TARGET

This gives SM a single command for the 30-min health check instead of running two commands and evaluating manually.

### Output format
```
EVALUATE_RESULT=on_target
EVALUATE_FIVE_HOUR=15
EVALUATE_SEVEN_DAY=28
EVALUATE_BURN_RATE=on_target
EVALUATE_ALERT=none
EVALUATE_TIMESTAMP=2026-02-05T12:30:00Z
```

Or if alert needed:
```
EVALUATE_RESULT=throttle
EVALUATE_FIVE_HOUR=85
EVALUATE_SEVEN_DAY=55
EVALUATE_BURN_RATE=too_fast
EVALUATE_ALERT=THROTTLE — burn rate too high
EVALUATE_TIMESTAMP=2026-02-05T12:30:00Z
```

### Tab completion
- No parameters needed — it evaluates current state

### Syntax check
- `bash -n scrumMaster` must pass

## When Done
Commit and report: `Task 40.5 method done`
