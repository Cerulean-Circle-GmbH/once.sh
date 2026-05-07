# State-Machine Fixup Audit

**Status:** research only — no code edits proposed yet. Untracked until reviewed.
**Date:** 2026-05-07
**Triggered by:** WODA-regression session — user articulated the load-bearing principle that *the install state machine must own every step; defensive fixups running after it mask state-machine bugs*.

---

## 1. Scope of the audit

Inspected for FIXUP / LEGIT / AMBIGUOUS classification:

- **`ossh.install.continue.local`** — `ossh:617–780`. This is the *real* state-machine entrypoint on the install target (invoked at `init/oosh:518`); blocks AFTER its `oo state` call (`ossh:662`) are post-state-machine.
- **`ossh.install.finish.local`** — `ossh:782–940`. Runs on the *runner* (caller-side) after the remote install completes (called from `ossh.install` at line ~502 and from `init/oosh` after `continue.local` returns).
- **`init/oosh` tail** — `init/oosh:521–559`. Anything between the state-machine handoff and process exit.
- **`osshLayout`** — module + its three call sites (`ossh:691`, `user:912`, `ossh:2446`).
- **`oo` state 31 (`private.check.root.shared.dev.folder.created`)** — included for context (the CIRCULAR commit chain starts here).

Excluded (out of audit scope, briefly noted):

- `ossh.install` itself (`ossh:401`) — caller-side, runs *before* the state machine on the target.
- `ossh.install.user.remote` (`ossh:955`), `ossh.install.log` (`ossh:942`), `ossh.install.completion` (`ossh:1168`) — utility / not post-machine.
- Variable assignments, pure logging (`success.log`, `info.log`), result/return statements — listed in "Skipped" section per agent.

---

## 2. Methodology

Decision rules used by the agents:

| Pattern | Verdict |
|---|---|
| `grep -q "^Host …" \|\| (write block)` | **FIXUP** — work the state machine should have done; this is a defensive re-add. |
| "Re-add", "ensure", "if missing then write" comments | FIXUP candidate. |
| `ossh.config.create` running *after* a state has supposedly already configured the host | FIXUP. |
| `sed -i` rewriting paths previously written | FIXUP — write-time logic should produce correct paths. |
| Backup-before-overwrite (`check dir … not exists call …`) | LEGIT (preserves user state). |
| Consuming state-machine output, optional polish, status reporting | LEGIT. |
| Bidirectional sync (e.g. push results back to caller after remote completed) | LEGIT (architecturally must be post-machine). |
| `osshLayout build` | AMBIGUOUS until we decide whether it's its own concern or belongs in a state. |

A FIXUP is judged **CIRCULAR** when its commit message justifies it as "state X stopped doing Y, so we add this fallback" — and that fallback is the very reason state X "could" stop doing Y. Such commits are top of the elimination order.

---

## 3. Inventory

Numbering: `F1`, `F2`, … merged across agents (Agent A's `F-A` rows + Agent B's `F-B` rows; duplicates collapsed — `F-A1 = F-B2 = F1`, `F-A2 = F-B3 = F2`, etc.).

### F1 — defensive `Host 2cuGitHub` re-add to `~/.ssh/config`

- **Location:** `ossh:700–711` inside `ossh.install.continue.local`.
- **What it does:** if `~/developking/.ssh/id_rsa` exists and `^Host 2cuGitHub` is not in `~/.ssh/config`, calls `ossh.config.create 2cuGitHub …` then `ssh-keyscan github.com >> known_hosts`.
- **Triggered when:** every install path that reaches `continue.local` (i.e. all of them, including `os platform.test`).
- **Verdict:** **FIXUP** — **CIRCULAR**.
- **Should be owned by:** state 31 (`root.shared.dev.folder.created`) for root, and `user.init` for non-root users (already writes WODA at `user:253–274` but does *not* write 2cuGitHub).
- **Risk if removed without fix:** `oo update` / `git pull` fails with "Could not resolve hostname 2cugithub" on first install — because `ossh:670–673` (`user ssh.backup original` then `user init`) destroys what state 31 wrote.
- **Cross-ref:** introduced in **`864ac8e`** (2026-04-23). Stated rationale (paraphrased from commit message): *"state 31's `private.install.dev.configs` appends the 2cuGitHub alias, but install.continue.local then calls `user init` (line 532) which creates a fresh ~/.ssh/config — discarding the 2cuGitHub block."* The fixup masks the fact that `user init`'s heredoc-overwrite (line `user:274`: `} >$sshDir/config`) is destructive.

### F2 — defensive `Host WODA.{test,dev.root,dev}` re-add to `~/.ssh/config`

- **Location:** `ossh:719–727` inside `ossh.install.continue.local`.
- **What it does:** if `~/.ssh/config` exists and `^Host WODA.test` is missing, calls `ossh.config.create` three times (one per WODA alias) using `~/.ssh/id_rsa` as IdentityFile.
- **Triggered when:** every install path through `continue.local`.
- **Verdict:** **FIXUP** — **CIRCULAR** (most circular: see history below).
- **Should be owned by:** state 31 for root; `user.init` for non-root (already writes WODA — but with `IdentityFile $sshDir/id_ed25519`, *not* `~/.ssh/id_rsa` — schema mismatch worth resolving).
- **Risk if removed without fix:** root has no WODA aliases after install — same regression that motivated `bed773c` originally.
- **Cross-ref:** introduced in **`bed773c`** (2026-05-06). Refactored in **`ff14cc2`** (same day) to use `ossh.config.create` instead of inline heredoc. The chain: state 31 had a writer at `oo:1305–1331` gated by `[ ! -d $HOME/.ssh ]`. Modern pipeline creates `~/.ssh` upstream of state 31 (via `user init` at `ossh:673`), so the gate stopped firing. `bed773c` was added to compensate. Then **`67ddeb1`** (2026-05-07) deleted the now-dead block from `oo` — citing `bed773c`'s defensive re-add as proof the writer was no longer needed. Pure circular justification.

### F3 — sed-rewrite of hardcoded `/root` paths in shared config

- **Location:** `ossh:729–758` inside `ossh.install.continue.local`.
- **What it does:** uses `sed` to replace absolute `/root` / `/root/dev` paths with `$HOME` (or generic) in shared config files and sub-configs.
- **Triggered when:** root's install wrote shared config with absolute paths; non-root users sourcing it would otherwise resolve to `/root/...`.
- **Verdict:** **FIXUP**.
- **Should be owned by:** whichever state writes the shared config (currently `private.install.dev.configs` at `oo:1612` and `ossh.config.shared.create` at `ossh:1570`). Should template paths from the start with `$HOME` / `${baseHome}`, not absolute root, so this sed is unnecessary.
- **Risk if removed without fix:** non-root users source shared config and hit `/root/...` paths → permission/path errors.
- **Cross-ref:** would benefit from `git log -S "sed.*\\/root" -- ossh` to date precisely; not done by Agent C.

### F4 — defensive shared-SSH seed from developking's in-place key

- **Location:** `ossh:760–768` inside `ossh.install.continue.local`.
- **What it does:** if `~/developking/.ssh/id_rsa` exists and `~/shared/.ssh/2cuGitHub` doesn't, calls `ossh.config.shared.create` to seed shared config with the developking-key fallback.
- **Triggered when:** state 31's seed didn't run or failed silently (e.g. early termination, permissions).
- **Verdict:** **FIXUP** (defensive duplicate of state-31 logic).
- **Should be owned by:** state 31 (`root.shared.dev.folder.created`) — single owner; if state 31 fails, the install must fail loud, not paper over with a fallback here.
- **Risk if removed without fix:** if state 31 is *currently* skipping this work (which the existence of this fallback suggests is happening), the shared SSH config remains unseeded → users can't access GitHub.

### F5 — `osshLayout build` invocation

- **Location:** `ossh:691–693` inside `ossh.install.continue.local`.
- **What it does:** materialises `~/.ssh/` layout (owner symlinks, `ids/ssh.developking/`, `ids/ssh.<installer-id>/`, `ids/ssh.outeruser/`).
- **Triggered when:** every install through `continue.local`.
- **Verdict:** **AMBIGUOUS — leaning LEGIT.** Per Agent B, `osshLayout` is its own module with role-based design; runs after `user init` so it can populate the post-keygen layout. Not a defensive re-add of someone else's missed work. *But:* nothing forces it to be post-state-machine; it could be a state itself.
- **Should be owned by:** stays where it is (LEGIT) **OR** promoted to a state of its own (e.g. `root.ssh.layout.materialized`). Defer until F1+F2 are addressed.
- **Risk if removed without fix:** users lack identity directories, can't SSH or git-push.

### F6 — clear install-only logging variables

- **Location:** `ossh:770–773` inside `ossh.install.continue.local`.
- **What it does:** unsets `LOG_INSTALL` and `INSTALL_LOG` so they don't persist into user shells via `log.env`.
- **Verdict:** **LEGIT** — pure housekeeping; logging framework should never auto-persist install-only vars.
- **Risk if removed without fix:** every subsequent user shell session hits `Permission denied` reading the install log.

### F7 — config push back to remote (`finish.local`)

- **Location:** `ossh:799–801` inside `ossh.install.finish.local`.
- **What it does:** pushes shared config from runner back to remote.
- **Verdict:** **LEGIT** — bidirectional sync, architecturally must be post-machine.

### F8 — shared SSH seeding + deploy-key transfer + copy-to-all-users (`finish.local`)

- **Location:** `ossh:803–913` inside `ossh.install.finish.local`.
- **What it does:** seeds `/<basehome>/shared/.ssh` on remote with deploy key; creates shared config + `known_hosts`; calls `private.ossh.shared.ssh.copy.to.all` to propagate to every user's `~/.ssh/`.
- **Verdict:** **FIXUP** — large block. Contains the recently-fixed destructive-cp bug (commit `115f862`, 2026-05-07).
- **Should be owned by:** dedicated state(s) — the seeding belongs in state 31 / a sibling state, the per-user propagation belongs in a per-user state (e.g. `user.<name>.ssh.config.propagated`).
- **Risk if removed without fix:** users on the remote can't access GitHub or each other.
- **Cross-ref:** the destructive `cp` here was the regression latent since `25676e2` (2026-04-21), exposed once `e197676` reliably seeded `2cuGitHub`, fixed in `115f862`. F8 is large enough to deserve its own breakdown — recommend a sub-audit before any code edit.

### F9 — remote key pull + authorized_keys update (`finish.local`)

- **Location:** `ossh:915–931` inside `ossh.install.finish.local`.
- **What it does:** pulls remote's public key, updates local `authorized_keys`.
- **Verdict:** **LEGIT** — bidirectional key sync; can only happen after the remote install has generated keys.

### F10 — non-root invoker `user.oosh.install` (`init/oosh` tail)

- **Location:** `init/oosh:536–559`.
- **What it does:** if curl-pipe was invoked by a non-root user via sudo (`SUDO_USER` set, non-root, install rc==0), runs `user.oosh.install` for that user too.
- **Verdict:** **LEGIT** — bootstrap flow extension, correctly gated; not a defensive fixup.

---

### Trivial / skipped blocks

Pure logging, variable assignments, and result/return statements were not classified. Itemised list per agent — see Agent A's skipped section (lines 619–658, 668–684, 777–778) and the equivalent in Agent B's report. None contained executable work that meets the FIXUP threshold.

---

## 4. Cross-references / circular-justification map

```
F1 (864ac8e, Apr 23)  ──┐
                        ├─→ both masked by `user init`'s `> $sshDir/config` (user:274) destroying state 31 + 2cuGitHub writes
F2 (bed773c, May 6)  ──┘
                        ↑
                        masked the regression that 67ddeb1 (May 7) then justified deleting the dead state-31 block

F4 (defensive shared seed)  ──→ state 31 is the canonical writer; F4 exists *because* state 31 sometimes silently doesn't.

F8 destructive-cp regression (115f862, May 7) ──→ latent since 25676e2 (Apr 21); each fix downstream made the symptom more visible without addressing the source.
```

Three commits form a closed cycle of mutually-justifying defensive logic: `864ac8e` → `bed773c` → `67ddeb1`. None of them removed the underlying breakage in `user init`'s overwrite (line `user:274`).

---

## 5. Recommended elimination order

1. **Fix `user.init` to be append-if-missing**, not destructive `> $sshDir/config`. Specifically: change `user:274` heredoc redirect to write a fresh file *only if `$sshDir/config` does not exist*, and otherwise call `ossh.config.create` per alias (idempotent). This single change removes the *original* destructive overwrite that F1 and F2 are masking. (Sub-plan needed: handle `ossh:670–673`'s `user ssh.backup original` + `user init` sequence which intentionally produces a fresh `.ssh` — clarify intent.)

2. **Harden state 31 to own root's WODA + 2cuGitHub writes with fail-loud.** This is the previously-parked plan (revert of `67ddeb1` via `user init` + verification loop). Once #1 lands, state 31 calling `user init` is safe and idempotent. Then delete F1 (`ossh:700–711`) and F2 (`ossh:719–727`).

3. **Eliminate F3** by templating shared-config paths with `$HOME`/`$baseHome` from the start in `private.install.dev.configs` (`oo:1612`) and `ossh.config.shared.create` (`ossh:1570`). Then delete the sed block at `ossh:729–758`.

4. **Eliminate F4** by hardening state 31's shared-config seed to fail loud if the developking key is missing. Delete the `ossh:760–768` fallback.

5. **Decompose F8** in a separate sub-audit. It's a 110-line block containing seed + transfer + per-user propagation; each concern should be in its own state. Don't touch until 1–4 are done — F8's destructive cp was very recently fixed and we want stability first.

6. **Decide on F5** (osshLayout). Either keep as LEGIT with a one-line comment explaining why, or promote to its own state. Lower priority — it is not currently masking a bug.

---

## 6. Open questions for the user

1. **F1 / F2 root cause vs symptom:** the root cause of both is that `user.init` truncates `$sshDir/config` (line `user:274`). Do you want me to plan fixing `user.init` first (making it append-if-missing), or harden state 31 to write WODA *after* `user init` runs (which lives in `continue.local`'s post-machine tail and therefore shifts the timing question)? The audit recommends the first; the parked plan assumed the second.

2. **F8 scope:** F8 is the largest single FIXUP in the codebase and was the source of the recent regression. Want a dedicated F8 sub-audit before any code edit there? Recommend yes.

3. **`user init` semantics:** when `ossh:670–673` runs `user ssh.backup original` then `user init`, the *intent* seems to be "blow away the old `.ssh` and re-init". If that's right, F1/F2 are not masking a bug in `user.init` — they're masking the fact that `init` happens *after* state 31's writes. In which case the elimination should move state 31's writes to *after* `user init`, not before. Need your call on this.

4. **F3 shared-config paths:** are there cases where the shared config legitimately needs absolute `/root` paths (e.g. for root-only access)? Or is `$HOME`/`$baseHome` always correct?

5. **F5 osshLayout:** is this its own concern (then keep it post-machine and explicitly mark as LEGIT) or should it become a state? Architecturally easier as state but adds machinery.

---

## 7. Next steps

After your review, the deliverable becomes a sequence of one focused implementation plan per item in §5, in order. Each will have its own `docs/superpowers/plans/…` plan + ExitPlanMode approval; this audit doc is the index.
