# Private methods — inventory, unused ones, and how to reduce them

Reference: [`docs/this.md`](this.md) defines the method model and keeps the private methods in
their own section (`| **=== private ===** |`), and [`docs/methods-index.md`](methods-index.md)
counts public/private per script. This page uses those conventions and measures `origin/dev` at
`7ab831d9`.

## 1. What `private.` means in this tree

From `docs/this.md`: every method is `<script>.<object>.<verb>[.<more.words>]`, the verb is last,
and the matrix separates **public** from **private**. A `private.*` method is the implementation
layer of exactly one script:

- it is **not** part of the object.verb contract, and it is **not** in the public matrix;
- it may change or disappear without a deprecation, because no caller outside its script should
  name it (see §4 for the scripts that already break this rule);
- completion hooks (`*.completion.<parameter>`) are private but **called by the completion engine**,
  so they are not dead even when `grep` cannot see a call.

`docs/methods-index.md` last measured 2 344 documented methods on 2026-10-20 (e.g. `otmux` 226
public / 93 private, `this` 27 / 34). The live tree is larger; the counts below are parsed from
the sources, both `name()` and `function name` forms.

## 2. Inventory (`dev`)

| Metric | Count |
|---|---:|
| Top-level methods | 3 954 |
| … public | 3 074 |
| … **private** | **880** (22 %) |
| private completion hooks | 26 |
| `*.darwin` / `*.linux` pairs (same method, two OS bodies) | 15 pairs (30 methods) |
| private methods called from **another script** | 295 |
| private methods called exactly **once** | 245 |

Per script (private methods, scripts with 10+):

| Script | private | Script | private |
|---|---:|---|---:|
| `hiveMind` | 135 | `state` | 26 |
| `otmux` | 97 | `claudeCode` | 23 |
| `ossh` | 80 | `docker` | 22 |
| `odocker` | 64 | `su/setup` | 22 |
| `check` | 49 | `user` | 22 |
| `test/*` scripts | 44 | `backup` | 18 |
| `config` | 36 | `ogit` | 18 |
| `oo` | 33 | `private.get.*` | 13 |
| `this` | 33 | `promote` | 12 |
| `scrumMaster` | 30 | rest | 62 |

## 3. Which are not in use

21 methods have **no call site in tracked code** (only their definition, and in some cases a
mention in a comment or doc):

| Method | Definition | What it was for |
|---|---|---|
| `private.claudeCode.projectHash` | `claudeCode:78` | encode a workspace path to a project-dir hash |
| `private.hiveMind.create.agent.pane` | `hiveMind:1523` | pane creation step of the old spawn |
| `private.hiveMind.pane.activity` | `hiveMind:1228` | classify pane activity |
| `private.hiveMind.pane.kind` | `hiveMind:3414` | classify pane: claude / shell / monitor / unknown |
| `private.hiveMind.pane.model` | `hiveMind:3435` | model flag from a running claude's ps args |
| `private.hiveMind.workers.legacy` | `hiveMind:2019` | worker list via agentRoom / pane titles |
| `private.oo.dev.to.testing` | `oo:787` | promote dev to testing, gated by core tests |
| `private.ossh.dir.push.completion` | `ossh:3097` | old whole-method completion |
| `private.ossh.get.current.key.file.name` | `ossh:1943` | predecessor of `private.ossh.get.file.name` |
| `private.ossh.get.server.port.wrapper` | `ossh:2413` | two-line wrapper |
| `private.otmux.capturePane` | `otmux:560` | camelCase predecessor of `otmux.pane.capture` |
| `private.otmux.configPath` | `otmux:1087` | config file location |
| `private.otmux.detachClient` | `otmux:1001` | detach a client |
| `private.otmux.showMessages` | `otmux:2272` | show server messages |
| `private.otmux.socketPath` | `otmux:2314` | use a specific socket path |
| `private.otmux.swapPane` | `otmux:480` | swap two panes |
| `private.platform.sshd.reload` | `platform:67` | sshd re-exec (odocker has its own copy) |
| `private.scrumMaster.subscription` | `scrumMaster:1360` | pre-`subscription.api.*` monolith |
| `private.scrumMaster.subscription.api.legacy` | `scrumMaster:1918` | the same, self-described legacy |
| `private.testNames` | `otest:709` | thin python-discovery shim (only `.camel` is used) |

### The `private.isPaneTarget` case — why "dead" needs a caller check

`otmux:1345` defines `private.isPaneTarget`; **no code calls it**. But 10 places call
**`this.isPaneTarget`**, a kernel predicate that `dev` never had:

```
claudeCode:435,494,527,999      if ! this.isPaneTarget "$pane"; then … "invalid pane"; return 1
hiveMind:2458,2821,5042,5066,5097,6924                     this.isPaneTarget …
otmux:1345                      private.isPaneTarget() { … }        ← the only definition, unused
```

Bash answers `this.isPaneTarget: command not found` (rc 127); the guard is `if ! …`, so it is
always true and **every** pane — valid or not — is rejected as invalid.

Provenance:

| Commit | What it did |
|---|---|
| `1b759c5a` | added the five SC-E.2 ingress predicates to `this` (`isPaneTarget`, `isUuid`, `isRoleName`, `isSessionName`, `isPipeSafe`) — **not an ancestor of `dev`** |
| `b745e766` (mcdonges, *"fixed this.is.... bloating"*) | commented the predicates out in `this`, copied them into `otmux` as `private.*`; mcdonges later switched its callers to `private.claudeCode.*` / `private.hiveMind.*` |
| `bf1ebe5a` (dev, *"updated agent tools from mcdonges"*) | imported claudeCode/hiveMind/otmux and added the `this.is…` calls — without touching `this` and without the per-script copies |

It is not one method: the same import left **47 dangling calls** across five predicates, and only
two of the five have any implementation on `dev` (both dead copies in `otmux`):

| Predicate | Calls on `dev` | Implementation on `dev` |
|---|---:|---|
| `this.isPaneTarget` | 10 (claudeCode 4, hiveMind 6) | only `otmux`'s unused `private.` copy |
| `this.isSessionName` | 13 (hiveMind) | only `otmux`'s unused `private.` copy |
| `this.isPipeSafe` | 13 (hiveMind) | **none** |
| `this.isRoleName` | 8 (claudeCode 1, hiveMind 7) | **none** |
| `this.isUuid` | 3 (claudeCode 2, hiveMind 1) | **none** |

The tests that pin this were mcdonges-only until §6e ported them — `test/test.claudeCode-validators`
and `test/test.hiveMind-validators` — and their header is the measurement:

> BUG (measured): b745e766 commented out this.isUuid / this.isPaneTarget / this.isRoleName in
> `this` … `if ! this.isUuid …` = command-not-found → EVERY input is rejected: join.byID,
> join.byPane, fork, fork.byPane, fork.to, stop.

`dev` carried neither file, so `core` stayed green while the guards rejected everything. Removing
`private.isPaneTarget` alone would therefore fix nothing and break nothing — the delete and the
restore have to happen together. §6 is the exact procedure.

### Why 21 and not 104

A raw "name appears once" scan flags 104. The other 83 are called **dynamically** and must not be
touched without reading the dispatcher:

| Dispatcher | Shape | Covers |
|---|---|---|
| `state` (`state:282,288,416,491`) | `private.check.$stageTo` | all `private.check.*` |
| `os.check` (`os:14`) | `private.<name>.$OSTYPE` → `.darwin` / `.linux` | every OS-paired method |
| completion engine (`ng/c2:585`) | `$class.$method.completion.$parameter` | every `*.completion.*` |
| `ossh config.set/field.get` (`ossh:207,244`) | `private.ossh.config.$field.{get,set}` | all per-field ossh accessors |
| `user` (`user:531`) | `private.get.$property` | `private.get.{basehome,home,info,name,shell}.*` |
| `init/once` (`:2810,4234,4253`) | `private.state.$state`, `private.docker.scenario.$action.$DOCKER_SCENARIO` | state machine, docker scenarios |

Anything else can be proven dead with a word-boundary grep (see §6).

## 4. How to reduce the number of private methods

**L1 — delete the 21 dead ones (§3).** 880 → 859. Fix the four `this.isPaneTarget` callers in
the same change. This is the only lever with zero behavioural risk.

**L2 — inline single-call methods (246 candidates, 86 of them thin wrappers).** A private method
whose only caller is in the same file adds a frame and a name. Inline the one-liners first:

```bash
private.ossh.get.server.port.wrapper() { private.ossh.get.server.port "$@"; }   # inline
```

Do **not** inline when it is a test seam (tests call it by name), when it names a step that the
docstring explains, or when it normalises the `RESULT`/rc contract. 246 is an upper bound, not a
target.

**L3 — fix the 295 cross-script privates.** A private method called from another script is either
public API in disguise or code in the wrong file. Two outcomes:

- promote it to a public `<object>.<verb>` and regenerate the matrix (`oosh-architect`), or
- move it to the script that owns the behaviour.

The biggest offenders are the shared toolkit (`private.this.path.canonical` 63 calls from
`config`, `odocker`, `ogit`, `oo`; `private.this.path.stat.get` 29; `private.this.temp.dir.get`
21; `private.this.file.write` 20) — that is a legitimate internal library, so document it as such
(a `private.this.* = shared toolkit` note in `docs/this.md`) instead of pretending it is private.
Then the real outliers: `private.ossh.ssh` (34, used by odocker), `private.config.homes.list`
(28, used by test.config), `private.as.user` (26, used by oo/setup).

**L4 — merge OS pairs (15 pairs → 15 methods).** Each `.darwin`/`.linux` pair costs two names for
one behaviour. A single function with a `case "$OSTYPE"` inside removes 15 methods, at the price
of the `os.check` idiom. Only worth it where the two bodies are short and stable.

**L5 — leave completion hooks alone (26).** They are dispatch targets of the completion engine,
not dead code, even though no literal call exists.

## 5. Safe removal procedure (per method)

```bash
cd ~/oosh
S=ossh; M=private.ossh.get.server.ip          # script and method

# 1. word-boundary proof (not substring: private.a.b must not match private.a.b.c)
git grep -nw "$M" -- . ':!docs/*.md'

# 2. dynamic dispatch? (see the table in §3; if the name is under one of those
#    prefixes, stop — it is resolved through a variable)

# 3. the repo's own remover: drops the function and its completions and reports
#    the tests that still name it
./oo method.delete "$S.$M"

# 4. the branch that may still call it (the deployed line is a different tree)
git grep -nw "$M" origin/test/mcdonges.latest -- .

# 5. gates
./test.suite core 1
./test.suite run "$S" 1
```

`oo method.delete` (`oo:3382`) is the intended tool: it removes the method and every
`<method>.completion.*`, and reports the test cases that reference it, so step 3 doubles as a
caller check for the test suite.

After a batch: regenerate the matrices (`docs/this.md`, `docs/methods-index.md`,
`docs/object-verb-index.md`, `docs/parameter.md` are generated by `oosh-architect`), otherwise
the docs and the code drift.

## 6. Case study — removing `private.isPaneTarget` completely

The deletion is one line; "completely" means the 10 callers keep working, so the home of the
predicate is decided first.

### 6a. Home in `this` (recommended)

1. **Restore the five predicates in `this`** — bodies from `1b759c5a`, next to `this.isNumber`:

   ```bash
   this.isPaneTarget() {
     # canonical session:window.pane, or a raw pane id %N
     [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_.-]*:[0-9]+\.[0-9]+$ ]] || [[ "$1" =~ ^%[0-9]+$ ]]
   }
   this.isSessionName() { [[ "$1" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]*$ ]]; }
   this.isRoleName()    { [[ "$1" =~ ^[A-Za-z][A-Za-z0-9._-]{0,39}$ ]]; }
   this.isUuid()        { [[ "$1" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; }
   this.isPipeSafe()    { [[ "$1" != *"|"* && "$1" != *$'\n'* ]]; }
   ```

2. **Port the red-first tests from mcdonges** (they are the proof, not decoration):

   ```bash
   git show origin/test/mcdonges.latest:test/test.claudeCode-validators > test/test.claudeCode-validators
   git show origin/test/mcdonges.latest:test/test.hiveMind-validators  > test/test.hiveMind-validators
   chmod +x test/test.claudeCode-validators test/test.hiveMind-validators
   ```

   Run them **before** step 1 if you want the red: they fail with `command not found`; after
   step 1 they pass. If they pass before, the predicates were restored by something else.

3. **Delete the copies in `otmux`.** `private.isPaneTarget` (`:1345`) is dead;
   `private.isSessionName` (`:1339`) was still called by `otmux.fit` (`:1361`), so repoint that
   caller to `this.isSessionName` first.

   Neither `oo method.delete` form reaches these legacy names: `otmux.private.isPaneTarget` greps
   the full dotted name in the file, and `private.isPaneTarget` has no script segment. `replace
   block` also refuses when the end pattern (`}`) is not unique. The exact-range removal that
   works, and that was applied:

   ```bash
   sed -i 's/private\.isSessionName "\$session" ||/this.isSessionName "$session" ||/' otmux
   for fn in isPaneTarget isSessionName; do
     awk -v fn="$fn" '
       $0 == "private." fn "() {" { skip = 1 }
       skip && $0 == "}"       { skip = 0; next }
       !skip
     ' otmux > otmux.new && mv otmux.new otmux
   done
   ```

4. **Prove the removal:**

   ```bash
   git grep -nw private.isPaneTarget -- .    # no code hit (docs may still mention it)
   git grep -nw this.isPaneTarget -- .       # exactly one definition + the 10 callers
   bash -c 'source this; type -t this.isPaneTarget'   # function
   ```

5. **Gates:**

   ```bash
   ./test.suite core 1
   ./test.suite run claudeCode 1
   ./test.suite run otmux 1
   ./test.suite run hiveMind 1     # extended: needs a live tmux, may skip on a bare host
   ```

6. Regenerate the matrices (see §5), or `docs/this.md` keeps listing the old set.

### 6b. Home in `otmux` (not recommended)

Rename the private copy to a public `otmux.pane.target.is`, point the 10 callers at it, then delete
`private.isPaneTarget`. It works, but it makes a kernel predicate an `otmux` dependency and leaves
`isUuid` / `isRoleName` / `isPipeSafe` still undefined. Choose it only if `otmux` is meant to own
pane validation.

### 6c. Acceptance — what "completely removed" means

- `git grep -nw private.isPaneTarget -- .` returns no code hit;
- the five `this.is*` exist and `type -t` says `function`;
- `test.claudeCode-validators` and `test.hiveMind-validators` pass, and **fail again** if the
  definition is commented out (that is the regression guard);
- `claudeCode join.byPane '%0'` no longer answers "invalid pane";
- none of the five predicates is left without a definition (the table in §3 is fully covered).

### 6d. Why not just delete it

Deleting `private.isPaneTarget` without step 1 leaves the 10 callers resolving `this.isPaneTarget`
to nothing — the bug is unchanged, only the "dead method" disappears from the report. The same
holds for `private.isSessionName`; `isUuid`, `isRoleName` and `isPipeSafe` have no implementation
to delete at all.

### 6e. Applied (2026-11-03)

- `this` now defines the five predicates right after `this.isEmpty` (`isPaneTarget`,
  `isSessionName`, `isRoleName`, `isUuid`, `isPipeSafe`) — 5 new **public** methods, one home.
- The two validator tests were ported from mcdonges and run red first: `this.isUuid: command not
  found` + "join.byID REJECTED valid …", then green.
- `otmux`: `private.isPaneTarget` deleted; `private.isSessionName`'s only caller (`otmux.fit`)
  repointed to `this.isSessionName` and the copy deleted.
- Results: `test.claudeCode-validators` **33/33**, `test.hiveMind-validators` **16/16**,
  `test.otmux` **45/45**, `test.this` **71/71**, `test.ossh` **154/154**.
- Inventory after the change: **880** private, **21** dead.
- Still open: the generated matrices (`docs/this.md`, `docs/methods-index.md`,
  `docs/object-verb-index.md`) do not list the five yet — regenerate them; and the two validator
  tests have no `TEST_CATEGORY`, so they run under `extended`, not `core`.

## 7. Suggested order

| Step | Change | Private count |
|---|---|---:|
| 1 | delete the 21 dead; the `private.isPaneTarget`/`isSessionName` pair is already done (§6) | 880 → 859 |
| 2 | inline the top ~20 thin wrappers (not test seams) | → ~840 |
| 3 | resolve the loudest cross-script privates (ossh.ssh, config.homes.list, as.user) | → ~837 |
| 4 | decide the `private.this.*` question: document as internal library, or promote | unchanged, but the rule becomes honest |
| 5 | merge OS pairs where the bodies are ≤5 lines | → ~822 |

Step 1 is mechanical and safe. Everything after it trades a name for a decision, so do it per
script with its test file, not repo-wide in one sweep.

## 8. Caveats

- "Dead" here means *no call site in tracked code on `dev`*. A method may still be called by the
  other branch (`mcdonges`), by a user's own script, or through one of the dispatchers in §3.
- The scan counts `name()` and `function name` definitions at column 1. A function defined inside
  another function, or built with `eval`, is not seen.
- `test/` call sites count as usage, so a method kept alive only by its test is not listed as dead
  (none of the 21 have that shape).
- The initial inventory was measured at `7ab831d9`; the §6 change (five predicates restored, two
  private copies deleted) is applied on top, which is why the totals read 3 954 / 3 074 / 880.
  The per-script numbers in `docs/methods-index.md` are from 2026-10-20 and are lower.
