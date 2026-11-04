# T11 — `ossh`: two incompatible naming/feature lines

<!-- ossh-rename-history: allowed — this ticket quotes retired names on purpose -->

- **Type:** finding · **Priority:** P1 · **Area:** `ossh`
- **State:** open; data in `docs/compare-ossh-dev-vs-mcdonges.md` and
  `docs/ossh-differences-dev-vs-mcdonges.md`

## The finding

| | `dev` | `mcdonges.latest` |
|---|---:|---:|
| Lines | 4 132 | 1 770 |
| Methods (public) | 230 (144) | 160 (106) |
| Shared names | 101 | |
| Shared but **changed** | 78 | |
| Only on one side | 129 (dev) | 59 (mcd) |
| Last change | 2026-10-22 | **2026-08-29** |

The two lines ran the same object.verb cleanup twice with different outcomes and then diverged:

- `dev`: `key.push`, `authorized.keys.update`, `config.field.get`, per-field accessors,
  `folder.fix`, `harden`, `config.shared.*`, `cmd/prereqs`, `key.revoke`, `exec.tty`, install split,
  atomic writes, 644 keys.
- `mcdonges`: verb-first aliases (`push.key`, `pull.key`, `push.config`, `pull.id`, `scp`) kept as
  deprecated wrappers, a generic `ossh get/set` dispatcher (unused), `private.ossh.hostKnown` /
  `validConfigBlock` for `config.pull`, `deploy.write` for `config.create`, **no** `chmod 644`
  anywhere.

Called with the same verb, the behaviour differs too: `exec` (remote prelude vs
`source config/user.env`), `key.push` (Host IdentityFile + login check vs rsync +
`user update.authorized_keys`), `config.create` (last-file + `config.save.last` vs append via
`deploy.write`), install (split vs one-shot).

## Duplicate definitions on mcdonges

A scan for method names defined more than once at column 1 finds two on `mcdonges.latest`, none
on `dev`:

| Name | mcdonges | dev |
|---|---|---|
| `ossh.config.push.completion()` | defined twice, identical, back to back (`ossh:1234`, `ossh:1239`) | once |
| `ossh.list()` | defined twice | once |

Bash silently keeps the last definition, so nothing fails — but the second copy is dead text and
the pattern hides edits: change the first block and the second silently wins.

On `dev` the same duplication existed in a different shape: `private.ossh.config.push.completion`
and `private.ossh.dir.push.completion` duplicated the public helpers byte for byte (introduced by
`dc7aa950`). Those were deleted in `ca008c60`, so `dev` now has one definition per name. When the
mcdonges line is merged, its duplicate `ossh.config.push.completion` / `ossh.list` should be
dropped instead of carried over.

## Why it matters

`docs/compare-ossh-dev-vs-mcdonges.md` §5 is a compatibility matrix: every row with a dash is a
script that works on one branch and fails on the other. Any merge or rollback has to pick a side
per row, not per file.

## Decision needed

1. **Naming** — keep `dev`'s object.verb and drop the aliases, or keep the aliases for one release?
2. **Dispatcher** — adopt `ossh get/set` or delete it (nothing calls it, even on mcdonges).
3. **Port forward from mcdonges** — `config.pull` validation (`hostKnown`, `validConfigBlock`) and
   the `config.create` → `deploy.write` wiring; both solve real bugs `dev` solves differently.
4. **Duplicate definitions** — drop mcdonges' second `ossh.config.push.completion` and
   `ossh.list` instead of merging them.
5. **Port back from dev** — 644 public keys, atomic `authorized_keys`, `folder.fix`, `key.revoke`,
   the install split.

## Acceptance

A written decision per compatibility row, reflected in `test.ossh` and `docs/ossh.md`; a merge
plan that does not take mcdonges' `ossh` wholesale (it would delete 2 355 lines of features).
