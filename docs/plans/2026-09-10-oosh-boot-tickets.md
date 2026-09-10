# OOSH boot tickets — working document

**Created:** 2026-09-10 · **Board source:** Kanban screenshot 2026-09-10 · **Branch:** `dev`

This is the step-by-step working document for the **remaining OOSH boot tickets**. The board is
the source of truth; this file mirrors it and is updated in the same commit as the work it tracks.

---

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
| 1 | **T4+T5** — `OOSH_DIR` audit + enforce | 🔵 **In Progress** | Core boot mechanism. 14 assignment sites, ~10 non-conforming. Everything below documents or depends on what this settles. |
| 2 | **T7** — config bootstraps branch-version vars / `config init` repairs | 💡 Ideas | Has a live reproducible bug, but its fix needs T4/T5's `OOSH_DIR`+branch semantics. |
| 3 | **T8** — PATH bootstrap + the `path` script | 💡 Ideas | Same "what does `boot` own" theme as T4/T5; natural follow-on. |
| 4 | **T3** — `env -i sh` SAFETY | 💡 Ideas | Verify/close once `boot` is final. |
| 5 | **T6** — `bootsratp.sequence` diagram | 💡 Ideas | Last: it documents the mechanism the four above settle. |

---

## 4. Tickets

### T4 + T5 — `OOSH_DIR` is always `~/oosh` · review all `OOSH_DIR=` 🔵 In Progress

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
| **Guard** | New `this.oosh.dir.validate` (`this`) — one `git grep` over the tracked tree, classifying every assignment conforming / exception / violation, verdict echoed to stdout, rc 1 on any violation. Shaped like `config.validate`. |

`oo.mode.base.get` itself remains legitimate for **locating worktrees**
(`oo:470,518,573,796,912,951,1082,1120`); the ticket forbids only deriving `OOSH_DIR` from it.

**Definition of done.**
- [x] Decision recorded on `oo mode`/`oo use` vs the always-`~/oosh` rule — `oo mode` no longer exports `OOSH_DIR` (the symlink move *is* the switch); `oo use` is a marked exception
- [x] Every remaining non-conforming site either fixed, or justified in-code with a marker
- [x] A test pins the rule — `test.this` T-OOSH-DIR-* (4 cases, including a *planted* violation so the guard is proven to fail); `test.config` T31 asserts `boot`'s literal and delegates the tree sweep
- [x] `docs/boot.md` states the rule and the sanctioned exceptions
- [ ] Standing verification bar passes

**Verification.**
```bash
source ~/oosh/boot && echo "$OOSH_DIR"      # → /home/<user>/oosh  (the symlink itself)
readlink ~/oosh                             # → the branch worktree, NOT ~/oosh
this.oosh.dir.validate                      # → OK: … 0 violations   (rc 0)
                                            #   (`this` is a function in an oosh shell,
                                            #    so call the method directly)
./test.suite run this 1 && ./test.suite run config 1 && ./test.suite core 1
os platform.test ubuntu_24_04
```

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

### T8 — review how PATH is bootstrapped · the `path` script 💡 Ideas

> **Card (Ideas #8):** `review hot PATH is bootstrapped` — `PATH=` — `and the path script`

**Meaning.** Establish a single owner for PATH.

**Evidence.** `boot:59,67` is now the single, colon-guarded, idempotent PATH builder (brew-bash
first). But a separate `path` script (`path.list`, `path.env`, `path.save`, `path.load`,
`path.file.user`…) **also** persists PATH into config — two mechanisms unaware of each other.
`.github/workflows/macos-test.yml` still hand-exports `PATH="$HOME/oosh:$PATH"` in **7** places
*after* sourcing `boot` (review finding **M1**, deferred).

**Definition of done.**
- [ ] Decision: `boot` owns runtime PATH; what (if anything) `path` may persist
- [ ] `path` script reconciled with that decision (or documented as a user-facing tool only)
- [ ] The 7 redundant `macos-test.yml` exports removed or justified
- [ ] Test pins PATH idempotency (extend `test.config` T24)
- [ ] Standing verification bar passes

---

### T3 — `env -i sh` SAFETY, shall boot correctly 💡 Ideas

> **Card (Ideas #3):** `env -i sh. SAVETY...shall boot correctly`

**Meaning.** Booting from a completely empty environment must work, safely.

**Evidence.** Already passes today:
```
env -i HOME=$HOME sh -c '. ~/oosh/boot'
→ OOSH_DIR, CONFIG_PATH, LOG_LEVEL set; ~/oosh on PATH
```
Guarded by `test.config` **T40** (POSIX-sh lint of `boot`) and **T47** (dash sources a *generated*
`user.env`).

**Open question to settle with the user.** What "SAVETY" must additionally cover: no `HOME`?
corrupt/missing config? ash/busybox? a `boot` that returns non-zero (its last statement is an
`&&` list — noted in the 2026-09-09 review)?

**Definition of done.**
- [ ] Scope of "SAVETY" agreed and written down
- [ ] Each agreed case has a test
- [ ] `docs/boot.md` documents the guarantees
- [ ] Standing verification bar passes

---

### T6 — `bootsratp.sequence` diagram 💡 Ideas

> **Card (Ideas #6):** `prod/docs/puml/bootsratp.sequence` `/bootsratp.sequence.svg`

**Meaning.** The bootstrap sequence diagram must match the real (post-`boot`) mechanism.

**Evidence.** `docs/puml/bootsratp.sequence.puml` last changed **2026-03-18** (`9d9b9bb`) — before
the boot loader — and mentions "boot" once. `~/oosh-notes/2026-09-08-oosh-install-break-and-revert-eval.md`
already flags a regression against its `this localInstall → "starts new bash"` step. Docs-only, no code.

**Definition of done.**
- [ ] `.puml` redrawn against `boot` (see `docs/boot.md` §"What it does, in order")
- [ ] `.svg` regenerated
- [ ] Cross-linked from `docs/boot.md` / `docs/wiki-index.md`
- [ ] User confirms the diagram is now correct (this was the original question)

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
