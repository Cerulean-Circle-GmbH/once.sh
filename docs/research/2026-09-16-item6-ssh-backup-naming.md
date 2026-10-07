# Item 6 — research: the `ssh.<user>.<host>.for.<host>` directory

**Written 2026-09-16 · Branch `dev` (`8875332`) · Status: DELIVERED — questions answered in § 11, what actually shipped in § 15.**
**Card:** `/root/ssh..2378eed3bee5.for.2378eed3bee5`

Ticket: [board backlog](../plans/2026-09-15-board-backlog.md) § 6 — the last **HIGH · install**
item on the list.

One stray directory name is the visible end of a code path that has been wrong since
`cab62d9` (2022-03-25, *"added user ssh functions and external install"*) and has never been
tested, documented or read back. **Grounding the card against today's tree makes it worse than
written, not better.** The card lists three defects; there are six. The guard that is supposed to
make the backup run *once* can never be satisfied, so it runs on **every** install and **nests one
level deeper each time**. The backups are **write-only** — nothing in the tree ever reads one. And
the restore half, which nobody calls, would `rm -Rf ~/.ssh` before discovering it has nothing to
put back.

**There is live proof on this machine**, and it is left in place deliberately — it is the evidence:

```
drwx------ 4 root root 4096 Apr 29 16:57 /home/hannesn/ssh.original
drwx------ 5 root root 4096 Apr 30 08:12 /home/hannesn/ssh.root.hannesn-VirtualBox.for.hannesn-VirtualBox
drwx------ 6 root root 4096 Apr 29 16:57 /home/hannesn/ssh.root.vm-dev.for.hannesn-VirtualBox
```

Copies of **root's** `~/.ssh`, mode `0700`, sitting in a normal user's home. `hannesn` cannot read
them (`ls` → `Permission denied`).

---

## 1. The call chain, once

```
init/oosh:590      local_name="${REMOTE_SSH_HOST:-$(hostname -s …)}"
init/oosh:592      "$OOSH_DIR/this" call ossh install.continue.local "$local_name" "$CONFIG_REMOTE"
ossh:707-708       check dir $HOME/ssh.original not exists \
                     call user ssh.backup original
ossh:712-713       check dir $HOME/ssh.$USER.$sshConfigNameUsedForLocal.for.$remoteSshConfigName not exists \
                     call user ssh.backup $USER.$sshConfigNameUsedForLocal.for.$remoteSshConfigName
check:339-343      check.call stores FIX_BY_CALL="$*"
check:348-372      private.check.call.execute runs it bare — `$FIX_BY_CALL` — no cd, child process
user:1284          cp -R $sshDir ssh.$name          ← RELATIVE TO CWD
```

`private.user.get.sshDir` (`user:81-94`) resolves `$sshDir` to `$CURRENT_SSH_DIR`, else
`$HOME/.ssh`. The **source** is absolute. Only the **destination** is relative.

---

## 2. Corrections and additions to the card

| The card says | What is actually true |
|---|---|
| three defects | **six.** Three more in § 3, and one of them has a security shape none of the three have |
| `$USER` unset → `ssh..` | **dead.** Measured, § 4. `this:74-77` heals `USER` from `id -un` at *file scope*, the install reaches this code through `this call`, and `ossh.start` sources `this` too — so no live path leaves it empty |
| the backup "only landed in `/root/` because cwd happened to be `/root`" | right, and the reason is worth naming: **cwd is unanchored the whole way up.** Neither `init/oosh` nor `this` nor `ossh.install.continue.local` contains a `cd` on the live path — `init/oosh`'s three `cd`s are all inside command substitutions, so they run in subshells. cwd is whatever directory the operator invoked the installer from |
| "the guard tests `$HOME/ssh.…` but … does `cp -R $sshDir ssh.$name`" | correct, and it has a consequence the card does not draw: **the guard can therefore never become true**, so the "backup once" intent is inverted into "back up on every install" — § 3 |

---

## 3. The three defects the card does not mention

### 3.1 The guard can never be satisfied — so it fires on every install

`ossh:707` and `ossh:712` test an **absolute** path (`$HOME/ssh.<name>`); `user:1284` writes a
**relative** one (`./ssh.<name>`). Unless cwd happens to equal `$HOME`, the test stays true
forever.

**And a repeat run nests.** `cp -R src dst` with an existing directory `dst` copies *into* it.
Measured with a fixture `HOME` and cwd elsewhere:

```
$ user.ssh.backup probe          # once
./ssh.probe/id_probe
$ user.ssh.backup probe          # twice
./ssh.probe/id_probe
./ssh.probe/.ssh/id_probe        ← nested one level
```

So on a machine installed *n* times from the same directory, the backup grows
`ssh.X/.ssh/.ssh/…` — each layer another full copy of the key material. (The three real
directories on this box are root-owned and unreadable from this session, so their internal shape
is *predicted*, not verified.)

### 3.2 `user.ssh.restore` is a loaded gun

`user:1302-1303`:

```bash
  rm -Rf $sshDir
  cp -R ssh.$name $sshDir
```

`rm` first, `cp` second, and the `cp` source is the same cwd-relative name. Invoked from the wrong
directory it **destroys `~/.ssh` and then fails to replace it**. It has **zero callers** anywhere
in the tracked tree — which is the only reason this has never fired.

### 3.3 Root's private keys in a user's home

The three directories above are `root:root`, `0700`, inside `/home/hannesn`. The `0700` is the
entire mitigation. The *containing* directory belongs to `hannesn`, so `hannesn` can rename or
remove the path (and therefore hand it to a process that runs as someone else) without being able
to read a byte of it. Two of the three predate the current code by months; they are not
hypothetical.

This is the one to lead with. The other five are correctness bugs; this one is key material in a
place nobody decided to put it.

---

## 4. Defect 1 is already dead — measured

The card asks for this to be disproved before anything else is done. It is.

`this:74-77`, at **file scope**, so it runs on sourcing or executing `this`, before any function is
defined:

```bash
if [ -z "$USER" ]; then
  USER=$(id -un 2>/dev/null)
  export USER
fi
```

Measured on `8875332`:

| Probe | `$USER` | resulting name |
|---|---|---|
| A — control: `env -u USER -u LOGNAME`, **no** `this` | *(empty)* | `ssh..local.for.remote` ← the card's title |
| B — `env -u USER -u LOGNAME`, `source this` | `hannesn` | `ssh.hannesn.local.for.remote` |
| C — `env -i HOME=…`, `source this` (the clean re-exec) | `hannesn` | `ssh.hannesn.local.for.remote` |

Both live routes into `ossh.install.continue.local` pass through `this`:

- `init/oosh:592` — `"$OOSH_DIR/this" call ossh install.continue.local …`;
- a direct `./ossh install.continue.local` — `ossh.start` (`ossh:3549`) does `source this`.

`c140c21` also carries `USER` and `LOGNAME` through the clean re-exec (Group 1 of the carry list,
[install-bootstrap.md](../install-bootstrap.md)). The on-disk evidence agrees: all three real
directories carry a populated `root` segment, none is the `ssh..` double-dot form.

**Conclusion: shrink the card.** `ssh..` is unreachable; the title is a historical artefact. The
implementation should still land probe A and B as a test case, because the property "`$USER` is
non-empty by the time `ossh` builds a path from it" is currently pinned by nothing.

---

## 5. The naming, as a contract

`ossh:654`:

```
ossh.install.continue.local() # <remoteSshConfigName> <sshConfigNameUsedForLocal> #
```

Both parameters have completion functions (`ossh:1320-1326`) that delegate to
`ossh.parameter.completion.sshConfigHost` — i.e. they promise an **ssh config Host alias**.

| Path | arg 1 → `remoteSshConfigName` | arg 2 → `sshConfigNameUsedForLocal` | Result |
|---|---|---|---|
| curl one-liner / drag-and-drop (`init/oosh:590`) | `hostname -s` — the **local kernel hostname** | `$CONFIG_REMOTE`, usually empty → `$OOSH_SSH_CONFIG_HOST` or `$HOSTNAME` | `ssh.$USER.<host>.for.<same host>` |
| `ossh install <host>` (`ossh:523`) | `$sshConfigHost` — the **target** | `${OOSH_SSH_CONFIG_HOST:-_}` — the **runner** | `ssh.$USER.<runner>.for.<target>` — the intended meaning |

So the scheme is **meaningful for a remote install and degenerate for a local one**, and the box
shows both: `ssh.root.vm-dev.for.hannesn-VirtualBox` is a genuine remote pair;
`ssh.root.hannesn-VirtualBox.for.hannesn-VirtualBox` is the `X.for.X` case.

Two things follow, and any fix must respect both:

- **argument 1 is a two-caller contract.** Changing its meaning changes `ossh install <host>` as
  well as the local path. `ossh:523` is the other caller;
- on the local path the value passed is not an ssh config alias at all, which is what the
  parameter name and its completion function both promise. The mismatch is the defect, not the
  `.for.` scheme itself.

`ossh:712-713` is the **only** `.for.` path construction in the tree (plus its `restore/` mirror),
and it has **no consumer**.

---

## 6. Why nothing caught it

Three mechanisms would normally have caught this. All three skip these two methods, **for the same
single reason**: `user.ssh.backup` (`user:1269`) and `user.ssh.restore` (`user:1287`) are bare
`name() {` — **no docstring**.

- `test/test.completion.audit` extracts parameter names from signatures, so it sees none and
  demands nothing;
- neither method has a completion function, and `user.parameter.completion.sshDir` (`user:30-33`)
  therefore never fires for them;
- `this.help` renders from docstrings, so the only documentation is the hand-maintained usage text
  at `user:1333-1334` — **which contradicts the code**: it says restore reads `ssh.<newName>` *"in
  sshDir"*, and the code reads it from cwd.

And there is **no test anywhere in the tree** for either method. `git grep` over `test/` returns
nothing; `test/test.user:3` enumerates its own scope and these are not in it.

That is why the docstrings are part of the fix, not tidying afterwards.

---

## 7. The placement question — with the nuance that cuts the other way

The backlog frames this as: the working agreement forbids new fixups in
`ossh.install.continue.local`, so should the backups move into a state?

**The audit already answered half of it.**
[`state-machine-fixup-audit.md`](state-machine-fixup-audit.md) § *Decision rules*:

> | Backup-before-overwrite (`check dir … not exists call …`) | **LEGIT** (preserves user state). |

So the two calls that exist are not the violation. What the agreement forbids is adding a **fourth
fixup** beside them — and the in-code record at `ossh:739-748` says exactly which three were moved
out and why ("State machine owns it; if it fails, state 31 halts and the install does not progress
here").

What *is* open, and what the doc puts to the boss:

- the calls sit **after** the `oo state` call at `ossh:699` — they are post-state-machine by
  construction;
- **no install state owns SSH backup.** The state list is `oo:1474-1501`; there is no candidate
  today, and `ossh.install.finish.local` (`ossh:762-817`) does no backup at all;
- `user init` runs *between* the two backups (`ossh:710`), so the second one deliberately captures
  a **post-`user init`** `~/.ssh`. Any move has to preserve that ordering or it captures something
  different from what it captures now.

---

## 8. The prior question the card does not ask

**Should the backup exist at all?**

- `user.ssh.restore` has **zero callers**;
- nothing in the tree reads a `ssh.*.for.*` directory — they are **write-only**;
- `osshLayout` now owns `~/.ssh` and builds it **idempotently and non-destructively**
  (`osshLayout.build`, `osshLayout:446`; the role methods at `:147`, `:208`, `:228`, `:348`), which
  is a large part of what the backup was insuring against in 2022;
- `user init` (`user:244`) was rewritten in `f515903` to be append-if-missing, replacing a
  destructive `} >$sshDir/config` heredoc — the other thing the backup insured against.

Fixing a mechanism nobody consumes is the more expensive mistake, so this comes before the fix.
The three honest shapes, with their costs:

| Shape | What it costs |
|---|---|
| **Keep and anchor** — `$HOME/ssh.<name>`, guard and write agreeing | smallest change; keeps a write-only artefact growing on every install unless the guard is also fixed; still leaves root-owned copies in the invoking user's home on a `sudo` install |
| **Keep as a real archive** — one timestamped tarball under a known directory, owned by the user whose keys it holds | honest, greppable, does not nest, survives repeat installs; costs a rewrite of both methods and a decision about where archives live |
| **Delete both** | removes six defects at once and 36 lines; costs the *only* pre-install snapshot of `~/.ssh` there is, and the card explicitly frames this as a backup worth having. Requires being sure `osshLayout` + `user init` are genuinely non-destructive on every path |

The doc does not choose — that is question 1 in § 11 — but it records the recommendation:
**keep as a real archive**. It is the only shape in which the thing does what its name says.

---

## 9. Cleanup — decided, recorded rather than asked

Decided by the user, 2026-09-16: the ticket covers **the debris that already exists**, not only the
defect. The constraints, so the implementation does not have to rediscover them:

- it is a **method**, not a shell snippet, and it belongs with the repair toolkit already
  documented in [repair-toolkit.md](../repair-toolkit.md) — `oo user.fix`, `config init.user`,
  `ossh rights.fix`, `ossh folder.fix`;
- **report before destroy.** The T8 precedent is `path validate` / `this anchor.validate`: echo the
  verdict on stdout so it survives any `LOG_LEVEL`, rc 1 on findings, and let a separate verb act.
  A repair that deletes SSH key material on first invocation is not acceptable;
- it must cope with what is actually there: **root-owned directories the invoking user cannot
  read.** The doc's position is that the reporting verb must work unprivileged (it only needs
  `stat` on the path, which the parent directory permits) and the acting verb must state plainly
  that it needs `$SUDO`, rather than silently failing;
- it must not touch `~/.ssh/ids/ssh.*`. `osshLayout` uses the same `ssh.<id>` prefix for a
  completely different thing (`osshLayout:329`, `:173-176`). `$HOME/ssh.*` and
  `$HOME/.ssh/ids/ssh.*` do not collide, but the overload is a real readability trap — three
  meanings for one prefix.

---

## 10. What else the sweep found

Recorded so it is not rediscovered, and so the implementation knows what it is *not* fixing.

- **`restore/user` and `restore/ossh` carry byte-identical copies** of both defects
  (`restore/user:626`, `:645`; `restore/ossh:436-437`). A fix to `user` alone leaves a working copy
  of the bug in the tree. Note `path validate` (T8) excludes `restore/` and `old/` by pathspec as
  legacy graveyards — the same argument applies here, and the doc's position is that `restore/` is
  **out of scope** and should be said so out loud rather than silently skipped.
- **`ossh:2437-2439`** does a bare `cd $sshDir/ids` that is never restored, leaking a changed cwd
  to everything the caller does afterwards in the same process. Same family, its own finding.
- **`oo:2260`** `cp -r config.initial/stateMachines/ config` has *both* operands cwd-relative. Not
  a defect today — a surrounding `cd` saves it — but the same latent pattern.
- **`user:1284` is the only true instance** of the bare-relative-destination shape in the tree.
  Every other `cp -r`/`cp -R` hit is `$`-anchored, absolute, or an explicit `./name`. Its partner
  `user:1303` does not match a destination-side sweep at all, because there the *source* is the
  relative one — a regex sweep alone would have found one half of the bug.
- **`init/once:1557`** prints `user ssh.backup` as operator advice inside an `important.log`
  string. Not a caller; it is why this path has historically "worked" (an interactive shell's cwd
  is usually `~`).

---

## 11. Open questions

Three, for the boss, before any code. The first two are coupled.

1. **Does `user.ssh.backup` survive, and in what shape?** Anchor it at `$HOME`; rewrite it as a
   timestamped archive; or delete both methods as write-only. Recommendation in § 8: the archive.
2. **Where does it live?** Stay in `ossh.install.continue.local` — the audit classifies
   backup-before-overwrite as legit there — or move into an install state so the state machine owns
   it and halts when it fails. Note the ordering constraint in § 7: the second backup is
   deliberately taken *after* `user init`.
3. **The name.** Fix the argument order so a local install cannot produce `X.for.X`, or retire the
   `.for.` scheme for something that carries a timestamp and cannot be ambiguous. Whichever, it has
   to hold for **both** callers of `ossh.install.continue.local` (§ 5).

**Not a question** — recorded so it is not asked again: **the cleanup is in scope**, and its
constraints are in § 9.

---

## 12. Baselines, for the implementation to move from

Measured on `8875332`, before any change.

| File | Host | Note |
|---|---|---|
| `test.user` | 19 / 19 | **prompts for `sudo` on the host** and cannot complete unattended; the run above was interrupted at the prompt. In a container with passwordless sudo it is 23 / 23 |
| `test.ossh` | 99 / 99 | |
| `test.install` | 35 / 35 | |
| `test.check` | 11 / 11 | |
| `test.osshLayout` | **0 / 0** | runs 25 test cases and reports *"NO RESULTS: produced no score of its own"* — backlog ticket 3's symptom, still live in this file |
| host `test.suite core 1` | 27 files, 695 assertions, 694 passed, 1 intentional | no `Shared tier:` line |

**None of `test.user`, `test.ossh`, `test.install`, `test.osshLayout` carries a `TEST_CATEGORY`**,
so none of them runs in `core`. Whether the new tests join `core` is a real decision: the ones that
matter here (a fixture `HOME`, a cwd elsewhere, no real keys touched) are cheap and hermetic and
**should** — but `test.user` as it stands cannot, because it wants `sudo`.

### The control, run today

The card's own "Done when" criterion, exercised against HEAD so the implementation has something to
move from. Fixture `HOME`, cwd elsewhere, no real keys involved:

```
$ cd elsewhere && HOME=fakehome user.ssh.backup probe
rc=0
in cwd (elsewhere):   ssh.probe
in fixture HOME:      (nothing)
```

It fails today, in exactly the way the card predicts. Run twice, it nests (§ 3.1).

---

## 13. Conformance of what is proposed

Checked before proposing, not after.

- **New methods come from `oo method.new`** — docstring, typed parameters and a completion stub per
  parameter, per the Method Structure Standard (`docs/oosh-architecture.md:122-124`, MANDATORY).
- **Deletions come from `oo method.delete`** (new on `2471b43`), so a removed method takes its
  docstring, its completion functions and its test with it; a legacy `private.` helper whose name
  carries no script segment goes via `replace block`.
- **Result contract**: `create.result` on every branch, `return $(result)` last. The two exemptions
  are stated rather than assumed — a getter consumed as `$(...)` runs in a subshell and must answer
  on stdout, and a completion function must never call it at all.
- **Status-output idiom**: the reporting verb in § 9 `echo`es its verdict, as `path validate`,
  `config.validate` and `this.anchor.validate` do.
- **OOSH commands before raw bash**: the repair is a method in an existing script, not a snippet;
  it reuses `private.user.get.sshDir` (`user:81`) rather than re-deriving `~/.ssh`.
- **`ossh.install.continue.local` gets no fourth fixup.** Whatever is proposed says which existing
  thing it replaces.
- **The two methods at the centre of this get docstrings** — that omission is *why* three separate
  safety nets missed them (§ 6), so it is part of the fix.

---

## 14. Deliberately out of scope

- The three directories on this box stay exactly where they are until the cleanup method exists.
  They are the evidence.
- `/root` is not readable from this session, so whether a matching set exists there is
  **undetermined**, not absent.
- `restore/` and `old/` — see § 10.
- `ossh:2437`'s leaked `cd` and `oo:2260` — recorded, not fixed here.

---

## 15. Decided, and what shipped (2026-09-16, `6ad508e` … `65ccd9d`)

**The four answers.**

1. **Archive** — a timestamped **directory** under `$HOME/.ssh.backups/`, not a tarball. There is
   no `tar` anywhere in the tracked tree, and the install path is the wrong place to introduce a
   cross-platform dependency for this. `cp -R "$src/." "$dst/"`, the idiom `osshLayout:220` already
   uses.
2. **Placement: it moved.** § 7 left this open; the measurement closed it. `oo state` at
   `ossh:699` drives the machine to 99 before returning, and state 31 writes `~/.ssh` at `oo:2066`
   and after — so the backup labelled `original` never was. The snapshot is now the first thing
   state 31 does, immediately above its own `mkdir -p "$HOME/.ssh"`, and it **fails loud**: the
   state halts rather than continue without one. The *second* snapshot stayed exactly where it
   was, immediately before `user init` — backup-before-overwrite, which § 7 showed the audit
   already blesses there.
3. **The argument order is kept**, and § 5's analysis is why: both callers pass the same shape, so
   the order was never the defect. `.for.` is retired because the install runs **on the target**,
   which made `.for.<target>` name the host the directory was already sitting on — redundant on
   *both* paths, not only the degenerate local one. No caller changed.
4. **Cleanup shipped** — `user ssh.backup.status` / `user ssh.backup.migrate`, § 9's constraints
   honoured: unprivileged reporting, move rather than delete, `$SUDO` named when it is needed, and
   the two same-prefix decoys (`$HOME/.ssh.backups`, `$HOME/.ssh/ids/ssh.*`) asserted to survive.

**Why a new state was not added.** § 7 assumed the choice was "stay, or add a state". It is
narrower than that: `private.check.priviledges.checked` (`oo:1537-1552`) **branches**, returning
`20` or `30` as the follow-up, so a state appended to the 10-lane is unreachable — and inserting
one before it renumbers `priviledges.checked`, which twelve files name by number, including
generated `docs/puml/*.svg` and `.html`. The T9 comment at `oo:1486-1491` warns about exactly
this. Putting the snapshot inside the state that does the writing satisfies the rule without any
of that.

**One claim in this document was wrong.** § 12 says the property "`$USER` is non-empty by the time
`ossh` builds a path from it" is *"currently pinned by nothing"*. It is pinned:
`test/test.this:543-561`, **T-THIS-USER-SELF-HEAL**, sources `this` under `env -i` and reads
`USER` back. Since `this` guarantees it for every oosh context, a second test in `test.user` would
have been a duplicate, and none was added.

**Two prerequisites the ticket had to clear first.**

- `test/test.user` carried **no `TEST_CATEGORY`**, so none of this would have run in the standing
  bar — and it could not join `core`, because it blocked on a sudo password prompt. The cause was
  one line in a fixture: `T-USER-INIT-SELF-HEAL` deliberately plants an incomplete
  `os.commands.env`, whose self-heal ends in `oo pm.discover` → `$SUDO apt-get update`
  (`oo:2961-2970`), and `sudo` reads the tty, so the redirects could not suppress it. Fixed with
  `OOSH_PM_UPDATED`, the mechanism `oo` already has for "the index has been refreshed".
- `user` and `test/test.user` had **neither insertion marker**, so `oo method.new` could not have
  written into either. Both added — the same template gap T8 found in `path`, `line` and
  `replace`.

**What is deliberately NOT fixed, and now has its own card.** `ossh:705` does
`config ssh.host.set "$sshConfigNameUsedForLocal"`, and by § 5's table that is the **runner's**
alias on the remote path, while `config.ssh.host.set` (`config:1025`) is documented as *"the name
of this host for ssh config"*. It lands right only because the runner's `OOSH_SSH_CONFIG_HOST` is
usually unset and `init/oosh:426` turns the `_` placeholder into empty.
`ssh.root.vm-dev.for.hannesn-VirtualBox` on the dev box is a case where it was not. That changes
remote-install behaviour, so it is not bundled into a backup fix.

**Baselines moved**: `test.user` 19 → 29 and it now runs in `core` for the first time;
`test.ossh` 99 → 101; `test.oo` 131 → 132; host `core` 27 files / 695 assertions → **28 files /
727 assertions**, 726 passed, 1 intentional, no `Shared tier:` line.

**Still open, on purpose** (§ 14): the three directories in `/home/hannesn` are untouched — the
tool that moves them now exists, and running it is the user's call.

### The ubuntu gate, on `1122808`

A real install from `origin/dev` into `os platform.test ubuntu_24_04`:

```
--- stray ssh.* in any home:
NONE (correct)
--- archives in /root/.ssh.backups:
20260916T080540Z-pre-install        ← state 31, before its first ~/.ssh write
20260916T080650Z-pre-user-init
20260916T080656Z-pre-user-init
--- user ssh.backup.status (as bash-user):
OK: no legacy ssh.* backup directories in /home/bash-user      rc=0
```

Three things it proves that no unit test can: the archives land in **root's own home** rather than
wherever the installer was started, **nothing** named `ssh.*` is created in any home any more, and
the two labels appear in the right order with the state-31 snapshot first. The two `pre-user-init`
entries are `ossh.install.continue.local` running more than once — which it always did; the
difference is that they no longer nest inside each other.

In-container `test.suite core 1`: 28 files, 731 assertions, 730 passed, 1 intentional, no
`Shared tier:` line. The +4 over the host are `test.user`'s password tests, which run where sudo
is passwordless.
