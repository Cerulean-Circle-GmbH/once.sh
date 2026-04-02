# `notests` Parameter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `<?notests>` positional parameter to `os platform.test` that skips all `test.suite core 1` runs while keeping container setup, oosh install, dev user creation, and terminal intact.

**Architecture:** Strict positional parameter at position 3 (after `<?terminal>`), parsed with the same shift pattern. The parameter gates only the three test invocations and their result evaluation. Both Docker and CI (macOS GitHub Actions) paths are updated.

**Tech Stack:** Bash (oosh), GitHub Actions YAML

---

### Task 1: Add `notests` parameter parsing to `os.platform.test()`

**Files:**
- Modify: `os:136-145` (signature and parameter parsing)
- Modify: `os:149-152` (CI call site)

- [ ] **Step 1: Update signature and add parameter parsing**

In `os:136`, change:

```bash
os.platform.test() # <platform> <?terminal> # tests oosh installation on a single platform
{
  local platform="$1"
  if [ -z "$platform" ]; then
    error.log "Usage: os platform.test <platform>"
    return 1
  fi
  shift
  local terminal="$1"
  if [ -n "$1" ]; then shift; fi
```

To:

```bash
os.platform.test() # <platform> <?terminal> <?notests> # tests oosh installation on a single platform
{
  local platform="$1"
  if [ -z "$platform" ]; then
    error.log "Usage: os platform.test <platform> <?terminal> <?notests>"
    return 1
  fi
  shift
  local terminal="$1"
  if [ -n "$1" ]; then shift; fi
  local notests="$1"
  if [ -n "$1" ]; then shift; fi
```

- [ ] **Step 2: Pass `notests` to CI call site**

In `os:151`, change:

```bash
      private.os.platform.test.ci "$platform" "$terminal"
```

To:

```bash
      private.os.platform.test.ci "$platform" "$terminal" "$notests"
```

- [ ] **Step 3: Add completion function**

After the existing `os.platform.test.completion.terminal()` block (after `os:307`), add:

```bash
os.platform.test.completion.notests() {
  echo "notests"
}
```

### Task 2: Gate test execution in the Docker path

**Files:**
- Modify: `os:226-298` (test runs and result evaluation)

- [ ] **Step 1: Wrap user, root, and dev test runs**

Replace `os:226-263` (from `# Run user tests first` through the dev test `local rcDev=...` line):

```bash
  # Run user tests first (clean shared config state)
  console.log "Running core tests as user test..."
  local userLog="/tmp/oosh-platform-test-user-$platform.log"
  ossh exec "$platform" "test.suite core 1" 2>&1 | tee "$userLog"
  local rcUser=${PIPESTATUS[0]}

  # Run tests as root (needs -tt for sudo TTY)
  console.log "Running core tests as root..."
  local rootLog="/tmp/oosh-platform-test-root-$platform.log"
  ossh exec.tty "$platform" "sudo bash -lc 'source /root/config/user.env 2>/dev/null; export PATH=/root/oosh:\$PATH; test.suite core 1'" 2>&1 | tee "$rootLog"
  local rcRoot=${PIPESTATUS[0]}

  # Test adding a second user via ossh install (auto-creates dev user)
  console.log "Adding second user: dev"
  ossh install "$platform" dev || {
    error.log "Failed to add dev user on $platform"
  }

  # Configure passwordless sudo for dev (container is ephemeral)
  ossh exec "$platform" "echo 'test' | sudo -S sh -c 'echo \"dev ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers'"

  # Reconnect as dev user and run tests
  ossh connection.close "$platform" 2>/dev/null
  local devConfig="${platform}_dev"
  ossh config.create "$devConfig" "dev@localhost:$sshPort"
  ossh config.save.last
  rm -f "/tmp/ossh-dev@localhost:$sshPort" 2>/dev/null
  SSHPASS=dev sshpass -e ssh \
    -o ControlMaster=yes \
    -o ControlPath="$OSSH_CONTROL_PATH" \
    -o ControlPersist=600 \
    -o StrictHostKeyChecking=accept-new \
    "$devConfig" true

  console.log "Running core tests as user dev..."
  local devLog="/tmp/oosh-platform-test-dev-$platform.log"
  ossh exec "$devConfig" "test.suite core 1" 2>&1 | tee "$devLog"
  local rcDev=${PIPESTATUS[0]}
```

With:

```bash
  local rcUser=0 rcRoot=0 rcDev=0
  local userLog="" rootLog="" devLog=""

  if [ -z "$notests" ]; then
    # Run user tests first (clean shared config state)
    console.log "Running core tests as user test..."
    userLog="/tmp/oosh-platform-test-user-$platform.log"
    ossh exec "$platform" "test.suite core 1" 2>&1 | tee "$userLog"
    rcUser=${PIPESTATUS[0]}

    # Run tests as root (needs -tt for sudo TTY)
    console.log "Running core tests as root..."
    rootLog="/tmp/oosh-platform-test-root-$platform.log"
    ossh exec.tty "$platform" "sudo bash -lc 'source /root/config/user.env 2>/dev/null; export PATH=/root/oosh:\$PATH; test.suite core 1'" 2>&1 | tee "$rootLog"
    rcRoot=${PIPESTATUS[0]}
  else
    console.log "Skipping tests (notests)"
  fi

  # Test adding a second user via ossh install (auto-creates dev user)
  console.log "Adding second user: dev"
  ossh install "$platform" dev || {
    error.log "Failed to add dev user on $platform"
  }

  # Configure passwordless sudo for dev (container is ephemeral)
  ossh exec "$platform" "echo 'test' | sudo -S sh -c 'echo \"dev ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers'"

  # Reconnect as dev user and run tests
  ossh connection.close "$platform" 2>/dev/null
  local devConfig="${platform}_dev"
  ossh config.create "$devConfig" "dev@localhost:$sshPort"
  ossh config.save.last
  rm -f "/tmp/ossh-dev@localhost:$sshPort" 2>/dev/null
  SSHPASS=dev sshpass -e ssh \
    -o ControlMaster=yes \
    -o ControlPath="$OSSH_CONTROL_PATH" \
    -o ControlPersist=600 \
    -o StrictHostKeyChecking=accept-new \
    "$devConfig" true

  if [ -z "$notests" ]; then
    console.log "Running core tests as user dev..."
    devLog="/tmp/oosh-platform-test-dev-$platform.log"
    ossh exec "$devConfig" "test.suite core 1" 2>&1 | tee "$devLog"
    rcDev=${PIPESTATUS[0]}
  fi
```

- [ ] **Step 2: Update result evaluation**

Replace `os:277-298` (from `if [ $rcRoot -eq 0 ]` through `fi`):

```bash
  if [ $rcRoot -eq 0 ] && [ $rcUser -eq 0 ] && [ $rcDev -eq 0 ]; then
    printf "PASS: %s (root=%d, user=%d, dev=%d)\n" "$platform" "$rcRoot" "$rcUser" "$rcDev"
    important.log "PASS: $platform (root=$rcRoot, user=$rcUser, dev=$rcDev)"
    create.result 0 "PASS"
    rm -f "$userLog" "$rootLog" "$devLog"
    rc=0
  else
    printf "FAIL: %s (root=%d, user=%d, dev=%d)\n" "$platform" "$rcRoot" "$rcUser" "$rcDev"
    error.log "FAIL: $platform (root=$rcRoot, user=$rcUser, dev=$rcDev)"
    if [ $rcUser -ne 0 ]; then
      error.log "--- USER test failures (grep FAIL) ---"
      grep -i "FAIL\|✗" "$userLog" 2>/dev/null
      error.log "--- Full user log: $userLog ---"
    fi
    if [ $rcRoot -ne 0 ]; then
      error.log "--- ROOT test failures (grep FAIL) ---"
      grep -i "FAIL\|✗" "$rootLog" 2>/dev/null
      error.log "--- Full root log: $rootLog ---"
    fi
    create.result 1 "FAIL"
    rc=1
  fi
```

With:

```bash
  if [ -n "$notests" ]; then
    printf "PASS: %s (tests=skipped)\n" "$platform"
    important.log "PASS: $platform (tests=skipped)"
    create.result 0 "PASS"
    rc=0
  elif [ $rcRoot -eq 0 ] && [ $rcUser -eq 0 ] && [ $rcDev -eq 0 ]; then
    printf "PASS: %s (root=%d, user=%d, dev=%d)\n" "$platform" "$rcRoot" "$rcUser" "$rcDev"
    important.log "PASS: $platform (root=$rcRoot, user=$rcUser, dev=$rcDev)"
    create.result 0 "PASS"
    rm -f "$userLog" "$rootLog" "$devLog"
    rc=0
  else
    printf "FAIL: %s (root=%d, user=%d, dev=%d)\n" "$platform" "$rcRoot" "$rcUser" "$rcDev"
    error.log "FAIL: $platform (root=$rcRoot, user=$rcUser, dev=$rcDev)"
    if [ $rcUser -ne 0 ]; then
      error.log "--- USER test failures (grep FAIL) ---"
      grep -i "FAIL\|✗" "$userLog" 2>/dev/null
      error.log "--- Full user log: $userLog ---"
    fi
    if [ $rcRoot -ne 0 ]; then
      error.log "--- ROOT test failures (grep FAIL) ---"
      grep -i "FAIL\|✗" "$rootLog" 2>/dev/null
      error.log "--- Full root log: $rootLog ---"
    fi
    create.result 1 "FAIL"
    rc=1
  fi
```

- [ ] **Step 3: Commit Docker path changes**

```bash
git add os
git commit -m "feat(os): add notests parameter to os.platform.test

Allows skipping test.suite runs while keeping container setup,
oosh install, dev user creation, and terminal intact.

Usage: os platform.test <platform> terminal notests"
```

### Task 3: Update `private.os.platform.test.ci()` for notests passthrough

**Files:**
- Modify: `os:60-83` (CI function signature and gh workflow call)

- [ ] **Step 1: Update CI function signature and parameter**

In `os:60-63`, change:

```bash
private.os.platform.test.ci() # <platform> <?terminal> # triggers CI workflow for native platform testing
{
  local platform="$1"
  local terminal="$2"
```

To:

```bash
private.os.platform.test.ci() # <platform> <?terminal> <?notests> # triggers CI workflow for native platform testing
{
  local platform="$1"
  local terminal="$2"
  local notests="$3"
```

- [ ] **Step 2: Pass notests to workflow dispatch**

In `os:83`, change:

```bash
  if ! gh workflow run macos-test.yml -R "$repo" -r "$branch" -f branch="$branch" -f terminal="${terminal:-}"; then
```

To:

```bash
  if ! gh workflow run macos-test.yml -R "$repo" -r "$branch" -f branch="$branch" -f terminal="${terminal:-}" -f notests="${notests:-}"; then
```

- [ ] **Step 3: Commit CI passthrough**

```bash
git add os
git commit -m "feat(os): pass notests parameter through to macOS CI workflow"
```

### Task 4: Update `macos-test.yml` workflow

**Files:**
- Modify: `.github/workflows/macos-test.yml:1-169`

- [ ] **Step 1: Add notests input**

After the `terminal` input block (after line 12), add:

```yaml
      notests:
        description: 'Skip test runs (pass "notests" to enable)'
        required: false
        default: ''
```

- [ ] **Step 2: Add conditions to test steps**

Add `if: github.event.inputs.notests != 'notests'` to the three test steps and summary.

On line 101 ("Run tests as user"), change:

```yaml
      - name: Run tests as user
        id: user-tests
        continue-on-error: true
```

To:

```yaml
      - name: Run tests as user
        if: github.event.inputs.notests != 'notests'
        id: user-tests
        continue-on-error: true
```

On line 109 ("Run tests as root"), change:

```yaml
      - name: Run tests as root
        id: root-tests
        continue-on-error: true
```

To:

```yaml
      - name: Run tests as root
        if: github.event.inputs.notests != 'notests'
        id: root-tests
        continue-on-error: true
```

On line 129 ("Run tests as dev"), change:

```yaml
      - name: Run tests as dev
        id: dev-tests
        continue-on-error: true
```

To:

```yaml
      - name: Run tests as dev
        if: github.event.inputs.notests != 'notests'
        id: dev-tests
        continue-on-error: true
```

On line 146 ("Test Summary"), change:

```yaml
      - name: Test Summary
        if: always()
```

To:

```yaml
      - name: Test Summary
        if: always() && github.event.inputs.notests != 'notests'
```

The "Add dev user" step (line 119) stays unchanged — dev user creation always runs.

The "Interactive terminal (tmate)" step (line 163) stays unchanged — it already has its own `terminal` condition.

- [ ] **Step 3: Commit workflow changes**

```bash
git add .github/workflows/macos-test.yml
git commit -m "feat(ci): support notests parameter in macOS test workflow

Skips test steps when notests is passed, keeping install and
dev user creation intact for interactive debugging."
```

### Task 5: Verify

- [ ] **Step 1: Verify tab completion works**

```bash
c2 function.completion os platform.test
```

Expected: shows `platform`, `terminal`, `notests` parameter completions.

- [ ] **Step 2: Test with Docker (notests + terminal)**

Run in tmux lower pane:

```bash
os platform.test alpine terminal notests
```

Expected:
- Container builds/resets
- oosh installs
- Dev user created
- NO `test.suite core 1` output
- Interactive terminal opens
- After `exit`, cleanup runs
- Output includes `PASS: alpine (tests=skipped)`

- [ ] **Step 3: Test without notests (regression check)**

```bash
os platform.test alpine
```

Expected: All three test suites run as before (user, root, dev), results reported normally.
