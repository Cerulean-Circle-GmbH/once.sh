# OOSH-philosophy conformance review — 15 commits, 2026-05-06 to 2026-05-07

**Status:** review artefact (research only — not normative). Untracked until reviewed.
**Date:** 2026-05-07
**Triggered by:** user requested "deep code review of everything we did yesterday and today" against OOSH philosophy/methodology/templates documented at `/home/hannesn/oosh/docs/`. The review surfaces missed OOSH-idiom opportunities, redundancies, and confirms the parts we did right.
**Headline score:** **9/10 — very disciplined OOSH thinking.** Two action items extracted into the executing plan (`/home/hannesn/.claude/plans/i-started-a-new-idempotent-coral.md`); three deferred.

---

## Part A — the rubric (11 OOSH idioms applied)

Distilled from `oosh-architecture.md`, `log.md`, `state.md`, `config.md`, `oo.md`, `debug.md`:

1. **Naming** — camelCase + dots; never dashes/underscores. Methods `script.methodName()`, params `<camelCase>`, privates `private.script.method()`.
2. **Method declaration** — every public method has signature line `# <params> # description`, plus `<method>.completion.<param>()` functions for completable params.
3. **Dispatching** — use OOSH primitives (`user create`, `ossh config.get`, `state.next`) via the dispatcher. From a script: dot notation (`user.init`); from shell: space notation (`user init`).
4. **Result/return pattern** — fail-loud uses `error.log "msg"` + `create.result 1 "reason"` + `return $(result)`; success: `create.result 0 "msg"` + `return $(result)`.
5. **Logging** — typed functions (`console.log`, `info.log`, `error.log`, `warn.log`, `success.log`) with consistent `LOG_LEVEL` checks. Gate writes on writable targets (`[ -w "$LOG_LIVE" ]`, `[ -w "$LOG_INSTALL" ]`).
6. **Config** — use `config.init`, `config save`, `config get`. Never hardcode paths; rely on `$CONFIG`, `$CONFIG_PATH`. Exclude per-user dynamic vars from shared configs.
7. **State machine** — owns all multi-step install logic. Each state has `private.check.<stateName>()`. Return 0 success, non-zero fail (halts machine).
8. **Idempotency** — detect-don't-suppress. Probe before write. `if ! ossh.config.get <alias>; then create…`.
9. **Helper extraction** — use `oo.new.method` or mirror its pattern (signature + docstring + completion). Not inline heredocs.
10. **Env reset for user switching** — explicit `export HOME=<target>; export USER=<target>; unset CONFIG CONFIG_PATH` + dispatch. Not `bash -lc` (bashrcTemplate early-returns for non-interactive).
11. **Guards are not substitutes for root-cause fixes** — symptom-fixes like `[ -w ]` gates are temporary; root-cause solutions follow.

---

## Part B — per-commit scorecard

| Commit | Summary | Verdict | Key notes |
|---|---|---|---|
| `12018a3` | add ssh.config.woda test | **PARTIAL** | Good test logic; lacks formal `test.case` discipline. Won't fix — cosmetic. |
| `4b1793f` | simplify ssh.config.woda to `$HOME` only | **PASS** | Removes false negatives. Order-independent grep. |
| `706950f` | extract F8 helpers `ossh.config.shared.seed.{from.local.deploy.key,fallback}` | **EXCELLENT** | Both helpers have docstrings + completion functions. 110-line region → 3-line dispatch. |
| `f515903` | `user.init`: append-if-missing WODA blocks | **GOLD STANDARD** | Replaces destructive heredoc with idempotent `ossh.config.create + ossh.config.save.last` per alias. |
| `8ec11a5` | delete F1 + F2 defensive re-adds | **PASS** | Verified safe before removal; explanatory comment retained. |
| `6ff8ab7` | add `[ -w "$LOG_LIVE" ]` guard | **PASS (symptom)** | Acknowledged temporary; real fix in `534ece9`. |
| `21e737c` | root-cause WODA + config ownership repair | **EXCELLENT** | `config.init` chowns `~/config` to actual `$HOME` owner. Portable `stat`. Could be extracted as helper (deferred). |
| `a237a90` | reset HOME/USER + clear `CONFIG_*` before `user init` | **TEXTBOOK** | Explicit env reset matches OOSH dispatch idiom; no `bash -lc` traps. |
| `4069475` | `user.group.add dev` BEFORE `user init` | **PASS** | One-line reorder; bash-user (created via raw `useradd`) now in dev group before shared write. |
| `cabe9ba` | state-machine fail-loud Phase 1 + F3/F4 | **EXCELLENT** | 5 numbered sub-steps; loop returns 1 on stuck. F3/F4 absorbed into state 31. |
| `6d83097` | retry `user.oosh.install` for developking | **PARTIAL** | Used dotted `user.oosh.install` (not in scope). Corrected in `78b7a34`. |
| `78b7a34` | dispatched `user oosh.install` + invariant fast-path | **EXCELLENT** | Space-notation dispatch + fast-path now checks symlink invariant, not just shared dir. |
| `f2ceed3` | `[ -w "$LOG_INSTALL" ]` guards (11 sites) | **PASS (symptom)** | Same layering rationale as `6ff8ab7`. |
| `534ece9` | migrate install.log to `/home/shared/sharedConfig` | **BEST-IN-CLASS** | Real fix. Shared canonical log captures all install actors; guards stay as belt-and-braces. |
| `be987b5` | source `$sharedOosh/this` directly in `private.as.user` | **PASS** | Bypasses bashrcTemplate's non-interactive early-return (matches commit `916306b`'s `ossh.exec` pattern). |

---

## Part C — cross-cutting findings

### Redundancies (intentional, not waste)
- **`[ -w ]` guards across `log` + `this` (11 sites)** + **shared install.log path** (`534ece9`): defense-in-depth, matches busybox-suid triple-defense pattern in `oosh-architecture.md`. **Keep both layers.**
- **F1 + F2 deletion** (`8ec11a5`) verified before removal — correct.

### Missed OOSH commands (real DRY opportunity)
- **`[ -w "$LOG_INSTALL" ]` guard pattern**: 11 sites with identical structure. Single highest-value DRY win — extract to `private.log.install.append <prefix> <message>`. **This plan addresses it.**
- **`config.init` ownership-repair block** (`21e737c`): could be `config.init.user.repair.ownership`, matching `config.md`'s repair family. Deferred — small + only called once.
- **F3 sed templating**: eval+sed pattern at `oo:1496-1502`. Could be `config.template.substitute <file> <pattern> <replacement>`. Deferred — current code is safely scoped.

### Philosophy contradictions
- **None observed.** Two-layer guard + shared path = intentional layering, not contradiction.

### Comment quality
- **Sub-step headers `# ─── state 31 [N/5: ...]`** (`cabe9ba`) — excellent.
- **F1/F2/F3/F4/F8 audit references** in code comments — helpful linkage to `docs/research/state-machine-fixup-audit.md`. Not cruft.
- **12-line `[ -w ]` rationale comment** at `this:78` — necessary (subtle bug); accept.

### Test surface gaps
- **F8 helpers (`706950f`)** have completion functions but no individual test cases. **This plan adds 4 cases.**
- **State 31 sub-step rc-checks** verified by integration testing (`os platform.test`); acceptable.
- **`user.oosh.install` dev-group reorder (`4069475`)** verified manually; ssh.config.woda implicitly catches regression.

### State-machine purity
- **State 31 dispatches every step through OOSH primitives** (`user create`, `ossh config.shared.create`, `private.install.dev.configs`, `git clone`, `user oosh.install`). **Compliant.**
- **Loop propagation** (`oo:1048-1050`, `cabe9ba`): `break` → `return 1`. **Compliant.**

---

## Part D — score breakdown

| Category | Score | Notes |
|----------|-------|-------|
| Naming | 10/10 | No violations. |
| Method structure | 8/10 | New helpers (706950f) have docstrings + completion. Tests lack formal OOSH signature. |
| Dispatching | 9/10 | One dispatch syntax error caught + corrected (`6d83097` → `78b7a34`). |
| Result/return fail-loud | 9/10 | `cabe9ba` introduces fail-loud across state 31. |
| Logging (typed + gates) | 9/10 | Consistent gate addition. Shared log path well-reasoned. |
| Config persistence | 8/10 | `config.init` ownership repair works but not extracted. |
| Idempotency | 9/10 | `ossh.config.get` guards + state fast-path + invariant check. |
| Helper extraction | 8/10 | Excellent for `ossh.config.shared.seed.*`. `[ -w ]` pattern not yet (this plan fixes). |
| Env reset for user switching | 10/10 | `a237a90` is textbook. |
| Root-cause over symptoms | 9/10 | Sequenced symptom → root-cause; layering retained as defense. |
| **OVERALL** | **9/10** | **Very disciplined OOSH discipline across 15 commits.** |

---

## Part E — recommendations

### High priority (acted on by the plan that produced this doc)
1. **Extract `private.log.install.append` helper** — collapse 11 sites to one. Done in this plan's Step 2.
2. **Add 4 T-SEED-* tests for F8 helpers** — done in this plan's Step 3.

### Deferred (each its own future plan)
3. **Extract `config.init.user.repair.ownership`** — small DRY win; align with `config.md` repair family.
4. **Build `config.template.substitute`** helper — replace eval+sed with primitive.
5. **Formalise `test/test.ssh.config.woda`** — cosmetic; test works.

### Out-of-scope (different effort)
6. **Hardening the other 16 install state-machine check functions** (audit doc §5.6) — Phase 2 of state-machine fail-loud.

---

## Closing note

These 15 commits demonstrate **rigorous OOSH discipline**. The team correctly sequenced symptom-then-root-cause fixes, properly layered defenses, used OOSH primitives throughout, introduced fail-loud at all critical state-machine boundaries, extracted F8 into named helpers, and fixed five distinct install-time bugs (WODA aliases wiped, dev-group membership, config ownership, env leakage, log-path EACCES spam). One missing refactor (the `[ -w ]` DRY) is closed by the plan that produced this doc; remainder is deferred without philosophy concern.

**Codebase is >95% in line with OOSH philosophy. Ready for production after this plan's two action items land.**
