# Audit: repo state and recent `dev` commits

**Status:** research — report only, nothing changed.
**Date:** 2026-10-28
**Companion:** [test-suite audit of 2026-10-28](review-2026-10-28-test-suite-audit.md).
**Post-audit (2026-10-28):** H1/H2/H3 were fixed — `log live panes` uses the current otmux API, `hiveMind` uses the real queue-drain/sshHost names, the tracked `.backup.env` handling is documented, and both test gates are green (core 1342/1343 with 1 intentional, extended 328/328). The security item (C1) remains open.
**Range reviewed:** `ac24756b..bbd74046` on `dev` (six first-parent commits incl. the merge `4736ac04`) plus the working tree.
**Triggered by:** "audit this" — a read-only audit of the oosh repo and its uncommitted work.
**Method:** diff and history review against `CLAUDE.md`, `docs/oo.md`, `docs/this.md`, `docs/backup.md`; targeted suite runs on this host (`test.suite run <name> 1`); one throwaway fixture probe of the `oo method.new` rollback path; syntax checks (`bash -n`) of every changed script. No tracked file was modified (`git status` clean before and after).

**Commits in scope (first parent):**

| Commit | Change |
|---|---|
| `bbd74046` | "push test with space" — one newline in `.backup.env` |
| `242ff5fb` | test(oo): `T-METHOD-NEW-ALL-OR-NOTHING` checks the message in `RESULT` |
| `b02bffa2` | fix(oo): method.new says what to do on a missing script/folder/method name |
| `dcaa94d4` | fix(oo): method.new checks first, asks next, method and test together or neither |
| `4c5d92d6` | fix(odocker): restore two completions Marcel commented out |
| `4736ac04` | merge `origin/dev` (Marcel's agent tools) into `dev.scriptLoadGone` |
| `ef24ee64` / `8da4ec9d` / `ac24756b` | config loads only `this`; user loop guard; kernel loader removed |

---

## Verdict

The small, hand-written work on this branch (`oo method.new`, the `config`/`this`/`os` split, the `user`/`setup` fallbacks, the `odocker` completions) is correct and green. The **merge `4736ac04`** is the problem: it replaced four large tools without updating their tests, and it broke `log` through a renamed otmux API. The branch still carries a **live private key in a public repository** and a **tracked backup config that hijacks `backup` for everyone**.

Priority: rotate the key → fix the two silent runtime breakages → decide the red-test policy → untrack the local files → regenerate the docs.

---

## Critical

### C1. A live SSH private key is committed to a public repository

- `templates/user/developking.ssh/id_rsa` and an identical copy at `templates/user/developking.ssh/private_key/developer.wo-da.de.private_key` (`cmp` reports identical).
- Valid, **unencrypted 4096-bit RSA**: `ssh-keygen -y -f …` succeeds; fingerprint `SHA256:hPJaud8IWxd/8tlKG5vNopKZyZewgH8owA4j8rkf/WU`.
- Present on `origin/main` **and** `origin/dev`, added `d4f3b846` on **2022-01-25** (~4.7 years exposed).
- `https://api.github.com/repos/Cerulean-Circle-GmbH/once.sh` answers `"private": false`.
- This is an operational credential, not a fixture: `oo:3910 private.oo.developking.key.place` installs it into every new user's `~/.ssh/ids/ssh.developking` (`docs/install-bootstrap.md:162`), and `known_hosts` plus the public keys ship with it.

**Remediation, in order:** rotate/revoke the key (assume compromised — purging history does not un-disclose it), stop shipping a shared identity (per-host key, or a secret fetched at bootstrap), `git rm --cached` and gitignore both copies, then purge history (`git filter-repo` / BFG) in a coordinated force-push and add secret scanning (gitleaks/trufflehog) to CI.

---

## High

### H1. `log live panes` is broken — otmux was renamed, `log` was not updated

`log` was not touched by the merge (0 files in `git diff 8da4ec9d 4736ac04 -- log`) and still calls otmux methods the rewrite deleted:

| `log` line | call | current otmux |
|---|---|---|
| 504, 549 | `otmux.session.has` | `otmux.has` (`otmux:166`) |
| 507, 540 | `otmux.session.switch` | `otmux.switch` (`otmux:215`) |
| 509, 542 | `otmux.session.attach` | `otmux.attach` (`otmux:132`) |
| 523–524 | `otmux.set -t …` | no equivalent |

All four existed at `8da4ec9d` (`otmux:916`, `1560`, `1576`, `1598`) and none exists now. Probe:

```bash
bash -c 'source ./this; source ./otmux; source ./log
  for f in otmux.session.has otmux.session.switch otmux.session.attach otmux.set; do
    type -t "$f" >/dev/null 2>&1 && echo "$f defined" || echo "$f MISSING"
  done'
```

→ all four `MISSING`. `docs/log.md:256,259,273` still documents `./log live panes` and `panes.stop`.

There is no guard for this: `T-PRIVATE-CALLS-DEFINED` checks only `private.*` calls. Extend the guard to public `script.method` references.

### H2. `dev` is red, and the merge is what made it red

`4736ac04` brought ~12,000 inserted lines across `hiveMind`, `otmux`, `claudeCode`, `scrumMaster`, but updated **none** of those tools' test files — the merge touched only `test/test.config`, `test/test.os`, `test/test.this`.

- **`test.this`: 70/71 — `T-PRIVATE-CALLS-DEFINED`**
  - `hiveMind:9295` calls `private.hiveMind.agent.queue.drain`; the function is `hiveMind.agent.queue.drain` (`hiveMind:8877`). Queued messages are therefore **never drained** when an agent goes idle, and `2>/dev/null` hides the `command not found`.
  - `hiveMind:4010` and `hiveMind:4567` call `private.ossh.config.complete.hosts`, which exists nowhere (also not at `42524563`). The equivalent is `ossh.parameter.completion.sshConfigHost` (`ossh:2001`). `sshHost` completion for `team.migrate`/`team.push` is dead.
  - Both were introduced by `bf1ebe5a`; neither string exists at `8da4ec9d`.
- **`test.completion.audit`: 4/75** — 68 parameters without a completion function (`hiveMind` 38, `otmux` 11, `claudeCode` 11, `scrumMaster` 8), plus duplicate definitions and a `function` keyword at `scrumMaster:1039`. The file is `TEST_CATEGORY=core`, so **`core` cannot pass**.
- **`test.otmux`: 32/45** (extended)
  - `otmux.send.keys` existed at `8da4ec9d` (`otmux:2224`) and was deleted; `test/test.otmux:559` and `docs/otmux.md:47` still require it. No production caller remains, so this is test/doc drift plus an API removal without a deprecation.
  - T10–14 (`pane-border-status`, `mouse`, `mode-keys`, `history-limit`) may be environmental here: tmux 3.4 is installed but `/root/.tmux.conf` does not exist and the repo's `tmux.conf → /root/.tmux.conf` symlink dangles. T16–21/T26/T30 should be triaged on a configured host before being called regressions.
- `test/test.scrumMaster`, `test/test.scrumMaster.measure` still expect removed or renamed methods (`scrumMaster.pane.measure`, `scrumMaster.parameter.completion.*`, `private.scrumMaster.metrics.dir.get`) and were not updated. They are extended, but they will fail. (`test/test.claudeCode` had the same problem and was fixed on 2026-10-28 — it is green now, 21/21.)

The commit message admits the 71 completion failures; it does not mention `test.this`. The push to `origin/dev` went ahead with both.

### H3. A tracked `.backup.env` hijacks `backup` for everyone using the tree

`$OOSH_DIR/.backup.env` holds the maintainer's local paths and NAS target:

```bash
export BACKUP_SOURCE="/Users/donges/oosh"
export BACKUP_TARGET="pi@pi400:/media/pi/myData/Devices/MacStudio.native/Users/donges/oosh"
```

`backup.config.discover` (`backup`) walks upward from `pwd` to the first `.backup.env`, so any `./backup` run inside the repo resolves to this file — verified with `./backup config.which`, which prints that config. On a non-mac it points at a source that does not exist, and it leaks a host/user path.

**Remediation:** `git rm --cached .backup.env`, add a root `/.backup.env` rule to `.gitignore` (today only `test/test.data/.backup.env` is ignored), keep a `.backup.env.example` if a template is wanted. The tip commit `bbd74046 "push test with space"` only adds a newline to this file — drop or squash it.

---

## Medium

### M1. Generated docs still document a deleted method

`ac24756b` removed `private.this.script.load` and deliberately left the generated tables as they were:

- `docs/this.md:75`, `docs/object-verb-index.md:2461,3071`, `docs/parameter.md:41,650` still list it.
- `docs/config.md:869` still says `private.config.derive.oosh.os` works "via `os.check.env`" — it now reads `OOSH_OS` else `private.this.os.family.get`.
- The new `private.this.os.family.get` is absent from the matrix (the matrix header says generated 2026-10-20).

Regenerate the matrix, or at minimum fix the removed-method references, before the docs are used as an API index.

### M2. Repo hygiene

- `.DS_Store` is tracked (the ignore rule only stops new ones).
- `.claude/settings.local.json` is tracked despite `.claude/` in `.gitignore`; it contains other developers' absolute home paths (`/Users/Shared/...`, `/home/hannesn/...`) and a `docker cp … id_ed25519.pub` permission entry.
- CI is a single **manual** macOS workflow (`.github/workflows/macos-test.yml`); nothing gates a push. That is why H1/H2 shipped.

---

## Low

- **`oo method.new` rc=2 path** (`oo:92`) does not set `create.result`/`RESULT`, unlike rc 3–5, so the documented refusal message exists only in the log device. Repro: `oo method.new mytestfile`.
- **No EOF handling** on the five `read -r` prompts: Ctrl-D produces a method and test with empty metadata. There is no test for rc=2.
- **The commit-failure rollback is untested.** I verified it manually: with `test/test.<script>` made a symlink (so its `replace commit` refuses), `oo method.new` returned rc=4, the script was restored byte-for-byte, its exec bit was kept, the symlink was intact and no `.bak`/`.new` was left. Add that case to `test/test.oo`.
- **`b02bffa2` shipped a red test** (it asserted `error.log` text on stdout); `242ff5fb` fixed it afterwards. History-level verification slip only.
- `grep -E "^${functionName//./\\.}\(\)"` assumes method names are regex-safe. Fine for real dotted names; `[`/`+` would misbehave.
- Committed artifacts worth a later pass: `defaults/platforms.env` and the `.claude/agents/*` skill files are tracked but local-looking; no action without an owner.

---

## Verified green (not assumed)

| Suite | Result |
|---|---|
| `test.oo` | **190/190** |
| `test.config` | **146/146** |
| `test.os` | **6/6** |
| `test.user` | **69/69** |
| `test.setup` | **14/14** |
| `test.odocker` | **171/171** |
| `test.replace` | **18/18** |
| `test.this` | 70/71 (only H2) |
| `test.completion.audit` | 4/75 (H2) |
| `test.otmux` | 32/45 (H2) |

`bash -n` passes for `oo`, `odocker`, `config`, `os`, `this`, `user`, `su/setup`, `platform`, `claudeCode`, `hiveMind`, `otmux`, `scrumMaster`, `agentRoom`.

The `oo method.new` rewrite behaves as documented: checks → prompts → one transaction; marker/duplicate/missing-file refusals all happen **before** the first prompt and leave every file untouched (`dcaa94d4` + `242ff5fb`; 190/190 in `test.oo`).

The `config`/`this`/`os` split is clean: `config` contains zero `os.*`/`ogit.*` calls and `config.start` sources only `this`; every script that calls `os.*` sources `os` (the remaining `os.` hits are Python `import os`, comments and `config save os.commands`). `test.config`, `test.os` and all but one assertion of `test.this` pass.

The `user` init-loop guard (`ooshUserInitHealing`) and the `su/setup` + `user` fallback changes are covered and green (`test.user`, `test.setup`), and the restored `odocker` completions are green (`test.odocker`).

---

## Suggested order

1. **Rotate the developking key**; treat the repo as compromised.
2. Fix `hiveMind:9295,4010,4567` and `log:504–549` — both are silent runtime breakage.
3. Decide the red-test policy for the merge: fix or explicitly waive the 71 completion failures and `test.otmux`, but do not leave `core` red. Extend the call guard to public `script.method` references.
4. `git rm --cached .backup.env`, `.DS_Store`, `.claude/settings.local.json`; revert the newline-only commit.
5. Regenerate the method matrix; fix the `private.this.script.load` references.

---

## Reproduction notes

```bash
# suites
./test.suite run oo 1
./test.suite run this 1
./test.suite run completion.audit 1
./test.suite run otmux 1

# key exposure
ssh-keygen -y -f templates/user/developking.ssh/id_rsa >/dev/null && echo unencrypted
ssh-keygen -lf templates/user/developking.ssh/id_rsa.pub
curl -s https://api.github.com/repos/Cerulean-Circle-GmbH/once.sh | grep '"private"'

# backup config hijack
./backup config.which

# dangling cross-script calls
grep -n 'otmux\.session\.\(has\|switch\|attach\)\|otmux\.set ' log
grep -n 'private\.hiveMind\.agent\.queue\.drain\|private\.ossh\.config\.complete\.hosts' hiveMind
```
