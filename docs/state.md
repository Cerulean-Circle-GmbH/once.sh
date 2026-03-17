# State Machine Tool Documentation

The `state` tool provides a framework for creating and managing state machines in oosh/once.sh. State machines enable multi-step workflows with validation, branching, and transition logic.

## Overview

State machines are stored as bash arrays in `$CONFIG_PATH/stateMachines/<name>.states.env`. Each state has an ID (number) and a value (name or transition target).

## Core Concepts

### State Machine Structure

A state machine consists of:
- **States**: Array entries with `[id]="name"` pairs
- **Transitions**: States where the value is a number (jumps to that state ID)
- **Script Reference**: The script containing `private.check.*` validation functions
- **Current State ID**: Tracks the machine's current position

### Default Template (from `state.machine.init`)

```bash
declare -xag ${machine}_STATES='(
  [0]="not.installed"      # Initial state
  [1]="initialized"        # After creation
  [2]="setup"              # Ready to add custom states
  [3]="all.states.added"   # Custom states defined
  [4]="started"            # Machine is running
  [5]=11                   # Transition → jump to first custom state
  [6]=to.be.deleted        # Cleanup state
  [11]="next.custom.state" # Placeholder for custom states
  [12]=99                  # Transition → jump to finished
  [99]="finished"          # Terminal state
  [100]=6                  # Transition → jump to cleanup
)'
${machine}_STATE_ID=1
${machine}_CUSTOM_SCRIPT=<script>
```

## Creating a State Machine

### Current Machine Concept

The state tool tracks a "current machine". Once set, commands operate on it without needing to specify the machine name:

```bash
state of PDCA              # Sets PDCA as current machine
state current              # Shows current machine info
state entry.list           # Lists states of current machine (PDCA)
state transition.next      # Advances current machine (PDCA)
```

### Command Line vs Script Usage

**Command line** (space notation):
```bash
state machine.create PDCA scrumMaster
state entry.add planning silent
```

**Inside scripts** after `source $OOSH_DIR/state` (dot notation):
```bash
source $OOSH_DIR/state
state.machine.create PDCA scrumMaster
state.entry.add planning silent
```

---

### Step 1: Create the Machine

```bash
state machine.create PDCA scrumMaster
```

This:
1. Creates `$CONFIG_PATH/stateMachines/PDCA.states.env`
2. Initializes with the default template
3. Sets `PDCA_CUSTOM_SCRIPT=scrumMaster` (script containing `private.check.*` functions)
4. Sets PDCA as the current machine

### Step 2: Add Custom States

The machine must be in state [2]="setup" to add states. Commands operate on current machine:

```bash
state entry.add planning               silent
state entry.add doing                  silent
state entry.add checking               silent
state entry.add acting                 silent
state entry.add finished               silent
state entry.add error.max.iterations   silent
```

States are added sequentially starting at slot [11]:
- `state entry.add planning` → [11]="planning"
- `state entry.add doing` → [12]="doing"
- etc.

### Step 3: Add Transition States

To create a transition (a state that jumps to another state ID):

```bash
state entry.add 20 silent  # Creates a state with VALUE "20" that jumps to state ID 20
```

**Important**: When you add a number, it creates a state where:
- The VALUE is the number string (e.g., "20")
- When the machine reaches this state, it automatically jumps to that state ID

### Step 4: Start the Machine

```bash
state machine.start scrumMaster
```

This starts the CURRENT machine (PDCA) and:
1. Validates that all required `private.check.*` functions exist in the script `scrumMaster`
2. Advances the state to [4]="started"

Note: The script parameter tells which script has the validation functions, not which machine to start.

### Step 5: Advance Through States

```bash
state transition.next
```

This advances the CURRENT machine:
1. Increments the state ID
2. Calls the `private.check.<stateName>` function from the associated script
3. The check function can return a different state ID to branch

## The private.check Pattern

Each state can have a validation function in your script:

```bash
private.check.<statename>() {
  local script=$1; shift
  local stageTo=$1; shift
  local stateFound=$1; shift

  # Validation logic here

  # Return normally to continue to next state:
  create.result 0 "success message"
  return $(result)

  # Or return a state ID to branch:
  create.result 0 30  # Jump to state [30]
  return $(result)
}
```

### Branching Logic

The check function can return:
- A **string message**: Continue to the next sequential state
- A **number**: Jump to that state ID (branching)

Example from `oo`:

```bash
private.check.priviledges.checked() {
  if [ "$USER" = "root" ]; then
    create.result 0 "30"  # Jump to state [30]="root.rights"
  else
    create.result 0 "20"  # Jump to state [20]="user.rights.only"
  fi
}
```

## Example: The `oo` Script's SETUP_SERVER Machine

The `oo` script demonstrates a complex state machine for installation:

```bash
private.init.state.machine() {
  local machine=$1
  console.log "initialising state machine: ${machine}"

  # Source the state script to use dot notation
  source $OOSH_DIR/state

  # Create machine with 'oo' as the script containing private.check.* functions
  state.machine.create ${machine} oo

  # Add custom states (sequentially assigned IDs starting at 11)
  state.entry.add remote.install.started               silent   # [11]
  state.entry.add local.install.started                silent   # [12]
  state.entry.add priviledges.checked                  silent   # [13]
  state.entry.add 20                                   silent   # [14]="20" - transition to [20]
  state.entry.add user.rights.only                     silent   # [15]
  state.entry.add user.installation.done               silent   # [16]
  state.entry.add 30                                   silent   # [17]="30" - transition to [30]
  state.entry.add root.rights                          silent   # [18]
  state.entry.add root.shared.dev.folder.created       silent   # [19]
  # ... more states

  # Advance past setup states and start the machine
  state.transition.next              # Move through initial states
  state.machine.start oo             # Validate private.check.* exist, set state to [4]=started
  state.transition.next              # Advance to first custom state
  state.transition.next              # Continue advancing
}
```

## State Tool Commands Reference

Command line usage (space notation). Signatures from method comments:

| Command | Signature | Description |
|---------|-----------|-------------|
| `state machine.list` | `<?nameFilter>` | Lists all available state machines |
| `state of` | `<machine> <?method>` | Selects machine as current, optionally calls method |
| `state current` | `<?print>` | Load current state cache, print if no arg |
| `state entry.list` | `<?machine> <listOption:all>` | Lists states |
| `state machine.create` | `<machine> <?script>` | Creates a new state machine |
| `state machine.exists` | `<machine>` | Checks if machine exists |
| `state machine.delete` | `<machine>` | Deletes a state machine (no warning) |
| `state machine.start` | `<?machine> <script>` | Validates private.check.* and starts |
| `state machine.declaration` | `<?machine>` | Shows machine declaration |
| `state machine.edit` | `<machine>` | Edit machine in editor |
| `state machine.diagnose` | | Shows full diagnostics and cache |
| `state entry.add` | `<?machine> <newStateName> <print>` | Adds state (must be in setup) |
| `state entry.set` | `<?machine> <state>` | Sets state directly |
| `state entry.find` | `<?machine> <allStates> <alwaysReturnId>` | Returns state ID for name |
| `state entry.rename` | `<?machine> <allStates> <newStateName:> <print:>` | Rename a state |
| `state transition.next` | `<?machine> <state>` | Advances to next state with check |
| `state transition.stage` | `<?machine> <state>` | Stage a state change |
| `state transition.check` | `<?machine> <allStates> <?script:state>` | Checks if state can be set |
| `state name` | `<?machine>` | Returns current state name |
| `state id` | `<?machine>` | Returns current state ID |
| `state declaration` | `<?machine>` | Shows machine declaration |
| `state edit` | `<?machine>` | Edit current machine |

After `source $OOSH_DIR/state`, use dot notation: `state.machine.create`, `state.entry.add`, etc.

## State Lifecycle

```
[1] initialized
    ↓
[2] setup (can add states here)
    ↓
[3] all.states.added (after state.entry.add calls)
    ↓
[4] started (after state.machine.start)
    ↓
[5] = 11 (transition to first custom state)
    ↓
[11] your.first.state
    ↓
    ... your custom states ...
    ↓
[99] finished
```

## Files

- `$CONFIG_PATH/stateMachines/<name>.states.env` - State machine definition
- `$CONFIG_PATH/current.state.machine.env` - Cache of currently selected machine

## Best Practices

1. **Always use `silent`** when adding states to avoid verbose output
2. **Implement `private.check.*`** for each state that needs validation
3. **Use number transitions** sparingly - prefer check function branching
4. **Test the workflow** by stepping through `state.transition.next` calls
5. **Use `state machine.diagnose`** for debugging state machine issues

## See Also

- [wiki-index.md](wiki-index.md) - Documentation index
- [oo script](../oo) - Example of state machine usage
- [scrumMaster](../scrumMaster) - PDCA state machine implementation
