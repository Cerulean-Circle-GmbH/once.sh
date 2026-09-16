# Item 7 — research: `oo.mode.setup`

**Written 2026-09-16 · Branch `dev` (`b6a0ecc`) · Status: DELIVERED — questions answered in § 10, what actually shipped in § 13.**
**Card:** `oo.mode.setup # <?worktree_base> # convert a plain clone to worktree structure for branch switching`

Ticket: [board backlog](../plans/2026-09-15-board-backlog.md) § 7 — the last **MEDIUM** on the list.

The card is the method's own signature comment, quoted verbatim. That is the tell: nobody wrote a
ticket about a symptom, somebody read the method and did not believe it.

`oo.mode.setup` converts a plain clone into the worktree layout `oo mode` needs, by **moving the
live tree**. It is the only destructive method in `oo` with no result protocol, no documentation,
and no test that reaches what it actually does. It has **zero callers** — it is reachable only by a
human typing `oo mode.setup`, which is what `oo.mode.base.get`'s own failure message tells them to
do (`oo:661`, `oo:823`, `oo:870`).

**The risk is not CI.** Install state 31 takes the other path — `private.oo.shared.tree.from.local`
(`oo:2134`) — so the platform gate never exercises this. The risk is destroying a developer's own
working tree.

**Grounding it corrected the card in three places and found a better defect than the one it names.**

---

## 1. Corrections to the card

| The card says | What is actually true |
|---|---|
| "defeats **all three** of `oo.mode.base.get`'s layout strategies, **every one** of which keys on a directory named `main`" | There are **four** strategies — five checks, since strategy 4 has two independent branches. **Strategy 1 does not key on `main` at all**: it keys on `$OOSH_COMPONENTS_DIR` and asks nothing about layout (`oo:586`). Strategies 2, 3, 4a and 4b do hard-code the literal string `main` (`oo:604`, `:615`, `:627`, `:631`). Right about 2/3/4; wrong about the count, and wrong about "every one" |
| "Its **three** tests use wildcard assertions from the cannot-fail family" | There are **four** (`T-SETUP-1..4`, `test/test.oo:1362-1464`). Only **T-SETUP-2** is literally wildcard-vacuous. The other three *are* falsifiable — but all four violate the `return $(result)` protocol, so their declared return codes are decorative. § 5 |
| "after running it on a plain clone, the base may still not be detectable" | True, and for a sharper reason than the card gives. § 3 |

---

## 2. The layout, and why `main` is load-bearing

The canonical layout is `main/` + one directory per branch, stated in
`private.oo.shared.tree.from.local`'s own docstring (`oo:1647`): *"produce canonical
`main/ + <branchName>/` worktree layout … (oo.mode.base.get strategy 2/4 then succeeds and
`oo mode <branch>` works)"*.

`main` is not a naming convention. On this box:

```
Once.sh/main   — drwxr-xr-x … .git is a DIRECTORY   ← the repository itself
Once.sh/dev    — .git is a FILE: "gitdir: …/main/.git/worktrees/dev"
Once.sh/prod   — .git is a FILE: same shape
```

`main` **is** the repository; `dev` and `prod` are linked worktrees pointing into it. A layout with
no `main` has nowhere for the repository to live.

---

## 3. The real defect — the one bridge is a variable `config` deliberately throws away

`oo.mode.setup` builds `<base>/dev` (`oo:1021`) and, for a feature branch, `<base>/<branch>`
(`oo:1059`, `:1072`). **It never creates `<base>/main`.** So strategies 2, 3 and 4 all fail on the
layout it produces.

Its one bridge to detectability is **strategy 1**:

```bash
oo:1083   export OOSH_COMPONENTS_DIR="$base"
oo:1085   config save oosh OOSH 2>/dev/null
```

**`config` filters `OOSH_COMPONENTS_DIR` out of every save, on purpose.** It is in the exclusion
list at `config:595`, with the reason written directly above it at `config:571`:

> `# OOSH_COMPONENTS_DIR is a transient /tmp/test.oo.* path from test runs — never share.`

and `docs/config.md:215` lists it with a re-derivation column of *"(none — set per test run)"*.

So the layout works **only in the process that ran setup**. The next shell has no
`OOSH_COMPONENTS_DIR`, strategy 1 fails, strategies 2/3/4 were never satisfiable, and
`oo.mode.base.get` returns 1 — the exact failure whose message tells the user to run
`oo mode.setup`. **The command that is supposed to fix the condition produces a layout that
re-creates it one shell later.**

### Measured, not asserted

A `base/dev`-only layout in a throwaway `git init` fixture, which is the card's central claim:

| Fixture | `oo.mode.base.get` |
|---|---|
| `base/dev` only, `OOSH_COMPONENTS_DIR` **unset** | **rc 1**, empty — base undetectable |
| the same layout, `OOSH_COMPONENTS_DIR` exported | rc 0, returns `base` |

And the control, this box's real install: `OOSH_COMPONENTS_DIR` is **empty** in every shell, yet
`oo mode.base.get` returns the base — it resolves through **strategy 3** (`dev/.git` is a pointer
file, `main/` is beside it). Confirmed absent from every generated env file.

### Same root cause, second symptom

`oo.mode.base.set`'s docstring says *"set and **persist** the OOSH components base directory"*
(`oo:641`). It does not persist either — `oo:653` is the same filtered `config save`. It has no
production callers; it exists for a human and for four tests.

### What this actually is

Two subsystems hold incompatible beliefs about one variable. `config` treats
`OOSH_COMPONENTS_DIR` as **test noise** and refuses to store it. `oo.mode.setup` and
`oo.mode.base.set` treat it as **production configuration** and try to. Neither knows about the
other, and the exclusion wins silently. Any fix has to reconcile that, not patch one side.

---

## 4. The `mv`, and how quietly it fails

The card asks to "make the destructive `mv` fail loudly". It is worth recording how loudly it does
not. Four `mv`s — `oo:1041`, `:1046`, and the rollbacks at `:1053`, `:1062` — with no rc check, no
`-n`, no `-T`, and no pre-flight `[ -e "$devDir" ]`. The source is `$currentDir`, the **physical
resolved live worktree** behind `~/oosh` (`oo:1000`).

- **Destination exists as a directory.** POSIX `mv` moves the source *inside* it —
  `…/Once.sh/dev/dev` — and exits 0. The function continues, and `ln -s "$devDir"` (`oo:1079`)
  points `~/oosh` at a directory that *contains* the clone rather than being it. This is the same
  nesting shape [item 6](2026-09-16-item6-ssh-backup-naming.md) just fixed in `user.ssh.backup`,
  on a live tree instead of a backup.
- **Destination exists as a file, or the move fails.** The rc is discarded. On the `dev`-branch
  path execution runs straight through to `rm "$OOSH_LINK"` and `ln -s`, so **`~/oosh` is deleted
  and re-pointed at a path the tree was never moved to** — the install is unreachable while the
  tree sits untouched exactly where it always was.
- **`~/oosh` is a real directory, not a symlink** — the condition `oo:870` explicitly warns about.
  The `rm` at `oo:1076` is skipped (`if [ -L … ]`), so `ln -s` creates `$HOME/oosh/<branch>`
  *inside* it. The `ln` rc is discarded too.
- **The rollback is asymmetric.** Both feature-branch failure paths restore with
  `mv "$devDir" "$currentDir"`. The `dev` lane has no failure path after its `mv` at all.

Three more things nothing documents:

- **there is no final `return`.** The function ends on `echo` (`oo:1099`), so every success path
  reports that `echo`'s status. There is no `create.result` anywhere in the body, which is also why
  T-SETUP-2 *has* to use `"*"` — `$RESULT` still holds whatever the previous test left in it;
- **`$1` is never validated** — not for existence, not for writability, not for being equal to or
  inside `$currentDir`;
- **it appends to `~/.bashrc`**, via `private.oo.install.shim` (`oo:972-993`), which also `cp`s the
  shim and `source`s it. Nothing in a signature about converting a directory layout suggests that.

---

## 5. The tests — and what "cannot fail" precisely means

The mechanism has **two** halves, and the distinction decides what is worth fixing.

`expect` compares **both** `RETURN_VALUE` and `RESULT`. `expect 0 "*"` assigns
`expectedresult=$RESULT`, killing the string half. A test function that does not end with
`return $(result)` returns its last command's status — and `create.result` always exits 0, because
its last statement is an `info.log` whose false branch yields 0 — killing the rc half. **A test is
vacuous only when both are dead.**

| Test | ends `return $(result)` | rc half | string half | verdict |
|---|---|---|---|---|
| T-SETUP-1 `:1365` | no | dead | live | falsifiable, but asserts only that sourcing `oo` defined a function |
| T-SETUP-2 `:1379` | ends on the SUT | live | **dead** (`"*"`) | the one literal cannot-fail case — **and it tests the wrong property** |
| T-SETUP-3 `:1398` | no | dead | live | falsifiable, but reaches **only** the early-return no-op at `oo:1015` |
| T-SETUP-4 `:1428` | no | dead | live | the only one reaching the destructive path — with the weakest possible post-condition |

**T-SETUP-2's name is a lie.** It is called *"mode.setup rejects non-git directory"*, and
`oo.mode.setup` has no git check. The rc 1 it observes comes from the empty-branch path at
`oo:1026-1029`, because `this.git.branch.short` prints nothing for a non-repo. Any unrelated future
rc-1 path keeps it green. Its `expect.error 1` at `:1385` is **inert**: it sets
`EXPECTED_RETURN_VALUE` for the `onError` trap, while `test.case` keys on `TEST_EXPECTING_ERROR`,
which only `test.case.expect.error` sets.

**T-SETUP-4's post-condition is `[ -d "$BASE_DIR/dev" ]`** — a bare `mkdir` in the implementation
would satisfy it. It does not check that the directory is the moved repo, that it is on `dev`, that
the symlink now points at it, or — the one that matters — **that `oo.mode.base.get` can
subsequently resolve the base**, which is the card's own acceptance criterion. It also runs the SUT
inside `$( )`, so the `export`s and the `config save` happen in a subshell and are invisible to the
assertion; only filesystem effects survive.

**And the bigger hole: no test anywhere exercises strategies 2, 3 or 4 of `oo.mode.base.get`.** The
nearest fixtures (`test/test.oo:315-346`, `:362-380`) set `OOSH_COMPONENTS_DIR` and short-circuit on
strategy 1. The four checks that run on every real host are untested; `test/test.oo:30-41` (T1) is
unfalsifiable on both halves. The only genuinely falsifiable assertion that `oo.mode.base.get`
works on a real host is `test/test.platform.shared.oosh.invariant:77-86`, which is a platform test
and not part of `core`.

**Scope, recorded so it is not argued later:** there are **57** wildcard assertions across **27**
files, 15 of them in `test/test.oo` — unchanged since
[tests that cannot fail](../plans/2026-09-14-tests-that-cannot-fail.md) was written. Item 7 fixes
the ones it is already touching and proves each can flip. That is a down payment, not a substitute
for that card.

---

## 6. The two builders

| | `private.oo.shared.tree.from.local` (`oo:1647`) | `oo.mode.setup` (`oo:995`) |
|---|---|---|
| layout | `main/` + `<branch>/` — canonical | `<base>/dev`, never `main` |
| how | `cp -a`, rc checked — the source survives | `mv`, rc discarded — the source is gone |
| idempotent | explicit fast-path on `main/` existing | weaker: accepts *any* subdir holding a `.git`, so a half-converted tree reads as done |
| validates input | both arguments and the source directory | nothing |
| git fallbacks | local ref then `origin/<branch>`; handles `branch == main` | none |
| callers | install state 31's fallback path (`oo:2134`) | **none** |
| tests | three, real post-conditions (`test/test.oo:2065-2147`) | four, § 5 |
| docs | docstring states the goal and names its consumer | none anywhere |
| result protocol | bare `return 0/1` | bare `return 0/1`, **and no final return** |

Neither is a superset. The helper is a better **layout builder**; `mode.setup` is an **install
mutator** — symlink, environment, shim, summary — wrapped around an inferior layout builder. They
overlap only on `git worktree add`.

---

## 7. The question the card does not ask

**Should `oo.mode.setup` exist at all?** Zero callers, no documentation, a sibling that already
produces the right layout non-destructively and is exercised by every install fallback, and a
bridge variable the config layer refuses to store.

Three shapes, with their costs:

| Shape | What it costs |
|---|---|
| **Delegate the layout half** to `private.oo.shared.tree.from.local`, keep the mutator half (symlink, shim, config, summary) | the honest fix, and it makes the output canonical so strategy 1 stops being load-bearing. Costs a rewrite of the body and a decision about `cp -a` + explicit removal vs `mv` |
| **Thin wrapper** — only symlink + shim + config save, layout assumed to exist | smallest, but leaves the user with no command that builds the layout, which is what the failure messages promise |
| **Delete it**, document the manual `git worktree` route | removes a destructive, untested, uncalled method — and removes the only thing three error messages tell the user to run, so those would need rewriting too |

**Recommendation: delegate.** It is the only shape in which `oo mode.setup` does what its own
failure messages claim, and it deletes the second layout builder rather than repairing it.

---

## 8. Documentation gaps

`docs/oo.md` documents `oo.mode` (`:117-134`) and then jumps straight to `oo.update`. `c2` offers
**seven** mode verbs — `mode`, `mode.align`, `mode.base.get`, `mode.base.set`, `mode.list`,
`mode.setup`, `mode.stage` — of which exactly one is documented. `oo.checkout` and `oo.use` have no
sections either.

There is **no section anywhere describing the on-disk worktree layout** that all of them assume.
The closest thing in the tree is a private helper's docstring (`oo:1647`). Whatever item 7 ships
should carry it, because § 2 shows the layout is a contract, not a convention.

---

## 9. Housekeeping found on the way

- `test/test.oo:947-949` says `private.oo.shared.tree.from.local` calls
  `private.oo.safeDirectory.add` "on every (re)install". The current body (`oo:1647-1698`) has no
  such call.
- `docs/research/2026-09-16-t7-config-branch-variables.md:61` cites `oo:1077` for `mode.setup`'s
  `OOSH_MODE` export. It is at `oo:1084`; `oo:1077` is a closing `fi`.
- **`oo.use.completion.command` (`oo:1331`)** does `local branchDir="$(oo.mode.base.get)/$branch"`
  with **no rc check**. When base.get fails that is the path `/$branch`. Of the nine `.get` call
  sites this is the only one that ignores the status entirely.
- `oo.mode.setup` exports `OOSH_MODE="$currentBranch"`, which agrees with T7's semantics — that one
  is correct and should stay.

---

## 10. Open questions

1. **Does the verb survive, and in what form?** § 7 — delegate, thin wrapper, or delete.
   Recommendation: delegate.
2. **The `mv`.** Guard it and check its status, or replace it with `cp -a` followed by an explicit,
   checked removal — non-destructive until the new layout is verified, the way
   `private.oo.shared.tree.from.local` already works.
3. **Does the fix carry `OOSH_COMPONENTS_DIR`'s persistence problem or end it?** Making the layout
   canonical removes the need for strategy 1 on this path entirely — at which point the honest move
   may be to delete `oo.mode.base.set`'s "and persist" claim, or the method, rather than teach
   `config` to store a variable it documents as test noise. This one reaches beyond item 7 and may
   deserve its own card.

---

## 11. Baselines

Measured on `b6a0ecc`, before any change:

| | |
|---|---|
| `test.oo` | 132 / 132 |
| `test.this` | 32 / 32 |
| host `test.suite core 1` | 28 files, 727 assertions, 726 passed, 1 intentional, no `Shared tier:` line |
| `oo mode.base.get` on this box | returns the base, via strategy 3 |
| `oo.mode.base.get` on a `base/dev`-only fixture | **rc 1** |

---

## 12. Deliberately out of scope

- **`oo.mode.setup` is never invoked outside a throwaway fixture.** On this box its first act would
  be `mv` of the shared `dev` worktree these files live in.
- The 57 wildcard assertions beyond the ones item 7 touches — § 5.
- `oo.use.completion.command`'s missing rc check — § 9, recorded not fixed.

---

## 13. Decided, and what shipped (2026-09-16, `ff465db` … `eabf472`)

**The three answers.**

1. **Delegate.** `oo.mode.setup` keeps its unique half — symlink, shim, summary — and hands the
   layout half to `private.oo.shared.tree.from.local`. There is one definition of "canonical" in
   the tree now, and it is the one install state 31 produces.
2. **Copy, verify, then remove the original.** No `mv` of a live tree survives.
3. **Stop the false claims here, file the rest.** `mode.setup`'s `config save` is gone and
   `oo.mode.base.set`'s docstring is corrected; the variable question is filed.

**What the research did not foresee: delegation does not fit in one call.** The helper goes
`cp -a "$src" main` → normalise → `git worktree add "../$branch"`. When the plain clone already
sits at `<base>/<branch>`, `../<branch>` **is** the source, and git refuses an existing non-empty
path. Measured: rc 1, with `dev/.git` left as a plain clone's directory rather than a worktree
pointer.

The source therefore has to go **between** the copy and the worktree-add — which is also exactly
the ordering decision 2 asks for. So the helper gained
`private.oo.shared.tree.from.local <sourceDir> <branchName> <?consumeSource:no>`: it verifies
`main/` is a real repository, then removes the source, then adds the worktree. Default `no`, so
state 31's call is unchanged. Putting it there rather than in `mode.setup` is what keeps a single
layout builder, with the destructive step beside the rc checks that already guard the copy.

**One ordering changed during implementation.** The already-set-up guard now runs **before** branch
detection. Caught by a test: with detection first, an already-canonical tree whose branch
directory was not itself a repository turned a no-op into a refusal.

**The acceptance criterion is enforced twice.** `mode.setup` verifies `oo.mode.base.get` resolves
the base with `OOSH_COMPONENTS_DIR` unset **before** it touches `~/oosh` — so a failure leaves a
canonical tree and a working symlink rather than a broken pair — and T-SETUP-4 asserts the same
property end to end. § 5 showed its old post-condition would have been satisfied by a bare `mkdir`.

**Tests: 132 → 140 in `test.oo`.** Four on `consumeSource` (default keeps the source, which pins
state 31; `yes` removes it; a `main/` that is not a repository is refused rather than treated as a
licence to delete; and the in-the-way case the parameter exists for, with a negative control
confirming rc 1 without it). Four rewritten `T-SETUP`. Four new `T-BASE-GET`, because § 5 found
that **nothing** exercised strategies 2/3/4 — including the negative that is this ticket's whole
reason, `<base>/dev` with no `main/` being undetectable.

**Not fixed, filed instead:** whether `OOSH_COMPONENTS_DIR` is production configuration or test
noise. `config` documents it as the latter and excludes it; `oo.mode.base.set` treats it as the
former. With a canonical layout it is no longer needed on this path, which is why item 7 could stop
at correcting the claims.

**Live box:** `oo mode.setup` reports "already exists" and touches nothing; `oo mode.base.get`
still resolves with `OOSH_COMPONENTS_DIR` unset. Host `core` 727 → 735 assertions, 734 passed,
1 intentional, no `Shared tier:` line.
