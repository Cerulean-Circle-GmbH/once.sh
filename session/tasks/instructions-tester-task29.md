# Task.29 Validation — Tester Assignment

**Priority**: HIGH — Expert just completed Steps 1-3. You validate Steps 4-6.

## What Was Implemented

Expert added `scrumMaster.measure.subscription.api` — an OOSH method that calls the Anthropic OAuth usage API to get real subscription utilization percentages.

## Full Spec

Read: `session/tasks/Task.29.202602041323.md` (Steps 4-6 are yours)

## Validation Steps

### Step 4: Test API Call with Real Credentials

```bash
# Run the new method
./scrumMaster measure.subscription.api

# Expected: utilization percentages for five_hour, seven_day, per-model
# Should output real numbers (not "4,300 tokens" — that was the old broken pane-scraping)
```

### Step 5: Test Alert Thresholds

- Verify the code checks `five_hour.utilization > 80` (warning) and `> 90` (error)
- Review the implementation to confirm threshold logic exists
- If possible, test with mock values

### Step 6: Test Error Handling

```bash
# Test graceful fallback scenarios:
# 1. What happens with invalid/expired token?
# 2. What happens if API returns malformed JSON?
# 3. What happens if Keychain entry doesn't exist?
```

## Additional Checks

- [ ] Tab completion works for `measure.subscription.api`
- [ ] Private methods are hidden from completion (`private.measure.subscription.api.*`)
- [ ] Existing Task.27 methods (`measure.pane`, `measure.team`) still work
- [ ] `./scrumMaster usage` shows the new method in help text
- [ ] No syntax errors: `bash -n scrumMaster`

## When Done

Report results: PASS or FAIL with details.
