# `user` Surface and Generated Help Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Normalize the public `user` command surface and make `this.help` generate sectioned help from optional `@group`/`@hidden` tags on method signatures.

**Architecture:** Extend `this.help` additively — a hidden filter plus optional grouping — so untagged scripts render exactly as today. Teach `c2` the same `@hidden` filter, then rename the `user` methods, merge `password.set`, and replace its hardcoded usage block with generated help. Tests are added before each behavioural change.

**Tech Stack:** Bash 4+, OOSH `line`/`this` helpers, `test.suite`, `ng/c2`.

**Spec:** `docs/superpowers/specs/2026-11-17-user-surface-help-redesign-design.md`

**Completed:** 2026-11-18 on `dev`, implementation commits `f01bab33..aeece0c9`.

| Suite | Result |
|---|---|
| `test.this` | 80/80 |
| `test.c2` | 32/32 |
| `test.user` | 88/88 |
| `test.install` | 51/51 |
| `test.completion.audit` | 7/7 |

Deviations from the written steps: return-code assertions use private test functions because
`test.case` re-splits `bash -c '…'`; the `password.set` description avoids an apostrophe because
`line.quote` breaks on one; `ossh.ssh.replicate` lost two apostrophes so the tree-wide `c2`
signature check passes.

---

## File structure

| File | Responsibility in this plan |
|---|---|
| `this` | `private.this.help.blocks.get`, `.render`, `.groups.get`, `.group.order.get`; rewrite `this.help` |
| `ng/c2` | Hide `@hidden` methods from completion extraction |
| `user` | Rename surface, merge `password.set`, add tags, generate usage, add group order |
| `init/deinstall.oosh` | Call `user delete` instead of `user linux.delete` |
| `test/test.this` | Help renderer tests (flat, hidden, grouped, filtered) |
| `test/test.c2` | Completion hides `@hidden` |
| `test/test.user` | Renamed invocations plus surface/completeness tests |
| `test/test.install` | Deinstall assertion follows `user delete` |
| `templates/code/newMethod`, `docs/command-creation.md` | Document the tag convention |

---

## Task 1: Tag-aware help renderer (flat + hidden)

**Files:**
- Modify: `this` (replace `this.help`, add two private helpers immediately above it, around lines 1844–1874)
- Test: `test/test.this` (append after the existing T5 block near line 78)

- [x] **Step 1: Write the failing test**

Append to `test/test.this`:

```bash
# ============================================================================
# T7: this.help — flat output for untagged scripts, @hidden omitted
# ============================================================================
HELP_FIXTURE=$(test.suite.fixture.make this.help)
cat > "$HELP_FIXTURE/flatFixture" <<'EOF'
flatFixture.alpha() # # first method
{ :; }
flatFixture.hidden() # # secret method # @hidden
{ :; }
EOF
source "$HELP_FIXTURE/flatFixture"

HELP_OUT=$(this.help "$HELP_FIXTURE/flatFixture" 2>/dev/null)
if printf '%s\n' "$HELP_OUT" | grep -q "first method"; then
  expect.pass "this.help prints an untagged method"
else
  expect.fail "this.help should print flatFixture.alpha"
fi
if printf '%s\n' "$HELP_OUT" | grep -q "secret method"; then
  expect.fail "this.help must omit @hidden methods"
else
  expect.pass "this.help omits @hidden methods"
fi
if printf '%s\n' "$HELP_OUT" | grep -q "@hidden"; then
  expect.fail "this.help must strip the @hidden tag"
else
  expect.pass "this.help strips the @hidden tag"
fi

FILTER_OUT=$(this.help "$HELP_FIXTURE/flatFixture" help alpha 2>/dev/null)
if printf '%s\n' "$FILTER_OUT" | grep -q "first method"; then
  expect.pass "this.help filters by method word"
else
  expect.fail "this.help should print flatFixture.alpha when filtered"
fi
if printf '%s\n' "$FILTER_OUT" | grep -q "@hidden"; then
  expect.fail "filtered help must strip @hidden"
else
  expect.pass "filtered help strips @hidden"
fi
```

- [x] **Step 2: Run the test to verify it fails**

Run: `./test.suite run this 1`

Expected: FAIL — the `secret method` assertion fails because the current `this.help` does not filter `@hidden`, and `private.this.help.render` does not exist.

- [x] **Step 3: Add the renderer helpers and rewrite `this.help`**

In `this`, replace the existing `this.help()` body with the code below, and insert the two helpers immediately above `this.help()`:

```bash
private.this.help.blocks.get() # <from> # echo the helpable signature blocks of <from>, hidden and completion/private methods removed #
{
  cat "$1" \
  | line.find "\(\)" "\{" \
  | line.filter "^#" \
  | line.filter "^{" \
  | line.filter "\.completion" \
  | line.filter "^private" \
  | line.filter "@hidden"
}

private.this.help.render() # <from> <?filter> <?group> # render one help table: all methods, one group, or the untagged ones #
{
  local from="$1"; shift
  local filter="$1"; shift
  local group="$1"; shift
  local name
  name=$(basename "$from")

  private.this.help.blocks.get "$from" \
  | { case "$group" in
        "")    cat ;;
        other) grep -v '@group:' ;;
        *)     grep -E "@group:$group([[:space:]]|$)" ;;
      esac; } \
  | line.replace " *@group:[a-z0-9_-]*" "" \
  | line.quote \
  | sort \
  | grep "$name\.$filter" \
  | line.prepend "'=========== # =========== # ==========='" \
  | line.prepend "'METHOD # PARAMETER # DESCRIPTION'" \
  | line.unify '#' " no name" " ${GRAY}none" " ${GRAY}please add a description" \
  | line.trim.quoted \
  | line.replace "\([^ ]\)()" "\1" \
  | line.replace " {" \
  | line.replace "$name\." \
  | line.format FORMAT_HELP
}

this.help() {
  source line
  local from="$1"
  if [ -n "$1" ]; then
    from="$1"
    shift
  else
    from="$This"
  fi
  shift

  private.this.help.render "$from" "$1" ""
}
```

- [x] **Step 4: Run the test to verify it passes**

Run: `./test.suite run this 1`

Expected: PASS — untagged fixture prints, hidden method and tag are absent from both full and filtered output.

- [x] **Step 5: Commit**

```bash
git add this test/test.this
git commit -m "feat(this): tag-aware help renderer with hidden filter"
```

---

## Task 2: Grouped help with script-defined order

**Files:**
- Modify: `this` (add `groups.get`, `group.order.get`; extend `this.help`)
- Test: `test/test.this`

- [x] **Step 1: Write the failing test**

Append to `test/test.this`:

```bash
# ============================================================================
# T8: this.help — groups, order, other, unlisted groups, tags stripped
# ============================================================================
GROUP_FIXTURE=$(test.suite.fixture.make this.help.groups)
cat > "$GROUP_FIXTURE/groupFixture" <<'EOF'
groupFixture.alpha() # # alpha method # @group:one
{ :; }
groupFixture.beta() # # beta method # @group:two
{ :; }
groupFixture.gamma() # # gamma method
{ :; }
groupFixture.delta() # # delta method # @group:three
{ :; }
groupFixture.hidden() # # secret method # @hidden
{ :; }
groupFixture.help.group.order() # # # @hidden
{ echo one; echo two; }
EOF
source "$GROUP_FIXTURE/groupFixture"

GROUP_OUT=$(this.help "$GROUP_FIXTURE/groupFixture" 2>/dev/null)
GROUP_HEADERS=$(printf '%s\n' "$GROUP_OUT" | grep -xE 'one|two|three|other')

if [ "$GROUP_HEADERS" = "$(printf '%s\n' one two three other)" ]; then
  expect.pass "this.help renders groups in order: defined, unlisted alphabetical, other last"
else
  expect.fail "this.help group order was: $GROUP_HEADERS"
fi
if printf '%s\n' "$GROUP_OUT" | grep -q '@group:'; then
  expect.fail "grouped help must strip @group tags"
else
  expect.pass "grouped help strips @group tags"
fi
if printf '%s\n' "$GROUP_OUT" | grep -q 'secret method'; then
  expect.fail "grouped help must omit @hidden methods"
else
  expect.pass "grouped help omits @hidden methods"
fi

FILTERED_GROUP_OUT=$(this.help "$GROUP_FIXTURE/groupFixture" help alpha 2>/dev/null)
if printf '%s\n' "$FILTERED_GROUP_OUT" | grep -q 'alpha method' \
   && ! printf '%s\n' "$FILTERED_GROUP_OUT" | grep -qxE 'one|two|three|other'; then
  expect.pass "filtered help stays flat and untagged"
else
  expect.fail "filtered help should stay flat without group headers"
fi
```

- [x] **Step 2: Run the test to verify it fails**

Run: `./test.suite run this 1`

Expected: FAIL — no `one`/`two` headers are printed, because grouping is not implemented.

- [x] **Step 3: Add grouping helpers and the grouped branch**

Insert these two helpers above `this.help()` in `this`:

```bash
private.this.help.groups.get() # <from> # echo the named groups in <from>; add "other" only when some method is tagged ##
{
  local blocks named
  blocks=$(private.this.help.blocks.get "$1")
  named=$(printf '%s\n' "$blocks" | grep -o '@group:[a-z0-9_-]*' | sed 's/@group://' | sort -u)
  [ -n "$named" ] && printf '%s\n' "$named"
  if [ -n "$named" ] && printf '%s\n' "$blocks" | grep -v '@group:' | grep -q '()'; then
    echo other
  fi
}

private.this.help.group.order.get() # <from> # echo group names: <script>.help.group.order first, then unlisted alphabetical, then other ##
{
  local script groups listed
  script=$(basename "$1")
  groups=$(private.this.help.groups.get "$1")
  listed=""
  if this.functionExists "$script.help.group.order"; then
    listed=$("$script.help.group.order")
  fi
  awk -v listed="$listed" -v groups="$groups" '
    BEGIN {
      n = split(listed, L, "\n")
      m = split(groups, G, "\n")
      for (i = 1; i <= m; i++) if (G[i] != "") have[G[i]] = 1
      for (i = 1; i <= n; i++) if (L[i] != "" && (L[i] in have) && !done[L[i]]++) print L[i]
      for (i = 1; i <= m; i++) if (G[i] != "" && G[i] != "other" && !done[G[i]]++) print G[i]
      if ("other" in have) print "other"
    }'
}
```

Replace `this.help()` with:

```bash
this.help() {
  source line
  local from="$1"
  if [ -n "$1" ]; then
    from="$1"
    shift
  else
    from="$This"
  fi
  shift

  local filter="$1"

  if [ -n "$filter" ]; then
    private.this.help.render "$from" "$filter" ""
    return 0
  fi

  local groups
  groups=$(private.this.help.groups.get "$from")
  if [ -z "$groups" ]; then
    private.this.help.render "$from" "" ""
    return 0
  fi

  local group
  private.this.help.group.order.get "$from" | while IFS= read -r group; do
    [ -n "$group" ] || continue
    printf '\n%s\n' "$group"
    private.this.help.render "$from" "" "$group"
  done
}
```

- [x] **Step 4: Run the test to verify it passes**

Run: `./test.suite run this 1`

Expected: PASS — headers are `one`, `two`, `three`, `other`; tags and hidden methods are absent; filtered output stays flat.

- [x] **Step 5: Commit**

```bash
git add this test/test.this
git commit -m "feat(this): grouped help with script-defined order"
```

---

## Task 3: Completion hides `@hidden`

**Files:**
- Modify: `ng/c2` (`private.c2.get.functions`, around line 237)
- Test: `test/test.c2`

- [x] **Step 1: Write the failing test**

Append to `test/test.c2`:

```bash
# ============================================================================
# T-C2-HIDDEN: @hidden methods are absent from completion
# ============================================================================
C2_FIXTURE=$(test.suite.fixture.make c2.hidden)
cat > "$C2_FIXTURE/c2Fixture" <<'EOF'
c2Fixture.visible() # # visible
{ :; }
c2Fixture.secret() # # secret # @hidden
{ :; }
EOF

C2_OUT=$(bash -c "source '$OOSH_DIR/this'; source '$OOSH_DIR/ng/c2'; c2 function.completion '$C2_FIXTURE/c2Fixture'" 2>/dev/null)
if printf '%s\n' "$C2_OUT" | grep -qx 'visible'; then
  expect.pass "completion lists a visible method"
else
  expect.fail "completion should list c2Fixture.visible"
fi
if printf '%s\n' "$C2_OUT" | grep -qx 'secret'; then
  expect.fail "completion must omit @hidden methods"
else
  expect.pass "completion omits @hidden methods"
fi
```

- [x] **Step 2: Run the test to verify it fails**

Run: `./test.suite run c2 1`

Expected: FAIL — `secret` is listed because `private.c2.get.functions` does not filter `@hidden`.

- [x] **Step 3: Add the filter**

In `ng/c2`, in `private.c2.get.functions`, add one filter after `line.filter "^{"`:

```bash
  cat "$from" \
  | line.find "^[^ ]*$1[^ ]*\(\) " \
  | line.filter "^{" \
  | line.filter "@hidden"
```

- [x] **Step 4: Run the test to verify it passes**

Run: `./test.suite run c2 1`

Expected: PASS — `visible` is listed, `secret` is not.

- [x] **Step 5: Commit**

```bash
git add ng/c2 test/test.c2
git commit -m "feat(c2): hide @hidden methods from completion"
```

---

## Task 4: Account surface — `user delete` and merged `password.set`

**Files:**
- Modify: `user` (account methods, lines 716–950 and 1372–1385)
- Modify: `init/deinstall.oosh:3`
- Modify: `test/test.install` (the deinstall assertions around lines 1157–1174)
- Test: `test/test.user`

- [x] **Step 1: Write the failing tests**

First update the existing cleanup calls in `test/test.user` (before appending the new test, so the
new `grep '^user\.linux\.delete()'` assertion below is not rewritten):

```bash
sed -i 's/user\.linux\.delete/user.delete/g' test/test.user
```

Then append to `test/test.user`:

```bash
# ============================================================================
# T-USER-DELETE: public delete exists, dispatches, and keeps the guards
# ============================================================================
private.test.user.deleteNoName() { bash -c 'source this; source user; user.delete'; }
private.test.user.deleteRoot()   { bash -c 'source this; source user; user.delete root'; }
private.test.user.passwordEmpty(){ bash -c 'source this; source user; user.password.set nobody ""'; }
private.test.user.passwordOs()   { bash -c 'source this; source user; OSTYPE=plan9 user.password.set nobody secret'; }

test.case $level "user.delete rejects a missing username" \
  private.test.user.deleteNoName

if [ "$RETURN_VALUE" -eq 1 ]; then
  expect.pass "user.delete with no name returns 1"
else
  expect.fail "user.delete with no name should return 1, got $RETURN_VALUE"
fi

test.case $level "user.delete refuses root" \
  private.test.user.deleteRoot

if [ "$RETURN_VALUE" -eq 1 ]; then
  expect.pass "user.delete root returns 1"
else
  expect.fail "user.delete root should return 1, got $RETURN_VALUE"
fi

if grep -q '^user\.linux\.delete()' "$OOSH_DIR/user"; then
  expect.fail "user.linux.delete should be gone"
else
  expect.pass "user.linux.delete is gone"
fi

# ============================================================================
# T-USER-PASSWORD-MERGE: one public body, empty password is a no-op
# ============================================================================
test.case $level "user.password.set with an empty password is a no-op" \
  private.test.user.passwordEmpty

if [ "$RETURN_VALUE" -eq 0 ]; then
  expect.pass "empty password returns 0 without touching the account"
else
  expect.fail "empty password should be a no-op, got $RETURN_VALUE"
fi

test.case $level "user.password.set rejects an unsupported OS" \
  private.test.user.passwordOs

if [ "$RETURN_VALUE" -eq 1 ]; then
  expect.pass "unsupported OS returns 1"
else
  expect.fail "unsupported OS should return 1, got $RETURN_VALUE"
fi

for m in user.password.set.darwin user.password.set.linux; do
  if bash -c "source '$OOSH_DIR/this'; source '$OOSH_DIR/user'; type -t '$m'" >/dev/null 2>&1; then
    expect.fail "$m should be merged into user.password.set"
  else
    expect.pass "$m is gone"
  fi
done
```

- [x] **Step 2: Run the tests to verify they fail**

Run: `./test.suite run user 1`

Expected: FAIL — `user.delete` does not exist, and `user.password.set.darwin`/`.linux` still exist.

- [x] **Step 3: Implement `user.delete`**

Replace the current `user.linux.delete()` definition with:

```bash
user.delete() # <username> # removes the user and all its files; refuses no name, an unknown user, root and the user running it (rc 1 + RESULT) # @group:account
{
  if os.check private.user.delete; then
    $RESULT "$@"
  else
    create.result 1 "user.delete is not supported on $OSTYPE"
    error.log "$RESULT"
    return $(result)
  fi
}
```

Leave `private.user.delete.linux()` unchanged.

- [x] **Step 4: Merge `password.set`**

Replace the three public definitions (`user.password.set`, `.darwin`, `.linux`) and delete the four per-OS completion hooks, keeping only the dispatcher-level ones:

```bash
user.password.set()        # <username> <password> # sets or resets the password of a user; an empty password is a no-op # @group:account
{
  local username="$1"
  if [ -n "$1" ]; then
    shift
  else
    error.log "no ${YELLOW}username${NORMAL} was specified"
    return 1
  fi
  local password="$1"
  if [ -z "$password" ]; then
    info.log "user.password.set: empty password for $username — skipping"
    return 0
  fi
  case "$OSTYPE" in
    darwin*) $SUDO dscl . -passwd "/Users/$username" "$password" ;;
    linux*)  printf '%s:%s\n' "$username" "$password" | $SUDO chpasswd ;;
    *)       create.result 1 "user.password.set is not supported on $OSTYPE"; error.log "$RESULT"; return $(result) ;;
  esac
}

user.password.set.completion.username() { user.list; }
user.password.set.completion.password() { :; }
```

Delete `user.password.set.darwin()`, `user.password.set.linux()`, and their four `.completion.` hooks.

- [x] **Step 5: Tag the remaining account methods**

Change these declaration lines in `user` (body unchanged):

```bash
user.create()  # <username> <?password> <?uid> <?gid> # creates a new user with home dir and auto-installs oosh; optional args are keyword-style # @group:account
user.login() # <userName> # switch to userName via login shell; cd to target home and reset env, only TERM is kept # @group:account
user.as()     # <username> <command...> # run <command> as <username> # @group:account
user.oosh.install() # <username> <?branch:$OOSH_MODE> # installs oosh for a local user from <branch> # @group:account
```

- [x] **Step 6: Update the deinstall caller and its test**

In `init/deinstall.oosh:3`, change:

```bash
check user developking exists call user delete developking
```

In `test/test.install`, update the deinstall assertions:

```bash
  grep -q '^user\.delete()' "$OOSH_DIR/user" || bad="$bad no-user.delete"
  grep -q 'linux\.delete' "$deinstall" && bad="$bad calls-linux.delete"
  grep -qx 'check user developking exists call user delete developking' "$deinstall" || bad="$bad no-checked-delete"
  grep -q 'delete developking.*|| *true' "$deinstall" && bad="$bad masked"
  [ -z "$bad" ] && create.result 0 "deinstall deletes developking through user delete when it exists" || create.result 1 "deinstall.oosh:$bad"
```

Update the test title and expectation message to say `user delete`.

- [x] **Step 7: Run the tests to verify they pass**

Run:

```bash
./test.suite run user 1
./test.suite run install 1
```

Expected: PASS — delete guards pass, password merge tests pass, and the deinstall assertion passes.

- [x] **Step 8: Commit**

```bash
git add user init/deinstall.oosh test/test.install test/test.user
git commit -m "refactor(user): public delete and one password.set body"
```

---

## Task 5: Inspect and group surface

**Files:**
- Modify: `user` (lines 251–260, 523–560, 1446–1466, 1482–1541)
- Test: `test/test.user`

- [x] **Step 1: Write the failing tests**

Replace the old T5 block in `test/test.user` (which calls `user.list.groups`) with:

```bash
# ============================================================================
# T5: user.group.list returns all groups
# ============================================================================
test.case $level "user.group.list returns groups" \
  bash -c 'source this; source user; user.group.list'

GROUPS_OUTPUT=$(bash -c 'source this; source user; user.group.list 2>/dev/null')
if [ -n "$GROUPS_OUTPUT" ]; then
  expect.pass "user.group.list returned groups"
else
  expect.fail "user.group.list should return at least one group"
fi
```

Replace the `user.group.list <group>` calls in the T-USER-GROUP-LIST block with `user.group.member.list`:

```bash
    out=$(user.group.member.list ooshtestgrp 2>/dev/null); echo "rc=$?"
    user.group.member.list nosuchgrp >/dev/null 2>&1; echo "unknown-rc=$?"
    user.group.member.list >/dev/null 2>&1; echo "noname-rc=$?"
```

Update the block comment and test title to `user.group.member.list`.

- [x] **Step 2: Run the tests to verify they fail**

Run: `./test.suite run user 1`

Expected: FAIL — `user.group.list` still lists members, and `user.group.member.list` does not exist.

- [x] **Step 3: Rename the group methods**

Rename the definitions and their self-references:

```bash
user.group.list() # # lists every group # @group:groups
{
  compgen -g "$1"
}

user.group.member.list() # <groupName> # lists the users in <groupName>: the members the group lists and the users whose primary group it is, one per line; rc 1 + RESULT for no name or an unknown group # @group:groups
{
  # body unchanged; change the usage string inside to:
  #   create.result 1 "usage: user.group.member.list <groupName>"
}
```

Update `user.group.add.completion.groupName()`:

```bash
user.group.add.completion.groupName() {
  user.group.list "$@"
}
```

Tag `user.group.add` and `user.group.member.pending`:

```bash
user.group.add() # <groupName> <?toUsername> # creates <groupName> when missing and adds <toUsername>; idempotent # @group:groups
user.group.check() # <groupName> # checks if a group exists # @group:groups
user.group.member.pending() # <group> <?user> # rc 0 when <user> is in <group> per the group database but not yet in this process # @group:groups
```

- [x] **Step 4: Complete and tag the inspect methods**

Change these declaration lines in `user` (body unchanged):

```bash
user.get() # <property> <username> # prints one property of <username>: home, basehome, shell, info or name # @group:inspect
user.info() # # prints the current user and home dir # @group:inspect
user.id() # <options="-u -n"> # shows the user id; without parameters it also shows all groups # @group:inspect
user.list() # # lists local user accounts, system accounts (leading _) left out # @group:inspect
user.list.all() # # lists all local user accounts, system accounts included # @group:inspect
```

- [x] **Step 5: Run the tests to verify they pass**

Run: `./test.suite run user 1`

Expected: PASS — `user.group.list` returns all groups; `user.group.member.list` returns members and keeps its rc guards.

- [x] **Step 6: Commit**

```bash
git add user test/test.user
git commit -m "refactor(user): split group list and member list"
```

---

## Task 6: SSH identity and legacy surface

**Files:**
- Modify: `user` (lines 8–121, 256–330, 417, 1446–1466, 1624–1700, 1773)
- Modify: `test/test.user` (identity and legacy calls)

- [x] **Step 1: Write the failing tests**

Append to `test/test.user`:

```bash
# ============================================================================
# T-USER-SSH-NAMES: identity and legacy names are the public surface
# ============================================================================
private.test.user.identityCurrent() {
  bash -c 'source this; source ossh; source user; user.ssh.identity.current'
}
test.case $level "user.ssh.identity.current returns a path" \
  private.test.user.identityCurrent

if [ -n "$(private.test.user.identityCurrent 2>/dev/null)" ]; then
  expect.pass "user.ssh.identity.current returned a path"
else
  expect.fail "user.ssh.identity.current should return a path"
fi

for m in user.ssh.init user.ssh.identity.list user.ssh.identity.use \
         user.ssh.backup.legacy.status user.ssh.backup.legacy.migrate; do
  if bash -c "source '$OOSH_DIR/this'; source '$OOSH_DIR/user'; type -t '$m'" >/dev/null 2>&1; then
    expect.pass "$m exists"
  else
    expect.fail "$m should exist"
  fi
done
```

Update the existing SSH calls in `test/test.user`:

```bash
sed -i \
  -e 's/user\.init "/user.ssh.init "/g' \
  -e 's/user\.get\.current\.identity/user.ssh.identity.current/g' \
  -e 's/user\.ssh\.backup\.status/user.ssh.backup.legacy.status/g' \
  -e 's/user\.ssh\.backup\.migrate/user.ssh.backup.legacy.migrate/g' \
  test/test.user
```

- [x] **Step 2: Run the tests to verify they fail**

Run: `./test.suite run user 1`

Expected: FAIL — the new names do not exist yet.

- [x] **Step 3: Rename the SSH methods**

Change these declaration lines in `user`:

```bash
user.ssh.init() # <?sshDir:~/.ssh> # creates a new SSH key pair and the WODA Host aliases for this user # @group:ssh
user.ssh.identity.current() # # shows the current SSH identity directory # @group:ssh
user.ssh.identity.list() # <?sshDir:~/.ssh> # lists identities in <sshDir>/ids # @group:ssh
user.ssh.identity.use() # <sshId> <?sshDir:~/.ssh> # choose another identity from user ssh.identity.list # @group:ssh
user.ssh.backup() # <?label:manual> <?sshDir:~/.ssh> # archives <sshDir> into $HOME/.ssh.backups/ under a UTC-timestamped name # @group:ssh
user.ssh.backup.list() # # lists the ssh archives under $HOME/.ssh.backups, oldest first # @group:ssh
user.ssh.restore() # <?archive:latest> <?sshDir:~/.ssh> # restores an archive from $HOME/.ssh.backups over <sshDir>; archives the current <sshDir> first # @group:ssh
user.authorized.keys.update() # <?sshDir:~/.ssh> # rebuilds authorized_keys from public_keys/ in one atomic swap # @group:ssh
```

Bodies stay unchanged. Update these self-references:

- `user.ssh.identity.use`'s body/description: replace `user list.other.identities` with `user ssh.identity.list`.
- `user.parameter.completion.sshId()`:

```bash
user.parameter.completion.sshId() {
  user.ssh.identity.list
  echo "main"
}
```

- `user.ssh.backup.legacy.status` and `.migrate` error messages: replace the literal `user.ssh.backup.status` / `user.ssh.backup.migrate` with the new names.

- [x] **Step 4: Rename the legacy methods**

Change the declarations at the top of `user`:

```bash
user.ssh.backup.legacy.status() # <?home:$HOME> # reports legacy ssh.* backup directories left in <home> by the old cwd-relative backup; rc 1 if any are found # @group:legacy
user.ssh.backup.legacy.migrate() # <?home:$HOME> # moves the legacy ssh.* backup directories in <home> under <home>/.ssh.backups/legacy/ # @group:legacy
```

Keep the bodies; update the internal messages listed in Step 3.

- [x] **Step 5: Tag the lifecycle methods**

Change the declarations:

```bash
user.start() # # # @hidden
user.usage() # # # @hidden
```

- [x] **Step 6: Run the tests to verify they pass**

Run: `./test.suite run user 1`

Expected: PASS — all renamed methods exist; identity current returns a path; legacy tests use the new names.

- [x] **Step 7: Commit**

```bash
git add user test/test.user
git commit -m "refactor(user): ssh identity and legacy names"
```

---

## Task 7: Generated usage and group order

**Files:**
- Modify: `user` (`user.usage` around line 1806)
- Test: `test/test.user`

- [x] **Step 1: Write the failing test**

Append to `test/test.user`:

```bash
# ============================================================================
# T-USER-HELP-COMPLETE: every visible method once, described, hidden absent
# ============================================================================
USAGE_OUT=$("$OOSH_DIR/user" usage 2>/dev/null)
VISIBLE=$(bash -c "source '$OOSH_DIR/this'; source '$OOSH_DIR/ng/c2'; c2 function.completion '$OOSH_DIR/user'" 2>/dev/null)
MISSING=""
for m in $VISIBLE; do
  n=$(printf '%s\n' "$USAGE_OUT" \
    | sed $'s,\x1b\\[[0-9;]*[a-zA-Z],,g' \
    | awk -v m="$m" '$1 == m { n++ } END { print n + 0 }')
  [ "$n" -eq 1 ] || MISSING="$MISSING $m($n)"
done
if [ -z "$MISSING" ]; then
  expect.pass "user usage lists every visible method once"
else
  expect.fail "user usage method count:$MISSING"
fi

if printf '%s\n' "$USAGE_OUT" | grep -q 'please add a description'; then
  expect.fail "a visible user method has no description"
else
  expect.pass "every visible user method has a description"
fi

for hidden in start usage help.group.order; do
  if printf '%s\n' "$USAGE_OUT" \
     | sed $'s,\x1b\\[[0-9;]*[a-zA-Z],,g' \
     | awk -v m="$hidden" '$1 == m { found=1 } END { exit !found }'; then
    expect.fail "hidden method $hidden leaked into usage"
  else
    expect.pass "hidden method $hidden is absent from usage"
  fi
done
```

- [x] **Step 2: Run the test to verify it fails**

Run: `./test.suite run user 1`

Expected: FAIL — `user usage` still prints the hardcoded block, missing descriptions, and hidden methods.

- [x] **Step 3: Replace `user.usage` and add the order function**

Replace the whole `user.usage` body with:

```bash
user.usage() # # # @hidden
{
  echo "user — user, group, and SSH identity management"
  echo
  this.help "${This:-$0}"
  echo
  echo "Run 'user help <word>' for the flat, filtered list."
}

user.help.group.order() # # # @hidden
{
  echo account
  echo inspect
  echo groups
  echo ssh
  echo legacy
}
```

- [x] **Step 4: Run the test to verify it passes**

Run: `./test.suite run user 1`

Expected: PASS — every `c2`-visible method appears once, no "please add a description", and `start`, `usage`, `help.group.order` are absent.

- [x] **Step 5: Commit**

```bash
git add user test/test.user
git commit -m "feat(user): generated sectioned usage"
```

---

## Task 8: Document the tag convention

**Files:**
- Modify: `templates/code/newMethod`
- Modify: `docs/command-creation.md`

- [x] **Step 1: Update the template**

Append above the method in `templates/code/newMethod`:

```bash
# Optional help metadata, on the signature line:
#   # @group:<name>   puts the method in a help section
#   # @hidden         omits the method from help and completion
newScript.newMethod()     # parameters # method description # an example
```

- [x] **Step 2: Update the docs**

Add to `docs/command-creation.md` under "Adding Methods":

```markdown
### Help metadata

An optional tag in the description field of the signature line controls the generated help:

- `# @group:<name>` — render the method under that section in `this.help`.
- `# @hidden` — omit the method from `this.help` and from `c2` completion; it stays callable.

A script that uses no tags keeps the old flat, alphabetical table. A script can fix section order by
defining `<script>.help.group.order`, one group per line.
```

`docs/user.md`, `docs/methods-index.md` and `docs/object-verb-index.md` are generated by
oosh-architect. Regenerating them is out of scope for this plan; note that in the commit message or
handoff so the next docs run picks up the new surface.

- [x] **Step 3: Commit**

```bash
git add templates/code/newMethod docs/command-creation.md
git commit -m "docs: document @group and @hidden help tags"
```

---

## Task 9: Full verification

- [x] **Step 1: Run the affected suites**

```bash
./test.suite run this 1
./test.suite run c2 1
./test.suite run user 1
./test.suite run install 1
./test.suite run completion.audit 1
```

Expected: all pass.

- [x] **Step 2: Inspect the generated help**

```bash
./user usage
./user help ssh
```

Expected: `user usage` prints `account`, `inspect`, `groups`, `ssh`, `legacy` sections with no stale `ssh.status`/`rootkey.*` lines; `user help ssh` prints a flat table containing the SSH methods with no `@group` text.

- [x] **Step 3: Confirm the worktree is clean**

```bash
git status --short
```

Expected: no output.

- [x] **Step 4: Final commit (only if Step 2 required a fix)**

```bash
git add -A
git commit -m "fix(user): final help polish"
```
