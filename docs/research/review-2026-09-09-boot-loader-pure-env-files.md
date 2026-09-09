# Review: boot loader + pure-data env files ("config has code!")

**Status:** research — report only, nothing changed.
**Date:** 2026-09-09
**Range reviewed:** `468fe13..070dcc3` on `dev` (14 commits, `8b498f4` → `070dcc3`).
**Triggered by:** request for a meticulous review of the whole boot-loader / pure-env-files effort against the OOSH philosophy, methodology and templates, with OOSH commands preferred over raw bash.
**Method:** manual diff review against `docs/oosh-architecture.md`, `docs/command-creation.md`, `docs/first-principles.md`, `templates/code/*`; empirical checks on this host; `test.suite run config|log|oo 1` in a tmux pane; one completed background correctness scan (`/code-review 468fe13..HEAD high`, angle A — the angle-B removed-behaviour audit and the orchestrator stopped on a session rate limit, so this is **not** a full multi-angle pass).

---

## 0. Commits in scope

| Commit | Change |
|---|---|
| `8b498f4` | feat(boot,config): pure-data env files via a boot loader |
| `fb7006f` | refactor(bootstrap): repoint every entry point to `$OOSH_DIR/boot` |
| `23587b6` | fix(user): guarantee OOSH_DIR on PATH in the `user.oosh.install` WODA sub-shell |
| `ca4abe1` | fix(ossh): self-heal OOSH_DIR + PATH in `ossh.start` |
| `4402f98` / `4eaf28d` | `config list` aggregate view added, then reverted |
| `b3e82fa` | feat(config): user.env holds config values + source chain |
| `10670c0` | refactor(config,boot): don't persist per-user anchors — boot owns them |
| `572c72b` / `d4e6504` | fix(config.save): match variable NAME, keep the `name[_=]` boundary |
| `f9f6905` | feat(log): per-user LOG_NAME + relocate LOG_DEVICE/LOG_LIVE |
| `a42aad4` | feat(config): tier-aware `config list` |
| `56ce683` | refactor: single source of truth `OOSH_USER_CONFIG_PATH` |
| `070dcc3` | feat(config,log): chain per-user `log.session.env` from shared `log.env` |

Files touched: `boot` (new), `config`, `log`, `this`, `user`, `oo`, `os`, `ossh`, `odocker`, `ng/c2`, `ng/2c`, `templates/user/bashrcTemplate`, `.github/workflows/macos-test.yml`, `docs/config.md`, `docs/log.md`, `test/test.config`, `test/test.log`, `test/test.oo`.

---

## 1. What was verified good

| Check | Result |
|---|---|
| `~/config/{user,oosh,log}.env` on this host are pure data | yes — `config validate user\|oosh\|log` → rc 0 for all three |
| `boot` parses under `sh -n`, `dash -n`, `bash -n` | yes |
| Sourcing `boot` twice grows PATH? | no — idempotent |
| New methods registered in c2 completion | `config validate`, `log name`, `log session`, `log session.save` all listed; `config validate <TAB>` offers `user oosh log` |
| Signatures / completion functions per Method Structure Standard | present and correctly named for all four new methods |
| `test.suite run config 1` | 54 / 54 |
| `test.suite run log 1` | 49 / 49 |
| `test.suite run oo 1` | 89 / 89 |

---

## 2. Defects (reproduced on this host unless noted)

### D1. `boot`'s POSIX-sh promise is broken by the generated chain lines

- **Where:** `config.add` (`config:744`, `echo source \$CONFIG_PATH/$file.env`) and the new chain line in `config.save` (`config:596`, `echo 'source $OOSH_USER_CONFIG_PATH/log.session.env'`). `config.validate` accepts both `source` and `.`.
- **What:** `boot` itself is POSIX-clean (T40 lints it), but the *data files it sources* contain `source …`, a bashism. dash/ash return 127 and skip `oosh.env` / `log.env`.
- **Repro:** `env -i HOME=$HOME sh -c '. ~/oosh/boot'` → `user.env: source: not found` ×2; `OOSH_*` / `LOG_*` never load.
- **Real trigger:** `ossh exec <debian-host> …` for any user whose login shell is `/bin/sh` (Debian `useradd` default without `-s`).
- **Also:** `declare -p` emits `$'a\nb'` for values containing newlines; `config.save` passes that through and dash mis-parses it.
- **Fix direction:** emit `. ` instead of `source` in `config.add` / `config.save`; have `config.validate` accept `.` only; extend T40-style test to a *generated* user.env under dash.

### D2. Env files are no longer self-standing, but old callers still source them directly

- **Where:** `log.init` (`log:78`), `err.log` (`log:270`), `ossh.start` (`ossh:3569`), `templates/user/bashrcTemplate:127` (`alias c='source $CONFIG;config list'`).
- **What:** the removed three-line self-anchor header is what made env files sourceable from anywhere. Now `log.env` ends with `source $OOSH_USER_CONFIG_PATH/log.session.env`, so sourcing `user.env` without `boot`/`this` having set that var expands to `source /log.session.env`.
- **Repro:** `env -i HOME=$HOME bash -c 'CONFIG_PATH=$HOME/config; source ~/config/user.env'` → `log.env: line 3: /log.session.env: No such file or directory`, rc 1, `LOG_NAME` empty.
- **Methodology note:** this is exactly the *call-path audit* required before removing defensive code (trace every load-time, REPL and subshell caller; fix upstream first). It was not done for the direct-sourcing callers.

### D3. `boot` does not exist on `testing`, `prod`, `main` — repointed callers dropped their fallback

- **Where:** `ossh.exec` (`ossh:2527`), `ossh.exec.tty` (`ossh:2545`), `user.ssh.rootkey.push` / `.file.push` / `.file.revoke` (`user:132,150,171`), `templates/user/bashrcTemplate:163` (`if [ -f "$HOME/oosh/boot" ]`).
- **Verified:** `git cat-file -e origin/{testing,prod,main}:boot` → none have it.
- **What:** the old lines carried `[ -d ~/oosh ] && export PATH=~/oosh:$PATH`; the new ones set nothing when `boot` is absent.
- **Consequences:**
  - `ossh exec <prod host> "test.suite core 1"` → no PATH / no config → `command not found`.
  - rootkey push: `. /root/oosh/boot` fails, `user` not found, `authorized.keys.update` never runs, ssh rc unchecked → key pushed but never authorised, silently.
  - locally: after the new bashrcTemplate is installed, `oo mode testing|prod` repoints `~/oosh` to a worktree without `boot`; every new shell skips the entire OOSH block (no PATH, no `oo` shim because `c2.install` is gated on `$OOSH_DIR`, no log). Recovery requires knowing to run `~/oosh/oo mode dev` by full path.
- **Interacts with:** D2 (the fallback that would have saved these paths is the thing that was removed).

### D4. Stale `LOG_DEVICE` is persisted and wins over the fresh terminal

- **Where:** `log.session.save` (`log:467`) writes `LOG_DEVICE`; `boot:48` loads it via the `log.env` chain **before** `boot:84` sources `log`, whose default guard is `[ -z "$LOG_DEVICE" ] || [ ! -w "$LOG_DEVICE" ]`; `boot:90` then re-persists it.
- **What:** a pts owned by the same user is writable, so the stale device passes the guard. Every new terminal, tmux pane, `ossh exec`, cron or CI step of that user writes `console.log` / `important.log` output onto the *first* terminal's screen.
- **Repro:** session file holds `LOG_DEVICE="/dev/pts/1"`; `env -i HOME=$HOME bash -c '. ~/oosh/boot; echo $LOG_DEVICE; tty' </dev/null` → `/dev/pts/1`, `not a tty`.
- **Docs say the opposite:** `docs/log.md` claims "LOG_DEVICE is re-derived per session (the saved tty is stale)".
- **Fix direction:** do not persist `LOG_DEVICE` (or unset it before `log`'s default block in `boot`).

### D5. `config.validate` "pure data" guard is trivially bypassed

- **Where:** `config:633` (`'' | [[:space:]]*'#'* | '#'*) continue ;;`) and `config:636` (export regex anchors only up to `=`).
- **What:** `[[:space:]]*'#'*` in a `case` pattern means "one whitespace char, anything, `#`, anything" — any *indented* line containing `#` is treated as a comment. And `export X=` is accepted regardless of what follows `=`.
- **Repro (rc 0 for all):** a file containing `  : ${OOSH_DIR:=/x} # guarded` and `export FOO="$(echo hi)"` validates as pure.
- **Impact:** a regression re-introducing an indented self-anchor with a trailing comment would sail through `config.save`'s warn loop; T30/T37/T38/T41 do not exercise these shapes.
- **Side note:** a legitimate `source $CONFIG_PATH/oosh.env  # chain` is *rejected* (source regex requires `\.env[[:space:]]*$`).
- **Fix direction:** strip leading whitespace before the comment test; reject `$(` / backtick in values.

### D6. Stale bashrc idempotency guards → duplicate boot lines

- **Where:** `config:328` and `user:892` still `grep -q 'config/user.env'`, while the appended fallback line is now `[ -f ~/oosh/boot ] && source ~/oosh/boot`.
- **What:** on hosts without `templates/user/bashrcTemplate`, every re-run of `config init.user` / `user.oosh.install` (both advertised as idempotent repair) appends another boot line; `boot`, `log.session.save` and the `log` re-source then run N times per shell.
- **Fragile-by-accident:** the template-installed case only still passes the guard because a *comment* in the new bashrcTemplate happens to contain `~/config/user.env`.

### D7. `config.list` per-user fallback mutates the global `$CONFIG`

- **Where:** `config:669–671`, after `config.file.check` has already exported `CONFIG` / `CONFIG_FILE`. Not `local`, never restored.
- **Repro:** `source this; source config; config.list log.session; echo $CONFIG` → `~/.config/oosh/log.session.env` for the rest of the shell.
- **Asymmetry:** `config edit log.session` has no fallback → vim creates a *shared* `sharedConfig/log.session.env`, which from then on shadows the per-user file in `config list log.session` for every user, while `log session` shows the real one. In a sourced context `config list log.session` followed by `config add` / `config clean` appends to the per-user file then `rm ~/config/log.session.env` → "No such file".
- **Fix direction:** local view-path variable; make `edit` / `delete` resolve the same way or refuse per-user names.

### Lower-confidence notes (from the scan, not promoted)

- `ossh:3574`: `: ${OOSH_DIR:="$(cd "$(dirname "$0")" …)"}` — `ossh` is sourced from `myId:41`, `user:1433`, `config:834`, `test/test.ossh:42`, where `$0` is the host process; only bites when `OOSH_DIR` is empty.
- `boot:90` is the last statement and an `&&` list → sourcing `boot` returns 1 under dash or when `log.session.save` is undefined. `boot:40` under `env -i sh` with no `HOME` tries `: > /.config/oosh/log.session.env` and prints "cannot create".
- `boot:63–69`: `BASH_FILE=$(command -v bash)` is `/usr/bin/bash` on merged-usr Linux, so `/usr/bin` lands *ahead of* `$OOSH_DIR`. No collision with a top-level oosh script found today; ordering predates this work.

---

## 3. Methodology / philosophy findings

### M1. Bootstrap logic is duplicated instead of owned once by `boot`

| Site | Duplication |
|---|---|
| `ossh.start` (`ossh:3561–3567`) | re-implements boot's OOSH_DIR + PATH block inline |
| `user.oosh.install` (`user:939–944`) | inline `export PATH=…` whose own comment says it "mirrors what `$OOSH_DIR/boot` does" |
| `this.init` (`this:415–431`) | re-sources `$CONFIG` after `boot` already did — contradicts boot's "no double-sourcing" header |
| `.github/workflows/macos-test.yml` | keeps `export PATH="$HOME/oosh:$PATH"` after sourcing boot, under a stale comment about "PATH wiring from oosh.env" |

Each should source `boot` or call one method.

### M2. The "single source of truth" is re-spelled everywhere

`${OOSH_USER_CONFIG_PATH:-$HOME/.config/oosh}` occurs 15× (config 3, log 8, oo 4). The bare literal `.config/oosh` also sits in `boot`, `this`, `templates/user/c2.install:73–74`, `templates/user/ooShim:37`. The fallback exists because `log` can be sourced before `boot`/`this`; the OOSH shape is one private accessor (e.g. `private.config.user.path`) — or `log` requiring `this`.

### M3. Raw bash where an OOSH method exists (or should)

- The `log.env` chain line is appended with a plain `echo >> "$CONFIG_PATH/log.env"`. The comment admits why: "not via `config.add`, which hardcodes `$CONFIG_PATH`". Extending `config.add` with a path/var parameter was the OOSH move.
- `config.save`'s new `declare -p | while read` harvesting loop (`config:547–558`) is a 12-line inline block that reads as `private.config.vars.export <prefix>`.
- `config.validate` shells out `echo "$line" | grep -qE` twice per line instead of bash `[[ =~ ]]` or the `line` script.

### M4. Naming standard violations (camelCase, no underscores)

| Location | Identifier |
|---|---|
| `config.save` | `_line`, `_vn` (also never declared `local`), `_envName` |
| `test/test.oo` | `_llfix`, `_leakpat` |
| `boot` | `_oosh_bashdir` (POSIX, so no `local`, but underscored) |
| `test/test.log` | `SAVED_LOG_NAME`, `GET_OUT`, `SESSION_BODY`, `DEFAULT_BODY` — uppercase non-env vars (follows existing test habit; minor) |

### M5. Template conformance of the new methods

- Neither `config` nor `log` carries the `### new.method` marker, so `oo new.method` (`docs/command-creation.md`, `docs/oo.md`) cannot have been used; the four methods were hand-written. Pre-existing gap, but this work did not restore the marker.
- Only `log.session.save` follows `templates/code/newMethod` (`create.result` + `return $(result)`). `config.validate` uses raw return codes; `log.name` and `log.session` return nothing.
- `config.validate` reports via `error.log` — invisible at `LOG_LEVEL=0`. Per the status-output idiom, a validation verdict should `echo`.

### M6. `boot` is not an OOSH script and its documentation does not exist

- No `boot.start`, no methods, POSIX `sh`. The dash/ash requirement justifies that.
- But: `boot`'s header points at `docs/boot.md`, which **does not exist**. There is no `test/test.boot` — boot tests live in `test/test.config` as T24, T31, T40, T45. Neither `docs/wiki-index.md` nor `docs/oosh-architecture.md` mentions `boot`.

### M7. Documentation drift

| Doc | Stale content |
|---|---|
| `docs/oosh-architecture.md` §Sourcing Order, §user.env Structure | still shows `source $CONFIG → PATH → log.env/oosh.env` and `export CONFIG=…` inside user.env |
| `docs/oosh-architecture.md:680`, `docs/log.md:369–377` | "LOG_LIVE per-user anchor" still says `~/config/log.live.out` and cites `log:22`, `this:215–227`, `config:261` |
| `docs/migration/env-files.md` | still calls the *removed* three-line self-anchor header "the centrepiece of the entire shift" (lines 11–19, 97–101) |
| `docs/log.md` | claims LOG_DEVICE is re-derived per session (see D4) |
| `this:421–425`, `config:535–538` | code comments cite the same dead line numbers |
| `sessions/agent.context.md` | no entry for any of the 14 commits (last entry 2026-05-12) — required by the per-prompt checklist in `CLAUDE.md` |

### M8. Silenced boot failures

`os` (3 sites), `odocker` (2), `ossh` (1), `macos-test.yml` (7) all use `source ~/oosh/boot 2>/dev/null`. This is what hid D1. Same rule as D2: removing/adding suppression requires tracing callers.

---

## 4. Priority

1. **Blocking:** D3 (no `boot` on other branches), D1 (`source` bashism), D2 (direct callers of user.env), D4 (stale LOG_DEVICE).
2. **Next:** D5 (validate bypass), D6 (bashrc guard), D7 (`config.list` global mutation).
3. **Then:** M1–M8, with M6/M7 (docs + `docs/boot.md`) and M2 (single accessor) first.

D1 needs a decision: is `boot`'s POSIX promise real? If yes, `config.add` and the chain line must write `.` not `source`, and a test must source a *generated* user.env under dash.

---

## 5. Repro commands (all read-only)

```bash
# D1
env -i HOME=$HOME sh -c '. ~/oosh/boot; echo "OOSH_MODE=[$OOSH_MODE] LOG_LEVEL=[$LOG_LEVEL]"'
# D2
env -i HOME=$HOME bash -c 'CONFIG_PATH=$HOME/config; source ~/config/user.env; echo rc=$?'
# D3
for b in testing prod main; do git cat-file -e origin/$b:boot 2>/dev/null && echo "$b has boot" || echo "$b NO boot"; done
# D4
env -i HOME=$HOME bash -c '. ~/oosh/boot; echo "LOG_DEVICE=$LOG_DEVICE tty=$(tty)"' </dev/null
# D5
printf '  : ${OOSH_DIR:=/x} # guarded\nexport FOO="$(echo hi)"\n' > /tmp/v.env; ./config validate /tmp/v.env; echo rc=$?
# D7
bash -c 'source ./this >/dev/null 2>&1; source ./config >/dev/null 2>&1; config.list log.session >/dev/null; echo CONFIG=$CONFIG'
# M2
git grep -c 'OOSH_USER_CONFIG_PATH:-' -- config log oo
# M6
ls docs/boot.md test/test.boot
```
