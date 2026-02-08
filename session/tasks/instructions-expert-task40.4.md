# Expert: Task 40.4 — Velocity Measurement Method

**Parent**: Task 40 CMM4 | **Depends on**: 40.1 (done, 1fe680f), Task.29 (subscription API, done)
**Your design plan**: session/tasks/task40-expert-plan.md (section 4)
**Priority**: High — blocks 40.5 (feedback loop)

## What to Build

### 1. `scrumMaster.measure.velocity`
Current velocity snapshot combining subscription data + task completion rate.

**Data sources**:
- Token consumption: `scrumMaster.measure.subscription.api` (exists, returns five_hour/seven_day %)
- Task completion: count task files with "done" or completed commits
- Time: wall clock since session start or day start

**Output format** (env-style for easy parsing):
```
VELOCITY_FIVE_HOUR_PCT=15
VELOCITY_SEVEN_DAY_PCT=34
VELOCITY_TASKS_TODAY=3
VELOCITY_TOKENS_PER_TASK_EST=high|medium|low
VELOCITY_BURN_RATE=on_target|too_fast|too_slow
VELOCITY_TIMESTAMP=2026-02-05T12:30:00Z
```

### 2. `scrumMaster.measure.velocity.target`
Calculate ideal burn rate per your formula:
```
ideal_daily_rate = 7_day_limit / 7
actual_daily_rate = tokens_used_today / hours_elapsed * 24
velocity_ratio = actual_daily_rate / ideal_daily_rate
```
- `ratio > 1.2` → BURN_RATE=too_fast
- `ratio < 0.8` → BURN_RATE=too_slow
- `0.8 <= ratio <= 1.2` → BURN_RATE=on_target

### 3. Storage
Save readings to `session/metrics/velocity.<timestamp>.env` — same pattern as existing context metrics.

### 4. Tab completion
- `scrumMaster.measure.velocity` — no parameters needed
- `scrumMaster.measure.velocity.target` — no parameters needed

## Risk (from your plan)
- five_hour % resets every 5 hours — not a clean daily metric. Sample and accumulate if needed, or use seven_day as the primary daily metric.

## Acceptance Criteria
- [ ] `scrumMaster measure.velocity` outputs velocity snapshot
- [ ] `scrumMaster measure.velocity.target` outputs burn rate assessment
- [ ] Velocity data saved to `session/metrics/velocity.<timestamp>.env`
- [ ] Burn rate classification works (too_fast/too_slow/on_target)
- [ ] `bash -n scrumMaster` passes

## When Done
Commit and report: `Task 40.4 done`
