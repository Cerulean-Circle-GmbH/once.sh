# Design: recovering a broken oosh from a bare shell

**Date:** 2026-09-14 · **Branch:** `dev` · **Ticket:** T3 — `env -i sh. SAVETY...shall boot correctly`

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

## Prerequisite: restore the method-creation machinery

`docs/command-creation.md` and `docs/first-principles.md` mandate `oo.new.method` for adding
methods. It is documented in six files, including its own section in `docs/oo.md` — and it does not
exist. Neither does a dispatchable `oo new.test` (only `private.oo.new.test`). And no core script
carries the `### new.method` marker such a tool inserts at.

That is why methods in this codebase get hand-written. It must be fixed **first**, or this work
repeats the same violation:

1. **`oo.new.method <script>.<method>`** — build it to the contract already published in
   `docs/oo.md`: prompt for method description and parameters, test description, test parameters,
   expected result; insert from `templates/code/newMethod` at the target's `### new.method` marker;
   append the matching case from `templates/code/newMethodTest` to `test/test.<script>`. It mirrors
   the existing `oo.new` / `private.oo.new.test` pair exactly.
2. **`oo.new.test`** — promote `private.oo.new.test` to the documented public method (keeping the
   private one as the implementation), so `oo new.test` dispatches as `docs/oo.md` says.
3. **`### new.method` markers** — add to `config`, `this`, `log`, `debug` (`oo` and the rest already
   have them), so methods can be inserted where this work actually lands.

## Design

### Trigger — narrow, so it never fires on a healthy shell

`boot` engages recovery only when **all** hold:

- running under **bash** (POSIX `sh` cannot portably know a sourced script's path);
- the directory `boot` was sourced from is a **real oosh tree** (`this`, `config`, `oo` present);
- the **anchors** are broken — `~/oosh` does not resolve to an oosh tree, **or** `~/config` is not
  a directory.

A healthy shell fails the third test immediately: no dispatch, no output, no cost.

**Deliberately *not* a trigger: missing env files alone.** If the anchors resolve and only the env
files are gone, `config reconstruct` (shipped today, `8b668c6`) already owns it — no symlink
surgery is needed or wanted. Disjoint triggers mean exactly one mechanism per failure.

### `config.env.init` — composition, not new logic

Written to `templates/code/newMethod`: `create.result` / `return $(result)`, a completion stub, and
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
- Recovery is **bash-only**. Acceptable: oosh requires bash 4+ to run at all.
- `boot`'s automatic check remains *existence only*. A present-but-corrupt file is caught by
  `config reconstruct` / `config init.check` when run explicitly, not at every shell start.

## Testing

Test cases are generated by `oo new.method` from `templates/code/newMethodTest` into
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
| `config init.env` alias | still dispatches, delegating to `config.env.init` |
| `this.anchor.validate` | still green — the `BASH_SOURCE` use is a marked exception |

Each guard is proven able to **fail** before it is trusted, against a deliberately broken fixture.

End-to-end: wreck a fixture `$HOME` (real-dir `~/oosh`, no `~/config`, no env files), source `boot`
from the tree by absolute path under `env -i`, and assert a working oosh comes out.

Prerequisite work is tested too: `oo new.method` generating a method + its test into a fixture
script, and `oo new.test` dispatching.

## Methodology debt this exposes (recorded)

Everything added to this tree today — `this.anchor.validate`, `config.reconstruct`,
`private.debug.errno` — was hand-written rather than generated from `templates/code/newMethod`,
because the tool that does that does not exist. The prerequisite above repays that. Two smaller
items found alongside it, not fixed here:

- `config.init.shared` / `.user` / `.check` / `.full` are all **verb.noun**, the same inversion as
  `config.init.env`. Flipping the whole family touches the install path and every call site, so it
  is left for a deliberate pass rather than bundled in.
- `docs/oo.md` documents `oo new.test` as public while only `private.oo.new.test` exists — fixed by
  the prerequisite, but a reminder that docs and code drift silently without a test pinning them.

## Relationship to today's work

Five commits landed today, four of which fixed defects independent of this misreading and stay:

| Commit | Fix |
|---|---|
| `a824d8e` | `boot` returned **rc 1 on success** under sh/dash/ash — five production sites took their "boot failed" branch on every successful boot |
| `5e44f2b` | `$HOME` derived from the password database, so `boot` works with `env -i` |
| `626b75a` | a **shared** file referenced a **per-user** variable → `/root/.config/oosh/log.session.env: Permission denied` across users |
| `250031e` | the ERR trap fabricated diagnoses (`env` → "Command not found", `grep` → "Misuse of shell builtins") |
| `8b668c6` | `boot` reconstructs missing env files — the one built on the misreading; harmless and useful, and the automatic counterpart to this design |

## Open question for the boss

This design keeps the env files pure and makes **`boot`** the initiation, satisfying both rulings.
If the intent of the card was instead that **the env files themselves** must stand alone again,
that is a partial reversal of the accepted `NEVER logic in ENV FILES` ticket and should be his
call, not ours. The evidence above is written so it can be taken to him as-is.
