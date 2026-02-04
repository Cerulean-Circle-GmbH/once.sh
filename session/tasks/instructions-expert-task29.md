# Task.29 Assignment: Fix Subscription Measurement

**Priority**: HIGH — this is your next task after pushing current work.

## What to Do

Implement `scrumMaster.measure.subscription.api` — a new OOSH method that calls the OAuth usage API to get real subscription utilization percentages.

## Full Specification

Read the complete task spec: `session/tasks/Task.29.202602041323.md`

Read the API details: `session/tasks/Task.29.subscription-measurement-fix.md`

## Quick Summary

1. Add `scrumMaster.measure.subscription.api` method to the `scrumMaster` script
2. Extract OAuth token from macOS Keychain (`security find-generic-password -s 'Claude Code-credentials' -w`)
3. Call `GET https://api.anthropic.com/api/oauth/usage` with the token
4. Parse JSON response: `five_hour.utilization`, `seven_day.utilization`, per-model breakdowns
5. Alert at >80% (warning via `console.log`), >90% (error via `error.log`)
6. Store results to `~/config/metrics/subscription.<timestamp>.env`
7. Private methods: `private.measure.subscription.api.auth()`, `private.measure.subscription.api.parse()`
8. Tab completion for `measure.subscription.api`
9. Graceful fallback when Keychain unavailable or API returns errors

## OOSH Conventions

- Method naming: `scrumMaster.measure.subscription.api`
- Private prefix: `private.measure.subscription.api.*`
- Tab completion via c2
- No flags (OOSH convention) — except `--detail` for per-model breakdown if needed
- Keep existing Task.27 pane-scraping methods unchanged

## When Done

Commit with descriptive message. Then notify: "Task 29 done"
