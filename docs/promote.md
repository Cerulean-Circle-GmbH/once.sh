# promote — Release Pipeline for oosh

The `promote` script implements a gated promotion pipeline (dev → testing → prod) backed by a PROMOTE state machine. It ensures code passes tests before advancing to the next branch.

## Overview

- Promotes code through stages: `dev` → `testing` → `prod`
- Each promotion is gated by automated checks (tests, clean tree, confirmations)
- Uses the oosh `state` machine framework for resumable, step-by-step advancement
- `oo` provides thin wrappers (`oo dev.to.testing`, `oo release`, etc.) that delegate to `promote`

## Where the merge happens — each stage in its own folder

Since the clone layout ([oo.md § The clone layout](oo.md#the-clone-layout); ogit plan, Task 24) every stage is its own folder under the components base: `<base>/dev`, `<base>/testing`, `<base>/prod`. `promote` merges, tags and pushes **inside the target stage's folder** (found with `ogit worktree.find <target>`, which also finds a linked worktree on hosts not yet migrated). The folder you work in (`$OOSH_DIR`, e.g. `dev`) is never checked out to another branch.

For each merge (`private.promote.merge.into.folder <source> <target>`):

1. push `<source>` to origin (from `<source>`'s folder when one exists) — fails fast if origin has diverged;
2. in `<base>/<target>`: stash local changes, `fetch`, fast-forward `<target>` to `origin/<target>` — a target that has **diverged** from origin is refused and left untouched;
3. merge `origin/<source>` as the promote bot (`oosh-promote@local` / `oosh promote`), rewrite `OOSH_SELF_BRANCH` there (auto-resolving the known `OOSH_SELF_BRANCH` drift conflict, else abort), pop the stash.

`testing.tagged` / `prod.tagged` tag in that folder, `testing.pushed` / `prod.pushed` push the branch and tags from it.

**Prerequisite:** the target folder must exist. A host without one (e.g. no `testing/`) is refused at the merge state with

```
no folder holds branch testing — run: oo checkout testing
```

Run `oo checkout testing` once, then re-run `promote testing` — it resumes at the merge state.

`promote status` reads each branch from its own folder (falling back to `$OOSH_DIR`); `promote branch.alignment <from> <to>` compares in `<to>`'s folder, where a clone knows `<from>` as `origin/<from>` (as of its last fetch).

## Quick Start

```bash
# Promote dev to testing (gated by core tests)
promote testing

# Skip confirmations
promote testing yes

# Promote testing to prod (gated by platform tests)
promote prod

# Skip a stuck state (e.g., you already ran tests manually)
promote testing skip

# Show pipeline state and branch diffs
promote status

# Show promotion history from git tags
promote report
```

## Public Methods

| Method | Parameters | Description |
|--------|-----------|-------------|
| `promote testing` | `<?reset\|yes\|skip>` | Promote dev → testing, gated by core tests |
| `promote prod` | `<?reset\|yes\|skip>` | Promote testing → prod, gated by platform tests |
| `promote status` | | Show PROMOTE machine state and branch diffs |
| `promote report` | | Show promotion history from git tags |
| `promote branch.alignment` | `<from> <to>` | Symmetric branch comparison; `$RESULT` is set to one of four verdicts described below. Used by `promote status`. |

### Branch alignment verdicts

`promote.branch.alignment <from> <to>` describes `<to>`'s relationship to `<from>` from the promote-pipeline's perspective (where `<to>` is one stage downstream of `<from>` — e.g. `<from>=dev`, `<to>=testing`). The four verdicts:

- **`up to date with <from>`** — Identical commit. `<to>` is the same tip as `<from>`. Rare; typically only right after a fresh clone or reset.
- **`<from> merged in`** — `<to>`'s history fully contains `<from>` plus `<to>`-only bookkeeping (the merge commit + `OOSH_SELF_BRANCH` rewrite that `oo stage <from>` writes onto `<to>`). The post-promote steady state. The number of bookkeeping commits isn't actionable; the timestamp on the `<to>` line tells you when the merge happened.
- **`N commits behind <from>`** — `<from>` advanced past `<to>`'s last merge point, and `<to>` has no own-side commits. `oo stage <from>` will pull the N commits in cleanly.
- **`diverged: N behind <from>`** — Same as "N behind" but `<to>` also has its own bookkeeping commits from prior promotes (the merge commit + rewrites from a previous `oo stage <from>`). This is **not** a manual-reconciliation alarm in the OOSH promote workflow — it's the normal state between two consecutive promotes. `oo stage <from>` resolves it by merging the new `<from>` work in, after which the verdict flips to `<from> merged in`. The ahead-count is bookkeeping and intentionally omitted; only the behind-count (how far `<to>` needs to catch up) is shown.

### Status output

`promote status` prints, regardless of `LOG_LEVEL`:

```
Promoting to: <target>
Current state: [N] = <state name>
Next check: [N+1] = <next state name>

=============
Branch Status
=============
dev    <sha>  <timestamp>
testing  <sha>  <timestamp>  (<verdict-vs-dev>)
prod   <sha>  <timestamp>  (<verdict-vs-testing>)
```

The `Promoting to:` / `Current state:` / `Next check:` header is present only when a PROMOTE machine exists (i.e. some `oo stage` has been started or is in progress). When no machine is active, those three lines are replaced by a single notice: `IMPORTANT> No active promotion — run 'promote testing' or 'promote prod' to start` (only visible at `LOG_LEVEL >= 2`).

The Branch Status block is always shown, regardless of LOG_LEVEL — it's the command's primary answer. Each branch's verdict suffix is one of the four [branch alignment verdicts](#branch-alignment-verdicts) above.

### Parameters

- `reset` — Delete and reinitialize the PROMOTE state machine (fresh start)
- `yes` — Set `PROMOTE_FORCE=yes` to skip interactive confirmations
- `skip` — Skip the current pending check and advance to the next state (also sets `PROMOTE_FORCE=yes`)

## State Machine

The PROMOTE state machine has two promotion paths that share a common entry and exit:

```
[11] promote.started         ← PROMOTE_TARGET set (testing or prod)
[12] target.checked          ← Branches to testing or prod path

Testing path (dev → testing):
  [13] uncommitted.checked   ← Clean working tree required
  [14] test.suite.passed     ← test.suite core 1 must pass
  [15] confirmation.received ← User confirms merge (diff stats shown)
  [16] merged.to.testing     ← merge origin/dev into testing, in <base>/testing
  [17] testing.tagged        ← Tag: testing-YYYY-MM-DD (in <base>/testing)
  [18] testing.pushed        ← push testing + tags from <base>/testing

Prod path (testing → prod):
  [20] prod.path.started        ← Pass-through entry to the prod path
  [21] uncommitted.checked.prod ← Clean working tree required
  [22] test.suite.passed.prod   ← test.suite core 1 must pass
  [23..N] platform.test.<name>  ← One state per must-pass platform from
                                  defaults/platforms.env (data-driven via
                                  private.os.platform.names + .parse). A
                                  failing platform stops the machine at
                                  that state; re-running `oo stage testing`
                                  re-runs only that platform.
  [N+1] confirmation.received.prod ← User confirms merge testing → prod
  [N+2] merged.to.prod          ← merge origin/testing into prod, in
                                  <base>/prod (with auto-resolve for
                                  OOSH_SELF_BRANCH drift on init/oosh +
                                  Install oosh.command)
  [N+3] prod.tagged             ← Tag: vX.Y.Z (auto-incremented semver, in <base>/prod)
  [N+4] prod.pushed             ← push prod + tags from <base>/prod

[99] finished
```

> *The exact number of states in the prod path depends on how many
> must-pass platforms are configured in `defaults/platforms.env`.
> `PROMOTE_PROD_LAST_STATE` is persisted by
> `private.promote.state.machine.init` and used by the resume-window
> check in `promote.testing.to.prod` to adapt to platform count without
> code edits. The per-platform check functions
> (`private.check.platform.test.<name>`) are generated at machine-init
> time via `this.function.partial` and re-sourced at the top of `promote`
> so they're in scope whenever the script is loaded.*

### Resumability

If a check fails (e.g., tests fail at state [14]), the machine stays at that state. Re-running `promote testing` resumes from the failing step — no need to re-run checks that already passed.

```bash
# First run — core tests fail:
promote testing
# ✓ [13] uncommitted.checked
# ✗ [14] test.suite.passed — fix the failing test

# Fix the test, run again — resumes at [14]:
promote testing
# ✓ [14] test.suite.passed
# ✓ [15] confirmation.received
# ... continues to completion
```

### Skipping a Stuck State

If a check fails and you want to bypass it (e.g., you already verified tests pass manually):

    promote testing skip

This advances past the current pending state without running its check function.
It also sets `PROMOTE_FORCE=yes` to auto-confirm remaining prompts.

## Gating Rules

| Promotion | Gate | Command |
|-----------|------|---------|
| dev → testing | Core test suite | `test.suite core 1` |
| dev → testing | Clean working tree | `git status --porcelain` |
| testing → prod | Platform install tests | `os platform.test.all` |

## Configuration

| File | Purpose |
|------|---------|
| `$CONFIG_PATH/stateMachines/PROMOTE.states.env` | State machine state array |
| `$CONFIG_PATH/stateMachines/PROMOTE.promote.env` | Promotion config (target, force flag) |

## oo Wrapper Aliases

These `oo` methods delegate directly to `promote`:

| oo command | Equivalent |
|-----------|------------|
| `oo dev.to.testing` | `promote testing` |
| `oo testing.to.prod` | `promote prod` |
| `oo promote.status` | `promote status` |
| `oo promote.report` | `promote report` |
| `oo release` | `promote testing` (legacy alias) |

## See Also

- [Branching Strategy](branching.md) — Branch naming and promotion flow
- [OS & Platform Testing](os.md) — Platform test infrastructure used by promote
- [OO Framework](oo.md) — oo wrapper methods
- [State Machine Documentation](state.md) — State machine framework
- [Auto-Staging Pipeline Plan](plans/auto-staging-pipeline.md) — Full implementation history
