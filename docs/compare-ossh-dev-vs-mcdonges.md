# `ossh` — `origin/dev` vs `origin/test/mcdonges.latest`

Generated 2026-11-03 from the two branch tips (`dev` = `7ab831d9`, `mcdonges.latest` = `760552c7`).

<!-- ossh-rename-history: allowed — this page names retired methods on purpose -->

> **Update 2026-11-04:** `dev` renamed `ossh.server.get.ip*` and `ossh.server.get.port` to
> `ossh.server.ip.get*` / `ossh.server.port.get`, matching this page's mcdonges column. The rows
> below describe the 2026-11-03 snapshot.
> **Update 2026-11-04 (2):** `private.ossh.key.push` and `private.ossh.key.pull` were collapsed
> into the public methods; the private rows in the one-sided lists are historical.

Companion: `docs/ossh-differences-dev-vs-mcdonges.md` (history, rename map, size analysis).

`ossh` is the remote-SSH command: Host blocks in `~/.ssh/config`, connections,
remote exec, key transfer, remote install and hardening. It is the command that changed most
between the branches — `dev` carries 2.3x the lines and a different naming scheme. The detailed
history (which commit did what) is in [`docs/ossh-differences-dev-vs-mcdonges.md`](ossh-differences-dev-vs-mcdonges.md);
this page is the command-surface comparison.

## 1. Snapshot

| | `dev` | `mcdonges.latest` |
|---|---:|---:|
| Lines | 4132 | 1770 |
| Methods | 230 | 160 |
| … public | 144 | 106 |

| Overlap | Value |
|---|---:|
| Shared names | 101 |
| Shared but changed (same name, different body) | 78 |
| … code changes | 75 |
| … docstring-only changes | 3 |
| Only in `dev` | 129 |
| Only in `mcdonges` | 59 |

## 2. Methods that exist on only one branch

<details><summary><b>Only in dev</b> (129)</summary>

- `ossh.authorized.keys.update`
- `ossh.cmd`
- `ossh.cmd.completion.pkg`
- `ossh.cmd.completion.sshConfigHost`
- `ossh.config.create.completion.idOrProxyJump`
- `ossh.config.create.completion.identitiesOnly`
- `ossh.config.create.completion.proxyJump`
- `ossh.config.delete`
- `ossh.config.delete.completion`
- `ossh.config.shared.create`
- `ossh.config.shared.create.completion.deployKeySrc`
- `ossh.config.shared.create.completion.sharedDir`
- `ossh.config.shared.github.create`
- `ossh.config.shared.github.create.completion.configFile`
- `ossh.config.shared.github.create.completion.knownHosts`
- `ossh.config.shared.seed.fallback`
- `ossh.config.shared.seed.fallback.completion.sshConfigHost`
- `ossh.config.shared.seed.from.local.deploy.key`
- `ossh.config.shared.seed.from.local.deploy.key.completion.sshConfigHost`
- `ossh.config.shared.seed.github`
- `ossh.config.shared.seed.github.completion.sshConfigHost`
- `ossh.create.and.install`
- `ossh.exec.tty`
- `ossh.exec.tty.completion`
- `ossh.file.get.name`
- `ossh.folder.fix`
- `ossh.folder.fix.check`
- `ossh.folder.fix.check.completion.sshDir`
- `ossh.folder.fix.completion.installerEmail`
- `ossh.folder.fix.completion.mode`
- `ossh.folder.fix.completion.sshDir`
- `ossh.harden`
- `ossh.harden.completion.sshConfigHost`
- `ossh.harden.fail2ban`
- `ossh.harden.fail2ban.completion.sshConfigHost`
- `ossh.harden.firewall`
- `ossh.harden.firewall.completion.extraPorts`
- `ossh.harden.firewall.completion.sshConfigHost`
- `ossh.harden.packages`
- `ossh.harden.packages.completion.sshConfigHost`
- `ossh.harden.sshd`
- `ossh.harden.sshd.allowusers`
- `ossh.harden.sshd.allowusers.completion.sshConfigHost`
- `ossh.harden.sshd.allowusers.completion.users`
- `ossh.harden.sshd.completion.sshConfigHost`
- `ossh.harden.unattended.upgrades`
- `ossh.harden.unattended.upgrades.completion.sshConfigHost`
- `ossh.install.log`
- `ossh.install.log.completion.sshConfigHost`
- `ossh.install.user.remote`
- `ossh.key.folders.create`
- `ossh.key.folders.delete`
- `ossh.key.get.name`
- `ossh.key.revoke`
- `ossh.key.set.name`
- `ossh.known.hosts.remove`
- `ossh.known.hosts.remove.completion`
- `ossh.parameter.completion.fromHost`
- `ossh.parameter.completion.remoteSshConfigName`
- `ossh.parameter.completion.sshConfigNameUsedForLocal`
- `ossh.parameter.completion.sshKeyName`
- `ossh.parameter.completion.user`
- `ossh.pm.discover`
- `ossh.pm.discover.completion.sshConfigHost`
- `ossh.prereqs.install`
- `ossh.prereqs.install.completion.sshConfigHost`
- `ossh.publicId.get`
- `ossh.remote.prelude.get`
- `ossh.remote.prelude.get.completion`
- `ossh.rights.fix`
- `ossh.rights.fix.completion.sshDir`
- `ossh.server.get.ip`
- `ossh.server.get.ip.darwin`
- `ossh.server.get.ip.linux`
- `ossh.server.get.port`
- `private.ossh.authorized.key.append.get`
- `private.ossh.config.block.put.get`
- `private.ossh.config.field.keyword.get`
- `private.ossh.config.last.file.get`
- `private.ossh.config.pull`
- `private.ossh.config.push`
- `private.ossh.config.push.completion`
- `private.ossh.connection.error.get`
- `private.ossh.connection.error.network.is`
- `private.ossh.control.path.get`
- `private.ossh.control.path.resolved.get`
- `private.ossh.create.key.folders`
- `private.ossh.delete.key.folders`
- `private.ossh.dir.pull`
- `private.ossh.dir.push`
- `private.ossh.dir.push.completion`
- `private.ossh.folder.fix.config.normalize`
- `private.ossh.folder.fix.config.strip.legacy`
- `private.ossh.folder.fix.prune`
- `private.ossh.folder.fix.scan.git.remotes`
- `private.ossh.get.current.key.file.name`
- `private.ossh.get.file.name`
- `private.ossh.get.key.name`
- `private.ossh.get.public.id`
- `private.ossh.get.server.ip`
- `private.ossh.get.server.port.wrapper`
- `private.ossh.get.ssh.parameter`
- `private.ossh.get.url`
- `private.ossh.github.block.is.oosh`
- `private.ossh.github.copies.remove`
- `private.ossh.github.copy.remove`
- `private.ossh.harden.preflight`
- `private.ossh.host.fqdn.get`
- `private.ossh.id.push`
- `private.ossh.identity.stage`
- `private.ossh.identity.stage.outer.fromRunner`
- `private.ossh.identity.stage.outer.proxyJump`
- `private.ossh.install.key.authorize`
- `private.ossh.key.pull`
- `private.ossh.key.push`
- `private.ossh.key.push.identity.get`
- `private.ossh.master.start`
- `private.ossh.oosh.init.push`
- `private.ossh.public.key.get`
- `private.ossh.public.key.put.text.get`
- `private.ossh.pull.id`
- `private.ossh.remote.key.file.name.get`
- `private.ossh.remote.public.key.put`
- `private.ossh.set.key.name`
- `private.ossh.shared.ssh.legacy.remove`
- `private.ossh.system.config.file.get`
- `private.ossh.system.known.hosts.get`
- `private.ossh.user.homes.get`
- `private.ossh.users.basehome`

</details>

<details><summary><b>Only in mcdonges</b> (59)</summary>

- `ossh.authorized_keys.update`
- `ossh.dir.pull.completion.dir`
- `ossh.dir.push.completion.dir`
- `ossh.get`
- `ossh.get.completion`
- `ossh.get.completion.object`
- `ossh.get.public.id`
- `ossh.id.create.completion.sshDir`
- `ossh.id.file.get`
- `ossh.id.public.get`
- `ossh.id.pull.completion.sshDir`
- `ossh.install.create`
- `ossh.key.folder.create`
- `ossh.key.folder.delete`
- `ossh.key.name.get`
- `ossh.key.name.set`
- `ossh.key.pull.completion.dir`
- `ossh.key.push.completion`
- `ossh.key.push.completion.sshDir`
- `ossh.parameter.completion.formHost`
- `ossh.permission.fix`
- `ossh.pull.config`
- `ossh.pull.dir`
- `ossh.pull.id`
- `ossh.pull.key`
- `ossh.push.config`
- `ossh.push.dir`
- `ossh.push.id`
- `ossh.push.key`
- `ossh.scp`
- `ossh.server.ip.get`
- `ossh.server.ip.get.darwin`
- `ossh.server.ip.get.linux`
- `ossh.server.port.get`
- `ossh.set`
- `ossh.set.completion`
- `ossh.set.completion.object`
- `private.ossh.config.complete.hosts`
- `private.ossh.config.deploy.write`
- `private.ossh.config.forwardAgent.get.completion.configItem`
- `private.ossh.config.forwardAgent.set.completion.configItem`
- `private.ossh.config.hostName.get.completion.configItem`
- `private.ossh.config.hostName.set.completion.configItem`
- `private.ossh.config.identitiesOnly.get.completion.configItem`
- `private.ossh.config.identitiesOnly.set.completion.configItem`
- `private.ossh.config.identityFile.get.completion.configItem`
- `private.ossh.config.identityFile.set.completion.configItem`
- `private.ossh.config.port.get.completion.configItem`
- `private.ossh.config.port.set.completion.configItem`
- `private.ossh.config.proxyJump.get.completion.configItem`
- `private.ossh.config.proxyJump.set.completion.configItem`
- `private.ossh.config.user.get.completion.configItem`
- `private.ossh.config.user.set.completion.configItem`
- `private.ossh.dispatch`
- `private.ossh.dispatch.objects`
- `private.ossh.get.config`
- `private.ossh.hostKnown`
- `private.ossh.validConfigBlock`
- `private.push.init.oosh`

</details>

## 3. Same name, different body

<details><summary><b>Changed</b> (78)</summary>

- `ossh.config.create`
- `ossh.config.edit`
- `ossh.config.field.get`
- `ossh.config.field.get.completion.configItem`
- `ossh.config.field.get.completion.field`
- `ossh.config.get`
- `ossh.config.list`
- `ossh.config.parse`
- `ossh.config.parse.completion`
- `ossh.config.parse.url`
- `ossh.config.pull`
- `ossh.config.push`
- `ossh.config.push.completion`
- `ossh.config.save.last`
- `ossh.config.set`
- `ossh.config.set.completion.configItem`
- `ossh.config.set.completion.field`
- `ossh.config.set.completion.value`
- `ossh.connection.close`
- `ossh.connection.close.completion.host`
- `ossh.connection.open`
- `ossh.connection.open.completion.host`
- `ossh.connection.status.completion.host`
- `ossh.dir.pull`
- `ossh.dir.push`
- `ossh.dir.push.completion`
- `ossh.exec`
- `ossh.exec.completion`
- `ossh.id.create`
- `ossh.id.pull`
- `ossh.id.push`
- `ossh.install`
- `ossh.install.completion`
- `ossh.install.continue.local`
- `ossh.install.finish.local`
- `ossh.isInstalled`
- `ossh.key.pull`
- `ossh.key.push`
- `ossh.list`
- `ossh.list.open.ports`
- `ossh.login`
- `ossh.login.completion`
- `ossh.parameter.completion.dir`
- `ossh.show`
- `ossh.ssh.parameter.get`
- `ossh.ssh.parameter.get.completion`
- `ossh.start`
- `ossh.status`
- `ossh.test`
- `ossh.url.get`
- `ossh.url.get.completion`
- `ossh.usage`
- `private.config.create`
- `private.ossh.config.field.get`
- `private.ossh.config.field.set`
- `private.ossh.config.forwardAgent.get`
- `private.ossh.config.forwardAgent.set`
- `private.ossh.config.forwardAgent.set.completion.value`
- `private.ossh.config.hostName.get`
- `private.ossh.config.hostName.set`
- `private.ossh.config.identitiesOnly.get`
- `private.ossh.config.identitiesOnly.set`
- `private.ossh.config.identitiesOnly.set.completion.value`
- `private.ossh.config.identityFile.get`
- `private.ossh.config.identityFile.set`
- `private.ossh.config.identityFile.set.completion.value`
- `private.ossh.config.port.get`
- `private.ossh.config.port.set`
- `private.ossh.config.port.set.completion.value`
- `private.ossh.config.proxyJump.get`
- `private.ossh.config.proxyJump.set`
- `private.ossh.config.proxyJump.set.completion.value`
- `private.ossh.config.user.get`
- `private.ossh.config.user.set`
- `private.ossh.config.user.set.completion.value`
- `private.ossh.rsync`
- `private.ossh.rsync.pull`
- `private.ossh.ssh`

</details>

## 4. What actually differs

**Naming.** `dev` enforces object.verb throughout (`ossh.key.push`, `ossh.authorized.keys.update`,
`ossh.config.field.get`); `mcdonges` keeps the older verb-first names (`push.key`, `pull.key`,
`get.public.id`, `server.ip.get`) next to object.verb ones, and both branches renamed the same
calls differently. A call that names a method directly is therefore branch-specific.

**A dispatcher that only mcdonges has.** `ossh get <object> <field>` / `ossh set …`,
implemented by `private.ossh.dispatch.objects`. Nothing in the tree calls it — not even on
mcdonges — so it is dead API, not a dev gap.

**Behaviour behind the shared names.**

| Verb | `dev` | `mcdonges` |
|---|---|---|
| `exec` | `private.ossh.ssh` + `ossh.remote.prelude.get` (works mid-install) | raw `ssh … "source config/user.env; …"` |
| `config.create` | writes a "last" block; `config.save.last` appends it | appends to `~/.ssh/config` via `deploy.write` |
| `key.push` | pushes the Host's `IdentityFile` key, verifies the login, enforces 644 | rsyncs a named key, then `user update.authorized_keys` |
| `config.pull` | inline Host-name check + atomic whole-file write | `hostKnown` + `validConfigBlock` helpers |
| `folder.fix`, `harden`, `config.shared.*`, `cmd/prereqs`, `key.revoke`, `exec.tty` | exist | absent |
| `install` | split: `continue.local` / `finish.local` / `log` / `user.remote` | one-shot `private.push.init.oosh` |

**No-python.** The burn-down (`test/test.no-python`, mcdonges only) counts non-comment lines
matching `python3|python -|-m json.tool`. `ossh` makes **no interpreter call on either branch**;
`dev` has one textual mention — `compgen -W "bash curl git wget tree expect python3 jq"` in
`ossh.cmd.completion.pkg`, a package name offered by completion, not an invocation. Because the
gate is textual it would still count that line, so adopting the gate on `dev` needs that word
rewritten. The real remaining sites are `claudeCode` (11 dev / 9 mcdonges), `scrumMaster`
(15/9), `hiveMind` (6/2) and one in `oo` (1/0) — not `ossh`.

**Layout repair.** Only `dev` has `ossh folder.fix` (identity bag + `~/.ssh` perms +
IdentityFile normalisation). On mcdonges the layout is whatever `user init` wrote.


## 5. Caller compatibility

| Call | `dev` | `mcdonges` |
|---|:--:|:--:|
| `ossh key.push` / `key.pull` | Y | Y |
| `ossh push.key` / `pull.key` (deprecated alias) | – | Y |
| `ossh key.revoke` | Y | – |
| `ossh authorized.keys.update` | Y | – |
| `ossh authorized_keys.update` | – | Y |
| `ossh server.get.ip` | Y | – |
| `ossh server.ip.get` | – | Y |
| `ossh rights.fix` | Y | – |
| `ossh permission.fix` | – | Y |
| `ossh get` / `ossh set` (dispatcher) | – | Y (unused) |
| `ossh config.field.get` | Y | Y |
| `ossh config.set` | Y | Y |
| `ossh config.delete` | Y | – |
| `ossh harden`, `folder.fix`, `cmd`, `prereqs.install`, `install.log` | Y | – |
| `ossh create.and.install` | Y | – |
| `ossh install.create` | – | Y |
| `ossh scp` | – | Y (unused) |

A script written against one branch's names fails on the other for every row with a dash.

## 6. Caveats

- **Changed** is byte comparison of the method block; 3 of the 78 are docstring-only.
- Renames (same body, new name) appear as one method in each one-sided list.
- Presence is parsed from top-level `name()` definitions at column 1.
