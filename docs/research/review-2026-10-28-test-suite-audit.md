# Test-suite audit: all 65 test files

**Status:** research — baseline report; the §9.7/§9.8 test-case fixes were applied after the run (see the note below).
**Date:** 2026-10-28
**Scope:** every file in `test/` — 30 `core`, 25 `extended`, 10 `platform` — on `dev` @ `bbd74046` (dirty tree: only the audit docs added).
**Companion:** [repo audit of 2026-10-28](review-2026-10-28-repo-audit.md).
**Method:** `./test.suite core 1` and `./test.suite extended 1` (full runs; per-file results reproduced in §8), the three tree validators (`portability.validate`, `path validate`, `ogit caller.validate`), static scans of every file (assertion counts, wildcard/`create.result` patterns, dead subjects, sleeps, source-shape greps, missing markers), and one framework negative control. The 10 `platform` files were **not executed**: they assert on a real installed machine and `test.platform.shared.idempotence.invariant` runs real `config save` / `oo user.init` / `oo update` (see §6, item 8); they are audited statically only.

**Post-audit fixes (2026-10-28, after this baseline):** the test-case bugs in §9.7–§9.8 were fixed — `test/test.claudeCode` (7 stdout-capture false failures, the 3-field registry parse, `list.named` → `list`, the hardcoded `AGENTS_BASE`) and `test/test.hiveMind` (function-body checks instead of stale line ranges, the `CYCLE_COMPLETE`/procArgs expectations, function-aware DRY scans, globals instead of `local reg=` re-derivations) — plus the four real `claudeCode` sites. Product fixes: `backup.config.repair` is portable and checks its status; `otmux.send.keys` is restored and resolves session targets; `otmux.pane.history` honours its line count; the `scrumMaster` measure API + completions are restored and the metrics dir is lazy; PDCA expects the real terminal state (`FINISHED`); `hiveMind` calls `hiveMind.agent.queue.drain`/`ossh.parameter.completion.sshConfigHost`, restores `monitor.approve`, the role-prompt prose fallback and the missing completions, and uses `otmux` for its local pane/session reads. The runner has `test.suite.skip` (counted as `Skipped:`, not a pass), fails `0/0` in `core`/`platform`, and `test.isSourced` has 2 real assertions. `test.mycmd` (10/10), `test.certificates` and `test.headless` (1/1) were repaired; `test.tt`, `test.myScript`, `test.academyScript` are `TEST_CATEGORY=legacy`.
**Final runs (2026-10-28):** **core 1342 / 1343 passed, exit 0** (the single failure is the intentional `test.test.suite` counter self-test; was 1332/1409, 77) and **extended 328 / 328 passed, 0 failed, 4 skipped, exit 0** (was 284/351, 67 counted + 7 dropped). Both gates are green. The 62 real failures listed above were closed: 55+ completion parameters, 30 c2 signatures, 46 direct `git` calls (refactored or `# ogit-exception:`), 7 `PATH` writes (`# path-exception:`), 13 old names in docs, plus the test-case/product fixes in §9. The only `No results`/`No assertions` warnings left are the deliberately dead fixtures (`test.colors`; the 8 guard-skip files). The non-test items still open are the security/config ones from the repo audit (private key, tracked `.backup.env`). §1–§3 and §8 below are the pre-fix baseline.

---

## 1. The headline numbers

| Run | Files | Test cases | Assertions | Passed | Failed | No results | Exit |
|---|---|---|---|---|---|---|---|
| `core 1` | 30 | 1313 | 1409 | 1332 | 77 (1 intentional) | 0 | 1 |
| `extended 1` | 25 | 319 | 351 | 284 | 67 counted | 9 files | 1 |
| **both** | 55 | 1632 | 1760 | 1616 | 144 counted | 9 | 1 |

Two corrections to those totals:

- **7 more failing assertions are silently dropped.** Nine extended files never call `test.suite.save.results`; six of them printed `✗ FAIL`, but the runner scores each as `0 / 0` and its failures never reach `Failed:`. The real extended failure count is **74**, not 67, and the real core+extended count is **150**, not 144.
- **`core` has 76 unintended failures**, not 77 — the 77th is `test.test.suite`'s deliberate meta-test.

Core has **no green gate**. 75 of the 76 unintended failures are merged code from `4736ac04`; the 76th is stale generated docs (`test.ossh`, old names predate the merge). None is in this branch's own work (`oo method.new`, `config`/`this`/`os`, `user`/`setup`, `odocker`).

---

## 2. Core: 6 files red (+1 intentional), and what each one proves

| File | Failed | Rule broken | Where |
|---|---|---|---|
| `test.completion.audit` | 71 | 68 parameters have no completion function; duplicate definitions; `function` keyword | `hiveMind` 38, `otmux` 11, `claudeCode` 11, `scrumMaster` 8; `scrumMaster:1039` |
| `test.c2` | 1 (30 methods) | signature not in documented form (`'`, `<a\|b>`, `[<x>...]`) — c2 cannot parse/complete them | `hiveMind` 19, `otmux` 8, `scrumMaster` 3 |
| `test.this` | 1 | 2 calls to non-existent `private.*` functions | `hiveMind:9295` (`private.hiveMind.agent.queue.drain`), `:4010`/`:4567` (`private.ossh.config.complete.hosts`) |
| `test.ogit` | 1 (48 calls) | direct `git` calls outside `ogit` | `hiveMind` 33, `scrumMaster` 14, `claudeCode` 1 |
| `test.path` | 1 (7 writes) | `PATH` written without a `# path-exception:` marker | `claudeCode` 4, `hiveMind` 3 |
| `test.ossh` | 1 (13 refs) | old method names still in the tree — **docs only** | `object-verb-index.md` 7, `ossh.md` 2, `parameter.md` 3, `user.md` 1 |
| `test.test.suite` | 1 | intentional meta-test (correct) | — |

The first five are the same story as the repo audit: the merge of `bf1ebe5a` was not brought up to the tree's rules, and the guards that enforce them are red. `test.ossh` is older doc debt (the generated tables predate the 2026-10-16 renames).

23 of 30 core files are green with real assertions, including `config` 146/146, `odocker` 171/171, `oo` 190/190, `user` 69/69.

---

## 3. Extended: 10 pass, 6 fail, 9 produce no score

| File | Assertions | Failed | Note |
|---|---|---|---|
| `test.hiveMind` | 138 | 38 | live/tmux/registry checks plus raw-`tmux` DRY scans; recorded at 115/138 on 2026-09-17 |
| `test.claudeCode` | 21 | 13 | **7 are test bugs** (`source claudeCode` prints its usage, polluting `FUNC_EXISTS`/`HAS_PANE`), 1 removed method (`list.named`), 4 style/DRY, 1 hardcoded agents path |
| `test.scrumMaster` | 13 | 6 | missing `parameter.completion.machineName`/`session`; `pdca.run` never reaches `cycle.complete` |
| `test.scrumMaster.measure` | 17 | 4 | `pane.measure` not found; metrics dir resolves at source time |
| `test.otmux` | 45 | 4 | `send.keys` missing (2), `tree` with no arg, `pane.history` count |
| `test.backup` | 38 | 2 | **real product bug** — see T10 |
| `test.academyScript` | 0 | 2 dropped | subject missing; no `save.results` |
| `test.certificates` | 0 | 1 dropped | stub, no `save.results` |
| `test.headless` | 0 | 1 dropped | stub, no `save.results` |
| `test.myScript` | 0 | 1 dropped | subject missing; no `save.results` |
| `test.mycmd` | 0 | 1 dropped | legacy expectations, no `save.results` |
| `test.tt` | 0 | 1 dropped | subject missing; no `save.results` |
| `test.colors`, `test.share`, `test.webitem` | 0 | 0 | no `save.results`, no assertions |

`test.otmux` is **not hermetic**: standalone it scores 32/45 with 13 failures; inside the suite it scores 41/45 with 4. The nine assertions that fail standalone pass in-suite only because sessions left by earlier test files make the completion checks find something. The same file gives two different verdicts depending on order.

---

## 4. Findings

Failure-by-failure causes and concrete fixes are in **§9**; this section is the classification and severity.

### T1 (High) — "tests that cannot fail" is still open, six weeks after the ticket

The defect from [`docs/plans/2026-09-14-tests-that-cannot-fail.md`](../plans/2026-09-14-tests-that-cannot-fail.md) is untouched:

- **55 `expect 0 "*"` assertions remain** (57 in the ticket) across 26 files.
- **22 of them sit in test functions that never `return $(result)`**; 19 of those end in `create.result`, so a deliberate failure is discarded:
  - `test.oo` 14 (`branchList.*`, `comp.*`, `shim.*`, `t1`, `mode.sameBranch`, `user.symlinks.ensure.collision`)
  - `test.this` 5 (`symlink.with.backup.*`)
  - `test.promote` 2, `test.call` 1
- Negative control, run in a throwaway shell:

  ```bash
  vacuous() { create.result 1 "this SHOULD be a failure"; }
  test.case - "negative control" vacuous
  # after test.case: RETURN_VALUE=0 RESULT=this SHOULD be a failure
  expect 0 "*" "wildcard assertion"      # → ✓ PASS
  ```

The framework replaces both discriminators with whatever happened, so the test passes for any behaviour. The Definition of Done in that ticket (add `return $(result)`, replace the wildcards, prove it with a negative control, add a guard) is still not fully checked.

**Applied 2026-10-28:** the 19 functions ending in `create.result` now `return $(result)`, so a deliberate failure propagates. The wildcards still ignore `RESULT`; replacing them and adding the planted-failure meta-test remains.

### T2 (High) — a core file can assert nothing and still be green

`test/test.isSourced` is `TEST_CATEGORY=core`, has **2 `test.case` and 0 `expect`**, calls `test.suite.save.results`, and reports:

```
Test Cases: 2 · Assertions: 0 · Passed: 0 · Failed: 0 · ⚠ NO TESTS RUN
```

The runner's verdict is `success == expects` → `0 == 0` → pass. The "no results" guard only catches a file that never writes the handoff, not one that writes `0/0`. This is the same class as the 2026-09-14 `test.tilde` finding, one level down.

**Applied 2026-10-28:** a `0/0` file now fails `core`/`platform`, is reported as `NO ASSERTIONS` for every category, and `test.isSourced` has 2 real assertions.

### T3 (High) — failures in "no results" files are dropped from the total

Six of the nine score-less extended files print real failures, and none of them is counted:

```
test.academyScript  2 · test.certificates 1 · test.headless 1
test.myScript 1      · test.mycmd 1        · test.tt 1
```

They also make those files un-gateable: `noResults` only fails `core`/`platform`; in `extended` it is a warning. The extended score is therefore `67 counted / 74 actual`.

**Applied 2026-10-28:** the 8 files that printed failures now call `test.suite.save.results`; the 7 failures are counted. `test.colors` is deliberately left score-less — `test.test.suite` uses it as the no-inherit fixture.

### T4 (Medium) — skips count as passes

- **51 `expect.pass` calls carry "skip"** in their message (`hiveMind` 9, `otmux` 1, `claudeCode` 3, `scrumMaster` 9, `odocker` 8, `otest` 6, `c2` 8, and 7 others). A green run does not mean those behaviours ran.
- **8 files exit 0 before any test** when their subject is absent: `matthias`, `once2023`, `pm-tools`, `symbolicLink`, `currentUser`, `fs`, `cd`, `scenario.fix`. Seven of the subjects no longer exist; `scenario.fix` needs a personal `~/.once`.
- These are green for the absence of the thing under test, which is worse than no file: the suite reports a pass it did not earn.

### T5 (Medium) — nine test files are placeholders for scripts that no longer exist

`test.matthias`, `test.once2023`, `test.pm-tools`, `test.tt`, `test.myScript`, `test.academyScript`, `test.currentUser`, `test.symbolicLink`, `test.fs` (+ `test.cd`, `test.scenario.fix` above) are placeholders: some guard and exit 0, some call a missing `*.start` and fail. `test.mycmd` is a legacy file in the same state. With the trivial files below they make up the 9 no-results files — `academyScript`, `certificates`, `colors`, `headless`, `myScript`, `mycmd`, `share`, `tt`, `webitem` — and 6 of those 9 printed a failure the runner drops. They should be deleted or moved behind `TEST_CATEGORY=legacy` with an owner, not kept in `extended`.

The remaining trivial ones — `test.share`, `test.webitem`, `test.certificates`, `test.colors`, `test.headless` — call `<script> usage` and assert `expect 0 "*"`. They prove the script parses, nothing more.

### T6 (Medium) — 30 assertions check the source text, not behaviour

`grep -q '^otmux.send.keys()'`-style assertions: `test.otmux` 26, `test.replace` 2, `test.install` 1, `test.platform` 1. They are cheap and they did catch the `send.keys` removal, but they cannot catch a broken body. `test.otmux` alone has 26 of them, 12 `sleep`s and 4 real failures, and its result changes with the session state.

### T7 (Medium) — the new-method tool cannot be used on 31 of 65 test files

`oo method.new` requires exactly one `### test.method` line in `test/test.<script>`. **31 files lack it**, including the actively changed `hiveMind`, `otmux`, `claudeCode`, `scrumMaster`, plus `test.check`, `test.state`, `test.setup`, `test.tilde`, all platform invariants and others. The branch fixed the tool to write method + test together, but the tool refuses on those files, so the rule cannot be followed there.

### T8 (Medium) — coverage gaps and non-hermetic tests

- **No test file at all** for: `agentRoom`, `context`, `disk`, `index`, `map`, `osx`, `snet`, `status` (and the `parameterTestScript` symlink). `agentRoom` (24 KB) and `context` (20 KB) are not small.
- `log.live.panes` / `panes.stop` have no test. That is why the repo audit's H1 (four deleted otmux methods still called by `log`) shipped green.
- **25 `sleep`s** in tests (`test.otmux` 12, `test.c2` 7, `test.oo` 3, `test.log` 2, the platform idempotence invariant 1; `test.odocker` stubs `sleep` out). The otmux standalone/in-suite split above is the measured symptom.
- `test.claudeCode:309` defaults `AGENTS_BASE` to `/Users/Shared/Workspaces/AI/Claude/.claude/agents`, a developer's machine path; off that machine the registry role check fails for every role (this is one of its 13 failures).

### T9 (Low) — portability and hygiene

- `portability.validate`: **0 violations, 61 advisories, 77 exceptions**. The advisories are latent (a raw `mktemp` path compared against a resolved path); the largest are `test.oo` 14, `test.test.suite` 9, `test.promote` 9, `test.config` 6, `test.install` 5.
- 24 of 65 files have no `TEST_CATEGORY` and default to `extended`; that is the bucket where the dead files accumulated.
- `test.absolute.path` repeats test-case names; harmless but makes the log harder to read.

### T10 (Low) — the suite found a real bug, and it is not gating

`test.backup` fails 2 assertions, correctly. `backup:664` uses BSD `sed -i ''` with no GNU branch:

```
sed: can't read s|BACKUP_TARGET="…"|BACKUP_TARGET="…"|: No such file or directory
SUCCESS> Repaired: …          # and it still claims success
```

`backup.config.repair` has been broken on GNU/Linux since `7998759a` (2026-03-09): it prints the corrected target, `sed` reads the replacement as a filename, and the function returns 0. `test.backup` is `extended`, so nothing gates on it. This is the audit's clearest example of "a real failure that does not count".

---

## 5. What the suite does well

- **The runner's isolation canaries work**: no core/extended file rewrote the shared config tier or the real `~/.ssh`; the per-run `TEST_SUITE_RESULT_PATH` fix means a score-less file can no longer inherit the previous file's numbers (it reports `0/0`, T3 is about the *dropped failures*, not the old phantom score).
- **`T-PRIVATE-CALLS-DEFINED` caught the merge's two dead calls** (`test.this`), exactly what a guard is for.
- **The new `oo method.new` test is the model**: a fixture `OOSH_DIR`, before/after byte comparisons, every refusal asserted **before** the first prompt, success asserting method + test + exec bit, no `.new`/`.bak` left. 190/190 in `test.oo`.
- **`test.test.suite` has real meta-tests** (intentional-failure counter, score handoff, shared-tier restore, ssh canary) — the pattern to extend to the wildcard defect.
- **`test.config` (146), `test.odocker` (171), `test.user` (69), `test.setup` (14), `test.replace` (18), `test.os` (6)** are green and substantive.
- The **portability sweep** itself (0 violations) is now a real gate with documented severities.

---

## 6. Recommendations, in order

1. **Close the 2026-09-14 ticket before adding tests**: 19 of the 22 functions now `return $(result)`; the wildcards still ignore `RESULT` — replace them with real expectations and add the planted-failure meta-test. Until then no green claim from this suite is evidence.
2. **Make `0/0` fail** — **done 2026-10-28** (core/platform fail; all categories report `NO ASSERTIONS`). The no-results gap (T3) remains: count its printed failures or fail `extended` on a score-less file.
3. **Triage the 76 core failures**: fix or explicitly waive per rule (`completion`, `c2 signature`, `ogit caller`, `path`, `private calls`, `ossh docs`). A red core that is normalized is worse than no core.
4. **Delete or quarantine the dead/placeholder test files** (T4/T5); each of the 9 scripts with no test either gets one or an explicit "not tested" marker.
5. **Give `test.otmux` its own tmux server/socket** so its verdict does not depend on leftover sessions; replace the 12 sleeps with bounded polling (`test.suite` already has the idiom).
6. **Add `### test.method` to the 31 files** so `oo method.new` works everywhere (T7).
7. **Fix `backup:664`** for GNU sed and make `success.log` conditional on `sed`'s status (T10).
8. **Do not run `test.suite all` on a working machine**: `all` includes the 10 `platform` files, and `test.platform.shared.idempotence.invariant` runs real `config save`/`oo user.init`/`oo update` (waived as a shared-tier writer). Use `core`/`extended`, and `platform test` for the invariants.
9. **Keep the suite runnable as evidence**: record per-file results (`level 2`) in CI; level 1 hides them. The two full runs here took ~8 and ~2 minutes on this host, so a per-PR gate is affordable.

---

## 7. Reproduction

```bash
# full runs
./test.suite core 1        # 30 files, 1409 assertions, 77 failed (1 intentional)
./test.suite extended 1    # 25 files, 351 assertions, 67 counted + 7 dropped, 9 no-results

# the tree validators
./test.suite portability.validate    # 0 violations, 61 advisories
./path validate                      # 7 violations: claudeCode 4, hiveMind 3
./ogit caller.validate               # 48 violations: hiveMind 33, scrumMaster 14, claudeCode 1

# the 22 wildcard assertions
grep -rn 'expect 0 "\*"' test/ | wc -l            # 55

# the negative control (subshell only — changes nothing)
LOG_LEVEL=1 bash -c '
  source ./this; source ./test.suite
  vacuous() { create.result 1 "SHOULD fail"; }
  test.case - "negative control" vacuous
  echo "RETURN_VALUE=$RETURN_VALUE"
  expect 0 "*" "wildcard assertion"; echo "expect rc=$?"'
```

## 8. Run details

### 8.1 `./test.suite core 1` — exit 1

```
  Test Files:  30
  Test Cases:  1313
  Assertions:  1409
  Passed:      1332
  Failed:      77

  ✗ 77 assertion(s) failed
```

| file | cases | assertions | passed | failed | note |
|---|---:|---:|---:|---:|---|
| `test.absolute.path` | 3 | 8 | 8 | 0 | |
| `test.c2` | 26 | 30 | 29 | 1 | 30 undocumented signatures (19 `hiveMind`, 8 `otmux`, 3 `scrumMaster`) |
| `test.call` | 12 | 12 | 12 | 0 | |
| `test.check` | 0 | 11 | 11 | 0 | direct `expect`s, no `test.case` |
| `test.completion.audit` | 74 | 75 | 4 | 71 | 68 missing completions, duplicate definitions, `function` keyword |
| `test.config` | 145 | 146 | 146 | 0 | |
| `test.debug` | 18 | 20 | 20 | 0 | |
| `test.install` | 51 | 51 | 51 | 0 | |
| `test.isSourced` | 2 | 0 | 0 | 0 | **0 assertions, still green (T2)** |
| `test.line` | 11 | 13 | 13 | 0 | |
| `test.log` | 66 | 67 | 67 | 0 | |
| `test.loop` | 9 | 9 | 9 | 0 | |
| `test.odocker` | 126 | 171 | 171 | 0 | |
| `test.ogit` | 54 | 54 | 53 | 1 | 48 direct `git` calls (33 `hiveMind`, 14 `scrumMaster`, 1 `claudeCode`) |
| `test.oo` | 188 | 190 | 190 | 0 | |
| `test.oosh` | 5 | 5 | 5 | 0 | |
| `test.os` | 6 | 6 | 6 | 0 | |
| `test.ossh` | 153 | 154 | 153 | 1 | 13 old names left in generated docs |
| `test.path` | 34 | 36 | 35 | 1 | 7 unmarked `PATH` writes (4 `claudeCode`, 3 `hiveMind`) |
| `test.platform` | 4 | 21 | 21 | 0 | |
| `test.promote` | 70 | 71 | 71 | 0 | |
| `test.replace` | 18 | 18 | 18 | 0 | |
| `test.setup` | 14 | 14 | 14 | 0 | |
| `test.ssh.config.invariant` | 6 | 6 | 6 | 0 | |
| `test.ssh.config.woda` | 3 | 3 | 3 | 0 | |
| `test.state` | 29 | 29 | 29 | 0 | |
| `test.test.suite` | 43 | 45 | 44 | 1 | intentional meta-test (correct) |
| `test.this` | 70 | 71 | 70 | 1 | 2 dead `private.*` calls (`hiveMind:9295`, `:4010`, `:4567`) |
| `test.tilde` | 4 | 4 | 4 | 0 | |
| `test.user` | 69 | 69 | 69 | 0 | |

### 8.2 `./test.suite extended 1` — exit 1

```
  Test Files:  25
  Test Cases:  319
  Assertions:  351
  Passed:      284
  Failed:      67
  No results:  9 file(s) never called test.suite.save.results:
               test.academyScript test.certificates test.colors
               test.headless test.myScript test.mycmd test.share
               test.tt test.webitem

  ✗ 67 assertion(s) failed
```

| file | cases | assertions | passed | failed | note |
|---|---:|---:|---:|---:|---|
| `test.academyScript` | 0 | 0 | 0 | 0 | subject missing; **2 printed failures dropped** (T3) |
| `test.backup` | 38 | 38 | 36 | 2 | `backup:664` BSD `sed` breaks on GNU (T10) |
| `test.cd` | 0 | 0 | 0 | 0 | skips without `once.completion.discover` |
| `test.certificates` | 0 | 0 | 0 | 0 | stub; **1 printed failure dropped** |
| `test.claudeCode` | 21 | 21 | 8 | 13 | 7 test bugs (stdout pollution), `list.named` removed, 4 DRY, hardcoded agents path — see §9.8 |
| `test.colors` | 0 | 0 | 0 | 0 | stub |
| `test.currentUser` | 0 | 0 | 0 | 0 | subject missing; skips |
| `test.fs` | 0 | 0 | 0 | 0 | subject missing; skips |
| `test.headless` | 0 | 0 | 0 | 0 | **1 printed failure dropped** |
| `test.hiveMind` | 136 | 138 | 100 | 38 | live/tmux/registry checks, raw-`tmux` DRY scans, hardcoded session `hiveMindTeam02_03_26` |
| `test.matthias` | 0 | 0 | 0 | 0 | subject missing; skips |
| `test.myScript` | 0 | 0 | 0 | 0 | subject missing; **1 printed failure dropped** |
| `test.mycmd` | 0 | 0 | 0 | 0 | legacy expectations; **1 printed failure dropped** |
| `test.once2023` | 0 | 0 | 0 | 0 | subject missing; skips |
| `test.osshLayout` | 28 | 58 | 58 | 0 | |
| `test.otest` | 21 | 21 | 21 | 0 | |
| `test.otmux` | 45 | 45 | 41 | 4 | `send.keys` (2), `tree` no-arg, `pane.history` — 13 fail standalone |
| `test.pm-tools` | 0 | 0 | 0 | 0 | subject missing; skips |
| `test.scenario.fix` | 0 | 0 | 0 | 0 | skips without a personal `~/.once` |
| `test.scrumMaster` | 13 | 13 | 7 | 6 | missing completions, `pdca.run` |
| `test.scrumMaster.measure` | 17 | 17 | 13 | 4 | `pane.measure` missing, metrics dir timing |
| `test.share` | 0 | 0 | 0 | 0 | stub |
| `test.symbolicLink` | 0 | 0 | 0 | 0 | subject missing; skips |
| `test.tt` | 0 | 0 | 0 | 0 | subject missing; **1 printed failure dropped** |
| `test.webitem` | 0 | 0 | 0 | 0 | stub |

The 67 in the runner's summary **exclude** the 7 failures printed by the six score-less files above, which is why §1 and T3 use 74 for extended and 150 overall.

### 8.3 Tree validators

```
portability.validate  OK: 138 constructs checked, 61 advisory(s), 77 exception(s), 0 violations
path validate         INVALID: 7 violations — claudeCode:849,854,859,873; hiveMind:4181,4202,4207
ogit caller.validate  INVALID: 48 violations — hiveMind 33, scrumMaster 14, claudeCode 1
```

---

## 9. Why each red test is red — and the fix

Legend: **[code]** the product violates a rule the test enforces; **[test]** the test itself is wrong; **[docs]** generated docs are stale; **[env]** the test needs a live host/session it does not create.

| Red test | Kind | One-line fix |
|---|---|---|
| `test.c2` | code | rewrite 30 docstrings to the documented signature form |
| `test.completion.audit` | code | add 68 completions, remove duplicate definitions, drop `function` keyword |
| `test.this` | code | call the two functions by their real names |
| `test.ogit` | code | use `ogit.*` (or mark a genuine exception) |
| `test.path` | code | use config data (or mark `# path-exception:`) |
| `test.ossh` | docs | regenerate the matrix / fix 13 old-name rows |
| `test.hiveMind` | code+test+env | split static vs live, de-hardcode the session, fix raw tmux calls |
| `test.claudeCode` | **test**+code+env | 7 test bugs (stdout pollution), 1 removed method, 4 DRY, 1 path |
| `test.scrumMaster` | code | add missing completions, debug `pdca.run` |
| `test.scrumMaster.measure` | code | restore `pane.measure`, make the metrics dir lazy |
| `test.otmux` | code+test | restore `send.keys`, give the test its own tmux socket |
| `test.backup` | code | portable in-place `sed`, check its status |
| 6 score-less files | test | make them real tests with `save.results`, or delete |

### 9.1 `test.c2` — 30 signatures c2 cannot read [code]

**Why.** c2's signature parser is line-based; three forms in the merged code break it:

- **15 choice lists** inside the parameter (`<target|all>`) — c2 reads three parameters. `hiveMind.agent.approve/dismiss/option/queue.*/reject/session.probe`, `hiveMind.consistency.audit/reconcile`, `hiveMind.plan.improve`, `hiveMind.shell.reap/dry`, `hiveMind.teams.restore`, `otmux.window.rename`.
- **13 apostrophes** in the description (`# <dir>'s …`) — `line.unquote` treats it as a quote. `hiveMind.agent.unblock`, `.join`, `.team.host.set`, `.team.migrate`; `otmux.attach`, `.fit`, `.pane.size`, `.send.submit`, `.status`, `.zoom`; `scrumMaster.pulse`, `.rewind.mark`, `.rewind.unmark`.
- **2 bracket lists** (`[<x>...]`) — write `<?x...>`. `hiveMind.context.record`, `otmux.send.tui`.

**Fix.** Rewrite the docstring to the documented form (`docs/oosh-architecture.md` → "Signature Format"): no apostrophe in the description, one parameter name, choices named in the description (`<?mode:reset>  # reset | yes | skip`), `<?x...>` for a list. Prove it per script with `./c2 signature.validate <script>`, then `./test.suite run c2 1`.

### 9.2 `test.completion.audit` — 71 failures [code]

**Why.** Three rules:
- **68 parameters have no completion function** (`hiveMind` 38, `otmux` 11, `claudeCode` 11, `scrumMaster` 8). Parameterised methods must carry `<script>.<method>.completion.<param>()` or `<script>.parameter.completion.<param>()`.
- **duplicate definitions** in `scrumMaster`: `subscription.completion` (1385, 2405), `velocity.target.completion` (1997, 2493), `health.evaluate.completion` (2054, 2487), `health.check.completion` (2095, 2481). Bash keeps the last; one of each is dead.
- **`function et2s(e, a)`** at `scrumMaster:1039` — the `function` keyword is not the house form.

**Fix.** Run the audit, add one stub per listed parameter (the class-level form is fine when the values are the same for every method), delete the first copy of each duplicate pair, change `function et2s(e, a)` to `et2s()` (declare `local e=$1 a=$2`). Verify: `./test.suite run completion.audit 1`.

### 9.3 `test.this` — 2 dead private calls [code]

**Why.** The merge renamed/never had the targets:
- `hiveMind:9295` calls `private.hiveMind.agent.queue.drain`; the function is `hiveMind.agent.queue.drain` (`hiveMind:8877`). Effect: queued messages never drain on idle.
- `hiveMind:4010` and `:4567` call `private.ossh.config.complete.hosts`; it exists nowhere. The equivalent is `ossh.parameter.completion.sshConfigHost` (`ossh:2001`).

**Fix.**
```bash
# hiveMind:9295
hiveMind.agent.queue.drain "$target"
# hiveMind:4010 / :4567 — hiveMind does not source ossh, so call it as a command
"$OOSH_DIR/ossh" parameter.completion.sshConfigHost 2>/dev/null
```
Verify with `./test.suite run this 1` and a Tab on `hiveMind team.migrate <TAB>`.

### 9.4 `test.ogit` — 48 direct `git` calls [code]

**Why.** The merged tools bypass `ogit` (`hiveMind` 33, `scrumMaster` 14, `claudeCode` 1): `git -C … log`, `git rev-parse --show-toplevel`, `git grep`, `git status`. The design rule is `ogit` is the only git caller.

**Fix.** Map to the existing methods:

| direct call | use |
|---|---|
| `git rev-parse --show-toplevel` (e.g. `hiveMind:2704`, `:3338`; `scrumMaster:1941`) | `ogit.repo.root.get` |
| `git log --oneline --since=…` (`scrumMaster:1907`) | `ogit.commit.log.show` / `ogit.commit.count` |
| `git grep` | `ogit.repo.grep` |
| `git status --short` | `ogit.status.show` |
| `git pull` / `git push` on this host | `ogit.remote.pull` / `ogit.remote.push` |

`hiveMind:3909`/`:4170` are `ossh exec <host> "cd ~/oosh && git pull"` — git runs on the **remote** host, where `ogit` is not involved. Mark those `# ogit-exception: git on the remote host`. Re-check with `./ogit caller.validate` (it lists every site at `LOG_LEVEL=1`).

### 9.5 `test.path` — 7 unmarked `PATH` writes [code]

**Why.** PATH is data in `~/config/user.env`, not something a method builds. The merge writes it at:
`claudeCode:849,854,859,873` (reading/rewriting the config file and installing to `~/.local/bin`) and `hiveMind:4181,4202,4207` (Homebrew `/opt/homebrew/bin` fallbacks, including two remote `ossh exec` strings).

**Fix.** Use the config data (`config set` / `config save`, or read `$PATH` as it comes from `user.env`). For the remote `ossh exec` lines and the genuinely local Homebrew probe, mark the line or the file:
```bash
export PATH=/opt/homebrew/bin:$PATH   # path-exception: tmux is not on the default PATH on macOS
```
(`# path-exception-file: <reason>` covers a whole file.) Verify: `./path validate`.

### 9.6 `test.ossh` — 13 old names in docs [docs]

**Why.** The generated matrix is dated 2026-10-20 and predates the 2026-10-16/19 renames. The test scans the **whole tracked tree**, so the doc rows fail it:
- `docs/ossh.md:773` — deprecated `private.ossh.get.config` (row should be gone; `ossh.config.get` is the name)
- `docs/ossh.md:852` — `private.push.init.oosh` → `private.ossh.oosh.init.push`
- `docs/user.md:31` — `user.update.authorized_keys` → `user.authorized.keys.update`
- `docs/object-verb-index.md:857,1824,1826,2283,2730,2770,3213` and `docs/parameter.md:45,66,104` — the same old names inside generated indexes

**Fix.** Regenerate the matrix with the generator named in `docs/this.md` (`oosh-architect`), or hand-edit the 13 rows. The test is the checklist: `./test.suite run ossh 1`.

### 9.7 `test.hiveMind` — 38 failures [code + test + env] — **fixed**

**Why, in three groups:**
- **Static design scans (code):** raw `tmux` subcommands (14 total), inline `grep`s (15), re-derivations (14), raw `has-session`/`new-session`/`list-sessions`/`split-window`/`display-message` calls. These are the same "use the wrapper" rules as `test.path`/`test.ogit`; the rewrite violates them.
- **Live environment (env):** the file hardcodes `hiveMindTeam02_03_26` (`test/test.hiveMind:1436-1458`) and reads `$CONFIG_PATH/hivemind.sessions.env`; on a host without that team the status/team/agent-count assertions cannot pass. `session size wrong: 156x53 (expected 200x50)` is the same class.
- **Missing/renamed API (code):** `hiveMind.monitor.approve`, `private.hiveMind.get.role.prompt` content, completions for `focus`/`spawn`; `teams.migrate`/`teams.restore` JSONL and fork checks assert features the rewrite does not have.

**Fix.** Split the file: deterministic static scans stay in `extended`; live checks move behind a `hiveMind live` test (or are skipped with a reason, not `expect.pass "skipped"`). Replace the hardcoded team with a fixture team the test creates and kills. Fix the raw `tmux` calls to `otmux.*` (the test names them). Restore/rename the missing methods or delete their tests. A known-failure ledger is better than a permanent 100/138.

**Applied (2026-10-28):** T-RESTORE-9/10/11 extract the function body; the completions, role-prompt prose fallback, `monitor.approve` and globals-instead-of-`local reg=` are in; local pane/session reads use `otmux`; the DRY/raw-`tmux` scans are function-aware and exclude remote `ossh` calls; the live identity/lifecycle/status/restore sections are gated behind `RUN_LIVE_TESTS=1` and count as one `test.suite.skip` each. `test.hiveMind` is **103/103, 0 failed, 4 skips**.

### 9.8 `test.claudeCode` — 13 failures [7 test bugs + 5 code + 1 env]

**Why.**
- **7 are test bugs, not missing functions.** The file runs `FUNC_EXISTS=$(bash -c 'source this; source claudeCode; type -t …')`. Sourcing `claudeCode` with no arguments prints its **usage** to stdout, so `FUNC_EXISTS` is the usage text, never `function`. The functions exist: `claudeCode.process.find`, `session.save`, `session.recover`, `session.name`, `context.check`, `session.id` all have definitions. The same pollution breaks the `HAS_PANE` numeric check for `context.jsonl` (the variable holds usage text, so `[ "$HAS_PANE" -ge 1 ]` is not a number). The `test.case` lines are also word-split: `test.case … bash -c 'source …'` reaches bash as `bash -c source this` because `test.case` expands `$testArguments` unquoted.
- **1 is real:** `claudeCode.list.named` is gone — `claudeCode.list <?nameFilter>` now does the filtering (`claudeCode:115`). Update the test or restore a one-line wrapper.
- **4 are style/DRY:** `--model)` case parsing at `claudeCode:1415`; raw `stat` at `1042, 1146, 1275, 1621, 1708, 1923, 2083` (should be `private.claudeCode.jsonl.age`); the JSONL `find` appears 3×; inline ghost detection instead of `private.otmux.pane.isGhost`.
- **1 is the path:** `AGENTS_BASE` defaults to `/Users/Shared/Workspaces/AI/Claude/.claude/agents` (`test/test.claudeCode:309`), which does not exist here, so the registry role check reports an orphan.

**Fix.**
```bash
# the 7: silence the source (and stop passing a quoted script through test.case)
FUNC_EXISTS=$(bash -c 'source this; source claudeCode >/dev/null 2>&1; type -t claudeCode.process.find')
# or: type -t "$(…)" >/dev/null 2>&1 && …  (no stdout capture)
HAS_PANE=$(bash -c 'source this; source claudeCode >/dev/null 2>&1; declare -f claudeCode.context.jsonl' | grep -c pane)
```
Set `AGENTS_BASE="${CLAUDE_PROJECT_DIR:-$OOSH_DIR}/.claude/agents"` (or skip the check with a reason when the dir is absent). Update `list.named` → `list`, and fix or mark the four DRY sites. That leaves 6 real failures (5 once the path is fixed) instead of 13.

**Applied (2026-10-28):** the 7 stdout-capture checks use a `test.claudeCode.fnExists` helper that silences the sourced script; the registry reader takes the third (`timestamp`) field; `list.named` checks `claudeCode.list`; `AGENTS_BASE` defaults to `$OOSH_DIR/.claude/agents`. The four code sites are fixed too: `agent.start` takes positional args, `stat` lives in `private.claudeCode.file.mtime.get`/`.human.get`, `find *.jsonl` lives in `private.claudeCode.jsonl.files.list`, and the ghost check targets `private.otmux.composer.read`/`otmux.composer.state`. Result: **21/21**. The stale test also expected `private.claudeCode.jsonl.age`/`private.otmux.pane.isGhost`, neither of which ever existed on this branch.

### 9.9 `test.scrumMaster` — 6 failures [code]

**Why.** Four assertions ask for completions that do not exist (`parameter.completion.machineName`, `parameter.completion.session`, `pane.measure` `agentName`, `team.measure` `session`). Two run `scrumMaster.pdca.run` and expect state `CYCLE_COMPLETE`; it returns 1 after the loop (the `pdca.next`/`reset` tests pass, so the state machine's loop is the suspect).

**Applied 2026-10-28:** the four completions were restored, and the real terminal success state is `FINISHED` — `CYCLE_COMPLETE` never existed in the state machine, so T5/T6 were stale. `test.scrumMaster` is 13/13.

### 9.10 `test.scrumMaster.measure` — 4 failures [code]

**Why.** `scrumMaster.pane.measure` does not exist (T14 fails). `scrumMaster:14` assigns `SCRUMMASTER_METRICS_DIR` at **file scope** (it runs `git rev-parse` when the script is sourced), so the test's fixture value assigned after sourcing is ignored — two path assertions then read the real tree.

**Applied 2026-10-28:** `pane.measure`/`team.measure` and their completions were restored; file scope is now `: ${SCRUMMASTER_METRICS_DIR:=}` and `private.scrumMaster.metrics.dir.get` resolves lazily. `test.scrumMaster.measure` is 17/17.

### 9.11 `test.otmux` — 4 in-suite, 13 standalone [code + test]

**Why.** `otmux.send.keys` existed at `8da4ec9d:2224` as a one-liner over `otmux.send` and was deleted by the rewrite; `test/test.otmux:559` and `docs/otmux.md:47` still require it (2 failures). `tree` with no arg expects multiple sessions; `pane.history` expects a line-count relation — both depend on leftover sessions/timing, which is why 9 more fail standalone (32/45) than in-suite (41/45).

**Applied 2026-10-28:** `otmux.send.keys` is restored and resolves a session name to its active pane before `otmux.send`; `otmux.pane.history` caps output at `<lines>` (so the parameter is a limit, not a start); the count test waits for the last echoed line, and the `send.key` tests read 30 lines. `test.otmux` is 45/45.

### 9.12 `test.backup` — 2 failures [code]

**Why.** `backup:664` is BSD-only:
```bash
sed -i '' "s|BACKUP_TARGET=\"$old\"|…|" "$configPath"
```
GNU sed treats `''` as the script and the expression as a filename: `can't read s|…|: No such file or directory`. The function then prints `SUCCESS> Repaired` and returns 0, so the config is silently wrong.

**Fix.** Use a portable helper (a GNU/BSD branch, or the tree's own file-rewrite primitive), and only `success.log` when the write returns 0:
```bash
if sed --version >/dev/null 2>&1; then sed -i "s|…|…|" "$f"
else sed -i '' "s|…|…|" "$f"; fi || { error.log "…"; return 1; }
```
`test.backup` is the negative control that proves it works on Linux; run `./test.suite run backup 1`.

### 9.13 The 7 dropped failures [test]

**Why.** `test.academyScript` (2), `test.certificates` (1), `test.headless` (1), `test.myScript` (1), `test.mycmd` (1), `test.tt` (1) print `✗ FAIL` but never call `test.suite.save.results`, so the runner reports `0 / 0` and drops them (`academyScript`, `myScript`, `tt` also call subjects that no longer exist).

**Fix.** Either make them real tests (source the correct script, add `test.suite.save.results`) or delete them with their subjects. Do not keep a file that can fail without counting.

**Applied 2026-10-28:** the 8 files that printed failures call `test.suite.save.results` (the 7 are counted); `test.colors` stays score-less as the meta-test's no-inherit fixture. `test.mycmd` (10/10), `test.certificates` and `test.headless` (1/1) were repaired; `test.tt`, `test.myScript` and `test.academyScript` — all subjects gone — are `TEST_CATEGORY=legacy`.

### 9.14 Harness-level failures [harness]

These are not file-specific and must be fixed first, because every "green" above them is suspect:

- **22 wildcard assertions in functions without `return $(result)`** (T1). **Applied 2026-10-28:** the 19 that end in `create.result` now `return $(result)`, so a deliberate failure propagates; the wildcard still ignores `RESULT`, but the return code is real. The other 3 (`promote.status`, `promote.report`, `test.call.recall`) check command return codes and were never vacuous.
- **`0/0` passes** (T2). **Applied 2026-10-28:** a file that saves `0/0` fails `core`/`platform`, is reported as `NO ASSERTIONS` for every category, and `test.isSourced` now has 2 real assertions. The 8 extended guard-skip files (`cd`, `currentUser`, `fs`, `matthias`, `once2023`, `pm-tools`, `scenario.fix`, `symbolicLink`) are now visible in the summary.
- **No-results files drop their failures** (T3). **Still open:** 9 files, 7 printed failures not counted in `Failed:`.
- **Skips are passes** (T4). **Still open:** 51 `expect.pass "skipped …"` and 8 early-exit files; add a real `test.suite.skip` counter so the summary states what did not run.

After those three runner changes, the effective totals in §1 and the per-file verdicts in §8 become trustworthy without manual correction.
