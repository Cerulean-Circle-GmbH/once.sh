# otmux Auto-Install Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Auto-install tmux when any otmux command is run and tmux is not yet installed.

**Architecture:** Add a `command -v tmux` guard in `otmux.start()` that delegates to the existing `otmux.install()` method. Two grep-based test cases validate the guard exists.

**Tech Stack:** Bash, oosh test.suite, `oo cmd` package management

**Design doc:** `docs/plans/2026-03-03-otmux-auto-install-design.md`

---

### Task 1: Write the failing tests

**Files:**
- Modify: `test/test.otmux:127` (insert before Test Summary section)

**Step 1: Add T9 and T10 test cases**

Insert the following before the `# Test Summary` section (line 128):

```bash
# ============================================================================
# T9: otmux.start contains auto-install guard
# ============================================================================
test.case $level "otmux.start auto-installs tmux if missing" \
  grep -q "command -v tmux" "$OOSH_DIR/otmux"

if grep -qP 'otmux\.start\(\).*\n.*\{[\s\S]*?command -v tmux' "$OOSH_DIR/otmux"; then
  expect.pass "otmux.start contains tmux install guard"
else
  expect.fail "otmux.start should check for tmux and auto-install"
fi

# ============================================================================
# T10: otmux.install function is defined
# ============================================================================
test.case $level "otmux.install function defined in script" \
  grep -q "^otmux.install()" "$OOSH_DIR/otmux"

if grep -q "^otmux.install()" "$OOSH_DIR/otmux"; then
  expect.pass "otmux.install function defined"
else
  expect.fail "otmux.install should be defined in otmux script"
fi
```

**Step 2: Run tests to verify T9 fails and T10 passes**

Run: `./test.suite run otmux 1`

Expected: T9 FAILS (guard not yet in otmux.start), T10 PASSES (otmux.install already exists)

---

### Task 2: Implement the auto-install guard

**Files:**
- Modify: `otmux:2216-2227` (the `otmux.start()` function)

**Step 1: Add tmux check to otmux.start()**

Replace `otmux.start()` at line 2216 with:

```bash
otmux.start()
{
  #echo "sourcing init"
  source this

  # Auto-install tmux if missing
  if ! command -v tmux &>/dev/null; then
    otmux.install || return 1
  fi

  if [ -z "$1" ]; then
    otmux.status
    return 0
  fi

  this.start "$@"
}
```

**Step 2: Run tests to verify all pass**

Run: `./test.suite run otmux 1`

Expected: All T1-T10 PASS

---

### Task 3: Run full test suite and commit

**Step 1: Run full test suite**

Run: `./test.suite all 1`

Expected: All tests pass, no regressions

**Step 2: Commit**

```bash
git add otmux test/test.otmux
git commit -m "feat(otmux): auto-install tmux on first call

Add command -v tmux guard in otmux.start() that calls
otmux.install when tmux is missing. Uses oo cmd for
oosh-idiomatic package management."
```
