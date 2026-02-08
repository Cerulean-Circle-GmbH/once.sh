# Task 40.5 — CMM4 Feedback Loop Protocol

**Status**: Active
**Owner**: Orchestrator (design) + ScrumMaster (execution)
**Dependencies**: 40.2 (sweep.detect, done), 40.4 (velocity measurement, done)

## PDCA Cycle: Plan-Do-Check-Act

The team measures and adjusts its own pace. This is the CMM4 meta-capability.

### Measurement Schedule (ScrumMaster)

SM runs two measurements on a fixed schedule:

| Measurement | Command | Interval | Purpose |
|-------------|---------|----------|---------|
| Subscription | `./scrumMaster measure.subscription.api` | Every 30 minutes | Token budget remaining |
| Velocity | `./scrumMaster measure.velocity` | Every 30 minutes | Burn rate + task throughput |

Both run back-to-back as a single "health check" cycle.

### Thresholds and Alerts

SM evaluates velocity after each measurement and sends alerts to Orchestrator:

| Condition | Threshold | Alert | Action |
|-----------|-----------|-------|--------|
| Burning too fast | seven_day > (day_number/7 * 100) + 10% | `ALERT: THROTTLE — burn rate too high` | Orchestrator reduces assignment rate |
| Burning too slow | seven_day < (day_number/7 * 100) - 10% | `ALERT: INCREASE — capacity underused` | Orchestrator assigns more work |
| On target | Within ±10% of ideal | No alert | Continue current pace |
| Five-hour critical | five_hour > 80% | `ALERT: QUOTA — five_hour at N%` | Orchestrator enters throttle mode |
| Five-hour emergency | five_hour > 90% | `ALERT: STAND DOWN — five_hour at N%` | Orchestrator stops all non-essential work |

**Simplified formula**:
```
ideal_seven_day_pct = (day_of_period / 7) * 100
actual_seven_day_pct = from measure.subscription.api
deviation = actual - ideal

if deviation > 10:  THROTTLE
if deviation < -10: INCREASE
else:               ON_TARGET
```

### Orchestrator Response Protocol

When Orchestrator receives an alert from SM:

| Alert | Response |
|-------|----------|
| THROTTLE | Reduce sweep frequency. Pause non-critical tasks. Tell Expert to commit and stand by. |
| INCREASE | Assign next queued task. Wake idle agents. Increase sweep frequency. |
| ON_TARGET | No change. Continue current assignment rate. |
| QUOTA (>80%) | Switch to essential-only mode. 60s sweeps. No new assignments. |
| STAND DOWN (>90%) | Sleep mode. 120s SM checks only. No sweeps, no assignments. |

### Feedback Loop Diagram

```
┌─────────────────────────────────────────────────────┐
│                    PDCA CYCLE                        │
│                                                      │
│  PLAN: SM schedules 30-min measurement cycle         │
│    ↓                                                 │
│  DO: SM runs measure.subscription.api +              │
│      measure.velocity                                │
│    ↓                                                 │
│  CHECK: SM evaluates burn rate vs ideal pace         │
│    ↓                                                 │
│  ACT: SM alerts Orchestrator if deviation > ±10%     │
│       Orchestrator adjusts assignment rate            │
│    ↓                                                 │
│  (loop back to PLAN after 30 minutes)                │
└─────────────────────────────────────────────────────┘
```

### Communication Path

```
SM measures → SM evaluates → SM alerts Orchestrator (via hiveMind send)
Orchestrator adjusts → Expert/Tester get more or fewer tasks
Next cycle: SM measures impact of adjustment
```

### Storage

- Velocity readings: `session/metrics/velocity.<timestamp>.env`
- Subscription readings: `session/metrics/subscription.<timestamp>.env`
- Alert log: `session/metrics/alerts.log` (append-only)
  - Format: `<timestamp> <alert_type> <details>`

### Implementation Checklist

- [ ] SM adds 30-min measurement cycle to its sweep loop
- [ ] SM evaluates thresholds after each measurement
- [ ] SM sends alerts to Orchestrator via `./hiveMind send orchestrator "<alert>"`
- [ ] Orchestrator responds to alerts per protocol above
- [ ] Agent Trainer updates SM SKILL.md with measurement duties
- [ ] Agent Trainer updates Orchestrator SKILL.md with response protocol
- [ ] Alert log written to session/metrics/alerts.log

### What This Achieves (CMM4)

- **Measured**: Team knows its burn rate at all times
- **Feedback**: Deviations trigger automatic alerts
- **Adaptive**: Orchestrator adjusts pace based on data, not guesswork
- **Sustainable**: 90% of 7-day limit reached on day 7, not day 2
