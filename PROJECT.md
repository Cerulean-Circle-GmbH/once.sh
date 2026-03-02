# OOSH - Object Oriented Shell

## Recovery After Context Reset

Read `sessions/agent.context.md` for current goals, recent work, and recovery steps.

## Must-Read Documentation

| Priority | File | Content |
|----------|------|---------|
| 1 | [docs/oosh-architecture.md](docs/oosh-architecture.md) | Complete OOSH reference - OOP concepts, bootstrap, patterns |
| 2 | [docs/wiki-index.md](docs/wiki-index.md) | All documentation links |
| 3 | `sessions/agent.context.md` | Current goals, recent work, recovery steps |

Tool documentation (read as needed):
- [docs/log.md](docs/log.md) - Logging system
- [docs/debug.md](docs/debug.md) - Step debugger, traps
- [docs/config.md](docs/config.md) - Configuration persistence
- [docs/state.md](docs/state.md) - State machines
- [docs/oo.md](docs/oo.md) - Script creation

## OOSH Conventions

- Source scripts with full paths: `$OOSH_DIR/path/to/script` not just `script`
- Don't filter oosh output — no `| tail`, `2>&1` — use `log.level` instead
- Use `console.log` for user-facing output (respects the oosh logging system)
- If stuck in debugger: `h` for help, `c` to continue, `q` to quit

## OOSH Wrappers

These scripts wrap external tools with oosh method syntax:

| Wrapper | Wraps | Example |
|---------|-------|---------|
| `otmux` | tmux terminal multiplexer | `otmux new`, `otmux list`, `otmux attach` |
| `claudeCode` | Claude Code CLI | `claudeCode session`, `claudeCode resume` |
| `claudeFlow` | Claude Flow orchestration | `claudeFlow tmux.init`, `claudeFlow list` |

## Testing with test.suite

Documentation: [docs/test-suite.md](docs/test-suite.md)

```bash
# Run a single test
./test.suite run <scriptname> <log-level>
./test.suite run c2 1          # Run c2 tests with minimal logging

# Run all tests
./test.suite all 1

# Log levels affect debugger behavior:
# 1 = minimal (recommended for CI)
# 3 = normal with test details
# 5+ = debug mode (may trigger breakpoints)
```

Writing tests:
```bash
#!/usr/bin/env bash
source this
source test.suite
source $OOSH_DIR/ng/c2    # Source script under test with full path

log.level $level

test.case $level "test description" function_to_test arg1 arg2
expect 0 "expected_result" "assertion message"
# Or simpler:
expect.pass "test passed"
expect.fail "test failed"

test.suite.save.results   # Always call at end
```

Never use output filtering (`| tail`, `| head`, `2>&1`) when running oosh tests.

## Completion System (c2)

Documentation: [docs/completion-system.md](docs/completion-system.md)

The `c2` script (in `ng/c2`) provides Tab completion for oosh methods:

```bash
./c2 function.completion ./otmux           # List all otmux methods
./c2 function.completion ./otmux config    # List config.* methods
```

Custom completion: Define `scriptname.method.completion.parameter()` functions.

## Tmux Workflow

Run tests and long-running commands in tmux panes:

```bash
# Setup with otmux
./otmux install           # Install tmux and initialize config
./otmux new mySession     # Create new session (UTF-8 enabled by default)
./otmux splitV            # Split into upper/lower panes

# Remote control via otmux send
./otmux sendEnter mySession:0.1 './test.suite run c2 1'

# Capture output
tmux capture-pane -t mySession:0.1 -p
```

## Logging

| Function | Min LOG_LEVEL | Writes to |
|----------|---------------|-----------|
| `console.log` | 3 | LOG_DEVICE |
| `important.log` | 2 | LOG_DEVICE |
| `error.log` | 1 | LOG_DEVICE |

If `console.log` produces no output, check `LOG_DEVICE` — should be `/dev/tty`.
See [docs/log.md](docs/log.md) for details.

## Key Documentation References

| Topic | Document |
|-------|----------|
| Architecture | [docs/oosh-architecture.md](docs/oosh-architecture.md) |
| Testing | [docs/test-suite.md](docs/test-suite.md) |
| Completion | [docs/completion-system.md](docs/completion-system.md) |
| Logging | [docs/log.md](docs/log.md) |
| Debugging | [docs/debug.md](docs/debug.md) |
