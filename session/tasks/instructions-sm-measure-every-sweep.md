# PO Directive: Measure Velocity Every Sweep Cycle

## Rule

Every 3rd sweep (roughly every 90s), run:
```bash
./scrumMaster measure.subscription.api
```

## What to Track

1. Current five_hour % and seven_day %
2. Are we burning too fast? (>14%/day of seven_day = too fast)
3. Are we burning too slow? (<10%/day = wasting capacity)

## What to Report

If five_hour > 80%: tell PO "Approaching limit — throttle soon"
If burn rate > 14%/day: tell Orchestrator "Slow down — burning too fast"
If burn rate < 10%/day: tell Orchestrator "Speed up — capacity unused"

## Why

This IS the CMM4 capability. Measurement that changes the process. Without this, we're CMM2 at best — repeatable but not measured.

Your sweep loop should be:
1. `./hiveMind sweep` — check agents
2. Unblock stuck agents
3. Every 3rd cycle: `./scrumMaster measure.subscription.api` — check velocity
4. Sleep 30s
5. Repeat
