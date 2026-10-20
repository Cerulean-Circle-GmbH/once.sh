# HiveMind - Multi-Agent Orchestrator

**Purpose:** Manage hive-mind agents in tmux panes for parallel task execution
**Script:** `hiveMind`
**Dependencies:** `claudeFlow`, `claudeCode`, `otmux`, `claude-flow`

---

## Overview

HiveMind orchestrates Claude Flow's hive-mind system with tmux integration:

- Initialize a hive with queen and worker agents
- Create tmux panes for each agent
- Submit tasks for distributed processing
- Integrate with Claude Code sessions

---

## Quick Start

```bash
# Initialize hivemind with hive and tmux layout
./hiveMind init

# Or with specific worker count
./hiveMind init 5 hierarchical-mesh

# Attach to existing session
./hiveMind attach

# Submit a task
./hiveMind task "Build authentication module"

# Check status
./hiveMind status
```

---

## Commands Reference

### Initialization

| Command | Description |
|---------|-------------|
| `init <?agents> <?workdir>` | Initialize hivemind with agents |
| `attach` | Attach to hivemind tmux session |
| `detach` | Detach from current session |
| `kill` | Shutdown hivemind completely |

```bash
# Examples
./hiveMind init                              # Default agents
./hiveMind init oosh-expert,oosh-tester      # Specific agents
```

### Agent Management

| Command | Description |
|---------|-------------|
| `list` | List all agents |
| `spawn <agentId> <?workdir>` | Spawn a new agent with pane |
| `focus <agentId>` | Focus on agent's tmux pane |
| `send <agentId> <message>` | Send message to agent's pane |
| `status <?pane>` | Show hivemind status |
| `panes` | List all agent tmux panes |

### Role Management

| Command | Description |
|---------|-------------|
| `roles` | Show all role descriptions |
| `role.list` | List roles from `.claude/agents/` |
| `role.prompt <role>` | Output teaching prompt for role |
| `role.teach <pane> <role>` | Teach role to existing pane |

```bash
# Examples
./hiveMind role.list                 # List all available roles
./hiveMind role.prompt oosh-expert   # Show expert's teaching prompt
./hiveMind role.teach 0.1 oosh-expert # Teach expert role to pane
```

### Agent Lifecycle

| Command | Description |
|---------|-------------|
| `agent.bootstrap <role> <?session> <?pane>` | Full bootstrap: create pane, start Claude, teach role |
| `agent.verify <pane>` | Check if agent is alive and processing |

```bash
# Examples
./hiveMind agent.bootstrap scrum-master         # Bootstrap in default session
./hiveMind agent.bootstrap oosh-expert mySession # Bootstrap in specific session
./hiveMind agent.verify cursorOrchestrator:0.1   # Verify expert is alive
```

### Team Setup

| Command | Description |
|---------|-------------|
| `team.setup.oosh <?session>` | Create 3-pane team (Teacher + Expert + Tester) |
| `team.setup.full <?session>` | Create 4-pane team (+ ScrumMaster) |
| `team.status <?session>` | Show status of all team members |
| `teach <pane> <role>` | Teach an agent its specialized role |

```bash
# Examples
./hiveMind team.setup.full                    # Full 4-agent team
./hiveMind team.setup.full mySession          # In specific session
./hiveMind team.status                        # Check all agents
```

### Monitoring

| Command | Description |
|---------|-------------|
| `monitor.approve <pane> <?option:2>` | Approve permission prompt in pane |

```bash
# Examples
./hiveMind monitor.approve cursorOrchestrator:0.1     # Approve with option 2
./hiveMind monitor.approve cursorOrchestrator:0.1 3   # Reject with option 3
```

### Task Management

| Command | Description |
|---------|-------------|
| `task <agentId> <description>` | Send task to specific agent |
| `broadcast <message>` | Send message to all agents |

### Claude Code Integration

| Command | Description |
|---------|-------------|
| `claude <agentId> <?prompt>` | Interact with agent via Claude Code |
| `createPane <agentId> <?workdir>` | Create tmux pane for agent |

---

## Tmux Layouts

### Full Team (`team.setup.full`)

```
┌─────────────────────────────────────────┐
│ Pane 0.0 - AGENT TEACHER                │
├───────────────────────┬─────────────────┤
│ Pane 0.2 - EXPERT     │ Pane 0.3 - TEST │
│ (oosh-expert)         │ (oosh-tester)   │
├───────────────────────┴─────────────────┤
│ Pane 0.1 - SCRUMMASTER                  │
└─────────────────────────────────────────┘
```

### OOSH Team (`team.setup.oosh`)

```
┌─────────────────────────────────────────┐
│ Pane 0.0 - ORCHESTRATOR                 │
├───────────────────────┬─────────────────┤
│ Pane 0.1 - EXPERT     │ Pane 0.2 - TEST │
│ (oosh-expert)         │ (oosh-tester)   │
└───────────────────────┴─────────────────┘
```

---

## Configuration

Environment variables for customization:

```bash
HIVEMIND_SESSION=hivemind      # tmux session name
HIVEMIND_MAIN_PANE_SIZE=60     # Main pane percentage
HIVEMIND_TOPOLOGY=hierarchical-mesh  # Hive topology
HIVEMIND_WORKERS=3             # Default worker count
HIVEMIND_CONSENSUS=byzantine   # Consensus algorithm
```

---

## Topologies

Available hive topologies:

| Topology | Description |
|----------|-------------|
| `hierarchical-mesh` | Queen coordinates workers in mesh (default) |
| `flat` | All agents equal, no hierarchy |
| `ring` | Circular communication pattern |
| `star` | Central coordinator pattern |

---

## Integration with OOSH

HiveMind follows OOSH patterns:

```bash
# Method naming
hiveMind.init()
hiveMind.list()
private.hiveMind.get.agents()

# Completions
hiveMind.focus.completion.agentId() {
  hiveMind.list
}

# Parameter syntax
hiveMind.init() # <?workers:3> <?topology:hierarchical-mesh> # description
```

---

## Workflow Example

```bash
# 1. Initialize the hive
./hiveMind init 5

# 2. Check agents are ready
./hiveMind list
./hiveMind status

# 3. Submit tasks
./hiveMind task "Research authentication patterns" high
./hiveMind task "Implement login API" medium
./hiveMind task "Write unit tests" medium

# 4. Monitor progress
./hiveMind status

# 5. Use Claude in main pane
./hiveMind claude "Review the authentication implementation"

# 6. When done
./hiveMind kill
```

---

## Related Commands

### claudeFlow Hive Commands

```bash
./claudeFlow hive.init          # Initialize hive (lower level)
./claudeFlow hive.spawn         # Spawn workers
./claudeFlow hive.status        # Show status
./claudeFlow hive.list          # List agent IDs
./claudeFlow hive.task          # Submit task
./claudeFlow hive.broadcast     # Send message
./claudeFlow hive.shutdown      # Shutdown hive
```

### otmux Commands

```bash
./otmux split                   # Split pane
./otmux panes                   # List panes
./otmux selectPane 1            # Select pane
./otmux send "command" Enter    # Send keys
```

---

## Troubleshooting

### No workers found

```bash
# Check if hive is initialized
./claudeFlow hive.status 0

# Re-initialize
./hiveMind kill
./hiveMind init
```

### Can't attach to session

```bash
# Check if session exists
tmux list-sessions

# Create new session
./hiveMind init
```

### Panes not showing agents

```bash
# Refresh panes
./hiveMind refresh

# Manually check workers
./hiveMind workers
```

---

## See Also

- [OOSH Quick Reference](oosh.md) - Framework basics
- [OOSH Architecture](oosh-architecture.md) - Technical details
- [claudeFlow](../claudeFlow) - Claude Flow wrapper
- [otmux](../otmux) - Tmux wrapper
- [Wiki Index](wiki-index.md) - All documentation

<!-- BEGIN generated: oosh method matrix (oosh-architect) -->
## `hiveMind` — method matrix (origin/dev ↔ origin/test/mcdonges.latest)

Generated by oosh-architect from the branch sources (2026-10-20). Indexes: [methods-index.md](methods-index.md) · [object-verb-index.md](object-verb-index.md) · [parameter.md](parameter.md).

**Decomposition** — every method is `hiveMind.<object>.<verb>[.<more.words>]`. One method = one row.
`object`/`verb` are left **blank when unchanged from the row above** (objects are never repeated).
The **script name is the root object** — `odocker` acts on `container`, `image`, `volume` … so a method is
an object CHAIN ending in a verb: **`object.object.verb`**. The object column shows the full chain.
The **verb is identified semantically** (a real action word), not by position; OOSH's normalized form puts
the **verb last** (e.g. `authorized.keys.update`), so segments before it are the object, after it `more.words`.
An **empty verb** means the name carries **no action at all** — the chain never reaches a verb
(an `object.verb` naming gap, listed in [verb-audit.md](verb-audit.md)).

| object | verb | more.words | all parameter | origin/test/mcdonges.latest | origin/dev |
|---|---|---|---|---|---|
| **=== public ===** | | | | | |
| `hiveMind` | `attach` |  | `# # attach to hivemind tmux session` | `hiveMind.attach` ✅ | `hiveMind.attach` ✅ |
|  | `broadcast` |  | `# <message> # send message to all agents` | `hiveMind.broadcast` | `hiveMind.broadcast` |
|  | `delegate` |  | `# <name> <description> <?from:PO> # write task file and send file-read nudge to agent` | `hiveMind.delegate` | `hiveMind.delegate` |
|  | `detach` |  | `# # detach from current session` | `hiveMind.detach` ✅ | `hiveMind.detach` ✅ |
|  | `discover` |  | `# # discover all agents as JSON` | `hiveMind.discover` ✅ | `hiveMind.discover` ✅ |
|  | `fix` | `path` | `# # verify OOSH PATH works, scan SKILL.md files for stale export patterns` |  | `hiveMind.fix.path` |
|  | `focus` |  | `# <agentId> # focus on specific agent pane` |  | `hiveMind.focus` |
|  | `help` |  | `# # show usage information` | `hiveMind.help` ✅ | `hiveMind.help` ✅ |
|  | `init` |  | `# <?agents:orchestrator,coder,tester,reviewer> <?workdir:.> # initialize hivemind with real Claude agents` | `hiveMind.init` | `hiveMind.init` |
|  | `join` |  | `# <name> # rejoin the Claude session of an agent by role name` | `hiveMind.join` | `hiveMind.join` |
|  | `kill` |  | `# # shutdown hivemind completely` | `hiveMind.kill` ✅ | `hiveMind.kill` ✅ |
|  | `list` |  | `# # list all agents` | `hiveMind.list` | `hiveMind.list` |
|  | `monitor` |  | `# <?name-or-lines:5> <?session-or-lines> # capture pane output; name=specific agent, number=line count for all panes` |  | `hiveMind.monitor` |
|  |  | `cycle` | `# <?session> # full monitoring cycle: context health, velocity, detect blockers, unblock, log` |  | `hiveMind.monitor.cycle` |
|  | `resolve` |  | `# <name> <?session> # resolve agent name to pane target via role registry` | `hiveMind.resolve` | `hiveMind.resolve` |
|  | `send` |  | `# <name> <text...> # send literal text to agent by name (no Enter appended)` | `hiveMind.send` | `hiveMind.send` |
|  |  | `message` | `# <name> <message> # safe send: pre-check, clear blockers, send with verification` | `hiveMind.send.message` | `hiveMind.send.message` |
|  | `spawn` |  | `# <agentId> <?workdir:.> # spawn a new agent with pane` |  | `hiveMind.spawn` |
|  | `sweep` |  | `# <?session> <?interval> # show last lines of each agent pane (optional sleep before sweep)` |  | `hiveMind.sweep` |
|  |  | `cycle` | `# <?session> <?interval:0> # run one sweep+unblock cycle with optional sleep` |  | `hiveMind.sweep.cycle` |
|  | `teach` |  | `# <pane> <role> # teach an agent its specialized role via SKILL.md` |  | `hiveMind.teach` |
|  | `train` |  | `# <role> <?session> # train agent: verify reading list, send training task, monitor, verify completion` |  | `hiveMind.train` |
|  | `unblock` |  | `# <name> <?session> # detect and resolve stuck prompt; name = agent name or all` |  | `hiveMind.unblock` |
| `hiveMind.agent` | `approve` |  | `# <agent\|pane> # affirmative response in current overlay (Epic I I1.3)` | `hiveMind.agent.approve` |  |
|  | `bootstrap` |  | `# <role> <?session> <?pane> # full bootstrap: create pane, start bash, launch claude, teach role` | `hiveMind.agent.bootstrap` | `hiveMind.agent.bootstrap` |
|  | `dismiss` |  | `# <agent\|pane> # dismiss any overlay with Escape (Epic I I1.3)` | `hiveMind.agent.dismiss` |  |
|  | `fork` | `best` | `# <role> <targetPane> # find best-trained session for <role> and fork it into <targetPane> (Epic J2)` | `hiveMind.agent.fork.best` |  |
|  | `monitor` |  | `# <agentName> <?session> <?lines:30> # capture pane output for agent by name; searches all teams when no session given` | `hiveMind.agent.monitor` |  |
|  |  | `cycle` | `# <?session> # full monitoring cycle: context health, velocity, detect blockers, unblock, log` | `hiveMind.agent.monitor.cycle` |  |
|  | `reject` |  | `# <agent\|pane> # negative response in current overlay (Epic I I1.3)` | `hiveMind.agent.reject` |  |
|  | `rename` |  | `# <agentName> <newName> # rename agent: /rename + pane.lock + registry update` | `hiveMind.agent.rename` |  |
|  | `respawn` |  | `# <agentName> # fork role snapshot into pane + /rename + re-register` | `hiveMind.agent.respawn` |  |
|  | `restart` |  | `# <configDir> <role> # restart single agent from pulled config` | `hiveMind.agent.restart` |  |
|  |  | `remote` | `# <role> <host> <?pane> # restart agent on remote machine by copying session JSONL` | `hiveMind.agent.restart.remote` | `hiveMind.agent.restart.remote` |
|  | `rewind` |  | `# <name> <?option:2> <?auth> # Controller: PEER-rewind an agent — Tron-auth + DURING_REWIND quiesce (poke-guard) → otmux.rewind.drive → reap leaked shells on success` | `hiveMind.agent.rewind` |  |
|  | `send` |  | `# <name> <message> # send message to agent via best available channel` | `hiveMind.agent.send` | `hiveMind.agent.send` |
|  | `spawn` |  | `# <agentName> <?workdir:.> # spawn a new agent with pane` | `hiveMind.agent.spawn` |  |
|  | `train` |  | `# <agentName> <?session> # train agent: verify reading list, send training task, monitor, verify completion` | `hiveMind.agent.train` |  |
|  | `unblock` |  | `# <agentName> <?session> # detect and resolve stuck prompt; name=agent name or 'all'` | `hiveMind.agent.unblock` |  |
|  | `verify` |  | `# <pane> # check if agent is alive and processing` | `hiveMind.agent.verify` ✅ | `hiveMind.agent.verify` ✅ |
| `hiveMind.agent.context.status` |  |  | `# <agent> <?session> # show context % for one agent by role name` | `hiveMind.agent.context.status` | `hiveMind.agent.context.status` |
| `hiveMind.agent.handoff` |  |  | `# <agentName> <?session> # full generational handoff: detect low context, compact, verify recovery` | `hiveMind.agent.handoff` |  |
| `hiveMind.agent.option` |  |  | `# <agent\|pane> <N> # send arbitrary option N in current overlay (Epic I I1.3)` | `hiveMind.agent.option` |  |
| `hiveMind.agent.queue` | `clear` |  | `# <agent\|pane> # cancel all pending queued messages (Epic I I1.4)` | `hiveMind.agent.queue.clear` |  |
|  | `drain` |  | `# <agent\|pane> # FIFO drain pending messages (re-checks state per message) (Epic I I1.4)` | `hiveMind.agent.queue.drain` |  |
|  | `list` |  | `# <agent\|pane> # show pending messages with age (Epic I I1.4)` | `hiveMind.agent.queue.list` |  |
| `hiveMind.agent.session` | `probe` |  | `# <agentName\|pane> <?session> # ground-truth UUID via /status + JSONL correlation (slow ~3s)` | `hiveMind.agent.session.probe` |  |
| `hiveMind.agent.snapshot` |  |  | `# <agentName> # register current session UUID as role snapshot` | `hiveMind.agent.snapshot` |  |
| `hiveMind.agent.state` | `clear` |  | `# <role> # clear operator override state for an agent` | `hiveMind.agent.state.clear` |  |
|  | `get` |  | `# <role> # get operator override state for an agent (empty if none)` | `hiveMind.agent.state.get` |  |
|  | `set` |  | `# <role> <STATE> # set operator override state for an agent` | `hiveMind.agent.state.set` |  |
| `hiveMind.auto` | `commit` |  | `# <?message> # auto-commit uncommitted changes if any exist` |  | `hiveMind.auto.commit` |
| `hiveMind.claude` |  |  | `# <agentId> <?prompt> # interact with agent via Claude Code` | `hiveMind.claude` | `hiveMind.claude` |
| `hiveMind.cold` | `recover` |  | `# <?session> # cold-start recovery: reconcile registry with live infrastructure, nudge agents` |  | `hiveMind.cold.recover` |
| `hiveMind.consistency` | `audit` |  | `# <?session> # cross-compare all identity sources and show mismatches` | `hiveMind.consistency.audit` | `hiveMind.consistency.audit` |
|  |  | `table` | `# <?session> # LEGACY per-pane table view (Sprint 0 — kept for diagnostics)` | `hiveMind.consistency.audit.table` |  |
|  | `fix` |  | `# <?session> # auto-repair identity mismatches from live truth` | `hiveMind.consistency.fix` | `hiveMind.consistency.fix` |
|  |  | `table` | `# <?session> # LEGACY Sprint-0 per-pane fixer (kept for diagnostics)` | `hiveMind.consistency.fix.table` |  |
|  | `reconcile` |  | `# <?session> <?mode:dry-run\|apply> # silent batch reconciliation; dry-run by default (U3 lock)` | `hiveMind.consistency.reconcile` |  |
| `hiveMind.consistency.reconcile` | `apply` |  | `# <?session> # non-interactive batch apply (flagless, for team.push automation)` | `hiveMind.consistency.reconcile.apply` |  |
| `hiveMind.context` | `gather` |  | `# <agent> # send /context to an IDLE agent, parse the real reading, record it (skips active)` | `hiveMind.context.gather` |  |
|  |  | `all` | `# <?session> # gather /context from every IDLE agent in a team (serial; skips active)` | `hiveMind.context.gather.all` |  |
|  |  | `quiet` | `# <agent> # refresh ctx from JSONL on disk — NO pane send (safe for near-cliff)` | `hiveMind.context.gather.quiet` |  |
|  | `get` |  | `# <agent> # return last-recorded context reading (unknown agent / no record → fail loud rc1)` | `hiveMind.context.get` |  |
|  | `record` |  | `# <agent> <usedK> <pct> [<denomK>] # store a MEASURED context reading (unknown agent → fail loud; non-numeric → reject)` | `hiveMind.context.record` |  |
| `hiveMind.ctx` | `refresh` |  | `# <?session> # auto-refresh ctx% for IDLE agents whose recorded reading is stale/near-cliff (bounded, serial, fail-safe). No arg=all teams.` | `hiveMind.ctx.refresh` |  |
|  |  | `dry` | `# <?session> # report which agents ctx.refresh WOULD refresh — sends NOTHING (safety audit)` | `hiveMind.ctx.refresh.dry` |  |
| `hiveMind.cycle.full` |  |  | `# <?session> # run full monitoring cycle: sweep + unblock + context check + auto-commit` |  | `hiveMind.cycle.full` |
| `hiveMind.dashboard` |  |  | `# <?session> # write consolidated team state to session/dashboard.md` | `hiveMind.dashboard` | `hiveMind.dashboard` |
| `hiveMind.events` | `list` |  | `# # show registered events and handler counts` | `hiveMind.events.list` |  |
| `hiveMind.events.history` |  |  | `# <?lines:50> # tail the events log` | `hiveMind.events.history` |  |
| `hiveMind.git` | `commit` |  | `# <?message> # auto-commit uncommitted changes if any exist` | `hiveMind.git.commit` |  |
| `hiveMind.handoff` |  |  | `# <target> <?session> # full generational handoff: detect low context, compact, verify recovery` |  | `hiveMind.handoff` |
| `hiveMind.improvement` |  |  | `# <?action:next> <?number> # CMM improvement workflow, action next, done or list: find next, mark done, list status` |  | `hiveMind.improvement` |
| `hiveMind.metrics` | `log` |  | `# <?session> # log sweep metrics per agent + flag context/subscription thresholds` | `hiveMind.metrics.log` | `hiveMind.metrics.log` |
| `hiveMind.metrics.summary` |  |  | `# <?lines:20> # summarize recent sweep-log: trends, burn rates, projections` | `hiveMind.metrics.summary` | `hiveMind.metrics.summary` |
| `hiveMind.monitor` | `approve` |  | `# <pane> <?option:2> # approve a permission prompt in a pane` |  | `hiveMind.monitor.approve` |
| `hiveMind.oosh` | `init` |  | `# <?session> # initialize OOSH expert and tester agents in existing session` |  | `hiveMind.oosh.init` |
| `hiveMind.pane` | `create` |  | `# <agentId> <?workdir:.> # create tmux pane with Claude Code for agent` | `hiveMind.pane.create` | `hiveMind.pane.create` |
|  | `focus` |  | `# <agentName> # focus on specific agent pane` | `hiveMind.pane.focus` |  |
|  | `sweep` |  | `# <?session> <?interval> # show last lines of each agent pane (optional sleep before sweep)` | `hiveMind.pane.sweep` |  |
|  |  | `cycle` | `# <?session> <?interval:0> # run one sweep+unblock cycle with optional sleep` | `hiveMind.pane.sweep.cycle` |  |
| `hiveMind.pane.sweep` | `loop` |  | `# <?seconds:30> # continuous sweep + unblock + ctx-refresh all sessions at interval` | `hiveMind.pane.sweep.loop` |  |
| `hiveMind.panes` |  |  | `# # list all agent panes` | `hiveMind.panes` | `hiveMind.panes` |
| `hiveMind.path` | `fix` |  | `# # verify OOSH PATH works, scan SKILL.md files for stale export patterns` | `hiveMind.path.fix` |  |
| `hiveMind.peer` | `compact` |  | `# <target> <?session> # trigger seamless compact for a peer agent` | `hiveMind.peer.compact` | `hiveMind.peer.compact` |
| `hiveMind.plan` | `create` |  | `# <slug> # link a plan from ~/.claude/plans/ to session/plans/ with timestamp, symlink back, git commit` | `hiveMind.plan.create` | `hiveMind.plan.create` |
|  | `improve` |  | `# <?action:next\|done\|list> <?number> # CMM improvement workflow: find next, mark done, list status` | `hiveMind.plan.improve` |  |
| `hiveMind.process` | `list` |  | `# <?session> # list all Claude processes with pane targets, roles, UUIDs` | `hiveMind.process.list` | `hiveMind.process.list` |
|  | `lookup` |  | `# <pid> # resolve Claude PID to pane target, role, and session UUID` | `hiveMind.process.lookup` ✅ | `hiveMind.process.lookup` ✅ |
| `hiveMind.protected.agents` | `discover` |  | `# <?session_filter> # shared discovery — output pane\|role\|state\|uuid\|title\|is_claude (protected: CLI-callable, hidden from Tab)` | `hiveMind.protected.agents.discover` |  |
| `hiveMind.protected.agents.offline` |  |  | `# <session> # synthesize 6-field discovery rows from persisted state (roles.env + sessions.env) for offline teams` | `hiveMind.protected.agents.offline` |  |
| `hiveMind.protected.events` | `emit` |  | `# <eventName> <arg...> # CLI wrapper for tests + cross-script events` | `hiveMind.protected.events.emit` |  |
|  | `register` |  | `# <eventName> <handlerFunction> # CLI wrapper for tests` | `hiveMind.protected.events.register` |  |
| `hiveMind.protected.identity` | `resolve` |  | `# <?pane> # CLI/hook entry: role@host for a pane (boot hook C.3 + reconcile consume this — the ONE shared resolver)` | `hiveMind.protected.identity.resolve` |  |
| `hiveMind.protected.live.tupleset` |  |  | `# <?session> # CLI / test / remote-exec entry for the canonical live reader (ossh exec <host> hiveMind protected.live.tupleset <s>)` | `hiveMind.protected.live.tupleset` |  |
| `hiveMind.protected.pane.moved` |  |  | `# <fromPane> <toPane> # B5.1 observer — emits pane.moved event (SC-C.7)` | `hiveMind.protected.pane.moved` |  |
| `hiveMind.protected.panes.shifted` |  |  | `# <session> # B5.1 observer — emits panes.shifted event (SC-C.5)` | `hiveMind.protected.panes.shifted` |  |
| `hiveMind.protected.panes.swapped` |  |  | `# <session> <paneA> <paneB> # B5.1 observer — emits panes.swapped event (SC-C.6)` | `hiveMind.protected.panes.swapped` |  |
| `hiveMind.protected.reconcile` | `diff` |  | `# <?invariant:all> # CLI-callable wrapper for tests/diagnostics; SC-A.2 will layer consistency.audit on top` | `hiveMind.protected.reconcile.diff` |  |
| `hiveMind.protected.session.renamed` |  |  | `# <oldName> <newName> # update all env files after session rename` | `hiveMind.protected.session.renamed` |  |
| `hiveMind.protected.team` | `import` |  | `# <session> # merge ~/config/{roles,sessions,teams}.<session>.env slice files into local registries (called by team.migrate on the remote side)` | `hiveMind.protected.team.import` |  |
| `hiveMind.queen` |  |  | `# # show queen (orchestrator) agent ID` | `hiveMind.queen` ✅ | `hiveMind.queen` ✅ |
| `hiveMind.registry` | `fix` |  | `# # clean up invalid entries in roles registry (raw %NNN pane IDs)` | `hiveMind.registry.fix` | `hiveMind.registry.fix` |
|  | `list` |  | `# <?session> # list registry entries (live discovery + file fallback)` | `hiveMind.registry.list` ✅ | `hiveMind.registry.list` ✅ |
|  | `refresh` |  | `# <?session> # probe all panes, update roles + sessions from /status ground truth` | `hiveMind.registry.refresh` | `hiveMind.registry.refresh` |
|  | `remove` |  | `# <pane> # remove registry entry for a pane` | `hiveMind.registry.remove` | `hiveMind.registry.remove` |
|  | `set` |  | `# <pane> <role> # set registry entry for a pane` | `hiveMind.registry.set` ✅ | `hiveMind.registry.set` ✅ |
| `hiveMind.role` | `list` |  | `# # list all agent roles from .claude/agents/` | `hiveMind.role.list` ✅ | `hiveMind.role.list` ✅ |
|  | `prompt` |  | `# <role> # output the teaching prompt for a role` | `hiveMind.role.prompt` | `hiveMind.role.prompt` |
|  | `teach` |  | `# <pane> <role> # teach a role to an existing pane (alias for teach)` | `hiveMind.role.teach` | `hiveMind.role.teach` |
| `hiveMind.role.uuid` |  |  | `# <role> <?session> # role → uuid; live proc-args preferred, snapshot only as timestamp-gated fallback` | `hiveMind.role.uuid` |  |
| `hiveMind.roles` |  |  | `# [filter] # list available agent roles with descriptions (from SKILL.md)` | `hiveMind.roles` | `hiveMind.roles` |
|  | `list` | `uuids` | `# <role> # list all session UUIDs that ever ran as <role>, sorted by recency (Epic J1)` | `hiveMind.roles.list.uuids` |  |
| `hiveMind.send` | `enter` |  | `# <name> <message> # send message to agent by name (delegates to send.message)` | `hiveMind.send.enter` | `hiveMind.send.enter` |
| `hiveMind.shell` | `reap` |  | `# <?pane\|session> # reap PROVABLY-SAFE leaked bg-shells (graceful SIGTERM→re-check→SIGKILL by PID; never active-work/foreground). No arg=all teams.` | `hiveMind.shell.reap` |  |
|  |  | `dry` | `# <?pane\|session> # CLASSIFY + report what shell.reap WOULD reap — kills NOTHING (safety audit)` | `hiveMind.shell.reap.dry` |  |
| `hiveMind.snapshot` | `list` |  | `# # list all registered agent snapshots with valid/stale flag` | `hiveMind.snapshot.list` |  |
| `hiveMind.snapshots` | `list` |  | `# # list all snapshots with date and agent count` | `hiveMind.snapshots.list` |  |
|  | `prune` |  | `# <?keep:5> # keep N newest snapshots, delete the rest` | `hiveMind.snapshots.prune` |  |
| `hiveMind.status` |  |  | `# <?session> # show one-line hivemind overview` | `hiveMind.status` | `hiveMind.status` |
| `hiveMind.sweep` | `loop` |  | `# <?seconds:30> # continuous sweep + unblock all sessions at interval` |  | `hiveMind.sweep.loop` |
| `hiveMind.task` |  |  | `# <agentId> <description> # send task to specific agent` | `hiveMind.task` | `hiveMind.task` |
|  | `delegate` |  | `# <sshHost> <pane> <taskFile> <?message> # delegate task file to remote agent via scp + send` | `hiveMind.task.delegate` | `hiveMind.task.delegate` |
| `hiveMind.team` | `activate` |  | `# <session> # set active team (alias for team.switch)` | `hiveMind.team.activate` | `hiveMind.team.activate` |
|  | `audit` |  | `# <session> # team-scoped fork-corruption audit — flags orphan (unknown-route) / empty-uuid / dead-route; exit = violation count (U2)` | `hiveMind.team.audit` |  |
|  | `init` | `oosh` | `# <?session> # initialize OOSH expert and tester agents in existing session` | `hiveMind.team.init.oosh` |  |
|  | `list` |  | `# # list all registered team sessions` | `hiveMind.team.list` | `hiveMind.team.list` |
|  | `loop` |  | `# <session> <?interval:30> # continuous team.sweep at interval` | `hiveMind.team.loop` ✅ | `hiveMind.team.loop` ✅ |
|  | `migrate` |  | `# <session> <sshHost> <?snapshotFile> # migrate ONE team to remote — session-filtered, merge-on-remote (preserves remote's other teams)` | `hiveMind.team.migrate` |  |
|  | `monitor` |  | `# <?session> <?agentName> <?lines:30> # capture pane output for agents in session (optionally filtered by agent)` | `hiveMind.team.monitor` |  |
|  | `pull` |  | `# <sshHost> # pull team config from remote machine` | `hiveMind.team.pull` |  |
|  | `push` |  | `# <host> <?teamSession> # push entire team to target host with per-agent verify-or-fail` | `hiveMind.team.push` |  |
|  | `recover` |  | `# <?session> # cold-start recovery: reconcile registry with live infrastructure, nudge agents` | `hiveMind.team.recover` |  |
|  | `register` |  | `# <session> <?description> # register a team session in the team registry` | `hiveMind.team.register` | `hiveMind.team.register` |
|  | `remove` |  | `# <session> # unregister a team session` | `hiveMind.team.remove` | `hiveMind.team.remove` |
|  | `restart` |  | `# <configDir> # restart ALL agents from pulled config directory` | `hiveMind.team.restart` |  |
|  | `setup` |  | `# <roles> <?session> # create N-pane session with agents from comma-separated role list` | `hiveMind.team.setup` |  |
|  |  | `full` | `# <?session> # bootstrap full team: Agent Teacher + Expert + Tester + ScrumMaster` | `hiveMind.team.setup.full` | `hiveMind.team.setup.full` |
|  |  | `oosh` | `# <?session> # create 3-pane tmux session with oosh-orchestrator, expert, and tester agents` | `hiveMind.team.setup.oosh` | `hiveMind.team.setup.oosh` |
|  | `sweep` |  | `# <session> <?interval> # structured one-line-per-pane status of all registered agents (optional sleep before sweep)` | `hiveMind.team.sweep` | `hiveMind.team.sweep` |
|  | `switch` |  | `# <session> # set the active team context` | `hiveMind.team.switch` | `hiveMind.team.switch` |
| `hiveMind.team.active` |  |  | `# # show the current active team` | `hiveMind.team.active` ✅ | `hiveMind.team.active` ✅ |
| `hiveMind.team.context.status` |  |  | `# <?session> # show context % for all registered agents in a team` | `hiveMind.team.context.status` | `hiveMind.team.context.status` |
| `hiveMind.team.cycle` |  |  | `# <?session> # run full monitoring cycle: sweep + unblock + context check + auto-commit` | `hiveMind.team.cycle` |  |
| `hiveMind.team.host` | `set` |  | `# <session> <host> # set/update a team's host column (remote-team registration; called at team.push time)` | `hiveMind.team.host.set` |  |
| `hiveMind.team.models` | `list` |  | `# <?session> # show model each agent is running across one or all teams` | `hiveMind.team.models.list` |  |
| `hiveMind.team.state` | `clear` |  | `# <session> # clear ALL operator overrides for a session` | `hiveMind.team.state.clear` |  |
|  | `set` |  | `# <session> <STATE> # set operator override for ALL agents in a session` | `hiveMind.team.state.set` |  |
| `hiveMind.team.status` |  |  | `# <?session> # show team summary (no arg) or per-pane details (with session)` | `hiveMind.team.status` | `hiveMind.team.status` |
| `hiveMind.teams` | `migrate` |  | `# <ossh-host> <?snapshot_file> # migrate team to remote machine via ossh` | `hiveMind.teams.migrate` | `hiveMind.teams.migrate` |
|  | `restore` |  | `# <?snapshot_file> <?--fork> # restore teams from snapshot; --fork uses fork instead of join (cross-machine)` | `hiveMind.teams.restore` | `hiveMind.teams.restore` |
|  | `save` |  | `# # snapshot all Claude processes for restore after restart` | `hiveMind.teams.save` | `hiveMind.teams.save` |
| `hiveMind.watchdog` |  |  | `# <?seconds:30> # start external sweep+unblock loop in a new tmux pane` | `hiveMind.watchdog` | `hiveMind.watchdog` |
|  | `stop` |  | `# # stop the external watchdog loop` | `hiveMind.watchdog.stop` ✅ | `hiveMind.watchdog.stop` ✅ |
| `hiveMind.watchdog.status` |  |  | `# # check if watchdog is running` | `hiveMind.watchdog.status` ✅ | `hiveMind.watchdog.status` ✅ |
| `hiveMind.watchdog.supervisor` |  |  | `# <?interval:30> # check watchdog health and restart if dead/stale` | `hiveMind.watchdog.supervisor` | `hiveMind.watchdog.supervisor` |
| `hiveMind.workers` |  |  | `# # list worker agents (non-orchestrator panes)` | `hiveMind.workers` | `hiveMind.workers` |
| **=== private ===** | | | | | |
| `hiveMind` | `create` | `agent.pane` |  | `private.hiveMind.create.agent.pane` | `private.hiveMind.create.agent.pane` |
|  | `ensure` | `pane` | `# <session:window.pane> # create session/window/pane if missing` | `private.hiveMind.ensure.pane` ✅ | `private.hiveMind.ensure.pane` ✅ |
|  | `find` | `agents.dir` |  | `private.hiveMind.find.agents.dir` ✅ | `private.hiveMind.find.agents.dir` ✅ |
|  | `get` | `agent.port` |  | `private.hiveMind.get.agent.port` ✅ | `private.hiveMind.get.agent.port` ✅ |
|  |  | `agents` |  | `private.hiveMind.get.agents` ✅ | `private.hiveMind.get.agents` ✅ |
|  | `list` | `panes` | `# <format> <?scope> # list panes with standard format strings` | `private.hiveMind.list.panes` ✅ | `private.hiveMind.list.panes` ✅ |
|  | `push` | `agent` | `# <host> <role> <sourceUUID> <targetPane>` | `private.hiveMind.push.agent` |  |
|  |  | `captureForkedUUID` | `# <host> <targetPane> <targetHashDir> <role> <preForkFiles>` | `private.hiveMind.push.captureForkedUUID` |  |
|  |  | `preflight` | `# <host> <teamSession>` | `private.hiveMind.push.preflight` |  |
|  |  | `resolveCanonical` | `# <role> <teamSession>` | `private.hiveMind.push.resolveCanonical` |  |
|  | `resolve` | `alias` |  | `private.hiveMind.resolve.alias` ✅ | `private.hiveMind.resolve.alias` ✅ |
|  | `sweep` | `bgshells` | `# <root_pid> <psSnap> # bg-shell COUNT (DRY: counts the shell.descendants producer shared with shell.reap)` | `private.hiveMind.sweep.bgshells` |  |
|  |  | `paneState` | `# <target>` | `private.hiveMind.sweep.paneState` |  |
|  | `unblock` | `pane` |  |  | `private.hiveMind.unblock.pane` |
|  | `wait` | `for.claude` | `# <paneTarget> <?timeout:30> # poll until Claude process alive` | `private.hiveMind.wait.for.claude` |  |
| `hiveMind.active.team` |  |  |  | `private.hiveMind.active.team` | `private.hiveMind.active.team` |
| `hiveMind.agent` | `inform` |  | `# <pane> <text...> # INFORM path: deliver text as user-turn input to agent at idle ❯` | `private.hiveMind.agent.inform` |  |
|  | `route` |  | `# <pane> # classify pane state → route name (inform\|overlay\|queue\|unknown-state)` | `private.hiveMind.agent.route` |  |
|  | `unblock` | `pane` |  | `private.hiveMind.agent.unblock.pane` |  |
| `hiveMind.agent.overlay` | `dispatch` |  | `# <agent\|pane> <verb> <?option> # detect overlay state, send key, return outcome` | `private.hiveMind.agent.overlay.dispatch` |  |
| `hiveMind.agent.overlay.key` |  |  | `# <overlayState> <verb> <?option> # map (state, verb) → tmux key sequence` | `private.hiveMind.agent.overlay.key` |  |
| `hiveMind.agent.queue` | `enqueue` |  | `# <pane> <intent> <text> # append message; enforce depth bound` | `private.hiveMind.agent.queue.enqueue` |  |
|  | `resolve` |  | `# <agent\|pane> # resolve to pane (used by public queue verbs)` | `private.hiveMind.agent.queue.resolve` |  |
| `hiveMind.agent.queue.depth` |  |  | `# <pane> # number of pending messages` | `private.hiveMind.agent.queue.depth` |  |
| `hiveMind.agent.queue.path` |  |  | `# <pane> # path to queue file for a pane (sanitize : and . to _)` | `private.hiveMind.agent.queue.path` |  |
| `hiveMind.audit` | `render` | `human` | `# <diff_lines> <total> <c> <h> <m> <l> # color-grouped report` | `private.hiveMind.audit.render.human` |  |
|  |  | `json` | `# <diff_lines> <total> <c> <h> <m> <l> # JSON output for CI/dashboards` | `private.hiveMind.audit.render.json` |  |
| `hiveMind.audit.json` | `escape` |  | `# <str> # minimal JSON string escape (\ and ")` | `private.hiveMind.audit.json.escape` |  |
| `hiveMind.channel` | `resolve` |  | `# <name> # resolve agent name to best available communication channel` | `private.hiveMind.channel.resolve` | `private.hiveMind.channel.resolve` |
| `hiveMind.claude.processes` |  |  | `# # list Claude processes with pane targets: pid\|tty\|paneTarget\|title\|args` | `private.hiveMind.claude.processes` | `private.hiveMind.claude.processes` |
| `hiveMind.context` | `ensure` | `dir` |  | `private.hiveMind.context.ensure.dir` |  |
|  | `get` |  | `# <role> # echo used_k\|pct\|denom_k\|ts_iso or empty` | `private.hiveMind.context.get` |  |
|  | `parse` |  | `# <captured-content> # echo used_k\|pct\|denom_k or empty` | `private.hiveMind.context.parse` |  |
|  | `set` |  | `# <roleKey> <usedK> <pct> <denomK> <tsIso> # upsert one reading` | `private.hiveMind.context.set` |  |
| `hiveMind.context.age` |  |  | `# <tsIso> # echo "<compactAge>\|<ageSeconds>" (e.g. "3m\|182"); rc1 on bad ts` | `private.hiveMind.context.age` |  |
| `hiveMind.context.denom.for.target` |  |  | `# <pane> # echo 1000 or 200` | `private.hiveMind.context.denom.for.target` |  |
| `hiveMind.context.from.jsonl.reading` |  |  | `# <pane> # echo used_k\|pct\|denom_k from JSONL total + honest denom` | `private.hiveMind.context.from.jsonl.reading` |  |
| `hiveMind.context.key` |  |  | `# <role> # echo canonical role@host storage key` | `private.hiveMind.context.key` |  |
| `hiveMind.context.live.jsonl` |  |  | `# <pane> # echo path to the live NON-ZERO-usage jsonl, or empty` | `private.hiveMind.context.live.jsonl` |  |
| `hiveMind.ctx` | `refresh` | `impl` | `# <?session> <mode:dry\|apply>` | `private.hiveMind.ctx.refresh.impl` |  |
| `hiveMind.ctxrefresh` | `eval` |  | `# <agent> <mode:dry\|apply>` | `private.hiveMind.ctxrefresh.eval` |  |
|  | `mark` |  | `# <agent> # stamp now as last-refresh (bounds the next tick)` | `private.hiveMind.ctxrefresh.mark` |  |
| `hiveMind.ctxrefresh.due` |  |  | `# <agent> # rc0 if backoff window elapsed (or never refreshed), rc1 if too soon` | `private.hiveMind.ctxrefresh.due` |  |
| `hiveMind.ctxrefresh.statefile` |  |  | `# <agent> # per-agent last-refresh state path (sanitize non-word → _)` | `private.hiveMind.ctxrefresh.statefile` |  |
| `hiveMind.current.session` |  |  | `# # return current tmux session name` | `private.hiveMind.current.session` ✅ | `private.hiveMind.current.session` ✅ |
| `hiveMind.env` | `del` |  | `# <file> <key> <?value> # delete matching line from env file` | `private.hiveMind.env.del` | `private.hiveMind.env.del` |
|  | `set` |  | `# <file> <key> <value> # set key\|value in env file (add or replace)` | `private.hiveMind.env.set` | `private.hiveMind.env.set` |
| `hiveMind.events` | `emit` |  | `# <eventName> <arg...> # fan-out to all registered handlers, log+continue on failure (U1)` | `private.hiveMind.events.emit` |  |
|  | `register` |  | `# <eventName> <handlerFunction> # idempotent — re-registering the same handler is a no-op` | `private.hiveMind.events.register` |  |
| `hiveMind.events.history` | `append` |  | `# <event> <arg...> # internal: append to log, rotate at 1 MiB` | `private.hiveMind.events.history.append` |  |
| `hiveMind.get.role` | `prompt` |  |  | `private.hiveMind.get.role.prompt` ✅ | `private.hiveMind.get.role.prompt` ✅ |
| `hiveMind.handler.agent.forked.forks` |  |  |  | `private.hiveMind.handler.agent.forked.forks` |  |
| `hiveMind.handler.agent.forked.registry` |  |  |  | `private.hiveMind.handler.agent.forked.registry` |  |
| `hiveMind.handler.agent.forked.sessions` |  |  |  | `private.hiveMind.handler.agent.forked.sessions` |  |
| `hiveMind.handler.agent.killed.queue` |  |  |  | `private.hiveMind.handler.agent.killed.queue` |  |
| `hiveMind.handler.agent.killed.registry` |  |  |  | `private.hiveMind.handler.agent.killed.registry` |  |
| `hiveMind.handler.agent.killed.sessions` |  |  |  | `private.hiveMind.handler.agent.killed.sessions` |  |
| `hiveMind.handler.agent.renamed.registry` |  |  |  | `private.hiveMind.handler.agent.renamed.registry` |  |
| `hiveMind.handler.agent.renamed.role_env` |  |  |  | `private.hiveMind.handler.agent.renamed.role_env` |  |
| `hiveMind.handler.agent.renamed.title` |  |  |  | `private.hiveMind.handler.agent.renamed.title` |  |
| `hiveMind.handler.agent.spawned.registry` |  |  |  | `private.hiveMind.handler.agent.spawned.registry` |  |
| `hiveMind.handler.agent.spawned.sessions` |  |  |  | `private.hiveMind.handler.agent.spawned.sessions` |  |
| `hiveMind.handler.pane.moved.registry` |  |  |  | `private.hiveMind.handler.pane.moved.registry` |  |
| `hiveMind.handler.pane.moved.role_env` |  |  |  | `private.hiveMind.handler.pane.moved.role_env` |  |
| `hiveMind.handler.panes.shifted.registry` |  |  |  | `private.hiveMind.handler.panes.shifted.registry` |  |
| `hiveMind.handler.panes.swapped.registry` |  |  |  | `private.hiveMind.handler.panes.swapped.registry` |  |
| `hiveMind.handler.panes.swapped.role_env` |  |  |  | `private.hiveMind.handler.panes.swapped.role_env` |  |
| `hiveMind.handler.team.created.teams` |  |  |  | `private.hiveMind.handler.team.created.teams` |  |
| `hiveMind.handler.team.created.tronMonitor` |  |  |  | `private.hiveMind.handler.team.created.tronMonitor` |  |
| `hiveMind.handler.team.destroyed.queue` |  |  |  | `private.hiveMind.handler.team.destroyed.queue` |  |
| `hiveMind.handler.team.destroyed.registry` |  |  |  | `private.hiveMind.handler.team.destroyed.registry` |  |
| `hiveMind.handler.team.destroyed.sessions` |  |  |  | `private.hiveMind.handler.team.destroyed.sessions` |  |
| `hiveMind.handler.team.destroyed.teams` |  |  |  | `private.hiveMind.handler.team.destroyed.teams` |  |
| `hiveMind.handler.team.destroyed.tronMonitor` |  |  |  | `private.hiveMind.handler.team.destroyed.tronMonitor` |  |
| `hiveMind.handler.team.restored.teams` |  |  |  | `private.hiveMind.handler.team.restored.teams` |  |
| `hiveMind.handler.team.restored.tronMonitor` |  |  |  | `private.hiveMind.handler.team.restored.tronMonitor` |  |
| `hiveMind.identity` | `resolve` |  | `# <?pane> # role@host for ONE pane — a projection of live.tupleset filtered to the pane (defaults to caller's own pane via pane.self)` | `private.hiveMind.identity.resolve` |  |
| `hiveMind.live` | `discover` |  |  | `private.hiveMind.live.discover` | `private.hiveMind.live.discover` |
|  |  | `session` |  | `private.hiveMind.live.discover.session` ✅ | `private.hiveMind.live.discover.session` ✅ |
| `hiveMind.live.tupleset` |  |  | `# <?session> # canonical live reader — emits host\|session\|address\|tty\|role\|uuid\|kind\|title\|cwd per live pane (LOCAL + remote teams)` | `private.hiveMind.live.tupleset` |  |
| `hiveMind.live.tupleset.remote` |  |  | `# <session> <host> # source ONE remote team's canonical rows via ossh exec; fail-safe marker on unreachable` | `private.hiveMind.live.tupleset.remote` |  |
| `hiveMind.liveUuid` |  |  | `# <paneTarget> <?procArgs> <?probe> # get live session UUID, skipping fork parents` | `private.hiveMind.liveUuid` | `private.hiveMind.liveUuid` |
| `hiveMind.monitor` | `switch` |  | `# <paneTarget> # auto-switch tronMonitor to the team containing this pane` | `private.hiveMind.monitor.switch` |  |
| `hiveMind.pane` | `count` |  | `# <target> # count panes in a window or session` | `private.hiveMind.pane.count` ✅ | `private.hiveMind.pane.count` ✅ |
|  | `identify` |  |  | `private.hiveMind.pane.identify` | `private.hiveMind.pane.identify` |
|  | `pushRoleEnv` |  | `# <pane> <newRole> # Bug #3 — push HIVEMIND_ROLE update to pane shell` | `private.hiveMind.pane.pushRoleEnv` |  |
| `hiveMind.pane.activity` |  |  |  | `private.hiveMind.pane.activity` | `private.hiveMind.pane.activity` |
| `hiveMind.pane.for.agent` |  |  |  | `private.hiveMind.pane.for.agent` ✅ | `private.hiveMind.pane.for.agent` ✅ |
| `hiveMind.pane.kind` |  |  | `# <paneTarget> # classify pane: claude \| shell \| monitor \| unknown` | `private.hiveMind.pane.kind` |  |
| `hiveMind.pane.model` |  |  | `# <paneTarget> # extract model flag from running claude's ps args` | `private.hiveMind.pane.model` |  |
| `hiveMind.reconcile` | `apply` |  | `# # consume diff lines on stdin, apply each mutation; echo summary at end` | `private.hiveMind.reconcile.apply` |  |
|  | `check` | `i1` | `# # I1 (HIGH): every pane in S1 exists in L1` | `private.hiveMind.reconcile.check.i1` |  |
|  |  | `i10` | `# # I10 (HIGH): every Claude-running pane should have an S2 (sessions.env) entry` | `private.hiveMind.reconcile.check.i10` |  |
|  |  | `i2` | `# # I2 (HIGH): every pane in S2 is in S1, UUID matches live ps` | `private.hiveMind.reconcile.check.i2` |  |
|  |  | `i3` | `# # I3 (CRITICAL): every team in S3 is a live tmux session` | `private.hiveMind.reconcile.check.i3` |  |
|  |  | `i4` | `# # I4 (MEDIUM): tronMonitor.env (S8) ⊂ teams.env (S3)` | `private.hiveMind.reconcile.check.i4` |  |
|  |  | `i5` | `# # I5 (MEDIUM): snapshot UUID JSONL exists on disk` | `private.hiveMind.reconcile.check.i5` |  |
|  |  | `i6` | `# # I6 (LOW): queue files reference valid panes` | `private.hiveMind.reconcile.check.i6` |  |
|  |  | `i7` | `# # I7 (CRITICAL): tronMonitor display matches title` | `private.hiveMind.reconcile.check.i7` |  |
|  |  | `i8` | `# # I8 (HIGH): every live pane should be in S1 (coverage)` | `private.hiveMind.reconcile.check.i8` |  |
|  |  | `i9` | `# # I9 (MEDIUM): pane titles should be role@HIVEMIND_HOST (not @model)` | `private.hiveMind.reconcile.check.i9` |  |
|  | `diff` |  | `# <?invariant:all> # emit mutations needed to reconcile caches to live truth` | `private.hiveMind.reconcile.diff` |  |
| `hiveMind.registry` | `find` |  |  | `private.hiveMind.registry.find` | `private.hiveMind.registry.find` |
|  | `get` |  |  | `private.hiveMind.registry.get` | `private.hiveMind.registry.get` |
|  | `isRecent` |  | `# <pane> # 0 if file entry was set within TTL window` | `private.hiveMind.registry.isRecent` |  |
|  | `list` |  |  | `private.hiveMind.registry.list` ✅ | `private.hiveMind.registry.list` ✅ |
|  | `migrate` |  |  | `private.hiveMind.registry.migrate` ✅ | `private.hiveMind.registry.migrate` ✅ |
|  | `set` |  |  | `private.hiveMind.registry.set` | `private.hiveMind.registry.set` |
| `hiveMind.role` | `isGeneric` |  | `# <role> # true if role is a generic placeholder` | `private.hiveMind.role.isGeneric` | `private.hiveMind.role.isGeneric` |
| `hiveMind.role.fromTitle` |  |  | `# <title> # extract role name from pane title, stripping prefixes` | `private.hiveMind.role.fromTitle` ✅ | `private.hiveMind.role.fromTitle` ✅ |
| `hiveMind.roles` | `complete` |  |  | `private.hiveMind.roles.complete` | `private.hiveMind.roles.complete` |
| `hiveMind.session` | `lookup` |  |  | `private.hiveMind.session.lookup` | `private.hiveMind.session.lookup` |
|  | `resolve` | `uuid` | `# <pane> # UUID discovery — pure bash, handles forks + autocompact` | `private.hiveMind.session.resolve.uuid` |  |
|  | `store` |  |  | `private.hiveMind.session.store` ✅ | `private.hiveMind.session.store` ✅ |
|  |  | `deferred` | `# <pane> <role> # bg retry probe @ 5/15/30s post-call` | `private.hiveMind.session.store.deferred` |  |
| `hiveMind.sessions` | `migrate` |  |  | `private.hiveMind.sessions.migrate` ✅ | `private.hiveMind.sessions.migrate` ✅ |
| `hiveMind.shell` | `classify` |  | `# <pid> <pane_pid> <paneAlive:0\|1> <psMeta> <ttl>` | `private.hiveMind.shell.classify` |  |
|  | `reap` | `impl` | `# <?scope:pane\|session> <mode:dry\|apply>` | `private.hiveMind.shell.reap.impl` |  |
| `hiveMind.shell.descendants` |  |  | `# <root_pid> <psSnap:"ppid pid comm"> # print shell descendant PIDs (excl root)` | `private.hiveMind.shell.descendants` |  |
| `hiveMind.snapshot` | `get` |  | `# <role> # echo "uuid\|timestamp\|ctxPct" or empty` | `private.hiveMind.snapshot.get` |  |
|  | `set` |  | `# <role> <uuid> <ctxPct> # upsert snapshot` | `private.hiveMind.snapshot.set` |  |
| `hiveMind.snapshot.jsonl.path` |  |  | `# <uuid> # echo local JSONL path or empty` | `private.hiveMind.snapshot.jsonl.path` |  |
| `hiveMind.snapshot.row.valid` |  |  | `# <row> # SC-F.2/3 — true if row passes per-field validation (logs reason on reject)` | `private.hiveMind.snapshot.row.valid` |  |
| `hiveMind.snapshot.version` | `check` |  | `# <snapfile> # SC-F.1 — 0 if supported (v1 explicit OR no header→grandfather), 1 if unknown` | `private.hiveMind.snapshot.version.check` |  |
| `hiveMind.snapshots` | `ensure` | `dir` |  | `private.hiveMind.snapshots.ensure.dir` |  |
| `hiveMind.state` | `clear` |  |  | `private.hiveMind.state.clear` |  |
|  | `get` |  |  | `private.hiveMind.state.get` |  |
|  | `set` |  |  | `private.hiveMind.state.set` |  |
| `hiveMind.sweep` | `detect` |  |  | `private.hiveMind.sweep.detect` | `private.hiveMind.sweep.detect` |
| `hiveMind.sweep.ratelimit` | `probe` |  | `# <content> # echo retry-detail + return 0 if content is an UNRESOLVED, last-substantive rate-limit; else return 1` | `private.hiveMind.sweep.ratelimit.probe` |  |
| `hiveMind.task` | `transfer` |  | `# <sshHost> <taskFile> <filename> # scp task file to remote session/tasks/` | `private.hiveMind.task.transfer` | `private.hiveMind.task.transfer` |
| `hiveMind.team.host` |  |  | `# <session> # host owning a team (teams.env column 3); default = local HIVEMIND_HOST when absent` | `private.hiveMind.team.host` |  |
| `hiveMind.teams` | `complete` |  |  | `private.hiveMind.teams.complete` ✅ | `private.hiveMind.teams.complete` ✅ |
|  | `ensure` | `dir` |  | `private.hiveMind.teams.ensure.dir` ✅ | `private.hiveMind.teams.ensure.dir` ✅ |
| `hiveMind.workers.legacy` |  |  | `# # list worker agents via agentRoom or pane titles` | `private.hiveMind.workers.legacy` |  |
<!-- END generated: oosh method matrix -->
