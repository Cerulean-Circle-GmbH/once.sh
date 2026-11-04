# T13 — Tools and gates `dev` never had

- **Type:** finding · **Priority:** P2 · **Area:** whole tree
- **State:** open; data in `docs/dev-gaps-vs-mcdonges.md`

## Never on `dev` (no commit in its history)

| Tool | Methods | Consequence on `dev` |
|---|---:|---|
| `osemvec` | 48 | absent |
| `tronMonitor` | 30 | `hiveMind` registers three TRON handlers + `monitor.switch`, all guarded with `command -v tronMonitor \|\| return 0` → **silent no-ops** |
| `opy` | 36 | absent |
| `claudeFlow` | 139 | was imported once and deleted in `36e1305d` (2026-10-20) |

Meanwhile `docs/methods-index.md` still documents all four as if they shipped (127/34/26/22
methods by its own count).

## Removed from `dev`

`myId` (`57a9dff6`) was deleted because its deploy key never worked — `ossh config.create` wrote
the Host block to a scratch file and never saved the config. `mcdonges` fixed the cause
(`c3a905bc`, `deploy.write`) and kept the tool; `dev` removed the tool instead. Same commit
removed `academyScript`, `myScript`, `tt`, `demo`, `old/` (`36e1305d`, `7cccf392`).

## No-python

`mcdonges` has the `test.no-python` burn-down gate; `dev` has none. Non-comment lines matching
`python3|python -|-m json.tool`:

| Script | dev | mcdonges |
|---|---:|---:|
| `claudeCode` | 11 | 9 |
| `scrumMaster` | 15 | 9 |
| `hiveMind` | 6 | 2 |
| `ossh` | 1 (a package name in a completion list, not a call) | 0 |
| `oo` | 1 | 0 |

## Hidden gaps the finding surfaced

- `this.is*` predicates imported without definitions — fixed in T04;
- `path.status`, `ssh.status`, `ssh.rename.files`, `ssh.get.*` are still advertised in docs/usage
  but absent (see `docs/dev-gaps-vs-mcdonges.md` §6);
- `test/test.academyScript`, `test/test.myScript`, `test/test.tt` are `legacy`-category tests for
  scripts that no longer exist.

## Acceptance

A decision per item: adopt (port the tool, its tests and the doc rows), or drop (remove the doc
rows, the TRON hooks, the legacy tests). For no-python: adopt `test.no-python` and rewrite the one
`ossh` completion word, or state why the gate stays mcdonges-only.
