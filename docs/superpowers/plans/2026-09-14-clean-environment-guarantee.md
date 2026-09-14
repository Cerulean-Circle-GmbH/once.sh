# Clean-Environment Guarantee Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Starting oosh from a clean environment works however you got there — `HOME` is recovered rather than demanded, and `init/oosh` re-establishes a clean environment for itself.

**Architecture:** Two files each gain a self-contained POSIX-sh `HOME` recovery (`getent` → `dscl` → `/etc/passwd`); `init/oosh` additionally re-execs itself through `env -i` when it can. No `env -S` anywhere — that flag is what BusyBox lacks and what cost the original guarantee in `075b4a3`.

**Tech Stack:** POSIX `sh` (must parse and run under `dash`, `busybox ash`, `bash`), oosh `test.suite`.

**Spec:** `docs/superpowers/specs/2026-09-14-clean-environment-guarantee-design.md`

---

## File Structure

| File | Responsibility | Change |
|---|---|---|
| `boot` | POSIX-sh prologue: settle `HOME`, anchors, config, PATH | replace the §0 refuse-block with recovery |
| `init/oosh` | installer bootstrap, runs before oosh exists | add clean re-exec + the same recovery |
| `test/test.config` | `boot`'s tests live here (T40/T47 precedent) | add recovery tests |
| `test/test.install` | `init/oosh`'s contract tests | add re-exec + recovery tests |

The `HOME` recovery is **duplicated on purpose** — `init/oosh` runs before oosh exists and `boot` runs in a shell where `this` cannot even be parsed, so neither may source a shared helper. Both copies carry a comment saying so.

---

## Task 1: `boot` recovers `$HOME` instead of refusing

**Files:**
- Modify: `boot` (the `── 0. Refuse to half-boot without a usable $HOME ──` block)
- Test: `test/test.config`

- [ ] **Step 1: Write the failing test**

Append to `test/test.config`, immediately before the final `### test.method` marker:

```bash
# ============================================================================
# T65: boot RECOVERS $HOME rather than demanding it
# ============================================================================
# `env -i` drops HOME, and every anchor hangs off it. boot used to refuse.
# The card (T3) is "env -i sh … shall boot correctly", so it must recover:
# getent -> dscl -> /etc/passwd, the same split as this:126-134.
test.config.bootRecoversHome() {
  local bad="" shell out expect
  expect="[$HOME|$HOME/oosh|$HOME/config]"
  for shell in sh dash bash; do
    command -v "$shell" >/dev/null 2>&1 || continue
    out=$(cd /tmp && env -i "$shell" -c ". \"$OOSH_DIR/boot\"; echo \"[\$HOME|\$OOSH_DIR|\$CONFIG_PATH]\"" 2>&1 | tail -1)
    [ "$out" = "$expect" ] || bad="$bad $shell=>$out"
  done
  if command -v busybox >/dev/null 2>&1; then
    out=$(cd /tmp && env -i busybox ash -c ". \"$OOSH_DIR/boot\"; echo \"[\$HOME|\$OOSH_DIR|\$CONFIG_PATH]\"" 2>&1 | tail -1)
    [ "$out" = "$expect" ] || bad="$bad busybox-ash=>$out"
  fi
  # a STALE HOME (set, but not a directory) is the same broken input
  out=$(cd /tmp && env -i HOME=/nonexistent/removed-user sh -c ". \"$OOSH_DIR/boot\"; echo \"[\$HOME]\"" 2>&1 | tail -1)
  [ "$out" = "[$HOME]" ] || bad="$bad stale-HOME=>$out"
  # an explicitly GOOD HOME must never be overridden
  out=$(cd /tmp && env -i HOME=/tmp sh -c ". \"$OOSH_DIR/boot\"; echo \"[\$HOME]\"" 2>&1 | tail -1)
  [ "$out" = "[/tmp]" ] || bad="$bad good-HOME-overridden=>$out"
  # and sourcing must leave the calling shell alive (boot must never exec)
  out=$(cd /tmp && env -i sh -c ". \"$OOSH_DIR/boot\"; echo STILL-HERE" 2>&1 | tail -1)
  [ "$out" = "STILL-HERE" ] || bad="$bad shell-did-not-survive=>$out"
  if [ -z "$bad" ]; then
    create.result 0 "HOME recovered in every shell"
  else
    create.result 1 "expected $expect —$bad"
  fi
}
test.case - "T65: boot recovers \$HOME under env -i (every shell)" \
  test.config.bootRecoversHome
expect 0 "HOME recovered in every shell" \
  "the T3 card: env -i sh must boot correctly, not refuse"
```

Note the `cd /tmp` — running from inside the oosh tree lets bash's `source` fall back to the cwd and can mask a PATH bug. This exact mistake cost a full cycle earlier.

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd ~/oosh && ./test.suite run config 1 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "T65|✗ FAIL|Failed:"
```
Expected: **FAIL** — current `boot` refuses, so `$HOME` comes back empty.

- [ ] **Step 3: Replace boot's §0 block**

Replace the whole block from `# ── 0. Refuse to half-boot without a usable $HOME ───` through its closing `fi` with:

```sh
# ── 0. $HOME ────────────────────────────────────────────────────────────────
# EVERY anchor below hangs off $HOME — and `env -i` drops it, which is exactly
# the "env -i sh … shall boot correctly" case (T3). So DERIVE it rather than
# give up: that is what bash itself does for `~` when HOME is unset, and it is
# what makes the documented clean-environment install work.
#
# A HOME that is SET but not a directory (a removed user, a container that
# inherited the builder's) is the same broken input and gets the same treatment.
#
# Three-way lookup, the same split the rest of the tree uses (this:126-134):
# getent (Linux/NSS) -> dscl (macOS) -> /etc/passwd (minimal images with
# neither). Only if all three come up empty do we refuse — and then by `return`,
# never `exit`, because boot is SOURCED and exit would close the terminal.
#
# DELIBERATELY DUPLICATED in init/oosh: that script runs before oosh exists and
# this one runs in a shell where `this` cannot even be parsed, so neither may
# source a shared helper. See the design spec, "Duplication is inherent".
if [ -z "$HOME" ] || [ ! -d "$HOME" ]; then
  _oosh_user=$(id -un 2>/dev/null)
  _oosh_home=""
  if [ -n "$_oosh_user" ]; then
    if command -v getent >/dev/null 2>&1; then
      _oosh_home=$(getent passwd "$_oosh_user" 2>/dev/null | cut -d: -f6)
    fi
    if [ -z "$_oosh_home" ] && command -v dscl >/dev/null 2>&1; then
      # macOS returns TWO paths in one field for root ("/var/root
      # /private/var/root"); take the first — same as private.get.home.darwin.
      _oosh_home=$(dscl . -read "/Users/$_oosh_user" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
    fi
    if [ -z "$_oosh_home" ] && [ -r /etc/passwd ]; then
      _oosh_home=$(awk -F: -v u="$_oosh_user" '$1 == u { print $6; exit }' /etc/passwd)
    fi
  fi
  if [ -n "$_oosh_home" ] && [ -d "$_oosh_home" ]; then
    HOME="$_oosh_home"
    export HOME
    unset _oosh_user _oosh_home
  else
    echo "oosh boot: \$HOME is unset or not a directory, and no home could be" >&2
    echo "oosh boot: derived for '${_oosh_user:-?}' from getent/dscl//etc/passwd." >&2
    echo "oosh boot: re-run with HOME set, e.g. HOME=/home/you sh -c '. ~/oosh/boot'" >&2
    unset _oosh_user _oosh_home
    return 1 2>/dev/null || exit 1
  fi
fi
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd ~/oosh && ./test.suite run config 1 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "T65|✗ FAIL|Failed:"
```
Expected: **PASS**, `Failed: 0`.

- [ ] **Step 5: Verify POSIX cleanliness in all four shells**

```bash
cd ~/oosh && for s in sh dash bash "busybox ash"; do printf '%-14s ' "$s"; $s -n boot && echo OK; done
```
Expected: `OK` four times. (`busybox ash -n` must pass — this is the Alpine guarantee.)

- [ ] **Step 6: Commit**

```bash
cd ~/oosh && git add boot test/test.config
git commit -m "fix(boot): recover \$HOME from the passwd database instead of refusing

env -i drops HOME and every anchor hangs off it, so boot refused — which made
the T3 card's own command impossible. It now derives HOME the way bash derives
~: getent -> dscl -> /etc/passwd, the same split as this:126-134. Refuses only
when all three come up empty, and by return rather than exit because boot is
sourced.

Test T65 pins it across sh, dash, bash and busybox ash."
```

---

## Task 2: `init/oosh` recovers `$HOME` the same way

**Files:**
- Modify: `init/oosh` (after the sourcing guard, before `OOSH_SELF_BRANCH`)
- Test: `test/test.install`

- [ ] **Step 1: Write the failing test**

Append to `test/test.install`, before `test.suite.save.results`:

```bash
# ============================================================================
# T-INIT-HOME-RECOVERY: init/oosh recovers $HOME under env -i
# ============================================================================
# README documents `unbuffer env -i sh -xc "$(wget -O- .../init/oosh)"`. env -i
# drops HOME, so init/oosh computed OOSH_DIR=/oosh and
# INSTALL_LOG=/config/install.log — it would install into the filesystem root.
# Structural check: the recovery block exists and precedes the first $HOME use.
test.install.homeRecovery() {
  local ok=1 recoverLn firstUseLn
  grep -q 'getent passwd' "$INIT_SCRIPT" || ok=0
  grep -q 'NFSHomeDirectory' "$INIT_SCRIPT" || ok=0
  grep -q '/etc/passwd' "$INIT_SCRIPT" || ok=0
  recoverLn=$(grep -n 'getent passwd' "$INIT_SCRIPT" | head -1 | cut -d: -f1)
  firstUseLn=$(grep -n ': ${OOSH_DIR:=$HOME/oosh}' "$INIT_SCRIPT" | head -1 | cut -d: -f1)
  [ -n "$recoverLn" ] && [ -n "$firstUseLn" ] && [ "$recoverLn" -lt "$firstUseLn" ] || ok=0
  if [ "$ok" = "1" ]; then
    create.result 0 "HOME recovery precedes the first \$HOME use"
  else
    create.result 1 "recover=$recoverLn firstUse=$firstUseLn"
  fi
}
test.case $level "T-INIT-HOME-RECOVERY: init/oosh recovers \$HOME before using it" \
  test.install.homeRecovery
expect 0 "HOME recovery precedes the first \$HOME use" \
  "env -i drops HOME; without recovery the installer targets /oosh"
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd ~/oosh && ./test.suite run install 1 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "HOME-RECOVERY|✗ FAIL|Failed:"
```
Expected: **FAIL** — no recovery block exists yet.

- [ ] **Step 3: Add the recovery to `init/oosh`**

Insert immediately **after** the sourcing guard (the block ending `return 0 2>/dev/null || exit 0` and its `fi`) and **before** the `# ─── Branch default ───` comment:

```sh
# ─── $HOME ───────────────────────────────────────────────────────────────
# Everything below anchors off $HOME — OOSH_DIR, INSTALL_LOG, the final
# `mv` to ~/oosh. `env -i` drops it, and the README documents exactly that:
#   unbuffer env -i sh -xc "$(wget -O- .../init/oosh)" | tee install.log.txt
# Without recovery that installs into /oosh with a log at /config/install.log.
#
# getent (Linux/NSS) -> dscl (macOS) -> /etc/passwd. DELIBERATELY DUPLICATED
# from boot: this script runs before oosh exists, so it cannot source a shared
# helper. See the design spec, "Duplication is inherent".
if [ -z "$HOME" ] || [ ! -d "$HOME" ]; then
  _oosh_user=$(id -un 2>/dev/null)
  _oosh_home=""
  if [ -n "$_oosh_user" ]; then
    if command -v getent >/dev/null 2>&1; then
      _oosh_home=$(getent passwd "$_oosh_user" 2>/dev/null | cut -d: -f6)
    fi
    if [ -z "$_oosh_home" ] && command -v dscl >/dev/null 2>&1; then
      _oosh_home=$(dscl . -read "/Users/$_oosh_user" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
    fi
    if [ -z "$_oosh_home" ] && [ -r /etc/passwd ]; then
      _oosh_home=$(awk -F: -v u="$_oosh_user" '$1 == u { print $6; exit }' /etc/passwd)
    fi
  fi
  if [ -n "$_oosh_home" ] && [ -d "$_oosh_home" ]; then
    HOME="$_oosh_home"
    export HOME
    echo "oosh install: \$HOME was unset; recovered as $HOME" >&2
  else
    echo "oosh install: \$HOME is unset and no home could be derived for" >&2
    echo "oosh install: '${_oosh_user:-?}'. Re-run with HOME set:" >&2
    echo "oosh install:   env -i HOME=\"\$HOME\" sh -c \"\$(wget -O- …/init/oosh)\"" >&2
    unset _oosh_user _oosh_home
    exit 1
  fi
  unset _oosh_user _oosh_home
fi
```

Unlike `boot`, this one **announces** the recovery — the documented invocation is an `-x` trace being captured to a log, so an install into an unexpected home must be visible in that log. And it `exit`s rather than `return`s: `init/oosh` is executed, never sourced (the guard above already handled sourcing).

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd ~/oosh && ./test.suite run install 1 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "HOME-RECOVERY|✗ FAIL|Failed:"
```
Expected: **PASS**, `Failed: 0`.

- [ ] **Step 5: Verify the recovery works, without running an install**

```bash
cd /tmp && env -i sh -c '
  sed -n "/─── \$HOME ───/,/^fi$/p" ~/oosh/init/oosh > /tmp/homeblock.sh
  . /tmp/homeblock.sh
  echo "HOME=[$HOME]  OOSH_DIR would be=[$HOME/oosh]"
' 2>&1; rm -f /tmp/homeblock.sh
```
Expected: `HOME=[/home/<you>]` and `OOSH_DIR would be=[/home/<you>/oosh]` — **not** `/oosh`.

- [ ] **Step 6: POSIX cleanliness**

```bash
cd ~/oosh && for s in sh dash bash "busybox ash"; do printf '%-14s ' "$s"; $s -n init/oosh && echo OK; done
```
Expected: `OK` four times.

- [ ] **Step 7: Commit**

```bash
cd ~/oosh && git add init/oosh test/test.install
git commit -m "fix(init/oosh): recover \$HOME so the documented env -i install works

README documents 'unbuffer env -i sh -xc \"\$(wget -O- .../init/oosh)\"'. env -i
drops HOME, so the installer computed OOSH_DIR=/oosh and
INSTALL_LOG=/config/install.log — it would install into the filesystem root.

Same getent -> dscl -> /etc/passwd lookup as boot, deliberately duplicated
because init/oosh runs before oosh exists. Announces the recovered HOME, since
the documented invocation is an -x trace captured to a log."
```

---

## Task 3: `init/oosh` re-establishes a clean environment for itself

**Files:**
- Modify: `init/oosh` (immediately after the `$HOME` block from Task 2)
- Test: `test/test.install`

This restores what `#!/usr/bin/env -iS HOME=${HOME} sh` gave from 2024-04-07 to 2026-03-09, without the `-S` flag BusyBox lacks. Verified: `busybox env` rejects `-S` but accepts `env -i VAR=val cmd`.

- [ ] **Step 1: Write the failing test**

Append to `test/test.install`, before `test.suite.save.results`:

```bash
# ============================================================================
# T-INIT-CLEAN-ENV: init/oosh re-establishes a clean environment
# ============================================================================
# From 2024-04-07 (8c277f4, Chris Daßler) to 2026-03-09 (075b4a3) init/oosh
# carried `#!/usr/bin/env -iS HOME=${HOME} sh` — clean environment, HOME passed
# through. 075b4a3 removed it because BusyBox env has no -S. A self-re-exec
# gets the same guarantee portably: busybox env rejects -S but accepts
# `env -i VAR=val cmd`.
test.install.cleanEnvReexec() {
  local ok=1
  grep -q 'OOSH_CLEAN_ENV' "$INIT_SCRIPT" || ok=0
  grep -qE 'exec env -i HOME=' "$INIT_SCRIPT" || ok=0
  # guarded on $0 being a real file — the curl-pipe case has no file to re-exec
  grep -qE '\[ -f "\$0" \]' "$INIT_SCRIPT" || ok=0
  # and must NOT reintroduce the flag BusyBox cannot parse
  grep -q 'env -S' "$INIT_SCRIPT" && ok=0
  if [ "$ok" = "1" ]; then
    create.result 0 "clean re-exec present, guarded, no -S"
  else
    create.result 1 "clean-env re-exec missing, unguarded, or uses env -S"
  fi
}
test.case $level "T-INIT-CLEAN-ENV: init/oosh re-execs clean without env -S" \
  test.install.cleanEnvReexec
expect 0 "clean re-exec present, guarded, no -S" \
  "restores the 2024-2026 clean-environment guarantee; -S is what BusyBox lacks"
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd ~/oosh && ./test.suite run install 1 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "CLEAN-ENV|✗ FAIL|Failed:"
```
Expected: **FAIL**.

- [ ] **Step 3: Add the re-exec, AFTER the branch default block**

**Placement matters and is not negotiable.** `init/oosh` sets the branch at:

```sh
OOSH_SELF_BRANCH="${OOSH_SELF_BRANCH:-dev}"
: ${OOSH_BRANCH:=$OOSH_SELF_BRANCH}
```

The re-exec must go **after those two lines**, not immediately after the `$HOME` block. Placed
earlier, `OOSH_BRANCH` would still be empty, the re-exec would carry nothing, and the child would
fall back to `dev` — silently discarding a caller's `OOSH_BRANCH=hannes-v2`. That is exactly the
bug `57f0984` (2026-02-16) fixed. Insert immediately after `: ${OOSH_BRANCH:=$OOSH_SELF_BRANCH}`:

```sh
# ─── Clean environment ───────────────────────────────────────────────────
# From 2024-04-07 (8c277f4) to 2026-03-09 (075b4a3) this file carried
#   #!/usr/bin/env -iS HOME=${HOME} sh
# — wipe the environment, pass HOME through. 075b4a3 removed it because
# BusyBox env has no -S flag, and nothing replaced the guarantee.
#
# Re-establish it here instead of in the shebang. `-S` was only ever needed
# because a SHEBANG can pass one argument; doing it inside the script removes
# that constraint. Verified: busybox env rejects -S but accepts
# `env -i VAR=val cmd`, so this works on Alpine.
#
# HOME is already recovered above, so the good value is what we carry across.
# Guarded on $0 being a readable file: in the curl-pipe path ($0 is "sh")
# there is nothing to re-exec, so we skip — that path is already clean-ish and
# the pre-clone fallback below handles the interpreter upgrade.
# OOSH_CLEAN_ENV makes it fire exactly once; looping is impossible.
if [ -z "$OOSH_CLEAN_ENV" ] && [ -f "$0" ]; then
  exec env -i \
    HOME="$HOME" \
    OOSH_CLEAN_ENV=1 \
    OOSH_BRANCH="${OOSH_BRANCH:-}" \
    OOSH_NO_AUTORUN="${OOSH_NO_AUTORUN:-}" \
    "$0" "$@"
fi
```

`OOSH_BRANCH` is carried explicitly because `57f0984` (2026-02-16) fixed precisely this: `env -i` wiped it when passed as an env-var prefix. Carrying it here keeps both the positional-argument path and the env-var path working.

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd ~/oosh && ./test.suite run install 1 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "CLEAN-ENV|✗ FAIL|Failed:"
```
Expected: **PASS**, `Failed: 0`.

- [ ] **Step 5: Prove the re-exec actually cleans, without running an install**

```bash
cd /tmp && cat > /tmp/reexec.sh <<'EOF'
if [ -z "$OOSH_CLEAN_ENV" ] && [ -f "$0" ]; then
  exec env -i HOME="$HOME" OOSH_CLEAN_ENV=1 "$0" "$@"
fi
echo "  vars=[$(env | wc -l)] HOME=[$HOME] args=[$*] POLLUTE=[${POLLUTE:-<gone>}]"
EOF
chmod +x /tmp/reexec.sh
for s in sh dash bash "busybox ash"; do printf '%-14s ' "$s"; POLLUTE=yes $s /tmp/reexec.sh a b; done
rm -f /tmp/reexec.sh
```
Expected, every shell: `POLLUTE=[<gone>]`, `HOME` intact, `args=[a b]`.

- [ ] **Step 6: POSIX cleanliness**

```bash
cd ~/oosh && for s in sh dash bash "busybox ash"; do printf '%-14s ' "$s"; $s -n init/oosh && echo OK; done
```
Expected: `OK` four times.

- [ ] **Step 7: Commit**

```bash
cd ~/oosh && git add init/oosh test/test.install
git commit -m "feat(init/oosh): restore the clean-environment guarantee, without env -S

From 2024-04-07 (8c277f4, Chris Dassler) to 2026-03-09 (075b4a3) init/oosh
carried '#!/usr/bin/env -iS HOME=\${HOME} sh' — clean environment, HOME passed
through. 075b4a3 removed it for Alpine: BusyBox env has no -S. Nothing replaced
the guarantee.

Re-established inside the script instead of in the shebang. -S was only needed
because a SHEBANG passes one argument; a self-re-exec removes that constraint.
Measured: busybox env rejects -S but accepts 'env -i VAR=val cmd'.

Guarded on \$0 being a readable file (the curl-pipe path has no file to
re-exec) and on an OOSH_CLEAN_ENV sentinel, so it fires once and cannot loop.
OOSH_BRANCH is carried across explicitly — 57f0984 fixed exactly that loss."
```

---

## Task 4: Documentation and the standing verification bar

**Files:**
- Modify: `docs/boot.md`, `docs/plans/2026-09-10-oosh-boot-tickets.md`

- [ ] **Step 1: Update `docs/boot.md`'s Guarantees table**

The table currently contains this row verbatim:

```markdown
| **Requires `$HOME`** | set, and an existing directory. Otherwise `boot` prints one diagnostic to stderr and `return`s non-zero without touching anything. |
```

Replace that single row with:

```markdown
| **Recovers `$HOME`** | `env -i` drops it, so `boot` looks it up in the password database (`getent` → `dscl` → `/etc/passwd`) and exports it — which is what makes `env -i sh` boot correctly. A `HOME` that is *set but not a directory* (a removed user, an inherited container env) is treated the same way. Only if no home can be found at all does `boot` print a diagnostic and `return` non-zero. |
```

Also update the **Proven shells** row, which currently ends *"and under `env -i` with `HOME` passed
through"* — the `HOME` caveat no longer applies:

```markdown
| **Proven shells** | `sh`, `dash`, `busybox ash`, `bash` — and under `env -i`, with or without `HOME`. |
```

- [ ] **Step 2: Tick T3's DoD in the tracker**

In `docs/plans/2026-09-10-oosh-boot-tickets.md`, under T3, mark the clean-environment items done and add:

```markdown
**Delivered (2026-09-14, second attempt).** `boot` and `init/oosh` both recover `$HOME`;
`init/oosh` re-execs clean without `env -S`. The guarantee `075b4a3` removed for Alpine is
restored portably — see
[the design spec](../superpowers/specs/2026-09-14-clean-environment-guarantee-design.md).
```

- [ ] **Step 3: Run the full core suite**

```bash
cd ~/oosh && ./test.suite core 1 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -8
```
Expected: one intentional failure only.

- [ ] **Step 4: Commit and push**

```bash
cd ~/oosh && git add docs/boot.md docs/plans/2026-09-10-oosh-boot-tickets.md
git commit -m "docs: the clean-environment guarantee is restored"
git push origin dev
```

- [ ] **Step 5: Platform test — the real gate**

```bash
cd ~/oosh && os platform.test ubuntu_24_04
```
Expected: `rc=0`; the only `✗ FAIL` lines the intentional counter meta-test, once per container user. **In particular `test.ssh.config.woda.portable` must pass 12×** — that is the regression that ended the previous attempt, and this run is what proves these changes are clean of it.

---

## Verification

```bash
# the card, verbatim, in every shell
cd /tmp && for s in sh dash bash "busybox ash"; do
  printf '%-14s ' "$s"
  env -i $s -c ". $HOME/oosh/boot; echo \"\$HOME \$OOSH_DIR \$CONFIG_PATH\""
done

# no env -S anywhere — the Alpine guarantee
grep -rn 'env -S' ~/oosh/init/oosh ~/oosh/boot || echo "clean"

# POSIX parse, all four shells, both files
for f in boot init/oosh; do for s in sh dash bash "busybox ash"; do $s -n ~/oosh/$f || echo "FAIL $s $f"; done; done

./test.suite run config 1 && ./test.suite run install 1 && ./test.suite core 1
os platform.test ubuntu_24_04
```

## Risks

- **`init/oosh` already re-execs twice** — for bash 4+ (`exec "$_newbash" "$0" "$@"`) and via a pre-clone for the curl-pipe path. The clean re-exec must come **first** so those inherit the clean environment; `OOSH_CLEAN_ENV` survives `exec` and stops any loop. Task 3 places it after the branch default and before Phase A — early enough to precede both existing re-execs, late enough that `OOSH_BRANCH` is set and can be carried across.
- **`env -i` wipes `SUDO`, `OOSH_APT_UPDATED` and similar mid-install state.** The re-exec happens before any of it is set, so nothing is lost — but if a future variable must survive, it has to be added to the carry list explicitly, the way `OOSH_BRANCH` is.
- **The previous attempt died on an unexplained WODA regression** (tracker §4d). These changes touch `boot` and `init/oosh` only — not `user`, `ossh` or `line` — but the platform test in Task 4 Step 5 is what decides that, not this reasoning.
