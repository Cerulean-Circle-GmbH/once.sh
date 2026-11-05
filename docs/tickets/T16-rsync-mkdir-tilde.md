# T16 — `private.ossh.rsync` creates the wrong remote directory

- **Type:** bug · **Priority:** P2 · **Area:** `ossh` (`private.ossh.rsync`, reached by `id.push`)
- **State:** fixed 2026-11-05, commit `90a4647b`; regression test `T-OSSH-RSYNC-TILDE`
- **Found by:** comparing `ossh dir.push` with `ossh id.push` (why does only one use `~`?)

## Symptom

`ossh id.push <host> <id>` copies `<sshDir>/ids/<id>` to `<toHost>:~/.ssh/ids/`, and
`private.ossh.rsync` runs a `mkdir` on the host first. On a host where `~/.ssh/ids` does not
exist yet:

- the intended directory is not created;
- a literal directory named `~` appears in the host's home;
- the copy then depends on rsync being able to create `~/.ssh/ids` by itself, which it cannot do
  if `~/.ssh` is also missing.

`dir.push` is unaffected because its destination is `<toHost>:.` (no `~`, no mkdir).

## Evidence

Two independent defects in the same ten lines:

1. **The path was single-quoted for the remote shell**

   ```bash
   ssh ... "$host" "mkdir -p '$remoteDir'" 2>/dev/null
   ```

   `~` is expanded by the shell only when it is unquoted at the start of a word, so the remote
   command is the literal string:

   ```
   mkdir -p '~/.ssh/ids'
   ```

   Reproduced locally:

   ```
   $ mkdir -p '~/.ssh/ids' && find . -maxdepth 3
   .
   ./~
   ./~/.ssh
   ./~/.ssh/ids          # a directory called "~", not $HOME/.ssh/ids
   ```

2. **`dirname` dropped the last component because the destination ends with `/`**

   ```bash
   remoteDir=$(dirname "$remotePath")     # ~/.ssh/ids/  →  ~/.ssh
   ```

   `dirname` strips trailing slashes before answering, so the mkdir made the parent, not the
   directory rsync copies *into*. The `mkdir` step never matched the `rsync` destination except
   for `host:.`.

Neither was caught by the suite: `test.ossh.pushPullResult` replaces `private.ossh.rsync` with a
stub (`return "$FX_COPY"`), so the mkdir/ssh path never runs under test.

## Fix

`ossh:729-751`, commit `90a4647b`:

```bash
  local remoteDir
  case "$remotePath" in
    */) remoteDir="${remotePath%/}" ;;   # rsync copies the source INTO this dir
    *)  remoteDir=$(dirname "$remotePath") ;;
  esac

  local mkdirCmd=""
  case "$remoteDir" in
    "."|"~"|"") : ;;
    "~/"*)      mkdirCmd="mkdir -p \"\$HOME\"/'${remoteDir#"~/"}'" ;;
    *)          mkdirCmd="mkdir -p '$remoteDir'" ;;
  esac
```

- trailing `/` now means "this directory must exist", no trailing `/` means "its parent must
  exist";
- a leading `~/` becomes `"$HOME"/'<tail>'`, so the remote shell expands `$HOME` while the rest of
  the path stays quoted and literal;
- `.`, `~` and the empty path still skip the mkdir.

The command the host receives for the `id.push` destination is now:

```
mkdir -p "$HOME"/'.ssh/ids'
```

## Test

`T-OSSH-RSYNC-TILDE` (`test/test.ossh`), four shapes with `ssh`/`rsync` stubbed:

| Destination | Remote command |
|---|---|
| `lab:~/.ssh/ids/` | `mkdir -p "$HOME"/'.ssh/ids'` |
| `lab:sub/dir/` | `mkdir -p 'sub/dir'` |
| `lab:sub/file` | `mkdir -p 'sub'` |
| `lab:.` | none (no ssh call) |

It also fails if the command contains a literal `'~`.

## Verification

```
bash -n ossh / test/test.ossh     → ok
test.ossh                         → 156/156 (one new case)
manual: private.ossh.rsync with ssh stubbed, four destinations → above
```

## Why P2, not P3

The failure is silent on the host (junk directory) and only shows up on a target that has no
`~/.ssh/ids` yet — exactly the first-time case `id.push` exists for. oosh installs usually create
that directory, which is why it survived.

## Follow-up worth checking

The same pattern — a path interpolated into a remote command inside single quotes — appears
wherever a remote `mkdir`, `cat` or `rm` is built by hand. `private.ossh.rsync` now handles `~`
explicitly; the other remote commands in `ossh` build fixed paths and are safe today, but a sweep
for `ssh .*"[^"]*'\$` is worth doing when remote paths become caller-controlled.
