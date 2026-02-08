# Agent Trainer: Update SKILL.md Files for CMM4 Feedback Loop

**Protocol**: `session/tasks/Task.40.5.cmm4-feedback-loop.md`

## Updates Needed

### 1. ScrumMaster SKILL.md (`.claude/agents/scrum-master/SKILL.md`)

Add a "CMM4 Measurement Duties" section:
- 30-minute health check cycle: `measure.subscription.api` + `measure.velocity`
- Threshold evaluation after each measurement
- Alert protocol: THROTTLE / INCREASE / QUOTA / STAND DOWN
- Alert log: append to `session/metrics/alerts.log`

### 2. Agent Teacher / Orchestrator SKILL.md (`.claude/agents/agent-teacher/SKILL.md`)

Add a "CMM4 Response Protocol" section:
- How Orchestrator responds to SM alerts
- THROTTLE → reduce assignments, slow sweeps
- INCREASE → assign more work, wake idle agents
- QUOTA (>80%) → essential-only mode
- STAND DOWN (>90%) → sleep mode

### 3. Keep It Concise

Add the minimum needed — a short section in each SKILL.md. Don't rewrite the whole file. The full protocol is in `session/tasks/Task.40.5.cmm4-feedback-loop.md` for reference.

## When Done
Report: `SKILL.md updates done`
