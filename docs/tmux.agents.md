# Tmux Agent Management

Manage claude-flow agents in tmux panes for visual monitoring and interaction.

## Layout Design

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                    MAIN CLAUDE (80%)                    │
│                    Your primary session                 │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  AGENT STATUS (20%)                                     │
│  ID         TYPE       STATUS    TASK                   │
│  agent-1    coder      running   Implementing auth      │
│  agent-2    reviewer   idle      -                      │
└─────────────────────────────────────────────────────────┘
```

When agents are spawned with `claudeFlow.tmux.spawn`, each gets its own pane:

```
┌─────────────────────────────────────────────────────────┐
│                    MAIN CLAUDE                          │
├──────────────────────────┬──────────────────────────────┤
│       agent-1            │          agent-2             │
│       (coder)            │          (reviewer)          │
└──────────────────────────┴──────────────────────────────┘
```

## Quick Start

```bash
# Initialize the agent workspace
claudeFlow tmux.init

# Enable quick-switch bindings (Alt+0-9)
claudeFlow tmux.bind

# Create a named pane for any task
claudeFlow tmux.pane "worker-1" bash

# Or spawn a claude-flow agent
claudeFlow tmux.spawn coder "Implement user auth"

# See all panes with their Alt+N shortcuts
claudeFlow tmux.list

# Switch between panes instantly:
#   Alt+0 = main, Alt+1 = first agent, etc.
#   Alt+n/p = next/previous
#   Alt+z = zoom toggle
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `claudeFlow tmux.init` | Initialize agent window layout |
| `claudeFlow tmux.bind` | Setup Alt+0-9 quick-switch bindings |
| `claudeFlow tmux.spawn <type> <task>` | Spawn claude-flow agent in pane |
| `claudeFlow tmux.pane <name> [cmd]` | Create named pane for any command |
| `claudeFlow tmux.run <name> <cmd>` | Run command in pane (stays open) |
| `claudeFlow tmux.list` | List panes with quick-switch indices |
| `claudeFlow tmux.agents` | List all agent panes |
| `claudeFlow tmux.focus <id>` | Focus on agent pane |
| `claudeFlow tmux.kill <id>` | Kill agent and close pane |
| `claudeFlow tmux.killAll` | Kill all agents, keep main |
| `claudeFlow tmux.main` | Return focus to main pane |
| `claudeFlow tmux.status` | Show agent status bar |
| `claudeFlow tmux.layout <type>` | Change agent pane layout |

## Keyboard Shortcuts

These shortcuts work when tmux prefix is `Ctrl+b` (default):

### Navigation

| Shortcut | Action |
|----------|--------|
| `Ctrl+b` `↑` | Move to pane above |
| `Ctrl+b` `↓` | Move to pane below |
| `Ctrl+b` `←` | Move to pane left |
| `Ctrl+b` `→` | Move to pane right |
| `Ctrl+b` `o` | Cycle through panes |
| `Ctrl+b` `;` | Toggle last active pane |
| `Ctrl+b` `q` | Show pane numbers (then press number) |

### Agent Pane Management

| Shortcut | Action |
|----------|--------|
| `Ctrl+b` `z` | Toggle zoom on current pane (fullscreen) |
| `Ctrl+b` `!` | Break pane into new window |
| `Ctrl+b` `x` | Kill current pane (with confirm) |
| `Ctrl+b` `{` | Swap pane with previous |
| `Ctrl+b` `}` | Swap pane with next |

### Layout Switching

| Shortcut | Action |
|----------|--------|
| `Ctrl+b` `Space` | Cycle through layouts |
| `Ctrl+b` `Alt+1` | Even horizontal split |
| `Ctrl+b` `Alt+2` | Even vertical split |
| `Ctrl+b` `Alt+3` | Main horizontal (large top) |
| `Ctrl+b` `Alt+4` | Main vertical (large left) |
| `Ctrl+b` `Alt+5` | Tiled layout |

### Resizing Panes

| Shortcut | Action |
|----------|--------|
| `Ctrl+b` `Ctrl+↑` | Resize pane up |
| `Ctrl+b` `Ctrl+↓` | Resize pane down |
| `Ctrl+b` `Ctrl+←` | Resize pane left |
| `Ctrl+b` `Ctrl+→` | Resize pane right |

### Custom Bindings (after tmux.init)

| Shortcut | Action |
|----------|--------|
| `Ctrl+b` `m` | Jump to main Claude pane |
| `Ctrl+b` `a` | Show agent list (popup or split) |

### Quick-Switch Bindings (after tmux.bind)

These work **without** the Ctrl+b prefix for fast switching:

| Shortcut | Action |
|----------|--------|
| `Alt+0` | Jump to main pane (index 0) |
| `Alt+1` | Jump to pane 1 |
| `Alt+2` | Jump to pane 2 |
| `Alt+3-9` | Jump to panes 3-9 |
| `Alt+n` | Next pane |
| `Alt+p` | Previous pane |
| `Alt+z` | Toggle zoom (fullscreen) |

Use `claudeFlow tmux.list` to see current pane indices.

## Window Structure

The `claudeFlow tmux.init` command creates:

```
Session: claude-agents
├── Window 0: main
│   ├── Pane 0: Main Claude session (top, 80%)
│   └── Pane 1: Agent status bar (bottom, 20%)
└── Window 1: agents (created on first spawn)
    ├── Pane 0: agent-1
    ├── Pane 1: agent-2
    └── ...
```

## Usage Patterns

### Pattern 1: Side-by-Side Coding

```bash
# Start workspace
claudeFlow tmux.init

# Spawn a coder for feature work
claudeFlow tmux.spawn coder "Add payment processing"

# Spawn a reviewer to check as you go
claudeFlow tmux.spawn reviewer "Review payment code"

# Use tiled layout to see both
claudeFlow tmux.layout tiled
```

### Pattern 2: Research Team

```bash
# Spawn multiple researchers
claudeFlow tmux.spawn researcher "Find auth best practices"
claudeFlow tmux.spawn researcher "Analyze competitor APIs"
claudeFlow tmux.spawn researcher "Security compliance requirements"

# Watch them work in even layout
claudeFlow tmux.layout evenV
```

### Pattern 3: Full Pipeline

```bash
# Spawn full development team
claudeFlow tmux.spawn planner "Design user dashboard"
claudeFlow tmux.spawn coder "Implement dashboard components"
claudeFlow tmux.spawn tester "Write dashboard tests"
claudeFlow tmux.spawn reviewer "Review all changes"

# Main horizontal: you on top, agents below
claudeFlow tmux.layout mainH
```

## Using with Claude Code Subagents

Claude Code's internal Task tool agents run within the same process. To give them
visible panes, create named panes that run commands or watch logs:

```bash
# Setup workspace with quick-switch
claudeFlow tmux.init
claudeFlow tmux.bind

# Create panes for different workers
claudeFlow tmux.pane "explorer" bash      # For exploration tasks
claudeFlow tmux.pane "coder" bash         # For coding tasks
claudeFlow tmux.pane "tester" bash        # For test tasks

# Check your layout
claudeFlow tmux.list
# Output:
#   Alt+0  →  main (bash)
#   Alt+1  →  explorer (bash)
#   Alt+2  →  coder (bash)
#   Alt+3  →  tester (bash)

# Now switch instantly with Alt+0, Alt+1, Alt+2, Alt+3
# Use Alt+z to zoom any pane to fullscreen
```

### Running Commands in Panes

```bash
# Run a command that stays open after completion
claudeFlow tmux.run "build" "npm run build"

# The pane shows output and waits for Enter to close
```

## Integration with otmux

The claudeFlow tmux commands use tmux directly:

```bash
# These are equivalent:
claudeFlow tmux.spawn coder "task"
# Internally calls:
otmux splitH "claude-flow agent spawn -t coder -d 'task'"
```

You can use otmux directly for advanced tmux operations:

```bash
# Rotate agent panes
otmux rotateWindow

# Capture agent output
otmux capturePane -p -t agent-1 > agent-1.log

# Send command to agent pane
otmux send -t agent-1 "status" Enter
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_AGENTS_SESSION` | `claude-agents` | Tmux session name |
| `CLAUDE_MAIN_PANE_SIZE` | `80` | Main pane percentage |
| `CLAUDE_AGENT_LAYOUT` | `mainH` | Default agent layout |

## Troubleshooting

### Panes not visible
```bash
# Check if in tmux
echo $TMUX

# List all panes
otmux panes -a
```

### Agent not responding
```bash
# Check agent status via MCP
claudeFlow agent.status <agent-id>

# Kill and respawn
claudeFlow tmux.kill <agent-id>
claudeFlow tmux.spawn <type> "task"
```

### Layout broken
```bash
# Reset to default layout
claudeFlow tmux.layout mainH

# Or let tmux auto-arrange
otmux tiled
```
