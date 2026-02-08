# ScrumMaster: CMM4 Feedback Loop — Your Measurement Duties

**Protocol**: `session/tasks/Task.40.5.cmm4-feedback-loop.md`

## New Duty: 30-Minute Health Check

Add to your sweep loop: every 30 minutes, run both measurements back-to-back:

```bash
./scrumMaster measure.subscription.api
./scrumMaster measure.velocity
```

## After Each Measurement: Evaluate and Alert

Check the burn rate from `measure.velocity` output:

1. If `VELOCITY_BURN_RATE=too_fast` → send: `./hiveMind send orchestrator "ALERT: THROTTLE — burn rate too high"`
2. If `VELOCITY_BURN_RATE=too_slow` → send: `./hiveMind send orchestrator "ALERT: INCREASE — capacity underused"`
3. If `VELOCITY_BURN_RATE=on_target` → no alert needed
4. If five_hour > 80% → send: `./hiveMind send orchestrator "ALERT: QUOTA — five_hour at N%"`
5. If five_hour > 90% → send: `./hiveMind send orchestrator "ALERT: STAND DOWN — five_hour at N%"`

## Alert Log

Append each alert to `session/metrics/alerts.log`:
```
2026-02-05T12:30:00Z THROTTLE seven_day=45% ideal=28% deviation=+17
```

## Schedule

- Normal operations: 30s sweeps + 30-min health check
- Throttle mode: 60s sweeps + 30-min health check
- Stand down: 120s SM checks only (no health check — conserve tokens)

## Start Now

Run your first health check immediately and report the result. Then integrate into your sweep loop.
