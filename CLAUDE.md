# OOSH - Object Oriented Shell

## Context Warning - MANDATORY

**When Claude Code shows a context low warning:**

1. **STOP** all other tasks immediately
2. **UPDATE** `sessions/agent.context.md` with:
   - Completed work this session
   - Pending tasks / current state
   - Key decisions made
   - Any blockers or questions
3. **THEN** proceed with `/compact` or continue

This ensures session state is preserved before context is lost.

---

## Must-Read Documentation

**Read these first for OOSH understanding:**

| Priority | File | Content |
|----------|------|---------|
| 1 | [docs/oosh-architecture.md](docs/oosh-architecture.md) | Complete OOSH reference - OOP concepts, bootstrap, patterns |
| 2 | [docs/wiki-index.md](docs/wiki-index.md) | All documentation links |
| 3 | `sessions/agent.context.md` | Current goals, recent work, recovery steps |

**Tool documentation (read as needed):**
- [docs/log.md](docs/log.md) - Logging system
- [docs/debug.md](docs/debug.md) - Step debugger, traps
- [docs/config.md](docs/config.md) - Configuration persistence
- [docs/state.md](docs/state.md) - State machines
- [docs/oo.md](docs/oo.md) - Script creation

---

## OOSH Wrappers

These scripts wrap external tools with oosh method syntax for easier use:

| Wrapper | Wraps | Common Methods |
|---------|-------|----------------|
| `claudeCode` | Claude Code CLI | `claudeCode session`, `claudeCode resume` |
| `claudeFlow` | Claude Flow orchestration | `claudeFlow tmux.init`, `claudeFlow list`, `claudeFlow swarm.status` |
| `otmux` | tmux terminal multiplexer | `otmux new`, `otmux list`, `otmux attach` |

**Usage pattern:**
```bash
./claudeFlow tmux.init          # Initialize tmux workspace
./claudeFlow list               # List all Claude sessions on host
./claudeFlow list --json        # JSON output
./otmux list                    # List tmux sessions
```

---

## Agent Per-Prompt Checklist

- [ ] **Run tests/commands in tmux lower pane** (see below)
- [ ] **Update `.claude/settings.json` permissions** for any new commands used
- [ ] Update `sessions/agent.context.md` if goals change
- [ ] Keep output clean (no debug pollution)

**Context file:** `sessions/agent.context.md`
**Permissions:** `.claude/settings.json` → `permissions.allow[]`

---

## Tmux Workflow (MANDATORY)

**All Task agents, tests, and long-running commands MUST run in the tmux lower pane.**

```bash
# Setup with otmux
./otmux install           # Install tmux and initialize config
./otmux new mySession     # Create new session (UTF-8 enabled by default)
./otmux splitV            # Split into upper/lower panes

# Remote control via otmux send
./otmux sendEnter mySession:0.1 './test.suite run c2 1'  # Run tests in pane 1
./otmux send mySession:0.1 'h' Enter                      # Send help command

# Capture output (don't use | tail or 2>&1 - oosh has its own logging)
tmux capture-pane -t mySession:0.1 -p

# Navigation
# Ctrl+b ↑/↓ - Switch between panes
```

---

## Testing with test.suite

**Documentation:** [docs/test-suite.md](docs/test-suite.md)

OOSH uses `test.suite` for all testing. Key points:

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

**Writing tests:**
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

**Important:** Never use output filtering (`| tail`, `| head`, `2>&1`) when running oosh tests - the framework has its own logging system via `log.level`.

---

## Completion System (c2)

**Documentation:** [docs/completion-system.md](docs/completion-system.md)

The `c2` script (in `ng/c2`) provides Tab completion for oosh methods:

```bash
# Test completion programmatically
./c2 function.completion ./otmux           # List all otmux methods
./c2 function.completion ./otmux config    # List config.* methods

# Interactive completion testing via tmux
./otmux sendEnter mySession:0.1 './c2 function.completion ./otmux config'
```

**Custom completion:** Define `scriptname.method.completion.parameter()` functions to provide custom completions for specific parameters.

---

## OOSH Best Practices for Agents

1. **Use otmux for all shell operations** - provides UTF-8, color support, and remote control
2. **Run tests in tmux panes** - use `./otmux sendEnter` to execute, capture output with `tmux capture-pane`
3. **Respect log levels** - use level 1 for clean output, higher for debugging
4. **Source scripts with full paths** - use `$OOSH_DIR/path/to/script` not just `script`
5. **Don't filter oosh output** - no `| tail`, `2>&1` - use `log.level` instead
6. **Check debugger** - if stuck, send `h` for help, `c` to continue, `q` to quit

---

## Key Documentation References

| Topic | Document |
|-------|----------|
| Architecture | [docs/oosh-architecture.md](docs/oosh-architecture.md) |
| Testing | [docs/test-suite.md](docs/test-suite.md) |
| Completion | [docs/completion-system.md](docs/completion-system.md) |
| Logging | [docs/log.md](docs/log.md) |
| Debugging | [docs/debug.md](docs/debug.md) |
| tmux Colors | [docs/tmux.claude.code.color.issue.md](docs/tmux.claude.code.color.issue.md) |
