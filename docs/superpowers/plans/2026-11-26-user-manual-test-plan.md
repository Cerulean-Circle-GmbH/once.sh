# `user` Manual Test Plan

**Goal:** Verify every public `user` method by hand on a real host — account, group, SSH identity, backup and legacy paths — without touching a real account or a real `~/.ssh`, and with no leftovers.

**Architecture:** Three safety tiers. **Read-only** checks run anywhere (`usage`, `id`, `list`, `get`, `group.*` reads, SSH reads). **Sandbox** checks point `HOME`, `CONFIG_PATH`, `CONFIG` and `sshDir` at `/tmp/umt-manual`, so `ssh.init`, `authorized.keys.update`, `ssh.backup`/`restore` and `ssh.identity.use` never touch the tester's real files. **Disposable-host** checks create a scratch account `umt-*` and a scratch group `umt-grp-*`; `user create`, `password.set`, `as`, `login`, `oosh.install` and `delete` are only run on a VM/container/laptop you can throw away. One pass per object family: help → inspect → groups → SSH sandbox → account lifecycle → install → delete/guards → negative → cleanup. Every step records the exit code and observed output against an expected result.

**Tech Stack:** `user` (bash/OOSH 4+), `sudo`/root, `test.suite`, tmux (interactive `login` and password prompts), `ssh-keygen`, `getent` (Linux) or `dscl` (macOS), `tree` (optional, for `user.info`).

**Estimated time:** 45–75 min for Tasks 0–5, 8–10; +30–45 min for the account lifecycle (`user create`, `oosh.install`) in Tasks 6–7.

**Source of truth:** the 26 visible methods reported by
`c2 function.completion ./user` and shown by `user usage`. `docs/user.md` is a generated matrix from
2026-10-20 and is **stale** for the 2026-11-17 renamed surface (`user.init` → `user.ssh.init`,
`user.list.groups` → `user.group.list`, `user.in` → `user.ssh.identity.use`, …). Do not use it as the
checklist; use `user usage` and the coverage matrix at the end of this plan.

---

## Rules (read before starting)

1. **Know which tier you are in.**

   | Tier | Tasks | May run on a shared host? | Touches |
   |---|---|---|---|
   | **Read-only** | 1, 2 | yes | nothing |
   | **Sandbox** | 4, 5 | yes | only `/tmp/umt-manual` (own `HOME`, `CONFIG`, `sshDir`) |
   | **Disposable** | 3, 6, 7, 8 | **NO** | real accounts, groups, homes, `/etc/passwd`, `/etc/group`, sudoers |

   Tasks 3 and 6–8 create and delete real local accounts. Run them only on a VM, container or
   personal laptop you can rebuild. Never on a shared dev box, a CI runner you do not own, or a
   machine where another person keeps work in `/home`.

2. **Scratch only.** Every account this plan creates is named `umt-<timestamp>-<random>`; every
   group is `umt-grp-<timestamp>-<random>`. Never pass a real username to `user create`,
   `user password.set`, `user as`, `user login`, `user oosh.install` or `user delete` unless that
   account is the scratch account you created here.

3. **Never run these on a real account:** `user delete`, `user password.set <real-user> …`,
   `user oosh.install <real-user>`, `user as <real-user> <write-command>`, `user login <real-user>`.
   The negative `user delete` guards in Task 8.1 are the only delete calls against non-scratch names
   and they must refuse before running any command.

4. **Snapshot before any disposable task.**

   ```bash
   rm -rf /tmp/umt-manual
   mkdir -p /tmp/umt-manual
   getent passwd | sort > /tmp/umt-manual/passwd.before
   getent group  | sort > /tmp/umt-manual/group.before
   cp -a ~/.ssh "$CONFIG_PATH/user.env" /tmp/umt-manual/ 2>/dev/null
   ```

   macOS:

   ```bash
   dscl . -list /Users  UniqueID        | sort > /tmp/umt-manual/users.before
   dscl . -list /Groups PrimaryGroupID  | sort > /tmp/umt-manual/groups.before
   ```

   Keep the snapshots until Task 10 has compared them. If you had to use sudo to read anything,
   do not leave a world-readable copy in `/tmp`.

5. **The sandbox is not the real config.** For Tier S, use the sandbox on each command rather than
   exporting it globally:

   ```bash
   export SBX=/tmp/umt-manual/sbx
   rm -rf "$SBX"
   mkdir -p "$SBX/home/config" "$SBX/config" "$SBX/ssh" "$SBX/ssh2" "$SBX/emptyhome"
   printf 'export OOSH_MODE="dev"\n' > "$SBX/config/user.env"
   SBX_HOME="$SBX/home"
   SBX_CONFIG_PATH="$SBX/config"
   SBX_CONFIG="$SBX/config/user.env"
   ```

   Run as:

   ```bash
   HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" user <method> …
   ```

   `$SBX/home/config` must exist: `result.save` writes `result.txt` / `error.txt` there. Do not
   export `HOME` globally for Tier D; it would make the scratch account's home the wrong folder.

6. **Interactive methods** (`user login`, password verification via `su`, and `user as` when it
   needs a TTY) run in the tmux lower pane, not in a captured shell.

7. **Log level.** Every command assumes `LOG_LEVEL=3` (the default). Raise to `4`/`5` when you need
   to see what `user` passes to `useradd`/`usermod`/`su`. Strip colour when comparing:

   ```bash
   strip() { sed $'s,\x1b\\[[0-9;]*[a-zA-Z],,g'; }
   ```

   Do **not** pipe oosh test output through `head`/`tail`/`2>&1`; use `test.suite`'s own log level.

8. **PATH.** The commands below use `user` as an installed oosh command. Check `command -v user`;
   if it prints nothing, prefix every command with `./` from the checkout and say so in the report.

9. **Record every step** in the [results table](#results-table). A step without a recorded verdict
   did not happen.

10. **Elevation.** Tier D expects root or passwordless sudo. OOSH normally carries `SUDO="sudo "`
    (or empty when root); check it in Task 0. If you are a non-root user with passwordless sudo and
    `$SUDO` is empty, `export SUDO="sudo "` before the disposable tasks, otherwise `useradd`,
    `usermod`, `userdel` and the `chown` in `user.oosh.install` are attempted unprivileged and fail
    for the wrong reason. Do not run the plan as root on a machine whose accounts you care about.

### Fixtures — choose on your machine (read-only)

```bash
export U_ME="$(id -un)"
export U_OTHER="$(user list | grep -vx "$U_ME" | grep -vx root | grep -v '^_' | head -1)"
export U_GROUP_READ="$(user group.list | grep -Ex 'dev|docker|sudo|wheel|admin|users' | head -1)"
printf 'U_ME=%s\nU_OTHER=%s\nU_GROUP_READ=%s\n' "$U_ME" "$U_OTHER" "$U_GROUP_READ"
```

| Variable | What to pick | Used by |
|---|---|---|
| `U_ME` | the account running the plan | `get`, `id`, guards, `as` self |
| `U_OTHER` | any ordinary account that is not `U_ME` and not `root`; read only | `user get` on another user, `group.member.list` check |
| `U_GROUP_READ` | a group you belong to that exists on this host (`dev`, `docker`, `sudo`, `wheel`, `admin`, `users`) | `group.member.pending` rc checks |

If `U_OTHER` is empty, skip the steps that need a second account and record them as skipped.
Never modify `U_OTHER`: it is a fixture, not a scratch account.

### Scratch names — disposable host only

```bash
export U_NAME="umt-$(date +%s)-$RANDOM"
export U_NAME2="${U_NAME}-b"
export U_PASS='umt-Passw0rd'
export U_PASS2='umt-Passw0rd-2'
export U_GROUP="umt-grp-$(date +%s)-$RANDOM"
export U_GROUP2="${U_GROUP}-b"
export U_GID_GROUP="${U_GROUP}-gid"
export U_UID=1899
export U_GID=1899
export U_HOME="$(user get basehome root)/$U_NAME"
```

Before creating anything, prove the names are free:

```bash
id "$U_NAME"                2>&1; echo "user rc=$?"
id "$U_NAME2"               2>&1; echo "user2 rc=$?"
getent group "$U_GROUP"     2>&1; echo "group rc=$?"
getent group "$U_GROUP2"    2>&1; echo "group2 rc=$?"
getent passwd "$U_UID"      2>&1; echo "uid rc=$?"
getent group "$U_GID"       2>&1; echo "gid rc=$?"
```

Expected: every lookup fails (`rc=1`/`rc=2`) — the names and IDs are unused. If a name or ID is
taken, change the suffix and re-check; never reuse an existing account.

---

## Task 0: Setup and baseline

- [ ] **Step 1: Go to the checkout, set a known log level and find the command**

  ```bash
  cd ~/oosh                     # your Once.sh checkout (dev branch)
  export LOG_LEVEL=3
  command -v user || echo "user not on PATH — use ./user"
  echo "OOSH_DIR=$OOSH_DIR"
  echo "CONFIG_PATH=$CONFIG_PATH"
  echo "CONFIG=$CONFIG"
  echo "CURRENT_SSH_DIR=$CURRENT_SSH_DIR"
  id
  ```

  Expected: the checkout path, `user` resolves (or the explicit fallback note), and `id` prints the
  account you are testing as. Record `U_ME`, the shell's `CONFIG`/`CONFIG_PATH`, and whether
  `CURRENT_SSH_DIR` is already set.

- [ ] **Step 2: Record the host, the user database and the real SSH state**

  ```bash
  uname -a
  bash --version | head -1
  printf 'OOSH_OS=%s OSTYPE=%s SUDO=%s\n' "${OOSH_OS:-}" "$OSTYPE" "${SUDO:-}"
  getent passwd | sort | tee /tmp/umt-manual/passwd.before
  getent group  | sort | tee /tmp/umt-manual/group.before
  user list      | sort | tee /tmp/umt-manual/user-list.before
  ls -la ~/.ssh 2>&1 | tee /tmp/umt-manual/ssh.before
  cp -a ~/.ssh "$CONFIG_PATH/user.env" /tmp/umt-manual/ 2>/dev/null; echo "backup rc=$?"
  ```

  macOS: use `dscl . -list /Users UniqueID` and `dscl . -list /Groups PrimaryGroupID` instead of
  `getent`. Record:
  - whether `SUDO` is set (`sudo `) and whether the caller is root (`id -u` = 0);
  - whether `~/.ssh` exists and what it holds — the read-only steps are allowed to look, never write;
  - the exact `CONFIG` path; Task 4 will write only to the sandbox.

- [ ] **Step 3: Record the automated-suite baseline**

  In the tmux lower pane:

  ```bash
  test.suite run user 1
  test.suite run completion.audit 1
  ```

  Expected: both finish; record the pass/fail counts. `completion.audit` covers method and parameter
  completion for `user`, so completion is **not** re-tested by hand. A pre-existing failure makes a
  later manual failure ambiguous — record it now.

- [ ] **Step 4: Record the install shape**

  ```bash
  user get basehome root
  user get home root
  user get shell root
  ls -ld "$(user get basehome root)/shared/EAMD.ucp" 2>&1
  test -w "$CONFIG_PATH/user.env"; echo "user.env writable rc=$?"
  ```

  Expected: the system user base (`/home`, `/Users`, or `$OOSH_USERS_BASEHOME`); root's home; root's
  shell; the shared tree either listed or absent. **This decides Task 7:** without
  `$(user get basehome root)/shared/EAMD.ucp`, `user oosh.install` is expected to return 1 with an
  INFO line and leave the account alone.

---

## Task 1: Help and usage (read-only, no mutation)

- [ ] **Step 1: No-argument usage**

  ```bash
  user; echo "rc=$?"
  ```

  Expected: `user — user, group, and SSH identity management`, the sectioned help with
  `account`, `inspect`, `groups`, `ssh`, `legacy` in **that order**, a colourised METHOD |
  PARAMETER | DESCRIPTION table, and `Run 'user help <word>' …`; **rc 1** (an invocation with no
  method is a usage error, not a request for help).

  Spot-check that every method in the coverage matrix is present exactly once and no
  `please add a description` line appears.

- [ ] **Step 2: `usage` and filtered help**

  ```bash
  user usage; echo "usage rc=$?"
  user help ssh; echo "ssh rc=$?"
  user help group; echo "group rc=$?"
  user help no_such_word; echo "none rc=$?"
  user help; echo "all rc=$?"
  ```

  Expected:
  - `usage` prints the same grouped table and **rc 0**;
  - `help ssh` is a **flat** table (no section headers) containing `ssh.init`,
    `ssh.identity.*`, `ssh.backup*`, `ssh.restore`, `authorized.keys.update`, and the two `legacy`
    methods whose names contain `ssh`; no `@group` text;
  - `help group` is flat and contains the `group.*` methods;
  - `help no_such_word` prints only the table header and **rc 0**;
  - `help` with no word is grouped like `usage` and rc 0.

- [ ] **Step 3: Hidden methods are callable but absent from help**

  ```bash
  bash -c 'source this; source user; for m in user.start user.usage user.help.group.order; do
    printf "%s=" "$m"; type -t "$m" || true; done'
  user usage | strip | grep -E '^(start|usage|help\.group\.order)( |$)' \
    && echo "LEAKED — finding" || echo "hidden methods absent"
  ```

  Expected: all three are functions and none appears in `user usage`. The hidden methods stay
  callable; that is the contract of the `@hidden` tag.

- [ ] **Step 4: Do not test completion by hand**

  `test.suite run completion.audit 1` in Task 0 already covers method and parameter completion.
  `c2 function.completion ./user` is the inventory, not a functional check; do not use it as one.

---

## Task 2: Inspect (read-only)

- [ ] **Step 1: `id`**

  ```bash
  user id; echo "rc=$?"
  user id -u -n; echo "rc=$?"
  user id -g; echo "rc=$?"
  user id -Z 2>&1; echo "bad-option rc=$?"
  ```

  Expected: the full `id` line (with groups) for no arguments; the login name for `-u -n`; the
  primary gid for `-g`; `id`'s own error and a non-zero rc for the invalid option. `user.id` is a
  pass-through to `id`, so the message is the platform's, not oosh's.

- [ ] **Step 2: `list` and `list.all`**

  ```bash
  user list; echo "list rc=$?"
  user list.all; echo "all rc=$?"
  user list | wc -l
  user list.all | wc -l
  ```

  Expected: `list.all` is every local account (`compgen -u`), `list` is the same list filtered to
  drop names beginning with `_` (the macOS system-account convention). On Linux, names such as
  `daemon`, `bin`, `sys`, `nobody` **remain** in `list` — the docstring says “system accounts
  (leading _) left out”, which is only the macOS shape. Record this as a docs/description finding,
  not a functional failure. `U_OTHER` must appear in both.

- [ ] **Step 3: `info`**

  ```bash
  user info; echo "rc=$?"
  ```

  Expected at `LOG_LEVEL=3`: `You started`, the script path, `Current user: $U_ME`,
  `Home directory: $HOME`, then `tree -L 3 ~/.ssh` (or `ls` output if `tree` is not installed).
  If `tree` is missing, record the shell's “command not found” and the rc — `user.info` has no
  fallback.

- [ ] **Step 4: `get` — every supported property**

  ```bash
  for p in home basehome shell info name; do
    printf '%s: ' "$p"
    user get "$p" "$U_ME"; echo "  rc=$?"
  done
  user get home "$U_OTHER" 2>&1; echo "other rc=$?"
  ```

  Expected:
  - `home` → the account's home path;
  - `basehome` → the parent of an ordinary user's home (`/home` on Linux, `/Users` on macOS);
    for `root` it is the **system** base, not the parent of `developking`'s home;
  - `shell` → the login shell from the user database (`/bin/bash`, `/usr/bin/bash`, …);
  - `info` → the full passwd line on Linux, the `dscl . -read /Users/<name>` record on macOS;
  - `name` → the login name;
  - `U_OTHER` → that user's home, owned by them, never modified.

- [ ] **Step 5: `get` — missing and unknown arguments**

  ```bash
  user get; echo "noargs rc=$?"
  user get home; echo "default-user rc=$?"
  user get bogus "$U_ME"; echo "unknown-prop rc=$?"
  user get home no_such_user_umt; echo "unknown-user rc=$?"
  user get shell no_such_user_umt; echo "unknown-shell rc=$?"
  user get name no_such_user_umt; echo "unknown-name rc=$?"
  user get basehome no_such_user_umt; echo "unknown-basehome rc=$?"
  ```

  Expected / record (these are the known sharp edges):
  - no arguments → **rc 0**, `IMPORTANT> private.get..linux.unknown is not supported` at level 3;
  - `user get home` → the **caller's** home (the username defaults to `$USER`), rc 0;
  - unknown property → **rc 0**, only the IMPORTANT “is not supported” line;
  - unknown user → rc 0 with empty output for `home`/`shell`, `name` prints the **caller's** name
    (it ignores its argument), and `basehome` prints `/`;
  - record all of these against the docstring, which promises “prints one property of `<username>`”
    and implies a failure for an unsupported property.

- [ ] **Step 6: `$OOSH_USERS_BASEHOME` override**

  ```bash
  OOSH_USERS_BASEHOME=/tmp/umt-base user get basehome root; echo "rc=$?"
  ```

  Expected: `/tmp/umt-base` (the override wins for root), rc 0. Repeat for an ordinary user; the
  override must **not** change the parent-of-home answer for a non-root user.

- [ ] **Step 7: Group reads**

  ```bash
  user group.list; echo "list rc=$?"
  user group.list | grep -x "$U_GROUP_READ"; echo "known rc=$?"
  user group.check "$U_GROUP_READ"; echo "check rc=$?"
  user group.check no_such_group_umt; echo "bad check rc=$?"
  user group.member.list "$U_GROUP_READ"; echo "members rc=$?"
  user group.member.list; echo "noarg rc=$?"
  user group.member.list no_such_group_umt; echo "bad group rc=$?"
  user group.member.pending "$U_GROUP_READ" "$U_ME"; echo "pending rc=$?"
  user group.member.pending no_such_group_umt "$U_ME"; echo "bad pending rc=$?"
  ```

  Expected:
  - `group.list` prints every group (`compgen -g`), rc 0;
  - `group.check` → `SUCCESS> group exists: …`, rc 0; unknown → `WARN> group does NOT exist`,
    rc 1;
  - `member.list` prints one user per line (or `no users in group …`) and rc 0; no argument → `ERROR> usage:
    user.group.member.list <groupName>` + rc 1; unknown → `ERROR> no such group: …` + rc 1;
  - `member.pending` is rc 0 only when the named user is in the group per the **database** and the
    caller's **current process** does not have it; otherwise rc 1. `U_ME` is normally already in
    `U_GROUP_READ`, so expect rc 1 there. Record the semantics rather than assuming one value.

- [ ] **Step 8: SSH reads**

  ```bash
  user ssh.identity.current; echo "current rc=$?"
  CURRENT_SSH_DIR=/tmp/umt-manual/none user ssh.identity.current; echo "override rc=$?"
  user ssh.identity.list; echo "ids rc=$?"
  user ssh.identity.list /tmp/umt-manual/none; echo "no-ids rc=$?"
  user ssh.backup.list; echo "backups rc=$?"
  user ssh.backup.legacy.status; echo "legacy rc=$?"
  user ssh.backup.legacy.status /tmp/umt-manual/nohome; echo "bad home rc=$?"
  ```

  Expected:
  - `identity.current` prints `$CURRENT_SSH_DIR` when set, else `$HOME/.ssh`. A cold start that
    sources `user.env` uses the persisted `CURRENT_SSH_DIR`, which can win over an environment
    override; record which path you got and why;
  - `identity.list` lists `$sshDir/ids`; with no `ids/` directory, `ls` writes “cannot access …”
    and the method returns **rc 2** — record it;
  - `backup.list` lists `$HOME/.ssh.backups/*/` oldest first, or prints
    `no archives: … does not exist` / `no archives under …` and returns 0;
  - `legacy.status` prints `OK: no legacy ssh.* backup directories in <home>` and rc 0 when clean;
    a missing home is an `INVALID`/error and **rc 2**.

---

## Task 3: Groups (disposable host only)

Creates one scratch group, exercises every group method, and leaves it for Task 6 (where the
scratch user joins it). Delete it in Task 8/10 even if you skip Task 6.

- [ ] **Step 1: Prove the scratch group name is free**

  ```bash
  getent group "$U_GROUP" 2>&1; echo "rc=$?"
  user group.check "$U_GROUP"; echo "check rc=$?"
  ```

  Expected: the lookup fails and `group.check` returns 1 (`WARN> group does NOT exist`).

- [ ] **Step 2: Create it with `group.add`**

  ```bash
  user group.add "$U_GROUP"; echo "create rc=$?"
  user group.check "$U_GROUP"; echo "check rc=$?"
  user group.list | grep -x "$U_GROUP"; echo "listed rc=$?"
  ```

  Expected: `console.log`'s `creating groupName: $U_GROUP`, rc 0; `group.check` now succeeds and the
  name appears in `group.list`. On Linux verify with `getent group "$U_GROUP"`; on macOS with
  `dscl . -read /Groups/"$U_GROUP"`.

- [ ] **Step 3: Idempotent second call — no sudo prompt**

  ```bash
  time user group.add "$U_GROUP"; echo "second rc=$?"
  ```

  Expected: `group $U_GROUP is there` and rc 0. No membership command runs, and the call must not
  ask for a sudo password. (The automated test T-USER-GROUP-ADD-IDEMPOTENT pins this; here you are
  checking the real host's behaviour and timing.)

- [ ] **Step 4: Read it back**

  ```bash
  user group.member.list "$U_GROUP"; echo "members rc=$?"
  user group.member.pending "$U_GROUP" "$U_ME"; echo "pending self rc=$?"
  ```

  Expected: `no users in group $U_GROUP` and rc 0; `member.pending` rc 1 because the caller is not
  a member. `user group.add "$U_GROUP"` with no username creates the group only.

- [ ] **Step 5: Leave the group in place**

  Do **not** delete it yet. Task 6 adds the scratch user; Task 8.5 and Task 10 remove it. If you are
  not doing Task 6, jump to the cleanup in Task 8.5 now.

---

## Task 4: SSH sandbox — init, identities, authorized keys (isolated)

Nothing here touches the real `~/.ssh` or the real `user.env`. All commands carry the sandbox
`HOME`/`CONFIG_PATH`/`CONFIG`.

- [ ] **Step 1: Create the sandbox**

  ```bash
  export SBX=/tmp/umt-manual/sbx
  rm -rf "$SBX"
  mkdir -p "$SBX/home/config" "$SBX/config" "$SBX/ssh" "$SBX/ssh2" "$SBX/emptyhome"
  printf 'export OOSH_MODE="dev"\n' > "$SBX/config/user.env"
  SBX_HOME="$SBX/home"; SBX_CONFIG_PATH="$SBX/config"; SBX_CONFIG="$SBX/config/user.env"
  env | grep -E '^(OOSH_DIR|OOSH_MODE)=' | sort
  ```

  Expected: an empty `$SBX/ssh`, a writable `$SBX/config/user.env`, and `$SBX/home/config` present
  (so `result.save` can write). Do not export `HOME` globally.

- [ ] **Step 2: `ssh.init` on an empty directory**

  ```bash
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.init "$SBX/ssh"; echo "rc=$?"
  ```

  Expected:
  - `ssh does not exist for <user> in <SBX>/ssh` (from `ossh.isInstalled log`);
  - `ssh-keygen` chatter for an **ed25519** key;
  - the computed key name printed (e.g. `<user>.<host>`);
  - rc 0.

  Verify:

  ```bash
  find "$SBX/ssh" -maxdepth 2 -printf '%M %p\n' | sort
  grep -c '^Host WODA' "$SBX/ssh/config"                 # 3
  grep -E '^Host WODA\.(test|dev|dev\.root)$' "$SBX/ssh/config"
  grep -F 'IdentityFile ~/.ssh/ids/ssh.developking/id_rsa' "$SBX/ssh/config"
  grep -F 'IdentityFile ~/.ssh/id_ed25519' "$SBX/ssh/config"
  stat -c '%a %n' "$SBX/ssh/config" "$SBX/ssh/id_ed25519" 2>/dev/null \
    || stat -f '%Lp %N' "$SBX/ssh/config" "$SBX/ssh/id_ed25519"
  ```

  Expected: `id_ed25519` 600, `id_ed25519.pub` 644, `private_key/<name>.private_key`,
  `public_keys/<name>.public_key`, and a `config` with **exactly three** WODA blocks (`WODA.test`,
  `WODA.dev.root`, `WODA.dev`) and **600** permissions. `WODA.test`/`WODA.dev` use the developking
  identity; `WODA.dev.root` uses the user's own `id_ed25519`; the `IdentityFile` paths are portable
  `~/.ssh/...`, never an absolute `/home/<user>/...`.

  Repeat the config creation under a permissive umask, the condition the 600 fix exists for:

  ```bash
  cp -a "$SBX/ssh" "$SBX/ssh-umask"
  rm -f "$SBX/ssh-umask/config"
  ( umask 002
    HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
      user ssh.init "$SBX/ssh-umask" ) >/dev/null 2>&1
  stat -c '%a %n' "$SBX/ssh-umask/config" 2>/dev/null \
    || stat -f '%Lp %N' "$SBX/ssh-umask/config"
  ```

  Expected: **600**, not 664. `ssh` refuses a group-writable config unless the group is the user
  alone; this is the `T-USER-INIT-CONFIG-600` regression guard.

- [ ] **Step 3: Idempotent second `ssh.init`**

  ```bash
  before=$(cksum < "$SBX/ssh/id_ed25519")
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.init "$SBX/ssh"; echo "second rc=$?"
  after=$(cksum < "$SBX/ssh/id_ed25519")
  [ "$before" = "$after" ] && echo "key unchanged" || echo "KEY CHANGED — finding"
  grep -c '^Host WODA' "$SBX/ssh/config"
  ```

  Expected: `.ssh exists` plus a `tree`/`ls` listing, the key checksum unchanged, still **3** WODA
  blocks (append-if-missing), rc 0.

  Then test the “existing key, missing WODA” path, which the unconditional ensure block exists for:

  ```bash
  cp -a "$SBX/ssh" "$SBX/ssh-nowoda"
  printf 'Host other\n User somebody\n' > "$SBX/ssh-nowoda/config"
  before=$(cksum < "$SBX/ssh-nowoda/id_ed25519")
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.init "$SBX/ssh-nowoda"; echo "nowoda rc=$?"
  grep -c '^Host WODA' "$SBX/ssh-nowoda/config"     # 3
  grep -q '^Host other$' "$SBX/ssh-nowoda/config" && echo "existing Host kept"
  [ "$before" = "$(cksum < "$SBX/ssh-nowoda/id_ed25519")" ] && echo "key unchanged"
  ```

  Expected: the three WODA blocks are appended, the pre-existing `Host other` block survives, the
  key is unchanged, rc 0. This is the path users whose `.ssh` was created by `ssh-keygen` on first
  login depend on.

- [ ] **Step 4: `ssh.identity.list` before and after `ids/` exists**

  ```bash
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.identity.list "$SBX/ssh"; echo "empty ids rc=$?"
  mkdir -p "$SBX/ssh/ids/ssh.developking" "$SBX/ssh/ids/ssh.outeruser"
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.identity.list "$SBX/ssh"; echo "ids rc=$?"
  ```

  Expected: the first prints `ls: cannot access '…/ids'` and returns **rc 2** (record: the method
  does not turn a missing `ids/` into a friendly answer); the second prints `ssh.developking` and
  `ssh.outeruser`, rc 0.

- [ ] **Step 5: `ssh.identity.current` and `ssh.identity.use`**

  ```bash
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.identity.current; echo "current rc=$?"

  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.identity.use; echo "noarg rc=$?"

  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.identity.use demo "$SBX/ssh"; echo "demo rc=$?"
  grep 'CURRENT_SSH_DIR' "$SBX_CONFIG"

  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.identity.use main "$SBX/ssh"; echo "main rc=$?"
  grep 'CURRENT_SSH_DIR' "$SBX_CONFIG"

  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.identity.use "$SBX/ssh/ids/ssh.outeruser" "$SBX/ssh"; echo "abs rc=$?"
  grep 'CURRENT_SSH_DIR' "$SBX_CONFIG"
  ```

  Expected:
  - `current` prints `$HOME/.ssh` when `CURRENT_SSH_DIR` is unset; with an env override it prints
    that path;
  - no argument prints `IMPORTANT> current sshId is: …` and rc 0;
  - `demo` writes `CURRENT_SSH_DIR="…/ssh/ids/demo"` and prints
    `SUCCESS> new sshId is: …/ssh/ids/demo`; it does **not** create the directory;
  - `main` resets to the base `…/ssh`;
  - an absolute path is used verbatim.

  Persistence check (a login shell reads `user.env`):

  ```bash
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" env -u CONFIG \
    user ssh.identity.current; echo "fresh rc=$?"
  ```

  Expected: the persisted `CURRENT_SSH_DIR`. Record the known caveat: a single `./user` process that
  inherits `CONFIG` from the parent environment may print `$HOME/.ssh` instead of re-sourcing
  `user.env`; a login shell and a shell where `user.env` was sourced show the persisted value.

  Record the `~/` form as a finding, do not rely on it:

  ```bash
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.identity.use '~/foo' "$SBX/ssh"; echo "tilde rc=$?"
  grep 'CURRENT_SSH_DIR' "$SBX_CONFIG"
  ```

  Observed on the dev box: the literal `~/foo` becomes `…/ssh/ids/~/foo`, not `$HOME/foo` — a
  likely bug in the `/*|~/*` branch. Record it; use an absolute path for the positive test.

- [ ] **Step 6: `authorized.keys.update` — no private key is rc 1 and leaves the file alone**

  ```bash
  mkdir -p "$SBX/nokey/public_keys"
  printf 'ssh-ed25519 AAAANOKEY nokey@here\n' > "$SBX/nokey/public_keys/a.public_key"
  printf 'ssh-ed25519 AAAAOLD old@here\n'      > "$SBX/nokey/authorized_keys"
  cp "$SBX/nokey/authorized_keys" "$SBX/nokey/authorized_keys.before"

  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user authorized.keys.update "$SBX/nokey"; echo "rc=$?"
  cmp -s "$SBX/nokey/authorized_keys" "$SBX/nokey/authorized_keys.before" \
    && echo "untouched" || echo "CHANGED — finding"
  ```

  Expected: **rc 1**, the file byte-for-byte unchanged, and no `.new`/`.bak` left. This is the
  `ossh key.push` fallback contract: no private key means no ssh is set up in that directory.

- [ ] **Step 7: `authorized.keys.update` — adopt, rebuild, do not resurrect revoked keys**

  ```bash
  cp -a "$SBX/ssh" "$SBX/sshkeys"
  printf 'ssh-ed25519 AAAAKEYA owner@here\n' > "$SBX/sshkeys/public_keys/ssh.owner.public_key"
  printf 'ssh-ed25519 AAAAKEYR revoked@here\n' > "$SBX/sshkeys/deactive.public_keys/old.public_key" 2>/dev/null \
    || { mkdir -p "$SBX/sshkeys/deactive.public_keys"; printf 'ssh-ed25519 AAAAKEYR revoked@here\n' > "$SBX/sshkeys/deactive.public_keys/old.public_key"; }
  printf '%s\n' \
    'ssh-ed25519 AAAAKEYA owner@here' \
    '# a comment line' \
    '' \
    'ssh-rsa AAAAKEYB hand-added@here' \
    'ssh-ed25519 AAAAKEYR revoked@here' \
    'from="10.0.0.1" ssh-ed25519 AAAAKEYC' > "$SBX/sshkeys/authorized_keys"

  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user authorized.keys.update "$SBX/sshkeys"; echo "rc=$?"

  cat "$SBX/sshkeys/authorized_keys"
  ls -l "$SBX/sshkeys/public_keys"
  find "$SBX/sshkeys" -maxdepth 1 \( -name '*.new' -o -name '*.bak' \) -print
  ```

  Expected:
  - rc 0;
  - `authorized_keys` contains `AAAAKEYA`, the hand-added `AAAAKEYB`, and `AAAAKEYC` (with its
    `from="10.0.0.1"` options preserved);
  - `AAAAKEYR` is **absent** (it lives in `deactive.public_keys/`);
  - `AAAAKEYB` and `AAAAKEYC` each got a file under `public_keys/` named
    `adopted.<comment>.public_key` (or `adopted.key.public_key` when the line has no comment);
  - every `public_keys/*` file is public data, **644**;
  - nothing named `*.new` or `*.bak` remains; `authorized_keys` is 600 and the directory 700.

  Run it a second time and re-check the same conditions: the adopted keys must not be adopted
  again, the revoked key must not come back, and no duplicate lines may appear.

- [ ] **Step 8: A key file without its last newline**

  ```bash
  cp -a "$SBX/sshkeys" "$SBX/sshkeys-nonl"
  printf '%s' 'ssh-ed25519 AAAANONL nonl@here' > "$SBX/sshkeys-nonl/public_keys/z.public_key"
  printf '%s\n' 'ssh-ed25519 AAAAKEYA owner@here' 'ssh-ed25519 AAAANONL nonl@here' \
    > "$SBX/sshkeys-nonl/authorized_keys"
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user authorized.keys.update "$SBX/sshkeys-nonl" >/dev/null 2>&1
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user authorized.keys.update "$SBX/sshkeys-nonl" >/dev/null 2>&1
  grep -c AAAANONL "$SBX/sshkeys-nonl/authorized_keys"
  ls "$SBX/sshkeys-nonl/public_keys" | grep '^adopted\.' && echo "ADOPTED — finding" || echo "not adopted"
  ```

  Expected: the non-newline key appears exactly **once** and is **not** adopted again. This is the
  `cat public_keys/* | while read` regression guard.

---

## Task 5: SSH sandbox — backup, list, restore, legacy (isolated)

All archives land under `$SBX_HOME/.ssh.backups`, never in the real home and never in the current
working directory.

- [ ] **Step 1: `ssh.backup` — first archive**

  ```bash
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.backup manual "$SBX/sshkeys"; echo "rc=$?"
  ls -1d "$SBX_HOME"/.ssh.backups/*/
  ```

  Expected: one path `<SBX_HOME>/.ssh.backups/<UTC timestamp>-manual`, rc 0. The path is printed on
  stdout even at low log levels.

- [ ] **Step 2: Archive shape — contents, not a nested copy**

  ```bash
  archive=$(ls -1d "$SBX_HOME"/.ssh.backups/*-manual/ | tail -1)
  find "$archive" -maxdepth 1 -printf '%M %f\n' | sort
  test -e "$archive/.ssh" && echo "NESTED — finding" || echo "contents at top level"
  stat -c '%a %n' "$archive" 2>/dev/null || stat -f '%Lp %N' "$archive"
  ```

  Expected: the archive contains `id_ed25519`, `config`, `public_keys/`, … directly (no `.ssh`
  subdirectory), and the archive directory is 700. This is the “never nest, never cwd-relative”
  contract.

  Prove it never writes to the current directory:

  ```bash
  mkdir -p /tmp/umt-manual/cwdtest
  ( cd /tmp/umt-manual/cwdtest
    HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
      user ssh.backup cwd "$SBX/sshkeys" >/dev/null )
  find /tmp/umt-manual/cwdtest -mindepth 1 -print
  ```

  Expected: no output. The archive is under `$SBX_HOME/.ssh.backups`, not in the cwd. This is the
  shape of the old `cp -R $sshDir ssh.$name` bug that left root-owned copies in a user's home.

- [ ] **Step 3: Label sanitising and missing source**

  ```bash
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.backup 'a/b c' "$SBX/sshkeys"; echo "label rc=$?"
  ls -1d "$SBX_HOME"/.ssh.backups/*-a-b-c/ && echo "sanitised"

  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.backup manual "$SBX/no-such-ssh"; echo "missing rc=$?"
  ```

  Expected: the label becomes `a-b-c` (only `[A-Za-z0-9._-]` survives); the missing directory gives
  `ERROR> user.ssh.backup: nothing to archive — … does not exist` and **rc 1**.

- [ ] **Step 4: Two archives do not overwrite each other**

  ```bash
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.backup collision "$SBX/sshkeys" >/dev/null
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.backup collision "$SBX/sshkeys" >/dev/null
  ls -1d "$SBX_HOME"/.ssh.backups/*-collision*/ | wc -l
  ```

  Expected: 2. If the two runs land in different seconds, both names differ; if in the same second,
  the second gets `.1`. Either way no archive is overwritten.

- [ ] **Step 5: `ssh.backup.list`**

  ```bash
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.backup.list; echo "rc=$?"
  HOME="$SBX/emptyhome" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.backup.list; echo "empty rc=$?"
  mkdir -p "$SBX/emptyhome/.ssh.backups"
  HOME="$SBX/emptyhome" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.backup.list; echo "empty-root rc=$?"
  ```

  Expected: archives oldest first (lexical UTC timestamp), rc 0; missing root prints
  `no archives: … does not exist`, rc 0; empty root prints `no archives under …`, rc 0.

- [ ] **Step 6: `ssh.restore latest`**

  ```bash
  printf 'marker\n' > "$SBX/sshkeys/MARKER"
  keep=$(HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.backup keep "$SBX/sshkeys")
  echo "keep=$keep"
  rm -f "$SBX/sshkeys/MARKER"
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.restore "$keep" "$SBX/sshkeys"; echo "explicit rc=$?"
  cat "$SBX/sshkeys/MARKER" 2>/dev/null || echo "MARKER MISSING — finding"
  ls -1d "$SBX_HOME"/.ssh.backups/*-pre-restore/ | tail -1
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.restore latest "$SBX/sshkeys"; echo "latest rc=$?"
  ```

  Expected: the explicit `keep` archive restores the marker, rc 0, and a new
  `*-pre-restore` archive holds the state that was replaced. `restore latest` then picks the
  lexically newest archive and also rc 0. Restore archives before swapping in both cases. (Restore
  the *explicit* archive for the marker assertion: `latest` may pick a different archive if several
  backups were made in the same second.)

- [ ] **Step 7: Exact archive, absolute archive, and unknown archive**

  ```bash
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.restore '20260101T000000Z-nope' "$SBX/sshkeys"; echo "unknown rc=$?"
  cp "$SBX/sshkeys/MARKER" "$SBX/sshkeys/MARKER.before" 2>/dev/null
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.restore "$(ls -1d "$SBX_HOME"/.ssh.backups/*-keep/ | tail -1)" "$SBX/sshkeys"; echo "absolute rc=$?"
  ```

  Expected: the unknown name gives `ERROR> user.ssh.restore: no such archive: … — <sshDir> is
  untouched` and **rc 1**; an absolute archive path restores and rc 0. After both, the target still
  exists and is 700.

- [ ] **Step 8: `ssh.restore` with no archives**

  ```bash
  HOME="$SBX/emptyhome" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.restore latest "$SBX/sshkeys"; echo "rc=$?"
  ```

  Expected: `no such archive: none — <sshDir> is untouched`, rc 1; the target is unchanged.

- [ ] **Step 9: Legacy `ssh.*` directories — status and migrate**

  ```bash
  HOME="$SBX_HOME" user ssh.backup.legacy.status "$SBX_HOME"; echo "clean rc=$?"
  mkdir -p "$SBX_HOME/ssh.original"
  HOME="$SBX_HOME" user ssh.backup.legacy.status "$SBX_HOME"; echo "found rc=$?"
  HOME="$SBX_HOME" user ssh.backup.legacy.migrate "$SBX_HOME"; echo "migrate rc=$?"
  find "$SBX_HOME/.ssh.backups/legacy" -maxdepth 1 -type d | sort
  HOME="$SBX_HOME" user ssh.backup.legacy.status "$SBX_HOME"; echo "after rc=$?"
  HOME="$SBX_HOME" user ssh.backup.legacy.migrate "$SBX_HOME"; echo "again rc=$?"
  HOME="$SBX_HOME" user ssh.backup.legacy.status "$SBX_HOME/does-not-exist"; echo "bad home rc=$?"
  ```

  Expected:
  - clean status: `OK: no legacy ssh.* backup directories in …`, rc 0;
  - found: `ERROR> … N legacy ssh.* director(ies) in …`, a `path owner=<user>` line, then
    `INVALID: N legacy …`, **rc 1** — it reports without destroying;
  - migrate: `moved … -> …/.ssh.backups/legacy/ssh.original`, rc 0; the directory is under
    `legacy/`; status is clean afterwards;
  - a second migrate: `moved 0 …`, rc 0;
  - missing home: `INVALID: no such directory`, rc 2.

  Do **not** point this at a real home unless the legacy directories really are yours; it moves
  private keys. The sandbox is the test.

- [ ] **Step 10: Verify the real SSH state was never touched**

  ```bash
  diff -r ~/.ssh /tmp/umt-manual/.ssh 2>/dev/null && echo "real ssh unchanged"
  # or: ls -la ~/.ssh and compare with /tmp/umt-manual/ssh.before
  ```

  Expected: no difference from Task 0. If the real `~/.ssh` changed, stop and restore from
  `/tmp/umt-manual/.ssh` before continuing.

---

## Task 6: Account lifecycle — create, password, as, login (disposable host only)

Run only on a disposable host. The scratch account's default password is its username unless you
pass `password`, so pass an explicit one. `user create` also adds the account to the platform's
sudoer group and `dev`, and auto-runs `user.oosh.install` for it — that is the method's contract.

- [ ] **Step 1: Missing username**

  ```bash
  user create; echo "rc=$?"
  ```

  Expected: `ERROR> no username was specified`, rc 1; nothing created.

- [ ] **Step 2: Create the scratch account**

  ```bash
  user create "$U_NAME" password "$U_PASS"; echo "create rc=$?"
  id "$U_NAME"; echo "id rc=$?"
  getent passwd "$U_NAME"
  user get home "$U_NAME"
  user get shell "$U_NAME"
  id -nG "$U_NAME"
  ls -ld "$U_HOME" "$U_HOME/.bashrc"
  readlink "$U_HOME/oosh" "$U_HOME/config" 2>/dev/null
  ```

  Expected:
  - rc 0 (the function returns 0 even when `user.oosh.install` soft-fails);
  - the account exists, has `$U_HOME` with the expected owner, and `/bin/bash` (or the brew bash on
    macOS) as its shell;
  - the password was set (verify in Step 5);
  - the account is in the platform sudoer group (`sudo`, `wheel` or `admin`) and in `dev` when that
    group exists;
  - `~/.bashrc` is the oosh template; `~/config` and `~/oosh` are symlinks **if** the shared tree
    exists (Task 0 Step 4); otherwise `user.oosh.install` prints the missing-tree INFO and the
    symlinks are absent — that is the documented soft-fail, record which happened;
  - the output names the branch being installed and may warn about node/npm; account creation still
    succeeded.

- [ ] **Step 3: Duplicate create — record, do not trust the rc**

  ```bash
  before=$(getent passwd "$U_NAME")
  user create "$U_NAME" password "$U_PASS"; echo "duplicate rc=$?"
  after=$(getent passwd "$U_NAME")
  [ "$before" = "$after" ] && echo "same account" || echo "ACCOUNT CHANGED"
  ```

  Expected: `useradd` fails because the user exists, but `user.create` does not check that rc; it
  proceeds to `password.set`, the group adds and `oosh.install`, and can still return 0. Record the
  exact output and rc. This is a likely finding: a duplicate create silently “succeeds” and resets
  the password.

- [ ] **Step 4: Explicit password is set (verify in the tmux pane)**

  On Linux:

  ```bash
  sudo passwd -S "$U_NAME"
  ```

  On macOS:

  ```bash
  sudo dscl . -read "/Users/$U_NAME" AuthenticationAuthority
  ```

  Expected: Linux `P` (usable password) or the platform's “password set” state; macOS an
  `AuthenticationAuthority` entry. Then verify the login itself in the tmux lower pane:

  ```bash
  su - "$U_NAME"
  ```

  Type `$U_PASS`; expect the scratch shell, `id -un` = `$U_NAME`, `pwd` = `$U_HOME`; `exit`.

- [ ] **Step 5: Reset, empty no-op, missing username**

  ```bash
  user password.set "$U_NAME" "$U_PASS2"; echo "reset rc=$?"
  user password.set "$U_NAME" "";          echo "empty rc=$?"
  user password.set;                        echo "noarg rc=$?"
  ```

  Expected: reset rc 0 (verify with `su` using `$U_PASS2`); empty password rc 0 and **no change** —
  the account still authenticates with the previous password, and there is no `chpasswd`/`dscl`
  call; no username prints `ERROR> no username was specified` and rc 1.

  If the account is the one you created, reseting and restoring is safe. Never do this to a real
  account.

- [ ] **Step 6: `user as`**

  ```bash
  user as "$U_NAME" id -un; echo "as rc=$?"
  user as "$U_NAME" sh -c 'echo HOME=$HOME; echo PWD=$(pwd); id -un'; echo "env rc=$?"
  user as "$U_ME" id -un; echo "self rc=$?"
  user as; echo "noarg rc=$?"
  user as "$U_NAME" no_such_command_umt; echo "bad cmd rc=$?"
  ```

  Expected:
  - the target's login name; the target runs the command;
  - no arguments → `ERROR> usage: user as <username> <command...>`, rc 1;
  - a missing command gives the shell's 127 (or the wrapper's failure), not a half-switch;
  - **record the environment**: `private.as.user` prefers `runuser -u` when the caller is root,
    and `runuser` does not reset `HOME`; `sudo -H -u` does. `HOME` may therefore be the caller's.
    That is a behavioural finding for `user as`, not a test failure, unless the documented intent
    says otherwise.

- [ ] **Step 7: `user login` (interactive, tmux lower pane)**

  ```bash
  user login "$U_NAME"
  ```

  Expected: `su -` asks for the target password (unless you are root); the shell starts in
  `$U_HOME`; `id -un` is `$U_NAME`; `echo $HOME` is the target home; `pwd` is the target home; the
  environment is clean (`env | sort` does not contain the caller's `OOSH_DIR`, `CONFIG_PATH`,
  `OOSH_MODE` or anchor paths); `echo $TERM` is the caller's terminal type, and if the caller's
  `TERM` was empty/`dumb` it is `xterm-256color` (the one variable `env -i` lets through). `exit`.

  A non-interactive `su` from a captured shell cannot test this; use tmux.

- [ ] **Step 8: Add the scratch user to the scratch group**

  ```bash
  user group.add "$U_GROUP" "$U_NAME"; echo "add rc=$?"
  user group.member.list "$U_GROUP"; echo "members rc=$?"
  user group.member.pending "$U_GROUP" "$U_NAME"; echo "pending rc=$?"
  user group.add "$U_GROUP" "$U_NAME"; echo "second rc=$?"
  ```

  Expected: first add rc 0 and a `… added to …` result; `member.list` includes `$U_NAME`; `pending`
  rc 0 (the named user is in the database while the caller's process is not in the group); the
  second add is idempotent, rc 0, no sudo prompt. This is the add-a-user branch `user.group.add`
  did **not** get in Task 3.

- [ ] **Step 9: Custom `uid`/`gid` (optional, still disposable)**

  Choose a free gid and make a group for it first; `useradd -g <gid>` requires an existing group:

  ```bash
  sudo groupadd -g "$U_GID" "$U_GID_GROUP"; echo "group rc=$?"
  user create "$U_NAME2" password "$U_PASS" uid "$U_UID" gid "$U_GID"; echo "create rc=$?"
  id "$U_NAME2"
  user delete "$U_NAME2"; echo "delete rc=$?"
  sudo groupdel "$U_GID_GROUP"; echo "groupdel rc=$?"
  ```

  Expected: the second account has uid `$U_UID` and gid `$U_GID`; deletion removes it and the home;
  the group is removed only after the user is gone.

  Then test the missing-gid edge on a **fresh** scratch name, and record rather than retry:

  ```bash
  user create "${U_NAME}-nogid" password "$U_PASS" uid "$((U_UID + 1))"; echo "nogid rc=$?"
  id "${U_NAME}-nogid" 2>&1; echo "id rc=$?"
  ```

  Expected: the implementation expands to `useradd … -u<uid> -g -s /bin/bash`, where `-g` consumes
  the next token; the account may not be created, or may be created with an unintended group.
  Record the exact command behaviour and clean up anything that was created. This is a likely
  finding: `uid` without `gid` is not guarded.

---

## Task 7: `user oosh.install` for the scratch account (disposable, optional)

Requires root (or `$SUDO`) and, for the success path, the shared tree from Task 0 Step 4. It writes
only inside the scratch home (plus the scratch user's own git config and the canonical `~/.ssh`
layout under that home). It is the per-user half of an oosh install, minus SSH.

- [ ] **Step 1: Missing username**

  ```bash
  user oosh.install; echo "rc=$?"
  ```

  Expected: `ERROR> no username was specified`, rc 1.

- [ ] **Step 2: Prepare a pre-existing `~/.ssh` so the backup-first path is exercised**

  ```bash
  mkdir -p "$U_HOME/.ssh"
  printf 'marker\n' > "$U_HOME/.ssh/marker"
  sudo chown -R "$U_NAME:" "$U_HOME/.ssh"
  ```

  Expected: the scratch home has a marker file. `user.oosh.install` must archive it as
  `pre-oosh-install` before `user init` and `osshLayout build` (the 2026-10-09 incident guard).

- [ ] **Step 3: Install from `dev`**

  ```bash
  user oosh.install "$U_NAME" dev; echo "rc=$?"
  readlink "$U_HOME/oosh"
  readlink "$U_HOME/config"
  ls -l "$U_HOME/.bashrc"
  ls -1d "$U_HOME"/.ssh.backups/*pre-oosh-install* 2>/dev/null
  grep -c '^Host WODA' "$U_HOME/.ssh/config" 2>/dev/null
  ls "$U_HOME/.ssh/ids" 2>/dev/null
  id -nG "$U_NAME"
  ```

  Expected when the shared tree exists:
  - `Installing oosh for '$U_NAME' from branch 'dev' (shared folder model)`, then success;
  - `~/oosh` → `<basehome>/shared/…/Once.sh/dev`, `~/config` → the shared config;
  - `~/.bashrc` is the oosh template;
  - `~/.ssh.backups/<UTC>-pre-oosh-install` exists and holds the marker;
  - the WODA aliases exist in `~/.ssh/config` (3 blocks) and `~/.ssh/ids/` has the canonical
    identities;
  - the user is in `dev`; node/npm setup is a warning at worst;
  - rc 0.

  Expected when the shared tree is missing:
  - `INFO> user.oosh.install: shared tree missing at <base>/shared — skipping '$U_NAME' …`;
  - **rc 1** and the account untouched, no symlinks created. Record this as the expected soft-fail
    for a host that has not run `ossh install`.

- [ ] **Step 4: Idempotent second install**

  ```bash
  user oosh.install "$U_NAME" dev; echo "second rc=$?"
  diff <(readlink "$U_HOME/oosh") <(readlink "$U_HOME/oosh") && echo "same target"
  ```

  Expected: rc 0, the symlinks still point at the same shared branch, no `config.orig`/`oosh.orig`
  churn beyond the first conversion, and no duplicate WODA blocks.

- [ ] **Step 5: An unavailable branch**

  ```bash
  user oosh.install "$U_NAME" no-such-branch-umt; echo "rc=$?"
  readlink "$U_HOME/oosh"
  ```

  Expected: `INFO> … <shared>/…/no-such-branch-umt not yet available — skipping symlink setup …`,
  **rc 1**, and the existing `~/oosh` link unchanged. The account is not damaged.

- [ ] **Step 6: Cross-check the SSH layout (read-only)**

  ```bash
  command -v ossh >/dev/null && ossh folder.fix.check "$U_HOME/.ssh"; echo "layout rc=$?"
  ```

  `ossh.folder.fix.check` reports drift from the canonical `.ssh` layout and **returns 0 even when
  it finds drift**, so read the report, not the rc. Expected: no drift for the files
  `user.oosh.install` just built (it may warn about missing optional identities on a minimal
  machine — record which). Do **not** run `ossh folder.fix` here; it mutates the scratch layout and
  is covered separately. Do not run the platform test suite from this plan.

---

## Task 8: Delete and its guards (disposable host only)

- [ ] **Step 1: Guards — nothing may be deleted**

  ```bash
  user delete;                   echo "noarg rc=$?"
  user delete no_such_user_umt;  echo "unknown rc=$?"
  user delete root;              echo "root rc=$?"
  user delete "$U_ME";           echo "self rc=$?"
  SUDO_USER=nobody user delete nobody 2>&1; echo "sudo-user rc=$?"
  ```

  Expected:
  - no name → `ERROR> usage: user linux.delete <username>`, **rc 1** (the usage text keeps the
    private family name; record it as a wording finding);
  - unknown → rc 1, no delete command run (no output beyond the function's RESULT);
  - `root` → `ERROR> refusing to delete root`, rc 1;
  - `$U_ME` → `ERROR> refusing to delete the user running this: $U_ME`, rc 1. When the caller is
    root, the root guard answers first; record that ordering;
  - `SUDO_USER=nobody` (if `nobody` exists and is not the caller) → refusing to delete the user
    running this: `nobody`, rc 1.

  Confirm `root`, `$U_ME` and `nobody` still exist after the guards:

  ```bash
  id root; id "$U_ME"; id nobody 2>&1
  ```

- [ ] **Step 2: Delete the scratch account**

  ```bash
  user delete "$U_NAME"; echo "delete rc=$?"
  id "$U_NAME" 2>&1; echo "id rc=$?"
  ls -ld "$U_HOME" 2>&1; echo "home rc=$?"
  user group.member.list "$U_GROUP" 2>&1; echo "members rc=$?"
  ```

  Expected: delete prints **nothing** on success (the wording lives in `RESULT`, not a log line) and
  rc 0; `id` fails; the home is gone; the group remains but no longer lists `$U_NAME` (the account
  deletion removed the membership). If the home survives, stop and investigate before continuing.

- [ ] **Step 3: Second delete and unknown account**

  ```bash
  user delete "$U_NAME"; echo "second rc=$?"
  user delete no_such_user_umt; echo "unknown rc=$?"
  ```

  Expected: both rc 1 (`no such user`); no command is run for an account that is not there.

- [ ] **Step 4: The `$U_NAME2` and `uid`/`gid` accounts**

  ```bash
  for u in "$U_NAME2" "${U_NAME}-nogid"; do
    id "$u" >/dev/null 2>&1 && { user delete "$u"; echo "$u delete rc=$?"; }
  done
  ```

  Expected: any account created in Task 6.9 is gone; no `umt-*` account remains.

- [ ] **Step 5: Delete the scratch groups**

  ```bash
  sudo groupdel "$U_GROUP" 2>&1; echo "group rc=$?"        # Alpine: sudo delgroup "$U_GROUP"
  sudo groupdel "$U_GROUP2" 2>/dev/null; echo "group2 rc=$?"
  user group.check "$U_GROUP"; echo "check rc=$?"
  ```

  Expected: `groupdel` rc 0 for the groups that exist; `group.check` rc 1 afterwards. macOS:
  `sudo dscl . -delete "/Groups/$U_GROUP"`. If a group still has the scratch user, delete the user
  first; `groupdel` refuses a primary group of an existing account.

- [ ] **Step 6: The delete command cache**

  ```bash
  grep -E '^export OS_CMD_' "$CONFIG_PATH/os.commands.env" 2>/dev/null
  bash -c 'source this; source user; printf "OS_CMD_USER_DEL=%s\nOS_CMD_USER_MOD=%s\nOS_CMD_GROUP_ADD=%s\n" \
    "${OS_CMD_USER_DEL:-}" "${OS_CMD_USER_MOD:-}" "${OS_CMD_GROUP_ADD:-}"'
  ```

  Expected: the platform's actual tools, e.g. `/usr/sbin/userdel -r` (or `deluser --remove-home`),
  `usermod -a -G`, `groupadd`; on macOS `sysadminctl -deleteUser`, `dseditgroup -o edit -a`,
  `dseditgroup -o create -q`. If a value is empty, `private.user.init` should heal it on the next
  source/command; record whether it does. The cache is `$CONFIG_PATH/os.commands.env`.

---

## Task 9: Negative cases and safety behaviours

Run each; record the actual message and rc. None of these should mutate a real account.

- [ ] **Step 1: Unknown users in every account-facing method**

  ```bash
  user as no_such_user_umt id -un 2>&1;        echo "as rc=$?"
  user login no_such_user_umt 2>&1;            echo "login rc=$?"
  user oosh.install no_such_user_umt 2>&1;     echo "install rc=$?"
  user get home no_such_user_umt 2>&1;         echo "get rc=$?"
  user delete no_such_user_umt 2>&1;           echo "delete rc=$?"
  ```

  Expected: a clear “no such user”/`su`/`runuser`/“cannot resolve home” error, non-zero rc, and no
  half-created home or group. `user get` is the exception already recorded in Task 2.5: rc 0 and
  empty output.

- [ ] **Step 2: Sandbox identity edge cases**

  ```bash
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.identity.use no-such-id "$SBX/ssh"; echo "missing id rc=$?"
  grep CURRENT_SSH_DIR "$SBX_CONFIG"
  HOME="$SBX_HOME" CONFIG_PATH="$SBX_CONFIG_PATH" CONFIG="$SBX_CONFIG" \
    user ssh.identity.list "$SBX/no-ids"; echo "no ids rc=$?"
  ```

  Expected: `identity.use` accepts a name that does not exist under `ids/`, writes the path, and
  returns 0 — record as a finding (typos are not rejected). `identity.list` on a missing directory
  returns `ls`'s rc **2**.

- [ ] **Step 3: Missing arguments and unknown words**

  ```bash
  user group.add 2>&1;                 echo "group.add rc=$?"
  user group.member.list 2>&1;         echo "member.list rc=$?"
  user group.member.pending 2>&1;      echo "pending rc=$?"
  user authorized.keys.update /tmp/umt-manual/none 2>&1; echo "auth rc=$?"
  user ssh.backup manual /tmp/umt-manual/none 2>&1;      echo "backup rc=$?"
  user ssh.restore latest /tmp/umt-manual/none 2>&1;     echo "restore rc=$?"
  user help no_such_word 2>&1;         echo "help rc=$?"
  ```

  Expected: each method's own usage/error line and rc 1 (or `ls`'s rc 2 where it delegates); no
  file is created for the missing paths.

- [ ] **Step 4: The known sharp edges (record as findings, one each)**

  | Edge | Command | Observed expectation |
  |---|---|---|
  | `get` with no/unknown property | `user get`, `user get bogus "$U_ME"` | rc 0 + IMPORTANT “is not supported” |
  | `get name` ignores its username | `user get name no_such_user_umt` | prints the caller's name |
  | `get basehome` of an unknown user | `user get basehome no_such_user_umt` | prints `/` |
  | `identity.use` tilde | `user ssh.identity.use '~/foo' "$SBX/ssh"` | `…/ids/~/foo`, not `$HOME/foo` |
  | `identity.use` missing id | `user ssh.identity.use no-such-id "$SBX/ssh"` | rc 0, path written |
  | `identity.list` missing `ids/` | `user ssh.identity.list "$SBX/no-ids"` | rc 2 |
  | duplicate `create` | `user create "$U_NAME" password "$U_PASS"` (after it exists) | can return 0 and reset the password |
  | `uid` without `gid` | `user create "$U_NAME-x" password "$U_PASS" uid 1898` | `-g` consumes the next token; record the account state |
  | `list` on Linux | `user list` | system accounts remain (only `_` is filtered) |
  | `delete` success | `user delete "$U_NAME"` | silent; verify by `id`/home, not by text |
  | `as` HOME | `user as "$U_NAME" sh -c 'echo $HOME'` | may be the caller's under `runuser` |
  | `identity.current` persistence | fresh `./user` vs login shell | may differ; see Task 4.5 |

- [ ] **Step 5: `user.id` pass-through**

  ```bash
  user id -u -n; echo "rc=$?"
  user id -Z 2>&1; echo "rc=$?"
  ```

  Expected: the name and rc 0; then `id`'s own invalid-option error and non-zero rc — `user.id` adds
  nothing.

- [ ] **Step 6: Nothing outside the sandbox was written**

  ```bash
  diff -r ~/.ssh /tmp/umt-manual/.ssh 2>/dev/null && echo "real ssh unchanged"
  diff "$CONFIG_PATH/user.env" /tmp/umt-manual/user.env 2>/dev/null && echo "real user.env unchanged"
  ```

  Expected: both unchanged. If not, stop, restore from the Task 0 backup, and record how it changed.

---

## Task 10: Cleanup and sign-off

- [ ] **Step 1: Delete every scratch account and group**

  ```bash
  for u in "$U_NAME" "$U_NAME2" "${U_NAME}-nogid" "${U_NAME}-x"; do
    id "$u" >/dev/null 2>&1 && { user delete "$u"; echo "$u rc=$?"; }
  done
  for g in "$U_GROUP" "$U_GROUP2" "$U_GID_GROUP"; do
    getent group "$g" >/dev/null 2>&1 && { sudo groupdel "$g"; echo "$g rc=$?"; }
  done
  ```

  macOS: `sudo dscl . -delete "/Groups/$g"`. Expected: every scratch name gone; no `umt-*` in
  `getent passwd` or `getent group`.

- [ ] **Step 2: Compare the user/group databases with the baseline**

  ```bash
  getent passwd | sort > /tmp/umt-manual/passwd.after
  getent group  | sort > /tmp/umt-manual/group.after
  diff /tmp/umt-manual/passwd.before /tmp/umt-manual/passwd.after
  diff /tmp/umt-manual/group.before  /tmp/umt-manual/group.after
  ```

  Expected: no `umt-` lines. Other diffs are only changes the host made independently; explain them.
  On macOS compare the `dscl` snapshots the same way.

- [ ] **Step 3: Restore/verify the real shared config and SSH**

  ```bash
  diff -r ~/.ssh /tmp/umt-manual/.ssh 2>/dev/null && echo "ssh ok"
  diff "$CONFIG_PATH/user.env" /tmp/umt-manual/user.env >/dev/null 2>&1 && echo "user.env ok"
  ```

  Expected: `ssh ok`, `user.env ok` (skip the second if the file did not exist in Task 0). If a
  file changed, restore it with `cp -a` from the backup and re-check; do not leave a modified real
  `~/.ssh` or `user.env`.

- [ ] **Step 4: Remove the sandbox**

  ```bash
  rm -rf /tmp/umt-manual/sbx
  rmdir /tmp/umt-manual 2>/dev/null || true
  ```

  Expected: the sandbox is gone. Keep the `.before` snapshots only if you still need them for the
  report; they contain no private keys once the sandbox is removed (the real `~/.ssh` backup does —
  delete it when the report is written).

- [ ] **Step 5: Cross-check the automated suite again**

  ```bash
  test.suite run user 1
  test.suite run completion.audit 1
  ```

  Expected: the same pass/fail picture as Task 0. Any new failure is a regression to investigate.

- [ ] **Step 6: Write the report**

  ```bash
  git status --short
  ```

  Expected: no changes under `user`, `test/`, or `$CONFIG_PATH`. The only new file should be this
  plan (and your results, if you keep them). Include the host/OS, the tier you ran, every finding,
  and any step you skipped with the reason.

---

## Results table

Copy this into your report; one row per task step.

| Task | Step | Command | Expected | Actual | rc | Verdict |
|---|---|---|---|---|---|---|
| 0.3 | automated baseline | `test.suite run user 1` / `completion.audit 1` | recorded | | | |
| 0.4 | install shape | `user get basehome root` / shared tree | recorded | | | |
| 1.1 | usage | `user` | sections, rc 1 | | | |
| 1.2 | filtered help | `user usage` / `help ssh` / `help group` | flat/grouped as specified | | | |
| 1.3 | hidden methods | `user.start` etc. | callable, absent from usage | | | |
| 2.1 | id | `user id`, `-u -n`, `-g`, bad option | pass-through | | | |
| 2.2 | list | `user list`, `list.all` | accounts; Linux systems remain | | | |
| 2.3 | info | `user info` | current user + tree | | | |
| 2.4 | get properties | `home basehome shell info name` | values | | | |
| 2.5 | get edges | no/unknown property/user | rc 0 findings | | | |
| 2.6 | basehome override | `OOSH_USERS_BASEHOME=…` | override | | | |
| 2.7 | group reads | `group.list/check/member.list/pending` | rc semantics | | | |
| 2.8 | ssh reads | `identity.*`, `backup.list`, `legacy.status` | values | | | |
| 3.1–3.4 | group create | `group.add`, `check`, `list`, `member.list` | created, idempotent, empty | | | |
| 4.1 | sandbox | `/tmp/umt-manual/sbx` | isolated env | | | |
| 4.2 | ssh.init | empty `$SBX/ssh` | keypair + 3 WODA, 600 | | | |
| 4.3 | ssh.init again | second run | key unchanged, 3 WODA | | | |
| 4.4 | identity.list | `$SBX/ssh`, missing ids | names / rc 2 | | | |
| 4.5 | identity.use | `demo`, `main`, abs, tilde | persisted `CURRENT_SSH_DIR` | | | |
| 4.6 | keys no key | `authorized.keys.update` | rc 1, untouched | | | |
| 4.7 | keys adopt | hand-added/revoked keys | adopted, revoked out, 644 | | | |
| 4.8 | keys newline | no trailing newline | once, no re-adopt | | | |
| 5.1–5.4 | backup | `ssh.backup` variants | archive, 700, sanitised | | | |
| 5.5 | backup.list | list/empty/missing | oldest first, rc 0 | | | |
| 5.6 | restore latest | marker round-trip | marker back, pre-restore | | | |
| 5.7 | restore exact/unknown | absolute / bad name | ok / rc 1 untouched | | | |
| 5.8 | restore empty | no archives | rc 1 | | | |
| 5.9 | legacy | status/migrate | rc 1 report, rc 0 move | | | |
| 5.10 | real ssh untouched | `diff -r ~/.ssh` | unchanged | | | |
| 6.1 | create no name | `user create` | rc 1 | | | |
| 6.2 | create | `user create $U_NAME password …` | account, home, groups, links | | | |
| 6.3 | duplicate create | second create | rc/output; account state | | | |
| 6.4–6.5 | password | `password.set` reset/empty/no name | rc 0 / no-op / rc 1 | | | |
| 6.6 | as | target, self, noarg, bad cmd | runs as target; HOME note | | | |
| 6.7 | login | `user login $U_NAME` | clean login shell | | | |
| 6.8 | group membership | `group.add $U_GROUP $U_NAME` | member, pending 0, idempotent | | | |
| 6.9 | uid/gid | create with `uid`/`gid` | ids honoured; nogid finding | | | |
| 7.1 | install no name | `oosh.install` | rc 1 | | | |
| 7.2–7.3 | install | `oosh.install $U_NAME dev` | links, .bashrc, backup, WODA | | | |
| 7.4 | install again | second run | idempotent | | | |
| 7.5 | bad branch | `oosh.install $U_NAME no-such…` | rc 1, link unchanged | | | |
| 8.1 | delete guards | none/unknown/root/self/SUDO_USER | rc 1, nothing deleted | | | |
| 8.2 | delete scratch | `user delete $U_NAME` | silent, rc 0, gone | | | |
| 8.3 | delete again | second delete | rc 1 | | | |
| 8.4–8.5 | cleanup extras | secondary users/groups | gone | | | |
| 8.6 | command cache | `OS_CMD_*` | platform values | | | |
| 9.1 | unknown users | `as/login/install/get/delete` | clear errors | | | |
| 9.2 | identity edges | missing id / missing ids | rc 0 / rc 2 | | | |
| 9.3 | missing args | group/keys/backup/restore/help | rc 1 / rc 2 | | | |
| 9.4 | sharp edges | table in 9.4 | recorded findings | | | |
| 9.6 | real state | `diff` ssh/config | unchanged | | | |
| 10.1–10.4 | cleanup | users, groups, sandbox | no `umt-*` | | | |
| 10.5 | automated again | `test.suite run user 1` | baseline | | | |
| 10.6 | report | `git status --short` | only the plan | | | |

## Findings template

```
### Finding N — <one line>
Task/step:
Command:
Expected:
Actual (paste, no filtering):
rc:
Reproduce: deterministic / intermittent
Severity: blocker / major / minor / docs
Suspected area (method + line if known):
```

## Known behaviours to watch (recent design, not accidents)

Confirm these while testing; they are the intended model, not bugs:

- `user create` takes **keyword** options: `password`, `uid`, `gid`. An unknown word is warned and
  ignored. The default password is the **username**; `password ""` opts out (macOS also removes
  `AuthenticationAuthority` so an empty password cannot authenticate).
- `user create` adds the account to the platform sudoer group (`sudo` on Debian, `wheel` on
  RHEL/Alpine, `admin` on macOS), to `dev` when it exists, and auto-runs `user.oosh.install`.
  A missing shared tree is a soft-fail; the account still exists.
- `user delete` refuses no name, an unknown user, `root`, the caller and `${SUDO_USER}` **before**
  running any command. On success it is silent — the wording is in `RESULT`; verify by state.
- `user.authorized.keys.update` adopts every key that only lives in `authorized_keys` into
  `public_keys/`, keeps `deactive.public_keys/` keys out, and swaps the rebuilt file in atomically.
  It never deletes the old file first and leaves no `.new`/`.bak`.
- `user.ssh.backup` is `$HOME`-anchored (`~/.ssh.backups/<UTC>-<label>`), never cwd-relative;
  labels are sanitised; archives are 700; two in the same second get `.1`.
- `user.ssh.restore` stages beside the target, archives the current tree as `pre-restore`, and only
  then swaps. An unknown archive leaves the target untouched.
- `user.ssh.identity.use` persists `CURRENT_SSH_DIR` in `user.env` and exports it in the current
  shell. A login shell reads it; a single process that already inherited `CONFIG` may not.
- `user.login` runs `env -i TERM=… su -`, so only `TERM` survives; `dumb`/empty becomes
  `xterm-256color`.
- `private.as.user` prefers `runuser` (root, no sudo), then `sudo -H -u`, then `su`; `runuser` does
  not reset `HOME` — record the `user as` environment.
- `user.list` filters only names starting with `_`; on Linux system accounts remain in the list.
- `user.get` is a dispatcher: an unsupported property is an IMPORTANT line, not an error, and
  missing/unknown users can return rc 0 with empty or surprising output.
- `user.ssh.identity.list` is `ls $sshDir/ids`; a missing `ids/` is `ls`'s rc 2.
- `user.oosh.install` reads the shared tree under `user get basehome root`; missing tree or missing
  branch is an INFO and rc 1, never a half-installed account.

**Reproduced while writing this plan (record your own result):**

- `user get bogus <user>` and `user get` exit **0** with an IMPORTANT “is not supported” line.
- `user get name no_such_user` prints the **caller's** name; `user get basehome no_such_user`
  prints `/`.
- `user ssh.identity.use '~/foo' <sshDir>` writes `…/ids/~/foo`, not `$HOME/foo`.
- `user ssh.identity.list <sshDir>` returns `ls`'s rc **2** when `ids/` does not exist.
- `user delete` prints nothing on success; `user delete` with no name still says
  `usage: user linux.delete <username>`.

---

## Appendix: method coverage matrix

The 26 visible methods of `user` on `dev` at the time of writing, each mapped to a task step.
`skip` entries state why.

| Method | Where | Method | Where |
|---|---|---|---|
| `as` | 6.6, 9.1 | `group.member.list` | 2.7, 3.4, 6.8 |
| `authorized.keys.update` | 4.6–4.8, 9.3 | `group.member.pending` | 2.7, 3.4, 6.8 |
| `create` | 6.1–6.3, 6.9, 9.4 | `id` | 2.1, 9.5 |
| `delete` | 8.1–8.4, 9.1 | `info` | 2.3 |
| `get` | 2.4–2.6, 9.1, 9.4 | `list` | 2.2, 9.4 |
| `group.add` | 3.2–3.4, 6.8 | `list.all` | 2.2 |
| `group.check` | 2.7, 3.2, 8.5 | `login` | 6.7, 9.1 |
| `group.list` | 2.7, 3.2 | `oosh.install` | 7.1–7.5, 9.1 |
| `password.set` | 6.5, 9.3 | `ssh.backup` | 5.1–5.4, 9.3 |
| `ssh.backup.legacy.migrate` | 5.9 | `ssh.identity.current` | 2.8, 4.5 |
| `ssh.backup.legacy.status` | 2.8, 5.9 | `ssh.identity.list` | 2.8, 4.4, 9.2 |
| `ssh.backup.list` | 2.8, 5.5 | `ssh.identity.use` | 4.5, 9.2, 9.4 |
| `ssh.init` | 4.2–4.3 | `ssh.restore` | 5.6–5.8, 9.3 |

**Deliberately not manually tested:**

- All `private.user.*` helpers — covered by `test.suite run user 1` (fixture-based, no real account).
- Completion — `test.suite run completion.audit 1` in Task 0.
- Package installation, `ossh install`, and node/npm provisioning — covered by `test.install` and
  the platform tests; Task 7 only checks `user.oosh.install`'s per-user effect on a scratch account.
- Deinstall (`init/deinstall.oosh`) — covered by `test.install`.
- Real user passwords / real `~/.ssh` mutations — never part of this plan.
