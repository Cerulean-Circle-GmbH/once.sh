# ossh ssh.replicate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `ossh ssh.replicate [<toHost>]` to copy root's whole `.ssh` into every normal user's `~/.ssh`, locally or on a remote Host entry.

**Architecture:** A private getter emits one POSIX `sh` script; the public method runs it locally under `$SUDO`, or pipes it into one remote ssh call whose wrapper becomes root (runuser not needed — already root, or passwordless sudo). The script enumerates real homes under `/home`/`/Users`, skips `shared`, copies over same names, keeps extras, fixes owner and modes, and prints `ok`/`FAILED`/`SUMMARY` lines the method parses into one RESULT.

**Tech Stack:** Bash (`ossh`), POSIX `sh` for the target script, the existing `test/test.ossh` harness (`test.case`, `expect`, fixtures).

---

## File Structure

- `ossh` — add `private.ossh.ssh.replicate.script.get()` and `ossh.ssh.replicate()` after `ossh.key.pull`, before `ossh.config.pull`.
- `test/test.ossh` — add `test.ossh.sshReplicate` before the `T-OSSH-KEY-REVOKE` section.
- `docs/ossh.md` — one method-table row and one Key Management subsection.

---

### Task 1: POSIX replication script

**Files:**
- Modify: `ossh:3296-3307` (insert between `ossh.key.pull` and `ossh.config.pull`)
- Test: `test/test.ossh:2974` (insert before `# T-OSSH-KEY-REVOKE:`)

- [ ] **Step 1: Write the failing test**

Insert this block into `test/test.ossh` immediately before `# T-OSSH-KEY-REVOKE: key.revoke moves the key ...`:

```bash
# T-OSSH-SSH-REPLICATE: ssh.replicate copies root's ~/.ssh into every normal
# user — the whole directory, private keys included, copying over same names
# and keeping each user's other files. The script is run against fixture
# homes with OSSH_SSH_REPLICATE_SOURCE/BASEHOME; id and chown are stubs in a
# fixture bin dir, so the test needs no root and touches no real /home.
test.ossh.sshReplicate() {
  local fx bad="" out rc script f
  fx=$(test.suite.fixture.make osshsshreplicate)
  mkdir -p "$fx/src" "$fx/home/alice/.ssh" "$fx/home/bob" \
           "$fx/home/shared/.ssh" "$fx/home/notauser/.ssh" "$fx/home/carol" \
           "$fx/bin" "$fx/empty"
  printf '%s\n' "private" > "$fx/src/id_ed25519"
  printf '%s\n' "ssh-ed25519 AAAA me@root" > "$fx/src/id_ed25519.pub"
  printf '%s\n' "Host *" " User root" > "$fx/src/config"
  printf '%s\n' "roothost ssh-ed25519 AAAA" > "$fx/src/known_hosts"
  printf '%s\n' "alice keeps this" > "$fx/home/alice/.ssh/keep_me"
  printf '%s\n' "old" > "$fx/home/alice/.ssh/config"
  : > "$fx/home/carol/.ssh"   # a file where ~/.ssh must be a directory
  cat > "$fx/bin/id" <<'SH'
#!/bin/sh
case "$1" in
  -u) echo 0 ;;
  -gn) echo "${2:-alice}" ;;
  alice|bob|carol|shared) echo "uid=1000($1)"; exit 0 ;;
  *) exit 1 ;;
esac
SH
  cat > "$fx/bin/chown" <<'SH'
#!/bin/sh
echo "chown $*" >> "$FX_LOG"
exit 0
SH
  chmod +x "$fx/bin/id" "$fx/bin/chown"

  script="$(private.ossh.ssh.replicate.script.get)"
  : > "$fx/chown.log"
  out=$(printf '%s\n' "$script" | PATH="$fx/bin:$PATH" FX_LOG="$fx/chown.log" \
    OSSH_SSH_REPLICATE_SOURCE="$fx/src" OSSH_SSH_REPLICATE_BASEHOME="$fx/home" sh 2>&1)
  rc=$?
  [ "$rc" = 1 ] || bad="$bad rc=$rc"
  echo "$out" | grep -qx 'ok alice' || bad="$bad noAlice=[$(echo "$out" | tr '\n' '|')]"
  echo "$out" | grep -qx 'ok bob' || bad="$bad noBob=[$(echo "$out" | tr '\n' '|')]"
  echo "$out" | grep -q '^ok shared$' && bad="$bad sharedCopied"
  echo "$out" | grep -q '^ok notauser$' && bad="$bad notAUserCopied"
  echo "$out" | grep -q '^FAILED carol:' || bad="$bad noCarol=[$(echo "$out" | tr '\n' '|')]"
  echo "$out" | grep -qx 'SUMMARY ok=2 failed=1' || bad="$bad summary=[$(echo "$out" | tr '\n' '|')]"
  # same names replaced, the user's own files kept
  grep -qx 'Host \*' "$fx/home/alice/.ssh/config" || bad="$bad notReplaced"
  grep -qx 'alice keeps this' "$fx/home/alice/.ssh/keep_me" || bad="$bad lostExtra"
  [ -f "$fx/home/bob/.ssh/id_ed25519" ] || bad="$bad bobNoKey"
  [ -f "$fx/home/shared/.ssh/id_ed25519" ] && bad="$bad sharedWrote"
  [ -f "$fx/home/notauser/.ssh/id_ed25519" ] && bad="$bad notAUserWrote"
  # owner fixed through the stub; modes on the copy
  grep -q 'alice:alice' "$fx/chown.log" || bad="$bad noChownAlice=[$(tr '\n' '|' < "$fx/chown.log")]"
  grep -q 'bob:bob' "$fx/chown.log" || bad="$bad noChownBob=[$(tr '\n' '|' < "$fx/chown.log")]"
  for f in "$fx/home/alice/.ssh" "$fx/home/bob/.ssh"; do
    [ "$(stat -c %a "$f" 2>/dev/null || stat -f %Lp "$f")" = 700 ] || bad="$bad dirMode=$(stat -c %a "$f" 2>/dev/null || stat -f %Lp "$f")"
  done
  for f in "$fx/home/bob/.ssh/id_ed25519" "$fx/home/bob/.ssh/config"; do
    [ "$(stat -c %a "$f" 2>/dev/null || stat -f %Lp "$f")" = 600 ] || bad="$bad keyMode=$(stat -c %a "$f" 2>/dev/null || stat -f %Lp "$f")"
  done
  for f in "$fx/home/bob/.ssh/id_ed25519.pub" "$fx/home/bob/.ssh/known_hosts"; do
    [ "$(stat -c %a "$f" 2>/dev/null || stat -f %Lp "$f")" = 644 ] || bad="$bad pubMode=$(stat -c %a "$f" 2>/dev/null || stat -f %Lp "$f")"
  done
  # no source: rc 1 and a source failure, nothing written
  out=$(printf '%s\n' "$script" | PATH="$fx/bin:$PATH" FX_LOG="$fx/chown.log" \
    OSSH_SSH_REPLICATE_SOURCE="$fx/none" OSSH_SSH_REPLICATE_BASEHOME="$fx/home" sh 2>&1)
  rc=$?
  [ "$rc" = 1 ] && echo "$out" | grep -q '^FAILED source: no ' || bad="$bad missingSource=[$out]"

  # the method: local and remote wiring, one RESULT per outcome
  test.ossh.sshReplicate.run() { # <remoteOut> <remoteRc> <what...> # echo calls, then rc and RESULT
    ( FX_OUT="$1" FX_RC="$2"; shift 2
      HOME="$fx"; CURRENT_SSH_DIR="$fx/.ssh"
      private.ossh.ssh.replicate.script.get() { printf '%s\n' 'echo "ok alice"' 'echo "SUMMARY ok=1 failed=0"'; }
      private.this.host.name.get() { echo fixturehost; }
      id() { if [ "$1" = "-u" ]; then echo 0; else command id "$@"; fi; }
      ossh.connection.open() { echo "open $*" >> "$fx/calls"; }
      private.ossh.ssh() {
        echo "ssh $*" >> "$fx/calls"
        cat >/dev/null
        printf '%s\n' "$FX_OUT"
        return "$FX_RC"
      }
      "$@" </dev/null >/dev/null 2>&1
      echo "rc=$? RESULT=$RESULT" >> "$fx/calls" )
    cat "$fx/calls"; rm -f "$fx/calls"
  }
  out=$(test.ossh.sshReplicate.run "" 0 ossh.ssh.replicate)
  echo "$out" | grep -qxF "rc=0 RESULT=replicated root's .ssh to 1 users on fixturehost (including private keys)" \
    || bad="$bad local=[$(echo "$out" | tail -1)]"
  out=$(test.ossh.sshReplicate.run $'ok alice\nSUMMARY ok=1 failed=0' 0 ossh.ssh.replicate lab)
  echo "$out" | grep -q '^ssh lab ' || bad="$bad remoteCall=[$out]"
  echo "$out" | grep -q 'sudo -n' || bad="$bad noSudo=[$out]"
  echo "$out" | grep -qxF "rc=0 RESULT=replicated root's .ssh to 1 users on lab (including private keys)" \
    || bad="$bad remote=[$(echo "$out" | tail -1)]"
  out=$(test.ossh.sshReplicate.run $'ok alice\nFAILED bob: copy failed\nSUMMARY ok=1 failed=1' 1 ossh.ssh.replicate lab)
  echo "$out" | grep -qxF "rc=1 RESULT=replicated root's .ssh to 1 users on lab — failed: bob: copy failed" \
    || bad="$bad partial=[$(echo "$out" | tail -1)]"
  out=$(test.ossh.sshReplicate.run $'FAILED carol: copy failed\nSUMMARY ok=0 failed=1' 1 ossh.ssh.replicate lab)
  echo "$out" | grep -qxF "rc=1 RESULT=could not replicate root's .ssh on lab: carol: copy failed" \
    || bad="$bad allFail=[$(echo "$out" | tail -1)]"
  out=$(test.ossh.sshReplicate.run 'SUMMARY ok=0 failed=0' 0 ossh.ssh.replicate lab)
  echo "$out" | grep -qxF 'rc=1 RESULT=no normal users found on lab — nothing copied' \
    || bad="$bad noUsers=[$(echo "$out" | tail -1)]"
  out=$(test.ossh.sshReplicate.run "" 255 ossh.ssh.replicate lab)
  echo "$out" | grep -qxF "rc=1 RESULT=could not replicate root's .ssh on lab: no answer from the target" \
    || bad="$bad noAnswer=[$(echo "$out" | tail -1)]"
  # no root and no sudo: rc 1 before anything runs
  out=$( ( PATH="$fx/empty" HOME="$fx"
      private.ossh.ssh.replicate.script.get() { echo ':'; }
      id() { if [ "$1" = "-u" ]; then echo 1000; else command id "$@"; fi; }
      ossh.ssh.replicate >/dev/null 2>&1; echo "rc=$? RESULT=$RESULT" ) )
  echo "$out" | grep -qxF 'rc=1 RESULT=ssh.replicate needs root or sudo' || bad="$bad noSudoLocal=[$out]"
  unset -f test.ossh.sshReplicate.run
  rm -rf "${fx:?}"
  [ -z "$bad" ] && create.result 0 "ssh.replicate copies root's .ssh to every normal user, keeping extras" \
    || create.result 1 "ssh.replicate:$bad"
  return $(result)
}
test.case $level "T-OSSH-SSH-REPLICATE: ssh.replicate copies root's ~/.ssh into every normal user, keeps extras, fixes owner and modes" test.ossh.sshReplicate
expect 0 "ssh.replicate copies root's .ssh to every normal user, keeping extras" \
  "one account or a failed copy stopped the rest, extras were deleted, modes stayed open, or the RESULT was wrong"
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
./test/test.ossh 1 2>&1 | grep -A6 'T-OSSH-SSH-REPLICATE'
```

Expected: the case fails because `private.ossh.ssh.replicate.script.get` is not defined (the script's `script=` is empty, `rc`/output assertions fail).

- [ ] **Step 3: Write the minimal implementation**

Insert into `ossh` between the `Same as key.push.` comment after `ossh.key.pull` and `ossh.config.pull()`:

```bash
private.ossh.ssh.replicate.script.get()     # # echo the POSIX sh script that copies root's ~/.ssh into every normal user's ~/.ssh — OSSH_SSH_REPLICATE_SOURCE and OSSH_SSH_REPLICATE_BASEHOME override the source and the users base for tests; "ok <user>" or "FAILED <user>: <reason>" per account, then "SUMMARY ok=<n> failed=<n>" #
{
  # NO create.result — a getter consumed as $(...). It is a POSIX sh script
  # for the target: no bash, no oosh, no rsync. The source is ~root/.ssh, not
  # the literal /root/.ssh: macOS keeps root's home in /var/root.
  cat <<'EOF'
src=${OSSH_SSH_REPLICATE_SOURCE:-$(eval echo ~root)/.ssh}
base=${OSSH_SSH_REPLICATE_BASEHOME:-}
if [ -z "$base" ]; then
  case "$(uname -s)" in
    Darwin) base=/Users ;;
    *) base=/home ;;
  esac
fi
if [ ! -d "$src" ]; then
  echo "FAILED source: no $src"
  exit 1
fi
if [ ! -d "$base" ]; then
  echo "FAILED source: no $base"
  exit 1
fi
ok=0
failed=0
for home in "$base"/*; do
  [ -d "$home" ] || continue
  user=${home##*/}
  case "$user" in shared|Shared) continue ;; esac
  id "$user" >/dev/null 2>&1 || continue
  if ! mkdir -p "$home/.ssh" 2>/dev/null; then
    echo "FAILED $user: cannot create $home/.ssh"
    failed=$((failed + 1))
    continue
  fi
  if ! sshdir=$(cd "$home/.ssh" 2>/dev/null && pwd -P); then
    echo "FAILED $user: cannot enter $home/.ssh"
    failed=$((failed + 1))
    continue
  fi
  if ! cp -Rp "$src"/. "$sshdir"/ 2>/dev/null; then
    echo "FAILED $user: copy failed"
    failed=$((failed + 1))
    continue
  fi
  if ! chown -R "$user":"$(id -gn "$user")" "$sshdir" 2>/dev/null; then
    echo "FAILED $user: chown failed"
    failed=$((failed + 1))
    continue
  fi
  chmod 700 "$sshdir" 2>/dev/null
  find "$sshdir" -type d -exec chmod 700 {} \; 2>/dev/null
  find "$sshdir" -type f -exec chmod 600 {} \; 2>/dev/null
  find "$sshdir" -type f \( -name '*.pub' -o -name 'known_hosts' -o -name 'known_hosts.old' \) -exec chmod 644 {} \; 2>/dev/null
  echo "ok $user"
  ok=$((ok + 1))
done
echo "SUMMARY ok=$ok failed=$failed"
[ "$failed" -eq 0 ]
EOF
}
```

- [ ] **Step 4: Run the script test part again**

Run:

```bash
./test/test.ossh 1 2>&1 | grep -A6 'T-OSSH-SSH-REPLICATE'
```

Expected: the script assertions pass; the case still fails on the method assertions because `ossh.ssh.replicate` is not defined yet.

- [ ] **Step 5: Commit**

```bash
git add ossh test/test.ossh
git commit -m "feat(ossh): replicate root's .ssh script"
```

---

### Task 2: Public `ossh.ssh.replicate`

**Files:**
- Modify: `ossh` (insert directly below the getter from Task 1)
- Test: the same `test.ossh.sshReplicate` case

- [ ] **Step 1: Run the test to confirm the method is still missing**

Run:

```bash
./test/test.ossh 1 2>&1 | grep -A6 'T-OSSH-SSH-REPLICATE'
```

Expected: FAIL on `local=[...]` / `remote=[...]` because `ossh.ssh.replicate` does not exist.

- [ ] **Step 2: Write the implementation**

Insert directly below the getter:

```bash
ossh.ssh.replicate()     # <?toHost> # copies root's ~/.ssh (/root/.ssh, /var/root/.ssh on macOS) into the ~/.ssh of every normal user on <toHost>, or on this machine without <toHost> — files of the same name replaced, the user's other files kept, owner and modes fixed; rc 0 + RESULT when every account got it, rc 1 + RESULT naming the accounts that failed or the connection/privilege/source error #
{
  local toHost="$1"
  [ $# -gt 0 ] && shift
  local script out rc machine line firstFailure="" failedUsers="" nOk=0 nFailed=0
  script="$(private.ossh.ssh.replicate.script.get)" || {
    create.result 1 "could not build the ssh.replicate script"
    error.log "$RESULT"
    return $(result)
  }

  if [ -n "$toHost" ]; then
    ossh.connection.open "$toHost" || return $(result)   # no master: every step would ask the password again (T-OSSH-CONNECTION-OPEN-FAIL)
    machine="$toHost"
    # One call for the whole loop. The wrapper picks the way to become root
    # on the target: already root, passwordless sudo, or nothing — and says
    # so instead of hanging on a password prompt with no tty.
    out="$(printf '%s\n' "$script" | private.ossh.ssh "$toHost" 'if [ "$(id -u)" = 0 ]; then exec sh -s; elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then exec sudo -n sh -s; else echo "FAILED privilege: need root or passwordless sudo"; exit 1; fi')"
    rc=$?
  else
    machine="$(private.this.host.name.get 2>/dev/null)"
    [ -n "$machine" ] || machine="this computer"
    if [ "$(id -u)" = 0 ]; then
      out="$(printf '%s\n' "$script" | sh -s)"
      rc=$?
    elif command -v sudo >/dev/null 2>&1; then
      out="$(printf '%s\n' "$script" | sudo sh -s)"
      rc=$?
    else
      create.result 1 "ssh.replicate needs root or sudo"
      error.log "$RESULT"
      return $(result)
    fi
  fi

  while IFS= read -r line; do
    case "$line" in
      "ok "*) nOk=$((nOk + 1)) ;;
      "FAILED "*)
        nFailed=$((nFailed + 1))
        [ -n "$firstFailure" ] || firstFailure="${line#FAILED }"
        failedUsers="${failedUsers}${failedUsers:+, }${line#FAILED }"
        ;;
    esac
  done <<< "$out"

  if [ "$nOk" -eq 0 ] && [ "$nFailed" -eq 0 ] && [ "$rc" -ne 0 ]; then
    create.result 1 "could not replicate root's .ssh on $machine: no answer from the target"
    error.log "$RESULT"
  elif [ "$nOk" -eq 0 ] && [ "$nFailed" -gt 0 ]; then
    create.result 1 "could not replicate root's .ssh on $machine: $failedUsers"
    error.log "$RESULT"
  elif [ "$nFailed" -gt 0 ]; then
    create.result 1 "replicated root's .ssh to $nOk users on $machine — failed: $failedUsers"
    error.log "$RESULT"
  elif [ "$nOk" -eq 0 ]; then
    create.result 1 "no normal users found on $machine — nothing copied"
    error.log "$RESULT"
  elif [ "$rc" -ne 0 ]; then
    create.result 1 "could not replicate root's .ssh on $machine"
    error.log "$RESULT"
  else
    create.result 0 "replicated root's .ssh to $nOk users on $machine (including private keys)"
    success.log "$RESULT"
    warn.log "ssh.replicate copied root's private keys: every user can now use them"
  fi
  return $(result)
}
ossh.ssh.replicate.completion() {
  ossh.config.get.completion "$@"
}
```

- [ ] **Step 3: Run the test to verify it passes**

Run:

```bash
./test/test.ossh 1 2>&1 | grep -A8 'T-OSSH-SSH-REPLICATE'
```

Expected: `PASS`, and the final summary reports no failures for this case.

- [ ] **Step 4: Run the full ossh suite**

Run:

```bash
./test/test.ossh 1 >/tmp/test-ossh.log 2>&1; echo "rc=$?"; tail -20 /tmp/test-ossh.log
```

Expected: `rc=0`, no `FAIL` lines.

- [ ] **Step 5: Commit**

```bash
git add ossh test/test.ossh
git commit -m "feat(ossh): add ssh.replicate for every normal user"
```

---

### Task 3: Documentation

**Files:**
- Modify: `docs/ossh.md:626` (method table) and before `### First contact with only a password` (Key Management section)

- [ ] **Step 1: Add the method-table row**

After the `ossh key.revoke` row:

```markdown
| `ossh ssh.replicate` | Copy root's whole `~/.ssh` to every normal user (private keys included) |
```

- [ ] **Step 2: Add the Key Management subsection**

Insert before `### First contact with only a password`:

```markdown
### Copying root's `.ssh` to every user

```bash
ossh ssh.replicate            # this machine
ossh ssh.replicate myhost     # that host
```

Copies root's `~/.ssh` (`/root/.ssh`; `/var/root/.ssh` on macOS) into the
`~/.ssh` of every normal user — every real home under `/home` on Linux or
`/Users` on macOS, skipping `shared`, nothing else. Files of the same name are
replaced; each user's other files stay. `~/.ssh` becomes 700, private keys,
`config` and `authorized_keys` 600, `*.pub` and `known_hosts` 644, and the copy
belongs to the user.

**This copies private keys.** Every normal user can then authenticate as root
to everything root's keys reach; the method logs that warning. It needs root
or passwordless sudo on a remote host (sudo may prompt locally). One failing
account does not stop the others; rc 1 names the failures.
```

- [ ] **Step 3: Verify the docs render and no generated section was touched**

Run:

```bash
grep -n "ossh ssh.replicate" docs/ossh.md
sed -n '/Copying root/,/First contact/p' docs/ossh.md
```

Expected: the table row and the new subsection appear; the generated
`<!-- BEGIN generated: oosh method matrix` block is unchanged.

- [ ] **Step 4: Commit**

```bash
git add docs/ossh.md
git commit -m "docs(ossh): ssh.replicate"
```

---

## Self-Review

**Spec coverage:**
- Command shape and optional `<toHost>` — Task 2.
- Same source on remote and local — Task 2 (`~root/.ssh` inside the script).
- Homes + root/skip `shared` — Task 1 script.
- Copy over/keep extras — Task 1 `cp -Rp`.
- Owner and modes — Task 1 `chown`/`chmod`/`find`.
- Continue on failure, per-user lines, rc semantics — Task 2 parser.
- No source / no users / no privilege — Task 2 branches.
- Safety warning — Task 2 `warn.log` and Task 3 docs.
- Tests and docs — Tasks 1–3.

**Placeholder scan:** no TBD/TODO; every code step is complete.

**Type consistency:** `private.ossh.ssh.replicate.script.get`, `ossh.ssh.replicate`, `OSSH_SSH_REPLICATE_SOURCE`, `OSSH_SSH_REPLICATE_BASEHOME`, `ok `, `FAILED `, `SUMMARY ok=` are used identically in the test and the implementation.
