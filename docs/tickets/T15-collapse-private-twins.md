# T15 — Collapse the public/private method twins (key.push / key.pull done)

- **Type:** refactor · **Priority:** P3 · **Area:** `ossh` (the same pattern exists in other scripts)
- **State:** `key.push`/`key.pull` collapsed (`abe94542`), the two unused `.completion` twins
  deleted (`ca008c60`) — both 2026-11-04; 6 pairs remain
- **Found by:** "why do we have `ossh.key.pull` and `private.ossh.key.pull` for the same thing?"

## The pattern

A public method that is a three-line wrapper over its private twin:

```bash
ossh.key.pull() { private.ossh.key.pull "$@"; }   # public: the contract
private.ossh.key.pull() { …   160 lines …   }     # private: the body
```

Ten such pairs exist in `ossh` (introduced by `dc7aa950`, 2026-10-16):

```
ossh.config.field.get   ossh.config.pull   ossh.config.push
ossh.config.push.completion   ossh.dir.pull   ossh.dir.push
ossh.dir.push.completion   ossh.id.push   ossh.key.pull   ossh.key.push
```

`ossh.key.push` and `ossh.key.pull` are collapsed (`abe94542`); the other eight remain.

## Why collapse (and why it is not access control)

- `this.call` falls back to a bare function name when `<script>.<method>` does not exist, so
  `./ossh private.ossh.key.pull lab` **reached the private method** anyway. The `private.` prefix
  is a label, not a guard.
- The wrapper added a frame and a second docstring; the two had already drifted.
- `docs/ossh.md` listed the same operation twice (public row + private row), and
  `docs/parameter.md` / `docs/object-verb-index.md` bound both names to the same parameters.
- Dead twins accumulated (`private.ossh.get.server.ip`, `private.ossh.get.server.port.wrapper`
  were exactly that).

## What was done for `key.push` / `key.pull`

| Step | Change |
|---|---|
| body | moved from `private.ossh.key.*` into the public method; the rc/`RESULT` clause of the private docstring merged into the public one |
| twins | `private.ossh.key.push` and `private.ossh.key.pull` deleted |
| caller | `ossh.create.and.install` calls `ossh.key.pull` (was `private.ossh.key.pull`) |
| guard | `T-OSSH-RENAMES-OBJECT-VERB` no longer expects the two private names |
| docs | private rows removed from `docs/ossh.md`; bindings removed from `docs/parameter.md` and `docs/object-verb-index.md`; `docs/methods-index.md` ossh row 97→95 private, 202→200 rows, 101→99 only-dev; dated note in the two comparison pages |

## Verification

```
type -t ossh.key.push / ossh.key.pull        → function
type -t private.ossh.key.push / .pull        → (empty)
grep private.ossh.key.{push,pull} in docs/   → 0
test.ossh                                    → 155/155
```

## Tree-wide count (2026-11-04)

A scan of every tracked script for `private.X` next to a public `X` finds **38 twins** in 10
scripts: `backup` 8, `ossh` 8, `oo` 5, `scrumMaster` 4, `config` 3, `hiveMind` 3, `odocker` 3,
`user` 2, `line` 1, `osshLayout` 1. Two are collapsed (`key.push`, `key.pull`), so **36 remain**.

They are not all the same thing:

| Shape | Count | What it means |
|---|---:|---|
| public body ≤2 code lines, delegates to the private | 25 | the `key.push`/`key.pull` pattern |
| longer delegate (extra logic around the call) | 5 | collapsing merges two bodies |
| same name, different body (or dynamic call) | 8 | usually a dynamic `private.<family>.$field` call — not a wrapper |

Of the 38, **13 have no caller besides their wrapper** and can be collapsed without touching
anyone:

```
backup.file.list.notBackedUp   backup.file.list.onlyInBackup   backup.log.capture.mode
backup.result.list.lastRaw     oo.dev.to.testing               oo.promote.report
oo.promote.status              ossh.config.push.completion     ossh.dir.push.completion
scrumMaster.health.check       scrumMaster.health.evaluate     scrumMaster.subscription
scrumMaster.velocity.target
```

The other 25 are called from other methods or from tests (`hiveMind.registry.set` 19 sites,
`ossh.config.push` 14, `odocker.workspace.list` 12, `oo.pm.env.get` 10, …). Collapsing those is
a rename, not a deletion: every caller and the rename guard must move with them.

## Remaining ossh pairs — measured (2026-11-04)

The earlier "check" rows were guesses. This table is from a tree-wide scan of `ossh` and `test/`
that separates three things: real callers outside the wrapper, the wrapper's own call, and
references that are only the rename guard's `for new in …` list.

| Private twin | Callers outside the wrapper | Test invocations | Verdict |
|---|---|---:|---|
| `private.ossh.config.push.completion` | none | none | **unused** — delete |
| `private.ossh.dir.push.completion` | none | none | **unused** — delete |
| `private.ossh.config.pull` | none | none (only the guard list, `test.ossh:3434`) | **unused** — guard pins the name; collapse + drop from guard |
| `private.ossh.dir.push` | none | 4 (`test.ossh:3336-3339`) | **test-only** — collapse + repoint tests |
| `private.ossh.id.push` | none | 5 (`test.ossh:3344-3348`) | **test-only** — collapse + repoint tests |
| `private.ossh.dir.pull` | 1 (`private.ossh.pull.id`, `ossh:3436`) | 4 (`test.ossh:3340-3343`) | **production + test** — collapse + repoint both |
| `private.ossh.config.push` | 1 (`create.and.install`, `ossh:1518`) | 11 (`test.ossh:497-521`, `3331-3334`) | **production + test** — collapse + repoint both |
| `private.ossh.config.field.get` | 8 (`ossh:323,394,409,415,421,426,432,438`) | 1 (`test.ossh:332`) | **keep** — not a wrapper |

Notes:

- `ossh:2778` is not a caller: it is the `create.result` message string inside
  `private.ossh.config.push` that mentions its own name.
- The wrapper call (`private.ossh.dir.push "$@"` and friends) is excluded from "callers".
- `ossh.config.field.get` is a validated public command over the raw per-field getter; the
  per-field getters and `config.set` consume the raw one. Merging would put validation on the
  internal path. Keep it, add a one-line comment saying so.
- The two `.completion` hooks are **not** called by the completion engine by name — the engine
  completes the operation, not its `*completion` helper. They are byte-identical duplicates of
  their public wrappers, so nothing breaks when they go.

## Done 2026-11-04 (2): the two `.completion` duplicates

`private.ossh.config.push.completion` and `private.ossh.dir.push.completion` were deleted in
`ca008c60`. Each was a byte-identical copy of its public wrapper:

```bash
ossh.config.push.completion() {          private.ossh.config.push.completion() {
  ossh.config.get.completion "$@"          ossh.config.get.completion "$@"
}                                        }
```

Why nothing broke:

- the c2 completion engine looks up `<class>.<method>.completion[<parameter>]`; the private
  name would need a `private` class, which nobody types;
- no test names them (checked tree-wide, not just in `ossh`);
- the rename guard lists the **pre-object-verb** names
  (`private.ossh.push.config.completion`), not these.

Branch comparison: mcdonges never had the private copies — only the public helper. dev created
them in `dc7aa950` (2026-10-16), the same commit that introduced the other twins. So the deletion
moves dev toward mcdonges rather than away from it.

mcdonges has the *other* form of the same defect: `ossh.config.push.completion()` is defined
twice, back to back and identical (`ossh:1234` and `1239`), and `ossh.list()` is also defined
twice. dev has no duplicate definitions. That is recorded in T11.

Verification: `bash -n ossh`, `type -t` for both public names, `test.ossh` 155/155,
`docs/methods-index.md` ossh 95→93 private / 200→198 rows / 99→97 only-dev / 2344→2342 total.

## Order of work

1. ~~**Now, no caller changes:** delete the two `.completion` twins.~~ **Done** — `ca008c60`.
2. **Next, no caller changes:** collapse `config.pull` (drop it from the guard list) — still no caller.
3. **Separate change:** collapse `dir.push`, `id.push`, `dir.pull`, `config.push` — each needs its
   test fixture (`test.ossh:3331-3348`) and, for the last two, the internal caller repointed.

## Acceptance

- per pair: either the private name is gone and the guard/docs updated, or a one-line comment says
  why the twin stays;
- `test.ossh` green; `docs/methods-index.md` counts adjusted;
- if the rule is to keep any twin, add the missing guard: `this.call` should refuse a bare
  `private.*` name from the CLI, so the wrapper is actually a boundary.

## Follow-up worth its own ticket

`this.call`'s bare-function fallback is the deeper issue: it makes every `private.*` in a sourced
script user-callable. Either block it (a name check in `this.call`) or drop the `private.`
convention's claim of inaccessibility in `docs/this.md`.
