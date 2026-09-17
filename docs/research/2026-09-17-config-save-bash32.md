# `config.save` under bash 3.2 — research: how the required-variables table got written into `oosh.env`

**Written 2026-09-17 · Branch `dev` (`93a9a12`) · Status: F1 + F2 + F3 DELIVERED 2026-09-17 — see § 12. F4 + F5 + F6 remain (card 2).**
**Found by:** the macOS gate after T6, on a virgin `sequoia-base` Tart VM (`192.168.64.5`, user `admin`).

A fresh macOS install produces a `~/config/oosh.env` that every shell fails to source:

```
/Users/admin/config/oosh.env: line 6: OOSH_MODE: command not found
/Users/admin/config/oosh.env: line 7: OOSH_OS: command not found
/Users/admin/config/oosh.env: line 8: OOSH_PM: command not found
/Users/admin/config/log.env:  line 2: LOG_LEVEL: command not found
```

The lines are **verbatim rows from T7's required-variables table** — the heredoc inside
`private.config.required.variables.get` (`config:719-726`) — routed into the file named in each
row's own second column. That routing is a coincidence, not a design, and § 3 explains why.

This is **mine**, introduced with T7 (`config validate required`). But T7 only supplied the
payload: the delivery mechanism is a **`config.save` assumption about `declare -p` that has never
been true on macOS**, and it predates T7 by years. Anything that put a matching line into any
function body would have done the same.

---

## 1. What the file actually contains

```
$ ssh tart_sequoia "cat -v ~/config/oosh.env"
OOSH_CONFIG_NEEDS_SAVE=/var/root/config/user.env
OOSH_PM='brew install'
OOSH_PROMPT='oosh '
OOSH_SHLVL=4
OOSH_STATUS='0: started in shell level: 1'
OOSH_MODE oosh.env basename of the canonical ~/oosh
OOSH_OS oosh.env $OSTYPE, via os
OOSH_PM oosh.env oo pm.discover
```

Two things are wrong before we even reach the bad rows:

1. **No `export` on any line.** `config.save` ends each line with
   `sed 's/^declare -[^ ]* /export /'` (`config:597`). Every line here
   went through that sed **unchanged**, so none of them had a `declare -` prefix to begin with.
2. **`OOSH_MODE` and `OOSH_OS` are absent** as assignments — which is exactly what
   `config validate required` reports. They were never set in the shell that saved.

`log.env` is the same story with one row:

```
LOG_LEVEL=3
LOG_LEVEL log.env defaults to 1
. $OOSH_USER_CONFIG_PATH/log.session.env
```

File ownership dates it: `oosh.env` and `log.env` are `root:dev`, written 05:16 during install;
`user.env` is `admin:dev`. `OOSH_CONFIG_NEEDS_SAVE=/var/root/config/user.env` confirms the saving
shell was **root** with `HOME=/var/root`.

## 2. The mechanism — three properties of bash 3.2, all measured on the VM

`config.save` reads `declare -p` line by line and decides per line
(`config:587-597`):

```bash
_vn=${_line#declare }; _vn=${_vn#-* }; _vn=${_vn%%=*}
case "$_vn" in ${name}|${name}_*) ;; *) continue ;; esac
...
echo "$_line" | sed 's/^declare -[^ ]* /export /'
```

It assumes `declare -p` output is: one line per variable, shaped `declare -flags NAME=value`,
variables only. **On macOS's `/bin/bash` 3.2.57 all three assumptions are false.**

### 2a. `declare -p` emits no `declare -x` prefix

```
$ ssh tart_sequoia '/bin/bash --version | head -1;
                    /bin/bash -c "X=1; Y=\"a b\"; declare -p | grep -E \"^(X|Y|TERM)\""'
GNU bash, version 3.2.57(1)-release (arm64-apple-darwin24)
TERM=dumb
X=1
Y='a b'
```

Plain `set`-style `NAME=value`, single-quoted only where needed — **exactly the shape of the
VM's `oosh.env`**. So on macOS the `sed` is a no-op and `config.save` has *never* written `export`
lines. That alone is a defect: `boot` sources these files, so the values survive only because
sourcing a bare assignment still assigns — but nothing is exported to child processes.

### 2b. `declare -p` with no arguments prints **function definitions**

```
$ ssh tart_sequoia '/bin/bash -c "myfn() { cat <<XX
OOSH_ZZZ_row is here
XX
}; declare -p 2>/dev/null | grep -n OOSH_ZZZ_row"'
4:BASH_EXECUTION_STRING=$'myfn() { cat <<XX\nOOSH_ZZZ_row is here\nXX\n}; declare -p …'
43:OOSH_ZZZ_row is here
```

**Line 43 is the finding.** Bash 3.2's `declare -p` with no names behaves like bare `declare` —
it dumps every function body, multi-line, verbatim, into the same stream `config.save` is
filtering. Bash 5 does not (`declare -p` is variables only).

### 2c. The name filter has no shape gate

For a function-body line such as `OOSH_MODE oosh.env basename of the canonical ~/oosh`:

| step | result |
|---|---|
| `${_line#declare }` | unchanged — no `declare ` prefix |
| `${_vn#-* }` | unchanged — does not start with `-` |
| `${_vn%%=*}` | unchanged — **there is no `=`** |
| `case "$_vn" in OOSH\|OOSH_*)` | **matches** — the glob `*` happily spans spaces |

`_vn` is produced by three strips and is **never checked to be a variable name**. Any line
beginning `OOSH_` or `LOG_` passes, whatever it is.

### 2d. Why exactly those four rows, and why the routing looks deliberate

The heredoc has six rows. Which ones leak is decided purely by the prefix filter:

| row | `config.save oosh OOSH` | `config.save log LOG` |
|---|---|---|
| `BASH_FILE user.env …` | no | no |
| `CONFIG_FILE user.env …` | no | no |
| `OOSH_MODE oosh.env …` | **leaks** | no |
| `OOSH_OS oosh.env …` | **leaks** | no |
| `OOSH_PM oosh.env …` | **leaks** | no |
| `LOG_LEVEL log.env …` | no | **leaks** |

Each row lands in the file its own second column names — but only because the column and the
prefix agree by construction. It is not routing; it is the same fact read twice.

## 3. Blast radius

**Linux is not affected.** Control on this box, same tree, same commit:

```
local bash=5.2.21(1)-release
OK: /home/hannesn/config/oosh.env is pure data
OK: /home/hannesn/config/log.env  is pure data
```

Bash 5 renders multi-line values with ANSI-C quoting (`T=$'a\nb'` — one line) and prints no
functions, so neither 2a nor 2b fires. Verified, not assumed — the earlier working theory was
"multi-line variable continuation lines", and the bash 5 probe **disproved** it before the VM
probe found the real cause.

So this is **macOS-only in practice**, but the cause is "`config.save` is not bash-3.2-safe", and
`init/oosh` is deliberately POSIX sh precisely because early bootstrap cannot assume bash 5.

**Which macOS step runs `config.save` under 3.2 is not yet pinned.** `~/config/install.log`
records no `generating …` line at the level the install ran, so the log cannot answer it. What is
certain from the file's shape is that the writer *was* bash 3.2 — no other shell produces that
output — and from the ownership that it was root. The plausible path: root's `PATH` during install
has no `/opt/homebrew/bin` (that is what `/etc/paths.d/oosh-homebrew`, created *by* the install,
fixes for *later* shells), so a bare `bash` resolves to `/bin/bash` 3.2.

## 4. The detector existed and fired into the void

`config.save` already validates what it wrote:

```bash
for _envName in user oosh log; do
  config.validate "$_envName" >/dev/null 2>&1 \
    || warn.log "config.save: $_envName.env has logic — run 'config validate $_envName' to see why"
done
```

Run by hand on the VM it is unambiguous:

```
INVALID: /Users/admin/config/oosh.env — 3 violation(s) (logic in an env file)
INVALID: /Users/admin/config/log.env  — 1 violation(s) (logic in an env file)
```

**`config.validate` caught this perfectly, on the first install, and nobody heard it** — the
output is sent to `/dev/null` and the only signal is a `warn.log` inside a 1 MB install log at a
level that was not printing. A guard whose verdict is discarded is not a guard.

## 5. The advertised repair makes it worse

`config validate required` prints `repair with: config init.env`. Measured:

```
before:  INCOMPLETE: missing: OOSH_MODE OOSH_OS
$ config init.env
after:   OK: oosh.env is pure data        ← malformed rows gone
         OK: log.env  is pure data
         INCOMPLETE: missing: OOSH_MODE OOSH_OS OOSH_PM   ← one WORSE
         $ cat ~/config/oosh.env          ← EMPTY
```

`config.init.env` regenerates by calling `config.save`, and `config.save` persists **whatever is
in the current environment**. Run from a shell whose environment was never populated — because
the broken env files were the only thing that would have populated it — it writes an empty file
and discards the one good value (`OOSH_PM`) that had survived.

The required-variables table has a third column, *how it is re-derived* (`command -v bash`,
`basename of the canonical ~/oosh`, `$OSTYPE, via os`, `oo pm.discover`). **Nothing in the tree
reads that column.** It is documentation of a repair that does not exist.

## 6. The faults, separated

| # | Fault | Where | Severity |
|---|---|---|---|
| **F1** | `config.save` assumes `declare -p` is `declare -flags NAME=value`, one line per variable, variables only — false on bash 3.2 | `config:587-597` | **HIGH · install** |
| **F2** | `_vn` is three string-strips with no variable-name shape gate; a non-assignment line starting `OOSH_`/`LOG_` is accepted as a variable | `config:589` | **HIGH · install** |
| **F3** | On macOS no env line ever gets `export` — the `sed` cannot match | `config:597` | **MEDIUM** |
| **F4** | `config.save`'s own `config.validate` verdict is discarded to `/dev/null` + `warn.log` | `config:646-649` | **MEDIUM** |
| **F5** | `config init.env` persists instead of deriving; on a broken config it empties the file and loses values | `config.init.env` (`config:432`) | **MEDIUM** |
| **F6** | The required-variables table's *re-derivation* column has no consumer | `private.config.required.variables.get` | **LOW** |

F1+F2 are the defect. F3 is the same root cause seen from the other side. F4 is why it shipped.
F5 is why it cannot be recovered from. F6 is why F5 has no easy fix.

## 7. Prior art in the tree, for whoever plans this

- **The status-output idiom** (`docs/…`, and `path.validate` / `config.validate` /
  `this.anchor.validate`): a verdict goes to stdout via bare `echo` so it survives any
  `LOG_LEVEL`. F4 is precisely the failure that idiom exists to prevent — `config.save` predates
  it and was never converted.
- **`config.validate`** is already the right shape and already returns the right answer. Nothing
  new needs inventing for the detection half.
- **`this.anchor.validate` / `path.validate`** are the two existing *sweep* validators; a
  `config.save` fix wants no new sweep, only a shape gate.
- **`BASH_MINIMUM_MAJOR_VERSION` / `config.bash.minimal.version`** (`config:780`) already exists as
  the tree's notion of "we need bash 5 from here on". Whether `config.save` should *refuse* under
  bash 3.2 rather than be made correct under it is the central design question below.

## 8. Open questions — for the ticket, not for this doc

1. **Correct under 3.2, or refuse under 3.2?** Making the loop bash-3.2-safe is small
   (parse only `^[A-Za-z_][A-Za-z0-9_]*=` and emit `export` ourselves, rather than sed-patching
   whatever `declare -p` happened to print). Refusing is smaller still and arguably more honest,
   but it turns a silent corruption into an install-time stop and needs the *caller* fixed too.
   **Both are needed if the answer to Q2 is "yes".**
2. **Should any install step run `config.save` under `/bin/bash` at all?** Not yet pinned (§ 3).
   If the answer is no, that is a second ticket on the install path and the real fix; F1/F2 then
   become defence in depth. This wants pinning *before* the fix is chosen.
3. **Does F4 become fail-loud?** `config.save` is called during install; making it stop on an
   invalid env file changes install behaviour. The alternative — verdict to stdout, install
   continues — matches the status-output idiom and is reversible.
4. **Does F5 get a real re-derivation path** (the table's third column made executable), or does
   `config init.env` simply refuse when it would write an empty file? The second is a one-line
   guard and stops the bleeding; the first is what the table promised.
5. **Migration.** Hosts already installed carry broken files. Is that a `config` verb, or is
   "reinstall" the answer? `config validate oosh` already names the problem precisely, so a
   `config repair` that deletes non-conforming lines is cheap — but see F5: deleting is not
   restoring.

## 9. What is NOT in scope here

`private.this.group.create` (`this`) has no macOS route — `groupadd` / `addgroup` / append to
`/etc/group`, none valid on darwin — and the append returns 0 while achieving nothing. Found by
the same gate, unrelated cause, **its own card**. `private.user.init` already knows the right
command (`OS_CMD_GROUP_ADD="dseditgroup -o create -q"`).

## 10. State of the VM

`tart_sequoia` (`192.168.64.5`, user `admin`) is up and deliberately left in the post-repair
state of § 5 — `oosh.env` empty, `required` reporting three missing. That is the evidence for F5.
Re-running the install from scratch reproduces § 1 from a clean VM in about six minutes.

## 11. Hand-off

`dev` at `93a9a12`, clean, in sync with `origin/dev`. No code changed by this research.

Board: this wants **one card for F1+F2+F3** (HIGH · install — `config.save` is not bash-3.2-safe)
and **one for F4+F5+F6** (MEDIUM — the guard that was discarded and the repair that does not
repair). They are separable and the first is the one that ships broken installs.

---

## 12. What shipped (2026-09-17)

**F1 + F2 + F3 — delivered.** Commits `287073f` … `2b70425` on `dev`.

| # | Fault | Fix |
|---|---|---|
| **F1** | `declare -p` assumed to be `declare -flags NAME=value` | `declare -p <name>` — the *named* form, measured correct on 3.2 and 5 — and `export` is **prepended**, never sed-patched onto a prefix bash 3.2 does not print |
| **F2** | no shape gate on the derived name | `compgen -v` supplies NAMES; two input gates and one output gate; both loops read **line by line**, so the line is the unit validated |
| **F3** | macOS env files never carried `export` | same change; `docs/config.md § File Format` now says `export` is mandatory and why |

The twelve-line inline loop is four private methods —
`private.config.variables.list`, `private.config.variable.export.line`,
`private.config.variables.export`, `private.config.string.upper` — which is the
extraction `review-2026-09-09 § M3` named eight days before it existed.

### Two prerequisites the ticket did not expect

- **`oo method.new` could not create a private method.** It split
  `private.config.variables.list` on the first segment, aimed at a file called
  `private`, and refused with rc 3. Private methods are a large share of every
  script, so the tool the project *mandates* could not make one and each was
  hand-written. Fixed first (`287073f`), with `T-METHOD-NEW-PRIVATE`.
- **Anything logged inside `config.save`'s redirect lands in the env file.**
  `log:35` sets `LOG_DEVICE=/proc/self/fd/1`; inside `{ … } >$CONFIG` fd 1 *is*
  `$CONFIG`. A second, latent route for junk into env files, now a stated
  contract on the three harvest methods.

### Three faults found while fixing these, and fixed here

- **`${file^^}` is fatal on bash 3.2**, not a warning: "bad substitution" and
  the shell **exits**. Reached by the DOCUMENTED single-argument form
  (`config add oosh`, `docs/config.md:343`), so on macOS a documented command
  killed the user's shell.
- **`config save backup BACKUP_`** (`backup:262`) harvested nothing: the gate
  read `BACKUP_|BACKUP__*`. `backup.env` has always been empty.
- **`result.save`** (`this:697`) wrote every line matching `RESULT` —
  name *and value* — into a file `result.load` then **sources**. With two
  planted decoys the red run also caught three unplanted ones, including
  `testName`, whose *value* merely mentioned RESULT.

### One correction to § 6

The table listed `result.save` as carrying the same bash-3.2 fault. It does
not: `declare -px` (**with** `-x`) is well behaved on 3.2 — probed on the VM.
Its defect is the sibling one, matching the whole line instead of the name.

### Still open — card 2

**F4** (`config.save` discards its own `config.validate` verdict), **F5**
(`config init.env` empties the file), **F6** (the re-derivation column has no
consumer). Plus the cards in § 13.

## 13. Cards filed while doing this

| Card | Why |
|---|---|
| `config.string.quote` is lossy | `config:163-166` ends `echo $RESULT` **unquoted**: `"a␣␣␣␣b"` → `'a b'`. It is the nearest-miss helper for this ticket and could not be reused. Fixing it moves T25/T26 semantics. |
| `BASH_MINIMUM_MAJOR_VERSION` is dead | `config.bash.minimal.version` (`config:780`) writes it; nothing in the tree reads it. It also appends straight to `$CONFIG` instead of via `config.set`, so it duplicates on every call. |
| `templates/code` has no `newGetterTest` | `newMethodTest` assumes a `create.result` method: its `expect 0 "<result>"` compares `$RESULT`, which a getter never sets, so the generated case compares whatever the previous test left — a test that cannot fail. Four such cases were generated and removed by hand here. |
| `replace` cannot target one of two identical adjacent lines | `replace block` requires anchors matching exactly one line each, so collapsing a duplicated line needed raw `python3` — the one edit in this ticket that did not go through an oosh command. |
| Which install step runs `config.save` under `/bin/bash`? | § 8 Q2, still unpinned. This ticket makes it harmless rather than answering it. If the answer is "none should", that is an install-path ticket and this becomes defence in depth. |

---

## 14. The macOS gate (2026-09-17) — before and after, same image

Tart VM rebuilt from `ghcr.io/cirruslabs/macos-sequoia-base:latest`, Sequoia 15.7.3,
`/bin/bash` 3.2.57, `ossh install tart_sequoia admin` from `origin/dev`.

**`~/config/oosh.env` before (§ 1) and after:**

```
before                                                after
──────────────────────────────────────────────────    ─────────────────────────────────────
OOSH_CONFIG_NEEDS_SAVE=/var/root/config/user.env      export OOSH_CLEAN_ENV="1"
OOSH_PM='brew install'                                export OOSH_CONFIG_NEEDS_SAVE="/var/root/config/user.env"
OOSH_PROMPT='oosh '                                   export OOSH_OS="darwin"
OOSH_SHLVL=4                                          export OOSH_PM="brew install"
OOSH_STATUS='0: started in shell level: 1'            export OOSH_PM_BIN="brew"
OOSH_MODE oosh.env basename of the canonical ~/oosh   export OOSH_PM_UPDATE=""
OOSH_OS oosh.env $OSTYPE, via os                      export OOSH_PROMPT="oosh "
OOSH_PM oosh.env oo pm.discover                       export OOSH_SHLVL="4"
                                                      export OOSH_STATUS="0: started in shell level: 1"
```

No prose rows; **every line carries `export` for the first time on macOS**; `OOSH_OS` is
persisted where before it was one of the "missing" variables. `log.env` likewise
(`export LOG_LEVEL="3"` plus the chain line, no `LOG_LEVEL log.env defaults to 1` row).

| Check | Before | After |
|---|---|---|
| `config validate oosh` | `INVALID — 3 violation(s)` | **OK** |
| `config validate log` | `INVALID — 1 violation(s)` | **OK** |
| `config validate user` | OK | OK |
| `path validate` | OK | OK |
| every shell | 4 × `…: command not found` | **silent** |
| `config validate required` | `missing: OOSH_MODE OOSH_OS` | `missing: OOSH_MODE` |
| `test.platform.shared.config.env.invariant` | — (did not exist) | **11 / 13** |
| `/bin/bash -n` on config/this/oo/boot | — | all parse under 3.2.57 |

### The two remaining failures are ONE defect, and it is not this card's

`OOSH_MODE` is never set in the shell that saves, so it is absent from `oosh.env` and empty
after sourcing `boot`. The value is plainly derivable — `~/oosh` is a symlink to `dev` on that
VM — and the required-variables table already states how (*"basename of the canonical
~/oosh"*). **Nothing reads that column.** That is **F6**, and the repair that should close it
is **F5**. Card 2.

It is worth saying what changed here: before, that validator's verdict was drowned in
corruption and a wall of `command not found`. Now it is the only thing left on the screen,
saying one true sentence.

### One more fault, found by the gate, fixed here

`this:191` used `${anchor,,}` — bash 4+. Under macOS `/bin/bash` 3.2 that is a "bad
substitution", so **`this anchor.validate` produced no verdict at all** on any macOS shell not
already re-pathed to brew bash: a validator silently declining to validate. Same class as
`config.save`'s `${file^^}`, found the same way, fixed with `printf | tr`. Measured on the VM:
`bash=3.2.57 slug=[oosh-dir]`, shell survives.

### The Linux container gate — 7 failures, then 1

The first `os platform.test ubuntu_24_04` after this ticket reported **7 failures: 6 in
`test.odocker` plus the 1 intentional meta-test**. The six were pre-existing and unrelated to
`config.save` — they assert the HOST's `/var/dev/…/DockerWorkspaces` tree exists, ungated, unlike
the docker-touching assertions beside them which are all behind `DOCKER_AVAILABLE`. They date from
`3cfd931`; backlog item 8 gave `test.odocker` its `core` category and score, and its plan said
*"No platform run: odocker is off the install path"* — so this was the first container `core` since,
and it surfaced item 8's blind spot.

**Fixed the same day** (`d60cf69`), in its own ticket: `T-WS-LIST` tests the enumerator against a
fixture built with `odocker workspace.init` and passes anywhere;
`test/test.platform.odocker.workspaces.invariant` keeps the host-readiness question where a
host-dependent assertion belongs. The gate now reads:

```
PASS: ubuntu_24_04 (test=0 root=0 oosh-user=0 bash-user=0)
748 test cases, 847 assertions, 846 passed, 1 intentional
```

So the ubuntu gate for this research doc's work is **green**, with the only remaining failure being
the meta-test that verifies the counters.

---

## 15. Card 2 delivered (2026-09-17) — F4 + F5 + F6

`5f258ba`. The repair that made things worse now repairs, **measured on the machine that was
actually broken**:

```
=== BEFORE   INCOMPLETE: /Users/admin/config — missing: OOSH_OS
=== REPAIR   config.init.env: re-derived: OOSH_OS
=== AFTER    OK: /Users/admin/config carries every required variable and agrees with the checkout
=== SECOND RUN
             (nothing to derive)  OK: … carries every required variable
```

`test/test.platform.shared.config.env.invariant` on the VM: **11/13 → 13/13**. Its two failures
were exactly this card's symptom.

### F6 — the third column is a function name now

Every derivation already existed; each got a name and one home:

| row | deriver | was |
|---|---|---|
| `OOSH_MODE` | `private.config.derive.oosh.mode` | inline **twice** — `config.validate.required`'s drift check and `oo:2631-2633` |
| `OOSH_OS` | `private.config.derive.oosh.os` | `os.check.env`, reached by nothing on the config path |
| `OOSH_PM` | `private.config.derive.oosh.pm` | only `oo pm.discover`, which is not a detector |
| `BASH_FILE` / `CONFIG_FILE` / `LOG_LEVEL` | ditto | inline in `config.save` / `config.init` / `this` |

The drift check now calls the same accessor the repair does, so they cannot disagree about what
"the branch this host is on" means.

### F5 — the repair derives before it saves

Per-variable emptiness guard (`private.user.init`'s OS_CMD shape), so a surviving value is never
overwritten. **All three env files are backed up**, not just `user.env` — that omission is exactly
how `OOSH_PM` was lost, because `config save oosh OOSH` truncates `oosh.env` before anything can
read the survivor out of it. And a **refuse-to-worsen** guard: fewer export lines out than in
restores the backup and says so.

### F4 — the verdict is heard, on stderr

`config.save` had no deliberate exit status at all; it has one now, and the verdict goes to
**stderr**. Not stylistic: `user:1702-1708` records that `$(user get basehome)` **captures** this
function's stdout, and a stray line there once propagated a garbage IdentityFile into a generated
ssh config and failed a git clone. Smoke-tested — a capture around `config save` comes back empty.

### Two corrections made during the work

- The first `OOSH_PM` deriver called **`oo pm.discover`**, which is not a detector: it runs the real
  package manager (`$SUDO apt-get update`) and then `config save`. It hung a test run on a sudo
  password prompt — the same trap `test.suite:895-905` records being sprung once before. **A
  deriver must have no side effects.** It now detects with `command -v` and maps; that map is a
  **third copy** (`init/oosh:214`, `oo:3093`) and is carded, not hidden.
- The first `T80` asserted `LOG_LEVEL` derives 3 while the suite runs at 1. The deriver was right —
  an already-chosen level wins — and the test was wrong.

The table claimed `LOG_LEVEL` *"defaults to 1"*; `this:16` and `log:125` both use **3**. Corrected.
**T37** — which passed on a **zero-byte** file, the one outcome that actually happened on the VM —
now asserts content.

### Open after this card

- **§ 5 / § 7.3** — on macOS `CONFIG_PATH` was exported by a parent and empty two processes down.
  Untouched, and it makes `test.suite.config.isolate` weaker than it looks.
- **Three copies of the package-manager table** — `init/oosh:214`, `oo:3093`, and now
  `private.config.pm.command.get`. One side-effect-free `oo pm.detect` should serve all three.
- **Four answers to "which branch is ~/oosh on"** — this card unified two (`config:874`,
  the repair); `private.oo.shared.base.get` and `config.init.user:277-282` remain.
