# Ticket: repair the `oo method.new` tooling

**Created:** 2026-09-14 · **Branch:** `dev` · **Status:** 💡 Ideas — investigated in depth; **implementation reverted 2026-09-14**
**Found while:** planning T3 (`env -i sh. SAVETY...shall boot correctly`)

## Why this is a ticket

The project mandates a template-driven route for adding methods —
`docs/command-creation.md`: *"Use `oo …` to interactively add new methods to scripts"*;
`docs/first-principles.md`: *"All new scripts and methods are based on templates in
`templates/code/`, enforcing best practices and DRY principles."*

That command exists and is correctly named: **`oo.method.new`** (`oo:75`), with **`oo.test.new`**
(`oo:54`). It was renamed from the verb-first `oo.new.method` in **`2fe5133`** (2026-03-16,
*"refactor: enforce object.verb method naming across all scripts"*), which kept the old names as
`private.*` so they drop out of completion.

**But it cannot currently be run against any script that matters.** Three things rotted around it,
so every method in this tree gets hand-written instead — which is a standing violation of the
project's own methodology, not a style preference.

## Evidence

### 1. The docs never followed the rename

`2fe5133` updated **one** documentation file (`docs/oosh-architecture.md`, 2 lines) — and even that
file still carries stale references. **17 references across 7 files** still name the pre-rename
commands, dead since March 2026:

| File | Lines |
|---|---|
| `oo.md` | 22, 61, 66, 75, 80, 412, 413 — including its own `### oo.new.method` section heading |
| `wiki-index.md` | 102, 117, 118 |
| `oosh-architecture.md` | 549, 550 |
| `oosh.md` | 139, 140 |
| `command-creation.md` | 12 |
| `first-principles.md` | 48 |
| `python.md` | 125 |

Anyone following the documentation types a command that has not dispatched for six months.

### 2. The insertion marker is missing from the core scripts

`private.oo.new.method` inserts via `replace within <script> "### new.method"`. That marker is
**absent** from `config`, `this`, `log`, `debug` and `oo` itself — precisely the scripts under
active work.

### 3. It runs — but mangles what it writes

Corrected from an earlier revision of this ticket: `<script>.new` is **not** a usage-file
convention. It is the *working copy* of the `replace` transaction — `replace within …` writes
`$FILE.new`, `replace commit` swaps it in (`mv $FILE $FILE.bak; mv $FILE.new $FILE`), `replace
cleanup` removes both. `myScript.new` (0 bytes, dated 2026-04-30) is a **leftover from an
interrupted run**, not a convention. There is no step to drop.

Driven end-to-end against a throwaway script (`oo new probeScript` → `oo method.new
probeScript.probeMethod`, four prompts answered), the tool **does** insert — and produces this:

**The test file is generated correctly.** All three test prompts land:

```bash
test.case - "a probe test" \
   probeScript.probeMethod probeArg
expect 0 "probe_ok"
```

**The script is not.** Two defects:

| Defect | Evidence |
|---|---|
| the typed description never reaches the method docstring | inserted as `probeScript.probeMethod()     # parameters # method description # an example` — the template placeholder, unchanged. That docstring is what the **completion engine reads** (`docs/first-principles.md`), so a method created by the tool is born with no usable parameter or description metadata |
| the usage/Examples table is mangled and the description is lost | `private.oo.sed.first "----" …` then `"--------------------------" …` against the `.new` working copy leaves `probeMethod------`, and the typed text appears nowhere in the file |

Plus a spurious warning on Linux: `WARNING> The filesystem is case insensitive and the case
sensitive file … DOES NOT exist!` — on a case-sensitive filesystem, where the file does exist.

So the tool is not missing and not unusable — it is **half-working**, and the half that fails is the
half that carries the DRY metadata. That is very likely why it fell out of use.

## Definition of done

- [ ] All 17 stale references corrected to `oo method.new` / `oo test.new`
- [ ] `### new.method` marker present in `config`, `this`, `log`, `debug`, `oo`
- [ ] The typed description reaches the **method docstring** — the metadata the completion engine reads
- [ ] The usage/Examples table is written correctly, not mangled (`probeMethod------`)
- [ ] The spurious case-sensitivity warning is gone on a case-sensitive filesystem
- [ ] The stale `myScript.new` leftover is removed
- [ ] `oo method.new <script>.<method>` runs end-to-end against a core script, generating the method
      from `templates/code/newMethod` **and** its test case from `templates/code/newMethodTest`
- [ ] A test pins **documented command names against what the scripts actually define**, so this
      cannot drift silently again
- [ ] Standing verification bar passes

## Scope note — this is probably not only `oo`

`2fe5133` renamed 57 methods across 7 scripts (its message: `ossh` 17, `backup` 13, `scrumMaster`
10, `oo` 7, `c2` 6, `user` 3, `config` 1) and updated 2 lines of documentation. The other six
scripts' docs are likely stale the same way. The name-pinning test in the DoD is what turns that
from an open-ended audit into a finite, enforced list — write the test first and let it enumerate
the drift.

## Verification

```bash
# no stale names remain
grep -rn 'oo\.new\.method\|oo new\.method\|oo\.new\.test\|oo new\.test' docs/

# the tool runs end-to-end
oo method.new config.someProbe && grep -n 'config.someProbe' config test/test.config

# and the guard catches a reintroduced drift
./test.suite run oo 1 && ./test.suite core 1
```

## Implementation reverted (2026-09-14)

This was built (`0428dca`, `f2ae994`, `cc6078a`) and then **reverted** along with the rest of the
day's code, because an unrelated regression appeared in the same window and could not be isolated —
see the boot-tickets tracker. **The findings below stand**; only the code is gone. Redoing it is a
matter of re-applying known changes, not re-investigating.

One further defect, found by *using* the tool and worth having on record:

- **It cannot create multi-segment method names.** `oo method.new config.env.init` produced
  `config.env()` and silently dropped `.init`, because the name is split with `cut -d. -f2`. Yet
  noun.verb naming inherently produces multi-segment methods (`oo.mode.base.get`,
  `config.init.user`) — so the tool cannot create the very naming style the project mandates.
  One-line fix: split on the FIRST dot (`${name%%.*}` / `${name#*.}`).
- The **test** half needs `### test.method` markers, absent from every core test file; without them
  it reports success and inserts nothing.

## Was delivered, now reverted

| Commit | What |
|---|---|
| `0428dca` | **`this.help` restored.** `line.quote` now escapes apostrophes (one apostrophe in one docstring had been killing `help` for an entire script — `config`, `this`, `oo`, `ossh`, `user` all affected), and the format init is guarded on **content** not existence (`lineFormat.env` existed at 0 bytes, so the init was skipped forever and `FORMAT_HELP` stayed unset). `line.unquote` mirrors the escaping — caught by `c2` going 23/23 → 22/23, not by reasoning. |
| `f2ae994` | **The docstring became the single source.** `templates/code/newScript` drops the per-method table; `oo method.new` writes the typed parameters + description into the method docstring instead of patching that table. Plus `check`'s `find` now follows a symlinked start dir — it had been warning "file DOES NOT exist" for every `check file $OOSH_DIR/<x>` since `OOSH_DIR` became the `~/oosh` symlink in T4+T5. |
| this commit | Markers, stale docs, and the drift guard. |

**Extra defect found and fixed along the way** (not in the original evidence): `docs/oo.md`
documented an entire `### oo.mode.dev` section for a method that does not exist — the command is
`oo mode <branch>`, the branch being an argument. The new drift guard found it.

**Still open:** `config save lineFormat "FORMAT_"` writes a 0-byte file, so the format init now
re-runs every shell rather than once. Harmless, and it is why `lineFormat.env` was empty in the
first place — but it is a separate defect in `config.save`'s prefix matching, not in `line`.

## Relationship to T3

T3's design (`docs/superpowers/specs/2026-09-14-oosh-recovery-from-bare-shell-design.md`) needs
`config.env.init` generated through this tooling. T3 is **blocked on this ticket** for the
*generation* step, though its design work can proceed in parallel.
