# `user` — `origin/dev` vs `origin/test/mcdonges.latest`

Generated 2026-11-03 from the two branch tips (`dev` = `7ab831d9`, `mcdonges.latest` = `760552c7`).

<!-- ossh-rename-history: allowed — this page names retired methods on purpose -->


`user` is the local-account command: create/delete/list users and groups, passwords,
home, the user's own keypair, `public_keys/` and `authorized_keys`, ssh backups, and the WODA
Host blocks in `~/.ssh/config`. It calls `ossh` for anything that leaves the machine.

## 1. Snapshot

| | `dev` | `mcdonges.latest` |
|---|---:|---:|
| Lines | 1916 | 747 |
| Methods | 89 | 49 |
| … public | 56 | 37 |

| Overlap | Value |
|---|---:|
| Shared names | 33 |
| Shared but changed (same name, different body) | 15 |
| … code changes | 15 |
| … docstring-only changes | 0 |
| Only in `dev` | 56 |
| Only in `mcdonges` | 16 |

## 2. Methods that exist on only one branch

<details><summary><b>Only in dev</b> (56)</summary>

- `private.as.user`
- `private.user.authorized.keys.adopt`
- `private.user.authorized.keys.rebuild`
- `private.user.basehome.system.get`
- `private.user.bashrc.install`
- `private.user.check.group`
- `private.user.create.addSudoer.darwin`
- `private.user.create.addSudoer.linux`
- `private.user.delete.command.get`
- `private.user.delete.command.get.completion.sbinDir`
- `private.user.delete.linux`
- `private.user.exists`
- `private.user.get.sshDir`
- `private.user.group.member.is`
- `private.user.group.member.pending`
- `private.user.login.term.get`
- `private.user.oosh.install.groups.darwin`
- `private.user.oosh.install.groups.linux`
- `private.user.oosh.install.node`
- `private.user.oosh.install.shell.darwin`
- `private.user.oosh.install.shell.linux`
- `private.user.path.owner.get`
- `user.as`
- `user.authorized.keys.update`
- `user.create.completion.gid`
- `user.create.completion.password`
- `user.create.completion.uid`
- `user.create.completion.username`
- `user.group.add.completion.groupName`
- `user.group.add.completion.toUsername`
- `user.group.member.pending`
- `user.group.member.pending.completion.group`
- `user.group.member.pending.completion.user`
- `user.info`
- `user.linux.delete`
- `user.oosh.install`
- `user.oosh.install.completion.branch`
- `user.oosh.install.completion.username`
- `user.parameter.completion.groupName`
- `user.parameter.completion.userName`
- `user.password.set`
- `user.password.set.completion.password`
- `user.password.set.completion.username`
- `user.password.set.darwin`
- `user.password.set.darwin.completion.password`
- `user.password.set.darwin.completion.username`
- `user.password.set.linux`
- `user.password.set.linux.completion.password`
- `user.password.set.linux.completion.username`
- `user.ssh.backup.completion.label`
- `user.ssh.backup.list`
- `user.ssh.backup.migrate`
- `user.ssh.backup.migrate.completion.home`
- `user.ssh.backup.status`
- `user.ssh.backup.status.completion.home`
- `user.ssh.restore.completion.archive`

</details>

<details><summary><b>Only in mcdonges</b> (16)</summary>

- `private.get.sshDir`
- `user.check.group`
- `user.delete.linux`
- `user.ssh.create.folders`
- `user.ssh.get.file.name`
- `user.ssh.get.key.name`
- `user.ssh.rename.files`
- `user.ssh.rootkey.file.push`
- `user.ssh.rootkey.file.revoke`
- `user.ssh.rootkey.pull`
- `user.ssh.rootkey.push`
- `user.ssh.rootkey.push.completion`
- `user.ssh.set.key.name`
- `user.ssh.status`
- `user.ssh.status.completion`
- `user.update.authorized_keys`

</details>

## 3. Same name, different body

<details><summary><b>Changed</b> (15)</summary>

- `private.get.basehome.darwin`
- `private.get.home.darwin`
- `private.user.init`
- `user.create`
- `user.get.current.identity`
- `user.group.add`
- `user.group.check`
- `user.in`
- `user.init`
- `user.list.other.identities`
- `user.login`
- `user.ssh.backup`
- `user.ssh.restore`
- `user.start`
- `user.usage`

</details>

## 4. What actually differs

**The account half was rebuilt on `dev`; the key half moved.** `dev`'s `user` is 1 916 lines
against 747, and most of the difference is account work plus the new authorized-keys model.

| Area | `dev` | `mcdonges` |
|---|---|---|
| `authorized_keys` | `user.authorized.keys.update` → atomic rebuild from `public_keys/`, after `adopt` gives every hand-added key a file; `deactive.public_keys/` is the revoke list | `user.update.authorized_keys` → `rm` then `cat public_keys/*`; a key only in `authorized_keys` is lost, and the file is briefly absent |
| Key operations | moved to `ossh` (`key.push`, `key.revoke`, `private.ossh.remote.public.key.put`) | in `user`: `ssh.rootkey.push/pull/file.push/file.revoke`, `ssh.create.folders`, `ssh.get.*`, `ssh.rename.files`, `ssh.set.key.name`, `ssh.status` |
| `create` | `<user> <?password> <?uid> <?gid>`, keyword args, sudoers, auto `oosh.install` | `<user> <?uid> <?gid>` |
| Passwords | `user.password.set` (darwin + linux) | absent |
| Groups | `group.member.pending`, completions | `user.check.group` |
| Backups | `ssh.backup` → `~/.ssh.backups/`, plus `list`/`restore`/`migrate`/`status` | `ssh.backup`/`ssh.restore` only, different bodies |
| WODA blocks | `~/.ssh/...` paths, per-alias identity (`developking` for `.test`/`.dev`, `id_ed25519` for `.root`), `IdentitiesOnly yes` | `IdentityFile $sshDir/id_ed25519` — expanded to an absolute `/home/<user>/…` at write time |

Those table rows are the same names doing different things, so a host upgraded from
mcdonges to dev changes behaviour without a rename: `user init` on mcdonges writes WODA
blocks that `test.platform.ssh.config.woda.portable` (dev) rejects as non-portable.

**Cross-command migration.** The mcdonges `user.ssh.rootkey.*` family is the same job dev
does through `ossh` (`ossh key.push` pushes the Host's `IdentityFile` and verifies the login;
`ossh key.revoke` moves the key to `deactive.public_keys/`). A caller of `user ssh.rootkey.push`
has to be rewritten to `ossh key.push`, not just renamed.

**What stayed the same.** `user init` (name and intent), `create`, `get`, `list*`, `id`, `in`,
`login`, `group.add/check`, `ssh.backup`/`ssh.restore`, `start`/`usage`, and the
`private.get.{basehome,home,info,name,shell}.*` platform readers — but 15 of the 33 shared
names have a different body on each branch.


## 5. Caller compatibility

| Call | `dev` | `mcdonges` |
|---|:--:|:--:|
| `user init` | Y | Y |
| `user authorized.keys.update` | Y | – |
| `user update.authorized_keys` | – | Y |
| `user ssh.rootkey.push` / `pull` / `file.revoke` | – | Y |
| `ossh key.push` / `key.revoke` (the dev replacement) | Y | Y |
| `user ssh.create.folders` | – | Y |
| `user ssh.get.file.name` / `get.key.name` / `rename.files` / `status` | – | Y |
| `user ssh.backup` / `ssh.restore` | Y | Y (different body) |
| `user ssh.backup.list` / `migrate` / `status` | Y | – |
| `user password.set` | Y | – |
| `user oosh.install` | Y | – |
| `user group.member.pending` | Y | – |
| `user check.group` | – | Y |
| `user as` / `user info` | Y | – |
| `user create` (password argument) | Y | – |
| `user delete.linux` | Y | Y (different body) |



## 6. Caveats

- **Changed** is byte comparison of the method block; none of the 15 are docstring-only.
- The mcdonges WODA form is documented in `docs/audit-woda.md`; the dev form and its
  tests in `docs/ossh-differences-dev-vs-mcdonges.md` and `test/test.ssh.config.woda`.
- `init/oosh` is a different script (bootstrap, 6 methods on dev, 10 on mcdonges, no shared
  names) and is not covered here.
