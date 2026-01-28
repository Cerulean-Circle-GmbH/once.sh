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
| `init <?workers> <?topology>` | Initialize hivemind session |
| `attach` | Attach to hivemind tmux session |
| `detach` | Detach from current session |
| `kill` | Shutdown hivemind completely |

```bash
# Examples
./hiveMind init                    # Default: 3 workers
./hiveMind init 5                  # 5 workers
./hiveMind init 8 hierarchical-mesh  # 8 workers, mesh topology
```

### Agent Management

| Command | Description |
|---------|-------------|
| `list` | List all agents (queen + workers) |
| `workers` | List worker agents only |
| `queen` | Show queen agent ID |
| `spawn <count> <?type>` | Spawn additional workers |
| `focus <agentId>` | Focus on agent's tmux pane |
| `send <agentId> <command>` | Send command to agent's pane |

```bash
# Examples
./hiveMind list                    # Show all agent IDs
./hiveMind spawn 3 coder           # Spawn 3 coder agents
./hiveMind focus queen-1234        # Focus queen pane
./hiveMind send hive-worker-abc "ls -la"
```

### Task Management

| Command | Description |
|---------|-------------|
| `task <description> <?priority>` | Submit task to hive |
| `broadcast <message>` | Send message to all workers |
| `docs` | Task hive with documentation creation |

```bash
# Examples
./hiveMind task "Implement login feature" high
./hiveMind broadcast "Focus on testing"
./hiveMind docs                    # Create OOSH docs
```

### Status & Monitoring

| Command | Description |
|---------|-------------|
| `status <?pane>` | Show hive status (0=here, 1=status pane) |
| `refresh` | Refresh agent panes to match hive |
| `panes` | List all agent tmux panes |

### Claude Code Integration

| Command | Description |
|---------|-------------|
| `claude <?prompt> <?model>` | Run Claude Code in main pane |
| `join <sessionId>` | Join existing Claude Code session |

```bash
# Examples
./hiveMind claude "explain the state machine" sonnet
./hiveMind join abc123-def456
```

---

## Tmux Layout

When initialized, HiveMind creates:

```
┌─────────────────────────────────────────┐
│ Window: hive                            │
├─────────────────────────────────────────┤
│                                         │
│  claude-main (60%)                      │
│  Main Claude Code session               │
│                                         │
├─────────────────────────────────────────┤
│  hive-status (40%)                      │
│  Status/control pane                    │
│                                         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Window: agents                          │
├──────────────────┬──────────────────────┤
│ worker-1         │ worker-2             │
│                  │                      │
├──────────────────┼──────────────────────┤
│ worker-3         │ worker-4             │
│                  │                      │
└──────────────────┴──────────────────────┘
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
