# Debug System Documentation

The `debug` script provides interactive debugging capabilities for oosh, including step-through execution, stack traces, and trap handlers for errors and returns.

## Overview

The debug system supports:
- **Interactive step debugger** with command menu
- **Stack trace** display for function call inspection
- **Trap handlers** for ERR, RETURN, and EXIT events
- **Debug level toggling** for quick verbosity changes
- **Expected error handling** for test scenarios

## Quick Start

```bash
# Enable step debugging
export STEP_DEBUG=ON
source debug

# Or set high log level to auto-enable traps
export LOG_LEVEL=6
source debug
```

## Environment Variables

| Variable | Values | Description |
|----------|--------|-------------|
| `STEP_DEBUG` | ON/OFF | Enables interactive step mode |
| `LOG_LEVEL` | 1-7 | Controls debug verbosity |
| `STEP_TILL_NEXT_RETURN` | ON/OFF | Continue until next function return |
| `EXPECTED_RETURN_VALUE` | number | Expected error code for test assertions |

## Interactive Step Debugger

When `STEP_DEBUG=ON`, the `step()` function provides an interactive debugging prompt at each line.

### Step Commands

| Command | Description |
|---------|-------------|
| `ENTER` | Continue to next command |
| `h` | Show help menu |
| `e` | Expand and show the current command with variables resolved |
| `n` | Next command with full debug trace |
| `d` | Enable debug messages (level 5) |
| `x` | TRON: Enable full code trace (level 6) |
| `t` | Show stack trace |
| `s` | Continue silently (level 1) |
| `c` | Continue with previous log level |
| `p` | Print PATH |
| `ll` | List current directory |
| `ls` | List directory (short) |
| `cd` | Change to entered directory |
| `root` | Tree view of /root |
| `home` | Tree view of /home |
| `env` | Show environment variable value |
| `cmd` | Run arbitrary command (use carefully) |
| `q` | Exit/quit |

### Example Session

```bash
export STEP_DEBUG=ON
source debug
./myScript process

# At each line you'll see:
# +<----------------------------------------- ON
# > myScript.process( arg1 arg2 )  in file: myScript
# > line: 42 'echo "hello"'
#
# Press ENTER to continue, or enter a command
```

## Functions

### debug.step()

The main interactive debugger function. Called automatically via DEBUG trap when enabled.

```bash
# Enable step debugging
export STEP_DEBUG=ON
debug.setTrap

# Now each line will pause for interaction
```

### debug.stackTrace()

Displays the complete call stack with line numbers, function names, files, and arguments.

```bash
# In step mode, press 't' to see:
# i:  0  line:     42  function: myScript.process()   file: myScript    args: arg1 arg2
# i:  1  line:    100  function: myScript.start()     file: myScript    args:
# i:  2  line:      0  function: source()             file: debug       args:
```

### debug.toggleDebug()

Toggles between debug mode (level 5) and normal mode (level 3).

```bash
./debug toggleDebug  # Switch debug on/off
```

### debug.setTrap()

Sets up all debugging traps:
- `ERR` trap → `debug.onError()` - Handles errors
- `RETURN` trap → `debug.onReturn()` - Logs function returns
- `EXIT` trap → `debug.onExit()` - Cleanup on exit
- `DEBUG` trap → `debug.step()` - Interactive stepping

```bash
./debug setTrap  # Enable all traps
```

### debug.onError()

Trap handler for errors. Shows error details and optionally stack trace.

```bash
# Automatically called on errors when trap is set
# Shows: line number, command, file, error code
```

### debug.onReturn()

Trap handler for function returns. Logs return values at debug level.

```bash
# Automatically called after each function return
# Logs: function name, return code, RESULT value
```

### debug.expect.error()

Sets an expected error code for testing. When this error occurs, it's treated as success.

```bash
./debug expect.error 1   # Expect exit code 1
myScript.failingMethod
# No error shown because code 1 was expected
```

### debug.noop()

No-operation function, returns 0. Useful as a placeholder.

```bash
./debug noop  # Does nothing, returns 0
```

## PS4 Trace Format

When trace mode is enabled (level 6+), the PS4 variable provides detailed execution context:

```
source_file -> caller_file: function:line - stack
```

Example output:
```
  myScript -> main.sh: myScript.process:42   - myScript main.sh debug
```

## Usage Examples

### Basic Step Debugging

```bash
#!/usr/bin/env bash
source this
source debug

export STEP_DEBUG=ON
debug.setTrap

echo "This will pause"
myScript.process "arg1"
echo "This too"
```

### Debugging a Specific Section

```bash
#!/usr/bin/env bash
source debug

# Normal execution here...

# Enable debugging for problematic section
export STEP_DEBUG=ON
debug.setTrap

myScript.problematicMethod
myScript.anotherMethod

# Disable debugging
export STEP_DEBUG=OFF
```

### Expected Errors in Tests

```bash
source debug

# This method should fail with code 1
./debug expect.error 1
myScript.methodThatFails
# No error message shown

# Reset expectation
./debug expect.error 0
```

### Stack Trace on Demand

```bash
source debug

myScript.outer() {
  myScript.inner
}

myScript.inner() {
  debug.stackTrace  # Shows full call chain
}

myScript.outer
```

### Toggle Debug While Running

```bash
source debug

myScript.processData() {
  for item in "$@"; do
    # Toggle debug mid-execution
    if [ "$item" = "problem" ]; then
      debug.toggleDebug
    fi
    myScript.processItem "$item"
  done
}
```

## Integration with Log System

The debug script integrates with the log system:

| Log Level | Debug Behavior |
|-----------|----------------|
| 1-4 | Traps set automatically |
| 5 | Debug messages shown |
| 6 | PS4 trace enabled |
| 7 | Full step debug mode |

```bash
# Set via log system
./log level 6  # Enables trace mode

# Or directly
export LOG_LEVEL=7
source debug
```

## Error Handling

The `debug.onError` trap provides:
- Error code translation via `errno` command
- Source file and line number
- Stack trace at level 4+
- Special handling for `ERROR_CODE_RECONFIG`

```bash
# Error output example:
# ERROR> line 42: "bad_command" from myScript returned with ERROR code: 127 (ENOENT)
```

## Testing

The debug system has tests in `test/test.debug`:

```bash
./test.suite run debug 1
```

## See Also

- [Log System Documentation](log.md)
- [Config System Documentation](config.md)
- [State Machine Documentation](state.md)
- [OOSH Architecture](oosh-architecture.md)
- [Wiki Index](wiki-index.md)
