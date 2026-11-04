# T12 — `user`: authorized-keys model and key API diverged

<!-- ossh-rename-history: allowed — this ticket quotes retired names on purpose -->

- **Type:** finding · **Priority:** P1 · **Area:** `user`
- **State:** open; data in `docs/compare-user-dev-vs-mcdonges.md`

## The finding

| | `dev` | `mcdonges.latest` |
|---|---:|---:|
| Lines | 1 916 | 747 |
| Methods (public) | 89 (56) | 49 (37) |
| Shared names | 33 | |
| Shared but **changed** | 15 | |
| dev-only / mcd-only | 56 | 16 |

The account half was rebuilt on `dev`; the key half moved to `ossh`:

| Area | `dev` | `mcdonges` |
|---|---|---|
| `authorized_keys` | `user.authorized.keys.update` → **atomic** rebuild from `public_keys/`, after `adopt` files every hand-added key; `deactive.public_keys/` is the revoke list | `user.update.authorized_keys` → `rm` then `cat public_keys/*`; a key only in `authorized_keys` is lost and the file is briefly absent |
| Key operations | moved to `ossh` (`key.push`, `key.revoke`, `private.ossh.remote.public.key.put`) | in `user`: `ssh.rootkey.push/pull/file.push/file.revoke`, `ssh.create.folders`, `ssh.get.*`, `ssh.rename.files`, `ssh.set.key.name`, `ssh.status` |
| `create` | `<user> <?password> <?uid> <?gid>`, keyword args, sudoers, auto `oosh.install` | `<user> <?uid> <?gid>` |
| Passwords | `user.password.set` (darwin + linux) | absent |
| Backups | `ssh.backup` → `~/.ssh.backups/` + `list`/`restore`/`migrate`/`status` | `ssh.backup`/`ssh.restore` only |
| WODA blocks | portable `~/…`, per-alias identity, `IdentitiesOnly yes` | `IdentityFile $sshDir/id_ed25519` → an absolute `/home/<user>/…` at write time |

## Why it matters

- The two `authorized_keys` models differ in **failure mode**: mcdonges' `rm` + `cat` loses a
  hand-added key and leaves a window with no file; `dev`'s adopt + atomic swap exists because of
  that (POL.dev lockout).
- mcdonges' WODA generator writes a non-portable path and has no developking identity; `dev`'s
  `test.platform.ssh.config.woda.portable` rejects that form (T02/T03).
- `user.ssh.rootkey.push` callers cannot be "renamed" to `ossh key.push` — the semantics differ.

## Decision needed

One model per row above; a migration note for scripts that call `user.ssh.rootkey.*`; and
`test.user` coverage for whichever `authorized_keys` implementation survives.

## Acceptance

A written decision per row, the chosen model covered by `test.user`, and any removed method
either redirected or listed as a documented break.
