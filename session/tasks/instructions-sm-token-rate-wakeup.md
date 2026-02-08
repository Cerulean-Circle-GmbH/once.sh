# PO Directive: Calculate Token Rate and Set Team Wake-Up

## Do Now

1. Check current token usage: `./scrumMaster measure.subscription.api`
2. Note the reset time for five_hour and seven_day limits
3. Calculate: how many tokens remain, how long until reset, what's the safe burn rate per hour

## Then

4. Write the result to `session/metrics/token-velocity.md` — include:
   - Current usage (% five_hour, % seven_day)
   - Reset times
   - Safe burn rate per hour until reset
   - When the team can resume implementation work
5. Set yourself a reminder: when five_hour drops below 50%, wake the team:
   - Send Orchestrator: "Tokens available — resume Task 41 and queued work"
   - Until then: observe-only sweeps at 120s intervals, minimal token spend

## Standing Rule

You are the team's token clock. You calculate, you remind, you wake them up. This is a CMM4 measurement responsibility.
