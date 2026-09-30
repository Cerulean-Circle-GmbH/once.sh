# Log Levels and Testing — Diagnostic Reference

> **CRITICAL NOTE — Context Recovery:**
> When your context runs low or after `/compact`, re-read this document and [docs/oosh-architecture.md](oosh-architecture.md) to recover framework knowledge. This document contains hard-won diagnostic findings about the log system and test suite interactions.

## 1. OOSH Log Levels 0-7

Every log function gates output with `if [ "$LOG_LEVEL" -gt N ]`. Higher levels include all output from lower levels.

| Level | Name | Gate | Functions Active | Use Case |
|-------|------|------|-----------------|----------|
| 0 | Silent | — | None | Suppress all output |
| 1 | Errors | `> 0` | `error.log`, `test.console.log`, `test.success.log`, `error.details.log` | CI / test runs |
| 2 | Warnings | `> 1` | + `warn.log`, `important.log`, `problem.log` | Notice problems |
| 3 | Console | `> 2` | + `console.log`, `success.log`, `silent.log` | **Default** — normal operation (see note) |
| 4 | Info | `> 3` | + `info.log`, `stop.log` | See method dispatch internals |
| 5 | Debug | `> 4` | + `debug.log` | Full debug messages |
| 6 | Trace | `> 5` | + `set -x` PS4 tracing via `seq.puml.log()` | Bash execution trace |
| 7 | Step | `> 6` | + `STEP_DEBUG=ON` interactive breakpoints | Interactive debugging |

> **Note:** During installation, LOG_LEVEL defaults to 1 (errors only). The `LOG_INSTALL` system captures full-density logs to file regardless of LOG_LEVEL.

### Where the functions are defined

| Function | File | Line | Gate |
|----------|------|------|------|
| `info.log` | `this` | 37 | `> 3` |
| `debug.log` | `log` | 207 | `> 4` |
| `console.log` | `log` | 99 | `> 2` |
| `error.log` | `log` | 237 | `> 0` |
| `warn.log` | `log` | 169 | `> 1` |
| `important.log` | `log` | 184 | `> 1` |
| `success.log` | `log` | 143 | `> 2` |
| `silent.log` | `log` | 132 | `> 2` |
| `stop.log` | `log` | 218 | `> 3` |
| `test.console.log` | `log` | 88 | `> 0` |
| `test.success.log` | `log` | 150 | `> 0` |

### Setting the level

```bash
# From a script (sourced context)
log.level 5

# Direct export
export LOG_LEVEL=5

# Toggle between current and previous level
log.level reset

# From command line (persists to config!)
./log level 5
```

## 2. The Config Persistence Pollution Problem

### The bug

When `./test.suite all 1` runs, the test suite can produce massive output — far beyond what level 1 should allow. The `"this.call to:"` messages (`this:682`, uses `debug.log`) should only appear at level 5+, yet they show at level 1.

### Root cause: config.save captures test state

The pollution chain:

```
test/test.log sets export LOG_LEVEL=5 (line 175) to test debug.log behavior
          │
          ▼
config.save log LOG runs (config:324)
captures ALL env vars matching prefix "LOG" via: declare -p | grep LOG
          │
          ▼
~/config/log.env now contains LOG_LEVEL="5" (and test artifacts)
          │
          ▼
~/config/user.env contains: source $CONFIG_PATH/log.env
          │
          ▼
Every script: source this → this.init() → source "$CONFIG" → loads LOG_LEVEL=5
          │
          ▼
Between "source this" and "log.level $level", all sourced scripts run at level 5
info.log and debug.log become active → massive output from this.call dispatch
```

### Evidence in ~/config/log.env

The file contains test artifacts that should never be persisted:

```bash
export declare LOG_DEVICE="/tmp/test.log.device.44933"   # test artifact
export declare LOG_LEVEL="3"                              # may be 5 after test.log runs
export declare LOG_LEVEL_RESET="1"
export declare LOG_LIVE="/tmp/test.log.live.44933"        # test artifact
declare -- ORIGINAL_LOG_DEVICE="/dev/stdout"              # test internal
declare -- TEST_LOG_DEVICE="/tmp/test.log.device.44933"   # test internal
declare -- TEST_LOG_LIVE="/tmp/test.log.live.44933"       # test internal
```

### Scripts that hardcode LOG_LEVEL

| Location | Code | Risk |
|----------|------|------|
| `test/test.log:175` | `export LOG_LEVEL=5` | Needed to test `debug.log` — can leak via `config.save` |
| `test/test.log:191` | `export LOG_LEVEL=4` | Same |
| `test/test.debug:94` | `export LOG_LEVEL=5` | Needed to test `toggleDebug` — same leak risk |
| `test/test.debug:272` | `export LOG_LEVEL=4` | Same |
| `debug:31-32` | `if [ -z "$LOG_LEVEL" ]; then LOG_LEVEL=5` | Fallback if LOG_LEVEL is empty — silently elevates |

**"Hardcoding"** means setting `export LOG_LEVEL=N` directly rather than using the `$level` parameter passed by the test framework. The values are necessary for testing log behavior at specific levels, but the config persistence system doesn't know the elevation is temporary.

## 3. The set +x Bug in seq.puml.log

`seq.puml.log()` (`log:104-124`) is called by **every log function** as its first action:

```bash
seq.puml.log() {
  {
    if [ "$LOG_LEVEL" -gt "5" ]; then
      set -x                          # Enables bash tracing
      export PS4='...'
      ...
    else
      pumlPrefix='echo ...'
      export PS4='...'
      #put back #set +x               # BUG: commented out!
    fi
  } 2>/dev/null
}
```

### The problem

- At level > 5, `set -x` enables bash tracing — every command produces a PS4 trace line
- The `{ } 2>/dev/null` wrapper only suppresses output from commands *inside* the block
- After the block exits, `set -x` remains active and traces go to stderr (no longer suppressed)
- When LOG_LEVEL drops back (e.g., test restores level 1), the `else` branch runs but `set +x` is **commented out**
- Tracing persists indefinitely, producing a trace line for every bash command
- With deep OOSH call chains, this multiplies output by 10-50x per command

### Impact

At level 6, the PS4 format is:
```
  source.sh -> caller.sh: functionName:42   - source.sh caller.sh this log debug
```

Every single bash statement produces this trace. A simple function call that normally produces 1 line of output generates 20-50 trace lines instead.

## 4. What Hardcoding Log Levels Means

### Correct pattern — use the passed $level

```bash
# Test file receives level as $1
level=$1
log.level $level

# test.case passes level through
test.case $level "my test" myFunction arg1
```

The `test.case` function calls `log.level $level` at the start of each case (`test.suite:298`), ensuring the caller's requested level is respected.

### Hardcoded pattern — overrides the caller

```bash
export LOG_LEVEL=5    # Overrides whatever the caller requested
debug.log "testing"   # Only works because we forced level 5
export LOG_LEVEL=3    # Attempts to restore — but may be too late
```

This is necessary in test.log and test.debug because they **test the log functions themselves** — they must set specific levels to verify that `debug.log` outputs at level 5 and is silent at level 4.

### Why it causes problems

1. `export LOG_LEVEL=5` sets the level for the **entire process**
2. If any code path triggers `config.save` while level is elevated, the elevated value gets persisted to `~/config/log.env`
3. All subsequent scripts inherit the elevated level from config
4. The developer sees massive output at level 1 and doesn't know why

## 5. Proposed Fixes

### Fix 1 — Uncomment set +x in seq.puml.log

**File:** `log`, line 121

```bash
# Change:
#put back #set +x

# To:
set +x
```

This ensures bash tracing is disabled when LOG_LEVEL drops below 6. Currently, tracing persists indefinitely once enabled.

### Fix 2 — Test isolation for LOG_* variables

Save and restore all LOG_* variables around tests that change them:

```bash
# At start of test file (or in test.suite.init)
_SAVED_LOG_LEVEL="$LOG_LEVEL"
_SAVED_LOG_DEVICE="$LOG_DEVICE"
_SAVED_LOG_LIVE="$LOG_LIVE"

# ... tests that change LOG_LEVEL ...

# At end of test file (or in test.suite.save.results)
export LOG_LEVEL="$_SAVED_LOG_LEVEL"
export LOG_DEVICE="$_SAVED_LOG_DEVICE"
export LOG_LIVE="$_SAVED_LOG_LIVE"
```

### Fix 3 — Guard config.save during tests

Prevent `config.save` from persisting test state:

```bash
# In test.suite.init
export TEST_SUITE_RUNNING=1

# In config.save (or log.level)
if [ "${TEST_SUITE_RUNNING:-0}" -eq 1 ]; then
  # Skip persisting to log.env during test execution
  return 0
fi
```

### Fix 4 — Clean polluted log.env

Remove non-system variables that leaked from tests:

```bash
# Variables that should be in log.env:
LOG_LEVEL, LOG_DEVICE, LOG_LIVE, LOG_LEVEL_RESET

# Variables that should NOT be in log.env (test artifacts):
TEST_LOG_DEVICE, TEST_LOG_LIVE, ORIGINAL_LOG_DEVICE, ORIGINAL_LOG_LEVEL, ORIGINAL_LOG_LIVE
```

Manual cleanup:
```bash
export LOG_LEVEL=3
export LOG_DEVICE=/dev/tty
unset LOG_LIVE TEST_LOG_DEVICE TEST_LOG_LIVE ORIGINAL_LOG_DEVICE ORIGINAL_LOG_LEVEL ORIGINAL_LOG_LIVE
./config save log LOG
```

## 6. Debugging Guide

### When to use each level

| Level | Use when... | What you see |
|-------|------------|-------------|
| 1 | Running tests for pass/fail results | Errors and test assertions only |
| 3 | Developing — want to see script output | Console messages, success/failure |
| 4 | Debugging method dispatch | `info.log` from `this.call`: which functions resolve, which scripts load |
| 5 | Full debug trace in application logic | `debug.log` messages, `"this.call to: $*"` for every dispatch |
| 6 | Tracing exact bash execution | Every command traced with source file, function, line number |
| 7 | Interactive stepping | Execution pauses at breakpoints: `h` help, `c` continue, `q` quit |

### Running tests at different levels

```bash
./test.suite run myScript 1    # Clean — errors and assertions only
./test.suite run myScript 3    # See console.log from script under test
./test.suite run myScript 5    # Full debug — see all framework internals
./test.suite all 1             # All tests — clean output
```

### Reading PS4 trace output (level 6)

Each trace line follows this format:
```
  source.sh -> caller.sh: functionName:42   - source.sh caller.sh this log debug
  ^source     ^caller      ^function ^line    ^full BASH_SOURCE stack
```

Read as: "In `source.sh`, called from `caller.sh`, function `functionName` at line 42."

The rightmost list is the full source stack (most recent first).

### Restoring after debugging

```bash
# Reset to default
export LOG_LEVEL=3
log.level 3

# Toggle to previous level
log.level reset

# Disable tracing if stuck
{ set +x; } 2>/dev/null

# Full reset (if log.env is polluted)
export LOG_LEVEL=3
export LOG_DEVICE=/dev/tty
unset LOG_LIVE
./config save log LOG
```

### The debug script's LOG_LEVEL fallback

The `debug` script (`debug:31-32`) has:
```bash
if [ -z "$LOG_LEVEL" ]; then
    LOG_LEVEL=5
fi
```

If LOG_LEVEL is ever unset (empty string), the debug script silently sets it to 5. This is a safety net to ensure debug functions work, but it can cause unexpected verbose output if LOG_LEVEL gets accidentally unset.

## See Also

- [Log System Documentation](log.md) — Function reference, live logging, capture modes
- [Debug System Documentation](debug.md) — Step debugger, breakpoints, trap handlers
- [OOSH Architecture](oosh-architecture.md) — Complete technical reference
- [Test Suite Documentation](test-suite.md) — Writing and running tests
- [Wiki Index](wiki-index.md) — All documentation links
