# Task 52: Teach Peer Monitoring and Sleep Cycles (from claudeWoda)

**From**: Product Owner (learned from claudeWoda writer)
**For**: Agent Trainer (teach into SKILL.md files)
**Priority**: High — prevents team collapse
**Status**: Done (commit 06f0596)

## Patterns from claudeWoda (proven working)

### 1. Survival Protocol
- Every 10 minutes: check peer's TUI for context %
- If context < 20%: alert peer to save and /compact
- After peer compacts: send resume prompt
- Optimize via CMM — understand patterns, document them

### 2. Background Monitor Loops
- Writer runs 5-minute background monitor loop
- Scribe runs 5-minute background monitor loop
- Both check each other — peer monitoring, not self-monitoring

### 3. Key Insight: Two Gather
- Neither agent can read their OWN context % from inside the conversation
- But PEERS can read each other's TUI via `hiveMind monitor` or `otmux pane.capture`
- "Two Gather" = interdependence as design, not limitation

### 4. CMM2 Checklist (until CMM3 automation)
1. Tell peer what you're doing
2. Verify Enter was submitted (peer captures your pane)
3. Wait for feedback
4. Acknowledge
5. Verify acknowledgment submitted
6. Check context health (peer checks yours, you check theirs)

## Apply to cursorOrchestrator Team

### Orchestrator ↔ SM Pair
- Orchestrator monitors SM context every sweep
- SM monitors Orchestrator context every sweep
- If either < 20%: alert, save context, compact
- After compact: send resume prompt with context file reference

### SM ↔ Watchdog Pair
- Watchdog is external (bash script, no context)
- SM can rely on watchdog for unblocking
- SM reports to Orchestrator if watchdog dies

### Agent Trainer Updates
Add to Orchestrator SKILL.md:
```
## Peer Monitoring (CMM4)
Every sweep cycle:
1. Check SM context via `hiveMind monitor scrum-master`
2. If context warning visible: alert SM to save and /compact
3. After SM compacts: send resume prompt
4. SM does same for you
```

Add to SM SKILL.md:
```
## Peer Monitoring (CMM4)
Every sweep cycle:
1. Check Orchestrator context via `hiveMind monitor orchestrator`
2. If context warning visible: alert Orchestrator to save and /compact
3. After Orchestrator compacts: send resume prompt
4. Orchestrator does same for you
5. Rely on watchdog for unblocking — you focus on context
```

## Acceptance Criteria

- [ ] Orchestrator SKILL.md has peer monitoring section
- [ ] SM SKILL.md has peer monitoring section
- [ ] Both include 20% threshold rule
- [ ] Both include resume-after-compact protocol
- [ ] Pattern documented in agent-overview.md
