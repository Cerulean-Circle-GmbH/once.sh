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

1. **Anchors.** `OOSH_DIR` is always `~/oosh` — the symlink path *itself*, never
   its resolved target, never from `oo.mode.base.get` (see the rule below).
   `CONFIG_PATH` = `~/config` (still resolved — the rule governs `OOSH_DIR` only),
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

**`OOSH_DIR` is always `~/oosh`** — the user's `oosh` symlink, never the branch
worktree it happens to point at, never a `BASH_SOURCE`/`$0` walk, never
`oo.mode.base.get`.

In code that is written `"$HOME/oosh"`, because a tilde inside quotes does **not**
expand (`OOSH_DIR="~/oosh"` would be seven literal characters and break every path
built from it). `$HOME/oosh` and `~/oosh` are the same path; `$HOME/oosh` is the
form that is safe in POSIX `sh` and in every quoting context.

```sh
export OOSH_DIR="$HOME/oosh"      # this IS ~/oosh
```

#### Why that makes it simple

Because the value is the symlink, `OOSH_DIR` is a **constant**. Switching branches
(`oo mode`) moves only what `~/oosh` *points at*; the variable itself never changes.
A constant needs setting in exactly **one** place, so:

- **`boot` is the single setter.** Everything else just reads it.
- The one other assignment is a same-literal *fallback* in `this`'s top-level block,
  for contexts that never source `boot` (a bare `source this`, a mid-install sub-shell).
- `oo.mode`, `oo.mode.setup` and install state 31 **no longer export it** — repointing
  the symlink *is* the switch. `mode-env.bash` (written by `oo.mode` for the `ooShim`
  to source into the parent shell) now carries only `OOSH_MODE`, `hash -r` and the
  PATH rewrite.
- `ossh.start` uses the same literal. It used to derive from `$0`, which is the *host*
  process whenever `ossh` is **sourced** (`myId`, `config`, `user`, `test.ossh`) and
  so yielded the caller's directory.

#### When you need the physical directory

Resolve it **at that spot** with the portable helper `private.this.path.canonical`
(`this:144`) — never bake the resolution into `OOSH_DIR`. The consumers that do:

| Site | Why it needs the physical path |
|---|---|
| install state 31 `ln -s … oosh` | linking `$OOSH_DIR` itself would create `~/oosh -> ~/oosh` ("Too many levels of symbolic links") |
| install state 31 `OOSH_MODE` | the branch name is `basename` of the *worktree*, not of the symlink |
| `config.init.user` | decides "are we under the shared tree?" with a string-prefix test |
| `promote` | `git worktree list` reports physical paths; a mismatch would stash the same directory twice |
| `oo.mode.base.get` | strategies 3/4 do `dirname`/`basename` — `dirname ~/oosh` is just `$HOME` |

Everything else works fine through the symlink and is deliberately left alone: every
`git -C "$OOSH_DIR" …`, every `$OOSH_DIR/<file>` path join, and
`ln -s "$path/$class" "$OOSH_DIR/external/$class"`.

#### Sanctioned exceptions

Each is marked in-code with `# oosh-dir-exception: <reason>` — or, for a whole file,
`# oosh-dir-exception-file: <reason>`:

| Site | Why |
|---|---|
| `oo.use` | runs one command **from another branch without switching** — a scoped child-process override; no symlink alternative by design |
| `ossh` remote invoke | a string executed on a **remote** host whose `~/oosh` does not exist yet |
| `user.oosh.install` sub-shell | installs **another user** before their `~/oosh` exists |
| `init/oosh` (file-wide) | the installer runs **before** `~/oosh` exists (it may start from a clone or a ZIP); it self-corrects by moving the repo to `$HOME/oosh`, and `unset`s `OOSH_DIR` before handing off to the login shell |

Enforced by **`this.oosh.dir.validate`** (in an oosh shell `this` is itself a
function, so call the method directly; as a script it is `./this oosh.dir.validate`)
— one `git grep` over the tracked tree
(`docs/`, `test/`, `.claude/` and `*.md`/`*.json` excluded), classifying every
assignment as conforming / exception / violation, echoing its verdict to stdout (so
it survives any `LOG_LEVEL`) and returning rc 1 on any violation. Covered by
`test.this` T-OOSH-DIR-* — including a *planted* violation, so the guard is proven to
fail — and `test.config` T31 asserts `boot`'s literal then delegates the tree sweep
to it.

> A shell opened **before** this change still holds its old resolved `OOSH_DIR`.
> `source ~/oosh/boot`, or simply a new shell, fixes it.

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
(T24 PATH idempotency, T31 the OOSH_DIR constant, T40 POSIX-sh lint, T44
`OOSH_USER_CONFIG_PATH`, T45 session touch-guard, T47 dash sources a generated
chain).

## See also
- [config.md](config.md) — the two config tiers and `config.save` generation
- [log.md](log.md) — `LOG_NAME`/`LOG_DEVICE`/`LOG_LIVE` and the session chain
- [migration/env-files.md](migration/env-files.md) — the pure-data migration
- [research/review-2026-09-09-boot-loader-pure-env-files.md](research/review-2026-09-09-boot-loader-pure-env-files.md)
