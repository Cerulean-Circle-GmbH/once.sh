# Task 1: Test otmux script

## Directive
Run a comprehensive test of the `otmux` script. Validate that the key methods work correctly.

## Scope
- Expert (0.2): Run `./otmux usage` to verify help output. Test key methods: `otmux sessions`, `otmux panes`, `otmux pane.capture`, `otmux send`. Verify Tab completion works with `./c2 function.completion ./otmux`.
- Tester (0.3): Run `./test.suite run otmux 1` if a test file exists. If not, report what test coverage is missing. Validate the usability contract: does `./otmux` show usage? Does completion list methods?

## Acceptance Criteria
1. `./otmux` with no args shows usage
2. `./otmux sessions` lists tmux sessions
3. `./otmux panes` lists panes
4. `./otmux pane.capture` works on a valid target
5. `./c2 function.completion ./otmux` lists methods
6. Test suite results reported (pass/fail)

## Assigned
- Expert: Explore and validate methods
- Tester: Run test suite, validate usability contract
