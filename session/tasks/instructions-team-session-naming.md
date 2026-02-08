# Team Directive: Session Naming (from PO)

## Problem
Every Claude Code agent session shows task names instead of agent role names in tmux pane titles. The `otmux tree` output is unreadable — you can't tell which pane is which agent.

## Root Cause
Claude Code overwrites the tmux pane title with its current subagent task description. Every time a Task tool runs, the pane title changes.

## Required Actions

### Step 1: Every agent must rename their Claude Code session
Each agent runs `/rename <role-name>` in their own Claude Code session:

| Pane | Agent | Command |
|------|-------|---------|
| 0.0 | orchestrator | `/rename orchestrator` |
| 0.2 | agent-trainer | `/rename agent-trainer` |
| 0.3 | task-agent | `/rename task-agent` |
| 0.4 | oosh-expert | `/rename oosh-expert` |
| 0.5 | oosh-tester | `/rename oosh-tester` |
| 0.6 | scrum-master | `/rename scrum-master` |

### Step 2: Expert to investigate preventing title overwrites
The oosh-expert should investigate whether tmux `allow-rename off` per pane can prevent Claude Code from overwriting titles. If so, add an `otmux pane.lock` method that:
1. Sets the pane title via `otmux pane.title`
2. Disables title renaming for that pane

### Step 3: Pane 0.7 cleanup
Pane 0.7 is a bare shell with no agent. Either:
- Kill it: close the shell
- Or assign it a role

## Priority
This is a governance issue — per SKILL.md, every Claude Code session MUST have a name matching the agent role. Non-compliance is a first-principles violation.
