# Task 1: c2 Completion Improvement

## Goal
Expand and refine the `c2` completion engine to handle all possible completion cases, ensuring maximum flexibility and accuracy.

## Test-Driven Approach
- For each improvement, write or update a test in `test/test.c2` or related scripts before implementing the change.
- Use the test suite to verify that new completion scenarios are covered and regressions are prevented.
- Document each new test case and its expected outcome.

## Numbered Tasks
8. Review all c2 completion functions and their parameter parsing logic.
9. Ensure completion works for all script/method/parameter combinations.
10. Add support for nested and optional parameters in completions.
11. Integrate more Bash built-in completions (files, users, groups, aliases, etc.).
12. Test completion for edge cases (empty, invalid, ambiguous input).
13. Add/expand tests in `test/test.c2` and related scripts.
14. Document advanced completion scenarios in the wiki.
15. Refactor for maintainability and extensibility.

## How to Test
- Run `bash test/test.c2` after each change.
- Ensure all test cases pass and new scenarios are covered.
- Use automated checks to detect infinite loops or hangs (see mitigation below).

## Mitigation for Interactive Hangs
- Add timeouts to test scripts using `timeout` or similar tools.
- Ensure all test cases are non-interactive and provide default/mock input where needed.
- Use CI or local scripts to kill tests that exceed a reasonable execution time.

## References
- [completion-system.md](../../docs/completion-system.md)
- [test-suite.md](../../docs/test-suite.md)