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
- **Linux is unaffected** in practice: the heal succeeds there, so the cache goes healthy and
  `oo pm.discover` stops being called. Verified — this host's `core` has been canary-silent all day
  and `os platform.test ubuntu_24_04` reports `test=0 root=0 oosh-user=0 bash-user=0`.
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
