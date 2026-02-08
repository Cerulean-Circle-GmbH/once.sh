# Expert: Task 47 — Fix ./ Prefix Permission Mismatch

**Task file**: `session/tasks/Task.47.path-prefix-permission-mismatch.md`
**Priority**: Medium — do AFTER Tasks 48 and 46

## Problem

SM runs `./hiveMind sweep` but settings.json allows `hiveMind sweep` (no `./`). The `./` prefix doesn't match, triggering permission prompts.

## Pick the OOSH-first Option

The spec offers three options. Evaluate which follows OOSH first principles (DRY, self-explaining):

- **Option A**: Remove `./` from SKILL.md and instructions — use PATH-style
- **Option B**: Add both `./hiveMind*` and `hiveMind*` patterns to settings.json
- **Option C**: Ensure `$OOSH_DIR` is in PATH so both forms work

Choose the simplest option that eliminates the mismatch without breaking anything.

## Acceptance Criteria
- [ ] `./hiveMind sweep` and `hiveMind sweep` both match settings.json permissions
- [ ] SM sweep loop runs without permission prompts for known commands
- [ ] No regression on other agent permission patterns
- [ ] Check `.claude/settings.json` and `.claude/settings.local.json` for the fix

## When Done
Commit and report: `Task 47 done`
