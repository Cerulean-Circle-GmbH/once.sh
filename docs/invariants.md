# State Invariants (I1–I10)

**Purpose**: canonical reference for the consistency invariants that must hold across OOSH state stores. Each invariant has a severity, a detection method, an owner, and (where automated) a fix recipe.

**Audience**: contributors changing state-handling code; on-call operators triaging drift.

**Companion docs**: [docs/state-stores.md](state-stores.md) (what each store holds), [docs/oosh-architecture.md](oosh-architecture.md) (framework primer).

---

## Severity grading (PO-locked U2)

| Severity | Meaning | Reconcile action |
|----------|---------|------------------|
| **CRITICAL** | System unusable until fixed (cross-script protocol broken) | Fix immediately on `consistency.reconcile apply` |
| **HIGH** | Drift accumulating; agents misroute or invisible | Fix on apply; logged on dry-run |
| **MEDIUM** | Cosmetic + future-disaster vector (e.g. title drift, audit-trail gaps) | Fix on apply |
| **LOW** | Diagnostic-only (e.g. stale queue file) | Skip on apply unless `--all` |

`hiveMind consistency.audit` (dry read) returns total violation count as exit code; `consistency.reconcile <?session> <?mode:dry-run|apply>` applies fixes when mode=apply (default dry-run per U3 lock).

---

## Invariant table

| ID | Severity | Statement | Detector | Auto-fix | Owner |
|----|----------|-----------|----------|----------|-------|
| **I1** | HIGH | Every pane in S1 (roles.env) exists in L1 (live tmux). | `private.hiveMind.reconcile.check.i1` — read S1, `tmux list-panes -t <pane>` per row | `S1:REMOVE` row | hiveMind |
| **I2** | HIGH | Every pane in S2 (sessions.env) is in S1; cached UUID matches live Claude on that pane. | `private.hiveMind.reconcile.check.i2` — orphan check (a) implemented; UUID-vs-ps check (b) deferred pending batched scan | `S2:REMOVE` orphan | hiveMind |
| **I3** | CRITICAL | Every team in S3 (teams.env) is a live tmux session. | `private.hiveMind.reconcile.check.i3` — read S3, `tmux has-session -t <sess>` | `S3:REMOVE` row | hiveMind |
| **I4** | MEDIUM | tronMonitor.env (S8) ⊂ teams.env (S3) — no monitor window for a non-registered team. | `private.hiveMind.reconcile.check.i4` — read S8, grep each session in S3 | `S8:REMOVE` (via `tronMonitor remove` so screen window is killed too) | hiveMind / tronMonitor |
| **I5** | MEDIUM | Snapshot UUIDs (S4) point to JSONL files that exist under `~/.claude/projects/*/`. | `private.hiveMind.reconcile.check.i5` — read S4, scan project dirs for `${uuid}.jsonl` | SKIP (needs human attention — JSONL was deleted) | hiveMind |
| **I6** | LOW | Every queue file (S6) references a pane that exists in S1. | `private.hiveMind.reconcile.check.i6` — list queue dir, normalize filename to pane, grep S1 | `S6:REMOVE` (`rm` queue file) | hiveMind |
| **I7** | CRITICAL | tronMonitor's displayed window matches the team name claimed in its pane title (V vs C state-sync). | `private.hiveMind.reconcile.check.i7` — `tronMonitor verify` (captures screen, compares to title) | SKIP (V-layer state — operator runs `tronMonitor sync` / `reset`) | tronMonitor / hiveMind |
| **I8** | HIGH | Every live pane in L1 should have an S1 (registry) entry. Coverage check — symmetric to I1. | `private.hiveMind.reconcile.check.i8` — list all panes via `tmux list-panes -a`, grep S1 | `S1:ADD` proposed role from pane title (via `role.fromTitle`) | hiveMind |
| **I9** | MEDIUM | Pane titles match `role@HIVEMIND_HOST` (CMM4 naming directive, Option C). | `private.hiveMind.reconcile.check.i9` — list panes, compare title to expected | `V1:UPDATE` (apply `otmux pane.lock` with correct title) | hiveMind / otmux |
| **I10** | HIGH | Every Claude-running pane should have an S2 (sessions.env) entry. Coverage check — symmetric to I2 for S2. | `private.hiveMind.reconcile.check.i10` — `private.hiveMind.claude.processes` to pane list, grep S2 | `S2:ADD` (cheap resolve); flags `<probe-required>` for fork children needing `/status` probe | hiveMind |

---

## Detection patterns

### Pure detectors (no I/O on observed system)
- I1, I3, I4, I6 — file grep + `tmux` predicate queries; cheap (<100ms each)
- I8, I10 — list panes/processes once + grep; cheap-ish (<500ms)

### Invasive detectors
- I2(b) UUID-match — would cost 1s/pane × all S2 rows = 45s+ at scale → deferred until batched ps+JSONL correlation lands
- I7 — captures tronMonitor screen via hardcopy (~0.5s); skipped if tronMonitor not running

### Fork-child UUID gap
I10 flags missing S2 entries but cannot auto-fix fork children — their real UUID lives only in the JSONL `customTitle`, requiring an invasive `/status` probe to discover. SC-H.2 Gap A (commit `1b2d59b`) introduced `private.hiveMind.session.store.deferred` which schedules background probes at 5s/15s/30s post-launch, populating S2 without operator intervention. I10 in dry-run still surfaces the gap; in apply mode it falls through to the deferred path.

---

## Fix recipes (dispatch table from `private.hiveMind.reconcile.apply`)

Reconcile rows have format `<severity>|<invariant>|<store>|<op>|<key>|<expected>|<actual>`. The apply primitive dispatches per `(store, op)`:

| Dispatch | Mutation |
|----------|----------|
| `S1:REMOVE` | `grep -v "^${pane}|" $reg > $tmp && mv $tmp $reg` |
| `S1:ADD` | `private.hiveMind.registry.set $pane $expected` (canonical writer) |
| `S2:REMOVE` | `grep -v "^${pane}|" $ses > $tmp && mv $tmp $ses` |
| `S2:ADD` | If `expected != <probe-required>`: `private.hiveMind.session.store $pane $expected`. Otherwise skip (Gap A deferred probe handles). |
| `S2:UPDATE` | `grep -v + append ${pane}|${liveUuid}` (cache refresh) |
| `S3:REMOVE` | `grep -v "^${session}|" $teams > $tmp && mv $tmp $teams` |
| `S6:REMOVE` | `rm <queue file path>` |
| `S8:REMOVE` | Prefer `tronMonitor remove $session` (V-aware — kills screen window too); raw-file fallback |
| `I5 / I7` | SKIP — snapshot staleness + V-layer mismatch need human attention |

---

## Reconcile cycle

`scrumMaster.cycle` (called periodically by SM) runs after sweep + unblock:

```bash
if private.scrumMaster.sweep.isStable "$session"; then
  hiveMind consistency.reconcile "$session" apply
fi
```

The stability gate (`private.scrumMaster.sweep.isStable`) checks for recent lifecycle/mutation processes in `ps` and skips if anything is in flight — reconcile is a safety net, not a hot path. One missed cycle is harmless; fighting a mid-flight mutation is destructive.

---

## How invariants get added

1. Write `private.hiveMind.reconcile.check.iN` returning canonical rows (one per violation).
2. Add a row to the table above (severity, statement, auto-fix).
3. If auto-fixable, add a dispatch arm in `private.hiveMind.reconcile.apply` for the new `(store, op)` pair.
4. Add a test fixture under SC-D.3 (tester scope) — inject a violation, verify detector fires + apply mutates correctly.

The reconcile cycle picks up new invariants automatically — no registration step. Just defining `private.hiveMind.reconcile.check.iN` and the audit/reconcile commands will iterate it.

---

## See also

- [docs/state-stores.md](state-stores.md) — S1–S10 definitions
- [docs/oosh-architecture.md](oosh-architecture.md) — framework conventions
- `scrum.pmo/sprints/sprint-1-state-correctness/sprint-1-design.md` — design rationale
- `hiveMind consistency.audit` — graded read-only invariant report
- `hiveMind consistency.reconcile <?session> <?mode>` — dry-run by default; `apply` mutates
- `hiveMind consistency.fix <?session>` — interactive y/N applier
