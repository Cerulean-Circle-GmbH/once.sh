# OOSH boot tickets — working document

**Created:** 2026-09-10 · **Board source:** Kanban screenshot 2026-09-10 · **Branch:** `dev`

This is the step-by-step working document for the **remaining OOSH boot tickets**. The board is
the source of truth; this file mirrors it and is updated in the same commit as the work it tracks.

---

> **Where things live.** This file and the cards next to it (`docs/plans/`) are the tickets; design
> specs and implementation plans from the superpowers workflow live under `docs/superpowers/{specs,plans}/`;
> reviews and forensics under `docs/research/`. `docs/wiki-index.md` § Design docs & tickets lists them.

> **Start here for the current backlog (2026-09-15):**
> [what each board card actually is, and what to do about it](2026-09-15-board-backlog.md) —
> all eleven open items grounded against the code, in recommended order, with the card text
> verbatim for matching against the board. It supersedes this file's execution order in §3:
> the test-isolation repair is scheduled **before** T7, because `./test.suite core 1` currently
> rewrites `oosh.env` — the very file T7's drift bug lives in.

## 1. Board mapping

| Column | Cards | Ours? |
|---|---|---|
| **Ideas** | `oosh staging`, `odocker`, `env -i sh. SAVETY...shall boot correctly`, `OOSH_DIR is always …`, `review all OOSH_DIR=`, `prod/docs/puml/bootsratp.sequence`, `config has to bootstrap always all variables …`, `review hot PATH is bootstrapped` | **YES** — all that is left (first two deferred by user) |
| **To Do - Refined** | `Plan a review miro clone / scenarios UcpComponent loaders` | no |
| **On Hold** | — | — |
| **In Progress** | `all possible entry points coverd`, `WODA staging`, `capsule-canvas` | no — owned by others |
| **In Review** | `log has missing variables`, `LOG_DEVICE is missing`, `LOG_LIVE missing?`, `check LOGNAME and why not LOG_NAME` | ours — **implemented & pushed**, awaiting boss review |
| **Done** | `NEVER logic in ENV FILES`, `config currently has code!` (+ Branching, dev/WODA, dev/WODA245-v2, test/WODA) | ours — accepted |

### Already delivered (context for reviewers)

| Area | Commits |
|---|---|
| boot loader + pure-data env files (`config currently has code!`, `NEVER logic in ENV FILES`) | `ca4abe1` series → `070dcc3` |
| log variables (`LOG_NAME`/`LOG_DEVICE`/`LOG_LIVE`, per-user `log.session.env`) | `f9f6905`, `a42aad4`, `56ce683`, `070dcc3` |
| review response waves 1–3 (D1–D7, M5–M7) | `110261a`, `d9bf854`, `e2ea957`, `0e3f734` |
| `state list` crash + shared-cache clobber | `604c296`, `ad73cfb` |
| revert of `state.list` display change (kept Marcel's form, per user) | `21f431d`, `b7a316b` |

**Deferred by user (not scheduled):** `oosh staging`, `odocker`.

---

## 2. Working agreement — how a ticket moves

1. **One of our tickets In Progress at a time.** The next one starts only when the current
   reaches *In Review*.
2. **→ In Progress** when we begin planning/implementing it. Each ticket gets its own plan
   before code (step-by-step, per user).
3. **→ In Review** only when **all** of these hold:
   - code + tests committed and pushed to `origin/dev`;
   - `./test.suite core 1` shows **zero real failures** (1 intentional meta-test is expected);
   - documentation updated;
   - the ticket's own verification commands (below) pass.
4. **→ Done** only when the boss/user accepts it. **We never self-promote** a ticket to Done,
   and we never propose dev→testing→prod promotion.
5. The user moves the physical cards. This file is updated in the same commit as the work.

---

## 3. Execution order

| # | Ticket | Status | Why this position |
|---|---|---|---|
| 1 | **T4+T5** — `OOSH_DIR` audit + enforce | 🟣 **In Review** | Core boot mechanism. Landed `2045811` + `518e179` (the `CONFIG_PATH` follow-up). Everything below documents or depends on what this settles. |
| 2 | **T7** — config bootstraps branch-version vars / `config init` repairs | 🔍 **In Review** | Delivered `fee9513`…`1d1cc41`: `OOSH_BRANCH` un-persisted, `OOSH_MODE` means the branch, `config.init` honours its anchor, `config validate required`, both shared-tier waivers deleted. |
| 3 | **T8** — PATH bootstrap + the `path` script | 🔍 **In Review** | Same "what does `boot` own" theme as T4/T5. Delivered `2471b43`…`db0177d` + markers: `path validate`, the writer rule in [boot.md](../boot.md), `path` shrunk 26 methods to 11, `.` off the PATH. |
| 4 | **T3** — `env -i sh` SAFETY | 🔍 **In Review** | Taken out of order at the user's request (2026-09-14). `boot` was final on both anchors after T4+T5, so nothing blocked it — and it turned out to hold two live defects, not to be a verify-and-close. Second attempt delivered `boot` + `init/oosh` recovery and the clean re-exec. |
| 5 | **T9** — fixed system path to `boot` | 🔍 **In Review** | Fell out of T3: `boot` recovers `$HOME`, but `. ~/oosh/boot` cannot be *reached* under `env -i sh` — dash leaves `~` literal with `HOME` unset. **Delivered 2026-09-14**: install state `34 root.boot.path.installed`, `oo boot.fix` / `oo boot.status`, the `/etc/profile.d/oosh.sh` login-shell drop-in (from `templates/user/profile.d.oosh.sh`), `test.platform.boot.system.path.invariant`. The five design decisions are recorded on [the card](2026-09-14-fixed-system-boot-path.md). Review checklist: the trust note (dev-group-writable content behind a root-looking path), the warn-and-skip on branches without `boot`, and a platform run on a host installed BEFORE state 34 followed by `oo boot.fix`. |
| 6 | **T6** — `bootstrap.sequence` diagram | 🔍 **In Review** | Last, and it documents the mechanism the five above settle. Diagram redrawn by the user (`bootstrap.sequence.drawio`); this pass declared it the source of truth, marked the pre-`boot` `.puml` superseded, cross-linked it, and corrected three labels that T8 and item 6 invalidated after it was drawn. |

---

## 4. Tickets

### T4 + T5 — `OOSH_DIR` is always `~/oosh` · review all `OOSH_DIR=` 🟣 In Review

> **Card (Ideas #4):** `OOSH_DIR is always /userhome/oosh  ~/oosh` — `NEVER oo mode.base.get`
> **Card (Ideas #5):** `review all OOSH_DIR=` — `understand the boot mechanism`

**Meaning.** One rule for where OOSH lives: `OOSH_DIR` is always the user's `~/oosh` —
**the symlink path itself**, never the worktree it points at, and never derived from
`oo mode.base.get`. T5 is the audit that makes T4 enforceable — hence taken together.

**The rule, and why it collapses the work.** Written in code as `OOSH_DIR="$HOME/oosh"`
(a tilde inside quotes does not expand). Because the value is the symlink, it is a
**constant**: `oo mode` moves only what `~/oosh` *points at*, so the variable never
changes and needs setting in exactly **one** place. Code that genuinely needs the
**physical** directory resolves it *at that spot* with the existing portable helper
`private.this.path.canonical` (`this:144`).

**Delivered (2026-09-10).**

| | |
|---|---|
| **Single setter** | `boot` — `export OOSH_DIR="$HOME/oosh"`. Plus one same-literal fallback in `this`'s top-level block for contexts that never source `boot`. |
| **Setters removed** | `oo.mode`, `oo.mode.setup`, install state 31 (root), `this.init`, and the `OOSH_DIR` line of the generated `mode-env.bash` — a constant needs no updating, and each assigned a *physical* path. |
| **Real bugs fixed** | `ossh.start` derived from `$0`, i.e. the **host** process whenever `ossh` is *sourced* (`myId`, `config`, `user`, `test.ossh`). Install state 31 (user) did `ln -s "$OOSH_DIR" oosh` inside `cd $HOME` — a self-referential symlink ("Too many levels of symbolic links") — and took `OOSH_MODE=$(basename "$OOSH_DIR")`, which yields `oosh` instead of the branch. |
| **Physical-path consumers fixed** | `config.init.user`'s shared-tree prefix test, `promote`'s worktree/mergeDir comparisons (double-stash of the same dir), `oo.mode.base.get` strategies 3/4 (`dirname ~/oosh` is just `$HOME`), `test.oo`'s mode fixture. |
| **Sanctioned exceptions** | 4, each marked in-code: `oo.use` (scoped child override), `ossh` remote invoke, `user.oosh.install` sub-shell, and `init/oosh` (file-wide — the installer runs before `~/oosh` exists). Marker: `# oosh-dir-exception: <reason>` / `# oosh-dir-exception-file: <reason>`. |
| **Guard** | New `this.anchor.validate <all\|OOSH_DIR\|CONFIG_PATH>` (`this`), with `this.oosh.dir.validate` / `this.config.path.validate` as the per-anchor forms — one `git grep` per anchor over the tracked tree, classifying every assignment conforming / exception / violation, verdict echoed to stdout, rc 1 on any violation. Shaped like `config.validate`. Tree today: `OOSH_DIR` 4 conforming / 7 exceptions / 0 violations; `CONFIG_PATH` 6 / 3 / 0. |
| **Follow-up: `CONFIG_PATH`** | Put under the same rule in the same pass — see below. |

`oo.mode.base.get` itself remains legitimate for **locating worktrees**
(`oo:470,518,573,796,912,951,1082,1120`); the ticket forbids only deriving `OOSH_DIR` from it.

**Definition of done.**
- [x] Decision recorded on `oo mode`/`oo use` vs the always-`~/oosh` rule — `oo mode` no longer exports `OOSH_DIR` (the symlink move *is* the switch); `oo use` is a marked exception
- [x] Every remaining non-conforming site either fixed, or justified in-code with a marker
- [x] A test pins the rule — `test.this` T-OOSH-DIR-* (4 cases, including a *planted* violation so the guard is proven to fail); `test.config` T31 asserts `boot`'s literal and delegates the tree sweep
- [x] `docs/boot.md` states the rule and the sanctioned exceptions
- [x] Standing verification bar passes — host `test.suite core 1` 623 assertions /
      622 passed / 1 intentional; `os platform.test ubuntu_24_04` **rc=0**, in-container
      core 628/627/1, the only `✗ FAIL` lines being that same intentional meta-test once
      per container user (root/test/oosh-user/bash-user). After a *real fresh install* all
      four users' shells passed T-OOSH-DIR-IS-HOME-OOSH, T-CONFIG-PATH-IS-HOME-CONFIG,
      T-ANCHOR-VALIDATE-TREE and T31 — and the log holds zero occurrences of "Too many
      levels of symbolic links" (the state-31 self-loop this ticket fixed).

**Verification.**
```bash
source ~/oosh/boot && echo "$OOSH_DIR"      # → /home/<user>/oosh  (the symlink itself)
readlink ~/oosh                             # → the branch worktree, NOT ~/oosh
echo "$CONFIG_PATH"                          # → /home/<user>/config  (the symlink itself)
this.anchor.validate                        # → OK for BOTH anchors, 0 violations (rc 0)
                                            #   (`this` is a function in an oosh shell,
                                            #    so call the method directly)
./test.suite run this 1 && ./test.suite run config 1 && ./test.suite core 1
os platform.test ubuntu_24_04
```

#### Follow-up done in the same pass — `CONFIG_PATH` is always `~/config`

The card names only `OOSH_DIR`, but the audit showed `CONFIG_PATH` had the *same*
defect in a sharper form: **`boot` was the only place in the tree that resolved it.**
`config:170` (`export CONFIG_PATH=~/config`), `log:103`, `log:300`, `ossh:3579` and
`this:492` (`: ${CONFIG_PATH:=$HOME/config}`) all already used the literal — so the
variable held *two different values depending on which entry point ran*: the shared
`sharedConfig` path after `boot`, `~/config` after a bare `source this`, `ossh exec`
or a mid-install sub-shell.

- **Fixed:** `boot` now sets `export CONFIG_PATH="$HOME/config"`, agreeing with
  everyone else. One line.
- **No point-of-use fixes were needed.** Unlike `OOSH_DIR`, nothing in the tree does
  `dirname` / `basename` / prefix arithmetic on `CONFIG_PATH` — only `-d` / `-f` /
  `-z` tests, which follow a symlink. The one `ln -s "$CONFIG_PATH" config`
  (`oo:2122`, the self-loop shape that bit `OOSH_DIR`) is safe because `CONFIG_PATH`
  is set to the explicit shared path 19 lines above it.
- **3 exceptions marked** `# config-path-exception:` — `config file <path>` (the one
  method whose job is to leave `~/config`) and install state 31 (×2, which builds the
  shared tree *before* `~/config` is a symlink to it).
- **Guard generalised** rather than cloned: the marker slug is derived from the
  variable name (`OOSH_DIR` → `oosh-dir-exception`, `CONFIG_PATH` →
  `config-path-exception`), and a self-assignment (`CONFIG_PATH=$CONFIG_PATH`, as in
  `config`'s and `test.suite`'s usage banners) is skipped — it is a no-op, and a
  marker comment there would be *printed to the user*.
- **Tests:** `test.this` T-CONFIG-PATH-IS-HOME-CONFIG and T-CONFIG-PATH-VALIDATE-REJECTS
  (the latter proves the rule is per-anchor: an `oosh-dir` marker does **not** exempt
  a `CONFIG_PATH` line); `test.config` T31 now asserts both of `boot`'s literals.

Not touched: `CONFIG` (`$CONFIG_PATH/$CONFIG_FILE`) simply follows, and
`OOSH_USER_CONFIG_PATH` was already the literal `$HOME/.config/oosh`.

#### Third scope correction — `boot` must RECONSTRUCT, not just read (2026-09-14)

The user's final steer: *"It should just reconstruct all the env files."* Measured before:

```
boot with no env files   ->  rc 0, nothing rebuilt        (silent no-op)
config init.env          ->  all files back, correct      (machinery already worked)
```

`boot` guards every source with `[ -f … ] &&`, so a missing config was simply skipped — a shell
that looked fine and had no environment. The repair family already existed; `boot` never called it.

**The hazard that shaped the design.** `config.init.env` → `config.save` writes the **shared**
sharedConfig from the **calling shell's live environment**. Auto-running it per shell would let one
user's shell rewrite everyone's config — not theoretical: earlier in this session a `config save`
from a `LOG_LEVEL=1` shell persisted `LOG_LEVEL="1"` into the shared `log.env` for all users. So
the reconstruct is scoped by blast radius:

| Situation | Behaviour |
|---|---|
| config intact | nothing — three `[ -f ]` tests, no subprocess, no output |
| all three shared files missing | rebuild (nothing to destroy) |
| some missing/invalid | **report only**, naming `config init.env` |
| `$CONFIG_PATH` absent | silence — install owns install |

New **`config.reconstruct`** owns the decision; `boot` only notices a file is gone and hands off,
invoking it as a **command, not sourced** (sourcing `config` runs its top level, which creates
`$CONFIG_PATH` — caught during implementation when the "not installed" case wrongly conjured a
config dir). `OOSH_BOOT_NO_RECONSTRUCT=1` opts out for the install pipeline and fixtures.

Two things the implementation corrected against the approved plan, both from measurement:
- the planned **per-user tier was dead weight** — `boot` already calls `log.session.save` on every
  shell, so that file cannot be missing afterwards;
- `config.init.full` did **not** need the reconstruct (its `config.init.env` is strictly more), but
  *did* lack any per-user repair, so it now calls `log.session.save` directly.

Covered by `test.config` **T55-T59**; T56/T57 proven to fail against the previous commit's `boot`.

~~This also delivers the first half of **T7**~~ — **corrected 2026-09-16.** It did not: `config.reconstruct` shipped in `8b668c6` and was rolled back with the whole day by `a8b6928`, for an unrelated WODA regression rather than on its merits. `grep` finds it only in docs. T7 was delivered instead by `fee9513`…`5fbb513`; see [the research doc](../research/2026-09-16-t7-config-branch-variables.md).

#### Found while verifying T3 — the error trap was inventing diagnoses (fixed)

Chasing the last two noisy lines in an otherwise clean install log showed that **neither was a
real failure**. `private.debug.errno` (was a nested `errno()` inside `onError`, `debug:259`)
mapped any command's exit status through **bash's own shell conventions**:

```
2)   EXIT 2 Misuse of shell builtins
126) EACCES 126 Command not executable
127) ENOENT 127 Command not found
```

Those meanings hold only when the **shell** could not run the command. A program is free to
return the same numbers as its own status, and two in this tree do:

| Seen in the log | What really happened |
|---|---|
| `"env" … ENOENT 127 Command not found` | the user ran `odocker` inside `env -i sh`, it was not on PATH, `exit` propagated 127 — **`env` itself ran fine** |
| `"grep" … EXIT 2 Misuse of shell builtins` | `grep` returns 2 for "an error occurred" (e.g. an unreadable file) — nothing to do with builtins |

A third layer: when `python3` was present the fallback translated the exit status through
**errno** — a third, unrelated numbering system (errno 2 is ENOENT; exit 2 is just 2).

**Fixed.** Every interpretation is now checked before it is offered: 126/127 only when
`command -v` confirms the command really is missing or non-executable; the `2` gloss and the
errno lookup are gone; everything else reports an honest `EXIT <n>`. The genuine diagnoses —
a truly missing command, and signal deaths (128+N, which the *shell* does set) — are unchanged.
Dropping the errno lookup also takes `python3` out of an ERR-trap path.

`errno()` was defined *inside* `onError`, so it was unreachable until the trap had fired once —
which is why it had never been tested. It is now `private.debug.errno`, covered by
`test.debug` **T-ERRNO-NO-FABRICATED-DIAGNOSIS**.

#### Follow-ups found while doing T4+T5 (not fixed here)

- **PATH physical-path rewrite pair** — `mode-env.bash`'s branch-name `sed` and install
  state 31's `export PATH="$( … replace.sedquoted "$HOME/oosh" "$onceShBase/$OOSH_BRANCH" )"`
  (which carries its own `# TODO: This should be removed to only use $HOME/oosh in the PATH`).
  Left in place deliberately: they still work, and removing them is a separate cleanup.
- `oo`'s `private.check.user.shared.dev.folder.linked`: non-idempotent `ln -s` (fails with
  "File exists" when `~/oosh` already exists, which it must for the resolve above it to work)
  and an unrestored `cd $HOME`. The rest of the tree uses the idempotent
  `private.oo.user.shared.symlinks.ensure` for exactly this.
- `docs/oo.md` has **no `oo use` section** — the "run from another branch without switching"
  contract exists only as the method's docstring, yet the `oo.use` exception depends on it.
- `this` lacks the `### new.method` insertion marker (only `ossh`/`state` carry it).

---

### T7 — config bootstraps all branch-version variables · `config init` repairs 💡 Ideas

> **Research doc (2026-09-16), read before any code:**
> [what a config must carry, and who owns `OOSH_BRANCH`](../research/2026-09-16-t7-config-branch-variables.md).
> It ends with three questions for the boss; the central one is whether `OOSH_BRANCH` stops being
> persisted, which makes the drift impossible rather than repairable.

> **Card (Ideas #7):** `config has to bootstrap always all variables required for a branch version`
> — `conifg init repairs a nonexisting or broken config`

**Meaning.** A config must always carry every variable the *current branch version* needs, and
`config init` must repair a missing or broken config.

**Evidence — live bug (2026-09-10).** Persisted config disagrees with reality on this host:

```
persisted oosh.env : OOSH_BRANCH=prod   OOSH_MODE=released
actual OOSH_DIR    : …/Once.sh/dev      (git branch: dev)
~/oosh ->          : …/Once.sh/dev
```

Nothing reconciles `OOSH_BRANCH`/`OOSH_MODE` with the actual checkout. `OOSH_DIR` and
`OOSH_USER_CONFIG_PATH` are *intentionally* not persisted (boot computes them) — that part is correct.

**Reuse.** The repair family already exists — extend, do not rewrite:
`config.init`, `.shared`, `.user`, `.env`, `.check`, `.full` (`config:168-458`).

**Definition of done.**
- [ ] Define the required-variable set for a branch version (and where it is asserted)
- [ ] `config init` (or `.check`) detects and repairs branch/mode drift
- [ ] Test reproducing the drift and proving the repair
- [ ] `docs/config.md` updated
- [ ] Standing verification bar passes

**Verification.**
```bash
grep -E 'OOSH_(BRANCH|MODE)' ~/config/oosh.env
git -C "$(readlink -f ~/oosh)" rev-parse --abbrev-ref HEAD    # must agree
config init.check && ./test.suite run config 1
```

---

### T8 — review how PATH is bootstrapped · the `path` script 🔍 In Review (2026-09-16)

> **Research doc (2026-09-16), read before any code:**
> [who owns `PATH`](../research/2026-09-16-t8-path-ownership.md). It corrects six of this
> ticket's factual claims, finds two defects the ticket does not mention, and ends with three
> questions — the first two coupled: does `path` survive, and where does the validator live.

> **Card (Ideas #8):** `review hot PATH is bootstrapped` — `PATH=` — `and the path script`

**Meaning.** Establish a single owner for PATH.

**Evidence.** `boot:59,67` is now the single, colon-guarded, idempotent PATH builder (brew-bash
first). But a separate `path` script (`path.list`, `path.env`, `path.save`, `path.load`,
`path.file.user`…) **also** persists PATH into config — two mechanisms unaware of each other.
`.github/workflows/macos-test.yml` still hand-exports `PATH="$HOME/oosh:$PATH"` in **7** places
*after* sourcing `boot` (review finding **M1**, deferred).

**Definition of done.**
- [x] Decision: `boot` owns runtime PATH; `path` persists **nothing** — it reports, and edits the
      session. The rule and its exception table are in [boot.md § The PATH-writer rule](../boot.md).
- [x] `path` script reconciled: 26 definitions to 11, 305 lines to ~260 (the new validator is most
      of what is left), `./c2 function.completion ./path` from 21 verbs to 9. The three mutators
      stopped claiming "and saves config", and stopped matching by substring.
- [x] The 7 redundant `macos-test.yml` exports — **converted, not deleted**. Each sat under
      `source "$HOME/oosh/boot" 2>/dev/null || true`, whose `|| true` makes a failed boot silent,
      so they were a real degrade branch. Both lines became the one blessed spelling the tree
      already uses.
- [x] Test pins PATH idempotency — `test.config` **T74**, behavioural (source `boot` twice in a
      clean sub-shell, inspect the PATH). It replaces a *second* test that also called itself T24
      and could not fail: it grepped `boot` for two literals that appear in `boot`'s own comment.
- [x] Standing verification bar passes — **ubuntu gate on `cd11aec`: PASS.** A real install from
      `origin/dev` completes, and inside the container `echo $PATH` shows **no `.`** — the CWE-426
      fix holds through the install path, which is where it used to fire. `test.suite core 1` there:
      27 files / 695 assertions / 694 passed / 1 intentional, same as the host, no `Shared tier:`
      line; `path validate` and `this anchor.validate` both 0 violations in the container.
      Host `test.suite core 1` 27 files / 695 assertions / 694
      passed / 1 intentional, no `Shared tier:` line; `path validate` 0 violations;
      `this anchor.validate` 0 violations on both anchors.

**Beyond the card.** Two live defects the ticket did not mention, both found by the research doc:

- **`this.path.add "."`** — CWE-426. Each call prepends, so `.` landed *fourth*, ahead of
  `/usr/local/bin`, `/usr/bin` and `/bin`, whenever `this`, `log`, `init` or `oosh` was
  **executed** — the whole install run included, since `init/oosh` has `$0` of `oosh`. Silent,
  because oosh's own tools still resolved from `$OOSH_DIR` while every `git`, `curl`, `tar` and
  `sudo` they shelled out to came from the current directory. Root too, via `$OOSH_DIR/su`.
- **`claudeCode`** wrote `export PATH=` **into a config env file** — the last writer that believed
  env files carry PATH. It was also dead on its feet: `$CONFIG_FILE` is a file *name*, so its
  `[ -f ]` guard was false anywhere but inside `~/config`.

**Three tools were built first**, because the ticket could not be done conformantly without them
(`2471b43`): `line.remove.exact` (whole-line, replacing the `grep -v` substring match behind three
separate bugs), `replace block` (a method is a block, not a line), and **`oo method.delete`** — the
missing member of the `oo new` / `oo test.new` / `oo method.new` family, without which sixteen
deletions would have been sixteen hand edits.

---

### T3 — `env -i sh` SAFETY, shall boot correctly 🔍 In Review (second attempt, 2026-09-14)

> **Card (Ideas #3):** `env -i sh. SAVETY...shall boot correctly`

## Forensics (2026-09-14) — `env -i` is a SHEBANG, not a command

The card was misread all day, in several different ways, before the history settled it. **`env -i`
was never something you type at a prompt.** It is the shebang `init/oosh` used to carry:

```sh
#!/usr/bin/env -iS HOME=${HOME} sh
         ^^         ^^^^^^^^^^^
         |          passes HOME through
         start from a CLEAN environment
```

Wipe the environment, **but keep `HOME`** — because `HOME` is the one thing that cannot be derived
from nothing. That is the "SAVETY" in the card.

### Where it came from and where it went

| When | Commit | What |
|---|---|---|
| **2024-04-07** | `8c277f4`, `815d14d` — *Chris Daßler* | Introduced `#!/usr/bin/env -iS HOME=${HOME} sh` on `init/oosh`, and the `bash` variant on `test/test.tilde`. Message: *"Shebang for clean environment"* |
| **2026-02-16** | `57f0984` | `env -i` wiped `OOSH_BRANCH` when it was passed as an env-var prefix; fixed by passing the branch as a **positional argument**, which survives the wipe |
| **2026-03-09** | `075b4a3` | **Removed.** *"Change shebang from `#!/usr/bin/env -iS` to `#!/bin/sh` (BusyBox env doesn't support `-S` flag)"* — Alpine compatibility |

So the guarantee held from **April 2024 to March 2026** and was traded away for Alpine support. A
real portability constraint, not a mistake — but nothing replaced the guarantee.

| branch | `init/oosh` shebang |
|---|---|
| **`main`** (last touched 2026-03-12) | `#!/usr/bin/env -iS HOME=${HOME} sh` — **still has it** |
| `prod` / `testing` / `dev` | `#!/usr/bin/env sh` |

### The separate question: could a bare shell ever stand up the environment?

Each era's `user.env` was reconstructed from its own `config.save` and **executed**, not read:

| Era | `env -i sh` | `env -i bash` |
|---|---|---|
| **main** (≤ Apr 2026) | ✅ works | ✅ works |
| **prod / testing** (Apr–Sep 2026) | ❌ `Bad substitution` | ✅ works |
| **dev**, env files alone (since `8b498f4`, 2026-09-08) | ❌ nothing set | ❌ nothing set |
| **dev**, via `$OOSH_DIR/boot` | ✅ works | ✅ works |

Two findings that matter:

- **prod/testing only ever worked under bash.** Their self-anchor is
  `: ${CONFIG_PATH:="${BASH_SOURCE[0]%/*}"}`, and `BASH_SOURCE` is a **bashism** — under `sh`/dash
  it dies with `Bad substitution` before anything is set. "It works in older branches" is true for
  `bash`; it has never been true for literal `sh`.
- **main worked under `sh` only because of the defect that was deliberately fixed** — it baked
  absolute paths (`export PATH=…`, `export OOSH_DIR=/home/x/oosh`) into the *shared* config, which
  is precisely the cross-user leak the pure-data migration removed.

**So `dev` + `boot` is the first design where a bare POSIX shell comes up correctly without baked-in
absolute paths.** For this card it is strictly better than prod/testing, not worse. The one
remaining gap is `HOME`: `env -i` drops it, and `boot` currently refuses rather than deriving it.

**Meaning (restated).** The installer, and any oosh entry point, must survive being started from a
clean environment — with `HOME` preserved, or derived when it is not.

**Correction to this document (2026-09-14).** An earlier revision of this section claimed T3
"already passes today". **It did not.** Only the *happy path with `HOME` set* passed. Probing
`boot` under a bare POSIX shell found two real defects, one of them live in production paths:

**Defect 1 — `boot` returned rc 1 after a completely successful POSIX-sh boot.**
Its last statement was `[ -n "$BASH_VERSION" ] && type log.session.save … && log.session.save …`.
Under `sh`/`dash`/`ash` there is no `$BASH_VERSION`, so the `&&` list was false and `boot` exited 1
with every anchor correctly set. Measured: `dash` 1, `busybox ash` 1, `bash` 0. Five production
sites branch on that status — `ossh:2530` (`ossh exec`), `ossh:2549` (`ossh exec.tty`) and
`user:135,156,180` (rootkey pushes) all do
`[ -f ~/oosh/boot ] && . ~/oosh/boot || export PATH=~/oosh:~/oosh/ng:$PATH`. On every dash/ash host
the "boot failed, degrade" branch fired **on success**, making a real failure indistinguishable
from a healthy boot and duplicating `~/oosh` on PATH.

**Defect 2 — no `HOME` did not merely half-boot, it KILLED the sourcing shell.**
`$HOME` empty → `OOSH_DIR=/oosh`, `CONFIG_PATH=/config`, then the touch-guard ran
`: > /.config/oosh/log.session.env`. A redirection failure on a **special builtin** (`:`) is fatal
under POSIX, so the shell that sourced `boot` died on the spot. `env -i` drops `HOME` unless it is
passed through, and `env -i` is how the install bootstrap starts.

**Scope agreed with the user (2026-09-14).** In: rc 0 on success; no-`HOME` handling;
busybox **ash** coverage.

**Scope corrected mid-ticket (2026-09-14), after the user tested it.** The first cut made `boot`
*fail fast* on a missing `HOME`. The user then ran `env -i sh` in a platform-test container and
reported "it is not working" — correctly. Failing fast is safe, but the card says
**"shall boot correctly"**, and a refusal is not a boot. (My scope question had framed this as a
safety choice; that framing was wrong.) `boot` now **derives** `$HOME` from the password database
instead — exactly what bash itself does for `~` when `HOME` is unset, which is why
`env -i bash` could reach `boot` at all while `env -i sh` could not even resolve `~/oosh/boot`.
Refusal is kept only for when no home can be found at all. Out: corrupt/missing config (probe shows it already works — not pinned
this round); the 8 `|| true` in `macos-test.yml` (review finding **M1**, still deferred); PATH
*design* (that is T8 — T3 only asserts `~/oosh` ends up on PATH).

**Second scope correction (2026-09-14), again from the user's own testing.** Running the
platform test again, the user pointed at the install log — *"still the same … what this needs to
do is fix all the env files as simple as this"*. The remaining noise was:

```
/home/test/config/log.env:       line 3: /root/.config/oosh/log.session.env: Permission denied
/home/developking/config/log.env: line 2: /root/.config/oosh/log.session.env: Permission denied
/home/bash-user/config/log.env:  line 3: /root/.config/oosh/log.session.env: Permission denied
```

**Root cause — a SHARED file referencing a PER-USER variable.** `config.save` appended
`. $OOSH_USER_CONFIG_PATH/log.session.env` to the shared `log.env`. That variable is *exported*
and per-user, so any cross-user sub-shell that inherited the caller's value resolved the line to
**their** directory. `user:951` reset `CONFIG CONFIG_PATH CONFIG_FILE` before running as another
user but had **not** been updated to reset `OOSH_USER_CONFIG_PATH` — it was added to
`config.save`'s persistence deny-list when the per-user tier was introduced, and this `unset` list
was missed.

**Fixed structurally, not patched.** Shared files now hold only shared data:
- `config.save` no longer appends that line — a freshly generated `log.env` is two `export LOG_*`
  lines and nothing else.
- `boot` sources `$OOSH_USER_CONFIG_PATH/log.session.env` itself (new **section 2b**), *after* the
  shared chain so per-user values still win.
- `boot`'s old touch-guard is gone with it — and with it the `:` redirection that could kill the
  sourcing shell (the same POSIX special-builtin hazard as Defect 2).
- `user:951` now unsets `OOSH_USER_CONFIG_PATH` too, so the leak cannot recur by another route.
- Stale `log.env` files on existing installs keep the old line harmlessly (pure data, sourced
  twice at worst) and lose it at the next `config save`.

*Out of scope, recorded:* `result.env` uses bare `declare -x` (which `config.validate` already
calls INVALID) and `setup.color.env` uses the bashism `ESC=$'\e['`. Neither is in `boot`'s chain;
the user chose not to fix them this round.


**Status after 2026-09-14.** `a824d8e` is **kept** — it fixes `boot` returning rc 1 on success under
sh/dash/ash, which made five production sites (`ossh exec`, `ossh exec.tty`, three `user` rootkey
pushes) take their "boot failed" branch on *every successful boot*. That commit is the only point of
the day **proven green by a container platform run**.

Everything after it was **reverted** (see §4d). Still missing, and recorded rather than lost:
`$HOME` derivation so `env -i sh` boots; `config.reconstruct`; `config.env.init` and `boot` restore
mode. The design for those is written up in full and was not found to be wrong.

**Was delivered, now reverted.**
- `boot`'s bash-only tail moved into **one `if`**, and the file now ends with a bare `:` — success
  can never again be reported as failure.
- New **section 0**: when `$HOME` is unset *or not a directory* (a stale `HOME` produces the same
  garbage anchors), derive it — `getent` (Linux/NSS) → `dscl` (macOS, taking the first of the two
  paths it returns for `root`) → `/etc/passwd` — and export it. Same three-way split the rest of
  the tree uses (`private.get.home.darwin` in `user`). Only if all three come up empty does `boot` refuse, with one
  diagnostic on stderr and `return` — never `exit`, because `boot` is sourced and `exit` would
  close the user's terminal.
- **Result: `env -i sh -c '. <path>/boot'` now comes out with `HOME`, `OOSH_DIR` and
  `CONFIG_PATH` all correct, in `sh`, `dash`, `bash` and `busybox ash`.** That is the card.
- The five `||` callers needed **no change**: the fix is upstream, and their degrade action is
  still right for a genuinely absent `boot` (non-dev branches — that is what T49 pins).
- `docs/boot.md` gains a **Guarantees** section: sourced-only, exit status is a contract,
  `$HOME` required, proven shells.

**Delivered (2026-09-14, second attempt).** `boot` and `init/oosh` both recover `$HOME`;
`init/oosh` re-execs clean without `env -S`. The guarantee `075b4a3` removed for Alpine is
restored portably — see
[the design spec](../superpowers/specs/2026-09-14-clean-environment-guarantee-design.md) and
[the plan](../superpowers/plans/2026-09-14-clean-environment-guarantee.md).

Commits: `80b6257` (`boot` recovers `$HOME`), `78957c7` (`init/oosh` recovers `$HOME`),
`dc3bbcb` (clean re-exec), `47f0a8b` (carry `SUDO_USER` + `OOSH_REPO`), `a886203` (comment).

**The finding that made this more than a restore.** `init/oosh` was rewritten three times
(`b8b90b8`, `b427809`, `0594657`) during the two years the shebang was absent: at the pre-change
baseline `a6f0ce3`, **531 of its 537 lines postdate `075b4a3`**, the other 6 being two bare `fi`s
and four blank lines. So "we are only putting
back what used to be there" was false — effectively the whole current file was meeting `env -i`
for the first time. An audit of every variable the installer *reads but never sets* found two that
had grown a dependency on inheritance and would have broken silently:

| Variable | Silent failure if not carried |
|---|---|
| `SUDO_USER` | `sudo ./init/oosh` loses the invoker; the post-install `user oosh.install "$SUDO_USER"` never runs, so the invoker simply does not get oosh |
| `OOSH_REPO` | a fork or private-repo override falls back to public GitHub, with no error |

Both are now carried. `PATH` is deliberately not carried: it is **seeded** to a fixed list by
the re-exec (`env -i` leaves it unset, and the compiled-in default lacks `/opt/homebrew/bin`, which on an arm64 Mac ran the Homebrew installer as root and aborted — see `docs/install-bootstrap.md`). **Anything added later that reads an inherited
variable must be added to the carry list** — the list and its rationale sit at the call site.

Two fossils confirmed by the audit: `ossh:518` already passes the branch as an argument *"not env
var — init/oosh shebang uses env -i which wipes environment"*, dead since March and true again now;
and `Install oosh.command:20` sets `OOSH_SELF_BRANCH` **unexported**, so it never crossed anyway.

**Definition of done.**
- [x] Scope of "SAVETY" agreed and written down (above) — **and corrected twice by the user's own testing**: `env -i` means env INITIATE, i.e. RECOVERY of a broken box; see [the design spec](../superpowers/specs/2026-09-14-oosh-recovery-from-bare-shell-design.md)
- [x] Each agreed case has a test. In `test.config`: **T40** (lints under `sh` *and* `ash`),
      **T50** (exits 0 in sh/dash/ash/bash), **T51** (refuses when no home is derivable),
      **T52** (ash really boots), **T65** (recovery across all four shells, a *stale* `HOME`,
      a good `HOME` left untouched, and the sourcing shell surviving). In `test.install`:
      **T-INIT-HOME-RECOVERY** (recovery precedes the first `$HOME` use),
      **T-INIT-CLEAN-ENV** (re-exec present, guarded, and no `env -S`) and
      **T-INIT-CLEAN-ENV-CARRY** (`SUDO_USER` and `OOSH_REPO` really cross the re-exec).
      Every new guard was proven able to FAIL first, against deliberately broken copies —
      and that discipline paid: it caught a plan-specified assertion that could never fail,
      because an unanchored `grep` for `[ -f "$0" ]` matched a pre-existing line elsewhere
      in `init/oosh`. See [tests that cannot fail](2026-09-14-tests-that-cannot-fail.md).
      *(T53/T54 from the first, reverted attempt do not exist; this list replaces them.)*
- [x] `docs/boot.md` documents the guarantees — the **Guarantees** table (`$HOME` is now
      *recovered*, not merely required) plus a section covering the `init/oosh` half: the
      re-exec, why placement after the branch default is load-bearing, and the carry list
- [x] Standing verification bar passes (2026-09-14, second attempt, at `7e88ec4`) —
      host `test.suite core 1` **643 assertions / 642 passed / 1 intentional**;
      `test.install` 33/33; `test.config` 61/61; four-shell lint clean on both `boot` and
      `init/oosh`; `grep 'env -S'` finds nothing.
      `os platform.test ubuntu_24_04` **rc=0**, in-container core **643/642/1**, and every
      `✗ FAIL` in the log is that same intentional meta-test, once per container user.
      **`test.ssh.config.woda.portable` passes 12×** — the regression that ended the first
      attempt (§4d) is absent. Re-run after the review fixes, not only before them.

**Verification.**
```bash
for s in sh dash bash "busybox ash"; do env -i HOME=$HOME $s -c '. ~/oosh/boot'; echo "$s rc=$?"; done
env -i sh -c ". $OOSH_DIR/boot; echo \"\$HOME \$OOSH_DIR \$CONFIG_PATH\""  # all three correct
env -i HOME=$HOME busybox ash -c '. ~/oosh/boot; echo "$OOSH_DIR $CONFIG_PATH"'
./test.suite run config 1 && ./test.suite core 1
os platform.test ubuntu_24_04                    # exercises ossh exec + the per-user runners
```

**Follow-ups (not this ticket).** The five `|| export PATH=~/oosh:~/oosh/ng:$PATH` fallbacks are
not colon-guarded, so a *genuine* failure still duplicates PATH entries. The 8
`source "$HOME/oosh/boot" … || true` in `macos-test.yml` are now redundant (review **M1**).

---

### T6 — `bootstrap.sequence` diagram 🔍 In Review (2026-09-16)

> **Card (Ideas #6):** `prod/docs/puml/bootsratp.sequence` `/bootsratp.sequence.svg` (sic — the family was renamed `bootstrap.sequence` on 2026-09-14)

**Meaning.** The bootstrap sequence diagram must match the real (post-`boot`) mechanism.

**Evidence.** `docs/puml/bootstrap.sequence.puml` last changed **2026-03-18** (`9d9b9bb`) — before
the boot loader — and mentions "boot" once. `~/oosh-notes/2026-09-08-oosh-install-break-and-revert-eval.md`
already flags a regression against its `this localInstall → "starts new bash"` step. Docs-only, no code.

**Definition of done.**
- [x] Redrawn against `boot` — **by the user, in `docs/puml/bootstrap.sequence.drawio`**. Six lanes
      (GitHub install, local `init/oosh`, login-shell `.bashrc → boot`, reconfigure-and-exit,
      remote install, de-install), and it carries the post-`boot` mechanism in detail: the T4+T5
      anchor rule and why the anchors are constants, the pure-data `user.env → oosh.env → log.env`
      chain, the colon-guarded PATH with `dirname $BASH_FILE` first, the bare-`sh` skip of steps
      6-7, and the `this call … then exit` step that replaced the old *"this localInstall → starts
      new bash"* the 2026-09-08 notes flagged.
- [x] Source of truth declared. Two editable sources was the same two-owners problem T8 exists to
      end. **`.drawio` wins**; `bootstrap.sequence.puml` and its April `.svg`/`.eps` renders are
      kept for history and now carry a `SUPERSEDED` header naming the replacement.
- [x] Cross-linked from [boot.md](../boot.md) § See also — which had the ownership **backwards**,
      calling the `.puml` the source and the `.drawio` an "editable copy" — and newly from
      [wiki-index](../wiki-index.md), which did not link the diagram at all.
- [x] **Three labels corrected**, because this week's tickets moved the mechanism under the
      diagram after it was drawn on 2026-09-14:
      `user ssh.backup $USER.$local.for.$remote (if not yet backed up)` → `user ssh.backup
      pre-user-init` (item 6 deleted that name *and* that guard);
      `this.path.add external · init · **.** · $OOSH_DIR · ng` → the `.` removed (T8, CWE-426);
      and state 31 gained its new **first** step, the `pre-install` ssh snapshot (item 6).
- [ ] **User confirms the diagram is correct** — the original question the card asked, and the one
      box that is not ours to tick.

**Not done, deliberately.** The `.svg` was not regenerated: the `.drawio` is the source now, and a
render pipeline for it (a `drawio-export` container) is a tooling decision of its own. The stale
renders say so in the `.puml` header rather than pretending otherwise.

---

**2026-09-14 note.** The misspelled family (`bootsratp.*`, since 2022) was renamed
`bootstrap.sequence`; a `.drawio` editable copy was added next to the `.puml`
(`docs/puml/bootstrap.sequence.drawio`) and `docs/boot.md` § See also links the
diagram. The `.svg` is still the 2026-04-30 render — no PlantUML on the dev host —
and the `.puml` is unchanged, so every DoD item above is still open.

## 4b. Recorded decisions (so they are not rediscovered)

### Per-host `ossh` configs live in the repo — backlog item 10, 2026-09-16

The card `/root/oosh/etc/ossh/hosts/WODA.test/certificates.update.conf` looked
like a stray file. It is not: nothing is broken, `WODA.test` is a genuinely known
host, the file is committed on purpose, a real-env test asserts its contents, and
`/root/oosh/etc/…` is the correct path when `OOSH_DIR=/root/oosh`.

**Decision: it stays in the repo.** It is team configuration, version-controlled
deliberately, and it arrives with a fresh install.

Two consequences of that, which are the reason this note exists:

1. **`$OOSH_DIR` is the `~/oosh` symlink**, so `oo mode <branch>` changes which
   branch's host configs are visible. A host config added on `dev` is not there
   after `oo mode prod` until it is promoted — that is the versioning working,
   not a fault.
2. **The resolved machine values go somewhere else entirely** — to
   `$CONFIG_PATH/stateMachines/`, not next to the `.conf`. The `.conf` is input;
   the state machine's record of a run is output, and it lives in the config tier
   with everything else per-host.

No code change. See [board backlog § 10](2026-09-15-board-backlog.md).

---

## 4c. Proposed new cards (found by us, not yet on the board)

The user moves cards; these are written up so they can be added to **Ideas** when he chooses.

| Ticket | Why | Doc |
|---|---|---|
| **Tests that cannot fail** | A test function calling `create.result 1` reports **PASS** unless it ends with `return $(result)` — `create.result` only assigns `RETURN_VALUE`, and `test.case` then overwrites it with the function's exit status, always 0. Combined with `expect 0 "*"` (which sets the expectation to the actual result) both discriminators vanish. 57 wildcard assertions across 26 files; 8/8 sampled in `test.oo` are vacuous. | [2026-09-14-tests-that-cannot-fail.md](2026-09-14-tests-that-cannot-fail.md) |
| **Repair the `oo method.new` tooling** | The project mandates template-driven method creation, but the tool could not run against any core script: 17 stale doc references to names dead since `2fe5133` (2026-03-16), the `### new.method` marker missing from `config`/`this`/`log`/`debug`/`oo`, and a `<script>.new` usage-file step with only `myScript.new` left. **Partly done, 2026-09-17.** The markers are now present in `config`, `this`, `log`, `oo`, `line`, `user`, `replace`, `ossh`, `os`, `path` and `odocker` — only `debug` and `check` still lack one. `287073f` taught the tool to create a **private** method (it split `private.config.x.y` on the first segment, aimed at a file called `private`, and refused with rc 3 — so it could not create any of the private methods that are a large share of every script), and to skip the dead completion stub for one. What remains: the stale doc references and the usage-file step. | [2026-09-14-method-tooling-repair.md](2026-09-14-method-tooling-repair.md) |
| ~~**Runner-level test isolation**~~ 🔍 **In Review (2026-09-16)** | Delivered, but **not as proposed**. The card asked the runner to point every `core`/`extended` child at a seeded fixture `CONFIG_PATH`. Grounding it killed that design: `test/test.this` asserts the running shell's `CONFIG_PATH` **is** `$HOME/config` (the T4+T5 anchor rule, with `this.config.path.validate` behind it), and about twenty files read `stateMachines/`, `result.txt`, `completion.result.txt` and the colour env files out of that directory. Worse, moving anchors only redirects writes addressed through `$CONFIG_PATH` — it can do nothing about a hardcoded `~/config` path, which is exactly what `test.log`'s T31 did while believing itself isolated. **A canary catches strictly more than isolation prevents**, so the runner now fingerprints `user.env`/`oosh.env`/`log.env` around every non-platform child, names the offender, restores the tier from its snapshot and fails the run (`cff3bb5`). It caught `test.odocker` on its first extended run (`ad7db00`). The handoff moved to a private per-run directory and the pass/fail rule is extracted to `private.test.suite.verdict`, so a score-less `core` file now fails. The fingerprint is **content only** — an mtime-sensitive stamp cascaded on alpine because a test user can restore a shared file's content but not its timestamp (`b1003c7`). Default isolation stays unbuilt and belongs after T7, which is what makes `config.init` honour a supplied path. | [board backlog § D](2026-09-15-board-backlog.md) |
| **The 20-lane cannot be traversed** | `private.check.user.mode.release` and `private.check.user.mode.dev` are registered as CONSECUTIVE states (`oo:1473-1474`). One demands the host be on prod, the very next demands it be on dev. A host cannot be both, so that lane has been unfinishable since it was written — it stalls either way, and `oo:1442-1449` aborts advancement on a stuck state. Found while doing T7, which changed what the first one asks but not the contradiction. Needs a decision: are these two alternative install flavours that were never branched, or is one of them dead? | — |
| **`config ssh.host.set` gets the wrong host on a remote install** | `ossh:705` does `config ssh.host.set "$sshConfigNameUsedForLocal"`, and `config.ssh.host.set` (`config:1025`) is documented as *"the name of this host for ssh config"* — but on the `ossh install <host>` path that argument is the **runner's** alias, not the target's. It lands right only because the runner's `OOSH_SSH_CONFIG_HOST` is usually unset and `init/oosh:426` turns the `_` placeholder into empty, falling back to `$HOSTNAME`. `~/ssh.root.vm-dev.for.hannesn-VirtualBox` on the dev box is a case where it was **not** unset. Found while doing backlog item 6; deliberately not bundled into it, because it changes remote-install behaviour. Both parameters of `ossh.install.continue.local` are documented in-code now. | [item 6 research § 5](../research/2026-09-16-item6-ssh-backup-naming.md) |
| **Is `OOSH_COMPONENTS_DIR` production config or test noise?** | `config` excludes it from every save on purpose (`config:595`, reason at `config:571`, documented at `docs/config.md:215` as a transient `/tmp/test.oo.*` path) while `oo.mode.base.set` exists to set it and `oo.mode.base.get` reads it as strategy 1. Two subsystems, incompatible beliefs, and the exclusion wins silently. Item 7 stopped the false claims (`mode.setup`'s `config save` deleted, `base.set`'s docstring corrected) and made the layout canonical so the variable is no longer needed on that path — but the disagreement itself is untouched. Either it leaves the exclusion list, or `oo.mode.base.set` goes. Shared-config policy, which T7 also touched. | [item 7 research § 3](../research/2026-09-16-item7-oo-mode-setup.md) |
| **`this.absolutePath` answers `$PWD` for a path that is not there** | It `cd`s to the `dirname` and, when that fails, `pwd` returns the CURRENT directory — so canonicalising a nonexistent path silently yields a completely different one, with only a `cd:` line on stderr (`this:805`). `odocker.workspace.set` is safe by accident (it checks `-d` first) and `odocker.workspace.get` now canonicalises only when the path exists, but any future caller inherits the trap. Either it returns non-zero for an unresolvable path, or its docstring says plainly that it requires an existing one. | [item 8](../plans/2026-09-15-board-backlog.md) |
| **Two parallel workspace enumerators in `odocker`** | `private.odocker.workspace.list` (`odocker:116`) and `odocker.workspace.list` (`odocker:195`) each carry the same hard-coded two-level glob (`*/` and `*/*/`), one emitting machine-readable lines and one a formatted table. A three-deep workspace is invisible to both, and a fix has to be made twice. The public one should render what the private one enumerates. Found while doing backlog item 8. | — |
| **Callers of `oo cmd` act on its status** | `oo cmd` reports failure since `8928c3e`, but 8 of 12 live call sites still ignore it: `oo:1976-1977`, `oo:2979`, `os:98`, `os:203`, `ossh:1910`, `ossh:1932-1933`. Per file, with a platform run for the install-path ones. | — |
| **`check.file` warning + `log`'s hardcoded `~/config`** | `check file <f> exists` warns "The filesystem is case insensitive and the case sensitive file … DOES NOT exist!" for *any* absent file (it is on `test.suite`'s handoff probe again since `87a84ca`; silent at level 1). Separately `log` writes `~/config/result.txt` / `error.txt` by a hardcoded tilde path at `log:147,159,193,205,232,285` — a production violation of "never hardcode config paths" that `CONFIG_PATH` fixtures cannot redirect. | — |
| **`config.save` F4 + F5 + F6 — card 2** | `config.save` runs `config.validate` on what it wrote and discards the verdict (`>/dev/null 2>&1` + `warn.log`) — the guard caught the macOS corruption on the first install and nobody heard it. `config init.env`, the repair `config validate required` advertises, leaves `oosh.env` EMPTY and one variable worse, because it persists an environment the broken files failed to populate. And the required-variable table's *re-derivation* column has no consumer. | [research § 6](../research/2026-09-17-config-save-bash32.md) |
| **`config.string.quote` is lossy** | `config:163-166` ends `echo $RESULT` **unquoted**, so `"a␣␣␣␣b"` → `'a b'` — it destroys whitespace runs and would corrupt any value passed through it. It was the nearest-miss helper for the bash-3.2 ticket and had to be rejected. Fixing it changes T25/T26 semantics, so it was not bundled. | [research § 13](../research/2026-09-17-config-save-bash32.md) |
| **`BASH_MINIMUM_MAJOR_VERSION` is dead** | `config.bash.minimal.version` (`config:780`) is the only writer and nothing in the tree reads it. It also appends straight to `$CONFIG` rather than going through `config.set`, so it duplicates the line on every call. Either it becomes a real guard or it goes. | — |
| **`templates/code` has no `newGetterTest`** | `newMethodTest` assumes a `create.result` method: `expect 0 "<result>"` compares `$RESULT`, which a getter never sets, so a generated case for a getter compares whatever the PREVIOUS test left behind — a test that cannot fail, the same defect as the "Tests that cannot fail" card. Four were generated and removed by hand during the bash-3.2 ticket. | — |
| **`replace` cannot target one of two identical adjacent lines** | `replace block` requires each anchor to match exactly one whole line, so there is no way to address the second of a duplicated pair. Collapsing one needed raw `python3` — the only edit in the bash-3.2 ticket that did not go through an oosh command. | — |
| **Which install step runs `config.save` under `/bin/bash`?** | Every oosh script carries `#!/usr/bin/env bash` with no version guard or re-exec, and root's PATH during a macOS install has no `/opt/homebrew/bin` — so the install runs under 3.2 while `docs/supported-platforms.md:5` declares bash 4.0 the minimum. `~/config/install.log` records nothing at the level the install ran. The bash-3.2 ticket makes this harmless rather than answering it. | [research § 8 Q2](../research/2026-09-17-config-save-bash32.md) |

---

## 4d. The 2026-09-14 revert, and the regression that caused it

**What happened.** A container platform run showed `test.ssh.config.woda.portable` failing 4× — the
WODA `~/.ssh/config` Host aliases missing for every user except `root`. The day's code was reverted
to `a824d8e` rather than shipped with an unexplained regression.

**Established, so it need not be rediscovered:**

| | |
|---|---|
| **Window** | `5e44f2b..f7607fe` (9 commits). `a824d8e` is **proven green**: 12 `✓ PASS: … IdentityFile is portable`, zero real failures |
| **Ruled out** | `boot` restore mode — the failures were identical after `f7607fe` fixed its real bug |
| **NOT evidence** | `ERROR> osshLayout.build failed` (3×) and `user init … did not complete` (10×) appear in the **green** run too — pre-existing noise, not the cause |
| **Works standalone** | running `user init` by hand for a fresh user writes all three WODA blocks |
| **Trap** | manual `user.oosh.install` does **not** reproduce install-time behaviour. Two A/B tests built on it (reverting `line`, then `user`) produced false exonerations. A real bisect needs one platform run per commit |

**Fixes given up with the revert** — each still described in its ticket, so redoing them is
re-applying, not re-investigating:

- shared/per-user env-file separation — the `/root/.config/oosh/log.session.env: Permission denied`
  errors across users **return**;
- honest ERR-trap diagnostics — `env`/`grep` are again reported as "Command not found" /
  "Misuse of shell builtins" when they ran fine;
- `this.help` — stays broken for `config`, `this`, `oo`, `ossh`, `user` (one apostrophe in one
  docstring breaks it for a whole script), and `lineFormat.env` stays 0 bytes;
- the `oo method.new` repair (see [its ticket](2026-09-14-method-tooling-repair.md)).

**Kept:** the two tickets, the design spec, and every documentation correction that is true
independent of the code — 17 stale `oo new.method`/`oo new.test` references (renamed in `2fe5133`,
March 2026) across 7 files, and `oo mode.dev` → `oo mode dev` in `docs/oo.md` for a method that has
never existed.

---

## 5. Standing verification bar (every ticket)

- `./test.suite core 1` → **zero real failures** (1 intentional meta-test expected; 613 pass at time of writing)
- `bash -n` / `sh -n` on every touched script; `dash -n` for boot-related work
- `os platform.test ubuntu_24_04` for anything install-affecting
- Bare-Ubuntu wget install for boot/entry-point tickets:
  ```bash
  docker run -it --name bare-ubuntu ubuntu:24.04 bash
  apt update && apt install -y wget
  sh -c "$(wget -O- https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/dev/init/oosh)"
  ```
- Interactive checks in the tmux pane

---

## 6. Change log

| Date | Change |
|---|---|
| 2026-09-10 | Document created; board oriented; T4+T5 moved to In Progress |
| 2026-09-10 | First T4+T5 attempt (`6ada741`) built on the WRONG rule (resolved target); reverted in full (`ba355b7`) and rebuilt on `OOSH_DIR` = the `~/oosh` symlink itself |
| 2026-09-10 | T4+T5 landed (`2045811`). Follow-up in the same pass: `CONFIG_PATH` put under the same rule; guard generalised to `this.anchor.validate` |
| 2026-09-10 | `os platform.test ubuntu_24_04` green against both commits (rc=0, zero real failures across all 4 container users) → **T4+T5 moved to In Review** |
| 2026-09-14 | **T3** taken next at the user's request (out of the original order). Tracker's "already passes today" claim corrected: 2 real defects found and fixed (`boot` rc 1 on success; no-`HOME` killed the sourcing shell). → In Review |
| 2026-09-14 | T3 landed (`a824d8e`); platform test green (rc=0, zero real failures across all 4 container users) |
| 2026-09-14 | The card finally read correctly — `env -i` is **env initiate**, and it means RECOVERY. `config.env.init` + `boot` restore mode landed; `env -i sh <tree>/boot` brings a wrecked box back |
| 2026-09-14 | **Reverted to `a824d8e`** after an unexplained WODA regression in the container. Knowledge kept, code rolled back — see §4d |
| 2026-09-14 | User tested `env -i sh` in a container: a refusal is not a boot. T3 scope corrected — `boot` now DERIVES `$HOME` from the passwd database instead of failing fast; `env -i sh` boots correctly in all four shells |
| 2026-09-14 | T3 review round: quality review found the re-exec required the exec bit (breaking `ossh prereqs.install`, whose `scp` has no `-p`), dropped `sh -x` from the documented debug command, and left `PATH` unseeded so an arm64 macOS root install would re-bootstrap Homebrew and die. Fixed in `7e88ec4` by naming an interpreter, forwarding `$-`, and seeding a fixed PATH. Also `getent passwd` multi-line (LDAP+files) poisoned `$HOME` recovery in BOTH files — `head -1` added. Platform test re-run green. |
| 2026-09-14 | **Guarantee scoped by the user: clean-plus-pass-through, not strictly clean.** `env -i` strips the environment of every child the installer spawns, so `LOG_LEVEL`, `TERM` (as `${TERM:-dumb}` — empty behaves worse than unset), `LANG`/`LC_ALL`, the three proxy vars, `SSH_AUTH_SOCK` and `GIT_SSH_COMMAND` now cross. `GIT_ASKPASS` deliberately does not: it names a binary, and PATH is reset in the same breath. |
| 2026-09-14 | T3 **second attempt**: `boot` + `init/oosh` recover `$HOME`; `init/oosh` re-execs clean without `env -S`, restoring the guarantee `075b4a3` traded away for Alpine. Audit found 531/537 lines of `init/oosh` (at baseline `a6f0ce3`) postdate the shebang removal, and two read-but-never-set variables (`SUDO_USER`, `OOSH_REPO`) that `env -i` would have destroyed silently — both now carried. → In Review, pending the platform test |
| 2026-09-14 | User pointed at the install log's env-file errors. Root cause: the SHARED `log.env` referenced the PER-USER `$OOSH_USER_CONFIG_PATH`, and `user:951` leaked it across users. Shared files now hold only shared data; `boot` sources the per-user file itself |
| 2026-09-14 | User queried the last two error lines in tmux. Neither was a real failure: the ERR trap's `errno()` glossed propagated exit statuses as "Command not found" / "Misuse of shell builtins". Now verifies before diagnosing; hoisted to `private.debug.errno` and tested |
| 2026-09-14 | **Review pass** on the day (all of T3 + T9, net of the revert). Two defects found and fixed: the clean re-exec erased `USER` (root installs with no later sudo hop were routed to the user lane — `this` now heals it like `$SUDO`) and set every pass-through variable EMPTY (`GIT_SSH_COMMAND=""` made git run `''`; state 31's ssh clone always fell back — only set variables cross now). Then: one boot-from-nothing test harness, one base+branch derivation, one privilege rule, the drop-in as a template, `test.tilde` a real test, symbol citations, `T-BOOTPATH-*` ids, diagram family renamed, docs de-duplicated (`install-bootstrap.md` split out of `boot.md`). Host `test.suite core 1` after the pass: 642 assertions / 641 passed / 1 intentional — the earlier 643/642/1 included the 31 phantom assertions `test.tilde` inherited. T3/T9 stay **In Review**; the platform test must be re-run, once with a ROOT ssh target. |
| 2026-09-15 | **Backlog grounded** ([board backlog](2026-09-15-board-backlog.md)); tickets 1 + 3 (no card) and 2 (`oo cmd`) landed `afa452c` … `8d1617c`. **Afternoon conformance review of the morning** (`87a84ca` … `8e3c9cc`): runner back on `check file … exists`; `config.isolate` chaining fix; `private.oo.cmd.verify` a logging-free predicate, its `>/dev/null 2>&1` gone; `ossh.prereqs.install` calls `oo.cmd` in-process; T47/T50 skip-guards outside the case (they were the "extra" reds on alpine/almalinux); six in-file `T-CMD-CONTROL-*`. Ubuntu gate on `8d1617c` PASS ×4 users (the morning never ran it). Host core on `8e3c9cc`: 661/660/1. Backlog order corrected to **T7 before T8**; three cards proposed in § 4c. No hard reset. |
| 2026-09-15 | **Three-platform gate on `9c05878`: PASS** — ubuntu_24_04, alpine_3_19, almalinux_9, all four users each, only the intentional meta-test failure (661/660/1 for the `test` user, 666/665/1 for root/oosh-user/bash-user — the +5 is `test.c2` in containers). The former alpine/almalinux reds now read `T47 skipped` ×8 and `T50 skipped` ×4. Also fixed: CLAUDE.md's `./otmux sendEnter` (dead name) → `./otmux send.enter`. |
| 2026-09-16 | **Runner-level shared-tier guard** (`cff3bb5`…`b1003c7`) and **`oo method.new` repaired** (`7f93f4b`…`f386f87`). The isolation card was delivered as a canary rather than as default isolation — see § 4c for why the proposed design was wrong. First catch: `test.odocker` had been rewriting the site-wide `user.env`. The platform gate then caught a defect in the guard itself (mtime in the fingerprint, cascading on alpine), which is what the gate is for. Method tooling: multi-segment names, the docstring as the single source, a mandatory completion stub per parameter, the usage-table edit deleted rather than repaired, and two ways `replace` could destroy the script it was editing. Host core 665/664/1 → 672/671/1 intentional across 27 files. |
| 2026-09-16 | **T7 delivered** (`fee9513`…`5fbb513`). `OOSH_BRANCH` is install INPUT and no longer persists; `OOSH_MODE` means the branch a host is on and the release lane asks for `prod` instead of a word promote stamped in after checking the tree back out to dev; `config.init` honours an anchor it is given, which is what finally made `config` fixture-able; `config validate required` declares the positive variable set and reports branch drift. **Both shared-tier waivers deleted and a core run now reports no `Shared tier:` line at all** — a pre-existing guard falling silent, which was the ticket's cheapest proof. Two things found on the way: an empty fixture is not isolation (test.config lost its PM cache and sat on a `sudo apt-get update` prompt — fixtures are seeded now), and the 20-lane is unfinishable by construction, filed in § 4c. core 674/673/1 → 680/679/1 intentional. |
| 2026-09-16 | **T8 delivered** (`2471b43`…`0821802`). `boot` is now the STATED single owner of PATH, with `path validate` enforcing it the way `this anchor.validate` enforces the anchors — but as a **writer sweep**, not a value check, because PATH is an accumulation and there is no value to compare. 55 violations to 0: two conforming sites in `boot`, 57 declared exceptions, two whole-file exemptions (`init/oosh`, and `init/once`, which is in `.gitignore` but still tracked — a correction to the research doc). `path` shrunk from 26 definitions to 11 and stopped claiming a persistence it never had. Two defects beyond the card: `.` came off the PATH (CWE-426, and it fired during every install), and `claudeCode` stopped writing `export PATH=` into an env file. Three tools were built first because the ticket could not be done conformantly without them — `line.remove.exact`, `replace block`, and `oo method.delete`, the missing member of the `oo new` family. core 680/679/1 → 694/693/1 intentional. |
| 2026-09-16 | **Backlog item 6 — research doc** ([the `ssh.<user>.<host>.for.<host>` directory](../research/2026-09-16-item6-ssh-backup-naming.md)). The card lists three defects; there are **six**. Defect 1 (`$USER` unset → `ssh..`) is **already dead** — measured three ways, because `this:74-77` heals `USER` at file scope and both live routes pass through `this`. The new ones: the guard tests `$HOME/ssh.<name>` while the writer writes `./ssh.<name>`, so it **can never be satisfied** and the backup fires on every install, **nesting one level deeper each time** (`ssh.X/.ssh/.ssh/…`, each layer a full copy of the keys); `user.ssh.restore` does `rm -Rf $sshDir` *before* a cwd-relative `cp`, and has zero callers; and three root-owned `0700` copies of root's `~/.ssh` sit in `/home/hannesn` right now, unreadable by its owner. Also found: the backups are **write-only** — nothing in the tree ever reads one — and the audit already classifies backup-before-overwrite as LEGIT where it sits, which reframes the placement question. Three questions open; the cleanup is decided and in scope. No code. |
| 2026-09-16 | **Backlog item 6 delivered** (`6ad508e`…`1122808`). The SSH backup is a `$HOME`-anchored timestamped archive under `~/.ssh.backups/`, which fixes the root-keys-in-a-user's-home defect **by construction** — during a root install `$HOME` is `/root` whatever the operator's cwd. The pre-install snapshot **moved into state 31**: `ssh.original` ran after `oo state`, and state 31 writes `~/.ssh` at `oo:2066`, so it was never original; it is now the first thing that state does, fail-loud. A new state was not an option — `private.check.priviledges.checked` branches, so the 10-lane is unreachable past it, and inserting before it renumbers a state twelve files name by number. `.for.` retired without moving an argument: the install runs ON the target, so it named the host the directory already sat on. `user ssh.backup.status` / `.migrate` clean up what is on disk, unprivileged report first, move-never-delete second. Two prerequisites cleared: `test/test.user` blocked on a sudo prompt from a fixture (`OOSH_PM_UPDATED`) and had no `TEST_CATEGORY` — it is in `core` now; and `user`/`test.user` had neither insertion marker, so `oo method.new` could not write into them. Ten tests where there were none. core 695 → 727 assertions, 27 → 28 files. **Ubuntu gate PASS**: a real install puts the archives in root's own home and leaves NO `ssh.*` in any home; in-container core 731/730/1. One finding filed rather than fixed: `config ssh.host.set` gets the runner's alias on a remote install (§ 4c). |
| 2026-09-16 | **Backlog item 7 — research doc** ([`oo.mode.setup`](../research/2026-09-16-item7-oo-mode-setup.md)). Three of the card's claims corrected: there are **four** `oo.mode.base.get` strategies, not three, and the first keys on `$OOSH_COMPONENTS_DIR` rather than on a directory named `main`; there are **four** T-SETUP tests, of which only one is literally wildcard-vacuous. The sharper defect the card does not name: `mode.setup` builds `<base>/dev` with no `main`, so strategies 2/3/4 cannot match, and its only bridge is `OOSH_COMPONENTS_DIR` — which `config` **excludes from every save by design** (`config:571,595`, documented at `docs/config.md:215` as test noise). Measured: `base/dev` alone gives base.get **rc 1**; with the variable exported, rc 0. So the command whose own failure message tells you to run it produces a layout that re-creates that failure one shell later. Also recorded: four unguarded `mv`s where a pre-existing destination nests the live tree and a failed move still deletes and re-points `~/oosh`; T-SETUP-2 tests a git check that does not exist; T-SETUP-4's post-condition would be satisfied by a bare `mkdir` and never checks base.get; and **no test anywhere exercises strategies 2/3/4**. Three questions open. No code. |
| 2026-09-16 | **Backlog item 7 delivered** (`ff465db`…`eabf472`). `oo.mode.setup` delegates its layout half to `private.oo.shared.tree.from.local`, so there is **one** definition of canonical and it is the one install state 31 produces. All four `mv`s of the live tree are gone. What the research did not foresee: delegation does not fit in one call — when the clone already sits at `<base>/<branch>`, `git worktree add ../<branch>` collides with it (measured: rc 1). The source has to go BETWEEN the copy and the worktree-add, which is also the ordering the boss asked for, so the helper gained `<?consumeSource:no>` — verify `main/` is a real repository, then remove, then build. Default `no`, so state 31 is unchanged. **The acceptance criterion is enforced twice**: `mode.setup` verifies `oo.mode.base.get` resolves with `OOSH_COMPONENTS_DIR` unset before touching `~/oosh`, and T-SETUP-4 asserts it end to end — its old post-condition would have been satisfied by a bare `mkdir`. Six other checks added (argument validation, a canonical already-set-up guard that runs before branch detection, a non-repository `main/` refused, rc-checked symlink swap, and the result contract it never had). `oo.mode.base.set`'s "and persist" docstring corrected. test.oo 132 → 140, including four `T-BASE-GET` cases because **nothing** exercised strategies 2/3/4. core 727 → 735 assertions. One card filed, not fixed: is `OOSH_COMPONENTS_DIR` production config or test noise (§ 4c). |
| 2026-09-16 | **Backlog item 8 delivered** (`54bc6ba`…`39f4ad4`). The card asked for `workspace.init` and for `workspace.get` to stop ignoring its argument; both done, and both `get` defects proven **red against the old code** before the fix. `init` delegates to `workspace.set` wholesale, so canonicalisation and the persistence trio keep one definition each; `get` also reports whether the root is **usable**, because it used to print a directory that was not there while `workspace.list` and `build` failed against the same value. **The bigger find was the template**: `templates/code/newScriptTest` carried no `test.suite.save.results` and no `TEST_CATEGORY`, so every generated test file was born score-less — which is why **twelve** files in `test/` report 0 / 0. Template fixed. Giving `test/test.odocker` a score exposed **nine** assertions failing invisibly, all defects in the test file: two dead function names (`private.odocker.workspaces`, `private.odocker.image.from.workspace`), three demanding method-specific completions where c2 and the audit both accept the shared form, and two demanding rc 1 from `up`/`down` where they deliberately show a picker and return 0. Two corrections to the card: the shipped default **does** exist here, and `this.absolutePath` answers `$PWD` for a nonexistent path — filed in § 4c with the two-enumerators finding. core 828 → 836 assertions, 28 → 29 files. |
| 2026-09-16 | **Backlog items 9 and 10 delivered** (`3a4a1b4`…). Item 9 was documentation only and `oo.checkout` turned out to be one of the good citizens — `create.result` on every branch, `return $(result)` at the end, and a deliberate refusal to pull, because pulling belongs to `oo update` and merging to `promote`. `docs/oo.md` gained `### oo.checkout` and `### oo.use`, plus three things beyond the card: `### oo.method.delete` (created Tuesday, documented only in a commit message), a table for the rest of the mode family, and a warning section for `tmp.cleanup.testing` / `install.dev` / `install.dev.keys` — verbs tab completion offers with nothing behind them, one of which removes oosh and the SSH keys. One naming drift fixed: the section titled `oo.find.cmd` documented a verb that has never dispatched; the method is `oo.cmd.find`. Item 10 was a note: the decision to keep per-host `ossh` configs in the repo, and its two consequences, are now in § 4b. No code change in either. |
| 2026-09-16 | **T6 — the last card.** The diagram itself was **redrawn by the user** (`docs/puml/bootstrap.sequence.drawio`, six lanes, current with `boot` — it carries the anchor rule, the pure-data env chain, the colon-guarded PATH, the bare-`sh` skip, and the `this call … then exit` step that replaced the *"starts new bash"* the 2026-09-08 notes flagged). This pass did the rest: **`.drawio` declared the single source of truth** — `boot.md` § See also had the ownership backwards, calling the pre-`boot` `.puml` the source and the `.drawio` an "editable copy" — the `.puml` and its April renders marked `SUPERSEDED` in their own header rather than deleted, a `wiki-index` link where there was none, and **three labels corrected that this week's own tickets invalidated after the diagram was drawn**: the `.for.` backup name and its unsatisfiable guard (item 6), the `.` on PATH (T8, CWE-426), and state 31's new first step (item 6). The `.svg` was deliberately not regenerated — a render pipeline for `.drawio` is its own tooling decision, and the stale renders now say so. One box left open on purpose: **the user confirming the diagram is correct**, which was the card's original question. |
