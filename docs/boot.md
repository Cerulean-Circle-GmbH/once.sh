# The `boot` loader

`$OOSH_DIR/boot` is the **single entry point** that turns a bare shell into an
oosh shell. It owns all the bootstrap logic that used to be generated *into* the
config env files, so those files can stay **pure data** (only `export KEY="VALUE"`
and `. x.env` chain lines — see [config.md](config.md) and
[migration/env-files.md](migration/env-files.md)).

## Why it exists

The old design self-anchored inside `~/config/user.env` (it carried
`export OOSH_DIR=…`, `export CONFIG=…`, a `CONFIG_PATH` fallback, and PATH
wiring). That put **code in data files** — the thing the boss explicitly
rejected — and the `~/oosh` self-anchor once produced a symlink self-loop
("Too many levels of symbolic links"). `boot` moves every bit of that logic into
one reviewed script; the env files became pure, portable data.

## Who sources it

Every context that needs an oosh environment sources `boot`:

- the interactive login shell — `templates/user/bashrcTemplate` does `. "$HOME/oosh/boot"`;
- `ossh exec` / `ossh exec.tty` on a remote host;
- the `os platform.test` per-user runners and `odocker` exec;
- CI steps (e.g. `.github/workflows/macos-test.yml`).

## POSIX-sh only (no bashisms)

`boot` must source cleanly under **dash / ash** (a `/bin/sh` login shell,
`ossh exec` on Debian) as well as bash, and under `env -i sh`. So: no `[[ ]]`,
no arrays, and the **env files it sources must use POSIX `.`, not the bash
`source` builtin** (`config.add` / `config.save` emit `.` — see D1 in
[the 2026-09-09 review](research/review-2026-09-09-boot-loader-pure-env-files.md)).
The one bash-only thing — the `log` framework script — is sourced under a
`[ -n "$BASH_VERSION" ]` guard and simply skipped under a bare `sh` (oosh needs
bash 4+ to actually run; the `env -i sh` bootstrap re-execs into bash immediately).

## What it does, in order

1. **Anchors.** `OOSH_DIR` is always `~/oosh`, resolved to its physical target
   (`cd "$HOME/oosh" && pwd -P`) — never the literal symlink string (self-loop),
   never from `oo.mode.base.get`. `CONFIG_PATH` = `~/config` (resolved),
   `CONFIG_FILE` = `user.env`, `CONFIG` = the two joined.
2. **`OOSH_USER_CONFIG_PATH`** = `~/.config/oosh` — the per-user (non-shared)
   config dir (see [config.md § two tiers](config.md)). Single source of truth;
   `log`/`config`/`oo` reference the var, not the literal path.
3. **Touch-guard** the per-user `log.session.env` so the next step's chain can
   source it even on a first-ever shell (it is written properly in step 6).
4. **Source the config.** Only `user.env` — it chains `. $CONFIG_PATH/oosh.env`
   / `log.env` itself, and `log.env` chains `. $OOSH_USER_CONFIG_PATH/log.session.env`.
   One line stands up the whole environment.
5. **PATH.** Put `$OOSH_DIR` and `$OOSH_DIR/ng` on PATH (and `$BASH_FILE`'s dir
   first, so brew bash wins over path_helper's `/bin/bash` on macOS). Colon-
   anchored, so re-sourcing never grows PATH.
6. **Logging primitives** (bash only): source `log`, then `log.session.save`
   writes the per-user `LOG_NAME`/`LOG_DEVICE`/`LOG_LIVE` to `log.session.env`.

### The `OOSH_DIR` rule (and its only exceptions)

`OOSH_DIR` is **always the user's `~/oosh`, physically resolved** — never a
`BASH_SOURCE`/`$0` walk, never `oo.mode.base.get`. There is **one** implementation:

- **bash** → dispatch to `private.this.oosh.dir` (`this`), which wraps the portable
  `private.this.path.canonical "$HOME/oosh"`.
- **pre-`source this` bootstrap** → the identical inline expression
  `"$(cd "$HOME/oosh" 2>/dev/null && pwd -P || echo "$HOME/oosh")"`, used by `boot`
  itself, by `ossh.start`, and emitted into the generated `~/.config/oosh/mode-env.bash`.

Code that repoints `~/oosh` (`oo mode`, `oo mode.setup`, install state 31) **derives
`OOSH_DIR` from the symlink afterwards** rather than assigning the target directly — the
export is still needed because a symlink change cannot update an already-running shell.
`oo.mode.base.get` remains legitimate for *locating worktrees*; it must never feed `OOSH_DIR`.

**Sanctioned exceptions** — each marked in-code with `# oosh-dir-exception: <reason>`:

| Site | Why |
|---|---|
| `oo.use` | runs one command **from another branch without switching** — a scoped child-process override; no symlink alternative by design |
| `ossh` remote invoke | string executed on a **remote** host whose `~/oosh` does not exist yet |
| `user.oosh.install` sub-shell | installs **another user** before their `~/oosh` exists |
| `init/oosh` | the installer runs **before** `~/oosh` exists (may start from a clone/ZIP); it self-corrects by moving the repo to `$HOME/oosh`, and `unset`s `OOSH_DIR` before handing off to the login shell |

Enforced by **`this oosh.dir.validate`** (rc 1 + report on any violation), which is
covered by `test.this` T-OOSH-DIR-VALIDATE and delegated to from `test.config` T31.

## Idempotent

Safe to source repeatedly (mode switches, `exec bash`, nested shells): PATH
additions are colon-guarded and nothing double-applies.

## Cross-branch note

`boot` exists on `dev`. Until it is promoted, `testing`/`prod`/`main` have no
`boot`, so callers that source it carry a fallback: `ossh exec`, the `user`
rootkey pushes, and `bashrcTemplate` do `. ~/oosh/boot || export PATH=~/oosh:…`
(or an `elif [ -d ~/oosh ]` PATH branch) so they still work when `boot` is
absent. (Promotion is owned by the release process, not by this work.)

## It is not an OOSH method-script

`boot` has no `boot.start`, no `noun.verb` methods, and is POSIX `sh` — that is
deliberate (the dash/ash requirement). Its tests live in `test/test.config`
(T24 PATH idempotency, T31 OOSH_DIR resolution, T40 POSIX-sh lint, T44
`OOSH_USER_CONFIG_PATH`, T45 session touch-guard, T47 dash sources a generated
chain).

## See also
- [config.md](config.md) — the two config tiers and `config.save` generation
- [log.md](log.md) — `LOG_NAME`/`LOG_DEVICE`/`LOG_LIVE` and the session chain
- [migration/env-files.md](migration/env-files.md) — the pure-data migration
- [research/review-2026-09-09-boot-loader-pure-env-files.md](research/review-2026-09-09-boot-loader-pure-env-files.md)
