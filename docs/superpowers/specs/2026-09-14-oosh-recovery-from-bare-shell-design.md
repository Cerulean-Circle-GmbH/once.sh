# Design: recovering a broken oosh from a bare shell

**Date:** 2026-09-14 · **Branch:** `dev` · **Ticket:** T3 — `env -i sh. SAVETY...shall boot correctly`

> **Status (2026-09-14): designed, implemented, reverted.** The implementation
> (`5f5a8bc`, `f7607fe`) was rolled back with the rest of the day's code after an unrelated
> regression appeared in the same commit window and could not be isolated — see
> [the boot-tickets tracker](../../plans/2026-09-10-oosh-boot-tickets.md). **The design and the
> ruling below stand**; nothing here was found to be wrong. What was lost is the code, not the
> reasoning.
>
> Two implementation lessons worth carrying forward:
> - `boot` must put the tree on **PATH** before dispatching `config`, or `config.start`'s
>   `source this` fails. A host test masked this for a whole cycle because it ran with the tree as
>   the current directory, and bash's `source` falls back to the cwd. Tests must `cd` elsewhere.
> - Restore must **not** fire when `boot` was reached *through* `~/oosh` — that is an ordinary
>   boot, and firing there puts it in the installer's way.

## Context

T3's card was misread for most of a day. `env -i` is not the shell's `env -i`, and not "install" —
it is **"env(ironment files) — initiate"**. The user was using `env -i sh` to *simulate* a machine
with nothing set up, and checking whether oosh could still come back.

Why it "works in older branches": on `prod`/`testing`, `config.save` emitted **self-anchors** into
the env files —

```sh
: ${CONFIG_PATH:="${BASH_SOURCE[0]%/*}"}
: ${OOSH_DIR:="$(cd "$HOME/oosh" 2>/dev/null && pwd -P || echo "$HOME/oosh")"}
```

— so sourcing `~/config/user.env` from *any* shell stood the environment up. The env files
initiated themselves. On `dev` that was removed by the **`NEVER logic in ENV FILES`** ticket
(Done, accepted); the env files became pure data and `$OOSH_DIR/boot` took over. Measured today:

| | `prod` / `testing` | `dev` |
|---|---|---|
| `. ~/config/user.env` from a bare shell | stands up the environment | **fails** — `cannot open /oosh.env` |
| `. ~/oosh/boot` from a bare shell | n/a | all anchors correct |

`macos-latest` CI does not exercise the old path either: its workflow sources `oosh/boot` in 8
places and `config/user.env` in 0.

## Ruling (2026-09-14)

Put to the user, answered: **`boot` is the accepted "env initiate".** The env files stay pure data;
the `NEVER logic in ENV FILES` ticket is **not** reversed. And — *"`env -i sh` should restore things
if it is broken."* That is this design, and it settles the entry-point question below.

## The actual need

Established by asking, not assumed:

1. **Recovering a broken machine** — getting back to a working oosh *without reinstalling*.
2. **From a bare shell** — the box is broken enough that oosh commands do not work; `config
   init.full` is unreachable.
3. **Assume the worst** — `~/oosh` and `~/config` may be missing, dangling, or real directories;
   the env files may be absent or wrong.

This is a **rescue entry point**. It is not about interactive `env -i sh`, which runs no startup
file and will always yield a bare prompt regardless of what oosh does.

## Method and naming

The card's `env -i` is **`env init`** — noun `env`, verb `init`. Today that capability exists as
**`config.init.env`**, which is *verb.noun*, the inversion the boss checks for (`oo user.fix`, not
`oo fix.user` — see `docs/oosh-architecture.md`). So the deliverable is named as the card names it:

| | |
|---|---|
| **`config.env.init`** | the card's `env -i`. Initiates the env files; when the anchors themselves are broken, repairs those first. One command, noun.verb. |
| `config.init.env` | kept as a thin deprecated alias delegating to `config.env.init`, so the install path and six docs pages do not break. |

`boot` does not implement any of this. It **detects** and **dispatches** — `"$OOSH_DIR/config" env.init` —
keeping the logic in a method where it is completable, testable and documented, per
`docs/first-principles.md` ("DRY: information about commands, parameters and defaults is defined
only once — in the code itself. The completion engine reads this directly").

## Dependency: the method-creation tooling

`config.env.init` must be generated through `oo method.new` from `templates/code/newMethod`, not
hand-written. That tooling currently cannot run against any core script — stale docs, a missing
`### new.method` marker, and a `.new` usage-file step with no files left.

That is **its own ticket**: `docs/plans/2026-09-14-method-tooling-repair.md`. This design is
blocked on it for the *generation* step only; the design work below stands independently.

## Design

### Two entry points — because `env -i sh` must be able to restore

A **sourced** script cannot know its own path under POSIX `sh`: `$0` is the shell name (`sh`,
`dash`, `ash`). Only bash exposes `BASH_SOURCE`. But an **executed** script's `$0` *is* its path —
measured in `sh`, `dash`, `bash` and `busybox ash`, including under `env -i`. That gives two routes,
and the second is the one the ruling asks for:

| How you run it | Shell | Knows its path via | Result |
|---|---|---|---|
| `. <tree>/boot` | bash | `BASH_SOURCE` | repairs the box **and** the current shell comes up working |
| `<tree>/boot` (executed) | **any**, incl. `env -i sh` | `$0` | repairs the box on disk, then says: start a new shell |

An executed `boot` is meaningless today — it would set variables in a process that immediately
exits. Restore mode gives it a purpose, and resolves what was otherwise a hard dash limitation.
**This revises the "sourced only" line in `docs/boot.md`'s Guarantees**: sourced is the normal path;
executed is restore.

### Trigger — narrow, so it never fires on a healthy shell

Recovery engages only when **all** hold:

- `boot` can determine its own location (sourced under bash, or executed under anything);
- that location is a **real oosh tree** (`this`, `config`, `oo` present);
- the **anchors** are broken — `~/oosh` does not resolve to an oosh tree, **or** `~/config` is not
  a directory.

A healthy shell fails the third test immediately: no dispatch, no output, no cost.

**Deliberately *not* a trigger: missing env files alone.** If the anchors resolve and only the env
files are gone, `config reconstruct` (shipped today, `8b668c6`) already owns it — no symlink
surgery is needed or wanted. Disjoint triggers mean exactly one mechanism per failure.

### `config.env.init` — composition, not new logic

Generated by `oo method.new config.env.init` from `templates/code/newMethod`: `create.result` /
`return $(result)`, a completion stub, and
its verdict echoed to stdout (the status-output idiom — it must survive any `LOG_LEVEL`).

| Step | Reuses |
|---|---|
| confirm a real oosh tree | refuse rather than guess |
| `~/oosh` → the tree `boot` was run from | `private.this.symlink.with.backup` (`this:170`) — preserves any real entry as `.orig.<ts>` |
| `~/config` → `sharedConfig` | `config.init.user` (`config:216`) |
| env files | `config.save`, as `config.init.env` does today |
| verify | `config.init.check` (`config:350`), and `config.validate` on each file |

### Safety

- **Loud.** It moves symlinks; every change is announced by `echo`.
- **Never deletes.** Pre-existing real entries survive as `.orig.<ts>`.
- **Refuses rather than guesses** when the directory is not an oosh tree.
- A full regenerate **is** justified here, unlike the automatic path where the rule is *never
  rewrite a populated shared config* — the difference is intent: recovery is invoked deliberately
  by a human who has decided the box is broken. It must say so as it does it.
- `OOSH_BOOT_NO_RECONSTRUCT=1` disables recovery as well as the automatic reconstruct.

### One sanctioned rule-break

Recovery derives `OOSH_DIR` from `BASH_SOURCE`, which **T4+T5 forbids**. That is the point: on a
broken box `~/oosh` is precisely what cannot be trusted. It carries an in-code
`# oosh-dir-exception: <reason>` marker so `this.anchor.validate` stays green.

## Known limits (stated, not solved)

- You must know **a** path to the tree to start. No mechanism solves that; it depends on the path
  being documented and stable. Discovery heuristics were rejected deliberately — on a box where
  "almost nothing" survives, every heuristic is a guess that can be wrong, whereas the directory
  `boot` was run from is known with certainty.
- The **sourced** route is bash-only (`BASH_SOURCE`); the **executed** route works in every shell,
  which is what makes `env -i sh` able to restore. An executed `boot` cannot fix the *current*
  shell's environment — only the box — so it ends by telling the user to start a new shell.
- `boot`'s automatic check remains *existence only*. A present-but-corrupt file is caught by
  `config reconstruct` / `config init.check` when run explicitly, not at every shell start.

## Testing

Test cases are generated by `oo method.new` from `templates/code/newMethodTest` into
`test/test.config`, per `docs/test-suite.md` — `test.case` + `expect`, `TEST_CATEGORY=core`,
`test.suite.save.results` at the end.

| Test | Asserts |
|---|---|
| healthy shell | recovery never engages; `boot` stays silent |
| `~/oosh` a real dir, not a symlink | repaired to a symlink; the real dir preserved as `.orig.<ts>` |
| `~/config` missing | repaired; env files rebuilt; `config.validate` passes on all three |
| anchors fine, only env files missing | recovery does **not** engage — `config reconstruct` owns that case |
| directory is **not** an oosh tree | refuses, says why, changes nothing |
| `OOSH_BOOT_NO_RECONSTRUCT=1` | recovery disabled |
| **executed** under `sh`, `dash`, `busybox ash` with `env -i` | restores the box from `$0`, then directs the user to a new shell |
| **sourced** under bash | restores, and the *current* shell comes up working |
| `config init.env` alias | still dispatches, delegating to `config.env.init` |
| `this.anchor.validate` | still green — the `BASH_SOURCE` use is a marked exception |

Each guard is proven able to **fail** before it is trusted, against a deliberately broken fixture.

End-to-end, both routes against a wrecked fixture `$HOME` (real-dir `~/oosh`, no `~/config`, no env
files):

```sh
env -i sh  <tree>/boot          # executed  — restores the box
env -i bash -c '. <tree>/boot'  # sourced   — restores AND the shell works
```

Prerequisite work is tested too: `oo method.new` generating a method + its test into a fixture
script end-to-end, and a test pinning every command name in `docs/` against what `oo` actually
defines — the guard that would have caught the March drift.

## Methodology debt this exposes (recorded)

Everything added to this tree today — `this.anchor.validate`, `config.reconstruct`,
`private.debug.errno` — was hand-written rather than generated from `templates/code/newMethod`,
because the tool that does that does not exist. The prerequisite above repays that. Two smaller
items found alongside it, not fixed here:

- `config.init.shared` / `.user` / `.check` / `.full` are all **verb.noun**, the same inversion as
  `config.init.env`. Flipping the whole family touches the install path and every call site, so it
  is left for a deliberate pass rather than bundled in.
- The March 2026 object.verb refactor (`2fe5133`) renamed 57 methods across 7 scripts and the docs
  were never updated. Only the `oo` ones are fixed here; the other six scripts' documentation
  should be audited the same way, which is why the prerequisite adds a test pinning documented
  names against defined ones rather than just editing prose.

## Relationship to today's work

Five commits landed today, four of which fixed defects independent of this misreading and stay:

| Commit | Fix |
|---|---|
| `a824d8e` | `boot` returned **rc 1 on success** under sh/dash/ash — five production sites took their "boot failed" branch on every successful boot |
| `5e44f2b` | `$HOME` derived from the password database, so `boot` works with `env -i` |
| `626b75a` | a **shared** file referenced a **per-user** variable → `/root/.config/oosh/log.session.env: Permission denied` across users |
| `250031e` | the ERR trap fabricated diagnoses (`env` → "Command not found", `grep` → "Misuse of shell builtins") |
| `8b668c6` | `boot` reconstructs missing env files — the one built on the misreading; harmless and useful, and the automatic counterpart to this design |
