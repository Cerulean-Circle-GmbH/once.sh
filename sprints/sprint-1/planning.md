# Sprint 1 Planning

## Overview
This sprint focuses on improving the completion systems for both `mycmd` and `c2`, ensuring all possible completion cases are covered and tested.

## Goals
- Achieve robust, context-aware, and user-friendly completions for both commands.
- Use a test-driven approach: write or update tests before implementing changes.
- Ensure all improvements are non-interactive and suitable for automated testing.

## Tasks
- [Task 1: c2 Completion Improvement](task-1.c2.md) (Tasks 8-15)
- [Task 2: mycmd Completion Improvement](task-2.mycmd.md) (Tasks 16-22)

## Test-Driven Methodology
- For each improvement, add or update a test case.
- Run the relevant test script (`test/test.mycmd` or `test/test.c2`) after each change.
- Use timeouts and non-interactive patterns to avoid manual intervention.

## Mitigation for Interactive Hangs
- Use the `timeout` command or similar to prevent endless waits in test scripts.
- Refactor tests to provide default/mock input where needed.
- Document any remaining interactive steps and plan for their automation.