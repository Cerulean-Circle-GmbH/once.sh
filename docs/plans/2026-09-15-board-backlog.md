# Board backlog — what each card actually is, and what to do about it

**Written 2026-09-15.** One section per card on the Ideas column, with the card text verbatim so it
can be matched to the board. Each section says what the card turned out to be once it was grounded
against the code, exactly what has to be done, and how it is proven done.

Work through it one ticket at a time. Card moves are done by hand on the board; nothing here moves
them.

> **Read this before starting any of them:** every card below was checked against the tree, and
> several are not what they look like. Two are already-working code that only lacks documentation.
> One has nothing wrong with it at all. One that reads like a one-liner is the highest-risk change
> in the list.

---

## Three findings that shape the whole list

**1. Most "new" cards are existing code with real defects, not new features.** Two of them —
`oo.mode.setup` and `oo.checkout` — are character-for-character copies of a function's own
signature comment. Most likely they were pasted because neither has a section in `docs/oo.md`.

**2. One card is a contract bug, not a one-liner.** `oo.cmd` has no result protocol at all and
*always* exits 0, which silently disarms three callers on the install path.

**3. The test suite writes the real shared config.** Verified on this host, not inferred.

### The shared-config finding

The shared tier is **correct and unchanged by any of this**. `~/config` → `.../sharedConfig`,
site-wide data shared across all users, with per-user and per-session state split into
`~/.config/oosh` and chained from it ([config.md](../config.md) § *Two config tiers*). `config save`
writing that tier is right in normal use.

The defect is that a **test** writes into it. `test/test.path` is `TEST_CATEGORY=core`, so it runs
in every `./test.suite core 1`. It sources `path` and calls `path.append` six times; each call ends
in `private.update.config`, whose body is a no-arg `config save` — and `test.path` sets no fixture.
On-disk proof:

```
log.env   2026-09-14 17:14:14.503
oosh.env  2026-09-14 17:14:14.478   <- 45 ms spread = the no-arg config.save cascade
user.env  2026-09-14 17:14:14.523
```

Because the tier is shared, a test run mutates site-wide state for **every user on the box**. And
`oosh.env` is the file whose drift T7 exists to fix — so T7's tests would be aiming at a moving
target. That is the only reason the order below departs from the tracker's, which puts T7 next.

---

## The list, in recommended order

| # | Card | What it is | Risk |
|---|---|---|---|
| 1 | *(no card — found while grounding)* | Tests write the real shared config | none to prod |
| 2 | `oo cmd mc && create.result check` | `oo.cmd` always exits 0 | **HIGH** — install |
| 3 | *(no card — open box on an existing ticket)* | `test.suite` inherits another file's score | none to prod |
| 4 | `review hot PATH is bootstrapped` | **T8** | LOW |
| 5 | `config has to bootstrap always all variables…` | **T7** | **HIGH** — install |
| 6 | `/root/ssh..2378eed3bee5.for.2378eed3bee5` | Two naming bugs + a cwd-relative backup | **HIGH** — install |
| 7 | `oo.mode.setup # <?worktree_base> #…` | Exists, incomplete | MEDIUM — dev tree |
| 8 | `odocker workspace.get …` + `odocker workspace.init` | `get` ignores its arg; `init` missing | LOW |
| 9 | `oo.checkout # <version> #…` | Works correctly. Docs-only | none |
| 10 | `…/hosts/WODA.test/certificates.update.conf` | Nothing broken. Note only | none |
| 11 | `prod/docs/puml/bootsratp.sequence` | **T6** diagram | none |

**Not scheduled — needs its own card.** 44 production functions call `create.result` without
`return $(result)`, across `oo`, `ossh`, `this`, `os`, `state`, `path`, `osshLayout`, `hiveMind`,
`scrumMaster`, `myId` and `test.suite`. Split it **per file**, with a platform run per install-path
file. As a single commit it would make roughly 45 dormant failure branches live at once — the most
dangerous change in this backlog. Note `oo.cmd` (#2) is *not* a member of this set: it has no
`create.result` anywhere, so the sweep's mechanical rule would never have caught it.

---

## 1. Give the tests a fixture config

**Card:** none — found while grounding the others.

**What it is.** `test/test.path` and `test/test.oo` (the `config set oosh OOSH_COMPONENTS_DIR` case
in T-SETUP-3) write the real site-wide config. See the finding above.

**What to do.** Set a `mktemp` fixture `CONFIG_PATH`/`HOME` before `source path`; point
`test.oo`'s `config set` at the fixture. The shared tier itself is not touched.

**Done when.** Record `oosh.env`'s mtime, run `./test.suite core 1`, assert it is unchanged.
Negative control: revert the fixture and watch the assertion go red.

**DONE 2026-09-15.** `test.suite.config.isolate` / `.restore` added; `test/test.path` and
`test/test.oo` adopt it. A full `core 1` run now leaves `user.env` and `oosh.env` byte- and
mtime-identical, where before it rewrote all three 45 ms apart.

Three things worth carrying forward:

- **`test/test.log` closed too** (scope extended on request). It needed more than the isolate line:
  its T23 wrote and asserted a hardcoded `~/config/result.txt`, while `clear.resultFiles` — the
  function under test — operates on `$CONFIG_PATH`. The two only coincided because `CONFIG_PATH`
  *was* `~/config`, so the test was both writing the shared tier and asserting against the wrong
  file the moment anything moved the anchor. Its T31 backup/restore used `$HOME/config/log.env`,
  which a `CONFIG_PATH` fixture does not move, so the restore was the actual remaining writer.
  **A full `core 1` run now leaves all three shared files untouched.**
- **Two `config set oosh OOSH_COMPONENTS_DIR` lines in `test.oo` were deleted, not fixed.** They
  were *inert*: `config.set` takes `<envVariable> <value>`, so they wrote
  `export oosh="OOSH_COMPONENTS_DIR"` and never touched the variable they named. The `export` on the
  line above already did the work. Correcting the arity would have been worse — it would persist a
  variable `config.save`'s exclusion list exists to keep out.
- **`~/.gitconfig` needed a different tool.** `CONFIG_PATH` cannot redirect it;
  `oo.safeDirectory.prune` writes it through `git config --global`, so it is sandboxed with
  `GIT_CONFIG_GLOBAL` — the pattern `test.oo` already used twelve lines later.

---

## 2. `oo cmd` result contract

**Card:** `oo cmd mc && create.result check`

**What it is.** `oo.cmd` has no `create.result` and no `return`. Its last statement is a bare
`RETURN=$1` assignment, which always exits 0 — so **`oo cmd <anything>` always reports success**,
even when the package manager fails. `RETURN` is also the shift global the result protocol itself
uses in `this`, so the tail pollutes that protocol too.

Three callers check the status and therefore can never fire:

- `oo.prereqs.install` — `if ! oo cmd "$pkg"` for `curl` and `git`
- `ossh.prereqs.install` — `oo cmd rsync || warn.log …`
- `ossh.prereqs.install` — `oo cmd tree || warn.log …`

`mc` is not special-cased anywhere; it falls through to `$SUDO $OOSH_PM mc` with no verification.

**What to do.** Adopt the protocol exactly as `oo.checkout` uses it — `create.result` on every
branch, `return $(result)` at the end. Capture the package manager's status, then **re-verify with
`command -v`**: installing and still not having the command is a failure. Delete the `RETURN=$1`
tail. Decide fatal-vs-warn per call site and record the decision in the commit message —
`oo.prereqs.install` fatal (it already reads that way), the two `ossh` sites warn (they already say
"install may still work").

**Land this one alone.** It makes dormant branches live, so a red platform run afterwards must have
exactly one candidate cause.

**RISK RATING CORRECTED (2026-09-15).** This card said HIGH — install, "three dormant install
branches live simultaneously". Two of the three claims were wrong. `oo.prereqs.install` — the one
with `if ! oo cmd "$pkg"` — has **zero callers in the tree**; it is reachable only by hand. The two
sites that do run during install are both followed by an unconditional `return 0` that already
discards even the existing verify's status. Real blast radius on a live install: **two new
`warn.log` lines**, on Alpine and naked macOS.

**Done when.** A stubbed `$OOSH_PM` that exits 1 → rc ≠ 0 and `$RESULT` names the tool; a command
already present → rc 0 and the PM is never invoked; `RETURN` unchanged across the call. Controls:
restore the `RETURN=$1` tail and watch case 1 flip; then make the stub exit **0** while leaving the
command absent, and watch the verify-after-install assertion flip. Platform run on ubuntu **plus
alpine and almalinux**. `docs/oo.md` gains the contract line.

**DONE 2026-09-15.** `oo.cmd` has the contract on every branch; the post-condition is the new
`private.oo.cmd.verify`, moved out of `ossh` so `oo.cmd` can enforce what its own comment used to
defer to `ossh.prereqs.install` for. Six `T-CMD-*` tests, each with its own negative control.

Two defects this card did not mention, both fixed here:

- **The two-argument form dropped the package.** `oo.cmd sshd openssh-server` shifted twice and
  installed nothing — the package manager was called with no operand at all, which `apt-get -y
  install` exits 0 for. Reproduced in the failing test as `[install ]`, the PM's whole argv. Live at
  `ossh`'s `oo.cmd sshd openssh-server`.
- **Four branches called commands that exist nowhere** (`once`, `private.stage`,
  `once.su.mkcert.install`). They now fail naming what is missing instead of emitting "command not
  found" and reporting success.

Also recorded: `RETURN=$1` was not nonsense — it was the chaining protocol hand-rolled. `RETURN` is
the sentinel `this.start` reads to find where the next command on a chained line begins, and the
documented way to set it is `create.result`'s **third argument**. Doing it by hand as the last
statement is what pinned the exit status at 0, and it was broken for its own purpose too: it set
`RETURN=""`, which never matches, so `this.start` shifted through every remaining argument, hit
"force stop" and exited — silently swallowing the rest of the line.

---

## 3. `test.suite` reports 0/0

**Card:** none — the one open box in [tests that cannot fail](2026-09-14-tests-that-cannot-fail.md).

**What it is.** A test file that writes no `testresult.env` inherits the previous file's score.
`test.tilde` reporting `test.this`'s 31 assertions was the instance that exposed it.

**What to do.** Clear the per-file result state before each file in the suite runner; a file that
produced no results of its own reports `0 / 0`, or fails loudly naming the file.

**Done when.** A fixture file that asserts nothing reports `0 / 0` rather than inheriting.
Control: revert and watch it inherit again. Re-baseline the totals in the same commit.

**DONE 2026-09-15** — and one thing above was wrong. "Expect the reported numbers to move once,
downward" is true of `extended` only. All 12 score-less files are `extended`; every one of the 26
`core` files saves, so `core` was never inflated and does not move. `extended` went 427 → **343**
assertions. No `extended` baseline had ever been recorded; it is now.

---

## 4. T8 — PATH bootstrap and the `path` script

**Card:** `review hot PATH is bootstrapped` · `PATH=` · `and the path script`

**What it is.** `boot` is already the correct colon-guarded, idempotent PATH builder. The problem
is that it is one of **five** mechanisms:

1. `boot` — correct
2. a duplicate of the same block in `ossh`
3. unguarded prepends in `this` (two of them)
4. `this.path.add`, a prepend chain invoked five times — including `this.path.add "."`, which puts
   **the current directory first on PATH**
5. the `path` script — effectively dead: `path append`/`prepend`/`remove` mutate a child process
   and exit, then claim to persist to config, but `config.save` never persists PATH.
   `path.file.global`/`save`/`load` target `/etc/paths` and `~/paths`, neither of which exists on
   Linux. `path.status`/`path.sync` grep for an `^export PATH=` line that pure-data `user.env` has
   not contained since the env-file migration.

Two stale docs: `docs/config.md` names `bashrcTemplate` as the PATH builder (it has only been a
degrade branch since the boot-loader migration), and `docs/oosh-architecture.md` advertises
`path add`, a verb that does not exist. There is no PATH-ownership rule in `docs/boot.md`, unlike
`OOSH_DIR` and `CONFIG_PATH`, which have one *and* a validator.

**Research doc first.**

**What to do.** Establish the rule: **`boot` is the single builder and stays byte-identical**;
everything else delegates or is a documented degrade branch. Guard it the way T4+T5 guarded the
anchors — a `this.anchor.validate` sibling with a planted violation in its test. Colon-guard the
two `this` prepends. Remove `this.path.add "."`. Reduce `path` to a read-only reporting tool plus
session-local helpers: delete `private.update.config` (this is what ends the shared-config
corruption), the macOS relics, and `path.status`/`path.sync`. Remove **7 of the 8** `export PATH`
lines in `.github/workflows/macos-test.yml` — **keep the Homebrew one**. Fix both stale docs. Add
the PATH section to `docs/boot.md`.

**Keep and document as sanctioned:** the five `. ~/oosh/boot || export PATH=…` degrade branches and
`bashrcTemplate`'s fallback. Those are the boot-absent path, not violations.

**Do not re-litigate.** T9 already decided `boot` may not skip PATH when `~/oosh` is absent — it
would skip during install, before `~/oosh` exists. Cite that decision rather than reopening it. Do
not touch `templates/user/profile.d.oosh.sh`; install state 34 owns that file.

**Done when.** `test.config` T24 — which today greps `boot` for literal strings and therefore
cannot fail — is replaced with a behavioural test: source `boot` twice from a fixture `HOME` and
assert `$OOSH_DIR` appears exactly once on PATH; then pre-seed PATH with it mid-string and assert
`boot` neither moves nor duplicates it. Controls: strip the colon guard; and add a bare
`export PATH=/tmp:$PATH` to a tracked file and require the sweep to report a violation.

*Housekeeping while in there: `test.config` has two different tests both numbered T24.*

---

## 5. T7 — config bootstraps all branch-version variables

**Card:** `config has to bootstrap always all variables required for a branch version` ·
`conifg init repairs a nonexisting or broken config`

**What it is.** A live, reproducible bug. The persisted config disagrees with reality:

```
persisted : OOSH_BRANCH="prod"   OOSH_MODE="released"
actual    : ~/oosh -> .../Once.sh/dev     (git branch: dev)
```

Nothing reconciles them, and `private.oo.install.branch.get` then prefers `prod` on a `dev` box.
Separately, `config.init` only creates the directory and three variables — on a **missing** config
it succeeds emptily, never creating `user.env`/`oosh.env`/`log.env`, leaving `$CONFIG` pointing at
a file that does not exist. `config.validate` exists and is good, but runs only inside
`config.save`, *after* writing, and only warns. No entry point validates on load, and no declared
required-variable set exists anywhere.

**Correct the tracker as part of this.** [The boot tickets tracker](2026-09-10-oosh-boot-tickets.md)
claims T7's first half was delivered via `config.reconstruct`. It was not — that shipped in
`8b668c6` and was reverted by `a8b6928`, and `grep` finds it only in docs. `git show 8b668c6` is
prior art worth reading: it contains the blast-radius table and the `OOSH_BOOT_NO_RECONSTRUCT=1`
escape hatch.

**Research doc first.** Its central decision is that **`OOSH_BRANCH` has two meanings**:

| Meaning | Where |
|---|---|
| install **input** — the branch the operator asked for | `init/oosh`, `oo` install states |
| derived **fact** — the branch this box is on | `ossh` (derives only when empty) |

A blind reconcile from `readlink ~/oosh` would destroy the install input mid-install. Meanwhile
`OOSH_MODE` has exactly one legitimate writer, `oo.mode`, which persists it but leaves
`OOSH_BRANCH` untouched — and that asymmetry *is* the drift mechanism. The proposal to argue:
keep `OOSH_BRANCH` as the input and stop persisting it (join the `config.save` exclusion list
beside `OOSH_DIR`/`CONFIG_PATH`), and make `OOSH_MODE` the persisted-and-reconciled fact. That is
the T4+T5 precedent applied consistently.

**What to do.** Declare the required-variable set — today there is a de-facto *negative* list
(what must never persist) and no positive one — as a table in `config` mirrored into
`docs/config.md`, naming for each variable who sets it, whether it persists, and how it is
re-derived. Give `config.validate` a `required` mode and call it from `config.init.check`. Reuse
the existing `config.init.shared`/`.user`/`.env`/`.check`/`.full` family; do not rewrite it.

**Hard constraint.** No-arg `config.save` may not be used as a repair primitive. It snapshots the
calling shell's variables into the shared tier — that is the mechanism that produced this bug.

**Done when.** With a fixture `CONFIG_PATH` and a fixture `oosh` symlink: drift is detected with
rc 1, and after repair the persisted value agrees with the checkout. With `oosh.env` absent
entirely: the check **names** every missing variable, instead of succeeding emptily. Controls:
revert the reconcile; and separately prove the repair cannot fire during an install.

---

## 6. The `ssh..<id>.for.<id>` directory

**Card:** `/root/ssh..2378eed3bee5.for.2378eed3bee5`

**What it is.** Three defects, two of them in the same two lines of `ossh.install.continue.local`.
The name is built as `ssh.` + `$USER` + `.` + *local* + `.for.` + *remote*.

1. `$USER` is unset under `docker exec` and non-login ssh, and nothing in `ossh` defaults it →
   `ssh..`.
2. Both halves are the same host because `init/oosh` computes the **local** `hostname -s` and
   passes it into the parameter named `remoteSshConfigName`, while the local slot falls back to
   `$HOSTNAME`. On-disk proof on the dev box:
   `~/ssh.root.hannesn-VirtualBox.for.hannesn-VirtualBox`.
3. **Separate and worse:** the guard tests `$HOME/ssh.…` but `user.ssh.backup` does
   `cp -R $sshDir ssh.$name` — **relative to the current directory**. It only landed in `/root/`
   because cwd happened to be `/root`. `user.ssh.restore` reads the same relative name, and the
   `ssh.original` guard has the identical flaw.

**Research doc first** — the placement question. These backup calls already live inside
`ossh.install.continue.local`, which the working agreement forbids for *new* fixups. The doc must
decide whether they move into a state rather than adding a fourth fixup beside them.

**What to do.** First **try to disprove defect 1**: `c140c21` added a `USER` heal in `this`, and
the install reaches this code via `this call`, so `ssh..` may already be unreachable. Write that
test, run it against HEAD, and if it passes, shrink the card and record why. Then anchor the backup
at `$HOME` — and change `user.ssh.restore` in the same commit, or restore breaks. Then fix the
argument order so the local case cannot produce `X.for.X`.

**Watch:** argument 1 of `ossh.install.continue.local` is a two-caller contract — local install and
`ossh install <host>` remote mode.

**Done when.** With a fixture `HOME` and cwd set elsewhere, `user.ssh.backup probe` creates
`$HOME/ssh.probe` and creates **nothing** in the current directory; round-trip through
`user.ssh.restore` succeeds. Control: revert the anchor and watch the backup reappear in cwd.

---

## 7. `oo.mode.setup`

**Card:** `oo.mode.setup # <?worktree_base> # convert a plain clone to worktree structure for
branch switching`

**What it is.** It exists — the card is its signature comment verbatim. Two problems. It uses bare
`return 0/1` with no result protocol. And it builds `base/dev`, which defeats **all three** of
`oo.mode.base.get`'s layout strategies, every one of which keys on a directory named `main` — so
after running it on a plain clone, the base may still not be detectable. `private.oo.shared.tree.from.local`
is the function that already produces the canonical layout, and `mode.setup` does not call it. Its
three tests use wildcard assertions from the cannot-fail family. No `docs/oo.md` section.

**Research doc first** — it `mv`s the live tree.

**What to do.** Delegate to `private.oo.shared.tree.from.local` rather than growing a second layout
builder. Add the result protocol. Make the destructive `mv` fail loudly.

**Done when.** A throwaway clone in a `mktemp` dir, run through `oo.mode.setup`, leaves
`oo.mode.base.get` able to return the fixture base — which it cannot today. The three existing
T-SETUP tests end with `return $(result)` and drop their wildcards, each proven to flip. Fixtures
only: restore `OOSH_DIR`, `OOSH_COMPONENTS_DIR`, `HOME` and `PATH`.

**Not on the install path** — install state 31 uses `private.oo.shared.tree.from.local` instead, so
the platform test does not exercise this. The risk here is destroying a developer's own tree, not
breaking CI.

---

## 8. odocker workspaces

**Cards:** `odocker workspace.get /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces`
and `odocker workspace.init`

**What it is.** `workspace.get` takes **no argument** and silently ignores the one the card passes.
The path in the card is the hard-coded default. `workspace.init` does not exist anywhere in the
tree. `workspace.set` exists and persists correctly, but **rejects** a missing directory — which is
right and should stay that way; `init` is the method that may create. Concretely: the shipped
default does not exist on this host, so `odocker workspace.set` with no arguments fails here today.

**What to do.** `workspace.init` = `mkdir -p` + reuse `workspace.set` wholesale, including its
persistence trio. Make `workspace.get` stop silently ignoring its argument — accept an optional
path and report whether it is a usable workspaces root, otherwise report the current resolution.

**Done when.** `init` on a nonexistent `mktemp` path creates it, canonicalises it, and it appears in
the fixture `odocker.env`; `get <path>` no longer ignores its argument. Controls: point `init` at
an unwritable parent — it must fail rc 1, not silently; and run the get-argument assertion against
today's code to watch it start red.

**Gotcha:** `odocker` runs `config get` at **source time**, so `CONFIG_PATH` must be set before
`source odocker` in any fixture.

---

## 9. `oo.checkout` — documentation only

**Card:** `oo.checkout # <version> # clone or add worktree for a remote branch`

**What it is.** It exists, the card is its signature verbatim, and it **works correctly** —
`create.result` on every branch and `return $(result)` at the end, a `git worktree add` path and a
`git clone` path, and a deliberate refusal to pull (that belongs to `oo update`). It is one of the
good citizens on the result contract.

The only gap: `docs/oo.md` jumps from `oo.mode` straight to `oo.update`.

**What to do.** Add an `### oo.checkout` section following the shape of `### oo.boot.fix`. Fold in
`oo.mode.setup` and `oo.use`, which are also missing, if #7 has landed.

**Done when.** The section exists. No code change.

---

## 10. WODA.test certificates config — note only

**Card:** `/root/oosh/etc/ossh/hosts/WODA.test/certificates.update.conf`

**What it is.** Nothing is broken. `ossh certificates.update` and its per-host config loader work,
`WODA.test` is a genuinely known host, the file is committed, and a real-env test asserts its
contents. `/root/oosh/etc/...` is the correct path when `OOSH_DIR=/root/oosh`.

**Decision taken: leave it in the repo.** It is team configuration, version-controlled on purpose,
and it arrives with a fresh install.

**What to do.** Record the trade-off in the tracker so it is not rediscovered: `$OOSH_DIR` is the
`~/oosh` **symlink**, so `oo mode <branch>` changes which branch's host configs are visible; and
the resolved machine values go somewhere else entirely, to `$CONFIG_PATH/stateMachines/`. No code
change.

---

## 11. T6 — bootstrap.sequence diagram

**Card:** `prod/docs/puml/bootsratp.sequence` `/bootsratp.sequence.svg`

**What it is.** The `.puml` last changed 2026-03-18, before the boot loader existed, and mentions
"boot" once. The `.svg` is a stale 2026-04-30 render. On 2026-09-14 the misspelled `bootsratp.*`
family was renamed to `bootstrap.sequence`, an editable `.drawio` source was added, and
`docs/boot.md` § See also now links it — but the diagram content itself is untouched.

**What to do.** The "no PlantUML on the dev host" blocker is removable without installing anything:
docker works here, so `docker run --rm -v … plantuml/plantuml` renders the SVG. Decide `.puml` or
`.drawio` as the single source of truth and say so in `docs/boot.md` § See also — two editable
sources is the same two-owners problem T8 exists to end. Redraw against `docs/boot.md` §
*What it does, in order*.

**Done when.** The four boxes already on T6: `.puml` redrawn, `.svg` regenerated, cross-linked from
`docs/boot.md` and `docs/wiki-index.md`, and the diagram confirmed correct — which was the original
question the card asked.

---

## Standing verification bar

Applies to every code ticket above:

- failing test first, with the real failure output recorded;
- a **negative control per assertion** — this suite passes a test whose function calls
  `create.result 1` without `return $(result)`, and `expect 0 "*"` sets the expectation to whatever
  actually happened, so a test nobody has watched fail is not a test;
- four-shell lint (`sh`, `dash`, `bash`, `busybox ash`) on anything POSIX;
- `./test.suite core 1` and `./this anchor.validate`;
- `os platform.test ubuntu_24_04` as the real gate, with `test.ssh.config.woda.portable` passing 12×.

Ticket 2 additionally runs alpine and almalinux, because it makes install-path branches live.
Tickets 1 and 3 move the reported totals once — re-baseline in the same commit.
