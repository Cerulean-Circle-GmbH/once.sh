# Task Agent: Create Task 33 — Automate Sweep as OOSH Methods

**From**: PO directive at `session/tasks/instructions-team-automate-sweep.md`

Create a task file for:

## Task 33: hiveMind sweep/unblock/sweep.loop

Three new methods in hiveMind:

1. `hiveMind sweep` — batch-capture all registered panes, return status table (pane | role | status | action-needed)
2. `hiveMind unblock <name|all>` — detect and fix stuck prompts (permission, queued message, autocomplete)
3. `hiveMind sweep.loop <seconds>` — continuous sweep + unblock every N seconds

**Assigned to**: oosh-expert (implement), oosh-tester (validate)
**Priority**: High — reduces permission prompts from 6+ per sweep to 1
**Depends on**: Task 30 (Enter fix) should be done first

Read the full PO directive: `session/tasks/instructions-team-automate-sweep.md`
