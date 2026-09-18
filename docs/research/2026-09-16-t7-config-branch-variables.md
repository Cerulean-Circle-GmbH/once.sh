# T7 — research: what a config must carry, and who owns `OOSH_BRANCH`

**Written 2026-09-16 · Branch `dev` · Status: research only, no code.**
**Card (Ideas):** `config has to bootstrap always all variables required for a branch version` ·
`conifg init repairs a nonexisting or broken config`

Ticket: [boot tickets tracker](../plans/2026-09-10-oosh-boot-tickets.md) § T7 ·
[board backlog](../plans/2026-09-15-board-backlog.md) § 4.

This document exists because the ticket looks like "add a repair function" and is actually a
question about **ownership**: two variables describe the same thing, one of them has no runtime
writer at all, and the mechanism that keeps them in sync does not exist. Deciding who owns which
has to happen before any code, because the obvious repair — reconcile from `readlink ~/oosh` —
would destroy the install.

---

## 1. The bug, measured today

```
persisted  ~/config/oosh.env : OOSH_BRANCH="prod"   OOSH_MODE="released"
actual     readlink ~/oosh   : …/Once.sh/dev        git branch: dev
```

It is not only on disk. In this very shell:

```
$ env | grep -E '^OOSH_(BRANCH|MODE)='
OOSH_BRANCH=prod
OOSH_MODE=released
```

So `private.oo.install.branch.get` (`oo:1721`) — documented as *"the one rule behind state 31,
state 34 and `oo boot.fix`"* — answers **`prod`** on a `dev` box, because its first line is
`local branch="${OOSH_BRANCH}"` and it only falls back to the checkout when that is empty
(`oo:1723-1727`).

`config.init` (`config:168`) creates the directory, touches `error.txt`, and sets three variables.
On a **missing** config it succeeds emptily: no `user.env`, no `oosh.env`, no `log.env`, and
`$CONFIG` left pointing at a file that does not exist. `config.init.check` (`config:350`) is pure
symlink and group diagnostics, never opens an env file, and always returns 0.

---

## 2. The drift mechanism, named

It is a closed loop, and nothing in it ever consults the filesystem.

1. `boot` sources `user.env`, which chains `oosh.env`. The shell now carries `OOSH_BRANCH=prod`.
2. Something calls `config save` — no-arg, or `config save oosh OOSH`.
3. `config.save`'s filter (`config:561`) excludes `OOSH_DIR`, `CONFIG_PATH`, `CONFIG`,
   `OOSH_COMPONENTS_DIR`, `OOSH_USER_CONFIG_PATH`, the three `LOG_*` per-user values, `*INSTALL*`
   and `SUDO_*`. **`OOSH_BRANCH` and `OOSH_MODE` are not on that list**, so they are written back.
4. `oosh.env` now says `prod` again.

The asymmetry that starts it: **`OOSH_MODE` has three runtime writers and `OOSH_BRANCH` has none.**

| Writer | Site | Writes |
|---|---|---|
| `oo.mode` | `oo:899` + `config save oosh OOSH` | `OOSH_MODE` only |
| `oo.mode.setup` | `oo:1084` at the time; the method was rewritten by [item 7](2026-09-16-item7-oo-mode-setup.md) | `OOSH_MODE` only — and its `config save` is gone, see that doc § 13 |
| `promote` | `promote:1029` | `OOSH_MODE="released"` — the source of the value on this box |

Each persists through a cascade that re-persists whatever `OOSH_BRANCH` the calling shell happens
to hold. `promote:1029` is especially telling: it sets `released` *after* checking the tree back
out to `dev`.

`OOSH_BRANCH`'s only derive-from-reality writer is `ossh:692`, and it is `[ -z ]`-guarded — once a
value is persisted it is permanently inert. Every other writer is on the install path
(`init/oosh:427,433`, `oo:1969`, `oo:2129-2132`, `oo:2259`).

---

## 3. The central decision: `OOSH_BRANCH` has two meanings

| Meaning | Where | Lifetime |
|---|---|---|
| install **input** — the branch the operator asked for | `init/oosh:96,427,433`, `oo` state 31 | one install |
| derived **fact** — the branch this box is on | `ossh:692` (only when empty) | forever |

A blind reconcile from `readlink ~/oosh` destroys the input mid-install: at the moment state 31
runs, `~/oosh` does not yet point where the operator asked it to.

**Proposal to argue.** Split them by lifetime, which is the T4+T5 precedent applied consistently:

- **`OOSH_BRANCH` is the install input and stops being persisted.** It joins the `config.save`
  exclusion list at `config:561`, beside `OOSH_DIR` and `CONFIG_PATH` — the variables that are
  already excluded precisely because they are derived or per-context rather than state.
- **`OOSH_MODE` becomes the persisted, reconciled fact** — the one variable that answers "which
  branch is this box on", with exactly one derivation.

The consequence to accept: `private.oo.install.branch.get` currently prefers `$OOSH_BRANCH` over
the checkout. With `OOSH_BRANCH` unpersisted it is empty outside an install, so the function falls
through to the checkout — which is the answer everyone actually wants. During an install it is set,
and it still wins. **That is the whole fix for the drift**, and it is a deletion, not an addition.

### Prior art that already exists in this tree

`oo:2506`, install state 41:

```bash
export OOSH_MODE=$(basename "$ooshTarget")     # ooshTarget = canonical(~/oosh)
```

A working reconcile-from-the-symlink, confined to install. It is a better citation than the
reverted `config.reconstruct`, because it is code that runs today.

`config:261-265` is the second piece of prior art: `config.init.user` already treats `OOSH_MODE` as
**untrustworthy**, demoting it to third choice behind `$OOSH_DIR` and the existing symlink, with
the comment *"Avoids the case where `$OOSH_MODE` is set to a stale value like `released` that
doesn't have a corresponding worktree on disk"*. Somebody has met this bug before and worked
around it locally.

### The reverted branch, and what to take from it

`8b668c6` added `config.reconstruct` and `a8b6928` reverted it. Read `git show 8b668c6` for two
things worth keeping: its **blast-radius table** (intact → do nothing; all three missing → rebuild;
*some* missing → **report only**; no `$CONFIG_PATH` → silence) and the `OOSH_BOOT_NO_RECONSTRUCT=1`
escape hatch.

It was **not reverted on its merits** — `a8b6928` rolled back a whole day after an unrelated WODA
regression, listing `config.reconstruct` under "knowingly given up". `config.reconstruct` exists
nowhere in the tree today; `grep` finds it only in documentation.

---

## 4. The required-variable set

Today there is a **negative** list (`config:561`, mirrored in `docs/config.md`) and no positive
one. `config.validate` (`config:621`) checks line *shape* — every line must be `export IDENT=…` or
a `.`-chain — and knows no variable name at all. Nothing anywhere asserts that a config contains
what a branch version needs. `docs/migration/env-files.md:23` lists what happens to survive the
filter, in a document already marked superseded; it asserts nothing.

Proposed shape, as a table in `config` mirrored into `docs/config.md`:

| Variable | Set by | Persisted? | Re-derived how |
|---|---|---|---|
| `OOSH_DIR` | `boot` | **no** (excluded) | constant `$HOME/oosh` |
| `CONFIG_PATH`, `CONFIG`, `CONFIG_FILE` | `boot` | **no** (excluded) | constant `$HOME/config` |
| `OOSH_USER_CONFIG_PATH` | `boot:80`, `this:562` | **no** (excluded) | constant `$HOME/.config/oosh` |
| `OOSH_BRANCH` | `init/oosh`, install states | **no — proposed change** | install input only |
| `OOSH_MODE` | `oo.mode`, `promote`, state 41 | **yes** | `basename(canonical(~/oosh))` |
| `OOSH_OS` | `os:635-650` | yes | `$OSTYPE` |
| `OOSH_PM` | `oo.pm.discover` | yes | probe the platform |
| `OOSH_SSH_CONFIG_HOST` | `config.ssh.host.set` | yes | `hostname -s` |
| `BASH_FILE` | `config.save:579` | yes | `command -v bash` |
| `LOG_LEVEL`, `LOG_LEVEL_RESET` | `log.level` | yes (shared `log.env`) | default 1 |
| `LOG_NAME`, `LOG_DEVICE`, `LOG_LIVE` | `log` | **no** (excluded) | per-user `log.session.env` |

Every row needs confirming against the code when the ticket is implemented; this is the shape of
the answer, not the answer.

Then: give `config.validate` a **`required` mode** that checks presence against that table, and
call it from `config.init.check` (`config:350`) — which today is the natural place and looks at
nothing. Reuse the existing `config.init.shared` / `.user` / `.env` / `.check` / `.full` family
(`config:168-456`); do not rewrite it.

---

## 5. Hard constraints

**No-arg `config.save` may not be used as a repair primitive.** It snapshots the *calling shell's*
variables into the *shared* tier: `config:593-594` cascade into `oosh.env` and `log.env` from
whatever the current process holds. That is the mechanism that produced this bug, and it is also
how one user's `LOG_LEVEL` reaches everyone else's config. Note `config.init.env` (`config:435`)
**does** exactly this today — so the one existing member of the repair family that creates env
files is built on the thing this ticket forbids. That contradiction has to be resolved by the
implementation, not papered over.

**The repair must be unable to fire during an install**, and that has to be proven, not asserted.

**Anchors stay constant.** `OOSH_DIR` is `~/oosh` and `CONFIG_PATH` is `~/config`, enforced by
`this.anchor.validate`. Nothing here changes that.

---

## 6. The fixture problem, and the two waivers T7 must delete

`config.init:170` is an unconditional `export CONFIG_PATH=~/config`. It is simultaneously

- **correct** under the T4+T5 anchor rule, which requires exactly that constant, and
- **the reason `config` cannot be tested against a fixture**, because `config.start:1020` re-runs
  `config.init` whenever `$CONFIG` is not a file, so any fixture is undone from inside.

Two `core` test files are blocked on this and say so in their own source:

```
test/test.completion.audit : TEST_SHARED_TIER_WRITER="blocked on T7: …"
test/test.config           : TEST_SHARED_TIER_WRITER="blocked on T7: …"
```

Both reach a production `config save` and rewrite the site-wide tier. The runner's guard reports
and restores them but does not fail the run (`docs/test-suite.md` § *When a file cannot be isolated
yet*). **Deleting both markers and getting a green `core` run without them is T7's cheapest
proof** — better than any assertion the ticket could write for itself.

**Resolution to argue:** `config.init` takes an optional **path argument** rather than reading the
environment, defaulting to the constant when none is given. The anchor rule is about what the value
*is*, not about where the function is forbidden to be pointed by an explicit caller.

---

## 7. Corrections this ticket must make

- `docs/plans/2026-09-10-oosh-boot-tickets.md:204` still claims T7's first half was delivered via
  `config.reconstruct`. It was not; the same file contradicts itself at `:450-452`.
- `docs/superpowers/specs/2026-09-14-oosh-recovery-from-bare-shell-design.md` describes
  `config reconstruct` as shipped, in six places.

---

## 8. Done when

- Drift is **detected** with rc 1 against a fixture `CONFIG_PATH` and a fixture `oosh` symlink, and
  after repair the persisted value agrees with the checkout.
- With `oosh.env` absent entirely, the check **names every missing variable** instead of succeeding
  emptily.
- The repair is proven **unable to fire during an install**.
- Both `TEST_SHARED_TIER_WRITER` markers are deleted and `core` is green without them.
- Controls: revert the reconcile and watch detection go silent; plant a missing variable and watch
  it be named.

---

## 9. Decided, and what shipped (2026-09-16)

All three questions below were answered, and one collision the research above **missed** turned
up during implementation.

| Question | Decided |
|---|---|
| Does `OOSH_BRANCH` stop being persisted? | **Yes.** Blast radius measured first: on an installed host no runtime reader's answer changes. |
| `OOSH_MODE` reconciled on load, or on request? | **On request.** `config validate required` returns rc 1; `config.init.check` reports and swallows it, because it is documented as never failing its caller. |
| Rewrite `config.init.env`? | **No** — recorded as a follow-up; it is the only code that creates the three-file structure. |

**The collision this document missed.** `OOSH_MODE` did not only hold branch names. `promote`
wrote the literal `released` into it, one line *after* `git checkout dev` — recording a
developer-box event in the variable that describes an installed host — and
`private.check.user.mode.release` asserted that word. Its sibling lane asserts `dev`, so a host
could satisfy only one, and on a genuinely released box (where `oo mode prod` had set the branch
name) the release lane failed anyway. **It was asking the wrong question.** A released install is
one sitting on the `prod` branch. The lane was repointed and promote's write deleted.

**A second finding, filed separately.** Those two lanes are registered *consecutively*
(`oo:1473-1474`), so the 20-lane has been unfinishable since it was written — it stalls either
way. T7 changed what the first one asks, not the contradiction. See the tracker § 4c.

**What shipped:** `fee9513` (exclusion) · `db4952f` (mode means branch) · `325c4e5` (config.init
honours its anchor) · `69cd0a8` (both waivers deleted) · `5fbb513` (required set + drift report).

Proof, in the ticket's own terms: a `core` run reports **no `Shared tier:` line at all**, where
for two days it named two files — a pre-existing guard falling silent rather than a new assertion.
And on this host the new check says exactly what the ticket was filed for:
`OOSH_MODE=released but ~/oosh is on dev`.

---

## 10. Open questions, as originally posed

1. **Does `OOSH_BRANCH` stop being persisted?** This is the whole decision. It makes the drift
   impossible rather than repairable, and it is a deletion — but it changes what a cold shell
   carries, so it wants an explicit yes.
2. **Does `OOSH_MODE` get reconciled automatically on load, or only by an explicit
   `config init.check`?** The working agreement says repair belongs to explicit primitives and must
   never fire from shell startup (`docs/oo.md` § repair). Detect-on-load and repair-on-request is
   the reading that honours it, but "always bootstrap" in the card text could be read either way.
3. **`config.init.env` is built on the forbidden primitive.** Rewrite it in this ticket, or leave
   it and scope T7 to detection plus a narrower repair?
