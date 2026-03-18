# promote — Release Pipeline for oosh

The `promote` script implements a gated promotion pipeline (dev → stage → prod) backed by a PROMOTE state machine. It ensures code passes tests before advancing to the next branch.

## Overview

- Promotes code through stages: `dev` → `stage` → `prod`
- Each promotion is gated by automated checks (tests, clean tree, confirmations)
- Uses the oosh `state` machine framework for resumable, step-by-step advancement
- `oo` provides thin wrappers (`oo dev.to.stage`, `oo release`, etc.) that delegate to `promote`

## Quick Start

```bash
# Promote dev to stage (gated by core tests)
promote stage

# Skip confirmations
promote stage yes

# Promote stage to prod (gated by platform tests)
promote prod

# Skip a stuck state (e.g., you already ran tests manually)
promote stage skip

# Show pipeline state and branch diffs
promote status

# Show promotion history from git tags
promote report
```

## Public Methods

| Method | Parameters | Description |
|--------|-----------|-------------|
| `promote stage` | `<?reset\|yes\|skip>` | Promote dev → stage, gated by core tests |
| `promote prod` | `<?reset\|yes\|skip>` | Promote stage → prod, gated by platform tests |
| `promote status` | | Show PROMOTE machine state and branch diffs |
| `promote report` | | Show promotion history from git tags |

### Parameters

- `reset` — Delete and reinitialize the PROMOTE state machine (fresh start)
- `yes` — Set `PROMOTE_FORCE=yes` to skip interactive confirmations
- `skip` — Skip the current pending check and advance to the next state (also sets `PROMOTE_FORCE=yes`)

## State Machine

The PROMOTE state machine has two promotion paths that share a common entry and exit:

```
[11] promote.started         ← PROMOTE_TARGET set (stage or prod)
[12] target.checked          ← Branches to stage or prod path

Stage path (dev → stage):
  [13] uncommitted.checked   ← Clean working tree required
  [14] test.suite.passed     ← test.suite core 1 must pass
  [15] confirmation.received ← User confirms merge (diff stats shown)
  [16] merged.to.stage       ← git merge dev into stage
  [17] stage.tagged          ← Tag: stage-YYYY-MM-DD
  [18] stage.pushed          ← git push origin stage + tags

Prod path (stage → prod):
  [20] prod.path.started     ← Pass-through to platform tests
  [21] platform.tests.passed ← os platform.test.all must pass
  [22] confirmation.received.prod ← User confirms merge
  [23] merged.to.prod        ← git merge stage into prod
  [24] prod.tagged           ← Tag: vX.Y.Z (auto-incremented semver)
  [25] prod.pushed           ← git push origin prod + tags

[99] finished
```

### Resumability

If a check fails (e.g., tests fail at state [14]), the machine stays at that state. Re-running `promote stage` resumes from the failing step — no need to re-run checks that already passed.

```bash
# First run — core tests fail:
promote stage
# ✓ [13] uncommitted.checked
# ✗ [14] test.suite.passed — fix the failing test

# Fix the test, run again — resumes at [14]:
promote stage
# ✓ [14] test.suite.passed
# ✓ [15] confirmation.received
# ... continues to completion
```

### Skipping a Stuck State

If a check fails and you want to bypass it (e.g., you already verified tests pass manually):

    promote stage skip

This advances past the current pending state without running its check function.
It also sets `PROMOTE_FORCE=yes` to auto-confirm remaining prompts.

## Gating Rules

| Promotion | Gate | Command |
|-----------|------|---------|
| dev → stage | Core test suite | `test.suite core 1` |
| dev → stage | Clean working tree | `git status --porcelain` |
| stage → prod | Platform install tests | `os platform.test.all` |

## Configuration

| File | Purpose |
|------|---------|
| `$CONFIG_PATH/stateMachines/PROMOTE.states.env` | State machine state array |
| `$CONFIG_PATH/stateMachines/PROMOTE.promote.env` | Promotion config (target, force flag) |

## oo Wrapper Aliases

These `oo` methods delegate directly to `promote`:

| oo command | Equivalent |
|-----------|------------|
| `oo dev.to.stage` | `promote stage` |
| `oo stage.to.prod` | `promote prod` |
| `oo promote.status` | `promote status` |
| `oo promote.report` | `promote report` |
| `oo release` | `promote stage` (legacy alias) |

## See Also

- [Branching Strategy](branching.md) — Branch naming and promotion flow
- [OS & Platform Testing](os.md) — Platform test infrastructure used by promote
- [OO Framework](oo.md) — oo wrapper methods
- [State Machine Documentation](state.md) — State machine framework
- [Auto-Staging Pipeline Plan](plans/auto-staging-pipeline.md) — Full implementation history
