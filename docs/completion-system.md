# Completion System

## Overview
The oosh/once.sh project features a dynamic Bash completion system, primarily implemented in the `c2` script. This system provides context-aware completions for commands, methods, parameters, and integrates standard Bash completions.

## Main Features
- Reads available scripts and their functions for completion.
- Parses method parameters and default values directly from code.
- Integrates standard file, directory, user, group, alias, and environment variable completions.
- Supports custom completions for specific parameters and methods.
- Designed for extensibility and DRY (Don't Repeat Yourself) principles.

## Completion Precedence (3-tier)
The order in which completions resolve is a MANDATORY first principle — see
**[first-principles.md](first-principles.md) → Bash Completion (c2) → Completion Precedence**:
1. Method-specific `<class>.<method>.completion.<param>` HARD-OVERWRITES the standard.
2. Standard class-level `<class>.parameter.completion.<param>` is the default fallback.
3. Parameter completion (either tier) is used OVER method/sub-command listing once a full method+params is on the line.
Parameter names must be valid bash identifiers (no `...`/dashes/spaces) or `declare PARAM_<name>` breaks tracking.

## How It Works
- The `c2` script scans scripts for function signatures and documentation.
- Completion logic is modular and can be extended for new scripts and methods.
- Parameter and default value parsing is automatic, reducing duplication.

## Advanced Usage
- Custom completions for advanced scenarios.
- Debugging and troubleshooting completion issues.

## Interactive Completion Testing via tmux

The completion system can be tested interactively using `otmux` to remote control a bash shell via tmux. This approach tests the actual user experience of Tab completion.

### Why Use tmux for Completion Testing?

1. **Real Interactive Shell**: Tests completion in an actual interactive bash session
2. **Automated**: Can be scripted and run as part of test suite
3. **Observable**: You can attach to the tmux session to watch tests run
4. **Isolated**: Tests run in a separate session, not affecting your current shell

### How It Works

```bash
# 1. Create a test tmux session
tmux -u new-session -d -s test_session -c "$OOSH_DIR"

# 2. Start bash and source oosh
tmux send-keys -t test_session:0.0 'exec bash' Enter
tmux send-keys -t test_session:0.0 'source this' Enter

# 3. Send Tab key to trigger completion
tmux send-keys -t test_session:0.0 './otmux config' Tab Tab

# 4. Capture output and verify
OUTPUT=$(tmux capture-pane -t test_session:0.0 -p)
echo "$OUTPUT" | grep -q "config.init"  # Verify completion appeared

# 5. Cleanup
tmux kill-session -t test_session
```

### Using otmux for Completion Testing

The `otmux` wrapper makes this even easier:

```bash
# Create session
./otmux new test_session

# Split and get a bash pane
./otmux splitH

# Send completion test
./otmux send test_session:0.1 './c2 ' Tab Tab

# Capture and verify
./otmux capturePane -t test_session:0.1 -p | grep "completion.discover"
```

### Test Cases in test.c2

The `test/test.c2` script includes interactive completion tests:

1. **c2 Tab completion**: Verifies `./c2 <Tab>` shows c2 methods
2. **otmux Tab completion**: Verifies `./otmux <Tab>` shows otmux methods  
3. **Partial completion**: Verifies `./otmux config<Tab>` shows config.* methods

These tests are skipped if:
- tmux is not installed
- Already running inside a tmux session (to avoid nesting issues)

### Running Interactive Completion Tests

```bash
# Run all c2 tests including interactive tmux tests
cd $OOSH_DIR
./test/test.c2

# Or run with higher log level for debugging
./test/test.c2 5
```

### Watching Tests Run

You can attach to the test session while it's running:

```bash
# In another terminal, while tests are running:
tmux attach -t c2_completion_test_*
```

## See Also
- [test-suite.md](test-suite.md) (for completion/parameter test cases)
- [command-creation.md](command-creation.md)
- [first-principles.md](first-principles.md)
- [tmux.claude.code.color.issue.md](tmux.claude.code.color.issue.md) (tmux color setup)
