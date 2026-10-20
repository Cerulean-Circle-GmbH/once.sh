# OOSH object · verb index

Every **unique object** across all oosh scripts and the verbs applied to it (2026-10-20).
Objects are **atoms, not chains** — `odocker`, `container`, `image`, never `odocker.container`.
A method appears under every object in its chain, so `odocker.container.list` is listed under both
`odocker` and `container`. Which `container` it is (docker vs portainer) is readable from the method names.
An **empty verb** = the method name carries no action (see [verb-audit.md](verb-audit.md)).
Objects come from two places: the **method name chain**, and **noun parameters** (a `<param>` is a thing a verb acts on, so it is an object too — 370 of them). The links are the usage sites either way.
Each method links to its script's matrix. Indexes: [methods-index.md](methods-index.md) · [parameter.md](parameter.md).

**911 objects** · **3359 object/verb pairs** · **6609 methods**

| object | verb | methods |
|---|---|---|
| `1` |  | [`mycmd.1`](mycmd.md) |
| `2` |  | [`mycmd.2`](mycmd.md) |
| `256color` |  | [`otmux.256color`](otmux.md) |
| `2c` |  | [`2c.alias`](2c.md) · [`2c.buildinCommands`](2c.md) · [`2c.env`](2c.md) · [`2c.folders`](2c.md) · [`2c.groups`](2c.md) · [`2c.jobs`](2c.md) · [`2c.status`](2c.md) · [`2c.user`](2c.md) · [`2c.variables`](2c.md) |
| `2c` | `format` | [`2c.format.functions`](2c.md) |
| `2c` | `get` | [`2c.get.formated.function.description`](2c.md) · [`2c.get.function.declaration`](2c.md) · [`2c.get.function.parameter`](2c.md) · [`2c.get.function.with.documentation`](2c.md) · [`2c.get.functions`](2c.md) |
| `2c` | `init` | [`2c.init`](2c.md) |
| `2c` | `install` | [`2c.install.linux`](2c.md) |
| `2c` | `parse` | [`2c.debug.parse.param`](2c.md) |
| `2c` | `test` | [`2c.test.absolutePathName`](2c.md) |
| `3` |  | [`mycmd.3`](mycmd.md) |
| `4` |  | [`mycmd.4`](mycmd.md) |
| `ENV_PREFIX` | `save` | [`config.save`](config.md) · [`private.config.save`](config.md) |
| `ENV_PREFIX` | `update` | [`config.update`](config.md) |
| `N` |  | [`hiveMind.agent.option`](hivemind.md) |
| `STATE` | `set` | [`hiveMind.agent.state.set`](hivemind.md) · [`hiveMind.team.state.set`](hivemind.md) |
| `TestName` | `newTest` | [`otest.newTest`](otest.md) |
| `a` |  | [`otmux.a`](otmux.md) |
| `a` | `get` | [`ogit.merge.base.get`](ogit.md) |
| `a` | `show` | [`ogit.diff.show`](ogit.md) |
| `aFunction` | `call` | [`this.call`](this.md) |
| `aFunction` | `load` | [`this.load`](this.md) |
| `aShellScript` | `call` | [`this.call`](this.md) |
| `aShellScript` | `load` | [`this.load`](this.md) |
| `absolute` | `get` | [`private.config.path.line.absolute.get`](config.md) |
| `absolutePath` |  | [`this.absolutePath`](this.md) |
| `absolutePathName` |  | [`this.absolutePathName`](this.md) |
| `academyScript` |  | [`academyScript.course`](academyScript.md) |
| `academyScript` | `check` | [`private.check.course.intro`](academyScript.md) · [`private.check.finished`](academyScript.md) |
| `access` | `ensure` | [`private.odocker.socket.access.ensure`](odocker.md) |
| `action` |  | [`hiveMind.improvement`](hivemind.md) |
| `action` | `improve` | [`hiveMind.plan.improve`](hivemind.md) |
| `action` | `setup` | [`private.check.setup`](state.md) |
| `active` |  | [`hiveMind.team.active`](hivemind.md) · [`private.hiveMind.active.team`](hivemind.md) |
| `activity` |  | [`private.hiveMind.pane.activity`](hivemind.md) |
| `admin` |  | [`check.admin`](check.md) |
| `age` |  | [`private.hiveMind.context.age`](hivemind.md) · [`scrumMaster.subscription.cache.age`](scrumMaster.md) |
| `agent` |  | [`agentRoom.agent.status`](agentRoom.md) · [`claudeFlow.agent`](claudeFlow.md) · [`claudeFlow.agent.health`](claudeFlow.md) · [`claudeFlow.agent.logs`](claudeFlow.md) · [`claudeFlow.agent.metrics`](claudeFlow.md) · [`claudeFlow.agent.pool`](claudeFlow.md) · [`claudeFlow.agent.status`](claudeFlow.md) · [`hiveMind.agent.context.status`](hivemind.md) · [`hiveMind.agent.handoff`](hivemind.md) · [`hiveMind.agent.option`](hivemind.md) · [`hiveMind.agent.snapshot`](hivemind.md) · [`private.hiveMind.agent.overlay.key`](hivemind.md) · [`private.hiveMind.agent.queue.depth`](hivemind.md) · [`private.hiveMind.agent.queue.path`](hivemind.md) · [`private.hiveMind.ctxrefresh.due`](hivemind.md) · [`private.hiveMind.ctxrefresh.statefile`](hivemind.md) · [`private.hiveMind.handler.agent.forked.forks`](hivemind.md) · [`private.hiveMind.handler.agent.forked.registry`](hivemind.md) · [`private.hiveMind.handler.agent.forked.sessions`](hivemind.md) · [`private.hiveMind.handler.agent.killed.queue`](hivemind.md) · [`private.hiveMind.handler.agent.killed.registry`](hivemind.md) · [`private.hiveMind.handler.agent.killed.sessions`](hivemind.md) · [`private.hiveMind.handler.agent.renamed.registry`](hivemind.md) · [`private.hiveMind.handler.agent.renamed.role_env`](hivemind.md) · [`private.hiveMind.handler.agent.renamed.title`](hivemind.md) · [`private.hiveMind.handler.agent.spawned.registry`](hivemind.md) · [`private.hiveMind.handler.agent.spawned.sessions`](hivemind.md) · [`private.hiveMind.pane.for.agent`](hivemind.md) |
| `agent` | `approve` | [`hiveMind.agent.approve`](hivemind.md) |
| `agent` | `bootstrap` | [`hiveMind.agent.bootstrap`](hivemind.md) |
| `agent` | `clear` | [`hiveMind.agent.queue.clear`](hivemind.md) · [`hiveMind.agent.state.clear`](hivemind.md) |
| `agent` | `dismiss` | [`hiveMind.agent.dismiss`](hivemind.md) |
| `agent` | `dispatch` | [`private.hiveMind.agent.overlay.dispatch`](hivemind.md) |
| `agent` | `drain` | [`hiveMind.agent.queue.drain`](hivemind.md) |
| `agent` | `enqueue` | [`private.hiveMind.agent.queue.enqueue`](hivemind.md) |
| `agent` | `eval` | [`private.hiveMind.ctxrefresh.eval`](hivemind.md) |
| `agent` | `fork` | [`hiveMind.agent.fork.best`](hivemind.md) |
| `agent` | `gather` | [`hiveMind.context.gather`](hivemind.md) · [`hiveMind.context.gather.quiet`](hivemind.md) |
| `agent` | `get` | [`hiveMind.agent.state.get`](hivemind.md) · [`hiveMind.context.get`](hivemind.md) |
| `agent` | `inform` | [`private.hiveMind.agent.inform`](hivemind.md) |
| `agent` | `kill` | [`claudeFlow.agent.kill`](claudeFlow.md) |
| `agent` | `list` | [`claudeFlow.agent.list`](claudeFlow.md) · [`hiveMind.agent.queue.list`](hivemind.md) |
| `agent` | `ls` | [`claudeFlow.agent.ls`](claudeFlow.md) |
| `agent` | `mark` | [`private.hiveMind.ctxrefresh.mark`](hivemind.md) |
| `agent` | `monitor` | [`hiveMind.agent.monitor`](hivemind.md) · [`hiveMind.agent.monitor.cycle`](hivemind.md) |
| `agent` | `probe` | [`hiveMind.agent.session.probe`](hivemind.md) |
| `agent` | `record` | [`hiveMind.context.record`](hivemind.md) |
| `agent` | `reject` | [`hiveMind.agent.reject`](hivemind.md) |
| `agent` | `rename` | [`hiveMind.agent.rename`](hivemind.md) |
| `agent` | `resolve` | [`private.hiveMind.agent.queue.resolve`](hivemind.md) |
| `agent` | `respawn` | [`hiveMind.agent.respawn`](hivemind.md) |
| `agent` | `restart` | [`hiveMind.agent.restart`](hivemind.md) · [`hiveMind.agent.restart.remote`](hivemind.md) |
| `agent` | `rewind` | [`hiveMind.agent.rewind`](hivemind.md) |
| `agent` | `route` | [`private.hiveMind.agent.route`](hivemind.md) |
| `agent` | `send` | [`hiveMind.agent.send`](hivemind.md) |
| `agent` | `set` | [`hiveMind.agent.state.set`](hivemind.md) |
| `agent` | `spawn` | [`claudeFlow.agent.spawn`](claudeFlow.md) · [`hiveMind.agent.spawn`](hivemind.md) |
| `agent` | `stop` | [`agentRoom.agent.stop`](agentRoom.md) · [`claudeFlow.agent.stop`](claudeFlow.md) |
| `agent` | `train` | [`hiveMind.agent.train`](hivemind.md) |
| `agent` | `unblock` | [`hiveMind.agent.unblock`](hivemind.md) · [`private.hiveMind.agent.unblock.pane`](hivemind.md) |
| `agent` | `verify` | [`hiveMind.agent.verify`](hivemind.md) |
| `agentId` |  | [`agentRoom.agent.status`](agentRoom.md) · [`agentRoom.chat`](agentRoom.md) · [`agentRoom.health`](agentRoom.md) · [`agentRoom.logs`](agentRoom.md) · [`claudeFlow.agent.status`](claudeFlow.md) · [`hiveMind.claude`](hivemind.md) · [`hiveMind.task`](hivemind.md) |
| `agentId` | `create` | [`hiveMind.pane.create`](hivemind.md) |
| `agentId` | `focus` | [`claudeFlow.tmux.focus`](claudeFlow.md) · [`hiveMind.focus`](hivemind.md) |
| `agentId` | `follow` | [`agentRoom.logs.follow`](agentRoom.md) |
| `agentId` | `join` | [`claudeFlow.hive.join`](claudeFlow.md) |
| `agentId` | `kill` | [`claudeFlow.agent.kill`](claudeFlow.md) · [`claudeFlow.tmux.kill`](claudeFlow.md) |
| `agentId` | `leave` | [`claudeFlow.hive.leave`](claudeFlow.md) |
| `agentId` | `spawn` | [`hiveMind.spawn`](hivemind.md) |
| `agentId` | `stop` | [`agentRoom.agent.stop`](agentRoom.md) · [`claudeFlow.agent.stop`](claudeFlow.md) |
| `agentName` |  | [`hiveMind.agent.handoff`](hivemind.md) · [`hiveMind.agent.snapshot`](hivemind.md) |
| `agentName` | `focus` | [`hiveMind.pane.focus`](hivemind.md) |
| `agentName` | `measure` | [`private.scrumMaster.measure.context`](scrumMaster.md) · [`private.scrumMaster.measure.pane`](scrumMaster.md) · [`private.scrumMaster.measure.speed`](scrumMaster.md) · [`scrumMaster.context.measure`](scrumMaster.md) · [`scrumMaster.pane.measure`](scrumMaster.md) · [`scrumMaster.speed.measure`](scrumMaster.md) |
| `agentName` | `monitor` | [`hiveMind.agent.monitor`](hivemind.md) · [`hiveMind.team.monitor`](hivemind.md) |
| `agentName` | `rename` | [`hiveMind.agent.rename`](hivemind.md) |
| `agentName` | `resolve` | [`private.scrumMaster.resolve.pane`](scrumMaster.md) |
| `agentName` | `respawn` | [`hiveMind.agent.respawn`](hivemind.md) |
| `agentName` | `save` | [`private.scrumMaster.metrics.save`](scrumMaster.md) |
| `agentName` | `spawn` | [`hiveMind.agent.spawn`](hivemind.md) |
| `agentName` | `train` | [`hiveMind.agent.train`](hivemind.md) |
| `agentName` | `unblock` | [`hiveMind.agent.unblock`](hivemind.md) |
| `agentRoom` |  | [`agentRoom.agent.status`](agentRoom.md) · [`agentRoom.backend.status`](agentRoom.md) · [`agentRoom.chat`](agentRoom.md) · [`agentRoom.health`](agentRoom.md) · [`agentRoom.logs`](agentRoom.md) |
| `agentRoom` | `check` | [`private.agentRoom.check.deps`](agentRoom.md) · [`private.agentRoom.check.node`](agentRoom.md) |
| `agentRoom` | `discover` | [`agentRoom.discover`](agentRoom.md) |
| `agentRoom` | `ensure` | [`private.agentRoom.ensure.dirs`](agentRoom.md) |
| `agentRoom` | `find` | [`private.agentRoom.find.free.port`](agentRoom.md) |
| `agentRoom` | `follow` | [`agentRoom.logs.follow`](agentRoom.md) |
| `agentRoom` | `get` | [`private.agentRoom.get.agent.pid`](agentRoom.md) · [`private.agentRoom.get.agent.port`](agentRoom.md) |
| `agentRoom` | `install` | [`agentRoom.install`](agentRoom.md) |
| `agentRoom` | `is` | [`private.agentRoom.is.running`](agentRoom.md) |
| `agentRoom` | `list` | [`agentRoom.list`](agentRoom.md) · [`agentRoom.list.ids`](agentRoom.md) · [`agentRoom.list.ports`](agentRoom.md) |
| `agentRoom` | `rebuild` | [`agentRoom.rebuild`](agentRoom.md) |
| `agentRoom` | `restart` | [`agentRoom.restart.all`](agentRoom.md) |
| `agentRoom` | `save` | [`private.agentRoom.save.agent.info`](agentRoom.md) |
| `agentRoom` | `setup` | [`agentRoom.setup`](agentRoom.md) |
| `agentRoom` | `start` | [`agentRoom.start.all`](agentRoom.md) |
| `agentRoom` | `stop` | [`agentRoom.agent.stop`](agentRoom.md) · [`agentRoom.backend.stop`](agentRoom.md) · [`agentRoom.stop.all`](agentRoom.md) |
| `agentRoom` | `update` | [`agentRoom.update`](agentRoom.md) |
| `agent_name` | `capture` | [`scrumMaster.pane.capture`](scrumMaster.md) |
| `agent_name` | `check` | [`scrumMaster.speed.check`](scrumMaster.md) |
| `agent_name` | `read` | [`scrumMaster.context.read`](scrumMaster.md) |
| `agents` |  | [`claudeFlow.tmux.agents`](claudeFlow.md) · [`hiveMind.protected.agents.offline`](hivemind.md) |
| `agents` | `check` | [`scrumMaster.subscription.check`](scrumMaster.md) |
| `agents` | `discover` | [`hiveMind.protected.agents.discover`](hivemind.md) |
| `agents` | `init` | [`hiveMind.init`](hivemind.md) |
| `agentsDir` |  | [`private.osemvec.agentsDir`](osemvec.md) |
| `aggressive` | `resize` | [`otmux.window.aggressive.resize`](otmux.md) |
| `alert` |  | [`claudeCode.context.alert`](claudeCode.md) · [`scrumMaster.velocity.alert`](scrumMaster.md) |
| `alias` |  | [`2c.alias`](2c.md) · [`c2.alias`](c2.md) · [`mycmd.tab.alias`](mycmd.md) |
| `alias` | `collect` | [`osx.alias.collect.all.here`](osx.md) |
| `alias` | `create` | [`osx.alias.create`](osx.md) |
| `alias` | `find` | [`osx.alias.find.all`](osx.md) |
| `alias` | `link` | [`osx.alias.to.link`](osx.md) |
| `alias` | `show` | [`osx.alias.show.target`](osx.md) |
| `aliasName` |  | [`c2.alias`](c2.md) |
| `alignment` |  | [`promote.branch.alignment`](promote.md) |
| `all` |  | [`claudeCode.context.all`](claudeCode.md) · [`claudeFlow.task.all`](claudeFlow.md) · [`setup.all`](setup.md) · [`test.suite.all`](test.suite.md) |
| `all` | `step` | [`private.setup.all.step`](setup.md) |
| `allStates` | `check` | [`state.check`](state.md) |
| `allStates` | `find` | [`state.find`](state.md) |
| `allStates` | `rename` | [`state.rename`](state.md) |
| `allowed` |  | [`claudeCode.tools.allowed`](claudeCode.md) |
| `alwaysReturnId` | `find` | [`state.find`](state.md) |
| `amount` |  | [`otmux.rp`](otmux.md) |
| `amount` | `resize` | [`otmux.pane.resize`](otmux.md) |
| `amount` | `resizePane` | [`private.otmux.resizePane`](otmux.md) |
| `anchor` | `validate` | [`private.this.anchor.validate.one`](this.md) · [`this.anchor.validate`](this.md) |
| `and` |  | [`check.and`](check.md) |
| `and` | `install` | [`ossh.create.and.install`](ossh.md) |
| `and` | `remove` | [`backup.sync.and.remove`](backup.md) |
| `answer` | `get` | [`private.odocker.workspaces.merge.answer.get`](odocker.md) |
| `any` |  | [`private.setup.samba.users.any`](setup.md) |
| `api` |  | [`private.scrumMaster.subscription.api.legacy`](scrumMaster.md) |
| `api` | `call` | [`private.scrumMaster.subscription.api.call`](scrumMaster.md) |
| `api` | `parse` | [`private.measure.subscription.api.parse`](scrumMaster.md) |
| `apostropheDesc` |  | [`parameterTestScript.apostropheDesc`](parameterTestScript.md) |
| `append` | `get` | [`private.ossh.authorized.key.append.get`](ossh.md) |
| `arch` | `get` | [`private.odocker.docker.repo.get`](odocker.md) |
| `archive` | `restore` | [`user.ssh.restore`](user.md) |
| `arg` | `append` | [`private.hiveMind.events.history.append`](hivemind.md) |
| `arg` | `emit` | [`hiveMind.protected.events.emit`](hivemind.md) · [`private.hiveMind.events.emit`](hivemind.md) |
| `args` |  | [`line.args`](line.md) · [`ogit.raw`](ogit.md) · [`private.disk.args.error.disk`](disk.md) · [`private.opy.pyenv`](opy.md) · [`private.osemvec.pss`](osemvec.md) |
| `args` | `dispatch` | [`private.ossh.dispatch`](ossh.md) |
| `args` | `get` | [`c2.function.parameter.get`](c2.md) · [`c2.get.function.parameter`](c2.md) · [`ossh.get`](ossh.md) · [`private.c2.get.function.parameter`](c2.md) |
| `args` | `run` | [`private.ogit.git.run`](ogit.md) |
| `args` | `set` | [`ossh.set`](ossh.md) |
| `argument` | `apply` | [`private.promote.argument.apply`](promote.md) |
| `argumentList` | `format` | [`line.format`](line.md) |
| `as` |  | [`private.as.user`](user.md) |
| `as` | `get` | [`private.this.as.user.preamble.get`](this.md) |
| `asEmail` |  | [`private.ogit.identity`](ogit.md) |
| `asEmail` | `adopt` | [`ogit.branch.adopt`](ogit.md) |
| `asEmail` | `continue` | [`ogit.commit.pick.continue`](ogit.md) |
| `asEmail` | `create` | [`ogit.commit.create`](ogit.md) |
| `asEmail` | `merge` | [`ogit.branch.merge`](ogit.md) |
| `asEmail` | `pick` | [`ogit.commit.pick`](ogit.md) |
| `asEmail` | `revert` | [`ogit.commit.revert`](ogit.md) |
| `asName` |  | [`private.ogit.identity`](ogit.md) |
| `asName` | `adopt` | [`ogit.branch.adopt`](ogit.md) |
| `asName` | `continue` | [`ogit.commit.pick.continue`](ogit.md) |
| `asName` | `create` | [`ogit.commit.create`](ogit.md) |
| `asName` | `merge` | [`ogit.branch.merge`](ogit.md) |
| `asName` | `pick` | [`ogit.commit.pick`](ogit.md) |
| `asName` | `revert` | [`ogit.commit.revert`](ogit.md) |
| `aspect` | `new` | [`oo.test.platform.new`](oo.md) |
| `assignedValue` | `declare` | [`line.param.declare`](line.md) |
| `audit` | `escape` | [`private.hiveMind.audit.json.escape`](hivemind.md) |
| `audit` | `render` | [`private.hiveMind.audit.render.human`](hivemind.md) · [`private.hiveMind.audit.render.json`](hivemind.md) |
| `auth` |  | [`private.osemvec.authorized`](osemvec.md) · [`private.scrumMaster.subscription.auth`](scrumMaster.md) |
| `auth` | `guard` | [`osemvec.guard`](osemvec.md) |
| `auth` | `rewind` | [`hiveMind.agent.rewind`](hivemind.md) |
| `auth` | `stop` | [`osemvec.stop`](osemvec.md) |
| `auth` | `stopAuthorized` | [`private.osemvec.stopAuthorized`](osemvec.md) |
| `authorized` |  | [`private.osemvec.authorized`](osemvec.md) |
| `authorized` | `adopt` | [`private.user.authorized.keys.adopt`](user.md) |
| `authorized` | `get` | [`private.ossh.authorized.key.append.get`](ossh.md) · [`private.user.authorized.key.get`](user.md) |
| `authorized` | `rebuild` | [`private.user.authorized.keys.rebuild`](user.md) |
| `authorized` | `update` | [`ossh.authorized.keys.update`](ossh.md) · [`user.authorized.keys.update`](user.md) |
| `authorized_keys` | `update` | [`ossh.authorized_keys.update`](ossh.md) |
| `auto` | `commit` | [`hiveMind.auto.commit`](hivemind.md) |
| `automount` |  | [`disk.automount`](disk.md) |
| `automount` | `create` | [`disk.automount.create.config`](disk.md) |
| `b` | `get` | [`ogit.merge.base.get`](ogit.md) |
| `b` | `show` | [`ogit.diff.show`](ogit.md) |
| `backend` |  | [`agentRoom.backend.status`](agentRoom.md) |
| `backend` | `stop` | [`agentRoom.backend.stop`](agentRoom.md) |
| `backup` |  | [`backup.config.which`](backup.md) · [`backup.from`](backup.md) · [`backup.here`](backup.md) · [`backup.status`](backup.md) · [`backup.strategy`](backup.md) · [`backup.target`](backup.md) · [`backup.to`](backup.md) · [`private.backup.strategy.secureMove`](backup.md) |
| `backup` | `capture` | [`backup.log.capture.mode`](backup.md) · [`private.backup.log.capture.mode`](backup.md) |
| `backup` | `complete` | [`private.complete.folders`](backup.md) |
| `backup` | `create` | [`backup.config.create`](backup.md) |
| `backup` | `diff` | [`backup.diff`](backup.md) · [`backup.full.diff`](backup.md) · [`backup.list.last.diff.result`](backup.md) |
| `backup` | `disable` | [`backup.config.disable`](backup.md) |
| `backup` | `discover` | [`backup.config.discover`](backup.md) |
| `backup` | `enable` | [`backup.config.enable`](backup.md) |
| `backup` | `get` | [`backup.backupPath.get`](backup.md) · [`backup.get.backupPath`](backup.md) · [`backup.get.relative.path`](backup.md) · [`backup.path.get.relative`](backup.md) · [`private.backup.get.backupPath`](backup.md) · [`private.backup.get.relative.path`](backup.md) |
| `backup` | `help` | [`backup.strategy.help`](backup.md) |
| `backup` | `inspect` | [`backup.inspect`](backup.md) |
| `backup` | `list` | [`backup.config.list`](backup.md) · [`backup.config.list.all`](backup.md) · [`backup.errors.list`](backup.md) · [`backup.file.list.notBackedUp`](backup.md) · [`backup.file.list.onlyInBackup`](backup.md) · [`backup.file.list.onlyInSource`](backup.md) · [`backup.file.list.onlyInTarget`](backup.md) · [`backup.file.list.same`](backup.md) · [`backup.list`](backup.md) · [`backup.list.config`](backup.md) · [`backup.list.errors`](backup.md) · [`backup.list.last.result.raw`](backup.md) · [`backup.list.notBackuped`](backup.md) · [`backup.list.onlyInBackup`](backup.md) · [`backup.list.onlyInSource`](backup.md) · [`backup.list.onlyInTarget`](backup.md) · [`backup.list.same`](backup.md) · [`backup.result.list.lastDiff`](backup.md) · [`backup.result.list.lastRaw`](backup.md) · [`private.backup.file.list.notBackedUp`](backup.md) · [`private.backup.file.list.onlyInBackup`](backup.md) · [`private.backup.file.list.onlyInSource`](backup.md) · [`private.backup.file.list.onlyInTarget`](backup.md) · [`private.backup.file.list.same`](backup.md) · [`private.backup.list.errors`](backup.md) · [`private.backup.result.list.lastDiff`](backup.md) · [`private.backup.result.list.lastRaw`](backup.md) · [`user.ssh.backup.list`](user.md) |
| `backup` | `log` | [`backup.capture.log.mode`](backup.md) · [`private.check.log.mode`](backup.md) |
| `backup` | `migrate` | [`user.ssh.backup.migrate`](user.md) |
| `backup` | `normalize` | [`backup.normalize.all`](backup.md) · [`backup.normalize.file`](backup.md) · [`backup.normalize.filename`](backup.md) |
| `backup` | `register` | [`backup.config.register`](backup.md) · [`backup.config.register.existing`](backup.md) |
| `backup` | `remove` | [`backup.sync.and.remove`](backup.md) |
| `backup` | `repair` | [`backup.config.repair`](backup.md) · [`private.backup.repair.config`](backup.md) |
| `backup` | `replace` | [`backup.folderLink.replace.by`](backup.md) · [`backup.folderLinks.replace.same.with`](backup.md) · [`backup.replace.by.folderLink`](backup.md) · [`backup.replace.same.with.folderLinks`](backup.md) · [`private.backup.replace.same.with.folderLinks`](backup.md) · [`private.replace.by.folderLink`](backup.md) |
| `backup` | `replaceByFolderLinks` | [`private.backup.strategy.replaceByFolderLinks`](backup.md) |
| `backup` | `resolve` | [`private.backup.resolve.paths`](backup.md) |
| `backup` | `revert` | [`backup.normalize.revert`](backup.md) |
| `backup` | `rsync` | [`private.backup.rsync`](backup.md) |
| `backup` | `run` | [`backup.run`](backup.md) · [`backup.run.mv`](backup.md) |
| `backup` | `save` | [`backup.config.save`](backup.md) |
| `backup` | `scan` | [`backup.normalize.scan`](backup.md) |
| `backup` | `source` | [`backup.source`](backup.md) |
| `backup` | `stop` | [`backup.stop`](backup.md) |
| `backup` | `sync` | [`backup.verify.sync`](backup.md) |
| `backup` | `unregister` | [`backup.config.unregister`](backup.md) |
| `backupPath` | `get` | [`backup.backupPath.get`](backup.md) |
| `base` |  | [`ogit.layout.status`](ogit.md) |
| `base` | `check` | [`private.ogit.root.check`](ogit.md) · [`private.oo.layout.folder.check`](oo.md) |
| `base` | `ensure` | [`ogit.safeDirectory.ensure`](ogit.md) · [`private.oo.shared.tree.ensure`](oo.md) |
| `base` | `get` | [`ogit.merge.base.get`](ogit.md) · [`oo.mode.base.get`](oo.md) · [`private.ogit.base.get`](ogit.md) |
| `base` | `list` | [`private.ogit.base.folders.list`](ogit.md) |
| `base` | `remove` | [`ogit.worktree.remove`](ogit.md) |
| `base` | `rerun` | [`private.ogit.sudo.rerun`](ogit.md) |
| `base` | `restore` | [`ogit.worktree.restore`](ogit.md) |
| `base` | `set` | [`oo.mode.base.set`](oo.md) |
| `baseBranch` | `check` | [`oo.branches.check`](oo.md) |
| `basehome` |  | [`private.ossh.users.basehome`](ossh.md) |
| `basehome` | `get` | [`private.user.basehome.system.get`](user.md) |
| `basehome` | `remove` | [`private.ossh.shared.ssh.legacy.remove`](ossh.md) |
| `bash` |  | [`config.bash.minimal.version`](config.md) |
| `bashrc` | `ensure` | [`private.config.bashrc.ensure.all`](config.md) |
| `bashrc` | `install` | [`private.user.bashrc.install`](user.md) |
| `bashrcBlock` |  | [`private.opy.bashrcBlock`](opy.md) |
| `binary` | `check` | [`ogit.binary.check`](ogit.md) |
| `block` |  | [`replace.block`](replace.md) |
| `block` | `get` | [`private.ossh.config.block.put.get`](ossh.md) |
| `block` | `is` | [`private.ossh.github.block.is.oosh`](ossh.md) |
| `branch` |  | [`ogit.branch.fastForward`](ogit.md) · [`oo.mode`](oo.md) · [`private.promote.rewrite.self.branch`](promote.md) · [`promote.branch.alignment`](promote.md) |
| `branch` | `add` | [`ogit.worktree.add`](ogit.md) |
| `branch` | `adopt` | [`ogit.branch.adopt`](ogit.md) |
| `branch` | `check` | [`ogit.branch.check`](ogit.md) |
| `branch` | `checkout` | [`ogit.branch.checkout`](ogit.md) |
| `branch` | `clone` | [`ogit.repo.clone`](ogit.md) |
| `branch` | `compare` | [`ogit.branch.compare`](ogit.md) |
| `branch` | `delete` | [`ogit.branch.remote.delete`](ogit.md) |
| `branch` | `deploy` | [`otest.deploy`](otest.md) |
| `branch` | `ensure` | [`private.oo.branch.clone.ensure`](oo.md) · [`private.oo.shared.tree.ensure`](oo.md) |
| `branch` | `find` | [`ogit.branch.find`](ogit.md) · [`ogit.worktree.find`](ogit.md) |
| `branch` | `get` | [`ogit.branch.get`](ogit.md) · [`private.oo.install.branch.get`](oo.md) |
| `branch` | `import` | [`private.ogit.branch.import`](ogit.md) |
| `branch` | `install` | [`user.oosh.install`](user.md) |
| `branch` | `list` | [`ogit.branch.list`](ogit.md) · [`ogit.remote.branch.list`](ogit.md) · [`oo.branch.list`](oo.md) |
| `branch` | `merge` | [`ogit.branch.merge`](ogit.md) |
| `branch` | `pull` | [`ogit.remote.pull`](ogit.md) |
| `branch` | `push` | [`ogit.remote.push`](ogit.md) |
| `branch` | `reset` | [`ogit.branch.reset`](ogit.md) |
| `branch` | `set` | [`ogit.branch.upstream.set`](ogit.md) |
| `branch` | `sync` | [`oo.mode.sync`](oo.md) |
| `branch` | `use` | [`oo.use`](oo.md) |
| `branchName` |  | [`private.oo.shared.tree.from.local`](oo.md) |
| `branches` | `check` | [`oo.branches.check`](oo.md) |
| `brew` | `fix` | [`osx.brew.fix`](osx.md) |
| `browser` | `open` | [`otest.browser.open`](otest.md) |
| `buffer` | `choose` | [`otmux.buffer.choose`](otmux.md) |
| `buffer` | `delete` | [`otmux.buffer.delete`](otmux.md) |
| `buffer` | `deleteBuffer` | [`private.otmux.deleteBuffer`](otmux.md) |
| `buffer` | `list` | [`otmux.buffer.list`](otmux.md) |
| `buffer` | `load` | [`otmux.buffer.load`](otmux.md) |
| `buffer` | `paste` | [`otmux.buffer.paste`](otmux.md) |
| `buffer` | `save` | [`otmux.buffer.save`](otmux.md) |
| `buffer` | `set` | [`otmux.buffer.set`](otmux.md) |
| `buffer` | `show` | [`otmux.buffer.show`](otmux.md) |
| `buffer` | `showBuffer` | [`private.otmux.showBuffer`](otmux.md) |
| `buffers` |  | [`otmux.buffers`](otmux.md) |
| `buildin` |  | [`c2.buildin.commands`](c2.md) |
| `buildinCommands` |  | [`2c.buildinCommands`](2c.md) · [`mycmd.tab.buildinCommands`](mycmd.md) |
| `by` |  | [`osx.spotlight.by.name`](osx.md) · [`osx.spotlight.by.size`](osx.md) · [`replace.by`](replace.md) · [`replace.by.file`](replace.md) |
| `by` | `filter` | [`line.filter`](line.md) |
| `by` | `replace` | [`line.replace`](line.md) · [`line.replace.sedquoted`](line.md) |
| `by` | `split` | [`line.split.quoted`](line.md) |
| `byBranch` | `check` | [`private.oo.layout.folder.check`](oo.md) |
| `byJsonl` |  | [`claudeCode.context.velocity.byJsonl`](claudeCode.md) |
| `byPane` |  | [`claudeCode.context.velocity.byPane`](claudeCode.md) |
| `bykind` |  | [`osx.spotlight.bykind`](osx.md) |
| `c` |  | [`claudeCode.c`](claudeCode.md) |
| `c` | `render` | [`private.hiveMind.audit.render.human`](hivemind.md) · [`private.hiveMind.audit.render.json`](hivemind.md) |
| `c2` |  | [`c2.alias`](c2.md) · [`c2.buildin.commands`](c2.md) · [`c2.env`](c2.md) · [`c2.folders`](c2.md) · [`c2.groups`](c2.md) · [`c2.jobs`](c2.md) · [`c2.status`](c2.md) · [`c2.user`](c2.md) · [`c2.variables`](c2.md) |
| `c2` | `format` | [`c2.format.functions`](c2.md) · [`c2.function.description.format`](c2.md) · [`c2.functions.format`](c2.md) · [`private.c2.format.functions`](c2.md) |
| `c2` | `get` | [`c2.function.declaration.get`](c2.md) · [`c2.function.get.with.documentation`](c2.md) · [`c2.function.parameter.get`](c2.md) · [`c2.functions.get`](c2.md) · [`c2.get.formated.function.description`](c2.md) · [`c2.get.function.declaration`](c2.md) · [`c2.get.function.parameter`](c2.md) · [`c2.get.function.with.documentation`](c2.md) · [`c2.get.functions`](c2.md) · [`private.c2.get.formated.function.description`](c2.md) · [`private.c2.get.function.declaration`](c2.md) · [`private.c2.get.function.parameter`](c2.md) · [`private.c2.get.function.with.documentation`](c2.md) · [`private.c2.get.functions`](c2.md) |
| `c2` | `init` | [`c2.init`](c2.md) |
| `c2` | `install` | [`c2.install.linux`](c2.md) |
| `c2` | `parse` | [`c2.debug.parse.param`](c2.md) |
| `c2` | `test` | [`c2.test.absolutePathName`](c2.md) |
| `c2` | `validate` | [`c2.signature.validate`](c2.md) |
| `cache` |  | [`scrumMaster.subscription.cache.age`](scrumMaster.md) |
| `cacheFile` |  | [`private.scrumMaster.subscription.cacheFile`](scrumMaster.md) |
| `call` | `execute` | [`private.check.call.execute`](check.md) |
| `caller` |  | [`this.caller`](this.md) · [`this.caller.function`](this.md) · [`this.methodNotFound`](this.md) |
| `caller` | `check` | [`private.this.tree.tracked.check`](this.md) |
| `caller` | `validate` | [`ogit.caller.validate`](ogit.md) |
| `canonical` |  | [`private.this.path.canonical`](this.md) |
| `capture` | `log` | [`backup.capture.log.mode`](backup.md) |
| `case` | `get` | [`private.this.path.case.get`](this.md) |
| `category` |  | [`private.test.suite.category`](test.suite.md) · [`private.test.suite.verdict`](test.suite.md) |
| `category` | `run` | [`private.test.suite.run.filtered`](test.suite.md) |
| `certificates` |  | [`certificates.once.scenarios`](certificates.md) · [`certificates.status`](certificates.md) · [`ossh.certificates.status`](ossh.md) |
| `certificates` | `create` | [`private.check.certificates.update.create.certbot`](ossh.md) · [`private.check.certificates.update.create.structr`](ossh.md) |
| `certificates` | `get` | [`certificates.once.get.certbot.path`](certificates.md) |
| `certificates` | `init` | [`private.certificates.init`](certificates.md) · [`private.certificates.update.state.machine.init`](ossh.md) |
| `certificates` | `list` | [`certificates.once.scenario.list`](certificates.md) |
| `certificates` | `load` | [`private.certificates.update.config.load`](ossh.md) |
| `certificates` | `read` | [`private.certificates.update.config.read`](ossh.md) |
| `certificates` | `restore` | [`private.check.certificates.update.restore.workspace`](ossh.md) |
| `certificates` | `rotate` | [`private.check.certificates.update.rotate.empty`](ossh.md) |
| `certificates` | `run` | [`private.certificates.update.ssh.run`](ossh.md) |
| `certificates` | `select` | [`certificates.once.scenario.select`](certificates.md) |
| `certificates` | `start` | [`private.check.certificates.update.start.structr`](ossh.md) |
| `certificates` | `stop` | [`private.check.certificates.update.stop.certbot`](ossh.md) · [`private.check.certificates.update.stop.structr`](ossh.md) |
| `certificates` | `update` | [`ossh.certificates.update`](ossh.md) · [`private.certificates.update.config.persist`](ossh.md) · [`private.certificates.update.machine.name`](ossh.md) · [`private.check.certificates.update.archive.workspace`](ossh.md) |
| `certificates` | `verify` | [`private.check.certificates.update.verify.https`](ossh.md) |
| `chain` |  | [`private.config.session.chain.ready`](config.md) |
| `chain` | `get` | [`private.config.chain.names.get`](config.md) |
| `chain` | `migrate` | [`private.config.log.chain.migrate`](config.md) |
| `chained` |  | [`private.odocker.env.chained`](odocker.md) |
| `changed` | `get` | [`private.test.suite.ssh.secrets.changed.get`](test.suite.md) |
| `channel` | `resolve` | [`private.hiveMind.channel.resolve`](hivemind.md) |
| `channel` | `wait` | [`otmux.wait`](otmux.md) |
| `charakter` |  | [`line.key`](line.md) · [`line.space2`](line.md) · [`line.value`](line.md) |
| `charakter` | `join` | [`line.join`](line.md) |
| `chat` |  | [`agentRoom.chat`](agentRoom.md) · [`claudeCode.chat`](claudeCode.md) |
| `check` |  | [`check.admin`](check.md) · [`check.and`](check.md) · [`check.condition`](check.md) · [`check.dir`](check.md) · [`check.directory`](check.md) · [`check.file`](check.md) · [`check.message`](check.md) · [`check.not`](check.md) · [`check.root`](check.md) · [`check.user`](check.md) |
| `check` | `boot` | [`private.check.root.boot.path.installed`](oo.md) |
| `check` | `call` | [`check.call`](check.md) · [`private.call.it`](check.md) |
| `check` | `complete` | [`private.check.cycle.complete`](scrumMaster.md) |
| `check` | `create` | [`private.check.certificates.update.create.certbot`](ossh.md) · [`private.check.certificates.update.create.structr`](ossh.md) |
| `check` | `dispatch` | [`private.check.platform.test.dispatch`](promote.md) |
| `check` | `execute` | [`private.check.call.execute`](check.md) · [`private.check.fix.execute`](check.md) |
| `check` | `exists` | [`check.exists`](check.md) |
| `check` | `fix` | [`check.fix`](check.md) · [`check.fix.message`](check.md) · [`private.fix.it`](check.md) |
| `check` | `install` | [`private.check.local.install.started`](oo.md) · [`private.check.remote.install.started`](oo.md) |
| `check` | `log` | [`private.check.log.mode`](backup.md) |
| `check` | `next` | [`private.check.next.custom.state`](ossh.md) · [`private.check.next.custom.state`](promote.md) · [`private.check.next.custom.state`](scrumMaster.md) |
| `check` | `release` | [`private.check.user.mode.release`](oo.md) |
| `check` | `restore` | [`private.check.certificates.update.restore.workspace`](ossh.md) |
| `check` | `rotate` | [`private.check.certificates.update.rotate.empty`](ossh.md) |
| `check` | `setup` | [`private.check.headless.setup.finished`](oo.md) · [`private.check.headless.setup.started`](oo.md) · [`private.check.once.setup.finished`](oo.md) · [`private.check.once.setup.started`](oo.md) · [`private.check.setup`](state.md) |
| `check` | `start` | [`private.check.certificates.update.start.structr`](ossh.md) |
| `check` | `stop` | [`private.check.certificates.update.stop.certbot`](ossh.md) · [`private.check.certificates.update.stop.structr`](ossh.md) |
| `check` | `test` | [`mycmd.check.test.results`](mycmd.md) · [`private.check.test.suite.passed`](promote.md) · [`private.check.test.suite.passed.prod`](promote.md) |
| `check` | `update` | [`private.check.certificates.update.archive.workspace`](ossh.md) |
| `check` | `verify` | [`private.check.certificates.update.verify.https`](ossh.md) |
| `checkout` | `get` | [`private.oo.checkout.dir.get`](oo.md) |
| `checkout` | `remove` | [`oo.checkout.remove`](oo.md) |
| `chevron` |  | [`line.example.chevron`](line.md) |
| `chromePath` |  | [`private.chromePath`](otest.md) |
| `chromium` |  | [`setup.chromium`](setup.md) |
| `claude` |  | [`hiveMind.claude`](hivemind.md) · [`private.hiveMind.claude.processes`](hivemind.md) |
| `claudeCode` |  | [`claudeCode.c`](claudeCode.md) · [`claudeCode.chat`](claudeCode.md) · [`claudeCode.config`](claudeCode.md) · [`claudeCode.context.alert`](claudeCode.md) · [`claudeCode.context.all`](claudeCode.md) · [`claudeCode.context.dashboard`](claudeCode.md) · [`claudeCode.context.jsonl`](claudeCode.md) · [`claudeCode.context.self`](claudeCode.md) · [`claudeCode.context.velocity`](claudeCode.md) · [`claudeCode.context.velocity.byJsonl`](claudeCode.md) · [`claudeCode.context.velocity.byPane`](claudeCode.md) · [`claudeCode.dangerously`](claudeCode.md) · [`claudeCode.doctor`](claudeCode.md) · [`claudeCode.haiku`](claudeCode.md) · [`claudeCode.json`](claudeCode.md) · [`claudeCode.mcp`](claudeCode.md) · [`claudeCode.model`](claudeCode.md) · [`claudeCode.opus`](claudeCode.md) · [`claudeCode.output`](claudeCode.md) · [`claudeCode.p`](claudeCode.md) · [`claudeCode.process.running`](claudeCode.md) · [`claudeCode.session.current`](claudeCode.md) · [`claudeCode.session.id`](claudeCode.md) · [`claudeCode.session.name`](claudeCode.md) · [`claudeCode.session.state`](claudeCode.md) · [`claudeCode.sessions`](claudeCode.md) · [`claudeCode.sonnet`](claudeCode.md) · [`claudeCode.status`](claudeCode.md) · [`claudeCode.tools.allowed`](claudeCode.md) · [`claudeCode.tools.disallowed`](claudeCode.md) · [`claudeCode.turns.max`](claudeCode.md) · [`claudeCode.v`](claudeCode.md) · [`claudeCode.verbose`](claudeCode.md) · [`claudeCode.version`](claudeCode.md) · [`claudeCode.yolo`](claudeCode.md) · [`private.claudeCode.context.from.jsonl`](claudeCode.md) · [`private.claudeCode.context.jsonl.lag`](claudeCode.md) · [`private.claudeCode.max.tokens.for.jsonl`](claudeCode.md) · [`private.claudeCode.projectHash`](claudeCode.md) |
| `claudeCode` | `append` | [`claudeCode.system.prompt.append`](claudeCode.md) |
| `claudeCode` | `calculate` | [`private.claudeCode.velocity.calculate`](claudeCode.md) |
| `claudeCode` | `check` | [`claudeCode.context.check`](claudeCode.md) |
| `claudeCode` | `complete` | [`private.claudeCode.complete.panes`](claudeCode.md) · [`private.claudeCode.complete.roleNames`](claudeCode.md) · [`private.claudeCode.complete.sessionIds`](claudeCode.md) |
| `claudeCode` | `continue` | [`claudeCode.continue`](claudeCode.md) |
| `claudeCode` | `decode` | [`private.claudeCode.decode.projectHash`](claudeCode.md) |
| `claudeCode` | `discover` | [`private.claudeCode.session.discover`](claudeCode.md) |
| `claudeCode` | `find` | [`claudeCode.process.find`](claudeCode.md) |
| `claudeCode` | `fork` | [`claudeCode.fork`](claudeCode.md) · [`claudeCode.fork.byID`](claudeCode.md) · [`claudeCode.fork.byName`](claudeCode.md) · [`claudeCode.fork.byPane`](claudeCode.md) · [`claudeCode.fork.to`](claudeCode.md) |
| `claudeCode` | `get` | [`claudeCode.model.get`](claudeCode.md) |
| `claudeCode` | `help` | [`claudeCode.help`](claudeCode.md) |
| `claudeCode` | `init` | [`claudeCode.init`](claudeCode.md) |
| `claudeCode` | `install` | [`claudeCode.install`](claudeCode.md) |
| `claudeCode` | `join` | [`claudeCode.join`](claudeCode.md) · [`claudeCode.join.byID`](claudeCode.md) · [`claudeCode.join.byName`](claudeCode.md) · [`claudeCode.join.byPane`](claudeCode.md) |
| `claudeCode` | `list` | [`claudeCode.list`](claudeCode.md) · [`claudeCode.list.json`](claudeCode.md) · [`claudeCode.list.named`](claudeCode.md) · [`claudeCode.model.list`](claudeCode.md) |
| `claudeCode` | `login` | [`claudeCode.login`](claudeCode.md) |
| `claudeCode` | `logout` | [`claudeCode.logout`](claudeCode.md) |
| `claudeCode` | `new` | [`claudeCode.new`](claudeCode.md) |
| `claudeCode` | `parse` | [`private.claudeCode.context.parse`](claudeCode.md) |
| `claudeCode` | `pipe` | [`claudeCode.pipe`](claudeCode.md) |
| `claudeCode` | `print` | [`claudeCode.print`](claudeCode.md) |
| `claudeCode` | `probe` | [`claudeCode.session.probe`](claudeCode.md) · [`claudeCode.session.probe.fromCapture`](claudeCode.md) |
| `claudeCode` | `prompt` | [`claudeCode.system.prompt`](claudeCode.md) |
| `claudeCode` | `read` | [`claudeCode.context.read`](claudeCode.md) · [`claudeCode.context.read.tui`](claudeCode.md) · [`private.claudeCode.context.read.tui`](claudeCode.md) |
| `claudeCode` | `recover` | [`claudeCode.recover`](claudeCode.md) · [`claudeCode.session.recover`](claudeCode.md) |
| `claudeCode` | `resolve` | [`private.claudeCode.resolve.byName`](claudeCode.md) · [`private.claudeCode.resolve.byPane`](claudeCode.md) · [`private.claudeCode.resolve.projectDir`](claudeCode.md) |
| `claudeCode` | `save` | [`claudeCode.session.save`](claudeCode.md) |
| `claudeCode` | `set` | [`claudeCode.model.set`](claudeCode.md) |
| `claudeCode` | `stop` | [`claudeCode.stop`](claudeCode.md) |
| `claudeCode` | `uninstall` | [`claudeCode.uninstall`](claudeCode.md) |
| `claudeCode` | `update` | [`claudeCode.update`](claudeCode.md) |
| `claudeFlow` |  | [`claudeFlow.agent`](claudeFlow.md) · [`claudeFlow.agent.health`](claudeFlow.md) · [`claudeFlow.agent.logs`](claudeFlow.md) · [`claudeFlow.agent.metrics`](claudeFlow.md) · [`claudeFlow.agent.pool`](claudeFlow.md) · [`claudeFlow.agent.status`](claudeFlow.md) · [`claudeFlow.daemon`](claudeFlow.md) · [`claudeFlow.doctor`](claudeFlow.md) · [`claudeFlow.embeddings`](claudeFlow.md) · [`claudeFlow.hive`](claudeFlow.md) · [`claudeFlow.hive.consensus`](claudeFlow.md) · [`claudeFlow.hive.memory`](claudeFlow.md) · [`claudeFlow.hive.status`](claudeFlow.md) · [`claudeFlow.hive.task`](claudeFlow.md) · [`claudeFlow.hooks`](claudeFlow.md) · [`claudeFlow.i`](claudeFlow.md) · [`claudeFlow.interactive`](claudeFlow.md) · [`claudeFlow.json`](claudeFlow.md) · [`claudeFlow.mcp`](claudeFlow.md) · [`claudeFlow.mcp.health`](claudeFlow.md) · [`claudeFlow.mcp.logs`](claudeFlow.md) · [`claudeFlow.mcp.status`](claudeFlow.md) · [`claudeFlow.mcp.tools`](claudeFlow.md) · [`claudeFlow.memory`](claudeFlow.md) · [`claudeFlow.memory.stats`](claudeFlow.md) · [`claudeFlow.neural`](claudeFlow.md) · [`claudeFlow.perf`](claudeFlow.md) · [`claudeFlow.performance`](claudeFlow.md) · [`claudeFlow.quick`](claudeFlow.md) · [`claudeFlow.quiet`](claudeFlow.md) · [`claudeFlow.security`](claudeFlow.md) · [`claudeFlow.session`](claudeFlow.md) · [`claudeFlow.session.current`](claudeFlow.md) · [`claudeFlow.status`](claudeFlow.md) · [`claudeFlow.statusline`](claudeFlow.md) · [`claudeFlow.statusline.config`](claudeFlow.md) · [`claudeFlow.statusline.off`](claudeFlow.md) · [`claudeFlow.statusline.on`](claudeFlow.md) · [`claudeFlow.statusline.status`](claudeFlow.md) · [`claudeFlow.swarm`](claudeFlow.md) · [`claudeFlow.swarm.status`](claudeFlow.md) · [`claudeFlow.swarm.v3`](claudeFlow.md) · [`claudeFlow.table`](claudeFlow.md) · [`claudeFlow.task`](claudeFlow.md) · [`claudeFlow.task.all`](claudeFlow.md) · [`claudeFlow.task.info`](claudeFlow.md) · [`claudeFlow.task.status`](claudeFlow.md) · [`claudeFlow.tmux`](claudeFlow.md) · [`claudeFlow.tmux.agents`](claudeFlow.md) · [`claudeFlow.tmux.layout`](claudeFlow.md) · [`claudeFlow.tmux.lower`](claudeFlow.md) · [`claudeFlow.tmux.main`](claudeFlow.md) · [`claudeFlow.tmux.pane`](claudeFlow.md) · [`claudeFlow.tmux.status`](claudeFlow.md) · [`claudeFlow.tmux.task`](claudeFlow.md) · [`claudeFlow.v`](claudeFlow.md) · [`claudeFlow.verbose`](claudeFlow.md) · [`claudeFlow.version`](claudeFlow.md) |
| `claudeFlow` | `assign` | [`claudeFlow.task.assign`](claudeFlow.md) |
| `claudeFlow` | `bind` | [`claudeFlow.tmux.bind`](claudeFlow.md) |
| `claudeFlow` | `broadcast` | [`claudeFlow.hive.broadcast`](claudeFlow.md) |
| `claudeFlow` | `cancel` | [`claudeFlow.task.cancel`](claudeFlow.md) |
| `claudeFlow` | `cleanup` | [`claudeFlow.memory.cleanup`](claudeFlow.md) |
| `claudeFlow` | `compress` | [`claudeFlow.memory.compress`](claudeFlow.md) |
| `claudeFlow` | `coordinate` | [`claudeFlow.swarm.coordinate`](claudeFlow.md) |
| `claudeFlow` | `create` | [`claudeFlow.task.create`](claudeFlow.md) |
| `claudeFlow` | `delete` | [`claudeFlow.memory.delete`](claudeFlow.md) · [`claudeFlow.session.delete`](claudeFlow.md) |
| `claudeFlow` | `exec` | [`claudeFlow.mcp.exec`](claudeFlow.md) |
| `claudeFlow` | `export` | [`claudeFlow.memory.export`](claudeFlow.md) · [`claudeFlow.session.export`](claudeFlow.md) |
| `claudeFlow` | `focus` | [`claudeFlow.tmux.focus`](claudeFlow.md) |
| `claudeFlow` | `get` | [`claudeFlow.memory.get`](claudeFlow.md) |
| `claudeFlow` | `help` | [`claudeFlow.help`](claudeFlow.md) |
| `claudeFlow` | `import` | [`claudeFlow.memory.import`](claudeFlow.md) · [`claudeFlow.session.import`](claudeFlow.md) |
| `claudeFlow` | `init` | [`claudeFlow.hive.init`](claudeFlow.md) · [`claudeFlow.init`](claudeFlow.md) · [`claudeFlow.memory.init`](claudeFlow.md) · [`claudeFlow.swarm.init`](claudeFlow.md) · [`claudeFlow.tmux.init`](claudeFlow.md) |
| `claudeFlow` | `install` | [`claudeFlow.install`](claudeFlow.md) |
| `claudeFlow` | `join` | [`claudeFlow.hive.join`](claudeFlow.md) |
| `claudeFlow` | `kill` | [`claudeFlow.agent.kill`](claudeFlow.md) · [`claudeFlow.tmux.kill`](claudeFlow.md) · [`claudeFlow.tmux.kill.all`](claudeFlow.md) |
| `claudeFlow` | `leave` | [`claudeFlow.hive.leave`](claudeFlow.md) |
| `claudeFlow` | `list` | [`claudeFlow.agent.list`](claudeFlow.md) · [`claudeFlow.hive.list`](claudeFlow.md) · [`claudeFlow.list`](claudeFlow.md) · [`claudeFlow.list.json`](claudeFlow.md) · [`claudeFlow.memory.list`](claudeFlow.md) · [`claudeFlow.session.list`](claudeFlow.md) · [`claudeFlow.task.list`](claudeFlow.md) · [`claudeFlow.tmux.list`](claudeFlow.md) |
| `claudeFlow` | `load` | [`claudeFlow.session.load`](claudeFlow.md) |
| `claudeFlow` | `ls` | [`claudeFlow.agent.ls`](claudeFlow.md) · [`claudeFlow.memory.ls`](claudeFlow.md) · [`claudeFlow.session.ls`](claudeFlow.md) · [`claudeFlow.task.ls`](claudeFlow.md) |
| `claudeFlow` | `new` | [`claudeFlow.task.new`](claudeFlow.md) |
| `claudeFlow` | `optimize` | [`claudeFlow.hive.optimize`](claudeFlow.md) |
| `claudeFlow` | `preview` | [`claudeFlow.statusline.preview`](claudeFlow.md) |
| `claudeFlow` | `restart` | [`claudeFlow.mcp.restart`](claudeFlow.md) · [`claudeFlow.restart`](claudeFlow.md) |
| `claudeFlow` | `restore` | [`claudeFlow.session.restore`](claudeFlow.md) |
| `claudeFlow` | `retry` | [`claudeFlow.task.retry`](claudeFlow.md) |
| `claudeFlow` | `rm` | [`claudeFlow.memory.rm`](claudeFlow.md) · [`claudeFlow.session.rm`](claudeFlow.md) |
| `claudeFlow` | `run` | [`claudeFlow.tmux.run`](claudeFlow.md) |
| `claudeFlow` | `save` | [`claudeFlow.session.save`](claudeFlow.md) |
| `claudeFlow` | `scale` | [`claudeFlow.swarm.scale`](claudeFlow.md) |
| `claudeFlow` | `search` | [`claudeFlow.memory.search`](claudeFlow.md) |
| `claudeFlow` | `set` | [`claudeFlow.statusline.set`](claudeFlow.md) |
| `claudeFlow` | `shutdown` | [`claudeFlow.hive.shutdown`](claudeFlow.md) |
| `claudeFlow` | `spawn` | [`claudeFlow.agent.spawn`](claudeFlow.md) · [`claudeFlow.hive.spawn`](claudeFlow.md) · [`claudeFlow.tmux.spawn`](claudeFlow.md) |
| `claudeFlow` | `stop` | [`claudeFlow.agent.stop`](claudeFlow.md) · [`claudeFlow.mcp.stop`](claudeFlow.md) · [`claudeFlow.stop`](claudeFlow.md) · [`claudeFlow.swarm.stop`](claudeFlow.md) |
| `claudeFlow` | `store` | [`claudeFlow.memory.store`](claudeFlow.md) |
| `claudeFlow` | `toggle` | [`claudeFlow.mcp.toggle`](claudeFlow.md) · [`claudeFlow.statusline.toggle`](claudeFlow.md) |
| `claudeFlow` | `uninstall` | [`claudeFlow.uninstall`](claudeFlow.md) |
| `claudeFlow` | `update` | [`claudeFlow.update`](claudeFlow.md) |
| `client` | `choose` | [`otmux.client.choose`](otmux.md) · [`otmux.client.choose.tree`](otmux.md) |
| `client` | `cleanup` | [`otmux.client.cleanup`](otmux.md) |
| `client` | `detach` | [`otmux.client.detach`](otmux.md) |
| `client` | `detachClient` | [`private.otmux.detachClient`](otmux.md) |
| `client` | `list` | [`otmux.client.list`](otmux.md) |
| `client` | `lock` | [`otmux.client.lock`](otmux.md) |
| `client` | `refresh` | [`otmux.client.refresh`](otmux.md) |
| `client` | `suspend` | [`otmux.client.suspend`](otmux.md) |
| `clients` |  | [`otmux.clients`](otmux.md) |
| `clipboard` | `apply` | [`private.otmux.setup.clipboard.apply`](otmux.md) |
| `clock` |  | [`otmux.clock`](otmux.md) |
| `clone` | `ensure` | [`private.oo.branch.clone.ensure`](oo.md) |
| `cmd` |  | [`oo.cmd`](oo.md) · [`ossh.cmd`](ossh.md) |
| `cmd` | `find` | [`oo.cmd.find`](oo.md) · [`private.oo.find.cmd`](oo.md) |
| `cmd` | `get` | [`private.odocker.prereq.package.get`](odocker.md) · [`private.setup.package.get`](setup.md) |
| `cmd` | `install` | [`private.setup.cmds.install`](setup.md) |
| `cmd` | `verify` | [`private.oo.cmd.verify`](oo.md) |
| `cmd1` |  | [`otmux.if`](otmux.md) |
| `cmd2` |  | [`otmux.if`](otmux.md) |
| `cmds` | `install` | [`private.setup.cmds.install`](setup.md) |
| `cold` | `recover` | [`hiveMind.cold.recover`](hivemind.md) |
| `command` |  | [`c2.buildin.commands`](c2.md) · [`claudeFlow.i`](claudeFlow.md) · [`claudeFlow.interactive`](claudeFlow.md) · [`claudeFlow.json`](claudeFlow.md) · [`claudeFlow.quiet`](claudeFlow.md) · [`claudeFlow.table`](claudeFlow.md) · [`claudeFlow.tmux.pane`](claudeFlow.md) · [`claudeFlow.verbose`](claudeFlow.md) · [`debug.onError`](debug.md) · [`odocker.image.command`](odocker.md) · [`otmux.256color`](otmux.md) · [`otmux.config`](otmux.md) · [`otmux.control`](otmux.md) · [`otmux.nw`](otmux.md) · [`otmux.socket`](otmux.md) · [`otmux.utf8`](otmux.md) · [`otmux.verbose`](otmux.md) · [`private.as.user`](user.md) · [`private.ossh.ssh`](ossh.md) · [`private.otmux.socketPath`](otmux.md) |
| `command` | `bind` | [`otmux.bind`](otmux.md) · [`otmux.key.bind`](otmux.md) |
| `command` | `confirm` | [`otmux.confirm`](otmux.md) · [`otmux.send.confirm`](otmux.md) |
| `command` | `exec` | [`odocker.exec.command`](odocker.md) · [`ossh.exec`](ossh.md) · [`ossh.exec.tty`](ossh.md) |
| `command` | `get` | [`private.config.pm.command.get`](config.md) · [`private.user.delete.command.get`](user.md) |
| `command` | `new` | [`otmux.new`](otmux.md) · [`otmux.session.new`](otmux.md) · [`otmux.window.new`](otmux.md) |
| `command` | `newWindow` | [`private.otmux.newWindow`](otmux.md) |
| `command` | `pipe` | [`otmux.pane.pipe`](otmux.md) |
| `command` | `pipePane` | [`private.otmux.pipePane`](otmux.md) |
| `command` | `respawn` | [`otmux.pane.respawn`](otmux.md) · [`otmux.window.respawn`](otmux.md) |
| `command` | `respawnPane` | [`private.otmux.respawnPane`](otmux.md) |
| `command` | `respawnWindow` | [`private.otmux.respawnWindow`](otmux.md) |
| `command` | `run` | [`claudeFlow.tmux.run`](claudeFlow.md) · [`otmux.run`](otmux.md) · [`otmux.send.run`](otmux.md) · [`private.certificates.update.ssh.run`](ossh.md) · [`private.setup.nvm.run`](setup.md) |
| `command` | `set` | [`claudeFlow.statusline.set`](claudeFlow.md) · [`otmux.config.set.hook`](otmux.md) |
| `command` | `setHook` | [`private.otmux.setHook`](otmux.md) |
| `command` | `split` | [`otmux.pane.split`](otmux.md) · [`otmux.pane.split.h`](otmux.md) · [`otmux.pane.split.v`](otmux.md) · [`otmux.split`](otmux.md) · [`otmux.split.h`](otmux.md) · [`otmux.split.v`](otmux.md) |
| `command` | `splitH` | [`otmux.pane.splitH`](otmux.md) · [`private.otmux.splitH`](otmux.md) |
| `command` | `splitV` | [`private.otmux.splitV`](otmux.md) |
| `command` | `use` | [`oo.use`](oo.md) |
| `commands` |  | [`c2.buildin.commands`](c2.md) · [`otmux.commands`](otmux.md) |
| `commit` | `continue` | [`ogit.commit.pick.continue`](ogit.md) |
| `commit` | `count` | [`ogit.commit.count`](ogit.md) |
| `commit` | `create` | [`ogit.commit.create`](ogit.md) |
| `commit` | `pick` | [`ogit.commit.pick`](ogit.md) · [`ogit.commit.pick.abort`](ogit.md) |
| `commit` | `revert` | [`ogit.commit.revert`](ogit.md) |
| `commit` | `show` | [`ogit.commit.log.show`](ogit.md) · [`ogit.commit.show`](ogit.md) |
| `compose` | `find` | [`private.odocker.compose.file.find`](odocker.md) |
| `composer` |  | [`otmux.composer.state`](otmux.md) |
| `condition` |  | [`check.condition`](check.md) · [`otmux.if`](otmux.md) |
| `config` |  | [`backup.config.which`](backup.md) · [`claudeCode.config`](claudeCode.md) · [`claudeFlow.statusline.config`](claudeFlow.md) · [`config.bash.minimal.version`](config.md) · [`config.file`](config.md) · [`config.location`](config.md) · [`otmux.config`](otmux.md) · [`private.config.session.chain.ready`](config.md) · [`private.config.string.upper`](config.md) · [`private.default.config`](otmux.md) |
| `config` | `add` | [`config.add`](config.md) |
| `config` | `append` | [`private.config.env.line.append`](config.md) |
| `config` | `check` | [`config.file.check`](config.md) · [`config.init.check`](config.md) |
| `config` | `clean` | [`config.clean`](config.md) · [`line.config.clean`](line.md) |
| `config` | `complete` | [`private.ossh.config.complete.hosts`](ossh.md) |
| `config` | `create` | [`backup.config.create`](backup.md) · [`ossh.config.create`](ossh.md) · [`ossh.config.shared.create`](ossh.md) · [`ossh.config.shared.github.create`](ossh.md) · [`private.config.create`](ossh.md) |
| `config` | `delete` | [`config.delete`](config.md) · [`ossh.config.delete`](ossh.md) |
| `config` | `deploy` | [`ossh.config.shared.seed.from.local.deploy.key`](ossh.md) |
| `config` | `derive` | [`private.config.derive.bash.file`](config.md) · [`private.config.derive.config.file`](config.md) · [`private.config.derive.oosh.mode`](config.md) · [`private.config.derive.oosh.os`](config.md) · [`private.config.derive.oosh.pm`](config.md) |
| `config` | `disable` | [`backup.config.disable`](backup.md) |
| `config` | `discover` | [`backup.config.discover`](backup.md) · [`config.discover`](config.md) |
| `config` | `drop` | [`private.config.env.lines.drop`](config.md) |
| `config` | `edit` | [`config.edit`](config.md) · [`ossh.config.edit`](ossh.md) · [`ossh.server.config.edit`](ossh.md) · [`share.samba.config.edit`](share.md) |
| `config` | `enable` | [`backup.config.enable`](backup.md) |
| `config` | `ensure` | [`private.config.bashrc.ensure.all`](config.md) · [`private.config.session.file.ensure`](config.md) · [`private.config.session.files.ensure.all`](config.md) |
| `config` | `export` | [`private.config.variable.export.line`](config.md) · [`private.config.variables.export`](config.md) |
| `config` | `get` | [`config.get`](config.md) · [`ogit.config.email.get`](ogit.md) · [`ogit.config.get`](ogit.md) · [`ossh.config.field.get`](ossh.md) · [`ossh.config.get`](ossh.md) · [`private.config.chain.names.get`](config.md) · [`private.config.host.container.name.get`](config.md) · [`private.config.host.name.get`](config.md) · [`private.config.linked.homes.get`](config.md) · [`private.config.oosh.session.file.get`](config.md) · [`private.config.path.line.absolute.get`](config.md) · [`private.config.path.line.get`](config.md) · [`private.config.path.segments.get`](config.md) · [`private.config.pm.command.get`](config.md) · [`private.config.required.file.path.get`](config.md) · [`private.config.required.variables.get`](config.md) · [`private.config.user.session.file.get`](config.md) · [`private.ossh.config.block.put.get`](ossh.md) · [`private.ossh.config.field.get`](ossh.md) · [`private.ossh.config.field.keyword.get`](ossh.md) · [`private.ossh.config.forwardAgent.get`](ossh.md) · [`private.ossh.config.hostName.get`](ossh.md) · [`private.ossh.config.identitiesOnly.get`](ossh.md) · [`private.ossh.config.identityFile.get`](ossh.md) · [`private.ossh.config.last.file.get`](ossh.md) · [`private.ossh.config.port.get`](ossh.md) · [`private.ossh.config.proxyJump.get`](ossh.md) · [`private.ossh.config.user.get`](ossh.md) · [`private.ossh.system.config.file.get`](ossh.md) · [`private.test.suite.config.stamp.get`](test.suite.md) |
| `config` | `init` | [`config.init`](config.md) · [`config.init.env`](config.md) · [`config.init.full`](config.md) · [`config.init.shared`](config.md) · [`config.init.user`](config.md) · [`otmux.config.init`](otmux.md) |
| `config` | `is` | [`private.config.oosh.session.split.is`](config.md) · [`private.config.session.split.is`](config.md) |
| `config` | `isolate` | [`test.suite.config.isolate`](test.suite.md) |
| `config` | `list` | [`backup.config.list`](backup.md) · [`backup.config.list.all`](backup.md) · [`config.list`](config.md) · [`ossh.config.list`](ossh.md) · [`private.config.homes.list`](config.md) · [`private.config.variables.list`](config.md) |
| `config` | `load` | [`private.certificates.update.config.load`](ossh.md) · [`private.pdca.config.load`](scrumMaster.md) · [`private.promote.config.load`](promote.md) |
| `config` | `log` | [`config.info.log`](config.md) · [`private.config.derive.log.level`](config.md) |
| `config` | `migrate` | [`private.config.log.chain.migrate`](config.md) · [`private.config.oosh.session.migrate`](config.md) · [`private.config.user.session.migrate`](config.md) |
| `config` | `normalize` | [`private.ossh.folder.fix.config.normalize`](ossh.md) |
| `config` | `parse` | [`ossh.config.parse`](ossh.md) · [`ossh.config.parse.url`](ossh.md) |
| `config` | `pull` | [`ossh.config.pull`](ossh.md) · [`private.ossh.config.pull`](ossh.md) |
| `config` | `push` | [`ossh.config.push`](ossh.md) · [`private.ossh.config.push`](ossh.md) |
| `config` | `quote` | [`config.string.quote`](config.md) |
| `config` | `read` | [`private.certificates.update.config.read`](ossh.md) |
| `config` | `refresh` | [`private.config.host.name.refresh`](config.md) |
| `config` | `register` | [`backup.config.register`](backup.md) · [`backup.config.register.existing`](backup.md) |
| `config` | `repair` | [`backup.config.repair`](backup.md) · [`private.os.platform.shared.config.repair`](os.md) |
| `config` | `reset` | [`otmux.config.reset`](otmux.md) |
| `config` | `resolve` | [`private.config.file.resolve`](config.md) |
| `config` | `restore` | [`test.suite.config.restore`](test.suite.md) |
| `config` | `save` | [`backup.config.save`](backup.md) · [`config.save`](config.md) · [`config.session.save`](config.md) · [`ossh.config.save.last`](ossh.md) · [`private.config.save`](config.md) · [`private.pdca.config.save`](scrumMaster.md) · [`private.promote.config.save`](promote.md) |
| `config` | `seed` | [`ossh.config.shared.seed.fallback`](ossh.md) · [`ossh.config.shared.seed.github`](ossh.md) |
| `config` | `set` | [`config.set`](config.md) · [`config.ssh.host.set`](config.md) · [`ogit.config.set`](ogit.md) · [`ossh.config.set`](ossh.md) · [`otmux.config.set`](otmux.md) · [`otmux.config.set.global`](otmux.md) · [`otmux.config.set.hook`](otmux.md) · [`otmux.config.set.window`](otmux.md) · [`private.ossh.config.field.set`](ossh.md) · [`private.ossh.config.forwardAgent.set`](ossh.md) · [`private.ossh.config.hostName.set`](ossh.md) · [`private.ossh.config.identitiesOnly.set`](ossh.md) · [`private.ossh.config.identityFile.set`](ossh.md) · [`private.ossh.config.port.set`](ossh.md) · [`private.ossh.config.proxyJump.set`](ossh.md) · [`private.ossh.config.user.set`](ossh.md) |
| `config` | `show` | [`ossh.config.show.last`](ossh.md) · [`otmux.config.show`](otmux.md) · [`otmux.config.show.global`](otmux.md) · [`otmux.config.show.hooks`](otmux.md) · [`otmux.config.show.window`](otmux.md) |
| `config` | `source` | [`otmux.config.source`](otmux.md) |
| `config` | `strip` | [`private.ossh.folder.fix.config.strip.legacy`](ossh.md) |
| `config` | `unregister` | [`backup.config.unregister`](backup.md) |
| `config` | `unset` | [`config.unset`](config.md) |
| `config` | `update` | [`config.update`](config.md) |
| `config` | `validate` | [`config.validate`](config.md) · [`config.validate.required`](config.md) · [`this.config.path.validate`](this.md) |
| `config` | `write` | [`private.ossh.config.deploy.write`](ossh.md) |
| `configDir` | `restart` | [`hiveMind.agent.restart`](hivemind.md) · [`hiveMind.team.restart`](hivemind.md) |
| `configFile` | `create` | [`ossh.config.shared.github.create`](ossh.md) |
| `configItem` | `get` | [`ossh.config.field.get`](ossh.md) · [`private.ossh.config.field.get`](ossh.md) · [`private.ossh.config.forwardAgent.get`](ossh.md) · [`private.ossh.config.hostName.get`](ossh.md) · [`private.ossh.config.identitiesOnly.get`](ossh.md) · [`private.ossh.config.identityFile.get`](ossh.md) · [`private.ossh.config.port.get`](ossh.md) · [`private.ossh.config.proxyJump.get`](ossh.md) · [`private.ossh.config.user.get`](ossh.md) |
| `configItem` | `set` | [`ossh.config.set`](ossh.md) · [`private.ossh.config.field.set`](ossh.md) · [`private.ossh.config.forwardAgent.set`](ossh.md) · [`private.ossh.config.hostName.set`](ossh.md) · [`private.ossh.config.identitiesOnly.set`](ossh.md) · [`private.ossh.config.identityFile.set`](ossh.md) · [`private.ossh.config.port.set`](ossh.md) · [`private.ossh.config.proxyJump.set`](ossh.md) · [`private.ossh.config.user.set`](ossh.md) |
| `configPath` |  | [`private.config.session.chain.ready`](config.md) · [`private.otmux.configPath`](otmux.md) |
| `configPath` | `disable` | [`backup.config.disable`](backup.md) |
| `configPath` | `enable` | [`backup.config.enable`](backup.md) |
| `configPath` | `get` | [`private.test.suite.config.stamp.get`](test.suite.md) |
| `configPath` | `is` | [`private.config.oosh.session.split.is`](config.md) · [`private.config.session.split.is`](config.md) |
| `configPath` | `migrate` | [`private.config.log.chain.migrate`](config.md) · [`private.config.oosh.session.migrate`](config.md) · [`private.config.user.session.migrate`](config.md) |
| `configPath` | `register` | [`backup.config.register`](backup.md) |
| `configPath` | `repair` | [`backup.config.repair`](backup.md) · [`private.backup.repair.config`](backup.md) |
| `configPath` | `unregister` | [`backup.config.unregister`](backup.md) |
| `configfile` |  | [`config.file`](config.md) · [`config.location`](config.md) |
| `conflict` | `list` | [`ogit.conflict.list`](ogit.md) |
| `conflict` | `resolve` | [`ogit.conflict.resolve`](ogit.md) |
| `connection` |  | [`ossh.connection.status`](ossh.md) |
| `connection` | `close` | [`ossh.connection.close`](ossh.md) |
| `connection` | `get` | [`private.ossh.connection.error.get`](ossh.md) |
| `connection` | `is` | [`private.ossh.connection.error.network.is`](ossh.md) |
| `connection` | `open` | [`ossh.connection.open`](ossh.md) |
| `consensus` |  | [`claudeFlow.hive.consensus`](claudeFlow.md) |
| `consistency` | `apply` | [`hiveMind.consistency.reconcile.apply`](hivemind.md) |
| `consistency` | `audit` | [`hiveMind.consistency.audit`](hivemind.md) · [`hiveMind.consistency.audit.table`](hivemind.md) |
| `consistency` | `fix` | [`hiveMind.consistency.fix`](hivemind.md) · [`hiveMind.consistency.fix.table`](hivemind.md) |
| `consistency` | `reconcile` | [`hiveMind.consistency.reconcile`](hivemind.md) |
| `consumeSource` |  | [`private.oo.shared.tree.from.local`](oo.md) |
| `container` |  | [`private.odocker.container.name`](odocker.md) · [`private.odocker.container.ports`](odocker.md) · [`private.os.platform.container.id`](os.md) |
| `container` | `add` | [`private.odocker.container.repo.add`](odocker.md) |
| `container` | `clone` | [`odocker.clone`](odocker.md) |
| `container` | `down` | [`odocker.down`](odocker.md) |
| `container` | `enter` | [`odocker.enter`](odocker.md) |
| `container` | `exec` | [`odocker.exec`](odocker.md) · [`odocker.exec.command`](odocker.md) |
| `container` | `get` | [`odocker.container.ip.get`](odocker.md) · [`private.config.host.container.name.get`](config.md) |
| `container` | `install` | [`odocker.install`](odocker.md) · [`private.odocker.container.prereqs.install`](odocker.md) |
| `container` | `is` | [`private.this.container.is`](this.md) |
| `container` | `list` | [`odocker.container.list`](odocker.md) · [`private.odocker.container.list.all`](odocker.md) · [`private.odocker.container.list.findable`](odocker.md) · [`private.odocker.container.list.running`](odocker.md) |
| `container` | `log` | [`odocker.log`](odocker.md) |
| `container` | `new` | [`private.odocker.container.name.new`](odocker.md) |
| `container` | `prune` | [`odocker.prune`](odocker.md) |
| `container` | `remove` | [`odocker.container.remove`](odocker.md) |
| `container` | `rm` | [`odocker.rm`](odocker.md) |
| `container` | `stop` | [`odocker.stop`](odocker.md) |
| `container` | `up` | [`odocker.up`](odocker.md) |
| `containerOrImage` | `find` | [`odocker.file.find`](odocker.md) |
| `content` | `make` | [`private.replace.copy.make`](replace.md) |
| `content` | `probe` | [`private.hiveMind.sweep.ratelimit.probe`](hivemind.md) |
| `content` | `write` | [`private.this.file.write`](this.md) |
| `context` |  | [`claudeCode.context.alert`](claudeCode.md) · [`claudeCode.context.all`](claudeCode.md) · [`claudeCode.context.dashboard`](claudeCode.md) · [`claudeCode.context.jsonl`](claudeCode.md) · [`claudeCode.context.self`](claudeCode.md) · [`claudeCode.context.velocity`](claudeCode.md) · [`claudeCode.context.velocity.byJsonl`](claudeCode.md) · [`claudeCode.context.velocity.byPane`](claudeCode.md) · [`context.lifecycle.status`](context.md) · [`context.schema`](context.md) · [`hiveMind.agent.context.status`](hivemind.md) · [`hiveMind.team.context.status`](hivemind.md) · [`osemvec.context`](osemvec.md) · [`private.claudeCode.context.from.jsonl`](claudeCode.md) · [`private.claudeCode.context.jsonl.lag`](claudeCode.md) · [`private.context.role.to.machine`](context.md) · [`private.hiveMind.context.age`](hivemind.md) · [`private.hiveMind.context.denom.for.target`](hivemind.md) · [`private.hiveMind.context.from.jsonl.reading`](hivemind.md) · [`private.hiveMind.context.key`](hivemind.md) · [`private.hiveMind.context.live.jsonl`](hivemind.md) |
| `context` | `check` | [`claudeCode.context.check`](claudeCode.md) |
| `context` | `compact` | [`context.lifecycle.pre.compact`](context.md) |
| `context` | `ensure` | [`private.hiveMind.context.ensure.dir`](hivemind.md) |
| `context` | `gather` | [`hiveMind.context.gather`](hivemind.md) · [`hiveMind.context.gather.all`](hivemind.md) · [`hiveMind.context.gather.quiet`](hivemind.md) |
| `context` | `get` | [`hiveMind.context.get`](hivemind.md) · [`private.hiveMind.context.get`](hivemind.md) |
| `context` | `init` | [`context.lifecycle.init`](context.md) |
| `context` | `list` | [`private.context.role.list`](context.md) |
| `context` | `measure` | [`scrumMaster.context.measure`](scrumMaster.md) |
| `context` | `parse` | [`private.claudeCode.context.parse`](claudeCode.md) · [`private.hiveMind.context.parse`](hivemind.md) |
| `context` | `read` | [`claudeCode.context.read`](claudeCode.md) · [`claudeCode.context.read.tui`](claudeCode.md) · [`private.claudeCode.context.read.tui`](claudeCode.md) · [`scrumMaster.context.read`](scrumMaster.md) |
| `context` | `record` | [`hiveMind.context.record`](hivemind.md) |
| `context` | `recover` | [`context.lifecycle.recover`](context.md) · [`context.recover`](context.md) |
| `context` | `save` | [`context.lifecycle.save`](context.md) |
| `context` | `set` | [`private.hiveMind.context.set`](hivemind.md) |
| `context` | `validate` | [`context.validate`](context.md) · [`context.validate.all`](context.md) |
| `control` |  | [`otmux.control`](otmux.md) |
| `control` | `get` | [`private.ossh.control.path.get`](ossh.md) · [`private.ossh.control.path.resolved.get`](ossh.md) |
| `copies` | `remove` | [`private.ossh.github.copies.remove`](ossh.md) |
| `copy` | `make` | [`private.replace.copy.make`](replace.md) |
| `copy` | `remove` | [`private.ossh.github.copy.remove`](ossh.md) |
| `core` |  | [`test.suite.core`](test.suite.md) |
| `counters` | `reset` | [`private.test.suite.counters.reset`](test.suite.md) |
| `course` |  | [`academyScript.course`](academyScript.md) |
| `create` | `deploy` | [`myId.create.github.deploy.key`](myId.md) |
| `create` | `install` | [`ossh.create.and.install`](ossh.md) |
| `created` |  | [`private.hiveMind.handler.team.created.teams`](hivemind.md) · [`private.hiveMind.handler.team.created.tronMonitor`](hivemind.md) |
| `ctx` | `refresh` | [`hiveMind.ctx.refresh`](hivemind.md) · [`hiveMind.ctx.refresh.dry`](hivemind.md) · [`private.hiveMind.ctx.refresh.impl`](hivemind.md) |
| `ctxPct` | `set` | [`private.hiveMind.snapshot.set`](hivemind.md) |
| `ctxrefresh` |  | [`private.hiveMind.ctxrefresh.due`](hivemind.md) · [`private.hiveMind.ctxrefresh.statefile`](hivemind.md) |
| `ctxrefresh` | `eval` | [`private.hiveMind.ctxrefresh.eval`](hivemind.md) |
| `ctxrefresh` | `mark` | [`private.hiveMind.ctxrefresh.mark`](hivemind.md) |
| `current` |  | [`claudeCode.session.current`](claudeCode.md) · [`claudeFlow.session.current`](claudeFlow.md) · [`otmux.current`](otmux.md) · [`private.hiveMind.current.session`](hivemind.md) · [`state.current`](state.md) |
| `currentID` | `check` | [`private.itterator.check.all.states.added`](state.md) · [`private.itterator.check.started`](state.md) |
| `currentID` | `find` | [`private.itterator.find`](state.md) |
| `currentID` | `list` | [`private.itterator.list`](state.md) |
| `currentName` | `check` | [`private.itterator.check.all.states.added`](state.md) · [`private.itterator.check.started`](state.md) |
| `currentName` | `find` | [`private.itterator.find`](state.md) |
| `currentName` | `list` | [`private.itterator.list`](state.md) |
| `currentSession` |  | [`private.otmux.size.currentSession`](otmux.md) |
| `currentValue` | `check` | [`private.itterator.check.all.states.added`](state.md) · [`private.itterator.check.started`](state.md) |
| `currentValue` | `find` | [`private.itterator.find`](state.md) |
| `currentValue` | `list` | [`private.itterator.list`](state.md) |
| `custom` |  | [`path.file.custom`](path.md) |
| `cycle` |  | [`hiveMind.cycle.full`](hivemind.md) · [`hiveMind.team.cycle`](hivemind.md) · [`scrumMaster.cycle`](scrumMaster.md) · [`scrumMaster.metrics.cycle`](scrumMaster.md) |
| `cycle` | `complete` | [`private.check.cycle.complete`](scrumMaster.md) |
| `d` |  | [`otmux.d`](otmux.md) |
| `daemon` |  | [`claudeFlow.daemon`](claudeFlow.md) |
| `dangerously` |  | [`claudeCode.dangerously`](claudeCode.md) |
| `darwin` |  | [`disk.image.darwin`](disk.md) · [`ossh.service.status.darwin`](ossh.md) · [`private.os.hostname.info.darwin`](os.md) · [`private.os.service.off.darwin`](os.md) · [`private.os.service.on.darwin`](os.md) · [`private.setup.headless.darwin`](setup.md) · [`private.setup.samba.password.darwin`](setup.md) · [`private.setup.samba.support.darwin`](setup.md) · [`private.setup.vnc.password.darwin`](setup.md) |
| `dashboard` |  | [`claudeCode.context.dashboard`](claudeCode.md) · [`hiveMind.dashboard`](hivemind.md) · [`scrumMaster.dashboard`](scrumMaster.md) |
| `data` | `set` | [`otmux.buffer.set`](otmux.md) |
| `data` | `setBuffer` | [`private.otmux.setBuffer`](otmux.md) |
| `debug` |  | [`debug.onError`](debug.md) · [`debug.onExit`](debug.md) · [`debug.onReturn`](debug.md) · [`debug.stackTrace`](debug.md) · [`debug.v`](debug.md) |
| `debug` | `noop` | [`debug.noop`](debug.md) |
| `debug` | `parse` | [`2c.debug.parse.param`](2c.md) · [`c2.debug.parse.param`](c2.md) |
| `debug` | `removeTrap` | [`debug.removeTrap`](debug.md) |
| `debug` | `setTrap` | [`debug.setTrap`](debug.md) |
| `debug` | `step` | [`debug.step`](debug.md) |
| `debug` | `toggleDebug` | [`debug.toggleDebug`](debug.md) |
| `declaration` |  | [`state.machine.declaration`](state.md) |
| `declaration` | `get` | [`c2.function.declaration.get`](c2.md) |
| `default` |  | [`private.default.config`](otmux.md) |
| `default` | `get` | [`private.odocker.workspaces.default.get`](odocker.md) |
| `defaultColumn1` | `prepend` | [`line.prepend.all`](line.md) |
| `defaultColumn1` | `unify` | [`line.unify`](line.md) |
| `defaultColumnN` | `prepend` | [`line.prepend.all`](line.md) |
| `defaultColumnN` | `unify` | [`line.unify`](line.md) |
| `defaultValue` | `declare` | [`line.param.declare`](line.md) |
| `delete` | `get` | [`private.user.delete.command.get`](user.md) |
| `denom` |  | [`private.hiveMind.context.denom.for.target`](hivemind.md) |
| `denomK` | `record` | [`hiveMind.context.record`](hivemind.md) |
| `denomK` | `set` | [`private.hiveMind.context.set`](hivemind.md) |
| `deploy` | `create` | [`myId.key.deploy.create`](myId.md) |
| `deploy` | `write` | [`private.ossh.config.deploy.write`](ossh.md) |
| `deps` |  | [`opy.deps`](opy.md) |
| `depth` |  | [`private.hiveMind.agent.queue.depth`](hivemind.md) |
| `depthLevel` |  | [`disk.space.used`](disk.md) |
| `derive` | `log` | [`private.config.derive.log.level`](config.md) |
| `descendants` |  | [`private.hiveMind.shell.descendants`](hivemind.md) |
| `description` |  | [`hiveMind.task`](hivemind.md) |
| `description` | `delegate` | [`hiveMind.delegate`](hivemind.md) |
| `description` | `format` | [`c2.function.description.format`](c2.md) |
| `description` | `register` | [`hiveMind.team.register`](hivemind.md) |
| `dest` | `pull` | [`private.ossh.rsync.pull`](ossh.md) |
| `dest` | `rsync` | [`private.ossh.rsync`](ossh.md) |
| `dest` | `scp` | [`ossh.scp`](ossh.md) |
| `destroyed` |  | [`private.hiveMind.handler.team.destroyed.queue`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.registry`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.sessions`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.teams`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.tronMonitor`](hivemind.md) |
| `detailed` |  | [`otmux.tree.detailed`](otmux.md) |
| `details` |  | [`otmux.session.details`](otmux.md) |
| `dev` |  | [`oo.dev.to.testing`](oo.md) · [`private.oo.dev.to.testing`](oo.md) · [`promote.dev.to.testing`](promote.md) |
| `developking` |  | [`osshLayout.role.developking`](osshLayout.md) |
| `device` |  | [`log.device`](log.md) · [`log.live`](log.md) · [`log.live.error`](log.md) · [`log.live.file`](log.md) · [`log.live.result.env`](log.md) · [`log.live.result.txt`](log.md) |
| `device` | `capture` | [`private.log.device.is.capture`](log.md) |
| `device` | `clear` | [`log.clear.liveLog`](log.md) |
| `device` | `is` | [`private.log.device.is.session`](log.md) · [`private.this.device.is.terminal`](this.md) |
| `device` | `probe` | [`private.log.device.probe`](log.md) |
| `diff` | `check` | [`ogit.diff.check`](ogit.md) |
| `diff` | `show` | [`ogit.diff.show`](ogit.md) |
| `diff_lines` | `render` | [`private.hiveMind.audit.render.human`](hivemind.md) · [`private.hiveMind.audit.render.json`](hivemind.md) |
| `dir` |  | [`check.dir`](check.md) · [`ogit.branch.fastForward`](ogit.md) · [`ogit.raw`](ogit.md) · [`private.odocker.workspaces.mine`](odocker.md) · [`private.ogit.gitdir`](ogit.md) · [`private.osshLayout.staged.dir`](osshLayout.md) · [`private.this.oosh.dir.invariant`](this.md) |
| `dir` | `add` | [`ogit.index.add`](ogit.md) · [`ogit.worktree.add`](ogit.md) · [`path.add`](path.md) · [`this.path.add`](this.md) |
| `dir` | `adopt` | [`ogit.branch.adopt`](ogit.md) |
| `dir` | `append` | [`path.append`](path.md) |
| `dir` | `check` | [`ogit.branch.check`](ogit.md) · [`ogit.diff.check`](ogit.md) · [`ogit.repo.check`](ogit.md) · [`ogit.status.check`](ogit.md) · [`ogit.tag.check`](ogit.md) · [`os.platform.parse.check`](os.md) |
| `dir` | `checkout` | [`ogit.branch.checkout`](ogit.md) |
| `dir` | `close` | [`private.test.suite.results.dir.close`](test.suite.md) |
| `dir` | `compare` | [`ogit.branch.compare`](ogit.md) |
| `dir` | `continue` | [`ogit.commit.pick.continue`](ogit.md) |
| `dir` | `count` | [`ogit.commit.count`](ogit.md) |
| `dir` | `create` | [`ogit.commit.create`](ogit.md) · [`ogit.tag.create`](ogit.md) |
| `dir` | `delete` | [`ogit.branch.remote.delete`](ogit.md) · [`ogit.worktree.delete`](ogit.md) |
| `dir` | `diff` | [`backup.diff`](backup.md) · [`backup.full.diff`](backup.md) |
| `dir` | `drop` | [`ogit.stash.drop`](ogit.md) |
| `dir` | `ensure` | [`private.ensure.sharedTree`](this.md) · [`private.this.folder.ensure`](this.md) · [`private.this.shared.top.ensure`](this.md) |
| `dir` | `fetch` | [`ogit.remote.fetch`](ogit.md) |
| `dir` | `find` | [`ogit.branch.find`](ogit.md) · [`ogit.worktree.find`](ogit.md) |
| `dir` | `finish` | [`private.promote.merge.finish`](promote.md) |
| `dir` | `get` | [`backup.backupPath.get`](backup.md) · [`backup.get.backupPath`](backup.md) · [`ogit.branch.get`](ogit.md) · [`ogit.config.email.get`](ogit.md) · [`ogit.config.get`](ogit.md) · [`ogit.merge.base.get`](ogit.md) · [`ogit.remote.url.get`](ogit.md) · [`ogit.repo.root.get`](ogit.md) · [`ogit.stash.top.get`](ogit.md) · [`ogit.tag.latest.get`](ogit.md) · [`private.backup.get.backupPath`](backup.md) · [`private.ogit.umask.get`](ogit.md) · [`private.ogit.worktree.paths.get`](ogit.md) · [`private.oo.checkout.dir.get`](oo.md) · [`private.scrumMaster.metrics.dir.get`](scrumMaster.md) · [`private.this.temp.dir.get`](this.md) |
| `dir` | `grep` | [`ogit.repo.grep`](ogit.md) |
| `dir` | `import` | [`private.ogit.branch.import`](ogit.md) |
| `dir` | `install` | [`agentRoom.install`](agentRoom.md) |
| `dir` | `list` | [`ogit.branch.list`](ogit.md) · [`ogit.conflict.list`](ogit.md) · [`ogit.remote.branch.list`](ogit.md) · [`ogit.repo.files.list`](ogit.md) · [`ogit.tag.list`](ogit.md) · [`ogit.worktree.list`](ogit.md) · [`private.os.shell.files.list`](os.md) |
| `dir` | `merge` | [`ogit.branch.merge`](ogit.md) · [`ogit.merge.abort`](ogit.md) |
| `dir` | `normalize` | [`backup.normalize.all`](backup.md) |
| `dir` | `open` | [`private.test.suite.results.dir.open`](test.suite.md) |
| `dir` | `pathadd` | [`private.pathadd`](path.md) |
| `dir` | `pathrm` | [`private.pathrm`](path.md) |
| `dir` | `pick` | [`ogit.commit.pick`](ogit.md) · [`ogit.commit.pick.abort`](ogit.md) |
| `dir` | `pop` | [`ogit.stash.pop`](ogit.md) |
| `dir` | `prepend` | [`path.prepend`](path.md) |
| `dir` | `prune` | [`ogit.worktree.prune`](ogit.md) |
| `dir` | `pull` | [`ogit.remote.pull`](ogit.md) · [`ossh.dir.pull`](ossh.md) · [`ossh.pull.dir`](ossh.md) · [`private.ossh.dir.pull`](ossh.md) |
| `dir` | `push` | [`ogit.remote.push`](ogit.md) · [`ogit.stash.push`](ogit.md) · [`ossh.dir.push`](ossh.md) · [`ossh.push.dir`](ossh.md) · [`path.push`](path.md) · [`private.ossh.dir.push`](ossh.md) |
| `dir` | `put` | [`path.put`](path.md) |
| `dir` | `remove` | [`backup.sync.and.remove`](backup.md) · [`ogit.index.remove`](ogit.md) · [`path.remove`](path.md) |
| `dir` | `reset` | [`ogit.branch.reset`](ogit.md) |
| `dir` | `resolve` | [`ogit.conflict.resolve`](ogit.md) · [`private.backup.resolve.paths`](backup.md) |
| `dir` | `revert` | [`ogit.commit.revert`](ogit.md) |
| `dir` | `rm` | [`path.rm`](path.md) |
| `dir` | `run` | [`backup.run`](backup.md) · [`backup.run.mv`](backup.md) · [`private.ogit.git.run`](ogit.md) |
| `dir` | `scan` | [`backup.normalize.scan`](backup.md) |
| `dir` | `set` | [`ogit.branch.upstream.set`](ogit.md) · [`ogit.config.set`](ogit.md) · [`ogit.remote.url.set`](ogit.md) |
| `dir` | `share` | [`ogit.repo.share`](ogit.md) · [`private.ogit.fetchhead.share`](ogit.md) · [`private.this.folder.share`](this.md) |
| `dir` | `show` | [`ogit.commit.log.show`](ogit.md) · [`ogit.commit.show`](ogit.md) · [`ogit.diff.show`](ogit.md) · [`ogit.status.show`](ogit.md) |
| `dir` | `sync` | [`backup.verify.sync`](backup.md) |
| `dir` | `validate` | [`this.oosh.dir.validate`](this.md) |
| `dirName` | `resolve` | [`private.oo.mode.resolve.branch`](oo.md) |
| `direction` |  | [`otmux.rp`](otmux.md) · [`otmux.sp`](otmux.md) |
| `direction` | `resize` | [`otmux.pane.resize`](otmux.md) |
| `direction` | `resizePane` | [`private.otmux.resizePane`](otmux.md) |
| `directory` |  | [`check.directory`](check.md) |
| `disallowed` |  | [`claudeCode.tools.disallowed`](claudeCode.md) |
| `disk` |  | [`disk.automount`](disk.md) · [`disk.image`](disk.md) · [`disk.image.darwin`](disk.md) · [`disk.image.linux`](disk.md) · [`disk.name2device`](disk.md) · [`disk.space.free`](disk.md) · [`disk.space.used`](disk.md) · [`odocker.disk`](odocker.md) · [`private.disk.args.error.disk`](disk.md) |
| `disk` | `calc` | [`disk.calc`](disk.md) · [`disk.calc.bytes.from.gb`](disk.md) · [`disk.calc.bytes.from.kb`](disk.md) · [`disk.calc.bytes.from.mb`](disk.md) · [`disk.calc.bytes.from.tb`](disk.md) · [`disk.calc.bytes.to.gb`](disk.md) · [`disk.calc.bytes.to.kb`](disk.md) · [`disk.calc.bytes.to.mb`](disk.md) · [`disk.calc.bytes.to.tb`](disk.md) · [`disk.calc.getBytesInGB`](disk.md) · [`disk.calc.getBytesInKB`](disk.md) · [`disk.calc.getBytesInMB`](disk.md) · [`disk.calc.getBytesInTB`](disk.md) · [`disk.calc.getGB`](disk.md) · [`disk.calc.getKB`](disk.md) · [`disk.calc.getMB`](disk.md) · [`disk.calc.getTB`](disk.md) |
| `disk` | `create` | [`disk.automount.create.config`](disk.md) |
| `disk` | `discover` | [`disk.discover`](disk.md) · [`disk.discover.linux`](disk.md) |
| `disk` | `eject` | [`disk.eject`](disk.md) · [`disk.eject.darwin`](disk.md) |
| `disk` | `find` | [`disk.find`](disk.md) · [`disk.find.dir`](disk.md) · [`disk.find.file`](disk.md) |
| `disk` | `get` | [`disk.get`](disk.md) · [`disk.get.linux`](disk.md) |
| `disk` | `install` | [`disk.install.raid.support`](disk.md) · [`disk.install.samba.support`](disk.md) |
| `disk` | `list` | [`disk.list`](disk.md) · [`disk.list.by`](disk.md) · [`disk.list.byUUID`](disk.md) · [`disk.list.darwin`](disk.md) · [`disk.list.linux`](disk.md) · [`disk.list.result`](disk.md) · [`disk.list.result.bySize`](disk.md) |
| `disk` | `restore` | [`disk.restore.linux`](disk.md) |
| `docker` |  | [`private.odocker.docker.socket.opt`](odocker.md) · [`setup.docker`](setup.md) · [`snet.docker.service.status`](snet.md) |
| `docker` | `add` | [`private.odocker.docker.repo.add`](odocker.md) |
| `docker` | `clone` | [`odocker.clone`](odocker.md) |
| `docker` | `download` | [`private.odocker.docker.repo.download`](odocker.md) |
| `docker` | `get` | [`private.odocker.docker.repo.get`](odocker.md) |
| `docker` | `reset` | [`odocker.reset`](odocker.md) |
| `docker` | `run` | [`odocker.run`](odocker.md) · [`odocker.run.sshd`](odocker.md) |
| `docker` | `up` | [`odocker.up`](odocker.md) |
| `doctor` |  | [`claudeCode.doctor`](claudeCode.md) · [`claudeFlow.doctor`](claudeFlow.md) |
| `dots` |  | [`line.dots`](line.md) |
| `dp` |  | [`otmux.dp`](otmux.md) |
| `dropin` | `remove` | [`private.oo.dropin.remove`](oo.md) |
| `dryRun` | `sync` | [`tronMonitor.sync`](tronMonitor.md) |
| `dst` | `link` | [`otmux.window.link`](otmux.md) |
| `dst` | `linkWindow` | [`private.otmux.linkWindow`](otmux.md) |
| `due` |  | [`private.hiveMind.ctxrefresh.due`](hivemind.md) |
| `each` |  | [`line.each`](line.md) · [`private.line.each`](line.md) |
| `eamdRoot` |  | [`private.eamdRoot`](otest.md) |
| `email` |  | [`osshLayout.id.from.email`](osshLayout.md) · [`private.osshLayout.owner.email`](osshLayout.md) · [`private.osshLayout.staged.email`](osshLayout.md) |
| `email` | `get` | [`ogit.config.email.get`](ogit.md) |
| `email` | `stage` | [`private.ossh.identity.stage.outer.fromRunner`](ossh.md) |
| `embeddings` |  | [`claudeFlow.embeddings`](claudeFlow.md) |
| `end` | `get` | [`private.oo.method.end.get`](oo.md) |
| `engine` |  | [`private.odocker.engine.supported`](odocker.md) |
| `ensure` | `log` | [`private.scrumMaster.velocity.ensure.log`](scrumMaster.md) |
| `entries` | `copy` | [`private.this.folder.entries.copy`](this.md) |
| `entry` |  | [`private.odocker.workspaces.entry.same`](odocker.md) |
| `env` |  | [`2c.env`](2c.md) · [`c2.env`](c2.md) · [`log.live.result.env`](log.md) · [`mycmd.tab.env`](mycmd.md) · [`path.env`](path.md) · [`private.odocker.env.chained`](odocker.md) |
| `env` | `append` | [`private.config.env.line.append`](config.md) |
| `env` | `del` | [`private.hiveMind.env.del`](hivemind.md) |
| `env` | `drop` | [`private.config.env.lines.drop`](config.md) |
| `env` | `get` | [`private.oo.pm.env.get`](oo.md) · [`private.this.env.export.line.get`](this.md) |
| `env` | `set` | [`otmux.env.set`](otmux.md) · [`private.hiveMind.env.set`](hivemind.md) |
| `env` | `show` | [`otmux.env.show`](otmux.md) |
| `envPrefix` | `export` | [`private.config.variables.export`](config.md) |
| `envPrefix` | `list` | [`private.config.variables.list`](config.md) |
| `envVariable` | `get` | [`config.get`](config.md) |
| `envVariable` | `set` | [`config.set`](config.md) |
| `envVariable` | `unset` | [`config.unset`](config.md) |
| `errFile` | `get` | [`private.ossh.connection.error.get`](ossh.md) |
| `error` |  | [`log.live.error`](log.md) · [`osemvec.error`](osemvec.md) · [`private.disk.args.error.disk`](disk.md) |
| `error` | `get` | [`private.ossh.connection.error.get`](ossh.md) |
| `error` | `is` | [`private.ossh.connection.error.network.is`](ossh.md) |
| `errorCount` | `run` | [`scrumMaster.pdca.run`](scrumMaster.md) |
| `errorText` |  | [`osemvec.error`](osemvec.md) |
| `errors` |  | [`scrumMaster.pdca.errors`](scrumMaster.md) |
| `errors` | `list` | [`backup.errors.list`](backup.md) |
| `escape` | `get` | [`private.oo.regex.escape.get`](oo.md) |
| `evaluate` | `measure` | [`scrumMaster.evaluate.measure`](scrumMaster.md) |
| `even` |  | [`otmux.layout.even.h`](otmux.md) · [`otmux.layout.even.v`](otmux.md) |
| `evenH` |  | [`private.otmux.evenH`](otmux.md) |
| `evenV` |  | [`private.otmux.evenV`](otmux.md) |
| `event` | `append` | [`private.hiveMind.events.history.append`](hivemind.md) |
| `eventName` | `emit` | [`hiveMind.protected.events.emit`](hivemind.md) · [`private.hiveMind.events.emit`](hivemind.md) |
| `eventName` | `register` | [`hiveMind.protected.events.register`](hivemind.md) · [`private.hiveMind.events.register`](hivemind.md) |
| `events` |  | [`hiveMind.events.history`](hivemind.md) |
| `events` | `append` | [`private.hiveMind.events.history.append`](hivemind.md) |
| `events` | `emit` | [`hiveMind.protected.events.emit`](hivemind.md) · [`private.hiveMind.events.emit`](hivemind.md) |
| `events` | `list` | [`hiveMind.events.list`](hivemind.md) |
| `events` | `register` | [`hiveMind.protected.events.register`](hivemind.md) · [`private.hiveMind.events.register`](hivemind.md) |
| `exactLine` |  | [`replace.line`](replace.md) · [`replace.lines`](replace.md) |
| `example` |  | [`line.example.chevron`](line.md) |
| `excludes` | `sweep` | [`private.this.marker.sweep`](this.md) |
| `execute` | `test` | [`mycmd.execute.logging.test`](mycmd.md) |
| `existingName` |  | [`this.function.partial`](this.md) |
| `expects` |  | [`private.test.suite.verdict`](test.suite.md) |
| `export` | `get` | [`private.this.env.export.line.get`](this.md) |
| `extended` |  | [`test.suite.extended`](test.suite.md) |
| `extraFlags` | `rsync` | [`private.backup.rsync`](backup.md) |
| `extraPorts` | `harden` | [`ossh.harden.firewall`](ossh.md) |
| `family` |  | [`private.config.session.chain.ready`](config.md) |
| `fastForward` |  | [`ogit.branch.fastForward`](ogit.md) |
| `feature1` |  | [`mycmd.feature1`](mycmd.md) |
| `feature2` |  | [`mycmd.feature2`](mycmd.md) |
| `feature3` |  | [`mycmd.feature3`](mycmd.md) |
| `featureBranchPrefix` | `check` | [`oo.branches.check`](oo.md) |
| `fetchhead` | `share` | [`private.ogit.fetchhead.share`](ogit.md) |
| `field` | `get` | [`ossh.config.field.get`](ossh.md) · [`private.odocker.docker.repo.get`](odocker.md) · [`private.ossh.config.field.get`](ossh.md) · [`private.ossh.config.field.keyword.get`](ossh.md) · [`private.this.path.stat.get`](this.md) |
| `field` | `set` | [`ossh.config.set`](ossh.md) · [`private.ossh.config.field.set`](ossh.md) |
| `file` |  | [`check.file`](check.md) · [`config.file`](config.md) · [`log.live.file`](log.md) · [`otmux.config`](otmux.md) · [`path.file.custom`](path.md) · [`path.file.global`](path.md) · [`path.file.user`](path.md) · [`private.ossh.validConfigBlock`](ossh.md) · [`private.test.suite.category`](test.suite.md) · [`private.this.file.same`](this.md) · [`replace.block`](replace.md) · [`replace.by.file`](replace.md) · [`replace.line`](replace.md) · [`replace.lines`](replace.md) · [`replace.word`](replace.md) |
| `file` | `append` | [`private.config.env.line.append`](config.md) |
| `file` | `check` | [`config.file.check`](config.md) |
| `file` | `commit` | [`replace.commit`](replace.md) |
| `file` | `del` | [`private.hiveMind.env.del`](hivemind.md) |
| `file` | `delete` | [`ossh.config.delete`](ossh.md) |
| `file` | `download` | [`private.odocker.docker.repo.download`](odocker.md) · [`private.this.url.download`](this.md) |
| `file` | `drop` | [`private.config.env.lines.drop`](config.md) |
| `file` | `edit` | [`ossh.config.edit`](ossh.md) · [`path.file.user.edit`](path.md) |
| `file` | `ensure` | [`private.config.session.file.ensure`](config.md) · [`private.ensure.groupWrite`](this.md) · [`private.this.file.line.ensure`](this.md) |
| `file` | `export` | [`claudeFlow.memory.export`](claudeFlow.md) |
| `file` | `find` | [`odocker.file.find`](odocker.md) · [`private.odocker.compose.file.find`](odocker.md) |
| `file` | `get` | [`ossh.config.get`](ossh.md) · [`ossh.file.get.name`](ossh.md) · [`ossh.id.file.get`](ossh.md) · [`private.config.chain.names.get`](config.md) · [`private.config.oosh.session.file.get`](config.md) · [`private.config.required.file.path.get`](config.md) · [`private.config.user.session.file.get`](config.md) · [`private.oo.method.end.get`](oo.md) · [`private.os.release.get`](os.md) · [`private.ossh.config.field.get`](ossh.md) · [`private.ossh.config.last.file.get`](ossh.md) · [`private.ossh.get.config`](ossh.md) · [`private.ossh.remote.key.file.name.get`](ossh.md) · [`private.ossh.system.config.file.get`](ossh.md) · [`private.test.suite.results.file.get`](test.suite.md) · [`private.test.suite.shared.waiver.get`](test.suite.md) · [`private.this.group.file.get`](this.md) |
| `file` | `import` | [`claudeFlow.memory.import`](claudeFlow.md) · [`claudeFlow.session.import`](claudeFlow.md) |
| `file` | `list` | [`backup.file.list.notBackedUp`](backup.md) · [`backup.file.list.onlyInBackup`](backup.md) · [`backup.file.list.onlyInSource`](backup.md) · [`backup.file.list.onlyInTarget`](backup.md) · [`backup.file.list.same`](backup.md) · [`ossh.config.list`](ossh.md) · [`osx.file.metadata.list`](osx.md) · [`private.backup.file.list.notBackedUp`](backup.md) · [`private.backup.file.list.onlyInBackup`](backup.md) · [`private.backup.file.list.onlyInSource`](backup.md) · [`private.backup.file.list.onlyInTarget`](backup.md) · [`private.backup.file.list.same`](backup.md) |
| `file` | `load` | [`otmux.buffer.load`](otmux.md) · [`path.load`](path.md) |
| `file` | `loadBuffer` | [`private.otmux.loadBuffer`](otmux.md) |
| `file` | `make` | [`private.replace.copy.make`](replace.md) |
| `file` | `pull` | [`ossh.config.pull`](ossh.md) · [`ossh.id.pull`](ossh.md) · [`ossh.pull.config`](ossh.md) · [`ossh.pull.id`](ossh.md) · [`private.ossh.config.pull`](ossh.md) · [`private.ossh.pull.id`](ossh.md) |
| `file` | `push` | [`user.ssh.rootkey.file.push`](user.md) |
| `file` | `recover` | [`claudeCode.session.recover`](claudeCode.md) |
| `file` | `register` | [`osemvec.register`](osemvec.md) |
| `file` | `resolve` | [`ogit.conflict.resolve`](ogit.md) · [`private.config.file.resolve`](config.md) |
| `file` | `revoke` | [`user.ssh.rootkey.file.revoke`](user.md) |
| `file` | `rollback` | [`replace.rollback`](replace.md) |
| `file` | `save` | [`claudeCode.session.save`](claudeCode.md) · [`ossh.config.save.last`](ossh.md) · [`otmux.buffer.save`](otmux.md) · [`path.file.user.save`](path.md) |
| `file` | `saveBuffer` | [`private.otmux.saveBuffer`](otmux.md) |
| `file` | `set` | [`path.file.user.set`](path.md) · [`private.hiveMind.env.set`](hivemind.md) · [`private.ossh.config.field.set`](ossh.md) |
| `file` | `source` | [`otmux.config.source`](otmux.md) · [`otmux.source`](otmux.md) |
| `file` | `use` | [`line.use`](line.md) |
| `file` | `validate` | [`context.validate`](context.md) |
| `file` | `write` | [`private.this.file.write`](this.md) |
| `fileA` |  | [`private.this.file.same`](this.md) |
| `fileB` |  | [`private.this.file.same`](this.md) |
| `filename` | `normalize` | [`backup.normalize.filename`](backup.md) |
| `filename` | `transfer` | [`private.hiveMind.task.transfer`](hivemind.md) |
| `filepath` | `normalize` | [`backup.normalize.file`](backup.md) |
| `filepath` | `revert` | [`backup.normalize.revert`](backup.md) |
| `files` |  | [`mycmd.tab.files`](mycmd.md) |
| `files` | `ensure` | [`private.config.session.files.ensure.all`](config.md) |
| `files` | `get` | [`private.test.suite.session.files.get`](test.suite.md) |
| `files` | `list` | [`ogit.repo.files.list`](ogit.md) · [`private.os.shell.files.list`](os.md) |
| `first` |  | [`private.oo.sed.first`](oo.md) |
| `firstArg` |  | [`this.function.partial`](this.md) |
| `fix` | `check` | [`ossh.folder.fix.check`](ossh.md) |
| `fix` | `execute` | [`private.check.fix.execute`](check.md) |
| `fix` | `normalize` | [`private.ossh.folder.fix.config.normalize`](ossh.md) |
| `fix` | `prune` | [`private.ossh.folder.fix.prune`](ossh.md) |
| `fix` | `scan` | [`private.ossh.folder.fix.scan.git.remotes`](ossh.md) |
| `fix` | `strip` | [`private.ossh.folder.fix.config.strip.legacy`](ossh.md) |
| `fixture` | `make` | [`test.suite.fixture.make`](test.suite.md) |
| `floor` | `apply` | [`otmux.window.size.floor.apply`](otmux.md) |
| `folder` |  | [`private.ogit.folder.gate`](ogit.md) · [`private.ogit.folder.shape`](ogit.md) |
| `folder` | `check` | [`ossh.folder.fix.check`](ossh.md) · [`private.oo.layout.folder.check`](oo.md) |
| `folder` | `clone` | [`private.ogit.clone.gate`](ogit.md) |
| `folder` | `copy` | [`private.this.folder.entries.copy`](this.md) |
| `folder` | `create` | [`ossh.key.folder.create`](ossh.md) |
| `folder` | `delete` | [`ossh.key.folder.delete`](ossh.md) |
| `folder` | `ensure` | [`private.this.folder.ensure`](this.md) |
| `folder` | `finish` | [`ogit.folder.finish`](ogit.md) |
| `folder` | `fix` | [`ossh.folder.fix`](ossh.md) |
| `folder` | `normalize` | [`private.ossh.folder.fix.config.normalize`](ossh.md) |
| `folder` | `prune` | [`private.ossh.folder.fix.prune`](ossh.md) |
| `folder` | `restore` | [`private.ogit.folder.ignored.restore`](ogit.md) |
| `folder` | `save` | [`private.ogit.folder.ignored.save`](ogit.md) |
| `folder` | `scan` | [`private.ossh.folder.fix.scan.git.remotes`](ossh.md) |
| `folder` | `share` | [`private.this.folder.share`](this.md) |
| `folder` | `strip` | [`private.ossh.folder.fix.config.strip.legacy`](ossh.md) |
| `folderLink` | `replace` | [`backup.folderLink.replace.by`](backup.md) |
| `folderLinks` | `replace` | [`backup.folderLinks.replace.same.with`](backup.md) |
| `folders` |  | [`2c.folders`](2c.md) · [`c2.folders`](c2.md) · [`mycmd.tab.folders`](mycmd.md) |
| `folders` | `create` | [`ossh.key.folders.create`](ossh.md) |
| `folders` | `delete` | [`ossh.key.folders.delete`](ossh.md) |
| `folders` | `list` | [`private.ogit.base.folders.list`](ogit.md) |
| `for` |  | [`private.claudeCode.max.tokens.for.jsonl`](claudeCode.md) · [`private.hiveMind.context.denom.for.target`](hivemind.md) · [`private.hiveMind.pane.for.agent`](hivemind.md) |
| `force` | `update` | [`line.format.force.update`](line.md) |
| `forked` |  | [`private.hiveMind.handler.agent.forked.forks`](hivemind.md) · [`private.hiveMind.handler.agent.forked.registry`](hivemind.md) · [`private.hiveMind.handler.agent.forked.sessions`](hivemind.md) |
| `forks` |  | [`private.hiveMind.handler.agent.forked.forks`](hivemind.md) |
| `form` | `get` | [`private.config.path.segments.get`](config.md) · [`private.this.host.name.get`](this.md) |
| `format` | `init` | [`private.line.format.init`](line.md) |
| `format` | `save` | [`private.line.format.save`](line.md) |
| `format` | `update` | [`line.format.force.update`](line.md) |
| `formats` | `edit` | [`line.formats.edit`](line.md) |
| `forwardAgent` | `get` | [`private.ossh.config.forwardAgent.get`](ossh.md) |
| `forwardAgent` | `set` | [`private.ossh.config.forwardAgent.set`](ossh.md) |
| `fqdn` | `get` | [`private.ossh.host.fqdn.get`](ossh.md) |
| `free` |  | [`disk.space.free`](disk.md) |
| `from` |  | [`backup.from`](backup.md) · [`osshLayout.id.from.email`](osshLayout.md) · [`private.claudeCode.context.from.jsonl`](claudeCode.md) · [`private.hiveMind.context.from.jsonl.reading`](hivemind.md) · [`private.oo.shared.tree.from.local`](oo.md) · [`private.os.platform.image.from.workspace`](os.md) · [`promote.branch.alignment`](promote.md) |
| `from` | `compare` | [`ogit.branch.compare`](ogit.md) |
| `from` | `copy` | [`private.this.folder.entries.copy`](this.md) |
| `from` | `count` | [`ogit.commit.count`](ogit.md) |
| `from` | `delegate` | [`hiveMind.delegate`](hivemind.md) |
| `from` | `deploy` | [`ossh.config.shared.seed.from.local.deploy.key`](ossh.md) |
| `from` | `find` | [`line.find`](line.md) |
| `from` | `seed` | [`odocker.workspace.seed`](odocker.md) |
| `fromHost` | `get` | [`private.ossh.remote.key.file.name.get`](ossh.md) |
| `fromHost` | `pull` | [`ossh.config.pull`](ossh.md) · [`ossh.dir.pull`](ossh.md) · [`ossh.id.pull`](ossh.md) · [`ossh.key.pull`](ossh.md) · [`ossh.pull.config`](ossh.md) · [`ossh.pull.dir`](ossh.md) · [`ossh.pull.id`](ossh.md) · [`ossh.pull.key`](ossh.md) · [`private.ossh.config.pull`](ossh.md) · [`private.ossh.dir.pull`](ossh.md) · [`private.ossh.key.pull`](ossh.md) · [`private.ossh.pull.id`](ossh.md) |
| `fromPane` |  | [`hiveMind.protected.pane.moved`](hivemind.md) |
| `fromPath` |  | [`backup.from`](backup.md) |
| `fromPath` | `source` | [`backup.source`](backup.md) |
| `fromTitle` |  | [`private.hiveMind.role.fromTitle`](hivemind.md) |
| `full` |  | [`hiveMind.cycle.full`](hivemind.md) · [`status.scope.full`](status.md) · [`this.scope.full`](this.md) |
| `full` | `diff` | [`backup.full.diff`](backup.md) |
| `fullScreenName` |  | [`private.tronMonitor.fullScreenName`](tronMonitor.md) |
| `function` |  | [`this.caller.function`](this.md) · [`this.function.partial`](this.md) |
| `function` | `find` | [`line.function.find`](line.md) |
| `function` | `format` | [`c2.function.description.format`](c2.md) |
| `function` | `get` | [`c2.function.declaration.get`](c2.md) · [`c2.function.get.with.documentation`](c2.md) · [`c2.function.parameter.get`](c2.md) |
| `functionExists` |  | [`this.functionExists`](this.md) |
| `functionName` | `find` | [`line.find.function`](line.md) · [`line.function.find`](line.md) |
| `functionName` | `get` | [`line.get.parameter`](line.md) · [`line.parameter.get`](line.md) |
| `functionNameFilter` | `format` | [`2c.format.functions`](2c.md) · [`c2.format.functions`](c2.md) · [`c2.function.description.format`](c2.md) · [`c2.functions.format`](c2.md) · [`private.c2.format.functions`](c2.md) |
| `functionNameFilter` | `get` | [`2c.get.function.with.documentation`](2c.md) · [`2c.get.functions`](2c.md) · [`c2.function.get.with.documentation`](c2.md) · [`c2.functions.get`](c2.md) · [`c2.get.formated.function.description`](c2.md) · [`c2.get.function.with.documentation`](c2.md) · [`c2.get.functions`](c2.md) · [`private.c2.get.formated.function.description`](c2.md) · [`private.c2.get.function.with.documentation`](c2.md) · [`private.c2.get.functions`](c2.md) |
| `functions` | `format` | [`c2.functions.format`](c2.md) |
| `functions` | `get` | [`c2.functions.get`](c2.md) |
| `gate` |  | [`private.ogit.folder.gate`](ogit.md) · [`private.promote.notests.gate`](promote.md) · [`private.setup.gate`](setup.md) · [`test.suite.gate`](test.suite.md) |
| `get` | `prompt` | [`private.hiveMind.get.role.prompt`](hivemind.md) |
| `gid` | `check` | [`private.odocker.socket.gid.check`](odocker.md) |
| `gid` | `create` | [`private.this.group.create`](this.md) · [`user.create`](user.md) |
| `gid` | `get` | [`private.this.group.name.get`](this.md) |
| `git` | `commit` | [`hiveMind.git.commit`](hivemind.md) |
| `git` | `get` | [`private.ogit.git.reason.get`](ogit.md) |
| `git` | `run` | [`private.ogit.git.run`](ogit.md) |
| `gitdir` |  | [`private.ogit.gitdir`](ogit.md) |
| `github` | `create` | [`ossh.config.shared.github.create`](ossh.md) |
| `github` | `deploy` | [`myId.create.github.deploy.key`](myId.md) |
| `github` | `is` | [`private.ossh.github.block.is.oosh`](ossh.md) |
| `github` | `remove` | [`private.ossh.github.copies.remove`](ossh.md) · [`private.ossh.github.copy.remove`](ossh.md) |
| `githubUrl` | `create` | [`myId.key.deploy.create`](myId.md) |
| `githubUrl` | `deploy` | [`myId.create.github.deploy.key`](myId.md) |
| `global` |  | [`path.file.global`](path.md) |
| `group` |  | [`private.user.group.member.pending`](user.md) |
| `group` | `add` | [`user.group.add`](user.md) |
| `group` | `check` | [`user.group.check`](user.md) |
| `group` | `create` | [`private.this.group.create`](this.md) |
| `group` | `ensure` | [`private.odocker.socket.group.ensure`](odocker.md) |
| `group` | `exists` | [`private.this.group.exists`](this.md) |
| `group` | `get` | [`private.this.group.file.get`](this.md) · [`private.this.group.members.get`](this.md) · [`private.this.group.name.get`](this.md) |
| `group` | `is` | [`private.user.group.member.is`](user.md) |
| `groupFile` | `get` | [`private.this.group.members.get`](this.md) |
| `groupName` | `add` | [`user.group.add`](user.md) |
| `groupName` | `check` | [`private.user.check.group`](user.md) · [`user.check.group`](user.md) · [`user.group.check`](user.md) |
| `groupName` | `create` | [`private.this.group.create`](this.md) |
| `groupName` | `exists` | [`private.this.group.exists`](this.md) |
| `groupName` | `get` | [`private.this.group.members.get`](this.md) |
| `groupname` |  | [`c2.groups`](c2.md) |
| `groups` |  | [`2c.groups`](2c.md) · [`c2.groups`](c2.md) · [`mycmd.tab.groups`](mycmd.md) |
| `h` |  | [`otmux.layout.even.h`](otmux.md) · [`otmux.layout.main.h`](otmux.md) |
| `h` | `render` | [`private.hiveMind.audit.render.human`](hivemind.md) · [`private.hiveMind.audit.render.json`](hivemind.md) |
| `haiku` |  | [`claudeCode.haiku`](claudeCode.md) |
| `handler` |  | [`private.hiveMind.handler.agent.forked.forks`](hivemind.md) · [`private.hiveMind.handler.agent.forked.registry`](hivemind.md) · [`private.hiveMind.handler.agent.forked.sessions`](hivemind.md) · [`private.hiveMind.handler.agent.killed.queue`](hivemind.md) · [`private.hiveMind.handler.agent.killed.registry`](hivemind.md) · [`private.hiveMind.handler.agent.killed.sessions`](hivemind.md) · [`private.hiveMind.handler.agent.renamed.registry`](hivemind.md) · [`private.hiveMind.handler.agent.renamed.role_env`](hivemind.md) · [`private.hiveMind.handler.agent.renamed.title`](hivemind.md) · [`private.hiveMind.handler.agent.spawned.registry`](hivemind.md) · [`private.hiveMind.handler.agent.spawned.sessions`](hivemind.md) · [`private.hiveMind.handler.pane.moved.registry`](hivemind.md) · [`private.hiveMind.handler.pane.moved.role_env`](hivemind.md) · [`private.hiveMind.handler.panes.shifted.registry`](hivemind.md) · [`private.hiveMind.handler.panes.swapped.registry`](hivemind.md) · [`private.hiveMind.handler.panes.swapped.role_env`](hivemind.md) · [`private.hiveMind.handler.team.created.teams`](hivemind.md) · [`private.hiveMind.handler.team.created.tronMonitor`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.queue`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.registry`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.sessions`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.teams`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.tronMonitor`](hivemind.md) · [`private.hiveMind.handler.team.restored.teams`](hivemind.md) · [`private.hiveMind.handler.team.restored.tronMonitor`](hivemind.md) · [`private.osemvec.pss`](osemvec.md) |
| `handlerFunction` | `register` | [`hiveMind.protected.events.register`](hivemind.md) · [`private.hiveMind.events.register`](hivemind.md) |
| `handoff` |  | [`hiveMind.agent.handoff`](hivemind.md) · [`hiveMind.handoff`](hivemind.md) |
| `hash` | `decode` | [`private.claudeCode.decode.projectHash`](claudeCode.md) |
| `heading` |  | [`line.table`](line.md) |
| `headless` |  | [`otest.here`](otest.md) · [`private.setup.headless.darwin`](setup.md) · [`private.setup.headless.linux`](setup.md) · [`setup.headless`](setup.md) · [`setup.status.headless`](setup.md) |
| `headless` | `enable` | [`setup.headless.enable`](setup.md) |
| `headless` | `run` | [`otest.run`](otest.md) |
| `headless` | `setup` | [`private.check.headless.setup.finished`](oo.md) · [`private.check.headless.setup.started`](oo.md) |
| `headless` | `updateGolden` | [`otest.updateGolden`](otest.md) |
| `health` |  | [`agentRoom.health`](agentRoom.md) · [`claudeFlow.agent.health`](claudeFlow.md) · [`claudeFlow.mcp.health`](claudeFlow.md) |
| `health` | `check` | [`private.scrumMaster.health.check`](scrumMaster.md) · [`scrumMaster.health.check`](scrumMaster.md) |
| `health` | `evaluate` | [`private.scrumMaster.health.evaluate`](scrumMaster.md) · [`scrumMaster.health.evaluate`](scrumMaster.md) |
| `health` | `measure` | [`scrumMaster.health.measure`](scrumMaster.md) |
| `height` | `apply` | [`otmux.window.size.floor.apply`](otmux.md) |
| `height` | `lock` | [`otmux.size.lock`](otmux.md) · [`otmux.window.size.lock`](otmux.md) |
| `height` | `set` | [`otmux.pane.size.set`](otmux.md) · [`private.otmux.size.lock.set`](otmux.md) |
| `here` |  | [`backup.here`](backup.md) · [`otest.here`](otest.md) |
| `history` |  | [`hiveMind.events.history`](hivemind.md) · [`otmux.pane.history`](otmux.md) · [`scrumMaster.velocity.history`](scrumMaster.md) |
| `history` | `append` | [`private.hiveMind.events.history.append`](hivemind.md) |
| `history` | `clear` | [`otmux.pane.history.clear`](otmux.md) |
| `hive` |  | [`claudeFlow.hive`](claudeFlow.md) · [`claudeFlow.hive.consensus`](claudeFlow.md) · [`claudeFlow.hive.memory`](claudeFlow.md) · [`claudeFlow.hive.status`](claudeFlow.md) · [`claudeFlow.hive.task`](claudeFlow.md) |
| `hive` | `broadcast` | [`claudeFlow.hive.broadcast`](claudeFlow.md) |
| `hive` | `init` | [`claudeFlow.hive.init`](claudeFlow.md) |
| `hive` | `join` | [`claudeFlow.hive.join`](claudeFlow.md) |
| `hive` | `leave` | [`claudeFlow.hive.leave`](claudeFlow.md) |
| `hive` | `list` | [`claudeFlow.hive.list`](claudeFlow.md) |
| `hive` | `optimize` | [`claudeFlow.hive.optimize`](claudeFlow.md) |
| `hive` | `shutdown` | [`claudeFlow.hive.shutdown`](claudeFlow.md) |
| `hive` | `spawn` | [`claudeFlow.hive.spawn`](claudeFlow.md) |
| `hiveMind` |  | [`hiveMind.agent.context.status`](hivemind.md) · [`hiveMind.agent.handoff`](hivemind.md) · [`hiveMind.agent.option`](hivemind.md) · [`hiveMind.agent.snapshot`](hivemind.md) · [`hiveMind.claude`](hivemind.md) · [`hiveMind.cycle.full`](hivemind.md) · [`hiveMind.dashboard`](hivemind.md) · [`hiveMind.events.history`](hivemind.md) · [`hiveMind.handoff`](hivemind.md) · [`hiveMind.improvement`](hivemind.md) · [`hiveMind.metrics.summary`](hivemind.md) · [`hiveMind.panes`](hivemind.md) · [`hiveMind.protected.agents.offline`](hivemind.md) · [`hiveMind.protected.live.tupleset`](hivemind.md) · [`hiveMind.protected.pane.moved`](hivemind.md) · [`hiveMind.protected.panes.shifted`](hivemind.md) · [`hiveMind.protected.panes.swapped`](hivemind.md) · [`hiveMind.protected.session.renamed`](hivemind.md) · [`hiveMind.queen`](hivemind.md) · [`hiveMind.role.uuid`](hivemind.md) · [`hiveMind.roles`](hivemind.md) · [`hiveMind.status`](hivemind.md) · [`hiveMind.task`](hivemind.md) · [`hiveMind.team.active`](hivemind.md) · [`hiveMind.team.context.status`](hivemind.md) · [`hiveMind.team.cycle`](hivemind.md) · [`hiveMind.team.status`](hivemind.md) · [`hiveMind.watchdog`](hivemind.md) · [`hiveMind.watchdog.status`](hivemind.md) · [`hiveMind.watchdog.supervisor`](hivemind.md) · [`hiveMind.workers`](hivemind.md) · [`private.hiveMind.active.team`](hivemind.md) · [`private.hiveMind.agent.overlay.key`](hivemind.md) · [`private.hiveMind.agent.queue.depth`](hivemind.md) · [`private.hiveMind.agent.queue.path`](hivemind.md) · [`private.hiveMind.claude.processes`](hivemind.md) · [`private.hiveMind.context.age`](hivemind.md) · [`private.hiveMind.context.denom.for.target`](hivemind.md) · [`private.hiveMind.context.from.jsonl.reading`](hivemind.md) · [`private.hiveMind.context.key`](hivemind.md) · [`private.hiveMind.context.live.jsonl`](hivemind.md) · [`private.hiveMind.ctxrefresh.due`](hivemind.md) · [`private.hiveMind.ctxrefresh.statefile`](hivemind.md) · [`private.hiveMind.current.session`](hivemind.md) · [`private.hiveMind.handler.agent.forked.forks`](hivemind.md) · [`private.hiveMind.handler.agent.forked.registry`](hivemind.md) · [`private.hiveMind.handler.agent.forked.sessions`](hivemind.md) · [`private.hiveMind.handler.agent.killed.queue`](hivemind.md) · [`private.hiveMind.handler.agent.killed.registry`](hivemind.md) · [`private.hiveMind.handler.agent.killed.sessions`](hivemind.md) · [`private.hiveMind.handler.agent.renamed.registry`](hivemind.md) · [`private.hiveMind.handler.agent.renamed.role_env`](hivemind.md) · [`private.hiveMind.handler.agent.renamed.title`](hivemind.md) · [`private.hiveMind.handler.agent.spawned.registry`](hivemind.md) · [`private.hiveMind.handler.agent.spawned.sessions`](hivemind.md) · [`private.hiveMind.handler.pane.moved.registry`](hivemind.md) · [`private.hiveMind.handler.pane.moved.role_env`](hivemind.md) · [`private.hiveMind.handler.panes.shifted.registry`](hivemind.md) · [`private.hiveMind.handler.panes.swapped.registry`](hivemind.md) · [`private.hiveMind.handler.panes.swapped.role_env`](hivemind.md) · [`private.hiveMind.handler.team.created.teams`](hivemind.md) · [`private.hiveMind.handler.team.created.tronMonitor`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.queue`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.registry`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.sessions`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.teams`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.tronMonitor`](hivemind.md) · [`private.hiveMind.handler.team.restored.teams`](hivemind.md) · [`private.hiveMind.handler.team.restored.tronMonitor`](hivemind.md) · [`private.hiveMind.live.tupleset`](hivemind.md) · [`private.hiveMind.live.tupleset.remote`](hivemind.md) · [`private.hiveMind.liveUuid`](hivemind.md) · [`private.hiveMind.pane.activity`](hivemind.md) · [`private.hiveMind.pane.for.agent`](hivemind.md) · [`private.hiveMind.pane.kind`](hivemind.md) · [`private.hiveMind.pane.model`](hivemind.md) · [`private.hiveMind.role.fromTitle`](hivemind.md) · [`private.hiveMind.shell.descendants`](hivemind.md) · [`private.hiveMind.snapshot.jsonl.path`](hivemind.md) · [`private.hiveMind.snapshot.row.valid`](hivemind.md) · [`private.hiveMind.team.host`](hivemind.md) · [`private.hiveMind.workers.legacy`](hivemind.md) |
| `hiveMind` | `activate` | [`hiveMind.team.activate`](hivemind.md) |
| `hiveMind` | `append` | [`private.hiveMind.events.history.append`](hivemind.md) |
| `hiveMind` | `apply` | [`hiveMind.consistency.reconcile.apply`](hivemind.md) · [`private.hiveMind.reconcile.apply`](hivemind.md) |
| `hiveMind` | `approve` | [`hiveMind.agent.approve`](hivemind.md) · [`hiveMind.monitor.approve`](hivemind.md) |
| `hiveMind` | `attach` | [`hiveMind.attach`](hivemind.md) |
| `hiveMind` | `audit` | [`hiveMind.consistency.audit`](hivemind.md) · [`hiveMind.consistency.audit.table`](hivemind.md) · [`hiveMind.team.audit`](hivemind.md) |
| `hiveMind` | `bootstrap` | [`hiveMind.agent.bootstrap`](hivemind.md) |
| `hiveMind` | `broadcast` | [`hiveMind.broadcast`](hivemind.md) |
| `hiveMind` | `check` | [`private.hiveMind.reconcile.check.i1`](hivemind.md) · [`private.hiveMind.reconcile.check.i10`](hivemind.md) · [`private.hiveMind.reconcile.check.i2`](hivemind.md) · [`private.hiveMind.reconcile.check.i3`](hivemind.md) · [`private.hiveMind.reconcile.check.i4`](hivemind.md) · [`private.hiveMind.reconcile.check.i5`](hivemind.md) · [`private.hiveMind.reconcile.check.i6`](hivemind.md) · [`private.hiveMind.reconcile.check.i7`](hivemind.md) · [`private.hiveMind.reconcile.check.i8`](hivemind.md) · [`private.hiveMind.reconcile.check.i9`](hivemind.md) · [`private.hiveMind.snapshot.version.check`](hivemind.md) |
| `hiveMind` | `classify` | [`private.hiveMind.shell.classify`](hivemind.md) |
| `hiveMind` | `clear` | [`hiveMind.agent.queue.clear`](hivemind.md) · [`hiveMind.agent.state.clear`](hivemind.md) · [`hiveMind.team.state.clear`](hivemind.md) · [`private.hiveMind.state.clear`](hivemind.md) |
| `hiveMind` | `commit` | [`hiveMind.auto.commit`](hivemind.md) · [`hiveMind.git.commit`](hivemind.md) |
| `hiveMind` | `compact` | [`hiveMind.peer.compact`](hivemind.md) |
| `hiveMind` | `complete` | [`private.hiveMind.roles.complete`](hivemind.md) · [`private.hiveMind.teams.complete`](hivemind.md) |
| `hiveMind` | `count` | [`private.hiveMind.pane.count`](hivemind.md) |
| `hiveMind` | `create` | [`hiveMind.pane.create`](hivemind.md) · [`hiveMind.plan.create`](hivemind.md) · [`private.hiveMind.create.agent.pane`](hivemind.md) |
| `hiveMind` | `del` | [`private.hiveMind.env.del`](hivemind.md) |
| `hiveMind` | `delegate` | [`hiveMind.delegate`](hivemind.md) · [`hiveMind.task.delegate`](hivemind.md) |
| `hiveMind` | `detach` | [`hiveMind.detach`](hivemind.md) |
| `hiveMind` | `detect` | [`private.hiveMind.sweep.detect`](hivemind.md) |
| `hiveMind` | `diff` | [`hiveMind.protected.reconcile.diff`](hivemind.md) · [`private.hiveMind.reconcile.diff`](hivemind.md) |
| `hiveMind` | `discover` | [`hiveMind.discover`](hivemind.md) · [`hiveMind.protected.agents.discover`](hivemind.md) · [`private.hiveMind.live.discover`](hivemind.md) · [`private.hiveMind.live.discover.session`](hivemind.md) |
| `hiveMind` | `dismiss` | [`hiveMind.agent.dismiss`](hivemind.md) |
| `hiveMind` | `dispatch` | [`private.hiveMind.agent.overlay.dispatch`](hivemind.md) |
| `hiveMind` | `drain` | [`hiveMind.agent.queue.drain`](hivemind.md) |
| `hiveMind` | `emit` | [`hiveMind.protected.events.emit`](hivemind.md) · [`private.hiveMind.events.emit`](hivemind.md) |
| `hiveMind` | `enqueue` | [`private.hiveMind.agent.queue.enqueue`](hivemind.md) |
| `hiveMind` | `ensure` | [`private.hiveMind.context.ensure.dir`](hivemind.md) · [`private.hiveMind.ensure.pane`](hivemind.md) · [`private.hiveMind.snapshots.ensure.dir`](hivemind.md) · [`private.hiveMind.teams.ensure.dir`](hivemind.md) |
| `hiveMind` | `enter` | [`hiveMind.send.enter`](hivemind.md) |
| `hiveMind` | `escape` | [`private.hiveMind.audit.json.escape`](hivemind.md) |
| `hiveMind` | `eval` | [`private.hiveMind.ctxrefresh.eval`](hivemind.md) |
| `hiveMind` | `find` | [`private.hiveMind.find.agents.dir`](hivemind.md) · [`private.hiveMind.registry.find`](hivemind.md) |
| `hiveMind` | `fix` | [`hiveMind.consistency.fix`](hivemind.md) · [`hiveMind.consistency.fix.table`](hivemind.md) · [`hiveMind.fix.path`](hivemind.md) · [`hiveMind.path.fix`](hivemind.md) · [`hiveMind.registry.fix`](hivemind.md) |
| `hiveMind` | `focus` | [`hiveMind.focus`](hivemind.md) · [`hiveMind.pane.focus`](hivemind.md) |
| `hiveMind` | `fork` | [`hiveMind.agent.fork.best`](hivemind.md) |
| `hiveMind` | `gather` | [`hiveMind.context.gather`](hivemind.md) · [`hiveMind.context.gather.all`](hivemind.md) · [`hiveMind.context.gather.quiet`](hivemind.md) |
| `hiveMind` | `get` | [`hiveMind.agent.state.get`](hivemind.md) · [`hiveMind.context.get`](hivemind.md) · [`private.hiveMind.context.get`](hivemind.md) · [`private.hiveMind.get.agent.port`](hivemind.md) · [`private.hiveMind.get.agents`](hivemind.md) · [`private.hiveMind.registry.get`](hivemind.md) · [`private.hiveMind.snapshot.get`](hivemind.md) · [`private.hiveMind.state.get`](hivemind.md) |
| `hiveMind` | `help` | [`hiveMind.help`](hivemind.md) |
| `hiveMind` | `identify` | [`private.hiveMind.pane.identify`](hivemind.md) |
| `hiveMind` | `import` | [`hiveMind.protected.team.import`](hivemind.md) |
| `hiveMind` | `improve` | [`hiveMind.plan.improve`](hivemind.md) |
| `hiveMind` | `inform` | [`private.hiveMind.agent.inform`](hivemind.md) |
| `hiveMind` | `init` | [`hiveMind.init`](hivemind.md) · [`hiveMind.oosh.init`](hivemind.md) · [`hiveMind.team.init.oosh`](hivemind.md) |
| `hiveMind` | `isGeneric` | [`private.hiveMind.role.isGeneric`](hivemind.md) |
| `hiveMind` | `isRecent` | [`private.hiveMind.registry.isRecent`](hivemind.md) |
| `hiveMind` | `join` | [`hiveMind.join`](hivemind.md) |
| `hiveMind` | `kill` | [`hiveMind.kill`](hivemind.md) |
| `hiveMind` | `list` | [`hiveMind.agent.queue.list`](hivemind.md) · [`hiveMind.events.list`](hivemind.md) · [`hiveMind.list`](hivemind.md) · [`hiveMind.process.list`](hivemind.md) · [`hiveMind.registry.list`](hivemind.md) · [`hiveMind.role.list`](hivemind.md) · [`hiveMind.roles.list.uuids`](hivemind.md) · [`hiveMind.snapshot.list`](hivemind.md) · [`hiveMind.snapshots.list`](hivemind.md) · [`hiveMind.team.list`](hivemind.md) · [`hiveMind.team.models.list`](hivemind.md) · [`private.hiveMind.list.panes`](hivemind.md) · [`private.hiveMind.registry.list`](hivemind.md) |
| `hiveMind` | `log` | [`hiveMind.metrics.log`](hivemind.md) |
| `hiveMind` | `lookup` | [`hiveMind.process.lookup`](hivemind.md) · [`private.hiveMind.session.lookup`](hivemind.md) |
| `hiveMind` | `loop` | [`hiveMind.pane.sweep.loop`](hivemind.md) · [`hiveMind.sweep.loop`](hivemind.md) · [`hiveMind.team.loop`](hivemind.md) |
| `hiveMind` | `mark` | [`private.hiveMind.ctxrefresh.mark`](hivemind.md) |
| `hiveMind` | `migrate` | [`hiveMind.team.migrate`](hivemind.md) · [`hiveMind.teams.migrate`](hivemind.md) · [`private.hiveMind.registry.migrate`](hivemind.md) · [`private.hiveMind.sessions.migrate`](hivemind.md) |
| `hiveMind` | `monitor` | [`hiveMind.agent.monitor`](hivemind.md) · [`hiveMind.agent.monitor.cycle`](hivemind.md) · [`hiveMind.monitor`](hivemind.md) · [`hiveMind.monitor.cycle`](hivemind.md) · [`hiveMind.team.monitor`](hivemind.md) |
| `hiveMind` | `parse` | [`private.hiveMind.context.parse`](hivemind.md) |
| `hiveMind` | `probe` | [`hiveMind.agent.session.probe`](hivemind.md) · [`private.hiveMind.sweep.ratelimit.probe`](hivemind.md) |
| `hiveMind` | `prompt` | [`hiveMind.role.prompt`](hivemind.md) · [`private.hiveMind.get.role.prompt`](hivemind.md) |
| `hiveMind` | `prune` | [`hiveMind.snapshots.prune`](hivemind.md) |
| `hiveMind` | `pull` | [`hiveMind.team.pull`](hivemind.md) |
| `hiveMind` | `push` | [`hiveMind.team.push`](hivemind.md) · [`private.hiveMind.push.agent`](hivemind.md) · [`private.hiveMind.push.captureForkedUUID`](hivemind.md) · [`private.hiveMind.push.preflight`](hivemind.md) · [`private.hiveMind.push.resolveCanonical`](hivemind.md) |
| `hiveMind` | `pushRoleEnv` | [`private.hiveMind.pane.pushRoleEnv`](hivemind.md) |
| `hiveMind` | `reap` | [`hiveMind.shell.reap`](hivemind.md) · [`hiveMind.shell.reap.dry`](hivemind.md) · [`private.hiveMind.shell.reap.impl`](hivemind.md) |
| `hiveMind` | `reconcile` | [`hiveMind.consistency.reconcile`](hivemind.md) |
| `hiveMind` | `record` | [`hiveMind.context.record`](hivemind.md) |
| `hiveMind` | `recover` | [`hiveMind.cold.recover`](hivemind.md) · [`hiveMind.team.recover`](hivemind.md) |
| `hiveMind` | `refresh` | [`hiveMind.ctx.refresh`](hivemind.md) · [`hiveMind.ctx.refresh.dry`](hivemind.md) · [`hiveMind.registry.refresh`](hivemind.md) · [`private.hiveMind.ctx.refresh.impl`](hivemind.md) |
| `hiveMind` | `register` | [`hiveMind.protected.events.register`](hivemind.md) · [`hiveMind.team.register`](hivemind.md) · [`private.hiveMind.events.register`](hivemind.md) |
| `hiveMind` | `reject` | [`hiveMind.agent.reject`](hivemind.md) |
| `hiveMind` | `remove` | [`hiveMind.registry.remove`](hivemind.md) · [`hiveMind.team.remove`](hivemind.md) |
| `hiveMind` | `rename` | [`hiveMind.agent.rename`](hivemind.md) |
| `hiveMind` | `render` | [`private.hiveMind.audit.render.human`](hivemind.md) · [`private.hiveMind.audit.render.json`](hivemind.md) |
| `hiveMind` | `resolve` | [`hiveMind.protected.identity.resolve`](hivemind.md) · [`hiveMind.resolve`](hivemind.md) · [`private.hiveMind.agent.queue.resolve`](hivemind.md) · [`private.hiveMind.channel.resolve`](hivemind.md) · [`private.hiveMind.identity.resolve`](hivemind.md) · [`private.hiveMind.resolve.alias`](hivemind.md) · [`private.hiveMind.session.resolve.uuid`](hivemind.md) |
| `hiveMind` | `respawn` | [`hiveMind.agent.respawn`](hivemind.md) |
| `hiveMind` | `restart` | [`hiveMind.agent.restart`](hivemind.md) · [`hiveMind.agent.restart.remote`](hivemind.md) · [`hiveMind.team.restart`](hivemind.md) |
| `hiveMind` | `restore` | [`hiveMind.teams.restore`](hivemind.md) |
| `hiveMind` | `rewind` | [`hiveMind.agent.rewind`](hivemind.md) |
| `hiveMind` | `route` | [`private.hiveMind.agent.route`](hivemind.md) |
| `hiveMind` | `save` | [`hiveMind.teams.save`](hivemind.md) |
| `hiveMind` | `send` | [`hiveMind.agent.send`](hivemind.md) · [`hiveMind.send`](hivemind.md) · [`hiveMind.send.message`](hivemind.md) |
| `hiveMind` | `set` | [`hiveMind.agent.state.set`](hivemind.md) · [`hiveMind.registry.set`](hivemind.md) · [`hiveMind.team.host.set`](hivemind.md) · [`hiveMind.team.state.set`](hivemind.md) · [`private.hiveMind.context.set`](hivemind.md) · [`private.hiveMind.env.set`](hivemind.md) · [`private.hiveMind.registry.set`](hivemind.md) · [`private.hiveMind.snapshot.set`](hivemind.md) · [`private.hiveMind.state.set`](hivemind.md) |
| `hiveMind` | `setup` | [`hiveMind.team.setup`](hivemind.md) · [`hiveMind.team.setup.full`](hivemind.md) · [`hiveMind.team.setup.oosh`](hivemind.md) |
| `hiveMind` | `spawn` | [`hiveMind.agent.spawn`](hivemind.md) · [`hiveMind.spawn`](hivemind.md) |
| `hiveMind` | `stop` | [`hiveMind.watchdog.stop`](hivemind.md) |
| `hiveMind` | `store` | [`private.hiveMind.session.store`](hivemind.md) · [`private.hiveMind.session.store.deferred`](hivemind.md) |
| `hiveMind` | `sweep` | [`hiveMind.pane.sweep`](hivemind.md) · [`hiveMind.pane.sweep.cycle`](hivemind.md) · [`hiveMind.sweep`](hivemind.md) · [`hiveMind.sweep.cycle`](hivemind.md) · [`hiveMind.team.sweep`](hivemind.md) · [`private.hiveMind.sweep.bgshells`](hivemind.md) · [`private.hiveMind.sweep.paneState`](hivemind.md) |
| `hiveMind` | `switch` | [`hiveMind.team.switch`](hivemind.md) · [`private.hiveMind.monitor.switch`](hivemind.md) |
| `hiveMind` | `teach` | [`hiveMind.role.teach`](hivemind.md) · [`hiveMind.teach`](hivemind.md) |
| `hiveMind` | `train` | [`hiveMind.agent.train`](hivemind.md) · [`hiveMind.train`](hivemind.md) |
| `hiveMind` | `transfer` | [`private.hiveMind.task.transfer`](hivemind.md) |
| `hiveMind` | `unblock` | [`hiveMind.agent.unblock`](hivemind.md) · [`hiveMind.unblock`](hivemind.md) · [`private.hiveMind.agent.unblock.pane`](hivemind.md) · [`private.hiveMind.unblock.pane`](hivemind.md) |
| `hiveMind` | `verify` | [`hiveMind.agent.verify`](hivemind.md) |
| `hiveMind` | `wait` | [`private.hiveMind.wait.for.claude`](hivemind.md) |
| `home` | `backup` | [`user.ssh.backup.status`](user.md) |
| `home` | `get` | [`private.config.oosh.session.file.get`](config.md) · [`private.config.user.session.file.get`](config.md) |
| `home` | `migrate` | [`private.oo.once.path.migrate`](oo.md) · [`user.ssh.backup.migrate`](user.md) |
| `homes` | `get` | [`private.config.linked.homes.get`](config.md) · [`private.ossh.user.homes.get`](ossh.md) |
| `homes` | `list` | [`private.config.homes.list`](config.md) |
| `hook` | `set` | [`otmux.config.set.hook`](otmux.md) |
| `hook` | `setHook` | [`private.otmux.setHook`](otmux.md) |
| `hooks` |  | [`claudeFlow.hooks`](claudeFlow.md) |
| `host` |  | [`ossh.connection.status`](ossh.md) · [`private.hiveMind.live.tupleset.remote`](hivemind.md) · [`private.hiveMind.team.host`](hivemind.md) · [`private.ossh.hostKnown`](ossh.md) · [`private.ossh.ssh`](ossh.md) |
| `host` | `close` | [`ossh.connection.close`](ossh.md) |
| `host` | `fetch` | [`private.odocker.workspaces.fetch.ssh`](odocker.md) |
| `host` | `get` | [`private.config.host.container.name.get`](config.md) · [`private.config.host.name.get`](config.md) · [`private.odocker.workspaces.source.host.get`](odocker.md) · [`private.ossh.control.path.resolved.get`](ossh.md) · [`private.ossh.host.fqdn.get`](ossh.md) · [`private.this.host.name.get`](this.md) |
| `host` | `load` | [`private.certificates.update.config.load`](ossh.md) |
| `host` | `open` | [`ossh.connection.open`](ossh.md) |
| `host` | `push` | [`hiveMind.team.push`](hivemind.md) · [`private.hiveMind.push.agent`](hivemind.md) · [`private.hiveMind.push.captureForkedUUID`](hivemind.md) · [`private.hiveMind.push.preflight`](hivemind.md) |
| `host` | `put` | [`private.ossh.remote.public.key.put`](ossh.md) |
| `host` | `refresh` | [`private.config.host.name.refresh`](config.md) |
| `host` | `remove` | [`ossh.known.hosts.remove`](ossh.md) |
| `host` | `restart` | [`hiveMind.agent.restart.remote`](hivemind.md) |
| `host` | `run` | [`private.certificates.update.ssh.run`](ossh.md) |
| `host` | `serve` | [`osemvec.serve`](osemvec.md) |
| `host` | `set` | [`config.ssh.host.set`](config.md) · [`hiveMind.team.host.set`](hivemind.md) |
| `host` | `update` | [`private.certificates.update.machine.name`](ossh.md) |
| `hostAlias` | `scan` | [`private.ossh.folder.fix.scan.git.remotes`](ossh.md) |
| `hostKnown` |  | [`private.ossh.hostKnown`](ossh.md) |
| `hostName` | `get` | [`private.ossh.config.hostName.get`](ossh.md) |
| `hostName` | `set` | [`private.ossh.config.hostName.set`](ossh.md) |
| `hostname` |  | [`os.hostname.info`](os.md) · [`private.os.hostname.info.darwin`](os.md) · [`private.os.hostname.info.linux`](os.md) |
| `hostname` | `get` | [`os.hostname.get`](os.md) · [`private.os.hostname.get.darwin`](os.md) · [`private.os.hostname.get.linux`](os.md) |
| `hostname` | `set` | [`os.hostname.set`](os.md) · [`private.os.hostname.set.darwin`](os.md) · [`private.os.hostname.set.linux`](os.md) |
| `hosts` | `get` | [`private.ossh.system.known.hosts.get`](ossh.md) |
| `hosts` | `remove` | [`ossh.known.hosts.remove`](ossh.md) |
| `i` |  | [`claudeFlow.i`](claudeFlow.md) |
| `id` |  | [`claudeCode.session.id`](claudeCode.md) · [`osshLayout.id.from.email`](osshLayout.md) · [`parameterTestScript.apostropheDesc`](parameterTestScript.md) · [`parameterTestScript.optional`](parameterTestScript.md) · [`parameterTestScript.optionalDefaultValue`](parameterTestScript.md) · [`private.os.platform.container.id`](os.md) · [`state.id`](state.md) · [`user.id`](user.md) |
| `id` | `create` | [`ossh.id.create`](ossh.md) · [`ossh.id.create.fromKey`](ossh.md) |
| `id` | `get` | [`ossh.get.public.id`](ossh.md) · [`ossh.id.file.get`](ossh.md) · [`ossh.id.public.get`](ossh.md) · [`ossh.publicId.get`](ossh.md) · [`private.ossh.get.public.id`](ossh.md) |
| `id` | `list` | [`myId.list`](myId.md) · [`ossh.list.ids`](ossh.md) |
| `id` | `pull` | [`ossh.id.pull`](ossh.md) |
| `id` | `push` | [`ossh.id.push`](ossh.md) · [`ossh.push.id`](ossh.md) · [`private.ossh.id.push`](ossh.md) |
| `idName` | `create` | [`myId.key.deploy.create`](myId.md) · [`ossh.id.create`](ossh.md) · [`ossh.id.create.fromKey`](ossh.md) |
| `idName` | `deploy` | [`myId.create.github.deploy.key`](myId.md) |
| `idOrProxyJump` | `create` | [`ossh.config.create`](ossh.md) |
| `identitiesOnly` | `create` | [`ossh.config.create`](ossh.md) |
| `identitiesOnly` | `get` | [`private.ossh.config.identitiesOnly.get`](ossh.md) |
| `identitiesOnly` | `set` | [`private.ossh.config.identitiesOnly.set`](ossh.md) |
| `identity` |  | [`private.ogit.identity`](ogit.md) |
| `identity` | `resolve` | [`hiveMind.protected.identity.resolve`](hivemind.md) · [`private.hiveMind.identity.resolve`](hivemind.md) |
| `identity` | `stage` | [`private.ossh.identity.stage`](ossh.md) · [`private.ossh.identity.stage.outer.fromRunner`](ossh.md) · [`private.ossh.identity.stage.outer.proxyJump`](ossh.md) |
| `identityFile` | `get` | [`private.ossh.config.identityFile.get`](ossh.md) |
| `identityFile` | `set` | [`private.ossh.config.identityFile.set`](ossh.md) |
| `if` |  | [`otmux.if`](otmux.md) |
| `ignored` | `restore` | [`private.ogit.folder.ignored.restore`](ogit.md) |
| `ignored` | `save` | [`private.ogit.folder.ignored.save`](ogit.md) |
| `image` |  | [`disk.image`](disk.md) · [`disk.image.darwin`](disk.md) · [`disk.image.linux`](disk.md) · [`odocker.image.command`](odocker.md) · [`private.os.platform.image.from.workspace`](os.md) |
| `image` | `create` | [`odocker.create`](odocker.md) |
| `image` | `exists` | [`private.os.platform.image.exists`](os.md) |
| `image` | `list` | [`odocker.image.list`](odocker.md) · [`private.odocker.image.list`](odocker.md) · [`private.odocker.image.list.findable`](odocker.md) |
| `image` | `new` | [`private.odocker.container.name.new`](odocker.md) |
| `image` | `remove` | [`odocker.image.remove`](odocker.md) |
| `image` | `reset` | [`odocker.reset`](odocker.md) |
| `image` | `resolve` | [`private.odocker.image.resolve.from.workspace`](odocker.md) |
| `image` | `rmi` | [`odocker.rmi`](odocker.md) |
| `image` | `run` | [`odocker.run`](odocker.md) · [`odocker.run.sshd`](odocker.md) |
| `imageFile` |  | [`disk.image`](disk.md) |
| `imageFile` | `restore` | [`disk.restore.linux`](disk.md) |
| `imageTag` | `exists` | [`private.os.platform.image.exists`](os.md) |
| `improvement` |  | [`hiveMind.improvement`](hivemind.md) |
| `in` |  | [`private.scrumMaster.subscription.resets.in`](scrumMaster.md) · [`user.in`](user.md) |
| `index` |  | [`osemvec.index`](osemvec.md) |
| `index` | `add` | [`ogit.index.add`](ogit.md) |
| `index` | `create` | [`index.create.all`](index.md) |
| `index` | `link` | [`index.link.directory`](index.md) |
| `index` | `list` | [`index.list.linkedDirectory`](index.md) |
| `index` | `remove` | [`ogit.index.remove`](ogit.md) |
| `info` |  | [`claudeFlow.task.info`](claudeFlow.md) · [`os.hostname.info`](os.md) · [`os.info`](os.md) · [`otmux.info`](otmux.md) · [`otmux.server.info`](otmux.md) · [`private.os.hostname.info.darwin`](os.md) · [`private.os.hostname.info.linux`](os.md) |
| `info` | `log` | [`config.info.log`](config.md) |
| `init` | `check` | [`config.init.check`](config.md) |
| `init` | `push` | [`private.ossh.oosh.init.push`](ossh.md) |
| `install` | `append` | [`private.log.install.append`](this.md) |
| `install` | `continue` | [`ossh.install.continue.local`](ossh.md) |
| `install` | `create` | [`ossh.install.create`](ossh.md) |
| `install` | `finish` | [`log.install.finish`](log.md) · [`ossh.install.finish.local`](ossh.md) |
| `install` | `get` | [`private.oo.install.branch.get`](oo.md) · [`private.oo.pm.install.prefix.get`](oo.md) |
| `install` | `init` | [`log.install.init`](log.md) |
| `install` | `log` | [`ossh.install.log`](ossh.md) |
| `installer` |  | [`osshLayout.role.installer`](osshLayout.md) |
| `installerEmail` |  | [`osshLayout.role.installer`](osshLayout.md) |
| `installerEmail` | `build` | [`osshLayout.build`](osshLayout.md) |
| `installerEmail` | `fix` | [`ossh.folder.fix`](ossh.md) |
| `installerKeypairSrc` | `build` | [`osshLayout.build`](osshLayout.md) |
| `intent` | `enqueue` | [`private.hiveMind.agent.queue.enqueue`](hivemind.md) |
| `intent` | `register` | [`osemvec.register`](osemvec.md) |
| `interactive` |  | [`claudeFlow.interactive`](claudeFlow.md) |
| `interval` |  | [`hiveMind.watchdog.supervisor`](hivemind.md) · [`scrumMaster.cycle`](scrumMaster.md) |
| `interval` | `loop` | [`hiveMind.team.loop`](hivemind.md) |
| `interval` | `sweep` | [`hiveMind.pane.sweep`](hivemind.md) · [`hiveMind.pane.sweep.cycle`](hivemind.md) · [`hiveMind.sweep`](hivemind.md) · [`hiveMind.sweep.cycle`](hivemind.md) · [`hiveMind.team.sweep`](hivemind.md) |
| `into` |  | [`line.into`](line.md) |
| `invariant` |  | [`private.this.oosh.dir.invariant`](this.md) |
| `invariant` | `diff` | [`hiveMind.protected.reconcile.diff`](hivemind.md) · [`private.hiveMind.reconcile.diff`](hivemind.md) |
| `ip` | `get` | [`odocker.container.ip.get`](odocker.md) · [`ossh.server.ip.get`](ossh.md) · [`ossh.server.ip.get.darwin`](ossh.md) · [`ossh.server.ip.get.linux`](ossh.md) |
| `is` | `capture` | [`private.log.device.is.capture`](log.md) |
| `iteration` |  | [`scrumMaster.pdca.iteration`](scrumMaster.md) |
| `iteratorFunction` | `loop` | [`private.loop.states`](state.md) |
| `itterator` | `check` | [`private.itterator.check.all.states.added`](state.md) · [`private.itterator.check.started`](state.md) |
| `itterator` | `find` | [`private.itterator.find`](state.md) |
| `itterator` | `list` | [`private.itterator.list`](state.md) |
| `job` |  | [`c2.jobs`](c2.md) |
| `jobs` |  | [`2c.jobs`](2c.md) · [`c2.jobs`](c2.md) · [`mycmd.tab.jobs`](mycmd.md) |
| `json` |  | [`claudeCode.json`](claudeCode.md) · [`claudeFlow.json`](claudeFlow.md) · [`scrumMaster.subscription.json`](scrumMaster.md) |
| `json` | `escape` | [`private.hiveMind.audit.json.escape`](hivemind.md) |
| `jsonResponse` | `parse` | [`private.measure.subscription.api.parse`](scrumMaster.md) |
| `json_response` | `parse` | [`private.scrumMaster.subscription.parse`](scrumMaster.md) |
| `jsonl` |  | [`claudeCode.context.jsonl`](claudeCode.md) · [`claudeCode.context.velocity.byJsonl`](claudeCode.md) · [`private.claudeCode.context.from.jsonl`](claudeCode.md) · [`private.claudeCode.context.jsonl.lag`](claudeCode.md) · [`private.claudeCode.max.tokens.for.jsonl`](claudeCode.md) · [`private.hiveMind.context.from.jsonl.reading`](hivemind.md) · [`private.hiveMind.context.live.jsonl`](hivemind.md) · [`private.hiveMind.snapshot.jsonl.path`](hivemind.md) |
| `jsonlFile` |  | [`private.claudeCode.context.jsonl.lag`](claudeCode.md) · [`private.claudeCode.max.tokens.for.jsonl`](claudeCode.md) |
| `jsonlFile` | `calculate` | [`private.claudeCode.velocity.calculate`](claudeCode.md) |
| `key` |  | [`line.key`](line.md) · [`private.hiveMind.agent.overlay.key`](hivemind.md) · [`private.hiveMind.context.key`](hivemind.md) |
| `key` | `bind` | [`otmux.bind`](otmux.md) · [`otmux.key.bind`](otmux.md) |
| `key` | `create` | [`myId.key.deploy.create`](myId.md) · [`ossh.key.folder.create`](ossh.md) · [`ossh.key.folders.create`](ossh.md) |
| `key` | `del` | [`private.hiveMind.env.del`](hivemind.md) |
| `key` | `delete` | [`claudeFlow.memory.delete`](claudeFlow.md) · [`ossh.key.folder.delete`](ossh.md) · [`ossh.key.folders.delete`](ossh.md) |
| `key` | `get` | [`claudeFlow.memory.get`](claudeFlow.md) · [`ogit.config.get`](ogit.md) · [`ossh.key.get.name`](ossh.md) · [`ossh.key.name.get`](ossh.md) · [`private.os.release.get`](os.md) · [`private.ossh.authorized.key.append.get`](ossh.md) · [`private.ossh.remote.key.file.name.get`](ossh.md) · [`private.user.authorized.key.get`](user.md) |
| `key` | `list` | [`otmux.key.list`](otmux.md) |
| `key` | `pull` | [`ossh.key.pull`](ossh.md) · [`private.ossh.key.pull`](ossh.md) |
| `key` | `push` | [`ossh.key.push`](ossh.md) · [`private.ossh.key.push`](ossh.md) |
| `key` | `put` | [`private.ossh.remote.public.key.put`](ossh.md) |
| `key` | `rm` | [`claudeFlow.memory.rm`](claudeFlow.md) |
| `key` | `send` | [`otmux.send.key`](otmux.md) |
| `key` | `set` | [`ogit.config.set`](ogit.md) · [`ossh.key.name.set`](ossh.md) · [`ossh.key.set.name`](ossh.md) · [`private.hiveMind.env.set`](hivemind.md) |
| `key` | `unbind` | [`otmux.key.unbind`](otmux.md) · [`otmux.unbind`](otmux.md) |
| `key1` | `send` | [`otmux.send.tui`](otmux.md) |
| `key1` | `sendKeys` | [`private.otmux.sendKeys`](otmux.md) |
| `key2` | `sendKeys` | [`private.otmux.sendKeys`](otmux.md) |
| `keyFile` | `install` | [`private.ossh.install.key.authorize`](ossh.md) |
| `keyFileName` | `get` | [`private.ossh.authorized.key.append.get`](ossh.md) |
| `keyFileName` | `install` | [`private.ossh.install.key.authorize`](ossh.md) |
| `keyFileName` | `put` | [`private.ossh.remote.public.key.put`](ossh.md) |
| `keyName` | `pull` | [`ossh.pull.key`](ossh.md) |
| `keyName` | `push` | [`ossh.key.push`](ossh.md) · [`ossh.push.key`](ossh.md) · [`private.ossh.key.push`](ossh.md) |
| `keypairSourceDir` |  | [`osshLayout.role.installer`](osshLayout.md) |
| `keys` |  | [`line.keys`](line.md) · [`otmux.keys`](otmux.md) |
| `keys` | `adopt` | [`private.user.authorized.keys.adopt`](user.md) |
| `keys` | `rebuild` | [`private.user.authorized.keys.rebuild`](user.md) |
| `keys` | `send` | [`otmux.send`](otmux.md) · [`otmux.send.keys`](otmux.md) · [`otmux.send.raw`](otmux.md) · [`otmux.send.tui`](otmux.md) |
| `keys` | `update` | [`ossh.authorized.keys.update`](ossh.md) · [`user.authorized.keys.update`](user.md) |
| `keyword` | `get` | [`private.ossh.config.field.keyword.get`](ossh.md) |
| `killed` |  | [`private.hiveMind.handler.agent.killed.queue`](hivemind.md) · [`private.hiveMind.handler.agent.killed.registry`](hivemind.md) · [`private.hiveMind.handler.agent.killed.sessions`](hivemind.md) |
| `kind` |  | [`osx.spotlight.bykind`](osx.md) · [`private.hiveMind.pane.kind`](hivemind.md) |
| `known` | `get` | [`private.ossh.system.known.hosts.get`](ossh.md) |
| `known` | `remove` | [`ossh.known.hosts.remove`](ossh.md) |
| `knownHosts` | `create` | [`ossh.config.shared.github.create`](ossh.md) |
| `knownHosts` | `remove` | [`private.ossh.github.copies.remove`](ossh.md) · [`private.ossh.github.copy.remove`](ossh.md) |
| `knownRoles` |  | [`private.osemvec.knownRoles`](osemvec.md) |
| `kp` |  | [`otmux.kp`](otmux.md) |
| `kw` |  | [`otmux.kw`](otmux.md) |
| `l` | `render` | [`private.hiveMind.audit.render.human`](hivemind.md) · [`private.hiveMind.audit.render.json`](hivemind.md) |
| `label` |  | [`private.os.service.off.darwin`](os.md) · [`private.os.service.on.darwin`](os.md) |
| `label` | `backup` | [`user.ssh.backup`](user.md) |
| `label` | `get` | [`private.this.temp.dir.get`](this.md) |
| `label` | `isolate` | [`test.suite.config.isolate`](test.suite.md) |
| `label` | `make` | [`test.suite.fixture.make`](test.suite.md) |
| `lag` |  | [`private.claudeCode.context.jsonl.lag`](claudeCode.md) |
| `last` |  | [`otmux.last`](otmux.md) · [`otmux.pane.last`](otmux.md) · [`otmux.session.last`](otmux.md) · [`otmux.window.last`](otmux.md) |
| `last` | `diff` | [`backup.list.last.diff.result`](backup.md) |
| `last` | `get` | [`private.ossh.config.last.file.get`](ossh.md) |
| `lastPane` |  | [`private.otmux.lastPane`](otmux.md) |
| `lastWindow` |  | [`private.otmux.lastWindow`](otmux.md) |
| `latest` |  | [`private.opy.latest`](opy.md) |
| `latest` | `get` | [`ogit.tag.latest.get`](ogit.md) |
| `layout` |  | [`claudeFlow.tmux.layout`](claudeFlow.md) · [`ogit.layout.status`](ogit.md) · [`otmux.layout`](otmux.md) · [`otmux.layout.even.h`](otmux.md) · [`otmux.layout.even.v`](otmux.md) · [`otmux.layout.main.h`](otmux.md) · [`otmux.layout.main.v`](otmux.md) · [`otmux.layout.tiled`](otmux.md) |
| `layout` | `check` | [`private.oo.layout.folder.check`](oo.md) |
| `layout` | `delete` | [`otmux.layout.delete`](otmux.md) |
| `layout` | `get` | [`otmux.window.layout.get`](otmux.md) |
| `layout` | `list` | [`otmux.layout.list`](otmux.md) |
| `layout` | `next` | [`otmux.layout.next`](otmux.md) |
| `layout` | `prev` | [`otmux.layout.prev`](otmux.md) |
| `layout` | `restore` | [`otmux.layout.restore`](otmux.md) |
| `layout` | `save` | [`otmux.layout.save`](otmux.md) |
| `layout` | `set` | [`otmux.layout.set`](otmux.md) · [`otmux.window.layout.set`](otmux.md) |
| `layout` | `show` | [`otmux.layout.show`](otmux.md) |
| `leaf` | `validate` | [`private.this.anchor.validate.one`](this.md) |
| `left` |  | [`otmux.left`](otmux.md) · [`otmux.pane.left`](otmux.md) |
| `legacy` |  | [`private.hiveMind.workers.legacy`](hivemind.md) · [`private.scrumMaster.subscription.api.legacy`](scrumMaster.md) |
| `legacy` | `remove` | [`private.ossh.shared.ssh.legacy.remove`](ossh.md) |
| `level` |  | [`log.level`](log.md) · [`test.suite.level`](test.suite.md) |
| `level` | `run` | [`private.test.suite.run.filtered`](test.suite.md) |
| `levelno` |  | [`log.level`](log.md) |
| `lifecycle` |  | [`context.lifecycle.status`](context.md) · [`odocker.lifecycle`](odocker.md) |
| `lifecycle` | `compact` | [`context.lifecycle.pre.compact`](context.md) |
| `lifecycle` | `init` | [`context.lifecycle.init`](context.md) |
| `lifecycle` | `recover` | [`context.lifecycle.recover`](context.md) |
| `lifecycle` | `save` | [`context.lifecycle.save`](context.md) |
| `limit` | `show` | [`ogit.commit.log.show`](ogit.md) |
| `line` |  | [`line.args`](line.md) · [`line.dots`](line.md) · [`line.each`](line.md) · [`line.example.chevron`](line.md) · [`line.into`](line.md) · [`line.key`](line.md) · [`line.keys`](line.md) · [`line.space2`](line.md) · [`line.table`](line.md) · [`line.value`](line.md) · [`line.values`](line.md) · [`private.line.each`](line.md) · [`replace.line`](replace.md) |
| `line` | `add` | [`line.add`](line.md) |
| `line` | `append` | [`private.config.env.line.append`](config.md) |
| `line` | `assign` | [`line.assign`](line.md) |
| `line` | `clean` | [`line.clean.config`](line.md) · [`line.config.clean`](line.md) |
| `line` | `count` | [`line.count`](line.md) |
| `line` | `declare` | [`line.declare`](line.md) · [`line.param.declare`](line.md) |
| `line` | `edit` | [`line.formats.edit`](line.md) |
| `line` | `emit` | [`private.log.emit`](log.md) |
| `line` | `ensure` | [`private.this.file.line.ensure`](this.md) |
| `line` | `filter` | [`line.filter`](line.md) · [`line.filter.comment.shell`](line.md) · [`line.filter.emptyLines`](line.md) |
| `line` | `find` | [`line.find`](line.md) · [`line.find.function`](line.md) · [`line.function.find`](line.md) |
| `line` | `format` | [`line.format`](line.md) · [`line.format.env`](line.md) |
| `line` | `get` | [`line.get.parameter`](line.md) · [`line.parameter.get`](line.md) · [`private.config.path.line.absolute.get`](config.md) · [`private.config.path.line.get`](config.md) · [`private.this.env.export.line.get`](this.md) · [`private.user.authorized.key.get`](user.md) |
| `line` | `init` | [`line.init`](line.md) · [`private.line.format.init`](line.md) |
| `line` | `join` | [`line.join`](line.md) |
| `line` | `new` | [`line.parse.param.new`](line.md) · [`line.parse.paramList.new`](line.md) |
| `line` | `parse` | [`line.parse.param`](line.md) · [`line.parse.paramList`](line.md) |
| `line` | `prepend` | [`line.prepend`](line.md) · [`line.prepend.all`](line.md) |
| `line` | `quote` | [`line.quote`](line.md) |
| `line` | `remove` | [`line.remove`](line.md) · [`line.remove.emptyLines`](line.md) · [`line.remove.exact`](line.md) |
| `line` | `replace` | [`line.replace`](line.md) · [`line.replace.sedquoted`](line.md) |
| `line` | `save` | [`private.line.format.save`](line.md) |
| `line` | `select` | [`line.select`](line.md) |
| `line` | `split` | [`line.split`](line.md) · [`line.split.env`](line.md) · [`line.split.quoted`](line.md) |
| `line` | `strip` | [`line.strip.color`](line.md) |
| `line` | `trim` | [`line.trim`](line.md) · [`line.trim.leading`](line.md) · [`line.trim.quoted`](line.md) · [`line.trim.quoted.leading`](line.md) · [`line.trim.quoted.trailing`](line.md) · [`line.trim.trailing`](line.md) |
| `line` | `unify` | [`line.unify`](line.md) · [`private.line.unify.each`](line.md) · [`private.unify.one`](line.md) |
| `line` | `unquote` | [`line.unquote`](line.md) |
| `line` | `update` | [`line.format.force.update`](line.md) |
| `line` | `use` | [`line.use`](line.md) |
| `lineNumber` | `remove` | [`line.remove`](line.md) |
| `lineNumber` | `select` | [`line.select`](line.md) |
| `lines` |  | [`agentRoom.logs`](agentRoom.md) · [`hiveMind.events.history`](hivemind.md) · [`hiveMind.metrics.summary`](hivemind.md) · [`otmux.pane.history`](otmux.md) · [`replace.lines`](replace.md) · [`scrumMaster.velocity.history`](scrumMaster.md) |
| `lines` | `capture` | [`otmux.pane.capture`](otmux.md) · [`private.tronMonitor.screen.capture`](tronMonitor.md) |
| `lines` | `drop` | [`private.config.env.lines.drop`](config.md) |
| `lines` | `join` | [`private.path.lines.join`](path.md) |
| `lines` | `log` | [`odocker.log`](odocker.md) |
| `lines` | `monitor` | [`hiveMind.agent.monitor`](hivemind.md) · [`hiveMind.team.monitor`](hivemind.md) |
| `linked` | `get` | [`private.config.linked.homes.get`](config.md) |
| `linux` |  | [`disk.image.linux`](disk.md) · [`ossh.service.status.linux`](ossh.md) · [`private.os.hostname.info.linux`](os.md) · [`private.os.service.off.linux`](os.md) · [`private.os.service.on.linux`](os.md) · [`private.setup.headless.linux`](setup.md) · [`private.setup.samba.password.linux`](setup.md) · [`private.setup.samba.support.linux`](setup.md) · [`private.setup.vnc.password.linux`](setup.md) |
| `linux` | `delete` | [`user.linux.delete`](user.md) |
| `linux` | `skip` | [`private.setup.linux.skip`](setup.md) |
| `list` | `diff` | [`backup.list.last.diff.result`](backup.md) |
| `list` | `format` | [`otmux.pane.list.format`](otmux.md) · [`otmux.window.list.format`](otmux.md) |
| `list` | `open` | [`ossh.list.open.ports`](ossh.md) |
| `live` |  | [`hiveMind.protected.live.tupleset`](hivemind.md) · [`log.live`](log.md) · [`log.live.error`](log.md) · [`log.live.file`](log.md) · [`log.live.panes`](log.md) · [`log.live.result.env`](log.md) · [`log.live.result.txt`](log.md) · [`private.hiveMind.context.live.jsonl`](hivemind.md) · [`private.hiveMind.live.tupleset`](hivemind.md) · [`private.hiveMind.live.tupleset.remote`](hivemind.md) |
| `live` | `discover` | [`private.hiveMind.live.discover`](hivemind.md) · [`private.hiveMind.live.discover.session`](hivemind.md) |
| `live` | `stop` | [`log.live.panes.stop`](log.md) |
| `liveUuid` |  | [`private.hiveMind.liveUuid`](hivemind.md) |
| `local` |  | [`private.oo.shared.tree.from.local`](oo.md) |
| `local` | `deploy` | [`ossh.config.shared.seed.from.local.deploy.key`](ossh.md) |
| `local` | `install` | [`private.check.local.install.started`](oo.md) |
| `localEntry` |  | [`private.odocker.workspaces.entry.same`](odocker.md) |
| `localFile` | `put` | [`private.ossh.remote.public.key.put`](ossh.md) |
| `location` |  | [`config.location`](config.md) |
| `lock` | `cleanup` | [`private.otmux.size.lock.cleanup`](otmux.md) |
| `lock` | `has` | [`private.otmux.size.lock.has`](otmux.md) |
| `lock` | `list` | [`private.otmux.size.lock.list`](otmux.md) |
| `lock` | `remove` | [`private.otmux.size.lock.remove`](otmux.md) |
| `lock` | `set` | [`private.otmux.size.lock.set`](otmux.md) |
| `log` |  | [`log.device`](log.md) · [`log.level`](log.md) · [`log.live`](log.md) · [`log.live.error`](log.md) · [`log.live.file`](log.md) · [`log.live.panes`](log.md) · [`log.live.result.env`](log.md) · [`log.live.result.txt`](log.md) · [`log.name`](log.md) · [`log.session`](log.md) |
| `log` | `append` | [`private.log.install.append`](this.md) |
| `log` | `capture` | [`backup.log.capture.mode`](backup.md) · [`log.capture.result`](log.md) · [`log.capture.result.silent`](log.md) · [`private.backup.log.capture.mode`](backup.md) · [`private.log.device.is.capture`](log.md) |
| `log` | `clear` | [`log.clear.all`](log.md) · [`log.clear.liveLog`](log.md) · [`log.clear.screen`](log.md) · [`log.clear.scrollbackBuffer`](log.md) |
| `log` | `cls` | [`log.cls`](log.md) |
| `log` | `emit` | [`private.log.emit`](log.md) |
| `log` | `finish` | [`log.install.finish`](log.md) |
| `log` | `init` | [`log.init`](log.md) · [`log.init.colors`](log.md) · [`log.install.init`](log.md) |
| `log` | `inspect` | [`log.inspect`](log.md) · [`log.inspect.errors`](log.md) |
| `log` | `install` | [`log.install`](log.md) · [`log.install.errors`](log.md) · [`log.install.live`](log.md) |
| `log` | `is` | [`private.log.device.is.session`](log.md) |
| `log` | `migrate` | [`private.config.log.chain.migrate`](config.md) |
| `log` | `probe` | [`private.log.device.probe`](log.md) |
| `log` | `save` | [`log.session.save`](log.md) |
| `log` | `show` | [`ogit.commit.log.show`](ogit.md) |
| `log` | `stop` | [`log.live.panes.stop`](log.md) |
| `log` | `write` | [`private.log.session.write`](log.md) |
| `logging` |  | [`mycmd.logging.tests`](mycmd.md) |
| `logging` | `test` | [`mycmd.execute.logging.test`](mycmd.md) |
| `login` | `get` | [`private.user.login.term.get`](user.md) |
| `logs` |  | [`agentRoom.logs`](agentRoom.md) · [`claudeFlow.agent.logs`](claudeFlow.md) · [`claudeFlow.mcp.logs`](claudeFlow.md) |
| `logs` | `follow` | [`agentRoom.logs.follow`](agentRoom.md) |
| `loop` |  | [`loop.this`](loop.md) |
| `loop` | `list` | [`loop.list`](loop.md) |
| `lower` |  | [`claudeFlow.tmux.lower`](claudeFlow.md) |
| `lsb` |  | [`otmux.lsb`](otmux.md) |
| `lsc` |  | [`otmux.lsc`](otmux.md) |
| `lscm` |  | [`otmux.lscm`](otmux.md) |
| `lsk` |  | [`otmux.lsk`](otmux.md) |
| `lsp` |  | [`otmux.lsp`](otmux.md) |
| `lsw` |  | [`otmux.lsw`](otmux.md) |
| `m` | `render` | [`private.hiveMind.audit.render.human`](hivemind.md) · [`private.hiveMind.audit.render.json`](hivemind.md) |
| `machine` |  | [`private.context.role.to.machine`](context.md) · [`state.id`](state.md) · [`state.machine.declaration`](state.md) · [`state.name`](state.md) · [`state.of`](state.md) |
| `machine` | `add` | [`state.add`](state.md) |
| `machine` | `check` | [`state.check`](state.md) |
| `machine` | `create` | [`state.machine.create`](state.md) |
| `machine` | `delete` | [`state.machine.delete`](state.md) |
| `machine` | `edit` | [`state.machine.edit`](state.md) |
| `machine` | `exists` | [`state.machine.exists`](state.md) |
| `machine` | `find` | [`state.find`](state.md) |
| `machine` | `init` | [`private.certificates.update.state.machine.init`](ossh.md) · [`private.init.state.machine`](oo.md) · [`private.promote.state.machine.init`](promote.md) · [`state.machine.init`](state.md) |
| `machine` | `list` | [`state.list`](state.md) · [`state.machine.list`](state.md) |
| `machine` | `next` | [`state.next`](state.md) |
| `machine` | `rename` | [`state.rename`](state.md) |
| `machine` | `set` | [`state.set`](state.md) |
| `machine` | `stage` | [`state.stage`](state.md) |
| `machine` | `update` | [`private.certificates.update.config.persist`](ossh.md) · [`private.state.machine.update`](state.md) |
| `machineName` |  | [`scrumMaster.pdca.errors`](scrumMaster.md) · [`scrumMaster.pdca.iteration`](scrumMaster.md) · [`scrumMaster.pdca.state`](scrumMaster.md) |
| `machineName` | `next` | [`scrumMaster.pdca.next`](scrumMaster.md) |
| `machineName` | `reset` | [`scrumMaster.pdca.reset`](scrumMaster.md) |
| `machineName` | `run` | [`scrumMaster.pdca.run`](scrumMaster.md) |
| `main` |  | [`claudeFlow.tmux.main`](claudeFlow.md) · [`otmux.layout.main.h`](otmux.md) · [`otmux.layout.main.v`](otmux.md) |
| `mainDir` | `clone` | [`private.ogit.clone.gate`](ogit.md) |
| `mainDir` | `source` | [`private.oo.source.consume.gate`](oo.md) |
| `mainH` |  | [`private.otmux.mainH`](otmux.md) |
| `mainV` |  | [`private.otmux.mainV`](otmux.md) |
| `map` | `create` | [`map.create`](map.md) |
| `map` | `save` | [`map.save`](map.md) |
| `marker` | `sweep` | [`private.this.marker.sweep`](this.md) |
| `markerSlug` | `sweep` | [`private.this.marker.sweep`](this.md) |
| `mathExpression` |  | [`osx.spotlight.by.size`](osx.md) |
| `mathExpression` | `calc` | [`disk.calc`](disk.md) |
| `max` |  | [`claudeCode.turns.max`](claudeCode.md) · [`private.claudeCode.max.tokens.for.jsonl`](claudeCode.md) |
| `mcp` |  | [`claudeCode.mcp`](claudeCode.md) · [`claudeFlow.mcp`](claudeFlow.md) · [`claudeFlow.mcp.health`](claudeFlow.md) · [`claudeFlow.mcp.logs`](claudeFlow.md) · [`claudeFlow.mcp.status`](claudeFlow.md) · [`claudeFlow.mcp.tools`](claudeFlow.md) |
| `mcp` | `exec` | [`claudeFlow.mcp.exec`](claudeFlow.md) |
| `mcp` | `restart` | [`claudeFlow.mcp.restart`](claudeFlow.md) |
| `mcp` | `stop` | [`claudeFlow.mcp.stop`](claudeFlow.md) |
| `mcp` | `toggle` | [`claudeFlow.mcp.toggle`](claudeFlow.md) |
| `mcpJson` |  | [`private.osemvec.mcpJson`](osemvec.md) |
| `measure` | `evaluate` | [`private.scrumMaster.measure.evaluate`](scrumMaster.md) |
| `measure` | `parse` | [`private.measure.subscription.api.parse`](scrumMaster.md) |
| `member` |  | [`private.user.group.member.pending`](user.md) |
| `member` | `is` | [`private.user.group.member.is`](user.md) |
| `members` | `get` | [`private.this.group.members.get`](this.md) |
| `memory` |  | [`claudeFlow.hive.memory`](claudeFlow.md) · [`claudeFlow.memory`](claudeFlow.md) · [`claudeFlow.memory.stats`](claudeFlow.md) |
| `memory` | `cleanup` | [`claudeFlow.memory.cleanup`](claudeFlow.md) |
| `memory` | `compress` | [`claudeFlow.memory.compress`](claudeFlow.md) |
| `memory` | `delete` | [`claudeFlow.memory.delete`](claudeFlow.md) |
| `memory` | `export` | [`claudeFlow.memory.export`](claudeFlow.md) |
| `memory` | `get` | [`claudeFlow.memory.get`](claudeFlow.md) |
| `memory` | `import` | [`claudeFlow.memory.import`](claudeFlow.md) |
| `memory` | `init` | [`claudeFlow.memory.init`](claudeFlow.md) |
| `memory` | `list` | [`claudeFlow.memory.list`](claudeFlow.md) |
| `memory` | `ls` | [`claudeFlow.memory.ls`](claudeFlow.md) |
| `memory` | `rm` | [`claudeFlow.memory.rm`](claudeFlow.md) |
| `memory` | `search` | [`claudeFlow.memory.search`](claudeFlow.md) |
| `memory` | `store` | [`claudeFlow.memory.store`](claudeFlow.md) |
| `menu` |  | [`otmux.menu`](otmux.md) |
| `merge` | `finish` | [`private.promote.merge.finish`](promote.md) |
| `merge` | `get` | [`ogit.merge.base.get`](ogit.md) · [`private.odocker.workspaces.merge.answer.get`](odocker.md) |
| `merge` | `show` | [`private.promote.merge.preview.show`](promote.md) |
| `message` |  | [`agentRoom.chat`](agentRoom.md) · [`check.message`](check.md) · [`otmux.msg`](otmux.md) |
| `message` | `adopt` | [`ogit.branch.adopt`](ogit.md) |
| `message` | `append` | [`claudeCode.system.prompt.append`](claudeCode.md) |
| `message` | `broadcast` | [`claudeFlow.hive.broadcast`](claudeFlow.md) · [`hiveMind.broadcast`](hivemind.md) |
| `message` | `commit` | [`hiveMind.auto.commit`](hivemind.md) · [`hiveMind.git.commit`](hivemind.md) |
| `message` | `create` | [`ogit.commit.create`](ogit.md) |
| `message` | `delegate` | [`hiveMind.task.delegate`](hivemind.md) |
| `message` | `display` | [`otmux.display`](otmux.md) · [`otmux.send.display`](otmux.md) |
| `message` | `enter` | [`hiveMind.send.enter`](hivemind.md) |
| `message` | `finish` | [`private.promote.merge.finish`](promote.md) |
| `message` | `prompt` | [`claudeCode.system.prompt`](claudeCode.md) |
| `message` | `push` | [`ogit.stash.push`](ogit.md) |
| `message` | `send` | [`hiveMind.agent.send`](hivemind.md) · [`hiveMind.send.message`](hivemind.md) |
| `messageBody` | `append` | [`private.log.install.append`](this.md) |
| `metaFailures` |  | [`private.test.suite.verdict`](test.suite.md) |
| `metadata` | `list` | [`osx.file.metadata.list`](osx.md) |
| `method` |  | [`line.each`](line.md) · [`private.line.each`](line.md) · [`state.of`](state.md) · [`this.methodNotFound`](this.md) |
| `method` | `check` | [`os.check`](os.md) |
| `method` | `delete` | [`oo.method.delete`](oo.md) |
| `method` | `get` | [`c2.function.declaration.get`](c2.md) · [`c2.function.parameter.get`](c2.md) · [`c2.get.function.declaration`](c2.md) · [`c2.get.function.parameter`](c2.md) · [`private.c2.get.function.declaration`](c2.md) · [`private.c2.get.function.parameter`](c2.md) · [`private.oo.method.end.get`](oo.md) · [`private.oo.method.stubs.get`](oo.md) |
| `method` | `new` | [`oo.method.new`](oo.md) |
| `method` | `parse` | [`ossh.config.parse`](ossh.md) · [`ossh.config.parse.url`](ossh.md) |
| `method` | `rerun` | [`private.ogit.sudo.rerun`](ogit.md) |
| `method` | `resolve` | [`private.oo.method.name.resolve`](oo.md) |
| `method` | `step` | [`private.setup.all.step`](setup.md) |
| `methodNotFound` |  | [`this.methodNotFound`](this.md) |
| `metrics` |  | [`claudeFlow.agent.metrics`](claudeFlow.md) · [`hiveMind.metrics.summary`](hivemind.md) · [`scrumMaster.metrics.cycle`](scrumMaster.md) |
| `metrics` | `collect` | [`scrumMaster.metrics.collect`](scrumMaster.md) |
| `metrics` | `get` | [`private.scrumMaster.metrics.dir.get`](scrumMaster.md) |
| `metrics` | `log` | [`hiveMind.metrics.log`](hivemind.md) |
| `metrics` | `save` | [`private.scrumMaster.metrics.save`](scrumMaster.md) |
| `mine` |  | [`private.odocker.workspaces.mine`](odocker.md) |
| `minimal` |  | [`config.bash.minimal.version`](config.md) |
| `mode` |  | [`oo.mode`](oo.md) |
| `mode` | `align` | [`oo.mode.align`](oo.md) |
| `mode` | `bind` | [`claudeFlow.tmux.bind`](claudeFlow.md) |
| `mode` | `commit` | [`oo.commit`](oo.md) |
| `mode` | `delete` | [`ogit.branch.remote.delete`](ogit.md) |
| `mode` | `eval` | [`private.hiveMind.ctxrefresh.eval`](hivemind.md) |
| `mode` | `fix` | [`ossh.folder.fix`](ossh.md) |
| `mode` | `get` | [`oo.mode.base.get`](oo.md) · [`private.odocker.prereq.package.get`](odocker.md) · [`private.oo.path.sudo.get`](oo.md) · [`private.test.suite.ssh.mode.get`](test.suite.md) |
| `mode` | `list` | [`oo.mode.list`](oo.md) |
| `mode` | `reap` | [`private.hiveMind.shell.reap.impl`](hivemind.md) |
| `mode` | `reconcile` | [`hiveMind.consistency.reconcile`](hivemind.md) |
| `mode` | `refresh` | [`private.hiveMind.ctx.refresh.impl`](hivemind.md) |
| `mode` | `release` | [`private.check.user.mode.release`](oo.md) |
| `mode` | `resolve` | [`private.oo.mode.resolve.branch`](oo.md) |
| `mode` | `revert` | [`ogit.commit.revert`](ogit.md) |
| `mode` | `set` | [`oo.mode.base.set`](oo.md) |
| `mode` | `setup` | [`oo.mode.setup`](oo.md) |
| `mode` | `stage` | [`oo.mode.stage`](oo.md) |
| `mode` | `sync` | [`oo.mode.sync`](oo.md) |
| `model` |  | [`claudeCode.model`](claudeCode.md) · [`claudeFlow.tmux.task`](claudeFlow.md) · [`private.hiveMind.pane.model`](hivemind.md) |
| `model` | `get` | [`claudeCode.model.get`](claudeCode.md) |
| `model` | `list` | [`claudeCode.model.list`](claudeCode.md) |
| `model` | `set` | [`claudeCode.model.set`](claudeCode.md) |
| `models` | `list` | [`hiveMind.team.models.list`](hivemind.md) |
| `monitor` | `approve` | [`hiveMind.monitor.approve`](hivemind.md) |
| `monitor` | `switch` | [`private.hiveMind.monitor.switch`](hivemind.md) |
| `morePrefixes` | `drop` | [`private.config.env.lines.drop`](config.md) |
| `moved` |  | [`hiveMind.protected.pane.moved`](hivemind.md) · [`private.hiveMind.handler.pane.moved.registry`](hivemind.md) · [`private.hiveMind.handler.pane.moved.role_env`](hivemind.md) |
| `msg` |  | [`otmux.msg`](otmux.md) |
| `myId` | `create` | [`myId.create`](myId.md) · [`myId.key.deploy.create`](myId.md) |
| `myId` | `deploy` | [`myId.create.github.deploy.key`](myId.md) |
| `myId` | `get` | [`myId.get`](myId.md) |
| `myId` | `list` | [`myId.list`](myId.md) |
| `myId` | `noop` | [`myId.noop`](myId.md) |
| `mycmd` |  | [`mycmd.1`](mycmd.md) · [`mycmd.2`](mycmd.md) · [`mycmd.3`](mycmd.md) · [`mycmd.4`](mycmd.md) · [`mycmd.feature1`](mycmd.md) · [`mycmd.feature2`](mycmd.md) · [`mycmd.feature3`](mycmd.md) · [`mycmd.logging.tests`](mycmd.md) · [`mycmd.scope`](mycmd.md) · [`mycmd.tab`](mycmd.md) · [`mycmd.tab.alias`](mycmd.md) · [`mycmd.tab.buildinCommands`](mycmd.md) · [`mycmd.tab.env`](mycmd.md) · [`mycmd.tab.files`](mycmd.md) · [`mycmd.tab.folders`](mycmd.md) · [`mycmd.tab.groups`](mycmd.md) · [`mycmd.tab.jobs`](mycmd.md) · [`mycmd.tab.user`](mycmd.md) · [`mycmd.tab.variables`](mycmd.md) |
| `mycmd` | `clean` | [`mycmd.clean.logfiles`](mycmd.md) |
| `mycmd` | `pipe` | [`mycmd.pipe.tests`](mycmd.md) |
| `mycmd` | `test` | [`mycmd.check.test.results`](mycmd.md) · [`mycmd.execute.logging.test`](mycmd.md) |
| `name` |  | [`claudeCode.session.name`](claudeCode.md) · [`claudeFlow.tmux.pane`](claudeFlow.md) · [`log.name`](log.md) · [`osx.spotlight.by.name`](osx.md) · [`otmux.nw`](otmux.md) · [`otmux.socket`](otmux.md) · [`private.odocker.container.name`](odocker.md) · [`state.name`](state.md) |
| `name` | `activate` | [`opy.venv.activate`](opy.md) |
| `name` | `add` | [`config.add`](config.md) |
| `name` | `check` | [`config.file.check`](config.md) |
| `name` | `create` | [`odocker.create`](odocker.md) · [`opy.venv.create`](opy.md) |
| `name` | `declare` | [`line.param.declare`](line.md) |
| `name` | `delegate` | [`hiveMind.delegate`](hivemind.md) |
| `name` | `delete` | [`config.delete`](config.md) |
| `name` | `edit` | [`config.edit`](config.md) |
| `name` | `enter` | [`hiveMind.send.enter`](hivemind.md) |
| `name` | `find` | [`disk.find.dir`](disk.md) · [`disk.find.file`](disk.md) |
| `name` | `fork` | [`claudeCode.fork.byName`](claudeCode.md) |
| `name` | `get` | [`ossh.key.name.get`](ossh.md) · [`private.config.host.container.name.get`](config.md) · [`private.config.host.name.get`](config.md) · [`private.ossh.remote.key.file.name.get`](ossh.md) · [`private.this.group.name.get`](this.md) · [`private.this.host.name.get`](this.md) · [`private.this.user.name.get`](this.md) |
| `name` | `join` | [`claudeCode.join.byName`](claudeCode.md) · [`hiveMind.join`](hivemind.md) |
| `name` | `list` | [`config.list`](config.md) |
| `name` | `new` | [`otmux.new`](otmux.md) · [`otmux.session.new`](otmux.md) · [`otmux.window.new`](otmux.md) · [`private.odocker.container.name.new`](odocker.md) |
| `name` | `newWindow` | [`private.otmux.newWindow`](otmux.md) |
| `name` | `refresh` | [`private.config.host.name.refresh`](config.md) |
| `name` | `remove` | [`opy.venv.remove`](opy.md) |
| `name` | `rename` | [`otmux.session.rename`](otmux.md) · [`otmux.window.rename`](otmux.md) |
| `name` | `renameWindow` | [`private.otmux.renameWindow`](otmux.md) |
| `name` | `reset` | [`odocker.reset`](odocker.md) |
| `name` | `resolve` | [`hiveMind.resolve`](hivemind.md) · [`private.claudeCode.resolve.byName`](claudeCode.md) · [`private.hiveMind.channel.resolve`](hivemind.md) · [`private.oo.method.name.resolve`](oo.md) |
| `name` | `rewind` | [`hiveMind.agent.rewind`](hivemind.md) |
| `name` | `run` | [`claudeFlow.tmux.run`](claudeFlow.md) · [`odocker.run`](odocker.md) · [`odocker.run.sshd`](odocker.md) |
| `name` | `save` | [`claudeFlow.session.save`](claudeFlow.md) · [`config.save`](config.md) · [`private.config.save`](config.md) |
| `name` | `send` | [`hiveMind.agent.send`](hivemind.md) · [`hiveMind.send`](hivemind.md) · [`hiveMind.send.message`](hivemind.md) |
| `name` | `set` | [`ossh.key.name.set`](ossh.md) · [`otmux.env.set`](otmux.md) |
| `name` | `setEnv` | [`private.otmux.setEnv`](otmux.md) |
| `name` | `show` | [`otmux.env.show`](otmux.md) |
| `name` | `showEnv` | [`private.otmux.showEnv`](otmux.md) |
| `name` | `step` | [`private.setup.all.step`](setup.md) |
| `name` | `unblock` | [`hiveMind.unblock`](hivemind.md) |
| `name` | `update` | [`config.update`](config.md) |
| `name` | `validate` | [`config.validate`](config.md) |
| `name2device` |  | [`disk.name2device`](disk.md) |
| `nameFilter` | `list` | [`state.machine.list`](state.md) |
| `names` |  | [`private.os.platform.names`](os.md) |
| `names` | `get` | [`private.config.chain.names.get`](config.md) |
| `network` | `is` | [`private.ossh.connection.error.network.is`](ossh.md) |
| `neural` |  | [`claudeFlow.neural`](claudeFlow.md) |
| `new` | `test` | [`oo.new.test`](oo.md) · [`private.oo.new.test`](oo.md) |
| `noResults` |  | [`private.test.suite.verdict`](test.suite.md) |
| `nodejs` |  | [`setup.nodejs`](setup.md) |
| `none` |  | [`parameterTestScript.none`](parameterTestScript.md) |
| `normalize` | `revert` | [`backup.normalize.revert`](backup.md) |
| `normalize` | `scan` | [`backup.normalize.scan`](backup.md) |
| `not` |  | [`check.not`](check.md) |
| `notests` |  | [`private.promote.notests.gate`](promote.md) |
| `notests` | `test` | [`os.platform.test`](os.md) · [`private.os.platform.test.ci`](os.md) |
| `notifyHiveMind` |  | [`private.otmux.notifyHiveMind.shifted`](otmux.md) |
| `npm` |  | [`setup.npm`](setup.md) |
| `number` |  | [`hiveMind.improvement`](hivemind.md) |
| `number` | `calc` | [`disk.calc.bytes.from.gb`](disk.md) · [`disk.calc.bytes.from.kb`](disk.md) · [`disk.calc.bytes.from.mb`](disk.md) · [`disk.calc.bytes.from.tb`](disk.md) · [`disk.calc.bytes.to.gb`](disk.md) · [`disk.calc.bytes.to.kb`](disk.md) · [`disk.calc.bytes.to.mb`](disk.md) · [`disk.calc.bytes.to.tb`](disk.md) · [`disk.calc.getBytesInGB`](disk.md) · [`disk.calc.getBytesInKB`](disk.md) · [`disk.calc.getBytesInMB`](disk.md) · [`disk.calc.getBytesInTB`](disk.md) · [`disk.calc.getGB`](disk.md) · [`disk.calc.getKB`](disk.md) · [`disk.calc.getMB`](disk.md) · [`disk.calc.getTB`](disk.md) |
| `number` | `improve` | [`hiveMind.plan.improve`](hivemind.md) |
| `nvm` |  | [`setup.nvm`](setup.md) |
| `nvm` | `is` | [`private.setup.nvm.is`](setup.md) |
| `nvm` | `run` | [`private.setup.nvm.run`](setup.md) |
| `nw` |  | [`otmux.nw`](otmux.md) |
| `object` | `dispatch` | [`private.ossh.dispatch`](ossh.md) |
| `object` | `get` | [`ossh.get`](ossh.md) |
| `object` | `set` | [`ossh.set`](ossh.md) |
| `odocker` |  | [`odocker.disk`](odocker.md) · [`odocker.image.command`](odocker.md) · [`odocker.lifecycle`](odocker.md) · [`odocker.ps`](odocker.md) · [`odocker.status`](odocker.md) · [`private.odocker.container.name`](odocker.md) · [`private.odocker.container.ports`](odocker.md) · [`private.odocker.docker.socket.opt`](odocker.md) · [`private.odocker.engine.supported`](odocker.md) · [`private.odocker.env.chained`](odocker.md) · [`private.odocker.port.offset`](odocker.md) · [`private.odocker.workspaces.entry.same`](odocker.md) · [`private.odocker.workspaces.mine`](odocker.md) |
| `odocker` | `add` | [`private.odocker.container.repo.add`](odocker.md) · [`private.odocker.docker.repo.add`](odocker.md) |
| `odocker` | `build` | [`odocker.build`](odocker.md) · [`odocker.build.all`](odocker.md) |
| `odocker` | `check` | [`private.odocker.socket.gid.check`](odocker.md) |
| `odocker` | `clone` | [`odocker.clone`](odocker.md) |
| `odocker` | `compose` | [`odocker.compose`](odocker.md) · [`private.odocker.compose.file.in`](odocker.md) · [`private.odocker.compose.services`](odocker.md) |
| `odocker` | `create` | [`odocker.create`](odocker.md) |
| `odocker` | `down` | [`odocker.down`](odocker.md) |
| `odocker` | `download` | [`private.odocker.docker.repo.download`](odocker.md) |
| `odocker` | `ensure` | [`private.odocker.ensure.socket.access`](odocker.md) · [`private.odocker.prereqs.ensure`](odocker.md) · [`private.odocker.socket.access.ensure`](odocker.md) · [`private.odocker.socket.group.ensure`](odocker.md) |
| `odocker` | `enter` | [`odocker.enter`](odocker.md) |
| `odocker` | `exec` | [`odocker.exec`](odocker.md) · [`odocker.exec.command`](odocker.md) |
| `odocker` | `fetch` | [`private.odocker.workspaces.fetch.ssh`](odocker.md) · [`private.odocker.workspaces.fetch.url`](odocker.md) |
| `odocker` | `find` | [`odocker.file.find`](odocker.md) · [`private.odocker.compose.file.find`](odocker.md) |
| `odocker` | `get` | [`odocker.container.ip.get`](odocker.md) · [`odocker.workspace.get`](odocker.md) · [`private.odocker.docker.repo.get`](odocker.md) · [`private.odocker.passwd.users.get`](odocker.md) · [`private.odocker.prereq.package.get`](odocker.md) · [`private.odocker.socket.get`](odocker.md) · [`private.odocker.workspaces.default.get`](odocker.md) · [`private.odocker.workspaces.merge.answer.get`](odocker.md) · [`private.odocker.workspaces.source.host.get`](odocker.md) · [`private.odocker.workspaces.source.path.get`](odocker.md) · [`private.odocker.workspaces.source.url.get`](odocker.md) |
| `odocker` | `init` | [`odocker.workspace.init`](odocker.md) |
| `odocker` | `install` | [`odocker.install`](odocker.md) · [`odocker.prereqs.install`](odocker.md) · [`private.odocker.container.prereqs.install`](odocker.md) · [`private.odocker.workspaces.install`](odocker.md) |
| `odocker` | `list` | [`odocker.container.list`](odocker.md) · [`odocker.image.list`](odocker.md) · [`odocker.list`](odocker.md) · [`odocker.list.running`](odocker.md) · [`odocker.workspace.list`](odocker.md) · [`private.odocker.container.list.all`](odocker.md) · [`private.odocker.container.list.findable`](odocker.md) · [`private.odocker.container.list.running`](odocker.md) · [`private.odocker.image.list`](odocker.md) · [`private.odocker.image.list.findable`](odocker.md) · [`private.odocker.workspace.list`](odocker.md) |
| `odocker` | `log` | [`odocker.log`](odocker.md) |
| `odocker` | `merge` | [`private.odocker.workspaces.merge`](odocker.md) |
| `odocker` | `new` | [`private.odocker.container.name.new`](odocker.md) |
| `odocker` | `prune` | [`odocker.prune`](odocker.md) · [`odocker.prune.all`](odocker.md) |
| `odocker` | `rebuild` | [`odocker.rebuild`](odocker.md) |
| `odocker` | `remove` | [`odocker.container.remove`](odocker.md) · [`odocker.image.remove`](odocker.md) |
| `odocker` | `reset` | [`odocker.reset`](odocker.md) |
| `odocker` | `resolve` | [`private.odocker.image.resolve.from.workspace`](odocker.md) · [`private.odocker.resolve.image`](odocker.md) |
| `odocker` | `rm` | [`odocker.rm`](odocker.md) |
| `odocker` | `rmi` | [`odocker.rmi`](odocker.md) |
| `odocker` | `run` | [`odocker.run`](odocker.md) · [`odocker.run.sshd`](odocker.md) |
| `odocker` | `seed` | [`odocker.workspace.seed`](odocker.md) |
| `odocker` | `set` | [`odocker.workspace.set`](odocker.md) |
| `odocker` | `stop` | [`odocker.stop`](odocker.md) |
| `odocker` | `up` | [`odocker.up`](odocker.md) |
| `of` |  | [`state.of`](state.md) |
| `off` |  | [`claudeFlow.statusline.off`](claudeFlow.md) · [`os.service.off`](os.md) · [`private.os.service.off.darwin`](os.md) · [`private.os.service.off.linux`](os.md) |
| `offline` |  | [`hiveMind.protected.agents.offline`](hivemind.md) |
| `offset` |  | [`private.odocker.port.offset`](odocker.md) |
| `ogit` |  | [`ogit.branch.fastForward`](ogit.md) · [`ogit.layout.status`](ogit.md) · [`ogit.raw`](ogit.md) · [`private.ogit.folder.gate`](ogit.md) · [`private.ogit.folder.shape`](ogit.md) · [`private.ogit.gitdir`](ogit.md) · [`private.ogit.identity`](ogit.md) |
| `ogit` | `add` | [`ogit.index.add`](ogit.md) · [`ogit.safeDirectory.add`](ogit.md) · [`ogit.worktree.add`](ogit.md) |
| `ogit` | `adopt` | [`ogit.branch.adopt`](ogit.md) |
| `ogit` | `check` | [`ogit.binary.check`](ogit.md) · [`ogit.branch.check`](ogit.md) · [`ogit.diff.check`](ogit.md) · [`ogit.repo.check`](ogit.md) · [`ogit.status.check`](ogit.md) · [`ogit.tag.check`](ogit.md) · [`private.ogit.root.check`](ogit.md) |
| `ogit` | `checkout` | [`ogit.branch.checkout`](ogit.md) |
| `ogit` | `clone` | [`ogit.repo.clone`](ogit.md) · [`private.ogit.clone.gate`](ogit.md) |
| `ogit` | `compare` | [`ogit.branch.compare`](ogit.md) |
| `ogit` | `continue` | [`ogit.commit.pick.continue`](ogit.md) |
| `ogit` | `count` | [`ogit.commit.count`](ogit.md) |
| `ogit` | `create` | [`ogit.commit.create`](ogit.md) · [`ogit.tag.create`](ogit.md) |
| `ogit` | `delete` | [`ogit.branch.remote.delete`](ogit.md) · [`ogit.worktree.delete`](ogit.md) |
| `ogit` | `drop` | [`ogit.stash.drop`](ogit.md) |
| `ogit` | `ensure` | [`ogit.safeDirectory.ensure`](ogit.md) |
| `ogit` | `fetch` | [`ogit.remote.fetch`](ogit.md) |
| `ogit` | `find` | [`ogit.branch.find`](ogit.md) · [`ogit.worktree.find`](ogit.md) |
| `ogit` | `finish` | [`ogit.folder.finish`](ogit.md) |
| `ogit` | `get` | [`ogit.branch.get`](ogit.md) · [`ogit.config.email.get`](ogit.md) · [`ogit.config.get`](ogit.md) · [`ogit.merge.base.get`](ogit.md) · [`ogit.remote.url.get`](ogit.md) · [`ogit.repo.root.get`](ogit.md) · [`ogit.stash.top.get`](ogit.md) · [`ogit.tag.latest.get`](ogit.md) · [`private.ogit.base.get`](ogit.md) · [`private.ogit.git.reason.get`](ogit.md) · [`private.ogit.umask.get`](ogit.md) · [`private.ogit.worktree.paths.get`](ogit.md) |
| `ogit` | `grep` | [`ogit.repo.grep`](ogit.md) |
| `ogit` | `import` | [`private.ogit.branch.import`](ogit.md) |
| `ogit` | `list` | [`ogit.branch.list`](ogit.md) · [`ogit.conflict.list`](ogit.md) · [`ogit.remote.branch.list`](ogit.md) · [`ogit.repo.files.list`](ogit.md) · [`ogit.safeDirectory.list`](ogit.md) · [`ogit.tag.list`](ogit.md) · [`ogit.worktree.list`](ogit.md) · [`private.ogit.base.folders.list`](ogit.md) |
| `ogit` | `merge` | [`ogit.branch.merge`](ogit.md) · [`ogit.merge.abort`](ogit.md) |
| `ogit` | `pick` | [`ogit.commit.pick`](ogit.md) · [`ogit.commit.pick.abort`](ogit.md) |
| `ogit` | `pop` | [`ogit.stash.pop`](ogit.md) |
| `ogit` | `prune` | [`ogit.safeDirectory.prune`](ogit.md) · [`ogit.worktree.prune`](ogit.md) |
| `ogit` | `pull` | [`ogit.remote.pull`](ogit.md) |
| `ogit` | `push` | [`ogit.remote.push`](ogit.md) · [`ogit.stash.push`](ogit.md) |
| `ogit` | `remove` | [`ogit.index.remove`](ogit.md) · [`ogit.worktree.remove`](ogit.md) |
| `ogit` | `require` | [`private.ogit.require`](ogit.md) |
| `ogit` | `rerun` | [`private.ogit.sudo.rerun`](ogit.md) |
| `ogit` | `reset` | [`ogit.branch.reset`](ogit.md) |
| `ogit` | `resolve` | [`ogit.conflict.resolve`](ogit.md) |
| `ogit` | `restore` | [`ogit.worktree.restore`](ogit.md) · [`private.ogit.folder.ignored.restore`](ogit.md) |
| `ogit` | `revert` | [`ogit.commit.revert`](ogit.md) |
| `ogit` | `run` | [`private.ogit.git.run`](ogit.md) |
| `ogit` | `save` | [`private.ogit.folder.ignored.save`](ogit.md) |
| `ogit` | `set` | [`ogit.branch.upstream.set`](ogit.md) · [`ogit.config.set`](ogit.md) · [`ogit.remote.url.set`](ogit.md) |
| `ogit` | `share` | [`ogit.repo.share`](ogit.md) · [`private.ogit.fetchhead.share`](ogit.md) |
| `ogit` | `show` | [`ogit.commit.log.show`](ogit.md) · [`ogit.commit.show`](ogit.md) · [`ogit.diff.show`](ogit.md) · [`ogit.status.show`](ogit.md) |
| `ogit` | `validate` | [`ogit.caller.validate`](ogit.md) |
| `oldName` |  | [`hiveMind.protected.session.renamed`](hivemind.md) |
| `on` |  | [`claudeFlow.statusline.on`](claudeFlow.md) · [`os.service.on`](os.md) · [`private.os.service.on.darwin`](os.md) · [`private.os.service.on.linux`](os.md) |
| `onError` |  | [`debug.onError`](debug.md) |
| `onExit` |  | [`debug.onExit`](debug.md) |
| `onReturn` |  | [`debug.onReturn`](debug.md) |
| `once` |  | [`certificates.once.scenarios`](certificates.md) |
| `once` | `get` | [`certificates.once.get.certbot.path`](certificates.md) |
| `once` | `list` | [`certificates.once.scenario.list`](certificates.md) |
| `once` | `migrate` | [`private.oo.once.path.migrate`](oo.md) |
| `once` | `select` | [`certificates.once.scenario.select`](certificates.md) |
| `once` | `setup` | [`private.check.once.setup.finished`](oo.md) · [`private.check.once.setup.started`](oo.md) |
| `onceShBase` | `ensure` | [`private.oo.user.shared.symlinks.ensure`](oo.md) |
| `one` |  | [`parameterTestScript.one`](parameterTestScript.md) |
| `oneDefaultValue` |  | [`parameterTestScript.oneDefaultValue`](parameterTestScript.md) |
| `oneDefaultValueQuotes` |  | [`parameterTestScript.oneDefaultValueQuotes`](parameterTestScript.md) |
| `onlyLive` |  | [`private.tronMonitor.registry.teams`](tronMonitor.md) |
| `oo` |  | [`oo.cmd`](oo.md) · [`oo.dev.to.testing`](oo.md) · [`oo.mode`](oo.md) · [`oo.pm`](oo.md) · [`oo.state`](oo.md) · [`oo.testing.to.prod`](oo.md) · [`private.oo.dev.to.testing`](oo.md) · [`private.oo.sed.first`](oo.md) · [`private.oo.shared.tree.from.local`](oo.md) |
| `oo` | `align` | [`oo.mode.align`](oo.md) |
| `oo` | `boot` | [`private.check.root.boot.path.installed`](oo.md) |
| `oo` | `check` | [`oo.branches.check`](oo.md) · [`private.check.all.pm`](oo.md) · [`private.check.finished`](oo.md) · [`private.check.pm`](oo.md) · [`private.check.priviledges.checked`](oo.md) · [`private.check.root.dev.keys.installed`](oo.md) · [`private.check.root.installation.done`](oo.md) · [`private.check.root.rights`](oo.md) · [`private.check.root.shared.dev.folder.created`](oo.md) · [`private.check.user.installation.done`](oo.md) · [`private.check.user.mode.dev`](oo.md) · [`private.check.user.rights.only`](oo.md) · [`private.check.user.shared.dev.folder.linked`](oo.md) · [`private.check.user.state.machine.synced.with.root`](oo.md) · [`private.oo.layout.folder.check`](oo.md) |
| `oo` | `checkout` | [`oo.checkout`](oo.md) |
| `oo` | `cleanup` | [`oo.tmp.cleanup.testing`](oo.md) · [`private.oo.tmp.cleanup.testing`](oo.md) |
| `oo` | `commit` | [`oo.commit`](oo.md) |
| `oo` | `deinstall` | [`oo.deinstall`](oo.md) |
| `oo` | `delete` | [`oo.method.delete`](oo.md) |
| `oo` | `discover` | [`oo.pm.discover`](oo.md) |
| `oo` | `ensure` | [`private.oo.branch.clone.ensure`](oo.md) · [`private.oo.shared.tree.ensure`](oo.md) · [`private.oo.user.shared.symlinks.ensure`](oo.md) |
| `oo` | `find` | [`oo.cmd.find`](oo.md) · [`private.oo.find.cmd`](oo.md) |
| `oo` | `fix` | [`oo.user.fix`](oo.md) |
| `oo` | `get` | [`oo.mode.base.get`](oo.md) · [`private.oo.checkout.dir.get`](oo.md) · [`private.oo.install.branch.get`](oo.md) · [`private.oo.method.end.get`](oo.md) · [`private.oo.method.stubs.get`](oo.md) · [`private.oo.path.sudo.get`](oo.md) · [`private.oo.pm.env.get`](oo.md) · [`private.oo.pm.install.prefix.get`](oo.md) · [`private.oo.regex.escape.get`](oo.md) |
| `oo` | `heal` | [`private.oo.update.heal.symlinks`](oo.md) |
| `oo` | `init` | [`private.init.state.machine`](oo.md) |
| `oo` | `install` | [`oo.install`](oo.md) · [`oo.install.dev`](oo.md) · [`oo.install.dev.keys`](oo.md) · [`oo.prereqs.install`](oo.md) · [`private.check.local.install.started`](oo.md) · [`private.check.remote.install.started`](oo.md) · [`private.install.dev.configs`](oo.md) · [`private.oo.install.launcher`](oo.md) · [`private.oo.install.shim`](oo.md) |
| `oo` | `is` | [`private.oo.path.writable.is`](oo.md) |
| `oo` | `list` | [`oo.branch.list`](oo.md) · [`oo.mode.list`](oo.md) |
| `oo` | `migrate` | [`private.oo.once.path.migrate`](oo.md) |
| `oo` | `new` | [`oo.method.new`](oo.md) · [`oo.new`](oo.md) · [`oo.new.method`](oo.md) · [`oo.test.new`](oo.md) · [`oo.test.platform.new`](oo.md) · [`private.oo.new.method`](oo.md) |
| `oo` | `promote` | [`oo.promote.status`](oo.md) · [`private.oo.promote.status`](oo.md) |
| `oo` | `prune` | [`oo.safeDirectory.prune`](oo.md) |
| `oo` | `release` | [`oo.release`](oo.md) · [`private.check.user.mode.release`](oo.md) |
| `oo` | `remove` | [`oo.checkout.remove`](oo.md) · [`private.oo.dropin.remove`](oo.md) |
| `oo` | `report` | [`oo.promote.report`](oo.md) · [`private.oo.promote.report`](oo.md) |
| `oo` | `resolve` | [`private.oo.method.name.resolve`](oo.md) · [`private.oo.mode.resolve.branch`](oo.md) |
| `oo` | `set` | [`oo.mode.base.set`](oo.md) |
| `oo` | `setup` | [`oo.mode.setup`](oo.md) · [`private.check.headless.setup.finished`](oo.md) · [`private.check.headless.setup.started`](oo.md) · [`private.check.once.setup.finished`](oo.md) · [`private.check.once.setup.started`](oo.md) |
| `oo` | `source` | [`private.oo.source.consume.gate`](oo.md) |
| `oo` | `stage` | [`oo.mode.stage`](oo.md) · [`oo.stage`](oo.md) |
| `oo` | `su` | [`oo.su`](oo.md) |
| `oo` | `sync` | [`oo.mode.sync`](oo.md) |
| `oo` | `test` | [`oo.new.test`](oo.md) · [`private.oo.new.test`](oo.md) · [`private.test.sudo.priviledges`](oo.md) |
| `oo` | `update` | [`oo.remote.update`](oo.md) · [`oo.update`](oo.md) |
| `oo` | `use` | [`oo.use`](oo.md) |
| `oo` | `verify` | [`private.oo.cmd.verify`](oo.md) |
| `oosh` |  | [`private.this.oosh.dir.invariant`](this.md) |
| `oosh` | `get` | [`private.config.oosh.session.file.get`](config.md) |
| `oosh` | `init` | [`hiveMind.oosh.init`](hivemind.md) |
| `oosh` | `install` | [`private.user.oosh.install.groups.darwin`](user.md) · [`private.user.oosh.install.groups.linux`](user.md) · [`private.user.oosh.install.node`](user.md) · [`private.user.oosh.install.shell.darwin`](user.md) · [`private.user.oosh.install.shell.linux`](user.md) · [`user.oosh.install`](user.md) |
| `oosh` | `is` | [`private.config.oosh.session.split.is`](config.md) |
| `oosh` | `migrate` | [`private.config.oosh.session.migrate`](config.md) |
| `oosh` | `push` | [`private.ossh.oosh.init.push`](ossh.md) |
| `oosh` | `validate` | [`this.oosh.dir.validate`](this.md) |
| `ooshBranch` | `ensure` | [`private.oo.user.shared.symlinks.ensure`](oo.md) |
| `ooshDir` |  | [`private.promote.rewrite.self.branch`](promote.md) |
| `ooshDir` | `install` | [`private.user.bashrc.install`](user.md) |
| `ooshSplit` | `save` | [`private.config.save`](config.md) |
| `opt` |  | [`private.odocker.docker.socket.opt`](odocker.md) |
| `option` |  | [`hiveMind.agent.option`](hivemind.md) · [`private.hiveMind.agent.overlay.key`](hivemind.md) · [`this.absolutePath`](this.md) · [`this.absolutePathName`](this.md) |
| `option` | `approve` | [`hiveMind.monitor.approve`](hivemind.md) |
| `option` | `dispatch` | [`private.hiveMind.agent.overlay.dispatch`](hivemind.md) |
| `option` | `rewind` | [`hiveMind.agent.rewind`](hivemind.md) |
| `option` | `set` | [`otmux.config.set`](otmux.md) · [`otmux.config.set.global`](otmux.md) · [`otmux.config.set.window`](otmux.md) · [`otmux.set`](otmux.md) |
| `option` | `setGlobal` | [`private.otmux.setGlobal`](otmux.md) |
| `option` | `setWindow` | [`private.otmux.setWindow`](otmux.md) |
| `option` | `show` | [`otmux.config.show`](otmux.md) · [`otmux.config.show.global`](otmux.md) · [`otmux.config.show.window`](otmux.md) · [`otmux.show`](otmux.md) |
| `option` | `showGlobal` | [`private.otmux.showGlobal`](otmux.md) |
| `option` | `showWindow` | [`private.otmux.showWindow`](otmux.md) |
| `optional` |  | [`parameterTestScript.optional`](parameterTestScript.md) |
| `optionalDefaultValue` |  | [`parameterTestScript.optionalDefaultValue`](parameterTestScript.md) |
| `options` |  | [`claudeFlow.agent.pool`](claudeFlow.md) · [`claudeFlow.daemon`](claudeFlow.md) · [`claudeFlow.hive.consensus`](claudeFlow.md) · [`claudeFlow.hive.task`](claudeFlow.md) · [`claudeFlow.swarm.v3`](claudeFlow.md) · [`user.id`](user.md) |
| `options` | `assign` | [`claudeFlow.task.assign`](claudeFlow.md) |
| `options` | `capturePane` | [`private.otmux.capturePane`](otmux.md) |
| `options` | `coordinate` | [`claudeFlow.swarm.coordinate`](claudeFlow.md) |
| `options` | `create` | [`claudeFlow.task.create`](claudeFlow.md) |
| `options` | `exec` | [`claudeFlow.mcp.exec`](claudeFlow.md) |
| `options` | `export` | [`claudeFlow.session.export`](claudeFlow.md) |
| `options` | `init` | [`claudeFlow.hive.init`](claudeFlow.md) · [`claudeFlow.swarm.init`](claudeFlow.md) |
| `options` | `list` | [`claudeFlow.task.list`](claudeFlow.md) |
| `options` | `ls` | [`claudeFlow.task.ls`](claudeFlow.md) |
| `options` | `new` | [`claudeFlow.task.new`](claudeFlow.md) |
| `options` | `spawn` | [`claudeFlow.agent.spawn`](claudeFlow.md) · [`claudeFlow.hive.spawn`](claudeFlow.md) |
| `options` | `store` | [`claudeFlow.memory.store`](claudeFlow.md) |
| `opus` |  | [`claudeCode.opus`](claudeCode.md) |
| `opy` |  | [`opy.deps`](opy.md) · [`opy.version`](opy.md) · [`private.opy.bashrcBlock`](opy.md) · [`private.opy.latest`](opy.md) · [`private.opy.pkgInstall`](opy.md) · [`private.opy.pyenv`](opy.md) · [`private.opy.pyenvBin`](opy.md) · [`private.opy.pyenvRoot`](opy.md) · [`private.opy.python`](opy.md) · [`private.opy.venvHome`](opy.md) |
| `opy` | `activate` | [`opy.venv.activate`](opy.md) |
| `opy` | `activateLatest` | [`private.opy.activateLatest`](opy.md) |
| `opy` | `create` | [`opy.venv.create`](opy.md) |
| `opy` | `deactivate` | [`opy.venv.deactivate`](opy.md) |
| `opy` | `ensurePyenv` | [`private.opy.ensurePyenv`](opy.md) |
| `opy` | `install` | [`opy.install`](opy.md) · [`opy.shell.install`](opy.md) |
| `opy` | `installBashrc` | [`private.opy.installBashrc`](opy.md) |
| `opy` | `installPyenv` | [`private.opy.installPyenv`](opy.md) |
| `opy` | `isInstalled` | [`private.opy.isInstalled`](opy.md) |
| `opy` | `list` | [`opy.venv.list`](opy.md) · [`opy.version.list`](opy.md) |
| `opy` | `remove` | [`opy.remove`](opy.md) · [`opy.venv.remove`](opy.md) |
| `opy` | `set` | [`opy.version.set`](opy.md) |
| `opy` | `update` | [`opy.update`](opy.md) |
| `origin` | `get` | [`private.test.suite.ssh.origin.get`](test.suite.md) |
| `os` |  | [`os.hostname.info`](os.md) · [`os.info`](os.md) · [`os.service.off`](os.md) · [`os.service.on`](os.md) · [`private.os.hostname.info.darwin`](os.md) · [`private.os.hostname.info.linux`](os.md) · [`private.os.platform.container.id`](os.md) · [`private.os.platform.image.from.workspace`](os.md) · [`private.os.platform.names`](os.md) · [`private.os.service.off.darwin`](os.md) · [`private.os.service.off.linux`](os.md) · [`private.os.service.on.darwin`](os.md) · [`private.os.service.on.linux`](os.md) |
| `os` | `check` | [`os.check`](os.md) · [`os.check.env`](os.md) · [`os.platform.parse.check`](os.md) |
| `os` | `cleanup` | [`private.os.platform.cleanup`](os.md) |
| `os` | `exists` | [`private.os.platform.image.exists`](os.md) |
| `os` | `get` | [`os.hostname.get`](os.md) · [`private.os.hostname.get.darwin`](os.md) · [`private.os.hostname.get.linux`](os.md) · [`private.os.release.get`](os.md) |
| `os` | `is` | [`private.os.systemd.is`](os.md) |
| `os` | `list` | [`os.platform.list`](os.md) · [`private.os.shell.files.list`](os.md) |
| `os` | `load` | [`private.os.platform.load`](os.md) |
| `os` | `parse` | [`private.os.platform.parse`](os.md) |
| `os` | `reload` | [`private.os.platform.sshd.reload`](os.md) |
| `os` | `repair` | [`private.os.platform.shared.config.repair`](os.md) |
| `os` | `set` | [`os.hostname.set`](os.md) · [`private.os.hostname.set.darwin`](os.md) · [`private.os.hostname.set.linux`](os.md) |
| `os` | `test` | [`os.platform.test`](os.md) · [`os.platform.test.all`](os.md) · [`private.os.platform.test.ci`](os.md) |
| `osRelease` | `get` | [`private.odocker.docker.repo.get`](odocker.md) |
| `osemvec` |  | [`osemvec.context`](osemvec.md) · [`osemvec.error`](osemvec.md) · [`osemvec.index`](osemvec.md) · [`osemvec.status`](osemvec.md) · [`private.osemvec.agentsDir`](osemvec.md) · [`private.osemvec.authorized`](osemvec.md) · [`private.osemvec.knownRoles`](osemvec.md) · [`private.osemvec.mcpJson`](osemvec.md) · [`private.osemvec.osemvecBin`](osemvec.md) · [`private.osemvec.ownsProcess`](osemvec.md) · [`private.osemvec.pss`](osemvec.md) · [`private.osemvec.pyver`](osemvec.md) · [`private.osemvec.semvecVersion`](osemvec.md) · [`private.osemvec.settingsJson`](osemvec.md) · [`private.osemvec.stateDir`](osemvec.md) · [`private.osemvec.templatesDir`](osemvec.md) · [`private.osemvec.venvName`](osemvec.md) · [`private.osemvec.venvPython`](osemvec.md) · [`private.osemvec.venvReady`](osemvec.md) |
| `osemvec` | `check` | [`osemvec.check`](osemvec.md) |
| `osemvec` | `guard` | [`osemvec.guard`](osemvec.md) |
| `osemvec` | `install` | [`osemvec.install`](osemvec.md) |
| `osemvec` | `list` | [`osemvec.list`](osemvec.md) · [`osemvec.list.raw`](osemvec.md) |
| `osemvec` | `listGuarded` | [`private.osemvec.listGuarded`](osemvec.md) |
| `osemvec` | `listServe` | [`private.osemvec.listServe`](osemvec.md) |
| `osemvec` | `new` | [`osemvec.new`](osemvec.md) |
| `osemvec` | `provision` | [`private.osemvec.provision`](osemvec.md) |
| `osemvec` | `register` | [`osemvec.register`](osemvec.md) |
| `osemvec` | `save` | [`osemvec.save`](osemvec.md) |
| `osemvec` | `serve` | [`osemvec.serve`](osemvec.md) |
| `osemvec` | `stop` | [`osemvec.stop`](osemvec.md) |
| `osemvec` | `stopAuthorized` | [`private.osemvec.stopAuthorized`](osemvec.md) |
| `osemvec` | `update` | [`osemvec.update`](osemvec.md) |
| `osemvecBin` |  | [`private.osemvec.osemvecBin`](osemvec.md) |
| `ossh` |  | [`ossh.certificates.status`](ossh.md) · [`ossh.cmd`](ossh.md) · [`ossh.connection.status`](ossh.md) · [`ossh.service.status.darwin`](ossh.md) · [`ossh.service.status.linux`](ossh.md) · [`ossh.service.status.unknown`](ossh.md) · [`ossh.status`](ossh.md) · [`ossh.tunnel`](ossh.md) · [`private.ossh.hostKnown`](ossh.md) · [`private.ossh.ssh`](ossh.md) · [`private.ossh.users.basehome`](ossh.md) · [`private.ossh.validConfigBlock`](ossh.md) |
| `ossh` | `check` | [`ossh.folder.fix.check`](ossh.md) · [`private.check.finished`](ossh.md) |
| `ossh` | `close` | [`ossh.connection.close`](ossh.md) |
| `ossh` | `complete` | [`private.ossh.config.complete.hosts`](ossh.md) |
| `ossh` | `continue` | [`ossh.install.continue.local`](ossh.md) |
| `ossh` | `create` | [`ossh.config.create`](ossh.md) · [`ossh.config.shared.create`](ossh.md) · [`ossh.config.shared.github.create`](ossh.md) · [`ossh.id.create`](ossh.md) · [`ossh.id.create.fromKey`](ossh.md) · [`ossh.install.create`](ossh.md) · [`ossh.key.folder.create`](ossh.md) · [`ossh.key.folders.create`](ossh.md) · [`private.check.certificates.update.create.certbot`](ossh.md) · [`private.check.certificates.update.create.structr`](ossh.md) · [`private.config.create`](ossh.md) · [`private.ossh.create.key.folders`](ossh.md) |
| `ossh` | `delete` | [`ossh.config.delete`](ossh.md) · [`ossh.key.folder.delete`](ossh.md) · [`ossh.key.folders.delete`](ossh.md) · [`private.ossh.delete.key.folders`](ossh.md) |
| `ossh` | `deploy` | [`ossh.config.shared.seed.from.local.deploy.key`](ossh.md) |
| `ossh` | `detect` | [`private.detect.ssh.key`](ossh.md) · [`private.detect.ssh.key.type`](ossh.md) |
| `ossh` | `discover` | [`ossh.pm.discover`](ossh.md) |
| `ossh` | `dispatch` | [`private.ossh.dispatch`](ossh.md) · [`private.ossh.dispatch.objects`](ossh.md) |
| `ossh` | `edit` | [`ossh.config.edit`](ossh.md) · [`ossh.server.config.edit`](ossh.md) |
| `ossh` | `exec` | [`ossh.exec`](ossh.md) · [`ossh.exec.tty`](ossh.md) |
| `ossh` | `finish` | [`ossh.install.finish.local`](ossh.md) |
| `ossh` | `fix` | [`ossh.folder.fix`](ossh.md) · [`ossh.permission.fix`](ossh.md) · [`ossh.rights.fix`](ossh.md) |
| `ossh` | `get` | [`ossh.config.field.get`](ossh.md) · [`ossh.config.get`](ossh.md) · [`ossh.file.get.name`](ossh.md) · [`ossh.get`](ossh.md) · [`ossh.get.public.id`](ossh.md) · [`ossh.id.file.get`](ossh.md) · [`ossh.id.public.get`](ossh.md) · [`ossh.key.get.name`](ossh.md) · [`ossh.key.name.get`](ossh.md) · [`ossh.publicId.get`](ossh.md) · [`ossh.remote.prelude.get`](ossh.md) · [`ossh.server.get.ip`](ossh.md) · [`ossh.server.get.ip.darwin`](ossh.md) · [`ossh.server.get.ip.linux`](ossh.md) · [`ossh.server.get.port`](ossh.md) · [`ossh.server.ip.get`](ossh.md) · [`ossh.server.ip.get.darwin`](ossh.md) · [`ossh.server.ip.get.linux`](ossh.md) · [`ossh.server.port.get`](ossh.md) · [`ossh.ssh.parameter.get`](ossh.md) · [`ossh.url.get`](ossh.md) · [`private.get.sshDir`](ossh.md) · [`private.ossh.authorized.key.append.get`](ossh.md) · [`private.ossh.config.block.put.get`](ossh.md) · [`private.ossh.config.field.get`](ossh.md) · [`private.ossh.config.field.keyword.get`](ossh.md) · [`private.ossh.config.forwardAgent.get`](ossh.md) · [`private.ossh.config.hostName.get`](ossh.md) · [`private.ossh.config.identitiesOnly.get`](ossh.md) · [`private.ossh.config.identityFile.get`](ossh.md) · [`private.ossh.config.last.file.get`](ossh.md) · [`private.ossh.config.port.get`](ossh.md) · [`private.ossh.config.proxyJump.get`](ossh.md) · [`private.ossh.config.user.get`](ossh.md) · [`private.ossh.connection.error.get`](ossh.md) · [`private.ossh.control.path.get`](ossh.md) · [`private.ossh.control.path.resolved.get`](ossh.md) · [`private.ossh.get.config`](ossh.md) · [`private.ossh.get.current.key.file.name`](ossh.md) · [`private.ossh.get.file.name`](ossh.md) · [`private.ossh.get.key.name`](ossh.md) · [`private.ossh.get.public.id`](ossh.md) · [`private.ossh.get.server.ip`](ossh.md) · [`private.ossh.get.server.port`](ossh.md) · [`private.ossh.get.server.port.wrapper`](ossh.md) · [`private.ossh.get.ssh.parameter`](ossh.md) · [`private.ossh.get.url`](ossh.md) · [`private.ossh.host.fqdn.get`](ossh.md) · [`private.ossh.remote.key.file.name.get`](ossh.md) · [`private.ossh.system.config.file.get`](ossh.md) · [`private.ossh.system.known.hosts.get`](ossh.md) · [`private.ossh.user.homes.get`](ossh.md) |
| `ossh` | `harden` | [`ossh.harden`](ossh.md) · [`ossh.harden.fail2ban`](ossh.md) · [`ossh.harden.firewall`](ossh.md) · [`ossh.harden.packages`](ossh.md) · [`ossh.harden.sshd`](ossh.md) · [`ossh.harden.sshd.allowusers`](ossh.md) · [`ossh.harden.unattended.upgrades`](ossh.md) · [`private.ossh.harden.preflight`](ossh.md) |
| `ossh` | `init` | [`private.certificates.update.state.machine.init`](ossh.md) · [`private.push.init.oosh`](ossh.md) |
| `ossh` | `install` | [`ossh.create.and.install`](ossh.md) · [`ossh.install`](ossh.md) · [`ossh.install.user.remote`](ossh.md) · [`ossh.prereqs.install`](ossh.md) · [`private.ossh.install.key.authorize`](ossh.md) |
| `ossh` | `is` | [`private.ossh.connection.error.network.is`](ossh.md) · [`private.ossh.github.block.is.oosh`](ossh.md) |
| `ossh` | `isInstalled` | [`ossh.isInstalled`](ossh.md) |
| `ossh` | `list` | [`ossh.config.list`](ossh.md) · [`ossh.list`](ossh.md) · [`ossh.list.ids`](ossh.md) |
| `ossh` | `load` | [`private.certificates.update.config.load`](ossh.md) |
| `ossh` | `log` | [`ossh.install.log`](ossh.md) |
| `ossh` | `login` | [`ossh.login`](ossh.md) |
| `ossh` | `next` | [`private.check.next.custom.state`](ossh.md) |
| `ossh` | `normalize` | [`private.ossh.folder.fix.config.normalize`](ossh.md) |
| `ossh` | `open` | [`ossh.connection.open`](ossh.md) · [`ossh.list.open.ports`](ossh.md) |
| `ossh` | `parse` | [`ossh.config.parse`](ossh.md) · [`ossh.config.parse.url`](ossh.md) |
| `ossh` | `prune` | [`private.ossh.folder.fix.prune`](ossh.md) |
| `ossh` | `pull` | [`ossh.config.pull`](ossh.md) · [`ossh.dir.pull`](ossh.md) · [`ossh.id.pull`](ossh.md) · [`ossh.key.pull`](ossh.md) · [`ossh.pull.config`](ossh.md) · [`ossh.pull.dir`](ossh.md) · [`ossh.pull.id`](ossh.md) · [`ossh.pull.key`](ossh.md) · [`private.ossh.config.pull`](ossh.md) · [`private.ossh.dir.pull`](ossh.md) · [`private.ossh.key.pull`](ossh.md) · [`private.ossh.pull.id`](ossh.md) · [`private.ossh.rsync.pull`](ossh.md) |
| `ossh` | `push` | [`ossh.config.push`](ossh.md) · [`ossh.dir.push`](ossh.md) · [`ossh.id.push`](ossh.md) · [`ossh.key.push`](ossh.md) · [`ossh.push.config`](ossh.md) · [`ossh.push.dir`](ossh.md) · [`ossh.push.id`](ossh.md) · [`ossh.push.key`](ossh.md) · [`private.ossh.config.push`](ossh.md) · [`private.ossh.dir.push`](ossh.md) · [`private.ossh.id.push`](ossh.md) · [`private.ossh.key.push`](ossh.md) · [`private.ossh.oosh.init.push`](ossh.md) |
| `ossh` | `put` | [`private.ossh.remote.public.key.put`](ossh.md) |
| `ossh` | `read` | [`private.certificates.update.config.read`](ossh.md) |
| `ossh` | `remove` | [`ossh.known.hosts.remove`](ossh.md) · [`private.ossh.github.copies.remove`](ossh.md) · [`private.ossh.github.copy.remove`](ossh.md) · [`private.ossh.shared.ssh.legacy.remove`](ossh.md) |
| `ossh` | `restore` | [`private.check.certificates.update.restore.workspace`](ossh.md) |
| `ossh` | `rotate` | [`private.check.certificates.update.rotate.empty`](ossh.md) |
| `ossh` | `rsync` | [`private.ossh.rsync`](ossh.md) |
| `ossh` | `run` | [`private.certificates.update.ssh.run`](ossh.md) |
| `ossh` | `save` | [`ossh.config.save.last`](ossh.md) |
| `ossh` | `scan` | [`private.ossh.folder.fix.scan.git.remotes`](ossh.md) |
| `ossh` | `scp` | [`ossh.scp`](ossh.md) |
| `ossh` | `seed` | [`ossh.config.shared.seed.fallback`](ossh.md) · [`ossh.config.shared.seed.github`](ossh.md) |
| `ossh` | `set` | [`ossh.config.set`](ossh.md) · [`ossh.key.name.set`](ossh.md) · [`ossh.key.set.name`](ossh.md) · [`ossh.set`](ossh.md) · [`private.ossh.config.field.set`](ossh.md) · [`private.ossh.config.forwardAgent.set`](ossh.md) · [`private.ossh.config.hostName.set`](ossh.md) · [`private.ossh.config.identitiesOnly.set`](ossh.md) · [`private.ossh.config.identityFile.set`](ossh.md) · [`private.ossh.config.port.set`](ossh.md) · [`private.ossh.config.proxyJump.set`](ossh.md) · [`private.ossh.config.user.set`](ossh.md) · [`private.ossh.set.key.name`](ossh.md) |
| `ossh` | `show` | [`ossh.config.show.last`](ossh.md) · [`ossh.show`](ossh.md) |
| `ossh` | `stage` | [`private.ossh.identity.stage`](ossh.md) · [`private.ossh.identity.stage.outer.fromRunner`](ossh.md) · [`private.ossh.identity.stage.outer.proxyJump`](ossh.md) |
| `ossh` | `start` | [`private.check.certificates.update.start.structr`](ossh.md) |
| `ossh` | `stop` | [`private.check.certificates.update.stop.certbot`](ossh.md) · [`private.check.certificates.update.stop.structr`](ossh.md) |
| `ossh` | `strip` | [`private.ossh.folder.fix.config.strip.legacy`](ossh.md) |
| `ossh` | `test` | [`ossh.test`](ossh.md) |
| `ossh` | `update` | [`ossh.authorized.keys.update`](ossh.md) · [`ossh.authorized_keys.update`](ossh.md) · [`ossh.certificates.update`](ossh.md) · [`private.certificates.update.config.persist`](ossh.md) · [`private.certificates.update.machine.name`](ossh.md) · [`private.check.certificates.update.archive.workspace`](ossh.md) |
| `ossh` | `verify` | [`private.check.certificates.update.verify.https`](ossh.md) |
| `ossh` | `write` | [`private.ossh.config.deploy.write`](ossh.md) |
| `osshLayout` |  | [`osshLayout.id.from.email`](osshLayout.md) · [`osshLayout.role.developking`](osshLayout.md) · [`osshLayout.role.installer`](osshLayout.md) · [`osshLayout.role.outeruser`](osshLayout.md) · [`osshLayout.role.owner`](osshLayout.md) · [`private.osshLayout.owner.email`](osshLayout.md) · [`private.osshLayout.staged.dir`](osshLayout.md) · [`private.osshLayout.staged.email`](osshLayout.md) |
| `osshLayout` | `build` | [`osshLayout.build`](osshLayout.md) |
| `osshLayout` | `ensure` | [`private.osshLayout.ensure.keypair`](osshLayout.md) |
| `osshLayout` | `has` | [`private.osshLayout.staged.has.keypair`](osshLayout.md) · [`private.osshLayout.staged.has.privkey`](osshLayout.md) · [`private.osshLayout.staged.has.pubkey`](osshLayout.md) |
| `osshLayout` | `tighten` | [`private.osshLayout.perms.tighten`](osshLayout.md) |
| `osx` |  | [`osx.spotlight`](osx.md) · [`osx.spotlight.by.name`](osx.md) · [`osx.spotlight.by.size`](osx.md) · [`osx.spotlight.bykind`](osx.md) · [`osx.timemachine.settings`](osx.md) |
| `osx` | `collect` | [`osx.alias.collect.all.here`](osx.md) |
| `osx` | `create` | [`osx.alias.create`](osx.md) |
| `osx` | `find` | [`osx.alias.find.all`](osx.md) |
| `osx` | `fix` | [`osx.brew.fix`](osx.md) |
| `osx` | `install` | [`osx.install.bash5`](osx.md) · [`osx.install.homebrew`](osx.md) · [`osx.timemachine.settings.install`](osx.md) |
| `osx` | `link` | [`osx.alias.to.link`](osx.md) |
| `osx` | `list` | [`osx.file.metadata.list`](osx.md) · [`osx.timemachine.list`](osx.md) |
| `osx` | `show` | [`osx.alias.show.target`](osx.md) |
| `otest` |  | [`otest.here`](otest.md) · [`private.chromePath`](otest.md) · [`private.eamdRoot`](otest.md) · [`private.python`](otest.md) |
| `otest` | `deploy` | [`otest.deploy`](otest.md) |
| `otest` | `discoverTests` | [`private.discoverTests`](otest.md) |
| `otest` | `ensureDir` | [`private.ensureDir`](otest.md) |
| `otest` | `ensureVenv` | [`private.ensureVenv`](otest.md) |
| `otest` | `findEamdRoot` | [`private.findEamdRoot`](otest.md) |
| `otest` | `list` | [`otest.list`](otest.md) |
| `otest` | `mapName` | [`private.mapName`](otest.md) |
| `otest` | `newTest` | [`otest.newTest`](otest.md) |
| `otest` | `open` | [`otest.browser.open`](otest.md) |
| `otest` | `run` | [`otest.run`](otest.md) |
| `otest` | `runTest` | [`private.runTest`](otest.md) |
| `otest` | `setup` | [`otest.setup`](otest.md) |
| `otest` | `testExists` | [`private.testExists`](otest.md) |
| `otest` | `testNames` | [`private.testNames`](otest.md) · [`private.testNames.camel`](otest.md) |
| `otest` | `updateGolden` | [`otest.updateGolden`](otest.md) |
| `otmux` |  | [`otmux.256color`](otmux.md) · [`otmux.a`](otmux.md) · [`otmux.buffers`](otmux.md) · [`otmux.clients`](otmux.md) · [`otmux.clock`](otmux.md) · [`otmux.commands`](otmux.md) · [`otmux.composer.state`](otmux.md) · [`otmux.config`](otmux.md) · [`otmux.control`](otmux.md) · [`otmux.current`](otmux.md) · [`otmux.d`](otmux.md) · [`otmux.dp`](otmux.md) · [`otmux.if`](otmux.md) · [`otmux.info`](otmux.md) · [`otmux.keys`](otmux.md) · [`otmux.kp`](otmux.md) · [`otmux.kw`](otmux.md) · [`otmux.last`](otmux.md) · [`otmux.layout`](otmux.md) · [`otmux.layout.even.h`](otmux.md) · [`otmux.layout.even.v`](otmux.md) · [`otmux.layout.main.h`](otmux.md) · [`otmux.layout.main.v`](otmux.md) · [`otmux.layout.tiled`](otmux.md) · [`otmux.left`](otmux.md) · [`otmux.lsb`](otmux.md) · [`otmux.lsc`](otmux.md) · [`otmux.lscm`](otmux.md) · [`otmux.lsk`](otmux.md) · [`otmux.lsp`](otmux.md) · [`otmux.lsw`](otmux.md) · [`otmux.menu`](otmux.md) · [`otmux.msg`](otmux.md) · [`otmux.nw`](otmux.md) · [`otmux.pane.history`](otmux.md) · [`otmux.pane.last`](otmux.md) · [`otmux.pane.left`](otmux.md) · [`otmux.pane.right`](otmux.md) · [`otmux.pane.self`](otmux.md) · [`otmux.pane.size`](otmux.md) · [`otmux.pane.title`](otmux.md) · [`otmux.panes`](otmux.md) · [`otmux.right`](otmux.md) · [`otmux.rp`](otmux.md) · [`otmux.rw`](otmux.md) · [`otmux.server.info`](otmux.md) · [`otmux.session.details`](otmux.md) · [`otmux.session.last`](otmux.md) · [`otmux.sessions`](otmux.md) · [`otmux.size.status`](otmux.md) · [`otmux.socket`](otmux.md) · [`otmux.sp`](otmux.md) · [`otmux.status`](otmux.md) · [`otmux.sw`](otmux.md) · [`otmux.tiled`](otmux.md) · [`otmux.tree`](otmux.md) · [`otmux.tree.detailed`](otmux.md) · [`otmux.utf8`](otmux.md) · [`otmux.v`](otmux.md) · [`otmux.verbose`](otmux.md) · [`otmux.version`](otmux.md) · [`otmux.window.last`](otmux.md) · [`otmux.window.size`](otmux.md) · [`otmux.window.size.status`](otmux.md) · [`otmux.windows`](otmux.md) · [`otmux.z`](otmux.md) · [`private.default.config`](otmux.md) · [`private.otmux.configPath`](otmux.md) · [`private.otmux.evenH`](otmux.md) · [`private.otmux.evenV`](otmux.md) · [`private.otmux.lastPane`](otmux.md) · [`private.otmux.lastWindow`](otmux.md) · [`private.otmux.mainH`](otmux.md) · [`private.otmux.mainV`](otmux.md) · [`private.otmux.notifyHiveMind.shifted`](otmux.md) · [`private.otmux.self.session`](otmux.md) · [`private.otmux.sessionFromPane`](otmux.md) · [`private.otmux.size.currentSession`](otmux.md) · [`private.otmux.socketPath`](otmux.md) |
| `otmux` | `apply` | [`otmux.window.size.floor.apply`](otmux.md) · [`private.otmux.setup.clipboard.apply`](otmux.md) |
| `otmux` | `attach` | [`otmux.attach`](otmux.md) · [`otmux.attach.readonly`](otmux.md) · [`otmux.session.attach`](otmux.md) |
| `otmux` | `bind` | [`otmux.bind`](otmux.md) · [`otmux.key.bind`](otmux.md) |
| `otmux` | `break` | [`otmux.pane.break`](otmux.md) |
| `otmux` | `breakPane` | [`private.otmux.breakPane`](otmux.md) |
| `otmux` | `capture` | [`otmux.pane.capture`](otmux.md) · [`otmux.pane.capture.full`](otmux.md) · [`otmux.pane.capture.visible`](otmux.md) |
| `otmux` | `capturePane` | [`private.otmux.capturePane`](otmux.md) |
| `otmux` | `choose` | [`otmux.buffer.choose`](otmux.md) · [`otmux.client.choose`](otmux.md) · [`otmux.client.choose.tree`](otmux.md) |
| `otmux` | `chooseBuffer` | [`private.otmux.chooseBuffer`](otmux.md) |
| `otmux` | `chooseClient` | [`private.otmux.chooseClient`](otmux.md) |
| `otmux` | `chooseTree` | [`private.otmux.chooseTree`](otmux.md) |
| `otmux` | `cleanup` | [`otmux.client.cleanup`](otmux.md) · [`private.otmux.size.lock.cleanup`](otmux.md) |
| `otmux` | `clear` | [`otmux.pane.history.clear`](otmux.md) |
| `otmux` | `clearHistory` | [`private.otmux.clearHistory`](otmux.md) |
| `otmux` | `complete` | [`private.complete.buffers`](otmux.md) · [`private.complete.clients`](otmux.md) · [`private.complete.panes`](otmux.md) · [`private.complete.sessions`](otmux.md) · [`private.complete.windows`](otmux.md) |
| `otmux` | `confirm` | [`otmux.confirm`](otmux.md) · [`otmux.send.confirm`](otmux.md) |
| `otmux` | `copy` | [`otmux.copy`](otmux.md) · [`otmux.copy.clock`](otmux.md) · [`otmux.copy.mode`](otmux.md) |
| `otmux` | `delete` | [`otmux.buffer.delete`](otmux.md) · [`otmux.layout.delete`](otmux.md) |
| `otmux` | `deleteBuffer` | [`private.otmux.deleteBuffer`](otmux.md) |
| `otmux` | `detach` | [`otmux.client.detach`](otmux.md) · [`otmux.detach`](otmux.md) · [`otmux.session.detach`](otmux.md) |
| `otmux` | `detachClient` | [`private.otmux.detachClient`](otmux.md) |
| `otmux` | `display` | [`otmux.display`](otmux.md) · [`otmux.pane.display`](otmux.md) · [`otmux.send.display`](otmux.md) |
| `otmux` | `displayPanes` | [`private.otmux.displayPanes`](otmux.md) |
| `otmux` | `down` | [`otmux.down`](otmux.md) · [`otmux.pane.down`](otmux.md) |
| `otmux` | `enter` | [`otmux.send.enter`](otmux.md) |
| `otmux` | `find` | [`otmux.window.find`](otmux.md) |
| `otmux` | `findWindow` | [`private.otmux.findWindow`](otmux.md) |
| `otmux` | `fit` | [`otmux.fit`](otmux.md) |
| `otmux` | `format` | [`otmux.pane.list.format`](otmux.md) · [`otmux.window.list.format`](otmux.md) |
| `otmux` | `get` | [`otmux.pane.get`](otmux.md) · [`otmux.pane.get.target`](otmux.md) · [`otmux.window.get`](otmux.md) · [`otmux.window.get.target`](otmux.md) · [`otmux.window.layout.get`](otmux.md) |
| `otmux` | `has` | [`otmux.has`](otmux.md) · [`otmux.session.has`](otmux.md) · [`private.otmux.size.lock.has`](otmux.md) |
| `otmux` | `help` | [`otmux.help`](otmux.md) |
| `otmux` | `init` | [`otmux.config.init`](otmux.md) |
| `otmux` | `install` | [`otmux.install`](otmux.md) |
| `otmux` | `is` | [`private.otmux.is.key`](otmux.md) |
| `otmux` | `isClaudeCode` | [`private.otmux.pane.isClaudeCode`](otmux.md) |
| `otmux` | `isPane` | [`private.otmux.target.isPane`](otmux.md) |
| `otmux` | `join` | [`otmux.pane.join`](otmux.md) |
| `otmux` | `joinPane` | [`private.otmux.joinPane`](otmux.md) |
| `otmux` | `kill` | [`otmux.kill`](otmux.md) · [`otmux.pane.kill`](otmux.md) · [`otmux.server.kill`](otmux.md) · [`otmux.session.kill`](otmux.md) · [`otmux.session.kill.all`](otmux.md) · [`otmux.window.kill`](otmux.md) |
| `otmux` | `killAll` | [`private.otmux.killAll`](otmux.md) |
| `otmux` | `killPane` | [`private.otmux.killPane`](otmux.md) |
| `otmux` | `killServer` | [`private.otmux.killServer`](otmux.md) |
| `otmux` | `killWindow` | [`private.otmux.killWindow`](otmux.md) |
| `otmux` | `link` | [`otmux.window.link`](otmux.md) |
| `otmux` | `linkWindow` | [`private.otmux.linkWindow`](otmux.md) |
| `otmux` | `list` | [`otmux.buffer.list`](otmux.md) · [`otmux.client.list`](otmux.md) · [`otmux.key.list`](otmux.md) · [`otmux.layout.list`](otmux.md) · [`otmux.pane.list`](otmux.md) · [`otmux.session.list`](otmux.md) · [`otmux.window.list`](otmux.md) · [`private.otmux.size.lock.list`](otmux.md) |
| `otmux` | `load` | [`otmux.buffer.load`](otmux.md) |
| `otmux` | `loadBuffer` | [`private.otmux.loadBuffer`](otmux.md) |
| `otmux` | `lock` | [`otmux.client.lock`](otmux.md) · [`otmux.lock`](otmux.md) · [`otmux.pane.lock`](otmux.md) · [`otmux.server.lock`](otmux.md) · [`otmux.session.lock`](otmux.md) · [`otmux.size.lock`](otmux.md) · [`otmux.window.size.lock`](otmux.md) · [`private.otmux.pane.lock.killEnforcers`](otmux.md) |
| `otmux` | `lockClient` | [`private.otmux.lockClient`](otmux.md) |
| `otmux` | `lockServer` | [`private.otmux.lockServer`](otmux.md) |
| `otmux` | `ls` | [`otmux.ls`](otmux.md) |
| `otmux` | `move` | [`otmux.pane.move`](otmux.md) · [`otmux.window.move`](otmux.md) |
| `otmux` | `movePane` | [`private.otmux.movePane`](otmux.md) |
| `otmux` | `moveWindow` | [`private.otmux.moveWindow`](otmux.md) |
| `otmux` | `new` | [`otmux.new`](otmux.md) · [`otmux.session.new`](otmux.md) · [`otmux.window.new`](otmux.md) |
| `otmux` | `newWindow` | [`private.otmux.newWindow`](otmux.md) |
| `otmux` | `next` | [`otmux.layout.next`](otmux.md) · [`otmux.next`](otmux.md) · [`otmux.session.next`](otmux.md) · [`otmux.window.next`](otmux.md) |
| `otmux` | `nextLayout` | [`private.otmux.nextLayout`](otmux.md) |
| `otmux` | `nextWindow` | [`private.otmux.nextWindow`](otmux.md) |
| `otmux` | `paste` | [`otmux.buffer.paste`](otmux.md) · [`otmux.paste`](otmux.md) |
| `otmux` | `pasteBuffer` | [`private.otmux.pasteBuffer`](otmux.md) |
| `otmux` | `pipe` | [`otmux.pane.pipe`](otmux.md) |
| `otmux` | `pipePane` | [`private.otmux.pipePane`](otmux.md) |
| `otmux` | `prev` | [`otmux.layout.prev`](otmux.md) · [`otmux.prev`](otmux.md) · [`otmux.session.prev`](otmux.md) · [`otmux.window.prev`](otmux.md) |
| `otmux` | `prevLayout` | [`private.otmux.prevLayout`](otmux.md) |
| `otmux` | `prevWindow` | [`private.otmux.prevWindow`](otmux.md) |
| `otmux` | `prompt` | [`otmux.prompt`](otmux.md) · [`otmux.send.prompt`](otmux.md) |
| `otmux` | `refresh` | [`otmux.client.refresh`](otmux.md) |
| `otmux` | `refreshClient` | [`private.otmux.refreshClient`](otmux.md) |
| `otmux` | `reload` | [`otmux.reload`](otmux.md) |
| `otmux` | `remove` | [`private.otmux.size.lock.remove`](otmux.md) |
| `otmux` | `rename` | [`otmux.rename`](otmux.md) · [`otmux.session.rename`](otmux.md) · [`otmux.window.rename`](otmux.md) |
| `otmux` | `renameWindow` | [`private.otmux.renameWindow`](otmux.md) |
| `otmux` | `reset` | [`otmux.config.reset`](otmux.md) |
| `otmux` | `resize` | [`otmux.pane.resize`](otmux.md) · [`otmux.window.aggressive.resize`](otmux.md) |
| `otmux` | `resizePane` | [`private.otmux.resizePane`](otmux.md) |
| `otmux` | `resolve` | [`private.otmux.pane.resolve`](otmux.md) · [`private.resolve.target`](otmux.md) |
| `otmux` | `respawn` | [`otmux.pane.respawn`](otmux.md) · [`otmux.window.respawn`](otmux.md) |
| `otmux` | `respawnPane` | [`private.otmux.respawnPane`](otmux.md) |
| `otmux` | `respawnWindow` | [`private.otmux.respawnWindow`](otmux.md) |
| `otmux` | `restore` | [`otmux.layout.restore`](otmux.md) |
| `otmux` | `rotate` | [`otmux.window.rotate`](otmux.md) |
| `otmux` | `rotateWindow` | [`private.otmux.rotateWindow`](otmux.md) |
| `otmux` | `run` | [`otmux.run`](otmux.md) · [`otmux.send.run`](otmux.md) |
| `otmux` | `save` | [`otmux.buffer.save`](otmux.md) · [`otmux.layout.save`](otmux.md) |
| `otmux` | `saveBuffer` | [`private.otmux.saveBuffer`](otmux.md) |
| `otmux` | `select` | [`otmux.pane.select`](otmux.md) · [`otmux.window.select`](otmux.md) |
| `otmux` | `selectPane` | [`private.otmux.selectPane`](otmux.md) |
| `otmux` | `selectWindow` | [`private.otmux.selectWindow`](otmux.md) |
| `otmux` | `send` | [`otmux.pane.send`](otmux.md) · [`otmux.send`](otmux.md) · [`otmux.send.key`](otmux.md) · [`otmux.send.keys`](otmux.md) · [`otmux.send.menu`](otmux.md) · [`otmux.send.raw`](otmux.md) · [`otmux.send.tui`](otmux.md) · [`otmux.send.verified`](otmux.md) · [`private.otmux.send.prefix`](otmux.md) · [`private.otmux.send.smart`](otmux.md) |
| `otmux` | `sendEnter` | [`private.otmux.sendEnter`](otmux.md) |
| `otmux` | `sendKeys` | [`private.otmux.sendKeys`](otmux.md) |
| `otmux` | `set` | [`otmux.buffer.set`](otmux.md) · [`otmux.config.set`](otmux.md) · [`otmux.config.set.global`](otmux.md) · [`otmux.config.set.hook`](otmux.md) · [`otmux.config.set.window`](otmux.md) · [`otmux.env.set`](otmux.md) · [`otmux.layout.set`](otmux.md) · [`otmux.pane.size.set`](otmux.md) · [`otmux.set`](otmux.md) · [`otmux.window.layout.set`](otmux.md) · [`private.otmux.size.lock.set`](otmux.md) |
| `otmux` | `setBuffer` | [`private.otmux.setBuffer`](otmux.md) |
| `otmux` | `setEnv` | [`private.otmux.setEnv`](otmux.md) |
| `otmux` | `setGlobal` | [`private.otmux.setGlobal`](otmux.md) |
| `otmux` | `setHook` | [`private.otmux.setHook`](otmux.md) |
| `otmux` | `setWindow` | [`private.otmux.setWindow`](otmux.md) |
| `otmux` | `setup` | [`otmux.setup.clipboard.local`](otmux.md) · [`otmux.setup.clipboard.remote`](otmux.md) · [`otmux.setup.default`](otmux.md) · [`otmux.tronMonitor.setup`](otmux.md) · [`private.otmux.setup.clipboard`](otmux.md) · [`private.otmux.setup.clipboard.darwin`](otmux.md) · [`private.otmux.setup.clipboard.linux`](otmux.md) · [`private.otmux.setup.clipboard.osc52`](otmux.md) |
| `otmux` | `show` | [`otmux.buffer.show`](otmux.md) · [`otmux.config.show`](otmux.md) · [`otmux.config.show.global`](otmux.md) · [`otmux.config.show.hooks`](otmux.md) · [`otmux.config.show.window`](otmux.md) · [`otmux.env.show`](otmux.md) · [`otmux.layout.show`](otmux.md) · [`otmux.show`](otmux.md) |
| `otmux` | `showBuffer` | [`private.otmux.showBuffer`](otmux.md) |
| `otmux` | `showEnv` | [`private.otmux.showEnv`](otmux.md) |
| `otmux` | `showGlobal` | [`private.otmux.showGlobal`](otmux.md) |
| `otmux` | `showHooks` | [`private.otmux.showHooks`](otmux.md) |
| `otmux` | `showMessages` | [`private.otmux.showMessages`](otmux.md) |
| `otmux` | `showWindow` | [`private.otmux.showWindow`](otmux.md) |
| `otmux` | `source` | [`otmux.config.source`](otmux.md) · [`otmux.source`](otmux.md) |
| `otmux` | `split` | [`otmux.pane.split`](otmux.md) · [`otmux.pane.split.h`](otmux.md) · [`otmux.pane.split.v`](otmux.md) · [`otmux.split`](otmux.md) · [`otmux.split.h`](otmux.md) · [`otmux.split.v`](otmux.md) |
| `otmux` | `splitH` | [`otmux.pane.splitH`](otmux.md) · [`private.otmux.splitH`](otmux.md) |
| `otmux` | `splitV` | [`private.otmux.splitV`](otmux.md) |
| `otmux` | `startServer` | [`private.otmux.startServer`](otmux.md) |
| `otmux` | `suspend` | [`otmux.client.suspend`](otmux.md) |
| `otmux` | `suspendClient` | [`private.otmux.suspendClient`](otmux.md) |
| `otmux` | `swap` | [`otmux.pane.swap`](otmux.md) · [`otmux.window.swap`](otmux.md) |
| `otmux` | `swapPane` | [`private.otmux.swapPane`](otmux.md) |
| `otmux` | `swapWindow` | [`private.otmux.swapWindow`](otmux.md) |
| `otmux` | `switch` | [`otmux.session.switch`](otmux.md) · [`otmux.switch`](otmux.md) |
| `otmux` | `unbind` | [`otmux.key.unbind`](otmux.md) · [`otmux.unbind`](otmux.md) |
| `otmux` | `unlink` | [`otmux.window.unlink`](otmux.md) |
| `otmux` | `unlinkWindow` | [`private.otmux.unlinkWindow`](otmux.md) |
| `otmux` | `unlock` | [`otmux.pane.unlock`](otmux.md) · [`otmux.size.unlock`](otmux.md) · [`otmux.window.size.unlock`](otmux.md) |
| `otmux` | `up` | [`otmux.pane.up`](otmux.md) · [`otmux.up`](otmux.md) |
| `otmux` | `wait` | [`otmux.wait`](otmux.md) |
| `otmux` | `zoom` | [`otmux.pane.zoom`](otmux.md) · [`otmux.zoom`](otmux.md) |
| `outeruser` |  | [`osshLayout.role.outeruser`](osshLayout.md) |
| `output` |  | [`claudeCode.output`](claudeCode.md) |
| `overlay` |  | [`private.hiveMind.agent.overlay.key`](hivemind.md) |
| `overlay` | `dispatch` | [`private.hiveMind.agent.overlay.dispatch`](hivemind.md) |
| `overlayState` |  | [`private.hiveMind.agent.overlay.key`](hivemind.md) |
| `owner` |  | [`osshLayout.role.owner`](osshLayout.md) · [`private.osshLayout.owner.email`](osshLayout.md) |
| `owner` | `ensure` | [`private.ensure.sharedTree`](this.md) · [`private.this.shared.top.ensure`](this.md) |
| `owner` | `get` | [`private.user.path.owner.get`](user.md) |
| `owner` | `set` | [`private.this.path.owner.set`](this.md) |
| `ownsProcess` |  | [`private.osemvec.ownsProcess`](osemvec.md) |
| `p` |  | [`claudeCode.p`](claudeCode.md) |
| `package` | `get` | [`private.odocker.prereq.package.get`](odocker.md) · [`private.setup.package.get`](setup.md) |
| `packageManagerBinary` | `get` | [`private.config.pm.command.get`](config.md) |
| `packageName` |  | [`oo.cmd`](oo.md) |
| `pacstall` |  | [`setup.pacstall`](setup.md) |
| `pane` |  | [`claudeCode.context.alert`](claudeCode.md) · [`claudeCode.context.jsonl`](claudeCode.md) · [`claudeCode.context.velocity.byPane`](claudeCode.md) · [`claudeCode.process.running`](claudeCode.md) · [`claudeCode.session.current`](claudeCode.md) · [`claudeCode.session.id`](claudeCode.md) · [`claudeCode.session.state`](claudeCode.md) · [`claudeFlow.hive.status`](claudeFlow.md) · [`claudeFlow.tmux.pane`](claudeFlow.md) · [`hiveMind.protected.pane.moved`](hivemind.md) · [`otmux.composer.state`](otmux.md) · [`otmux.kp`](otmux.md) · [`otmux.pane.history`](otmux.md) · [`otmux.pane.last`](otmux.md) · [`otmux.pane.left`](otmux.md) · [`otmux.pane.right`](otmux.md) · [`otmux.pane.self`](otmux.md) · [`otmux.pane.size`](otmux.md) · [`otmux.pane.title`](otmux.md) · [`private.hiveMind.agent.queue.depth`](hivemind.md) · [`private.hiveMind.agent.queue.path`](hivemind.md) · [`private.hiveMind.context.denom.for.target`](hivemind.md) · [`private.hiveMind.context.from.jsonl.reading`](hivemind.md) · [`private.hiveMind.context.live.jsonl`](hivemind.md) · [`private.hiveMind.handler.pane.moved.registry`](hivemind.md) · [`private.hiveMind.handler.pane.moved.role_env`](hivemind.md) · [`private.hiveMind.pane.activity`](hivemind.md) · [`private.hiveMind.pane.for.agent`](hivemind.md) · [`private.hiveMind.pane.kind`](hivemind.md) · [`private.hiveMind.pane.model`](hivemind.md) · [`private.otmux.sessionFromPane`](otmux.md) · [`private.tronMonitor.pane`](tronMonitor.md) |
| `pane` | `approve` | [`hiveMind.monitor.approve`](hivemind.md) |
| `pane` | `bootstrap` | [`hiveMind.agent.bootstrap`](hivemind.md) |
| `pane` | `break` | [`otmux.pane.break`](otmux.md) |
| `pane` | `capture` | [`otmux.pane.capture`](otmux.md) · [`otmux.pane.capture.full`](otmux.md) · [`otmux.pane.capture.visible`](otmux.md) · [`scrumMaster.pane.capture`](scrumMaster.md) |
| `pane` | `check` | [`claudeCode.context.check`](claudeCode.md) |
| `pane` | `clear` | [`otmux.pane.history.clear`](otmux.md) |
| `pane` | `count` | [`private.hiveMind.pane.count`](hivemind.md) |
| `pane` | `create` | [`hiveMind.pane.create`](hivemind.md) |
| `pane` | `delegate` | [`hiveMind.task.delegate`](hivemind.md) |
| `pane` | `discover` | [`private.claudeCode.session.discover`](claudeCode.md) |
| `pane` | `display` | [`otmux.pane.display`](otmux.md) |
| `pane` | `down` | [`otmux.pane.down`](otmux.md) |
| `pane` | `enqueue` | [`private.hiveMind.agent.queue.enqueue`](hivemind.md) |
| `pane` | `find` | [`claudeCode.process.find`](claudeCode.md) |
| `pane` | `focus` | [`hiveMind.pane.focus`](hivemind.md) |
| `pane` | `fork` | [`claudeCode.fork.byPane`](claudeCode.md) · [`claudeCode.fork.to`](claudeCode.md) |
| `pane` | `format` | [`otmux.pane.list.format`](otmux.md) |
| `pane` | `get` | [`claudeCode.model.get`](claudeCode.md) · [`otmux.pane.get`](otmux.md) · [`otmux.pane.get.target`](otmux.md) |
| `pane` | `guard` | [`osemvec.guard`](osemvec.md) |
| `pane` | `identify` | [`private.hiveMind.pane.identify`](hivemind.md) |
| `pane` | `inform` | [`private.hiveMind.agent.inform`](hivemind.md) |
| `pane` | `isClaudeCode` | [`private.otmux.pane.isClaudeCode`](otmux.md) |
| `pane` | `isRecent` | [`private.hiveMind.registry.isRecent`](hivemind.md) |
| `pane` | `isValid` | [`private.tronMonitor.pane.isValid`](tronMonitor.md) |
| `pane` | `join` | [`claudeCode.join.byPane`](claudeCode.md) · [`otmux.pane.join`](otmux.md) |
| `pane` | `kill` | [`otmux.pane.kill`](otmux.md) |
| `pane` | `list` | [`otmux.pane.list`](otmux.md) |
| `pane` | `lock` | [`otmux.pane.lock`](otmux.md) · [`private.otmux.pane.lock.killEnforcers`](otmux.md) |
| `pane` | `loop` | [`hiveMind.pane.sweep.loop`](hivemind.md) |
| `pane` | `measure` | [`scrumMaster.pane.measure`](scrumMaster.md) |
| `pane` | `move` | [`otmux.pane.move`](otmux.md) |
| `pane` | `pipe` | [`otmux.pane.pipe`](otmux.md) |
| `pane` | `probe` | [`claudeCode.session.probe`](claudeCode.md) |
| `pane` | `pushRoleEnv` | [`private.hiveMind.pane.pushRoleEnv`](hivemind.md) |
| `pane` | `read` | [`claudeCode.context.read`](claudeCode.md) · [`claudeCode.context.read.tui`](claudeCode.md) · [`private.claudeCode.context.read.tui`](claudeCode.md) |
| `pane` | `recover` | [`claudeCode.recover`](claudeCode.md) |
| `pane` | `remove` | [`hiveMind.registry.remove`](hivemind.md) |
| `pane` | `resize` | [`otmux.pane.resize`](otmux.md) |
| `pane` | `resolve` | [`hiveMind.protected.identity.resolve`](hivemind.md) · [`private.claudeCode.resolve.byPane`](claudeCode.md) · [`private.hiveMind.identity.resolve`](hivemind.md) · [`private.hiveMind.session.resolve.uuid`](hivemind.md) · [`private.otmux.pane.resolve`](otmux.md) |
| `pane` | `respawn` | [`otmux.pane.respawn`](otmux.md) |
| `pane` | `restart` | [`hiveMind.agent.restart.remote`](hivemind.md) |
| `pane` | `rewind` | [`private.scrumMaster.rewind.markname`](scrumMaster.md) |
| `pane` | `route` | [`private.hiveMind.agent.route`](hivemind.md) |
| `pane` | `select` | [`otmux.pane.select`](otmux.md) |
| `pane` | `send` | [`otmux.pane.send`](otmux.md) |
| `pane` | `set` | [`claudeCode.model.set`](claudeCode.md) · [`hiveMind.registry.set`](hivemind.md) · [`otmux.pane.size.set`](otmux.md) |
| `pane` | `setup` | [`otmux.tronMonitor.setup`](otmux.md) |
| `pane` | `split` | [`otmux.pane.split`](otmux.md) · [`otmux.pane.split.h`](otmux.md) · [`otmux.pane.split.v`](otmux.md) |
| `pane` | `splitH` | [`otmux.pane.splitH`](otmux.md) |
| `pane` | `stop` | [`claudeCode.stop`](claudeCode.md) |
| `pane` | `store` | [`private.hiveMind.session.store.deferred`](hivemind.md) |
| `pane` | `swap` | [`otmux.pane.swap`](otmux.md) |
| `pane` | `sweep` | [`hiveMind.pane.sweep`](hivemind.md) · [`hiveMind.pane.sweep.cycle`](hivemind.md) |
| `pane` | `teach` | [`hiveMind.role.teach`](hivemind.md) · [`hiveMind.teach`](hivemind.md) |
| `pane` | `unlock` | [`otmux.pane.unlock`](otmux.md) |
| `pane` | `up` | [`otmux.pane.up`](otmux.md) |
| `pane` | `verify` | [`hiveMind.agent.verify`](hivemind.md) |
| `pane` | `zoom` | [`otmux.pane.zoom`](otmux.md) |
| `paneA` |  | [`hiveMind.protected.panes.swapped`](hivemind.md) |
| `paneAlive` | `classify` | [`private.hiveMind.shell.classify`](hivemind.md) |
| `paneB` |  | [`hiveMind.protected.panes.swapped`](hivemind.md) |
| `paneContent` | `parse` | [`private.scrumMaster.parse.state`](scrumMaster.md) · [`private.scrumMaster.parse.timing`](scrumMaster.md) · [`private.scrumMaster.parse.tokens`](scrumMaster.md) |
| `paneOrJsonl` |  | [`claudeCode.context.velocity`](claudeCode.md) |
| `paneTarget` |  | [`private.hiveMind.liveUuid`](hivemind.md) · [`private.hiveMind.pane.kind`](hivemind.md) · [`private.hiveMind.pane.model`](hivemind.md) |
| `paneTarget` | `switch` | [`private.hiveMind.monitor.switch`](hivemind.md) |
| `paneTarget` | `wait` | [`private.hiveMind.wait.for.claude`](hivemind.md) |
| `pane_pid` | `classify` | [`private.hiveMind.shell.classify`](hivemind.md) |
| `panes` |  | [`hiveMind.panes`](hivemind.md) · [`hiveMind.protected.panes.shifted`](hivemind.md) · [`hiveMind.protected.panes.swapped`](hivemind.md) · [`log.live.panes`](log.md) · [`otmux.panes`](otmux.md) · [`private.hiveMind.handler.panes.shifted.registry`](hivemind.md) · [`private.hiveMind.handler.panes.swapped.registry`](hivemind.md) · [`private.hiveMind.handler.panes.swapped.role_env`](hivemind.md) |
| `panes` | `stop` | [`log.live.panes.stop`](log.md) |
| `param` | `declare` | [`line.param.declare`](line.md) |
| `param` | `new` | [`line.parse.param.new`](line.md) |
| `paramList` | `new` | [`line.parse.paramList.new`](line.md) |
| `parameter` | `get` | [`c2.function.parameter.get`](c2.md) · [`line.parameter.get`](line.md) · [`ossh.ssh.parameter.get`](ossh.md) |
| `parameterTestScript` |  | [`parameterTestScript.apostropheDesc`](parameterTestScript.md) · [`parameterTestScript.none`](parameterTestScript.md) · [`parameterTestScript.one`](parameterTestScript.md) · [`parameterTestScript.oneDefaultValue`](parameterTestScript.md) · [`parameterTestScript.oneDefaultValueQuotes`](parameterTestScript.md) · [`parameterTestScript.optional`](parameterTestScript.md) · [`parameterTestScript.optionalDefaultValue`](parameterTestScript.md) |
| `parameterTestScript` | `noop` | [`parameterTestScript.noop`](parameterTestScript.md) |
| `parameters` | `get` | [`private.oo.method.stubs.get`](oo.md) |
| `parse` | `check` | [`os.platform.parse.check`](os.md) |
| `parse` | `new` | [`line.parse.param.new`](line.md) · [`line.parse.paramList.new`](line.md) |
| `parse` | `normalize` | [`private.scrumMaster.parse.normalize.k`](scrumMaster.md) |
| `partial` |  | [`this.function.partial`](this.md) |
| `passed` |  | [`private.test.suite.verdict`](test.suite.md) |
| `passwd` | `get` | [`private.odocker.passwd.users.get`](odocker.md) |
| `password` |  | [`private.setup.samba.password.darwin`](setup.md) · [`private.setup.samba.password.linux`](setup.md) · [`private.setup.vnc.password.darwin`](setup.md) · [`private.setup.vnc.password.linux`](setup.md) · [`setup.samba.password`](setup.md) · [`setup.vnc.password`](setup.md) |
| `password` | `create` | [`user.create`](user.md) |
| `password` | `set` | [`user.password.set`](user.md) · [`user.password.set.darwin`](user.md) · [`user.password.set.linux`](user.md) |
| `path` |  | [`c2.folders`](c2.md) · [`path.env`](path.md) · [`path.file.custom`](path.md) · [`path.file.global`](path.md) · [`path.file.user`](path.md) · [`path.saved`](path.md) · [`path.status`](path.md) · [`private.claudeCode.projectHash`](claudeCode.md) · [`private.hiveMind.agent.queue.path`](hivemind.md) · [`private.hiveMind.snapshot.jsonl.path`](hivemind.md) · [`private.otmux.socketPath`](otmux.md) · [`private.this.path.canonical`](this.md) · [`status.path`](status.md) · [`this.absolutePath`](this.md) · [`this.absolutePathName`](this.md) |
| `path` | `add` | [`ogit.safeDirectory.add`](ogit.md) · [`path.add`](path.md) · [`this.path.add`](this.md) |
| `path` | `append` | [`path.append`](path.md) |
| `path` | `dedup` | [`private.this.path.dedup`](this.md) |
| `path` | `delete` | [`ogit.worktree.delete`](ogit.md) |
| `path` | `edit` | [`path.edit`](path.md) · [`path.file.user.edit`](path.md) |
| `path` | `fix` | [`hiveMind.path.fix`](hivemind.md) |
| `path` | `get` | [`backup.path.get.relative`](backup.md) · [`odocker.workspace.get`](odocker.md) · [`private.config.path.line.absolute.get`](config.md) · [`private.config.path.line.get`](config.md) · [`private.config.path.segments.get`](config.md) · [`private.config.required.file.path.get`](config.md) · [`private.odocker.workspaces.source.path.get`](odocker.md) · [`private.oo.path.sudo.get`](oo.md) · [`private.ossh.control.path.get`](ossh.md) · [`private.ossh.control.path.resolved.get`](ossh.md) · [`private.test.suite.ssh.mode.get`](test.suite.md) · [`private.this.path.case.get`](this.md) · [`private.this.path.stat.get`](this.md) · [`private.user.path.owner.get`](user.md) |
| `path` | `init` | [`claudeCode.init`](claudeCode.md) · [`claudeFlow.init`](claudeFlow.md) · [`log.install.init`](log.md) · [`odocker.workspace.init`](odocker.md) |
| `path` | `install` | [`oo.install`](oo.md) · [`private.odocker.workspaces.install`](odocker.md) |
| `path` | `is` | [`private.oo.path.writable.is`](oo.md) |
| `path` | `join` | [`private.path.lines.join`](path.md) |
| `path` | `list` | [`path.list`](path.md) |
| `path` | `load` | [`path.load`](path.md) |
| `path` | `migrate` | [`private.oo.once.path.migrate`](oo.md) |
| `path` | `pathadd` | [`private.pathadd`](path.md) |
| `path` | `pathrm` | [`private.pathrm`](path.md) |
| `path` | `prepend` | [`path.prepend`](path.md) |
| `path` | `push` | [`path.push`](path.md) |
| `path` | `put` | [`path.put`](path.md) |
| `path` | `remove` | [`ogit.index.remove`](ogit.md) · [`path.remove`](path.md) |
| `path` | `rm` | [`path.rm`](path.md) |
| `path` | `save` | [`path.file.user.save`](path.md) · [`path.save`](path.md) |
| `path` | `seed` | [`odocker.workspace.seed`](odocker.md) |
| `path` | `set` | [`odocker.workspace.set`](odocker.md) · [`oo.mode.base.set`](oo.md) · [`path.file.user.set`](path.md) · [`private.this.path.owner.set`](this.md) |
| `path` | `show` | [`path.show.once.path`](path.md) · [`path.show.oosh.path`](path.md) |
| `path` | `sync` | [`path.sync`](path.md) |
| `path` | `test` | [`c2.test.absolutePathName`](c2.md) |
| `path` | `update` | [`private.update.config`](path.md) |
| `path` | `validate` | [`path.validate`](path.md) · [`this.config.path.validate`](this.md) |
| `paths` | `add` | [`ogit.index.add`](ogit.md) |
| `paths` | `check` | [`ogit.diff.check`](ogit.md) |
| `paths` | `get` | [`private.ogit.worktree.paths.get`](ogit.md) |
| `pathspecs` | `grep` | [`ogit.repo.grep`](ogit.md) |
| `pattern` | `find` | [`otmux.window.find`](otmux.md) |
| `pattern` | `findWindow` | [`private.otmux.findWindow`](otmux.md) |
| `pattern` | `get` | [`ogit.tag.latest.get`](ogit.md) |
| `pattern` | `grep` | [`ogit.repo.grep`](ogit.md) |
| `pattern` | `list` | [`ogit.tag.list`](ogit.md) |
| `pattern` | `sweep` | [`private.this.marker.sweep`](this.md) |
| `pct` | `record` | [`hiveMind.context.record`](hivemind.md) |
| `pct` | `set` | [`private.hiveMind.context.set`](hivemind.md) |
| `pdca` |  | [`scrumMaster.pdca.errors`](scrumMaster.md) · [`scrumMaster.pdca.iteration`](scrumMaster.md) · [`scrumMaster.pdca.state`](scrumMaster.md) |
| `pdca` | `load` | [`private.pdca.config.load`](scrumMaster.md) |
| `pdca` | `next` | [`scrumMaster.pdca.next`](scrumMaster.md) |
| `pdca` | `reset` | [`scrumMaster.pdca.reset`](scrumMaster.md) |
| `pdca` | `run` | [`scrumMaster.pdca.run`](scrumMaster.md) |
| `pdca` | `save` | [`private.pdca.config.save`](scrumMaster.md) |
| `peer` | `compact` | [`hiveMind.peer.compact`](hivemind.md) |
| `pending` |  | [`private.user.group.member.pending`](user.md) |
| `perf` |  | [`claudeFlow.perf`](claudeFlow.md) |
| `performance` |  | [`claudeFlow.performance`](claudeFlow.md) |
| `permission` | `fix` | [`ossh.permission.fix`](ossh.md) |
| `perms` | `tighten` | [`private.osshLayout.perms.tighten`](osshLayout.md) |
| `pick` | `continue` | [`ogit.commit.pick.continue`](ogit.md) |
| `pid` |  | [`private.osemvec.ownsProcess`](osemvec.md) |
| `pid` | `classify` | [`private.hiveMind.shell.classify`](hivemind.md) |
| `pid` | `lookup` | [`hiveMind.process.lookup`](hivemind.md) |
| `pkg` |  | [`ossh.cmd`](ossh.md) · [`private.opy.pkgInstall`](opy.md) |
| `pkgInstall` |  | [`private.opy.pkgInstall`](opy.md) |
| `plan` | `create` | [`hiveMind.plan.create`](hivemind.md) |
| `plan` | `improve` | [`hiveMind.plan.improve`](hivemind.md) |
| `platform` |  | [`private.os.platform.container.id`](os.md) · [`private.os.platform.image.from.workspace`](os.md) · [`private.os.platform.names`](os.md) |
| `platform` | `check` | [`os.platform.parse.check`](os.md) |
| `platform` | `cleanup` | [`private.os.platform.cleanup`](os.md) |
| `platform` | `dispatch` | [`private.check.platform.test.dispatch`](promote.md) |
| `platform` | `exists` | [`private.os.platform.image.exists`](os.md) |
| `platform` | `list` | [`os.platform.list`](os.md) |
| `platform` | `load` | [`private.os.platform.load`](os.md) |
| `platform` | `new` | [`oo.test.platform.new`](oo.md) |
| `platform` | `parse` | [`private.os.platform.parse`](os.md) |
| `platform` | `reload` | [`private.os.platform.sshd.reload`](os.md) |
| `platform` | `repair` | [`private.os.platform.shared.config.repair`](os.md) |
| `platform` | `source` | [`private.promote.platform.stubs.source`](promote.md) |
| `platform` | `test` | [`os.platform.test`](os.md) · [`os.platform.test.all`](os.md) · [`private.os.platform.test.ci`](os.md) |
| `pm` |  | [`oo.pm`](oo.md) |
| `pm` | `add` | [`private.odocker.container.repo.add`](odocker.md) |
| `pm` | `discover` | [`oo.pm.discover`](oo.md) · [`ossh.pm.discover`](ossh.md) |
| `pm` | `ensure` | [`private.setup.pm.ensure`](setup.md) |
| `pm` | `get` | [`private.config.pm.command.get`](config.md) · [`private.odocker.docker.repo.get`](odocker.md) · [`private.oo.pm.env.get`](oo.md) · [`private.oo.pm.install.prefix.get`](oo.md) |
| `pmCmd` | `get` | [`private.oo.pm.install.prefix.get`](oo.md) |
| `policy` | `new` | [`osemvec.new`](osemvec.md) |
| `pool` |  | [`claudeFlow.agent.pool`](claudeFlow.md) |
| `port` |  | [`private.odocker.port.offset`](odocker.md) · [`private.os.platform.container.id`](os.md) |
| `port` | `cleanup` | [`private.os.platform.cleanup`](os.md) |
| `port` | `get` | [`ossh.server.port.get`](ossh.md) · [`private.ossh.config.port.get`](ossh.md) |
| `port` | `reload` | [`private.os.platform.sshd.reload`](os.md) |
| `port` | `remove` | [`ossh.known.hosts.remove`](ossh.md) |
| `port` | `serve` | [`osemvec.serve`](osemvec.md) |
| `port` | `set` | [`private.ossh.config.port.set`](ossh.md) |
| `portMap` |  | [`ossh.tunnel`](ossh.md) |
| `portOrOffset` | `clone` | [`odocker.clone`](odocker.md) |
| `portOrOffset` | `reset` | [`odocker.reset`](odocker.md) |
| `portOrOffset` | `run` | [`odocker.run.sshd`](odocker.md) |
| `portOrOffset` | `up` | [`odocker.up`](odocker.md) |
| `portability` | `validate` | [`test.suite.portability.validate`](test.suite.md) |
| `ports` |  | [`private.odocker.container.ports`](odocker.md) |
| `position` | `pathadd` | [`private.pathadd`](path.md) |
| `pre` | `compact` | [`context.lifecycle.pre.compact`](context.md) |
| `preForkFiles` | `push` | [`private.hiveMind.push.captureForkedUUID`](hivemind.md) |
| `preamble` | `get` | [`private.this.as.user.preamble.get`](this.md) |
| `prefix` | `append` | [`private.log.install.append`](this.md) |
| `prefix` | `drop` | [`private.config.env.lines.drop`](config.md) |
| `prefix` | `get` | [`private.oo.pm.install.prefix.get`](oo.md) |
| `prelude` | `get` | [`ossh.remote.prelude.get`](ossh.md) |
| `prereq` | `get` | [`private.odocker.prereq.package.get`](odocker.md) |
| `prereqs` | `ensure` | [`private.odocker.prereqs.ensure`](odocker.md) |
| `prereqs` | `install` | [`odocker.prereqs.install`](odocker.md) · [`oo.prereqs.install`](oo.md) · [`ossh.prereqs.install`](ossh.md) · [`private.odocker.container.prereqs.install`](odocker.md) |
| `preview` | `show` | [`private.promote.merge.preview.show`](promote.md) |
| `privKey` | `stage` | [`private.ossh.identity.stage.outer.fromRunner`](ossh.md) |
| `procArgs` |  | [`private.hiveMind.liveUuid`](hivemind.md) |
| `process` |  | [`claudeCode.process.running`](claudeCode.md) |
| `process` | `find` | [`claudeCode.process.find`](claudeCode.md) |
| `process` | `list` | [`hiveMind.process.list`](hivemind.md) |
| `process` | `lookup` | [`hiveMind.process.lookup`](hivemind.md) |
| `processes` |  | [`private.hiveMind.claude.processes`](hivemind.md) |
| `prod` |  | [`oo.testing.to.prod`](oo.md) · [`promote.prod`](promote.md) · [`promote.testing.to.prod`](promote.md) |
| `profile` | `open` | [`otest.browser.open`](otest.md) |
| `profileDir` | `remove` | [`private.oo.dropin.remove`](oo.md) |
| `projectDir` |  | [`osemvec.context`](osemvec.md) · [`osemvec.error`](osemvec.md) · [`osemvec.index`](osemvec.md) · [`private.osemvec.pss`](osemvec.md) |
| `projectDir` | `new` | [`osemvec.new`](osemvec.md) |
| `projectDir` | `provision` | [`private.osemvec.provision`](osemvec.md) |
| `projectDir` | `register` | [`osemvec.register`](osemvec.md) |
| `projectDir` | `save` | [`osemvec.save`](osemvec.md) |
| `projectDir` | `update` | [`osemvec.update`](osemvec.md) |
| `projectHash` |  | [`private.claudeCode.projectHash`](claudeCode.md) |
| `promote` |  | [`private.promote.notests.gate`](promote.md) · [`private.promote.rewrite.self.branch`](promote.md) · [`promote.branch.alignment`](promote.md) · [`promote.dev.to.testing`](promote.md) · [`promote.prod`](promote.md) · [`promote.status`](promote.md) · [`promote.testing`](promote.md) · [`promote.testing.to.prod`](promote.md) |
| `promote` | `apply` | [`private.promote.argument.apply`](promote.md) |
| `promote` | `check` | [`private.check.confirmation.received`](promote.md) · [`private.check.confirmation.received.prod`](promote.md) · [`private.check.finished`](promote.md) · [`private.check.initialization.checked`](promote.md) · [`private.check.merged.to.prod`](promote.md) · [`private.check.merged.to.testing`](promote.md) · [`private.check.prod.path.started`](promote.md) · [`private.check.prod.pushed`](promote.md) · [`private.check.prod.tagged`](promote.md) · [`private.check.target.checked`](promote.md) · [`private.check.testing.pushed`](promote.md) · [`private.check.testing.tagged`](promote.md) · [`private.check.uncommitted.checked`](promote.md) · [`private.check.uncommitted.checked.prod`](promote.md) |
| `promote` | `dispatch` | [`private.check.platform.test.dispatch`](promote.md) |
| `promote` | `finish` | [`private.promote.merge.finish`](promote.md) |
| `promote` | `init` | [`private.promote.state.machine.init`](promote.md) |
| `promote` | `load` | [`private.promote.config.load`](promote.md) |
| `promote` | `merge` | [`private.promote.merge.into.folder`](promote.md) |
| `promote` | `next` | [`private.check.next.custom.state`](promote.md) |
| `promote` | `report` | [`oo.promote.report`](oo.md) · [`private.oo.promote.report`](oo.md) · [`promote.report`](promote.md) |
| `promote` | `resolve` | [`private.promote.try.resolve.self.branch.conflict`](promote.md) |
| `promote` | `save` | [`private.promote.config.save`](promote.md) |
| `promote` | `show` | [`private.promote.merge.preview.show`](promote.md) |
| `promote` | `source` | [`private.promote.platform.stubs.source`](promote.md) · [`private.promote.push.source.branch`](promote.md) |
| `promote` | `test` | [`private.check.test.suite.passed`](promote.md) · [`private.check.test.suite.passed.prod`](promote.md) |
| `prompt` | `append` | [`claudeCode.system.prompt.append`](claudeCode.md) |
| `property` | `get` | [`user.get`](user.md) |
| `protected` |  | [`hiveMind.protected.agents.offline`](hivemind.md) · [`hiveMind.protected.live.tupleset`](hivemind.md) · [`hiveMind.protected.pane.moved`](hivemind.md) · [`hiveMind.protected.panes.shifted`](hivemind.md) · [`hiveMind.protected.panes.swapped`](hivemind.md) · [`hiveMind.protected.session.renamed`](hivemind.md) |
| `protected` | `diff` | [`hiveMind.protected.reconcile.diff`](hivemind.md) |
| `protected` | `discover` | [`hiveMind.protected.agents.discover`](hivemind.md) |
| `protected` | `emit` | [`hiveMind.protected.events.emit`](hivemind.md) |
| `protected` | `import` | [`hiveMind.protected.team.import`](hivemind.md) |
| `protected` | `register` | [`hiveMind.protected.events.register`](hivemind.md) |
| `protected` | `resolve` | [`hiveMind.protected.identity.resolve`](hivemind.md) |
| `proxyJump` | `create` | [`ossh.config.create`](ossh.md) |
| `proxyJump` | `get` | [`private.ossh.config.proxyJump.get`](ossh.md) |
| `proxyJump` | `set` | [`private.ossh.config.proxyJump.set`](ossh.md) |
| `ps` |  | [`odocker.ps`](odocker.md) |
| `psMeta` | `classify` | [`private.hiveMind.shell.classify`](hivemind.md) |
| `psSnap` |  | [`private.hiveMind.shell.descendants`](hivemind.md) |
| `psSnap` | `sweep` | [`private.hiveMind.sweep.bgshells`](hivemind.md) |
| `pss` |  | [`private.osemvec.pss`](osemvec.md) |
| `pubKey` | `stage` | [`private.ossh.identity.stage.outer.fromRunner`](ossh.md) |
| `public` | `get` | [`ossh.id.public.get`](ossh.md) |
| `public` | `put` | [`private.ossh.remote.public.key.put`](ossh.md) |
| `publicId` | `get` | [`ossh.publicId.get`](ossh.md) |
| `pulse` |  | [`scrumMaster.pulse`](scrumMaster.md) |
| `push` | `init` | [`private.push.init.oosh`](ossh.md) |
| `push` | `source` | [`private.promote.push.source.branch`](promote.md) |
| `put` | `get` | [`private.ossh.config.block.put.get`](ossh.md) |
| `pyenv` |  | [`private.opy.pyenv`](opy.md) |
| `pyenvBin` |  | [`private.opy.pyenvBin`](opy.md) |
| `pyenvRoot` |  | [`private.opy.pyenvRoot`](opy.md) |
| `python` |  | [`private.opy.python`](opy.md) · [`private.osemvec.mcpJson`](osemvec.md) · [`private.osemvec.semvecVersion`](osemvec.md) · [`private.osemvec.settingsJson`](osemvec.md) · [`private.python`](otest.md) |
| `pyver` |  | [`private.osemvec.pyver`](osemvec.md) |
| `queen` |  | [`hiveMind.queen`](hivemind.md) |
| `queue` |  | [`private.hiveMind.agent.queue.depth`](hivemind.md) · [`private.hiveMind.agent.queue.path`](hivemind.md) · [`private.hiveMind.handler.agent.killed.queue`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.queue`](hivemind.md) |
| `queue` | `clear` | [`hiveMind.agent.queue.clear`](hivemind.md) |
| `queue` | `drain` | [`hiveMind.agent.queue.drain`](hivemind.md) |
| `queue` | `enqueue` | [`private.hiveMind.agent.queue.enqueue`](hivemind.md) |
| `queue` | `list` | [`hiveMind.agent.queue.list`](hivemind.md) |
| `queue` | `resolve` | [`private.hiveMind.agent.queue.resolve`](hivemind.md) |
| `quick` |  | [`claudeFlow.quick`](claudeFlow.md) |
| `quiet` |  | [`claudeFlow.quiet`](claudeFlow.md) |
| `range` | `show` | [`ogit.commit.log.show`](ogit.md) |
| `rate` |  | [`scrumMaster.velocity.rate`](scrumMaster.md) |
| `ratelimit` | `probe` | [`private.hiveMind.sweep.ratelimit.probe`](hivemind.md) |
| `raw` |  | [`ogit.raw`](ogit.md) |
| `rc` |  | [`debug.onError`](debug.md) · [`debug.onExit`](debug.md) · [`debug.onReturn`](debug.md) |
| `rc` | `finish` | [`private.promote.merge.finish`](promote.md) |
| `rcfile` | `install` | [`opy.shell.install`](opy.md) |
| `rcfile` | `installBashrc` | [`private.opy.installBashrc`](opy.md) |
| `reading` |  | [`private.hiveMind.context.from.jsonl.reading`](hivemind.md) |
| `ready` |  | [`private.config.session.chain.ready`](config.md) |
| `reason` | `get` | [`private.ogit.git.reason.get`](ogit.md) |
| `reason` | `is` | [`private.ossh.connection.error.network.is`](ossh.md) |
| `reason` | `report` | [`private.test.suite.shared.report`](test.suite.md) · [`private.test.suite.ssh.report`](test.suite.md) |
| `reconcile` | `apply` | [`hiveMind.consistency.reconcile.apply`](hivemind.md) · [`private.hiveMind.reconcile.apply`](hivemind.md) |
| `reconcile` | `check` | [`private.hiveMind.reconcile.check.i1`](hivemind.md) · [`private.hiveMind.reconcile.check.i10`](hivemind.md) · [`private.hiveMind.reconcile.check.i2`](hivemind.md) · [`private.hiveMind.reconcile.check.i3`](hivemind.md) · [`private.hiveMind.reconcile.check.i4`](hivemind.md) · [`private.hiveMind.reconcile.check.i5`](hivemind.md) · [`private.hiveMind.reconcile.check.i6`](hivemind.md) · [`private.hiveMind.reconcile.check.i7`](hivemind.md) · [`private.hiveMind.reconcile.check.i8`](hivemind.md) · [`private.hiveMind.reconcile.check.i9`](hivemind.md) |
| `reconcile` | `diff` | [`hiveMind.protected.reconcile.diff`](hivemind.md) · [`private.hiveMind.reconcile.diff`](hivemind.md) |
| `ref` |  | [`ogit.branch.fastForward`](ogit.md) |
| `ref` | `adopt` | [`ogit.branch.adopt`](ogit.md) |
| `ref` | `check` | [`ogit.branch.check`](ogit.md) |
| `ref` | `checkout` | [`ogit.branch.checkout`](ogit.md) |
| `ref` | `create` | [`ogit.tag.create`](ogit.md) |
| `ref` | `merge` | [`ogit.branch.merge`](ogit.md) |
| `ref` | `set` | [`ogit.branch.upstream.set`](ogit.md) |
| `ref` | `show` | [`ogit.commit.show`](ogit.md) |
| `regex` | `get` | [`private.oo.regex.escape.get`](oo.md) |
| `registry` |  | [`private.hiveMind.handler.agent.forked.registry`](hivemind.md) · [`private.hiveMind.handler.agent.killed.registry`](hivemind.md) · [`private.hiveMind.handler.agent.renamed.registry`](hivemind.md) · [`private.hiveMind.handler.agent.spawned.registry`](hivemind.md) · [`private.hiveMind.handler.pane.moved.registry`](hivemind.md) · [`private.hiveMind.handler.panes.shifted.registry`](hivemind.md) · [`private.hiveMind.handler.panes.swapped.registry`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.registry`](hivemind.md) · [`private.tronMonitor.registry.teams`](tronMonitor.md) |
| `registry` | `find` | [`private.hiveMind.registry.find`](hivemind.md) |
| `registry` | `fix` | [`hiveMind.registry.fix`](hivemind.md) |
| `registry` | `get` | [`private.hiveMind.registry.get`](hivemind.md) |
| `registry` | `isRecent` | [`private.hiveMind.registry.isRecent`](hivemind.md) |
| `registry` | `list` | [`hiveMind.registry.list`](hivemind.md) · [`private.hiveMind.registry.list`](hivemind.md) |
| `registry` | `migrate` | [`private.hiveMind.registry.migrate`](hivemind.md) |
| `registry` | `refresh` | [`hiveMind.registry.refresh`](hivemind.md) |
| `registry` | `remove` | [`hiveMind.registry.remove`](hivemind.md) |
| `registry` | `set` | [`hiveMind.registry.set`](hivemind.md) · [`private.hiveMind.registry.set`](hivemind.md) |
| `relPath` | `is` | [`private.test.suite.ssh.secret.is`](test.suite.md) |
| `release` | `get` | [`private.os.release.get`](os.md) |
| `remote` |  | [`private.hiveMind.live.tupleset.remote`](hivemind.md) |
| `remote` | `delete` | [`ogit.branch.remote.delete`](ogit.md) |
| `remote` | `fetch` | [`ogit.remote.fetch`](ogit.md) |
| `remote` | `get` | [`ogit.remote.url.get`](ogit.md) · [`ossh.remote.prelude.get`](ossh.md) · [`private.ossh.remote.key.file.name.get`](ossh.md) |
| `remote` | `install` | [`private.check.remote.install.started`](oo.md) |
| `remote` | `list` | [`ogit.remote.branch.list`](ogit.md) |
| `remote` | `pull` | [`ogit.remote.pull`](ogit.md) |
| `remote` | `push` | [`ogit.remote.push`](ogit.md) |
| `remote` | `put` | [`private.ossh.remote.public.key.put`](ossh.md) |
| `remote` | `set` | [`ogit.remote.url.set`](ogit.md) |
| `remote` | `update` | [`oo.remote.update`](oo.md) |
| `remoteConfigName` | `pull` | [`ossh.config.pull`](ossh.md) · [`private.ossh.config.pull`](ossh.md) |
| `remoteKeyName` | `pull` | [`ossh.key.pull`](ossh.md) · [`private.ossh.key.pull`](ossh.md) |
| `remoteSshConfigName` | `continue` | [`ossh.install.continue.local`](ossh.md) |
| `renamed` |  | [`hiveMind.protected.session.renamed`](hivemind.md) · [`private.hiveMind.handler.agent.renamed.registry`](hivemind.md) · [`private.hiveMind.handler.agent.renamed.role_env`](hivemind.md) · [`private.hiveMind.handler.agent.renamed.title`](hivemind.md) |
| `replace` |  | [`replace.block`](replace.md) · [`replace.by`](replace.md) · [`replace.by.file`](replace.md) · [`replace.line`](replace.md) · [`replace.lines`](replace.md) · [`replace.within`](replace.md) · [`replace.word`](replace.md) |
| `replace` | `cleanup` | [`replace.cleanup`](replace.md) |
| `replace` | `commit` | [`replace.commit`](replace.md) |
| `replace` | `diff` | [`replace.diff`](replace.md) |
| `replace` | `make` | [`private.replace.copy.make`](replace.md) |
| `replace` | `rollback` | [`replace.rollback`](replace.md) |
| `repo` | `add` | [`private.odocker.container.repo.add`](odocker.md) · [`private.odocker.docker.repo.add`](odocker.md) |
| `repo` | `check` | [`ogit.repo.check`](ogit.md) |
| `repo` | `clone` | [`ogit.repo.clone`](ogit.md) |
| `repo` | `download` | [`private.odocker.docker.repo.download`](odocker.md) |
| `repo` | `get` | [`ogit.repo.root.get`](ogit.md) · [`private.odocker.docker.repo.get`](odocker.md) |
| `repo` | `grep` | [`ogit.repo.grep`](ogit.md) |
| `repo` | `list` | [`ogit.repo.files.list`](ogit.md) |
| `repo` | `share` | [`ogit.repo.share`](ogit.md) |
| `required` | `get` | [`private.config.required.file.path.get`](config.md) · [`private.config.required.variables.get`](config.md) |
| `resets` |  | [`private.scrumMaster.subscription.resets.in`](scrumMaster.md) |
| `resolved` | `get` | [`private.ossh.control.path.resolved.get`](ossh.md) |
| `rest` | `find` | [`private.itterator.find`](state.md) |
| `restored` |  | [`private.hiveMind.handler.team.restored.teams`](hivemind.md) · [`private.hiveMind.handler.team.restored.tronMonitor`](hivemind.md) |
| `result` |  | [`log.live.result.env`](log.md) · [`log.live.result.txt`](log.md) |
| `result` | `list` | [`backup.result.list.lastDiff`](backup.md) · [`backup.result.list.lastRaw`](backup.md) · [`private.backup.result.list.lastDiff`](backup.md) · [`private.backup.result.list.lastRaw`](backup.md) |
| `results` | `clear` | [`private.test.suite.results.clear`](test.suite.md) |
| `results` | `close` | [`private.test.suite.results.dir.close`](test.suite.md) |
| `results` | `get` | [`private.test.suite.results.file.get`](test.suite.md) |
| `results` | `open` | [`private.test.suite.results.dir.open`](test.suite.md) |
| `rewind` | `list` | [`scrumMaster.rewind.list`](scrumMaster.md) |
| `rewind` | `mark` | [`scrumMaster.rewind.mark`](scrumMaster.md) |
| `rewind` | `unmark` | [`scrumMaster.rewind.unmark`](scrumMaster.md) |
| `rewrite` |  | [`private.promote.rewrite.self.branch`](promote.md) |
| `right` |  | [`otmux.pane.right`](otmux.md) · [`otmux.right`](otmux.md) |
| `rights` | `fix` | [`ossh.rights.fix`](ossh.md) |
| `role` |  | [`context.lifecycle.status`](context.md) · [`hiveMind.role.uuid`](hivemind.md) · [`osshLayout.role.developking`](osshLayout.md) · [`osshLayout.role.installer`](osshLayout.md) · [`osshLayout.role.outeruser`](osshLayout.md) · [`osshLayout.role.owner`](osshLayout.md) · [`private.context.role.to.machine`](context.md) · [`private.hiveMind.context.key`](hivemind.md) · [`private.hiveMind.role.fromTitle`](hivemind.md) · [`private.osshLayout.staged.email`](osshLayout.md) |
| `role` | `bootstrap` | [`hiveMind.agent.bootstrap`](hivemind.md) |
| `role` | `clear` | [`hiveMind.agent.state.clear`](hivemind.md) |
| `role` | `fork` | [`claudeCode.fork.to`](claudeCode.md) · [`hiveMind.agent.fork.best`](hivemind.md) |
| `role` | `get` | [`hiveMind.agent.state.get`](hivemind.md) · [`private.hiveMind.context.get`](hivemind.md) · [`private.hiveMind.snapshot.get`](hivemind.md) |
| `role` | `has` | [`private.osshLayout.staged.has.keypair`](osshLayout.md) · [`private.osshLayout.staged.has.privkey`](osshLayout.md) · [`private.osshLayout.staged.has.pubkey`](osshLayout.md) |
| `role` | `init` | [`context.lifecycle.init`](context.md) |
| `role` | `isGeneric` | [`private.hiveMind.role.isGeneric`](hivemind.md) |
| `role` | `list` | [`hiveMind.role.list`](hivemind.md) · [`hiveMind.roles.list.uuids`](hivemind.md) · [`private.context.role.list`](context.md) |
| `role` | `new` | [`osemvec.new`](osemvec.md) |
| `role` | `prompt` | [`hiveMind.role.prompt`](hivemind.md) · [`private.hiveMind.get.role.prompt`](hivemind.md) |
| `role` | `push` | [`private.hiveMind.push.agent`](hivemind.md) · [`private.hiveMind.push.captureForkedUUID`](hivemind.md) · [`private.hiveMind.push.resolveCanonical`](hivemind.md) |
| `role` | `recover` | [`context.lifecycle.recover`](context.md) · [`context.recover`](context.md) |
| `role` | `restart` | [`hiveMind.agent.restart`](hivemind.md) · [`hiveMind.agent.restart.remote`](hivemind.md) |
| `role` | `save` | [`context.lifecycle.save`](context.md) |
| `role` | `set` | [`hiveMind.agent.state.set`](hivemind.md) · [`hiveMind.registry.set`](hivemind.md) · [`private.hiveMind.snapshot.set`](hivemind.md) |
| `role` | `store` | [`private.hiveMind.session.store.deferred`](hivemind.md) |
| `role` | `teach` | [`hiveMind.role.teach`](hivemind.md) · [`hiveMind.teach`](hivemind.md) |
| `role` | `train` | [`hiveMind.train`](hivemind.md) |
| `roleKey` | `set` | [`private.hiveMind.context.set`](hivemind.md) |
| `role_env` |  | [`private.hiveMind.handler.agent.renamed.role_env`](hivemind.md) · [`private.hiveMind.handler.pane.moved.role_env`](hivemind.md) · [`private.hiveMind.handler.panes.swapped.role_env`](hivemind.md) |
| `roles` |  | [`hiveMind.roles`](hivemind.md) |
| `roles` | `complete` | [`private.hiveMind.roles.complete`](hivemind.md) |
| `roles` | `list` | [`hiveMind.roles.list.uuids`](hivemind.md) |
| `roles` | `setup` | [`hiveMind.team.setup`](hivemind.md) |
| `roles` | `start` | [`agentRoom.start.all`](agentRoom.md) |
| `root` |  | [`check.root`](check.md) |
| `root` | `add` | [`private.odocker.docker.repo.add`](odocker.md) |
| `root` | `boot` | [`private.check.root.boot.path.installed`](oo.md) |
| `root` | `check` | [`private.ogit.root.check`](ogit.md) |
| `root` | `get` | [`ogit.repo.root.get`](ogit.md) |
| `root` | `is` | [`private.os.systemd.is`](os.md) · [`private.this.container.is`](this.md) |
| `root` | `merge` | [`private.odocker.workspaces.merge`](odocker.md) |
| `root_pid` |  | [`private.hiveMind.shell.descendants`](hivemind.md) |
| `root_pid` | `sweep` | [`private.hiveMind.sweep.bgshells`](hivemind.md) |
| `rootkey` | `pull` | [`user.ssh.rootkey.pull`](user.md) |
| `rootkey` | `push` | [`user.ssh.rootkey.file.push`](user.md) · [`user.ssh.rootkey.push`](user.md) |
| `rootkey` | `revoke` | [`user.ssh.rootkey.file.revoke`](user.md) |
| `row` |  | [`private.hiveMind.snapshot.row.valid`](hivemind.md) |
| `rp` |  | [`otmux.rp`](otmux.md) |
| `rsync` | `pull` | [`private.ossh.rsync.pull`](ossh.md) |
| `running` |  | [`claudeCode.process.running`](claudeCode.md) |
| `rw` |  | [`otmux.rw`](otmux.md) |
| `safeDirectory` | `add` | [`ogit.safeDirectory.add`](ogit.md) |
| `safeDirectory` | `ensure` | [`ogit.safeDirectory.ensure`](ogit.md) |
| `safeDirectory` | `list` | [`ogit.safeDirectory.list`](ogit.md) |
| `safeDirectory` | `prune` | [`ogit.safeDirectory.prune`](ogit.md) · [`oo.safeDirectory.prune`](oo.md) |
| `samba` |  | [`private.setup.samba.password.darwin`](setup.md) · [`private.setup.samba.password.linux`](setup.md) · [`private.setup.samba.support.darwin`](setup.md) · [`private.setup.samba.support.linux`](setup.md) · [`private.setup.samba.users.any`](setup.md) · [`setup.samba.password`](setup.md) · [`setup.samba.support`](setup.md) · [`share.samba.service`](share.md) · [`share.samba.status`](share.md) |
| `samba` | `edit` | [`share.samba.config.edit`](share.md) |
| `samba` | `install` | [`share.samba.install`](share.md) |
| `samba` | `restart` | [`share.samba.restart`](share.md) |
| `same` |  | [`private.odocker.workspaces.entry.same`](odocker.md) · [`private.this.file.same`](this.md) |
| `saved` |  | [`path.saved`](path.md) |
| `savedDevice` | `write` | [`private.log.session.write`](log.md) |
| `sbinDir` | `get` | [`private.user.delete.command.get`](user.md) |
| `scenario` |  | [`certificates.once.scenarios`](certificates.md) |
| `scenario` | `list` | [`certificates.once.scenario.list`](certificates.md) |
| `scenario` | `select` | [`certificates.once.scenario.select`](certificates.md) |
| `scenarios` |  | [`certificates.once.scenarios`](certificates.md) |
| `schema` |  | [`context.schema`](context.md) |
| `scope` |  | [`mycmd.scope`](mycmd.md) · [`status.scope`](status.md) · [`status.scope.full`](status.md) · [`this.scope`](this.md) · [`this.scope.full`](this.md) |
| `scope` | `add` | [`ogit.index.add`](ogit.md) |
| `scope` | `get` | [`ogit.config.get`](ogit.md) |
| `scope` | `list` | [`private.hiveMind.list.panes`](hivemind.md) |
| `scope` | `new` | [`oo.test.platform.new`](oo.md) |
| `scope` | `reap` | [`private.hiveMind.shell.reap.impl`](hivemind.md) |
| `scope` | `save` | [`backup.config.save`](backup.md) |
| `screen` |  | [`private.tronMonitor.screen.showsTeam`](tronMonitor.md) |
| `screen` | `capture` | [`private.tronMonitor.screen.capture`](tronMonitor.md) |
| `screen` | `ensure` | [`private.tronMonitor.screen.ensure`](tronMonitor.md) |
| `screen` | `isAlive` | [`private.tronMonitor.screen.isAlive`](tronMonitor.md) |
| `screenSession` |  | [`private.tronMonitor.screenSession`](tronMonitor.md) |
| `script` | `check` | [`private.check.acting`](scrumMaster.md) · [`private.check.checking`](scrumMaster.md) · [`private.check.confirmation.received`](promote.md) · [`private.check.confirmation.received.prod`](promote.md) · [`private.check.doing`](scrumMaster.md) · [`private.check.error.max.iterations`](scrumMaster.md) · [`private.check.finished`](ossh.md) · [`private.check.finished`](promote.md) · [`private.check.finished`](scrumMaster.md) · [`private.check.initialization.checked`](promote.md) · [`private.check.merged.to.prod`](promote.md) · [`private.check.merged.to.testing`](promote.md) · [`private.check.planning`](scrumMaster.md) · [`private.check.prod.path.started`](promote.md) · [`private.check.prod.pushed`](promote.md) · [`private.check.prod.tagged`](promote.md) · [`private.check.target.checked`](promote.md) · [`private.check.testing.pushed`](promote.md) · [`private.check.testing.tagged`](promote.md) · [`private.check.uncommitted.checked`](promote.md) · [`state.check`](state.md) |
| `script` | `complete` | [`private.check.cycle.complete`](scrumMaster.md) |
| `script` | `create` | [`private.check.certificates.update.create.certbot`](ossh.md) · [`private.check.certificates.update.create.structr`](ossh.md) · [`state.machine.create`](state.md) |
| `script` | `format` | [`2c.format.functions`](2c.md) · [`c2.format.functions`](c2.md) · [`c2.function.description.format`](c2.md) · [`c2.functions.format`](c2.md) · [`private.c2.format.functions`](c2.md) |
| `script` | `get` | [`2c.get.function.with.documentation`](2c.md) · [`2c.get.functions`](2c.md) · [`c2.function.declaration.get`](c2.md) · [`c2.function.get.with.documentation`](c2.md) · [`c2.function.parameter.get`](c2.md) · [`c2.functions.get`](c2.md) · [`c2.get.formated.function.description`](c2.md) · [`c2.get.function.declaration`](c2.md) · [`c2.get.function.parameter`](c2.md) · [`c2.get.function.with.documentation`](c2.md) · [`c2.get.functions`](c2.md) · [`private.c2.get.formated.function.description`](c2.md) · [`private.c2.get.function.declaration`](c2.md) · [`private.c2.get.function.parameter`](c2.md) · [`private.c2.get.function.with.documentation`](c2.md) · [`private.c2.get.functions`](c2.md) |
| `script` | `init` | [`state.machine.init`](state.md) |
| `script` | `load` | [`private.this.script.load`](this.md) |
| `script` | `next` | [`private.check.next.custom.state`](ossh.md) · [`private.check.next.custom.state`](promote.md) · [`private.check.next.custom.state`](scrumMaster.md) |
| `script` | `restore` | [`private.check.certificates.update.restore.workspace`](ossh.md) |
| `script` | `rotate` | [`private.check.certificates.update.rotate.empty`](ossh.md) |
| `script` | `start` | [`private.check.certificates.update.start.structr`](ossh.md) |
| `script` | `stop` | [`private.check.certificates.update.stop.certbot`](ossh.md) · [`private.check.certificates.update.stop.structr`](ossh.md) |
| `script` | `test` | [`private.check.test.suite.passed`](promote.md) |
| `script` | `update` | [`private.check.certificates.update.archive.workspace`](ossh.md) |
| `script` | `validate` | [`c2.signature.validate`](c2.md) |
| `script` | `verify` | [`private.check.certificates.update.verify.https`](ossh.md) |
| `scriptClass` | `install` | [`oo.install`](oo.md) |
| `scrumMaster` |  | [`private.scrumMaster.subscription`](scrumMaster.md) · [`private.scrumMaster.subscription.api.legacy`](scrumMaster.md) · [`private.scrumMaster.subscription.auth`](scrumMaster.md) · [`private.scrumMaster.subscription.cacheFile`](scrumMaster.md) · [`private.scrumMaster.subscription.resets.in`](scrumMaster.md) · [`private.scrumMaster.subscription.verdict`](scrumMaster.md) · [`private.scrumMaster.velocity.target`](scrumMaster.md) · [`scrumMaster.cycle`](scrumMaster.md) · [`scrumMaster.dashboard`](scrumMaster.md) · [`scrumMaster.metrics.cycle`](scrumMaster.md) · [`scrumMaster.pdca.errors`](scrumMaster.md) · [`scrumMaster.pdca.iteration`](scrumMaster.md) · [`scrumMaster.pdca.state`](scrumMaster.md) · [`scrumMaster.pulse`](scrumMaster.md) · [`scrumMaster.subscription`](scrumMaster.md) · [`scrumMaster.subscription.cache.age`](scrumMaster.md) · [`scrumMaster.subscription.json`](scrumMaster.md) · [`scrumMaster.subscription.status`](scrumMaster.md) · [`scrumMaster.velocity`](scrumMaster.md) · [`scrumMaster.velocity.alert`](scrumMaster.md) · [`scrumMaster.velocity.history`](scrumMaster.md) · [`scrumMaster.velocity.rate`](scrumMaster.md) · [`scrumMaster.velocity.target`](scrumMaster.md) |
| `scrumMaster` | `call` | [`private.scrumMaster.subscription.api.call`](scrumMaster.md) |
| `scrumMaster` | `capture` | [`private.scrumMaster.velocity.capture.sample`](scrumMaster.md) · [`scrumMaster.pane.capture`](scrumMaster.md) · [`scrumMaster.team.capture`](scrumMaster.md) |
| `scrumMaster` | `check` | [`private.check.acting`](scrumMaster.md) · [`private.check.checking`](scrumMaster.md) · [`private.check.doing`](scrumMaster.md) · [`private.check.error.max.iterations`](scrumMaster.md) · [`private.check.finished`](scrumMaster.md) · [`private.check.planning`](scrumMaster.md) · [`private.scrumMaster.health.check`](scrumMaster.md) · [`scrumMaster.health.check`](scrumMaster.md) · [`scrumMaster.speed.check`](scrumMaster.md) · [`scrumMaster.subscription.check`](scrumMaster.md) · [`scrumMaster.velocity.check`](scrumMaster.md) |
| `scrumMaster` | `collect` | [`scrumMaster.metrics.collect`](scrumMaster.md) |
| `scrumMaster` | `complete` | [`private.check.cycle.complete`](scrumMaster.md) |
| `scrumMaster` | `evaluate` | [`private.scrumMaster.health.evaluate`](scrumMaster.md) · [`private.scrumMaster.measure.evaluate`](scrumMaster.md) · [`scrumMaster.health.evaluate`](scrumMaster.md) |
| `scrumMaster` | `get` | [`private.scrumMaster.metrics.dir.get`](scrumMaster.md) |
| `scrumMaster` | `list` | [`scrumMaster.rewind.list`](scrumMaster.md) |
| `scrumMaster` | `load` | [`private.pdca.config.load`](scrumMaster.md) |
| `scrumMaster` | `log` | [`private.scrumMaster.velocity.ensure.log`](scrumMaster.md) · [`scrumMaster.velocity.log`](scrumMaster.md) |
| `scrumMaster` | `mark` | [`scrumMaster.rewind.mark`](scrumMaster.md) |
| `scrumMaster` | `measure` | [`private.measure.subscription.api.auth`](scrumMaster.md) · [`private.scrumMaster.measure.context`](scrumMaster.md) · [`private.scrumMaster.measure.health`](scrumMaster.md) · [`private.scrumMaster.measure.pane`](scrumMaster.md) · [`private.scrumMaster.measure.speed`](scrumMaster.md) · [`private.scrumMaster.measure.subscription`](scrumMaster.md) · [`private.scrumMaster.measure.subscription.api`](scrumMaster.md) · [`private.scrumMaster.measure.team`](scrumMaster.md) · [`private.scrumMaster.measure.velocity`](scrumMaster.md) · [`private.scrumMaster.measure.velocity.target`](scrumMaster.md) · [`scrumMaster.context.measure`](scrumMaster.md) · [`scrumMaster.evaluate.measure`](scrumMaster.md) · [`scrumMaster.health.measure`](scrumMaster.md) · [`scrumMaster.pane.measure`](scrumMaster.md) · [`scrumMaster.speed.measure`](scrumMaster.md) · [`scrumMaster.subscription.measure`](scrumMaster.md) · [`scrumMaster.subscription.measure.api`](scrumMaster.md) · [`scrumMaster.team.measure`](scrumMaster.md) · [`scrumMaster.velocity.measure`](scrumMaster.md) · [`scrumMaster.velocity.measure.target`](scrumMaster.md) |
| `scrumMaster` | `next` | [`private.check.next.custom.state`](scrumMaster.md) · [`scrumMaster.pdca.next`](scrumMaster.md) |
| `scrumMaster` | `normalize` | [`private.scrumMaster.parse.normalize.k`](scrumMaster.md) |
| `scrumMaster` | `parse` | [`private.measure.subscription.api.parse`](scrumMaster.md) · [`private.scrumMaster.parse.state`](scrumMaster.md) · [`private.scrumMaster.parse.timing`](scrumMaster.md) · [`private.scrumMaster.parse.tokens`](scrumMaster.md) · [`private.scrumMaster.subscription.parse`](scrumMaster.md) |
| `scrumMaster` | `read` | [`scrumMaster.context.read`](scrumMaster.md) |
| `scrumMaster` | `reset` | [`scrumMaster.pdca.reset`](scrumMaster.md) |
| `scrumMaster` | `resolve` | [`private.scrumMaster.resolve.pane`](scrumMaster.md) |
| `scrumMaster` | `rewind` | [`private.scrumMaster.rewind.markdir`](scrumMaster.md) · [`private.scrumMaster.rewind.markname`](scrumMaster.md) |
| `scrumMaster` | `run` | [`scrumMaster.pdca.run`](scrumMaster.md) |
| `scrumMaster` | `save` | [`private.pdca.config.save`](scrumMaster.md) · [`private.scrumMaster.metrics.save`](scrumMaster.md) |
| `scrumMaster` | `scan` | [`scrumMaster.subscription.scan`](scrumMaster.md) |
| `scrumMaster` | `sweep` | [`private.scrumMaster.sweep.isStable`](scrumMaster.md) |
| `scrumMaster` | `unmark` | [`scrumMaster.rewind.unmark`](scrumMaster.md) |
| `seconds` |  | [`hiveMind.watchdog`](hivemind.md) |
| `seconds` | `loop` | [`hiveMind.pane.sweep.loop`](hivemind.md) · [`hiveMind.sweep.loop`](hivemind.md) |
| `secret` | `is` | [`private.test.suite.ssh.secret.is`](test.suite.md) |
| `secrets` | `get` | [`private.test.suite.ssh.secrets.changed.get`](test.suite.md) |
| `secureMove` |  | [`private.backup.strategy.secureMove`](backup.md) |
| `security` |  | [`claudeFlow.security`](claudeFlow.md) |
| `sed` |  | [`private.oo.sed.first`](oo.md) |
| `seed` | `deploy` | [`ossh.config.shared.seed.from.local.deploy.key`](ossh.md) |
| `segments` | `get` | [`private.config.path.segments.get`](config.md) |
| `self` |  | [`claudeCode.context.self`](claudeCode.md) · [`otmux.pane.self`](otmux.md) · [`private.otmux.self.session`](otmux.md) · [`private.promote.rewrite.self.branch`](promote.md) |
| `semvecVersion` |  | [`private.osemvec.semvecVersion`](osemvec.md) |
| `send` | `confirm` | [`otmux.send.confirm`](otmux.md) |
| `send` | `display` | [`otmux.send.display`](otmux.md) |
| `send` | `enter` | [`hiveMind.send.enter`](hivemind.md) · [`otmux.send.enter`](otmux.md) |
| `send` | `prompt` | [`otmux.send.prompt`](otmux.md) |
| `send` | `run` | [`otmux.send.run`](otmux.md) |
| `sepearator` |  | [`line.each`](line.md) |
| `sepearator` | `prepend` | [`line.prepend.all`](line.md) |
| `sepearator` | `unify` | [`line.unify`](line.md) |
| `seperator` |  | [`line.keys`](line.md) · [`line.table`](line.md) · [`line.values`](line.md) |
| `seperator` | `split` | [`line.split`](line.md) |
| `server` |  | [`otmux.server.info`](otmux.md) |
| `server` | `edit` | [`ossh.server.config.edit`](ossh.md) |
| `server` | `get` | [`ossh.server.get.ip`](ossh.md) · [`ossh.server.get.ip.darwin`](ossh.md) · [`ossh.server.get.ip.linux`](ossh.md) · [`ossh.server.get.port`](ossh.md) · [`ossh.server.ip.get`](ossh.md) · [`ossh.server.ip.get.darwin`](ossh.md) · [`ossh.server.ip.get.linux`](ossh.md) · [`ossh.server.port.get`](ossh.md) |
| `server` | `kill` | [`otmux.server.kill`](otmux.md) |
| `server` | `lock` | [`otmux.server.lock`](otmux.md) |
| `service` |  | [`os.service.off`](os.md) · [`os.service.on`](os.md) · [`ossh.service.status.darwin`](ossh.md) · [`ossh.service.status.linux`](ossh.md) · [`ossh.service.status.unknown`](ossh.md) · [`private.os.service.off.darwin`](os.md) · [`private.os.service.off.linux`](os.md) · [`private.os.service.on.darwin`](os.md) · [`private.os.service.on.linux`](os.md) · [`share.samba.service`](share.md) · [`snet.docker.service.status`](snet.md) · [`snet.service.status`](snet.md) |
| `service` | `compose` | [`odocker.compose`](odocker.md) |
| `service` | `install` | [`snet.service.install`](snet.md) |
| `service` | `stop` | [`snet.service.stop`](snet.md) |
| `service` | `switch` | [`private.setup.services.switch`](setup.md) |
| `serviceCmd` |  | [`share.samba.service`](share.md) |
| `services` | `switch` | [`private.setup.services.switch`](setup.md) |
| `session` |  | [`claudeCode.session.current`](claudeCode.md) · [`claudeCode.session.id`](claudeCode.md) · [`claudeCode.session.name`](claudeCode.md) · [`claudeCode.session.state`](claudeCode.md) · [`claudeFlow.session`](claudeFlow.md) · [`claudeFlow.session.current`](claudeFlow.md) · [`hiveMind.agent.context.status`](hivemind.md) · [`hiveMind.agent.handoff`](hivemind.md) · [`hiveMind.cycle.full`](hivemind.md) · [`hiveMind.dashboard`](hivemind.md) · [`hiveMind.handoff`](hivemind.md) · [`hiveMind.protected.agents.offline`](hivemind.md) · [`hiveMind.protected.live.tupleset`](hivemind.md) · [`hiveMind.protected.panes.shifted`](hivemind.md) · [`hiveMind.protected.panes.swapped`](hivemind.md) · [`hiveMind.protected.session.renamed`](hivemind.md) · [`hiveMind.role.uuid`](hivemind.md) · [`hiveMind.status`](hivemind.md) · [`hiveMind.team.context.status`](hivemind.md) · [`hiveMind.team.cycle`](hivemind.md) · [`hiveMind.team.status`](hivemind.md) · [`log.session`](log.md) · [`otmux.a`](otmux.md) · [`otmux.session.details`](otmux.md) · [`otmux.session.last`](otmux.md) · [`otmux.tree`](otmux.md) · [`otmux.tree.detailed`](otmux.md) · [`private.config.session.chain.ready`](config.md) · [`private.hiveMind.current.session`](hivemind.md) · [`private.hiveMind.live.tupleset`](hivemind.md) · [`private.hiveMind.live.tupleset.remote`](hivemind.md) · [`private.hiveMind.team.host`](hivemind.md) · [`private.otmux.notifyHiveMind.shifted`](otmux.md) · [`private.otmux.self.session`](otmux.md) · [`private.test.suite.session.snapshot`](test.suite.md) · [`scrumMaster.cycle`](scrumMaster.md) · [`scrumMaster.dashboard`](scrumMaster.md) · [`scrumMaster.metrics.cycle`](scrumMaster.md) · [`scrumMaster.pulse`](scrumMaster.md) |
| `session` | `activate` | [`hiveMind.team.activate`](hivemind.md) |
| `session` | `apply` | [`hiveMind.consistency.reconcile.apply`](hivemind.md) |
| `session` | `attach` | [`otmux.session.attach`](otmux.md) |
| `session` | `audit` | [`hiveMind.consistency.audit`](hivemind.md) · [`hiveMind.consistency.audit.table`](hivemind.md) · [`hiveMind.team.audit`](hivemind.md) |
| `session` | `bootstrap` | [`hiveMind.agent.bootstrap`](hivemind.md) |
| `session` | `capture` | [`scrumMaster.pane.capture`](scrumMaster.md) · [`scrumMaster.team.capture`](scrumMaster.md) |
| `session` | `check` | [`scrumMaster.speed.check`](scrumMaster.md) |
| `session` | `clear` | [`hiveMind.team.state.clear`](hivemind.md) |
| `session` | `collect` | [`scrumMaster.metrics.collect`](scrumMaster.md) |
| `session` | `compact` | [`hiveMind.peer.compact`](hivemind.md) |
| `session` | `delete` | [`claudeFlow.session.delete`](claudeFlow.md) · [`otmux.layout.delete`](otmux.md) |
| `session` | `detach` | [`otmux.session.detach`](otmux.md) |
| `session` | `discover` | [`private.claudeCode.session.discover`](claudeCode.md) |
| `session` | `ensure` | [`private.config.session.file.ensure`](config.md) · [`private.config.session.files.ensure.all`](config.md) · [`private.hiveMind.ensure.pane`](hivemind.md) |
| `session` | `export` | [`claudeFlow.session.export`](claudeFlow.md) |
| `session` | `fit` | [`otmux.fit`](otmux.md) |
| `session` | `fix` | [`hiveMind.consistency.fix`](hivemind.md) · [`hiveMind.consistency.fix.table`](hivemind.md) |
| `session` | `format` | [`otmux.window.list.format`](otmux.md) |
| `session` | `gather` | [`hiveMind.context.gather.all`](hivemind.md) |
| `session` | `get` | [`private.config.oosh.session.file.get`](config.md) · [`private.config.user.session.file.get`](config.md) · [`private.test.suite.session.files.get`](test.suite.md) |
| `session` | `has` | [`otmux.session.has`](otmux.md) · [`private.otmux.size.lock.has`](otmux.md) |
| `session` | `import` | [`claudeFlow.session.import`](claudeFlow.md) · [`hiveMind.protected.team.import`](hivemind.md) |
| `session` | `init` | [`hiveMind.oosh.init`](hivemind.md) · [`hiveMind.team.init.oosh`](hivemind.md) |
| `session` | `is` | [`private.config.oosh.session.split.is`](config.md) · [`private.config.session.split.is`](config.md) |
| `session` | `join` | [`claudeCode.join`](claudeCode.md) |
| `session` | `kill` | [`otmux.session.kill`](otmux.md) · [`otmux.session.kill.all`](otmux.md) |
| `session` | `list` | [`claudeFlow.session.list`](claudeFlow.md) · [`hiveMind.process.list`](hivemind.md) · [`hiveMind.registry.list`](hivemind.md) · [`hiveMind.team.models.list`](hivemind.md) · [`otmux.pane.list`](otmux.md) · [`otmux.session.list`](otmux.md) · [`private.otmux.size.lock.list`](otmux.md) |
| `session` | `load` | [`claudeFlow.session.load`](claudeFlow.md) |
| `session` | `lock` | [`otmux.session.lock`](otmux.md) · [`otmux.size.lock`](otmux.md) · [`otmux.window.size.lock`](otmux.md) |
| `session` | `log` | [`hiveMind.metrics.log`](hivemind.md) |
| `session` | `lookup` | [`private.hiveMind.session.lookup`](hivemind.md) |
| `session` | `loop` | [`hiveMind.team.loop`](hivemind.md) |
| `session` | `ls` | [`claudeFlow.session.ls`](claudeFlow.md) |
| `session` | `measure` | [`private.scrumMaster.measure.context`](scrumMaster.md) · [`private.scrumMaster.measure.pane`](scrumMaster.md) · [`private.scrumMaster.measure.speed`](scrumMaster.md) · [`private.scrumMaster.measure.subscription`](scrumMaster.md) · [`private.scrumMaster.measure.team`](scrumMaster.md) · [`scrumMaster.context.measure`](scrumMaster.md) · [`scrumMaster.pane.measure`](scrumMaster.md) · [`scrumMaster.speed.measure`](scrumMaster.md) · [`scrumMaster.subscription.measure`](scrumMaster.md) · [`scrumMaster.team.measure`](scrumMaster.md) |
| `session` | `migrate` | [`hiveMind.team.migrate`](hivemind.md) · [`private.config.oosh.session.migrate`](config.md) · [`private.config.user.session.migrate`](config.md) |
| `session` | `monitor` | [`hiveMind.agent.monitor`](hivemind.md) · [`hiveMind.agent.monitor.cycle`](hivemind.md) · [`hiveMind.monitor.cycle`](hivemind.md) · [`hiveMind.team.monitor`](hivemind.md) |
| `session` | `new` | [`otmux.session.new`](otmux.md) |
| `session` | `next` | [`otmux.session.next`](otmux.md) |
| `session` | `prev` | [`otmux.session.prev`](otmux.md) |
| `session` | `probe` | [`claudeCode.session.probe`](claudeCode.md) · [`claudeCode.session.probe.fromCapture`](claudeCode.md) · [`hiveMind.agent.session.probe`](hivemind.md) |
| `session` | `read` | [`scrumMaster.context.read`](scrumMaster.md) |
| `session` | `reconcile` | [`hiveMind.consistency.reconcile`](hivemind.md) |
| `session` | `recover` | [`claudeCode.session.recover`](claudeCode.md) · [`hiveMind.cold.recover`](hivemind.md) · [`hiveMind.team.recover`](hivemind.md) |
| `session` | `refresh` | [`hiveMind.ctx.refresh`](hivemind.md) · [`hiveMind.ctx.refresh.dry`](hivemind.md) · [`hiveMind.registry.refresh`](hivemind.md) · [`private.hiveMind.ctx.refresh.impl`](hivemind.md) |
| `session` | `register` | [`hiveMind.team.register`](hivemind.md) |
| `session` | `remove` | [`hiveMind.team.remove`](hivemind.md) · [`private.otmux.size.lock.remove`](otmux.md) |
| `session` | `rename` | [`otmux.session.rename`](otmux.md) |
| `session` | `resolve` | [`hiveMind.resolve`](hivemind.md) · [`private.hiveMind.session.resolve.uuid`](hivemind.md) · [`private.scrumMaster.resolve.pane`](scrumMaster.md) |
| `session` | `restore` | [`claudeFlow.session.restore`](claudeFlow.md) · [`otmux.layout.restore`](otmux.md) · [`private.test.suite.session.restore`](test.suite.md) |
| `session` | `rm` | [`claudeFlow.session.rm`](claudeFlow.md) |
| `session` | `save` | [`claudeCode.session.save`](claudeCode.md) · [`claudeFlow.session.save`](claudeFlow.md) · [`config.session.save`](config.md) · [`log.session.save`](log.md) · [`otmux.layout.save`](otmux.md) |
| `session` | `scan` | [`scrumMaster.subscription.scan`](scrumMaster.md) |
| `session` | `set` | [`hiveMind.team.host.set`](hivemind.md) · [`hiveMind.team.state.set`](hivemind.md) · [`private.otmux.size.lock.set`](otmux.md) |
| `session` | `setup` | [`hiveMind.team.setup`](hivemind.md) · [`hiveMind.team.setup.full`](hivemind.md) · [`hiveMind.team.setup.oosh`](hivemind.md) · [`otmux.tronMonitor.setup`](otmux.md) |
| `session` | `show` | [`otmux.layout.show`](otmux.md) |
| `session` | `store` | [`private.hiveMind.session.store`](hivemind.md) · [`private.hiveMind.session.store.deferred`](hivemind.md) |
| `session` | `sweep` | [`hiveMind.pane.sweep`](hivemind.md) · [`hiveMind.pane.sweep.cycle`](hivemind.md) · [`hiveMind.sweep`](hivemind.md) · [`hiveMind.sweep.cycle`](hivemind.md) · [`hiveMind.team.sweep`](hivemind.md) · [`private.scrumMaster.sweep.isStable`](scrumMaster.md) |
| `session` | `switch` | [`hiveMind.team.switch`](hivemind.md) · [`otmux.session.switch`](otmux.md) |
| `session` | `train` | [`hiveMind.agent.train`](hivemind.md) · [`hiveMind.train`](hivemind.md) |
| `session` | `unblock` | [`hiveMind.agent.unblock`](hivemind.md) · [`hiveMind.unblock`](hivemind.md) |
| `session` | `unlock` | [`otmux.size.unlock`](otmux.md) · [`otmux.window.size.unlock`](otmux.md) |
| `session` | `write` | [`private.log.session.write`](log.md) |
| `sessionFromPane` |  | [`private.otmux.sessionFromPane`](otmux.md) |
| `sessionId` |  | [`claudeCode.session.name`](claudeCode.md) |
| `sessionId` | `delete` | [`claudeFlow.session.delete`](claudeFlow.md) |
| `sessionId` | `fork` | [`claudeCode.fork`](claudeCode.md) · [`claudeCode.fork.byID`](claudeCode.md) |
| `sessionId` | `join` | [`claudeCode.join.byID`](claudeCode.md) |
| `sessionId` | `load` | [`claudeFlow.session.load`](claudeFlow.md) |
| `sessionId` | `resolve` | [`private.claudeCode.resolve.projectDir`](claudeCode.md) |
| `sessionId` | `restore` | [`claudeFlow.session.restore`](claudeFlow.md) |
| `sessionId` | `rm` | [`claudeFlow.session.rm`](claudeFlow.md) |
| `sessionSplit` | `export` | [`private.config.variables.export`](config.md) |
| `sessionSplit` | `list` | [`private.config.variables.list`](config.md) |
| `sessionSplit` | `save` | [`private.config.save`](config.md) |
| `session_filter` | `discover` | [`hiveMind.protected.agents.discover`](hivemind.md) |
| `sessions` |  | [`claudeCode.sessions`](claudeCode.md) · [`otmux.sessions`](otmux.md) · [`private.hiveMind.handler.agent.forked.sessions`](hivemind.md) · [`private.hiveMind.handler.agent.killed.sessions`](hivemind.md) · [`private.hiveMind.handler.agent.spawned.sessions`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.sessions`](hivemind.md) |
| `sessions` | `migrate` | [`private.hiveMind.sessions.migrate`](hivemind.md) |
| `settings` |  | [`osx.timemachine.settings`](osx.md) |
| `settings` | `install` | [`osx.timemachine.settings.install`](osx.md) |
| `settingsJson` |  | [`private.osemvec.settingsJson`](osemvec.md) |
| `setup` |  | [`private.setup.gate`](setup.md) · [`private.setup.headless.darwin`](setup.md) · [`private.setup.headless.linux`](setup.md) · [`private.setup.samba.password.darwin`](setup.md) · [`private.setup.samba.password.linux`](setup.md) · [`private.setup.samba.support.darwin`](setup.md) · [`private.setup.samba.support.linux`](setup.md) · [`private.setup.samba.users.any`](setup.md) · [`private.setup.vnc.password.darwin`](setup.md) · [`private.setup.vnc.password.linux`](setup.md) · [`setup.all`](setup.md) · [`setup.chromium`](setup.md) · [`setup.docker`](setup.md) · [`setup.headless`](setup.md) · [`setup.nodejs`](setup.md) · [`setup.npm`](setup.md) · [`setup.nvm`](setup.md) · [`setup.pacstall`](setup.md) · [`setup.samba.password`](setup.md) · [`setup.samba.support`](setup.md) · [`setup.status.headless`](setup.md) · [`setup.vnc.password`](setup.md) |
| `setup` | `apply` | [`private.otmux.setup.clipboard.apply`](otmux.md) |
| `setup` | `enable` | [`setup.headless.enable`](setup.md) |
| `setup` | `ensure` | [`private.setup.pm.ensure`](setup.md) |
| `setup` | `get` | [`private.setup.package.get`](setup.md) · [`private.setup.user.get`](setup.md) · [`private.setup.vnc.unit.get`](setup.md) |
| `setup` | `install` | [`private.setup.cmds.install`](setup.md) · [`private.setup.template.install`](setup.md) |
| `setup` | `is` | [`private.setup.nvm.is`](setup.md) |
| `setup` | `load` | [`private.setup.load`](setup.md) |
| `setup` | `run` | [`private.setup.nvm.run`](setup.md) |
| `setup` | `skip` | [`private.setup.linux.skip`](setup.md) |
| `setup` | `snapAppStore` | [`setup.snapAppStore`](setup.md) |
| `setup` | `step` | [`private.setup.all.step`](setup.md) |
| `setup` | `switch` | [`private.setup.services.switch`](setup.md) |
| `shape` |  | [`private.ogit.folder.shape`](ogit.md) |
| `share` |  | [`share.samba.service`](share.md) · [`share.samba.status`](share.md) · [`share.status`](share.md) |
| `share` | `edit` | [`share.samba.config.edit`](share.md) |
| `share` | `install` | [`share.samba.install`](share.md) |
| `share` | `restart` | [`share.samba.restart`](share.md) |
| `shared` |  | [`private.oo.shared.tree.from.local`](oo.md) · [`private.test.suite.shared.snapshot`](test.suite.md) |
| `shared` | `create` | [`ossh.config.shared.create`](ossh.md) · [`ossh.config.shared.github.create`](ossh.md) |
| `shared` | `deploy` | [`ossh.config.shared.seed.from.local.deploy.key`](ossh.md) |
| `shared` | `ensure` | [`private.oo.shared.tree.ensure`](oo.md) · [`private.oo.user.shared.symlinks.ensure`](oo.md) · [`private.this.shared.top.ensure`](this.md) |
| `shared` | `get` | [`private.test.suite.shared.waiver.get`](test.suite.md) |
| `shared` | `remove` | [`private.ossh.shared.ssh.legacy.remove`](ossh.md) |
| `shared` | `repair` | [`private.os.platform.shared.config.repair`](os.md) |
| `shared` | `report` | [`private.test.suite.shared.report`](test.suite.md) |
| `shared` | `restore` | [`private.test.suite.shared.restore`](test.suite.md) |
| `shared` | `seed` | [`ossh.config.shared.seed.fallback`](ossh.md) · [`ossh.config.shared.seed.github`](ossh.md) |
| `shared` | `verify` | [`private.test.suite.shared.verify`](test.suite.md) |
| `sharedConfig` | `ensure` | [`private.config.bashrc.ensure.all`](config.md) · [`private.config.session.files.ensure.all`](config.md) |
| `sharedConfig` | `get` | [`private.config.linked.homes.get`](config.md) |
| `sharedConfigPath` | `ensure` | [`private.oo.user.shared.symlinks.ensure`](oo.md) |
| `sharedDir` | `create` | [`ossh.config.shared.create`](ossh.md) |
| `sharedOosh` | `ensure` | [`private.config.bashrc.ensure.all`](config.md) · [`private.config.session.files.ensure.all`](config.md) |
| `sharedOosh` | `get` | [`private.this.as.user.preamble.get`](this.md) |
| `sharedWrites` |  | [`private.test.suite.verdict`](test.suite.md) |
| `shell` |  | [`private.hiveMind.shell.descendants`](hivemind.md) |
| `shell` | `classify` | [`private.hiveMind.shell.classify`](hivemind.md) |
| `shell` | `enter` | [`odocker.enter`](odocker.md) |
| `shell` | `exec` | [`odocker.exec`](odocker.md) |
| `shell` | `install` | [`opy.shell.install`](opy.md) |
| `shell` | `list` | [`private.os.shell.files.list`](os.md) |
| `shell` | `reap` | [`hiveMind.shell.reap`](hivemind.md) · [`hiveMind.shell.reap.dry`](hivemind.md) · [`private.hiveMind.shell.reap.impl`](hivemind.md) |
| `shifted` |  | [`hiveMind.protected.panes.shifted`](hivemind.md) · [`private.hiveMind.handler.panes.shifted.registry`](hivemind.md) · [`private.otmux.notifyHiveMind.shifted`](otmux.md) |
| `showsTeam` |  | [`private.tronMonitor.screen.showsTeam`](tronMonitor.md) |
| `side` | `resolve` | [`ogit.conflict.resolve`](ogit.md) |
| `signature` | `register` | [`osemvec.register`](osemvec.md) |
| `signature` | `validate` | [`c2.signature.validate`](c2.md) |
| `size` |  | [`osx.spotlight.by.size`](osx.md) · [`otmux.pane.size`](otmux.md) · [`otmux.size.status`](otmux.md) · [`otmux.window.size`](otmux.md) · [`otmux.window.size.status`](otmux.md) · [`private.otmux.size.currentSession`](otmux.md) |
| `size` | `apply` | [`otmux.window.size.floor.apply`](otmux.md) |
| `size` | `cleanup` | [`private.otmux.size.lock.cleanup`](otmux.md) |
| `size` | `has` | [`private.otmux.size.lock.has`](otmux.md) |
| `size` | `list` | [`private.otmux.size.lock.list`](otmux.md) |
| `size` | `lock` | [`otmux.size.lock`](otmux.md) · [`otmux.window.size.lock`](otmux.md) |
| `size` | `remove` | [`private.otmux.size.lock.remove`](otmux.md) |
| `size` | `set` | [`otmux.pane.size.set`](otmux.md) · [`private.otmux.size.lock.set`](otmux.md) |
| `size` | `unlock` | [`otmux.size.unlock`](otmux.md) · [`otmux.window.size.unlock`](otmux.md) |
| `slug` | `create` | [`hiveMind.plan.create`](hivemind.md) |
| `snapfile` | `check` | [`private.hiveMind.snapshot.version.check`](hivemind.md) |
| `snapshot` |  | [`hiveMind.agent.snapshot`](hivemind.md) · [`private.hiveMind.snapshot.jsonl.path`](hivemind.md) · [`private.hiveMind.snapshot.row.valid`](hivemind.md) · [`private.test.suite.session.snapshot`](test.suite.md) · [`private.test.suite.shared.snapshot`](test.suite.md) · [`private.test.suite.ssh.snapshot`](test.suite.md) |
| `snapshot` | `check` | [`private.hiveMind.snapshot.version.check`](hivemind.md) |
| `snapshot` | `get` | [`private.hiveMind.snapshot.get`](hivemind.md) |
| `snapshot` | `list` | [`hiveMind.snapshot.list`](hivemind.md) |
| `snapshot` | `set` | [`private.hiveMind.snapshot.set`](hivemind.md) |
| `snapshotFile` | `migrate` | [`hiveMind.team.migrate`](hivemind.md) |
| `snapshot_file` | `migrate` | [`hiveMind.teams.migrate`](hivemind.md) |
| `snapshot_file` | `restore` | [`hiveMind.teams.restore`](hivemind.md) |
| `snapshots` | `ensure` | [`private.hiveMind.snapshots.ensure.dir`](hivemind.md) |
| `snapshots` | `list` | [`hiveMind.snapshots.list`](hivemind.md) |
| `snapshots` | `prune` | [`hiveMind.snapshots.prune`](hivemind.md) |
| `snet` |  | [`snet.docker.service.status`](snet.md) · [`snet.service.status`](snet.md) |
| `snet` | `install` | [`snet.install`](snet.md) · [`snet.service.install`](snet.md) |
| `snet` | `stop` | [`snet.service.stop`](snet.md) |
| `snet` | `update` | [`snet.update`](snet.md) |
| `socket` |  | [`otmux.socket`](otmux.md) · [`private.odocker.docker.socket.opt`](odocker.md) |
| `socket` | `check` | [`private.odocker.socket.gid.check`](odocker.md) |
| `socket` | `ensure` | [`private.odocker.socket.access.ensure`](odocker.md) · [`private.odocker.socket.group.ensure`](odocker.md) |
| `socket` | `get` | [`private.odocker.socket.get`](odocker.md) |
| `socketPath` |  | [`private.otmux.socketPath`](otmux.md) |
| `sonnet` |  | [`claudeCode.sonnet`](claudeCode.md) |
| `source` | `get` | [`private.odocker.workspaces.source.host.get`](odocker.md) · [`private.odocker.workspaces.source.path.get`](odocker.md) · [`private.odocker.workspaces.source.url.get`](odocker.md) |
| `sp` |  | [`otmux.sp`](otmux.md) |
| `space` |  | [`disk.space.free`](disk.md) · [`disk.space.used`](disk.md) |
| `space2` |  | [`line.space2`](line.md) |
| `spawned` |  | [`private.hiveMind.handler.agent.spawned.registry`](hivemind.md) · [`private.hiveMind.handler.agent.spawned.sessions`](hivemind.md) |
| `spec` | `set` | [`otmux.window.layout.set`](otmux.md) |
| `speed` | `check` | [`scrumMaster.speed.check`](scrumMaster.md) |
| `speed` | `measure` | [`scrumMaster.speed.measure`](scrumMaster.md) |
| `split` | `is` | [`private.config.oosh.session.split.is`](config.md) · [`private.config.session.split.is`](config.md) |
| `spotlight` |  | [`osx.spotlight`](osx.md) · [`osx.spotlight.by.name`](osx.md) · [`osx.spotlight.by.size`](osx.md) · [`osx.spotlight.bykind`](osx.md) |
| `src` | `link` | [`otmux.window.link`](otmux.md) |
| `src` | `linkWindow` | [`private.otmux.linkWindow`](otmux.md) |
| `src` | `pull` | [`private.ossh.rsync.pull`](ossh.md) |
| `src` | `rsync` | [`private.ossh.rsync`](ossh.md) |
| `src` | `scp` | [`ossh.scp`](ossh.md) |
| `srcDir` | `import` | [`private.ogit.branch.import`](ogit.md) |
| `ssh` |  | [`private.ossh.ssh`](ossh.md) · [`private.test.suite.ssh.snapshot`](test.suite.md) · [`user.ssh.status`](user.md) |
| `ssh` | `backup` | [`user.ssh.backup`](user.md) · [`user.ssh.backup.status`](user.md) |
| `ssh` | `create` | [`user.ssh.create.folders`](user.md) |
| `ssh` | `get` | [`ossh.ssh.parameter.get`](ossh.md) · [`private.test.suite.ssh.mode.get`](test.suite.md) · [`private.test.suite.ssh.origin.get`](test.suite.md) · [`private.test.suite.ssh.secrets.changed.get`](test.suite.md) · [`private.test.suite.ssh.stamp.get`](test.suite.md) · [`user.ssh.get.file.name`](user.md) · [`user.ssh.get.key.name`](user.md) |
| `ssh` | `is` | [`private.test.suite.ssh.secret.is`](test.suite.md) |
| `ssh` | `list` | [`user.ssh.backup.list`](user.md) |
| `ssh` | `migrate` | [`user.ssh.backup.migrate`](user.md) |
| `ssh` | `pull` | [`user.ssh.rootkey.pull`](user.md) |
| `ssh` | `push` | [`user.ssh.rootkey.file.push`](user.md) · [`user.ssh.rootkey.push`](user.md) |
| `ssh` | `remove` | [`private.ossh.shared.ssh.legacy.remove`](ossh.md) |
| `ssh` | `rename` | [`user.ssh.rename.files`](user.md) |
| `ssh` | `report` | [`private.test.suite.ssh.report`](test.suite.md) |
| `ssh` | `restore` | [`private.test.suite.ssh.restore`](test.suite.md) · [`user.ssh.restore`](user.md) |
| `ssh` | `revoke` | [`user.ssh.rootkey.file.revoke`](user.md) |
| `ssh` | `run` | [`private.certificates.update.ssh.run`](ossh.md) |
| `ssh` | `set` | [`config.ssh.host.set`](config.md) · [`user.ssh.set.key.name`](user.md) |
| `ssh` | `verify` | [`private.test.suite.ssh.verify`](test.suite.md) |
| `sshConfigHost` |  | [`ossh.certificates.status`](ossh.md) · [`ossh.cmd`](ossh.md) |
| `sshConfigHost` | `create` | [`ossh.install.create`](ossh.md) |
| `sshConfigHost` | `delete` | [`ossh.config.delete`](ossh.md) |
| `sshConfigHost` | `deploy` | [`ossh.config.shared.seed.from.local.deploy.key`](ossh.md) |
| `sshConfigHost` | `discover` | [`ossh.pm.discover`](ossh.md) |
| `sshConfigHost` | `get` | [`ossh.config.get`](ossh.md) · [`ossh.ssh.parameter.get`](ossh.md) · [`ossh.url.get`](ossh.md) · [`private.ossh.get.config`](ossh.md) · [`private.ossh.get.ssh.parameter`](ossh.md) · [`private.ossh.get.url`](ossh.md) |
| `sshConfigHost` | `harden` | [`ossh.harden`](ossh.md) · [`ossh.harden.fail2ban`](ossh.md) · [`ossh.harden.firewall`](ossh.md) · [`ossh.harden.packages`](ossh.md) · [`ossh.harden.sshd`](ossh.md) · [`ossh.harden.sshd.allowusers`](ossh.md) · [`ossh.harden.unattended.upgrades`](ossh.md) · [`private.ossh.harden.preflight`](ossh.md) |
| `sshConfigHost` | `install` | [`ossh.create.and.install`](ossh.md) · [`ossh.install`](ossh.md) · [`ossh.install.user.remote`](ossh.md) · [`ossh.prereqs.install`](ossh.md) · [`private.ossh.install.key.authorize`](ossh.md) |
| `sshConfigHost` | `log` | [`ossh.install.log`](ossh.md) |
| `sshConfigHost` | `login` | [`ossh.login`](ossh.md) |
| `sshConfigHost` | `parse` | [`ossh.config.parse`](ossh.md) |
| `sshConfigHost` | `seed` | [`ossh.config.shared.seed.fallback`](ossh.md) · [`ossh.config.shared.seed.github`](ossh.md) |
| `sshConfigHost` | `show` | [`ossh.show`](ossh.md) |
| `sshConfigHost` | `update` | [`oo.remote.update`](oo.md) · [`ossh.certificates.update`](ossh.md) |
| `sshConfigName` |  | [`parameterTestScript.one`](parameterTestScript.md) · [`parameterTestScript.oneDefaultValue`](parameterTestScript.md) · [`parameterTestScript.oneDefaultValueQuotes`](parameterTestScript.md) |
| `sshConfigName` | `create` | [`myId.create`](myId.md) · [`myId.key.deploy.create`](myId.md) · [`ossh.config.create`](ossh.md) |
| `sshConfigName` | `deploy` | [`myId.create.github.deploy.key`](myId.md) |
| `sshConfigName` | `get` | [`myId.get`](myId.md) · [`private.ossh.config.block.put.get`](ossh.md) |
| `sshConfigName` | `pull` | [`ossh.pull.config`](ossh.md) |
| `sshConfigName` | `push` | [`ossh.config.push`](ossh.md) · [`ossh.push.config`](ossh.md) · [`private.ossh.config.push`](ossh.md) |
| `sshConfigName` | `set` | [`config.ssh.host.set`](config.md) |
| `sshConfigNameUsedForLocal` | `continue` | [`ossh.install.continue.local`](ossh.md) |
| `sshDir` |  | [`osshLayout.role.developking`](osshLayout.md) · [`osshLayout.role.installer`](osshLayout.md) · [`osshLayout.role.outeruser`](osshLayout.md) · [`osshLayout.role.owner`](osshLayout.md) · [`user.in`](user.md) · [`user.ssh.status`](user.md) |
| `sshDir` | `adopt` | [`private.user.authorized.keys.adopt`](user.md) |
| `sshDir` | `backup` | [`user.ssh.backup`](user.md) |
| `sshDir` | `build` | [`osshLayout.build`](osshLayout.md) |
| `sshDir` | `check` | [`ossh.folder.fix.check`](ossh.md) |
| `sshDir` | `create` | [`ossh.id.create`](ossh.md) · [`ossh.id.create.fromKey`](ossh.md) · [`ossh.key.folder.create`](ossh.md) · [`ossh.key.folders.create`](ossh.md) · [`private.ossh.create.key.folders`](ossh.md) · [`user.ssh.create.folders`](user.md) |
| `sshDir` | `delete` | [`ossh.key.folder.delete`](ossh.md) · [`ossh.key.folders.delete`](ossh.md) · [`private.ossh.delete.key.folders`](ossh.md) |
| `sshDir` | `detect` | [`private.detect.ssh.key`](ossh.md) · [`private.detect.ssh.key.type`](ossh.md) |
| `sshDir` | `ensure` | [`private.osshLayout.ensure.keypair`](osshLayout.md) |
| `sshDir` | `fix` | [`ossh.folder.fix`](ossh.md) · [`ossh.permission.fix`](ossh.md) · [`ossh.rights.fix`](ossh.md) |
| `sshDir` | `get` | [`ossh.config.get`](ossh.md) · [`ossh.get.public.id`](ossh.md) · [`ossh.id.public.get`](ossh.md) · [`ossh.publicId.get`](ossh.md) · [`private.ossh.get.public.id`](ossh.md) · [`private.test.suite.ssh.stamp.get`](test.suite.md) |
| `sshDir` | `init` | [`user.init`](user.md) |
| `sshDir` | `isInstalled` | [`ossh.isInstalled`](ossh.md) |
| `sshDir` | `list` | [`ossh.list.ids`](ossh.md) · [`user.list.other.identities`](user.md) |
| `sshDir` | `normalize` | [`private.ossh.folder.fix.config.normalize`](ossh.md) |
| `sshDir` | `prune` | [`private.ossh.folder.fix.prune`](ossh.md) |
| `sshDir` | `pull` | [`ossh.id.pull`](ossh.md) · [`ossh.key.pull`](ossh.md) · [`ossh.pull.id`](ossh.md) · [`private.ossh.key.pull`](ossh.md) · [`private.ossh.pull.id`](ossh.md) |
| `sshDir` | `push` | [`ossh.id.push`](ossh.md) · [`ossh.key.push`](ossh.md) · [`ossh.push.id`](ossh.md) · [`ossh.push.key`](ossh.md) · [`private.ossh.id.push`](ossh.md) · [`private.ossh.key.push`](ossh.md) |
| `sshDir` | `rebuild` | [`private.user.authorized.keys.rebuild`](user.md) |
| `sshDir` | `remove` | [`private.ossh.github.copy.remove`](ossh.md) |
| `sshDir` | `restore` | [`user.ssh.restore`](user.md) |
| `sshDir` | `strip` | [`private.ossh.folder.fix.config.strip.legacy`](ossh.md) |
| `sshDir` | `tighten` | [`private.osshLayout.perms.tighten`](osshLayout.md) |
| `sshDir` | `update` | [`ossh.authorized.keys.update`](ossh.md) · [`ossh.authorized_keys.update`](ossh.md) · [`user.authorized.keys.update`](user.md) · [`user.update.authorized_keys`](user.md) |
| `sshFlags` |  | [`private.ossh.ssh`](ossh.md) |
| `sshHost` | `delegate` | [`hiveMind.task.delegate`](hivemind.md) |
| `sshHost` | `migrate` | [`hiveMind.team.migrate`](hivemind.md) |
| `sshHost` | `pull` | [`hiveMind.team.pull`](hivemind.md) |
| `sshHost` | `transfer` | [`private.hiveMind.task.transfer`](hivemind.md) |
| `sshId` |  | [`user.in`](user.md) |
| `sshKeyName` | `rename` | [`user.ssh.rename.files`](user.md) |
| `sshKeyName` | `set` | [`ossh.key.name.set`](ossh.md) · [`ossh.key.set.name`](ossh.md) · [`private.ossh.set.key.name`](ossh.md) |
| `sshWrites` |  | [`private.test.suite.verdict`](test.suite.md) |
| `sshd` | `reload` | [`private.os.platform.sshd.reload`](os.md) |
| `stackTrace` |  | [`debug.stackTrace`](debug.md) |
| `staged` |  | [`private.osshLayout.staged.dir`](osshLayout.md) · [`private.osshLayout.staged.email`](osshLayout.md) |
| `staged` | `has` | [`private.osshLayout.staged.has.keypair`](osshLayout.md) · [`private.osshLayout.staged.has.privkey`](osshLayout.md) · [`private.osshLayout.staged.has.pubkey`](osshLayout.md) |
| `stamp` | `get` | [`private.test.suite.config.stamp.get`](test.suite.md) · [`private.test.suite.ssh.stamp.get`](test.suite.md) |
| `stash` | `drop` | [`ogit.stash.drop`](ogit.md) |
| `stash` | `get` | [`ogit.stash.top.get`](ogit.md) |
| `stash` | `pop` | [`ogit.stash.pop`](ogit.md) |
| `stash` | `push` | [`ogit.stash.push`](ogit.md) |
| `stashDir` | `restore` | [`private.ogit.folder.ignored.restore`](ogit.md) |
| `stashDir` | `save` | [`private.ogit.folder.ignored.save`](ogit.md) |
| `stashed` | `finish` | [`private.promote.merge.finish`](promote.md) |
| `stat` | `get` | [`private.this.path.stat.get`](this.md) |
| `state` |  | [`claudeCode.session.state`](claudeCode.md) · [`oo.state`](oo.md) · [`otmux.composer.state`](otmux.md) · [`scrumMaster.pdca.state`](scrumMaster.md) · [`state.current`](state.md) · [`state.id`](state.md) · [`state.machine.declaration`](state.md) · [`state.name`](state.md) · [`state.of`](state.md) |
| `state` | `add` | [`state.add`](state.md) |
| `state` | `check` | [`private.check.all.states.added`](state.md) · [`private.check.started`](state.md) · [`private.itterator.check.all.states.added`](state.md) · [`private.itterator.check.started`](state.md) · [`state.check`](state.md) |
| `state` | `clear` | [`hiveMind.agent.state.clear`](hivemind.md) · [`hiveMind.team.state.clear`](hivemind.md) · [`private.hiveMind.state.clear`](hivemind.md) |
| `state` | `create` | [`state.machine.create`](state.md) |
| `state` | `delete` | [`state.machine.delete`](state.md) |
| `state` | `diagnose` | [`state.diagnose`](state.md) |
| `state` | `edit` | [`state.machine.edit`](state.md) |
| `state` | `exists` | [`state.machine.exists`](state.md) |
| `state` | `find` | [`private.itterator.find`](state.md) · [`state.find`](state.md) |
| `state` | `get` | [`hiveMind.agent.state.get`](hivemind.md) · [`private.hiveMind.state.get`](hivemind.md) |
| `state` | `init` | [`private.certificates.update.state.machine.init`](ossh.md) · [`private.promote.state.machine.init`](promote.md) · [`private.states.init`](state.md) · [`state.machine.init`](state.md) |
| `state` | `list` | [`private.itterator.list`](state.md) · [`state.list`](state.md) · [`state.machine.list`](state.md) |
| `state` | `loop` | [`private.loop.states`](state.md) |
| `state` | `next` | [`state.next`](state.md) |
| `state` | `rename` | [`state.rename`](state.md) |
| `state` | `set` | [`hiveMind.agent.state.set`](hivemind.md) · [`hiveMind.team.state.set`](hivemind.md) · [`private.hiveMind.state.set`](hivemind.md) · [`state.set`](state.md) |
| `state` | `setup` | [`private.check.setup`](state.md) |
| `state` | `stage` | [`state.stage`](state.md) |
| `state` | `update` | [`private.state.machine.update`](state.md) · [`private.state.update.current.machine`](state.md) |
| `stateDir` |  | [`private.osemvec.stateDir`](osemvec.md) |
| `stateFound` | `check` | [`private.check.acting`](scrumMaster.md) · [`private.check.checking`](scrumMaster.md) · [`private.check.confirmation.received`](promote.md) · [`private.check.confirmation.received.prod`](promote.md) · [`private.check.doing`](scrumMaster.md) · [`private.check.error.max.iterations`](scrumMaster.md) · [`private.check.finished`](ossh.md) · [`private.check.finished`](promote.md) · [`private.check.finished`](scrumMaster.md) · [`private.check.initialization.checked`](promote.md) · [`private.check.merged.to.prod`](promote.md) · [`private.check.merged.to.testing`](promote.md) · [`private.check.planning`](scrumMaster.md) · [`private.check.prod.path.started`](promote.md) · [`private.check.prod.pushed`](promote.md) · [`private.check.prod.tagged`](promote.md) · [`private.check.target.checked`](promote.md) · [`private.check.testing.pushed`](promote.md) · [`private.check.testing.tagged`](promote.md) · [`private.check.uncommitted.checked`](promote.md) |
| `stateFound` | `complete` | [`private.check.cycle.complete`](scrumMaster.md) |
| `stateFound` | `create` | [`private.check.certificates.update.create.certbot`](ossh.md) · [`private.check.certificates.update.create.structr`](ossh.md) |
| `stateFound` | `next` | [`private.check.next.custom.state`](ossh.md) · [`private.check.next.custom.state`](promote.md) · [`private.check.next.custom.state`](scrumMaster.md) |
| `stateFound` | `restore` | [`private.check.certificates.update.restore.workspace`](ossh.md) |
| `stateFound` | `rotate` | [`private.check.certificates.update.rotate.empty`](ossh.md) |
| `stateFound` | `start` | [`private.check.certificates.update.start.structr`](ossh.md) |
| `stateFound` | `stop` | [`private.check.certificates.update.stop.certbot`](ossh.md) · [`private.check.certificates.update.stop.structr`](ossh.md) |
| `stateFound` | `test` | [`private.check.test.suite.passed`](promote.md) |
| `stateFound` | `update` | [`private.check.certificates.update.archive.workspace`](ossh.md) |
| `stateFound` | `verify` | [`private.check.certificates.update.verify.https`](ossh.md) |
| `stateID` | `check` | [`private.itterator.check.all.states.added`](state.md) · [`private.itterator.check.started`](state.md) |
| `stateID` | `list` | [`private.itterator.list`](state.md) |
| `statefile` |  | [`private.hiveMind.ctxrefresh.statefile`](hivemind.md) |
| `states` | `init` | [`private.states.init`](state.md) |
| `stats` |  | [`claudeFlow.memory.stats`](claudeFlow.md) |
| `status` |  | [`2c.status`](2c.md) · [`agentRoom.agent.status`](agentRoom.md) · [`agentRoom.backend.status`](agentRoom.md) · [`backup.status`](backup.md) · [`c2.status`](c2.md) · [`certificates.status`](certificates.md) · [`claudeCode.status`](claudeCode.md) · [`claudeFlow.agent.status`](claudeFlow.md) · [`claudeFlow.hive.status`](claudeFlow.md) · [`claudeFlow.mcp.status`](claudeFlow.md) · [`claudeFlow.status`](claudeFlow.md) · [`claudeFlow.statusline.status`](claudeFlow.md) · [`claudeFlow.swarm.status`](claudeFlow.md) · [`claudeFlow.task.status`](claudeFlow.md) · [`claudeFlow.tmux.status`](claudeFlow.md) · [`context.lifecycle.status`](context.md) · [`hiveMind.agent.context.status`](hivemind.md) · [`hiveMind.status`](hivemind.md) · [`hiveMind.team.context.status`](hivemind.md) · [`hiveMind.team.status`](hivemind.md) · [`hiveMind.watchdog.status`](hivemind.md) · [`odocker.status`](odocker.md) · [`ogit.layout.status`](ogit.md) · [`osemvec.status`](osemvec.md) · [`ossh.certificates.status`](ossh.md) · [`ossh.connection.status`](ossh.md) · [`ossh.service.status.darwin`](ossh.md) · [`ossh.service.status.linux`](ossh.md) · [`ossh.service.status.unknown`](ossh.md) · [`ossh.status`](ossh.md) · [`otmux.size.status`](otmux.md) · [`otmux.status`](otmux.md) · [`otmux.window.size.status`](otmux.md) · [`path.status`](path.md) · [`promote.status`](promote.md) · [`scrumMaster.subscription.status`](scrumMaster.md) · [`setup.status.headless`](setup.md) · [`share.samba.status`](share.md) · [`share.status`](share.md) · [`snet.docker.service.status`](snet.md) · [`snet.service.status`](snet.md) · [`status.path`](status.md) · [`status.scope`](status.md) · [`status.scope.full`](status.md) · [`user.ssh.status`](user.md) |
| `status` | `check` | [`ogit.status.check`](ogit.md) |
| `status` | `discover` | [`status.discover`](status.md) |
| `status` | `show` | [`ogit.status.show`](ogit.md) |
| `statusline` |  | [`claudeFlow.statusline`](claudeFlow.md) · [`claudeFlow.statusline.config`](claudeFlow.md) · [`claudeFlow.statusline.off`](claudeFlow.md) · [`claudeFlow.statusline.on`](claudeFlow.md) · [`claudeFlow.statusline.status`](claudeFlow.md) |
| `statusline` | `preview` | [`claudeFlow.statusline.preview`](claudeFlow.md) |
| `statusline` | `set` | [`claudeFlow.statusline.set`](claudeFlow.md) |
| `statusline` | `toggle` | [`claudeFlow.statusline.toggle`](claudeFlow.md) |
| `str` | `escape` | [`private.hiveMind.audit.json.escape`](hivemind.md) |
| `strategy` |  | [`backup.strategy`](backup.md) · [`private.backup.strategy.secureMove`](backup.md) |
| `strategy` | `help` | [`backup.strategy.help`](backup.md) |
| `strategy` | `replaceByFolderLinks` | [`private.backup.strategy.replaceByFolderLinks`](backup.md) |
| `string` |  | [`private.config.string.upper`](config.md) |
| `string` | `quote` | [`config.string.quote`](config.md) |
| `stubs` | `get` | [`private.oo.method.stubs.get`](oo.md) |
| `stubs` | `source` | [`private.promote.platform.stubs.source`](promote.md) |
| `subcommand` |  | [`claudeFlow.agent`](claudeFlow.md) · [`claudeFlow.embeddings`](claudeFlow.md) · [`claudeFlow.hive`](claudeFlow.md) · [`claudeFlow.hooks`](claudeFlow.md) · [`claudeFlow.mcp`](claudeFlow.md) · [`claudeFlow.memory`](claudeFlow.md) · [`claudeFlow.neural`](claudeFlow.md) · [`claudeFlow.perf`](claudeFlow.md) · [`claudeFlow.performance`](claudeFlow.md) · [`claudeFlow.security`](claudeFlow.md) · [`claudeFlow.session`](claudeFlow.md) · [`claudeFlow.statusline`](claudeFlow.md) · [`claudeFlow.swarm`](claudeFlow.md) · [`claudeFlow.task`](claudeFlow.md) · [`claudeFlow.tmux`](claudeFlow.md) |
| `subscription` |  | [`private.scrumMaster.subscription`](scrumMaster.md) · [`private.scrumMaster.subscription.api.legacy`](scrumMaster.md) · [`private.scrumMaster.subscription.auth`](scrumMaster.md) · [`private.scrumMaster.subscription.cacheFile`](scrumMaster.md) · [`private.scrumMaster.subscription.resets.in`](scrumMaster.md) · [`private.scrumMaster.subscription.verdict`](scrumMaster.md) · [`scrumMaster.subscription`](scrumMaster.md) · [`scrumMaster.subscription.cache.age`](scrumMaster.md) · [`scrumMaster.subscription.json`](scrumMaster.md) · [`scrumMaster.subscription.status`](scrumMaster.md) |
| `subscription` | `call` | [`private.scrumMaster.subscription.api.call`](scrumMaster.md) |
| `subscription` | `check` | [`scrumMaster.subscription.check`](scrumMaster.md) |
| `subscription` | `measure` | [`scrumMaster.subscription.measure`](scrumMaster.md) · [`scrumMaster.subscription.measure.api`](scrumMaster.md) |
| `subscription` | `parse` | [`private.measure.subscription.api.parse`](scrumMaster.md) · [`private.scrumMaster.subscription.parse`](scrumMaster.md) |
| `subscription` | `scan` | [`scrumMaster.subscription.scan`](scrumMaster.md) |
| `sudo` | `get` | [`private.oo.path.sudo.get`](oo.md) |
| `sudo` | `rerun` | [`private.ogit.sudo.rerun`](ogit.md) |
| `suite` |  | [`private.test.suite.category`](test.suite.md) · [`private.test.suite.session.snapshot`](test.suite.md) · [`private.test.suite.shared.snapshot`](test.suite.md) · [`private.test.suite.ssh.snapshot`](test.suite.md) · [`private.test.suite.verdict`](test.suite.md) · [`test.suite.all`](test.suite.md) · [`test.suite.core`](test.suite.md) · [`test.suite.extended`](test.suite.md) · [`test.suite.gate`](test.suite.md) · [`test.suite.level`](test.suite.md) · [`test.suite.summary`](test.suite.md) |
| `suite` | `clear` | [`private.test.suite.results.clear`](test.suite.md) |
| `suite` | `close` | [`private.test.suite.results.dir.close`](test.suite.md) |
| `suite` | `discover` | [`test.suite.discover`](test.suite.md) |
| `suite` | `get` | [`private.test.suite.config.stamp.get`](test.suite.md) · [`private.test.suite.results.file.get`](test.suite.md) · [`private.test.suite.session.files.get`](test.suite.md) · [`private.test.suite.shared.waiver.get`](test.suite.md) · [`private.test.suite.ssh.mode.get`](test.suite.md) · [`private.test.suite.ssh.origin.get`](test.suite.md) · [`private.test.suite.ssh.secrets.changed.get`](test.suite.md) · [`private.test.suite.ssh.stamp.get`](test.suite.md) |
| `suite` | `init` | [`test.suite.init`](test.suite.md) |
| `suite` | `is` | [`private.test.suite.ssh.secret.is`](test.suite.md) |
| `suite` | `isolate` | [`test.suite.config.isolate`](test.suite.md) |
| `suite` | `list` | [`private.test.suite.list.names`](test.suite.md) · [`private.test.suite.list.tags`](test.suite.md) · [`test.suite.list`](test.suite.md) |
| `suite` | `make` | [`test.suite.fixture.make`](test.suite.md) |
| `suite` | `open` | [`private.test.suite.results.dir.open`](test.suite.md) |
| `suite` | `report` | [`private.test.suite.shared.report`](test.suite.md) · [`private.test.suite.ssh.report`](test.suite.md) |
| `suite` | `reset` | [`private.test.suite.counters.reset`](test.suite.md) |
| `suite` | `restore` | [`private.test.suite.session.restore`](test.suite.md) · [`private.test.suite.shared.restore`](test.suite.md) · [`private.test.suite.ssh.restore`](test.suite.md) · [`test.suite.config.restore`](test.suite.md) |
| `suite` | `run` | [`private.test.suite.run.filtered`](test.suite.md) · [`test.suite.run`](test.suite.md) |
| `suite` | `save` | [`test.suite.save.results`](test.suite.md) |
| `suite` | `validate` | [`test.suite.portability.validate`](test.suite.md) |
| `suite` | `verify` | [`private.test.suite.shared.verify`](test.suite.md) · [`private.test.suite.ssh.verify`](test.suite.md) |
| `summary` |  | [`hiveMind.metrics.summary`](hivemind.md) · [`test.suite.summary`](test.suite.md) |
| `supervisor` |  | [`hiveMind.watchdog.supervisor`](hivemind.md) |
| `support` |  | [`private.setup.samba.support.darwin`](setup.md) · [`private.setup.samba.support.linux`](setup.md) · [`setup.samba.support`](setup.md) |
| `supported` |  | [`private.odocker.engine.supported`](odocker.md) |
| `sw` |  | [`otmux.sw`](otmux.md) |
| `swapped` |  | [`hiveMind.protected.panes.swapped`](hivemind.md) · [`private.hiveMind.handler.panes.swapped.registry`](hivemind.md) · [`private.hiveMind.handler.panes.swapped.role_env`](hivemind.md) |
| `swarm` |  | [`claudeFlow.swarm`](claudeFlow.md) · [`claudeFlow.swarm.status`](claudeFlow.md) · [`claudeFlow.swarm.v3`](claudeFlow.md) |
| `swarm` | `coordinate` | [`claudeFlow.swarm.coordinate`](claudeFlow.md) |
| `swarm` | `init` | [`claudeFlow.swarm.init`](claudeFlow.md) |
| `swarm` | `scale` | [`claudeFlow.swarm.scale`](claudeFlow.md) |
| `swarm` | `stop` | [`claudeFlow.swarm.stop`](claudeFlow.md) |
| `sweep` | `detect` | [`private.hiveMind.sweep.detect`](hivemind.md) |
| `sweep` | `loop` | [`hiveMind.pane.sweep.loop`](hivemind.md) · [`hiveMind.sweep.loop`](hivemind.md) |
| `sweep` | `probe` | [`private.hiveMind.sweep.ratelimit.probe`](hivemind.md) |
| `symlink` | `backup` | [`private.this.symlink.with.backup`](this.md) |
| `symlinks` | `ensure` | [`private.oo.user.shared.symlinks.ensure`](oo.md) |
| `sync` | `remove` | [`backup.sync.and.remove`](backup.md) |
| `system` | `append` | [`claudeCode.system.prompt.append`](claudeCode.md) |
| `system` | `get` | [`private.ossh.system.config.file.get`](ossh.md) · [`private.ossh.system.known.hosts.get`](ossh.md) · [`private.user.basehome.system.get`](user.md) |
| `system` | `prompt` | [`claudeCode.system.prompt`](claudeCode.md) |
| `systemPath` | `remove` | [`private.oo.dropin.remove`](oo.md) |
| `systemd` | `is` | [`private.os.systemd.is`](os.md) |
| `tab` |  | [`mycmd.tab`](mycmd.md) · [`mycmd.tab.alias`](mycmd.md) · [`mycmd.tab.buildinCommands`](mycmd.md) · [`mycmd.tab.env`](mycmd.md) · [`mycmd.tab.files`](mycmd.md) · [`mycmd.tab.folders`](mycmd.md) · [`mycmd.tab.groups`](mycmd.md) · [`mycmd.tab.jobs`](mycmd.md) · [`mycmd.tab.user`](mycmd.md) · [`mycmd.tab.variables`](mycmd.md) |
| `table` |  | [`claudeFlow.table`](claudeFlow.md) · [`line.table`](line.md) |
| `tag` | `check` | [`ogit.tag.check`](ogit.md) |
| `tag` | `create` | [`ogit.tag.create`](ogit.md) |
| `tag` | `get` | [`ogit.tag.latest.get`](ogit.md) |
| `tag` | `list` | [`ogit.tag.list`](ogit.md) |
| `tags` | `fetch` | [`ogit.remote.fetch`](ogit.md) |
| `tags` | `push` | [`ogit.remote.push`](ogit.md) |
| `target` |  | [`backup.target`](backup.md) · [`hiveMind.handoff`](hivemind.md) · [`otmux.layout`](otmux.md) · [`otmux.pane.history`](otmux.md) · [`otmux.pane.title`](otmux.md) · [`otmux.tiled`](otmux.md) · [`private.hiveMind.context.denom.for.target`](hivemind.md) · [`private.scrumMaster.velocity.target`](scrumMaster.md) · [`scrumMaster.velocity.target`](scrumMaster.md) |
| `target` | `attach` | [`otmux.attach`](otmux.md) · [`otmux.attach.readonly`](otmux.md) · [`otmux.session.attach`](otmux.md) |
| `target` | `backup` | [`private.this.symlink.with.backup`](this.md) |
| `target` | `capture` | [`otmux.pane.capture`](otmux.md) · [`otmux.pane.capture.full`](otmux.md) · [`otmux.pane.capture.visible`](otmux.md) |
| `target` | `check` | [`osemvec.check`](osemvec.md) |
| `target` | `compact` | [`hiveMind.peer.compact`](hivemind.md) |
| `target` | `count` | [`private.hiveMind.pane.count`](hivemind.md) |
| `target` | `enter` | [`otmux.send.enter`](otmux.md) |
| `target` | `format` | [`otmux.pane.list.format`](otmux.md) |
| `target` | `get` | [`otmux.pane.get`](otmux.md) · [`otmux.window.layout.get`](otmux.md) |
| `target` | `has` | [`otmux.has`](otmux.md) · [`otmux.session.has`](otmux.md) |
| `target` | `install` | [`private.oo.install.launcher`](oo.md) · [`private.setup.template.install`](setup.md) |
| `target` | `isClaudeCode` | [`private.otmux.pane.isClaudeCode`](otmux.md) |
| `target` | `isPane` | [`private.otmux.target.isPane`](otmux.md) |
| `target` | `kill` | [`otmux.kill`](otmux.md) · [`otmux.pane.kill`](otmux.md) · [`otmux.session.kill`](otmux.md) · [`otmux.window.kill`](otmux.md) |
| `target` | `killPane` | [`private.otmux.killPane`](otmux.md) |
| `target` | `killWindow` | [`private.otmux.killWindow`](otmux.md) |
| `target` | `lock` | [`otmux.pane.lock`](otmux.md) |
| `target` | `merge` | [`private.promote.merge.into.folder`](promote.md) |
| `target` | `move` | [`otmux.window.move`](otmux.md) |
| `target` | `moveWindow` | [`private.otmux.moveWindow`](otmux.md) |
| `target` | `rename` | [`otmux.window.rename`](otmux.md) |
| `target` | `resize` | [`otmux.window.aggressive.resize`](otmux.md) |
| `target` | `save` | [`private.scrumMaster.metrics.save`](scrumMaster.md) |
| `target` | `select` | [`otmux.pane.select`](otmux.md) · [`otmux.window.select`](otmux.md) |
| `target` | `selectPane` | [`private.otmux.selectPane`](otmux.md) |
| `target` | `selectWindow` | [`private.otmux.selectWindow`](otmux.md) |
| `target` | `send` | [`otmux.pane.send`](otmux.md) · [`otmux.send`](otmux.md) · [`otmux.send.key`](otmux.md) · [`otmux.send.keys`](otmux.md) · [`otmux.send.raw`](otmux.md) · [`otmux.send.tui`](otmux.md) · [`otmux.send.verified`](otmux.md) · [`private.otmux.send.smart`](otmux.md) |
| `target` | `sendEnter` | [`private.otmux.sendEnter`](otmux.md) |
| `target` | `sendKeys` | [`private.otmux.sendKeys`](otmux.md) |
| `target` | `set` | [`otmux.window.layout.set`](otmux.md) |
| `target` | `show` | [`private.promote.merge.preview.show`](promote.md) |
| `target` | `splitH` | [`otmux.pane.splitH`](otmux.md) |
| `target` | `stop` | [`osemvec.stop`](osemvec.md) |
| `target` | `swap` | [`otmux.window.swap`](otmux.md) |
| `target` | `swapWindow` | [`private.otmux.swapWindow`](otmux.md) |
| `target` | `sweep` | [`private.hiveMind.sweep.paneState`](hivemind.md) |
| `target` | `switch` | [`otmux.session.switch`](otmux.md) · [`otmux.switch`](otmux.md) |
| `target` | `unlink` | [`otmux.window.unlink`](otmux.md) |
| `target` | `unlinkWindow` | [`private.otmux.unlinkWindow`](otmux.md) |
| `target` | `unlock` | [`otmux.pane.unlock`](otmux.md) |
| `targetBase` | `create` | [`backup.config.create`](backup.md) |
| `targetDir` | `add` | [`ogit.worktree.add`](ogit.md) |
| `targetDir` | `clone` | [`ogit.repo.clone`](ogit.md) |
| `targetDir` | `ensure` | [`private.oo.branch.clone.ensure`](oo.md) |
| `targetHashDir` | `push` | [`private.hiveMind.push.captureForkedUUID`](hivemind.md) |
| `targetHome` | `ensure` | [`private.config.session.file.ensure`](config.md) |
| `targetHome` | `get` | [`private.this.as.user.preamble.get`](this.md) |
| `targetHome` | `install` | [`private.user.bashrc.install`](user.md) · [`private.user.oosh.install.shell.darwin`](user.md) · [`private.user.oosh.install.shell.linux`](user.md) |
| `targetPane` | `fork` | [`hiveMind.agent.fork.best`](hivemind.md) |
| `targetPane` | `push` | [`private.hiveMind.push.agent`](hivemind.md) · [`private.hiveMind.push.captureForkedUUID`](hivemind.md) |
| `targetPane` | `swap` | [`otmux.pane.swap`](otmux.md) |
| `targetPane` | `swapPane` | [`private.otmux.swapPane`](otmux.md) |
| `targetPath` |  | [`private.backup.strategy.secureMove`](backup.md) |
| `targetPath` | `replaceByFolderLinks` | [`private.backup.strategy.replaceByFolderLinks`](backup.md) |
| `targetPath` | `rsync` | [`private.backup.rsync`](backup.md) |
| `task` |  | [`claudeFlow.hive.task`](claudeFlow.md) · [`claudeFlow.task`](claudeFlow.md) · [`claudeFlow.task.all`](claudeFlow.md) · [`claudeFlow.task.info`](claudeFlow.md) · [`claudeFlow.task.status`](claudeFlow.md) · [`claudeFlow.tmux.task`](claudeFlow.md) · [`hiveMind.task`](hivemind.md) · [`osemvec.context`](osemvec.md) |
| `task` | `assign` | [`claudeFlow.task.assign`](claudeFlow.md) |
| `task` | `cancel` | [`claudeFlow.task.cancel`](claudeFlow.md) |
| `task` | `create` | [`claudeFlow.task.create`](claudeFlow.md) |
| `task` | `delegate` | [`hiveMind.task.delegate`](hivemind.md) |
| `task` | `list` | [`claudeFlow.task.list`](claudeFlow.md) |
| `task` | `ls` | [`claudeFlow.task.ls`](claudeFlow.md) |
| `task` | `new` | [`claudeFlow.task.new`](claudeFlow.md) |
| `task` | `retry` | [`claudeFlow.task.retry`](claudeFlow.md) |
| `task` | `spawn` | [`claudeFlow.tmux.spawn`](claudeFlow.md) |
| `task` | `transfer` | [`private.hiveMind.task.transfer`](hivemind.md) |
| `taskFile` | `delegate` | [`hiveMind.task.delegate`](hivemind.md) |
| `taskFile` | `transfer` | [`private.hiveMind.task.transfer`](hivemind.md) |
| `taskId` |  | [`claudeFlow.task.info`](claudeFlow.md) · [`claudeFlow.task.status`](claudeFlow.md) |
| `taskId` | `assign` | [`claudeFlow.task.assign`](claudeFlow.md) |
| `taskId` | `cancel` | [`claudeFlow.task.cancel`](claudeFlow.md) |
| `taskId` | `retry` | [`claudeFlow.task.retry`](claudeFlow.md) |
| `team` |  | [`hiveMind.team.active`](hivemind.md) · [`hiveMind.team.context.status`](hivemind.md) · [`hiveMind.team.cycle`](hivemind.md) · [`hiveMind.team.status`](hivemind.md) · [`private.hiveMind.active.team`](hivemind.md) · [`private.hiveMind.handler.team.created.teams`](hivemind.md) · [`private.hiveMind.handler.team.created.tronMonitor`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.queue`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.registry`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.sessions`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.teams`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.tronMonitor`](hivemind.md) · [`private.hiveMind.handler.team.restored.teams`](hivemind.md) · [`private.hiveMind.handler.team.restored.tronMonitor`](hivemind.md) · [`private.hiveMind.team.host`](hivemind.md) |
| `team` | `activate` | [`hiveMind.team.activate`](hivemind.md) |
| `team` | `audit` | [`hiveMind.team.audit`](hivemind.md) |
| `team` | `capture` | [`scrumMaster.team.capture`](scrumMaster.md) |
| `team` | `clear` | [`hiveMind.team.state.clear`](hivemind.md) |
| `team` | `import` | [`hiveMind.protected.team.import`](hivemind.md) |
| `team` | `init` | [`hiveMind.team.init.oosh`](hivemind.md) |
| `team` | `list` | [`hiveMind.team.list`](hivemind.md) · [`hiveMind.team.models.list`](hivemind.md) |
| `team` | `loop` | [`hiveMind.team.loop`](hivemind.md) |
| `team` | `measure` | [`scrumMaster.team.measure`](scrumMaster.md) |
| `team` | `migrate` | [`hiveMind.team.migrate`](hivemind.md) |
| `team` | `monitor` | [`hiveMind.team.monitor`](hivemind.md) |
| `team` | `pull` | [`hiveMind.team.pull`](hivemind.md) |
| `team` | `push` | [`hiveMind.team.push`](hivemind.md) |
| `team` | `recover` | [`hiveMind.team.recover`](hivemind.md) |
| `team` | `register` | [`hiveMind.team.register`](hivemind.md) |
| `team` | `remove` | [`hiveMind.team.remove`](hivemind.md) |
| `team` | `restart` | [`hiveMind.team.restart`](hivemind.md) |
| `team` | `set` | [`hiveMind.team.host.set`](hivemind.md) · [`hiveMind.team.state.set`](hivemind.md) |
| `team` | `setup` | [`hiveMind.team.setup`](hivemind.md) · [`hiveMind.team.setup.full`](hivemind.md) · [`hiveMind.team.setup.oosh`](hivemind.md) |
| `team` | `sweep` | [`hiveMind.team.sweep`](hivemind.md) |
| `team` | `switch` | [`hiveMind.team.switch`](hivemind.md) |
| `teamSession` |  | [`private.tronMonitor.screen.showsTeam`](tronMonitor.md) |
| `teamSession` | `add` | [`tronMonitor.add`](tronMonitor.md) |
| `teamSession` | `findWindow` | [`private.tronMonitor.findWindow`](tronMonitor.md) |
| `teamSession` | `fit` | [`tronMonitor.fit`](tronMonitor.md) |
| `teamSession` | `push` | [`hiveMind.team.push`](hivemind.md) · [`private.hiveMind.push.preflight`](hivemind.md) · [`private.hiveMind.push.resolveCanonical`](hivemind.md) |
| `teamSession` | `remove` | [`tronMonitor.remove`](tronMonitor.md) |
| `teamSession` | `switch` | [`tronMonitor.switch`](tronMonitor.md) |
| `teams` |  | [`private.hiveMind.handler.team.created.teams`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.teams`](hivemind.md) · [`private.hiveMind.handler.team.restored.teams`](hivemind.md) · [`private.tronMonitor.registry.teams`](tronMonitor.md) · [`private.tronMonitor.tracked.teams`](tronMonitor.md) |
| `teams` | `complete` | [`private.hiveMind.teams.complete`](hivemind.md) |
| `teams` | `ensure` | [`private.hiveMind.teams.ensure.dir`](hivemind.md) |
| `teams` | `migrate` | [`hiveMind.teams.migrate`](hivemind.md) |
| `teams` | `restore` | [`hiveMind.teams.restore`](hivemind.md) |
| `teams` | `save` | [`hiveMind.teams.save`](hivemind.md) |
| `temp` | `get` | [`private.this.temp.dir.get`](this.md) |
| `template` | `install` | [`private.setup.template.install`](setup.md) |
| `template` | `prompt` | [`otmux.prompt`](otmux.md) · [`otmux.send.prompt`](otmux.md) |
| `templatesDir` |  | [`private.osemvec.templatesDir`](osemvec.md) |
| `term` | `get` | [`private.user.login.term.get`](user.md) |
| `terminal` | `test` | [`os.platform.test`](os.md) · [`private.os.platform.test.ci`](os.md) |
| `test` |  | [`private.test.suite.category`](test.suite.md) · [`private.test.suite.session.snapshot`](test.suite.md) · [`private.test.suite.shared.snapshot`](test.suite.md) · [`private.test.suite.ssh.snapshot`](test.suite.md) · [`private.test.suite.verdict`](test.suite.md) · [`test.suite.all`](test.suite.md) · [`test.suite.core`](test.suite.md) · [`test.suite.extended`](test.suite.md) · [`test.suite.gate`](test.suite.md) · [`test.suite.level`](test.suite.md) · [`test.suite.summary`](test.suite.md) |
| `test` | `clear` | [`private.test.suite.results.clear`](test.suite.md) |
| `test` | `close` | [`private.test.suite.results.dir.close`](test.suite.md) |
| `test` | `discover` | [`test.suite.discover`](test.suite.md) |
| `test` | `dispatch` | [`private.check.platform.test.dispatch`](promote.md) |
| `test` | `get` | [`private.test.suite.config.stamp.get`](test.suite.md) · [`private.test.suite.results.file.get`](test.suite.md) · [`private.test.suite.session.files.get`](test.suite.md) · [`private.test.suite.shared.waiver.get`](test.suite.md) · [`private.test.suite.ssh.mode.get`](test.suite.md) · [`private.test.suite.ssh.origin.get`](test.suite.md) · [`private.test.suite.ssh.secrets.changed.get`](test.suite.md) · [`private.test.suite.ssh.stamp.get`](test.suite.md) |
| `test` | `init` | [`test.suite.init`](test.suite.md) |
| `test` | `is` | [`private.test.suite.ssh.secret.is`](test.suite.md) |
| `test` | `isolate` | [`test.suite.config.isolate`](test.suite.md) |
| `test` | `list` | [`private.test.suite.list.names`](test.suite.md) · [`private.test.suite.list.tags`](test.suite.md) · [`test.suite.list`](test.suite.md) |
| `test` | `make` | [`test.suite.fixture.make`](test.suite.md) |
| `test` | `new` | [`oo.test.new`](oo.md) · [`oo.test.platform.new`](oo.md) |
| `test` | `open` | [`private.test.suite.results.dir.open`](test.suite.md) |
| `test` | `report` | [`private.test.suite.shared.report`](test.suite.md) · [`private.test.suite.ssh.report`](test.suite.md) |
| `test` | `reset` | [`private.test.suite.counters.reset`](test.suite.md) |
| `test` | `restore` | [`private.test.suite.session.restore`](test.suite.md) · [`private.test.suite.shared.restore`](test.suite.md) · [`private.test.suite.ssh.restore`](test.suite.md) · [`test.suite.config.restore`](test.suite.md) |
| `test` | `run` | [`private.test.suite.run.filtered`](test.suite.md) · [`test.suite.run`](test.suite.md) |
| `test` | `save` | [`test.suite.save.results`](test.suite.md) |
| `test` | `validate` | [`test.suite.portability.validate`](test.suite.md) |
| `test` | `verify` | [`private.test.suite.shared.verify`](test.suite.md) · [`private.test.suite.ssh.verify`](test.suite.md) |
| `testing` |  | [`oo.dev.to.testing`](oo.md) · [`oo.testing.to.prod`](oo.md) · [`private.oo.dev.to.testing`](oo.md) · [`promote.dev.to.testing`](promote.md) · [`promote.testing`](promote.md) · [`promote.testing.to.prod`](promote.md) |
| `tests` |  | [`mycmd.logging.tests`](mycmd.md) |
| `text` | `enqueue` | [`private.hiveMind.agent.queue.enqueue`](hivemind.md) |
| `text` | `enter` | [`otmux.send.enter`](otmux.md) |
| `text` | `get` | [`private.oo.regex.escape.get`](oo.md) |
| `text` | `inform` | [`private.hiveMind.agent.inform`](hivemind.md) |
| `text` | `remove` | [`line.remove.exact`](line.md) |
| `text` | `send` | [`hiveMind.send`](hivemind.md) · [`otmux.pane.send`](otmux.md) · [`otmux.send.verified`](otmux.md) · [`private.otmux.send.smart`](otmux.md) |
| `text` | `sendEnter` | [`private.otmux.sendEnter`](otmux.md) |
| `text` | `update` | [`osemvec.update`](osemvec.md) |
| `this` |  | [`loop.this`](loop.md) · [`private.this.file.same`](this.md) · [`private.this.oosh.dir.invariant`](this.md) · [`private.this.path.canonical`](this.md) · [`this.absolutePath`](this.md) · [`this.absolutePathName`](this.md) · [`this.caller`](this.md) · [`this.caller.function`](this.md) · [`this.function.partial`](this.md) · [`this.functionExists`](this.md) · [`this.methodNotFound`](this.md) · [`this.scope`](this.md) · [`this.scope.full`](this.md) |
| `this` | `add` | [`this.path.add`](this.md) |
| `this` | `append` | [`private.log.install.append`](this.md) |
| `this` | `backup` | [`private.this.symlink.with.backup`](this.md) |
| `this` | `call` | [`this.call`](this.md) |
| `this` | `check` | [`private.this.tree.tracked.check`](this.md) |
| `this` | `copy` | [`private.this.folder.entries.copy`](this.md) |
| `this` | `create` | [`private.this.group.create`](this.md) |
| `this` | `dedup` | [`private.this.path.dedup`](this.md) |
| `this` | `download` | [`private.this.url.download`](this.md) |
| `this` | `ensure` | [`private.ensure.groupWrite`](this.md) · [`private.ensure.sharedTree`](this.md) · [`private.this.file.line.ensure`](this.md) · [`private.this.folder.ensure`](this.md) · [`private.this.shared.top.ensure`](this.md) |
| `this` | `exists` | [`private.this.group.exists`](this.md) |
| `this` | `get` | [`private.this.as.user.preamble.get`](this.md) · [`private.this.env.export.line.get`](this.md) · [`private.this.group.file.get`](this.md) · [`private.this.group.members.get`](this.md) · [`private.this.group.name.get`](this.md) · [`private.this.host.name.get`](this.md) · [`private.this.path.case.get`](this.md) · [`private.this.path.stat.get`](this.md) · [`private.this.temp.dir.get`](this.md) · [`private.this.user.name.get`](this.md) |
| `this` | `help` | [`this.help`](this.md) · [`this.help.table`](this.md) |
| `this` | `init` | [`this.init`](this.md) |
| `this` | `is` | [`private.this.container.is`](this.md) · [`private.this.device.is.terminal`](this.md) |
| `this` | `isEmpty` | [`this.isEmpty`](this.md) |
| `this` | `isNumber` | [`this.isNumber`](this.md) |
| `this` | `isPaneTarget` | [`this.isPaneTarget`](this.md) |
| `this` | `isPipeSafe` | [`this.isPipeSafe`](this.md) |
| `this` | `isRoleName` | [`this.isRoleName`](this.md) |
| `this` | `isSessionName` | [`this.isSessionName`](this.md) |
| `this` | `isSourced` | [`this.isSourced`](this.md) |
| `this` | `isUuid` | [`this.isUuid`](this.md) |
| `this` | `load` | [`private.this.script.load`](this.md) · [`this.load`](this.md) |
| `this` | `restart` | [`this.restart`](this.md) |
| `this` | `set` | [`private.this.path.owner.set`](this.md) |
| `this` | `share` | [`private.this.folder.share`](this.md) |
| `this` | `sweep` | [`private.this.marker.sweep`](this.md) |
| `this` | `validate` | [`private.this.anchor.validate.one`](this.md) · [`this.anchor.validate`](this.md) · [`this.config.path.validate`](this.md) · [`this.oosh.dir.validate`](this.md) |
| `this` | `write` | [`private.this.file.write`](this.md) |
| `threshold` |  | [`claudeCode.context.alert`](claudeCode.md) · [`scrumMaster.velocity.alert`](scrumMaster.md) |
| `tiled` |  | [`otmux.layout.tiled`](otmux.md) · [`otmux.tiled`](otmux.md) |
| `timemachine` |  | [`osx.timemachine.settings`](osx.md) |
| `timemachine` | `install` | [`osx.timemachine.settings.install`](osx.md) |
| `timemachine` | `list` | [`osx.timemachine.list`](osx.md) |
| `timeout` | `send` | [`otmux.send.verified`](otmux.md) |
| `timeout` | `wait` | [`private.hiveMind.wait.for.claude`](hivemind.md) |
| `title` |  | [`otmux.pane.title`](otmux.md) · [`private.hiveMind.handler.agent.renamed.title`](hivemind.md) · [`private.hiveMind.role.fromTitle`](hivemind.md) |
| `title` | `lock` | [`otmux.pane.lock`](otmux.md) |
| `tmp` | `cleanup` | [`oo.tmp.cleanup.testing`](oo.md) · [`private.oo.tmp.cleanup.testing`](oo.md) |
| `tmux` |  | [`claudeFlow.tmux`](claudeFlow.md) · [`claudeFlow.tmux.agents`](claudeFlow.md) · [`claudeFlow.tmux.layout`](claudeFlow.md) · [`claudeFlow.tmux.lower`](claudeFlow.md) · [`claudeFlow.tmux.main`](claudeFlow.md) · [`claudeFlow.tmux.pane`](claudeFlow.md) · [`claudeFlow.tmux.status`](claudeFlow.md) · [`claudeFlow.tmux.task`](claudeFlow.md) |
| `tmux` | `bind` | [`claudeFlow.tmux.bind`](claudeFlow.md) |
| `tmux` | `focus` | [`claudeFlow.tmux.focus`](claudeFlow.md) |
| `tmux` | `init` | [`claudeFlow.tmux.init`](claudeFlow.md) |
| `tmux` | `kill` | [`claudeFlow.tmux.kill`](claudeFlow.md) · [`claudeFlow.tmux.kill.all`](claudeFlow.md) |
| `tmux` | `list` | [`claudeFlow.tmux.list`](claudeFlow.md) |
| `tmux` | `run` | [`claudeFlow.tmux.run`](claudeFlow.md) |
| `tmux` | `spawn` | [`claudeFlow.tmux.spawn`](claudeFlow.md) |
| `to` |  | [`backup.to`](backup.md) · [`oo.dev.to.testing`](oo.md) · [`oo.testing.to.prod`](oo.md) · [`private.context.role.to.machine`](context.md) · [`private.oo.dev.to.testing`](oo.md) · [`promote.branch.alignment`](promote.md) · [`promote.dev.to.testing`](promote.md) · [`promote.testing.to.prod`](promote.md) |
| `to` | `compare` | [`ogit.branch.compare`](ogit.md) |
| `to` | `copy` | [`private.this.folder.entries.copy`](this.md) |
| `to` | `count` | [`ogit.commit.count`](ogit.md) |
| `to` | `find` | [`line.find`](line.md) |
| `to` | `link` | [`osx.alias.to.link`](osx.md) |
| `toHost` |  | [`ossh.tunnel`](ossh.md) |
| `toHost` | `exec` | [`ossh.exec`](ossh.md) · [`ossh.exec.tty`](ossh.md) |
| `toHost` | `push` | [`ossh.config.push`](ossh.md) · [`ossh.dir.push`](ossh.md) · [`ossh.id.push`](ossh.md) · [`ossh.key.push`](ossh.md) · [`ossh.push.config`](ossh.md) · [`ossh.push.dir`](ossh.md) · [`ossh.push.id`](ossh.md) · [`ossh.push.key`](ossh.md) · [`private.ossh.config.push`](ossh.md) · [`private.ossh.dir.push`](ossh.md) · [`private.ossh.id.push`](ossh.md) · [`private.ossh.key.push`](ossh.md) |
| `toHost` | `stage` | [`private.ossh.identity.stage`](ossh.md) · [`private.ossh.identity.stage.outer.fromRunner`](ossh.md) · [`private.ossh.identity.stage.outer.proxyJump`](ossh.md) |
| `toPane` |  | [`hiveMind.protected.pane.moved`](hivemind.md) |
| `toPath` |  | [`backup.target`](backup.md) · [`backup.to`](backup.md) |
| `toUsername` | `add` | [`user.group.add`](user.md) |
| `token` | `is` | [`private.otmux.is.key`](otmux.md) |
| `tokens` |  | [`private.claudeCode.max.tokens.for.jsonl`](claudeCode.md) |
| `tool` | `exec` | [`claudeFlow.mcp.exec`](claudeFlow.md) |
| `tool` | `toggle` | [`claudeFlow.mcp.toggle`](claudeFlow.md) |
| `tools` |  | [`claudeCode.tools.allowed`](claudeCode.md) · [`claudeCode.tools.disallowed`](claudeCode.md) · [`claudeFlow.mcp.tools`](claudeFlow.md) |
| `top` | `ensure` | [`private.this.shared.top.ensure`](this.md) |
| `top` | `get` | [`ogit.stash.top.get`](ogit.md) |
| `total` | `render` | [`private.hiveMind.audit.render.human`](hivemind.md) · [`private.hiveMind.audit.render.json`](hivemind.md) |
| `tracked` |  | [`private.tronMonitor.tracked.teams`](tronMonitor.md) |
| `tracked` | `check` | [`private.this.tree.tracked.check`](this.md) |
| `tree` |  | [`otmux.tree`](otmux.md) · [`otmux.tree.detailed`](otmux.md) · [`private.oo.shared.tree.from.local`](oo.md) |
| `tree` | `check` | [`private.this.tree.tracked.check`](this.md) |
| `tree` | `ensure` | [`private.oo.shared.tree.ensure`](oo.md) |
| `treeRoot` | `check` | [`private.this.tree.tracked.check`](this.md) |
| `treeRoot` | `sweep` | [`private.this.marker.sweep`](this.md) |
| `treeRoot` | `validate` | [`ogit.caller.validate`](ogit.md) · [`path.validate`](path.md) · [`private.this.anchor.validate.one`](this.md) · [`test.suite.portability.validate`](test.suite.md) · [`this.anchor.validate`](this.md) · [`this.config.path.validate`](this.md) · [`this.oosh.dir.validate`](this.md) |
| `tronMonitor` |  | [`private.hiveMind.handler.team.created.tronMonitor`](hivemind.md) · [`private.hiveMind.handler.team.destroyed.tronMonitor`](hivemind.md) · [`private.hiveMind.handler.team.restored.tronMonitor`](hivemind.md) · [`private.tronMonitor.fullScreenName`](tronMonitor.md) · [`private.tronMonitor.pane`](tronMonitor.md) · [`private.tronMonitor.registry.teams`](tronMonitor.md) · [`private.tronMonitor.screen.showsTeam`](tronMonitor.md) · [`private.tronMonitor.screenSession`](tronMonitor.md) · [`private.tronMonitor.tracked.teams`](tronMonitor.md) |
| `tronMonitor` | `add` | [`tronMonitor.add`](tronMonitor.md) |
| `tronMonitor` | `capture` | [`private.tronMonitor.screen.capture`](tronMonitor.md) |
| `tronMonitor` | `ensure` | [`private.tronMonitor.screen.ensure`](tronMonitor.md) |
| `tronMonitor` | `findWindow` | [`private.tronMonitor.findWindow`](tronMonitor.md) |
| `tronMonitor` | `fit` | [`tronMonitor.fit`](tronMonitor.md) |
| `tronMonitor` | `isAlive` | [`private.tronMonitor.screen.isAlive`](tronMonitor.md) |
| `tronMonitor` | `isValid` | [`private.tronMonitor.pane.isValid`](tronMonitor.md) |
| `tronMonitor` | `list` | [`tronMonitor.list`](tronMonitor.md) |
| `tronMonitor` | `nextWindow` | [`private.tronMonitor.nextWindow`](tronMonitor.md) |
| `tronMonitor` | `prune` | [`tronMonitor.prune`](tronMonitor.md) |
| `tronMonitor` | `remove` | [`tronMonitor.remove`](tronMonitor.md) |
| `tronMonitor` | `reset` | [`tronMonitor.reset`](tronMonitor.md) |
| `tronMonitor` | `setup` | [`otmux.tronMonitor.setup`](otmux.md) · [`tronMonitor.setup`](tronMonitor.md) |
| `tronMonitor` | `switch` | [`tronMonitor.switch`](tronMonitor.md) |
| `tronMonitor` | `sync` | [`tronMonitor.sync`](tronMonitor.md) |
| `tronMonitor` | `verify` | [`tronMonitor.verify`](tronMonitor.md) |
| `try` | `resolve` | [`private.promote.try.resolve.self.branch.conflict`](promote.md) |
| `ts` | `backup` | [`private.this.symlink.with.backup`](this.md) |
| `tsIso` |  | [`private.hiveMind.context.age`](hivemind.md) |
| `tsIso` | `set` | [`private.hiveMind.context.set`](hivemind.md) |
| `ttl` | `classify` | [`private.hiveMind.shell.classify`](hivemind.md) |
| `tunnel` |  | [`ossh.tunnel`](ossh.md) |
| `tupleset` |  | [`hiveMind.protected.live.tupleset`](hivemind.md) · [`private.hiveMind.live.tupleset`](hivemind.md) · [`private.hiveMind.live.tupleset.remote`](hivemind.md) |
| `turns` |  | [`claudeCode.turns.max`](claudeCode.md) |
| `txt` |  | [`log.live.result.txt`](log.md) |
| `type` |  | [`claudeFlow.tmux.layout`](claudeFlow.md) |
| `type` | `spawn` | [`claudeFlow.tmux.spawn`](claudeFlow.md) |
| `type` | `update` | [`osemvec.update`](osemvec.md) |
| `uid` | `create` | [`user.create`](user.md) |
| `umask` | `get` | [`private.ogit.umask.get`](ogit.md) |
| `unit` | `get` | [`private.odocker.workspaces.merge.answer.get`](odocker.md) · [`private.setup.vnc.unit.get`](setup.md) |
| `unknown` |  | [`ossh.service.status.unknown`](ossh.md) |
| `update` | `create` | [`private.check.certificates.update.create.certbot`](ossh.md) · [`private.check.certificates.update.create.structr`](ossh.md) |
| `update` | `heal` | [`private.oo.update.heal.symlinks`](oo.md) |
| `update` | `init` | [`private.certificates.update.state.machine.init`](ossh.md) |
| `update` | `load` | [`private.certificates.update.config.load`](ossh.md) |
| `update` | `read` | [`private.certificates.update.config.read`](ossh.md) |
| `update` | `restore` | [`private.check.certificates.update.restore.workspace`](ossh.md) |
| `update` | `rotate` | [`private.check.certificates.update.rotate.empty`](ossh.md) |
| `update` | `run` | [`private.certificates.update.ssh.run`](ossh.md) |
| `update` | `start` | [`private.check.certificates.update.start.structr`](ossh.md) |
| `update` | `stop` | [`private.check.certificates.update.stop.certbot`](ossh.md) · [`private.check.certificates.update.stop.structr`](ossh.md) |
| `update` | `verify` | [`private.check.certificates.update.verify.https`](ossh.md) |
| `upper` |  | [`private.config.string.upper`](config.md) |
| `upstream` | `set` | [`ogit.branch.upstream.set`](ogit.md) |
| `url` | `clone` | [`ogit.repo.clone`](ogit.md) |
| `url` | `create` | [`ossh.config.create`](ossh.md) · [`ossh.install.create`](ossh.md) · [`webitem.create`](webitem.md) |
| `url` | `download` | [`private.odocker.docker.repo.download`](odocker.md) · [`private.this.url.download`](this.md) |
| `url` | `ensure` | [`private.oo.branch.clone.ensure`](oo.md) · [`private.oo.shared.tree.ensure`](oo.md) |
| `url` | `fetch` | [`private.odocker.workspaces.fetch.url`](odocker.md) |
| `url` | `get` | [`ogit.remote.url.get`](ogit.md) · [`ossh.url.get`](ossh.md) · [`private.odocker.workspaces.source.url.get`](odocker.md) |
| `url` | `install` | [`ossh.create.and.install`](ossh.md) |
| `url` | `newTest` | [`otest.newTest`](otest.md) |
| `url` | `open` | [`otest.browser.open`](otest.md) |
| `url` | `parse` | [`ossh.config.parse.url`](ossh.md) |
| `url` | `pull` | [`ogit.remote.pull`](ogit.md) |
| `url` | `set` | [`ogit.remote.url.set`](ogit.md) |
| `used` |  | [`disk.space.used`](disk.md) |
| `usedK` | `record` | [`hiveMind.context.record`](hivemind.md) |
| `usedK` | `set` | [`private.hiveMind.context.set`](hivemind.md) |
| `user` |  | [`2c.user`](2c.md) · [`c2.user`](c2.md) · [`check.user`](check.md) · [`mycmd.tab.user`](mycmd.md) · [`path.file.user`](path.md) · [`private.as.user`](user.md) · [`private.setup.headless.darwin`](setup.md) · [`private.setup.headless.linux`](setup.md) · [`private.setup.samba.password.darwin`](setup.md) · [`private.setup.samba.password.linux`](setup.md) · [`private.setup.samba.support.darwin`](setup.md) · [`private.setup.samba.support.linux`](setup.md) · [`private.setup.vnc.password.darwin`](setup.md) · [`private.setup.vnc.password.linux`](setup.md) · [`private.user.group.member.pending`](user.md) · [`setup.all`](setup.md) · [`setup.docker`](setup.md) · [`setup.headless`](setup.md) · [`setup.nodejs`](setup.md) · [`setup.npm`](setup.md) · [`setup.nvm`](setup.md) · [`setup.samba.password`](setup.md) · [`setup.samba.support`](setup.md) · [`setup.vnc.password`](setup.md) · [`user.id`](user.md) · [`user.in`](user.md) · [`user.ssh.status`](user.md) |
| `user` | `add` | [`user.group.add`](user.md) |
| `user` | `adopt` | [`private.user.authorized.keys.adopt`](user.md) |
| `user` | `backup` | [`user.ssh.backup`](user.md) · [`user.ssh.backup.status`](user.md) |
| `user` | `check` | [`private.user.check.group`](user.md) · [`user.check.group`](user.md) · [`user.group.check`](user.md) |
| `user` | `create` | [`private.user.create.addSudoer.darwin`](user.md) · [`private.user.create.addSudoer.linux`](user.md) · [`user.create`](user.md) · [`user.ssh.create.folders`](user.md) |
| `user` | `delete` | [`private.user.delete.linux`](user.md) · [`user.delete.linux`](user.md) · [`user.linux.delete`](user.md) |
| `user` | `edit` | [`path.file.user.edit`](path.md) |
| `user` | `ensure` | [`private.oo.user.shared.symlinks.ensure`](oo.md) |
| `user` | `fix` | [`oo.user.fix`](oo.md) |
| `user` | `get` | [`private.config.user.session.file.get`](config.md) · [`private.get.basehome.darwin`](user.md) · [`private.get.basehome.linux`](user.md) · [`private.get.home.darwin`](user.md) · [`private.get.home.linux`](user.md) · [`private.get.info.darwin`](user.md) · [`private.get.info.linux`](user.md) · [`private.get.name.darwin`](user.md) · [`private.get.name.linux`](user.md) · [`private.get.shell.darwin`](user.md) · [`private.get.shell.linux`](user.md) · [`private.ossh.config.user.get`](ossh.md) · [`private.ossh.user.homes.get`](ossh.md) · [`private.setup.user.get`](setup.md) · [`private.this.as.user.preamble.get`](this.md) · [`private.this.user.name.get`](this.md) · [`private.user.authorized.key.get`](user.md) · [`private.user.basehome.system.get`](user.md) · [`private.user.delete.command.get`](user.md) · [`private.user.get.sshDir`](user.md) · [`private.user.login.term.get`](user.md) · [`private.user.path.owner.get`](user.md) · [`user.get`](user.md) · [`user.get.current.identity`](user.md) · [`user.ssh.get.file.name`](user.md) · [`user.ssh.get.key.name`](user.md) |
| `user` | `init` | [`private.user.init`](user.md) · [`user.init`](user.md) |
| `user` | `install` | [`odocker.prereqs.install`](odocker.md) · [`ossh.install`](ossh.md) · [`ossh.install.user.remote`](ossh.md) · [`private.user.bashrc.install`](user.md) · [`private.user.oosh.install.groups.darwin`](user.md) · [`private.user.oosh.install.groups.linux`](user.md) · [`private.user.oosh.install.node`](user.md) · [`private.user.oosh.install.shell.darwin`](user.md) · [`private.user.oosh.install.shell.linux`](user.md) · [`user.oosh.install`](user.md) |
| `user` | `is` | [`private.setup.nvm.is`](setup.md) · [`private.user.group.member.is`](user.md) |
| `user` | `list` | [`user.list`](user.md) · [`user.list.all`](user.md) · [`user.list.groups`](user.md) · [`user.list.other.identities`](user.md) · [`user.ssh.backup.list`](user.md) |
| `user` | `login` | [`user.login`](user.md) |
| `user` | `migrate` | [`private.config.user.session.migrate`](config.md) · [`user.ssh.backup.migrate`](user.md) |
| `user` | `pull` | [`user.ssh.rootkey.pull`](user.md) |
| `user` | `push` | [`user.ssh.rootkey.file.push`](user.md) · [`user.ssh.rootkey.push`](user.md) |
| `user` | `rebuild` | [`private.user.authorized.keys.rebuild`](user.md) |
| `user` | `release` | [`private.check.user.mode.release`](oo.md) |
| `user` | `rename` | [`user.ssh.rename.files`](user.md) |
| `user` | `restore` | [`user.ssh.restore`](user.md) |
| `user` | `revoke` | [`user.ssh.rootkey.file.revoke`](user.md) |
| `user` | `run` | [`private.setup.nvm.run`](setup.md) |
| `user` | `save` | [`path.file.user.save`](path.md) |
| `user` | `set` | [`path.file.user.set`](path.md) · [`private.ossh.config.user.set`](ossh.md) · [`user.password.set`](user.md) · [`user.password.set.darwin`](user.md) · [`user.password.set.linux`](user.md) · [`user.ssh.set.key.name`](user.md) |
| `user` | `update` | [`user.authorized.keys.update`](user.md) · [`user.update.authorized_keys`](user.md) |
| `userHome` | `ensure` | [`private.oo.user.shared.symlinks.ensure`](oo.md) |
| `userName` | `login` | [`user.login`](user.md) |
| `username` |  | [`c2.user`](c2.md) · [`private.as.user`](user.md) |
| `username` | `check` | [`config.init.check`](config.md) |
| `username` | `create` | [`private.user.create.addSudoer.darwin`](user.md) · [`private.user.create.addSudoer.linux`](user.md) · [`user.create`](user.md) |
| `username` | `delete` | [`private.user.delete.linux`](user.md) · [`user.delete.linux`](user.md) · [`user.linux.delete`](user.md) |
| `username` | `fix` | [`oo.user.fix`](oo.md) |
| `username` | `get` | [`private.get.basehome.darwin`](user.md) · [`private.get.basehome.linux`](user.md) · [`private.get.home.darwin`](user.md) · [`private.get.home.linux`](user.md) · [`private.get.info.darwin`](user.md) · [`private.get.info.linux`](user.md) · [`private.get.shell.darwin`](user.md) · [`private.get.shell.linux`](user.md) · [`private.this.as.user.preamble.get`](this.md) · [`user.get`](user.md) |
| `username` | `init` | [`config.init.full`](config.md) · [`config.init.user`](config.md) |
| `username` | `install` | [`private.user.oosh.install.groups.darwin`](user.md) · [`private.user.oosh.install.groups.linux`](user.md) · [`private.user.oosh.install.node`](user.md) · [`private.user.oosh.install.shell.darwin`](user.md) · [`private.user.oosh.install.shell.linux`](user.md) · [`user.oosh.install`](user.md) |
| `username` | `set` | [`user.password.set`](user.md) · [`user.password.set.darwin`](user.md) · [`user.password.set.linux`](user.md) |
| `users` |  | [`private.ossh.users.basehome`](ossh.md) · [`private.setup.samba.users.any`](setup.md) |
| `users` | `get` | [`private.odocker.passwd.users.get`](odocker.md) |
| `users` | `harden` | [`ossh.harden.sshd.allowusers`](ossh.md) |
| `utf8` |  | [`otmux.utf8`](otmux.md) |
| `uuid` |  | [`hiveMind.role.uuid`](hivemind.md) · [`private.hiveMind.snapshot.jsonl.path`](hivemind.md) |
| `uuid` | `set` | [`private.hiveMind.snapshot.set`](hivemind.md) |
| `v` |  | [`claudeCode.v`](claudeCode.md) · [`claudeFlow.v`](claudeFlow.md) · [`debug.v`](debug.md) · [`otmux.layout.even.v`](otmux.md) · [`otmux.layout.main.v`](otmux.md) · [`otmux.v`](otmux.md) |
| `v3` |  | [`claudeFlow.swarm.v3`](claudeFlow.md) |
| `valid` |  | [`private.hiveMind.snapshot.row.valid`](hivemind.md) |
| `validConfigBlock` |  | [`private.ossh.validConfigBlock`](ossh.md) |
| `value` |  | [`line.value`](line.md) · [`otmux.window.size`](otmux.md) |
| `value` | `assign` | [`line.assign`](line.md) |
| `value` | `del` | [`private.hiveMind.env.del`](hivemind.md) |
| `value` | `get` | [`private.this.env.export.line.get`](this.md) |
| `value` | `new` | [`line.parse.param.new`](line.md) |
| `value` | `normalize` | [`private.scrumMaster.parse.normalize.k`](scrumMaster.md) |
| `value` | `parse` | [`line.parse.param`](line.md) |
| `value` | `resize` | [`otmux.window.aggressive.resize`](otmux.md) |
| `value` | `set` | [`config.set`](config.md) · [`ogit.config.set`](ogit.md) · [`ossh.config.set`](ossh.md) · [`otmux.config.set`](otmux.md) · [`otmux.config.set.global`](otmux.md) · [`otmux.config.set.window`](otmux.md) · [`otmux.env.set`](otmux.md) · [`otmux.set`](otmux.md) · [`private.hiveMind.env.set`](hivemind.md) · [`private.ossh.config.field.set`](ossh.md) · [`private.ossh.config.forwardAgent.set`](ossh.md) · [`private.ossh.config.hostName.set`](ossh.md) · [`private.ossh.config.identitiesOnly.set`](ossh.md) · [`private.ossh.config.identityFile.set`](ossh.md) · [`private.ossh.config.port.set`](ossh.md) · [`private.ossh.config.proxyJump.set`](ossh.md) · [`private.ossh.config.user.set`](ossh.md) |
| `value` | `setEnv` | [`private.otmux.setEnv`](otmux.md) |
| `value` | `setGlobal` | [`private.otmux.setGlobal`](otmux.md) |
| `value` | `setWindow` | [`private.otmux.setWindow`](otmux.md) |
| `value1` |  | [`line.each`](line.md) |
| `valueList` |  | [`private.line.each`](line.md) |
| `valueN` |  | [`line.each`](line.md) |
| `values` |  | [`line.values`](line.md) |
| `varName` |  | [`c2.env`](c2.md) · [`c2.variables`](c2.md) |
| `variable` | `export` | [`private.config.variable.export.line`](config.md) |
| `variableName` | `export` | [`private.config.variable.export.line`](config.md) |
| `variableName` | `get` | [`private.this.env.export.line.get`](this.md) |
| `variables` |  | [`2c.variables`](2c.md) · [`c2.variables`](c2.md) · [`mycmd.tab.variables`](mycmd.md) |
| `variables` | `export` | [`private.config.variables.export`](config.md) |
| `variables` | `get` | [`private.config.required.variables.get`](config.md) |
| `variables` | `list` | [`private.config.variables.list`](config.md) |
| `velocity` |  | [`claudeCode.context.velocity`](claudeCode.md) · [`claudeCode.context.velocity.byJsonl`](claudeCode.md) · [`claudeCode.context.velocity.byPane`](claudeCode.md) · [`private.scrumMaster.velocity.target`](scrumMaster.md) · [`scrumMaster.velocity`](scrumMaster.md) · [`scrumMaster.velocity.alert`](scrumMaster.md) · [`scrumMaster.velocity.history`](scrumMaster.md) · [`scrumMaster.velocity.rate`](scrumMaster.md) · [`scrumMaster.velocity.target`](scrumMaster.md) |
| `velocity` | `calculate` | [`private.claudeCode.velocity.calculate`](claudeCode.md) |
| `velocity` | `capture` | [`private.scrumMaster.velocity.capture.sample`](scrumMaster.md) |
| `velocity` | `check` | [`scrumMaster.velocity.check`](scrumMaster.md) |
| `velocity` | `log` | [`private.scrumMaster.velocity.ensure.log`](scrumMaster.md) · [`scrumMaster.velocity.log`](scrumMaster.md) |
| `velocity` | `measure` | [`scrumMaster.velocity.measure`](scrumMaster.md) · [`scrumMaster.velocity.measure.target`](scrumMaster.md) |
| `venv` | `activate` | [`opy.venv.activate`](opy.md) |
| `venv` | `create` | [`opy.venv.create`](opy.md) |
| `venv` | `deactivate` | [`opy.venv.deactivate`](opy.md) |
| `venv` | `list` | [`opy.venv.list`](opy.md) |
| `venv` | `remove` | [`opy.venv.remove`](opy.md) |
| `venvHome` |  | [`private.opy.venvHome`](opy.md) |
| `venvName` |  | [`private.osemvec.venvName`](osemvec.md) |
| `venvPython` |  | [`private.osemvec.venvPython`](osemvec.md) |
| `venvReady` |  | [`private.osemvec.venvReady`](osemvec.md) |
| `verb` |  | [`private.hiveMind.agent.overlay.key`](hivemind.md) |
| `verb` | `dispatch` | [`private.hiveMind.agent.overlay.dispatch`](hivemind.md) · [`private.ossh.dispatch`](ossh.md) · [`private.ossh.dispatch.objects`](ossh.md) |
| `verbose` |  | [`claudeCode.verbose`](claudeCode.md) · [`claudeFlow.verbose`](claudeFlow.md) · [`os.info`](os.md) · [`otmux.verbose`](otmux.md) |
| `verdict` |  | [`private.scrumMaster.subscription.verdict`](scrumMaster.md) · [`private.test.suite.verdict`](test.suite.md) |
| `verify` | `sync` | [`backup.verify.sync`](backup.md) |
| `version` |  | [`claudeCode.version`](claudeCode.md) · [`claudeFlow.version`](claudeFlow.md) · [`config.bash.minimal.version`](config.md) · [`opy.deps`](opy.md) · [`opy.version`](opy.md) · [`otmux.version`](otmux.md) · [`private.opy.python`](opy.md) · [`setup.nodejs`](setup.md) · [`setup.nvm`](setup.md) |
| `version` | `activateLatest` | [`private.opy.activateLatest`](opy.md) |
| `version` | `check` | [`private.hiveMind.snapshot.version.check`](hivemind.md) |
| `version` | `checkout` | [`oo.checkout`](oo.md) |
| `version` | `create` | [`opy.venv.create`](opy.md) |
| `version` | `get` | [`private.oo.checkout.dir.get`](oo.md) |
| `version` | `install` | [`opy.install`](opy.md) |
| `version` | `isInstalled` | [`private.opy.isInstalled`](opy.md) |
| `version` | `list` | [`opy.version.list`](opy.md) |
| `version` | `remove` | [`oo.checkout.remove`](oo.md) · [`opy.remove`](opy.md) |
| `version` | `set` | [`opy.version.set`](opy.md) |
| `version` | `update` | [`opy.update`](opy.md) |
| `vnc` |  | [`private.setup.vnc.password.darwin`](setup.md) · [`private.setup.vnc.password.linux`](setup.md) · [`setup.vnc.password`](setup.md) |
| `vnc` | `get` | [`private.setup.vnc.unit.get`](setup.md) |
| `waiver` | `get` | [`private.test.suite.shared.waiver.get`](test.suite.md) |
| `waiver` | `report` | [`private.test.suite.shared.report`](test.suite.md) |
| `watchdog` |  | [`hiveMind.watchdog`](hivemind.md) · [`hiveMind.watchdog.status`](hivemind.md) · [`hiveMind.watchdog.supervisor`](hivemind.md) |
| `watchdog` | `stop` | [`hiveMind.watchdog.stop`](hivemind.md) |
| `webitem` |  | [`webitem.webloc2json`](webitem.md) · [`webitem.webloc2url`](webitem.md) · [`webitem.webloc2xml`](webitem.md) |
| `webitem` | `create` | [`webitem.create`](webitem.md) |
| `webkit` |  | [`otest.here`](otest.md) |
| `webkit` | `run` | [`otest.run`](otest.md) |
| `webkit` | `updateGolden` | [`otest.updateGolden`](otest.md) |
| `webloc2json` |  | [`webitem.webloc2json`](webitem.md) |
| `webloc2url` |  | [`webitem.webloc2url`](webitem.md) |
| `webloc2xml` |  | [`webitem.webloc2xml`](webitem.md) |
| `weblocFile` |  | [`webitem.webloc2json`](webitem.md) · [`webitem.webloc2url`](webitem.md) · [`webitem.webloc2xml`](webitem.md) |
| `what` |  | [`private.promote.notests.gate`](promote.md) |
| `what` | `skip` | [`private.setup.linux.skip`](setup.md) |
| `which` |  | [`backup.config.which`](backup.md) |
| `width` | `apply` | [`otmux.window.size.floor.apply`](otmux.md) |
| `width` | `lock` | [`otmux.size.lock`](otmux.md) · [`otmux.window.size.lock`](otmux.md) |
| `width` | `set` | [`otmux.pane.size.set`](otmux.md) · [`private.otmux.size.lock.set`](otmux.md) |
| `window` |  | [`otmux.kw`](otmux.md) · [`otmux.sw`](otmux.md) · [`otmux.window.last`](otmux.md) · [`otmux.window.size`](otmux.md) · [`otmux.window.size.status`](otmux.md) |
| `window` | `apply` | [`otmux.window.size.floor.apply`](otmux.md) |
| `window` | `find` | [`otmux.window.find`](otmux.md) |
| `window` | `format` | [`otmux.window.list.format`](otmux.md) |
| `window` | `get` | [`otmux.window.get`](otmux.md) · [`otmux.window.get.target`](otmux.md) · [`otmux.window.layout.get`](otmux.md) |
| `window` | `join` | [`otmux.pane.join`](otmux.md) |
| `window` | `joinPane` | [`private.otmux.joinPane`](otmux.md) |
| `window` | `kill` | [`otmux.window.kill`](otmux.md) |
| `window` | `link` | [`otmux.window.link`](otmux.md) |
| `window` | `list` | [`otmux.window.list`](otmux.md) |
| `window` | `lock` | [`otmux.window.size.lock`](otmux.md) |
| `window` | `move` | [`otmux.pane.move`](otmux.md) · [`otmux.window.move`](otmux.md) |
| `window` | `movePane` | [`private.otmux.movePane`](otmux.md) |
| `window` | `new` | [`otmux.window.new`](otmux.md) |
| `window` | `next` | [`otmux.window.next`](otmux.md) |
| `window` | `prev` | [`otmux.window.prev`](otmux.md) |
| `window` | `rename` | [`otmux.window.rename`](otmux.md) |
| `window` | `resize` | [`otmux.window.aggressive.resize`](otmux.md) |
| `window` | `respawn` | [`otmux.window.respawn`](otmux.md) |
| `window` | `rotate` | [`otmux.window.rotate`](otmux.md) |
| `window` | `select` | [`otmux.window.select`](otmux.md) |
| `window` | `set` | [`otmux.window.layout.set`](otmux.md) |
| `window` | `swap` | [`otmux.window.swap`](otmux.md) |
| `window` | `unlink` | [`otmux.window.unlink`](otmux.md) |
| `window` | `unlock` | [`otmux.window.size.unlock`](otmux.md) |
| `windowMin` |  | [`scrumMaster.velocity.alert`](scrumMaster.md) · [`scrumMaster.velocity.rate`](scrumMaster.md) |
| `windows` |  | [`otmux.windows`](otmux.md) |
| `with` | `backup` | [`private.this.symlink.with.backup`](this.md) |
| `within` |  | [`replace.within`](replace.md) |
| `word` |  | [`replace.word`](replace.md) |
| `word` | `apply` | [`private.promote.argument.apply`](promote.md) |
| `word` | `filter` | [`line.filter`](line.md) |
| `word` | `replace` | [`line.replace`](line.md) · [`line.replace.sedquoted`](line.md) |
| `word` | `split` | [`line.split.quoted`](line.md) |
| `workdir` | `create` | [`hiveMind.pane.create`](hivemind.md) |
| `workdir` | `init` | [`hiveMind.init`](hivemind.md) |
| `workdir` | `spawn` | [`hiveMind.agent.spawn`](hivemind.md) · [`hiveMind.spawn`](hivemind.md) |
| `workers` |  | [`hiveMind.workers`](hivemind.md) · [`private.hiveMind.workers.legacy`](hivemind.md) |
| `workspace` |  | [`private.os.platform.image.from.workspace`](os.md) |
| `workspace` | `build` | [`odocker.build`](odocker.md) |
| `workspace` | `get` | [`odocker.workspace.get`](odocker.md) |
| `workspace` | `init` | [`odocker.workspace.init`](odocker.md) |
| `workspace` | `list` | [`odocker.workspace.list`](odocker.md) · [`private.odocker.workspace.list`](odocker.md) |
| `workspace` | `rebuild` | [`odocker.rebuild`](odocker.md) |
| `workspace` | `seed` | [`odocker.workspace.seed`](odocker.md) |
| `workspace` | `set` | [`odocker.workspace.set`](odocker.md) |
| `workspaces` |  | [`private.odocker.workspaces.entry.same`](odocker.md) · [`private.odocker.workspaces.mine`](odocker.md) |
| `workspaces` | `fetch` | [`private.odocker.workspaces.fetch.ssh`](odocker.md) · [`private.odocker.workspaces.fetch.url`](odocker.md) |
| `workspaces` | `get` | [`private.odocker.workspaces.default.get`](odocker.md) · [`private.odocker.workspaces.merge.answer.get`](odocker.md) · [`private.odocker.workspaces.source.host.get`](odocker.md) · [`private.odocker.workspaces.source.path.get`](odocker.md) · [`private.odocker.workspaces.source.url.get`](odocker.md) |
| `workspaces` | `install` | [`private.odocker.workspaces.install`](odocker.md) |
| `workspaces` | `merge` | [`private.odocker.workspaces.merge`](odocker.md) |
| `worktree` | `add` | [`ogit.worktree.add`](ogit.md) |
| `worktree` | `delete` | [`ogit.worktree.delete`](ogit.md) |
| `worktree` | `find` | [`ogit.worktree.find`](ogit.md) |
| `worktree` | `get` | [`private.ogit.worktree.paths.get`](ogit.md) |
| `worktree` | `list` | [`ogit.worktree.list`](ogit.md) |
| `worktree` | `prune` | [`ogit.worktree.prune`](ogit.md) |
| `worktree` | `remove` | [`ogit.worktree.remove`](ogit.md) |
| `worktree` | `restore` | [`ogit.worktree.restore`](ogit.md) |
| `worktree_base` | `setup` | [`oo.mode.setup`](oo.md) |
| `writable` | `is` | [`private.oo.path.writable.is`](oo.md) |
| `yolo` |  | [`claudeCode.yolo`](claudeCode.md) |
| `z` |  | [`otmux.z`](otmux.md) |
