# Plan: Fix `user.init` destructive overwrite

**Status:** plan only — no edits yet. Untracked until reviewed.
**Date:** 2026-05-07
**Parent audit:** [state-machine-fixup-audit.md](state-machine-fixup-audit.md) §5 step 1.
**Triggered by:** `user.init` (`user:230–278`) ends with `} >$sshDir/config` — a destructive redirect that wipes whatever `~/.ssh/config` previously held. Two defensive re-add blocks (F1 at `ossh:700–711` and F2 at `ossh:719–727`) exist *only* to repair what this overwrite destroys. Fix the root cause; the masks become no-ops.

---

## Context

Findings from the targeted research pass:

- **Only one live caller:** `ossh:673` (`user init` inside `ossh.install.continue.local`). The other reference at `user:1234` is inside a help/usage block, not a real call site. Blast radius is small.
- **The "backup-then-init" pattern at `ossh:670–673` does NOT depend on destructiveness.** `user.ssh.backup original` (`user:1158-1174`) is `cp -R $sshDir ssh.original` — a *copy*, not a *move*. The original `.ssh/config` is still in place when `user.init` runs immediately after. So the destructive `>$sshDir/config` is a hidden bug, not a deliberate "fresh start after we moved the old aside".
- **State 31 writes 2cuGitHub via `private.install.dev.configs` (`oo:1612`) BEFORE `ossh.install.continue.local` runs.** `user.init`'s overwrite then wipes that 2cuGitHub block. F1's stated rationale (`864ac8e`, Apr 23) explicitly diagnoses this as the bug it papers over.
- **Append-if-missing primitives already exist** and are idempotent: `ossh.config.create <alias> <user@host:port> <id>` stages a Host block, then `ossh.config.save.last [<file>]` appends — guarded by a `grep -q "^Host ${entry}$"` dedup that *skips append* when the alias is already present. We don't need new primitives; we need to use these.
- **The post-fix `private.ossh.shared.ssh.copy.to.all` (`ossh:1687+`, fixed in `115f862`) propagates only `Host 2cuGitHub`** to per-user `~/.ssh/config` — *not* WODA blocks. WODA is owned entirely by `user.init` per-user (with templated `IdentityFile $sshDir/id_ed25519`).

**Knock-on insight: the new `test.ssh.config.woda` test cannot pass for non-root users today.** Test expects literal `IdentityFile /root/.ssh/id_ed25519` (hardcoded) in every user's `~/.ssh/config`. `user.init` writes `IdentityFile $sshDir/id_ed25519` (templated, per-user). Non-root users *never* get the hardcoded `/root/...` path. This is a separate bug-or-design-mismatch and is addressed in §5 below.

---

## Reused OOSH artefacts (do not reimplement)

| Path | Purpose |
|---|---|
| `ossh.config.create` (`ossh:253–327`) | Stage a Host block in `$CONFIG_PATH/result.txt`. |
| `ossh.config.save.last` (`ossh:1449–1468`) | Append the staged block to a config file, **idempotent** (skips if Host already present). |
| `ossh.config.get <alias> [<file>]` (`ossh:1148–1182`) | Read-only check whether an alias exists. Returns 0 if found, 2 if not. |
| `user.ssh.status log` (`user:25–28` → `ossh.isInstalled` at `ossh:1844-1872`) | Detect whether `~/.ssh` already has a keypair. Drives `user.init`'s outer if/else. |

**Not reimplementing:** the heredoc that writes the WODA block from a single template literal at `user:253–274`. Replaced by per-alias loop using the primitives above.

---

## Files modified

- **`user`** — rewrite the inner `else` branch of `user.init` (the "initialising new .ssh in $sshDir" path, currently `user:243–277`). Keep the outer if/else (`user.ssh.status log`) and the keypair-creation steps unchanged.
- **`test/test.ssh.config.woda`** — relax the IdentityFile assertion to accept the templated form (see §5).

That's it. F1 (`ossh:700–711`) and F2 (`ossh:719–727`) are *not* touched in this plan — they're follow-up cleanup once we've verified that user.init no longer destroys what they were re-adding.

---

## The change to `user.init`

### Replace the inner `else` branch

**Currently (`user:243–277`)** the else branch creates the keypair, then truncates `config` with a heredoc:

```bash
else
  console.log "initialising new .ssh in $sshDir"
  mkdir -p $sshDir
  ssh-keygen -t ed25519 -f "$sshDir/id_ed25519" -N ''
  mkdir -p $sshDir/public_keys
  mkdir -p $sshDir/private_key
  user.ssh.get.key.name
  local sshKeyName="$RESULT"
  cp "$sshDir/id_ed25519" "$sshDir/private_key/$sshKeyName.private_key"
  cp "$sshDir/id_ed25519.pub" "$sshDir/public_keys/$sshKeyName.public_key"
  {
    echo "
Host WODA.test
 User root
 ...
    "
  } >$sshDir/config         # ← DESTRUCTIVE: wipes any prior content
  oo cmd tree >/dev/null
  tree $sshDir
fi
```

**New version** keeps the keypair work as-is and replaces the heredoc with append-if-missing per alias:

```bash
else
  console.log "initialising new .ssh in $sshDir"
  mkdir -p $sshDir
  ssh-keygen -t ed25519 -f "$sshDir/id_ed25519" -N ''
  mkdir -p $sshDir/public_keys
  mkdir -p $sshDir/private_key
  user.ssh.get.key.name
  local sshKeyName="$RESULT"
  cp "$sshDir/id_ed25519" "$sshDir/private_key/$sshKeyName.private_key"
  cp "$sshDir/id_ed25519.pub" "$sshDir/public_keys/$sshKeyName.public_key"

  # Ensure WODA Host aliases are present without truncating any pre-existing
  # config entries (e.g. state 31's 2cuGitHub write that previously got wiped).
  # ossh.config.save.last is idempotent — skips when ^Host <alias>$ already
  # exists in $sshDir/config — so this loop is safe on partial / re-run state.
  touch "$sshDir/config"
  if ! ossh.config.get WODA.test "$sshDir/config" >/dev/null 2>&1; then
    ossh.config.create WODA.test     root@178.254.18.182:22  "$sshDir/id_ed25519"
    ossh.config.save.last "$sshDir/config"
  fi
  if ! ossh.config.get WODA.dev.root "$sshDir/config" >/dev/null 2>&1; then
    ossh.config.create WODA.dev.root root@cerulean.it:22     "$sshDir/id_ed25519"
    ossh.config.save.last "$sshDir/config"
  fi
  if ! ossh.config.get WODA.dev "$sshDir/config" >/dev/null 2>&1; then
    ossh.config.create WODA.dev      developking@cerulean.it:22 "$sshDir/id_ed25519"
    ossh.config.save.last "$sshDir/config"
  fi

  oo cmd tree >/dev/null
  tree $sshDir
fi
```

### What changes semantically

1. **No truncation.** Anything previously in `$sshDir/config` (e.g. state 31's 2cuGitHub block) survives `user.init`.
2. **Per-alias idempotency.** Re-runs are silent no-ops once the three WODA aliases are present.
3. **Same `IdentityFile $sshDir/id_ed25519` semantics** — preserves the templated-per-user design (intentional per `32e3b66`, Feb 2026).
4. **`touch "$sshDir/config"`** ensures the file exists before `ossh.config.get` is called — that primitive returns 2 (not found) if the file is missing AND emits a noisy log line. Touch prevents the noise on first install.

### What does NOT change

- The outer `if user.ssh.status log` early-return branch (`user:236–242`) is unchanged — already idempotent.
- Keypair creation, `public_keys`/`private_key` symlink copies — unchanged.
- The `ossh:670–673` backup-then-init pattern in `continue.local` — unchanged. After this fix, `user.init` is safely re-runnable, but the existing `check dir $HOME/ssh.original not exists` guard already makes the backup itself a once-only step.

---

## Test adjustment (`test/test.ssh.config.woda`)

**Today's test** asserts each user's `~/.ssh/config` contains the literal lines:

```
IdentityFile /root/.ssh/id_ed25519
IdentityFile /home/developking/.ssh/id_rsa
```

**The mismatch:** `user.init` writes `IdentityFile $sshDir/id_ed25519` per user, so for `bob` the line is `IdentityFile /home/bob/.ssh/id_ed25519` — the literal `/root/...` test will never pass for non-root users.

**Why templated is correct:** non-root users can't *read* `/root/.ssh/id_ed25519` — file mode 600 owned by root. A WODA Host block pointing them at root's key is broken-by-design. Each user must use their own key.

**Two viable test designs:**

- **A (recommended)** — relax the `IdentityFile` assertion to "*some* file ending in `id_ed25519`" (use `grep -Eq "IdentityFile .*id_ed25519"` and same for `id_rsa`). Continues to verify the four Host aliases + User/HostName, but accepts per-user paths.
- **B** — split assertions by `whoami`: when `$USER == root` expect literal `/root/...`; when non-root expect `$HOME/.ssh/...`. More precise; more code.

Plan goes with A — the goal of the test is "WODA Host aliases are present and pointing at *an* ed25519 key", not "every user impersonates root".

Concrete change to `test/test.ssh.config.woda`:

- Replace `"WODA.test::IdentityFile /root/.ssh/id_ed25519"` with a loop that uses `grep -Eq "^[[:space:]]*IdentityFile[[:space:]].*id_ed25519"` (and similarly for `id_rsa`). Kept as a single check at the bottom of the test, separate from the per-alias Host/User/HostName checks.

---

## Verification

1. **Syntax + smoke on host:** `bash -n user && ./test.suite all 1` — same 2-failed baseline (intentional + hannesn's still-missing WODA, since hannesn's config didn't go through `user.init` on this host). No regression.

2. **Targeted in-container verification** via `os platform.test ubuntu_24_04 notests`:
   - After install, `ossh exec ubuntu_24_04 "sudo cat /root/.ssh/config"` → expect: 2cuGitHub block (from state 31) **and** all three WODA blocks (from user.init), neither overwriting the other. Pre-fix this assertion fails (or only passes via F1's defensive re-add).
   - `ossh exec ubuntu_24_04 "sudo cat /home/test/.ssh/config"` → expect: WODA blocks with `IdentityFile /home/test/.ssh/id_ed25519` (templated, correct for the test user).
   - `ossh exec ubuntu_24_04 "sudo bash -lc 'cd \$OOSH_DIR && ./test.suite run ssh.config.woda 1'"` → expect PASS.

3. **Negative-path test (manual):** before the fix, append a `Host MyServer` block to a clean container's `/root/.ssh/config`, run `user init`, confirm `MyServer` is GONE (destructive write proven). After the fix, repeat — confirm `MyServer` survives.

---

## Out of scope (deferred follow-ups)

- **Delete F1 + F2** (`ossh:700–711` + `ossh:719–727`). Once user.init is non-destructive, both become true no-ops (their `grep -q "^Host …" ||` guards now always succeed). Worth a separate, tiny commit *after* this plan lands and a clean install is verified — but doing it in the same commit risks bisect noise if the user.init change has an unexpected wrinkle.
- **Decide on the broader audit's §5 steps 3–6** — F3 (path-rewrite sed), F4 (defensive shared-seed), F5 (osshLayout LEGIT/state choice), F6 (state 31 ownership of WODA). Each is its own plan.
- **State 31 revert/harden.** The `67ddeb1` commit's removal of the WODA-write block from `oo` becomes self-correcting once `user.init` writes WODA without destroying state 31's contributions. State 31 still doesn't *itself* fail-loud on missing WODA, but the regression mode that motivated the audit ("WODA missing on the install host") is closed by this plan alone.

---

## Risks / things to watch

- **`ossh.config.get` returning 2 vs 1.** The function uses `create.result <code>` and `return $(result)`. Confirm `>/dev/null 2>&1` properly suppresses both stderr noise and the function's `info.log` side effect. If `info.log` writes to a file via `LOG_DEVICE`, suppression may need to be `LOG_DEVICE=/dev/null ossh.config.get …` instead.
- **`ossh.config.save.last`'s "duplicate" warn.log.** The dedup branch emits `warn.log "Host '<alias>' already exists in <file> — not appending duplicate"`. On every re-run that's a per-alias warn. Acceptable noise level on this host? If not, suppress at the call site (`ossh.config.save.last "$sshDir/config" 2>/dev/null` or similar) — but that hides legitimate warnings too. Prefer the wrap-with-`ossh.config.get` guard already in the proposed code, which avoids the dedup branch entirely.
- **`touch "$sshDir/config"` permissions.** `mkdir -p $sshDir` (line above) creates the dir without explicit chmod. If `$sshDir` is created with default umask (often 0022 → mode 0755), `touch` works; if the parent process has set a stricter umask, `chmod 700 $sshDir; chmod 600 $sshDir/config` may be required for ssh's strictness checks. Existing code at `user.init` doesn't chmod either — so this isn't a regression, just something to keep an eye on.
- **`ssh-keygen` failure path.** Currently no rc check after `ssh-keygen -t ed25519 -f …`. If keygen fails, the rest of the function continues with a missing key. Out of scope for this plan but worth noting for a future hardening pass.

---

## Files touched (summary)

- Modified: `user` — rewrite of `user.init`'s inner else branch (`user:243–277`).
- Modified: `test/test.ssh.config.woda` — relax IdentityFile assertion to accept templated per-user paths.

No new files, no deletions in this plan. F1/F2 deletion is a follow-up.
