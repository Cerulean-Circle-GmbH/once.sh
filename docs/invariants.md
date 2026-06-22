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

## Event handlers that enforce each invariant

Invariants are maintained by two mechanisms: **event handlers** (primary, real-time)
and **reconcile** (safety net, periodic). This table shows which events keep each
invariant true, and what reconcile catches if an event is missed (bash 3.2 no-op,
race condition, tmux kill bypassing hiveMind, etc).

| I# | Enforced by events | Reconcile catches |
|----|-------------------|-------------------|
| **I1** | `agent.spawned` → `registry.set` (adds S1 entry for new pane). `agent.killed` → `registry.remove` (removes S1 entry). `panes.shifted` → `registry.shift` (re-keys S1 when tmux renumbers). `team.destroyed` → `registry.prune` (bulk-removes all S1 entries for dead session). | Orphan S1 entries where pane no longer exists in L1 (`S1:REMOVE`). Missing S1 entries for live Claude panes (`S1:ADD` via I8). |
| **I2** | `agent.spawned` → `sessions.store` (writes pane→UUID to S2). `agent.forked` → `sessions.store` (updates S2 with child UUID). `session.store.deferred` retries at 5s/15s/30s when UUID unknown at spawn (Gap A). | Orphan S2 entries for panes not in S1 (`S2:REMOVE`). Stale UUIDs where cached UUID doesn't match live ps args (`S2:UPDATE`). |
| **I3** | `team.created` → `teams.add` (writes S3 after `otmux new`). `team.destroyed` → `teams.remove` (removes S3 entry). `team.register` applies P3 triple defense at ingress (rejects non-existent sessions). | Ghost S3 entries for tmux sessions that no longer exist (`S3:REMOVE`). |
| **I4** | `team.created` → `tronMonitor.add` (observer pattern, soft-fail). `team.destroyed` → `tronMonitor.remove`. `team.restored` → `tronMonitor.add` (bulk). | S8 entries referencing sessions not in S3 (`S8:REMOVE` via `tronMonitor remove`). |
| **I5** | `teams.save` validates each row via `snapshot.row.valid` before writing (SC-F.2). No event needed — validation is at write time. | Stale UUIDs in S4 pointing to deleted JSONLs (SKIP — needs human attention; JSONL was garbage-collected). |
| **I6** | `agent.killed` → `queue.clean` (deletes queue file for dead pane). `team.destroyed` → `queue.prune` (bulk-deletes queue files for all panes in dead session). `panes.shifted` → `queue.rename` (renames queue files when pane addresses change). | Orphan queue files for panes not in S1 (`S6:REMOVE`). |
| **I7** | `tronMonitor.switch` calls `tronMonitor.verify` after switching (Pattern P2 — verify-before-claim). | V-layer mismatch (SKIP — operator runs `tronMonitor sync/reset`). |
| **I8** | Same as I1 — `agent.spawned` ensures new panes get S1 entries. Coverage is the complement of I1 (I1 = no orphans in S1; I8 = no gaps in S1). | Live Claude panes missing from S1 (`S1:ADD` with role from `role.fromTitle`). |
| **I9** | `agent.renamed` → `pane.title.pushed` (sets title to `role@HIVEMIND_HOST`). `agent.spawned` → `pane.lock` (same title format). | Title drift where pane title doesn't match `role@HIVEMIND_HOST` (`V1:UPDATE` via `otmux pane.lock`). |
| **I10** | Same as I2 — `agent.spawned`/`agent.forked` populate S2. `session.store.deferred` handles async UUID discovery. | Claude-running panes missing from S2 (`S2:ADD` or flag `<probe-required>` for fork children). |

### Bash 3.2 fallback

Events are gated by `BASH_VERSINFO >= 4` (task #29). On macOS default bash 3.2,
`events.emit` is a no-op — handlers never fire. Each mutation method has a direct
fallback gated by `[ -z "$HIVEMIND_EVENTS_AVAILABLE" ]` that performs the same
store updates inline. The reconcile cycle catches anything both paths missed.

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

## Real-world example: P0 context.read staleness (2026-05-28)

**Invariant violated:** I2 (UUID in S2 matches live Claude) + I10 (every Claude pane has S2 entry).

**What happened:** After forking oosh-expert, S2 retained the parent's UUID (`ea2c7021`).
The parent's JSONL had stopped being written 39 minutes ago — its last 50 lines
contained zero assistant messages with usage data (fully compacted). `claudeCode context.read`
resolved pane → S2 → stale UUID → dead JSONL → total=0 → reported **100% remaining**.
The SM used this to decide the agent was healthy. In reality the fork's real JSONL
showed **48% remaining**.

**Why events didn't catch it:** The fork happened via `claudeCode fork` from an
external pane, not through `hiveMind.agent.fork.best` which would have emitted
`agent.forked` and updated S2. Direct CLI fork bypasses the event system.

**Fix (commit f89bbc8):**
1. `context.from.jsonl` added staleness guard — rejects JSONL with mtime >10min
2. `context.read` catches `"stale"` return, re-resolves UUID via `session.current` (ps-based)
3. `context.read` searches ALL project dirs (was hardcoded to 2 paths)

**Lesson:** Even with events + reconcile, consumers of cache data (like `context.read`)
must defend against stale reads independently. The staleness guard is a Pattern P2
application — verify the data you're about to use, don't trust the cache blindly.

---

## See also

- [docs/state-stores.md](state-stores.md) — S1–S10 definitions
- [docs/oosh-architecture.md](oosh-architecture.md) — framework conventions
- `scrum.pmo/sprints/sprint-1-state-correctness/sprint-1-design.md` — design rationale
- `hiveMind consistency.audit` — graded read-only invariant report
- `hiveMind consistency.reconcile <?session> <?mode>` — dry-run by default; `apply` mutates
- `hiveMind consistency.fix <?session>` — interactive y/N applier
