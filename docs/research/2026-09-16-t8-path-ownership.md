# T8 — research: who owns `PATH`

**Written 2026-09-16 · Branch `dev` (`97ad59c`) · Status: research only, no code.**
**Card (Ideas):** `review hot PATH is bootstrapped` · `PATH=` · `and the path script`

Ticket: [boot tickets tracker](../plans/2026-09-10-oosh-boot-tickets.md) § T8 ·
[board backlog](../plans/2026-09-15-board-backlog.md) § 5.

`OOSH_DIR` and `CONFIG_PATH` each got a stated rule, a marker syntax, a validator and
planted-violation tests out of T4+T5 ([boot.md § The path-anchor rule](../boot.md)). `PATH` got
none of that. `boot` builds it correctly and is not the only thing that builds it; nothing says it
should be; and the one script named after `PATH` has no production callers at all.

**Everything below was re-checked against the tree today. Six claims in the ticket did not
survive.** That is the main reason this document exists before any code.

---

## 1. Corrections to the ticket

| The ticket says | What is actually true |
|---|---|
| "one of **five** mechanisms" | Five *named* ones. The real count of independent PATH writers in tracked production code is **eleven** — see § 2. |
| `this.path.add` "invoked five times" | **Six** (`this:1236-1243`); the sixth is `$OOSH_DIR/su`, root only. |
| `this.path.add "."` "puts the current directory **first** on PATH" | **It does not.** Each call *prepends*, so later calls land in front of earlier ones and `.` ends up **fourth**. Still serious — § 4. |
| `ossh` holds "a duplicate of the same block" | Semantically equivalent, **not a duplicate**: one line vs five, `export` inside the `case` rather than outside, and **no `$BASH_FILE` block at all**. A rule saying "`boot` stays byte-identical" would require rewriting one of the two first. |
| `config.save` never persists PATH — "`config:559-561`" | The conclusion is right, the mechanism and the lines are not. PATH is stopped by the **inclusion gate** (`config:591`), never reaching the exclusion list at `config:595`. The cited lines are now dead commented-out code. |
| the shared-config finding is an open defect | **Closed**, by backlog ticket 1 and T7's `config.init` fix (`325c4e5`). `test.suite:848-851`'s own comment describing the old behaviour is now stale. |

---

## 2. Every PATH writer

Five named mechanisms, eleven actual writers. One methodological note first: the default `grep`
in this environment honours `.gitignore`, which **silently hides `init/once`** — it has 21 `PATH=`
hits and is invisible to a plain `grep -rn`. Use `command grep` for this audit.

**Builders and extenders, production:**

| Site | What | Guarded? |
|---|---|---|
| `boot:103-109` | `$OOSH_DIR:$OOSH_DIR/ng` prepend | yes, colon-anchored |
| `boot:110-117` | `dirname $BASH_FILE` prepend | **front-anchored only** — § 3 |
| `ossh:3555` (`ossh.start`) | same prepend, one line | yes, colon-anchored |
| `this:46` (file scope) | `PATH="$OOSH_DIR:$PATH"` | no, but self-limiting |
| `this:966` (`this.path.add`) | `export PATH="$OOSH_DIR:$PATH"` | **no** |
| `this:951-999` | the `this.path.add` chain, six call sites | de-dupes by unanchored `grep -v` |
| `this:580` (`this.init`) | restores PATH across a mid-session `source "$CONFIG"` | n/a |
| `init/oosh:384-392`, `:395-409` | brew-bash and `command -v bash` prepends | yes |
| `init/oosh:563` | `export PATH="$OOSH_DIR:$PATH"` | **no** |
| `oo:893`, `:909`, `:2248` | branch-name rewrites via `sed` / `line replace.sedquoted` | conditional |
| `oo:2745`, `:2764` | `ONCE_LOAD_DIR` append, brew dir prepend | **no** |
| `ossh:884`, `user:955`, `user:984` | prepends inside remote / `$SUDO bash -c` strings | **no** |
| `hiveMind:1762`, `:1783`, `:1788` | prepends inside `ossh exec` strings | **no** |
| `claudeCode:628` | install-dir append | yes |
| `init/once` (gitignored) | legacy ONCE builders, incl. a wholesale replacement | **no** |

**Sanctioned degrade branches — five, plus the template.** `ossh:2530`, `ossh:2549`, `user:135`,
`user:156`, `user:180` all carry the byte-identical
`[ -f ~/oosh/boot ] && . ~/oosh/boot || export PATH=~/oosh:~/oosh/ng:$PATH`, and
`templates/user/bashrcTemplate:191-200` carries the `elif [ -d "$HOME/oosh" ]` form. The ticket's
count is right. Documented at [boot.md § Cross-branch note](../boot.md) and pinned structurally by
`test/test.config:1252-1276` (T49) — which proves *presence* only, so it would still pass with one
of the five deleted.

**These five are not colon-guarded**, so a genuine `boot` failure duplicates entries. Already
recorded as a follow-up at `docs/plans/2026-09-10-oosh-boot-tickets.md:540-541`; cite it rather
than rediscovering it.

### A writer the ticket does not mention at all

`claudeCode:605-615` **writes `export PATH=…` into a config env file.** It is the one live writer
that still believes env files carry PATH. Env files have been pure data since the boot-loader
migration, `config.validate` exists to enforce exactly that, and this appends to one. Worth its own
line in whatever T8 becomes.

---

## 3. `boot` is right, with one claim that is not

`boot:103-109` is exactly what the rule should say: `case ":$PATH:"` against `*":$OOSH_DIR:"*` is a
true segment test, so a pre-seeded `$OOSH_DIR` anywhere in PATH is neither moved nor duplicated.

`boot:110-117` is different. Its guard is `case "$PATH" in "$_oosh_bashdir:"*` — **anchored to the
front of PATH only**. If `$BASH_FILE`'s directory is present but not first, `boot` prepends it
again. That is deliberate, because brew bash must beat the `/bin/bash` that macOS `path_helper`
appends. But it means the claim *"re-sourcing `boot` never grows PATH"* — stated at `boot:13-15`
and in [boot.md § Idempotent](../boot.md) — is **false** in precisely that case, and the case is
reachable: block 1 prepending `$OOSH_DIR` pushes the bash dir back one position.

Either the behaviour or the claim has to give way. That is open question 3.

**Not open:** `boot` touches PATH even when `~/oosh` is absent. Its only guard is
`[ -n "$OOSH_DIR" ]`, and `OOSH_DIR` was set unconditionally 36 lines earlier at `boot:67`. This
was decided under T9, with reasoning, at
`docs/plans/2026-09-14-fixed-system-boot-path.md:264-295` and shipped at
[boot.md § The three recovery routes](../boot.md): a `[ -d "$OOSH_DIR" ]` guard inside `boot` would
also skip PATH **during install, before `~/oosh` exists**. The existence gate lives instead in
`templates/user/profile.d.oosh.sh:27-31`, which install state 34 owns. Cite; do not reopen; do not
edit that template.

---

## 4. `this.path.add "."` — what it actually does

`this:1238`, inside a block gated on `case "${0##*/}" in "init"|"oosh"|"log"|"this")`. Because
`this.path.add` prepends, the head of PATH after the chain is:

```
$OOSH_DIR/su : $OOSH_DIR/ng : $OOSH_DIR : . : $OOSH_DIR/init : $OOSH_DIR/external : <inherited>
```

So `.` is **fourth**, not first. It is still an untrusted search path (CWE-426), and the shape of
the risk is worth stating exactly, because it cuts both ways.

**Smaller than it looks:** an interactive login shell has `${0##*/}` of `bash`, and `source this`
from `ossh`, `config`, `path` or a test leaves `$0` as the *host* script. The chain fires only when
`this` or `log` — or a script literally named `init` or `oosh` — is **executed**.

**Worse than it looks:** because oosh's own tools resolve from `$OOSH_DIR` first, **the hijack is
silent**. `oo`, `ossh` and `config` keep working normally while every system tool they shell out to
— `git`, `curl`, `tar`, `sudo`, `python3` — resolves from whatever directory the user last `cd`'d
into, since `.` sits ahead of all of `/usr/local/bin`, `/usr/bin` and `/bin`. Root gets the same
treatment via `$OOSH_DIR/su`.

One implementation detail that must survive any edit: `this:975` rewrites the argument to `"\."`
for the `line.remove` de-dupe pass only. Without that escape, `grep -v .` would delete the entire
PATH.

---

## 5. `this.path.add` itself

It has **no signature comment**, so it is invisible to `test/test.completion.audit` and absent from
every usage table — while `docs/oosh-architecture.md:365` lists it as a public method of `this`.
By the Method Structure Standard (`docs/oosh-architecture.md:122-124`) that makes it broken as it
stands, independently of what it does.

Its de-dupe is `line.remove` (`line:161-167`) → `grep -v "$1"`, an **unanchored regex**. So
`this.path.add "$OOSH_DIR"` removes every entry *containing* that substring — `$OOSH_DIR/ng`,
`/init`, `/external`, `/su` included. That is why the six calls are ordered as they are: the chain
is order-fragile by construction rather than idempotent.

It also ends in `line.into PATH` → `result.into` (`this:715-721`), which writes a bare unquoted
`PATH=<value>` into `$CONFIG_PATH/result.env`. A PATH containing a space or a glob character
corrupts on any later `result.load`.

---

## 6. The `path` script

**Zero production callers.** Nothing in `oo`, `ossh`, `os`, `user`, `config`, `state`, `promote`,
`boot`, `init/oosh`, the templates or CI invokes `path` or any of its methods. The only consumers
are tests:

- `test/test.path:26` — `source path`, the one sourcing consumer;
- `test/test.c2:162-177` — uses `$OOSH_DIR/path` as a **completion fixture**, depending on
  `path.parameter.completion.dir` and on `path.prepend`'s `<dir>` **signature comment**;
- `test/test.completion.audit` — sources `path` on every run, because it is in scope.

Structurally it is a well-formed oosh script: `### new.method` marker (`path:8`), `path.usage`,
`path.start`, two `path.parameter.completion.*`. Twelve of its twenty-two methods carry signature
comments; `./c2 function.completion ./path` currently offers twenty-one verbs. **Fourteen of its
methods have no test at all.**

What does not work:

| Family | State |
|---|---|
| `path.file.global`, `.global.use` | target `/etc/paths` — **macOS only**, absent on Linux. macOS also has `/etc/paths.d/`, which `init/oosh:332-335` writes and `path` knows nothing about |
| `path.file.user`, `path.save`, `path.load`, `path.edit` | target `~/paths`, which exists only if `path save` created it |
| `path.show.oosh.path` | greps `$CONFIG` for `^export PATH=`. **No generated env file has contained that line since the env-file migration** — `config:606-614` says so by design. Returns empty with rc 0 |
| `path.show.once.path` | reads `~/.once`, which does not exist |
| `path.status` | compares two values read back from `result.env` after `check` ran in a **separate process** that never called `result.save`. It compares stale data against stale data and typically prints *"all well configured"* |
| `path.sync` | calls `once path.use.oosh` — `init/once` is **gitignored**, so it exists on no other machine, and it replaces PATH wholesale with a hardcoded layout containing literal `\$ONCE_REPO_PREFIX` placeholders |
| `private.pathadd`, `private.pathrm` | correct code, **zero callers** |
| `path.usage` | advertises `add`, `push`, `put`, `rm` — **none of which exist**. `path add /x` reaches `this.methodNotFound` |

What half-works — `path.append`, `path.prepend`, `path.remove`:

- Invoked as `path append /x` they mutate **a child process** and exit. The parent shell is
  untouched. They mutate a caller only under `source path`, which is exactly and only what
  `test/test.path` does.
- They claim to persist, twice: the docstrings say "and saves config", and
  `private.update.config` prints *"Path updated in OOSH config: $CONFIG"* and tells the user to run
  `reconfigure`. Nothing can restore a PATH that was never written.
- `line.filter` and `line.remove` are unanchored `grep -v`, so **`path remove /usr` deletes
  `/usr/bin`, `/usr/local/bin` and `/usr/sbin`**. "Removes duplicates" is an over-claim; it removes
  matches.

`private.update.config` (`path:240-263`) is worth reading in full. `config` is **not sourced** by
`path` (`path:295` has `#source config` commented out), so its `config save` is an **external
command** that rewrites the tier from a child's own environment. It also contains dead code with a
bug: `[ -z "list" ]` tests a non-empty string literal, so it is always false — had it been
`[ -z "$list" ]` it would have been true and blanked PATH outright.

**Correction to a neighbouring ticket:** the backlog's 44-function `create.result` list names
`path`. That is wrong — all three of its `create.result` calls (`path:60`, `:175`, `:184`) are
immediately followed by `return $(result save)`.

---

## 7. What T8 should establish

**`boot` is the single builder. Everything else delegates, or is a documented degrade branch.**
Modelled on the anchor rule, because that precedent is complete, tested, and already generic:

| Piece | Anchors today | PATH equivalent |
|---|---|---|
| stated rule | [boot.md § The path-anchor rule](../boot.md) | a sibling section |
| marker | `# oosh-dir-exception:` / `-exception-file:` | `# path-exception:` — `private.this.anchor.validate.one` already derives the slug from the variable name (`this:189`), so no new syntax |
| validator | `this.anchor.validate` + `private.this.anchor.validate.one` (`this:180-304`) | a sibling method |
| proof | planted violations in a throwaway git repo, `test/test.this:463-534` | the same mechanism, verbatim |

**What "conforming" means is different, and this is the design answer.** The anchor validator
matches a *constant*: `OOSH_DIR` is `$HOME/oosh` and anything else is a violation. `PATH` is an
*accumulation*, so no value test is possible. The rule can therefore only be about **who may
write it** — which makes the validator a **writer sweep** with an exception marker, not a value
check. Concretely: any `PATH=` or `export PATH=` assignment outside `boot` is a violation unless it
carries `# path-exception: <reason>`. The five degrade branches and the template fallback get
markers; `boot` is the one conforming site.

One wrinkle a copy would inherit: at `this:288-289`, `[ $? -eq 0 ]` reads the status of an
**assignment**, not of the command substitution inside it. It works today only because the right
hand side is a bare substitution, and the test pins the verdict *text* rather than the rc. Do not
propagate it silently.

---

## 8. Conformance of what is proposed

The proposals above are checked against the methodology before being proposed, not after.

- **Any new method is created with `oo method.new <script>.<method>`**, not by hand. The
  template-driven route is mandated by `docs/first-principles.md:49` and
  `docs/command-creation.md:12`, and it **works again as of this week** (`e4842d0`): multi-segment
  names, the typed docstring, and a completion stub per parameter all land. Hand-writing one now
  needs a stated reason in the commit.
- **Method Structure Standard, MANDATORY** (`docs/oosh-architecture.md:122-124`): object.verb name,
  doc comment, typed parameters, completion functions. A validator gets its
  `…validate.completion.*` alongside, exactly as the four anchor forms do.
- **Result contract**: `create.result` on every branch, `return $(result)` last. The two exemptions
  are stated rather than assumed — a getter consumed as `$(...)` runs in a subshell and must answer
  on stdout, and a completion function must never call `create.result` at all.
- **Status-output idiom**: the verdict is `echo`ed so it survives any `LOG_LEVEL` or `LOG_DEVICE`,
  as `config.validate` and `this.anchor.validate` already do.
- **OOSH commands before raw bash**: the sweep is one `git grep` inside a method, reusing the slug
  derivation and pathspec that already exist; nothing re-implements `line`, `check` or `config`.
- **Deletions are method-shaped too**: anything removed from `path` goes with its docstring, its
  completion function and its test, rather than by deleting lines.

---

## 9. Housekeeping to fold in

- **`test/test.config` has two tests numbered T24** — `:449-465` (config.set normalisation) and
  `:578-593` (the PATH one).
- **The PATH T24 cannot fail.** It greps `boot` for `":$PATH:"` and `":$OOSH_DIR:"`. Both literals
  **also appear in `boot`'s own comment at `:101`**, so it would pass with the `case` statements
  deleted. [boot.md](../boot.md) advertises it as pinning PATH idempotency; it does not. **Nothing
  anywhere sources `boot` and inspects the resulting `$PATH`** — not for content, not for ordering,
  not across a double source.
- **`test/test.path`'s `path.usage` assertion cannot fail either** (`:196`): its second disjunct is
  `[ $RETURN_VALUE -eq 0 ]`, satisfied by almost any outcome.
- **`docs/config.md:201`** names `bashrcTemplate` as the PATH builder via `this.path.add`.
  `bashrcTemplate` has contained no such call since the boot-loader migration; its only PATH action
  is the degrade `elif`.
- **`docs/oosh-architecture.md:404`** advertises `path add`, a verb that has never existed.

---

## 10. Baselines, for the implementation to move from

Measured on `97ad59c`, host, before any T8 change:

| File | Assertions |
|---|---|
| `test.this` | 32 / 32 |
| `test.config` | 70 / 70 |
| `test.path` | 13 / 13 |

`./c2 function.completion ./path` currently offers 21 verbs.

---

## 11. Open questions

The first two are **coupled** and should be answered together.

1. **Does `path` survive?** A read-only reporting tool, or deleted outright. There are no
   production callers either way. Deleting it costs `test/test.c2:162-177`, which uses
   `path prepend`'s signature as a completion fixture and would need repointing at another script.
2. **Where does the validator live?** If `path` survives, `path.validate` is the noun.verb home and
   the script finally earns its keep. If `path` goes, it belongs in `this` beside
   `this.anchor.validate` as `this.path.validate`, completing the family that already has
   `this.oosh.dir.validate` and `this.config.path.validate`.
3. **Which gives way on the `BASH_FILE` block** — the idempotency claim in the documentation, or
   the must-be-first behaviour in the code?

Not a question, an answer, recorded here so it is not asked again: **the rule is about writers, not
values**, because `PATH` is an accumulation. See § 7.
