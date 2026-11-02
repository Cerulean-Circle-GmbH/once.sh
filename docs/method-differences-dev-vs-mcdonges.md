# Method differences — `origin/dev` vs `origin/test/mcdonges.latest`

Generated 2026-11-02 from the two branch tips `7ab831d9` (dev) and `760552c7` (mcdonges.latest).

A *method* here is a top-level bash function: a line starting at column 1 with
`name()` or `function name`. Its block runs from that line to the line before the next
definition, so the docstring and any `test.case` / `expect` wiring directly below it count as
part of the method. Two methods are equal when their block text is identical.

Status meanings:

- **changed** — same name in both branches, different block (split into *code* and *doc-only*).
- **added** — exists on `mcdonges.latest`, not on `dev` (in a file both branches have).
- **removed** — exists on `dev`, not on `mcdonges.latest` (in a file both branches have).
- **relocated** — same name and same code, but a different file on the other branch (moved by
  the `dev` load/ownership refactor).

Test files written as straight-line scripts (no top-level functions, e.g. `test/test.claudeCode`
on `mcdonges`) have no methods to compare; they are listed at the end as whole-file differences.

## Totals

| Scope | changed | added | removed |
|---|---:|---:|---:|
| Product scripts | 470 | 181 | 694 |
| Test files, method-style | 35 | 22 | 540 |
| Test files, script-style (whole file) | 0 | 1 | 259 |
| **All compared files** | **505** | **204** | **1493** |

The script-style row counts names that only exist on the function-style side of a file that is
straight-line on the other; they are moved out of the per-file tables and listed as whole-file
differences instead.

Of the 505 changed methods, 488 differ in code
and 17 only in their docstring/comment.

## Product scripts

### changed

| Method | File | Note |
|---|---|---|
| `backup.config.list.all` | `backup` |  |
| `backup.config.register` | `backup` |  |
| `backup.config.register.existing` | `backup` |  |
| `backup.config.save` | `backup` |  |
| `backup.config.unregister` | `backup` |  |
| `backup.config.which` | `backup` |  |
| `backup.diff` | `backup` |  |
| `backup.diff.completion` | `backup` |  |
| `backup.full.diff` | `backup` |  |
| `backup.here` | `backup` |  |
| `backup.normalize.file` | `backup` |  |
| `backup.normalize.revert` | `backup` |  |
| `backup.parameter.completion.dir` | `backup` |  |
| `backup.parameter.completion.logMode` | `backup` |  |
| `backup.start` | `backup` |  |
| `backup.status` | `backup` |  |
| `backup.stop` | `backup` |  |
| `backup.sync.and.remove` | `backup` |  |
| `backup.usage` | `backup` |  |
| `backup.verify.sync` | `backup` |  |
| `private.backup.repair.config` | `backup` |  |
| `private.backup.resolve.paths` | `backup` |  |
| `private.backup.rsync` | `backup` |  |
| `private.complete.folders` | `backup` | doc only |
| `certificates.once.scenario.select` | `certificates` |  |
| `certificates.once.scenario.select.completion` | `certificates` |  |
| `check.call` | `check` |  |
| `check.condition` | `check` |  |
| `check.file` | `check` |  |
| `check.fix` | `check` |  |
| `check.start` | `check` |  |
| `claudeCode.agent.start` | `claudeCode` |  |
| `claudeCode.context.all` | `claudeCode` |  |
| `claudeCode.context.check` | `claudeCode` |  |
| `claudeCode.context.dashboard` | `claudeCode` |  |
| `claudeCode.context.jsonl` | `claudeCode` |  |
| `claudeCode.fork` | `claudeCode` |  |
| `claudeCode.fork.byPane` | `claudeCode` |  |
| `claudeCode.fork.to` | `claudeCode` |  |
| `claudeCode.install` | `claudeCode` |  |
| `claudeCode.join.byID` | `claudeCode` |  |
| `claudeCode.join.byPane` | `claudeCode` |  |
| `claudeCode.list` | `claudeCode` |  |
| `claudeCode.session.probe.fromCapture` | `claudeCode` |  |
| `claudeCode.stop` | `claudeCode` |  |
| `private.claudeCode.context.from.jsonl` | `claudeCode` |  |
| `private.claudeCode.context.jsonl.lag` | `claudeCode` |  |
| `private.claudeCode.max.tokens.for.jsonl` | `claudeCode` |  |
| `private.claudeCode.session.jsonl.scan` | `claudeCode` |  |
| `private.claudeCode.session.resolve` | `claudeCode` |  |
| `config.add` | `config` |  |
| `config.bash.minimal.version` | `config` |  |
| `config.check.completion` | `config` |  |
| `config.clean` | `config` |  |
| `config.completion.discover` | `config` |  |
| `config.delete` | `config` |  |
| `config.edit` | `config` |  |
| `config.file.check` | `config` | doc only |
| `config.get` | `config` |  |
| `config.init` | `config` |  |
| `config.list` | `config` |  |
| `config.list.completion.name` | `config` |  |
| `config.location` | `config` | doc only |
| `config.save` | `config` |  |
| `config.set` | `config` |  |
| `config.start` | `config` |  |
| `context.lifecycle.pre.compact` | `context` |  |
| `context.lifecycle.save` | `context` |  |
| `context.lifecycle.status` | `context` |  |
| `context.recover` | `context` |  |
| `context.start` | `context` |  |
| `context.validate` | `context` |  |
| `private.context.role.list` | `context` |  |
| `debug.v` | `debug` |  |
| `expect.error` | `debug` |  |
| `disk.install.samba.support` | `disk` |  |
| `disk.start` | `disk` |  |
| `hiveMind.agent.approve` | `hiveMind` |  |
| `hiveMind.agent.dismiss` | `hiveMind` |  |
| `hiveMind.agent.fork.best` | `hiveMind` |  |
| `hiveMind.agent.handoff` | `hiveMind` |  |
| `hiveMind.agent.monitor.cycle` | `hiveMind` |  |
| `hiveMind.agent.option` | `hiveMind` |  |
| `hiveMind.agent.queue.clear` | `hiveMind` |  |
| `hiveMind.agent.queue.drain` | `hiveMind` |  |
| `hiveMind.agent.queue.list` | `hiveMind` |  |
| `hiveMind.agent.reject` | `hiveMind` |  |
| `hiveMind.agent.rename` | `hiveMind` |  |
| `hiveMind.agent.restart.remote` | `hiveMind` |  |
| `hiveMind.agent.rewind` | `hiveMind` |  |
| `hiveMind.agent.send` | `hiveMind` |  |
| `hiveMind.agent.session.probe` | `hiveMind` |  |
| `hiveMind.agent.spawn` | `hiveMind` |  |
| `hiveMind.agent.state.set` | `hiveMind` |  |
| `hiveMind.agent.train` | `hiveMind` |  |
| `hiveMind.agent.unblock` | `hiveMind` |  |
| `hiveMind.consistency.audit` | `hiveMind` |  |
| `hiveMind.consistency.reconcile` | `hiveMind` |  |
| `hiveMind.context.record` | `hiveMind` |  |
| `hiveMind.dashboard` | `hiveMind` |  |
| `hiveMind.delegate` | `hiveMind` |  |
| `hiveMind.git.commit` | `hiveMind` |  |
| `hiveMind.join` | `hiveMind` |  |
| `hiveMind.metrics.log` | `hiveMind` |  |
| `hiveMind.metrics.summary` | `hiveMind` |  |
| `hiveMind.pane.sweep` | `hiveMind` |  |
| `hiveMind.path.fix` | `hiveMind` |  |
| `hiveMind.plan.create` | `hiveMind` |  |
| `hiveMind.plan.improve` | `hiveMind` |  |
| `hiveMind.protected.pane.moved` | `hiveMind` |  |
| `hiveMind.protected.panes.swapped` | `hiveMind` |  |
| `hiveMind.protected.session.renamed` | `hiveMind` |  |
| `hiveMind.protected.team.import` | `hiveMind` |  |
| `hiveMind.registry.remove` | `hiveMind` |  |
| `hiveMind.resolve` | `hiveMind` |  |
| `hiveMind.resolve.completion.agentName` | `hiveMind` |  |
| `hiveMind.roles.list.uuids` | `hiveMind` |  |
| `hiveMind.shell.reap` | `hiveMind` |  |
| `hiveMind.shell.reap.dry` | `hiveMind` |  |
| `hiveMind.task.delegate` | `hiveMind` |  |
| `hiveMind.team.audit` | `hiveMind` |  |
| `hiveMind.team.host.set` | `hiveMind` |  |
| `hiveMind.team.list` | `hiveMind` |  |
| `hiveMind.team.migrate` | `hiveMind` |  |
| `hiveMind.team.migrate.completion.sshHost` | `hiveMind` |  |
| `hiveMind.team.pull` | `hiveMind` |  |
| `hiveMind.team.push` | `hiveMind` |  |
| `hiveMind.team.push.completion.sshHost` | `hiveMind` |  |
| `hiveMind.team.recover` | `hiveMind` |  |
| `hiveMind.team.remove` | `hiveMind` |  |
| `hiveMind.team.setup` | `hiveMind` |  |
| `hiveMind.team.setup.full` | `hiveMind` |  |
| `hiveMind.team.state.set` | `hiveMind` |  |
| `hiveMind.team.sweep` | `hiveMind` |  |
| `hiveMind.team.switch` | `hiveMind` |  |
| `hiveMind.teams.migrate` | `hiveMind` |  |
| `hiveMind.teams.restore` | `hiveMind` |  |
| `private.hiveMind.agent.unblock.pane` | `hiveMind` |  |
| `private.hiveMind.channel.resolve` | `hiveMind` |  |
| `private.hiveMind.context.denom.for.target` | `hiveMind` |  |
| `private.hiveMind.context.from.jsonl.reading` | `hiveMind` |  |
| `private.hiveMind.context.live.jsonl` | `hiveMind` |  |
| `private.hiveMind.get.role.prompt` | `hiveMind` |  |
| `private.hiveMind.handler.agent.renamed.title` | `hiveMind` |  |
| `private.hiveMind.handler.pane.moved.registry` | `hiveMind` |  |
| `private.hiveMind.handler.panes.swapped.registry` | `hiveMind` |  |
| `private.hiveMind.handler.team.destroyed.registry` | `hiveMind` |  |
| `private.hiveMind.handler.team.restored.tronMonitor` | `hiveMind` |  |
| `private.hiveMind.live.tupleset` | `hiveMind` |  |
| `private.hiveMind.reconcile.check.i1` | `hiveMind` |  |
| `private.hiveMind.reconcile.check.i10` | `hiveMind` |  |
| `private.hiveMind.reconcile.check.i2` | `hiveMind` |  |
| `private.hiveMind.reconcile.check.i3` | `hiveMind` |  |
| `private.hiveMind.reconcile.check.i6` | `hiveMind` |  |
| `private.hiveMind.reconcile.check.i8` | `hiveMind` |  |
| `private.hiveMind.reconcile.check.i9` | `hiveMind` |  |
| `private.hiveMind.shell.reap.impl` | `hiveMind` |  |
| `private.hiveMind.snapshot.row.valid` | `hiveMind` |  |
| `private.hiveMind.sweep.detect` | `hiveMind` |  |
| `checkAndFix` | `init/once` |  |
| `info.log` | `init/once` |  |
| `once.check.root.ssh.initialized` | `init/once` |  |
| `once.docker.scenario.log` | `init/once` | doc only |
| `once.docker.scenario.status` | `init/once` |  |
| `once.hibernate` | `init/once` |  |
| `once.install.oosh` | `init/once` |  |
| `once.repo.init` | `init/once` |  |
| `once.su.check.installation` | `init/once` |  |
| `once.su.group.discover.id` | `init/once` |  |
| `once.su.user.create` | `init/once` |  |
| `once.su.user.developer` | `init/once` |  |
| `once.su.user.discover` | `init/once` |  |
| `private.docker.scenario.delete.pgv` | `init/once` |  |
| `private.state.initialized` | `init/once` |  |
| `private.state.not.installed` | `init/once` |  |
| `line.format` | `line` |  |
| `line.format.force.update` | `line` |  |
| `line.init` | `line` |  |
| `line.remove.emptyLines` | `line` | doc only |
| `line.replace` | `line` |  |
| `private.line.format.init` | `line` |  |
| `clear.resultFiles` | `log` |  |
| `console.log` | `log` |  |
| `debug.log` | `log` |  |
| `err.log` | `log` |  |
| `important.log` | `log` |  |
| `log.cls` | `log` |  |
| `log.device` | `log` |  |
| `log.init` | `log` |  |
| `log.live` | `log` |  |
| `log.live.file` | `log` |  |
| `log.start` | `log` |  |
| `log.usage` | `log` |  |
| `problem.log` | `log` |  |
| `silent.log` | `log` |  |
| `stop.log` | `log` |  |
| `success.log` | `log` |  |
| `test.console.log` | `log` |  |
| `warn.log` | `log` |  |
| `loop.start` | `loop` |  |
| `loop.this` | `loop` |  |
| `private.call.custom.completion` | `ng/2c` |  |
| `c2.completion.discover` | `ng/c2` |  |
| `c2.completion.enable` | `ng/c2` |  |
| `c2.file.completion` | `ng/c2` | doc only |
| `c2.function.completion` | `ng/c2` |  |
| `c2.install.linux` | `ng/c2` |  |
| `c2.start` | `ng/c2` |  |
| `private.call.custom.completion` | `ng/c2` |  |
| `odocker.build` | `odocker` |  |
| `odocker.build.all` | `odocker` | doc only |
| `odocker.clone` | `odocker` | doc only |
| `odocker.create` | `odocker` |  |
| `odocker.file.find` | `odocker` |  |
| `odocker.file.find.completion.containerOrImage` | `odocker` |  |
| `odocker.install` | `odocker` |  |
| `odocker.prune` | `odocker` |  |
| `odocker.rebuild` | `odocker` |  |
| `odocker.reset` | `odocker` |  |
| `odocker.rm` | `odocker` |  |
| `odocker.rm.completion.container` | `odocker` | doc only |
| `odocker.rmi` | `odocker` |  |
| `odocker.run` | `odocker` |  |
| `odocker.run.sshd` | `odocker` |  |
| `odocker.start` | `odocker` |  |
| `odocker.stop` | `odocker` |  |
| `odocker.up` | `odocker` |  |
| `odocker.usage` | `odocker` |  |
| `odocker.workspace.get` | `odocker` |  |
| `odocker.workspace.set` | `odocker` |  |
| `private.odocker.docker.socket.opt` | `odocker` |  |
| `private.odocker.port.offset` | `odocker` |  |
| `oo.branches.check` | `oo` |  |
| `oo.checkout` | `oo` |  |
| `oo.checkout.completion.version` | `oo` |  |
| `oo.cmd` | `oo` |  |
| `oo.cmd.find` | `oo` |  |
| `oo.commit` | `oo` |  |
| `oo.install.dev` | `oo` |  |
| `oo.mode` | `oo` |  |
| `oo.mode.base.get` | `oo` |  |
| `oo.mode.base.set` | `oo` |  |
| `oo.mode.list` | `oo` |  |
| `oo.new` | `oo` |  |
| `oo.parameter.completion.branch` | `oo` |  |
| `oo.release` | `oo` |  |
| `oo.start` | `oo` |  |
| `oo.state` | `oo` |  |
| `oo.update` | `oo` |  |
| `oo.use` | `oo` |  |
| `oo.use.completion.branch` | `oo` |  |
| `oo.use.completion.command` | `oo` |  |
| `private.check.all.pm` | `oo` |  |
| `private.check.headless.setup.started` | `oo` |  |
| `private.check.once.setup.started` | `oo` |  |
| `private.check.pm` | `oo` |  |
| `private.check.priviledges.checked` | `oo` |  |
| `private.check.root.installation.done` | `oo` |  |
| `private.check.root.shared.dev.folder.created` | `oo` |  |
| `private.check.user.mode.release` | `oo` |  |
| `private.check.user.shared.dev.folder.linked` | `oo` |  |
| `private.init.state.machine` | `oo` |  |
| `private.install.dev.configs` | `oo` |  |
| `os.check` | `os` |  |
| `os.check.env` | `os` |  |
| `os.info` | `os` |  |
| `os.start` | `os` |  |
| `os.usage` | `os` |  |
| `ossh.config.create` | `ossh` |  |
| `ossh.config.edit` | `ossh` |  |
| `ossh.config.field.get` | `ossh` |  |
| `ossh.config.field.get.completion.configItem` | `ossh` |  |
| `ossh.config.field.get.completion.field` | `ossh` |  |
| `ossh.config.get` | `ossh` |  |
| `ossh.config.list` | `ossh` |  |
| `ossh.config.parse` | `ossh` |  |
| `ossh.config.parse.completion` | `ossh` |  |
| `ossh.config.parse.url` | `ossh` |  |
| `ossh.config.pull` | `ossh` |  |
| `ossh.config.push` | `ossh` |  |
| `ossh.config.push.completion` | `ossh` |  |
| `ossh.config.save.last` | `ossh` |  |
| `ossh.config.set` | `ossh` |  |
| `ossh.config.set.completion.configItem` | `ossh` |  |
| `ossh.config.set.completion.field` | `ossh` |  |
| `ossh.config.set.completion.value` | `ossh` |  |
| `ossh.connection.close` | `ossh` |  |
| `ossh.connection.close.completion.host` | `ossh` |  |
| `ossh.connection.open` | `ossh` |  |
| `ossh.connection.open.completion.host` | `ossh` |  |
| `ossh.connection.status.completion.host` | `ossh` |  |
| `ossh.dir.pull` | `ossh` |  |
| `ossh.dir.push` | `ossh` |  |
| `ossh.dir.push.completion` | `ossh` |  |
| `ossh.exec` | `ossh` |  |
| `ossh.exec.completion` | `ossh` |  |
| `ossh.id.create` | `ossh` |  |
| `ossh.id.pull` | `ossh` |  |
| `ossh.id.push` | `ossh` |  |
| `ossh.install` | `ossh` |  |
| `ossh.install.completion` | `ossh` |  |
| `ossh.install.continue.local` | `ossh` |  |
| `ossh.install.finish.local` | `ossh` |  |
| `ossh.isInstalled` | `ossh` |  |
| `ossh.key.pull` | `ossh` |  |
| `ossh.key.push` | `ossh` |  |
| `ossh.list` | `ossh` |  |
| `ossh.list.open.ports` | `ossh` |  |
| `ossh.login` | `ossh` |  |
| `ossh.login.completion` | `ossh` |  |
| `ossh.parameter.completion.dir` | `ossh` | doc only |
| `ossh.show` | `ossh` |  |
| `ossh.ssh.parameter.get` | `ossh` |  |
| `ossh.ssh.parameter.get.completion` | `ossh` |  |
| `ossh.start` | `ossh` |  |
| `ossh.status` | `ossh` |  |
| `ossh.test` | `ossh` | doc only |
| `ossh.url.get` | `ossh` |  |
| `ossh.url.get.completion` | `ossh` |  |
| `ossh.usage` | `ossh` | doc only |
| `private.config.create` | `ossh` |  |
| `private.ossh.config.field.get` | `ossh` |  |
| `private.ossh.config.field.set` | `ossh` |  |
| `private.ossh.config.forwardAgent.get` | `ossh` |  |
| `private.ossh.config.forwardAgent.set` | `ossh` |  |
| `private.ossh.config.forwardAgent.set.completion.value` | `ossh` |  |
| `private.ossh.config.hostName.get` | `ossh` |  |
| `private.ossh.config.hostName.set` | `ossh` |  |
| `private.ossh.config.identitiesOnly.get` | `ossh` |  |
| `private.ossh.config.identitiesOnly.set` | `ossh` |  |
| `private.ossh.config.identitiesOnly.set.completion.value` | `ossh` |  |
| `private.ossh.config.identityFile.get` | `ossh` |  |
| `private.ossh.config.identityFile.set` | `ossh` |  |
| `private.ossh.config.identityFile.set.completion.value` | `ossh` |  |
| `private.ossh.config.port.get` | `ossh` |  |
| `private.ossh.config.port.set` | `ossh` |  |
| `private.ossh.config.port.set.completion.value` | `ossh` |  |
| `private.ossh.config.proxyJump.get` | `ossh` |  |
| `private.ossh.config.proxyJump.set` | `ossh` |  |
| `private.ossh.config.proxyJump.set.completion.value` | `ossh` |  |
| `private.ossh.config.user.get` | `ossh` |  |
| `private.ossh.config.user.set` | `ossh` |  |
| `private.ossh.config.user.set.completion.value` | `ossh` |  |
| `private.ossh.rsync` | `ossh` |  |
| `private.ossh.rsync.pull` | `ossh` |  |
| `private.ossh.ssh` | `ossh` |  |
| `otest.browser.open` | `otest` |  |
| `otest.deploy` | `otest` |  |
| `otest.newTest` | `otest` |  |
| `otest.parameter.completion.branch` | `otest` |  |
| `otest.run` | `otest` |  |
| `otest.setup` | `otest` |  |
| `otest.start` | `otest` |  |
| `private.ensureVenv` | `otest` |  |
| `private.python` | `otest` |  |
| `private.runTest` | `otest` |  |
| `private.testExists` | `otest` |  |
| `private.testNames` | `otest` |  |
| `otmux.attach` | `otmux` |  |
| `otmux.fit` | `otmux` |  |
| `otmux.pane.history` | `otmux` |  |
| `otmux.pane.size` | `otmux` |  |
| `otmux.pane.swap` | `otmux` |  |
| `otmux.parameter.completion.target` | `otmux` |  |
| `otmux.send.submit` | `otmux` |  |
| `otmux.send.tui` | `otmux` |  |
| `otmux.session.rename` | `otmux` |  |
| `otmux.status` | `otmux` |  |
| `otmux.window.rename` | `otmux` |  |
| `otmux.zoom` | `otmux` |  |
| `private.otmux.notifyHiveMind.shifted` | `otmux` |  |
| `private.otmux.send.prefix` | `otmux` |  |
| `private.resolve.target` | `otmux` |  |
| `path.add` | `path` |  |
| `path.append` | `path` |  |
| `path.edit` | `path` |  |
| `path.env` | `path` | doc only |
| `path.list` | `path` |  |
| `path.load` | `path` |  |
| `path.parameter.completion.dir` | `path` |  |
| `path.prepend` | `path` |  |
| `path.push` | `path` |  |
| `path.put` | `path` |  |
| `path.remove` | `path` |  |
| `path.rm` | `path` |  |
| `path.save` | `path` |  |
| `path.start` | `path` |  |
| `path.usage` | `path` |  |
| `replace.by` | `replace` |  |
| `replace.cleanup` | `replace` |  |
| `replace.commit` | `replace` |  |
| `replace.rollback` | `replace` |  |
| `replace.usage` | `replace` |  |
| `private.scrumMaster.health.check` | `scrumMaster` | doc only |
| `private.scrumMaster.health.evaluate` | `scrumMaster` |  |
| `private.scrumMaster.metrics.save` | `scrumMaster` |  |
| `private.scrumMaster.rewind.markname` | `scrumMaster` |  |
| `private.scrumMaster.subscription` | `scrumMaster` |  |
| `private.scrumMaster.subscription.auth` | `scrumMaster` |  |
| `private.scrumMaster.swipe.classify` | `scrumMaster` |  |
| `private.scrumMaster.swipe.ctx` | `scrumMaster` |  |
| `private.scrumMaster.swipe.role` | `scrumMaster` |  |
| `private.scrumMaster.swipe.subtree` | `scrumMaster` |  |
| `private.scrumMaster.velocity.target` | `scrumMaster` | doc only |
| `scrumMaster.context.read` | `scrumMaster` |  |
| `scrumMaster.dashboard` | `scrumMaster` |  |
| `scrumMaster.metrics.collect` | `scrumMaster` |  |
| `scrumMaster.rewind.mark` | `scrumMaster` |  |
| `scrumMaster.rewind.unmark` | `scrumMaster` |  |
| `scrumMaster.subscription.scan` | `scrumMaster` |  |
| `scrumMaster.swipe` | `scrumMaster` |  |
| `scrumMaster.velocity.check` | `scrumMaster` |  |
| `share.samba.install` | `share` |  |
| `share.start` | `share` |  |
| `snet.start` | `snet` |  |
| `snet.update` | `snet` |  |
| `private.loop.states` | `state` |  |
| `private.state.update.current.machine` | `state` |  |
| `state.add` | `state` |  |
| `state.check` | `state` |  |
| `state.find` | `state` |  |
| `state.id` | `state` |  |
| `state.list` | `state` |  |
| `state.machine.declaration` | `state` |  |
| `state.machine.delete` | `state` |  |
| `state.machine.exists` | `state` |  |
| `state.name` | `state` |  |
| `state.next` | `state` |  |
| `state.of` | `state` |  |
| `status.discover` | `status` |  |
| `setup.docker` | `su/setup` |  |
| `setup.headless` | `su/setup` |  |
| `setup.nodejs` | `su/setup` |  |
| `setup.npm` | `su/setup` |  |
| `setup.nvm` | `su/setup` |  |
| `setup.samba.support` | `su/setup` |  |
| `setup.start` | `su/setup` |  |
| `setup.usage` | `su/setup` |  |
| `add_to_completion` | `templates/user/c2.install` |  |
| `check.debug.level` | `this` |  |
| `create.result` | `this` |  |
| `info.log` | `this` |  |
| `result.into` | `this` |  |
| `result.load` | `this` |  |
| `result.save` | `this` |  |
| `this.call` | `this` |  |
| `this.functionExists` | `this` |  |
| `this.init` | `this` |  |
| `this.isEmpty` | `this` | doc only |
| `this.isSourced` | `this` |  |
| `this.load` | `this` |  |
| `this.path.add` | `this` |  |
| `this.scope` | `this` |  |
| `this.start` | `this` |  |
| `private.get.basehome.darwin` | `user` |  |
| `private.get.home.darwin` | `user` |  |
| `private.user.init` | `user` |  |
| `user.create` | `user` |  |
| `user.get.current.identity` | `user` |  |
| `user.group.add` | `user` |  |
| `user.group.check` | `user` |  |
| `user.in` | `user` |  |
| `user.init` | `user` |  |
| `user.list.other.identities` | `user` |  |
| `user.login` | `user` |  |
| `user.ssh.backup` | `user` |  |
| `user.ssh.restore` | `user` |  |
| `user.start` | `user` |  |
| `user.usage` | `user` |  |
| `webitem.create` | `webitem` |  |

### added (mcdonges only)

| Method | File |
|---|---|
| `backup.capture.log.mode` | `backup` |
| `backup.get.backupPath` | `backup` |
| `backup.get.backupPath.completion` | `backup` |
| `backup.get.relative.path` | `backup` |
| `backup.list.errors` | `backup` |
| `backup.list.last.diff.result` | `backup` |
| `backup.list.last.result.raw` | `backup` |
| `backup.list.notBackuped` | `backup` |
| `backup.list.onlyInBackup` | `backup` |
| `backup.list.onlyInSource` | `backup` |
| `backup.list.onlyInTarget` | `backup` |
| `backup.list.same` | `backup` |
| `backup.list.same.completion` | `backup` |
| `backup.replace.by.folderLink` | `backup` |
| `backup.replace.by.folderLink.completion` | `backup` |
| `backup.replace.same.with.folderLinks` | `backup` |
| `backup.source` | `backup` |
| `backup.source.completion` | `backup` |
| `backup.target` | `backup` |
| `backup.target.completion` | `backup` |
| `certificates.once.scenarios` | `certificates` |
| `certificates.parameter.scenario.completion` | `certificates` |
| `private.call.it` | `check` |
| `private.fix.it` | `check` |
| `claudeCode.jsonl.usage` | `claudeCode` |
| `private.claudeCode.isPaneTarget` | `claudeCode` |
| `private.claudeCode.isRoleName` | `claudeCode` |
| `private.claudeCode.isUuid` | `claudeCode` |
| `_oo_commands` | `config` |
| `config.completion.install` | `config` |
| `config.folder.create` | `config` |
| `config.path.create` | `config` |
| `step` | `debug` |
| `disk.calc.getBytesInGB` | `disk` |
| `disk.calc.getBytesInKB` | `disk` |
| `disk.calc.getBytesInMB` | `disk` |
| `disk.calc.getBytesInTB` | `disk` |
| `disk.calc.getGB` | `disk` |
| `disk.calc.getKB` | `disk` |
| `disk.calc.getMB` | `disk` |
| `disk.calc.getTB` | `disk` |
| `private.hiveMind.isPaneTarget` | `hiveMind` |
| `private.hiveMind.isPipeSafe` | `hiveMind` |
| `private.hiveMind.isRoleName` | `hiveMind` |
| `private.hiveMind.isSessionName` | `hiveMind` |
| `private.hiveMind.isSshHost` | `hiveMind` |
| `private.hiveMind.isUuid` | `hiveMind` |
| `private.hiveMind.resolve.guard` | `hiveMind` |
| `private.hiveMind.resolve.heal` | `hiveMind` |
| `private.hiveMind.resolve.liveMap` | `hiveMind` |
| `_once_commands` | `init/once` |
| `once.docker.scenario.go` | `init/once` |
| `once.docker.scenario.go.completion` | `init/once` |
| `line.config.clean` | `line` |
| `line.function.find` | `line` |
| `line.parameter.get` | `line` |
| `c2.format.functions` | `ng/c2` |
| `c2.get.formated.function.description` | `ng/c2` |
| `c2.get.function.declaration` | `ng/c2` |
| `c2.get.function.parameter` | `ng/c2` |
| `c2.get.function.with.documentation` | `ng/c2` |
| `c2.get.functions` | `ng/c2` |
| `odocker.build.completion.workspace` | `odocker` |
| `private.odocker.ensure.socket.access` | `odocker` |
| `oo.mode.sync` | `oo` |
| `oo.new.method` | `oo` |
| `oo.new.test` | `oo` |
| `private.oo.mode.resolve.branch` | `oo` |
| `private.oo.sed.first` | `oo` |
| `private.oo.tmp.cleanup.testing` | `oo` |
| `os.hostname.get` | `os` |
| `os.hostname.info` | `os` |
| `os.hostname.set` | `os` |
| `private.os.hostname.get.darwin` | `os` |
| `private.os.hostname.get.linux` | `os` |
| `private.os.hostname.info.darwin` | `os` |
| `private.os.hostname.info.linux` | `os` |
| `private.os.hostname.set.darwin` | `os` |
| `private.os.hostname.set.linux` | `os` |
| `ossh.authorized_keys.update` | `ossh` |
| `ossh.dir.pull.completion.dir` | `ossh` |
| `ossh.dir.push.completion.dir` | `ossh` |
| `ossh.get` | `ossh` |
| `ossh.get.completion` | `ossh` |
| `ossh.get.completion.object` | `ossh` |
| `ossh.get.public.id` | `ossh` |
| `ossh.id.create.completion.sshDir` | `ossh` |
| `ossh.id.file.get` | `ossh` |
| `ossh.id.public.get` | `ossh` |
| `ossh.id.pull.completion.sshDir` | `ossh` |
| `ossh.install.create` | `ossh` |
| `ossh.key.folder.create` | `ossh` |
| `ossh.key.folder.delete` | `ossh` |
| `ossh.key.name.get` | `ossh` |
| `ossh.key.name.set` | `ossh` |
| `ossh.key.pull.completion.dir` | `ossh` |
| `ossh.key.push.completion` | `ossh` |
| `ossh.key.push.completion.sshDir` | `ossh` |
| `ossh.parameter.completion.formHost` | `ossh` |
| `ossh.permission.fix` | `ossh` |
| `ossh.pull.config` | `ossh` |
| `ossh.pull.dir` | `ossh` |
| `ossh.pull.id` | `ossh` |
| `ossh.pull.key` | `ossh` |
| `ossh.push.config` | `ossh` |
| `ossh.push.dir` | `ossh` |
| `ossh.push.id` | `ossh` |
| `ossh.push.key` | `ossh` |
| `ossh.scp` | `ossh` |
| `ossh.server.ip.get` | `ossh` |
| `ossh.server.ip.get.darwin` | `ossh` |
| `ossh.server.ip.get.linux` | `ossh` |
| `ossh.server.port.get` | `ossh` |
| `ossh.set` | `ossh` |
| `ossh.set.completion` | `ossh` |
| `ossh.set.completion.object` | `ossh` |
| `private.ossh.config.complete.hosts` | `ossh` |
| `private.ossh.config.deploy.write` | `ossh` |
| `private.ossh.config.forwardAgent.get.completion.configItem` | `ossh` |
| `private.ossh.config.forwardAgent.set.completion.configItem` | `ossh` |
| `private.ossh.config.hostName.get.completion.configItem` | `ossh` |
| `private.ossh.config.hostName.set.completion.configItem` | `ossh` |
| `private.ossh.config.identitiesOnly.get.completion.configItem` | `ossh` |
| `private.ossh.config.identitiesOnly.set.completion.configItem` | `ossh` |
| `private.ossh.config.identityFile.get.completion.configItem` | `ossh` |
| `private.ossh.config.identityFile.set.completion.configItem` | `ossh` |
| `private.ossh.config.port.get.completion.configItem` | `ossh` |
| `private.ossh.config.port.set.completion.configItem` | `ossh` |
| `private.ossh.config.proxyJump.get.completion.configItem` | `ossh` |
| `private.ossh.config.proxyJump.set.completion.configItem` | `ossh` |
| `private.ossh.config.user.get.completion.configItem` | `ossh` |
| `private.ossh.config.user.set.completion.configItem` | `ossh` |
| `private.ossh.dispatch` | `ossh` |
| `private.ossh.dispatch.objects` | `ossh` |
| `private.ossh.get.config` | `ossh` |
| `private.ossh.hostKnown` | `ossh` |
| `private.ossh.validConfigBlock` | `ossh` |
| `private.push.init.oosh` | `ossh` |
| `private.otmux.observer.notify` | `otmux` |
| `private.otmux.pane.role.parse` | `otmux` |
| `path.add.completion.dir` | `path` |
| `path.append.completion.dir` | `path` |
| `path.file.global` | `path` |
| `path.file.global.use` | `path` |
| `path.file.user` | `path` |
| `path.file.user.edit` | `path` |
| `path.file.user.save` | `path` |
| `path.file.user.set` | `path` |
| `path.prepend.completion.dir` | `path` |
| `path.push.completion.dir` | `path` |
| `path.remove.completion.dir` | `path` |
| `path.rm.completion.dir` | `path` |
| `path.show.once.path` | `path` |
| `path.show.oosh.path` | `path` |
| `path.status` | `path` |
| `path.sync` | `path` |
| `private.pathadd` | `path` |
| `private.pathrm` | `path` |
| `private.update.config` | `path` |
| `private.scrumMaster.creds.expired` | `scrumMaster` |
| `private.scrumMaster.swipe.classify.active` | `scrumMaster` |
| `private.scrumMaster.swipe.role.display` | `scrumMaster` |
| `private.scrumMaster.swipe.role.parse` | `scrumMaster` |
| `setup.headless.enable` | `su/setup` |
| `setup.status.headless` | `su/setup` |
| `private.this.oosh.dir.invariant` | `this` |
| `user.check.group` | `user` |
| `user.delete.linux` | `user` |
| `user.ssh.create.folders` | `user` |
| `user.ssh.get.file.name` | `user` |
| `user.ssh.get.key.name` | `user` |
| `user.ssh.rename.files` | `user` |
| `user.ssh.rootkey.file.push` | `user` |
| `user.ssh.rootkey.file.revoke` | `user` |
| `user.ssh.rootkey.pull` | `user` |
| `user.ssh.rootkey.push` | `user` |
| `user.ssh.rootkey.push.completion` | `user` |
| `user.ssh.set.key.name` | `user` |
| `user.ssh.status` | `user` |
| `user.ssh.status.completion` | `user` |
| `user.update.authorized_keys` | `user` |

### removed (dev only)

| Method | File |
|---|---|
| `backup.backupPath.get` | `backup` |
| `backup.backupPath.get.completion` | `backup` |
| `backup.errors.list` | `backup` |
| `backup.file.list.notBackedUp` | `backup` |
| `backup.file.list.onlyInBackup` | `backup` |
| `backup.file.list.onlyInSource` | `backup` |
| `backup.file.list.onlyInTarget` | `backup` |
| `backup.file.list.same` | `backup` |
| `backup.file.list.same.completion` | `backup` |
| `backup.folderLink.replace.by` | `backup` |
| `backup.folderLink.replace.by.completion` | `backup` |
| `backup.folderLinks.replace.same.with` | `backup` |
| `backup.log.capture.mode` | `backup` |
| `backup.parameter.completion.configPath` | `backup` |
| `backup.path.get.relative` | `backup` |
| `backup.result.list.lastDiff` | `backup` |
| `backup.result.list.lastRaw` | `backup` |
| `private.backup.file.list.notBackedUp` | `backup` |
| `private.backup.file.list.onlyInBackup` | `backup` |
| `private.backup.file.list.onlyInSource` | `backup` |
| `private.backup.file.list.onlyInTarget` | `backup` |
| `private.backup.file.list.same` | `backup` |
| `private.backup.get.backupPath` | `backup` |
| `private.backup.get.relative.path` | `backup` |
| `private.backup.list.errors` | `backup` |
| `private.backup.log.capture.mode` | `backup` |
| `private.backup.replace.by.folderLink` | `backup` |
| `private.backup.replace.same.with.folderLinks` | `backup` |
| `private.backup.result.list.lastDiff` | `backup` |
| `private.backup.result.list.lastRaw` | `backup` |
| `certificates.once.scenario.list` | `certificates` |
| `certificates.parameter.completion.scenario` | `certificates` |
| `private.check.call.execute` | `check` |
| `private.check.fix.execute` | `check` |
| `claudeCode.parameter.completion.captureText` | `claudeCode` |
| `claudeCode.parameter.completion.cleanTitle` | `claudeCode` |
| `claudeCode.parameter.completion.file` | `claudeCode` |
| `claudeCode.parameter.completion.model` | `claudeCode` |
| `claudeCode.parameter.completion.nameFilter` | `claudeCode` |
| `claudeCode.parameter.completion.pane` | `claudeCode` |
| `claudeCode.parameter.completion.path` | `claudeCode` |
| `claudeCode.parameter.completion.state` | `claudeCode` |
| `claudeCode.parameter.completion.uuid` | `claudeCode` |
| `claudeCode.parameter.completion.workdir` | `claudeCode` |
| `private.claudeCode.file.mtime.get` | `claudeCode` |
| `private.claudeCode.file.mtime.human.get` | `claudeCode` |
| `private.claudeCode.jsonl.files.list` | `claudeCode` |
| `config.host.name.get` | `config` |
| `config.host.name.get.completion.name` | `config` |
| `config.host.name.refresh` | `config` |
| `config.init.check` | `config` |
| `config.init.check.completion.username` | `config` |
| `config.init.env` | `config` |
| `config.init.env.completion` | `config` |
| `config.init.full` | `config` |
| `config.init.full.completion.username` | `config` |
| `config.init.shared` | `config` |
| `config.init.shared.completion` | `config` |
| `config.init.user` | `config` |
| `config.init.user.completion.username` | `config` |
| `config.parameter.completion.name` | `config` |
| `config.parameter.completion.sshConfigName` | `config` |
| `config.session.save` | `config` |
| `config.session.save.completion` | `config` |
| `config.unset` | `config` |
| `config.validate` | `config` |
| `config.validate.completion.name` | `config` |
| `config.validate.required` | `config` |
| `config.validate.required.completion` | `config` |
| `private.config.chain.names.get` | `config` |
| `private.config.derive.bash.file` | `config` |
| `private.config.derive.config.file` | `config` |
| `private.config.derive.log.level` | `config` |
| `private.config.derive.oosh.mode` | `config` |
| `private.config.derive.oosh.os` | `config` |
| `private.config.derive.oosh.pm` | `config` |
| `private.config.env.line.append` | `config` |
| `private.config.env.lines.drop` | `config` |
| `private.config.file.resolve` | `config` |
| `private.config.homes.list` | `config` |
| `private.config.host.container.name.get` | `config` |
| `private.config.host.name.get` | `config` |
| `private.config.host.name.refresh` | `config` |
| `private.config.linked.homes.get` | `config` |
| `private.config.log.chain.migrate` | `config` |
| `private.config.oosh.session.file.get` | `config` |
| `private.config.oosh.session.migrate` | `config` |
| `private.config.oosh.session.split.is` | `config` |
| `private.config.path.line.absolute.get` | `config` |
| `private.config.path.line.get` | `config` |
| `private.config.path.segments.get` | `config` |
| `private.config.pm.command.get` | `config` |
| `private.config.required.file.path.get` | `config` |
| `private.config.required.variables.get` | `config` |
| `private.config.save` | `config` |
| `private.config.session.chain.ready` | `config` |
| `private.config.session.file.ensure` | `config` |
| `private.config.session.split.is` | `config` |
| `private.config.string.upper` | `config` |
| `private.config.user.session.file.get` | `config` |
| `private.config.user.session.migrate` | `config` |
| `private.config.variable.export.line` | `config` |
| `private.config.variables.export` | `config` |
| `private.config.variables.list` | `config` |
| `debug.noop` | `debug` |
| `debug.noop.completion` | `debug` |
| `debug.onError` | `debug` |
| `debug.onExit` | `debug` |
| `debug.onReturn` | `debug` |
| `debug.removeTrap` | `debug` |
| `debug.removeTrap.completion` | `debug` |
| `debug.setTrap` | `debug` |
| `debug.setTrap.completion` | `debug` |
| `debug.stackTrace` | `debug` |
| `debug.stackTrace.completion` | `debug` |
| `debug.step` | `debug` |
| `debug.step.completion` | `debug` |
| `debug.toggleDebug` | `debug` |
| `debug.toggleDebug.completion` | `debug` |
| `debug.v.completion` | `debug` |
| `disk.calc.bytes.from.gb` | `disk` |
| `disk.calc.bytes.from.kb` | `disk` |
| `disk.calc.bytes.from.mb` | `disk` |
| `disk.calc.bytes.from.tb` | `disk` |
| `disk.calc.bytes.to.gb` | `disk` |
| `disk.calc.bytes.to.kb` | `disk` |
| `disk.calc.bytes.to.mb` | `disk` |
| `disk.calc.bytes.to.tb` | `disk` |
| `hiveMind.focus.completion.agentId` | `hiveMind` |
| `hiveMind.monitor.approve` | `hiveMind` |
| `hiveMind.monitor.approve.completion.option` | `hiveMind` |
| `hiveMind.monitor.completion.session` | `hiveMind` |
| `hiveMind.parameter.completion.agent` | `hiveMind` |
| `hiveMind.parameter.completion.agentId` | `hiveMind` |
| `hiveMind.parameter.completion.arg` | `hiveMind` |
| `hiveMind.parameter.completion.auth` | `hiveMind` |
| `hiveMind.parameter.completion.denomK` | `hiveMind` |
| `hiveMind.parameter.completion.eventName` | `hiveMind` |
| `hiveMind.parameter.completion.filter` | `hiveMind` |
| `hiveMind.parameter.completion.fromPane` | `hiveMind` |
| `hiveMind.parameter.completion.handlerFunction` | `hiveMind` |
| `hiveMind.parameter.completion.host` | `hiveMind` |
| `hiveMind.parameter.completion.oldName` | `hiveMind` |
| `hiveMind.parameter.completion.option` | `hiveMind` |
| `hiveMind.parameter.completion.pane` | `hiveMind` |
| `hiveMind.parameter.completion.paneA` | `hiveMind` |
| `hiveMind.parameter.completion.paneB` | `hiveMind` |
| `hiveMind.parameter.completion.pct` | `hiveMind` |
| `hiveMind.parameter.completion.role` | `hiveMind` |
| `hiveMind.parameter.completion.s` | `hiveMind` |
| `hiveMind.parameter.completion.sessionFilter` | `hiveMind` |
| `hiveMind.parameter.completion.session_filter` | `hiveMind` |
| `hiveMind.parameter.completion.target` | `hiveMind` |
| `hiveMind.parameter.completion.toPane` | `hiveMind` |
| `hiveMind.parameter.completion.type` | `hiveMind` |
| `hiveMind.parameter.completion.usedK` | `hiveMind` |
| `hiveMind.parameter.completion.workdir` | `hiveMind` |
| `hiveMind.spawn.completion.type` | `hiveMind` |
| `hiveMind.team.setup.full.completion.session` | `hiveMind` |
| `hiveMind.team.setup.oosh.completion.session` | `hiveMind` |
| `private.hiveMind.handler.agent.renamed.role_env` | `hiveMind` |
| `private.hiveMind.handler.pane.moved.role_env` | `hiveMind` |
| `private.hiveMind.handler.panes.swapped.role_env` | `hiveMind` |
| `private.hiveMind.pane.pushRoleEnv` | `hiveMind` |
| `private.once.commands` | `init/once` |
| `line.clean.config` | `line` |
| `line.filter.emptyLines` | `line` |
| `line.find.function` | `line` |
| `line.get.parameter` | `line` |
| `line.remove.exact` | `line` |
| `line.remove.exact.completion.text` | `line` |
| `private.line.format.save` | `line` |
| `log.device.completion.device` | `log` |
| `log.install` | `log` |
| `log.install.errors` | `log` |
| `log.install.finish` | `log` |
| `log.install.init` | `log` |
| `log.install.live` | `log` |
| `log.live.panes` | `log` |
| `log.live.panes.stop` | `log` |
| `log.name` | `log` |
| `log.name.completion` | `log` |
| `log.session` | `log` |
| `log.session.save` | `log` |
| `private.log.device.is.capture` | `log` |
| `private.log.device.is.session` | `log` |
| `private.log.device.probe` | `log` |
| `private.log.emit` | `log` |
| `private.log.session.write` | `log` |
| `mycmd.1` | `mycmd` |
| `mycmd.2` | `mycmd` |
| `mycmd.3` | `mycmd` |
| `mycmd.4` | `mycmd` |
| `c2.function.declaration.get` | `ng/c2` |
| `c2.function.description.format` | `ng/c2` |
| `c2.function.get.with.documentation` | `ng/c2` |
| `c2.function.parameter.get` | `ng/c2` |
| `c2.functions.format` | `ng/c2` |
| `c2.functions.get` | `ng/c2` |
| `c2.parameter.completion.functionNameFilter` | `ng/c2` |
| `c2.parameter.completion.method` | `ng/c2` |
| `c2.parameter.completion.path` | `ng/c2` |
| `c2.parameter.completion.script` | `ng/c2` |
| `c2.signature.validate` | `ng/c2` |
| `c2.signature.validate.completion.script` | `ng/c2` |
| `private.c2.format.functions` | `ng/c2` |
| `private.c2.get.formated.function.description` | `ng/c2` |
| `private.c2.get.function.declaration` | `ng/c2` |
| `private.c2.get.function.parameter` | `ng/c2` |
| `private.c2.get.function.with.documentation` | `ng/c2` |
| `private.c2.get.functions` | `ng/c2` |
| `odocker.container.create` | `odocker` |
| `odocker.container.ip.get` | `odocker` |
| `odocker.container.oosh.install` | `odocker` |
| `odocker.container.oosh.install.completion.image` | `odocker` |
| `odocker.container.remove` | `odocker` |
| `odocker.container.remove.completion.container` | `odocker` |
| `odocker.container.ssh.prune` | `odocker` |
| `odocker.container.ssh.start` | `odocker` |
| `odocker.container.ssh.start.completion.image` | `odocker` |
| `odocker.container.stop` | `odocker` |
| `odocker.exec.command` | `odocker` |
| `odocker.exec.command.completion.container` | `odocker` |
| `odocker.image.command` | `odocker` |
| `odocker.image.remove` | `odocker` |
| `odocker.image.remove.completion.image` | `odocker` |
| `odocker.parameter.completion.from` | `odocker` |
| `odocker.parameter.completion.toHost` | `odocker` |
| `odocker.parameter.completion.user` | `odocker` |
| `odocker.prereqs.install` | `odocker` |
| `odocker.prereqs.install.completion.user` | `odocker` |
| `odocker.rmi.completion.image` | `odocker` |
| `odocker.socket.group.ensure` | `odocker` |
| `odocker.socket.group.ensure.completion.socket` | `odocker` |
| `odocker.support.check` | `odocker` |
| `odocker.workspace.get.completion.path` | `odocker` |
| `odocker.workspace.init` | `odocker` |
| `odocker.workspace.init.completion.path` | `odocker` |
| `odocker.workspace.install` | `odocker` |
| `odocker.workspace.install.completion.path` | `odocker` |
| `odocker.workspace.push` | `odocker` |
| `odocker.workspace.push.completion.image` | `odocker` |
| `odocker.workspace.push.completion.path` | `odocker` |
| `odocker.workspace.seed` | `odocker` |
| `odocker.workspace.seed.completion.path` | `odocker` |
| `private.odocker.container.list.findable` | `odocker` |
| `private.odocker.container.name.new` | `odocker` |
| `private.odocker.container.prereqs.install` | `odocker` |
| `private.odocker.container.repo.add` | `odocker` |
| `private.odocker.container.ssh.config` | `odocker` |
| `private.odocker.container.ssh.forget` | `odocker` |
| `private.odocker.container.ssh.host.is` | `odocker` |
| `private.odocker.container.ssh.master` | `odocker` |
| `private.odocker.container.ssh.port.get` | `odocker` |
| `private.odocker.container.ssh.undo` | `odocker` |
| `private.odocker.container.sshd.reload` | `odocker` |
| `private.odocker.container.sudo.nopasswd` | `odocker` |
| `private.odocker.docker.config.keyless` | `odocker` |
| `private.odocker.docker.registry` | `odocker` |
| `private.odocker.docker.repo.add` | `odocker` |
| `private.odocker.docker.repo.download` | `odocker` |
| `private.odocker.docker.repo.get` | `odocker` |
| `private.odocker.engine.start` | `odocker` |
| `private.odocker.engine.supported` | `odocker` |
| `private.odocker.env.chained` | `odocker` |
| `private.odocker.image.list.findable` | `odocker` |
| `private.odocker.image.list.sshd` | `odocker` |
| `private.odocker.image.local.ensure` | `odocker` |
| `private.odocker.image.sshd.is` | `odocker` |
| `private.odocker.image.user.get` | `odocker` |
| `private.odocker.passwd.users.get` | `odocker` |
| `private.odocker.port.user.get` | `odocker` |
| `private.odocker.ports.get` | `odocker` |
| `private.odocker.prereq.package.get` | `odocker` |
| `private.odocker.prereqs.ensure` | `odocker` |
| `private.odocker.socket.access.ensure` | `odocker` |
| `private.odocker.socket.get` | `odocker` |
| `private.odocker.socket.gid.check` | `odocker` |
| `private.odocker.socket.group.ensure` | `odocker` |
| `private.odocker.ssh.hosts.local.get` | `odocker` |
| `private.odocker.terminal.is` | `odocker` |
| `private.odocker.workspaces.default.get` | `odocker` |
| `private.odocker.workspaces.entry.same` | `odocker` |
| `private.odocker.workspaces.fetch.ssh` | `odocker` |
| `private.odocker.workspaces.fetch.url` | `odocker` |
| `private.odocker.workspaces.host.path.get` | `odocker` |
| `private.odocker.workspaces.legacy.path.get` | `odocker` |
| `private.odocker.workspaces.merge` | `odocker` |
| `private.odocker.workspaces.merge.answer.get` | `odocker` |
| `private.odocker.workspaces.mine` | `odocker` |
| `private.odocker.workspaces.push.files.get` | `odocker` |
| `private.odocker.workspaces.push.filter` | `odocker` |
| `private.odocker.workspaces.push.image.get` | `odocker` |
| `private.odocker.workspaces.push.select` | `odocker` |
| `private.odocker.workspaces.source.host.get` | `odocker` |
| `private.odocker.workspaces.source.url.get` | `odocker` |
| `oo.branch.list` | `oo` |
| `oo.branch.list.completion.source` | `oo` |
| `oo.checkout.remove` | `oo` |
| `oo.checkout.remove.completion.version` | `oo` |
| `oo.cmd.completion.packageName` | `oo` |
| `oo.dev.to.testing` | `oo` |
| `oo.method.delete` | `oo` |
| `oo.method.delete.completion.script` | `oo` |
| `oo.method.new` | `oo` |
| `oo.mode.align` | `oo` |
| `oo.mode.base.set.completion.path` | `oo` |
| `oo.mode.completion.branch` | `oo` |
| `oo.mode.setup` | `oo` |
| `oo.mode.stage` | `oo` |
| `oo.parameter.completion.baseBranch` | `oo` |
| `oo.parameter.completion.cmd` | `oo` |
| `oo.parameter.completion.packageName` | `oo` |
| `oo.parameter.completion.reset` | `oo` |
| `oo.parameter.completion.stage` | `oo` |
| `oo.parameter.completion.username` | `oo` |
| `oo.pm.env.get` | `oo` |
| `oo.pm.env.get.completion.pm` | `oo` |
| `oo.pm.get` | `oo` |
| `oo.pm.install.prefix.get` | `oo` |
| `oo.pm.install.prefix.get.completion.pmCmd` | `oo` |
| `oo.prereqs.install` | `oo` |
| `oo.promote.report` | `oo` |
| `oo.promote.status` | `oo` |
| `oo.safeDirectory.prune` | `oo` |
| `oo.shared.init` | `oo` |
| `oo.shared.init.completion` | `oo` |
| `oo.stage` | `oo` |
| `oo.test.new` | `oo` |
| `oo.test.platform.new` | `oo` |
| `oo.test.platform.new.completion.aspect` | `oo` |
| `oo.test.platform.new.completion.scope` | `oo` |
| `oo.testing.to.prod` | `oo` |
| `oo.tmp.cleanup.testing` | `oo` |
| `oo.user.check` | `oo` |
| `oo.user.fix` | `oo` |
| `oo.user.init` | `oo` |
| `oo.user.repair` | `oo` |
| `private.check.root.boot.path.installed` | `oo` |
| `private.oo.bashrc.ensure.all` | `oo` |
| `private.oo.branch.clone.ensure` | `oo` |
| `private.oo.checkout.dir.get` | `oo` |
| `private.oo.cmd.verify` | `oo` |
| `private.oo.completion.worktree.branches` | `oo` |
| `private.oo.dev.to.testing` | `oo` |
| `private.oo.developking.key.place` | `oo` |
| `private.oo.dropin.remove` | `oo` |
| `private.oo.find.cmd` | `oo` |
| `private.oo.install.branch.get` | `oo` |
| `private.oo.install.launcher` | `oo` |
| `private.oo.install.shim` | `oo` |
| `private.oo.layout.folder.check` | `oo` |
| `private.oo.method.end.get` | `oo` |
| `private.oo.method.name.resolve` | `oo` |
| `private.oo.method.stubs.get` | `oo` |
| `private.oo.mode.env.file.write` | `oo` |
| `private.oo.new.method` | `oo` |
| `private.oo.new.test` | `oo` |
| `private.oo.once.path.migrate` | `oo` |
| `private.oo.path.sudo.get` | `oo` |
| `private.oo.path.writable.is` | `oo` |
| `private.oo.pm.env.get` | `oo` |
| `private.oo.pm.install.prefix.get` | `oo` |
| `private.oo.promote.report` | `oo` |
| `private.oo.promote.status` | `oo` |
| `private.oo.regex.escape.get` | `oo` |
| `private.oo.session.files.ensure.all` | `oo` |
| `private.oo.shared.tree.ensure` | `oo` |
| `private.oo.shared.tree.from.local` | `oo` |
| `private.oo.source.consume.gate` | `oo` |
| `private.oo.update.heal.symlinks` | `oo` |
| `private.oo.user.shared.symlinks.ensure` | `oo` |
| `os.platform.list` | `os` |
| `os.platform.parse.check` | `os` |
| `os.platform.parse.check.completion.platform` | `os` |
| `os.platform.test` | `os` |
| `os.platform.test.all` | `os` |
| `os.platform.test.completion.notests` | `os` |
| `os.platform.test.completion.platform` | `os` |
| `os.platform.test.completion.terminal` | `os` |
| `os.service.off` | `os` |
| `os.service.on` | `os` |
| `private.os.release.get` | `os` |
| `private.os.service.off.darwin` | `os` |
| `private.os.service.off.linux` | `os` |
| `private.os.service.on.darwin` | `os` |
| `private.os.service.on.linux` | `os` |
| `private.os.shell.files.list` | `os` |
| `private.os.systemd.is` | `os` |
| `ossh.authorized.keys.update` | `ossh` |
| `ossh.cmd` | `ossh` |
| `ossh.cmd.completion.pkg` | `ossh` |
| `ossh.cmd.completion.sshConfigHost` | `ossh` |
| `ossh.config.create.completion.idOrProxyJump` | `ossh` |
| `ossh.config.create.completion.identitiesOnly` | `ossh` |
| `ossh.config.create.completion.proxyJump` | `ossh` |
| `ossh.config.delete` | `ossh` |
| `ossh.config.delete.completion` | `ossh` |
| `ossh.config.shared.create` | `ossh` |
| `ossh.config.shared.create.completion.deployKeySrc` | `ossh` |
| `ossh.config.shared.create.completion.sharedDir` | `ossh` |
| `ossh.config.shared.github.create` | `ossh` |
| `ossh.config.shared.github.create.completion.configFile` | `ossh` |
| `ossh.config.shared.github.create.completion.knownHosts` | `ossh` |
| `ossh.config.shared.seed.fallback` | `ossh` |
| `ossh.config.shared.seed.fallback.completion.sshConfigHost` | `ossh` |
| `ossh.config.shared.seed.from.local.deploy.key` | `ossh` |
| `ossh.config.shared.seed.from.local.deploy.key.completion.sshConfigHost` | `ossh` |
| `ossh.config.shared.seed.github` | `ossh` |
| `ossh.config.shared.seed.github.completion.sshConfigHost` | `ossh` |
| `ossh.create.and.install` | `ossh` |
| `ossh.exec.tty` | `ossh` |
| `ossh.exec.tty.completion` | `ossh` |
| `ossh.file.get.name` | `ossh` |
| `ossh.folder.fix` | `ossh` |
| `ossh.folder.fix.check` | `ossh` |
| `ossh.folder.fix.check.completion.sshDir` | `ossh` |
| `ossh.folder.fix.completion.installerEmail` | `ossh` |
| `ossh.folder.fix.completion.mode` | `ossh` |
| `ossh.folder.fix.completion.sshDir` | `ossh` |
| `ossh.harden` | `ossh` |
| `ossh.harden.completion.sshConfigHost` | `ossh` |
| `ossh.harden.fail2ban` | `ossh` |
| `ossh.harden.fail2ban.completion.sshConfigHost` | `ossh` |
| `ossh.harden.firewall` | `ossh` |
| `ossh.harden.firewall.completion.extraPorts` | `ossh` |
| `ossh.harden.firewall.completion.sshConfigHost` | `ossh` |
| `ossh.harden.packages` | `ossh` |
| `ossh.harden.packages.completion.sshConfigHost` | `ossh` |
| `ossh.harden.sshd` | `ossh` |
| `ossh.harden.sshd.allowusers` | `ossh` |
| `ossh.harden.sshd.allowusers.completion.sshConfigHost` | `ossh` |
| `ossh.harden.sshd.allowusers.completion.users` | `ossh` |
| `ossh.harden.sshd.completion.sshConfigHost` | `ossh` |
| `ossh.harden.unattended.upgrades` | `ossh` |
| `ossh.harden.unattended.upgrades.completion.sshConfigHost` | `ossh` |
| `ossh.install.log` | `ossh` |
| `ossh.install.log.completion.sshConfigHost` | `ossh` |
| `ossh.install.user.remote` | `ossh` |
| `ossh.key.folders.create` | `ossh` |
| `ossh.key.folders.delete` | `ossh` |
| `ossh.key.get.name` | `ossh` |
| `ossh.key.revoke` | `ossh` |
| `ossh.key.set.name` | `ossh` |
| `ossh.known.hosts.remove` | `ossh` |
| `ossh.known.hosts.remove.completion` | `ossh` |
| `ossh.parameter.completion.fromHost` | `ossh` |
| `ossh.parameter.completion.remoteSshConfigName` | `ossh` |
| `ossh.parameter.completion.sshConfigNameUsedForLocal` | `ossh` |
| `ossh.parameter.completion.sshKeyName` | `ossh` |
| `ossh.parameter.completion.user` | `ossh` |
| `ossh.pm.discover` | `ossh` |
| `ossh.pm.discover.completion.sshConfigHost` | `ossh` |
| `ossh.prereqs.install` | `ossh` |
| `ossh.prereqs.install.completion.sshConfigHost` | `ossh` |
| `ossh.publicId.get` | `ossh` |
| `ossh.remote.prelude.get` | `ossh` |
| `ossh.remote.prelude.get.completion` | `ossh` |
| `ossh.rights.fix` | `ossh` |
| `ossh.rights.fix.completion.sshDir` | `ossh` |
| `ossh.server.get.ip` | `ossh` |
| `ossh.server.get.ip.darwin` | `ossh` |
| `ossh.server.get.ip.linux` | `ossh` |
| `ossh.server.get.port` | `ossh` |
| `private.ossh.authorized.key.append.get` | `ossh` |
| `private.ossh.config.block.put.get` | `ossh` |
| `private.ossh.config.field.keyword.get` | `ossh` |
| `private.ossh.config.last.file.get` | `ossh` |
| `private.ossh.config.pull` | `ossh` |
| `private.ossh.config.push` | `ossh` |
| `private.ossh.config.push.completion` | `ossh` |
| `private.ossh.connection.error.get` | `ossh` |
| `private.ossh.connection.error.network.is` | `ossh` |
| `private.ossh.control.path.get` | `ossh` |
| `private.ossh.control.path.resolved.get` | `ossh` |
| `private.ossh.create.key.folders` | `ossh` |
| `private.ossh.delete.key.folders` | `ossh` |
| `private.ossh.dir.pull` | `ossh` |
| `private.ossh.dir.push` | `ossh` |
| `private.ossh.dir.push.completion` | `ossh` |
| `private.ossh.folder.fix.config.normalize` | `ossh` |
| `private.ossh.folder.fix.config.strip.legacy` | `ossh` |
| `private.ossh.folder.fix.prune` | `ossh` |
| `private.ossh.folder.fix.scan.git.remotes` | `ossh` |
| `private.ossh.get.current.key.file.name` | `ossh` |
| `private.ossh.get.file.name` | `ossh` |
| `private.ossh.get.key.name` | `ossh` |
| `private.ossh.get.public.id` | `ossh` |
| `private.ossh.get.server.ip` | `ossh` |
| `private.ossh.get.server.port.wrapper` | `ossh` |
| `private.ossh.get.ssh.parameter` | `ossh` |
| `private.ossh.get.url` | `ossh` |
| `private.ossh.github.block.is.oosh` | `ossh` |
| `private.ossh.github.copies.remove` | `ossh` |
| `private.ossh.github.copy.remove` | `ossh` |
| `private.ossh.harden.preflight` | `ossh` |
| `private.ossh.host.fqdn.get` | `ossh` |
| `private.ossh.id.push` | `ossh` |
| `private.ossh.identity.stage` | `ossh` |
| `private.ossh.identity.stage.outer.fromRunner` | `ossh` |
| `private.ossh.identity.stage.outer.proxyJump` | `ossh` |
| `private.ossh.install.key.authorize` | `ossh` |
| `private.ossh.key.pull` | `ossh` |
| `private.ossh.key.push` | `ossh` |
| `private.ossh.key.push.identity.get` | `ossh` |
| `private.ossh.master.start` | `ossh` |
| `private.ossh.oosh.init.push` | `ossh` |
| `private.ossh.public.key.get` | `ossh` |
| `private.ossh.public.key.put.text.get` | `ossh` |
| `private.ossh.pull.id` | `ossh` |
| `private.ossh.remote.key.file.name.get` | `ossh` |
| `private.ossh.remote.public.key.put` | `ossh` |
| `private.ossh.set.key.name` | `ossh` |
| `private.ossh.shared.ssh.legacy.remove` | `ossh` |
| `private.ossh.system.config.file.get` | `ossh` |
| `private.ossh.system.known.hosts.get` | `ossh` |
| `private.ossh.user.homes.get` | `ossh` |
| `private.ossh.users.basehome` | `ossh` |
| `otmux.pane.command` | `otmux` |
| `otmux.parameter.completion.file` | `otmux` |
| `otmux.parameter.completion.option` | `otmux` |
| `otmux.parameter.completion.pane` | `otmux` |
| `otmux.parameter.completion.spec` | `otmux` |
| `otmux.send.keys` | `otmux` |
| `path.parameter.completion.file` | `path` |
| `path.saved` | `path` |
| `path.validate` | `path` |
| `path.validate.completion.treeRoot` | `path` |
| `private.path.lines.join` | `path` |
| `private.replace.copy.make` | `replace` |
| `replace.block` | `replace` |
| `replace.block.completion.endLine` | `replace` |
| `replace.block.completion.file` | `replace` |
| `replace.block.completion.startLine` | `replace` |
| `replace.line` | `replace` |
| `replace.lines` | `replace` |
| `replace.lines.completion.exactLine` | `replace` |
| `replace.lines.completion.file` | `replace` |
| `replace.word` | `replace` |
| `replace.word.completion.file` | `replace` |
| `replace.word.completion.word` | `replace` |
| `main` | `scrumMaster` |
| `private.scrumMaster.measure.pane` | `scrumMaster` |
| `private.scrumMaster.measure.team` | `scrumMaster` |
| `private.scrumMaster.metrics.dir.get` | `scrumMaster` |
| `scrumMaster.pane.measure` | `scrumMaster` |
| `scrumMaster.pane.measure.completion.agentName` | `scrumMaster` |
| `scrumMaster.pane.measure.completion.session` | `scrumMaster` |
| `scrumMaster.parameter.completion.machineName` | `scrumMaster` |
| `scrumMaster.parameter.completion.session` | `scrumMaster` |
| `scrumMaster.pulse` | `scrumMaster` |
| `scrumMaster.pulse.completion.session` | `scrumMaster` |
| `scrumMaster.team.measure` | `scrumMaster` |
| `scrumMaster.team.measure.completion.session` | `scrumMaster` |
| `private.setup.all.step` | `su/setup` |
| `private.setup.cmds.install` | `su/setup` |
| `private.setup.completion.users` | `su/setup` |
| `private.setup.gate` | `su/setup` |
| `private.setup.headless.darwin` | `su/setup` |
| `private.setup.headless.linux` | `su/setup` |
| `private.setup.linux.skip` | `su/setup` |
| `private.setup.nvm.is` | `su/setup` |
| `private.setup.nvm.run` | `su/setup` |
| `private.setup.package.get` | `su/setup` |
| `private.setup.pm.ensure` | `su/setup` |
| `private.setup.samba.password.darwin` | `su/setup` |
| `private.setup.samba.password.linux` | `su/setup` |
| `private.setup.samba.support.darwin` | `su/setup` |
| `private.setup.samba.support.linux` | `su/setup` |
| `private.setup.samba.users.any` | `su/setup` |
| `private.setup.services.switch` | `su/setup` |
| `private.setup.template.install` | `su/setup` |
| `private.setup.user.get` | `su/setup` |
| `private.setup.vnc.password.darwin` | `su/setup` |
| `private.setup.vnc.password.linux` | `su/setup` |
| `private.setup.vnc.unit.get` | `su/setup` |
| `setup.all` | `su/setup` |
| `setup.all.completion.user` | `su/setup` |
| `setup.docker.completion.user` | `su/setup` |
| `setup.headless.completion.user` | `su/setup` |
| `setup.nodejs.completion.user` | `su/setup` |
| `setup.nodejs.completion.version` | `su/setup` |
| `setup.npm.completion.user` | `su/setup` |
| `setup.nvm.completion.user` | `su/setup` |
| `setup.nvm.completion.version` | `su/setup` |
| `setup.samba.password` | `su/setup` |
| `setup.samba.password.completion.user` | `su/setup` |
| `setup.samba.support.completion.user` | `su/setup` |
| `setup.vnc.password` | `su/setup` |
| `setup.vnc.password.completion.user` | `su/setup` |
| `private.ensure.groupWrite` | `this` |
| `private.ensure.sharedTree` | `this` |
| `private.log.install.append` | `this` |
| `private.this.anchor.validate.one` | `this` |
| `private.this.as.user.preamble.get` | `this` |
| `private.this.config.write.guard` | `this` |
| `private.this.container.is` | `this` |
| `private.this.device.is.terminal` | `this` |
| `private.this.env.export.line.get` | `this` |
| `private.this.file.line.ensure` | `this` |
| `private.this.file.same` | `this` |
| `private.this.file.write` | `this` |
| `private.this.folder.ensure` | `this` |
| `private.this.folder.entries.copy` | `this` |
| `private.this.folder.share` | `this` |
| `private.this.group.create` | `this` |
| `private.this.group.exists` | `this` |
| `private.this.group.file.get` | `this` |
| `private.this.group.members.get` | `this` |
| `private.this.group.name.get` | `this` |
| `private.this.home.real.get` | `this` |
| `private.this.host.name.get` | `this` |
| `private.this.marker.sweep` | `this` |
| `private.this.os.family.get` | `this` |
| `private.this.path.canonical` | `this` |
| `private.this.path.case.get` | `this` |
| `private.this.path.dedup` | `this` |
| `private.this.path.owner.set` | `this` |
| `private.this.path.stat.get` | `this` |
| `private.this.path.stat.get.completion.field` | `this` |
| `private.this.shared.top.ensure` | `this` |
| `private.this.symlink.with.backup` | `this` |
| `private.this.temp.dir.get` | `this` |
| `private.this.tree.tracked.check` | `this` |
| `private.this.url.download` | `this` |
| `private.this.user.name.get` | `this` |
| `this.anchor.validate` | `this` |
| `this.anchor.validate.completion.anchor` | `this` |
| `this.anchor.validate.completion.treeRoot` | `this` |
| `this.config.path.validate` | `this` |
| `this.config.path.validate.completion.treeRoot` | `this` |
| `this.function.partial` | `this` |
| `this.function.partial.completion.existingName` | `this` |
| `this.function.partial.completion.newName` | `this` |
| `this.methodNotFound` | `this` |
| `this.oosh.dir.validate` | `this` |
| `this.oosh.dir.validate.completion.treeRoot` | `this` |
| `this.path.add.completion.dir` | `this` |
| `private.as.user` | `user` |
| `private.user.authorized.keys.adopt` | `user` |
| `private.user.authorized.keys.rebuild` | `user` |
| `private.user.basehome.system.get` | `user` |
| `private.user.bashrc.install` | `user` |
| `private.user.check.group` | `user` |
| `private.user.create.addSudoer.darwin` | `user` |
| `private.user.create.addSudoer.linux` | `user` |
| `private.user.delete.command.get` | `user` |
| `private.user.delete.command.get.completion.sbinDir` | `user` |
| `private.user.delete.linux` | `user` |
| `private.user.exists` | `user` |
| `private.user.get.sshDir` | `user` |
| `private.user.group.member.is` | `user` |
| `private.user.group.member.pending` | `user` |
| `private.user.login.term.get` | `user` |
| `private.user.oosh.install.groups.darwin` | `user` |
| `private.user.oosh.install.groups.linux` | `user` |
| `private.user.oosh.install.node` | `user` |
| `private.user.oosh.install.shell.darwin` | `user` |
| `private.user.oosh.install.shell.linux` | `user` |
| `private.user.path.owner.get` | `user` |
| `user.as` | `user` |
| `user.authorized.keys.update` | `user` |
| `user.create.completion.gid` | `user` |
| `user.create.completion.password` | `user` |
| `user.create.completion.uid` | `user` |
| `user.create.completion.username` | `user` |
| `user.group.add.completion.groupName` | `user` |
| `user.group.add.completion.toUsername` | `user` |
| `user.group.member.pending` | `user` |
| `user.group.member.pending.completion.group` | `user` |
| `user.group.member.pending.completion.user` | `user` |
| `user.info` | `user` |
| `user.linux.delete` | `user` |
| `user.oosh.install` | `user` |
| `user.oosh.install.completion.branch` | `user` |
| `user.oosh.install.completion.username` | `user` |
| `user.parameter.completion.groupName` | `user` |
| `user.parameter.completion.userName` | `user` |
| `user.password.set` | `user` |
| `user.password.set.completion.password` | `user` |
| `user.password.set.completion.username` | `user` |
| `user.password.set.darwin` | `user` |
| `user.password.set.darwin.completion.password` | `user` |
| `user.password.set.darwin.completion.username` | `user` |
| `user.password.set.linux` | `user` |
| `user.password.set.linux.completion.password` | `user` |
| `user.password.set.linux.completion.username` | `user` |
| `user.ssh.backup.completion.label` | `user` |
| `user.ssh.backup.list` | `user` |
| `user.ssh.backup.migrate` | `user` |
| `user.ssh.backup.migrate.completion.home` | `user` |
| `user.ssh.backup.status` | `user` |
| `user.ssh.backup.status.completion.home` | `user` |
| `user.ssh.restore.completion.archive` | `user` |

## Relocated

Same name, same code, different file — the `dev` refactor moved the method between scripts.

| Method | Found in | On the other branch | Direction |
|---|---|---|---|
| `private.get.sshDir` | `user` | `ossh` | mcdonges → dev |

## Scripts that exist on only one branch

Their methods are not comparable one by one; the list is the whole file. Only product scripts
are shown; the public methods (no `private.` prefix) are named, private helpers are counted.

| Branch | File | Methods | Public API |
|---|---|---:|---|
| mcdonges | `academyScript` | 4 | `academyScript.start`, `academyScript.usage` |
| mcdonges | `claudeFlow` | 139 | `claudeFlow.agent`, `claudeFlow.agent.health`, `claudeFlow.agent.kill`, `claudeFlow.agent.list`, `claudeFlow.agent.logs`, `claudeFlow.agent.ls`, `claudeFlow.agent.metrics`, `claudeFlow.agent.pool`, `claudeFlow.agent.spawn`, `claudeFlow.agent.spawn.completion.type` … (+129) |
| mcdonges | `demo` | 2 | `demo.start`, `demo.usage` |
| mcdonges | `fix` | 0 | — |
| mcdonges | `myId` | 5 | `myId.key.deploy.create`, `myId.list`, `myId.parameter.completion.id`, `myId.start`, `myId.usage` |
| mcdonges | `myScript` | 2 | `myScript.start`, `myScript.usage` |
| mcdonges | `opy` | 36 | `opy.deps`, `opy.install`, `opy.install.completion.version`, `opy.remove`, `opy.remove.completion.version`, `opy.shell.install`, `opy.shell.install.completion.rcfile`, `opy.start`, `opy.update`, `opy.update.completion.version` … (+13) |
| mcdonges | `osemvec` | 48 | `osemvec.check`, `osemvec.check.completion.target`, `osemvec.context`, `osemvec.context.completion.projectDir`, `osemvec.error`, `osemvec.error.completion.projectDir`, `osemvec.guard`, `osemvec.guard.completion.pane`, `osemvec.index`, `osemvec.index.completion.projectDir` … (+19) |
| mcdonges | `tronMonitor` | 30 | `tronMonitor.add`, `tronMonitor.add.completion.teamSession`, `tronMonitor.fit`, `tronMonitor.fit.completion.teamSession`, `tronMonitor.list`, `tronMonitor.prune`, `tronMonitor.remove`, `tronMonitor.remove.completion.teamSession`, `tronMonitor.reset`, `tronMonitor.setup` … (+8) |
| mcdonges | `tt` | 2 | `tt.start`, `tt.usage` |
| dev | `Install oosh.command` | 1 | `oosh_fetch` |
| dev | `agentRoom` | 35 | `agentRoom.agent.start`, `agentRoom.agent.status`, `agentRoom.agent.stop`, `agentRoom.backend.start`, `agentRoom.backend.status`, `agentRoom.backend.stop`, `agentRoom.chat`, `agentRoom.discover`, `agentRoom.health`, `agentRoom.install` … (+17) |
| dev | `ogit` | 131 | `ogit.binary.check`, `ogit.binary.check.completion`, `ogit.branch.adopt`, `ogit.branch.check`, `ogit.branch.checkout`, `ogit.branch.compare`, `ogit.branch.fastForward`, `ogit.branch.find`, `ogit.branch.get`, `ogit.branch.list` … (+103) |
| dev | `osshLayout` | 29 | `osshLayout.build`, `osshLayout.build.completion.installerEmail`, `osshLayout.build.completion.installerKeypairSrc`, `osshLayout.build.completion.sshDir`, `osshLayout.id.from.email`, `osshLayout.id.from.email.completion.email`, `osshLayout.perms.tighten`, `osshLayout.perms.tighten.completion.sshDir`, `osshLayout.role.developking`, `osshLayout.role.developking.completion.sshDir` … (+11) |
| dev | `platform` | 20 | `platform.list`, `platform.parse.check`, `platform.parse.check.completion.platform`, `platform.start`, `platform.test`, `platform.test.all`, `platform.test.completion.notests`, `platform.test.completion.platform`, `platform.test.completion.terminal`, `platform.usage` |
| dev | `promote` | 43 | `promote.branch.alignment`, `promote.branch.alignment.completion.from`, `promote.branch.alignment.completion.to`, `promote.dev.to.testing`, `promote.dev.to.testing.completion.reset`, `promote.prod`, `promote.report`, `promote.start`, `promote.status`, `promote.testing` … (+3) |

Test files that exist on only one branch (27 on mcdonges, 20 on dev):

<details><summary>list</summary>

- mcdonges: `test/test.claudeCode-validators` (6 methods)
- mcdonges: `test/test.composer-state` (4 methods)
- mcdonges: `test/test.context-occupancy` (1 methods)
- mcdonges: `test/test.creds-expiry` (3 methods)
- mcdonges: `test/test.events` (4 methods)
- mcdonges: `test/test.hiveMind-validators` (13 methods)
- mcdonges: `test/test.jsonl-lag` (1 methods)
- mcdonges: `test/test.lifecycle` (6 methods)
- mcdonges: `test/test.myId` (1 methods)
- mcdonges: `test/test.no-python` (3 methods)
- mcdonges: `test/test.opy` (1 methods)
- mcdonges: `test/test.osemvec` (1 methods)
- mcdonges: `test/test.pulse-removed` (6 methods)
- mcdonges: `test/test.send-composer-guard` (5 methods)
- mcdonges: `test/test.send-deliver-rc` (6 methods)
- mcdonges: `test/test.send-submit-otr1` (6 methods)
- mcdonges: `test/test.session-discover-all` (4 methods)
- mcdonges: `test/test.session-id-fresh` (0 methods)
- mcdonges: `test/test.session-resolve-drift` (5 methods)
- mcdonges: `test/test.state.correctness` (1 methods)
- mcdonges: `test/test.static-defined-functions` (12 methods)
- mcdonges: `test/test.swipe-active-narrow` (5 methods)
- mcdonges: `test/test.swipe-jsonl-lag` (3 methods)
- mcdonges: `test/test.swipe-role-live` (14 methods)
- mcdonges: `test/test.tronMonitor` (5 methods)
- mcdonges: `test/test.usage-dispatch` (0 methods)
- mcdonges: `test/test.zoom-target` (5 methods)
- dev: `test/test.completion.audit` (10 methods)
- dev: `test/test.ogit` (59 methods)
- dev: `test/test.osshLayout` (12 methods)
- dev: `test/test.otest` (2 methods)
- dev: `test/test.platform` (2 methods)
- dev: `test/test.platform.odocker.workspaces.invariant` (0 methods)
- dev: `test/test.platform.shared.boot.invariant` (1 methods)
- dev: `test/test.platform.shared.config.env.invariant` (0 methods)
- dev: `test/test.platform.shared.config.invariant` (0 methods)
- dev: `test/test.platform.shared.configLayout.invariant` (1 methods)
- dev: `test/test.platform.shared.idempotence.invariant` (8 methods)
- dev: `test/test.platform.shared.layout.invariant` (0 methods)
- dev: `test/test.platform.shared.oosh.invariant` (0 methods)
- dev: `test/test.platform.ssh.config.woda.portable` (0 methods)
- dev: `test/test.platform.ssh.layout.invariant` (0 methods)
- dev: `test/test.promote` (18 methods)
- dev: `test/test.replace` (18 methods)
- dev: `test/test.setup` (16 methods)
- dev: `test/test.ssh.config.invariant` (0 methods)
- dev: `test/test.ssh.config.woda` (0 methods)

</details>

## Files compared as a whole

These differ, but at least one side has no top-level function in them: the file is written as
a straight-line script (or carries exactly one definition). A function-level diff cannot say
more than "the file differs", so they are listed here instead of in the tables above.

| File | dev functions | mcdonges functions |
|---|---:|---:|
| `init/deinstall.oosh` | 0 | 0 |
| `test/test.absolute.path` | 0 | 0 |
| `test/test.c2` | 13 | 0 |
| `test/test.check` | 0 | 0 |
| `test/test.claudeCode` | 2 | 0 |
| `test/test.isSourced` | 0 | 0 |
| `test/test.mycmd` | 0 | 0 |
| `test/test.odocker` | 94 | 0 |
| `test/test.oosh` | 0 | 1 |
| `test/test.pm-tools` | 0 | 0 |
| `test/test.scenario.fix` | 0 | 0 |
| `test/test.test.suite` | 43 | 0 |
| `test/test.this` | 61 | 0 |
| `test/test.user` | 46 | 0 |

## Test files

Per-file counts; the full method lists are in the collapsible block.

| File | changed | added | removed |
|---|---:|---:|---:|
| `test.suite` | 11 | 9 | 41 |
| `test/test.academyScript` | 1 | 0 | 0 |
| `test/test.backup` | 1 | 0 | 0 |
| `test/test.call` | 1 | 0 | 0 |
| `test/test.certificates` | 1 | 0 | 0 |
| `test/test.config` | 1 | 0 | 123 |
| `test/test.currentUser` | 1 | 0 | 0 |
| `test/test.data/parameterTestScript` | 1 | 1 | 0 |
| `test/test.debug` | 2 | 0 | 5 |
| `test/test.fs` | 1 | 0 | 0 |
| `test/test.headless` | 1 | 0 | 0 |
| `test/test.hiveMind` | 0 | 4 | 11 |
| `test/test.install` | 0 | 1 | 34 |
| `test/test.line` | 1 | 0 | 11 |
| `test/test.log` | 0 | 1 | 22 |
| `test/test.loop` | 1 | 0 | 0 |
| `test/test.myScript` | 1 | 0 | 0 |
| `test/test.oo` | 3 | 0 | 174 |
| `test/test.os` | 0 | 1 | 4 |
| `test/test.ossh` | 1 | 0 | 75 |
| `test/test.otmux` | 0 | 1 | 2 |
| `test/test.path` | 1 | 0 | 30 |
| `test/test.scrumMaster` | 0 | 1 | 2 |
| `test/test.scrumMaster.measure` | 0 | 1 | 1 |
| `test/test.share` | 1 | 0 | 0 |
| `test/test.state` | 2 | 0 | 1 |
| `test/test.tilde` | 0 | 2 | 4 |
| `test/test.tt` | 1 | 0 | 0 |
| `test/test.webitem` | 1 | 0 | 0 |

<details><summary>Test methods, full list</summary>

**`test.suite`**

- changed (11): `expect`, `expect.fail`, `expect.pass`, `test.case`, `test.suite.all`, `test.suite.init`, `test.suite.parameter.completion.test`, `test.suite.run`, `test.suite.save.results`, `test.suite.summary`, `test.suite.usage`
- added (9): `private.test.suite.list.names`, `private.test.suite.list.tags`, `test.def`, `test.def.completion.label`, `test.suite.list`, `test.suite.list.completion.test`, `test.suite.run.completion.filter`, `test.suite.run.completion.logLevel`, `test.suite.run.completion.test`
- removed (41): `private.test.suite.category`, `private.test.suite.config.stamp.get`, `private.test.suite.counters.reset`, `private.test.suite.real.config.verify`, `private.test.suite.results.clear`, `private.test.suite.results.dir.close`, `private.test.suite.results.dir.open`, `private.test.suite.results.file.get`, `private.test.suite.run.filtered`, `private.test.suite.session.files.get`, `private.test.suite.session.restore`, `private.test.suite.session.snapshot`, `private.test.suite.shared.report`, `private.test.suite.shared.restore`, `private.test.suite.shared.snapshot`, `private.test.suite.shared.verify`, `private.test.suite.shared.waiver.get`, `private.test.suite.ssh.mode.get`, `private.test.suite.ssh.origin.get`, `private.test.suite.ssh.report`, `private.test.suite.ssh.restore`, `private.test.suite.ssh.secret.is`, `private.test.suite.ssh.secrets.changed.get`, `private.test.suite.ssh.snapshot`, `private.test.suite.ssh.stamp.get`, `private.test.suite.ssh.verify`, `private.test.suite.verdict`, `test.suite.completion.exists`, `test.suite.completion.get`, `test.suite.config.isolate`, `test.suite.config.isolate.completion.label`, `test.suite.config.restore`, `test.suite.core`, `test.suite.extended`, `test.suite.fixture.make`, `test.suite.fixture.make.completion.label`, `test.suite.gate`, `test.suite.parameter.completion.logLevel`, `test.suite.portability.validate`, `test.suite.portability.validate.completion.treeRoot`, `test.suite.skip`

**`test/test.academyScript`**

- changed (1): `test.academyScript`

**`test/test.backup`**

- changed (1): `setupTestBackup`

**`test/test.call`**

- changed (1): `test.call.recall`

**`test/test.certificates`**

- changed (1): `test.certificates`

**`test/test.config`**

- changed (1): `setup_test_config`
- removed (123): `test.config.anchorSurvivesGrandchild`, `test.config.anchorsTreeConform`, `test.config.bash32Save`, `test.config.bashrcAll`, `test.config.bashrcAllNoCmp`, `test.config.bashrcAllOwnBranch`, `test.config.bashrcEnvIInteractive`, `test.config.bashrcLogDeviceKept`, `test.config.bashrcLogOnce`, `test.config.bashrcNvmNotFirst`, `test.config.bashrcTemplateNoFunctionKeyword`, `test.config.bashrcThisFirst`, `test.config.branchIsInputNotState`, `test.config.branchNoAlias`, `test.config.chainNamesGet`, `test.config.checkAlwaysSucceeds`, `test.config.cmd.fixture`, `test.config.cmdSaveLog`, `test.config.cmdSaveOosh`, `test.config.cmdSaveUserKeepsChains`, `test.config.coldRunHasLog`, `test.config.completionOffersPerUser`, `test.config.completionsExist`, `test.config.dashSourcesGeneratedUserEnv`, `test.config.definesNoLogApi`, `test.config.deprecatedCreateGone`, `test.config.deriversAnswer`, `test.config.envLineAppend`, `test.config.envLinesDrop`, `test.config.exportLineRoundTrip`, `test.config.fallbackRedirectsMisderivedPath`, `test.config.fullExists`, `test.config.hostContainerNameGet`, `test.config.hostNameGet`, `test.config.hostNameGetPublic`, `test.config.hostNameNoHostname`, `test.config.hostNameRefresh`, `test.config.hostNameRefreshPublic`, `test.config.hostNameRefreshTwice`, `test.config.initEnvBacksUpUserEnv`, `test.config.initEnvNeverWorsens`, `test.config.initEnvRederives`, `test.config.initEnvRegensOoshEnv`, `test.config.initEnvRegensUserEnv`, `test.config.initEnvRepairsMissing`, `test.config.initHonoursGivenAnchor`, `test.config.initNoSharedTree`, `test.config.initSharedOwner`, `test.config.initUserCalls`, `test.config.initUserWriteFail`, `test.config.linkedHomesGet`, `test.config.listNoGlobalMutation`, `test.config.listReadsPerUserTier`, `test.config.logBootDoesNotSaveMidLoad`, `test.config.logChainMigrate`, `test.config.logEnvChainLast`, `test.config.logEnvLoadsSession`, `test.config.migrateWriteFail`, `test.config.noFunctionKeyword`, `test.config.noUserConfigPathVar`, `test.config.odockerSgNotSaved`, `test.config.ooshChainKept`, `test.config.ooshSessionCarriesMode`, `test.config.ooshSessionFileEnsure`, `test.config.ooshSessionGate`, `test.config.ooshSessionMigrate`, `test.config.ooshSessionSave`, `test.config.pathLine`, `test.config.pathLineLinkSpelling`, `test.config.pathLineNoCode`, `test.config.pathLinePhysicalOosh`, `test.config.realSessionUntouched`, `test.config.requiredFixture`, `test.config.requiredRun`, `test.config.saveAnchorsConstant`, `test.config.saveCaptureClean`, `test.config.saveExcludesInstall`, `test.config.saveKeepsRequired`, `test.config.saveLayoutArgs`, `test.config.saveLogEnsuresSession`, `test.config.saveMigrateWriteFail`, `test.config.saveNoAbsoluteHome`, `test.config.savePathBashDir`, `test.config.savePrefixLog`, `test.config.savePrefixOosh`, `test.config.savePreservesNonInstall`, `test.config.saveReportsInvalid`, `test.config.saveShapeAndPrefix`, `test.config.saveSurvivesBash32Stream`, `test.config.saveUserEnvLayout`, `test.config.savesBashFile`, `test.config.selfLoopRemoved`, `test.config.sessionFileEnsure`, `test.config.sessionFilesEnsureAll`, `test.config.sessionWritesOnce`, `test.config.setHandlesSpaces`, `test.config.sharedTreeIdempotent`, `test.config.sharedTreeOwner`, `test.config.startOnlyThis`, `test.config.stringQuoteDoubleQuotes`, `test.config.stringQuoteSpaces`, `test.config.tildeRunsInCleanEnvironment`, `test.config.userEnvSelfAnchors`, `test.config.userSessionDashStart`, `test.config.userSessionFileEnsure`, `test.config.userSessionGate`, `test.config.userSessionMigrate`, `test.config.userSessionPathAbsolute`, `test.config.userSessionPathFiltered`, `test.config.userSessionPathNoSessionDirs`, `test.config.userSessionPathNoSu`, `test.config.userSessionPathPhysicalOosh`, `test.config.userSessionSave`, `test.config.userSessionSaveCarriesMode`, `test.config.userSessionSaveForeignHome`, `test.config.userSessionSaveGated`, `test.config.userSessionSplit`, `test.config.validateRequired`, `test.config.variablesListShapeGate`, `test.config.variablesListTrailingUnderscore`, `test.config.writeFails`, `test.config.writeGuardWriters`, `test.config.writerValidatorAgree`

**`test/test.currentUser`**

- changed (1): `test.currentUser`

**`test/test.data/parameterTestScript`**

- changed (1): `parameterTestScript.noop`
- added (1): `parameterTestScript.apostropheDesc`

**`test/test.debug`**

- changed (2): `cleanup_debug_test`, `test_return_func`
- removed (5): `test.debug.bareRemoveTrapFixtures`, `test.debug.bareRemoveTrapIn`, `test.debug.helpersNamed`, `test.debug.methodsDocumented`, `test.debug.removeTrapKeepsResult`

**`test/test.fs`**

- changed (1): `test.fs`

**`test/test.headless`**

- changed (1): `test.headless`

**`test/test.hiveMind`**

- added (4): `__test_cleanup`, `__test_detect_fixture`, `__test_hm_teardown`, `private.hiveMind.sweep.detect`
- removed (11): `helpersCleanup`, `private.test.role.to.agent.dir`, `test.hiveMind.envDel`, `test.hiveMind.envSet`, `test.hiveMind.functionBody`, `test.hiveMind.liveUuid`, `test.hiveMind.roleFromTitle`, `test.hiveMind.roleIsGeneric`, `test.hiveMind.sessionLookup`, `test.hiveMind.sessionStore`, `testCleanup`

**`test/test.install`**

- added (1): `test.install`
- removed (34): `console.log`, `debug.log`, `important.log`, `test.install.cleanEnvAbsentStaysAbsent`, `test.install.cleanEnvCarriesRepo`, `test.install.cleanEnvCarriesSudoUser`, `test.install.cleanEnvCarriesUser`, `test.install.cleanEnvKeepsBash`, `test.install.cleanEnvKeepsXtrace`, `test.install.cleanEnvNoExecBit`, `test.install.cleanEnvPassesLogLevel`, `test.install.cleanEnvProbe`, `test.install.cleanEnvReexec`, `test.install.cleanEnvSeedsPath`, `test.install.cleanEnvTermDefault`, `test.install.deinstallUserDelete`, `test.install.homeLinkNotMoved`, `test.install.homeRecovery`, `test.install.homeRecoveryNoGetent`, `test.install.invokerOoshShell`, `test.install.noDoubledLogCall`, `test.install.noFetcherFailsLoud`, `test.install.once.load`, `test.install.once.stub`, `test.install.onceNoAutorunSentinel`, `test.install.onceNoMidInstallPull`, `test.install.onceNoNestedInstall`, `test.install.pmEnvAgrees`, `test.install.rootOwnsOosh`, `test.install.sudoKeepsMode`, `test.install.thisLauncherExec`, `test.install.thisLauncherSourced`, `test.install.thisLauncherTemplate`, `test.state31.sharedDevEnd`

**`test/test.line`**

- changed (1): `test.line`
- removed (11): `test.line.formatColourFreshShell`, `test.line.formatCustomKept`, `test.line.formatEnvExpected`, `test.line.formatFilePlain`, `test.line.formatInitNoError`, `test.line.freshShell`, `test.line.removeExactEmptyArgument`, `test.line.removeExactKeepsSubstrings`, `test.line.setupColorEarlyLoad`, `test.line.setupColorIdempotent`, `test.line.startFixture`

**`test/test.log`**

- added (1): `cleanup_test_files`
- removed (22): `cleanup.testFiles`, `test.log.deviceIsCapture`, `test.log.deviceIsSession`, `test.log.deviceIsTerminal`, `test.log.deviceOne`, `test.log.deviceProbe`, `test.log.deviceSets`, `test.log.emitNeverStdout`, `test.log.liveFileSession`, `test.log.liveResultEnvExists`, `test.log.liveResultTxtExists`, `test.log.liveTtyWinsOverStale`, `test.log.nameNoHostname`, `test.log.sessionDeviceTerminal`, `test.log.sessionDeviceTwoTerminals`, `test.log.sessionPureData`, `test.log.sessionSaveIdempotent`, `test.log.sessionSaveWriteFail`, `test.log.sessionWrite`, `test.log.standaloneStart`, `test.log.terminalOneList`, `test.stop.log.safe`

**`test/test.loop`**

- changed (1): `test.loop`

**`test/test.myScript`**

- changed (1): `test.myScript`

**`test/test.oo`**

- changed (3): `test.oo.t1`, `test.oo.t5`, `test.oo.t8`
- removed (174): `private.test.oo.base.get.canonical`, `private.test.oo.base.get.probe`, `private.test.oo.branchClone.origin`, `private.test.oo.consume.fixture`, `private.test.oo.method.delete.fixture`, `private.test.oo.stree.cloneShape`, `test.oo.align.fix`, `test.oo.align.noOp`, `test.oo.base`, `test.oo.baseFoldersOneLoop`, `test.oo.baseGetFromMain`, `test.oo.baseGetFromWorktree`, `test.oo.baseGetRefusesDevOnly`, `test.oo.baseGetSiblingMain`, `test.oo.bootPathCheckDefined`, `test.oo.branchCloneEnsureClonesAndKeeps`, `test.oo.branchCloneEnsureLeavesWorktree`, `test.oo.branchCloneEnsureRefusesOther`, `test.oo.branchList.dedup`, `test.oo.branchList.invalidSource`, `test.oo.branchList.local`, `test.oo.branchList.remote`, `test.oo.branchList.worktrees`, `test.oo.branchNoAlias`, `test.oo.checkPmDoesNotClobber`, `test.oo.checkout.clonesUnderBase`, `test.oo.checkout.dirName`, `test.oo.checkout.missingArg`, `test.oo.checkout.noBase`, `test.oo.checkout.worktreeShared`, `test.oo.checkoutRemove`, `test.oo.cmd.control`, `test.oo.cmd.fixture`, `test.oo.cmd.fixture.apt`, `test.oo.cmd.fixture.brew`, `test.oo.cmd.run`, `test.oo.cmdAlreadyPresent`, `test.oo.cmdAptNonInteractive`, `test.oo.cmdBrewNonInteractive`, `test.oo.cmdBusyboxWget`, `test.oo.cmdDeadBranch`, `test.oo.cmdNoInstall`, `test.oo.cmdNoInstallBusybox`, `test.oo.cmdNoInstallCheck`, `test.oo.cmdNoNoise`, `test.oo.cmdNoPm`, `test.oo.cmdPmFails`, `test.oo.cmdRefreshMarker`, `test.oo.cmdRefreshOnce`, `test.oo.cmdTwoArg`, `test.oo.cmdVerifyAfterInstall`, `test.oo.comp.checkoutVersion`, `test.oo.comp.useBranch`, `test.oo.consist.aligned`, `test.oo.consist.mismatch`, `test.oo.developkingKeyPlace`, `test.oo.docsNameNoDrift`, `test.oo.dropinCleanupCallers`, `test.oo.dropinRemove`, `test.oo.dropinRemoveManaged`, `test.oo.gitconfig.cksum`, `test.oo.gitconfig.isolate`, `test.oo.gitconfigUntouchedAtEnd`, `test.oo.homeTrust`, `test.oo.installLauncher`, `test.oo.installLauncherNoCmp`, `test.oo.installWritesOdockerEnv`, `test.oo.layoutFolderCheck`, `test.oo.lazyOoshDir`, `test.oo.method.probe.clean`, `test.oo.method.probe.make`, `test.oo.methodDeleteOneLine`, `test.oo.methodDeletePrivate`, `test.oo.methodDeleteRefusesUnknown`, `test.oo.methodDeleteRemovesMethodAndCompletions`, `test.oo.methodEndGet`, `test.oo.methodNameResolve`, `test.oo.methodNewAllOrNothing`, `test.oo.methodNewDottedScript`, `test.oo.methodNewMultiSegment`, `test.oo.methodNewPrivate`, `test.oo.methodNewSymlinkedScript`, `test.oo.methodNewWritesDocstring`, `test.oo.methodTestBanner`, `test.oo.methodTestBanner.left`, `test.oo.mode.clonesMissing`, `test.oo.mode.completionFilter`, `test.oo.mode.completionLazyRealDir`, `test.oo.mode.completionLazySymlink`, `test.oo.mode.completionNoBase`, `test.oo.mode.completionWorktree`, `test.oo.mode.dir`, `test.oo.mode.list.noLeak`, `test.oo.mode.listFilter`, `test.oo.mode.sameBranch`, `test.oo.mode.switch`, `test.oo.mode.switchBack`, `test.oo.mode.trust`, `test.oo.mode.trustCurrent`, `test.oo.modeBaseWording`, `test.oo.modeRelease`, `test.oo.modeReleaseChecksProd`, `test.oo.oncePathMigrate`, `test.oo.pathSudoGet`, `test.oo.pathWritableIs`, `test.oo.pmDiscoverRecords`, `test.oo.pmEnvGet`, `test.oo.pmHost`, `test.oo.pmHost.run`, `test.oo.pmInstallPrefixGet`, `test.oo.pmInstallPrefixPublic`, `test.oo.pmOtherUnchanged`, `test.oo.pmTablesAgree`, `test.oo.prereqsBashNonInteractive`, `test.oo.privilegeQuiet`, `test.oo.privilegesRouteWithoutUser`, `test.oo.realGitconfigUntouched`, `test.oo.safeDirectory.delegates`, `test.oo.scriptLoadKeepsThis`, `test.oo.setup.alreadyExists`, `test.oo.setup.functionExists`, `test.oo.setup.nonGit`, `test.oo.setup.producesDetectableLayout`, `test.oo.setupGate.case`, `test.oo.setupGate.stash`, `test.oo.setupGate.unpushed`, `test.oo.setupLayout.case`, `test.oo.setupLayout.detach`, `test.oo.setupLayout.hotfix`, `test.oo.setupLayout.none`, `test.oo.setupLayout.run`, `test.oo.setupLayoutExists`, `test.oo.setupSafeSwap`, `test.oo.setupSafeSwap.run`, `test.oo.setupSourceGate`, `test.oo.sharedTreeConsumeDefaultKeepsSource`, `test.oo.sharedTreeConsumeRefusesBadMain`, `test.oo.sharedTreeConsumeRemovesSource`, `test.oo.sharedTreeConsumeSourceInTheWay`, `test.oo.sharedTreeEnsure`, `test.oo.sharedTreeFromLocalBranchMain`, `test.oo.sharedTreeFromLocalCreatesLayout`, `test.oo.sharedTreeFromLocalIdempotent`, `test.oo.sharedTreeFromLocalOriginFallback`, `test.oo.sharedTreeNoDevelopking`, `test.oo.shim.findLatest`, `test.oo.shim.mostRecent`, `test.oo.shim.noValidDirs`, `test.oo.shim.plainClone`, `test.oo.shim.skipNonGit`, `test.oo.shim.skipSymlinks`, `test.oo.shim.spaceInBase`, `test.oo.shimBashrcSettles`, `test.oo.shimNoWorktreeBase`, `test.oo.sourceConsumeGate`, `test.oo.state31CloneLayout`, `test.oo.state31DevGroupOnce`, `test.oo.state31KeyBeforeClone`, `test.oo.state31NonRootBase`, `test.oo.state31SnapshotsBeforeWriting`, `test.oo.state50`, `test.oo.stateMachineNumbering`, `test.oo.testPlatformNew`, `test.oo.update.ensuresTrust`, `test.oo.update.noBaseQuiet`, `test.oo.updateCalls`, `test.oo.updateCalls.run`, `test.oo.use.badBranch`, `test.oo.use.missingArgs`, `test.oo.use.siblingFallback`, `test.oo.user.symlinks.ensure`, `test.oo.user.symlinks.ensure.collision`, `test.oo.userFixCompletionFresh`, `test.oo.userInitMoved`

**`test/test.os`**

- added (1): `test.os`
- removed (4): `test.os.platformMoved`, `test.os.releaseGet`, `test.os.service`, `test.os.systemdIs`

**`test/test.ossh`**

- changed (1): `test.ossh`
- removed (75): `test.ossh.authorizedKeyAppend`, `test.ossh.backupPrecedesUserInit`, `test.ossh.basehomeUnloaded`, `test.ossh.branchNoAlias`, `test.ossh.cmdNonInteractive`, `test.ossh.colorStrip`, `test.ossh.configBlockPut`, `test.ossh.configDelete`, `test.ossh.configFieldGet`, `test.ossh.configPull`, `test.ossh.configPullCompletion`, `test.ossh.configPush`, `test.ossh.configSaveLast`, `test.ossh.configSet`, `test.ossh.configSetCompletion`, `test.ossh.connectionCloseNoHost`, `test.ossh.connectionErrorGet`, `test.ossh.connectionErrorNetworkIs`, `test.ossh.connectionOpenFail`, `test.ossh.connectionOpenTemp`, `test.ossh.continueLocalNameAfterState`, `test.ossh.continueLocalStateFail`, `test.ossh.controlPathInStart`, `test.ossh.controlPathResolvedGet`, `test.ossh.controlPathShort`, `test.ossh.foldFixCheckRcZero`, `test.ossh.foldFixCheckReadonly`, `test.ossh.foldFixConfigNormalizeWoda`, `test.ossh.foldFixConfigStripLegacy`, `test.ossh.foldFixPruneKeepsUserState`, `test.ossh.foldFixPrunesStale`, `test.ossh.folderFixCheckBsdStat`, `test.ossh.folderFixIdPortable`, `test.ossh.folderFixNoGithubCopy`, `test.ossh.folderFixWritesWoda`, `test.ossh.getFileNameOne`, `test.ossh.githubBlockIsOosh`, `test.ossh.installContinueLocalBackupCallSites`, `test.ossh.installHostName`, `test.ossh.installKeyFallback`, `test.ossh.installPushesKey`, `test.ossh.installRemoteNamesItself`, `test.ossh.installUserRemoteKeyMode`, `test.ossh.keyCompletion`, `test.ossh.keyNameNoHostname`, `test.ossh.keyPull`, `test.ossh.keyPullResult`, `test.ossh.keyPushBareQuiet`, `test.ossh.keyPushIdentity`, `test.ossh.keyRevoke`, `test.ossh.masterStart`, `test.ossh.ooshInitPushResult`, `test.ossh.osshLayoutOuteruserNoSelfCopy`, `test.ossh.prereqs.local.run`, `test.ossh.prereqs.local.stub`, `test.ossh.prereqsLocalNamesTool`, `test.ossh.publicKeyGet`, `test.ossh.pushInitOneError`, `test.ossh.pushPullResult`, `test.ossh.remoteKeyFileNameGet`, `test.ossh.remotePrelude`, `test.ossh.remotePublicKeyPut`, `test.ossh.remotePublicKeyPutModes`, `test.ossh.renamesObjectVerb`, `test.ossh.rightsFixRuns`, `test.ossh.scriptLoad`, `test.ossh.sharedCopies`, `test.ossh.sharedGithub.fixture`, `test.ossh.sharedGithub.run`, `test.ossh.sharedGithubCreate`, `test.ossh.sharedLegacy`, `test.ossh.sharedSshGone`, `test.ossh.state31GithubSystem`, `test.ossh.systemFilesGet`, `test.ossh.userHomesGet`

**`test/test.otmux`**

- added (1): `__empty_test`
- removed (2): `cleanupOtmuxServer`, `test.otmux.paneHistoryExists`

**`test/test.path`**

- changed (1): `reset_path`
- removed (30): `private.test.path.validate.clear`, `private.test.path.validate.plant`, `test.path.aliases`, `test.path.appendDeDupeIsWholeSegment`, `test.path.awkwardDirs`, `test.path.bash.segment`, `test.path.editGuards`, `test.path.editRoundtrip`, `test.path.fixture.make`, `test.path.fixture.saved`, `test.path.loadCommandNoop`, `test.path.loadOldPathsFile`, `test.path.loadRefuses`, `test.path.loadSourced`, `test.path.mutatorsPersistNothing`, `test.path.onceHibernateNoPath`, `test.path.onceInitDoesNotDuplicateOoshDir`, `test.path.removeIsWholeSegment`, `test.path.saveFilters`, `test.path.saveSurvivesLogin`, `test.path.saveWritesSession`, `test.path.savedLists`, `test.path.usageAdvertisesOnlyRealVerbs`, `test.path.validateBootIsNoException`, `test.path.validateHonoursFileMarker`, `test.path.validateHonoursMarker`, `test.path.validateIgnoresOtherPathVars`, `test.path.validateRefusesBlind`, `test.path.validateRejects`, `test.path.validateTree`

**`test/test.scrumMaster`**

- added (1): `cleanup_pdca`
- removed (2): `cleanupPdca`, `restorePdca`

**`test/test.scrumMaster.measure`**

- added (1): `cleanup_metrics`
- removed (1): `cleanupMetrics`

**`test/test.share`**

- changed (1): `test.share`

**`test/test.state`**

- changed (2): `cleanup_test_machines`, `private.check.error.max.iterations`
- removed (1): `restore_current_cache`

**`test/test.tilde`**

- added (2): `expand_tilde`, `test_start`
- removed (4): `test.tilde.expand`, `test.tilde.fileTest`, `test.tilde.home`, `test.tilde.string`

**`test/test.tt`**

- changed (1): `test.tt`

**`test/test.webitem`**

- changed (1): `test.webitem`

</details>

## Caveats

- `restore/` (6 files, 771 methods by the `old/`-excluded count) and `old/` (19 files)
  exist only on `mcdonges`; they are deployed copies and scratch files, so they are left out of
  the product/test split.
- A method renamed between branches appears as one `removed` plus one `added`; the block
  heuristic cannot tell a rename from an independent rewrite.
- The block heuristic attributes any loose code *between* two function definitions to the
  earlier function. Test files put `test.case`/`expect` lines there, so an assertion-text edit
  is reported as a change of the preceding test function.
- Files that are byte-identical on both branches are skipped entirely (no method can differ).

