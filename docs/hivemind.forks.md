# hiveMind UUID Tracking & Fork Lineage

**Purpose:** Document the non-invasive UUID discovery pipeline and the `hivemind.forks.env` audit log.

Related scripts: `claudeCode`, `hiveMind`, `otmux`.

---

## Problem this solves

Claude Code sessions are identified by a UUID. When you `claudeCode fork <uuid>`, the child gets a NEW UUID — but the parent UUID stays in the `ps` args (via `--resume <parent>`). After `autocompact`, a new JSONL is also created under a new UUID. Neither source is reliable on its own:

| Source | Reliable? |
|---|---|
| `ps` args `--resume <uuid>` | No — parent only for forks |
| `/status` dialog | Invasive (~3s TUI hijack), and Claude Code ≥ 2.1 removed the `Session ID:` line |
| `sessions.env` cache | Only if kept fresh |
| JSONL file | Yes — the filename IS the UUID |

We need a single, non-invasive function that finds the right UUID for a pane, works for forks, and distinguishes live/stable/dead sessions.

---

## The API — `claudeCode.session.*`

One primitive, two thin wrappers.

### `private.claudeCode.session.discover <pane>`

Prints one line: `<uuid>|<state>|<customTitle>`.

Non-invasive. No `/status`, no `ps` reliance. Algorithm:

1. Read pane title via `otmux pane.get '#{pane_title}'` (strip spinner markers `✳ `, `⏵⏵ `).
2. Read pane cwd via `otmux pane.get '#{pane_current_path}'`.
3. Check whether Claude is running in the pane via `claudeCode.process.find`.
4. Walk `~/.claude/projects/*/*.jsonl`:
   - Extract the **last** `customTitle` entry (not any — /rename appends new ones over time).
   - If it matches the pane's cleaned title → candidate.
   - Score by: (a) first-line `cwd` matches pane cwd → preferred, (b) mtime newest.
5. Classify state:
   - `live` — JSONL found, mtime < 120s, Claude process running
   - `stable` — JSONL found, Claude process running, mtime ≥ 120s
   - `stale` — JSONL found, no Claude process (zombie)
   - `broken` — no JSONL match, but `sessions.env` has a UUID for this pane → cache refers to a dead session
   - `unknown` — no pane, no Claude, no JSONL

### `claudeCode.session.current <pane>`

Thin wrapper. Prints just the UUID. Empty on unknown. Use this in most callers.

### `claudeCode.session.state <pane>`

Thin wrapper. Prints just the state.

### `claudeCode.session.probe <pane>`

Legacy invasive method. Sends `/status` + Enter, waits, parses the dialog. Fallback for diagnostic use — routinely prefer `session.current`. Still works on both Claude Code ≤ 2.0 (`Session ID:` regex) and ≥ 2.1 (`Session name:` + JSONL correlate).

---

## `hivemind.forks.env` — append-only audit log

| Field | Default |
|---|---|
| Location | `~/config/hivemind.forks.env` |
| Env var | `HIVEMIND_FORKS` |
| Writer | `hiveMind.registry.refresh` (single writer) |
| Format | append-only, one line per refreshed Claude pane per refresh call |

### Schema

```
# hiveMind fork lineage — append-only audit log
# timestamp|pane|role|uuid|state|parentUuid
2026-04-22T08:52:40Z|web4team:0.0|web4-po|a2ad74ab-...|stable|
2026-04-22T08:52:40Z|web4team:0.1|web4-architect|5b56e996-...|stable|
2026-04-22T08:55:12Z|web4team:0.1|web4-architect|5b56e996-...|live|a2ad74ab-...
```

| Column | Source |
|---|---|
| timestamp | `date -u '+%Y-%m-%dT%H:%M:%SZ'` at refresh time |
| pane | `session:window.pane` |
| role | pane title (stripped of `@model` suffix, validated) |
| uuid | from `session.current` |
| state | from `session.state` |
| parentUuid | JSONL first-line `parentUuid` field, empty for root sessions |

### Retention

Append-only, no retention policy. File grows linearly with refresh calls (4 panes × N refreshes ≈ negligible). Manual truncation only.

### Querying

```bash
# Every state change for a pane over time:
grep '|web4team:0.1|' ~/config/hivemind.forks.env

# All forks of a parent UUID:
awk -F'|' '$6 == "a2ad74ab-..."' ~/config/hivemind.forks.env

# Count sessions that became broken:
awk -F'|' '$5 == "broken" {print $4}' ~/config/hivemind.forks.env | sort -u | wc -l
```

---

## How `registry.refresh` uses the API

```
hiveMind.registry.refresh <session>
  ├─ prune dead panes from sessions.env and roles.env
  ├─ for each Claude-running pane in <session>:
  │    ├─ discover = private.claudeCode.session.discover <pane>
  │    ├─ extract role from pane title (strip @model, validate)
  │    ├─ write pane|role    → roles.env    (overwrite existing)
  │    ├─ write pane|uuid    → sessions.env (overwrite existing)
  │    └─ append timestamped row → forks.env
  └─ report: updated=<N> broken=<M>
```

Non-invasive: no `/status`, no agent interruption. Safe to call on every lifecycle edge.

---

## Lifecycle hooks (auto-refresh)

The following `hiveMind` methods auto-call `registry.refresh` at the end so caches stay fresh without manual invocation:

| Method | Why |
|---|---|
| `agent.rename` | `/rename` writes a new `customTitle` to JSONL — must pick up |
| `agent.spawn` | New pane → new UUID to register |
| `agent.bootstrap` | Fresh Claude launch — UUID comes into existence |
| `agent.respawn` | Fork → new child UUID replaces old one |
| `agent.restart` | Claude re-fork inside existing pane |
| `team.restart` | Bulk restart — single refresh after all agents up |

For manual flows, `hiveMind registry.refresh <session>` is the public entry point.

---

## Cold-start visibility — `hiveMind` (no args)

When tmux has no sessions running, `hiveMind` used to just say `No tmux sessions` and exit. Now it falls through to `hivemind.teams.env` and lists persisted teams:

```
[oosh MacStudio] donges@MacStudio:~ > hiveMind

No tmux sessions running.
Persisted teams from /Users/donges/config/hivemind.teams.env:

  TEAM                           DESCRIPTION
  ----                           -----------
  ooshTeam                       OOSH development team
  web4team                       Web4 architecture team
  TRONinterface                  PO supervision

Start with:  hiveMind teams.restore --fork
Restart one: hiveMind team.restart <configDir>
Pull remote: hiveMind team.pull <host>
```

This matters for cold recovery — you need to see what teams CAN be restored before you can restore them.

---

## Cross-reference

- Implementation: `claudeCode:private.claudeCode.session.discover`, `hiveMind:hiveMind.registry.refresh`
- Tests: `test/test.claudeCode` T-DISCOVER-1..9b, `test/test.hiveMind` T-REFRESH-1..8
- Related docs: `docs/hivemind.md`, `docs/claudeCode.sessions.md` (if present)
- Schema files in `~/config/`: `hivemind.roles.env` (pane|role), `hivemind.sessions.env` (pane|uuid), `hivemind.teams.env` (session|description), `hivemind.forks.env` (audit log).

---

## Design notes

### Why match on *last* customTitle

A single JSONL accumulates one `custom-title` entry every time `/rename` is called. Early entries may reflect the parent's name; the latest is the session's current identity. Using `grep | head -1` on the whole file would match inherited titles from before the rename — wrong answer.

### Why cwd disambiguator

Multiple simultaneous sessions can share a customTitle (e.g. two forks from the same parent before one is renamed). Pane cwd vs JSONL first-line cwd disambiguates cases where titles alone are ambiguous.

### Why non-invasive (no `/status`)

`/status` hijacks the Claude TUI for ~3 seconds and clears any text the user had typed. With 4-agent teams running refresh on every lifecycle edge (bootstrap, rename, respawn), `/status`-based discovery would constantly interrupt agents. JSONL correlation reads disk — agents never notice.

### Why forks.env is append-only

Three benefits:
- **Audit trail** — see every state transition for a pane/uuid over time
- **Lineage reconstruction** — when a JSONL is deleted, its parent chain survives in forks.env
- **No merge hazards** — concurrent refreshes don't corrupt a rewriting file

The cost (file growth) is minimal — a 4-agent team refreshed 20×/day for a year = ~30k lines = ~3MB.
