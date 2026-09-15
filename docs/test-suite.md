# Test Suite Documentation

## Overview
The oosh/once.sh project uses a comprehensive Bash-based test suite to ensure reliability, correctness, and safe refactoring. All test scripts are located in the `test/` directory and follow strict conventions for structure and usage.

## Structure & Conventions
- **Naming:** Test scripts are named `test.<command>` (e.g., `test.mycmd`, `test.oosh`, `test.c2`).
- **Location:** All test scripts reside in the `test/` directory.
- **Sourcing:** Each script sources `test.suite` for test utilities and result tracking, and typically sources the command under test.
- **Setup:** Logging and environment are initialized at the start of each script.

## Writing Tests
- **Test Cases:** Use `test.case` to run a function or command and capture results.
- **Assertions:** Use `expect` to assert return values and outputs. Use `expect.error` for negative tests.
- **Result Tracking:** Results are summarized for each test and the overall suite.

## Running Tests
- **Single Test:** `test.suite run <command>` (e.g., `test.suite run mycmd`)
- **All Tests:** `test.suite all`
- **Output:** Test results are summarized, showing the number of successful and expected cases, and reporting any failures.

## Example Test Script
```bash
#!/usr/bin/env bash
source test.suite $*
log.level $level

test.case - "direct call with parameter" \
  mycmd 3 f g 1 a b c
expect 0 "result not loaded" "$RESULT after a direct call"

# More test cases ...
```

## Advanced & Edge Testing
- **Shell Features:** Some tests (e.g., `test.tilde`, `test.absolute.path`) focus on shell or path behaviors.
- **Completion & Parameters:** Scripts like `test.c2` and `test.data/parameterTestScript` test completion logic and parameter parsing.
- **Error Handling:** Use `expect.error` to check for expected failures and edge cases.

### Diagnostic-rich assertions with `expect.pass` / `expect.fail`
When a test must surface an actionable recovery hint on failure
(more useful than "Expected return: 0, got: 1"), use
`expect.pass "<context>"` and `expect.fail "<reason + recovery>"`
instead of the value-comparing `expect 0 "*"` form. The framework
prints the message verbatim to the test report:

```bash
test.case - "T-USER-FIX-EXISTS: oo.user.fix is defined" \
  type oo.user.fix
if type oo.user.fix >/dev/null 2>&1; then
  expect.pass "oo.user.fix is defined"
else
  expect.fail "oo.user.fix should be defined — run \`oo update\` to re-source"
fi
```

This is the right pattern for real-environment integration tests
(e.g. `T-MODE-COMPLETION-REAL-ENV` in `test/test.oo`,
`test/test.platform.shared.oosh.invariant`) where the fail message
is the user's first signal that something needs fixing.

### Platform-category tests
Tests with `TEST_CATEGORY=platform` (e.g.
`test.platform.shared.config.invariant`,
`test.platform.shared.oosh.invariant`) verify post-install
invariants on real machines. They run inside
`os platform.test <platform> terminal` containers via
`./test.suite run <name> 1`. See
`templates/code/newPlatformInvariantTest` for the skeleton.

## Isolating a test from the shared config

`~/config` (`$CONFIG_PATH`) is normally a **site-wide `sharedConfig`** that every user sources at
login. A test that reaches a production `config save` rewrites it for everybody. If the script under
test can persist anything, isolate first:

```bash
source this
source test.suite
test.suite.config.isolate test.myscript >/dev/null || exit 1
source myscript          # <- after the isolate line
```

`test.suite.config.isolate` points `CONFIG_PATH`, `CONFIG_FILE` and `CONFIG` at a fresh `mktemp`
directory, **and touches `$CONFIG`**. All four moves are required. The touch is not tidiness:
`config.start` re-runs `config.init` whenever `$CONFIG` is not a file, and `config.init` then does an
unconditional `export CONFIG_PATH=~/config`. Setting the path alone is therefore not isolation — the
next `source $OOSH_DIR/config` silently snaps back to the shared dir while the test believes it is
safe. `isolate` refuses loudly rather than half-isolating, and `test.suite.config.restore` is
installed as an `EXIT` trap (chained onto any trap the file already had).

**Your score is unaffected.** `test.suite.init` pins the inherited `CONFIG_PATH` into
`TEST_SUITE_RESULT_PATH` *before* anything can move it, and `test.suite.save.results` always writes
there. Without that pin a file that isolated its config would write its score into its own fixture,
and the runner would report `0 / 0` for a file that really ran.

**What `CONFIG_PATH` does not cover:** `~/.gitconfig` (use `GIT_CONFIG_GLOBAL`), and `log`'s
`~/config/result.txt` / `error.txt`, which are hardcoded to `$HOME`.

## Every file scores itself

`test.suite.save.results` at the end of a test file is **mandatory**, not decorative. Test files run
as child processes (the runner invokes `$file` directly), so the only channel back to the runner is
the handoff file `testresult.env`. A file that never calls `test.suite.save.results` produces no
score of its own.

Until 2026-09-15 such a file was silently given the **previous** file's numbers, because the runner
cleared only its shell variables and left the handoff behind. `test.tilde` reporting `test.this`'s
31 assertions was the instance that exposed it. The runner now clears the handoff *before* each
file — so it exists if and only if that file wrote it — and a file that produced none is reported
`0 / 0`, named on its own line, and counted in a `No results:` summary at the end.

If you see `⚠ NO RESULTS: test.<name> produced no score of its own`, that file is not being
measured. Add `test.suite.save.results` as its last line.

## Best Practices
- Use `test.case` for each logical test scenario.
- Use `expect` to assert both return values and output.
- Source the command under test and any required dependencies.
- Keep tests isolated and repeatable.
- Document the purpose of each test at the top of the script.

## Test Coverage
The suite covers a wide range of commands and scenarios, including:
- Core utilities (e.g., `test.loop`, `test.call`, `test.line`)
- Completion and parameter parsing (`test.c2`, `test.data/parameterTestScript`)
- File system and environment (`test.fs`, `test.tilde`, `test.absolute.path`)
- Error handling and edge cases

## See Also
- [First Principles](first-principles.md)
- [Outline](outline.md)
- [completion-system.md](completion-system.md) (for completion/parameter testing)
- [command-creation.md](command-creation.md)