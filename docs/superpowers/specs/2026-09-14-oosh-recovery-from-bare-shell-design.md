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

## Design

### Trigger — narrow enough never to fire on a healthy shell

Recovery engages only when **all** hold:

- `boot` is running under **bash** (POSIX `sh` cannot portably know a sourced script's path);
- the directory `boot` was sourced from is a **real oosh tree** (contains `this`, `config`, `oo`);
- the **anchors** are broken — `~/oosh` does not resolve to an oosh tree, **or** `~/config` is not
  a directory.

A healthy shell fails the third test immediately: no subprocess, no output, no cost.

**Deliberately *not* a trigger: missing env files alone.** If the anchors resolve and only the env
files are gone, that is already handled by `config reconstruct` (shipped today, `8b668c6`) — no
symlink surgery is needed or wanted. Recovery is strictly the harder case: *the anchors themselves
are wrong*. Keeping the two triggers disjoint means exactly one mechanism owns each failure.

### Repair — composition of what already exists

| Step | Reuses |
|---|---|
| confirm a real oosh tree | plain tests; refuse rather than guess |
| `~/oosh` → the tree `boot` was run from | `private.this.symlink.with.backup` (`this:170`) — preserves any real entry as `.orig.<ts>` |
| `~/config` → `sharedConfig` | `config.init.user` (`config:216`) |
| env files | `config.init.env` (`config:407`) |
| verify | `config.init.check` (`config:350`) |

Recovery therefore is: set `OOSH_DIR` to the known-good tree → source `this` + `config` from it →
run the repair family → continue `boot`'s normal path. Almost no new logic; the value is in the
*trigger* and the *ordering*, not in new machinery.

### Safety

- **Loud.** It moves symlinks; every change is announced via plain `echo` (status-output idiom —
  it must survive any `LOG_LEVEL`).
- **Never deletes.** Pre-existing real entries are preserved as `.orig.<ts>`.
- **Refuses rather than guesses** when the directory is not a real oosh tree.
- **A full `config init.env` is justified here** — unlike the automatic path (`config reconstruct`,
  added earlier today), where the rule is *never rewrite a populated shared config*. The difference
  is intent: recovery is an explicit act, invoked by absolute path by a human who has decided the
  box is broken. It must still say that it is doing it.
- `OOSH_BOOT_NO_RECONSTRUCT=1` disables recovery as well as the automatic reconstruct.

### One sanctioned rule-break

Recovery derives `OOSH_DIR` from `BASH_SOURCE`, which **T4+T5 explicitly forbids**. That is the
point: on a broken box `~/oosh` is precisely what cannot be trusted. It carries an in-code
`# oosh-dir-exception: <reason>` marker, so `this.anchor.validate` stays green and the exception is
visible to the next reader.

## Known limits (stated, not solved)

- You must know **a** path to the tree to start. No mechanism solves that; it depends on the path
  being documented and stable. Discovery heuristics were rejected deliberately — on a box where
  "almost nothing" survives, every heuristic is a guess that can be wrong, whereas the directory
  `boot` was run from is known with certainty.
- Recovery is **bash-only**. Acceptable: oosh requires bash 4+ to run at all.
- `boot`'s automatic check remains *existence only*. A present-but-corrupt file is caught by
  `config reconstruct` / `config init.check` when run explicitly, not at every shell start.

## Testing

| Test | Asserts |
|---|---|
| healthy shell | recovery never engages; `boot` stays silent |
| `~/oosh` a real dir, not a symlink | repaired to a symlink; the real dir preserved as `.orig.<ts>` |
| `~/config` missing | repaired; env files rebuilt; `config.validate` passes on all three |
| anchors fine, only env files missing | recovery does **not** engage — `config reconstruct` owns that case |
| directory is **not** an oosh tree | refuses, says why, changes nothing |
| `OOSH_BOOT_NO_RECONSTRUCT=1` | recovery disabled |
| `this.anchor.validate` | still green — the `BASH_SOURCE` use is a marked exception |

End-to-end: wreck a fixture `$HOME` (real-dir `~/oosh`, no `~/config`, no env files), source `boot`
from the tree by absolute path under `env -i`, and assert a working oosh comes out.

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
