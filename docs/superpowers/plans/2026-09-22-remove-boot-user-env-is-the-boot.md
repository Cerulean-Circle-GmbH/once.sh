# Remove `boot` — `user.env` becomes the boot — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> At execution time copy this file to `docs/superpowers/plans/2026-09-22-remove-boot-user-env-is-the-boot.md` in the repo (this plan-mode path is the drafting location). Work on `dev` in the `dev` worktree (`/home/shared/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/Once.sh/dev`), one commit per task, no promotion (the user owns releases). Run tests in the existing tmux pane `oosh:1.1` (cd to the dev dir first); never pipe oosh test output through `tail`/`head`/`2>&1`.

**Goal:** Delete `$OOSH_DIR/boot` and have every shell get its oosh environment from pure-data lines at the head of `~/config/user.env`, on every supported platform (dash, busybox ash, POSIX-mode bash 3.2 on macOS, bash 4+).

**Architecture:** The anchors `boot` computes are constants (`OOSH_DIR` is always `~/oosh`, `CONFIG_PATH` always `~/config` — boss rulings Ideas #4), so they become `$HOME`-relative `export` lines that `config.save` writes first into `user.env` and `init/oosh` seeds once after the clone. Bash-only work (PATH de-duplication, sourcing `log`, `log.session.env`) moves into `this` and `log`; the only POSIX logic left (`$HOME` recovery) lives in the `/etc/profile.d/oosh.sh` login drop-in. Every former `boot` caller sources `$HOME/config/user.env`.

**Tech Stack:** POSIX sh (the data file and the drop-in must parse under dash/ash/`bash --posix`), bash 4+ (`this`, `log`, `config`, `oo`), OOSH `test.suite` (`./test.suite run <name> 1`, `./test.suite core 1`), `os platform.test <platform> terminal notests`.

**Decisions taken by the user (2026-09-22):** delete `boot` outright (no shim); `$HOME` recovery moves to `/etc/profile.d/oosh.sh` only; platform gate = ubuntu_24_04 + alpine_3_19 + macos.

---

## Context

**Why.** `$OOSH_DIR/boot` (155 lines, POSIX sh, sourced by every shell since 2026-09-08,
`8b498f4`) is the file the boss wants gone: it is invisible in his architecture (his
"ossh boot sequence" is `env -i sh → bash → this`) and it is a fourth place that touches
the bootstrap next to `init/oosh`, `this` and `.bashrc`. The research
(`docs/research/2026-09-22-init-oosh-history-and-boot.md`, § 9) found the one shape that
removes the file without losing platform coverage: because `OOSH_DIR` is always `~/oosh`
and `CONFIG_PATH` is always `~/config` (Ideas #4, T4+T5), the anchors and the PATH prepend
are portable **data** — `$HOME`-relative `export` lines that dash, ash, POSIX-mode bash 3.2
and bash 4+ all read, and that one shared `user.env` serves correctly for every user. This
is also what the boss's Ideas #7 card says: *"config has to bootstrap always all variables
required for a branch version."*

**What `boot` does today and where each duty goes.**

| `boot` step (boot:20-155) | New home |
|---|---|
| 0 · recover `$HOME` (getent → dscl → /etc/passwd) | `/etc/profile.d/oosh.sh` only (login route, Linux); `init/oosh` keeps its own copy |
| 1 · `OOSH_DIR`, `CONFIG_PATH`, `CONFIG_FILE`, `CONFIG` | data lines at the head of `user.env`, written by `config.save`, seeded by `init/oosh` |
| 2 · `OOSH_USER_CONFIG_PATH` | same data line |
| 3 · touch-guard `log.session.env` | `log` creates + sources it itself; `log.env` no longer chains a per-user file |
| 4 · `. user.env` | the caller's one line (`.bashrc`, `ossh exec`, runners, CI) and `this` on cold start |
| 5 · PATH (+ brew-bash first) | data lines in `user.env`; `this` de-duplicates on load |
| 6 · `. log`, `log.session.save` | `.bashrc` and `this`/`log` |
| 7 · exit 0 | n/a |
| T9 `/etc/oosh/boot` symlink + `oo boot.*` | removed; the profile.d drop-in stays, tooling renamed `oo profile.fix` / `oo profile.status` |

**Blast radius measured (2026-09-22):** 205 edit-relevant references in code (`oo` 75, CI
workflow 17, `user` 16, `ossh` 14, `this` 13, `config` 13, `test.suite` 12, `path` 12,
templates 16, `os` 5, `log` 4, `init/oosh` 3, `odocker` 2, `ng/c2` 1, `ng/2c` 1), 345 in
tests (`test.config` 157, `test.oo` 113, `test.platform.boot.system.path.invariant` 47,
`test.path` 11, others small). Three places write `boot` to disk, all in `oo`
(`private.oo.boot.path.ensure`, called by state 34 and `oo boot.fix`). `claudeCode` and
`hiveMind` hits about `session/boot/<role>.md` are agent boot-prompt files — **not** this
loader; leave them alone.

**Load-bearing facts the tasks are built on**

- `this.init` (this:562-640) never sets `CONFIG`/`CONFIG_FILE`; nothing in `this` sources
  `user.env`. Cold starts (`bash -c 'source ~/oosh/this'`, `ossh exec`, non-interactive
  ssh) get their anchors only from `boot` today → `this` must source `user.env` itself.
  `this.init:573` and `ossh.start:3596` already gate on `[ -z "$CONFIG" ]`; that gate is
  the cold-start hook.
- `config.save` no-arg truncates `user.env` and writes exactly two lines
  (config:956-959: `BASH_FILE`, `CONFIG_FILE`), then `config.add` appends the unquoted
  `. $CONFIG_PATH/oosh.env` / `log.env` chain (config:1265-1270), then `config.clean`
  whole-line de-dups (config:1230). The **named** form `config.save <name> <PREFIX>` goes
  through the harvester whose exclusion list (config:615) drops the anchors; T29
  (test.config:725) tests only the named form, so it stays as is.
- `config.validate` (config:1054/1059) accepts `export NAME=…` with `$HOME`/`$PATH`
  expansions and the **unquoted** `. $CONFIG_PATH/x.env` chain; it rejects `$(`, backticks,
  and a quoted `. "…env"`.
- `this.anchor.validate` (this:182-269) `git grep`s the tree for `export OOSH_DIR=` /
  `CONFIG_PATH=` (also inside `echo '…'` strings) and requires the literal `"$HOME/oosh"`
  form or a `# oosh-dir-exception:` / `# config-path-exception:` comment within 5 lines
  above; T31 requires 0 violations.
- `path.validate` (path:71-74) treats the file literally named `boot` as the only
  conforming PATH writer; every other `PATH=` needs `# path-exception:` within 5 lines
  above or `# path-exception-file:` anywhere. `init/oosh` is file-wide exempt.
- `oo mode` (oo:922-959) moves the `~/oosh` symlink and re-saves `oosh.env` only; it never
  touches `user.env`, so the `$HOME`-relative data lines are branch-independent.
- `bashrcTemplate:27-30` returns early for non-interactive shells, so `.bashrc` cannot be
  the cold-start path; `ossh.start` (ossh:3587-3599) already sources `$HOME/config/user.env`
  directly — the working model.
- `log.session.save` (log:491-505) already writes the per-user file; only the touch-create
  (boot:89-90) and the load-time source are missing from `log`. `log.env` today ends with
  `. $OOSH_USER_CONFIG_PATH/log.session.env` (config:977); dash aborts on `.` of a missing
  file, which is the only reason the touch-guard exists.
- `test.suite.config.isolate` (test.suite:871-963) copies every `*.env` from the real tier
  into the fixture. Once `user.env` carries `export CONFIG_PATH="$HOME/config"`, any
  mid-test re-source of it would repoint a test at the real shared tier and the stamp check
  in `test.suite.save.results` (test.suite:135-142) scores a FAIL. `this.init:589-592`
  already saves/restores `PATH` and `LOG_LIVE` across its re-source; the anchors join
  that list (Task 2).
- `. user.env` returns the status of its last command. After Task 3 that is
  `. $CONFIG_PATH/log.env`, whose last line is an `export` → rc 0, so the degrade one-liner
  `[ -f ~/config/user.env ] && . ~/config/user.env || export PATH=…` behaves like the old
  `boot` form.
- `test.suite.boot.anchors.check` (test.suite:810-839) is the one harness behind every
  "boots from an empty environment" assertion (T65/T66/T67, platform INVARIANT-4).

**Naming (OOSH noun.verb):** `oo profile.fix`, `oo profile.status`,
`private.oo.profile.dropin.ensure`, `private.oo.profile.content.get`,
`private.check.root.profile.dropin.installed` (state 34 keeps its number),
`private.config.anchor.lines.get`, `test.suite.anchors.check`.

**Final shape of `~/config/user.env`** (what every task converges on):

```sh
export OOSH_DIR="$HOME/oosh"
export CONFIG_PATH="$HOME/config"
export CONFIG_FILE="user.env"
export CONFIG="$CONFIG_PATH/$CONFIG_FILE"
export OOSH_USER_CONFIG_PATH="$HOME/.config/oosh"
export PATH="$HOME/oosh:$HOME/oosh/ng:$PATH"
export PATH="/opt/homebrew/bin:$PATH"          # only where bash is not in /bin or /usr/bin
export BASH_FILE="/opt/homebrew/bin/bash"
. $CONFIG_PATH/oosh.env
. $CONFIG_PATH/log.env
```

---

## File structure

| File | Responsibility after this plan |
|---|---|
| `config` | **writer** of the boot data: `private.config.anchor.lines.get` (new) emits the head of `user.env`; `config.save` no-arg uses it; `config.validate.required` checks it; the `log.env` per-user chain line is gone |
| `init/oosh` | **seeder**: writes the same lines once, after the clone, when `~/config/user.env` is absent (POSIX duplicate, pinned by test) |
| `this` | **cold-start reader** (`. ~/config/user.env` when `CONFIG` is unset) and **PATH de-duplicator**; anchors preserved across `this.init`'s re-source |
| `log` | **owner** of `$OOSH_USER_CONFIG_PATH/log.session.env` (create + source at load) |
| `templates/user/bashrcTemplate` | interactive login: `. user.env` → `source log` → `log.session.save` |
| `templates/user/profile.d.oosh.sh` | login-shell drop-in: `$HOME` recovery, then `. $HOME/config/user.env` |
| `oo` | `oo profile.fix` / `oo profile.status`, `private.oo.profile.dropin.ensure`, `private.oo.profile.content.get`, state 34 `root.profile.dropin.installed` |
| `path` | `path.validate`: conforming writer = the `# path-writer:`-marked lines in `config` |
| `test.suite` | `test.suite.anchors.check <sourceCommand>` (HOME passed in) |
| `ossh`, `user`, `os`, `odocker`, `ng/c2`, `ng/2c`, `.github/workflows/macos-test.yml` | callers repointed to `~/config/user.env` |
| `test/test.config`, `test/test.oo`, `test/test.install`, `test/test.path`, `test/test.this`, `test/test.platform.shared.config.env.invariant` | retargeted cases |
| `test/test.platform.profile.dropin.invariant` (new), `test/test.platform.boot.system.path.invariant` (deleted) | platform invariant for the drop-in |
| `boot` | **deleted** (Task 8) |
| docs | Task 9 |

**Conventions used in every task**
- A test function ends with `create.result <rc> "<message>"` then `return $(result)` (see test.config:616-627 for the shape); a case is `test.case - "<id>: <what>" <function>` followed by `expect 0 "<message>" "<why>"`.
- Skip-guards sit **outside** the case (`if command -v dash …; then test.case …; expect …; else expect.pass "… skipped"; fi`, test.config:1240-1251), or use a distinct literal result branched on after the case (test.config:1405-1412).
- Fixtures: `local fx; fx=$(test.suite.fixture.make <label>) || { create.result 1 "mktemp failed"; return $(result); }` and `rm -rf "$fx"` before returning.
- New methods carry the docstring shape `name() # <args> # description` on the signature line (`oo method.new` is interactive; adding by hand in that shape is equivalent). Use `oo method.delete <script.method>` for removals — it reports test cases that still reference the method.
- After every task: `./test.suite core 1` in the tmux pane; the summary must show 0 failures (the file's intentional-failure baseline is 1 — read the summary line, compare against the run before the task).
- Commit messages end with `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.

---

### Task 1: `config` emits the boot data lines

**Files:**
- Modify: `config:853-1018` (`config.save`), `config:1099-1141` (`config.validate.required`); add `private.config.anchor.lines.get` directly above `config.save`
- Test: `test/test.config` (new T29b after T29 at :743; T30 extension at :754-774; T31 retarget at :787-812; T44 retarget at :1126-1143)

- [ ] **Step 1: Write the failing tests**

Insert after T29's `expect` (test.config:745):

```bash
test.config.noArgSaveEmitsAnchors() {
  # T29b — the NO-ARG save writes the boot data at the head of user.env, and
  # only in $HOME-relative form (never an absolute path: shared config).
  local fx; fx=$(test.suite.fixture.make t29b) || { create.result 1 "mktemp failed"; return $(result); }
  mkdir -p "$fx/pu"
  ( export CONFIG_PATH="$fx" CONFIG_FILE=user.env CONFIG="$fx/user.env" OOSH_USER_CONFIG_PATH="$fx/pu"
    export BASH_FILE=/opt/homebrew/bin/bash
    : > "$CONFIG"; config.save >/dev/null 2>&1 )
  local l1; l1=$(head -1 "$fx/user.env")
  if [ "$l1" != 'export OOSH_DIR="$HOME/oosh"' ]; then
    rm -rf "$fx"; create.result 1 "first line is not the OOSH_DIR anchor: $l1"; return $(result)
  fi
  local line
  for line in 'export CONFIG_PATH="$HOME/config"' 'export CONFIG_FILE="user.env"' \
              'export CONFIG="$CONFIG_PATH/$CONFIG_FILE"' 'export OOSH_USER_CONFIG_PATH="$HOME/.config/oosh"' \
              'export PATH="$HOME/oosh:$HOME/oosh/ng:$PATH"' 'export PATH="/opt/homebrew/bin:$PATH"' \
              'export BASH_FILE="/opt/homebrew/bin/bash"' '. $CONFIG_PATH/oosh.env' '. $CONFIG_PATH/log.env'; do
    grep -Fxq "$line" "$fx/user.env" || { rm -rf "$fx"; create.result 1 "missing line: $line"; return $(result); }
  done
  if grep -Eq '^export (OOSH_DIR|CONFIG_PATH|CONFIG|OOSH_USER_CONFIG_PATH)="/' "$fx/user.env"; then
    rm -rf "$fx"; create.result 1 "an anchor was persisted as an absolute path"; return $(result)
  fi
  # the chain must FOLLOW the anchors (config.clean preserves order)
  local nA nC; nA=$(grep -nF 'export OOSH_DIR=' "$fx/user.env" | cut -d: -f1); nC=$(grep -nF '. $CONFIG_PATH/oosh.env' "$fx/user.env" | cut -d: -f1)
  rm -rf "$fx"
  if [ "$nA" -lt "$nC" ]; then create.result 0 "anchors head user.env"; else create.result 1 "chain precedes anchors"; fi
  return $(result)
}
test.case - "T29b: no-arg config.save writes the boot data lines at the head of user.env" \
  test.config.noArgSaveEmitsAnchors
expect 0 "anchors head user.env" "user.env IS the boot: anchors, PATH, BASH_FILE, then the chain"

test.config.noArgSaveSkipsDefaultBashDir() {
  # T29c — the brew-bash PATH line is written only when bash lives outside /bin, /usr/bin.
  local fx; fx=$(test.suite.fixture.make t29c) || { create.result 1 "mktemp failed"; return $(result); }
  mkdir -p "$fx/pu"
  ( export CONFIG_PATH="$fx" CONFIG_FILE=user.env CONFIG="$fx/user.env" OOSH_USER_CONFIG_PATH="$fx/pu"
    export BASH_FILE=/usr/bin/bash
    : > "$CONFIG"; config.save >/dev/null 2>&1 )
  local n; n=$(grep -c '^export PATH=' "$fx/user.env"); rm -rf "$fx"
  if [ "$n" = 1 ]; then create.result 0 "one PATH line"; else create.result 1 "expected 1 PATH line, got $n"; fi
  return $(result)
}
test.case - "T29c: no brew-bash PATH line when bash is in a default directory" \
  test.config.noArgSaveSkipsDefaultBashDir
expect 0 "one PATH line" "the second PATH line exists only for a non-default bash (macOS brew)"
```

Retarget T31 (`test.config.ooshDirSelfAnchors`, :787-809): replace the two `grep … "$OOSH_DIR/boot"` lines with

```bash
  local emitted; emitted=$(private.config.anchor.lines.get /bin/bash)
  printf '%s\n' "$emitted" | grep -Fxq 'export OOSH_DIR="$HOME/oosh"' || { create.result 1 "emitter lacks the OOSH_DIR constant"; return $(result); }
  printf '%s\n' "$emitted" | grep -Fxq 'export CONFIG_PATH="$HOME/config"' || { create.result 1 "emitter lacks the CONFIG_PATH constant"; return $(result); }
```
keep the `mode.base.get` negative and the two `this.anchor.validate all "$OOSH_DIR"` → `"0 violations"` checks unchanged. Rename the case text to `"T31: the emitter writes the constants and the tree has 0 anchor violations"`.

Retarget T44 (`test.config.userConfigPathAnchored`, :1126-1139): replace the `grep … "$OOSH_DIR/boot"` line with
```bash
  private.config.anchor.lines.get /bin/bash | grep -Fxq 'export OOSH_USER_CONFIG_PATH="$HOME/.config/oosh"' \
    || { create.result 1 "emitter lacks OOSH_USER_CONFIG_PATH"; return $(result); }
```

Extend T30 (`test.config.userEnvSelfAnchors`, :754-771): after its existing checks add
```bash
  [ "$(head -1 "$fixture/user.env")" = 'export OOSH_DIR="$HOME/oosh"' ] || { create.result 1 "user.env does not start with the OOSH_DIR anchor"; return $(result); }
```

- [ ] **Step 2: Run to verify they fail**

Run (tmux pane): `./test.suite run config 1`
Expected: T29b, T29c, T31, T44 FAIL (`private.config.anchor.lines.get: command not found` / missing lines); T30 FAIL on the head-line check.

- [ ] **Step 3: Add the emitter and wire `config.save`**

Insert above `config.save()` (config:853):

```bash
private.config.anchor.lines.get() # <?bashFile:$BASH_FILE> # emit the head of user.env: the $HOME-relative anchors, the PATH prepend and BASH_FILE — pure data, one line each
{
  # THE boot. Every shell sources these lines (bashrcTemplate, ossh exec, the
  # platform runners, `this` on a cold start). They are DATA: $HOME expands when
  # sourced, so one shared user.env is right for every user on the host.
  # Duplicated verbatim in init/oosh (BEGIN/END userEnvSeed) — POSIX sh cannot
  # call this; test.install T-INIT-SEEDS-USER-ENV pins the two identical.
  local bashFile="${1:-$BASH_FILE}" bashDir
  # oosh-dir-exception: the persisted DATA form of the constant — the value IS
  # "$HOME/oosh", written unexpanded for the sourcing shell to expand.
  echo 'export OOSH_DIR="$HOME/oosh"'
  # config-path-exception: same, for CONFIG_PATH.
  echo 'export CONFIG_PATH="$HOME/config"'
  echo 'export CONFIG_FILE="user.env"'
  echo 'export CONFIG="$CONFIG_PATH/$CONFIG_FILE"'
  echo 'export OOSH_USER_CONFIG_PATH="$HOME/.config/oosh"'
  # path-writer: the ONE sanctioned PATH builder in the tree (path.validate).
  # Grows by one segment per re-source; `this` de-duplicates on load.
  echo 'export PATH="$HOME/oosh:$HOME/oosh/ng:$PATH"'
  # Brew bash must beat the /bin/bash that macOS path_helper appends. Host-wide,
  # so safe in shared config; skipped where bash lives in a default directory.
  bashDir=$(dirname "$bashFile" 2>/dev/null)
  case "$bashDir" in
    /bin|/usr/bin|"") ;;
    # path-writer: the same builder, brew-bash half.
    *) echo "export PATH=\"$bashDir:\$PATH\"" ;;
  esac
  echo "export BASH_FILE=\"$bashFile\""
}
```

Replace config:946-959 (the comment block, `[ -z "$BASH_FILE" ] && …`, and the two-line `{ echo …; echo …; } >$CONFIG`) with:

```bash
    important.log "generating $CONFIG"
    # user.env IS the boot: private.config.anchor.lines.get writes the anchors,
    # the PATH prepend and BASH_FILE as data, then config.add appends the source
    # chain. No loader stands between a shell and this file.
    [ -z "$BASH_FILE" ] && BASH_FILE=$(command -v bash)
    private.config.anchor.lines.get "$BASH_FILE" >$CONFIG
```

In `config.validate.required` (config:1099-1141), after the required-variables loop and before the branch-drift check, add:

```bash
  # The boot data: every anchor line the emitter writes must be present verbatim.
  local anchorLine
  while IFS= read -r anchorLine; do
    case "$anchorLine" in 'export BASH_FILE='*|'export PATH="'/*) continue ;; esac   # host-specific lines
    grep -Fxq "$anchorLine" "$CONFIG_PATH/user.env" 2>/dev/null || missing="$missing anchor:${anchorLine#export }"
  done <<< "$(private.config.anchor.lines.get "${BASH_FILE:-/bin/bash}")"
```
(`missing` is the variable the existing loop already accumulates; keep its reporting.)

- [ ] **Step 4: Run to verify they pass**

Run: `./test.suite run config 1`
Expected: T29b, T29c, T30, T31, T44 PASS. T31's `this.anchor.validate` half passes because the two marker comments sit within 5 lines above each `echo`.

Then: `./this anchor.validate all` → `OK: OOSH_DIR … 0 violations` and `OK: CONFIG_PATH … 0 violations`.
Then: `./path validate` → `INVALID: … 2 violation(s)` — the two `# path-writer:` lines in the emitter. `path.validate` only knows `# path-exception:` until Task 7 teaches it the writer marker; do **not** paper over it with a second marker. `./test.suite run path 1` → `T-PATH-VALIDATE-TREE` FAILS until Task 7. Both are expected and are named in this task's commit message.

- [ ] **Step 5: Run the whole core suite**

Run: `./test.suite core 1`
Expected: failures = baseline + 1 (the T-PATH-VALIDATE-TREE case). Note the exact summary line for the commit.

- [ ] **Step 6: Commit**

```bash
git add config test/test.config
git commit -m "feat(config): user.env is the boot — anchor lines emitted by private.config.anchor.lines.get

config.save (no-arg) writes the \$HOME-relative anchors, the PATH prepend and
BASH_FILE at the head of user.env as pure data; config validate required
checks them. T29b/T29c new, T30/T31/T44 retargeted. path validate reports 2
violations (the emitter) until the sweep learns # path-writer: in the
path.validate task.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `this` sources `user.env` on a cold start and de-duplicates PATH

**Files:**
- Modify: `this:40-49` (fallback), new block after it, `this:589-592` (re-source save/restore)
- Test: `test/test.config` T74 (:588-611), new T74b

- [ ] **Step 1: Write the failing tests**

Replace T74 (`test.config.bootDoubleSourceDoesNotGrowPath`, :595-611) with:

```bash
test.config.userEnvDoubleSourceDedupedByThis() {
  # T74 — user.env's PATH line is data and cannot guard itself; `this` de-dups on load.
  local once twice
  once=$(env -u BASH_FILE HOME="$HOME" bash -c '. "$HOME/config/user.env"; . "$HOME/oosh/this" >/dev/null 2>&1; printf "%s" "$PATH"')
  twice=$(env -u BASH_FILE HOME="$HOME" bash -c '. "$HOME/config/user.env"; . "$HOME/config/user.env"; . "$HOME/oosh/this" >/dev/null 2>&1; printf "%s" "$PATH"')
  local n; n=$(printf '%s' "$twice" | tr ':' '\n' | grep -c -x -F "$HOME/oosh")
  if [ "$once" = "$twice" ] && [ "$n" = 1 ]; then
    create.result 0 "deduplicated"
  else
    create.result 1 "PATH grew or differs: once=[$once] twice=[$twice] count=$n"
  fi
  return $(result)
}
test.case - "T74: sourcing user.env twice, then this, yields one ~/oosh on PATH" \
  test.config.userEnvDoubleSourceDedupedByThis
expect 0 "deduplicated" "the PATH line is data; this de-duplicates whole segments, first wins"

test.config.thisColdStartLoadsUserEnv() {
  # T74b — a bare `source this` with CONFIG unset stands the environment up from user.env.
  local out
  out=$(env -i HOME="$HOME" PATH=/usr/bin:/bin bash -c '. "$HOME/oosh/this" >/dev/null 2>&1; echo "[$CONFIG|$OOSH_DIR|$CONFIG_PATH|$OOSH_USER_CONFIG_PATH]"')
  if [ "$out" = "[$HOME/config/user.env|$HOME/oosh|$HOME/config|$HOME/.config/oosh]" ]; then
    create.result 0 "cold start anchored"
  else
    create.result 1 "got $out"
  fi
  return $(result)
}
test.case - "T74b: a bare source this loads ~/config/user.env when CONFIG is unset" \
  test.config.thisColdStartLoadsUserEnv
expect 0 "cold start anchored" "ossh exec, CI steps and bash -c callers never run bashrc; this is their boot"

test.config.thisReSourceKeepsAnchors() {
  # T74c — this.init's mid-session re-source of $CONFIG must not move an isolated CONFIG_PATH.
  local fx; fx=$(test.suite.fixture.make t74c) || { create.result 1 "mktemp failed"; return $(result); }
  cp "$HOME/config/user.env" "$fx/user.env"
  # Executed (not sourced) `this` takes this.init's re-source branch; the fixture
  # user.env carries `export CONFIG_PATH="$HOME/config"`, which must NOT win.
  local kept; kept=$(env -i HOME="$HOME" PATH=/usr/bin:/bin CONFIG_PATH="$fx" CONFIG="$fx/user.env" CONFIG_FILE=user.env OOSH_USER_CONFIG_PATH="$fx/pu" \
        "$HOME/oosh/this" call this.scope 2>/dev/null | grep -m1 -o "CONFIG_PATH=[^ ]*" | cut -d= -f2)
  [ -n "$kept" ] || kept=$(env -i HOME="$HOME" PATH=/usr/bin:/bin CONFIG_PATH="$fx" CONFIG="$fx/user.env" CONFIG_FILE=user.env OOSH_USER_CONFIG_PATH="$fx/pu" \
        bash -c 'source "$HOME/oosh/this" >/dev/null 2>&1; this.isSourced() { return 1; }; this.init >/dev/null 2>&1; echo "$CONFIG_PATH"')
  rm -rf "$fx"
  if [ "$kept" = "$fx" ]; then create.result 0 "anchors preserved"; else create.result 1 "CONFIG_PATH moved to $kept"; fi
  return $(result)
}
test.case - "T74c: this.init re-source preserves CONFIG_PATH/CONFIG/CONFIG_FILE/OOSH_USER_CONFIG_PATH" \
  test.config.thisReSourceKeepsAnchors
expect 0 "anchors preserved" "isolated tests would otherwise be repointed at the real shared tier"
```

- [ ] **Step 2: Run to verify they fail**

Run: `./test.suite run config 1`
Expected: T74 FAIL (count 2), T74b FAIL (`[|…]` — CONFIG empty), T74c FAIL (CONFIG_PATH = `$HOME/config`).

- [ ] **Step 3: Implement in `this`**

Replace this:40-49 with:

```bash
# The anchors, the env chain and the PATH prepend are DATA in ~/config/user.env
# (config.save writes them, init/oosh seeds them). A context that never sourced
# it — a bare `source this`, an ssh command without bashrc, a mid-install
# sub-shell — loads it here, once, before anything else. Same gate as this.init
# and ossh.start: CONFIG set means someone already stood the environment up
# (or a test isolated it — never override that).
if [ -z "$CONFIG" ] && [ -f "$HOME/config/user.env" ]; then
  . "$HOME/config/user.env"
fi
# oosh-dir-exception: the last-resort fallback when no user.env exists yet
# (mid-install, before init/oosh seeded it): the same literal constant, never a
# BASH_SOURCE/$0 walk, never a resolved physical path.
# path-exception: the same fallback — without $OOSH_DIR on PATH nothing resolves.
if [ -z "$OOSH_DIR" ]; then
  export OOSH_DIR="$HOME/oosh"
  PATH="$OOSH_DIR:$OOSH_DIR/ng:$PATH"
fi

# PATH de-duplication. user.env's `export PATH="$HOME/oosh:…:$PATH"` is data and
# cannot guard itself, so a shell that sources it twice (bashrc + a nested
# `source this`, a re-login inside tmux) carries the prepend twice. Whole
# segments, first occurrence wins, order preserved. Runs once per `source this`.
# path-exception: a REWRITE of the value already there, not a build.
_oosh_new=""; _oosh_seen=":"
while IFS= read -r -d ':' _oosh_seg || [ -n "$_oosh_seg" ]; do
  _oosh_seg=${_oosh_seg%$'\n'}
  [ -z "$_oosh_seg" ] && continue
  case "$_oosh_seen" in *":$_oosh_seg:"*) continue ;; esac
  _oosh_seen="$_oosh_seen$_oosh_seg:"
  _oosh_new="${_oosh_new:+$_oosh_new:}$_oosh_seg"
done <<< "$PATH"
export PATH="$_oosh_new"
unset _oosh_new _oosh_seen _oosh_seg
```

In `this.init`, replace this:589-592 with:

```bash
        # path-exception: SAVE AND RESTORE across a mid-session `source "$CONFIG"`,
        # not a write — the value put back is the one that was there. The four
        # anchors are restored too: user.env now carries them as $HOME-relative
        # data, and a test that isolated CONFIG_PATH must not be repointed at
        # the real shared tier by this re-source.
        local _savedPath="$PATH" _savedLogLive="$LOG_LIVE"
        local _savedConfigPath="$CONFIG_PATH" _savedConfig="$CONFIG" _savedConfigFile="$CONFIG_FILE" _savedUserCfg="$OOSH_USER_CONFIG_PATH"
        source "$CONFIG"
        export PATH="$_savedPath"
        [ -n "$_savedLogLive" ] && export LOG_LIVE="$_savedLogLive"
        export CONFIG_PATH="$_savedConfigPath" CONFIG="$_savedConfig" CONFIG_FILE="$_savedConfigFile"
        [ -n "$_savedUserCfg" ] && export OOSH_USER_CONFIG_PATH="$_savedUserCfg"
```

Update the comment at this:580 (`PATH is built dynamically by $OOSH_DIR/boot and this.path.add`) to `PATH comes from user.env's data line and is de-duplicated at the top of this file`; this:628-630 (`already set by boot or by this scripts top-level fallback`) → `already set by user.env or by this file's top-level fallback`.

- [ ] **Step 4: Run to verify they pass**

Run: `./test.suite run config 1` → T74, T74b, T74c PASS.
Run: `./test.suite run this 1` → no new failures.
Run: `./path validate` → the two `this` sites carry `# path-exception:` (still the 2 emitter violations from Task 1).

- [ ] **Step 5: Core suite, then commit**

Run: `./test.suite core 1` → failures unchanged from Task 1.

```bash
git add this test/test.config
git commit -m "feat(this): cold start from ~/config/user.env, PATH de-dup on load, anchors kept across this.init re-source

A bare source this (ossh exec, CI, bash -c) now loads user.env when CONFIG is
unset — the job boot did for contexts that never run bashrc. PATH is
de-duplicated by whole segment on every load, so the data PATH line may grow
and never hurts. this.init's re-source restores CONFIG_PATH/CONFIG/CONFIG_FILE/
OOSH_USER_CONFIG_PATH like it restores PATH. T74 retargeted, T74b/T74c new.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: `log` owns `log.session.env`; the shared `log.env` stops chaining it

**Files:**
- Modify: `log:1-17` (insert before the live-tty cascade), `log:10-17` comment; `config:969-977` (delete the chain append + its comment)
- Test: `test/test.config` T45 (:1152-1170), T46 (:1178-1206), T71 (:1862)

- [ ] **Step 1: Write the failing tests**

Replace T45's function body (`test.config.bootTouchGuardsSession`, rename to `test.config.logOwnsSessionFile`):

```bash
test.config.logOwnsSessionFile() {
  # T45 — log creates the per-user session file and sources it BEFORE the live-tty
  # cascade (which corrects a stale LOG_DEVICE loaded from it).
  local nTouch nTty
  nTouch=$(grep -nF '[ -f "$OOSH_USER_CONFIG_PATH/log.session.env" ] || : >' "$OOSH_DIR/log" | head -1 | cut -d: -f1)
  nTty=$(grep -nF '_oosh_livetty="$(tty' "$OOSH_DIR/log" | head -1 | cut -d: -f1)
  if [ -n "$nTouch" ] && [ -n "$nTty" ] && [ "$nTouch" -lt "$nTty" ]; then
    create.result 0 "log owns the session file"
  else
    create.result 1 "touch-create at line ${nTouch:-none}, tty cascade at line ${nTty:-none}"
  fi
  return $(result)
}
test.case - "T45: log creates and sources log.session.env before the live-tty cascade" \
  test.config.logOwnsSessionFile
expect 0 "log owns the session file" "dash aborts on . of a missing file, so no shared env file may chain a per-user path"
```

Replace T46's function body (`test.config.logEnvLoadsSession`, keep the name): generate the config into `$fx` as it does today (keep lines :1178-1190), then replace the assertion half with:

```bash
  if grep -q 'log.session.env' "$fx/log.env"; then
    rm -rf "$fx"; create.result 1 "generated log.env still chains the per-user session file"; return $(result)
  fi
  printf 'export LOG_NAME="chained@fixturehost"\n' > "$fx/pu/log.session.env"
  # CONFIG/CONFIG_PATH point at the FIXTURE so `this` (sourced by log) does not
  # cold-start from the real ~/config/user.env and drag the host's session in.
  local got
  got=$(env -i HOME="$HOME" PATH=/usr/bin:/bin OOSH_DIR="$HOME/oosh" CONFIG_PATH="$fx" CONFIG="$fx/user.env" CONFIG_FILE=user.env \
        OOSH_USER_CONFIG_PATH="$fx/pu" LOG_DEVICE=/dev/null bash -c '. "$HOME/oosh/log" >/dev/null 2>&1; echo "$LOG_NAME"')
  rm -rf "$fx"
  if [ "$got" = "chained@fixturehost" ]; then create.result 0 "log loads the session file"; else create.result 1 "LOG_NAME=$got"; fi
  return $(result)
```
Case text: `"T46: log.env carries no per-user chain; log itself loads log.session.env"`.

T71 (:1862): delete the two lines that pre-create `$OOSH_USER_CONFIG_PATH/log.session.env` in the child (they exist only because boot was not run there).

- [ ] **Step 2: Run to verify they fail**

Run: `./test.suite run config 1` → T45 FAIL (no touch line in `log`), T46 FAIL (`log.env` still chains).

- [ ] **Step 3: Implement**

Insert in `log` immediately before line 10 (the `# Ensure LOG_DEVICE points at the LIVE terminal` comment):

```bash
# The per-user session file (LOG_NAME / LOG_DEVICE / LOG_LIVE of the last
# shell). `log` OWNS it: created here when missing — dash aborts on `.` of a
# missing file, so the SHARED log.env must never chain a per-user path — and
# sourced before the live-tty cascade below, which corrects a stale device
# loaded from it. Written by log.session.save.
export OOSH_USER_CONFIG_PATH="${OOSH_USER_CONFIG_PATH:-$HOME/.config/oosh}"
mkdir -p "$OOSH_USER_CONFIG_PATH" 2>/dev/null
[ -f "$OOSH_USER_CONFIG_PATH/log.session.env" ] || : > "$OOSH_USER_CONFIG_PATH/log.session.env"
. "$OOSH_USER_CONFIG_PATH/log.session.env"
```

Change log:11-12 (`… loaded from the chained log.session.env (boot sources it before this runs) …`) to `… loaded from log.session.env, sourced just above …`.

Delete config:969-977 (the nine comment lines and `echo '. $OOSH_USER_CONFIG_PATH/log.session.env' >> "$CONFIG_PATH/log.env"`).

Migration note (no code): an installed host keeps its old chain line until its next `config save`; because `log` has run at least once there, the file exists and the line is harmless. Add one line to `docs/repair-toolkit.md` in Task 9: *"after updating to this change run `config save` once to drop the old per-user chain line from log.env."*

- [ ] **Step 4: Verify**

Run: `./test.suite run config 1` → T45, T46, T71 PASS.
Run: `./test.suite run log 1` → no new failures.
Manual: `env -i HOME=$HOME PATH=/usr/bin:/bin dash -c '. $HOME/config/user.env; echo "$OOSH_MODE"'` → prints the mode, no `log.session.env` error (this host's `log.env` still chains it and the file exists; after `./config save` the line is gone — verify with `grep -c session ~/config/log.env` → 0).

- [ ] **Step 5: Core suite, commit**

```bash
git add log config test/test.config
git commit -m "feat(log,config): log owns the per-user session file; log.env no longer chains it

log creates \$OOSH_USER_CONFIG_PATH/log.session.env when missing and sources
it before the live-tty cascade. config.save stops appending the per-user
chain line to the shared log.env — a dash sourcing the chain can no longer
abort on a missing per-user file. T45/T46 retargeted, T71 pre-create dropped.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: `init/oosh` seeds `~/config/user.env` after the clone

**Files:**
- Modify: `init/oosh` — insert after line 585; rewrite comments at 509-512 and 664-671
- Test: `test/test.install` — new `T-INIT-SEEDS-USER-ENV`; `T-HOME-RECOVERY-NSS` (:722-745) retarget comes in Task 5 (the profile.d template does not exist yet)

- [ ] **Step 1: Write the failing test**

Append to `test/test.install` before `test.suite.save.results` (follow the file's existing `INIT_SCRIPT="$OOSH_DIR/init/oosh"` variable):

```bash
test.install.initSeedsUserEnv() {
  # The seed block in init/oosh is a POSIX duplicate of private.config.anchor.lines.get;
  # extract it by its markers, run it under sh into a fixture HOME, diff against the emitter.
  local fx; fx=$(test.suite.fixture.make seed) || { create.result 1 "mktemp failed"; return $(result); }
  mkdir -p "$fx/config"
  local block; block=$(sed -n '/^# BEGIN userEnvSeed/,/^# END userEnvSeed/p' "$INIT_SCRIPT")
  if [ -z "$block" ]; then rm -rf "$fx"; create.result 1 "no BEGIN/END userEnvSeed block in init/oosh"; return $(result); fi
  printf '%s\n' "$block" | env -i HOME="$fx" BASH_FILE=/opt/homebrew/bin/bash PATH=/usr/bin:/bin sh
  if ! diff <(private.config.anchor.lines.get /opt/homebrew/bin/bash) "$fx/config/user.env" >/dev/null; then
    rm -rf "$fx"; create.result 1 "seeded user.env differs from private.config.anchor.lines.get"; return $(result)
  fi
  echo 'export PLANTED=1' >> "$fx/config/user.env"
  printf '%s\n' "$block" | env -i HOME="$fx" BASH_FILE=/opt/homebrew/bin/bash PATH=/usr/bin:/bin sh
  local kept; kept=$(grep -c PLANTED "$fx/config/user.env"); rm -rf "$fx"
  if [ "$kept" = 1 ]; then create.result 0 "seed matches emitter and is write-once"; else create.result 1 "second run rewrote an existing user.env"; fi
  return $(result)
}
test.case - "T-INIT-SEEDS-USER-ENV: init/oosh seeds ~/config/user.env once, identical to config's emitter" \
  test.install.initSeedsUserEnv
expect 0 "seed matches emitter and is write-once" "the first login after a fresh install boots from this file before state 31 ever runs config save"
```

- [ ] **Step 2: Run to verify it fails**

Run: `./test.suite run install 1` → FAIL: `no BEGIN/END userEnvSeed block`.

- [ ] **Step 3: Implement**

Insert after init/oosh:585 (`[ -n "$LOG_LEVEL_ARG" ] && export LOG_LEVEL="$LOG_LEVEL_ARG"`):

```sh
# ─── Seed ~/config/user.env — the boot data ─────────────────────────────
# The login shell that follows sources ~/config/user.env for its anchors and
# PATH; state 31's `config save` rewrites the file, but the FIRST login needs
# the head before that. Written only when absent (a re-install already has
# ~/config -> sharedConfig with a full user.env). Byte-identical to
# private.config.anchor.lines.get in `config` — POSIX sh cannot call it —
# pinned by test.install T-INIT-SEEDS-USER-ENV.
# BEGIN userEnvSeed
if [ ! -f "$HOME/config/user.env" ]; then
  mkdir -p "$HOME/config"
  _oosh_bashDir=$(dirname "$BASH_FILE" 2>/dev/null)
  {
    echo 'export OOSH_DIR="$HOME/oosh"'
    echo 'export CONFIG_PATH="$HOME/config"'
    echo 'export CONFIG_FILE="user.env"'
    echo 'export CONFIG="$CONFIG_PATH/$CONFIG_FILE"'
    echo 'export OOSH_USER_CONFIG_PATH="$HOME/.config/oosh"'
    echo 'export PATH="$HOME/oosh:$HOME/oosh/ng:$PATH"'
    case "$_oosh_bashDir" in
      /bin|/usr/bin|"") ;;
      *) echo "export PATH=\"$_oosh_bashDir:\$PATH\"" ;;
    esac
    echo "export BASH_FILE=\"$BASH_FILE\""
  } > "$HOME/config/user.env"
  unset _oosh_bashDir
fi
# END userEnvSeed
```
(`init/oosh` is file-wide exempt from both sweeps: `# path-exception-file:` at :509, `# oosh-dir-exception-file:` at :515.)

Rewrite init/oosh:509-512 to:
```sh
# path-exception-file: the installer runs BEFORE ~/config/user.env exists — the
# data file every later shell boots from — so it builds its own PATH (brew bash
# first on macOS, then $OOSH_DIR) and seeds that file below for the login shell.
```
Rewrite init/oosh:664-671 to:
```sh
  # Start a CLEAN login shell: drop the install process's OOSH_DIR/OOSH_MODE so
  # the new shell takes them from ~/config/user.env exactly like every later
  # login does.
```

- [ ] **Step 4: Verify**

Run: `./test.suite run install 1` → `T-INIT-SEEDS-USER-ENV` PASS. `sh -n init/oosh` → silent. `dash -n init/oosh` and `busybox ash -n init/oosh` (where installed) → silent.

- [ ] **Step 5: Core suite, commit**

```bash
git add init/oosh test/test.install
git commit -m "feat(init/oosh): seed ~/config/user.env with the boot data after the clone

Write-once POSIX duplicate of private.config.anchor.lines.get, between
BEGIN/END userEnvSeed markers; T-INIT-SEEDS-USER-ENV diffs the two. The first
login after a fresh install boots from this file before state 31 saves.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: The profile.d drop-in replaces `/etc/oosh/boot`; `oo profile.*`; state 34; the test harness

**Files:**
- Modify: `templates/user/profile.d.oosh.sh` (whole file); `oo:333-399` (`oo.boot.fix` → `oo.profile.fix`), `oo:401-481` (`oo.boot.status` → `oo.profile.status`), `oo:1584-1589` (state list), `oo:1848-1905` (three docstrings), `oo:1910-2014` (`private.oo.boot.path.ensure` → `private.oo.profile.dropin.ensure`), `oo:2016-2032` (`private.oo.boot.profile.content.get` → `private.oo.profile.content.get`), `oo:2609-2627` (state 34 check), `oo:3425-3431` (delete `systemPath` completion), `oo:3434-3441` (keep `profileDir` completion); `test.suite:791-839`
- Test: `test/test.oo` T-BOOTPATH-* block (:2408-3200), `test/test.install` T-HOME-RECOVERY-NSS (:722-745); create `test/test.platform.profile.dropin.invariant`; delete `test/test.platform.boot.system.path.invariant`

- [ ] **Step 1: Write the failing tests**

In `test/test.oo`, delete the six symlink cases `T-BOOTPATH-BOOT-PATH-{CREATES-SYMLINK,SKIPS-WHEN-TARGET-MISSING,NO-NESTING,IDEMPOTENT,REQUIRES-ARGS,FAILS-LOUD}` (their functions and case/expect pairs). Rename the rest with:
```bash
sed -i 's/T-BOOTPATH-/T-PROFILE-/g; s/private\.oo\.boot\.path\.ensure/private.oo.profile.dropin.ensure/g; s/private\.oo\.boot\.profile\.content\.get/private.oo.profile.content.get/g; s/private\.check\.root\.boot\.path\.installed/private.check.root.profile.dropin.installed/g; s/root\.boot\.path\.installed/root.profile.dropin.installed/g; s/oo\.boot\.fix/oo.profile.fix/g; s/oo\.boot\.status/oo.profile.status/g; s/oo boot\.fix/oo profile.fix/g; s/oo boot\.status/oo profile.status/g' test/test.oo
```
Then by hand:
- `T-PROFILE-STATE-34`: the expected list line `34=root.profile.dropin.installed` (sed did it); nothing else in the list moves.
- Every case that passed `<base> <branch> <systemPath> <profileDir>` to the ensure helper now passes only `<profileDir>`; every `oo profile.fix`/`oo profile.status` call passes only `<profileDir>`. Drop assertions about `$systemPath/boot` (symlink, target, readlink); keep assertions about `$profileDir/oosh.sh` (created, 644, idempotent, skipped when the dir is absent, fatal uses bare echo, status echoes at log level 1, status is read-only).
- `T-PROFILE-PROFILED-CONTENT-FROM-TEMPLATE`: assert `private.oo.profile.content.get` output is byte-equal to `templates/user/profile.d.oosh.sh` (`diff` rc 0); no `@SYSTEM_PATH@` anywhere in it.
- `T-PROFILE-PROFILED-CONTENT-IS-GUARDED`: assert the content sources `$HOME/config/user.env` only behind `[ -f "$HOME/config/user.env" ]`, and contains neither `return` nor `exit` outside comments: `grep -vE '^[[:space:]]*#' <content> | grep -Ewq 'return|exit'` must be false.
- Add `T-PROFILE-PROFILED-CONTENT-RECOVERS-HOME`: `env -i PATH=/usr/bin:/bin sh -c ". $OOSH_DIR/templates/user/profile.d.oosh.sh; echo \"[\$HOME]\""` prints `[<passwd home>]` (use `test.suite.home.passwd`), and `env -i PATH=/nonexistent sh -c ". …; echo ALIVE"` prints `ALIVE` (no exit).

In `test/test.install`, T-HOME-RECOVERY-NSS (:722): change the loop `for file in "$INIT_SCRIPT" "$OOSH_DIR/boot"` to `for file in "$INIT_SCRIPT" "$OOSH_DIR/templates/user/profile.d.oosh.sh"`.

Create `test/test.platform.profile.dropin.invariant` (start from `templates/code/newPlatformInvariantTest` for the header; the cases):

```bash
#!/usr/bin/env bash
TEST_CATEGORY=platform
# Post-install invariant: the login-shell drop-in /etc/profile.d/oosh.sh (install
# state 34, `oo profile.fix`) makes `env -i sh -l` come up as an oosh shell.
# Run: ./test.suite run platform.profile.dropin.invariant 1   (inside os platform.test)
level=$1
if [ -z "$level" ]; then level=1; else shift; fi
source this
source test.suite
log.level $level

dropIn="/etc/profile.d/oosh.sh"
pwHome=$(test.suite.home.passwd)

if [ ! -d /etc/profile.d ]; then
  expect.pass "INVARIANT-0 skipped — no /etc/profile.d on this host (macOS); the login route does not exist here"
  test.suite.save.results; return 0 2>/dev/null || exit 0
fi

test.platform.profile.dropin.exists() {
  if [ -r "$dropIn" ]; then create.result 0 "drop-in present"; else create.result 1 "$dropIn missing or unreadable — repair: oo profile.fix"; fi
  return $(result)
}
test.case $level "INVARIANT-1: $dropIn exists and is readable" test.platform.profile.dropin.exists
expect 0 "drop-in present" "state 34 / oo profile.fix writes it"

test.platform.profile.dropin.matchesTemplate() {
  if diff -q "$dropIn" "$OOSH_DIR/templates/user/profile.d.oosh.sh" >/dev/null 2>&1; then create.result 0 "byte-equal to template"; else create.result 1 "drop-in differs from templates/user/profile.d.oosh.sh — repair: oo profile.fix"; fi
  return $(result)
}
test.case $level "INVARIANT-2: drop-in is byte-equal to the template" test.platform.profile.dropin.matchesTemplate
expect 0 "byte-equal to template" "managed file, no substitution"

test.platform.profile.dropin.parses() {
  if sh -n "$dropIn" 2>/dev/null; then create.result 0 "parses under sh"; else create.result 1 "sh -n $dropIn failed"; fi
  return $(result)
}
test.case $level "INVARIANT-3: drop-in parses under /bin/sh" test.platform.profile.dropin.parses
expect 0 "parses under sh" "it runs for every login on the host"

test.platform.profile.dropin.loginRecovers() {
  local out; out=$(cd /tmp && env -i sh -lc 'echo "<[$HOME|$OOSH_DIR|$CONFIG_PATH]>"' 2>/dev/null | tail -1)
  if [ "$out" = "<[$pwHome|$pwHome/oosh|$pwHome/config]>" ]; then create.result 0 "env -i sh -l recovers"; else create.result 1 "got $out"; fi
  return $(result)
}
test.case $level "INVARIANT-4: env -i sh -l comes up anchored via the drop-in" test.platform.profile.dropin.loginRecovers
expect 0 "env -i sh -l recovers" "HOME derived from the password database, then ~/config/user.env sourced"

test.platform.profile.dropin.dataRoute() {
  local bad; bad=$(test.suite.anchors.check '. "$HOME/config/user.env"')
  if [ -z "$bad" ]; then create.result 0 "every shell anchors from user.env"; else create.result 1 "failures:$bad"; fi
  return $(result)
}
test.case $level "INVARIANT-5: . \$HOME/config/user.env anchors sh, dash, ash, bash and busybox" test.platform.profile.dropin.dataRoute
expect 0 "every shell anchors from user.env" "the data route needs only HOME"

test.suite.save.results
```

`git rm test/test.platform.boot.system.path.invariant`.

- [ ] **Step 2: Run to verify they fail**

Run: `./test.suite run oo 1` → every `T-PROFILE-*` case FAILS (`oo.profile.fix: command not found` etc.). `./test.suite run install 1` → T-HOME-RECOVERY-NSS FAILS (template has no `homeRecovery` block yet).

- [ ] **Step 3: Implement — the template**

Replace `templates/user/profile.d.oosh.sh` entirely:

```sh
# oosh — host-wide login-shell bootstrap. MANAGED FILE: written by install
# state 34 (root.profile.dropin.installed) and by `oo profile.fix`; both
# overwrite it. Source: templates/user/profile.d.oosh.sh (oosh repo).
#
# /etc/profile loops `for i in /etc/profile.d/*.sh`, so this is what makes
# `env -i sh -l` come up as an oosh shell. POSIX sh; it runs for EVERY login
# on this host: never `exit` (closes the login), never `return` (not every
# /etc/profile sources this from a function), every path guarded.
#
# 1. $HOME — `env -i` drops it and every anchor hangs off it. Derive it:
#    getent (Linux/NSS) -> dscl (macOS) -> /etc/passwd. On failure fall
#    through silently; the user gets a plain login shell. DELIBERATELY
#    DUPLICATED in init/oosh, which runs before oosh exists (test.install
#    T-HOME-RECOVERY-NSS pins the two blocks identical).
# BEGIN homeRecovery
if [ -z "$HOME" ] || [ ! -d "$HOME" ]; then
  _oosh_user=$(id -un 2>/dev/null)
  _oosh_home=""
  if [ -n "$_oosh_user" ]; then
    if command -v getent >/dev/null 2>&1; then
      # `head -1` is load-bearing: getent prints one line PER NSS SOURCE, so a
      # user present in both `files` and LDAP/SSSD yields two. Without it the
      # cut returns two lines, _oosh_home is non-empty so both fallbacks are
      # skipped, and `[ -d ]` on the two-line string fails — refusing while
      # holding a perfectly good home on line 1.
      _oosh_home=$(getent passwd "$_oosh_user" 2>/dev/null | head -1 | cut -d: -f6)
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
  fi
  unset _oosh_user _oosh_home
fi
# END homeRecovery
# 2. An oosh user has ~/config/user.env — the anchors, the env chain and the
#    PATH prepend, as data. A user without one is left exactly as found.
if [ -n "${HOME-}" ] && [ -f "$HOME/config/user.env" ]; then
  . "$HOME/config/user.env"
fi
:
```
**T-HOME-RECOVERY-NSS diffs the block between the markers against `init/oosh`'s.** `init/oosh:75-85` prints a diagnostic and `exit 1` on failure; the drop-in must not. Make the two identical by changing **init/oosh's** block to the template's shape (silent fall-through, no exit) and moving init/oosh's diagnostic+`exit 1` to just **after** its `# END homeRecovery` line:
```sh
if [ -z "$HOME" ] || [ ! -d "$HOME" ]; then
  echo "oosh install: \$HOME is unset or not a directory, and no home could be" >&2
  echo "oosh install: derived from getent, dscl or /etc/passwd." >&2
  echo "oosh install: re-run with HOME set, e.g. HOME=/home/you sh init/oosh" >&2
  exit 1
fi
```
(and drop the `echo "… recovered as $HOME"` line inside the block, so the two blocks match byte-for-byte).

- [ ] **Step 4: Implement — `oo`**

Delete `oo.boot.fix`, `oo.boot.status`, `private.oo.boot.path.ensure`, `private.oo.boot.profile.content.get`, `private.check.root.boot.path.installed`, `oo.parameter.completion.systemPath` (use `oo method.delete oo.boot.fix` etc. — it lists remaining test references; there must be none after Step 1). Add in their places:

```bash
oo.profile.fix() # <?profileDir:/etc/profile.d> # install or repair the login-shell drop-in <profileDir>/oosh.sh that makes `env -i sh -l` come up as an oosh shell; idempotent
{
  # Successor of the T9 `oo boot.fix`: there is no /etc/oosh/boot any more —
  # the boot data lives in ~/config/user.env and the drop-in sources it after
  # recovering $HOME. NOT auto-triggered (see docs/repair-toolkit.md).
  local profileDir="${1:-/etc/profile.d}"
  local needsSudo=""
  [ -d "$profileDir" ] && needsSudo=$(private.oo.path.sudo.get "$profileDir")
  if [ -n "$needsSudo" ] && ! command -v sudo >/dev/null 2>&1; then
    # bare echo: a fatal instruction must survive every LOG_LEVEL / LOG_DEVICE
    echo "oo profile.fix: $profileDir needs root — you are '${USER:-?}' and no usable sudo was found. Re-run as root (e.g. \`su - -c 'oo profile.fix'\`) or install sudo." >&2
    create.result 1 "oo profile.fix: neither root nor sudo"
    return $(result)
  fi
  private.oo.profile.dropin.ensure "$profileDir"
  return $(result)
}
oo.profile.fix.completion.profileDir() { oo.parameter.completion.profileDir "$@"; }

oo.profile.status() # <?profileDir:/etc/profile.d> # read-only report on the login-shell drop-in; rc 0 when healthy
{
  # Status-command idiom: the ANSWER goes to plain stdout, never behind
  # console.log. Read-only: it diagnoses, `oo profile.fix` repairs.
  local profileDir="${1:-/etc/profile.d}"
  local dropIn="$profileDir/oosh.sh" rc=0
  echo "oosh login-shell drop-in: $dropIn"
  if [ ! -d "$profileDir" ]; then
    echo "  state:   N/A — this host has no $profileDir (macOS); the login route does not exist here"
    echo "  use:     . ~/config/user.env      # any shell, HOME set"
  elif [ ! -r "$dropIn" ]; then
    echo "  state:   MISSING — /etc/profile globs $profileDir/*.sh and finds no oosh line"
    echo "  effect:  \`env -i sh -l\` does NOT come up as an oosh shell on this host"
    echo "  fix:     oo profile.fix"; rc=1
  elif ! grep -Fq 'config/user.env' "$dropIn" 2>/dev/null; then
    echo "  state:   STALE — present, but it does not source ~/config/user.env"
    echo "  fix:     oo profile.fix"; rc=1
  else
    echo "  state:   OK"
    echo "  use:     env -i sh -l             # login shells recover by themselves"
  fi
  if [ "$rc" = 0 ]; then create.result 0 "login-shell drop-in healthy"; else create.result 1 "login-shell drop-in needs oo profile.fix"; fi
  return $(result)
}
oo.profile.status.completion.profileDir() { oo.parameter.completion.profileDir "$@"; }
```

```bash
private.oo.profile.dropin.ensure() # <?profileDir:/etc/profile.d> # ensure <profileDir>/oosh.sh is the login-shell drop-in from templates/user/profile.d.oosh.sh; idempotent; skips (rc 0) when <profileDir> does not exist (macOS)
{
  local profileDir="${1:-/etc/profile.d}"
  local dropIn="$profileDir/oosh.sh"
  # macOS has NO /etc/profile.d: its /etc/profile runs path_helper and globs
  # nothing — a directory created there would never be read. Graceful SKIP.
  if [ ! -d "$profileDir" ]; then
    info.log "private.oo.profile.dropin.ensure: no $profileDir on this host — skipping the login-shell drop-in (macOS has none)"
    create.result 0 "login-shell drop-in skipped (no $profileDir)"
    return $(result)
  fi
  local sudoProfile; sudoProfile=$(private.oo.path.sudo.get "$profileDir")
  private.oo.profile.content.get | $sudoProfile tee "$dropIn" >/dev/null
  $sudoProfile chmod 644 "$dropIn"
  if [ -r "$dropIn" ] && grep -Fq 'config/user.env' "$dropIn" 2>/dev/null; then
    create.result 0 "login-shell drop-in ensured at $dropIn"
  else
    create.result 1 "failed to write the login-shell drop-in $dropIn (readable=$([ -r "$dropIn" ] && echo y || echo n)) — \`env -i sh -l\` will not recover on this host"
    error.log "$RESULT"
  fi
  return $(result)
}

private.oo.profile.content.get() # # emit the POSIX-sh /etc/profile.d drop-in, verbatim from templates/user/profile.d.oosh.sh
{
  local template="$OOSH_DIR/templates/user/profile.d.oosh.sh"
  if [ ! -r "$template" ]; then
    create.result 1 "private.oo.profile.content.get: template missing: $template"
    error.log "$RESULT"
    return $(result)
  fi
  cat "$template"
}

private.check.root.profile.dropin.installed() # # state 34 — install the login-shell drop-in /etc/profile.d/oosh.sh
{
  # Runs in the 30-lane as root. Dedicated state so a failure reads
  # "halted at [34] root.profile.dropin.installed".
  private.oo.profile.dropin.ensure
  return $(result)
}
```

State list oo:1584-1589: replace the comment and the line with
```bash
  # The login-shell drop-in /etc/profile.d/oosh.sh. Inserted HERE, after the
  # last named 30-lane state and before the `40` jump, so it lands at 34 and
  # no existing state NUMBER moves. Pinned by T-PROFILE-STATE-34 in test/test.oo.
  state.add root.profile.dropin.installed         silent
```
Docstrings oo:1848, 1861, 1893: replace "oo boot.fix" with "oo profile.fix" and "state 34 (root.boot.path.installed)" with "state 34 (root.profile.dropin.installed)".

`oo.tmp.cleanup.testing` (oo:2731): `source ~/oosh/boot` → `source ~/config/user.env`.

- [ ] **Step 5: Implement — `test.suite`**

Replace `test.suite.boot.anchors.check` (:811-834) and its completion (:836-839):

```bash
test.suite.anchors.check() # <sourceCommand> # run <sourceCommand> (e.g. `. "$HOME/config/user.env"`) under env -i HOME=<passwd home> in sh, dash, ash, bash and busybox ash; print nothing when every shell yields this user's anchors and the caller survives, else one `shell=>output` per failure
{
  # The one harness behind every "stand the environment up from user.env"
  # assertion (test.config T65, test.platform.profile.dropin.invariant). HOME is
  # PASSED: the data route cannot derive it — that is the login drop-in's job,
  # asserted separately through `env -i sh -l`.
  local sourceCommand="$1"
  local home expected bad="" shell out
  home=$(test.suite.home.passwd)
  expected="[$home|$home/oosh|$home/config]"
  for shell in sh dash ash bash; do
    command -v "$shell" >/dev/null 2>&1 || continue
    out=$(cd /tmp && env -i HOME="$home" "$shell" -c "$sourceCommand; echo \"[\$HOME|\$OOSH_DIR|\$CONFIG_PATH]\"" 2>&1 | tail -1)
    [ "$out" = "$expected" ] || bad="$bad $shell=>$out"
  done
  if command -v busybox >/dev/null 2>&1; then
    out=$(cd /tmp && env -i HOME="$home" busybox ash -c "$sourceCommand; echo \"[\$HOME|\$OOSH_DIR|\$CONFIG_PATH]\"" 2>&1 | tail -1)
    [ "$out" = "$expected" ] || bad="$bad busybox-ash=>$out"
  fi
  # SOURCED, never executed: the calling shell must survive it.
  out=$(cd /tmp && env -i HOME="$home" sh -c "$sourceCommand; echo STILL-HERE" 2>&1 | tail -1)
  [ "$out" = "STILL-HERE" ] || bad="$bad shell-did-not-survive=>$out"
  echo "$bad"
}
test.suite.anchors.check.completion.sourceCommand() {
  echo ". \"\$HOME/config/user.env\""
  echo ". /etc/profile.d/oosh.sh"
}
```
Update the comment at test.suite:81 and :1172 accordingly. `test.suite.home.passwd` stays.

- [ ] **Step 6: Verify**

Run: `./test.suite run oo 1` → all `T-PROFILE-*` PASS. `./test.suite run install 1` → T-HOME-RECOVERY-NSS and T-INIT-SEEDS-USER-ENV PASS. `sh -n templates/user/profile.d.oosh.sh` silent. `./oo profile.status` prints a report (on this host: OK if state 34 ran the old T9 — it will say STALE until `sudo ./oo profile.fix` is run; do NOT run it here, the platform gate covers it).
`./test.suite run platform.profile.dropin.invariant 1` on this host: INVARIANT-1..3 may FAIL until `oo profile.fix` is run; that is expected for a platform test on a pre-change host — record it, do not fix the host.

- [ ] **Step 7: Core suite, commit**

```bash
git add templates/user/profile.d.oosh.sh oo test.suite init/oosh test/test.oo test/test.install test/test.platform.profile.dropin.invariant
git rm test/test.platform.boot.system.path.invariant
git commit -m "feat(oo,templates,test.suite): login drop-in sources ~/config/user.env; oo profile.fix/status replace boot.fix/status

/etc/oosh/boot and its symlink machinery are gone. The profile.d drop-in
recovers \$HOME (block byte-identical to init/oosh's) and sources the boot
data. State 34 is root.profile.dropin.installed (number unchanged).
test.suite.anchors.check replaces boot.anchors.check (HOME passed in).
T-BOOTPATH-* → T-PROFILE-*; the six symlink cases and the /etc/oosh/boot
platform invariant are deleted; test.platform.profile.dropin.invariant is new.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Repoint every caller to `~/config/user.env`

**Files:**
- Modify: `templates/user/bashrcTemplate:163-201`; `config:347-356`; `user:294,316,341,1085-1091,1138-1140,1168`; `ossh:479,915,2561-2566,2584-2586,3587-3599` (comments); `os:352,363-365,380,382,392,394`; `odocker:1103,1107`; `ng/c2:746`; `ng/2c:580`; `.github/workflows/macos-test.yml` (7 sites)
- Test: `test/test.config` T49 (:1285-1302); `test/test.platform.shared.config.env.invariant` (:81, :132-151)

- [ ] **Step 1: Write the failing tests**

Replace T49's function (`test.config.bootAbsentFallbacks` → `test.config.userEnvDegradePaths`):

```bash
test.config.userEnvDegradePaths() {
  # T49 — every remote/one-liner caller sources user.env first and degrades to a
  # bare PATH prepend when it is missing; the two .bashrc writers guard on the
  # new hook; and no live `oosh/boot` reference is left anywhere in code.
  local f
  for f in ossh user; do
    grep -Eq '\[ -f ~/config/user\.env \] && \. ~/config/user\.env \|\| export PATH=~/oosh' "$OOSH_DIR/$f" \
      || { create.result 1 "$f lacks the user.env degrade one-liner"; return $(result); }
  done
  grep -Eq 'elif \[ -d "\$HOME/oosh" \]' "$OOSH_DIR/templates/user/bashrcTemplate" \
    || { create.result 1 "bashrcTemplate lost its degrade branch"; return $(result); }
  for f in config user; do
    grep -Fq "grep -q 'config/user.env'" "$OOSH_DIR/$f" \
      || { create.result 1 "$f's .bashrc writer does not guard on config/user.env"; return $(result); }
  done
  local hits
  hits=$(git -C "$OOSH_DIR" grep -nE 'oosh/boot|OOSH_DIR/boot|etc/oosh' -- \
           ':!docs' ':!test' ':!old' ':!*.md' ':!claudeCode' ':!hiveMind' ':!restore' 2>/dev/null | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#')
  if [ -n "$hits" ]; then create.result 1 "live boot references remain: $hits"; return $(result); fi
  create.result 0 "user.env is the entry point everywhere"
  return $(result)
}
test.case - "T49: every caller sources ~/config/user.env (degrading to a PATH prepend); no live boot reference remains" \
  test.config.userEnvDegradePaths
expect 0 "user.env is the entry point everywhere" "ossh exec, the rootkey pushes, bashrc and the .bashrc writers"
```

In `test/test.platform.shared.config.env.invariant`: INVARIANT-4 (:132-143) becomes `env -i HOME="$HOME" sh -c '. "$HOME/config/user.env" 2>&1 1>/dev/null'` must print nothing; INVARIANT-4b (:145-151) reads `OOSH_MODE` after `. "$HOME/config/user.env"`. Add INVARIANT-1b after INVARIANT-1:
```bash
test.platform.userEnvHeadIsAnchors() {
  local n=0 line
  for line in 'export OOSH_DIR="$HOME/oosh"' 'export CONFIG_PATH="$HOME/config"' 'export CONFIG_FILE="user.env"' 'export CONFIG="$CONFIG_PATH/$CONFIG_FILE"' 'export OOSH_USER_CONFIG_PATH="$HOME/.config/oosh"'; do
    n=$((n + 1))
    [ "$(sed -n "${n}p" "$cfgPath/user.env")" = "$line" ] || { create.result 1 "line $n of user.env is not: $line (run: config save)"; return $(result); }
  done
  create.result 0 "user.env heads with the anchors"; return $(result)
}
test.case $level "INVARIANT-1b: user.env begins with the five anchor lines" test.platform.userEnvHeadIsAnchors
expect 0 "user.env heads with the anchors" "the shared config IS the boot; a host installed before this change needs one config save"
```
Update the comment at :81 (`because boot sources them under dash/ash`) → `because every shell sources them, dash and ash included`.

- [ ] **Step 2: Run to verify it fails**

Run: `./test.suite run config 1` → T49 FAIL (`ossh lacks the user.env degrade one-liner`).

- [ ] **Step 3: Implement — the templates and the two `.bashrc` writers**

`templates/user/bashrcTemplate`, replace lines 163-201 with:

```bash
if [ -f "$HOME/config/user.env" ]; then
    # user.env IS the boot: the anchors, the env chain and the PATH prepend are
    # data in it (config.save writes them, init/oosh seeds them). Then the
    # bash-only pieces: `log` (which sources `this` — PATH de-dup, dispatch)
    # gives console.log / info.log / error.log and owns the per-user session
    # file, and log.session.save records this shell's LOG_NAME/DEVICE/LIVE.
    . "$HOME/config/user.env"
    [ -f "$OOSH_DIR/log" ] && source "$OOSH_DIR/log"
    type log.session.save >/dev/null 2>&1 && log.session.save >/dev/null 2>&1

    if ! [ -f $CONFIG_PATH/color.env ]; then
        line init
    fi
    source $CONFIG_PATH/setup.color.env

    # sudo-chain cwd guard: if this shell was started via `sudo su` /
    # `sudo -s` (without `-` / `-i`), PWD was inherited from the invoker
    # and likely points at /home/<other-user> which is confusing ("why
    # am I in bob's home as root?") and often not fully readable.
    # Detect the situation via SUDO_USER being set and PWD ≠ HOME, and
    # cd to the target's HOME — same intent as `sudo -i` / `su -`.
    if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "$USER" ] \
       && [ -n "$HOME" ] && [ "$PWD" != "$HOME" ] \
       && [ -d "$HOME" ]; then
        cd "$HOME"
    fi
elif [ -d "$HOME/oosh" ]; then
    # user.env absent: a host mid-install, or a config that predates the
    # anchor lines (run `config save`). Degrade: ~/oosh on PATH so oo/os/ossh
    # still resolve. path-exception: the sanctioned degrade branch.
    case ":$PATH:" in
        *":$HOME/oosh:"*) : ;;
        *) export PATH="$HOME/oosh:$HOME/oosh/ng:$PATH" ;;
    esac
fi
```

`config:347-356` — the `bash -c` string inside `config.init.user` becomes:

```bash
    if ! grep -q 'config/user.env' \"$targetHome/.bashrc\" 2>/dev/null; then
      if [ -f \"$sharedOosh/templates/user/bashrcTemplate\" ]; then
        cp \"$sharedOosh/templates/user/bashrcTemplate\" \"$targetHome/.bashrc\"
      else
        printf '\n# oosh environment\n[ -f ~/config/user.env ] && . ~/config/user.env\n' >> \"$targetHome/.bashrc\"
      fi
    fi
```

`user:1085-1091` — the `bash -c` string inside `user.oosh.install` becomes:

```bash
    if [ -f ~/oosh/templates/user/bashrcTemplate ]; then
      cp ~/oosh/templates/user/bashrcTemplate ~/.bashrc
    elif ! grep -q 'config/user.env' ~/.bashrc 2>/dev/null; then
      printf '\n# oosh environment\n[ -f ~/config/user.env ] && . ~/config/user.env\n' >> ~/.bashrc
    fi
```
(The old `grep -q 'oosh/boot'` guard must go in both, or a `.bashrc` carrying the old template line is never re-templated.)

- [ ] **Step 4: Implement — remote and runner strings**

Exact replacements (each preceded by the existing `# path-exception:` comment reworded `boot` → `user.env`):

| site | new |
|---|---|
| `ossh:2566`, `ossh:2586` | `private.ossh.ssh [-tt] "$toHost" "[ -f ~/config/user.env ] && . ~/config/user.env \|\| export PATH=~/oosh:~/oosh/ng:\$PATH; $@"` |
| `user:294`, `user:316`, `user:341` | same one-liner prefix in each `ssh … "…"` string |
| `ossh:479` | `"bash -c '[ -f ~/config/user.env ] && . ~/config/user.env; source ~/config/current.state.machine.env 2>/dev/null && [ \"\$state\" = \"99\" ]'"` |
| `odocker:1103` | `docker exec "$container" bash -c 'source ~/config/user.env 2>/dev/null; echo "$OOSH_DIR"'` |
| `odocker:1107` | `docker exec "$container" bash -c "source ~/config/user.env 2>/dev/null; LOG_LEVEL=0 \$OOSH_DIR/user group.add $socketGroup $u"` |
| `os:352` | `… 'cd /root 2>/dev/null \|\| cd /tmp; source /root/config/user.env 2>/dev/null; test.suite core 1'` |
| `os:380,382,392,394` | `source ~/config/user.env 2>/dev/null` in place of `source ~/oosh/boot 2>/dev/null` |
| `os:363-365` comment | "bashrcTemplate early-exits for non-interactive shells, so the runner sources ~/config/user.env itself (the boot data) or `test.suite: command not found` fires" |
| `ng/c2:746`, `ng/2c:580` | **delete the line** — the `source …/this` on the line above loads user.env on a cold start (Task 2) |
| `.github/workflows/macos-test.yml` :165-168, :199-200, :241-242, :268-269, :278-279, :291-292, :304-305 | `[ -f ~/config/user.env ] && . ~/config/user.env \|\| export PATH=~/oosh:~/oosh/ng:$PATH` with the marker comment reworded |
| `.github/workflows/macos-test.yml:284` | `ossh exec macos "sudo -H /opt/homebrew/bin/bash -c 'source /var/root/config/user.env 2>/dev/null; test.suite core 1'"` |
| `user:366` | delete the commented-out line |
| comment-only sites `ossh:915`, `ossh:3587-3599`, `user:1138-1140`, `user:1168`, `user:1207`, `config:265,593,662,803,1066,1228,1266`, `log:46,100,102`, `promote:918`, `claudeCode:601-614`, `hiveMind:1786`, `path:129,178,191,215,240`, `test.suite:81,1172` | reword `boot` → `user.env` / "the anchor lines in user.env"; `docs/boot.md` → `docs/config.md § user.env is the boot` |

- [ ] **Step 5: Verify**

Run: `./test.suite run config 1` → T49 PASS. `./test.suite run ossh 1`, `run user 1`, `run os 1`, `run odocker 1` → no new failures. `bash -n templates/user/bashrcTemplate` silent.
Manual on this host: open a new tmux window (`./otmux new t6`) → prompt shows `[oosh ]`, `type console.log` → function, `echo $PATH | tr : '\n' | grep -c oosh$` → 1 (this host's `.bashrc` is the template? if the host `.bashrc` still says `. "$HOME/oosh/boot"`, that is expected until `config init.user` re-templates it — note it, do not edit the host `.bashrc` by hand).

- [ ] **Step 6: Core suite, commit**

```bash
git add templates/user/bashrcTemplate config user ossh os odocker ng/c2 ng/2c log promote claudeCode hiveMind path test.suite .github/workflows/macos-test.yml test/test.config test/test.platform.shared.config.env.invariant
git commit -m "refactor(callers): every entry point sources ~/config/user.env instead of boot

bashrcTemplate, the two .bashrc writers, ossh exec/exec.tty, the rootkey
pushes, the platform runners, odocker exec, ng/c2, ng/2c and the macOS CI
workflow all boot from the data file; the degrade-to-PATH branches stay.
T49 retargeted and now guards against any live boot reference returning.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: `path.validate` learns the new writer

**Files:**
- Modify: `path:8` (docstring), `path:10-19` (rule text), `path:71-74` (the `boot)` arm), `path:97-109` (error texts), `path:129` (usage)
- Test: `test/test.path` `T-PATH-VALIDATE-BOOT` (:359-369) → `T-PATH-VALIDATE-WRITER`; `T-PATH-VALIDATE-FILE-MARKER` message (:400); `path.usage` case (:279)

- [ ] **Step 1: Write the failing test**

Replace the `test.path.validateAcceptsBoot` function and its case/expect (test.path:354-369) with two cases in the file's own shape (`private.test.path.validate.clear`, then `private.test.path.validate.plant <file> <lines…>` which writes the file into `$PV_FIXTURE`, git-adds it and echoes the verdict):

```bash
test.path.validateAcceptsConfigWriter() {
  private.test.path.validate.clear
  local out
  out=$(private.test.path.validate.plant config '#!/usr/bin/env bash' \
        '  # path-writer: the ONE sanctioned PATH builder' \
        "  echo 'export PATH=\"\$HOME/oosh:\$HOME/oosh/ng:\$PATH\"'")
  case "$out" in
    *"OK:"*"1 conforming"*) create.result 0 "config writer conforms" ;;
    *)                      create.result 1 "expected 1 conforming, got: $out" ;;
  esac
  return $(result)
}
test.case $level "T-PATH-VALIDATE-WRITER: the # path-writer: line in config is the one conforming site" \
  test.path.validateAcceptsConfigWriter
expect 0 "config writer conforms" "PATH is written as data by private.config.anchor.lines.get; that emitter declares itself"

test.path.validateRejectsImpostorWriter() {
  private.test.path.validate.clear
  local out
  out=$(private.test.path.validate.plant other '#!/usr/bin/env bash' \
        '  # path-writer: pretending' \
        '  export PATH="/x:$PATH"')
  case "$out" in
    *"INVALID:"*"1 violation"*) create.result 0 "impostor rejected" ;;
    *)                          create.result 1 "expected 1 violation, got: $out" ;;
  esac
  return $(result)
}
test.case $level "T-PATH-VALIDATE-WRITER-ONLY-CONFIG: # path-writer: outside config is a violation" \
  test.path.validateRejectsImpostorWriter
expect 0 "impostor rejected" "only config may claim the writer marker"
```

Also change the `T-PATH-VALIDATE-REJECTS` case text and message (test.path:351-353) from `outside boot` / `boot is the single builder; everything else declares itself` to `outside config's emitter` / `config's emitter is the single builder; everything else declares itself`, and `T-PATH-VALIDATE-FILE-MARKER`'s expected message (:400) from `"an installer that runs before ~/oosh exists cannot delegate to boot"` to `"an installer that runs before ~/config/user.env exists cannot read the data PATH"` (the same string must change in `path`'s error text at :97-109 and in `init/oosh:509`'s marker comment so the test keeps matching).

- [ ] **Step 2: Run to verify it fails**

Run: `./test.suite run path 1` → T-PATH-VALIDATE-WRITER FAIL (`0 conforming`), T-PATH-VALIDATE-TREE still FAIL (the 2 emitter violations from Task 1).

- [ ] **Step 3: Implement**

Replace path:71-74 (`# boot IS the rule …` through `esac`) with — placed **after** `prevLine` is computed (move the `prevLine` block, path:87-92, above this if it is not already):

```bash
    # THE writer declares itself: `# path-writer:` on one of the five lines
    # above marks the sanctioned PATH builder — private.config.anchor.lines.get
    # in `config`, which writes PATH as DATA into user.env. Only `config` may
    # carry the marker; anywhere else it is a violation with a better excuse.
    if printf '%s' "$prevLine" | grep -qE '#[[:space:]]*path-writer:'; then
      case "$file" in
        config) conforming=$((conforming + 1)); continue ;;
        *) error.log "path.validate: $file:$lineNo claims # path-writer: — only config may"
           violations=$((violations + 1)); continue ;;
      esac
    fi
```
Docstring path:8 → `# <?treeRoot:$OOSH_DIR> # verify every PATH assignment in the tree is config's data writer (# path-writer:) or carries a # path-exception: marker; rc 1 + report on any violation`. Rule text path:10-19 → "THE RULE (docs/config.md § user.env is the boot): `config` writes PATH as data (`private.config.anchor.lines.get`, marked `# path-writer:`); `this` de-duplicates it on load; every other assignment is a violation unless it carries `# path-exception: <reason>` …". Error texts path:97-109 and usage path:129: `boot` → `config` wording as above.

- [ ] **Step 4: Verify**

Run: `./path validate` → `OK: PATH in … — 0 violation(s), 2 conforming, N exception(s)`. `./test.suite run path 1` → all PASS including T-PATH-VALIDATE-TREE. `./test.suite core 1` → failures back to the pre-Task-1 baseline.

- [ ] **Step 5: Commit**

```bash
git add path test/test.path
git commit -m "feat(path): path.validate recognises config's # path-writer: data lines as the PATH builder

boot was the conforming site by filename; now the emitter in config declares
itself and only config may. T-PATH-VALIDATE-BOOT → T-PATH-VALIDATE-WRITER
(+ the impostor case). Tree back to 0 violations.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Delete `boot`; retarget or delete the remaining `boot`-shaped tests

**Files:**
- Delete: `boot`
- Test: `test/test.config` T40 (:1001-1026), T50 (:1314-1336), T51 (:1350-1377), T52 (:1385-1412), T65 (:1420-1440), T66 (:1468-1500) delete, T67 (:1524-1571) delete, T68 (:1605-1657) delete, T70 (:1773-1834); `test/test.this` :426, :438 messages

- [ ] **Step 1: Retarget the tests (they go red first because they still name `boot`; after the edits they must pass with `boot` still on disk, then `git rm boot` must not change the result)**

Helper used by several cases — add once above T40:
```bash
test.config.generatedUserEnv() { # <fx> # config.save into <fx>, echo the path of the generated user.env
  mkdir -p "$1/pu"
  ( export CONFIG_PATH="$1" CONFIG_FILE=user.env CONFIG="$1/user.env" OOSH_USER_CONFIG_PATH="$1/pu" OOSH_MODE=dev
    : > "$CONFIG"; config.save >/dev/null 2>&1 )
  echo "$1/user.env"
}
```

- T40 (`test.config.fallbackPrecedesSourceLines` → `test.config.userEnvIsPosix`): generate into a fixture; `sh -n "$f"`, `busybox ash -n "$f"` (if present), the bashism grep from :1016 against `$f` **and** against `$OOSH_DIR/templates/user/profile.d.oosh.sh`; message `"user.env and the drop-in parse under POSIX sh"`.
- T50 (`bootExitsZeroOnSuccess` → `userEnvExitsZero`): for `sh dash bash` + `busybox ash`: `env -i HOME="$HOME" <shell> -c ". \"$f\""` rc 0 where `$f` is the generated fixture user.env **whose chain files exist** (the fixture has `oosh.env`/`log.env` from `config.save`); message `"sourcing user.env exits 0"`.
- T51 (`bootRefusesWhenHomeUndiscoverable` → `dropinFallsThroughWithoutHome`): `env -i PATH=/nonexistent sh -c ". $OOSH_DIR/templates/user/profile.d.oosh.sh; echo \"[\$HOME]\"; echo SHELL-ALIVE"` → last two lines `[]` and `SHELL-ALIVE`; keep the `"skipped: no sh on PATH"` idiom; message `"drop-in leaves HOME unset and the shell alive"`.
- T52 (`ashBootsCorrectly` → `ashSourcesUserEnv`): `env -i HOME="$HOME" busybox ash -c ". \"$f\"; echo \"D=[\$OOSH_DIR] C=[\$CONFIG_PATH]\"; case \":\$PATH:\" in *\":\$HOME/oosh:\"*) echo P=yes;; *) echo P=no;; esac"` → `D=[$HOME/oosh] C=[$HOME/config]` and `P=yes`; keep the `"skipped: busybox absent"` idiom.
- T65 (`bootRecoversHome` → `userEnvAnchorsEveryShell`): `bad=$(test.suite.anchors.check '. "$HOME/config/user.env"')` empty → `"every shell anchors from user.env"`; drop the stale-HOME half (that is INVARIANT-4 of the new platform test).
- T66, T67, T68: delete (documented one-liner to `…/oosh/boot`, symlink-to-boot, and the `ENV=` route are gone).
- T70 (`bootSurvivesPosixModeBash` → `userEnvSurvivesPosixModeBash`): `env -i HOME="$HOME" bash --posix -c ". \"$f\"; echo RC=\$?; echo \"<[\$HOME|\$OOSH_DIR|\$CONFIG_PATH|\$OOSH_USER_CONFIG_PATH]>\"; echo ALIVE"` → `RC=0`, all four anchors, `ALIVE`, no `not a valid identifier`; keep assertion 5 as: `env -i HOME="$HOME" PATH=/usr/bin:/bin bash -c ". \"$f\"; . \"$HOME/oosh/log\" >/dev/null 2>&1; type log.device >/dev/null 2>&1 && echo LOGFN=yes"` → `LOGFN=yes`.
- `test/test.this` :426 and :438 messages: `— re-source $HOME/oosh/boot in a new shell` → `— re-source ~/config/user.env in a new shell (config save if it lacks the anchors)`.

- [ ] **Step 2: Run with `boot` still present**

Run: `./test.suite run config 1` → T40, T50, T51, T52, T65, T70 PASS; T66/T67/T68 gone. `./test.suite run this 1` PASS.

- [ ] **Step 3: Delete the file**

```bash
git rm boot
```
Then: `git grep -nE 'oosh/boot|OOSH_DIR/boot|etc/oosh|\bboot\b' -- ':!docs' ':!test' ':!old' ':!*.md' ':!claudeCode' ':!hiveMind' ':!restore'` → only the `session/boot` agent-prompt hits (none of those paths are in the list) — expected output: **empty**. Also `grep -rn 'boot' test.suite path this config log oo ossh user os odocker init templates .github` → comments referring to the *history* only (e.g. "successor of the T9 oo boot.fix"); no path.

- [ ] **Step 4: Verify the whole tree**

Run: `./test.suite core 1` → failures = the pre-Task-1 baseline. `./this anchor.validate all` → 0 violations ×2. `./path validate` → 0 violations. `./test.suite run config 1`, `run oo 1`, `run install 1`, `run path 1`, `run this 1` all PASS.
Manual, this host (still has the old `.bashrc` line until re-templated):
```
env -i HOME=$HOME PATH=/usr/bin:/bin bash -c '. ~/config/user.env; oo version'      # prints a version
env -i HOME=$HOME PATH=/usr/bin:/bin dash -c '. ~/config/user.env; echo $OOSH_DIR'  # /home/hannesn/oosh
```
Then `config init.user hannesn` (or by hand) so this host's `.bashrc` is re-templated; open a new tmux window → `[oosh ]` prompt.

- [ ] **Step 5: Commit**

```bash
git add test/test.config test/test.this
git commit -m "feat!: remove boot — user.env is the boot

The POSIX loader is gone. Anchors, PATH and the env chain are data at the
head of ~/config/user.env (config.save writes, init/oosh seeds); this loads it
on a cold start and de-duplicates PATH; log owns the per-user session file;
the /etc/profile.d drop-in recovers \$HOME for env -i sh -l. T40/T50/T51/T52/
T65/T70 retargeted, T66/T67/T68 deleted with the routes they proved.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 9: Docs, then the platform gate

**Files:**
- Delete: `docs/boot.md`
- Modify: `docs/config.md`, `docs/oosh-architecture.md`, `docs/repair-toolkit.md`, `docs/install-bootstrap.md`, `docs/wiki-index.md`, `docs/oo.md`, `docs/migration/env-files.md`, `docs/plans/2026-09-10-oosh-boot-tickets.md`, `docs/plans/2026-09-14-fixed-system-boot-path.md`, `docs/research/review-2026-09-09-boot-loader-pure-env-files.md`, `docs/puml/bootstrap.sequence/2026-09-22-v2-review.md`

- [ ] **Step 1: Write the new home of the two surviving rules**

`docs/config.md` — new section `## user.env is the boot` (replacing § at :108-109 and :201): the final-shape block from Context, who writes it (`config.save`, `init/oosh` seed), who reads it (`.bashrc`, `this` cold start, `ossh exec`, runners, the drop-in), the PATH-writer rule (moved from boot.md:204-251: `config` writes PATH as data with `# path-writer:`, `this` de-duplicates, everything else `# path-exception:`), and the ordering constraint (anchors → BASH_FILE → chain, `config.clean` preserves it). Update :65 (session file: `log` creates it), :74-76 (anchors: data lines), :212-214 (owner column: `config` / `this`), :361 (ordering), :497 (POSIX `.` because dash sources the file directly). Add to § Required variables: "`config validate required` also checks the five anchor lines verbatim."
`docs/oosh-architecture.md` — new section `## The anchors are data` (moved from boot.md:98-203: the path-anchor rule, `this anchor.validate`, the sanctioned exceptions — `oo.use`, the `ossh` remote invoke, `user.oosh.install`'s sub-shell, `init/oosh` file-wide, plus the two `config` emitter lines and `this`'s fallback). Rewrite :269 (login shell boots via `. ~/config/user.env` from bashrcTemplate), :285, :365 (`this.path.add` row: "a bootstrap helper used by the executed-script branch of `this`; PATH itself is data in user.env, de-duplicated by `this`"), :434-435, :455, :509.
`docs/repair-toolkit.md` — `oo boot.fix` → `oo profile.fix` / `oo profile.status` throughout (:19, :82-87, :94-109, :115-129, :137-138); recovery-commands table becomes: `env -i sh -l` (Linux, the drop-in), `. ~/config/user.env` (any shell, `HOME` set), `config save` (a host from before this change: adds the anchor lines and drops the old `log.session.env` chain from log.env), `config init.user <user>` (re-templates `.bashrc`).
`docs/install-bootstrap.md` — :4 and :13 rewritten (the duplicated block's twin is now the profile.d drop-in); § 108 gains "and seeds user.env" with the Task 4 block.
`docs/wiki-index.md` — :46 label (drop "superseded pre-`boot` version"), :87-96 → a 6-line "user.env is the boot" summary linking config.md; every `boot.md` link → `config.md#userenv-is-the-boot`.
`docs/oo.md` — :110 (non-method scripts: `debug` only), :240 link, `### oo.boot.fix`/`### oo.boot.status` → `### oo.profile.fix`/`### oo.profile.status` with the new signatures, state table row 34 `root.profile.dropin.installed | /etc/profile.d/oosh.sh`.
`docs/migration/env-files.md` — banner: "superseded twice: by `boot` (2026-09-08) and then by the anchor lines in `user.env` (2026-09-22). The `$HOME`-relative form avoids the absolute-path leak this page describes."
`docs/plans/2026-09-10-oosh-boot-tickets.md` — one change-log row; T3, T8, T9 cards get a first line `> **Superseded 2026-09-22** — see docs/superpowers/plans/2026-09-22-remove-boot-user-env-is-the-boot.md`; T4+T5 unchanged.
`docs/plans/2026-09-14-fixed-system-boot-path.md`, `docs/research/review-2026-09-09-boot-loader-pure-env-files.md` — same superseded banner at the top, no rewrite.
`docs/puml/bootstrap.sequence/2026-09-22-v2-review.md` — add to § 5: "group 3 of the drawio must be redrawn: `.bashrc → user.env → log`; not done in this change."
`git rm docs/boot.md`. Then `grep -rn 'boot\.md' docs CLAUDE.md README.md` → empty.

- [ ] **Step 2: Commit the docs**

```bash
git add docs
git commit -m "docs: user.env is the boot — boot.md folded into config.md and oosh-architecture.md; T3/T8/T9 marked superseded

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

- [ ] **Step 3: Push and run the platform gate (in order; stop at the first red)**

`git push origin dev` (the containers clone from origin/dev). Then in the tmux pane, one at a time:

```
./os platform.test ubuntu_24_04 terminal notests
```
Inside the container shell: `cat ~/config/user.env | head -6` shows the anchors; `env -i sh -l -c 'echo "<[$HOME|$OOSH_DIR|$CONFIG_PATH]>"'` prints the root anchors; `oo profile.status` → OK; `./test.suite run platform.profile.dropin.invariant 1` and `run platform.shared.config.env.invariant 1` PASS; `exit`. Then the full run: `./os platform.test ubuntu_24_04` → PASS for root, oosh-user, bash-user, test.
```
./os platform.test alpine_3_19 terminal notests     # busybox ash login shell
```
Same checks (`busybox ash -l -c …`). Then `./os platform.test alpine_3_19` → PASS.
```
./os platform.test macos
```
(GitHub Actions; the workflow was repointed in Task 6.) Expect green; `oo profile.status` there reports `N/A` (no `/etc/profile.d`), and `macos-test.yml`'s root step uses `/var/root/config/user.env`.

- [ ] **Step 4: Record the result**

Append the three platform results (PASS lines with counts) to the change-log row in `docs/plans/2026-09-10-oosh-boot-tickets.md`, commit `docs(plans): boot removal — platform gate ubuntu/alpine/macos green`, push. Do **not** promote to testing/prod; report back to the user with the three summary lines and the commit list.

---

## Verification (end to end)

1. Static: `./this anchor.validate all` → 0 violations twice; `./path validate` → 0 violations, 2 conforming; `git grep -n 'oosh/boot\|etc/oosh' -- ':!docs' ':!test' ':!old'` → empty; `sh -n init/oosh templates/user/profile.d.oosh.sh` silent; `bash -n this log config oo path templates/user/bashrcTemplate` silent.
2. Host: `./test.suite core 1` at the pre-change baseline; `./test.suite run config 1`, `run oo 1`, `run install 1`, `run path 1`, `run this 1`, `run log 1`, `run ossh 1`, `run user 1` green.
3. Shells: `env -i HOME=$HOME PATH=/usr/bin:/bin <sh|dash|bash --posix|busybox ash> -c '. ~/config/user.env; echo "<[$HOME|$OOSH_DIR|$CONFIG_PATH|$OOSH_USER_CONFIG_PATH]>"'` prints the four anchors under each; `bash -c '. ~/config/user.env; . ~/config/user.env; . ~/oosh/this >/dev/null; echo $PATH'` shows `~/oosh` once.
4. Cold start: `env -i HOME=$HOME PATH=/usr/bin:/bin bash -c 'source ~/oosh/this >/dev/null 2>&1; echo $CONFIG'` → `/home/<user>/config/user.env`.
5. Platforms: ubuntu_24_04, alpine_3_19, macos PASS (Task 9 step 3), including `platform.profile.dropin.invariant` on the two Linux containers.
6. Fresh install (in the ubuntu container's `terminal notests` shell, as root): `cat ~/config/install.log` shows the hand-off; `~/config/user.env` head is the seed; after login the prompt is `[oosh ]`.

## Out of scope (recorded, not done)

- The drawio (`docs/puml/bootstrap.sequence/Bootstrap Sequence v2.drawio`) group 3 still draws `.bashrc → boot`; redraw is a separate diagram task.
- Pre-existing defects noticed: `this.anchor.validate` loses `$?` through an assignment (this:297-298); `oo mode`'s branch-name PATH repair (oo:946) is a permanent no-op for conforming shells and could be deleted.
- Hosts installed before this change keep working (their `.bashrc` still sources a now-missing `boot` → the `elif` degrade puts `~/oosh` on PATH); `config save` + `config init.user <user>` bring them to the new shape. That is a repair-toolkit note, not a migration script.
