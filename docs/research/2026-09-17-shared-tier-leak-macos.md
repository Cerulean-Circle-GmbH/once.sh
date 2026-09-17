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
