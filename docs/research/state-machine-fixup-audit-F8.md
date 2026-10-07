# F8 Sub-Audit — `ossh.install.finish.local` shared-SSH region

**Status:** research only — no code edits. Untracked until reviewed.
**Date:** 2026-05-07
**Parent:** [state-machine-fixup-audit.md](state-machine-fixup-audit.md) (F8 row)

---

## Headline finding — F8 is not a FIXUP

The parent audit pre-classified F8 (`ossh:803–913`) as **FIXUP** based on its size and the recent destructive-cp regression (`115f862`). The sub-audit reaches a different verdict: **every sub-block is LEGIT** under the methodology of §2 of the parent audit. None of F8.1–F8.7 masks a missed state-machine step.

What F8 actually is: the runner-side seeding phase that propagates GitHub access (deploy key + Host alias + known_hosts) from the runner's local artefacts to the remote's shared SSH dir, then to every user on the remote. It's bidirectional sync that **architecturally must be post-state-machine** because the runner is the only host that holds the deploy key. The recent regression in `private.ossh.shared.ssh.copy.to.all` was a destructive-cp bug *inside* a legitimate phase, not a bug *of having* the phase.

The sub-audit therefore recommends **refactor for clarity, not elimination** — see §4. F8 should be downgraded in the parent audit's elimination order.

---

## 1. Call-graph note

Within `ossh.install.finish.local` (`ossh:782+`), the F8 region calls:

- `ossh.exec` — `ossh:820` (idempotency probe), `ossh:889` (remote `ossh config.shared.create` invocation)
- `private.ossh.ssh` — `ossh:828, 836, 899, 904` (heredoc-based config writes + cleanup)
- `private.ossh.shared.ssh.copy.to.all` — `ossh:825, 852, 912` — **three** call sites (caller-path post-seed, conditional, fallback-path post-seed). Definition at `ossh:1687+`.
- `scp` — `ossh:899` (stage runner-side developking template to remote `/tmp`)

External callers to `ossh.install.finish.local`: `ossh.install` at lines `~444`, `~451`, `~502`.

---

## 2. Sub-block inventory

### F8.1 — Skip-when-seeded probe

- **Location:** `ossh:819–823`.
- **What it does:** `ossh.exec` to test whether `/<basehome>/shared/.ssh/2cuGitHub` already exists on the remote. If yes, sets `_sharedAlreadySeeded=1` and short-circuits the destructive transfer paths.
- **Side effects:** none — read-only probe; sets local var.
- **Triggered when:** every call to `finish.local`.
- **Verdict:** **LEGIT**. Detect-don't-suppress is canonical OOSH idempotency.
- **Should be owned by:** stay. Could move *inside* a seeding helper (see §4) but that's refactor, not elimination.
- **Risk if removed:** every re-run emits `Permission denied` warnings re-seeding `/home/shared/.ssh` as the non-root install user.
- **Notes:** introduced in `67ddeb1` (May 7) — same commit that deleted state 31's dead block. Critical because `finish.local` runs on the *runner* as the install user (often `test@localhost` in `os.platform.test`), not as root on the remote. Continue.local already seeded shared as root via `ossh.config.shared.create` at `ossh:766–768`.

### F8.2 — Deploy-key transfer to shared (when local copy exists)

- **Location:** `ossh:826–834`.
- **What it does:** if `_sharedAlreadySeeded=0` and runner has `~/.ssh/deploy_keys/2cuGitHub` locally, pipes that file via `private.ossh.ssh` heredoc to create `/<basehome>/shared/.ssh/2cuGitHub` on remote. `mkdir -p` + `chmod 750` for dir, `chmod 600` for file.
- **Side effects:** writes `/<basehome>/shared/.ssh/2cuGitHub` (binary key, perms 600) and parent dir on remote.
- **Triggered when:** `[ $_sharedAlreadySeeded -eq 0 ] && [ -f $HOME/.ssh/deploy_keys/2cuGitHub ]` — first install with caller-side deploy key.
- **Verdict:** **LEGIT** (initial provisioning, not re-add).
- **Should be owned by:** stay. This is the runner→remote provisioning channel — only place that has the deploy-key bytes.
- **Risk if removed:** users on remote can't access GitHub at all (no shared deploy key to copy).
- **Notes:** `cat >` heredoc is atomic + idempotent for binary content.

### F8.3 — Shared `config` + `known_hosts` (append-if-missing)

- **Location:** `ossh:835–849`.
- **What it does:** in the same heredoc as F8.2, appends `Host 2cuGitHub` block to `/<basehome>/shared/.ssh/config` (guarded by `grep -q "^Host 2cuGitHub"`); populates `known_hosts` with `ssh-keyscan github.com` (also guarded).
- **Side effects:** append to `config` (perms 644) + `known_hosts` (perms 644).
- **Triggered when:** same as F8.2.
- **Verdict:** **LEGIT** (idempotent append).
- **Should be owned by:** stay. The Host block uses `IdentityFile ~/.ssh/2cuGitHub` (per-user relative), which is the right design — each user reads their own copy.
- **Risk if removed:** remote users would have the deploy key but no Host alias / no known_hosts entry → GitHub access requires explicit `-i`.

### F8.4 — Propagate shared → all users (caller path)

- **Location:** `ossh:850–852`.
- **What it does:** calls `private.ossh.shared.ssh.copy.to.all "$sshConfigHost"` to propagate the seeded shared artefacts to every user's `~/.ssh/`.
- **Side effects:** per user (and root): appends `Host 2cuGitHub` to `~/.ssh/config` (perms 600), appends github.com to `known_hosts`, copies `2cuGitHub` deploy key (perms 600, owner=user). Runs `sudo bash -c` on remote.
- **Triggered when:** after F8.2/F8.3 succeed (caller path).
- **Verdict:** **LEGIT** (delegated to a single-source-of-truth helper).
- **Should be owned by:** stay. The helper itself is the propagation primitive used by both paths.
- **Risk if removed:** only root has the shared config; non-root users on remote lack GitHub access.
- **Notes:** **this is where the recent regression lived.** Commit `115f862` (May 7) replaced destructive `cp $sharedSsh/config $h/.ssh/config` with append-if-missing inside the helper. The helper signature did not change — F8.4 is correct as written; the bug was *inside* the helper, now fixed. Confirm `115f862`'s fix is at the right line numbers in `private.ossh.shared.ssh.copy.to.all` before removing any defence.

### F8.5 — Fallback gate (no local deploy key)

- **Location:** `ossh:853–873`.
- **What it does:** logging + `elif [ ! -f $HOME/.ssh/deploy_keys/2cuGitHub ]` to enter the fallback path.
- **Verdict:** **LEGIT** (control-flow gate).

### F8.6 — Fallback seed via remote developking key (with template fallback)

- **Location:** `ossh:874–909`.
- **What it does:** calls `ossh.exec "$sshConfigHost" 'ossh config.shared.create "" "~developking/.ssh/id_rsa"'` — invokes the remote oosh to seed shared SSH from developking's in-place key. On failure, scp's the bundled template (`$OOSH_DIR/templates/user/developking.ssh/id_rsa`) to remote `/tmp` and retries `ossh.config.shared.create` with that path.
- **Side effects:** seeds `/<basehome>/shared/.ssh/{2cuGitHub,config,known_hosts}` on remote as root (via `ossh.exec`); transient `/tmp/oosh-developking-id_rsa.$$` file.
- **Triggered when:** caller has no local deploy key AND probe didn't fire.
- **Verdict:** **LEGIT** (robust fallback for environments without a runner deploy key).
- **Should be owned by:** stay. **Refactor candidate** — the dual-strategy (remote-key + template-fallback) is dense; could become its own helper `ossh.config.shared.seed.fallback`. See §4 priority 1.
- **Risk if removed:** installs without a local deploy key + unreachable remote developking would silently skip GitHub seeding.
- **Notes:** uses `ossh.exec` (not raw `private.ossh.ssh`) so OOSH_DIR is on PATH for both Linux and macOS. Stderr is **not** suppressed — real errors surface (per the `67ddeb1` philosophy of detect-don't-suppress).

### F8.7 — Propagate shared → all users (fallback path)

- **Location:** `ossh:911–912`.
- **What it does:** second call to `private.ossh.shared.ssh.copy.to.all` after the fallback seed.
- **Verdict:** **LEGIT** (same helper as F8.4; helper is idempotent).
- **Notes:** F8.4 + F8.7 are duplicate calls. **Refactor candidate** — call once at the end of all seeding paths, not twice. See §4 priority 3.

---

## 3. Permission boundary summary

| Block | Runs on | As whom | Why that user is allowed |
|---|---|---|---|
| F8.1 (probe) | remote | install user (often `test@localhost`) | read-only, no privilege needed |
| F8.2 (key transfer) | remote | install user, via `private.ossh.ssh` heredoc | the heredoc creates `/<basehome>/shared/.ssh` — needs `sudo` or that the user owns the parent. In `os platform.test` the install user has passwordless sudo (set up at `os:217, 260, 266`). |
| F8.3 (config/known_hosts) | remote | install user | same as F8.2 |
| F8.4 (propagate) | remote | install user, but helper does `sudo bash -c '...'` internally | each per-user copy needs `chown user:` → requires sudo |
| F8.6 (fallback seed) | remote | runs `ossh` → which on remote runs as root | `ossh.exec` reaches root via `sudo` per the install user's sudoers entry |
| F8.7 (propagate) | remote | install user with internal sudo | same as F8.4 |

The skip-when-seeded probe (F8.1) is what avoids the wall of permission errors on re-runs — without it, every block from F8.2 onward would attempt write operations and (most) fail.

---

## 4. Recommended F8 elimination / refactor order

The goal is **clarity, not elimination** — F8 is doing real work that belongs post-state-machine. Refactor priorities:

1. **Extract F8.6 to its own helper.** Name suggestion: `ossh.config.shared.seed.fallback <sshConfigHost>`. Encapsulates the dual-strategy (remote-developking-key + bundled-template fallback). Reduces `finish.local` clutter and makes the fallback testable in isolation.

2. **Consolidate the F8.4 + F8.7 propagation calls into one.** Move `private.ossh.shared.ssh.copy.to.all "$sshConfigHost"` to a single call at the end of the F8 region, after both seeding paths have had a chance to run. The helper is idempotent so this is a pure simplification — but it makes the data-flow obvious: "seed → propagate".

3. **Move F8.1's idempotency probe inside the seeding helpers.** After (1) and (2), the probe-then-seed-or-skip logic should live inside `ossh.config.shared.seed.fallback` and a new `ossh.config.shared.seed.from.local.deploy.key` helper. `finish.local` would then read as: "if deploy key local → seed.from.local.deploy.key; else → seed.fallback; then propagate". The probe becomes an implementation detail of "seed".

4. **Optional later step: turn the seeded-shared-SSH check into a state.** Instead of `finish.local` being responsible for ensuring `/<basehome>/shared/.ssh/2cuGitHub` exists, define a state like `shared.ssh.seeded` whose check function calls `ossh.config.shared.seed.*` with fail-loud semantics. Aligns F8 with the parent audit's broader principle (state machine owns everything). Defer until parent §5.1 (`user.init` truncate fix) is done — that one matters more.

End state of F8 region after (1)–(3):

```bash
# F8 — runner-side shared-SSH seeding + propagation
if [ -f "$HOME/.ssh/deploy_keys/2cuGitHub" ]; then
  ossh.config.shared.seed.from.local.deploy.key "$sshConfigHost"
else
  ossh.config.shared.seed.fallback "$sshConfigHost"
fi
private.ossh.shared.ssh.copy.to.all "$sshConfigHost"
```

Three lines instead of 110, with no behaviour change.

---

## 5. Correction to parent audit

The parent audit's §3 (F8 entry) classified F8 as `FIXUP` and put it in §5 elimination order step 5 ("decompose F8 in a separate sub-audit"). This sub-audit's verdict overrides that:

- **F8 verdict update: LEGIT (refactor candidate, not eliminate).** Update the parent audit's row F8 accordingly.
- **Parent §5 step 5 update:** instead of "decompose F8 because it's the largest FIXUP," reword as "F8 is legit; refactor for clarity per F8 sub-audit §4 — non-blocking, do after §5.1–§5.4."
- **Parent §6 open question 2** ("F8 scope: want a dedicated F8 sub-audit?") — answered. The audit found no FIXUPs in F8. The dedicated sub-audit was warranted (the destructive-cp regression history made the size suspicious), but the answer is "no eliminate-able fixups inside; refactor only."

---

## 6. Open questions (F8-specific)

1. **Should we apply refactor priorities 1–3 now or defer?** They're pure cleanup — no behaviour change. Cheap to do but not urgent. Recommendation: defer until after §5.1 (`user.init` truncate fix) — that's the one that's actively masked by F1+F2 and worth touching first.

2. **Priority 4 (turn shared-ssh-seed into a state)** — this would align F8 with the parent audit's "state machine owns everything" principle. It's architecturally clean but adds new state-machine machinery. Want it, or is "post-state-machine sync done by `finish.local`" an acceptable architectural exception (with the rationale: only the runner has the deploy key, so this work *cannot* run on the install target during the state machine)?
