# OOSH parameter index

Every documented parameter across all oosh scripts, with the methods that take it (2026-10-20).
Read from each method's signature doc (`# <param> <?optional:default> # …`); the `?` marker and `:default` are stripped.
A parameter name is **qualified by its owning object**, because the same word means different things:
`claudeCode.session` is a Claude session, `otmux.session` is a tmux session, `hiveMind.session` a team session.
The `parameter` column is blank when unchanged from the row above.
Indexes: [methods-index.md](methods-index.md) · [object-verb-index.md](object-verb-index.md).

**423 distinct parameter names** · **699 object-qualified parameters** · **2162 method bindings** (most-used first)

| parameter | object.parameter | methods |
|---|---|---|
| `session` | `claudeCode.session` | [`claudeCode.join`](claudeCode.md) |
|  | `hiveMind.session` | [`hiveMind.agent.bootstrap`](hivemind.md) · [`hiveMind.agent.context.status`](hivemind.md) · [`hiveMind.agent.handoff`](hivemind.md) · [`hiveMind.agent.monitor`](hivemind.md) · [`hiveMind.agent.monitor.cycle`](hivemind.md) · [`hiveMind.agent.session.probe`](hivemind.md) · [`hiveMind.agent.train`](hivemind.md) · [`hiveMind.agent.unblock`](hivemind.md) · [`hiveMind.cold.recover`](hivemind.md) · [`hiveMind.consistency.audit`](hivemind.md) · [`hiveMind.consistency.audit.table`](hivemind.md) · [`hiveMind.consistency.fix`](hivemind.md) · [`hiveMind.consistency.fix.table`](hivemind.md) · [`hiveMind.consistency.reconcile`](hivemind.md) · [`hiveMind.consistency.reconcile.apply`](hivemind.md) · [`hiveMind.context.gather.all`](hivemind.md) · [`hiveMind.ctx.refresh`](hivemind.md) · [`hiveMind.ctx.refresh.dry`](hivemind.md) · [`hiveMind.cycle.full`](hivemind.md) · [`hiveMind.dashboard`](hivemind.md) · [`hiveMind.handoff`](hivemind.md) · [`hiveMind.metrics.log`](hivemind.md) · [`hiveMind.monitor.cycle`](hivemind.md) · [`hiveMind.oosh.init`](hivemind.md) · [`hiveMind.pane.sweep`](hivemind.md) · [`hiveMind.pane.sweep.cycle`](hivemind.md) · [`hiveMind.peer.compact`](hivemind.md) · [`hiveMind.process.list`](hivemind.md) · [`hiveMind.protected.agents.offline`](hivemind.md) · [`hiveMind.protected.live.tupleset`](hivemind.md) · [`hiveMind.protected.panes.shifted`](hivemind.md) · [`hiveMind.protected.panes.swapped`](hivemind.md) · [`hiveMind.protected.team.import`](hivemind.md) · [`hiveMind.registry.list`](hivemind.md) · [`hiveMind.registry.refresh`](hivemind.md) · [`hiveMind.resolve`](hivemind.md) · [`hiveMind.role.uuid`](hivemind.md) · [`hiveMind.status`](hivemind.md) · [`hiveMind.sweep`](hivemind.md) · [`hiveMind.sweep.cycle`](hivemind.md) · [`hiveMind.team.activate`](hivemind.md) · [`hiveMind.team.audit`](hivemind.md) · [`hiveMind.team.context.status`](hivemind.md) · [`hiveMind.team.cycle`](hivemind.md) · [`hiveMind.team.host.set`](hivemind.md) · [`hiveMind.team.init.oosh`](hivemind.md) · [`hiveMind.team.loop`](hivemind.md) · [`hiveMind.team.migrate`](hivemind.md) · [`hiveMind.team.models.list`](hivemind.md) · [`hiveMind.team.monitor`](hivemind.md) · [`hiveMind.team.recover`](hivemind.md) · [`hiveMind.team.register`](hivemind.md) · [`hiveMind.team.remove`](hivemind.md) · [`hiveMind.team.setup`](hivemind.md) · [`hiveMind.team.setup.full`](hivemind.md) · [`hiveMind.team.setup.oosh`](hivemind.md) · [`hiveMind.team.state.clear`](hivemind.md) · [`hiveMind.team.state.set`](hivemind.md) · [`hiveMind.team.status`](hivemind.md) · [`hiveMind.team.sweep`](hivemind.md) · [`hiveMind.team.switch`](hivemind.md) · [`hiveMind.train`](hivemind.md) · [`hiveMind.unblock`](hivemind.md) · [`private.hiveMind.ctx.refresh.impl`](hivemind.md) · [`private.hiveMind.ensure.pane`](hivemind.md) · [`private.hiveMind.live.tupleset`](hivemind.md) · [`private.hiveMind.live.tupleset.remote`](hivemind.md) · [`private.hiveMind.team.host`](hivemind.md) |
|  | `otmux.session` | [`otmux.a`](otmux.md) · [`otmux.fit`](otmux.md) · [`otmux.layout.delete`](otmux.md) · [`otmux.layout.restore`](otmux.md) · [`otmux.layout.save`](otmux.md) · [`otmux.layout.show`](otmux.md) · [`otmux.pane.list`](otmux.md) · [`otmux.session.details`](otmux.md) · [`otmux.size.lock`](otmux.md) · [`otmux.size.unlock`](otmux.md) · [`otmux.tree`](otmux.md) · [`otmux.tree.detailed`](otmux.md) · [`otmux.tronMonitor.setup`](otmux.md) · [`otmux.window.list.format`](otmux.md) · [`otmux.window.size.lock`](otmux.md) · [`otmux.window.size.unlock`](otmux.md) · [`private.otmux.notifyHiveMind.shifted`](otmux.md) · [`private.otmux.size.lock.has`](otmux.md) · [`private.otmux.size.lock.list`](otmux.md) · [`private.otmux.size.lock.remove`](otmux.md) · [`private.otmux.size.lock.set`](otmux.md) |
|  | `scrumMaster.session` | [`private.scrumMaster.measure.context`](scrumMaster.md) · [`private.scrumMaster.measure.pane`](scrumMaster.md) · [`private.scrumMaster.measure.speed`](scrumMaster.md) · [`private.scrumMaster.measure.subscription`](scrumMaster.md) · [`private.scrumMaster.measure.team`](scrumMaster.md) · [`private.scrumMaster.resolve.pane`](scrumMaster.md) · [`private.scrumMaster.sweep.isStable`](scrumMaster.md) · [`scrumMaster.context.measure`](scrumMaster.md) · [`scrumMaster.context.read`](scrumMaster.md) · [`scrumMaster.cycle`](scrumMaster.md) · [`scrumMaster.dashboard`](scrumMaster.md) · [`scrumMaster.metrics.collect`](scrumMaster.md) · [`scrumMaster.metrics.cycle`](scrumMaster.md) · [`scrumMaster.pane.capture`](scrumMaster.md) · [`scrumMaster.pane.measure`](scrumMaster.md) · [`scrumMaster.pulse`](scrumMaster.md) · [`scrumMaster.speed.check`](scrumMaster.md) · [`scrumMaster.speed.measure`](scrumMaster.md) · [`scrumMaster.subscription.measure`](scrumMaster.md) · [`scrumMaster.subscription.scan`](scrumMaster.md) · [`scrumMaster.team.capture`](scrumMaster.md) · [`scrumMaster.team.measure`](scrumMaster.md) |
| `dir` | `agentRoom.dir` | [`agentRoom.install`](agentRoom.md) |
|  | `backup.dir` | [`backup.backupPath.get`](backup.md) · [`backup.diff`](backup.md) · [`backup.full.diff`](backup.md) · [`backup.get.backupPath`](backup.md) · [`backup.normalize.all`](backup.md) · [`backup.normalize.scan`](backup.md) · [`backup.run`](backup.md) · [`backup.run.mv`](backup.md) · [`backup.sync.and.remove`](backup.md) · [`backup.verify.sync`](backup.md) · [`private.backup.get.backupPath`](backup.md) · [`private.backup.resolve.paths`](backup.md) |
|  | `odocker.dir` | [`private.odocker.workspaces.mine`](odocker.md) |
|  | `ogit.dir` | [`ogit.branch.adopt`](ogit.md) · [`ogit.branch.check`](ogit.md) · [`ogit.branch.checkout`](ogit.md) · [`ogit.branch.compare`](ogit.md) · [`ogit.branch.fastForward`](ogit.md) · [`ogit.branch.find`](ogit.md) · [`ogit.branch.get`](ogit.md) · [`ogit.branch.list`](ogit.md) · [`ogit.branch.merge`](ogit.md) · [`ogit.branch.remote.delete`](ogit.md) · [`ogit.branch.reset`](ogit.md) · [`ogit.branch.upstream.set`](ogit.md) · [`ogit.commit.count`](ogit.md) · [`ogit.commit.create`](ogit.md) · [`ogit.commit.log.show`](ogit.md) · [`ogit.commit.pick`](ogit.md) · [`ogit.commit.pick.abort`](ogit.md) · [`ogit.commit.pick.continue`](ogit.md) · [`ogit.commit.revert`](ogit.md) · [`ogit.commit.show`](ogit.md) · [`ogit.config.email.get`](ogit.md) · [`ogit.config.get`](ogit.md) · [`ogit.config.set`](ogit.md) · [`ogit.conflict.list`](ogit.md) · [`ogit.conflict.resolve`](ogit.md) · [`ogit.diff.check`](ogit.md) · [`ogit.diff.show`](ogit.md) · [`ogit.index.add`](ogit.md) · [`ogit.index.remove`](ogit.md) · [`ogit.merge.abort`](ogit.md) · [`ogit.merge.base.get`](ogit.md) · [`ogit.raw`](ogit.md) · [`ogit.remote.branch.list`](ogit.md) · [`ogit.remote.fetch`](ogit.md) · [`ogit.remote.pull`](ogit.md) · [`ogit.remote.push`](ogit.md) · [`ogit.remote.url.get`](ogit.md) · [`ogit.remote.url.set`](ogit.md) · [`ogit.repo.check`](ogit.md) · [`ogit.repo.files.list`](ogit.md) · [`ogit.repo.grep`](ogit.md) · [`ogit.repo.root.get`](ogit.md) · [`ogit.repo.share`](ogit.md) · [`ogit.stash.drop`](ogit.md) · [`ogit.stash.pop`](ogit.md) · [`ogit.stash.push`](ogit.md) · [`ogit.stash.top.get`](ogit.md) · [`ogit.status.check`](ogit.md) · [`ogit.status.show`](ogit.md) · [`ogit.tag.check`](ogit.md) · [`ogit.tag.create`](ogit.md) · [`ogit.tag.latest.get`](ogit.md) · [`ogit.tag.list`](ogit.md) · [`ogit.worktree.add`](ogit.md) · [`ogit.worktree.delete`](ogit.md) · [`ogit.worktree.find`](ogit.md) · [`ogit.worktree.list`](ogit.md) · [`ogit.worktree.prune`](ogit.md) · [`private.ogit.branch.import`](ogit.md) · [`private.ogit.fetchhead.share`](ogit.md) · [`private.ogit.git.run`](ogit.md) · [`private.ogit.gitdir`](ogit.md) · [`private.ogit.umask.get`](ogit.md) · [`private.ogit.worktree.paths.get`](ogit.md) |
|  | `os.dir` | [`platform.parse.check`](os.md) · [`private.os.shell.files.list`](os.md) |
|  | `ossh.dir` | [`ossh.dir.pull`](ossh.md) · [`ossh.dir.push`](ossh.md) · [`ossh.pull.dir`](ossh.md) · [`ossh.push.dir`](ossh.md) · [`private.ossh.dir.pull`](ossh.md) · [`private.ossh.dir.push`](ossh.md) |
|  | `path.dir` | [`path.add`](path.md) · [`path.append`](path.md) · [`path.prepend`](path.md) · [`path.push`](path.md) · [`path.put`](path.md) · [`path.remove`](path.md) · [`path.rm`](path.md) · [`private.pathadd`](path.md) · [`private.pathrm`](path.md) |
|  | `promote.dir` | [`private.promote.merge.finish`](promote.md) |
|  | `this.dir` | [`private.ensure.sharedTree`](this.md) · [`private.this.folder.ensure`](this.md) · [`private.this.folder.share`](this.md) · [`private.this.shared.top.ensure`](this.md) · [`this.path.add`](this.md) |
| `target` | `hiveMind.target` | [`hiveMind.handoff`](hivemind.md) · [`hiveMind.peer.compact`](hivemind.md) · [`private.hiveMind.pane.count`](hivemind.md) · [`private.hiveMind.sweep.paneState`](hivemind.md) |
|  | `oo.target` | [`private.oo.install.launcher`](oo.md) |
|  | `osemvec.target` | [`osemvec.check`](osemvec.md) · [`osemvec.stop`](osemvec.md) |
|  | `otmux.target` | [`otmux.attach`](otmux.md) · [`otmux.attach.readonly`](otmux.md) · [`otmux.has`](otmux.md) · [`otmux.kill`](otmux.md) · [`otmux.layout`](otmux.md) · [`otmux.pane.capture`](otmux.md) · [`otmux.pane.capture.full`](otmux.md) · [`otmux.pane.capture.visible`](otmux.md) · [`otmux.pane.get`](otmux.md) · [`otmux.pane.history`](otmux.md) · [`otmux.pane.kill`](otmux.md) · [`otmux.pane.list.format`](otmux.md) · [`otmux.pane.lock`](otmux.md) · [`otmux.pane.select`](otmux.md) · [`otmux.pane.send`](otmux.md) · [`otmux.pane.splitH`](otmux.md) · [`otmux.pane.title`](otmux.md) · [`otmux.pane.unlock`](otmux.md) · [`otmux.send`](otmux.md) · [`otmux.send.enter`](otmux.md) · [`otmux.send.key`](otmux.md) · [`otmux.send.keys`](otmux.md) · [`otmux.send.raw`](otmux.md) · [`otmux.send.tui`](otmux.md) · [`otmux.send.verified`](otmux.md) · [`otmux.session.attach`](otmux.md) · [`otmux.session.has`](otmux.md) · [`otmux.session.kill`](otmux.md) · [`otmux.session.switch`](otmux.md) · [`otmux.switch`](otmux.md) · [`otmux.tiled`](otmux.md) · [`otmux.window.aggressive.resize`](otmux.md) · [`otmux.window.kill`](otmux.md) · [`otmux.window.layout.get`](otmux.md) · [`otmux.window.layout.set`](otmux.md) · [`otmux.window.move`](otmux.md) · [`otmux.window.rename`](otmux.md) · [`otmux.window.select`](otmux.md) · [`otmux.window.swap`](otmux.md) · [`otmux.window.unlink`](otmux.md) · [`private.otmux.killPane`](otmux.md) · [`private.otmux.killWindow`](otmux.md) · [`private.otmux.moveWindow`](otmux.md) · [`private.otmux.pane.isClaudeCode`](otmux.md) · [`private.otmux.selectPane`](otmux.md) · [`private.otmux.selectWindow`](otmux.md) · [`private.otmux.send.smart`](otmux.md) · [`private.otmux.sendEnter`](otmux.md) · [`private.otmux.sendKeys`](otmux.md) · [`private.otmux.swapWindow`](otmux.md) · [`private.otmux.target.isPane`](otmux.md) · [`private.otmux.unlinkWindow`](otmux.md) |
|  | `promote.target` | [`private.promote.merge.into.folder`](promote.md) · [`private.promote.merge.preview.show`](promote.md) |
|  | `scrumMaster.target` | [`private.scrumMaster.metrics.save`](scrumMaster.md) |
|  | `setup.target` | [`private.setup.template.install`](setup.md) |
|  | `this.target` | [`private.this.symlink.with.backup`](this.md) |
| `script` | `2c.script` | [`2c.format.functions`](2c.md) · [`2c.get.function.with.documentation`](2c.md) · [`2c.get.functions`](2c.md) |
|  | `c2.script` | [`c2.format.functions`](c2.md) · [`c2.function.declaration.get`](c2.md) · [`c2.function.description.format`](c2.md) · [`c2.function.get.with.documentation`](c2.md) · [`c2.function.parameter.get`](c2.md) · [`c2.functions.format`](c2.md) · [`c2.functions.get`](c2.md) · [`c2.get.formated.function.description`](c2.md) · [`c2.get.function.declaration`](c2.md) · [`c2.get.function.parameter`](c2.md) · [`c2.get.function.with.documentation`](c2.md) · [`c2.get.functions`](c2.md) · [`c2.signature.validate`](c2.md) · [`private.c2.format.functions`](c2.md) · [`private.c2.get.formated.function.description`](c2.md) · [`private.c2.get.function.declaration`](c2.md) · [`private.c2.get.function.parameter`](c2.md) · [`private.c2.get.function.with.documentation`](c2.md) · [`private.c2.get.functions`](c2.md) |
|  | `ossh.script` | [`private.check.certificates.update.archive.workspace`](ossh.md) · [`private.check.certificates.update.create.certbot`](ossh.md) · [`private.check.certificates.update.create.structr`](ossh.md) · [`private.check.certificates.update.restore.workspace`](ossh.md) · [`private.check.certificates.update.rotate.empty`](ossh.md) · [`private.check.certificates.update.start.structr`](ossh.md) · [`private.check.certificates.update.stop.certbot`](ossh.md) · [`private.check.certificates.update.stop.structr`](ossh.md) · [`private.check.certificates.update.verify.https`](ossh.md) · [`private.check.finished`](ossh.md) · [`private.check.next.custom.state`](ossh.md) |
|  | `promote.script` | [`private.check.confirmation.received`](promote.md) · [`private.check.confirmation.received.prod`](promote.md) · [`private.check.finished`](promote.md) · [`private.check.initialization.checked`](promote.md) · [`private.check.merged.to.prod`](promote.md) · [`private.check.merged.to.testing`](promote.md) · [`private.check.next.custom.state`](promote.md) · [`private.check.prod.path.started`](promote.md) · [`private.check.prod.pushed`](promote.md) · [`private.check.prod.tagged`](promote.md) · [`private.check.target.checked`](promote.md) · [`private.check.test.suite.passed`](promote.md) · [`private.check.testing.pushed`](promote.md) · [`private.check.testing.tagged`](promote.md) · [`private.check.uncommitted.checked`](promote.md) |
|  | `scrumMaster.script` | [`private.check.acting`](scrumMaster.md) · [`private.check.checking`](scrumMaster.md) · [`private.check.cycle.complete`](scrumMaster.md) · [`private.check.doing`](scrumMaster.md) · [`private.check.error.max.iterations`](scrumMaster.md) · [`private.check.finished`](scrumMaster.md) · [`private.check.next.custom.state`](scrumMaster.md) · [`private.check.planning`](scrumMaster.md) |
|  | `state.script` | [`state.check`](state.md) · [`state.machine.create`](state.md) · [`state.machine.init`](state.md) |
|  | `this.script` | [`private.this.script.load`](this.md) |
| `sshDir` | `ossh.sshDir` | [`ossh.authorized.keys.update`](ossh.md) · [`ossh.authorized.keys.update`](ossh.md) · [`ossh.config.get`](ossh.md) · [`ossh.folder.fix`](ossh.md) · [`ossh.folder.fix.check`](ossh.md) · [`ossh.get.public.id`](ossh.md) · [`ossh.id.create`](ossh.md) · [`ossh.id.create.fromKey`](ossh.md) · [`ossh.id.public.get`](ossh.md) · [`ossh.id.pull`](ossh.md) · [`ossh.id.push`](ossh.md) · [`ossh.isInstalled`](ossh.md) · [`ossh.key.folder.create`](ossh.md) · [`ossh.key.folder.delete`](ossh.md) · [`ossh.key.folders.create`](ossh.md) · [`ossh.key.folders.delete`](ossh.md) · [`ossh.key.pull`](ossh.md) · [`ossh.key.push`](ossh.md) · [`ossh.list.ids`](ossh.md) · [`ossh.permission.fix`](ossh.md) · [`ossh.publicId.get`](ossh.md) · [`ossh.pull.id`](ossh.md) · [`ossh.push.id`](ossh.md) · [`ossh.push.key`](ossh.md) · [`ossh.rights.fix`](ossh.md) · [`private.detect.ssh.key`](ossh.md) · [`private.detect.ssh.key.type`](ossh.md) · [`private.ossh.create.key.folders`](ossh.md) · [`private.ossh.delete.key.folders`](ossh.md) · [`private.ossh.folder.fix.config.normalize`](ossh.md) · [`private.ossh.folder.fix.config.strip.legacy`](ossh.md) · [`private.ossh.folder.fix.prune`](ossh.md) · [`private.ossh.get.public.id`](ossh.md) · [`private.ossh.github.copy.remove`](ossh.md) · [`private.ossh.id.push`](ossh.md) · [`private.ossh.key.pull`](ossh.md) · [`private.ossh.key.push`](ossh.md) · [`private.ossh.pull.id`](ossh.md) |
|  | `osshLayout.sshDir` | [`osshLayout.build`](osshLayout.md) · [`osshLayout.role.developking`](osshLayout.md) · [`osshLayout.role.installer`](osshLayout.md) · [`osshLayout.role.outeruser`](osshLayout.md) · [`osshLayout.role.owner`](osshLayout.md) · [`private.osshLayout.ensure.keypair`](osshLayout.md) · [`private.osshLayout.perms.tighten`](osshLayout.md) |
|  | `test.suite.sshDir` | [`private.test.suite.ssh.stamp.get`](test.suite.md) |
|  | `user.sshDir` | [`private.user.authorized.keys.adopt`](user.md) · [`private.user.authorized.keys.rebuild`](user.md) · [`user.authorized.keys.update`](user.md) · [`user.in`](user.md) · [`user.init`](user.md) · [`user.list.other.identities`](user.md) · [`user.ssh.backup`](user.md) · [`user.ssh.create.folders`](user.md) · [`user.ssh.restore`](user.md) · [`user.ssh.status`](user.md) · [`user.authorized.keys.update`](user.md) |
| `command` | `c2.command` | [`c2.buildin.commands`](c2.md) |
|  | `claudeFlow.command` | [`claudeFlow.i`](claudeFlow.md) · [`claudeFlow.interactive`](claudeFlow.md) · [`claudeFlow.json`](claudeFlow.md) · [`claudeFlow.quiet`](claudeFlow.md) · [`claudeFlow.statusline.set`](claudeFlow.md) · [`claudeFlow.table`](claudeFlow.md) · [`claudeFlow.tmux.pane`](claudeFlow.md) · [`claudeFlow.tmux.run`](claudeFlow.md) · [`claudeFlow.verbose`](claudeFlow.md) |
|  | `debug.command` | [`debug.onError`](debug.md) |
|  | `odocker.command` | [`odocker.exec.command`](odocker.md) · [`odocker.image.command`](odocker.md) |
|  | `oo.command` | [`oo.use`](oo.md) |
|  | `ossh.command` | [`ossh.exec`](ossh.md) · [`ossh.exec.tty`](ossh.md) · [`private.certificates.update.ssh.run`](ossh.md) · [`private.ossh.ssh`](ossh.md) |
|  | `otmux.command` | [`otmux.256color`](otmux.md) · [`otmux.bind`](otmux.md) · [`otmux.config`](otmux.md) · [`otmux.config.set.hook`](otmux.md) · [`otmux.confirm`](otmux.md) · [`otmux.control`](otmux.md) · [`otmux.key.bind`](otmux.md) · [`otmux.new`](otmux.md) · [`otmux.nw`](otmux.md) · [`otmux.pane.pipe`](otmux.md) · [`otmux.pane.respawn`](otmux.md) · [`otmux.pane.split`](otmux.md) · [`otmux.pane.split.h`](otmux.md) · [`otmux.pane.split.v`](otmux.md) · [`otmux.pane.splitH`](otmux.md) · [`otmux.run`](otmux.md) · [`otmux.send.confirm`](otmux.md) · [`otmux.send.run`](otmux.md) · [`otmux.session.new`](otmux.md) · [`otmux.socket`](otmux.md) · [`otmux.split`](otmux.md) · [`otmux.split.h`](otmux.md) · [`otmux.split.v`](otmux.md) · [`otmux.utf8`](otmux.md) · [`otmux.verbose`](otmux.md) · [`otmux.window.new`](otmux.md) · [`otmux.window.respawn`](otmux.md) · [`private.otmux.newWindow`](otmux.md) · [`private.otmux.pipePane`](otmux.md) · [`private.otmux.respawnPane`](otmux.md) · [`private.otmux.respawnWindow`](otmux.md) · [`private.otmux.setHook`](otmux.md) · [`private.otmux.socketPath`](otmux.md) · [`private.otmux.splitH`](otmux.md) · [`private.otmux.splitV`](otmux.md) |
|  | `setup.command` | [`private.setup.nvm.run`](setup.md) |
|  | `user.command` | [`private.as.user`](user.md) |
| `file` | `claudeCode.file` | [`claudeCode.session.recover`](claudeCode.md) · [`claudeCode.session.save`](claudeCode.md) |
|  | `claudeFlow.file` | [`claudeFlow.memory.export`](claudeFlow.md) · [`claudeFlow.memory.import`](claudeFlow.md) · [`claudeFlow.session.import`](claudeFlow.md) |
|  | `config.file` | [`private.config.chain.names.get`](config.md) · [`private.config.env.line.append`](config.md) · [`private.config.env.lines.drop`](config.md) · [`private.config.required.file.path.get`](config.md) |
|  | `context.file` | [`context.validate`](context.md) |
|  | `hiveMind.file` | [`private.hiveMind.env.del`](hivemind.md) · [`private.hiveMind.env.set`](hivemind.md) |
|  | `line.file` | [`line.use`](line.md) |
|  | `odocker.file` | [`private.odocker.docker.repo.download`](odocker.md) |
|  | `ogit.file` | [`ogit.conflict.resolve`](ogit.md) |
|  | `oo.file` | [`private.oo.method.end.get`](oo.md) |
|  | `os.file` | [`private.os.release.get`](os.md) |
|  | `osemvec.file` | [`osemvec.register`](osemvec.md) |
|  | `ossh.file` | [`ossh.config.delete`](ossh.md) · [`ossh.config.edit`](ossh.md) · [`ossh.config.get`](ossh.md) · [`ossh.config.list`](ossh.md) · [`ossh.config.pull`](ossh.md) · [`ossh.config.save.last`](ossh.md) · [`ossh.id.pull`](ossh.md) · [`ossh.pull.config`](ossh.md) · [`ossh.pull.id`](ossh.md) · [`private.ossh.config.field.get`](ossh.md) · [`private.ossh.config.field.set`](ossh.md) · [`private.ossh.config.pull`](ossh.md) · [`ossh.config.get`](ossh.md) · [`private.ossh.pull.id`](ossh.md) · [`private.ossh.validConfigBlock`](ossh.md) |
|  | `otmux.file` | [`otmux.buffer.load`](otmux.md) · [`otmux.buffer.save`](otmux.md) · [`otmux.config`](otmux.md) · [`otmux.config.source`](otmux.md) · [`otmux.source`](otmux.md) · [`private.otmux.loadBuffer`](otmux.md) · [`private.otmux.saveBuffer`](otmux.md) |
|  | `path.file` | [`path.file.custom`](path.md) · [`path.load`](path.md) |
|  | `replace.file` | [`private.replace.copy.make`](replace.md) · [`replace.block`](replace.md) · [`replace.commit`](replace.md) · [`replace.line`](replace.md) · [`replace.lines`](replace.md) · [`replace.rollback`](replace.md) · [`replace.word`](replace.md) |
|  | `test.suite.file` | [`private.test.suite.category`](test.suite.md) · [`private.test.suite.shared.waiver.get`](test.suite.md) |
|  | `this.file` | [`private.ensure.groupWrite`](this.md) · [`private.this.file.line.ensure`](this.md) · [`private.this.file.write`](this.md) · [`private.this.url.download`](this.md) |
| `pane` | `claudeCode.pane` | [`claudeCode.context.alert`](claudeCode.md) · [`claudeCode.context.check`](claudeCode.md) · [`claudeCode.context.jsonl`](claudeCode.md) · [`claudeCode.context.read`](claudeCode.md) · [`claudeCode.context.read.tui`](claudeCode.md) · [`claudeCode.context.velocity.byPane`](claudeCode.md) · [`claudeCode.fork.byPane`](claudeCode.md) · [`claudeCode.fork.to`](claudeCode.md) · [`claudeCode.join.byPane`](claudeCode.md) · [`claudeCode.model.get`](claudeCode.md) · [`claudeCode.model.set`](claudeCode.md) · [`claudeCode.process.find`](claudeCode.md) · [`claudeCode.process.running`](claudeCode.md) · [`claudeCode.recover`](claudeCode.md) · [`claudeCode.session.current`](claudeCode.md) · [`claudeCode.session.id`](claudeCode.md) · [`claudeCode.session.probe`](claudeCode.md) · [`claudeCode.session.state`](claudeCode.md) · [`claudeCode.stop`](claudeCode.md) · [`private.claudeCode.context.read.tui`](claudeCode.md) · [`private.claudeCode.resolve.byPane`](claudeCode.md) · [`private.claudeCode.session.discover`](claudeCode.md) |
|  | `claudeFlow.pane` | [`claudeFlow.hive.status`](claudeFlow.md) |
|  | `hiveMind.pane` | [`hiveMind.agent.bootstrap`](hivemind.md) · [`hiveMind.agent.restart.remote`](hivemind.md) · [`hiveMind.agent.verify`](hivemind.md) · [`hiveMind.monitor.approve`](hivemind.md) · [`hiveMind.protected.identity.resolve`](hivemind.md) · [`hiveMind.registry.remove`](hivemind.md) · [`hiveMind.registry.set`](hivemind.md) · [`hiveMind.role.teach`](hivemind.md) · [`hiveMind.task.delegate`](hivemind.md) · [`hiveMind.teach`](hivemind.md) · [`private.hiveMind.agent.inform`](hivemind.md) · [`private.hiveMind.agent.queue.depth`](hivemind.md) · [`private.hiveMind.agent.queue.enqueue`](hivemind.md) · [`private.hiveMind.agent.queue.path`](hivemind.md) · [`private.hiveMind.agent.route`](hivemind.md) · [`private.hiveMind.context.denom.for.target`](hivemind.md) · [`private.hiveMind.context.from.jsonl.reading`](hivemind.md) · [`private.hiveMind.context.live.jsonl`](hivemind.md) · [`private.hiveMind.identity.resolve`](hivemind.md) · [`private.hiveMind.pane.pushRoleEnv`](hivemind.md) · [`private.hiveMind.registry.isRecent`](hivemind.md) · [`private.hiveMind.session.resolve.uuid`](hivemind.md) · [`private.hiveMind.session.store.deferred`](hivemind.md) |
|  | `osemvec.pane` | [`osemvec.guard`](osemvec.md) |
|  | `otmux.pane` | [`otmux.composer.state`](otmux.md) · [`otmux.kp`](otmux.md) · [`otmux.pane.size`](otmux.md) · [`otmux.pane.size.set`](otmux.md) · [`otmux.tronMonitor.setup`](otmux.md) · [`private.otmux.sessionFromPane`](otmux.md) |
|  | `scrumMaster.pane` | [`private.scrumMaster.rewind.markname`](scrumMaster.md) |
|  | `tronMonitor.pane` | [`private.tronMonitor.pane.isValid`](tronMonitor.md) |
| `name` | `claudeCode.name` | [`claudeCode.fork.byName`](claudeCode.md) · [`claudeCode.join.byName`](claudeCode.md) · [`private.claudeCode.resolve.byName`](claudeCode.md) |
|  | `claudeFlow.name` | [`claudeFlow.session.save`](claudeFlow.md) · [`claudeFlow.tmux.pane`](claudeFlow.md) · [`claudeFlow.tmux.run`](claudeFlow.md) |
|  | `config.name` | [`config.add`](config.md) · [`config.delete`](config.md) · [`config.edit`](config.md) · [`config.file.check`](config.md) · [`config.list`](config.md) · [`config.save`](config.md) · [`config.update`](config.md) · [`config.validate`](config.md) · [`private.config.host.name.get`](config.md) · [`private.config.save`](config.md) |
|  | `disk.name` | [`disk.find.dir`](disk.md) · [`disk.find.file`](disk.md) |
|  | `hiveMind.name` | [`hiveMind.agent.rewind`](hivemind.md) · [`hiveMind.agent.send`](hivemind.md) · [`hiveMind.delegate`](hivemind.md) · [`hiveMind.join`](hivemind.md) · [`hiveMind.resolve`](hivemind.md) · [`hiveMind.send`](hivemind.md) · [`hiveMind.send.enter`](hivemind.md) · [`hiveMind.send.message`](hivemind.md) · [`hiveMind.unblock`](hivemind.md) · [`private.hiveMind.channel.resolve`](hivemind.md) |
|  | `line.name` | [`line.param.declare`](line.md) |
|  | `log.name` | [`log.name`](log.md) |
|  | `odocker.name` | [`odocker.create`](odocker.md) · [`odocker.reset`](odocker.md) · [`odocker.run`](odocker.md) · [`odocker.run.sshd`](odocker.md) |
|  | `oo.name` | [`private.oo.method.name.resolve`](oo.md) |
|  | `opy.name` | [`opy.venv.activate`](opy.md) · [`opy.venv.create`](opy.md) · [`opy.venv.remove`](opy.md) |
|  | `osx.name` | [`osx.spotlight.by.name`](osx.md) |
|  | `otmux.name` | [`otmux.env.set`](otmux.md) · [`otmux.env.show`](otmux.md) · [`otmux.new`](otmux.md) · [`otmux.nw`](otmux.md) · [`otmux.session.new`](otmux.md) · [`otmux.session.rename`](otmux.md) · [`otmux.socket`](otmux.md) · [`otmux.window.new`](otmux.md) · [`otmux.window.rename`](otmux.md) · [`private.otmux.newWindow`](otmux.md) · [`private.otmux.renameWindow`](otmux.md) · [`private.otmux.setEnv`](otmux.md) · [`private.otmux.showEnv`](otmux.md) |
|  | `setup.name` | [`private.setup.all.step`](setup.md) |
| `role` | `claudeCode.role` | [`claudeCode.fork.to`](claudeCode.md) |
|  | `context.role` | [`context.lifecycle.init`](context.md) · [`context.lifecycle.recover`](context.md) · [`context.lifecycle.save`](context.md) · [`context.lifecycle.status`](context.md) · [`context.recover`](context.md) · [`private.context.role.to.machine`](context.md) |
|  | `hiveMind.role` | [`hiveMind.agent.bootstrap`](hivemind.md) · [`hiveMind.agent.fork.best`](hivemind.md) · [`hiveMind.agent.restart`](hivemind.md) · [`hiveMind.agent.restart.remote`](hivemind.md) · [`hiveMind.agent.state.clear`](hivemind.md) · [`hiveMind.agent.state.get`](hivemind.md) · [`hiveMind.agent.state.set`](hivemind.md) · [`hiveMind.registry.set`](hivemind.md) · [`hiveMind.role.prompt`](hivemind.md) · [`hiveMind.role.teach`](hivemind.md) · [`hiveMind.role.uuid`](hivemind.md) · [`hiveMind.roles.list.uuids`](hivemind.md) · [`hiveMind.teach`](hivemind.md) · [`hiveMind.train`](hivemind.md) · [`private.hiveMind.context.get`](hivemind.md) · [`private.hiveMind.context.key`](hivemind.md) · [`private.hiveMind.push.agent`](hivemind.md) · [`private.hiveMind.push.captureForkedUUID`](hivemind.md) · [`private.hiveMind.push.resolveCanonical`](hivemind.md) · [`private.hiveMind.role.isGeneric`](hivemind.md) · [`private.hiveMind.session.store.deferred`](hivemind.md) · [`private.hiveMind.snapshot.get`](hivemind.md) · [`private.hiveMind.snapshot.set`](hivemind.md) |
|  | `osemvec.role` | [`osemvec.new`](osemvec.md) |
|  | `osshLayout.role` | [`private.osshLayout.staged.email`](osshLayout.md) · [`private.osshLayout.staged.has.keypair`](osshLayout.md) · [`private.osshLayout.staged.has.privkey`](osshLayout.md) · [`private.osshLayout.staged.has.pubkey`](osshLayout.md) |
| `stageTo` | `ossh.stageTo` | [`private.check.certificates.update.archive.workspace`](ossh.md) · [`private.check.certificates.update.create.certbot`](ossh.md) · [`private.check.certificates.update.create.structr`](ossh.md) · [`private.check.certificates.update.restore.workspace`](ossh.md) · [`private.check.certificates.update.rotate.empty`](ossh.md) · [`private.check.certificates.update.start.structr`](ossh.md) · [`private.check.certificates.update.stop.certbot`](ossh.md) · [`private.check.certificates.update.stop.structr`](ossh.md) · [`private.check.certificates.update.verify.https`](ossh.md) · [`private.check.finished`](ossh.md) · [`private.check.next.custom.state`](ossh.md) |
|  | `promote.stageTo` | [`private.check.confirmation.received`](promote.md) · [`private.check.confirmation.received.prod`](promote.md) · [`private.check.finished`](promote.md) · [`private.check.initialization.checked`](promote.md) · [`private.check.merged.to.prod`](promote.md) · [`private.check.merged.to.testing`](promote.md) · [`private.check.next.custom.state`](promote.md) · [`private.check.prod.path.started`](promote.md) · [`private.check.prod.pushed`](promote.md) · [`private.check.prod.tagged`](promote.md) · [`private.check.target.checked`](promote.md) · [`private.check.test.suite.passed`](promote.md) · [`private.check.testing.pushed`](promote.md) · [`private.check.testing.tagged`](promote.md) · [`private.check.uncommitted.checked`](promote.md) |
|  | `scrumMaster.stageTo` | [`private.check.acting`](scrumMaster.md) · [`private.check.checking`](scrumMaster.md) · [`private.check.cycle.complete`](scrumMaster.md) · [`private.check.doing`](scrumMaster.md) · [`private.check.error.max.iterations`](scrumMaster.md) · [`private.check.finished`](scrumMaster.md) · [`private.check.next.custom.state`](scrumMaster.md) · [`private.check.planning`](scrumMaster.md) |
| `stateFound` | `ossh.stateFound` | [`private.check.certificates.update.archive.workspace`](ossh.md) · [`private.check.certificates.update.create.certbot`](ossh.md) · [`private.check.certificates.update.create.structr`](ossh.md) · [`private.check.certificates.update.restore.workspace`](ossh.md) · [`private.check.certificates.update.rotate.empty`](ossh.md) · [`private.check.certificates.update.start.structr`](ossh.md) · [`private.check.certificates.update.stop.certbot`](ossh.md) · [`private.check.certificates.update.stop.structr`](ossh.md) · [`private.check.certificates.update.verify.https`](ossh.md) · [`private.check.finished`](ossh.md) · [`private.check.next.custom.state`](ossh.md) |
|  | `promote.stateFound` | [`private.check.confirmation.received`](promote.md) · [`private.check.confirmation.received.prod`](promote.md) · [`private.check.finished`](promote.md) · [`private.check.initialization.checked`](promote.md) · [`private.check.merged.to.prod`](promote.md) · [`private.check.merged.to.testing`](promote.md) · [`private.check.next.custom.state`](promote.md) · [`private.check.prod.path.started`](promote.md) · [`private.check.prod.pushed`](promote.md) · [`private.check.prod.tagged`](promote.md) · [`private.check.target.checked`](promote.md) · [`private.check.test.suite.passed`](promote.md) · [`private.check.testing.pushed`](promote.md) · [`private.check.testing.tagged`](promote.md) · [`private.check.uncommitted.checked`](promote.md) |
|  | `scrumMaster.stateFound` | [`private.check.acting`](scrumMaster.md) · [`private.check.checking`](scrumMaster.md) · [`private.check.cycle.complete`](scrumMaster.md) · [`private.check.doing`](scrumMaster.md) · [`private.check.error.max.iterations`](scrumMaster.md) · [`private.check.finished`](scrumMaster.md) · [`private.check.next.custom.state`](scrumMaster.md) · [`private.check.planning`](scrumMaster.md) |
| `sshConfigHost` | `oo.sshConfigHost` | [`oo.remote.update`](oo.md) |
|  | `ossh.sshConfigHost` | [`ossh.certificates.status`](ossh.md) · [`ossh.certificates.update`](ossh.md) · [`ossh.cmd`](ossh.md) · [`ossh.config.delete`](ossh.md) · [`ossh.config.get`](ossh.md) · [`ossh.config.parse`](ossh.md) · [`ossh.config.shared.seed.fallback`](ossh.md) · [`ossh.config.shared.seed.from.local.deploy.key`](ossh.md) · [`ossh.config.shared.seed.github`](ossh.md) · [`ossh.create.and.install`](ossh.md) · [`ossh.harden`](ossh.md) · [`ossh.harden.fail2ban`](ossh.md) · [`ossh.harden.firewall`](ossh.md) · [`ossh.harden.packages`](ossh.md) · [`ossh.harden.sshd`](ossh.md) · [`ossh.harden.sshd.allowusers`](ossh.md) · [`ossh.harden.unattended.upgrades`](ossh.md) · [`ossh.install`](ossh.md) · [`ossh.install.create`](ossh.md) · [`ossh.install.log`](ossh.md) · [`ossh.install.user.remote`](ossh.md) · [`ossh.login`](ossh.md) · [`ossh.pm.discover`](ossh.md) · [`ossh.prereqs.install`](ossh.md) · [`ossh.show`](ossh.md) · [`ossh.ssh.parameter.get`](ossh.md) · [`ossh.url.get`](ossh.md) · [`ossh.config.get`](ossh.md) · [`private.ossh.get.ssh.parameter`](ossh.md) · [`private.ossh.get.url`](ossh.md) · [`private.ossh.harden.preflight`](ossh.md) · [`private.ossh.install.key.authorize`](ossh.md) |
| `username` | `c2.username` | [`c2.user`](c2.md) |
|  | `config.username` | [`config.init.check`](config.md) · [`config.init.full`](config.md) · [`config.init.user`](config.md) |
|  | `oo.username` | [`oo.user.fix`](oo.md) |
|  | `this.username` | [`private.this.as.user.preamble.get`](this.md) |
|  | `user.username` | [`private.as.user`](user.md) · [`private.get.basehome.darwin`](user.md) · [`private.get.basehome.linux`](user.md) · [`private.get.home.darwin`](user.md) · [`private.get.home.linux`](user.md) · [`private.get.info.darwin`](user.md) · [`private.get.info.linux`](user.md) · [`private.get.shell.darwin`](user.md) · [`private.get.shell.linux`](user.md) · [`private.user.create.addSudoer.darwin`](user.md) · [`private.user.create.addSudoer.linux`](user.md) · [`private.user.delete.linux`](user.md) · [`private.user.oosh.install.groups.darwin`](user.md) · [`private.user.oosh.install.groups.linux`](user.md) · [`private.user.oosh.install.node`](user.md) · [`private.user.oosh.install.shell.darwin`](user.md) · [`private.user.oosh.install.shell.linux`](user.md) · [`user.create`](user.md) · [`user.delete.linux`](user.md) · [`user.get`](user.md) · [`user.linux.delete`](user.md) · [`user.oosh.install`](user.md) · [`user.password.set`](user.md) · [`user.password.set.darwin`](user.md) · [`user.password.set.linux`](user.md) |
| `value` | `config.value` | [`config.set`](config.md) |
|  | `hiveMind.value` | [`private.hiveMind.env.del`](hivemind.md) · [`private.hiveMind.env.set`](hivemind.md) |
|  | `line.value` | [`line.assign`](line.md) · [`line.parse.param`](line.md) · [`line.parse.param.new`](line.md) |
|  | `ogit.value` | [`ogit.config.set`](ogit.md) |
|  | `ossh.value` | [`ossh.config.set`](ossh.md) · [`private.ossh.config.field.set`](ossh.md) · [`private.ossh.config.forwardAgent.set`](ossh.md) · [`private.ossh.config.hostName.set`](ossh.md) · [`private.ossh.config.identitiesOnly.set`](ossh.md) · [`private.ossh.config.identityFile.set`](ossh.md) · [`private.ossh.config.port.set`](ossh.md) · [`private.ossh.config.proxyJump.set`](ossh.md) · [`private.ossh.config.user.set`](ossh.md) |
|  | `otmux.value` | [`otmux.config.set`](otmux.md) · [`otmux.config.set.global`](otmux.md) · [`otmux.config.set.window`](otmux.md) · [`otmux.env.set`](otmux.md) · [`otmux.set`](otmux.md) · [`otmux.window.aggressive.resize`](otmux.md) · [`otmux.window.size`](otmux.md) · [`private.otmux.setEnv`](otmux.md) · [`private.otmux.setGlobal`](otmux.md) · [`private.otmux.setWindow`](otmux.md) |
|  | `scrumMaster.value` | [`private.scrumMaster.parse.normalize.k`](scrumMaster.md) |
|  | `this.value` | [`private.this.env.export.line.get`](this.md) |
| `path` | `c2.path` | [`c2.folders`](c2.md) · [`c2.test.absolutePathName`](c2.md) |
|  | `claudeCode.path` | [`claudeCode.init`](claudeCode.md) · [`private.claudeCode.projectHash`](claudeCode.md) |
|  | `claudeFlow.path` | [`claudeFlow.init`](claudeFlow.md) |
|  | `log.path` | [`log.install.init`](log.md) |
|  | `odocker.path` | [`odocker.workspace.get`](odocker.md) · [`odocker.workspace.init`](odocker.md) · [`odocker.workspace.seed`](odocker.md) · [`odocker.workspace.set`](odocker.md) · [`odocker.workspace.install`](odocker.md) |
|  | `ogit.path` | [`ogit.index.remove`](ogit.md) · [`ogit.safeDirectory.add`](ogit.md) · [`ogit.worktree.delete`](ogit.md) |
|  | `oo.path` | [`oo.install`](oo.md) · [`oo.mode.base.set`](oo.md) · [`private.oo.path.sudo.get`](oo.md) · [`private.oo.path.writable.is`](oo.md) |
|  | `otmux.path` | [`private.otmux.socketPath`](otmux.md) |
|  | `test.suite.path` | [`private.test.suite.ssh.mode.get`](test.suite.md) |
|  | `this.path` | [`private.this.path.canonical`](this.md) · [`private.this.path.case.get`](this.md) · [`private.this.path.owner.set`](this.md) · [`private.this.path.stat.get`](this.md) · [`this.absolutePath`](this.md) · [`this.absolutePathName`](this.md) |
|  | `user.path` | [`private.user.path.owner.get`](user.md) |
| `user` | `odocker.user` | [`odocker.prereqs.install`](odocker.md) |
|  | `ossh.user` | [`ossh.install`](ossh.md) · [`ossh.install.user.remote`](ossh.md) |
|  | `setup.user` | [`private.setup.headless.darwin`](setup.md) · [`private.setup.headless.linux`](setup.md) · [`private.setup.nvm.is`](setup.md) · [`private.setup.nvm.run`](setup.md) · [`private.setup.samba.password.darwin`](setup.md) · [`private.setup.samba.password.linux`](setup.md) · [`private.setup.samba.support.darwin`](setup.md) · [`private.setup.samba.support.linux`](setup.md) · [`private.setup.user.get`](setup.md) · [`private.setup.vnc.password.darwin`](setup.md) · [`private.setup.vnc.password.linux`](setup.md) · [`setup.all`](setup.md) · [`setup.docker`](setup.md) · [`setup.headless`](setup.md) · [`setup.nodejs`](setup.md) · [`setup.npm`](setup.md) · [`setup.nvm`](setup.md) · [`setup.samba.password`](setup.md) · [`setup.samba.support`](setup.md) · [`setup.vnc.password`](setup.md) |
|  | `user.user` | [`private.user.group.member.is`](user.md) · [`private.user.group.member.pending`](user.md) |
| `host` | `hiveMind.host` | [`hiveMind.agent.restart.remote`](hivemind.md) · [`hiveMind.team.host.set`](hivemind.md) · [`hiveMind.team.push`](hivemind.md) · [`private.hiveMind.live.tupleset.remote`](hivemind.md) · [`private.hiveMind.push.agent`](hivemind.md) · [`private.hiveMind.push.captureForkedUUID`](hivemind.md) · [`private.hiveMind.push.preflight`](hivemind.md) |
|  | `odocker.host` | [`private.odocker.workspaces.fetch.ssh`](odocker.md) |
|  | `osemvec.host` | [`osemvec.serve`](osemvec.md) |
|  | `ossh.host` | [`ossh.connection.close`](ossh.md) · [`ossh.connection.open`](ossh.md) · [`ossh.connection.status`](ossh.md) · [`ossh.known.hosts.remove`](ossh.md) · [`private.certificates.update.config.load`](ossh.md) · [`private.certificates.update.machine.name`](ossh.md) · [`private.certificates.update.ssh.run`](ossh.md) · [`private.ossh.control.path.resolved.get`](ossh.md) · [`private.ossh.hostKnown`](ossh.md) · [`private.ossh.remote.public.key.put`](ossh.md) · [`private.ossh.ssh`](ossh.md) |
| `machine` | `oo.machine` | [`private.init.state.machine`](oo.md) |
|  | `ossh.machine` | [`private.certificates.update.config.persist`](ossh.md) · [`private.certificates.update.state.machine.init`](ossh.md) |
|  | `state.machine` | [`state.add`](state.md) · [`state.check`](state.md) · [`state.find`](state.md) · [`state.id`](state.md) · [`state.list`](state.md) · [`state.machine.create`](state.md) · [`state.machine.declaration`](state.md) · [`state.machine.delete`](state.md) · [`state.machine.edit`](state.md) · [`state.machine.exists`](state.md) · [`state.machine.init`](state.md) · [`state.name`](state.md) · [`state.next`](state.md) · [`state.of`](state.md) · [`state.rename`](state.md) · [`state.set`](state.md) · [`state.stage`](state.md) |
| `options` | `claudeFlow.options` | [`claudeFlow.agent.pool`](claudeFlow.md) · [`claudeFlow.agent.spawn`](claudeFlow.md) · [`claudeFlow.daemon`](claudeFlow.md) · [`claudeFlow.hive.consensus`](claudeFlow.md) · [`claudeFlow.hive.init`](claudeFlow.md) · [`claudeFlow.hive.spawn`](claudeFlow.md) · [`claudeFlow.hive.task`](claudeFlow.md) · [`claudeFlow.mcp.exec`](claudeFlow.md) · [`claudeFlow.memory.store`](claudeFlow.md) · [`claudeFlow.session.export`](claudeFlow.md) · [`claudeFlow.swarm.coordinate`](claudeFlow.md) · [`claudeFlow.swarm.init`](claudeFlow.md) · [`claudeFlow.swarm.v3`](claudeFlow.md) · [`claudeFlow.task.assign`](claudeFlow.md) · [`claudeFlow.task.create`](claudeFlow.md) · [`claudeFlow.task.list`](claudeFlow.md) · [`claudeFlow.task.ls`](claudeFlow.md) · [`claudeFlow.task.new`](claudeFlow.md) |
|  | `otmux.options` | [`private.otmux.capturePane`](otmux.md) |
|  | `user.options` | [`user.id`](user.md) |
| `agentId` | `agentRoom.agentId` | [`agentRoom.agent.status`](agentRoom.md) · [`agentRoom.agent.stop`](agentRoom.md) · [`agentRoom.chat`](agentRoom.md) · [`agentRoom.health`](agentRoom.md) · [`agentRoom.logs`](agentRoom.md) · [`agentRoom.logs.follow`](agentRoom.md) |
|  | `claudeFlow.agentId` | [`claudeFlow.agent.kill`](claudeFlow.md) · [`claudeFlow.agent.status`](claudeFlow.md) · [`claudeFlow.agent.stop`](claudeFlow.md) · [`claudeFlow.hive.join`](claudeFlow.md) · [`claudeFlow.hive.leave`](claudeFlow.md) · [`claudeFlow.tmux.focus`](claudeFlow.md) · [`claudeFlow.tmux.kill`](claudeFlow.md) |
|  | `hiveMind.agentId` | [`hiveMind.claude`](hivemind.md) · [`hiveMind.focus`](hivemind.md) · [`hiveMind.pane.create`](hivemind.md) · [`hiveMind.spawn`](hivemind.md) · [`hiveMind.task`](hivemind.md) |
| `agentName` | `hiveMind.agentName` | [`hiveMind.agent.handoff`](hivemind.md) · [`hiveMind.agent.monitor`](hivemind.md) · [`hiveMind.agent.rename`](hivemind.md) · [`hiveMind.agent.respawn`](hivemind.md) · [`hiveMind.agent.snapshot`](hivemind.md) · [`hiveMind.agent.spawn`](hivemind.md) · [`hiveMind.agent.train`](hivemind.md) · [`hiveMind.agent.unblock`](hivemind.md) · [`hiveMind.pane.focus`](hivemind.md) · [`hiveMind.team.monitor`](hivemind.md) |
|  | `scrumMaster.agentName` | [`private.scrumMaster.measure.context`](scrumMaster.md) · [`private.scrumMaster.measure.pane`](scrumMaster.md) · [`private.scrumMaster.measure.speed`](scrumMaster.md) · [`private.scrumMaster.metrics.save`](scrumMaster.md) · [`private.scrumMaster.resolve.pane`](scrumMaster.md) · [`scrumMaster.context.measure`](scrumMaster.md) · [`scrumMaster.pane.measure`](scrumMaster.md) · [`scrumMaster.speed.measure`](scrumMaster.md) |
| `configItem` | `ossh.configItem` | [`ossh.config.field.get`](ossh.md) · [`ossh.config.set`](ossh.md) · [`private.ossh.config.field.get`](ossh.md) · [`private.ossh.config.field.set`](ossh.md) · [`private.ossh.config.forwardAgent.get`](ossh.md) · [`private.ossh.config.forwardAgent.set`](ossh.md) · [`private.ossh.config.hostName.get`](ossh.md) · [`private.ossh.config.hostName.set`](ossh.md) · [`private.ossh.config.identitiesOnly.get`](ossh.md) · [`private.ossh.config.identitiesOnly.set`](ossh.md) · [`private.ossh.config.identityFile.get`](ossh.md) · [`private.ossh.config.identityFile.set`](ossh.md) · [`private.ossh.config.port.get`](ossh.md) · [`private.ossh.config.port.set`](ossh.md) · [`private.ossh.config.proxyJump.get`](ossh.md) · [`private.ossh.config.proxyJump.set`](ossh.md) · [`private.ossh.config.user.get`](ossh.md) · [`private.ossh.config.user.set`](ossh.md) |
| `message` | `agentRoom.message` | [`agentRoom.chat`](agentRoom.md) |
|  | `claudeCode.message` | [`claudeCode.system.prompt`](claudeCode.md) · [`claudeCode.system.prompt.append`](claudeCode.md) |
|  | `claudeFlow.message` | [`claudeFlow.hive.broadcast`](claudeFlow.md) |
|  | `hiveMind.message` | [`hiveMind.agent.send`](hivemind.md) · [`hiveMind.auto.commit`](hivemind.md) · [`hiveMind.broadcast`](hivemind.md) · [`hiveMind.git.commit`](hivemind.md) · [`hiveMind.send.enter`](hivemind.md) · [`hiveMind.send.message`](hivemind.md) · [`hiveMind.task.delegate`](hivemind.md) |
|  | `ogit.message` | [`ogit.branch.adopt`](ogit.md) · [`ogit.commit.create`](ogit.md) · [`ogit.stash.push`](ogit.md) |
|  | `otmux.message` | [`otmux.display`](otmux.md) · [`otmux.msg`](otmux.md) · [`otmux.send.display`](otmux.md) |
|  | `promote.message` | [`private.promote.merge.finish`](promote.md) |
| `number` | `disk.number` | [`disk.calc.bytes.from.gb`](disk.md) · [`disk.calc.bytes.from.kb`](disk.md) · [`disk.calc.bytes.from.mb`](disk.md) · [`disk.calc.bytes.from.tb`](disk.md) · [`disk.calc.bytes.to.gb`](disk.md) · [`disk.calc.bytes.to.kb`](disk.md) · [`disk.calc.bytes.to.mb`](disk.md) · [`disk.calc.bytes.to.tb`](disk.md) · [`disk.calc.getBytesInGB`](disk.md) · [`disk.calc.getBytesInKB`](disk.md) · [`disk.calc.getBytesInMB`](disk.md) · [`disk.calc.getBytesInTB`](disk.md) · [`disk.calc.getGB`](disk.md) · [`disk.calc.getKB`](disk.md) · [`disk.calc.getMB`](disk.md) · [`disk.calc.getTB`](disk.md) |
|  | `hiveMind.number` | [`hiveMind.improvement`](hivemind.md) · [`hiveMind.plan.improve`](hivemind.md) |
| `option` | `hiveMind.option` | [`hiveMind.agent.rewind`](hivemind.md) · [`hiveMind.monitor.approve`](hivemind.md) · [`private.hiveMind.agent.overlay.dispatch`](hivemind.md) · [`private.hiveMind.agent.overlay.key`](hivemind.md) |
|  | `otmux.option` | [`otmux.config.set`](otmux.md) · [`otmux.config.set.global`](otmux.md) · [`otmux.config.set.window`](otmux.md) · [`otmux.config.show`](otmux.md) · [`otmux.config.show.global`](otmux.md) · [`otmux.config.show.window`](otmux.md) · [`otmux.set`](otmux.md) · [`otmux.show`](otmux.md) · [`private.otmux.setGlobal`](otmux.md) · [`private.otmux.setWindow`](otmux.md) · [`private.otmux.showGlobal`](otmux.md) · [`private.otmux.showWindow`](otmux.md) |
|  | `this.option` | [`this.absolutePath`](this.md) · [`this.absolutePathName`](this.md) |
| `prompt` | `claudeCode.prompt` | [`claudeCode.chat`](claudeCode.md) · [`claudeCode.dangerously`](claudeCode.md) · [`claudeCode.haiku`](claudeCode.md) · [`claudeCode.json`](claudeCode.md) · [`claudeCode.model`](claudeCode.md) · [`claudeCode.new`](claudeCode.md) · [`claudeCode.opus`](claudeCode.md) · [`claudeCode.output`](claudeCode.md) · [`claudeCode.p`](claudeCode.md) · [`claudeCode.print`](claudeCode.md) · [`claudeCode.sonnet`](claudeCode.md) · [`claudeCode.system.prompt`](claudeCode.md) · [`claudeCode.system.prompt.append`](claudeCode.md) · [`claudeCode.turns.max`](claudeCode.md) · [`claudeCode.verbose`](claudeCode.md) · [`claudeCode.yolo`](claudeCode.md) |
|  | `claudeFlow.prompt` | [`claudeFlow.tmux.task`](claudeFlow.md) |
|  | `hiveMind.prompt` | [`hiveMind.claude`](hivemind.md) |
| `toHost` | `ossh.toHost` | [`ossh.config.push`](ossh.md) · [`ossh.dir.push`](ossh.md) · [`ossh.exec`](ossh.md) · [`ossh.exec.tty`](ossh.md) · [`ossh.id.push`](ossh.md) · [`ossh.key.push`](ossh.md) · [`ossh.push.config`](ossh.md) · [`ossh.push.dir`](ossh.md) · [`ossh.push.id`](ossh.md) · [`ossh.push.key`](ossh.md) · [`ossh.tunnel`](ossh.md) · [`private.ossh.config.push`](ossh.md) · [`private.ossh.dir.push`](ossh.md) · [`private.ossh.id.push`](ossh.md) · [`private.ossh.identity.stage`](ossh.md) · [`private.ossh.identity.stage.outer.fromRunner`](ossh.md) · [`private.ossh.identity.stage.outer.proxyJump`](ossh.md) · [`private.ossh.key.push`](ossh.md) |
| `branch` | `ogit.branch` | [`ogit.branch.remote.delete`](ogit.md) · [`ogit.branch.reset`](ogit.md) · [`ogit.remote.pull`](ogit.md) · [`ogit.remote.push`](ogit.md) · [`ogit.repo.clone`](ogit.md) · [`ogit.worktree.add`](ogit.md) · [`ogit.worktree.find`](ogit.md) · [`private.ogit.branch.import`](ogit.md) |
|  | `oo.branch` | [`oo.mode`](oo.md) · [`oo.mode.sync`](oo.md) · [`oo.use`](oo.md) · [`private.oo.branch.clone.ensure`](oo.md) · [`private.oo.shared.tree.ensure`](oo.md) |
|  | `otest.branch` | [`otest.deploy`](otest.md) |
|  | `user.branch` | [`user.oosh.install`](user.md) |
| `container` | `odocker.container` | [`odocker.clone`](odocker.md) · [`odocker.container.ip.get`](odocker.md) · [`odocker.container.remove`](odocker.md) · [`odocker.down`](odocker.md) · [`odocker.enter`](odocker.md) · [`odocker.exec`](odocker.md) · [`odocker.exec.command`](odocker.md) · [`odocker.install`](odocker.md) · [`odocker.log`](odocker.md) · [`odocker.prune`](odocker.md) · [`odocker.rm`](odocker.md) · [`odocker.stop`](odocker.md) · [`odocker.up`](odocker.md) · [`private.odocker.container.prereqs.install`](odocker.md) · [`private.odocker.container.repo.add`](odocker.md) |
| `functionNameFilter` | `2c.functionNameFilter` | [`2c.format.functions`](2c.md) · [`2c.get.function.with.documentation`](2c.md) · [`2c.get.functions`](2c.md) |
|  | `c2.functionNameFilter` | [`c2.format.functions`](c2.md) · [`c2.function.description.format`](c2.md) · [`c2.function.get.with.documentation`](c2.md) · [`c2.functions.format`](c2.md) · [`c2.functions.get`](c2.md) · [`c2.get.formated.function.description`](c2.md) · [`c2.get.function.with.documentation`](c2.md) · [`c2.get.functions`](c2.md) · [`private.c2.format.functions`](c2.md) · [`private.c2.get.formated.function.description`](c2.md) · [`private.c2.get.function.with.documentation`](c2.md) · [`private.c2.get.functions`](c2.md) |
| `method` | `c2.method` | [`c2.function.declaration.get`](c2.md) · [`c2.function.parameter.get`](c2.md) · [`c2.get.function.declaration`](c2.md) · [`c2.get.function.parameter`](c2.md) · [`private.c2.get.function.declaration`](c2.md) · [`private.c2.get.function.parameter`](c2.md) |
|  | `line.method` | [`line.each`](line.md) · [`private.line.each`](line.md) |
|  | `ogit.method` | [`private.ogit.sudo.rerun`](ogit.md) |
|  | `os.method` | [`os.check`](os.md) |
|  | `ossh.method` | [`ossh.config.parse`](ossh.md) · [`ossh.config.parse.url`](ossh.md) |
|  | `setup.method` | [`private.setup.all.step`](setup.md) |
|  | `state.method` | [`state.of`](state.md) |
|  | `this.method` | [`this.methodNotFound`](this.md) |
| `subcommand` | `claudeFlow.subcommand` | [`claudeFlow.agent`](claudeFlow.md) · [`claudeFlow.embeddings`](claudeFlow.md) · [`claudeFlow.hive`](claudeFlow.md) · [`claudeFlow.hooks`](claudeFlow.md) · [`claudeFlow.mcp`](claudeFlow.md) · [`claudeFlow.memory`](claudeFlow.md) · [`claudeFlow.neural`](claudeFlow.md) · [`claudeFlow.perf`](claudeFlow.md) · [`claudeFlow.performance`](claudeFlow.md) · [`claudeFlow.security`](claudeFlow.md) · [`claudeFlow.session`](claudeFlow.md) · [`claudeFlow.statusline`](claudeFlow.md) · [`claudeFlow.swarm`](claudeFlow.md) · [`claudeFlow.task`](claudeFlow.md) · [`claudeFlow.tmux`](claudeFlow.md) |
| `url` | `odocker.url` | [`private.odocker.docker.repo.download`](odocker.md) · [`private.odocker.workspaces.fetch.url`](odocker.md) |
|  | `ogit.url` | [`ogit.remote.pull`](ogit.md) · [`ogit.remote.url.set`](ogit.md) · [`ogit.repo.clone`](ogit.md) |
|  | `oo.url` | [`private.oo.branch.clone.ensure`](oo.md) · [`private.oo.shared.tree.ensure`](oo.md) |
|  | `ossh.url` | [`ossh.config.create`](ossh.md) · [`ossh.config.parse.url`](ossh.md) · [`ossh.create.and.install`](ossh.md) · [`ossh.install.create`](ossh.md) |
|  | `otest.url` | [`otest.browser.open`](otest.md) · [`otest.newTest`](otest.md) |
|  | `this.url` | [`private.this.url.download`](this.md) |
|  | `webitem.url` | [`webitem.create`](webitem.md) |
| `sshConfigName` | `config.sshConfigName` | [`config.ssh.host.set`](config.md) |
|  | `myId.sshConfigName` | [`myId.create`](myId.md) · [`myId.create.github.deploy.key`](myId.md) · [`myId.get`](myId.md) · [`myId.key.deploy.create`](myId.md) |
|  | `ossh.sshConfigName` | [`ossh.config.create`](ossh.md) · [`ossh.config.push`](ossh.md) · [`ossh.pull.config`](ossh.md) · [`ossh.push.config`](ossh.md) · [`private.ossh.config.block.put.get`](ossh.md) · [`private.ossh.config.push`](ossh.md) |
|  | `parameterTestScript.sshConfigName` | [`parameterTestScript.one`](parameterTestScript.md) · [`parameterTestScript.oneDefaultValue`](parameterTestScript.md) · [`parameterTestScript.oneDefaultValueQuotes`](parameterTestScript.md) |
| `version` | `oo.version` | [`oo.checkout`](oo.md) · [`oo.checkout.remove`](oo.md) · [`private.oo.checkout.dir.get`](oo.md) |
|  | `opy.version` | [`opy.deps`](opy.md) · [`opy.install`](opy.md) · [`opy.remove`](opy.md) · [`opy.update`](opy.md) · [`opy.venv.create`](opy.md) · [`opy.version.set`](opy.md) · [`private.opy.activateLatest`](opy.md) · [`private.opy.isInstalled`](opy.md) · [`private.opy.python`](opy.md) |
|  | `setup.version` | [`setup.nodejs`](setup.md) · [`setup.nvm`](setup.md) |
| `configPath` | `backup.configPath` | [`backup.config.disable`](backup.md) · [`backup.config.enable`](backup.md) · [`backup.config.register`](backup.md) · [`backup.config.repair`](backup.md) · [`backup.config.unregister`](backup.md) · [`private.backup.repair.config`](backup.md) |
|  | `config.configPath` | [`private.config.log.chain.migrate`](config.md) · [`private.config.oosh.session.migrate`](config.md) · [`private.config.oosh.session.split.is`](config.md) · [`private.config.session.chain.ready`](config.md) · [`private.config.session.split.is`](config.md) · [`private.config.user.session.migrate`](config.md) |
|  | `test.suite.configPath` | [`private.test.suite.config.stamp.get`](test.suite.md) |
| `fromHost` | `ossh.fromHost` | [`ossh.config.pull`](ossh.md) · [`ossh.dir.pull`](ossh.md) · [`ossh.id.pull`](ossh.md) · [`ossh.key.pull`](ossh.md) · [`ossh.pull.config`](ossh.md) · [`ossh.pull.dir`](ossh.md) · [`ossh.pull.id`](ossh.md) · [`ossh.pull.key`](ossh.md) · [`private.ossh.config.pull`](ossh.md) · [`private.ossh.dir.pull`](ossh.md) · [`private.ossh.key.pull`](ossh.md) · [`private.ossh.pull.id`](ossh.md) · [`private.ossh.remote.key.file.name.get`](ossh.md) |
| `key` | `claudeFlow.key` | [`claudeFlow.memory.delete`](claudeFlow.md) · [`claudeFlow.memory.get`](claudeFlow.md) · [`claudeFlow.memory.rm`](claudeFlow.md) |
|  | `hiveMind.key` | [`private.hiveMind.env.del`](hivemind.md) · [`private.hiveMind.env.set`](hivemind.md) |
|  | `ogit.key` | [`ogit.config.get`](ogit.md) · [`ogit.config.set`](ogit.md) |
|  | `os.key` | [`private.os.release.get`](os.md) |
|  | `otmux.key` | [`otmux.bind`](otmux.md) · [`otmux.key.bind`](otmux.md) · [`otmux.key.unbind`](otmux.md) · [`otmux.send.key`](otmux.md) · [`otmux.unbind`](otmux.md) |
| `id` | `myId.id` | [`myId.list`](myId.md) |
|  | `ossh.id` | [`ossh.get.public.id`](ossh.md) · [`ossh.id.public.get`](ossh.md) · [`ossh.id.push`](ossh.md) · [`ossh.list.ids`](ossh.md) · [`ossh.publicId.get`](ossh.md) · [`ossh.push.id`](ossh.md) · [`private.ossh.get.public.id`](ossh.md) · [`private.ossh.id.push`](ossh.md) |
|  | `parameterTestScript.id` | [`parameterTestScript.apostropheDesc`](parameterTestScript.md) · [`parameterTestScript.optional`](parameterTestScript.md) · [`parameterTestScript.optionalDefaultValue`](parameterTestScript.md) |
| `format` | `claudeCode.format` | [`claudeCode.output`](claudeCode.md) |
|  | `hiveMind.format` | [`private.hiveMind.list.panes`](hivemind.md) |
|  | `line.format` | [`line.format`](line.md) · [`line.format.env`](line.md) |
|  | `ogit.format` | [`ogit.commit.log.show`](ogit.md) · [`ogit.diff.show`](ogit.md) · [`ogit.status.show`](ogit.md) |
|  | `otmux.format` | [`otmux.pane.get`](otmux.md) · [`otmux.pane.list.format`](otmux.md) · [`otmux.pane.self`](otmux.md) · [`otmux.window.list.format`](otmux.md) |
| `mode` | `claudeFlow.mode` | [`claudeFlow.tmux.bind`](claudeFlow.md) |
|  | `hiveMind.mode` | [`hiveMind.consistency.reconcile`](hivemind.md) · [`private.hiveMind.ctx.refresh.impl`](hivemind.md) · [`private.hiveMind.ctxrefresh.eval`](hivemind.md) · [`private.hiveMind.shell.reap.impl`](hivemind.md) |
|  | `odocker.mode` | [`private.odocker.prereq.package.get`](odocker.md) |
|  | `ogit.mode` | [`ogit.branch.remote.delete`](ogit.md) · [`ogit.commit.revert`](ogit.md) |
|  | `oo.mode` | [`oo.commit`](oo.md) · [`private.oo.path.sudo.get`](oo.md) |
|  | `ossh.mode` | [`ossh.folder.fix`](ossh.md) |
| `text` | `hiveMind.text` | [`hiveMind.send`](hivemind.md) · [`private.hiveMind.agent.inform`](hivemind.md) · [`private.hiveMind.agent.queue.enqueue`](hivemind.md) |
|  | `line.text` | [`line.remove.exact`](line.md) |
|  | `oo.text` | [`private.oo.regex.escape.get`](oo.md) |
|  | `osemvec.text` | [`osemvec.update`](osemvec.md) |
|  | `otmux.text` | [`otmux.pane.send`](otmux.md) · [`otmux.send.enter`](otmux.md) · [`otmux.send.verified`](otmux.md) · [`private.otmux.send.smart`](otmux.md) · [`private.otmux.sendEnter`](otmux.md) |
| `args` | `c2.args` | [`c2.function.parameter.get`](c2.md) · [`c2.get.function.parameter`](c2.md) · [`private.c2.get.function.parameter`](c2.md) |
|  | `ogit.args` | [`ogit.raw`](ogit.md) · [`private.ogit.git.run`](ogit.md) |
|  | `opy.args` | [`private.opy.pyenv`](opy.md) |
|  | `osemvec.args` | [`private.osemvec.pss`](osemvec.md) |
|  | `ossh.args` | [`ossh.get`](ossh.md) · [`ossh.set`](ossh.md) · [`private.ossh.dispatch`](ossh.md) |
| `base` | `ogit.base` | [`ogit.layout.status`](ogit.md) · [`ogit.safeDirectory.ensure`](ogit.md) · [`ogit.worktree.remove`](ogit.md) · [`ogit.worktree.restore`](ogit.md) · [`private.ogit.base.folders.list`](ogit.md) · [`private.ogit.base.get`](ogit.md) · [`private.ogit.root.check`](ogit.md) · [`private.ogit.sudo.rerun`](ogit.md) |
|  | `oo.base` | [`private.oo.layout.folder.check`](oo.md) · [`private.oo.shared.tree.ensure`](oo.md) |
| `device` | `log.device` | [`log.clear.liveLog`](log.md) · [`log.device`](log.md) · [`log.live`](log.md) · [`log.live.error`](log.md) · [`log.live.file`](log.md) · [`log.live.result.env`](log.md) · [`log.live.result.txt`](log.md) · [`private.log.device.is.capture`](log.md) · [`private.log.device.is.session`](log.md) |
|  | `this.device` | [`private.this.device.is.terminal`](this.md) |
| `lines` | `agentRoom.lines` | [`agentRoom.logs`](agentRoom.md) |
|  | `hiveMind.lines` | [`hiveMind.agent.monitor`](hivemind.md) · [`hiveMind.events.history`](hivemind.md) · [`hiveMind.metrics.summary`](hivemind.md) · [`hiveMind.team.monitor`](hivemind.md) |
|  | `odocker.lines` | [`odocker.log`](odocker.md) |
|  | `otmux.lines` | [`otmux.pane.capture`](otmux.md) · [`otmux.pane.history`](otmux.md) |
|  | `scrumMaster.lines` | [`scrumMaster.velocity.history`](scrumMaster.md) |
|  | `tronMonitor.lines` | [`private.tronMonitor.screen.capture`](tronMonitor.md) |
| `reset` | `oo.reset` | [`oo.dev.to.testing`](oo.md) · [`oo.mode.stage`](oo.md) · [`oo.release`](oo.md) · [`oo.stage`](oo.md) · [`oo.testing.to.prod`](oo.md) |
|  | `ossh.reset` | [`ossh.certificates.update`](ossh.md) |
|  | `promote.reset` | [`promote.dev.to.testing`](promote.md) · [`promote.prod`](promote.md) · [`promote.testing`](promote.md) · [`promote.testing.to.prod`](promote.md) |
| `agent` | `hiveMind.agent` | [`hiveMind.agent.context.status`](hivemind.md) · [`hiveMind.context.gather`](hivemind.md) · [`hiveMind.context.gather.quiet`](hivemind.md) · [`hiveMind.context.get`](hivemind.md) · [`hiveMind.context.record`](hivemind.md) · [`private.hiveMind.ctxrefresh.due`](hivemind.md) · [`private.hiveMind.ctxrefresh.eval`](hivemind.md) · [`private.hiveMind.ctxrefresh.mark`](hivemind.md) · [`private.hiveMind.ctxrefresh.statefile`](hivemind.md) |
| `projectDir` | `osemvec.projectDir` | [`osemvec.context`](osemvec.md) · [`osemvec.error`](osemvec.md) · [`osemvec.index`](osemvec.md) · [`osemvec.new`](osemvec.md) · [`osemvec.register`](osemvec.md) · [`osemvec.save`](osemvec.md) · [`osemvec.update`](osemvec.md) · [`private.osemvec.provision`](osemvec.md) · [`private.osemvec.pss`](osemvec.md) |
| `sessionId` | `claudeCode.sessionId` | [`claudeCode.fork`](claudeCode.md) · [`claudeCode.fork.byID`](claudeCode.md) · [`claudeCode.join.byID`](claudeCode.md) · [`claudeCode.session.name`](claudeCode.md) · [`private.claudeCode.resolve.projectDir`](claudeCode.md) |
|  | `claudeFlow.sessionId` | [`claudeFlow.session.delete`](claudeFlow.md) · [`claudeFlow.session.load`](claudeFlow.md) · [`claudeFlow.session.restore`](claudeFlow.md) · [`claudeFlow.session.rm`](claudeFlow.md) |
| `teamSession` | `hiveMind.teamSession` | [`hiveMind.team.push`](hivemind.md) · [`private.hiveMind.push.preflight`](hivemind.md) · [`private.hiveMind.push.resolveCanonical`](hivemind.md) |
|  | `tronMonitor.teamSession` | [`private.tronMonitor.findWindow`](tronMonitor.md) · [`private.tronMonitor.screen.showsTeam`](tronMonitor.md) · [`tronMonitor.add`](tronMonitor.md) · [`tronMonitor.fit`](tronMonitor.md) · [`tronMonitor.remove`](tronMonitor.md) · [`tronMonitor.switch`](tronMonitor.md) |
| `treeRoot` | `ogit.treeRoot` | [`ogit.caller.validate`](ogit.md) |
|  | `path.treeRoot` | [`path.validate`](path.md) |
|  | `test.suite.treeRoot` | [`test.suite.portability.validate`](test.suite.md) |
|  | `this.treeRoot` | [`private.this.anchor.validate.one`](this.md) · [`private.this.marker.sweep`](this.md) · [`private.this.tree.tracked.check`](this.md) · [`this.anchor.validate`](this.md) · [`this.config.path.validate`](this.md) · [`this.oosh.dir.validate`](this.md) |
| `image` | `odocker.image` | [`odocker.create`](odocker.md) · [`odocker.image.command`](odocker.md) · [`odocker.image.remove`](odocker.md) · [`odocker.reset`](odocker.md) · [`odocker.rmi`](odocker.md) · [`odocker.run`](odocker.md) · [`odocker.run.sshd`](odocker.md) · [`private.odocker.container.name.new`](odocker.md) |
| `interval` | `hiveMind.interval` | [`hiveMind.pane.sweep`](hivemind.md) · [`hiveMind.pane.sweep.cycle`](hivemind.md) · [`hiveMind.sweep`](hivemind.md) · [`hiveMind.sweep.cycle`](hivemind.md) · [`hiveMind.team.loop`](hivemind.md) · [`hiveMind.team.sweep`](hivemind.md) · [`hiveMind.watchdog.supervisor`](hivemind.md) |
|  | `scrumMaster.interval` | [`scrumMaster.cycle`](scrumMaster.md) |
| `ref` | `ogit.ref` | [`ogit.branch.adopt`](ogit.md) · [`ogit.branch.check`](ogit.md) · [`ogit.branch.checkout`](ogit.md) · [`ogit.branch.fastForward`](ogit.md) · [`ogit.branch.merge`](ogit.md) · [`ogit.branch.upstream.set`](ogit.md) · [`ogit.commit.show`](ogit.md) · [`ogit.tag.create`](ogit.md) |
| `asEmail` | `ogit.asEmail` | [`ogit.branch.adopt`](ogit.md) · [`ogit.branch.merge`](ogit.md) · [`ogit.commit.create`](ogit.md) · [`ogit.commit.pick`](ogit.md) · [`ogit.commit.pick.continue`](ogit.md) · [`ogit.commit.revert`](ogit.md) · [`private.ogit.identity`](ogit.md) |
| `asName` | `ogit.asName` | [`ogit.branch.adopt`](ogit.md) · [`ogit.branch.merge`](ogit.md) · [`ogit.commit.create`](ogit.md) · [`ogit.commit.pick`](ogit.md) · [`ogit.commit.pick.continue`](ogit.md) · [`ogit.commit.revert`](ogit.md) · [`private.ogit.identity`](ogit.md) |
| `cmd` | `odocker.cmd` | [`private.odocker.prereq.package.get`](odocker.md) |
|  | `oo.cmd` | [`oo.cmd`](oo.md) · [`oo.cmd.find`](oo.md) · [`private.oo.cmd.verify`](oo.md) · [`private.oo.find.cmd`](oo.md) |
|  | `setup.cmd` | [`private.setup.cmds.install`](setup.md) · [`private.setup.package.get`](setup.md) |
| `field` | `odocker.field` | [`private.odocker.docker.repo.get`](odocker.md) |
|  | `ossh.field` | [`ossh.config.field.get`](ossh.md) · [`ossh.config.set`](ossh.md) · [`private.ossh.config.field.get`](ossh.md) · [`private.ossh.config.field.keyword.get`](ossh.md) · [`private.ossh.config.field.set`](ossh.md) |
|  | `this.field` | [`private.this.path.stat.get`](this.md) |
| `folder` | `ogit.folder` | [`ogit.folder.finish`](ogit.md) · [`private.ogit.clone.gate`](ogit.md) · [`private.ogit.folder.gate`](ogit.md) · [`private.ogit.folder.ignored.restore`](ogit.md) · [`private.ogit.folder.ignored.save`](ogit.md) · [`private.ogit.folder.shape`](ogit.md) |
|  | `oo.folder` | [`private.oo.layout.folder.check`](oo.md) |
| `from` | `hiveMind.from` | [`hiveMind.delegate`](hivemind.md) |
|  | `line.from` | [`line.find`](line.md) |
|  | `odocker.from` | [`odocker.workspace.seed`](odocker.md) |
|  | `ogit.from` | [`ogit.branch.compare`](ogit.md) · [`ogit.commit.count`](ogit.md) |
|  | `promote.from` | [`promote.branch.alignment`](promote.md) |
|  | `this.from` | [`private.this.folder.entries.copy`](this.md) |
| `groupName` | `this.groupName` | [`private.this.group.create`](this.md) · [`private.this.group.exists`](this.md) · [`private.this.group.members.get`](this.md) |
|  | `user.groupName` | [`private.user.check.group`](user.md) · [`user.check.group`](user.md) · [`user.group.add`](user.md) · [`user.group.check`](user.md) |
| `source` | `odocker.source` | [`private.odocker.workspaces.merge`](odocker.md) · [`private.odocker.workspaces.merge.answer.get`](odocker.md) |
|  | `ogit.source` | [`ogit.branch.list`](ogit.md) |
|  | `oo.source` | [`oo.branch.list`](oo.md) |
|  | `osemvec.source` | [`osemvec.error`](osemvec.md) |
|  | `promote.source` | [`private.promote.merge.into.folder`](promote.md) · [`private.promote.merge.preview.show`](promote.md) |
| `label` | `os.label` | [`private.os.service.off.darwin`](os.md) · [`private.os.service.on.darwin`](os.md) |
|  | `test.suite.label` | [`test.suite.config.isolate`](test.suite.md) · [`test.suite.fixture.make`](test.suite.md) |
|  | `this.label` | [`private.this.temp.dir.get`](this.md) |
|  | `user.label` | [`user.ssh.backup`](user.md) |
| `logLevel` | `ossh.logLevel` | [`ossh.install`](ossh.md) |
|  | `test.suite.logLevel` | [`test.suite.all`](test.suite.md) · [`test.suite.core`](test.suite.md) · [`test.suite.extended`](test.suite.md) · [`test.suite.gate`](test.suite.md) · [`test.suite.run`](test.suite.md) |
| `machineName` | `scrumMaster.machineName` | [`scrumMaster.pdca.errors`](scrumMaster.md) · [`scrumMaster.pdca.iteration`](scrumMaster.md) · [`scrumMaster.pdca.next`](scrumMaster.md) · [`scrumMaster.pdca.reset`](scrumMaster.md) · [`scrumMaster.pdca.run`](scrumMaster.md) · [`scrumMaster.pdca.state`](scrumMaster.md) |
| `pattern` | `ogit.pattern` | [`ogit.repo.grep`](ogit.md) · [`ogit.tag.latest.get`](ogit.md) · [`ogit.tag.list`](ogit.md) |
|  | `otmux.pattern` | [`otmux.window.find`](otmux.md) · [`private.otmux.findWindow`](otmux.md) |
|  | `this.pattern` | [`private.this.marker.sweep`](this.md) |
| `scope` | `backup.scope` | [`backup.config.save`](backup.md) |
|  | `hiveMind.scope` | [`private.hiveMind.list.panes`](hivemind.md) · [`private.hiveMind.shell.reap.impl`](hivemind.md) |
|  | `ogit.scope` | [`ogit.config.get`](ogit.md) · [`ogit.index.add`](ogit.md) |
|  | `oo.scope` | [`oo.test.platform.new`](oo.md) |
| `service` | `odocker.service` | [`odocker.compose`](odocker.md) |
|  | `os.service` | [`os.service.off`](os.md) · [`os.service.on`](os.md) · [`private.os.service.off.linux`](os.md) · [`private.os.service.on.linux`](os.md) |
|  | `setup.service` | [`private.setup.services.switch`](setup.md) |
| `window` | `otmux.window` | [`otmux.kw`](otmux.md) · [`otmux.pane.join`](otmux.md) · [`otmux.pane.move`](otmux.md) · [`otmux.sw`](otmux.md) · [`private.otmux.joinPane`](otmux.md) · [`private.otmux.movePane`](otmux.md) |
| `word` | `line.word` | [`line.filter`](line.md) · [`line.replace`](line.md) · [`line.replace.sedquoted`](line.md) · [`line.split.quoted`](line.md) |
|  | `promote.word` | [`private.promote.argument.apply`](promote.md) |
|  | `replace.word` | [`replace.word`](replace.md) |
| `auth` | `hiveMind.auth` | [`hiveMind.agent.rewind`](hivemind.md) |
|  | `osemvec.auth` | [`osemvec.guard`](osemvec.md) · [`osemvec.stop`](osemvec.md) · [`private.osemvec.authorized`](osemvec.md) · [`private.osemvec.stopAuthorized`](osemvec.md) |
| `docker` | `odocker.docker` | [`odocker.clone`](odocker.md) · [`odocker.reset`](odocker.md) · [`odocker.run`](odocker.md) · [`odocker.run.sshd`](odocker.md) · [`odocker.up`](odocker.md) |
| `height` | `otmux.height` | [`otmux.pane.size.set`](otmux.md) · [`otmux.size.lock`](otmux.md) · [`otmux.window.size.floor.apply`](otmux.md) · [`otmux.window.size.lock`](otmux.md) · [`private.otmux.size.lock.set`](otmux.md) |
| `home` | `config.home` | [`private.config.oosh.session.file.get`](config.md) · [`private.config.user.session.file.get`](config.md) |
|  | `oo.home` | [`private.oo.once.path.migrate`](oo.md) |
|  | `user.home` | [`user.ssh.backup.migrate`](user.md) · [`user.ssh.backup.status`](user.md) |
| `newName` | `hiveMind.newName` | [`hiveMind.agent.rename`](hivemind.md) · [`hiveMind.protected.session.renamed`](hivemind.md) |
|  | `otmux.newName` | [`otmux.rename`](otmux.md) · [`otmux.rw`](otmux.md) |
|  | `this.newName` | [`this.function.partial`](this.md) |
| `paneTarget` | `hiveMind.paneTarget` | [`private.hiveMind.liveUuid`](hivemind.md) · [`private.hiveMind.monitor.switch`](hivemind.md) · [`private.hiveMind.pane.kind`](hivemind.md) · [`private.hiveMind.pane.model`](hivemind.md) · [`private.hiveMind.wait.for.claude`](hivemind.md) |
| `platform` | `os.platform` | [`platform.parse.check`](os.md) · [`platform.test`](os.md) · [`private.platform.parse`](os.md) · [`private.platform.shared.config.repair`](os.md) · [`private.platform.test.ci`](os.md) |
| `port` | `os.port` | [`private.platform.cleanup`](os.md) · [`private.platform.container.id`](os.md) · [`private.platform.sshd.reload`](os.md) |
|  | `osemvec.port` | [`osemvec.serve`](osemvec.md) |
|  | `ossh.port` | [`ossh.known.hosts.remove`](ossh.md) |
| `src` | `ossh.src` | [`ossh.scp`](ossh.md) · [`private.ossh.rsync`](ossh.md) · [`private.ossh.rsync.pull`](ossh.md) |
|  | `otmux.src` | [`otmux.window.link`](otmux.md) · [`private.otmux.linkWindow`](otmux.md) |
| `stage` | `odocker.stage` | [`private.odocker.workspaces.fetch.ssh`](odocker.md) · [`private.odocker.workspaces.fetch.url`](odocker.md) · [`private.odocker.workspaces.merge`](odocker.md) |
|  | `oo.stage` | [`oo.mode.stage`](oo.md) · [`oo.stage`](oo.md) |
| `targetHome` | `config.targetHome` | [`private.config.session.file.ensure`](config.md) |
|  | `this.targetHome` | [`private.this.as.user.preamble.get`](this.md) |
|  | `user.targetHome` | [`private.user.bashrc.install`](user.md) · [`private.user.oosh.install.shell.darwin`](user.md) · [`private.user.oosh.install.shell.linux`](user.md) |
| `targetPane` | `hiveMind.targetPane` | [`hiveMind.agent.fork.best`](hivemind.md) · [`private.hiveMind.push.agent`](hivemind.md) · [`private.hiveMind.push.captureForkedUUID`](hivemind.md) |
|  | `otmux.targetPane` | [`otmux.pane.swap`](otmux.md) · [`private.otmux.swapPane`](otmux.md) |
| `taskId` | `claudeFlow.taskId` | [`claudeFlow.task.assign`](claudeFlow.md) · [`claudeFlow.task.cancel`](claudeFlow.md) · [`claudeFlow.task.info`](claudeFlow.md) · [`claudeFlow.task.retry`](claudeFlow.md) · [`claudeFlow.task.status`](claudeFlow.md) |
| `to` | `line.to` | [`line.find`](line.md) |
|  | `ogit.to` | [`ogit.branch.compare`](ogit.md) · [`ogit.commit.count`](ogit.md) |
|  | `promote.to` | [`promote.branch.alignment`](promote.md) |
|  | `this.to` | [`private.this.folder.entries.copy`](this.md) |
| `width` | `otmux.width` | [`otmux.pane.size.set`](otmux.md) · [`otmux.size.lock`](otmux.md) · [`otmux.window.size.floor.apply`](otmux.md) · [`otmux.window.size.lock`](otmux.md) · [`private.otmux.size.lock.set`](otmux.md) |
| `buffer` | `otmux.buffer` | [`otmux.buffer.delete`](otmux.md) · [`otmux.buffer.show`](otmux.md) · [`private.otmux.deleteBuffer`](otmux.md) · [`private.otmux.showBuffer`](otmux.md) |
| `by` | `line.by` | [`line.filter`](line.md) · [`line.replace`](line.md) · [`line.replace.sedquoted`](line.md) · [`line.split.quoted`](line.md) |
| `charakter` | `line.charakter` | [`line.join`](line.md) · [`line.key`](line.md) · [`line.space2`](line.md) · [`line.value`](line.md) |
| `currentID` | `state.currentID` | [`private.itterator.check.all.states.added`](state.md) · [`private.itterator.check.started`](state.md) · [`private.itterator.find`](state.md) · [`private.itterator.list`](state.md) |
| `currentName` | `state.currentName` | [`private.itterator.check.all.states.added`](state.md) · [`private.itterator.check.started`](state.md) · [`private.itterator.find`](state.md) · [`private.itterator.list`](state.md) |
| `currentValue` | `state.currentValue` | [`private.itterator.check.all.states.added`](state.md) · [`private.itterator.check.started`](state.md) · [`private.itterator.find`](state.md) · [`private.itterator.list`](state.md) |
| `direction` | `otmux.direction` | [`otmux.pane.resize`](otmux.md) · [`otmux.rp`](otmux.md) · [`otmux.sp`](otmux.md) · [`private.otmux.resizePane`](otmux.md) |
| `eventName` | `hiveMind.eventName` | [`hiveMind.protected.events.emit`](hivemind.md) · [`hiveMind.protected.events.register`](hivemind.md) · [`private.hiveMind.events.emit`](hivemind.md) · [`private.hiveMind.events.register`](hivemind.md) |
| `functionName` | `line.functionName` | [`line.find.function`](line.md) · [`line.function.find`](line.md) · [`line.get.parameter`](line.md) · [`line.parameter.get`](line.md) |
| `gid` | `odocker.gid` | [`private.odocker.socket.gid.check`](odocker.md) |
|  | `this.gid` | [`private.this.group.create`](this.md) · [`private.this.group.name.get`](this.md) |
|  | `user.gid` | [`user.create`](user.md) |
| `idName` | `myId.idName` | [`myId.create.github.deploy.key`](myId.md) · [`myId.key.deploy.create`](myId.md) |
|  | `ossh.idName` | [`ossh.id.create`](ossh.md) · [`ossh.id.create.fromKey`](ossh.md) |
| `keyName` | `ossh.keyName` | [`ossh.key.push`](ossh.md) · [`ossh.pull.key`](ossh.md) · [`ossh.push.key`](ossh.md) · [`private.ossh.key.push`](ossh.md) |
| `keys` | `otmux.keys` | [`otmux.send`](otmux.md) · [`otmux.send.keys`](otmux.md) · [`otmux.send.raw`](otmux.md) · [`otmux.send.tui`](otmux.md) |
| `line` | `config.line` | [`private.config.env.line.append`](config.md) |
|  | `log.line` | [`private.log.emit`](log.md) |
|  | `this.line` | [`private.this.file.line.ensure`](this.md) |
|  | `user.line` | [`private.user.authorized.key.get`](user.md) |
| `newClassName` | `oo.newClassName` | [`oo.new`](oo.md) · [`oo.new.test`](oo.md) · [`oo.test.new`](oo.md) · [`private.oo.new.test`](oo.md) |
| `password` | `user.password` | [`user.create`](user.md) · [`user.password.set`](user.md) · [`user.password.set.darwin`](user.md) · [`user.password.set.linux`](user.md) |
| `portOrOffset` | `odocker.portOrOffset` | [`odocker.clone`](odocker.md) · [`odocker.reset`](odocker.md) · [`odocker.run.sshd`](odocker.md) · [`odocker.up`](odocker.md) |
| `rc` | `debug.rc` | [`debug.onError`](debug.md) · [`debug.onExit`](debug.md) · [`debug.onReturn`](debug.md) |
|  | `promote.rc` | [`private.promote.merge.finish`](promote.md) |
| `root` | `odocker.root` | [`private.odocker.docker.repo.add`](odocker.md) · [`private.odocker.workspaces.merge`](odocker.md) |
|  | `os.root` | [`private.os.systemd.is`](os.md) |
|  | `this.root` | [`private.this.container.is`](this.md) |
| `seperator` | `line.seperator` | [`line.keys`](line.md) · [`line.split`](line.md) · [`line.table`](line.md) · [`line.values`](line.md) |
| `sourceDir` | `oo.sourceDir` | [`private.oo.install.launcher`](oo.md) · [`private.oo.shared.tree.from.local`](oo.md) · [`private.oo.source.consume.gate`](oo.md) |
|  | `osshLayout.sourceDir` | [`osshLayout.role.outeruser`](osshLayout.md) |
| `sshHost` | `hiveMind.sshHost` | [`hiveMind.task.delegate`](hivemind.md) · [`hiveMind.team.migrate`](hivemind.md) · [`hiveMind.team.pull`](hivemind.md) · [`private.hiveMind.task.transfer`](hivemind.md) |
| `sshKeyName` | `ossh.sshKeyName` | [`ossh.key.name.set`](ossh.md) · [`ossh.key.set.name`](ossh.md) · [`private.ossh.set.key.name`](ossh.md) |
|  | `user.sshKeyName` | [`user.ssh.rename.files`](user.md) |
| `test` | `test.suite.test` | [`private.test.suite.list.names`](test.suite.md) · [`private.test.suite.list.tags`](test.suite.md) · [`test.suite.list`](test.suite.md) · [`test.suite.run`](test.suite.md) |
| `testFile` | `test.suite.testFile` | [`private.test.suite.shared.report`](test.suite.md) · [`private.test.suite.shared.verify`](test.suite.md) · [`private.test.suite.ssh.report`](test.suite.md) · [`private.test.suite.ssh.verify`](test.suite.md) |
| `verb` | `hiveMind.verb` | [`private.hiveMind.agent.overlay.dispatch`](hivemind.md) · [`private.hiveMind.agent.overlay.key`](hivemind.md) |
|  | `ossh.verb` | [`private.ossh.dispatch`](ossh.md) · [`private.ossh.dispatch.objects`](ossh.md) |
| `workdir` | `hiveMind.workdir` | [`hiveMind.agent.spawn`](hivemind.md) · [`hiveMind.init`](hivemind.md) · [`hiveMind.pane.create`](hivemind.md) · [`hiveMind.spawn`](hivemind.md) |
| `action` | `hiveMind.action` | [`hiveMind.improvement`](hivemind.md) · [`hiveMind.plan.improve`](hivemind.md) |
|  | `state.action` | [`private.check.setup`](state.md) |
| `agent_name` | `scrumMaster.agent_name` | [`scrumMaster.context.read`](scrumMaster.md) · [`scrumMaster.pane.capture`](scrumMaster.md) · [`scrumMaster.speed.check`](scrumMaster.md) |
| `allStates` | `state.allStates` | [`state.check`](state.md) · [`state.find`](state.md) · [`state.rename`](state.md) |
| `amount` | `otmux.amount` | [`otmux.pane.resize`](otmux.md) · [`otmux.rp`](otmux.md) · [`private.otmux.resizePane`](otmux.md) |
| `arg` | `hiveMind.arg` | [`hiveMind.protected.events.emit`](hivemind.md) · [`private.hiveMind.events.emit`](hivemind.md) · [`private.hiveMind.events.history.append`](hivemind.md) |
| `commit` | `ogit.commit` | [`ogit.branch.find`](ogit.md) · [`ogit.commit.pick`](ogit.md) · [`ogit.commit.revert`](ogit.md) |
| `content` | `hiveMind.content` | [`private.hiveMind.sweep.ratelimit.probe`](hivemind.md) |
|  | `replace.content` | [`private.replace.copy.make`](replace.md) |
|  | `this.content` | [`private.this.file.write`](this.md) |
| `count` | `claudeFlow.count` | [`claudeFlow.swarm.scale`](claudeFlow.md) |
|  | `otmux.count` | [`otmux.send.key`](otmux.md) |
|  | `scrumMaster.count` | [`scrumMaster.pdca.errors`](scrumMaster.md) |
| `description` | `hiveMind.description` | [`hiveMind.delegate`](hivemind.md) · [`hiveMind.task`](hivemind.md) · [`hiveMind.team.register`](hivemind.md) |
| `dest` | `ossh.dest` | [`ossh.scp`](ossh.md) · [`private.ossh.rsync`](ossh.md) · [`private.ossh.rsync.pull`](ossh.md) |
| `ENV_PREFIX` | `config.ENV_PREFIX` | [`config.save`](config.md) · [`config.update`](config.md) · [`private.config.save`](config.md) |
| `envVariable` | `config.envVariable` | [`config.get`](config.md) · [`config.set`](config.md) · [`config.unset`](config.md) |
| `headless` | `otest.headless` | [`otest.here`](otest.md) · [`otest.run`](otest.md) · [`otest.updateGolden`](otest.md) |
| `hostname` | `os.hostname` | [`os.hostname.set`](os.md) · [`private.os.hostname.set.darwin`](os.md) · [`private.os.hostname.set.linux`](os.md) |
| `installerEmail` | `ossh.installerEmail` | [`ossh.folder.fix`](ossh.md) |
|  | `osshLayout.installerEmail` | [`osshLayout.build`](osshLayout.md) · [`osshLayout.role.installer`](osshLayout.md) |
| `jsonlFile` | `claudeCode.jsonlFile` | [`private.claudeCode.context.jsonl.lag`](claudeCode.md) · [`private.claudeCode.max.tokens.for.jsonl`](claudeCode.md) · [`private.claudeCode.velocity.calculate`](claudeCode.md) |
| `keyFileName` | `ossh.keyFileName` | [`private.ossh.authorized.key.append.get`](ossh.md) · [`private.ossh.install.key.authorize`](ossh.md) · [`private.ossh.remote.public.key.put`](ossh.md) |
| `knownHosts` | `ossh.knownHosts` | [`ossh.config.shared.github.create`](ossh.md) · [`private.ossh.github.copies.remove`](ossh.md) · [`private.ossh.github.copy.remove`](ossh.md) |
| `listOption` | `disk.listOption` | [`disk.list.by`](disk.md) |
|  | `state.listOption` | [`private.loop.states`](state.md) · [`state.list`](state.md) |
| `log` | `certificates.log` | [`certificates.once.scenario.select`](certificates.md) |
|  | `ossh.log` | [`ossh.isInstalled`](ossh.md) |
|  | `user.log` | [`user.ssh.status`](user.md) |
| `logMode` | `backup.logMode` | [`backup.capture.log.mode`](backup.md) · [`backup.log.capture.mode`](backup.md) · [`private.backup.log.capture.mode`](backup.md) |
| `model` | `claudeCode.model` | [`claudeCode.model`](claudeCode.md) · [`claudeCode.model.set`](claudeCode.md) |
|  | `claudeFlow.model` | [`claudeFlow.tmux.task`](claudeFlow.md) |
| `object` | `ossh.object` | [`ossh.get`](ossh.md) · [`ossh.set`](ossh.md) · [`private.ossh.dispatch`](ossh.md) |
| `owner` | `this.owner` | [`private.ensure.sharedTree`](this.md) · [`private.this.path.owner.set`](this.md) · [`private.this.shared.top.ensure`](this.md) |
| `paneContent` | `scrumMaster.paneContent` | [`private.scrumMaster.parse.state`](scrumMaster.md) · [`private.scrumMaster.parse.timing`](scrumMaster.md) · [`private.scrumMaster.parse.tokens`](scrumMaster.md) |
| `pid` | `hiveMind.pid` | [`hiveMind.process.lookup`](hivemind.md) · [`private.hiveMind.shell.classify`](hivemind.md) |
|  | `osemvec.pid` | [`private.osemvec.ownsProcess`](osemvec.md) |
| `pm` | `odocker.pm` | [`private.odocker.container.repo.add`](odocker.md) · [`private.odocker.docker.repo.get`](odocker.md) |
|  | `oo.pm` | [`private.oo.pm.env.get`](oo.md) |
| `print` | `state.print` | [`state.add`](state.md) · [`state.current`](state.md) · [`state.rename`](state.md) |
| `python` | `osemvec.python` | [`private.osemvec.mcpJson`](osemvec.md) · [`private.osemvec.semvecVersion`](osemvec.md) · [`private.osemvec.settingsJson`](osemvec.md) |
| `reason` | `ossh.reason` | [`private.ossh.connection.error.network.is`](ossh.md) |
|  | `test.suite.reason` | [`private.test.suite.shared.report`](test.suite.md) · [`private.test.suite.ssh.report`](test.suite.md) |
| `remote` | `ogit.remote` | [`ogit.remote.branch.list`](ogit.md) · [`ogit.remote.url.get`](ogit.md) · [`ogit.remote.url.set`](ogit.md) |
| `scenario` | `certificates.scenario` | [`certificates.once.scenario.list`](certificates.md) · [`certificates.once.scenario.select`](certificates.md) · [`certificates.once.scenarios`](certificates.md) |
| `seconds` | `hiveMind.seconds` | [`hiveMind.pane.sweep.loop`](hivemind.md) · [`hiveMind.sweep.loop`](hivemind.md) · [`hiveMind.watchdog`](hivemind.md) |
| `sepearator` | `line.sepearator` | [`line.each`](line.md) · [`line.prepend.all`](line.md) · [`line.unify`](line.md) |
| `sessionSplit` | `config.sessionSplit` | [`private.config.save`](config.md) · [`private.config.variables.export`](config.md) · [`private.config.variables.list`](config.md) |
| `sharedConfig` | `config.sharedConfig` | [`private.config.bashrc.ensure.all`](config.md) · [`private.config.linked.homes.get`](config.md) · [`private.config.session.files.ensure.all`](config.md) |
| `sharedOosh` | `config.sharedOosh` | [`private.config.bashrc.ensure.all`](config.md) · [`private.config.session.files.ensure.all`](config.md) |
|  | `this.sharedOosh` | [`private.this.as.user.preamble.get`](this.md) |
| `sourcePath` | `backup.sourcePath` | [`private.backup.rsync`](backup.md) · [`private.backup.strategy.replaceByFolderLinks`](backup.md) · [`private.backup.strategy.secureMove`](backup.md) |
| `state` | `state.state` | [`state.next`](state.md) · [`state.set`](state.md) · [`state.stage`](state.md) |
| `stateID` | `state.stateID` | [`private.itterator.check.all.states.added`](state.md) · [`private.itterator.check.started`](state.md) · [`private.itterator.list`](state.md) |
| `targetDir` | `ogit.targetDir` | [`ogit.repo.clone`](ogit.md) · [`ogit.worktree.add`](ogit.md) |
|  | `oo.targetDir` | [`private.oo.branch.clone.ensure`](oo.md) |
| `targetPath` | `backup.targetPath` | [`private.backup.rsync`](backup.md) · [`private.backup.strategy.replaceByFolderLinks`](backup.md) · [`private.backup.strategy.secureMove`](backup.md) |
| `template` | `otmux.template` | [`otmux.prompt`](otmux.md) · [`otmux.send.prompt`](otmux.md) |
|  | `setup.template` | [`private.setup.template.install`](setup.md) |
| `title` | `hiveMind.title` | [`private.hiveMind.role.fromTitle`](hivemind.md) |
|  | `otmux.title` | [`otmux.pane.lock`](otmux.md) · [`otmux.pane.title`](otmux.md) |
| `type` | `claudeFlow.type` | [`claudeFlow.tmux.layout`](claudeFlow.md) · [`claudeFlow.tmux.spawn`](claudeFlow.md) |
|  | `osemvec.type` | [`osemvec.update`](osemvec.md) |
| `webkit` | `otest.webkit` | [`otest.here`](otest.md) · [`otest.run`](otest.md) · [`otest.updateGolden`](otest.md) |
| `weblocFile` | `webitem.weblocFile` | [`webitem.webloc2json`](webitem.md) · [`webitem.webloc2url`](webitem.md) · [`webitem.webloc2xml`](webitem.md) |
| `workspace` | `odocker.workspace` | [`odocker.build`](odocker.md) · [`odocker.rebuild`](odocker.md) |
|  | `os.workspace` | [`private.platform.image.from.workspace`](os.md) |
| `a` | `ogit.a` | [`ogit.diff.show`](ogit.md) · [`ogit.merge.base.get`](ogit.md) |
| `aFunction` | `this.aFunction` | [`this.call`](this.md) · [`this.load`](this.md) |
| `agents` | `hiveMind.agents` | [`hiveMind.init`](hivemind.md) |
|  | `scrumMaster.agents` | [`scrumMaster.subscription.check`](scrumMaster.md) |
| `anchor` | `this.anchor` | [`private.this.anchor.validate.one`](this.md) · [`this.anchor.validate`](this.md) |
| `aShellScript` | `this.aShellScript` | [`this.call`](this.md) · [`this.load`](this.md) |
| `b` | `ogit.b` | [`ogit.diff.show`](ogit.md) · [`ogit.merge.base.get`](ogit.md) |
| `c` | `hiveMind.c` | [`private.hiveMind.audit.render.human`](hivemind.md) · [`private.hiveMind.audit.render.json`](hivemind.md) |
| `caller` | `this.caller` | [`private.this.tree.tracked.check`](this.md) · [`this.methodNotFound`](this.md) |
| `category` | `test.suite.category` | [`private.test.suite.run.filtered`](test.suite.md) · [`private.test.suite.verdict`](test.suite.md) |
| `client` | `otmux.client` | [`otmux.client.detach`](otmux.md) · [`private.otmux.detachClient`](otmux.md) |
| `configDir` | `hiveMind.configDir` | [`hiveMind.agent.restart`](hivemind.md) · [`hiveMind.team.restart`](hivemind.md) |
| `configfile` | `config.configfile` | [`config.file`](config.md) · [`config.location`](config.md) |
| `data` | `otmux.data` | [`otmux.buffer.set`](otmux.md) · [`private.otmux.setBuffer`](otmux.md) |
| `defaultColumn1` | `line.defaultColumn1` | [`line.prepend.all`](line.md) · [`line.unify`](line.md) |
| `defaultColumnN` | `line.defaultColumnN` | [`line.prepend.all`](line.md) · [`line.unify`](line.md) |
| `denomK` | `hiveMind.denomK` | [`hiveMind.context.record`](hivemind.md) · [`private.hiveMind.context.set`](hivemind.md) |
| `diff_lines` | `hiveMind.diff_lines` | [`private.hiveMind.audit.render.human`](hivemind.md) · [`private.hiveMind.audit.render.json`](hivemind.md) |
| `disk` | `disk.disk` | [`disk.image`](disk.md) · [`disk.restore.linux`](disk.md) |
| `dst` | `otmux.dst` | [`otmux.window.link`](otmux.md) · [`private.otmux.linkWindow`](otmux.md) |
| `email` | `ossh.email` | [`private.ossh.identity.stage.outer.fromRunner`](ossh.md) |
|  | `osshLayout.email` | [`osshLayout.id.from.email`](osshLayout.md) |
| `envPrefix` | `config.envPrefix` | [`private.config.variables.export`](config.md) · [`private.config.variables.list`](config.md) |
| `exactLine` | `replace.exactLine` | [`replace.line`](replace.md) · [`replace.lines`](replace.md) |
| `filename` | `backup.filename` | [`backup.normalize.filename`](backup.md) |
|  | `hiveMind.filename` | [`private.hiveMind.task.transfer`](hivemind.md) |
| `filepath` | `backup.filepath` | [`backup.normalize.file`](backup.md) · [`backup.normalize.revert`](backup.md) |
| `form` | `config.form` | [`private.config.path.segments.get`](config.md) |
|  | `this.form` | [`private.this.host.name.get`](this.md) |
| `fromPath` | `backup.fromPath` | [`backup.from`](backup.md) · [`backup.source`](backup.md) |
| `githubUrl` | `myId.githubUrl` | [`myId.create.github.deploy.key`](myId.md) · [`myId.key.deploy.create`](myId.md) |
| `group` | `user.group` | [`private.user.group.member.is`](user.md) · [`private.user.group.member.pending`](user.md) |
| `h` | `hiveMind.h` | [`private.hiveMind.audit.render.human`](hivemind.md) · [`private.hiveMind.audit.render.json`](hivemind.md) |
| `handlerFunction` | `hiveMind.handlerFunction` | [`hiveMind.protected.events.register`](hivemind.md) · [`private.hiveMind.events.register`](hivemind.md) |
| `hook` | `otmux.hook` | [`otmux.config.set.hook`](otmux.md) · [`private.otmux.setHook`](otmux.md) |
| `imageFile` | `disk.imageFile` | [`disk.image`](disk.md) · [`disk.restore.linux`](disk.md) |
| `intent` | `hiveMind.intent` | [`private.hiveMind.agent.queue.enqueue`](hivemind.md) |
|  | `osemvec.intent` | [`osemvec.register`](osemvec.md) |
| `invariant` | `hiveMind.invariant` | [`hiveMind.protected.reconcile.diff`](hivemind.md) · [`private.hiveMind.reconcile.diff`](hivemind.md) |
| `keepScreenshots` | `otest.keepScreenshots` | [`otest.here`](otest.md) · [`otest.run`](otest.md) |
| `key1` | `otmux.key1` | [`otmux.send.tui`](otmux.md) · [`private.otmux.sendKeys`](otmux.md) |
| `l` | `hiveMind.l` | [`private.hiveMind.audit.render.human`](hivemind.md) · [`private.hiveMind.audit.render.json`](hivemind.md) |
| `layout` | `otmux.layout` | [`otmux.layout`](otmux.md) · [`otmux.layout.set`](otmux.md) |
| `lineNumber` | `line.lineNumber` | [`line.remove`](line.md) · [`line.select`](line.md) |
| `load` | `certificates.load` | [`certificates.once.scenario.list`](certificates.md) · [`certificates.once.scenarios`](certificates.md) |
| `m` | `hiveMind.m` | [`private.hiveMind.audit.render.human`](hivemind.md) · [`private.hiveMind.audit.render.json`](hivemind.md) |
| `mainDir` | `ogit.mainDir` | [`private.ogit.clone.gate`](ogit.md) |
|  | `oo.mainDir` | [`private.oo.source.consume.gate`](oo.md) |
| `mathExpression` | `disk.mathExpression` | [`disk.calc`](disk.md) |
|  | `osx.mathExpression` | [`osx.spotlight.by.size`](osx.md) |
| `newFileName` | `webitem.newFileName` | [`webitem.create`](webitem.md) · [`webitem.webloc2url`](webitem.md) |
| `newStateName` | `state.newStateName` | [`state.add`](state.md) · [`state.rename`](state.md) |
| `notests` | `os.notests` | [`platform.test`](os.md) · [`private.platform.test.ci`](os.md) |
| `ooshDir` | `promote.ooshDir` | [`private.promote.rewrite.self.branch`](promote.md) |
|  | `user.ooshDir` | [`private.user.bashrc.install`](user.md) |
| `paths` | `ogit.paths` | [`ogit.diff.check`](ogit.md) · [`ogit.index.add`](ogit.md) |
| `pct` | `hiveMind.pct` | [`hiveMind.context.record`](hivemind.md) · [`private.hiveMind.context.set`](hivemind.md) |
| `pkg` | `opy.pkg` | [`private.opy.pkgInstall`](opy.md) |
|  | `ossh.pkg` | [`ossh.cmd`](ossh.md) |
| `prefix` | `config.prefix` | [`private.config.env.lines.drop`](config.md) |
|  | `this.prefix` | [`private.log.install.append`](this.md) |
| `psSnap` | `hiveMind.psSnap` | [`private.hiveMind.shell.descendants`](hivemind.md) · [`private.hiveMind.sweep.bgshells`](hivemind.md) |
| `rcfile` | `opy.rcfile` | [`opy.shell.install`](opy.md) · [`private.opy.installBashrc`](opy.md) |
| `remoteConfigName` | `ossh.remoteConfigName` | [`ossh.config.pull`](ossh.md) · [`private.ossh.config.pull`](ossh.md) |
| `remoteKeyName` | `ossh.remoteKeyName` | [`ossh.key.pull`](ossh.md) · [`private.ossh.key.pull`](ossh.md) |
| `roles` | `agentRoom.roles` | [`agentRoom.start.all`](agentRoom.md) |
|  | `hiveMind.roles` | [`hiveMind.team.setup`](hivemind.md) |
| `root_pid` | `hiveMind.root_pid` | [`private.hiveMind.shell.descendants`](hivemind.md) · [`private.hiveMind.sweep.bgshells`](hivemind.md) |
| `shell` | `odocker.shell` | [`odocker.enter`](odocker.md) · [`odocker.exec`](odocker.md) |
| `snapshot_file` | `hiveMind.snapshot_file` | [`hiveMind.teams.migrate`](hivemind.md) · [`hiveMind.teams.restore`](hivemind.md) |
| `socket` | `odocker.socket` | [`private.odocker.socket.access.ensure`](odocker.md) · [`private.odocker.socket.group.ensure`](odocker.md) |
| `sourcePane` | `otmux.sourcePane` | [`otmux.pane.swap`](otmux.md) · [`private.otmux.swapPane`](otmux.md) |
| `startLine` | `oo.startLine` | [`private.oo.method.end.get`](oo.md) |
|  | `replace.startLine` | [`replace.block`](replace.md) |
| `startPoint` | `ogit.startPoint` | [`ogit.branch.reset`](ogit.md) · [`ogit.worktree.add`](ogit.md) |
| `stashDir` | `ogit.stashDir` | [`private.ogit.folder.ignored.restore`](ogit.md) · [`private.ogit.folder.ignored.save`](ogit.md) |
| `STATE` | `hiveMind.STATE` | [`hiveMind.agent.state.set`](hivemind.md) · [`hiveMind.team.state.set`](hivemind.md) |
| `string` | `config.string` | [`config.string.quote`](config.md) · [`private.config.string.upper`](config.md) |
| `tag` | `ogit.tag` | [`ogit.tag.check`](ogit.md) · [`ogit.tag.create`](ogit.md) |
| `tags` | `ogit.tags` | [`ogit.remote.fetch`](ogit.md) · [`ogit.remote.push`](ogit.md) |
| `task` | `claudeFlow.task` | [`claudeFlow.tmux.spawn`](claudeFlow.md) |
|  | `osemvec.task` | [`osemvec.context`](osemvec.md) |
| `taskFile` | `hiveMind.taskFile` | [`hiveMind.task.delegate`](hivemind.md) · [`private.hiveMind.task.transfer`](hivemind.md) |
| `terminal` | `os.terminal` | [`platform.test`](os.md) · [`private.platform.test.ci`](os.md) |
| `testName` | `otest.testName` | [`otest.run`](otest.md) · [`otest.updateGolden`](otest.md) |
| `threshold` | `claudeCode.threshold` | [`claudeCode.context.alert`](claudeCode.md) |
|  | `scrumMaster.threshold` | [`scrumMaster.velocity.alert`](scrumMaster.md) |
| `timeout` | `hiveMind.timeout` | [`private.hiveMind.wait.for.claude`](hivemind.md) |
|  | `otmux.timeout` | [`otmux.send.verified`](otmux.md) |
| `tool` | `claudeFlow.tool` | [`claudeFlow.mcp.exec`](claudeFlow.md) · [`claudeFlow.mcp.toggle`](claudeFlow.md) |
| `tools` | `claudeCode.tools` | [`claudeCode.tools.allowed`](claudeCode.md) · [`claudeCode.tools.disallowed`](claudeCode.md) |
| `toPath` | `backup.toPath` | [`backup.target`](backup.md) · [`backup.to`](backup.md) |
| `total` | `hiveMind.total` | [`private.hiveMind.audit.render.human`](hivemind.md) · [`private.hiveMind.audit.render.json`](hivemind.md) |
| `tsIso` | `hiveMind.tsIso` | [`private.hiveMind.context.age`](hivemind.md) · [`private.hiveMind.context.set`](hivemind.md) |
| `updateGolden` | `otest.updateGolden` | [`otest.here`](otest.md) · [`otest.run`](otest.md) |
| `usedK` | `hiveMind.usedK` | [`hiveMind.context.record`](hivemind.md) · [`private.hiveMind.context.set`](hivemind.md) |
| `uuid` | `hiveMind.uuid` | [`private.hiveMind.snapshot.jsonl.path`](hivemind.md) · [`private.hiveMind.snapshot.set`](hivemind.md) |
| `variableName` | `config.variableName` | [`private.config.variable.export.line`](config.md) |
|  | `this.variableName` | [`private.this.env.export.line.get`](this.md) |
| `varName` | `c2.varName` | [`c2.env`](c2.md) · [`c2.variables`](c2.md) |
| `what` | `promote.what` | [`private.promote.notests.gate`](promote.md) |
|  | `setup.what` | [`private.setup.linux.skip`](setup.md) |
| `windowMin` | `scrumMaster.windowMin` | [`scrumMaster.velocity.alert`](scrumMaster.md) · [`scrumMaster.velocity.rate`](scrumMaster.md) |
| `aliasName` | `c2.aliasName` | [`c2.alias`](c2.md) |
| `alwaysReturnId` | `state.alwaysReturnId` | [`state.find`](state.md) |
| `arch` | `odocker.arch` | [`private.odocker.docker.repo.get`](odocker.md) |
| `archive` | `user.archive` | [`user.ssh.restore`](user.md) |
| `argumentList` | `line.argumentList` | [`line.format`](line.md) |
| `aspect` | `oo.aspect` | [`oo.test.platform.new`](oo.md) |
| `assignedValue` | `line.assignedValue` | [`line.param.declare`](line.md) |
| `baseBranch` | `oo.baseBranch` | [`oo.branches.check`](oo.md) |
| `basehome` | `ossh.basehome` | [`private.ossh.shared.ssh.legacy.remove`](ossh.md) |
| `block` | `ossh.block` | [`private.ossh.github.block.is.oosh`](ossh.md) |
| `branchName` | `oo.branchName` | [`private.oo.shared.tree.from.local`](oo.md) |
| `byBranch` | `oo.byBranch` | [`private.oo.layout.folder.check`](oo.md) |
| `captureText` | `claudeCode.captureText` | [`claudeCode.session.probe.fromCapture`](claudeCode.md) |
| `channel` | `otmux.channel` | [`otmux.wait`](otmux.md) |
| `clear` | `test.suite.clear` | [`private.test.suite.run.filtered`](test.suite.md) |
| `cmd1` | `otmux.cmd1` | [`otmux.if`](otmux.md) |
| `cmd2` | `otmux.cmd2` | [`otmux.if`](otmux.md) |
| `condition` | `otmux.condition` | [`otmux.if`](otmux.md) |
| `configFile` | `ossh.configFile` | [`ossh.config.shared.github.create`](ossh.md) |
| `consumeSource` | `oo.consumeSource` | [`private.oo.shared.tree.from.local`](oo.md) |
| `containerOrImage` | `odocker.containerOrImage` | [`odocker.file.find`](odocker.md) |
| `copyCmd` | `otmux.copyCmd` | [`private.otmux.setup.clipboard.apply`](otmux.md) |
| `ctxPct` | `hiveMind.ctxPct` | [`private.hiveMind.snapshot.set`](hivemind.md) |
| `defaultValue` | `line.defaultValue` | [`line.param.declare`](line.md) |
| `deployKeySrc` | `ossh.deployKeySrc` | [`ossh.config.shared.create`](ossh.md) |
| `depthLevel` | `disk.depthLevel` | [`disk.space.used`](disk.md) |
| `dirName` | `oo.dirName` | [`private.oo.mode.resolve.branch`](oo.md) |
| `dryRun` | `tronMonitor.dryRun` | [`tronMonitor.sync`](tronMonitor.md) |
| `endLine` | `replace.endLine` | [`replace.block`](replace.md) |
| `errFile` | `ossh.errFile` | [`private.ossh.connection.error.get`](ossh.md) |
| `errorCount` | `scrumMaster.errorCount` | [`scrumMaster.pdca.run`](scrumMaster.md) |
| `errorText` | `osemvec.errorText` | [`osemvec.error`](osemvec.md) |
| `event` | `hiveMind.event` | [`private.hiveMind.events.history.append`](hivemind.md) |
| `excludes` | `this.excludes` | [`private.this.marker.sweep`](this.md) |
| `existingName` | `this.existingName` | [`this.function.partial`](this.md) |
| `expects` | `test.suite.expects` | [`private.test.suite.verdict`](test.suite.md) |
| `extraFlags` | `backup.extraFlags` | [`private.backup.rsync`](backup.md) |
| `extraPorts` | `ossh.extraPorts` | [`ossh.harden.firewall`](ossh.md) |
| `family` | `config.family` | [`private.config.session.chain.ready`](config.md) |
| `featureBranchPrefix` | `oo.featureBranchPrefix` | [`oo.branches.check`](oo.md) |
| `fileA` | `this.fileA` | [`private.this.file.same`](this.md) |
| `fileB` | `this.fileB` | [`private.this.file.same`](this.md) |
| `filter` | `otmux.filter` | [`otmux.client.cleanup`](otmux.md) |
| `findArguments` | `disk.findArguments` | [`disk.find`](disk.md) |
| `firstArg` | `this.firstArg` | [`this.function.partial`](this.md) |
| `force` | `otmux.force` | [`otmux.layout.restore`](otmux.md) |
| `fromPane` | `hiveMind.fromPane` | [`hiveMind.protected.pane.moved`](hivemind.md) |
| `groupFile` | `this.groupFile` | [`private.this.group.members.get`](this.md) |
| `groupname` | `c2.groupname` | [`c2.groups`](c2.md) |
| `handler` | `osemvec.handler` | [`private.osemvec.pss`](osemvec.md) |
| `hash` | `claudeCode.hash` | [`private.claudeCode.decode.projectHash`](claudeCode.md) |
| `heading` | `line.heading` | [`line.table`](line.md) |
| `hostAlias` | `ossh.hostAlias` | [`private.ossh.folder.fix.scan.git.remotes`](ossh.md) |
| `identitiesOnly` | `ossh.identitiesOnly` | [`ossh.config.create`](ossh.md) |
| `idOrProxyJump` | `ossh.idOrProxyJump` | [`ossh.config.create`](ossh.md) |
| `imageTag` | `os.imageTag` | [`private.platform.image.exists`](os.md) |
| `installerKeypairSrc` | `osshLayout.installerKeypairSrc` | [`osshLayout.build`](osshLayout.md) |
| `iteratorFunction` | `state.iteratorFunction` | [`private.loop.states`](state.md) |
| `job` | `c2.job` | [`c2.jobs`](c2.md) |
| `json_response` | `scrumMaster.json_response` | [`private.scrumMaster.subscription.parse`](scrumMaster.md) |
| `jsonl` | `claudeCode.jsonl` | [`claudeCode.context.velocity.byJsonl`](claudeCode.md) |
| `jsonResponse` | `scrumMaster.jsonResponse` | [`private.measure.subscription.api.parse`](scrumMaster.md) |
| `jumpHost` | `ossh.jumpHost` | [`private.ossh.identity.stage.outer.proxyJump`](ossh.md) |
| `keep` | `hiveMind.keep` | [`hiveMind.snapshots.prune`](hivemind.md) |
| `key2` | `otmux.key2` | [`private.otmux.sendKeys`](otmux.md) |
| `keyFile` | `ossh.keyFile` | [`private.ossh.install.key.authorize`](ossh.md) |
| `keypairSourceDir` | `osshLayout.keypairSourceDir` | [`osshLayout.role.installer`](osshLayout.md) |
| `kind` | `osx.kind` | [`osx.spotlight.bykind`](osx.md) |
| `leaf` | `this.leaf` | [`private.this.anchor.validate.one`](this.md) |
| `level` | `test.suite.level` | [`private.test.suite.run.filtered`](test.suite.md) |
| `levelno` | `log.levelno` | [`log.level`](log.md) |
| `limit` | `ogit.limit` | [`ogit.commit.log.show`](ogit.md) |
| `linkPath` | `this.linkPath` | [`private.this.symlink.with.backup`](this.md) |
| `localEntry` | `odocker.localEntry` | [`private.odocker.workspaces.entry.same`](odocker.md) |
| `localFile` | `ossh.localFile` | [`private.ossh.remote.public.key.put`](ossh.md) |
| `markerSlug` | `this.markerSlug` | [`private.this.marker.sweep`](this.md) |
| `messageBody` | `this.messageBody` | [`private.log.install.append`](this.md) |
| `metaFailures` | `test.suite.metaFailures` | [`private.test.suite.verdict`](test.suite.md) |
| `monitorPane` | `tronMonitor.monitorPane` | [`tronMonitor.setup`](tronMonitor.md) |
| `morePrefixes` | `config.morePrefixes` | [`private.config.env.lines.drop`](config.md) |
| `N` | `hiveMind.N` | [`hiveMind.agent.option`](hivemind.md) |
| `nameFilter` | `state.nameFilter` | [`state.machine.list`](state.md) |
| `newRole` | `hiveMind.newRole` | [`private.hiveMind.pane.pushRoleEnv`](hivemind.md) |
| `newText` | `replace.newText` | [`replace.by`](replace.md) |
| `next` | `replace.next` | [`private.replace.copy.make`](replace.md) |
| `noResults` | `test.suite.noResults` | [`private.test.suite.verdict`](test.suite.md) |
| `oldName` | `hiveMind.oldName` | [`hiveMind.protected.session.renamed`](hivemind.md) |
| `onceShBase` | `oo.onceShBase` | [`private.oo.user.shared.symlinks.ensure`](oo.md) |
| `onlyLive` | `tronMonitor.onlyLive` | [`private.tronMonitor.registry.teams`](tronMonitor.md) |
| `ooshBranch` | `oo.ooshBranch` | [`private.oo.user.shared.symlinks.ensure`](oo.md) |
| `ooshSplit` | `config.ooshSplit` | [`private.config.save`](config.md) |
| `osRelease` | `odocker.osRelease` | [`private.odocker.docker.repo.get`](odocker.md) |
| `overlayState` | `hiveMind.overlayState` | [`private.hiveMind.agent.overlay.key`](hivemind.md) |
| `packageManagerBinary` | `config.packageManagerBinary` | [`private.config.pm.command.get`](config.md) |
| `packageName` | `oo.packageName` | [`oo.cmd`](oo.md) |
| `pane_pid` | `hiveMind.pane_pid` | [`private.hiveMind.shell.classify`](hivemind.md) |
| `paneA` | `hiveMind.paneA` | [`hiveMind.protected.panes.swapped`](hivemind.md) |
| `paneAlive` | `hiveMind.paneAlive` | [`private.hiveMind.shell.classify`](hivemind.md) |
| `paneB` | `hiveMind.paneB` | [`hiveMind.protected.panes.swapped`](hivemind.md) |
| `paneOrJsonl` | `claudeCode.paneOrJsonl` | [`claudeCode.context.velocity`](claudeCode.md) |
| `parameters` | `oo.parameters` | [`private.oo.method.stubs.get`](oo.md) |
| `passed` | `test.suite.passed` | [`private.test.suite.verdict`](test.suite.md) |
| `passwd` | `odocker.passwd` | [`private.odocker.passwd.users.get`](odocker.md) |
| `pasteCmd` | `otmux.pasteCmd` | [`private.otmux.setup.clipboard.apply`](otmux.md) |
| `pathspecs` | `ogit.pathspecs` | [`ogit.repo.grep`](ogit.md) |
| `pmCmd` | `oo.pmCmd` | [`private.oo.pm.install.prefix.get`](oo.md) |
| `policy` | `osemvec.policy` | [`osemvec.new`](osemvec.md) |
| `portMap` | `ossh.portMap` | [`ossh.tunnel`](ossh.md) |
| `position` | `path.position` | [`private.pathadd`](path.md) |
| `preForkFiles` | `hiveMind.preForkFiles` | [`private.hiveMind.push.captureForkedUUID`](hivemind.md) |
| `privKey` | `ossh.privKey` | [`private.ossh.identity.stage.outer.fromRunner`](ossh.md) |
| `probe` | `hiveMind.probe` | [`private.hiveMind.liveUuid`](hivemind.md) |
| `probeFn` | `this.probeFn` | [`private.this.script.load`](this.md) |
| `procArgs` | `hiveMind.procArgs` | [`private.hiveMind.liveUuid`](hivemind.md) |
| `profile` | `otest.profile` | [`otest.browser.open`](otest.md) |
| `profileDir` | `oo.profileDir` | [`private.oo.dropin.remove`](oo.md) |
| `property` | `user.property` | [`user.get`](user.md) |
| `proxyJump` | `ossh.proxyJump` | [`ossh.config.create`](ossh.md) |
| `prune` | `ogit.prune` | [`ogit.remote.fetch`](ogit.md) |
| `psMeta` | `hiveMind.psMeta` | [`private.hiveMind.shell.classify`](hivemind.md) |
| `pubKey` | `ossh.pubKey` | [`private.ossh.identity.stage.outer.fromRunner`](ossh.md) |
| `query` | `claudeFlow.query` | [`claudeFlow.memory.search`](claudeFlow.md) |
| `range` | `ogit.range` | [`ogit.commit.log.show`](ogit.md) |
| `relPath` | `test.suite.relPath` | [`private.test.suite.ssh.secret.is`](test.suite.md) |
| `remoteSshConfigName` | `ossh.remoteSshConfigName` | [`ossh.install.continue.local`](ossh.md) |
| `rest` | `state.rest` | [`private.itterator.find`](state.md) |
| `roleKey` | `hiveMind.roleKey` | [`private.hiveMind.context.set`](hivemind.md) |
| `row` | `hiveMind.row` | [`private.hiveMind.snapshot.row.valid`](hivemind.md) |
| `savedDevice` | `log.savedDevice` | [`private.log.session.write`](log.md) |
| `sbinDir` | `user.sbinDir` | [`private.user.delete.command.get`](user.md) |
| `scriptClass` | `oo.scriptClass` | [`oo.install`](oo.md) |
| `serviceCmd` | `share.serviceCmd` | [`share.samba.service`](share.md) |
| `session_filter` | `hiveMind.session_filter` | [`hiveMind.protected.agents.discover`](hivemind.md) |
| `sharedConfigPath` | `oo.sharedConfigPath` | [`private.oo.user.shared.symlinks.ensure`](oo.md) |
| `sharedDir` | `ossh.sharedDir` | [`ossh.config.shared.create`](ossh.md) |
| `sharedWrites` | `test.suite.sharedWrites` | [`private.test.suite.verdict`](test.suite.md) |
| `side` | `ogit.side` | [`ogit.conflict.resolve`](ogit.md) |
| `signature` | `osemvec.signature` | [`osemvec.register`](osemvec.md) |
| `slug` | `hiveMind.slug` | [`hiveMind.plan.create`](hivemind.md) |
| `snapfile` | `hiveMind.snapfile` | [`private.hiveMind.snapshot.version.check`](hivemind.md) |
| `snapshotFile` | `hiveMind.snapshotFile` | [`hiveMind.team.migrate`](hivemind.md) |
| `sourceEntry` | `odocker.sourceEntry` | [`private.odocker.workspaces.entry.same`](odocker.md) |
| `sourceSshDir` | `ossh.sourceSshDir` | [`ossh.id.create.fromKey`](ossh.md) |
| `sourceUUID` | `hiveMind.sourceUUID` | [`private.hiveMind.push.agent`](hivemind.md) |
| `spec` | `otmux.spec` | [`otmux.window.layout.set`](otmux.md) |
| `srcDir` | `ogit.srcDir` | [`private.ogit.branch.import`](ogit.md) |
| `sshConfigNameUsedForLocal` | `ossh.sshConfigNameUsedForLocal` | [`ossh.install.continue.local`](ossh.md) |
| `sshFlags` | `ossh.sshFlags` | [`private.ossh.ssh`](ossh.md) |
| `sshId` | `user.sshId` | [`user.in`](user.md) |
| `sshWrites` | `test.suite.sshWrites` | [`private.test.suite.verdict`](test.suite.md) |
| `startCommit` | `oo.startCommit` | [`oo.branches.check`](oo.md) |
| `stashed` | `promote.stashed` | [`private.promote.merge.finish`](promote.md) |
| `str` | `hiveMind.str` | [`private.hiveMind.audit.json.escape`](hivemind.md) |
| `strategy` | `backup.strategy` | [`backup.strategy`](backup.md) |
| `systemPath` | `oo.systemPath` | [`private.oo.dropin.remove`](oo.md) |
| `targetBase` | `backup.targetBase` | [`backup.config.create`](backup.md) |
| `targetHashDir` | `hiveMind.targetHashDir` | [`private.hiveMind.push.captureForkedUUID`](hivemind.md) |
| `TestName` | `otest.TestName` | [`otest.newTest`](otest.md) |
| `token` | `otmux.token` | [`private.otmux.is.key`](otmux.md) |
| `toPane` | `hiveMind.toPane` | [`hiveMind.protected.pane.moved`](hivemind.md) |
| `toUsername` | `user.toUsername` | [`user.group.add`](user.md) |
| `ts` | `this.ts` | [`private.this.symlink.with.backup`](this.md) |
| `ttl` | `hiveMind.ttl` | [`private.hiveMind.shell.classify`](hivemind.md) |
| `turns` | `claudeCode.turns` | [`claudeCode.turns.max`](claudeCode.md) |
| `uid` | `user.uid` | [`user.create`](user.md) |
| `unit` | `odocker.unit` | [`private.odocker.workspaces.merge.answer.get`](odocker.md) |
| `userHome` | `oo.userHome` | [`private.oo.user.shared.symlinks.ensure`](oo.md) |
| `userName` | `user.userName` | [`user.login`](user.md) |
| `users` | `ossh.users` | [`ossh.harden.sshd.allowusers`](ossh.md) |
| `value1` | `line.value1` | [`line.each`](line.md) |
| `valueList` | `line.valueList` | [`private.line.each`](line.md) |
| `valueN` | `line.valueN` | [`line.each`](line.md) |
| `verbose` | `os.verbose` | [`os.info`](os.md) |
| `waiver` | `test.suite.waiver` | [`private.test.suite.shared.report`](test.suite.md) |
| `worktree_base` | `oo.worktree_base` | [`oo.mode.setup`](oo.md) |
