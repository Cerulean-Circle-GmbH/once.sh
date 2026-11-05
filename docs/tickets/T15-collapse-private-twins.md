# T15 — Collapse the public/private method twins (ossh done: 10 of 10)

<!-- ossh-rename-history: allowed — this ticket quotes retired names on purpose -->

- **Type:** refactor · **Priority:** P3 · **Area:** `ossh` (the same pattern exists in other scripts)
- **State:** **`ossh` done** — 9 twins collapsed/deleted, `config.field.get` kept with a
  comment. `key.push`/`key.pull` (`abe94542`) and the two unused `.completion` twins
  (`ca008c60`) on 2026-11-04; `config.pull` (`da01a047`), `dir.push`/`id.push` (`d76c8c69`),
  `dir.pull`/`config.push` (`96e5584d`) and the keep note (`b2be95f9`) on 2026-11-05.
  36 twins in other scripts are inventoried below but not started.
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
| `private.ossh.config.pull` | none | none (only the guard list) | ~~**unused** — collapse + drop from guard~~ **done 2026-11-05** |
| `private.ossh.dir.push` | none | 4 (`test.ossh:3336-3339`) | ~~**test-only** — collapse + repoint tests~~ **done 2026-11-05** |
| `private.ossh.id.push` | none | 5 (`test.ossh:3344-3348`) | ~~**test-only** — collapse + repoint tests~~ **done 2026-11-05** |
| `private.ossh.dir.pull` | 1 (`private.ossh.pull.id`) | 4 (`test.ossh:3340-3343`) | ~~**production + test**~~ **done 2026-11-05** |
| `private.ossh.config.push` | 1 (`create.and.install`) | 11 (`test.ossh:497-521`, `3331-3334`) | ~~**production + test**~~ **done 2026-11-05** |
| `private.ossh.config.field.get` | 8 (`ossh:323,394,409,415,421,426,432,438`) | 1 (`test.ossh:332`) | **keep** — not a wrapper; comment added `b2be95f9` |

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

## Done 2026-11-05: `config.pull`

`private.ossh.config.pull` (82 lines) moved into `ossh.config.pull`; the private block is gone
(commit `da01a047`).
The public docstring kept its wording and took the private one's `rc 1 + RESULT` clause.

Changes that went with it:

| Where | Change |
|---|---|
| `test.ossh` | dropped `private.ossh.config.pull` from the guard's `for new in …` list; comment records the collapse |
| `docs/ossh.md` | private row removed, public row carries the merged docstring |
| `docs/parameter.md`, `docs/object-verb-index.md` | the private binding is gone |
| `docs/methods-index.md` | ossh 93→92 private, 198→197 rows, 97→96 only-dev, 2342→2341 total |

Nothing called it: no production caller, no test invocation. The guard was the only thing keeping
the name alive. Verified with `bash -n`, `./ossh config.pull` (no args → "no fromHost was
specified"; `bad name` → "is no Host name") and `test.ossh` 155/155.

This also fixes a latent guard failure introduced when the tickets were committed: T15 quoted
`private.ossh.push.config.completion` without the `ossh-rename-history: allowed` marker, so
`T-OSSH-RENAMES-OBJECT-VERB` reported `left=[docs/tickets/T15-collapse-private-twins.md:132]`.
The marker is now in T15's first lines.

## Done 2026-11-05 (2): `dir.push` and `id.push`

Both were pure wrappers. The bodies moved into the public methods (commit
`d76c8c69`); the docstrings took the private `rc 0 + RESULT / rc 1 + RESULT and error.log`
clauses.

The only work beyond the move was the nine test invocations:

```
test.ossh:3336-3339   private.ossh.dir.push  → ossh.dir.push
test.ossh:3344-3348   private.ossh.id.push   → ossh.id.push
```

Same arguments, same expected RESULT strings — the bodies are unchanged, so the fixtures
prove the public methods now behave exactly as the private ones did.

Guard, docs and counts went with `config.pull`: `for new in …` lost both names, the prose in
`docs/ossh.md` (§ "The copy helpers say theirs too") now names the public methods, the private
rows are gone, and `docs/methods-index.md` is at 90 private / 195 rows / 94 only-dev / 2 339
total.

Verified: `bash -n`; `./ossh dir.push` and `./ossh id.push` argument paths print the expected
errors; `type -t` shows the public functions and no private ones; `test.ossh` 155/155.

## Done 2026-11-05 (3): `dir.pull`, `config.push`, and the keep note

The last two twins were the "production + test" ones, so the move also repointed their callers:

| Caller | Was | Now |
|---|---|---|
| `ossh.install.finish.local` | `private.ossh.config.push $sshConfigName` | `ossh.config.push $sshConfigName` |
| `private.ossh.pull.id` | `private.ossh.dir.pull $fromHost ".ssh"` | `ossh.dir.pull $fromHost ".ssh"` |
| tests `497-521`, `3331-3334` | `private.ossh.config.push` | `ossh.config.push` |
| tests `3340-3343` | `private.ossh.dir.pull` | `ossh.dir.pull` |

The bodies moved into the public methods, the docstrings took the private `rc 0 + RESULT` /
`rc 1 + RESULT and error.log` clauses, and the no-configName skip message inside `config.push`
now names `ossh.config.push` instead of the private one. The guard's `for new in …` list is down
to `private.ossh.oosh.init.push` — the last name in it that is not a collapsed twin.

`config.field.get` got the opposite treatment: a four-line comment above its body records that it
is the low-level getter (no RESULT, consumed as `$(...)` by the per-field accessors and
`ossh.config.set`), not a wrapper — and that mcdonges has the same public/private split.

Final ossh numbers: 10 twins originally, 9 resolved (2 collapsed, 2 deleted as duplicates, 5
collapsed with caller updates), 1 kept by design. `docs/methods-index.md` is at 88 private /
193 rows / 92 only-dev / 2 337 total. `test.ossh` 155/155.

## Order of work

1. ~~**Now, no caller changes:** delete the two `.completion` twins.~~ **Done** — `ca008c60`.
2. ~~**Next, no caller changes:** collapse `config.pull` (drop it from the guard list).~~ **Done.**
3. ~~**Separate change:** collapse `dir.push`, `id.push`~~ **Done** — `d76c8c69`.
4. ~~**Next:** collapse `dir.pull` and `config.push`.~~ **Done** — `96e5584d`;
   `config.field.get` kept with a comment in `b2be95f9`.

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
