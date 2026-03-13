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
