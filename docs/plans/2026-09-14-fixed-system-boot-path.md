# T9 — a fixed system path to `boot` 🚧 In Progress

> **Card:** `. /etc/oosh/boot` — one command that recovers any user, in any shell,
> with no environment at all.

**Status:** design complete, **all five decisions taken** (bottom). Implementation started
2026-09-14.

## Why

T3 made `boot` recover `$HOME` from the password database, so it survives `env -i`. But it can
only do that **once it is reached**, and reaching it is the problem. Measured in a container:

| Under `env -i` | Result |
|---|---|
| `sh` → `. ~/oosh/boot` | **fails** — `sh: .: cannot open ~/oosh/boot: No such file` |
| `sh` → `. /home/you/oosh/boot` | `rc=0`, all three anchors recovered |
| `bash` → `. ~/oosh/boot` | `rc=0` |

With `HOME` unset, `~` is undefined in POSIX: dash and ash leave it **literal**, bash falls back
to the password database. So the form `docs/boot.md` documents, and that all 20 call sites use,
is exactly the form that cannot work in the empty-environment case `boot` exists to survive.

`boot` cannot fix this from inside — the shell resolves the path before `boot` runs. The thing
that would recover `HOME` sits behind a path that needs `HOME`.

**Found by the user testing `env -i sh` by hand in a platform-test container.** No automated test
caught it, because T65 sources `"$OOSH_DIR/boot"` — a path the test builds itself. That gap is
now closed by **T66** (`4dbabd5`), which runs the *documented* command verbatim.

## Recommendation

A single host-wide symlink **`/etc/oosh/boot` → `<sharedOoshBase>/<installBranch>/boot`**,
created as root by a new install state **`34 root.boot.path.installed`**, healed by a new
**`oo boot.fix`**.

### Why `/etc/oosh`

- **Precedent in-repo, on both platforms.** `init/oosh:351-354` already writes
  `/etc/paths.d/oosh-homebrew` as root with `$SUDO tee` + `chmod 644` — macOS-only code, so it is
  proof root can write `/etc` on macOS (`/etc` → `private/etc`; SIP covers `/System` and `/usr`
  except `/usr/local`). One precedent, one idiom, one permission model.
- **FHS allows it.** FHS 3.0 forbids *binaries* under `/etc`, not sourced fragments.
  `/etc/profile`, `/etc/bashrc`, `/etc/profile.d/*.sh` are the established idiom for precisely
  this — a shell fragment sourced into a user's environment.
- **`/usr/local/share/oosh/boot` is worse in practice.** On Apple Silicon the live prefix is
  `/opt/homebrew`; `/usr/local` may not exist on a fresh macOS. `init/oosh:174` already has to
  probe *both* prefixes. A "fixed" path whose location depends on CPU architecture defeats
  the entire purpose.
- **`/usr/local/bin/` is wrong on type grounds.** `boot` is sourced, never executed
  (`docs/boot.md`). A non-executable fragment in a `bin` dir invites being run as a program,
  which sets variables in a process that immediately exits.

Own the directory, not just the file — it leaves room for a future `/etc/oosh/sharedbase`
without re-arguing the FHS question.

### Why a symlink, and not a stub or a copy

- **The repo rule.** `boot:2-7`: it is *"the SINGLE entry point… It owns ALL the bootstrap logic
  that the old design generated INTO the config env files, so those files can stay PURE DATA."*
  A generated stub at `/etc/oosh/boot` would be a second, hand-rolled bootstrap fragment living
  outside `boot` — the exact shape the "config has code!" ticket removed.
- **A stub cannot actually do the job.** It cannot say `. "$HOME/oosh/boot"`, because with `HOME`
  unset that expands to `/oosh/boot`. To work it would need its own copy of the
  getent→dscl→/etc/passwd lookup — and `boot:34-36` already records that this block is
  "DELIBERATELY DUPLICATED in init/oosh" and why a third copy is unacceptable. The only stub that
  works is a symlink with extra steps.
- **A copy is worse than either.** It reintroduces the defect T4+T5 just removed: two versions of
  the same truth depending on which entry point ran. A dangling symlink fails loudly
  (`sh: .: cannot open`); a stale copy boots you into last month's bootstrap in silence.

### Where it is created

**New state `34 root.boot.path.installed`** in `private.init.state.machine` (`oo:1275-1310`).

- Root is available from state 30 onward: `private.check.priviledges.checked` (`oo:1345`) routes
  to the 30-lane when `$USER = root` or sudo works; `ossh:523` re-enters as root. State 33
  (`oo:2053`) already does unguarded `chsh -s … root` and `sed -i /etc/passwd`.
- **Inserting it renumbers nothing.** `state.add` (`state:732-786`) treats a numeric argument as
  a transition marker that jumps the index. Adding between `oo:1295` and `oo:1296` lands the new
  state at 34 and pushes only the `state.add 40` marker to 35 — every existing state number,
  including those hard-coded in comments across `oo` and `ossh`, is unchanged.
- **Not folded into state 31**, which is disqualified by its own idempotent fast-path
  (`oo:1573-1580`): it returns success *without entering the body* whenever the invariant already
  holds, so new work in the body would be silently skipped on every re-install of a healthy host.
  That is a correctness trap, not a style objection.
- **Not folded into state 33**, which conflates scopes and currently `return 0`s unconditionally
  (`oo:2089`); making it fail-loud would change the failure surface of `chsh`/`.bashrc` work that
  is deliberately best-effort.
- Consistent with the standing rule recorded at `ossh:733-748` — F3/F4 were *moved out* of
  `ossh.install.continue.local` into state 31 precisely so "State machine owns it; if it fails,
  state 31 halts."

Shape, mirroring the existing testable-helper pattern (`private.oo.user.shared.symlinks.ensure`,
`oo:1498`) so tests can drive it against a fixture without root:

```
private.oo.boot.path.ensure <sharedOoshBase> <branch> [<systemPath:/etc/oosh>]
  → verify <target> exists     (warn-and-SKIP if not — see promotion risk)
  → mkdir -p /etc/oosh ; chmod 755
  → ln -sfn <target> /etc/oosh/boot    (-n so a re-run does not nest inside a dir symlink)
  → post-condition [ -L ] && [ -r ], else create.result 1
private.check.root.boot.path.installed()  → calls it, returns $(result)
```

### How it is healed — `oo boot.fix`

None of the five existing repair primitives can absorb it: `oo user.fix` / `config init.user` are
per-user scope and run as the user; `config init.shared` is host scope but its single
responsibility is `sharedConfig` mode 2775 + group `dev`; `ossh rights.fix` / `folder.fix` are
`~/.ssh`-only. `docs/repair-toolkit.md:5-7` states the constraint: *"Each primitive has a single,
scoped responsibility."*

**A repair method is not optional**, because the state-machine declaration is **frozen per host on
first install**: `state.machine.init` (`state:887-907`) writes the state array once,
`private.state.machine.update` (`state:913-933`) persists it, and `oo.state()` (`oo:1233`)
re-creates the machine only when it does not exist. **Every already-installed host will never see
state 34.** `oo boot.fix` is the only path onto those machines.

Naming follows `oo user.fix`, not `oo fix.user`. Add `oo boot.status` as the read-only report,
emitting via plain `echo` per the status-command idiom. **Do not auto-trigger it** — `oo update`
runs as an ordinary user with no sudo (`oo:191-232`), and implicit auto-repair on startup was
deliberately removed after the May-8 sudo-chain incident (`docs/repair-toolkit.md:7-10`).

### Multi-user: one path, pinned to the canonical install, deliberately NOT following the caller

`boot`'s content is **user-independent and branch-independent by construction**. It names no user
(`$HOME` is derived at run time, `boot:37-69`) and no branch — every anchor is a literal built
from `$HOME`: `OOSH_DIR="$HOME/oosh"` (`boot:78`), `CONFIG_PATH="$HOME/config"` (`boot:84`),
`OOSH_USER_CONFIG_PATH="$HOME/.config/oosh"` (`boot:91`). Everything branch-specific is then
loaded *through those anchors, from the caller's own tree* (`boot:106`, `boot:149`).

So a user on `testing` sources `/etc/oosh/boot`, gets `OOSH_DIR=$HOME/oosh`, and immediately
loads **their own** config and **their own** `log`. Only the ~160-line anchoring prologue comes
from the canonical copy.

"Follow the user" is not merely undesirable — it is **impossible**, for the same reason the ticket
exists: to know whose tree to follow you need `HOME`, which is what you don't have. A
`/etc/oosh/boot → /root/oosh/boot` variant fails twice: it follows root's branch, not the
caller's, and on Linux `/root` is mode 700 so no ordinary user can read through it.

Residual coupling to state in the docs: **`boot`'s prologue becomes host-wide.** If a branch's
`boot` diverges, users on that branch get canonical anchor semantics. Acceptable, arguably
correct, and `boot` is already the most heavily pinned file in the tree.

## Tests

- **T67** (`test.config`) — `. /etc/oosh/boot` works under `env -i` in all four shells; asserts
  the path is a **symlink** (not a copy or stub) and that it resolves to something readable.
  Skips cleanly with a recovery hint on a host installed before state 34.
  Made failable deliberately: ends with `return $(result)` (closing the `create.result` defect
  annotated at `test.config:1310-1315`) and matches a **literal** success string rather than
  `expect 0 "*"`, so the skip path and every failure path fail the comparison.
- **`test.platform.boot.system.path.invariant`** (`TEST_CATEGORY=platform`) — run inside
  `os platform.test <p> terminal` as each of root/test/oosh-user/bash-user: the symlink exists,
  resolves into the shared tree, and **a non-root user can read through it** — the one property a
  host-scope symlink into a group-owned tree can lose silently.
- **Update T66 in the same commit.** Its tilde tripwire (`test.config:1424-1429`) is designed to
  go red when this lands. Leave it red by accident and the signal is wasted: it should keep
  asserting the caveat (still true) but drop the "until a fixed path exists" framing, and
  `docs/boot.md` should replace the getent one-liner and the **Open** block with the one command.

## Risks

| Risk | Assessment |
|---|---|
| **Dev-group-writable code behind a root-looking path** | **Escalate.** State 31 runs `chmod -R g+w "$dir/shared"` (`oo:1809`), so any member of `dev` can edit the file `/etc/oosh/boot` points at — and anyone who sources it, root included, executes it. The trust model is unchanged from root's existing `~/oosh` (already a symlink into the same tree), but a path under `/etc` *looks* root-owned and will be treated as trusted by reviewers and by future code. |
| **Promotion to `testing`/`prod`** | Real. `boot` exists on `dev` only (`docs/boot.md` cross-branch note). An install from `testing` would create a **dangling** link. Mitigation: `private.oo.boot.path.ensure` must test `[ -f "$target" ]` and **warn-and-skip**, never create a dangling link; state 34 must then *pass* (absence is correct on a branch without `boot`), not halt. |
| **Read-only `/etc` / no root** | The 20-lane (user-rights-only install) never reaches state 34 — correct; the feature simply does not exist there and T67 skips. Follow `init/oosh:351-354`: warn on failure, do not `die`. |
| **macOS / SIP** | `/etc` → `private/etc` is root-writable and not SIP-protected; proven in-repo by the macOS-only write at `init/oosh:351-354`. `/usr` *is* protected except `/usr/local` — a further argument against that candidate. |
| **SELinux (Alma/RHEL)** | Low. A symlink is read through to its target, labelled `home_root_t`/`default_t` under `/home/shared/...`. Unconfined user shells — the only consumers today — are unaffected. A *confined* domain sourcing it would be denied. One sentence in the docs; not a blocker. |
| **AppArmor** | Path-based, applies only to confined profiles. User shells unconfined. No impact. |
| **`this anchor.validate`** | The helper writes a *path*, not an `OOSH_DIR=`/`CONFIG_PATH=` assignment, so the tree sweep is unaffected and needs no exception marker. Confirm with `./this anchor.validate` after implementation. |
| **Sourcing on a host where the user never installed oosh** | `boot` sets a nonexistent `OOSH_DIR`, skips the guarded sources, prepends a nonexistent dir to PATH, returns 0. Harmless and already true — but now reachable by users who never installed, so it becomes a *reported* behaviour rather than a theoretical one. |

## What it unlocks beyond the docs cleanup

`os:352` and `os:380-394` currently hardcode `/root/oosh/boot` vs `~/oosh/boot` per user; systemd
units (which frequently run with no `HOME`) get a stable ABI; and `ossh exec`'s five
`|| <degrade>` call sites gain a second recovery rung.

## Decisions taken (2026-09-14)

1. **Trust — (a) accept and document.** `/etc/oosh/boot` points at dev-group-writable content.
   This is the *same* trust model as root's existing `~/oosh`, which is already a symlink into the
   same `chmod -R g+w` tree — the change is not that `dev` members can influence root's bootstrap
   (they already can), but that the path now *looks* root-owned. So it must be said out loud, in
   two places: a note in `docs/boot.md` next to the fixed-path instruction, and a comment at the
   creation site in `oo`. Anyone who later treats `/etc/oosh/boot` as trusted-because-`/etc`
   should find the correction where they are looking.
2. **Pins to the install branch.** `$OOSH_BRANCH` as state 31 already builds it; `oo mode` does
   **not** re-point it. Low-stakes by construction: `boot` names no branch, so all a user on
   another branch inherits is the ~160-line anchor prologue, and their own config and `log` still
   load from their own tree (`boot:106`, `boot:149`).
3. **New state `34 root.boot.path.installed`.** Dedicated halt point, so a failure reads
   *"halted at [34] root.boot.path.installed"* rather than being folded into state 33's
   best-effort `chsh`/`.bashrc` work. Renumbers nothing.
4. **`$SUDO` internally, not `sudo oo boot.fix`.** One command in the docs that works whether the
   caller is already root or a `dev` member with sudo, matching `init/oosh`'s idiom
   (`init/oosh:351-354`). If neither applies it fails loudly naming what it needed — it must never
   half-succeed.
5. **A card of its own** — this one. T3 stays In Review.
