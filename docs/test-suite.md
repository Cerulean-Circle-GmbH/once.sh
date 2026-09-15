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