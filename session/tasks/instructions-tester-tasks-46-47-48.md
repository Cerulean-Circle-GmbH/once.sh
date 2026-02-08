# Tester: Validate Tasks 48, 46, 47 (in that order)

Validate each as Expert commits. Task 48 first (critical).

---

## Task 48 — Watchdog (Critical)

### Test 1: watchdog starts
```bash
./hiveMind watchdog
# Should spawn a new tmux pane running the sweep/unblock loop
```

### Test 2: watchdog runs as plain bash (no Claude Code)
```bash
# Check the watchdog pane — should show a bash loop, not a Claude Code session
# Look for the while loop output, no ❯ prompt
```

### Test 3: watchdog.status reports running
```bash
./hiveMind watchdog.status
```

### Test 4: watchdog.stop kills it
```bash
./hiveMind watchdog.stop
./hiveMind watchdog.status
# Should report not running
```

### Test 5: Syntax check
```bash
bash -n hiveMind && echo "PASS" || echo "FAIL"
```

Report: `Task 48 validation: PASS/FAIL`

---

## Task 46 — Background Tasks Overlay Detection

### Test 1: sweep.detect recognizes overlay
```bash
grep -n 'Background tasks\|overlay.*escape' hiveMind | head -5
```

### Test 2: unblock sends Escape for overlay
```bash
grep -A 5 'overlay\|escape' hiveMind | grep -i 'escape\|Escape'
```

### Test 3: Existing permission handling unchanged
```bash
grep -n 'Allow.*Deny\|Do you want to proceed\|accept edits' hiveMind | head -10
```

### Test 4: Syntax check
```bash
bash -n hiveMind && echo "PASS" || echo "FAIL"
```

Report: `Task 46 validation: PASS/FAIL`

---

## Task 47 — ./ Prefix Fix

### Test 1: settings.json has matching patterns
```bash
grep -E 'hiveMind|scrumMaster' .claude/settings.json | head -10
# Should match both ./hiveMind and hiveMind patterns
```

### Test 2: No regressions
```bash
# Verify other permission patterns still present
grep -c 'allow' .claude/settings.json
```

### Test 3: Syntax check on any modified scripts
```bash
bash -n hiveMind && echo "PASS" || echo "FAIL"
```

Report: `Task 47 validation: PASS/FAIL`
