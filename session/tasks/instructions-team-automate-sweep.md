# PO Directive: Automate Repetitive Commands as OOSH Methods

## Problem
The SM and Orchestrator repeat the same commands every sweep cycle:
- `./otmux pane.capture` on every pane
- `./otmux send <pane> Enter` to unblock
- Manual parsing of output to detect stuck prompts

Each raw command triggers a permission prompt. A 6-pane sweep = 6+ permission prompts. This is why the SM gets stuck — it's fighting permissions instead of monitoring.

## Solution: OOSH First Principles

Wrap repetitive patterns in OOSH methods. One method = one permission = entire sweep done.

### Required new methods (Expert to implement)

#### 1. `hiveMind sweep` (or `hiveMind monitor.all`)
Batch-capture all registered agent panes in one call. Returns a summary table.
```bash
# Instead of 6 separate pane.capture calls:
./hiveMind sweep
# Output: table of pane | role | status | action-needed
```

#### 2. `hiveMind unblock <name|all>`
Detect and resolve common blockers on a pane:
- Permission prompt → send Enter
- Queued message not submitted → send Enter
- `/compact` autocomplete stuck → send Escape then Enter
- Rate limit prompt → send Enter
```bash
./hiveMind unblock all    # Fix all stuck agents in one call
./hiveMind unblock expert # Fix one agent
```

#### 3. `hiveMind sweep.loop`
Continuous monitoring loop — sweep + unblock every N seconds.
```bash
./hiveMind sweep.loop 30  # Sweep every 30 seconds
```
The SM runs this ONE command instead of manually scripting a loop every session.

## Why this matters

- **Fewer permissions** — one OOSH method = one approval, not 6+
- **Consistent behavior** — no more SM doing it differently each session
- **Self-explaining** — `./hiveMind sweep` is Tab-completable and has usage docs
- **DRY** — every agent reinvents the sweep loop today; one method for all

## Priority

This is a first-principles issue. The team is using raw repetitive commands instead of building tools. OOSH exists to solve exactly this problem.

## Assignment

Expert implements. Tester validates. Task Agent tracks as a new task.
