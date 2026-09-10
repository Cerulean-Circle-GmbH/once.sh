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

1. **Anchors.** `OOSH_DIR` is always `~/oosh` and `CONFIG_PATH` is always
   `~/config` — the symlink paths *themselves*, never their resolved targets,
   never from `oo.mode.base.get` (see the rule below). `CONFIG_FILE` =
   `user.env`, `CONFIG` = `CONFIG_PATH` + `CONFIG_FILE`.
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

### The path-anchor rule (and its only exceptions)

**`OOSH_DIR` is always `~/oosh`** — the user's `oosh` symlink, never the branch
worktree it happens to point at, never a `BASH_SOURCE`/`$0` walk, never
`oo.mode.base.get`.

**`CONFIG_PATH` is always `~/config`** — the user's `config` symlink, never the
shared `sharedConfig` directory it points at.

In code those are written `"$HOME/oosh"` / `"$HOME/config"`, because a tilde inside
quotes does **not** expand (`OOSH_DIR="~/oosh"` would be seven literal characters and
break every path built from it). `$HOME/oosh` and `~/oosh` are the same path;
`$HOME/oosh` is the form that is safe in POSIX `sh` and in every quoting context.

```sh
export OOSH_DIR="$HOME/oosh"        # this IS ~/oosh
export CONFIG_PATH="$HOME/config"   # this IS ~/config
```

`CONFIG_PATH` came to the rule second, and for a blunt reason: `boot` was the **only**
place that resolved it. `config`, `log`, `ossh` and `this` all already default to the
literal `$HOME/config`, so the variable had *two different values depending on which
entry point ran* — the shared physical path after `boot`, `~/config` after a bare
`source this` or a mid-install sub-shell. Making `boot` agree with everyone else
removed that split.

#### Why that makes it simple

Because the value is the symlink, `OOSH_DIR` is a **constant**. Switching branches
(`oo mode`) moves only what `~/oosh` *points at*; the variable itself never changes.
A constant needs setting in exactly **one** place, so:

- **`boot` is the single setter** for both. Everything else just reads them.
- For `OOSH_DIR` the one other assignment is a same-literal *fallback* in `this`'s
  top-level block, for contexts that never source `boot` (a bare `source this`, a
  mid-install sub-shell). `CONFIG_PATH` has the same shape of fallback in `this`,
  `log` and `ossh` (`: ${CONFIG_PATH:=$HOME/config}`).
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
`git -C "$OOSH_DIR" …`, every `$OOSH_DIR/<file>` and `$CONFIG_PATH/<file>` path join,
`private.ensure.groupWrite "$CONFIG_PATH/…"`, and
`ln -s "$path/$class" "$OOSH_DIR/external/$class"`. `CONFIG_PATH` needed **no**
point-of-use fixes at all — nothing in the tree does `dirname`/`basename`/prefix
arithmetic on it, only `-d` / `-f` / `-z` tests, which all follow a symlink.

#### Sanctioned exceptions

Each is marked in-code with `# <anchor>-exception: <reason>` — or, for a whole file,
`# <anchor>-exception-file: <reason>` — where `<anchor>` is the variable name
lower-cased with `_` → `-`: `oosh-dir-exception`, `config-path-exception`.

**`OOSH_DIR`:**

| Site | Why |
|---|---|
| `oo.use` | runs one command **from another branch without switching** — a scoped child-process override; no symlink alternative by design |
| `ossh` remote invoke | a string executed on a **remote** host whose `~/oosh` does not exist yet |
| `user.oosh.install` sub-shell | installs **another user** before their `~/oosh` exists |
| `init/oosh` (file-wide) | the installer runs **before** `~/oosh` exists (it may start from a clone or a ZIP); it self-corrects by moving the repo to `$HOME/oosh`, and `unset`s `OOSH_DIR` before handing off to the login shell |

**`CONFIG_PATH`:**

| Site | Why |
|---|---|
| `config file <path>` | the one method whose *job* is to leave `~/config` — it points the session at an arbitrary config file, so `CONFIG_PATH` must come from that path |
| install state 31 (×2) | builds the shared tree **before** `~/config` is a symlink to it, so it must name the target directly |

A self-assignment (`CONFIG_PATH=$CONFIG_PATH`, as in `config`'s and `test.suite`'s
usage banners) is not an assignment site — it is a no-op, and a marker comment there
would be *printed to the user*.

Enforced by **`this.anchor.validate <all|OOSH_DIR|CONFIG_PATH>`**, with
`this.oosh.dir.validate` and `this.config.path.validate` as the per-anchor forms.
(In an oosh shell `this` is itself a function, so call the method directly; as a
script it is `./this anchor.validate`.) One `git grep` per anchor over the tracked
tree (`docs/`, `test/`, `.claude/` and `*.md`/`*.json` excluded), classifying every
assignment as conforming / exception / violation, echoing its verdict to stdout (so
it survives any `LOG_LEVEL`) and returning rc 1 on any violation. Covered by
`test.this` T-OOSH-DIR-* / T-CONFIG-PATH-* — including *planted* violations, so the
guard is proven to fail, and proven to be per-anchor (an `oosh-dir` marker does not
exempt a `CONFIG_PATH` line) — and `test.config` T31 asserts both of `boot`'s
literals then delegates the tree sweep to it.

> A shell opened **before** this change still holds the old resolved `OOSH_DIR` /
> `CONFIG_PATH`. `source ~/oosh/boot`, or simply a new shell, fixes it.

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
(T24 PATH idempotency, T31 the OOSH_DIR/CONFIG_PATH constants, T40 POSIX-sh lint, T44
`OOSH_USER_CONFIG_PATH`, T45 session touch-guard, T47 dash sources a generated
chain).

## See also
- [config.md](config.md) — the two config tiers and `config.save` generation
- [log.md](log.md) — `LOG_NAME`/`LOG_DEVICE`/`LOG_LIVE` and the session chain
- [migration/env-files.md](migration/env-files.md) — the pure-data migration
- [research/review-2026-09-09-boot-loader-pure-env-files.md](research/review-2026-09-09-boot-loader-pure-env-files.md)
