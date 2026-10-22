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
2. in `<base>/<target>`: stash local changes (staged or not — `ogit.status.check`), `fetch`, fast-forward `<target>` to `origin/<target>` — a target that has **diverged** from origin is refused and left untouched;
3. merge `origin/<source>` as the promote bot (`oosh-promote@local` / `oosh promote`), rewrite `OOSH_SELF_BRANCH` there (auto-resolving the known `OOSH_SELF_BRANCH` drift conflict, else abort), pop the stash. The rewrite sets **every** `OOSH_SELF_BRANCH="${OOSH_SELF_BRANCH:-…}"` default line of `init/oosh` and `Install oosh.command` (identical duplicates through `replace lines`); a file that keeps another default stops the step with rc 1 — `Merged … but the OOSH_SELF_BRANCH default could not be set to <branch> in: <file>` — instead of shipping it (T-PROMOTE-SELF-BRANCH-EVERY-LINE, -STOPS). Every way out — success, refusal or abort — pops it through `private.promote.merge.finish`; a pop that fails (the merge changed the same lines) leaves conflict markers in the folder and keeps the change in the stash: the step warns and answers **rc 1** — the merge itself is done and `RESULT` says so — so the state machine stops there, and `RESULT` ends with `Resolve the conflicts in <base>/<target>, then run: ogit stash.drop <base>/<target> — and promote again` (never `stash.pop` again: it would re-apply the same change). A plain `promote` then resumes at the merge step, which is already up to date and stashes and pops the resolved change around it (T-PROMOTE-STASH-POP-FAILS).

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

# Promote without running the tests (core and platforms) — e.g. fixes already
# tested on their topic branch; also: oo stage dev notests, oo dev.to.testing notests
promote testing notests
promote prod notests

# Show pipeline state and branch diffs
promote status

# Show promotion history from git tags
promote report
```

## Public Methods

| Method | Parameters | Description |
|--------|-----------|-------------|
| `promote testing` | `<?reset\|yes\|skip\|notests>` | Promote dev → testing, gated by core tests |
| `promote prod` | `<?reset\|yes\|skip\|notests>` | Promote testing → prod, gated by platform tests |
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
- `notests` — Pass over every test step of this run: `test.suite core 1` and each `os platform.test <platform>` answer `skipped (notests): …` and the run goes on. Merge, `OOSH_SELF_BRANCH` rewrite, tags, push and the y/N question stay. Like `yes` and `skip` it holds for **one run** (`PROMOTE_NOTESTS` in `PROMOTE.promote.env`, cleared by the next run without it). Run it again to resume a stopped run without tests. The words of a run are set in one place, `private.promote.argument.apply`; the test steps ask `private.promote.notests.gate` (T-PROMOTE-NOTESTS). The word is exported: the checks run in a child of the run (`promote` → `state next` → `test.suite core 1`), which sees it; a process outside the run does not, whatever `PROMOTE.promote.env` still holds.

## State Machine

The PROMOTE state machine has two promotion paths that share a common entry and exit:

```
[11] promote.started         ← PROMOTE_TARGET set (testing or prod)
[12] target.checked          ← Branches to testing or prod path

Testing path (dev → testing):
  [13] uncommitted.checked   ← Clean working tree required
  [14] test.suite.passed     ← test.suite core 1 must pass
  [15] confirmation.received ← User confirms merge; the commits listed first come
                               from dev's folder: dev against its fetched
                               origin/testing ("nothing to merge" when none)
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
  [N+1] confirmation.received.prod ← User confirms merge testing → prod; the
                                  commits listed come from <base>/testing
                                  against its fetched origin/prod
  [N+2] merged.to.prod          ← merge origin/testing into prod, in
                                  <base>/prod (with auto-resolve for
                                  OOSH_SELF_BRANCH drift on init/oosh +
                                  os.specific/macos/Install oosh.command)
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

<!-- BEGIN generated: oosh method matrix (oosh-architect) -->
## `promote` — method matrix (origin/dev ↔ origin/test/mcdonges.latest)

Generated by oosh-architect from the branch sources (2026-10-20). Indexes: [methods-index.md](methods-index.md) · [object-verb-index.md](object-verb-index.md) · [parameter.md](parameter.md).

**Decomposition** — every method is `promote.<object>.<verb>[.<more.words>]`. One method = one row.
`object`/`verb` are left **blank when unchanged from the row above** (objects are never repeated).
The **script name is the root object** — `odocker` acts on `container`, `image`, `volume` … so a method is
an object CHAIN ending in a verb: **`object.object.verb`**. The object column shows the full chain.
The **verb is identified semantically** (a real action word), not by position; OOSH's normalized form puts
the **verb last** (e.g. `authorized.keys.update`), so segments before it are the object, after it `more.words`.
An **adverbial modifier** directly before the verb belongs to the verb, not the object —
`otmux.window.aggressive.resize` is object `otmux.window` + verb `aggressive.resize`.
An **empty verb** means the name carries **no action at all** — the chain never reaches a verb
(an `object.verb` naming gap, listed in [verb-audit.md](verb-audit.md)).

| object | verb | more.words | all parameter | origin/test/mcdonges.latest | origin/dev |
|---|---|---|---|---|---|
| **=== public ===** | | | | | |
| `promote` | `report` |  | `# # show promotion history from git tags` |  | `promote.report` |
| `promote.branch.alignment` |  |  | `# <from> <to> # symmetric branch comparison; sets RESULT to one of: up to date with <from>, <from> merged in, N commits behind <from>, diverged: N behind <from>` |  | `promote.branch.alignment` |
| `promote.dev.to.testing` |  |  | `# <?reset> # promote dev to testing, gated by core tests; reset, yes, skip or notests (no tests)` |  | `promote.dev.to.testing` |
| `promote.prod` |  |  | `# <?reset> # [deprecated: use promote testing.to.prod] promote testing to prod; reset, yes, skip or notests` |  | `promote.prod` |
| `promote.status` |  |  | `# # show PROMOTE pipeline state and branch diffs` |  | `promote.status` |
| `promote.testing` |  |  | `# <?reset> # [deprecated: use promote dev.to.testing] promote dev to testing; reset, yes, skip or notests` |  | `promote.testing` |
| `promote.testing.to.prod` |  |  | `# <?reset> # promote testing to prod, gated by platform tests; reset, yes, skip or notests (no tests)` |  | `promote.testing.to.prod` |
| **=== private ===** | | | | | |
| `promote` | `check` | `confirmation.received` | `# <script> <stageTo> <stateFound> # confirm merge dev to testing` |  | `private.check.confirmation.received` |
|  |  | `confirmation.received.prod` | `# <script> <stageTo> <stateFound> # confirm merge testing to prod` |  | `private.check.confirmation.received.prod` |
|  |  | `finished` | `# <script> <stageTo> <stateFound> # terminal state` |  | `private.check.finished` |
|  |  | `initialization.checked` | `# <script> <stageTo> <stateFound> # verify PROMOTE_TARGET is set` |  | `private.check.initialization.checked` |
|  |  | `merged.to.prod` | `# <script> <stageTo> <stateFound> # merge testing into prod` |  | `private.check.merged.to.prod` |
|  |  | `merged.to.testing` | `# <script> <stageTo> <stateFound> # merge dev into testing` |  | `private.check.merged.to.testing` |
|  |  | `prod.path.started` | `# <script> <stageTo> <stateFound> # pass-through to platform tests` |  | `private.check.prod.path.started` |
|  |  | `prod.pushed` | `# <script> <stageTo> <stateFound> # push prod and tags from prod's own folder` |  | `private.check.prod.pushed` |
|  |  | `prod.tagged` | `# <script> <stageTo> <stateFound> # tag prod with semver` |  | `private.check.prod.tagged` |
|  |  | `target.checked` | `# <script> <stageTo> <stateFound> # branch to testing or prod path` |  | `private.check.target.checked` |
|  |  | `testing.pushed` | `# <script> <stageTo> <stateFound> # push testing and tags from testing's own folder` |  | `private.check.testing.pushed` |
|  |  | `testing.tagged` | `# <script> <stageTo> <stateFound> # tag testing with date` |  | `private.check.testing.tagged` |
|  |  | `uncommitted.checked` | `# <script> <stageTo> <stateFound> # verify clean working tree` |  | `private.check.uncommitted.checked` |
|  |  | `uncommitted.checked.prod` | `private.check.uncommitted.checked "$@"; }` |  | `private.check.uncommitted.checked.prod` |
|  | `merge` | `into.folder` | `# <source> <target> # push <source>; in <target>'s own folder: fetch, fast-forward <target> to origin/<target>, merge origin/<source> as the promote bot, rewrite OOSH_SELF_BRANCH there; RESULT tells #` |  | `private.promote.merge.into.folder` |
| `promote.argument` | `apply` |  | `# <?word:reset\|yes\|skip\|notests> # set the words of this one promote run and save them: reset starts a new PROMOTE machine, yes answers the questions, skip passes over the stuck state, notests passes over every test step; no word = a plain resume #` |  | `private.promote.argument.apply` |
| `promote.check` | `next` | `custom.state` | `# <script> <stageTo> <stateFound> # placeholder pass-through` |  | `private.check.next.custom.state` |
|  | `test` | `suite.passed` | `# <script> <stageTo> <stateFound> # run test.suite core 1` |  | `private.check.test.suite.passed` |
|  |  | `suite.passed.prod` | `private.check.test.suite.passed "$@"; }` |  | `private.check.test.suite.passed.prod` |
| `promote.check.platform.test` | `dispatch` |  |  |  | `private.check.platform.test.dispatch` |
| `promote.config` | `load` |  |  |  | `private.promote.config.load` |
|  | `save` |  |  |  | `private.promote.config.save` |
| `promote.merge` | `finish` |  | `# <rc> <message> <stashed> <dir> # every way out of private.promote.merge.into.folder: pop the pre-merge stash of <dir> when <stashed> is yes, then RESULT <rc> <message>; a pop that fails (it conflicted: markers in the tree, the stash kept) warns, answers rc 1 and puts resolve-then-ogit stash.drop into RESULT #` |  | `private.promote.merge.finish` |
| `promote.merge.preview` | `show` |  | `# <source> <target> # print the commits a merge of origin/<source> into <target> brings, from the folder that holds <source> (its fetched origin/<target>); says so when there are none #` |  | `private.promote.merge.preview.show` |
| `promote.notests.gate` |  |  | `# <what> # rc 0 with RESULT "skipped (notests): <what>" when this run was started with notests — the test step runs nothing; rc 1 otherwise #` |  | `private.promote.notests.gate` |
| `promote.platform.stubs` | `source` |  |  |  | `private.promote.platform.stubs.source` |
| `promote.push` | `source` | `branch` |  |  | `private.promote.push.source.branch` |
| `promote.rewrite.self.branch` |  |  | `# <ooshDir> # rewrite EVERY OOSH_SELF_BRANCH default line in init/oosh and os.specific/macos/Install oosh.command to the currently-checked-out branch and commit if changed; rc 1 (RESULT names the files) when one keeps another default` |  | `private.promote.rewrite.self.branch` |
| `promote.state.machine` | `init` |  |  |  | `private.promote.state.machine.init` |
| `promote.try` | `resolve` | `self.branch.conflict` |  |  | `private.promote.try.resolve.self.branch.conflict` |
<!-- END generated: oosh method matrix -->
