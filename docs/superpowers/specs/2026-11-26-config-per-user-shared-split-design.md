# Config split: per-user `CONFIG_PATH` and shared `SHARED_CONFIG_PATH`

**Status:** design, awaiting review.
**Date:** 2026-11-26
**Ticket:** Split config into per-user and shared parts. Each user keeps their own
`config/user.env`; shared imports are read from a new `SHARED_CONFIG_PATH`.
User-specific log settings stay in `CONFIG_PATH`.

**Acceptance criteria**

1. `SHARED_CONFIG_PATH` exists and is exported.
2. Shared imports load from it.
3. `user.env` stays per user.
4. One user cannot read another user's config.

---

## 1. Current state

`~/config` (`$CONFIG_PATH`) is a symlink to one site-wide `sharedConfig`
directory. Everything in it is shared: `user.env`, `oosh.env`, `log.env`,
`odocker.env`, `os.commands.env`, the colour set, `lineFormat.env`, state and
hivemind files. The per-user half lives in `$HOME/.config/oosh` and is chained
from those shared files (`user.session.env`, `oosh.session.env`,
`log.session.env`).

That means the main `user.env` is shared too, and the only reason it is safe is
that its per-user values are reduced to `$HOME` constants and chained session
files. A second user can read it, and every user writes the same site-wide
files.

The anchor rule (`docs/config.md` § The anchor rule) says `CONFIG_PATH` is
always the `~/config` symlink itself and `OOSH_DIR` is always `~/oosh`, both
constants.

## 2. Decisions

| Decision | Choice |
|---|---|
| Layout | `~/config` becomes a real per-user directory; a new `~/sharedConfig` symlink points at the existing shared tree |
| Shared path | `SHARED_CONFIG_PATH` is the constant `"$HOME/sharedConfig"` and becomes a third path anchor |
| Log settings | **All** `LOG_*` settings are per-user in `CONFIG_PATH/log.env`; no `log.env` in the shared tree is imported |
| Other per-user files | `user.session.env` (PATH) and `oosh.session.env` (`OOSH_MODE`) stay in `$HOME/.config/oosh` |
| Shared data files | Every shared entry except `user.env`/`log.env` is symlinked into `~/config`, so existing `$CONFIG_PATH/<file>` readers keep working |
| Migration | Automatic on the first shell per user, with an idempotent, locked, reversible migration |
| Save targets | `user.env` and `log.env` -> `CONFIG_PATH`; `oosh.env` and custom `<name>.env` -> `SHARED_CONFIG_PATH` |

## 3. Target layout

```
$HOME/.config/oosh/              per-user state, unchanged
  user.session.env               real PATH, no $
  oosh.session.env               OOSH_MODE

$HOME/config/                    CONFIG_PATH, real dir, mode 0700
  user.env                       real file, 0600, per-user
  log.env                        real file, 0600, all LOG_*
  oosh.env        -> ../sharedConfig/oosh.env
  odocker.env     -> ../sharedConfig/odocker.env
  os.commands.env -> ../sharedConfig/os.commands.env
  color.env, color.names.env, bold.color.names.env,
  setup.color.env, lineFormat.env -> symlinks
  hivemind.*, stateMachines/, completion.*, ssh.info.env -> symlinks

$HOME/sharedConfig -> <existing sharedConfig tree>
                                 SHARED_CONFIG_PATH, symlink in the user's home
```

Generated `$HOME/config/user.env`:

```sh
export CONFIG_PATH="$HOME/config"
export SHARED_CONFIG_PATH="$HOME/sharedConfig"
export CONFIG_FILE="user.env"
export CONFIG="$HOME/config/user.env"
export BASH_FILE="/usr/bin/bash"
. $SHARED_CONFIG_PATH/oosh.env
. $CONFIG_PATH/log.env
. $SHARED_CONFIG_PATH/odocker.env
. $HOME/.config/oosh/user.session.env
```

Generated `$HOME/config/log.env`:

```sh
export LOG_LEVEL="3"
export LOG_LEVEL_RESET="3"
export LOG_NAME="me@host"
export LOG_LIVE="$HOME/.config/oosh/log.live.out"
export LOG_DEVICE="/dev/pts/3"   # only when a file was chosen with `log device <file>`
```

`LOG_DEVICE` is still omitted when it is a terminal, exactly as
`log.session.save` does today. No line chains another file.

Invariants:

- `CONFIG_PATH` remains the `~/config` constant; the anchor rule is unchanged
  for it. Its **target** is now private.
- `SHARED_CONFIG_PATH` is always `"$HOME/sharedConfig"`, written as the
  `$HOME` constant in env files.
- `user.env` and `log.env` are always real per-user files: never symlinks, never
  copies of shared files.
- Every other shared entry is visible through `~/config` as a symlink.
- `~/config` is `0700` and its real files are `0600`.
- Shared files stay readable by the shared group; they are site-wide, not
  "another user's config".

## 4. Variables and the anchor rule

Add `SHARED_CONFIG_PATH` to:

- `this` file scope and `this.init`: `: ${SHARED_CONFIG_PATH:=$HOME/sharedConfig}`,
  `export SHARED_CONFIG_PATH`.
- `templates/user/bashrcTemplate`'s su re-anchor block: an inherited
  `SHARED_CONFIG_PATH` that does not name this `HOME` is dropped together with
  the other anchors.
- `this.anchor.validate`'s pair list: `SHARED_CONFIG_PATH:sharedConfig`.
- The anchor validator's constant forms: `"$HOME/sharedConfig"`,
  `$HOME/sharedConfig`, `~/sharedConfig`.
- `config.save`'s anchor writer: `export SHARED_CONFIG_PATH="$HOME/sharedConfig"`.
- `docs/config.md` § The anchor rule and the environment-variable table.
- `this.anchor.validate` / `this.config.path.validate` tests and
  `test/test.config`'s expected constants.

`config file <path>` and `config-path-exception` keep working. A new
`shared-config-path-exception:` marker is accepted by the validator.

## 5. Import and resolution rules

### `user.env`

`user.env` is per-user. It keeps the anchors and `BASH_FILE`, chains:

```sh
. $SHARED_CONFIG_PATH/oosh.env
. $CONFIG_PATH/log.env
. $SHARED_CONFIG_PATH/odocker.env
. $HOME/.config/oosh/user.session.env
```

Any additional chain line already in `user.env` is preserved. A legacy
`. $CONFIG_PATH/<name>.env` line is rewritten to
`. $SHARED_CONFIG_PATH/<name>.env` when that file is shared, or kept on
`$CONFIG_PATH` when it is a per-user file (`user.env`, `log.env`).

`private.config.chain.names.get` learns both prefixes and
`private.config.save` re-emits each chain with the correct one.

### `oosh.env` and `odocker.env`

They stay shared, including their `$HOME/.config/oosh/<family>.session.env`
chain lines. `SHARED_CONFIG_PATH/oosh.env` remains the single source of
`OOSH_*` settings.

### `log.env`

`log.env` is per-user and is the only log file. The old per-user
`$HOME/.config/oosh/log.session.env` is no longer chained; its values are
folded into `CONFIG_PATH/log.env` during migration. The shared `log.env` is
left on disk for rollback but is no longer imported.

`log.session.save` changes its target to `CONFIG_PATH/log.env` and keeps its
current in-place, content-compared writer (`private.config.env.lines.drop` /
`private.config.env.line.append`), so it updates `LOG_NAME`, `LOG_LIVE` and a
file `LOG_DEVICE` without disturbing the other `LOG_*` lines. `config save log
LOG` still writes the whole family.

### `private.config.file.resolve`

Resolution order becomes:

1. `$CONFIG_PATH/$CONFIG_FILE`
2. `$SHARED_CONFIG_PATH/$CONFIG_FILE`
3. `$HOME/.config/oosh/$CONFIG_FILE`

`config list` shows the per-user file when both tiers carry the same name.
`config list oosh` finds the shared file through `SHARED_CONFIG_PATH` (and
through the symlink in `CONFIG_PATH`, which is the same file).

### `config save` targets

| Invocation | Target |
|---|---|
| `config save` | `$CONFIG_PATH/user.env` |
| `config save log LOG` | `$CONFIG_PATH/log.env` |
| `config save oosh OOSH` | `$SHARED_CONFIG_PATH/oosh.env` |
| `config save <name> <PREFIX>` | `$SHARED_CONFIG_PATH/<name>.env` |
| `config add <name>` | appends `. $SHARED_CONFIG_PATH/<name>.env` to `user.env` |
| `config session.save` | unchanged: `$HOME/.config/oosh/{user,oosh}.session.env` |

`config delete` refuses to delete `user.env` or `log.env` through a shared
path and refuses shared files for a non-group-writer; the error names
`$SHARED_CONFIG_PATH/<file>` and `oo shared.init`.

## 6. Migration and healing

Triggered from the first shell that sources `this`, and by `oo update` /
`config init.user`; idempotent.

Legacy detection: `~/config` is a symlink, `~/sharedConfig` does not exist,
the resolved `~/config` target contains `user.env`, and its `oosh.env` is a
**regular file** (in the new layout every shared entry under `~/config` is a
symlink, so a real `oosh.env` identifies the old shared directory). A real
`~/config` with no `SHARED_CONFIG_PATH` line in `user.env` is also repaired.

Per-user migration:

1. Take `$HOME/.config/oosh/config.split.lock` with an atomic `mkdir`; a second
   process waits, then re-reads the result.
2. Resolve the old target (`shared=$(cd ~/config && pwd -P)`). If it is missing
   or unreadable, leave the legacy layout usable and warn once.
3. Create `~/sharedConfig -> $shared` if absent.
4. Build `~/config.new` with `umask 077`:
   - copy the effective `user.env`, rewriting the anchors and chain lines;
   - write `log.env` from the effective `LOG_*` values (old shared `log.env`
     first, old `log.session.env` last, so per-user values win);
   - symlink every shared entry except `user.env`, `log.env` and a
     self-referential `sharedConfig/sharedConfig`.
5. Swap: rename `~/config` to `~/config.pre-split.<UTC timestamp>`, rename
   `~/config.new` to `~/config`. On any failure, restore the backup and leave
   the legacy layout.
6. Release the lock, log the backup path at `info.log`, and let the caller
   re-source the new `user.env`.
7. A later pass links any **new** shared entries, re-points stale links, and
   leaves real per-user files alone.

The migration never needs root: it touches only the user's home. `oo user.init`
and the install run the same helper for the target home, with the target owner
and mode as the final step.

## 7. Security

- `~/config` is created `0700`, owned by the user.
- `user.env` and `log.env` are created `0600`, owned by the user.
- The migration and every writer use `umask 077`; when root writes for another
  user, it `chown`s the directory and files back to that user and applies
  `0700`/`0600`.
- Symlinks and the shared tree are readable by the shared group by design.
  "One user cannot read another user's config" means another user's `~/config`
  and its real files, not the site-wide shared tier.
- `test/test.platform.shared.config.invariant` gains a two-account check:
  user B cannot list `~userA/config` and cannot read
  `~userA/config/user.env`.

## 8. Install and new machines

- Install state 31 and `user.oosh.install` stop doing
  `ln -s <sharedConfig> ~/config`.
- They create `~/config` as a real `0700` directory, `~/sharedConfig` as the
  shared symlink, generate the per-user `user.env` and `log.env`, and link the
  shared entries.
- `oo shared.init` continues to own the shared tree (`root:dev`, `g+w`, SGID
  on top); it never writes a user's `~/config`.
- `oo user.repair` and `config init.user` rebuild a missing per-user config and
  re-link shared entries without copying shared data.

## 9. Test plan (red first)

Core tests, using fixture homes and isolated config tiers:

| Test | Pins |
|---|---|
| `T-CONFIG-SHARED-PATH-EXPORTED` | a fresh `source this` exports `SHARED_CONFIG_PATH=$HOME/sharedConfig` |
| `T-CONFIG-SHARED-ANCHOR-VALIDATE` | the third anchor is validated; a non-constant assignment is caught |
| `T-CONFIG-USER-ENV-PER-USER` | `config save` writes `$CONFIG_PATH/user.env`, never the shared tree; the body chains `$SHARED_CONFIG_PATH/oosh.env` |
| `T-CONFIG-SAVE-OOSH-SHARED` | `config save oosh OOSH` writes `$SHARED_CONFIG_PATH/oosh.env` |
| `T-CONFIG-LOG-PER-USER` | `config save log LOG` writes all `LOG_*` to `$CONFIG_PATH/log.env`; the shared `log.env` is untouched |
| `T-CONFIG-LOG-SESSION-IN-PLACE` | `log.session.save` updates `LOG_NAME`/`LOG_LIVE`/file `LOG_DEVICE` in `$CONFIG_PATH/log.env` and keeps `LOG_LEVEL` |
| `T-CONFIG-MIGRATE-SPLIT` | a legacy symlinked `~/config` becomes a `0700` dir, `~/sharedConfig` appears, per-user files are real, shared entries are links, the backup is kept |
| `T-CONFIG-MIGRATE-IDEMPOTENT` | a second pass changes no bytes, no inode, no owner |
| `T-CONFIG-MIGRATE-LOCK` | two concurrent migrations produce one layout and no half-swap |
| `T-CONFIG-RESOLVE-TWO-TIERS` | per-user wins for `user`/`log`; shared answers for `oosh` |
| `T-CONFIG-USER-PRIVATE-MODE` | `~/config` is `0700`, `user.env`/`log.env` are `0600` |
| `T-CONFIG-SHARED-LINK-FARM` | every shared entry except `user.env`/`log.env` is a link; a new shared file is linked by the next heal |

Platform invariant:

- `test.platform.shared.config.invariant`: two local accounts; B cannot read
  A's config; A's `~/config` and files have the expected modes; shared imports
  resolve; `SHARED_CONFIG_PATH` is set for both.

Existing tests to update:

- `test.suite.config.isolate`: move **both** tiers into fixtures and fingerprint
  both; the real-config guard covers `$SHARED_CONFIG_PATH`.
- `test/test.config`: anchor constants, save targets, required-file paths,
  chain parsing, session-file expectations.
- `test/test.this`: `SHARED_CONFIG_PATH` anchor and the su re-anchor block.
- `test/test.log`: colours and session-write targets move to `CONFIG_PATH/log.env`.
- `test/test.line` and any test that seeds `CONFIG_PATH` colour files.

## 10. Rollout and compatibility

- New install: split layout from the start.
- Existing install: first shell migrates the user; `oo update` and
  `config init.user` do it for every user the caller may repair.
- A host that cannot migrate (home read-only, shared target missing) keeps the
  legacy layout for that user and derives `SHARED_CONFIG_PATH` from the old
  symlink, so `SHARED_CONFIG_PATH` is still exported and shared imports still
  resolve. A warning names the failed step.
- The legacy `~/config.pre-split.<timestamp>` symlink and the shared `log.env`
  stay on disk for rollback; nothing reads them.
- `su` re-anchoring covers `SHARED_CONFIG_PATH` as well, so a non-login
  `su <user>` never uses another user's shared link.

## 11. Out of scope

- Moving `user.session.env` / `oosh.session.env` out of `~/.config/oosh`.
  The one-file variant that keeps them in `~/.config/oosh` is recorded in
  §12; neither move is part of this change.
- Per-user custom `<name>.env` files (a later `config save --user` flag).
- Encrypting per-user config.
- Removing shared files that the split no longer imports.

## 12. Alternative considered: one session file

The accepted layout keeps two per-user session files. This section records the
one-file alternative, so a later review does not have to rediscover it.

The `log.session.env` → per-user `log.env` change is orthogonal: it applies to
both layouts and is not counted as one of the session files here.

### 12.1 The two layouts

**Current (accepted):**

```text
$HOME/.config/oosh/
  user.session.env    real PATH  (+ OOSH_MODE as a transition copy until the oosh gate opens)
  oosh.session.env    OOSH_MODE
  log.session.env     LOG_NAME / LOG_DEVICE / LOG_LIVE   (until the log move)
```

Chains:

```sh
# user.env
. $HOME/.config/oosh/user.session.env

# oosh.env
. $HOME/.config/oosh/oosh.session.env

# log.env
. $HOME/.config/oosh/log.session.env
```

**Option 1 (one file):**

```text
$HOME/.config/oosh/
  session.env         OOSH_MODE + PATH
  log.session.env     unchanged / orthogonal
```

One file:

```sh
export OOSH_MODE="dev"
export PATH="/usr/local/bin:/usr/bin:/bin:..."
```

`PATH` stays absolute — no `$HOME`, no `:$PATH` — as
`private.config.path.line.absolute.get` already writes it. `OOSH_MODE` is
omitted when no branch is derivable.

Chains:

```sh
# user.env
. $HOME/.config/oosh/session.env

# oosh.env — only if OOSH_MODE must be available early
. $HOME/.config/oosh/session.env
```

### 12.2 Side-by-side

| Area | Current | Option 1 | Effect |
|---|---|---|---|
| Files for PATH + branch | 2 | 1 | less state, one source of truth |
| Writes per shell | 2 (`user.session.env`, `oosh.session.env`) | 1 | fewer writes, one mtime/mode |
| Chain lines | 2 for these values (`user.env` → user, `oosh.env` → oosh) | 1, or 2 if sourced from both | simpler, but see OOSH_MODE timing |
| `OOSH_MODE` availability | set as soon as shared `oosh.env` is sourced | later if chained only from `user.env`; same if chained from both | behavioural risk |
| Transition copy of `OOSH_MODE` | yes — duplicated into `user.session.env` until the oosh gate opens | not needed | removes a whole state |
| Split predicates | `private.config.session.split.is` + `private.config.oosh.session.split.is` | one | less code |
| Split gates | `private.config.session.chain.ready` for user and oosh | one | less code, same all-users prerequisite |
| Migrations | `private.config.user.session.migrate` + `private.config.oosh.session.migrate` | one fold/migrate | simpler, fewer failure paths |
| `config.session.save` | writes two files, computes fallback mode, conditionally duplicates | writes one file | roughly half the function |
| `private.config.session.file.ensure` | creates/validates 3 files | creates/validates 1 session file | simpler first-shell path |
| `config.validate.required` | `OOSH_MODE` lives in `oosh.session.env` | `OOSH_MODE` lives in `session.env` | one mapping change, no duplicate |
| `config list` | `user.session` and `oosh.session` are separate names | `session` holds both | loses family-specific naming |
| Compatibility | existing names | old names break unless aliased | medium migration work |
| Removes `~/.config/oosh` | no | no | only a partial simplification |
| Test churn | baseline | session/gate/migration tests + docs | medium risk |

### 12.3 Advantages of Option 1

1. **One source of truth.** PATH and `OOSH_MODE` cannot disagree; a branch
   change and a PATH update are one write.
2. **One write, one mtime, one mode.** No “PATH written, branch file failed”
   state.
3. **Less code.**
   - one `session.file.get` instead of two;
   - one `session.split.is` instead of two;
   - one `session.migrate` instead of two;
   - one `sessionSplit` flag in `config.save` instead of `sessionSplit` +
     `ooshSplit`;
   - `private.config.session.file.ensure` checks one file instead of two.
4. **No transition copy.** Today `OOSH_MODE` is temporarily written into both
   `user.session.env` and `oosh.session.env`; `private.config.oosh.session.migrate`
   then removes it from `user.session.env`. Option 1 deletes that concept.
5. **One gate instead of two.** The gate still has to wait until every linked
   user has the file, but there is only one “everyone has it” check.
6. **Easier inspection and backup.** `config list session`, one file to copy,
   one file to diff, one file to fix.
7. **Consistent with the target log move.** After `log.session.env` becomes
   `$CONFIG_PATH/log.env`, the only remaining per-user session state is PATH
   plus branch, so one file matches the model.

### 12.4 Disadvantages of Option 1

1. **`OOSH_MODE` timing changes.** Today the shared `oosh.env` chains
   `oosh.session.env`, so `OOSH_MODE` is set immediately after `oosh.env` is
   sourced. If Option 1 chains `session.env` only from `user.env` (last), then:
   - `odocker.env` or any custom chain sourced before `session.env` will not
     see `OOSH_MODE`;
   - anything that sources `oosh.env` alone will not see it.

   Chaining the same file from both `oosh.env` and `user.env` avoids the timing
   change, but sources the file twice. That is harmless for PATH (the stored
   PATH is absolute) and for `OOSH_MODE` (same value), but it is conceptually
   less clean and `config list oosh` and `config list user` both show the same
   file.

2. **The migration gate does not disappear.** The shared `user.env`/`oosh.env`
   still cannot chain a per-user file until every linked user has it. Option 1
   merges two gates into one, but still needs:
   - `ensure` to create the file for every user;
   - a gate before the shared chain line changes;
   - a migration path for hosts where the old chain lines still exist.

   That is less work than two gates, but not “no gate”.

3. **Compatibility breaks.** These stop resolving unless aliases or symlinks
   are kept:
   - `~/.config/oosh/user.session.env`
   - `~/.config/oosh/oosh.session.env`
   - `config list user.session`
   - `config add user.session`
   - scripts, docs, backups and test fixtures that name the old files.

   A compatibility symlink from the old names to `session.env` is easy, but
   the directory then still has three names (one real file, two links).

4. **`config` naming becomes ambiguous.**
   - `config list session` works;
   - `config list oosh.session` and `config list user.session` no longer work
     unless aliased;
   - `config save session` may write a **shared** `session.env` per the
     save-target rules, not the per-user file;
   - `config delete session` and `config edit session` need guards so they do
     not destroy generated state.

5. **Failure blast radius.** A failed `> session.env` truncates one file that
   holds both PATH and branch. Today a failed `oosh.session.env` write does not
   lose the PATH file. The one-file writer must use an atomic write
   (`private.this.file.write`, temp file + move) or the change makes one
   failure worse.

6. **Empty `OOSH_MODE` is no longer represented the same way.** Today an empty
   `oosh.session.env` is legal and means “no branch derivable”. A one-file
   `session.env` always has a PATH line, so it is never empty; if `OOSH_MODE`
   is omitted, a stale exported `OOSH_MODE` from the parent could survive
   unless the file explicitly clears it. Decide whether to write
   `export OOSH_MODE=""` or rely on `this`/`bashrc` resetting it.

7. **Test churn is broad.** `test/test.config` currently pins:
   - `T-CONFIG-USER-SESSION-SAVE`
   - `T-CONFIG-USER-SESSION-SAVE-CARRIES-MODE`
   - `T-CONFIG-SESSION-FILE-ENSURE`
   - `T-CONFIG-SESSION-WRITES-ONCE`
   - `T-CONFIG-USER-SESSION-MIGRATE`
   - `T-CONFIG-OOSH-SESSION-MIGRATE`
   - the open/closed gate cases
   - `config list log.session` and the per-user tier

   All of those need rewriting around one file. The log tests are separate, but
   the session/gate tests are not.

8. **It does not remove `~/.config/oosh`.** It still leaves a second per-user
   directory. If the original goal was “one private root”, Option 1 is only a
   partial step.

### 12.5 Advantages of the current two-file model

- `OOSH_MODE` is available immediately after `oosh.env`, without sourcing
  anything twice.
- PATH and branch fail independently; one bad write does not take both.
- `config list oosh.session` and `config list user.session` name exactly what
  the user is looking at.
- The gates and migrations already exist and are tested, including the
  transition copy of `OOSH_MODE`.
- The log family stays separate without fighting the design.

### 12.6 Disadvantages of the current model

- Two files, two writes, two mtimes, two backup entries.
- `OOSH_MODE` is temporarily duplicated in `user.session.env`, then removed by
  `private.config.oosh.session.migrate`.
- Two gates and two migrations, with a lot of explanatory comments.
- `config.session.save` is more complex than the problem requires.
- The directory holds more names than values.

### 12.7 Verdict

Option 1 is a real simplification, but not a cheap one. It removes the
duplicate `OOSH_MODE` state, one writer, one gate and one migration. In
exchange it:

- changes `OOSH_MODE` availability unless the file is sourced twice;
- breaks the old file names unless aliases are kept;
- still requires a migration gate;
- still leaves `~/.config/oosh` in place;
- rewrites a meaningful part of `test/test.config`.

Recommendation:

- If the goal is “one file for PATH + `OOSH_MODE`” while keeping the current
  migration model: take Option 1, chain it from both `oosh.env` and `user.env`,
  use an atomic writer, and keep `user.session.env`/`oosh.session.env` as
  compatibility symlinks for one release.
- If the goal is to remove `~/.config/oosh` entirely: do not stop at Option 1.
  Do the split first, then move to `$CONFIG_PATH/session.env` in a second
  migration; that gives the final minimal tree, but until the split completes
  `$CONFIG_PATH` still resolves through the shared `~/config` symlink, so the
  shared chain cannot point at a per-user file yet (see §6).
- If stability is the priority: keep the current two files and revisit after
  the `~/config` split. Option 1 is a middle step that pays most of the
  compatibility cost without removing the directory.

### 12.8 If Option 1 is taken later

Layout and chains are in §12.1. The implementation surface:

- `config.session.save`: write one `$HOME/.config/oosh/session.env` instead of
  the two files; read `OOSH_MODE` fallback from the new file, then the old
  `oosh.session.env`, old `user.session.env`, then shared `oosh.env`; write
  PATH and, when non-empty, `OOSH_MODE`; use an atomic writer.
- `private.config.session.file.ensure`: create/verify one session file; the
  log file is handled by the separate log change.
- `private.config.required.file.path.get`: map `session.env`,
  `user.session.env` and `oosh.session.env` to the one path during migration.
- `private.config.required.variables.get`: move the `OOSH_MODE` row to
  `session.env`.
- `config.save`: one `sessionSplit`; append
  `. $HOME/.config/oosh/session.env`; exclude `OOSH_MODE` from the shared files
  on the same flag; remove the `ooshSplit` branch and
  `private.config.oosh.session.migrate` call.
- `config.add session` cannot be reused: it writes
  `. $CONFIG_PATH/session.env`, which is the wrong tier. Write the chain
  explicitly (as `oosh.env`/`log.env` do) and skip `session` in the generic
  `chainNames` loop.
- Remove `private.config.oosh.session.file.get`,
  `private.config.oosh.session.split.is` and
  `private.config.oosh.session.migrate`; fold
  `private.config.user.session.migrate` into one `private.config.session.migrate`.
- `private.config.session.split.is` and
  `private.config.session.chain.ready` check the one file.
- Migration: create `session.env` from the old `user.session.env` (PATH) and
  `oosh.session.env` (`OOSH_MODE`), mode 0600; keep the two old names as
  symlinks for one release so old chain lines keep resolving; append the new
  chain line only when every linked user has the file; then drop the old
  chain lines and symlinks.
- Tests/docs: the `test/test.config` cases listed in §12.4, the
  `config list log.session`/per-user-tier test, and the session-file paths in
  `docs/config.md`.

## 13. Acceptance mapping

| Acceptance criterion | Where it is met |
|---|---|
| `SHARED_CONFIG_PATH` exists and is exported | §4; `T-CONFIG-SHARED-PATH-EXPORTED` |
| Shared imports load from it | §5 `user.env` chain; `T-CONFIG-USER-ENV-PER-USER` |
| `user.env` stays per user | §3, §5, §6; `T-CONFIG-USER-ENV-PER-USER`, `T-CONFIG-MIGRATE-SPLIT` |
| One user cannot read another's config | §7; `T-CONFIG-USER-PRIVATE-MODE`, platform invariant |
