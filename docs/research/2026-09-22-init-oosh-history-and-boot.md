# `init/oosh` through its history, and whether `boot` belongs inside it

Research only — nothing changed. Written 2026-09-22 against dev `09020ba` (worktree
HEAD), `origin/main` (`29f4252`), and the full `git log --follow` of `init/oosh`
(166 commits, 2021-11-23 → 2026-09-21). Line numbers are in the dev worktree unless
a commit is named.

## The question, and the short answer

The boss's position, as relayed: *`boot` should be removed and its tasks taken over
elsewhere — by `init/oosh`.* The user's doubts: is that a clean separation of concerns,
did `boot`'s job ever live in `init/oosh`, and how did it work before?

**Short answer.**

1. **`boot`'s job was never in `init/oosh`.** In every one of its 166 revisions
   `init/oosh` has been a one-shot *installer* that runs before `~/oosh` exists:
   find a package manager, get git and bash, clone, put the clone at `~/oosh`, hand
   off to bash (`this` / the state machine) and exit. It has never been sourced by a
   login shell; since 2026-04-28 (`c32a1ff`) it actively refuses to do anything when
   sourced (the auto-run guard, `init/oosh:38-40`).
2. **Before `boot` existed, `boot`'s work was done by three other things** at every
   login: the generated `~/config/user.env` (a persisted `export PATH=…` on `main`;
   generated *logic* on dev from 2026-05), the oosh block in `.bashrc`
   (`source $CONFIG` → `source $OOSH_DIR/log` → the OOSH_LINK auto-sync/PATH block),
   and `this`'s own top-level fallback (OOSH_DIR from `$BASH_SOURCE`, PATH prepend).
   `boot` (2026-09-08, `8b498f4`) collected exactly those pieces into one file so the
   env files could go back to pure data — the boss's own "config has code!" ticket.
3. **Moving `boot` into `init/oosh` is not a separation of concerns, it is the
   opposite.** The two files have different lifetimes (once per host vs once per
   shell), different execution modes (executed with `set -e`/`exec`/`exit` vs
   *sourced*, where `exec` or `exit` would kill the user's shell), and different
   inputs (network, sudo, a repo that may not exist yet vs a config that must). The
   only thing they share is "POSIX sh", which is why the boss's diagram draws them
   next to each other. The one closest precedent — the March-2026 `init/oosh` that
   wrote `export PATH=…` lines into `user.env` — is the very design that produced
   the symlink self-loop and the "config has code" complaint.
4. **What the boss is probably reacting to is real, though:** there are *four*
   files touching the bootstrap (`init/oosh`, `boot`, `this`, `.bashrc`), and
   `boot` does not appear in his mental model at all — his "ossh boot sequence"
   panel is `env -i sh → bash → this → log/debug/config`, in which `this` *is* the
   boot. The honest options are in § 6; the recommendation is to keep the three-way
   split but make `boot` visible where he expects it (the `init/` family), not to
   merge it into the installer.

---

## 1 · `init/oosh`, era by era

| Era | Commits | Lines | Author(s) | Shape |
|---|---|---|---|---|
| **2021-11 — birth** | `e0be4b2` … `c073494` | 202 | Marcel | `#!/bin/sh`. `oosh_check_all_pm` (brew/apt-get/apk/dpkg/pkg/pacman), `oosh_cmd git`, `git clone` → `mv once.sh oosh`, `PATH=~/init:$OOSH_DIR:$PATH:.`, then **start bash on `$OOSH_DIR/this`** (`"$BASH_FILE" "$OOSH_DIR"/this`). Same commit renamed the kernel `init` → `this`. |
| **2022-04 — remote mode** | `77fbcfb`, `5c49fd5`, `3ec9866` | 232 | Marcel | `mode ssh` → `"$BASH_FILE" "$OOSH_DIR"/ossh continue.local.install`; copies `~/oosh/init/*` → `~/init` (so `oosh` is on PATH as a command); `mode user`, `dev mode` follow (`0efb825`, `aec7315`). |
| **2022-06 → 2024-06 — steady** | 7 Matthias, 3 Chris, Marcel | 286 → 334 | Matthias: install from local/feature branch (`4ff42cd`), `~/init` link (`f3ba36d`). **Chris 2024-04-07 `8c277f4`: `#!/usr/bin/env -iS HOME=${HOME} sh`** — the clean-environment shebang. `OOSH_INSTALL_SOURCE` rsync path. This is **`origin/main` today** (334 lines, last touched 2026-03-12): `oosh_start` → PM check → clone/pull → `mode ssh|user` → `this call ossh install.continue.local`, else **`"$BASH_FILE" $SH_OPT "$OOSH_DIR"/this localInstall`**. |
| **2026-02/03 — the fat era** | `45d9e10` … `e66ff29` (≈50 commits) | 461 → **649** | Hannes | Still Marcel's skeleton, plus: `OOSH_BRANCH` propagation, `LOG_INSTALL`/`install_log`, dnf/yum, Alpine (`075b4a3` **drops the `env -iS` shebang** — BusyBox `env` has no `-S`), bash 3→5 upgrade on macOS, brew discovery over ssh, `oosh_setup_env` (**writes `.bashrc` from the template and `user.env`**, `6000b1c`), and `printf 'export PATH=…' >> user.env` for brew bash (`c7846c1`, `8033a6f`). This is the closest `init/oosh` ever came to owning the per-shell environment — by *writing the data file*, not by being sourced. |
| **2026-04-23 — the shrink** | `b8b90b8` | 649 → **115** | Hannes | *"shrink init/oosh to thin bootstrap"*: deletes sh→bash re-exec, bash upgrade, PM detection, shell probing, `oosh_cmd`, `oosh_setup_env`, `oosh_status`. bash 4+ and git become declared prereqs. Adds `Install-oosh.command`. Handoff: `exec $OOSH_DIR/this call ossh install.continue.local`. `mode root` only. |
| **2026-04-24 → 04-30 — grows back** | `7ac375a` … `b427809` | 115 → 266 → **578** | Hannes | sudo re-exec with curl-pipe pre-clone, `user oosh.install $SUDO_USER`, batch prereq error, then `b427809` **restores self-install of platform deps** (Phase A) because a drag-and-drop bootstrap cannot assume git/bash. |
| **2026-05-05/08 — POSIX + minimal** | `0594657`, `014cf5d` | 561 → **493** | Hannes | bash → POSIX sh (`#!/usr/bin/env sh`); boss feedback 2026-05-08 (*"init/oosh should not do much: git+curl, clone, then prereqs via `oo cmd`"*) → rsync/tree/python3 move to the new `ossh prereqs.install` local mode. Q1/Q2/Q3 (bash-4+ install, sudo re-exec, install log) locked KEEP. |
| **2026-09-08 — login hand-off** | `4d41ab7` | 533 | Hannes | `unset OOSH_DIR OOSH_MODE; exec bash -l` after a local interactive install — replaces the `main`-era `this localInstall → $BASH_FILE` start. Same day `boot` is born in a *different* commit (`8b498f4`). |
| **2026-09-10/14 — T4+T5, T3** | `2045811`, `78957c7`, `dc3bbcb`, `7e88ec4`, `18d4dfa` | 537 → **598 → 676** | Hannes | OOSH_DIR exception marker (installer runs before `~/oosh`), **`$HOME` recovery** (duplicated from `boot` on purpose), **`env -i` clean self-re-exec** replacing the shebang lost in `075b4a3`, carried-variable list. |
| **2026-09-21** | `899358e` | 676 | Hannes | `DEBIAN_FRONTEND=noninteractive` for apt. |

Authors over the whole history: Hannes 103, Marcel 52, Matthias 7, Chris 3.

### What is different today vs `origin/main`

| | `origin/main` (334 lines, Marcel's design) | dev today (676 lines) |
|---|---|---|
| Interpreter | `#!/usr/bin/env -iS HOME=${HOME} sh` | `#!/usr/bin/env sh` + in-script `exec env -i PATH=<seeded> HOME OOSH_CLEAN_ENV=1 … sh $0` (`init/oosh:143-171`) |
| Modes | `mode ssh`, `mode user`, `dev` flag, `DEV_MODE`, `OOSH_INSTALL_SOURCE` rsync | `mode root <host> <configRemote|_> <branch> <logLevel>` only; branch via `OOSH_SELF_BRANCH` literal that `promote` rewrites |
| Prereqs | PM check via `oosh_check_all_pm`, `oosh_cmd git rsync` | Phase A: PM detect, Homebrew bootstrap, apt update gate, git, bash 4+ (brew + `/etc/paths.d`); Phase B: prereq `die`s; rsync/tree via `ossh prereqs.install` local mode |
| Clone | `git clone` into `~`, `mv once.sh oosh`, `git pull` if present, copy `init/*` → `~/init` | `git clone -b $OOSH_BRANCH` into `$OOSH_DIR`, `mv` to `~/oosh` + re-exec if elsewhere, no pull, no `~/init` copy (state 31 does `ln -s ~/oosh/init ~/init`) |
| Privilege | `SUDO="sudo -S"` when not `/root`; no re-exec | `exec sudo -H -E sh "$0"` when not root (curl-pipe pre-clones to mktemp) |
| Hand-off | `this localInstall` → `oo state`, `user get home`, then `$BASH_FILE` (interactive bash inside the installer, `this.restart` loop) | `this call ossh prereqs.install`, `this call ossh install.continue.local`, `user oosh.install $SUDO_USER`, `~/.bash_profile`, then `exec bash -l` (fresh login, boot runs) |
| `$HOME` | assumed (kept by the shebang) | recovered via getent → dscl → /etc/passwd when unset/stale |
| Per-shell env | none — `this localInstall` and `user.env`'s persisted `export PATH=` did it | none — `boot` does it at the next login |

The through-line: **the installer has been shrunk and re-grown three times** (Feb–Mar
2026, Apr 2026, Sep 2026) and every time the boss's guidance pushed the same way —
*do less in `init/oosh`, hand off sooner*. Adding `boot`'s duties to it would reverse
that for the first time.

## 2 · Was `boot` ever inside `init/oosh`? — No, and here is where each piece lived

`boot` (`boot:1-155`) does eight things. None of them was ever done by `init/oosh` *for
the login shell*. Where each one lived before 2026-09-08:

| `boot` step today | On `main` (Marcel's design, ≤ 2026-03) | On dev, spring 2026 (before `boot`) | Since 2026-09-08 |
|---|---|---|---|
| 0 · recover `$HOME` | nowhere (the `env -iS HOME=` shebang kept it for the installer only) | nowhere | `boot:28-60`; **duplicated** in `init/oosh:52-87` because the installer runs before `~/oosh` exists |
| 1 · `OOSH_DIR`, `CONFIG_PATH`, `CONFIG` anchors | `this:26-34`: `OOSH_DIR=$(cd $(dirname $BASH_SOURCE); pwd)`, `$USERHOME/init` → `$USERHOME/oosh`; `CONFIG=~/config/user.env` hard-coded in `bashrc_template:9` and `config.init` | `user.env`/`oosh.env` **generated code**: `: ${CONFIG_PATH:="${BASH_SOURCE[0]%/*}"}`, a validity predicate, `: ${OOSH_DIR:="$(cd ~/oosh && pwd -P …)"}` (`8b498f4^:config:584-596, 631`) | `boot:70-78` — constants (`~/oosh`, `~/config`), T4+T5 |
| 2 · `OOSH_USER_CONFIG_PATH` | did not exist (everything in shared `~/config`) | did not exist | `boot:83` (2026-09-09, `56ce683`) |
| 3 · touch-guard `log.session.env` | — | — | `boot:89-90` |
| 4 · source the config | `.bashrc`: `source "$CONFIG"` (`bashrc_template:153-154`) | same, plus config.add's `source $CONFIG_PATH/oosh.env` chain | `boot:98` (`.` not `source`, so dash can run it) |
| 5 · PATH | **persisted**: `config.save` wrote `export PATH="$PATH"` into `user.env` (`main:config:325`); `this` prepended `$OOSH_DIR`; `init/oosh` set `PATH=~/init:$OOSH_DIR:$PATH:.` for its own process | generated **if-block** appended to `oosh.env` (`8b498f4^:config:636-640`) + `.bashrc`'s OOSH_LINK auto-sync + PATH rewrite (`fb7006f^:bashrcTemplate:172-198`) | `boot:106-120`; T8 made `boot` the declared single PATH writer (`path validate`) |
| 6 · source `log`, `log.session.save` | `.bashrc:159`: `source "$OOSH_DIR/log"` (which sources `this`) | same, plus `source $OOSH_DIR/log` *generated into* `oosh.env` | `boot:140-147`, guarded on "bash and not POSIX mode" |
| 7 · exit 0 | — | — | `boot:155` |

Two readings of "boot used to be in init/oosh" are worth checking against this table:

- **The `~/init` link.** From 2022 (`77fbcfb`) to today, an installed host has `~/init`
  → `~/oosh/init`, so `~/init/oosh` is a stable path and `this` special-cases `$0` =
  `oosh`|`init` (`this:1251`). That made `oosh` a *command you could run again* (re-install /
  update / start a shell), never a file you sourced at login. `.bashrc` on `main` never
  references `init/oosh` (`git log -S'init/oosh' -- templates config user` finds only
  2026 commits about `user.oosh.install`).
- **The March-2026 `oosh_setup_env`.** For ~5 weeks (`6000b1c` 2026-03-10 → `b8b90b8`
  2026-04-23) `init/oosh` installed `.bashrc` from the template and appended
  `export BASH_FILE/OOSH_DIR/PATH` lines to `user.env`. That is the installer *seeding the
  data file the login shell reads* — the persisted-PATH model of `main` — and it was
  deleted as "dead-weight bootstrap scaffolding" in the shrink. It is also the model that
  leaks one user's absolute PATH into the shared config (T8 rationale) and that
  `config.save` overwrote on every save (hence `c7846c1`'s "append AFTER Phase 2").

So the installer has twice been made to *write* the per-shell environment, and both times
the design moved away from it: `main` persists PATH (leaky on shared hosts), dev-spring
generated logic (rejected as "config has code"), and now `boot` computes it fresh per shell.

## 3 · How it used to work at login (the `main` picture)

```
login → ~/.bashrc (bashrc_template)
          CONFIG=~/config/user.env
          source "$CONFIG"           ← data: export PATH="<saver's PATH>", BASH_FILE, …
          source setup.color.env
          source "$OOSH_DIR/log"     ← log sources this (info.log missing) → this sources debug
          PS1, c2.install, onExit trap, OOSH_PROMPT
```

`OOSH_DIR` came from `user.env` if it had been saved there, else from `this`'s
`$BASH_SOURCE` fallback. It *worked* on a single-user box and broke in exactly the ways the
2026 tickets list: `oo mode <branch>` re-saving `oosh.env` without the anchor, `sudo su`
shells with no `OOSH_DIR`, a persisted PATH from root landing in every user's shell, and the
`.bashrc` auto-sync that turned `~/oosh` into a self-loop ("Too many levels of symbolic
links", `8b498f4^:config:620-626`). Each fix added logic to the env files until the boss
said stop. `boot` is that stop.

And the installer's part on `main`: `init/oosh` ends by starting **an interactive bash
inside itself** (`this localInstall` → `$BASH_FILE` → `this.restart` loop, `main:this:809-832`).
That is the "this localInstall → starts new bash" step the bootstrap diagram carried
until T6 and which `4d41ab7` replaced with a real `exec bash -l`, so that the first shell
after install boots *exactly* like every later one.

## 4 · The boss's model, and where `boot` sits in it

His `oosh.drawio` has no `boot`. Its "ossh boot sequence" panel is:

```
env -i sh → bash → this
                  → log · debug · config · all other oosh commands
           → this
```

and "OOSH Entry Points" is `init/oosh → git | env -i sh (as root → bash | this) | ssh
<sshConfig> | file | os platform`. In that picture the *boot sequence* is the chain
`init/oosh → bash → this`, and `this` is the thing that boots every command. There is no
per-login step because on `main` the per-login step is data (`user.env`) plus `this`.

Read that way, "remove `boot`, `init/oosh` does it" most plausibly means one of:

- **(a)** *"Bootstrapping belongs to the `init` family, not to a new top-level file."*
  `init/oosh`, `init/once`, `init/deinstall.oosh` are "the things that run before
  `this`". `boot` is exactly such a thing, but it lives at `$OOSH_DIR/boot`.
- **(b)** *"The installer should leave the host in a state where a plain login works
  without a loader"* — i.e. `main`'s model: `.bashrc` sources data, `this` does the rest.
- **(c)** literally *"source `init/oosh` at login"*.

(c) cannot be meant as written: `init/oosh` returns immediately when sourced
(`init/oosh:38-40`, added after a sourced test run "wiped user oosh trees"), and if the
guard were removed a sourced run would `set -e`, `exec sudo`, `exec env -i` and `exit` in
the user's shell. Making it sourceable would mean putting a "sourced mode" *before* the
guard — which is `boot` pasted into the top of `init/oosh`, sharing nothing with the rest
of the file. That is two programs in one file, not one concern.

## 5 · Is the current split a separation of concerns? — Yes, and here is the test

Three concerns, three lifetimes, three execution contracts:

| | `init/oosh` | `boot` | `this` |
|---|---|---|---|
| Runs | **once per host** | **once per shell** | **once per command** |
| How | executed; `set -e`, four `exec`s, `exit $rc` | **sourced**; must `return`, never `exec`/`exit` (T51), must never kill the caller (T70) | sourced by every oosh file, or executed |
| Language | POSIX sh (dash/ash/bash 3.2 must run it) | POSIX sh (dash callers: `ossh exec`, `env -i sh`, mid-install login shells) | bash 4+ (dotted names — **cannot parse under sh**, measured in the 2026-09-14 spec) |
| Inputs | network, sudo, a repo that may not exist | `~/config/*.env` that must exist | a booted environment |
| Idempotent? | no — it is a state change | yes (one stated PATH qualification) | yes |
| Size | 676 | 155 | 1389 |
| Callers | curl one-liner, `ossh install`, `Install oosh.command` | `.bashrc`, `ossh exec`/`exec.tty`, `os platform.test` runners, `odocker`, CI, `/etc/profile.d/oosh.sh`, `oo boot.fix` — 53 call sites in code, 13 test cases | everything |

Merging **`boot` into `init/oosh`** violates the second row (a sourced file that
contains `exec` and `exit`) and the fourth (a per-shell prologue that depends on nothing
would gain a dependency on installer code). Merging **`boot` into `this`** violates the
third row — `dash -n this` fails on line 66 and a `[ -n "$BASH_VERSION" ]` guard does not
help because sh dies on the *definition*. The 2026-09-14 spec measured both
(`docs/superpowers/specs/2026-09-14-clean-environment-guarantee-design.md § Why boot and
this are two files`). So the split is not tradition; it is forced by "must run under sh"
on one side and "must not exec/exit" on the other.

What is **not** clean, and where the boss's instinct has a target:

1. **`this` still carries anchor fallbacks** — `OOSH_DIR="$HOME/oosh"; PATH=…` when unset
   (`this:46-49`) and the `this.path.add` case block (`this:1251-1279`). They are declared
   exceptions (T4/T5, T8), but they are a second place that *can* set what `boot` owns.
2. **`$HOME` recovery is duplicated** in `boot` and `init/oosh` (spec: "duplication is
   inherent" — neither may source a helper). True, but it is 33 identical lines in two
   files with a `BEGIN/END homeRecovery` marker and no test that they stay identical.
3. **`boot` is invisible in the architecture the boss draws.** It is not an OOSH
   method-script, it has no `noun.verb`, and it is not in `init/`. From his diagram's
   point of view it is an undeclared fourth actor.
4. **`.bashrc` still has bootstrap logic of its own** after `boot` returns: the
   `[boot absent]` PATH fallback, `line init`, the sudo-cwd guard, the c2.install source,
   the `onExit`/`reconfigure` pair, `.once`, `OOSH_PROMPT` (`bashrcTemplate:163-279`).

## 6 · Options, with a recommendation

| | Option | What it buys | What it costs | Verdict |
|---|---|---|---|---|
| A | **Fold `boot` into `init/oosh`** (a sourced prologue above the auto-run guard) | one file fewer; matches a literal reading of the boss | a 700-line installer sourced by every shell; `exec`/`exit`/`set -e` one guard away from the user's shell; `/etc/oosh/boot` (T9) and `~/init/oosh` would point at the installer; `path validate`'s exemption of `init/oosh` would have to be un-done; T3's sourced-safety tests re-done against the installer | **No.** Reverses three shrink cycles and re-mixes the two contracts that were separated on purpose. |
| B | **Fold `boot` into `this`** | one file fewer; `this` is already "the kernel" in his picture | impossible under sh (measured); gives up T3 (`env -i sh`), `ossh exec` to non-oosh users, mid-install dash shells | **No.** |
| C | **Go back to `main`'s model** — installer/`config.save` persist `export OOSH_DIR="$HOME/oosh"`, `CONFIG_PATH="$HOME/config"`, `PATH="$HOME/oosh:$HOME/oosh/ng:$PATH"` as *data* in `user.env`; `.bashrc` sources it; no loader | no `boot`; pure data (with the T4/T5 constants the anchors *are* portable data now, unlike main's absolute PATH) | PATH grows on every re-source (no idempotency without logic); no `$HOME` recovery (T3 fails again); the "bash and not POSIX" guard for `log` has to live in `.bashrc`; `env -i sh` needs `HOME` from somewhere; `ossh exec` fallback logic returns to every caller; `log.session.env`/per-user tier has nowhere to be created | **No**, but worth naming — it is what the boss's picture *is*, and it explains why he does not see a need for `boot`. |
| D | **Keep the split; make `boot` a citizen of the `init` family** — move it to `init/boot` (with `$OOSH_DIR/boot` kept as a symlink for the 53 callers during transition, or repoint them), document it as "the sourced half of init", add it to his diagram as `init/oosh → bash → this` **plus** `login → init/boot → this` | separation stays; the file lands where his tree puts pre-`this` things; `~/init/boot` and `/etc/oosh/boot` read naturally | a rename touching 53 sites and 13 tests; T9's `/etc/oosh/boot` symlink target changes | **Recommended if the boss's objection is "where is it / one more thing".** |
| E | **Keep everything as is; fix the four leftovers in § 5** — remove `this`'s anchor fallback (or make it an assertion), pin the `homeRecovery` duplicate with a test, move the residual `.bashrc` logic into `boot` or a `boot`-owned hook, and put `boot` on the boss's diagram | smallest change; addresses the *substance* of "too many places" | `boot` stays a top-level non-method file | **Recommended in any case**, independently of D. |

**Recommendation:** E now, D if the boss confirms his objection is about placement. Not
A, B or C. Before any of it, ask him the two questions below — the history shows
`init/oosh` has swung between 115 and 676 lines on guidance that was never written
down verbatim, and this decision deserves a written ruling like Ideas #4 got.

**Questions for the boss**

1. When you say `init/oosh` should take over `boot`'s tasks — do you mean the login
   shell should *source the installer*, or that the installer should *leave the host
   needing no loader* (the `main` model), or that `boot` should *live under `init/`*?
2. Your diagram's "ossh boot sequence" has `env -i sh → bash → this`. Where in it does
   the per-login step happen for a plain `ssh user@host` — `this` (which cannot run under
   dash), `.bashrc` logic, or a data file? That answer decides A/C/D.

## 7 · Evidence index

- History: `git log --follow --reverse -- init/oosh`; sizes per commit in § 1. Key diffs:
  `77fbcfb` (mode ssh, `~/init`), `8c277f4` (env -iS), `075b4a3` (drop -S), `6000b1c` /
  `c7846c1` (installer writes `.bashrc` + PATH into `user.env`), `b8b90b8` (shrink to 115),
  `b427809` (self-install back), `0594657` (POSIX), `014cf5d` (minimal, boss 2026-05-08),
  `4d41ab7` (exec bash -l), `8b498f4` (boot), `fb7006f` (every caller repointed to boot),
  `10670c0` (boot owns the anchors; nothing per-user persisted), `2045811`/`518e179`
  (constants), `80b6257`/`78957c7` (HOME recovery ×2), `dc3bbcb` (clean re-exec).
- `main` today: `origin/main:init/oosh` (334), `origin/main:this:26-34`,
  `origin/main:templates/user/bashrc_template:153-159`, `origin/main:config:325`.
- Pre-boot generated logic: `git show 8b498f4^:config | sed -n '553,640p'`.
- Design record: `docs/superpowers/specs/2026-09-14-clean-environment-guarantee-design.md`
  (§ Why boot and this are two files, § Division of labour), `docs/boot.md`,
  `docs/install-bootstrap.md`, `docs/plans/2026-09-10-oosh-boot-tickets.md` (T3 forensics
  table, Ideas #3/#4/#5/#7/#8), `docs/plans/2026-09-14-fixed-system-boot-path.md` (T9).
- Boss guidance on record: 2026-05-08 (memory `project_init_oosh_minimal_refactor`:
  *"init/oosh should not do much"*), Ideas #4 (*OOSH_DIR is always ~/oosh*), Ideas #7
  (*config has to bootstrap always all variables*), "config has code!".

## 8 · Hand-off

For whoever acts on this after the boss answers:

1. If **E**: (i) `this:46-49` — replace the silent fallback with `this.anchor.validate`
   or leave it and add a test that it never fires in an installed shell; (ii) a test that
   `boot` and `init/oosh` `homeRecovery` blocks are byte-identical between the markers;
   (iii) list what `bashrcTemplate:163-279` still does after `boot` and decide what moves;
   (iv) add `boot` to the boss's drawio and to v2 group 3 (already there) — the v2 review
   doc has the label text.
2. If **D**: rename with `git mv boot init/boot`; repoint the 53 call sites (list:
   `grep -rln 'oosh/boot\|\$OOSH_DIR/boot' --exclude-dir=.git .`); keep `$OOSH_DIR/boot`
   as a symlink for one release; update `oo.boot.fix` / `private.oo.boot.path.ensure`
   (`oo:333, 1910`) and state 34; T9 doc. Run `test.suite core 1`, then `os platform.test
   ubuntu_24_04` — this is an install-path change, so all five platforms before promotion.
3. If the boss insists on **A**: write the ruling down first (like Ideas #4), then plan
   it as a *split file*: a sourced prologue above the auto-run guard that is byte-for-byte
   today's `boot`, with `path validate`, T3/T51/T70 and the 13 boot tests re-targeted.
   Expect the same objections to resurface at the next shrink.

## 9 · If the boss insists: the boot-less design that actually works everywhere

Added 2026-09-22 on the user's request ("how can we get rid of boot, but it has to work
over the whole framework, all platforms"). This is the one shape that removes the file
without breaking dash/ash/POSIX-bash callers, shared multi-user configs, or the env files
being pure data. It is `main`'s model made portable by the T4/T5 constants, and it is
what the boss's Ideas #7 card literally says: *"config has to bootstrap always all
variables required for a branch version."*

**The idea in one sentence:** `user.env` becomes the boot. Because `OOSH_DIR` is always
`~/oosh` and `CONFIG_PATH` is always `~/config` (his ruling, Ideas #4), the anchors and
the PATH prepend are *portable data lines*, not logic — they expand `$HOME` at source
time, so one shared `user.env` is right for every user on the host:

```sh
export OOSH_DIR="$HOME/oosh"
export CONFIG_PATH="$HOME/config"
export CONFIG_FILE="user.env"
export CONFIG="$CONFIG_PATH/user.env"
export OOSH_USER_CONFIG_PATH="$HOME/.config/oosh"
export PATH="$HOME/oosh:$HOME/oosh/ng:$PATH"
export PATH="/opt/homebrew/bin:$PATH"        # macOS only, written by config.save from BASH_FILE
. "$CONFIG_PATH/oosh.env"
. "$CONFIG_PATH/log.env"
```

`config.validate` already accepts every line above (it rejects `$(`/backticks and logic,
not `$HOME`). Every caller then does what it did before 2026-09-08: `[ -f
"$HOME/config/user.env" ] && . "$HOME/config/user.env"`.

**Where each of `boot`'s eight duties goes**

| `boot` today | Boot-less home | Why it still works on every platform |
|---|---|---|
| 0 · recover `$HOME` | **a rule, not code**: every `env -i` in the framework passes `HOME` (`env -i HOME="$HOME" sh …`) — the original 2024 shebang rule. `init/oosh` keeps its own copy (it must). Only `user:1364 env -i su -` exists in-tree today, and `su -` sets HOME itself. | `$HOME` is the one thing you cannot derive without logic; passing it is what Chris's shebang did for two years. Loss: a shell with *no* HOME at all does not self-heal — `HOME=/home/you sh` is the documented fallback. |
| 1 · anchors | `config.save` writes the six lines as the head of `user.env` (they join the required-variables carry-forward table, `config:488/918`); **`init/oosh` seeds the same lines once, right after the clone, so the first login works before state 31 ever runs `config save`.** This is the sense in which "init/oosh takes over". | Pure `export` data; dash, ash, bash 3.2 in POSIX mode all read it. |
| 2 · `OOSH_USER_CONFIG_PATH` | same data line | same |
| 3 · touch-guard `log.session.env` | **move the per-user chain out of the shared data file**: `log.env` no longer ends with `. $OOSH_USER_CONFIG_PATH/log.session.env`; `log` (bash) creates and sources it when it loads. | The guard existed only because dash aborts on `.` of a missing file. If the data chain never names a per-user file, nothing can be missing. |
| 4 · source the config | the caller's one line (`.bashrc`, `ossh exec`, `os platform.test` runners, `odocker`, CI, `ng/c2`, `ng/2c`) | that is exactly what `fb7006f` replaced; the lines are still there in the fallback branches |
| 5 · PATH | data line (above). **Idempotency moves into `this`**: on load it de-duplicates PATH (bash, two lines). | Re-sourcing `user.env` in a shell that never runs `this` grows PATH by one segment — cosmetic, and today's `$BASH_FILE` block already does that. |
| 6 · source `log`, `log.session.save` | `.bashrc` (it is bash by definition) and `this` (already sources `log` via `debug`). `log.start` calls `log.session.save` on first load. | Non-bash callers never had log functions from `boot` either — the guard skipped them. |
| 7 · exit 0 | — | a data file has no status to get wrong |
| T9 `/etc/oosh/boot` + `/etc/profile.d/oosh.sh` | drop-in stays and sources `$HOME/config/user.env`; the `/etc/oosh/boot` symlink, `oo boot.fix`, `oo boot.status` go; state 34 shrinks to "write the drop-in". | The symlink existed so a HOME-less shell could reach `boot` by absolute path; with the HOME rule it has no job. |

**The steps, in order** (each one leaves the tree green; do them as one ticket, one
commit per step):

1. `config`: add the six anchor lines to the required-variables table; `config.save`
   emits them first; `config.validate` T-cases for them; `config init.user` writes the
   caller line into `.bashrc` as `. "$HOME/config/user.env"`.
2. `log`: own `log.session.env` (create if missing, source on load); remove the chain
   line from `log.env`'s writer (`config:977`).
3. `this`: PATH de-dup on load; keep `this.anchor.validate` as the assertion that the
   data lines were sourced (fail loud, do not silently re-anchor).
4. `init/oosh`: after the clone, `mkdir -p ~/config` and write the six lines if
   `user.env` is missing — data only, before `this call ossh install.continue.local`.
5. Repoint the 53 `boot` call sites to `user.env` (list: `grep -rln 'oosh/boot' …`);
   `.bashrc` additionally sources `log` + `log.session.save` after it.
6. T9: `/etc/profile.d/oosh.sh` → `user.env`; delete `oo boot.*`, state 34 becomes the
   drop-in only; `path validate`'s rule becomes "PATH is written in `user.env` by
   `config.save`, de-duplicated by `this`" (`init/oosh` stays the file-wide exception).
7. Delete `boot`; retarget its 13 tests (T31 → the data lines; T40 → lint `user.env`
   under dash/ash/`bash --posix`; T74 → `this` de-dup; T49–52 → trivially true for a
   data file, keep one as a regression guard against logic creeping back; T65–68 → the
   HOME rule; T70 → gone with the guard). `docs/boot.md` folds into `config.md`.
8. Verify: `test.suite core 1`, then all five platforms (`os platform.test …`) — this is
   an install-path change — plus a hand-run of `env -i HOME=$HOME sh -c '. ~/config/user.env; oo version'`
   on ubuntu, alpine and macOS.

**What you give up, honestly**

- Self-healing from a shell with **no `HOME`** (today's `boot` step 0). Replaced by a rule.
- PATH idempotency in shells that source `user.env` but never run `this` (cosmetic).
- One unit-testable file. The contract spreads over `config.save` (writer), `this`
  (bash side) and `.bashrc` (caller). That is the same amount of logic as `boot` has,
  living in files that already exist — which is the boss's point, and the spec's
  counter-argument ("two files because sh cannot parse `this`") no longer applies,
  because the sh-side is *data*, not a file with functions.

**What you must not do**

- Do not put the lines into `oosh.env` — `oo mode` re-saves it and the anchors vanish
  (that is the 2026-05 bug, `4a2b5d1`).
- Do not persist an absolute PATH or absolute `OOSH_DIR` — shared `~/config` would leak
  one user's paths into the others (T8). `$HOME`-relative is the whole trick.
- Do not make `init/oosh` sourceable. It seeds the file; it never becomes the file.
