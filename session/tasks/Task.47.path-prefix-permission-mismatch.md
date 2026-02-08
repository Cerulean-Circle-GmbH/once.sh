# Task 47: Fix ./ Prefix Mismatch Causing Extra Permission Prompts

**From**: woda-writer (Ch7-Ch8 observation, via PO)
**For**: Expert (implement), Tester (validate)
**Priority**: Medium
**Status**: Open

## Problem

Scrum Master runs commands with `./` prefix:
```bash
./hiveMind sweep
./scrumMaster measure.subscription.api
```

But `settings.json` permissions are registered without `./`:
```json
"allow": ["hiveMind sweep", "scrumMaster measure.subscription.api"]
```

This mismatch means `./hiveMind sweep` doesn't match the allowed pattern `hiveMind sweep`, triggering a permission prompt every time.

## Fix

Either:
- **Option A**: SM SKILL.md and all agent instructions use PATH-style (no `./` prefix) — requires hiveMind/scrumMaster to be in PATH
- **Option B**: `settings.json` permissions include both `./hiveMind*` and `hiveMind*` patterns
- **Option C**: OOSH bootstrap adds `$OOSH_DIR` to PATH so both forms resolve identically

Pick the option that follows OOSH first principles (DRY, self-explaining).

## Acceptance Criteria

- [ ] `./hiveMind sweep` and `hiveMind sweep` both match settings.json permissions
- [ ] SM sweep loop runs without permission prompts for known commands
- [ ] No regression on other agent permission patterns
