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