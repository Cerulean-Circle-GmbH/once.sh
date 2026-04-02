# Design: `notests` parameter for `os platform.test`

## Context

When debugging platform issues or exploring a freshly-installed oosh container, you often want `os platform.test <platform> terminal` to skip the three `test.suite core 1` runs (user, root, dev) and drop straight into the interactive shell. Currently there's no way to skip tests — you must wait for all three test passes before the terminal opens.

## Design

Add `<?notests>` as the 3rd positional parameter to `os.platform.test`, using strict positional parsing (same shift pattern as existing `<?terminal>`). Since oosh positional parameters are sequential, `notests` physically requires `terminal` to be specified first — which enforces the intended dependency.

### Signature

```
os.platform.test() # <platform> <?terminal> <?notests> # tests oosh installation on a single platform
```

### Usage

```bash
os platform.test alpine                      # run tests, no terminal
os platform.test alpine terminal             # run tests, then open terminal
os platform.test alpine terminal notests     # skip tests, open terminal
```

### Files changed

#### 1. `os` — `os.platform.test()` (line 136)

- Update signature comment to `# <platform> <?terminal> <?notests>`
- Parse `$notests` after `$terminal` with same `shift` pattern
- Wrap user/root/dev `test.suite core 1` calls in `if [ -z "$notests" ]` guards
- When `notests` is set, skip test log variables and test result evaluation — go straight to terminal/cleanup
- Add `os.platform.test.completion.notests()` returning `"notests"`

#### 2. `os` — `private.os.platform.test.ci()` (line 60)

- Update signature to `# <platform> <?terminal> <?notests>`
- Accept `$3` as `notests`
- Pass `-f notests="${notests:-}"` to `gh workflow run`

#### 3. `.github/workflows/macos-test.yml`

- Add `notests` workflow input (optional, default `''`)
- Add condition `if: github.event.inputs.notests != 'notests'` to:
  - "Run tests as user" step
  - "Run tests as root" step
  - "Run tests as dev" step
  - "Test Summary" step
- The tmate terminal step already has `if: always() && ...terminal == 'terminal'` — no change needed

### What always runs (even with notests)

- Container build/reset
- SSH setup and ControlMaster
- Key push
- oosh install
- Dev user creation
- Interactive terminal (when `terminal` is set)
- Cleanup

### What is skipped with notests

- `test.suite core 1` as user
- `test.suite core 1` as root
- `test.suite core 1` as dev
- Test result evaluation and log file handling
