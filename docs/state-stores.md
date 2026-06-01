# State Stores (S1–S10)

**Purpose**: canonical reference for OOSH state stores. Each store has an owner script, a writer (the only path that mutates it), a serialization format, and a ground-truth source it must converge to via reconcile.

**Audience**: contributors changing state-handling code. **Read before** adding a method that writes to any of these files.

**Companion docs**: [docs/invariants.md](invariants.md) (what must hold across stores), [docs/oosh-architecture.md](oosh-architecture.md) (framework primer).

---

## Layered model

| Layer | Examples |
|-------|----------|
| **L1 — tmux state** | `tmux list-sessions`, `tmux list-panes` — sessions, panes, titles, tty, pid |
| **L2 — screen state** | `screen -ls`, `screen -X hardcopy` — GNU screen for tronMonitor viewer |
| **L3 — Claude state** | `~/.claude/projects/*/*.jsonl` (conversation + usage), `ps -eo args` (running processes with `--resume <UUID>` flags) |

**L3 token semantics (hard-won, P0 bug f89bbc8):**
The JSONL `usage` object in each assistant message contains:
- `input_tokens` — non-cached prompt portion (often just 1 with full caching!)
- `cache_creation_input_tokens` — new tokens written to prompt cache this turn
- `cache_read_input_tokens` — tokens read from existing prompt cache
- **Total context = input + cache_creation + cache_read** (together = full prompt sent to model)

These are NOT overlapping billing categories — they are additive components of the context window.
`input_tokens` alone is meaningless with prompt caching enabled (shows 1 when context is 500k).

For 1M-context sessions (`claude-opus-4-6[1m]`), max_tokens is 1,000,000 — detected by
`private.claudeCode.max.tokens.for.jsonl` via 3-tier priority: ps args `[1m]` flag → observed
max > 200k → model default. See `CLAUDE_MAX_TOKENS_*` env constants at top of `claudeCode`.

Caches (S1–S10) MUST converge to L1+L2+L3 via the reconcile cycle (see `hiveMind.consistency.reconcile`).

---

## Store table

| ID | Name | File | Format | Owner | Writer methods | Reads from |
|----|------|------|--------|-------|----------------|------------|
| **S1** | roles | `~/config/hivemind.roles.env` | `pane\|role\|epoch` (TTL field optional) | hiveMind | `private.hiveMind.registry.set` (one write path; called by `agent.bootstrap`, `agent.rename`, `agent.spawn`, `team.setup`, `consistency.fix`, event handlers) | many; canonical lookup via `private.hiveMind.registry.find` |
| **S2** | sessions | `~/config/hivemind.sessions.env` | `pane\|uuid` | hiveMind | `private.hiveMind.session.store` (one write path; called after `agent.session.probe` succeeds, and by `private.hiveMind.session.store.deferred` async retry) | `private.hiveMind.session.lookup`, `private.hiveMind.session.resolve.uuid`. **Staleness risk (P0 bug f89bbc8):** after fork, S2 retains PARENT UUID. `claudeCode.context.read` now rejects stale JSONL (mtime >10min) and re-resolves via `session.current`. |
| **S3** | teams | `~/config/hivemind.teams.env` | `session\|description` | hiveMind | `hiveMind.team.register` (gold-standard triple defense, P3 reference), event handlers `team.created.teams` / `team.destroyed.teams` / `team.restored.teams` | `hiveMind.team.list`, `hiveMind.team.switch`, `private.hiveMind.active.team` |
| **S4** | snapshots | `~/config/hivemind.snapshot.*.env` | header `# version: 1` + 8-field rows `session\|addr\|role\|uuid\|title\|cwd\|model\|kind` (post SC-F.1) | hiveMind | `hiveMind.teams.save` only; validated via `private.hiveMind.snapshot.row.valid` (SC-F.2) | `hiveMind.teams.restore`, `agent.restart`, `team.restart` — all gated by `private.hiveMind.snapshot.version.check` (SC-F.1) and per-row validator (SC-F.3) |
| **S5** | forks audit | `~/config/hivemind.forks.env` | append-only: `ts\|pane\|role\|childUuid\|status\|parentUuid` | hiveMind | event handler `agent.forked.forks` only | diagnostic; consulted by `hiveMind.forks.list` |
| **S6** | queues | `~/config/hivemind.queue/<sanitized-pane>.queue` | one row per pending message: `epoch\|intent\|text` | hiveMind | `hiveMind.agent.queue.append` (during throttle), `hiveMind.agent.queue.drain` removes consumed rows; event handler `agent.killed.queue` removes the whole file | `hiveMind.agent.queue.show`, dashboard rendering |
| **S7** | active team | `~/config/hivemind.active.team` | single line: session name | hiveMind | `hiveMind.team.switch` / `team.activate` only | `private.hiveMind.active.team` (called by every method that defaults `$session`) |
| **S8** | tronMonitor windows | `~/config/tronMonitor.env` | `screenWin\|session` | tronMonitor | `tronMonitor.add` / `tronMonitor.remove` / `tronMonitor.sync` / `tronMonitor.reset`; event handlers `team.created.tronMonitor` / `team.destroyed.tronMonitor` / `team.restored.tronMonitor` | `tronMonitor.list`, `tronMonitor.switch`, `private.tronMonitor.findWindow`, `private.tronMonitor.tracked.teams` |
| **S9** | size locks | `~/config/otmux.size.locks.env` | `session\|minW×minH` | otmux | `otmux.size.lock` / `otmux.size.unlock` only | `otmux.size.floor.apply` (called by tronMonitor + scrumMaster.cycle to enforce minimums) |
| **S10** | per-session layouts | `~/config/otmux/<session>.layout.env` | sourced bash env: `OTMUX_LAYOUT_SESSION`, `OTMUX_WINDOW_<N>_LAYOUT` (tmux layout string), `OTMUX_WINDOW_<N>_PANE_<M>_TITLE/CWD/CMD` (per-pane metadata) | otmux | `otmux.layout.save` only (called by `hiveMind.teams.save` end of cycle, and `hiveMind.team.migrate` push) | `otmux.layout.restore` (called by `hiveMind.teams.restore`, `team.restart`), `otmux.layout.list`, `otmux.layout.show` |

---

## Write-path discipline (DRY rule)

**Exactly one writer per store** is the discipline. If you find yourself directly editing a `~/config/hivemind.*.env` file from a public method, you are bypassing the canonical writer and breaking the event-emission contract. Always go through the writer.

Example: do NOT do
```bash
echo "${pane}|${role}" >> "$HIVEMIND_REGISTRY"  # WRONG — bypasses registry.set
```
Always do
```bash
private.hiveMind.registry.set "$pane" "$role"   # canonical writer (emits event)
```

Event-emission is the link between writers and observers. Skipping the writer means observers (tronMonitor sync, sessions cache invalidation, etc.) miss the mutation and drift accumulates.

---

## Event-driven mutation (SC-B/SC-C)

Mutating a store should fire the appropriate event (see `private.hiveMind.events.emit` and the handler registrations at hiveMind line ~755):

| Event | Args | Handlers update |
|-------|------|-----------------|
| `agent.spawned` | `<pane> <role> <?uuid>` | S1 (registry), S2 (sessions or defer-probe) |
| `agent.killed` | `<pane>` | S1 (registry), S2 (sessions), S6 (queue) |
| `agent.renamed` | `<pane> <oldName> <newName>` | S1 (registry), display title (pane.lock), per-pane HIVEMIND_ROLE env |
| `agent.forked` | `<pane> <role> <parentUuid> <childUuid>` | S1, S2, S5 (forks log) |
| `panes.shifted` | `<session>` | S1 (registry re-key) |
| `panes.swapped` | `<session> <A> <B>` | S1, per-pane role env |
| `pane.moved` | `<from> <to>` | S1, per-pane role env |
| `team.created` | `<session> <description>` | S3 (teams), S8 (tronMonitor) |
| `team.destroyed` | `<session>` | S3, S8, S1 (prune), S2 (prune), S6 (queue prune) |
| `team.restored` | `<session> <snapfile>` | S3, S8 |

The reconcile cycle catches anything that escaped the event path (see invariants doc).

---

## Snapshot format (S4) — schema v1

```
# version: 1
# hiveMind snapshot 2026-05-25T19:30:00
# session|address|role|uuid|title|cwd|model|kind
ooshTeam|0.0|oosh-po|aca3405a-...|oosh-po|/Users/Shared/...|opus|claude
ooshTeam|0.4|oosh-expert-shell||oosh-expert-shell|/Users/Shared/...||shell
```

Header rows (`#` prefix) are skipped during restore. Data rows are validated per-field by `private.hiveMind.snapshot.row.valid` — invalid rows are logged and skipped (not aborted), so partial corruption never blocks restore of clean rows.

Backward compat: snapshots without `# version:` header are grandfathered as v1 (pre-SC-F.1 era).

---

## File ownership (do not cross-edit)

| Files written by | Script |
|------------------|--------|
| `hivemind.*.env` | hiveMind (only) |
| `tronMonitor.env` | tronMonitor (only) |
| `otmux.*.env`, `otmux.<sess>.layout` | otmux (only) |

Other scripts read these files. Other scripts MUST NOT write them. Crossing this line creates phantom state and breaks the audit trail.

---

## See also

- [docs/invariants.md](invariants.md) — what must hold across these stores (I1–I10)
- [docs/oosh-architecture.md](oosh-architecture.md) — framework conventions
- `scrum.pmo/sprints/sprint-1-state-correctness/sprint-1-design.md` — design rationale
