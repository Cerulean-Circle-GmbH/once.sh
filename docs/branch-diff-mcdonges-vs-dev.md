# Branch difference report — `origin/dev` vs `origin/test/mcdonges.latest`

Generated on 2026-10-30 from the local clone (fetch of both branches ran first).

Everything below compares the two **trees**, not the commit lists: 
`git diff origin/dev origin/test/mcdonges.latest`.

Sign convention for line counts: `+` = lines that exist only in **mcdonges**, 
`-` = lines that exist only in **dev**.

## 1. Snapshot

| | `origin/dev` | `origin/test/mcdonges.latest` |
|---|---|---|
| Tip | `7ab831d9` | `760552c7` |
| Tip date | 2026-10-29 05:19 UTC | 2026-10-28 16:09 CET |
| Tip subject | fix(product,tests): close the merge's red gates — core and extended green | test: creds-expiry python-free — E2 oracle = STATIC golden column ... |
| Commits since merge base | 1 572 | 563 |
| Files changed since merge base | 286 | 123 |
| Lines added / removed since merge base | +108 983 / −20 745 | +29 658 / −3 877 |

Merge base: `1604e3ed` (2026-03-10) — *Improve teams.migrate: JSONL transfer, --fork mode, model compat check*.
The two branches have not been merged since March 2026, so the merge base is not a useful guide to intent;
compare the tips instead.

## 2. Divergence at a glance

| Metric | Value |
|---|---|
| Commits only on `dev` | 1 572 |
| Commits only on `mcdonges.latest` | 563 |
| Files that differ | 344 |
| Files only in `mcdonges.latest` | 104 |
| Files only in `dev` | 129 |
| Files modified on both sides | 102 |
| Renames | 9 |
| Lines added in `mcdonges` side of the diff | +32 736 |
| Lines removed from `dev` side of the diff | −95 193 |
| Binary files | 1 |

**Key number:** only **57 paths** were edited by *both* branches since the merge base.
220 of the differing files were changed only on `dev`, 66 only on `mcdonges`.
The rest is one-sided drift: `mcdonges` is a deployed-look test branch sitting on a March-era tree plus a
focused slice of work, while `dev` has reworked most of the repository.

## 3. What each branch is doing

### `origin/test/mcdonges.latest` (563 commits)

A *deployed-state / verification* branch. Its own work is concentrated:

- **no-python migration** — removes `python3` from `claudeCode`, `hiveMind` and `scrumMaster`;
  adds one shared awk JSONL usage reader (`claudeCode jsonl.usage`) and the `test.no-python` burn-down gate.
- **live pane identity** — rules 1–4: role/prefix/resolve come from the live tmux pane title (`role@host`)
  before the (stale) registry; ACTIVE detection survives a narrow pane.
- **pulse → swipe** — deletes `scrumMaster.pulse` (embedded Python) in favour of bash `swipe`,
  full `role@host` display names; new `test.pulse-removed`, `test.swipe-*` suites.
- **otmux observer failures** — surfaced as warnings on **stderr** instead of stdout (so `-P` data stays clean).
- **new tools** — `tronMonitor`, `claudeFlow`, `opy`, `osemvec`, `otest`, ~30 new `test/test.*` files
  including golden fixtures under `test/test.data/sweep.detect/`.
- **`restore/`** — verbatim copies of the deployed `claudeCode`, `hiveMind`, `ossh`, `otmux`, `scrumMaster`, `user`.
- **cleanup debt** — `agentRoom` deleted; scratch scripts `fix`, `tt`, `demo`, `myScript.new`, `myScript` and the `old/` folder are still present.

### `origin/dev` (1 572 commits)

An *architecture* branch — the tree has been reworked far more widely:

- **no cross-sourcing** — scripts no longer `source` each other (`config` loads only `this`, `oo`/`user`/`odocker`/`ossh`
  call each other as commands, `ogit`/`promote`/`replace` sourced once in `start()`).
- **docs explosion** — `docs/object-verb-index.md` (3 374 lines), method matrices for all 47 scripts, plans, research notes.
- **product behaviour fixes** — `oo method.new` (all-or-nothing, better messages), `odocker` completions,
  `otmux current` target, `this.isEmpty`.
- **swipe exists here too, but differently** — `dev` has `scrumMaster swipe` as a pure-bash *drop-in* while
  keeping `scrumMaster.pulse` as the deprecated parity oracle; its `swipe.ctx` still shells out to `python3`
  and its role lookup is registry-first (title last word). `mcdonges` deletes pulse entirely and makes both
  `swipe` and the role/prefix/resolve paths python-free and pane-title-first.
- **removals / relocations** — `promote`, `ogit`, `osshLayout`, `platform` split out, `Install oosh.command`,
  `.github/workflows/macos-test.yml`, many `test/test.platform.*`, `templates/setup/*` are gone from `mcdonges`' tree
  because they were added on `dev`.
- **template renames** to snake_case: `newScript`→`new_script`, `newMethod`→`new_method`, `ooShim`→`oo-shim`, etc.

## 4. Files only in `origin/test/mcdonges.latest`

104 files. These would be **added** by merging mcdonges into dev.

| Area | Files |
|---|---|
| `test` | 63 — `test/test.claudeCode-validators`, `test/test.composer-state`, `test/test.context-occupancy`, `test/test.creds-expiry`, `test/test.data/.backup.env`, `test/test.data/sweep.detect/README.md` … (+57) |
| `old` | 19 — `old/call`, `old/clean`, `old/config`, `old/currentUser`, `old/debug`, `old/fs` … (+13) |
| `(root)` | 11 — `CLAUDE-Flow.md`, `academyScript`, `claudeFlow`, `demo`, `fix`, `myId` … (+5) |
| `restore` | 6 — `restore/claudeCode`, `restore/hiveMind`, `restore/ossh`, `restore/otmux`, `restore/scrumMaster`, `restore/user` |
| `templates` | 3 — `templates/code/new_method_test`, `templates/code/new_script`, `templates/user/oo-shim` |
| `docs` | 1 — `docs/hivemind.forks.md` |
| `ng` | 1 — `ng/test.txt` |

<details><summary>Full list</summary>

**`test/`** (63)

- `test/test.claudeCode-validators`
- `test/test.composer-state`
- `test/test.context-occupancy`
- `test/test.creds-expiry`
- `test/test.data/.backup.env`
- `test/test.data/sweep.detect/README.md`
- `test/test.data/sweep.detect/accept-edits.txt`
- `test/test.data/sweep.detect/active.txt`
- `test/test.data/sweep.detect/api-error.txt`
- `test/test.data/sweep.detect/autocomplete.txt`
- `test/test.data/sweep.detect/context-warning.txt`
- `test/test.data/sweep.detect/crash.txt`
- `test/test.data/sweep.detect/fp-accept-edits-scrollback.txt`
- `test/test.data/sweep.detect/fp-c-block-comment.txt`
- `test/test.data/sweep.detect/fp-html-comment.txt`
- `test/test.data/sweep.detect/fp-js-slashslash-comment.txt`
- `test/test.data/sweep.detect/fp-menu-text-not-live.txt`
- `test/test.data/sweep.detect/fp-python-docstring.txt`
- `test/test.data/sweep.detect/fp-sql-dashdash-comment.txt`
- `test/test.data/sweep.detect/idle.txt`
- `test/test.data/sweep.detect/just-compacted.txt`
- `test/test.data/sweep.detect/mcp-error.txt`
- `test/test.data/sweep.detect/overlay.txt`
- `test/test.data/sweep.detect/panel.txt`
- `test/test.data/sweep.detect/permission-edit-variant.txt`
- `test/test.data/sweep.detect/permission-false-positive-prose.txt`
- `test/test.data/sweep.detect/permission-proceed-variant.txt`
- `test/test.data/sweep.detect/permission.txt`
- `test/test.data/sweep.detect/queued.txt`
- `test/test.data/sweep.detect/rate-limit-false-positive-source.txt`
- `test/test.data/sweep.detect/rate-limit-overloaded-variant.txt`
- `test/test.data/sweep.detect/rate-limit.txt`
- `test/test.data/sweep.detect/shell-escaped.txt`
- `test/test.data/sweep.detect/subscription-limit-billing-variant.txt`
- `test/test.data/sweep.detect/subscription-limit-false-positive-source.txt`
- `test/test.data/sweep.detect/subscription-limit.txt`
- `test/test.data/sweep.detect/tool-confirm.txt`
- `test/test.data/sweep.detect/unknown.txt`
- `test/test.events`
- `test/test.hiveMind-validators`
- `test/test.jsonl-lag`
- `test/test.lifecycle`
- `test/test.myId`
- `test/test.no-python`
- `test/test.opy`
- `test/test.osemvec`
- `test/test.pulse-removed`
- `test/test.send-composer-guard`
- `test/test.send-deliver-rc`
- `test/test.send-submit-otr1`
- `test/test.session-discover-all`
- `test/test.session-id-fresh`
- `test/test.session-resolve-drift`
- `test/test.state.correctness`
- `test/test.static-defined-functions`
- `test/test.swipe-active-narrow`
- `test/test.swipe-jsonl-lag`
- `test/test.swipe-role-live`
- `test/test.test_temp`
- `test/test.test_temp_script`
- `test/test.tronMonitor`
- `test/test.usage-dispatch`
- `test/test.zoom-target`

**`old/`** (19)

- `old/call`
- `old/clean`
- `old/config`
- `old/currentUser`
- `old/debug`
- `old/fs`
- `old/fsys/symbolicLink`
- `old/init`
- `old/log`
- `old/t1`
- `old/t2`
- `old/t3`
- `old/t4`
- `old/t5`
- `old/t6`
- `old/t7`
- `old/update.from.once`
- `old/update.to.once`
- `old/zip.to.once`

**`(root)/`** (11)

- `CLAUDE-Flow.md`
- `academyScript`
- `claudeFlow`
- `demo`
- `fix`
- `myId`
- `myScript.new`
- `opy`
- `osemvec`
- `tronMonitor`
- `tt`

**`restore/`** (6)

- `restore/claudeCode`
- `restore/hiveMind`
- `restore/ossh`
- `restore/otmux`
- `restore/scrumMaster`
- `restore/user`

**`templates/`** (3)

- `templates/code/new_method_test`
- `templates/code/new_script`
- `templates/user/oo-shim`

**`docs/`** (1)

- `docs/hivemind.forks.md`

**`ng/`** (1)

- `ng/test.txt`

</details>

## 5. Files only in `origin/dev`

129 files. These would be **deleted** by merging mcdonges into dev.

| Area | Files |
|---|---|
| `docs` | 89 — `docs/2c.md`, `docs/academyScript.md`, `docs/agentRoom.md`, `docs/backup.md`, `docs/branching.md`, `docs/c2.md` … (+83) |
| `test` | 20 — `test/test.completion.audit`, `test/test.ogit`, `test/test.osshLayout`, `test/test.otest`, `test/test.platform`, `test/test.platform.odocker.workspaces.invariant` … (+14) |
| `(root)` | 6 — `Install oosh.command`, `agentRoom`, `ogit`, `osshLayout`, `platform`, `promote` |
| `templates` | 6 — `templates/code/newMethodTest`, `templates/code/newPlatformInvariantTest`, `templates/setup/avahi.smb.service`, `templates/setup/samba.homes.conf`, `templates/user/ooShim`, `templates/user/thisLauncher` |
| `.claude` | 3 — `.claude/agents/agent-teacher/SKILL.md`, `.claude/agents/oosh-expert/SKILL.md`, `.claude/agents/scrum-master/SKILL.md` |
| `.cursor` | 3 — `.cursor/skills/agent-teacher`, `.cursor/skills/oosh-expert`, `.cursor/skills/scrum-master` |
| `.github` | 1 — `.github/workflows/macos-test.yml` |
| `defaults` | 1 — `defaults/platforms.env` |

<details><summary>Full list</summary>

**`docs/`** (89)

- `docs/2c.md`
- `docs/academyScript.md`
- `docs/agentRoom.md`
- `docs/backup.md`
- `docs/branching.md`
- `docs/c2.md`
- `docs/certificates.md`
- `docs/check.md`
- `docs/claudeCode.md`
- `docs/claudeFlow.md`
- `docs/context.md`
- `docs/disk.md`
- `docs/handoffs/2026-05-27-handoff-marcel-claudeCode-python.md`
- `docs/index.md`
- `docs/install-bootstrap.md`
- `docs/line.md`
- `docs/loop.md`
- `docs/map.md`
- `docs/methods-index.md`
- `docs/migration/env-files.md`
- `docs/myId.md`
- `docs/mycmd.md`
- `docs/object-verb-index.md`
- `docs/odocker.md`
- `docs/ogit.md`
- `docs/opy.md`
- `docs/os.md`
- `docs/osemvec.md`
- `docs/ossh.md`
- `docs/osshLayout.md`
- `docs/osx.md`
- `docs/otest.md`
- `docs/otmux.md`
- `docs/parameter.md`
- `docs/parameterTestScript.md`
- `docs/path.md`
- `docs/plans/2026-03-05-web4pycomponent-design.md`
- `docs/plans/2026-03-05-web4pycomponent-implementation.md`
- `docs/plans/2026-09-10-oosh-boot-tickets.md`
- `docs/plans/2026-09-14-fixed-system-boot-path.md`
- `docs/plans/2026-09-14-method-tooling-repair.md`
- `docs/plans/2026-09-14-tests-that-cannot-fail.md`
- `docs/plans/2026-09-15-board-backlog.md`
- `docs/plans/auto-staging-pipeline.md`
- `docs/platform.md`
- `docs/promote.md`
- `docs/puml/Bootstrap Sequence.html`
- `docs/puml/bootstrap.sequence/2026-09-22-v2-review.md`
- `docs/puml/bootstrap.sequence/Bootstrap Sequence v2.drawio`
- `docs/puml/bootstrap.sequence/bootstrap.sequence.drawio`
- `docs/puml/ogit.tree/ogit.tree.drawio`
- `docs/python.md`
- `docs/repair-toolkit.md`
- `docs/replace.md`
- `docs/reports/2026-04-13-almalinux-spreadsheet-design.md`
- `docs/reports/2026-04-13-almalinux-work-report.md`
- `docs/reports/2026-04-13-almalinux-work-report.xlsx`
- `docs/reports/generate_almalinux_report.py`
- `docs/research/2026-09-16-item6-ssh-backup-naming.md`
- `docs/research/2026-09-16-item7-oo-mode-setup.md`
- `docs/research/2026-09-16-t7-config-branch-variables.md`
- `docs/research/2026-09-16-t8-path-ownership.md`
- `docs/research/2026-09-17-config-save-bash32.md`
- `docs/research/2026-09-17-shared-tier-leak-macos.md`
- `docs/research/2026-09-22-worktrees-vs-version-convention.md`
- `docs/research/plan-user-init-fix.md`
- `docs/research/review-2026-05-07-philosophy-conformance.md`
- `docs/research/review-2026-09-09-boot-loader-pure-env-files.md`
- `docs/research/review-2026-10-28-repo-audit.md`
- `docs/research/review-2026-10-28-test-suite-audit.md`
- `docs/research/state-machine-fixup-audit-F8.md`
- `docs/research/state-machine-fixup-audit.md`
- `docs/scrumMaster.md`
- `docs/setup.md`
- `docs/share.md`
- `docs/snet.md`
- `docs/status.md`
- `docs/superpowers/plans/2026-09-14-clean-environment-guarantee.md`
- `docs/superpowers/plans/2026-09-23-ogit-clones-per-branch.md`
- `docs/superpowers/specs/2026-09-14-clean-environment-guarantee-design.md`
- `docs/superpowers/specs/2026-09-14-oosh-recovery-from-bare-shell-design.md`
- `docs/superpowers/specs/2026-09-23-ogit-clones-per-branch-design.md`
- `docs/supported-platforms.md`
- `docs/test.suite.md`
- `docs/this.md`
- `docs/tronMonitor.md`
- `docs/user.md`
- `docs/verb-audit.md`
- `docs/webitem.md`

**`test/`** (20)

- `test/test.completion.audit`
- `test/test.ogit`
- `test/test.osshLayout`
- `test/test.otest`
- `test/test.platform`
- `test/test.platform.odocker.workspaces.invariant`
- `test/test.platform.shared.boot.invariant`
- `test/test.platform.shared.config.env.invariant`
- `test/test.platform.shared.config.invariant`
- `test/test.platform.shared.configLayout.invariant`
- `test/test.platform.shared.idempotence.invariant`
- `test/test.platform.shared.layout.invariant`
- `test/test.platform.shared.oosh.invariant`
- `test/test.platform.ssh.config.woda.portable`
- `test/test.platform.ssh.layout.invariant`
- `test/test.promote`
- `test/test.replace`
- `test/test.setup`
- `test/test.ssh.config.invariant`
- `test/test.ssh.config.woda`

**`(root)/`** (6)

- `Install oosh.command`
- `agentRoom`
- `ogit`
- `osshLayout`
- `platform`
- `promote`

**`templates/`** (6)

- `templates/code/newMethodTest`
- `templates/code/newPlatformInvariantTest`
- `templates/setup/avahi.smb.service`
- `templates/setup/samba.homes.conf`
- `templates/user/ooShim`
- `templates/user/thisLauncher`

**`.claude/`** (3)

- `.claude/agents/agent-teacher/SKILL.md`
- `.claude/agents/oosh-expert/SKILL.md`
- `.claude/agents/scrum-master/SKILL.md`

**`.cursor/`** (3)

- `.cursor/skills/agent-teacher`
- `.cursor/skills/oosh-expert`
- `.cursor/skills/scrum-master`

**`.github/`** (1)

- `.github/workflows/macos-test.yml`

**`defaults/`** (1)

- `defaults/platforms.env`

</details>

## 6. Renames

Git's rename detection (`-M`) pairs these paths; similarity 100% means only the path changed.

| Similarity | From (dev) | To (mcdonges) |
|---|---|---|
| 81% | `docs/puml/bootstrap.sequence.puml` | `docs/puml/bootsratp.sequence.puml` |
| 100% | `docs/puml/bootstrap.sequence/bootstrap.sequence.eps` | `docs/puml/bootsratp.sequence/bootsratp.sequence.eps` |
| 100% | `docs/puml/bootstrap.sequence/bootstrap.sequence.svg` | `docs/puml/bootsratp.sequence/bootsratp.sequence.svg` |
| 90% | `templates/code/newScript` | `myScript` |
| 76% | `templates/code/newMethod` | `templates/code/new_method` |
| 50% | `templates/code/newScriptTest` | `templates/code/new_script_test` |
| 100% | `templates/user/bashrcOnce` | `templates/user/bashrc_once` |
| 55% | `templates/user/bashrcTemplate` | `templates/user/bashrc_template` |
| 100% | `templates/user/tmuxDefaultConfig` | `templates/user/tmux_default_config` |

Caveat: the `templates/code/newScript` → `myScript` pairing is an artifact of similarity — `dev` keeps the
template, whereas `mcdonges` has a script generated from it. The real content change there is
"template in dev" vs "generated `myScript` on mcdonges".

## 7. Files modified on both sides

102 files. Sorted by churn. `Side` says which branch moved since the merge base —
`both` is where a real merge conflict is likely.

| File | + | − | Side |
|---|---:|---:|---|
| `test/test.oo` | 31 | 5224 | both |
| `test/test.ossh` | 706 | 3254 | both |
| `test/test.config` | 18 | 3816 | both |
| `test/test.hiveMind` | 3107 | 627 | both |
| `oo` | 576 | 3110 | both |
| `ossh` | 605 | 2960 | both |
| `test/test.odocker` | 55 | 2894 | both |
| `odocker` | 126 | 2111 | both |
| `test/test.this` | 52 | 1740 | both |
| `user` | 303 | 1460 | both |
| `test.suite` | 204 | 1462 | both |
| `config` | 150 | 1511 | both |
| `this` | 177 | 1404 | both |
| `test/test.otmux` | 1337 | 230 | both |
| `test/test.user` | 11 | 1544 | both |
| `test/test.test.suite` | 2 | 1311 | dev |
| `test/test.install` | 24 | 1234 | dev |
| `test/test.log` | 21 | 1092 | dev |
| `init/oosh` | 309 | 675 | dev |
| `test/test.claudeCode` | 868 | 73 | both |
| `docs/oo.md` | 82 | 750 | dev |
| `hiveMind` | 313 | 396 | both |
| `test/test.path` | 71 | 608 | dev |
| `docs/config.md` | 21 | 612 | dev |
| `path` | 233 | 324 | both |
| `log` | 98 | 415 | both |
| `su/setup` | 112 | 401 | dev |
| `scrumMaster` | 120 | 376 | both |
| `backup` | 202 | 240 | both |
| `test/test.scrumMaster.measure` | 370 | 28 | both |
| `test/test.state` | 14 | 369 | dev |
| `test/test.c2` | 65 | 317 | both |
| `ng/c2` | 92 | 275 | both |
| `test/test.os` | 233 | 129 | both |
| `docs/test-suite.md` | 2 | 347 | dev |
| `replace` | 20 | 316 | dev |
| `docs/log.md` | 14 | 321 | dev |
| `docs/hivemind.md` | 0 | 315 | dev |
| `os` | 137 | 152 | both |
| `test/test.debug` | 108 | 172 | dev |
| `test/test.line` | 1 | 238 | dev |
| `test/test.scrumMaster` | 62 | 174 | dev |
| `claudeCode` | 130 | 104 | both |
| `init/once` | 88 | 144 | both |
| `docs/oosh-architecture.md` | 56 | 169 | both |
| `.claude/settings.local.json` | 3 | 209 | both |
| `docs/state.md` | 42 | 127 | dev |
| `test/test.tilde` | 35 | 132 | dev |
| `debug` | 51 | 111 | both |
| `state` | 60 | 83 | both |
| `line` | 32 | 101 | both |
| `test/test.oosh` | 33 | 96 | both |
| `otmux` | 50 | 50 | both |
| `docs/oosh.md` | 76 | 3 | both |
| `README.md` | 27 | 48 | both |
| `otest` | 29 | 41 | both |
| `test/test.check` | 18 | 35 | both |
| `docs/debug.md` | 5 | 46 | dev |
| `docs/wiki-index.md` | 8 | 43 | both |
| `context` | 24 | 26 | dev |
| `docs/completion-system.md` | 0 | 33 | both |
| `test/test.scenario.fix` | 4 | 29 | dev |
| `check` | 9 | 23 | dev |
| `test/test.absolute.path` | 14 | 15 | dev |
| `disk` | 10 | 12 | dev |
| `test/test.isSourced` | 3 | 16 | dev |
| `test/test.loop` | 7 | 11 | dev |
| `CLAUDE.md` | 4 | 12 | dev |
| `test/test.call` | 5 | 11 | both |
| `templates/user/c2.install` | 2 | 11 | both |
| `test/test.currentUser` | 9 | 4 | dev |
| `test/test.fs` | 9 | 4 | dev |
| `test/test.mycmd` | 5 | 8 | both |
| `certificates` | 6 | 5 | dev |
| `loop` | 3 | 8 | dev |
| `.gitignore` | 0 | 10 | dev |
| `test/test.backup` | 5 | 5 | dev |
| `docs/first-principles.md` | 7 | 1 | both |
| `docs/log-levels-and-testing.md` | 3 | 5 | dev |
| `mycmd` | 4 | 4 | dev |
| `test/test.certificates` | 3 | 5 | dev |
| `test/test.headless` | 3 | 5 | dev |
| `test/test.matthias` | 0 | 7 | dev |
| `test/test.once2023` | 0 | 7 | dev |
| `test/test.pm-tools` | 0 | 7 | dev |
| `test/test.symbolicLink` | 0 | 7 | dev |
| `ng/2c` | 3 | 3 | both |
| `share` | 2 | 4 | dev |
| `test/test.academyScript` | 1 | 4 | dev |
| `test/test.data/parameterTestScript` | 5 | 0 | mcdonges |
| `test/test.tt` | 1 | 4 | dev |
| `docs/puml/SETUP_SERVER.sequence.puml` | 2 | 2 | dev |
| `snet` | 1 | 3 | dev |
| `test/test.share` | 1 | 3 | dev |
| `test/test.webitem` | 1 | 3 | dev |
| `test/test.myScript` | 0 | 3 | dev |
| `docs/command-creation.md` | 1 | 1 | dev |
| `init/deinstall.oosh` | 1 | 1 | dev |
| `status` | 1 | 1 | dev |
| `test/test.cd` | 1 | 1 | dev |
| `webitem` | 1 | 1 | dev |
| `.backup.env` | 0 | 1 | both |

## 8. Conflict candidates

These 57 paths were edited by *both* branches since the merge base, so a merge has to reconcile them by hand:

```
.backup.env
.claude/settings.local.json
README.md
agentRoom
backup
claudeCode
config
debug
docs/completion-system.md
docs/first-principles.md
docs/oosh-architecture.md
docs/oosh.md
docs/wiki-index.md
hiveMind
init/once
line
log
myId
ng/2c
ng/c2
odocker
oo
os
ossh
otest
otmux
path
scrumMaster
sprints/sprint-1/planning.md
sprints/sprint-1/task-1.c2.md
sprints/sprint-1/task-2.mycmd.md
state
templates/user/c2.install
templates/user/oosh.code-workspace
test.suite
test/test.c2
test/test.call
test/test.check
test/test.claudeCode
test/test.colors
test/test.config
test/test.data/test.backup.source/file2.txt
test/test.hiveMind
test/test.myId
test/test.mycmd
test/test.odocker
test/test.oo
test/test.oosh
test/test.os
test/test.ossh
test/test.otmux
test/test.scrumMaster.measure
test/test.this
test/test.user
this
tmux.conf
user
```

Highest risk among them (both sides rewrote large parts): `oo`, `ossh`, `odocker`, `config`, `this`, `user`,
`hiveMind`, `scrumMaster`, `claudeCode`, `otmux`, `test/test.oo`, `test/test.ossh`, `test/test.config`,
`test/test.hiveMind`, `test/test.otmux`, `test/test.claudeCode`, `test.suite`, `README.md`.

Notably, `dev` does **not** contain the `test.no-python` gate, the shared `claudeCode jsonl.usage` reader, the
pure-bash (python-free) `swipe.ctx`, the `pulse` removal or the live-pane-title rules; those exist only on
`mcdonges`. Conversely `mcdonges` does not contain `dev`'s load-architecture refactor, the 47-script docs
matrix, `ogit`/`promote`/`osshLayout`, or the macos CI workflow.

## 9. Cleanup notes

- The `mcdonges` tree carries scratch artifacts that probably should not be merged: `fix`, `tt`, `demo`,
  `myScript.new`, `myScript`, `ng/test.txt`, `test/test.test_temp{,_script}`, and the whole `old/` folder (19 files).
- `restore/` (6 files) is a deployed-state snapshot; keep it only if the branch is meant to be a reference.
- The single binary file in the diff is `docs/reports/2026-04-13-almalinux-work-report.xlsx` (dev only).
- The `mcdonges` tree misspells the diagram folder: `docs/puml/bootsratp.sequence*` vs `bootstrap.sequence*` on `dev`.
- `mcdonges` deleted `agentRoom`; `dev` modified it — a merge will resurrect or drop it depending on resolution.

