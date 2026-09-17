# The shared-tier leak on macOS — research: why a test rewrote a real machine's `log.env`

**Written 2026-09-17 · Branch `dev` (`df6d57b`) · Status: RESEARCH — no code changed. Decisions in § 7.**
**Found by:** the first full `test.suite core 1` on a clean macOS install (Tart VM, Sequoia 15.7.3).

```
Shared tier: 2 file(s) rewrote /Users/admin/config: test.completion.audit test.user
✗ SHARED CONFIG WRITTEN: test.completion.audit wrote the shared config tier: log.env
  the tier has been restored from this run's snapshot
```

`test/test.completion.audit:18` **does** call `test.suite.config.isolate`, before it sources
anything. It is correctly isolated. Something escaped anyway — and only on macOS: the same file is
canary-silent on this Linux host and in the ubuntu container.

---

## 1. What was written

The canary restores the tier, which hides the evidence. Running the file directly (bypassing the
runner) leaves it in place:

```
BEFORE (62 bytes)                          AFTER (89 bytes)
export LOG_LEVEL="3"                       export LOG_LEVEL="1"
                                           export LOG_LEVEL_RESET="3"
. $OOSH_USER_CONFIG_PATH/log.session.env   . $OOSH_USER_CONFIG_PATH/log.session.env
```

`LOG_LEVEL_RESET` is written by nothing but `log.level` (`log:382-385`), so the shell that wrote
this had run `log.level 1` — and then something persisted the whole `LOG_*` family.

**A correction to my first attempt.** I diffed `log.env` around a run and saw `IDENTICAL`, and said
so. That was wrong: the canary had already restored the file from its snapshot before the `diff`
ran. The guard was working; my measurement was taken after its cleanup.

## 2. The chain, measured

Probes inserted at all three `this.call config save log LOG` sites in `log`, plus one in the audit:

```
AUDIT-PARENT cfg=/var/folders/…/T//test.completion.audit.config.u6FQ5P  exported=2
PROBE site=586 cfg=[/Users/admin/config] pid=39682 ppid=39581
      parent=bash /Users/admin/oosh/oo pm.discover
      gparent=bash ./test/test.completion.audit 1
      fn=log.device config.save this.call this.start config.start main
```

So:

```
./test/test.completion.audit 1         CONFIG_PATH = the fixture, exported   ✓ isolated
  └─ oo pm.discover                    spawned by the audit
       └─ config …                     CONFIG_PATH EMPTY → config.init defaults it to ~/config
            └─ config.save (no args)
                 └─ log.device "$LOG_DEVICE"        config:740-742, the "### HACK" block
                      └─ config save log LOG        log:586, UNGUARDED
                           └─ writes $CONFIG_PATH/log.env   ← the shared tier
```

Neither of the two guarded sites fired. `log.level`'s save (`log:399`) is behind
`this.isSourced` and was never reached — the probe there recorded nothing.

**`config.save` re-enters itself.** `config:740` calls `log.device $LOG_DEVICE`; `log.device`
(`log:582-590`) unconditionally calls `this.call config save log LOG`. The HACK's own comment
admits it: *"should be in log.init only. but is needed for ssh remote logging"*. It only fires when
`$LOG_DEVICE` is non-empty, which is why this reproduces under `ossh exec` (a tty) and not under a
plain non-interactive `ssh` — my first two reproduction attempts failed for exactly that reason.

**This cascade is already written down.** `user:1685-1698` describes it verbatim — *"the full
cascade from oo.pm.discover's internal `config save` (no args) → config:601's `log.device
$LOG_DEVICE` HACK → recursive `this.call config save log LOG`"* — and works around it by swapping
`LOG_DEVICE=/dev/null` for the duration. What is new is that it reaches the **shared tier** from an
isolated test.

## 3. Why `oo pm.discover` runs at all — the macOS root cause

`private.user.init` caches the platform's user/group commands in `os.commands.env` and self-heals a
missing one. On this clean macOS install the cache is **half empty**:

```
macOS                                       Linux
export OS_CMD_GROUP_ADD=""     ← empty      export OS_CMD_GROUP_ADD="groupadd -f"
export OS_CMD_USER_ADD=""      ← empty      export OS_CMD_USER_ADD="useradd -g dev"
export OS_CMD_USER_DEL="sysadminctl -deleteUser"
export OS_CMD_USER_MOD="dseditgroup -o edit -a"
```

### CORRECTION (2026-09-17, later the same day)

**The paragraph that stood here was wrong, and is kept below the fix so the mistake is legible.**

I wrote that `private.user.init`'s heal "looks for the wrong tools — macOS has neither `addgroup`
nor `groupadd`". That code (`user:1666-1675`) is in the **`else` branch**. It never runs on darwin.
`private.user.init` has a correct darwin branch (`user:1632-1637`) that sets all four, including
`OS_CMD_GROUP_ADD="dseditgroup -o create -q"`.

**The real writer of the empty strings is `private.check.pm`** (`oo:3055`):

```bash
export OS_CMD_GROUP_ADD=$3     # unconditional
export OS_CMD_USER_ADD=$4      # unconditional
…
config save os.commands "OS_CMD"
```

and the call table (`oo:3093-3101`) gives the whole game away in one column:

```
private.check.pm brew    "brew install"                                    ← no $3, no $4
private.check.pm apt-get "apt-get -y install" "groupadd -f" "useradd -g dev"
private.check.pm dnf     "dnf -y install"     "groupadd -f" "useradd -g dev"
private.check.pm yum     "yum -y install"     "groupadd -f" "useradd -g dev"
private.check.pm apk     "apk add"            "addgroup"    "adduser -g dev"
private.check.pm dpkg    "dpkg install"                                    ← no $3, no $4
private.check.pm pkg     "pkg install"                                     ← no $3, no $4
private.check.pm pacman  "pacman -S"                                       ← no $3, no $4
```

**Every Linux package manager passes the pair. `brew` — the macOS one — passes neither**, so both
are exported as the empty string and then persisted. That is where
`export OS_CMD_GROUP_ADD=""` in a clean Sequoia install comes from.

**Fixed** (`oo`, 2026-09-17): `check.pm` now writes only what it was given. Not by adding darwin's
commands at the call site — `private.user.init` already knows them, and a second copy would be the
same knowledge in two places — but by leaving them **unset**, which is what lets the existing heal
run. `T-CHECK-PM-NO-CLOBBER` in `test/test.oo` pins it, watched failing with
`check.pm overwrote the pair with [|]`.

**Still not pinned:** the heal *should* have repaired the file on a later run and did not. There is
an ordering question between `private.check.pm`'s save and `private.user.init`'s persist that this
research did not answer. The fix removes the bad write at its source, so the question is no longer
load-bearing — but it is not answered.

<details><summary>The original, incorrect paragraph</summary>

and the heal cannot fill them, because it looks for the wrong tools (`user:1666-1675`):

```bash
if [ -z "$OS_CMD_GROUP_ADD" ]; then
  if [ -x "$(command -v addgroup …)" ]; then export OS_CMD_GROUP_ADD="addgroup"; fi
  _groupadd=$(command -v groupadd … || echo /usr/sbin/groupadd)
  if [ -x "$_groupadd" ]; then export OS_CMD_GROUP_ADD="$_groupadd"; fi
fi
```

**macOS has neither `addgroup` nor `groupadd`** — it has `dseditgroup`, which the *same file*
already knows about for `OS_CMD_USER_MOD`. So the variable stays empty, the cache is never healthy,
and the persist branch — `config save os.commands OS_CMD` followed by `oo pm.discover` — runs on
**every** invocation, on every macOS host, forever.

</details>

## 4. Three symptoms, one cause

This single gap explains three things logged separately today:

1. **The shared-tier leak** — § 2, via the unconditional `oo pm.discover`.
2. **`core` failure "ooshTestC should exist with no password hash"** — `user.create` on macOS with
   `OS_CMD_USER_ADD` empty.
3. **`private.this.group.create` has no macOS route** (found by the T6 macOS gate this morning:
   `groupadd` / `addgroup` / append to `/etc/group`, none valid on darwin, and the append returns 0
   while achieving nothing). Same missing knowledge, in a second place.

`private.user.init` already contains the answer for darwin — `dseditgroup -o create -q` is what
sets `OS_CMD_GROUP_ADD` on the install path — so the fix is to make the *heal* as clever as the
*install*, in one place both can use.

## 5. Why isolation did not hold

`test.suite.config.isolate` exports `CONFIG_PATH`, and the audit had it (`exported=2` above). The
grandchild `config` process had it **empty** — `config.init` defaulted it to `~/config`, which is
only reachable when the variable is unset or empty (`config:186`, `: ${CONFIG_PATH:=~/config}`).

So something between `oo pm.discover` and the `config` it spawns clears or fails to pass the
anchor. **That link is not yet pinned** — it is the one open question, and it matters beyond this
ticket: any isolated test that reaches `oo` can write a real machine's config the same way.

## 6. Blast radius

- **Not a test-only bug.** The same cascade runs during a real install and on every login shell
  that sources `user` on macOS, writing `~/config/log.env` each time.
- **~~Linux is unaffected~~ — WRONG, corrected 2026-09-17 evening. See § 13.** What this bullet
  said was: *"the heal succeeds there, so the cache goes healthy and `oo pm.discover` stops being
  called. Verified — this host's `core` has been canary-silent all day and
  `os platform.test ubuntu_24_04` reports `test=0 root=0 oosh-user=0 bash-user=0`."* Both
  observations were true and the conclusion drawn from them was not: every Linux run quoted there
  was either a long-established config or a context with no controlling terminal. A **fresh Linux
  install, first `core`, under a pty** has **seven** files rewriting the shared tier.
- The canary **did its job**: it caught the write, named the file, and restored the tier from its
  snapshot. Without it this would still be invisible.

## 7. Open questions — for the ticket, not for this doc

1. **Where does `OS_CMD_GROUP_ADD` / `OS_CMD_USER_ADD` get their darwin values?** The install path
   knows (`dseditgroup -o create -q`); the heal does not. One accessor both call, or the heal
   learns darwin? This is the fix that removes the cause.
2. **Should `log.device` persist at all when called from `config.save`?** The HACK comment says it
   does not belong there. Removing it breaks "ssh remote logging" per that comment — what exactly?
   The alternative is guarding `log.device`'s save the way `log.level`'s is guarded.
3. **Why does the anchor not survive into `oo pm.discover`'s child?** (§ 5.) Until this is answered,
   `test.suite.config.isolate` is weaker than it looks.
4. **Should `private.user.init` stop persisting on a cache miss it cannot fill?** A heal that cannot
   succeed should not rewrite config on every call.
5. Does the same leak explain **`test.user`**, the second file the canary named? Not yet checked —
   `test.user` sources `user` directly, so it is the same cascade by a shorter route, but that is a
   hypothesis, not a measurement.

## 8. What is NOT in scope

The other eleven macOS `core` failures. Six or more are one cause — macOS `/tmp` and `/var/folders`
are symlinks, so a canonicalised path gains a `/private` prefix and string comparisons fail — and
one is `$TMPDIR` carrying a trailing slash, producing `//` in a built path. Their own ticket.

## 9. Hand-off

`dev` at `df6d57b`, clean, in sync with `origin/dev`. No code changed by this research.
The Tart VM (`192.168.64.5`, user `admin`) is installed and restored to a clean state; the probes
used in § 2 were removed.

---

## 10. Verified on the VM (2026-09-17)

`823d50a` — `private.check.pm` writes only the OS_CMD values it was given.

**The cache heals, on macOS, measured:**

```
BEFORE                        AFTER
OS_CMD_GROUP_ADD=""           OS_CMD_GROUP_ADD="dseditgroup -o create -q"
OS_CMD_USER_ADD=""            OS_CMD_USER_ADD="sysadminctl -addUser"
OS_CMD_USER_DEL="sysadminctl -deleteUser"     (unchanged)
OS_CMD_USER_MOD="dseditgroup -o edit -a"      (unchanged)
```

**The leak is gone.** `test.suite run completion.audit 1` on the VM:

```
✓ PASS: shared config tier untouched (/Users/admin/config)
2 / 2 assertions passed
```

**Full `core` on the clean macOS install:**

| | before | after |
|---|---|---|
| assertions | 842 | 848 |
| failed | 12 | **11** |
| shared tier | **2 files rewrote /Users/admin/config** | *(no such line — canary silent)* |

So the cause identified in § 3 is removed and the leak it produced is closed.

### What this did NOT fix, stated plainly

`user.create ooshTestC password '' leaves account locked` still fails
(`ooshTestC should exist with no password hash`), while the test above it —
`user.create ooshTestB defaults password to username` — passes. Having the right *command* is not
the same as asserting the right *evidence*: macOS keeps credentials in OpenDirectory, not in a
shadow file, so "no password hash" is not a question `/etc/shadow` can answer there. That is a
narrower, separate defect in the assertion or in `user.password`'s darwin route.

### Open question § 7.3 is still open

`CONFIG_PATH` was exported by the audit and **empty** in the `config` process two levels down. The
fix removes the *reason* that path was taken, not the *possibility*: any isolated test that reaches
a subprocess losing the anchor can still write a real machine's config. Its own card.

### The remaining 11 macOS failures

One is the intentional meta-test. Eight are one cause — macOS `/tmp` and `/var/folders` are
symlinks, so a canonicalised path gains a `/private` prefix and a string comparison fails. One is
`$TMPDIR` carrying a trailing slash, producing `//` in a built path. One is the `ooshTestC` case
above. **None is in this ticket.**

---

## 11. The macOS portability pass (2026-09-17) — 12 failures to 2

`493c25c` (canonicalised fixtures) and `48f8b05` (portable grep), on top of `823d50a`.

| | at the start | now |
|---|---|---|
| macOS `core` failures | 12 | **2** |
| of which intentional | 1 | 1 |
| **real** failures | **11** | **1** |
| shared tier written | 2 files | **none** |
| ubuntu gate | `test=0 root=0 oosh-user=0 bash-user=0` | **unchanged** |
| host `core` | 838/839 | **unchanged** |

Two causes, eleven assertions:

- **Eight** — macOS `/tmp` is a symlink to `/private/tmp`, and `$TMPDIR` lives under
  `/var/folders`, reached the same way. A fixture path handed to code that RESOLVES it comes back
  with the `/private` prefix, so a comparison against the raw `mktemp` path can never match.
  `test.suite.fixture.make` canonicalises at creation. **`$TMPDIR` also ends in a slash on macOS**,
  so `"${TMPDIR}/x"` yields `…//x`; canonicalising collapses that too — one fix, two symptoms.
- **One** — `grep -c -- '-one$\|-two$'`. **`\|` alternation is a GNU extension**; BSD grep does not
  support it, so the count was 0 and the test reported `user.ssh.backup.list` broken **while the
  tool was working perfectly**. The worst kind of failure: it sends you to debug working code.

**Regression safety, which is the reason for the shape of this fix.** Canonicalisation is a
**no-op on Linux** (`/tmp` is a real directory) — measured before converting anything — so a
converted fixture cannot behave differently here, and host `core` is byte-for-byte the same score.
Only the **seven sites that actually failed** were converted, not all 85 `mktemp -d` sites in
`test/`: a sweep of that size is churn with its own regression risk and no measured benefit.

### The one real failure left

`user.create ooshTestC password '' leaves account locked`. Not a path or a regex — genuine macOS
account semantics: `sysadminctl -addUser` does not produce the shadow-less account `useradd`
does, and the test's cleanup calls `user.delete.linux` unconditionally (a name that is not a
defined public method — `private.user.delete.linux` is). Sibling of the
`private.this.group.create has no macOS route` card. **Its own ticket.**

### Cards filed by this pass

| Card | Why |
|---|---|
| **macOS account creation** | `user.create <u> password ""` does not leave a locked account on darwin; the test also calls `user.delete.linux`, which no public method defines. Same family as `private.this.group.create`. |
| **`test/test.hiveMind` uses GNU-only `\|` BREs** | `:1211, :1222, :2163, :2171, :2185`. `TEST_CATEGORY=extended`, already has known failures, so not bundled — but it will never pass on macOS as written. |
| **78 un-canonicalised fixture sites** | `test/` has 85 `mktemp -d` calls; seven now use `test.suite.fixture.make`. The rest are latent macOS failures, each waiting for someone to compare a resolved path. |
| **`test.suite` cannot be extended by the tool** | It carries no `### new.method` marker, and `oo method.new` cannot parse a dotted script name — `${name%%.*}` on `test.suite.fixture.make` yields `test`. So `test.suite.fixture.make` had to be hand-written. |

---

## 12. macOS `core` is green (2026-09-17)

`f53efa1` — `password ""` leaves a locked account on darwin.

```
  Test Files:  29
  Test Cases:  748
  Assertions:  848
  Passed:      847
  Failed:      1 (intentional meta-test)

  ✓ ALL TESTS PASSED
```

**Zero real failures on a clean macOS install**, from twelve this morning, and the shared-tier
canary silent throughout. Linux is unchanged at every step: host `core` 838/839 before and after,
ubuntu gate `test=0 root=0 oosh-user=0 bash-user=0`.

The last one was the only defect of the four that was a **security** difference rather than a
portability one: `password ""` on macOS produced an account that authenticates with an empty
password, where Linux produces one that cannot authenticate at all.

| # | Defect | Class | Fix |
|---|---|---|---|
| 1 | `check.pm` persisted two empty `OS_CMD_*` values | install | write only what was given |
| 2 | fixture paths resolved through `/private`; `$TMPDIR` has a trailing slash | test | `test.suite.fixture.make` canonicalises |
| 3 | `\|` alternation in a BRE is GNU-only | test | POSIX ERE |
| 4 | `password ""` gave an empty-password account, not a locked one | **security** | delete `AuthenticationAuthority` |

Each was measured on the VM before being fixed, and each fix is confined to a branch Linux never
reaches or to a path nothing in production takes — which is why the Linux numbers never moved.

---

## 13. The leak is on Linux too — the "unaffected" claim in § 6 was wrong

**Found 2026-09-17 evening**, while chasing an unrelated question: the user installed oosh into a
naked Ubuntu 24.04 container using the README's `wget` one-liner, as root, and ran `core`. It
scored 840/843 with **3** failures where every Linux run that day had scored 2.

Chasing the third failure produced a **controlled pair**. Two fresh containers from the same image,
both installed the same way from `dev`, both running their **first** `core` — differing in one
thing only, whether a pty was allocated:

| | `docker exec` (no pty) | `docker exec -t` (pty) |
|---|---|---|
| test cases / assertions | 744 / 843 | 744 / 843 |
| failed | **2** | **5** |
| shared tier | *(no such line)* | **7 file(s) rewrote /root/config** |

```
Shared tier: 7 file(s) rewrote /root/config:
  test.check test.debug test.log test.oo test.promote test.state test.user
```

Same image, same install, same first run, one variable. **The pty is what makes the difference**,
and it makes it on Linux.

### Why every earlier Linux observation missed it

Both of the runs quoted in § 6 were structurally incapable of showing it:

- **This host's `core`** runs in a tmux pane — which *does* have a tty — but against a
  **long-established** `~/config`. The canary compares CONTENT. On a config whose `log.env` already
  holds what the cascade would write, the write happens and changes nothing, so the canary is
  silent. Silence there means "no CHANGE", not "no write".
- **`os platform.test`** runs `core` through `ossh exec`, and the four passes after the first are
  no longer first runs.

So "canary-silent" was never evidence of "does not write". That is the error in § 6, and it is an
error of inference, not of measurement.

### What is NOT yet established

The macOS root cause — `private.check.pm` persisting empty `OS_CMD_*`, § 3 — **cannot** be the
Linux trigger: every Linux package manager passes those arguments, the cache is complete there, and
the container installed from `dev` **with** `823d50a` already in it and leaked anyway.

Five of the seven named files (`test.check`, `test.debug`, `test.promote`, `test.state`,
`test.user`) do not call `test.suite.config.isolate` at all, so any config write they make lands on
the shared tier by construction. Two of them (`test.log`, `test.oo`) **do** isolate and wrote
anyway — which is the same "isolation did not hold" question as § 5, and still unanswered.

**The hypothesis to test, not a conclusion:** `config.save`'s `log.device "$LOG_DEVICE"` HACK
(`config:740`) writes only when `$LOG_DEVICE` is non-empty, and a pty is what makes it non-empty.
That fits every observation above and the macOS chain in § 2, but it has not been probed on Linux
the way § 2 was probed on macOS. **Do that before changing anything.**

### One more failure the pty run surfaced

`T74: re-sourcing boot never grows PATH` → `$OOSH_DIR appears 2 time(s) in PATH, expected exactly 1`.
Only under a pty, only on a first run; the login PATH inspected afterwards holds `/root/oosh`
exactly once. Unexplained, and a candidate for the third failure the user saw — **candidate, not
conclusion**: their run had 3 failures where the closest reproduction has 5, so the environments
still differ and the specific assertion they hit was never identified.

---

## 14. § 13 was wrong too — the "controlled pair" was not controlled

**Same evening, one hour later.** § 13 claimed a Linux tty-dependent leak on the strength of two
container runs differing "in one thing only, whether a pty was allocated". They differed in a
second thing I did not notice: **how each waited for the install to finish.**

| run | how it waited | verdict |
|---|---|---|
| no-pty | install and `core` **chained in one `docker exec`** — cannot race | clean |
| pty | `until docker exec … 'test -x /root/oosh/test.suite'` | **raced the install** |

`test -x ~/oosh/test.suite` becomes true **partway through** the install, while the tree is still
being assembled. That run's `core` therefore executed against a half-installed oosh. So did the
probe run after it, which is how I ended up looking at a `~/oosh` symlink pointing at a `dev`
worktree that had not been created yet and briefly believing a test had deleted it.

**Redone properly** — install writes a completion marker, the wait polls for the marker, *then*
`core` runs under a pty on a fresh install:

```
  Assertions:  843
  Failed:      2          ← T50 + the intentional meta-test
  (no "Shared tier:" line)
  diff /tmp/log.env.before /root/config/log.env → IDENTICAL
```

and every one of the eight probe hits at `log`'s three `config save log LOG` sites carried a
**fixture** `CONFIG_PATH`, never `/root/config`:

```
PROBE site=399 cfg=[/tmp/test.log.config.428px9]     parent=test/test.log
PROBE site=473 cfg=[/tmp/test.log.config.428px9]     parent=test.suite core
PROBE site=586 cfg=[/tmp/oosh.t71.c0DqKT]            parent=test/test.config
PROBE site=586 cfg=[/tmp/test.config.bak.0.29629]    parent=test.suite core
…
```

The cascade **runs** — eight times — and isolation **holds** every time. That is the opposite of
what § 13 concluded.

### What stands, and what is withdrawn

- **WITHDRAWN:** "the leak is on Linux too", "the pty is what makes the difference", and the
  seven-writer table. All of it rested on the contaminated run.
- **STANDS:** everything in §§ 1-5 and § 10-12 — the macOS chain, which was probed directly, and
  the `check.pm` fix, which was measured before and after on the VM.
- **STANDS, and is the better-evidenced version of § 6:** a fresh Linux install's first `core`,
  under a pty, writes nothing to the shared tier. That is now a measurement rather than an
  inference from silence.

### The lesson worth keeping

**`test -x <file>` is not an install-completion check.** It was wrong twice in one hour, and both
times it produced a confident, wrong finding rather than an obvious error. A background install
must publish a completion marker and the waiter must poll for *that*.

### Still unexplained

The user's own run — install by hand, `core` by hand, no race — scored **843 assertions, 3
failures** where every clean reproduction scores 843/2. One assertion failed for them that has
never failed since, and it was not identified. That remains open, and § 13's `T74` guess is
withdrawn along with the rest of it.

---

## 17. § 5 / § 7.3 — the anchor that vanished: not reproduced, trigger removed

**The claim, from § 2:** on macOS the audit had `CONFIG_PATH=<fixture>` and `export -p` agreed
(`exported=2`), and the `config` process **two levels down** had it EMPTY, so `config.init`
defaulted it to `~/config` and the write landed on the shared tier.

```
AUDIT-PARENT cfg=/var/folders/…/T//test.completion.audit.config.u6FQ5P  exported=2
PROBE site=586 cfg=[/Users/admin/config]  parent=oo pm.discover  gparent=test.completion.audit
```

**It does not reproduce.** Measured on the same VM after cards 1-3:

| probe | result |
|---|---|
| `CONFIG_PATH=/tmp/probeCFG config discover` (one level) | **survives** — answers `/tmp/probeCFG` |
| `CONFIG_PATH=/tmp/probeCFG oo pm.discover` (two levels, the same shape) | **survives** — every `.env` written landed in the fixture, the shared `oosh.env` mtime unchanged |
| `test.suite run completion.audit 1` on the VM — the real path | **2/2, canary silent** |

### Ruled out

- **A general inheritance failure on macOS.** No: one level survives, measured.
- **An `oo` shim re-execing with a clean environment.** No shim — `command -v oo` is
  `/Users/admin/oosh/oo`, the real script.
- **`oo`'s two unconditional `export CONFIG_PATH=`** (`oo:2383`, `oo:2623`). Real, and they *would*
  override an inherited anchor — but both carry `# config-path-exception:` markers with a sound
  reason (install state 31 builds the shared tree before `~/config` is a symlink to it) and neither
  is on the audit's path.
- **`config.init` clobbering it.** T7 made that conditional (`: ${CONFIG_PATH:=~/config}`), and T72
  pins it.

### The honest conclusion

**The trigger is gone, and the mechanism was never determined.** Card 2's `check.pm` fix means the
macOS `OS_CMD` cache is now complete, so `private.user.init`'s heal-and-persist branch — the thing
that invoked `oo pm.discover` from inside the audit — no longer fires. The chain that lost the
anchor is simply not walked any more.

That is the removal of a trigger, not an explanation. **I could not reproduce it and I am not going
to invent a cause for it.** What was observed was observed; it is recorded above with its probe
output, and if it returns the next person starts from the ruled-out list rather than from nothing.

### What was done instead

`T85` in `test/test.config` asserts the property that was silently assumed: an exported
`CONFIG_PATH` **survives into a grandchild process**, and a `config save` two levels down writes
the fixture and leaves the real tier byte-identical. Deliberately a WRITE test, not a
variable-echo test — what matters is not that the child can read the anchor but that its writes
land in the right place.

Nothing asserted that before. "Isolation held the last five times I looked" is not a guarantee;
this makes it one.

---

## 18. § 11 delivered — and the measured surface was wrong in both directions

§ 11 counted the portability faults in test-harness code and proposed a sweep. Both halves of that
are now in the tree: `test.suite portability.validate [<treeRoot>]`, gated by `T-PORTABILITY-TREE`
in `test/test.test.suite`, with the 22 genuine violations fixed.

The count in § 11 was wrong in **both** directions, and the two errors are different in kind.

**Over-reported — 14 correct sites flagged.** § 11 counted *constructs*, and a construct is not a
fault. Five shapes are portable and were being called violations:

| Flagged | Why it is correct |
|---|---|
| `grep -E '…\|…'` ×3 | under `-E` a backslash-pipe is an escaped **literal** pipe — `test.config:1155/1287/1288` are matching `\|\|` in shell source, which is the whole point |
| `stat -c … \| … stat -f …` ×6 | the BSD fallback is on the **continued** line. So the "7 unpaired `stat -c`" of § 11 was **1**, and even that one paired. |
| `date -r … \|\| date -d …` | the BSD form is already **first**; `-d` is the GNU fallback |
| `pgrep -P` | caught by a `grep -P` rule with no word anchor |
| `sed -i` ×2 | inside an `expect.pass` **message string**, not a command |

Each of those became a rule the sweep understands — `-E` detection, a continued-line join, a
`date -r` pairing case, word-anchoring, command-position anchoring — rather than a
`# portability-exception:` marker somebody has to write and the next reader has to trust. **A sweep
is only as useful as its false-positive rate**: markers accumulated to silence a noisy rule are
indistinguishable from markers that mean something.

**Under-reported — `\|` was 3 *files*, not 3 sites.** There were **14**, across `test.c2`,
`test.config`, `test.hiveMind`, `test.oo` and `test.otmux`. And `mktemp` was **118**, not 74.

### The severity column, which § 11 did not foresee

§ 11's scope note said "most of the 74 are latent … so mark rather than churn" — correct, but it
did not say what *marking* means for a gate. Converting 118 fixtures in the same commit that
introduces the guard is churn with no test behind it; leaving the rule in at `violation` makes the
gate permanently red, and **a rule that is always red is a rule nobody reads**. So the rule table
carries a severity and `mktemp` is an `advisory`: counted, reported as a per-file tally through
`warn.log`, rc unchanged. `T-PORTABILITY-ADVISORY` pins that behaviour, so the two severities
cannot quietly collapse back into one.

`test.hiveMind` turned out to be **in** scope, against § 11's exclusion: its six `\|` sites are
mechanical BRE→ERE rewrites, and it scores 115/138 before and after, so its known failures are
untouched. Excluding a file because its suite is red would have left a third of the fault class in
the tree.

### Two prerequisites

Neither was foreseen, and neither was optional if the work was to be done in the tree's own idiom:

1. **`oo method.new` could not name this method.** `private.oo.new.method` split the script from the
   method at the **first** dot (`${nameBody%%.*}`), so `test.suite.portability.validate` resolved
   its script to `test` — a **directory**. It now walks back from the longest prefix that is an
   existing file. Red-first with `T-METHOD-NEW-DOTTED-SCRIPT` in `test/test.oo`.
2. **`test.suite` had no `### new.method` marker**, so `oo method.new` returned rc 3 and could not
   write into it at all. Added, along with `### test.method` in `test/test.test.suite`.

### What it does not cover

Production portability — that is what the macOS and container gates are for, and cards 1-3 are the
work that came out of them. The sweep is static: it finds constructs, not behaviours. `mktemp`'s
118 advisories are the honest measure of how much of this class is still latent.
