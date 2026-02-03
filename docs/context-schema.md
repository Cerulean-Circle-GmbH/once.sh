# Agent Context File Schema

**Purpose:** Define the canonical format for agent context files used in session recovery after `/compact`.

**Location:** `session/agents/<role>.context.md`

---

## Schema Version

1.0

---

## File Structure

```
# <Role Name> — Session Context          ← TITLE (line 1)
                                          ← blank line
**Updated**: YYYY-MM-DDTHH:MMZ           ← METADATA (lines 3-5)
**Role**: <role-name> (<description>)
**Pane**: <pane-id> in <session-name>
                                          ← blank line
## Recovery Steps                         ← REQUIRED SECTION
1. Read this file
2. ...

## Completed Work                         ← REQUIRED SECTION
### Task N: <description> (DONE)
- ...

## Pending                                ← RECOMMENDED SECTION
- ...

## Key Files                              ← RECOMMENDED SECTION
- ...
```

---

## Title (Required)

**Line 1** must be a markdown H1 heading ending with `Context`:

```
# <Role Name> — Session Context
```

- Use em dash `—` (U+2014) as separator
- `<Role Name>` is the human-readable role name (e.g., `OOSH Expert Agent`, `ScrumMaster`)
- Must end with the word `Context`

---

## Metadata (Required)

Three bold key-value fields in the **first 6 lines** of the file (after the title):

| Field | Format | Example |
|-------|--------|---------|
| `**Updated**` | ISO 8601 date or datetime | `2026-02-03T12:15Z` or `2026-02-03` |
| `**Role**` | Role name, optional description in parens | `oosh-expert (implementation & architecture)` |
| `**Pane**` | Pane ID, optional session context | `0.4 in cursorOrchestrator` |

**Rules:**
- Each field on its own line, format: `**Key**: value`
- `**Updated**` must contain a date matching `YYYY-MM-DD`
- All three fields are required

---

## Required Sections

These sections **must** exist. Validation fails without them.

### `## Recovery Steps`

Numbered list of actions to resume work after context loss.

```markdown
## Recovery Steps
1. Read this file
2. Read `.claude/agents/<role>/SKILL.md` at <path>
3. Read `docs/oosh-architecture.md` for framework reference
4. Check with Orchestrator for next task
```

**Rules:**
- Must contain at least one numbered item (`1.`)
- Steps should be actionable and ordered by priority
- First step should always be "Read this file"

### `## Completed Work`

Record of tasks completed in the current session. Prefix match — `## Completed Work This Session` also passes.

```markdown
## Completed Work
### Task 8: Agent navigation by name (DONE — commit c2c326f)
- Part A: tree output
- Part B: registry

### Task 9: Create Agent Trainer role (DONE — commit de0a992)
- Created SKILL.md
- Added to hiveMind
```

**Rules:**
- Section heading must start with `## Completed Work`
- Use `### Task N:` subsections or a numbered list
- Mark completion status: `(DONE)`, `(DONE — commit <hash>)`

---

## Recommended Sections

Validation produces **warnings** if these are missing.

### `## Pending`

Outstanding or blocked work. Prefix match — `## Pending Tasks` also passes.

```markdown
## Pending
- Expert needs to remove `--dangerously-skip-permissions` from hiveMind
- Session ID detection unavailable for sessions without `--resume`
```

### `## Key Files`

Important file paths for this agent's work.

```markdown
## Key Files
- `test/test.hiveMind` — 31 test cases, 33 assertions
- `hiveMind` — registry at line 30, status at ~line 416
- `/tmp/hivemind.roles` — agent registry file
```

---

## Optional Sections

No warnings if absent. Use as needed for the role.

| Section | Purpose | Typical Role |
|---------|---------|-------------|
| `## Current Team Layout` | Pane/agent layout | All |
| `## Current State` | Status summary | Tester |
| `## Key Rules` | Operational rules | Expert, ScrumMaster |
| `## Key Architecture Decisions` | Design patterns | Expert |
| `## Git Status` | Branch, latest commit | Expert |
| `## Next Tasks` | Assigned upcoming work | Expert |
| `## Test Suites` | Test suite counts | Tester |

---

## Validation

Use the `context` script to validate:

```bash
# Validate a single file
./context validate session/agents/oosh-expert.context.md

# Validate all agent context files
./context validate.all

# Display the schema
./context schema
```

**Exit codes:**
- `0` — valid (may have warnings)
- `1` — invalid (has errors)

---

## Lifecycle (Automated Save-Before-Compact)

The `context` script provides a lifecycle state machine to automate the save-before-compact workflow.

### State Machine

Each agent role gets its own state machine tracking where it is in the save/compact cycle:

```
active → saving → saved → compacting → recovering → active (loop)
```

| State | Meaning |
|-------|---------|
| `active` | Normal work — agent is operating |
| `saving` | Context write triggered (transitional) |
| `saved` | Context file written and validated against schema |
| `compacting` | `/compact` is running |
| `recovering` | Post-compact, agent re-reading context |

Machine stored at: `$CONFIG_PATH/stateMachines/<machine_name>.states.env`
Machine naming: role with hyphens replaced by underscores (e.g., `oosh-expert` → `oosh_expert`)

### Lifecycle Commands

```bash
# Initialize lifecycle for a role
./context lifecycle.init oosh-expert

# Save context (validates + transitions to saved)
./context lifecycle.save oosh-expert

# Check status (single role or all)
./context lifecycle.status oosh-expert
./context lifecycle.status

# Pre-compact check (uses HIVEMIND_ROLE env var)
./context lifecycle.pre.compact

# Recover after compact (transitions back to active)
./context lifecycle.recover oosh-expert
```

### PreCompact Hook

A PreCompact hook at `.claude/hooks/pre-compact.sh` runs automatically before `/compact`:

- Checks if `HIVEMIND_ROLE` is set
- Validates context file exists with required sections
- Outputs warnings if context isn't saved
- Auto-marks state as `saved` if context passes validation
- Always exits 0 (PreCompact cannot block)

Hook configured in `.claude/settings.local.json`.

### Typical Flow

1. Agent works normally (state: `active`)
2. Before `/compact`, agent runs `./context lifecycle.save <role>`
3. Validation passes → state becomes `saved`
4. `/compact` runs → PreCompact hook confirms context is saved
5. After compact, agent runs `./context lifecycle.recover <role>`
6. State returns to `active`

---

## Migration Guide

To migrate an existing context file to this schema:

1. Run `./context validate <file>` to see errors
2. Fix title format: `# <Role> — Session Context` (line 1)
3. Ensure metadata fields use `**Updated**:`, `**Role**:`, `**Pane**:` format
4. Rename section headings to canonical names (e.g., `## Completed This Session` -> `## Completed Work`)
5. Add missing required sections
6. Re-run validation until errors reach 0
