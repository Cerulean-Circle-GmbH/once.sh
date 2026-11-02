# What `dev` never had — and where `dev` is incomplete

Compared with `origin/test/mcdonges.latest` at `760552c7` (`dev` = `7ab831d9`), 2026-11-02.
Companion to `docs/branch-diff-mcdonges-vs-dev.md`, `docs/method-differences-dev-vs-mcdonges.md`
and `docs/ossh-differences-dev-vs-mcdonges.md`.

Method: git-level comparison of the two trees (function inventories per script, diff of the
shared files, `git log` on each side for provenance) plus a call-site scan on `dev`. Every item
below is either verified absent from `dev`'s tree or annotated with the `dev` name that covers it.

## 1. Tools that are not on `dev` at all

Zero commits on `dev`'s history for these paths — they were added on the test line only:

| Tool | Methods | What it does |
|---|---:|---|
| `osemvec` | 48 | semvec-guarded `claudeCode` provisioner: `osemvec install/new/register/guard/index/serve/status` |
| `tronMonitor` | 30 | team-session monitor for tmux (`add/remove/list/fit/prune/reset/setup/sync`) |
| `opy` | 36 | pyenv-backed Python version + venv manager (`opy install/version/venv.*`) |

`claudeFlow` (139 methods) belongs here too in spirit — it is in section 2 because `dev` did
ship it once and deleted it.

Consequence on `dev`: `hiveMind` still registers three TRON hooks
(`private.hiveMind.handler.team.created|destroyed|restored.tronMonitor`, `hiveMind:676/704/766`)
and `private.hiveMind.monitor.switch` (`hiveMind:1212`), but every one of them starts with
`command -v tronMonitor >/dev/null 2>&1 || return 0`, so on `dev` they are **silent no-ops** —
the monitor feature is advertised in the docs and dead in the code.

`dev`'s own docs still describe them: `docs/methods-index.md` lists `claudeFlow` (127 methods),
`osemvec` (34), `opy` (26) and `tronMonitor` (22) — its own counts — as if they shipped.

## 2. Tools `dev` had and deleted on 2026-10-20

| Tool | Methods on mcdonges | Deleted by | Note |
|---|---:|---|---|
| `claudeFlow` | 139 | `36e1305d` *cleanup md* | removed together with `CLAUDE-Flow.md`, `demo`, `academyScript`, `tt`, `old/` |
| `myId` | 5 | `57a9dff6` *chore: remove myId* | **the bug it was deleted for is fixed on mcdonges** |
| `academyScript` | 4 | `36e1305d` | |
| `myScript` | 2 | `7cccf392` *cleanup* | |
| `tt` | 2 | `36e1305d` | scratch scaffold |
| `demo` | 2 | `36e1305d` | scratch scaffold |

The `myId` case is the clearest "dev chose removal, mcdonges chose the fix":

- `myId` creates a GitHub deploy key through `ossh config.create`.
- On `dev`, `config.create` only writes the Host block to `config`'s "last" file; nothing appends
  it to `~/.ssh/config`, so the deploy key never worked (`57a9dff6` says it broke on 2026-03-16).
- On `mcdonges`, `c3a905bc` (2026-08-29) added `private.ossh.config.deploy.write` so
  `config.create` appends the block, and `myId` still works:
  `ossh id.create` → `ossh config.create` → `ossh id.public.get`.

## 3. Capabilities in shared scripts that `dev` never had

Verified absent from `dev` (no equivalent under another name):

| Area | Methods on mcdonges | What it buys |
|---|---|---|
| Python-free JSONL reader | `claudeCode.jsonl.usage` (`last/max/lag/first/firstlast/all`) | one awk pass over a 600 MB session; `hiveMind`/`scrumMaster` call it instead of `python3` |
| Live pane identity | `private.hiveMind.resolve.liveMap`, `.guard`, `.heal`, `private.hiveMind.isUuid`, `.isRoleName`, `.isPipeSafe`, `.isSshHost`, `private.otmux.pane.role.parse`, `private.scrumMaster.swipe.role.parse`, `.role.display`, `.classify.active`, `private.claudeCode.isUuid`, `.isRoleName` | role/name resolution from the live pane title (`role@host`) instead of the stale registry; ACTIVE survives a narrow pane |
| Python-free swipe/creds | `private.scrumMaster.creds.expired` | token expiry in bash+awk; the old python check is gone |
| Observer failures | `private.otmux.observer.notify` | `session.renamed`/`panes.shifted`/`panes.swapped` warn on **stderr** instead of corrupting `-P` output |
| Hostname | `os.hostname.get/.set/.info` + 6 `private.os.hostname.*` | read/set/report the computer name (Linux + Darwin) |
| Headless control | `setup.headless.enable`, `setup.status.headless` | `dev` only has `setup.headless` (install); no on/off/status |
| PATH inspection | `path.status`, `path.sync`, `path.file.user.set`, `private.pathadd`, `private.pathrm`, `private.update.config` | `dev` redesigned `path` around `save/load/edit`; `path.status` is still documented in `docs/path.md` and `docs/oo.md` but exists nowhere |
| ossh config wiring | `private.ossh.config.deploy.write` | `config.create` appends the Host block to `~/.ssh/config` |
| ossh pull validation | `private.ossh.hostKnown`, `private.ossh.validConfigBlock` | validates a pulled Host block before writing (dev has an inline variant) |
| Capability guard | `private.this.oosh.dir.invariant` | re-pins `OOSH_DIR=$HOME/oosh` after every config source when `~/oosh` is a symlink |
| Completion caches | `config._oo_commands`, `init/once._once_commands` | cached command list for the completion engine |
| Mode switching | `oo.mode.sync`, `private.oo.mode.resolve.branch`, `private.oo.sed.first` | `dev` has `oo.method.new` + `private.oo.mode.env.file.write` instead |
| Legacy key API | `user.ssh.status`, `user.ssh.rename.files` | `dev`'s usage text still lists both (`user:1752,1755`) although they are gone |

Also present only on `mcdonges`, but **unused there too** (so not a real gap, listed for
completeness): the `ossh get`/`ossh set` dispatcher (`private.ossh.dispatch.objects`, 8 methods)
and `ossh.scp`. No caller anywhere in the tree, on either branch.

## 4. Same thing under another name — not a gap

Of the 181 methods that exist only on `mcdonges` in shared scripts:

- **45** are the same code under another name (`sim ≥ 0.85`),
- **76** are the same concept rewritten (`0.5 ≤ sim < 0.85`),
- **60** have no near match — section 3 above is the subset that is a real capability.

Typical pairs (full tables in `docs/method-differences-dev-vs-mcdonges.md` and
`docs/ossh-differences-dev-vs-mcdonges.md`):

| mcdonges | dev |
|---|---|
| `backup.list.same` | `private.backup.file.list.same` |
| `disk.calc.getGB` | `disk.calc.bytes.to.gb` |
| `line.function.find` | `line.find.function` |
| `c2.format.functions` | `private.c2.format.functions` |
| `odocker.build.completion.workspace` | `odocker.rebuild.completion.workspace` |
| `private.odocker.ensure.socket.access` | `private.odocker.socket.access.ensure` |
| `debug.step` under its old name `step` | `debug.step` |
| `ossh.authorized_keys.update` | `ossh.authorized.keys.update` (dev delegates to `user authorized.keys.update`) |
| `user.update.authorized_keys` | `ossh.authorized.keys.update` |
| `user.ssh.rootkey.*` | `ossh.key.push` / `ossh.key.revoke` / `private.ossh.remote.public.key.put` |
| `backup.source`, `backup.target` | `backup.from`, `backup.to` (mcdonges just adds aliases) |

## 5. Tests `dev` does not have

29 test files exist only on `mcdonges` (plus their fixtures under `test/test.data/sweep.detect/`):

```
test.claudeCode-validators   test.composer-state          test.context-occupancy
test.creds-expiry            test.events                  test.hiveMind-validators
test.jsonl-lag               test.lifecycle               test.myId
test.no-python               test.opy                     test.osemvec
test.pulse-removed           test.send-composer-guard     test.send-deliver-rc
test.send-submit-otr1        test.session-discover-all    test.session-id-fresh
test.session-resolve-drift   test.state.correctness       test.static-defined-functions
test.swipe-active-narrow     test.swipe-jsonl-lag         test.swipe-role-live
test.test_temp               test.test_temp_script        test.tronMonitor
test.usage-dispatch          test.zoom-target
```

`test.no-python` is the important one: it is the burn-down gate that forbids `python3` in
tracked scripts (N0 scanner self-check, N1 zero calls, N2 exemptions real, N3 interpreter under
`OPY_VENVS`). `dev` has no such gate.

The no-python migration is **ahead on mcdonges but not finished there either** (lines containing
`python3` outside comments):

| Script | dev | mcdonges |
|---|---:|---:|
| `claudeCode` | 11 | 9 |
| `hiveMind` | 6 | 2 |
| `scrumMaster` | 15 | 9 |
| `ossh` | 1 | 0 |
| **total** | **33** | **20** |

## 6. Where `dev` itself is incomplete or inconsistent

1. **TRON monitor is dead code on `dev`** — three event handlers and `monitor.switch` exist,
   guard on a `tronMonitor` command that is not shipped (section 1).
2. **Docs promise things the tree does not have**:
   - `docs/methods-index.md` rows for `claudeFlow`, `osemvec`, `opy`, `tronMonitor`;
   - `docs/path.md:43` and `docs/oo.md:386` use `path.status`, which is defined nowhere on `dev`;
   - `user`'s usage text advertises `ssh.status`, `ssh.rename.files`, `ssh.get.key.name`,
     `ssh.get.file.name`, none of which `dev` defines (`user:1752-1758`).
3. **`myId` was removed rather than repaired** — the underlying `ossh config.create` gap it
   names was fixed on `mcdonges` (`c3a905bc`), not on `dev`.
4. **Stale tests for deleted scripts** — `test/test.academyScript`, `test/test.myScript`,
   `test/test.tt` still call `academyScript.start`, `myScript.start`, `tt.start`. They carry
   `TEST_CATEGORY=legacy` so `core`/`extended` do not run them, but they cannot pass anywhere.
5. **No no-python gate** (section 5), so the 33 remaining `python3` call lines on `dev` have
   nothing stopping them from growing.

## 7. What is *not* a gap (checked, so this list stays trustworthy)

- `ossh get/set` and `ossh.scp`: unused on `mcdonges` as well.
- `config.folder.create` / `config.path.create`: deprecated on `mcdonges`; `dev`'s
  `test/test.config:2650` asserts they are gone on purpose.
- `user.ssh.rootkey.*`, `user.update.authorized_keys`, `ossh.authorized_keys.update`: moved or
  de-duplicated on `dev` (`ossh.key.*`, `ossh.authorized.keys.update`, `user authorized.keys.update`).
- `step`: renamed `debug.step` on `dev`.
- `ossh.harden`, `ossh.config.shared.*`, `ossh.folder.fix`, `ossh.cmd/prereqs`, `ossh.key.revoke`,
  `ossh.exec.tty`, `ogit`, `promote`, `agentRoom`, `osshLayout`, `platform`, `Install oosh.command`:
  these are the reverse direction — `dev`-only, not part of this question.

## 8. Caveats

- "Never had" is based on `git log -- <path>` returning no commit on `origin/dev`; the three tools
  in section 1 have zero commits there.- Method presence is parsed from top-level `name()` / `function name` definitions; a capability
  implemented inline in `start()` would not be counted as a method.
- The similarity buckets come from `difflib` on comment-stripped blocks; a rename that was also
  rewritten can fall into "no near match", which is why section 3 lists the verified subset rather
  than all 60 unmatched names.
