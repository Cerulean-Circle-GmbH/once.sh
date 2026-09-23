# Test Suite Documentation

## Overview
The oosh/once.sh project uses a comprehensive Bash-based test suite to ensure reliability, correctness, and safe refactoring. All test scripts are located in the `test/` directory and follow strict conventions for structure and usage.

## Structure & Conventions
- **Naming:** Test scripts are named `test.<command>` (e.g., `test.mycmd`, `test.oosh`, `test.c2`).
- **Location:** All test scripts reside in the `test/` directory.
- **Sourcing:** Each script sources `test.suite` for test utilities and result tracking, and typically sources the command under test.
- **Setup:** Logging and environment are initialized at the start of each script.

## Writing Tests
- **Test Cases:** Use `test.case` to run a function or command and capture results.
- **Assertions:** Use `expect` to assert return values and outputs. Use `expect.error` for negative tests.
- **Result Tracking:** Results are summarized for each test and the overall suite.

## Running Tests
- **Single Test:** `test.suite run <command>` (e.g., `test.suite run mycmd`)
- **All Tests:** `test.suite all`
- **Output:** Test results are summarized, showing the number of successful and expected cases, and reporting any failures.

## Example Test Script
```bash
#!/usr/bin/env bash
source test.suite $*
log.level $level

test.case - "direct call with parameter" \
  mycmd 3 f g 1 a b c
expect 0 "result not loaded" "$RESULT after a direct call"

# More test cases ...
```

## Advanced & Edge Testing
- **Shell Features:** Some tests (e.g., `test.tilde`, `test.absolute.path`) focus on shell or path behaviors.
- **Completion & Parameters:** Scripts like `test.c2` and `test.data/parameterTestScript` test completion logic and parameter parsing.
- **Error Handling:** Use `expect.error` to check for expected failures and edge cases.

### Diagnostic-rich assertions with `expect.pass` / `expect.fail`
When a test must surface an actionable recovery hint on failure
(more useful than "Expected return: 0, got: 1"), use
`expect.pass "<context>"` and `expect.fail "<reason + recovery>"`
instead of the value-comparing `expect 0 "*"` form. The framework
prints the message verbatim to the test report:

```bash
test.case - "T-USER-FIX-EXISTS: oo.user.fix is defined" \
  type oo.user.fix
if type oo.user.fix >/dev/null 2>&1; then
  expect.pass "oo.user.fix is defined"
else
  expect.fail "oo.user.fix should be defined — run \`oo update\` to re-source"
fi
```

This is the right pattern for real-environment integration tests
(e.g. `T-MODE-COMPLETION-REAL-ENV` in `test/test.oo`,
`test/test.platform.shared.oosh.invariant`) where the fail message
is the user's first signal that something needs fixing.

### Platform-category tests
Tests with `TEST_CATEGORY=platform` (e.g.
`test.platform.shared.config.invariant`,
`test.platform.shared.oosh.invariant`) verify post-install
invariants on real machines. They run inside
`os platform.test <platform> terminal` containers via
`./test.suite run <name> 1`. See
`templates/code/newPlatformInvariantTest` for the skeleton.

**A host-resource check belongs here, not in `core`.** If an assertion needs
something the oosh install does not itself create — a checkout of another
repository, a daemon, a tree under `/var` — it cannot pass on a fresh machine or
inside a container, and `os platform.test` runs `test.suite core 1` four times
per gate. Do not reach for a `[ -d … ] → expect.pass "skipped"` guard either:
`expect.pass` bumps both counters and `expect.fail` only one, so **a skip is
indistinguishable from a pass** and the assertion silently stops asserting
everywhere it matters.

The worked example is `test/test.odocker`, 2026-09-17. Six assertions checked
that this machine had the EAMD.ucp `DockerWorkspaces` tree; they failed 6 × 4 on
every container gate. They split into `T-WS-LIST` in `core` — which tests the
enumerator against a fixture built with `odocker workspace.init` and passes
anywhere — and `test/test.platform.odocker.workspaces.invariant`, which keeps
the host-readiness question where it belongs.

### Bootstrap-from-nothing assertions: `test.suite.anchors.check`

`test.suite.anchors.check <sourceCommand>` is the one harness behind every
"stand the environment up from `~/config/user.env`" assertion (test.config T65,
test.platform.profile.dropin.invariant INVARIANT-5). It runs `<sourceCommand>`
under `env -i` — with `HOME` set from the password database, via
`test.suite.home.passwd` — in `sh`, `dash`, `ash`, `bash` and `busybox ash`,
and prints nothing when every shell yields this user's `[$HOME|~/oosh|~/config]`
anchors and survives the source; otherwise one `shell=>output` per failure.

```bash
bad=$(test.suite.anchors.check '. "$HOME/config/user.env"')
[ -z "$bad" ] && create.result 0 "every shell anchors" || create.result 1 "shells that did not:$bad"
```

`HOME` is *passed*, deliberately: the data route cannot derive it. Deriving
`$HOME` is the login drop-in's job (`/etc/profile.d/oosh.sh`), asserted
separately through `env -i sh -l` in the platform test.

## The runner guards the shared config tier

You do not have to remember to isolate for the guard to catch you. Before the first test file, the
runner copies `user.env`, `oosh.env` and `log.env` out of the inherited `$CONFIG_PATH` and
fingerprints them (content checksum, size and mtime — the checksum is load-bearing, because BSD
`stat` reports whole seconds and a test rewrite lands inside one). After **every** `core` and
`extended` file it compares. A file that changed any of the three is reported like this:

```
  ✗ SHARED CONFIG WRITTEN: test.myscript wrote the shared config tier: oosh.env
    fix: add  test.suite.config.isolate test.myscript  before the 'source' of the script under test
    the tier has been restored from this run's snapshot
```

and **the whole run fails**, in every category. The tier is then put back from the snapshot, so one
bad test file does not leave the site-wide config broken for everyone else on the box. The failure
is the point; the restore is damage control.

`TEST_CATEGORY=platform` files are exempt. They assert on the real installed machine, which is the
entire reason that category exists.

### When a file cannot be isolated yet

Two `core` files reach a production `config save` and **cannot be fixed today**:
`test.completion.audit` and `test.config`. Both `source` the `config` script, whose `config.start`
re-runs `config.init`, and `config.init` does an unconditional `export CONFIG_PATH=~/config`. The
fixture is undone from inside the file under test. That is T7's blocker, not a test defect.

Such a file declares it, in the file, next to `TEST_CATEGORY`:

```bash
TEST_SHARED_TIER_WRITER="blocked on T7: …the reason, and the ticket that removes it"
```

The guard still reports the file, still names which shared file changed, and still restores the
tier. It only stops the run going red, and the line turns yellow and says `(known)` with the
declared reason. The summary counts waived files on their own line.

**A waiver is a confession, not an exemption.** It names the ticket that will delete it, it lives
in the file rather than in a list inside the runner so it cannot outlive the fix by accident, and
the count is meant to reach zero. Do not add one to make a red run green; add one only when the
write is genuinely unreachable from the test file, and say why.

Why this is not visible on a dev host: `log.env` is only rewritten when its content actually
differs, and the persisted `LOG_LEVEL` here happens to equal the level the suite runs at. In a
container that persists `3` while the suite runs at `1`, the same write changes the file. The guard
is right either way; the host just has nothing to report.

This catches strictly more than isolation prevents. `test.suite.config.isolate` redirects writes
addressed through `$CONFIG_PATH`; it can do nothing about a hardcoded `~/config` path. That is not
hypothetical — `test.log`'s T31 wrote the real shared `log.env` through `$HOME/config/log.env`
while the file believed itself isolated, until 2026-09-15. The fingerprint sees the write whatever
route it took.

**The handoff is no longer in the shared tier either.** `testresult.env` used to land in
`$CONFIG_PATH`, so two users running tests at the same time overwrote each other's scores. The
runner now gives each run a private `mktemp -d` and exports it as `TEST_SUITE_RESULT_PATH`. A
caller that pins that variable itself is never overridden — that is how the meta-test drives a
nested runner.

## Isolating a test from the shared config

`~/config` (`$CONFIG_PATH`) is normally a **site-wide `sharedConfig`** that every user sources at
login. A test that reaches a production `config save` rewrites it for everybody. If the script under
test can persist anything, isolate first:

```bash
source this
source test.suite
test.suite.config.isolate test.myscript >/dev/null || exit 1
source myscript          # <- after the isolate line
```

`test.suite.config.isolate` points `CONFIG_PATH`, `CONFIG_FILE` and `CONFIG` at a fresh `mktemp`
directory, **and touches `$CONFIG`**. All four moves are required. The touch is not tidiness:
`config.start` re-runs `config.init` whenever `$CONFIG` is not a file, and `config.init` then does an
unconditional `export CONFIG_PATH=~/config`. Setting the path alone is therefore not isolation — the
next `source $OOSH_DIR/config` silently snaps back to the shared dir while the test believes it is
safe. `isolate` refuses loudly rather than half-isolating, and `test.suite.config.restore` is
installed as an `EXIT` trap (chained onto any trap the file already had).

**Your score is unaffected.** `test.suite.save.results` writes to `TEST_SUITE_RESULT_PATH`, which
the runner owns and exports; isolating your config does not move it. Without that separation a file
that isolated would write its score into its own fixture, and the runner would report `0 / 0` for a
file that really ran.

**Two variables, two jobs.** `TEST_SUITE_RESULT_PATH` is where the score goes.
`TEST_SUITE_CONFIG_ORIGIN` is the config tier this process inherited — it is what
`test.suite.config.restore` puts back into `CONFIG_PATH`, and what the runner snapshots. They were
one variable until 2026-09-16, which was only correct while the score happened to live in the
config tier.

**What `CONFIG_PATH` does not cover:** `~/.gitconfig` (use `GIT_CONFIG_GLOBAL`), and `log`'s
`~/config/result.txt` / `error.txt`, which are hardcoded to `$HOME`.

## Every file scores itself

`test.suite.save.results` at the end of a test file is **mandatory**, not decorative. Test files run
as child processes (the runner invokes `$file` directly), so the only channel back to the runner is
the handoff file `testresult.env`. A file that never calls `test.suite.save.results` produces no
score of its own.

Until 2026-09-15 such a file was silently given the **previous** file's numbers, because the runner
cleared only its shell variables and left the handoff behind. `test.tilde` reporting `test.this`'s
31 assertions was the instance that exposed it. The runner now clears the handoff *before* each
file — so it exists if and only if that file wrote it — and a file that produced none is reported
`0 / 0`, named on its own line, and counted in a `No results:` summary at the end.

If you see `⚠ NO RESULTS: test.<name> produced no score of its own`, that file is not being
measured. Add `test.suite.save.results` as its last line.

Since 2026-09-16 that warning **fails a `core` run**. All twenty-six `core` files score today, so
the rule costs nothing now and exists to catch the regression. `extended` keeps the warning without
failing, because twelve of its files have never scored and giving them one is content work, not
runner work.

The whole pass/fail rule lives in one place, `private.test.suite.verdict`, so it can be tested. It
used to be an if/elif chain in the tail of the runner that nothing could reach — which is how both
of these causes came to be printed on screen and then dropped before the return code that the macOS
workflow and `os platform.test` actually gate on.

## The test tree is itself checked for portability

```bash
test.suite portability.validate [<treeRoot>]     # default: $OOSH_DIR/test
```

A test that assumes GNU coreutils or a Linux filesystem does not fail honestly. It reports **the
code under test** as broken while that code is fine, with a confident and specific message that
sends you to debug the wrong thing. Three of those on 2026-09-17 alone:

| Construct | What it did |
|---|---|
| `grep '…$\|…$'` | `\|` is a GNU BRE extension. BSD `grep` counted 0 and the test blamed `user.ssh.backup.list`. |
| a raw `mktemp` path | macOS `/tmp` is a symlink to `/private/tmp`, so a path the code **resolves** never equals the fixture literal. Eight assertions blamed `oo.mode`, `base.get` and `workspace.init`. |
| `script -qec '<cmd>'` | does not guarantee which shell runs the command. Under dash the probe died on `source: not found`, never sourced `log`, and blamed log's D4 guard in every container. |

`test.suite.portability.validate` is the sibling of `path.validate` and `this.anchor.validate` and
has the same shape: one `git grep` sweep of the tree, a verdict **echoed to stdout** so it survives
any `LOG_LEVEL`, and `create.result` / `return $(result)`. It differs in one way on purpose — it
scans **test** code, not production code. Production portability is enforced by running the thing
on the platforms (the macOS and container gates); nothing ran the test harness anywhere new often
enough to catch these.

`T-PORTABILITY-TREE` in `test/test.test.suite` is the gate, so a new offender fails `core` on the
machine that introduces it rather than on someone's Mac a week later.

### Two severities

A **violation** is wrong wherever it stands and fails the gate (rc 1): the BRE `\|`, `readlink -f`,
`grep -P`, `date -d`, a bare `sed -i`, an unpaired `stat -c`, and `script -qec` handed a command
without naming the shell. The tree ships at **zero** of these.

An **advisory** is *latent* — correct today, wrong the day someone compares its result against a
canonicalised path. `mktemp` is the whole of that class, at 82 sites. Converting all of them in
one commit would be churn with no test behind it, so the sweep **marks** them, reports a per-file
tally through `warn.log`, and leaves the gate actionable. Convert one whenever you are in the file
anyway:

```bash
fixture=$(test.suite.fixture.make my.label)   # mktemp -d + private.this.path.canonical
```

Both `sed -i` and `mktemp` carry a **command-position anchor** — `(^|[|;&(`]|\$\()[[:space:]]*` —
so a construct merely *named* in a message string is not counted as a use of it. Without it the
mktemp rule matched `|| { create.result 1 "mktemp failed"; … }`, the commonest line in the tree
containing the word, and over-counted its own tally by 43% (119 reported against 82 real). A
validator that reports faults which are not there is doing a mild version of exactly what this
sweep exists to stop, so `T-PORTABILITY-ADVISORY-STRING` pins it.

### Declaring a deliberate one

Put `# portability-exception: <reason>` on the line, or in the five lines just above it — the same
affordance `path.validate` gives, and the escape hatch for a construct that is the point of the
test. The marker must be in a **comment**, so a string that merely names a construct cannot exempt
itself.

Some correct shapes need no marker at all, because the sweep understands them: `grep -E` (where
`\|` is an escaped *literal* pipe), a GNU form with its BSD fallback (`stat -c … || stat -f …`,
`date -r … || date -d …`) including when the pair is written across a continued line, and
`script -qec "bash <file>"`, where naming the shell **is** the fix.

### The rules are measured, not reasoned

Each one was checked against a real BSD userland on the macOS VM, because a portability rule
justified by reasoning is exactly what this sweep exists to stop. `stat -c`, `date -d`, `grep -P`,
`sed -i <script>` and `script -qec` are all *illegal option* there. `readlink -f` in fact **works**
on macOS 12.3+, so that rule is about older BSD — it stays a violation only because
`private.this.path.canonical` already exists and carries the fallback for free.

The `\|` case is the one that justifies the whole card: on BSD grep it does not error and does not
return zero — it returns **1 where the answer is 2**. A wrong count, silently, in a test that then
reports the code under test as broken. The full probe table is in
[the research doc](research/2026-09-17-shared-tier-leak-macos.md).

## Best Practices
- Use `test.case` for each logical test scenario.
- Use `expect` to assert both return values and output.
- Source the command under test and any required dependencies.
- Keep tests isolated and repeatable.
- Document the purpose of each test at the top of the script.

## Test Coverage
The suite covers a wide range of commands and scenarios, including:
- Core utilities (e.g., `test.loop`, `test.call`, `test.line`)
- Completion and parameter parsing (`test.c2`, `test.data/parameterTestScript`)
- File system and environment (`test.fs`, `test.tilde`, `test.absolute.path`)
- Error handling and edge cases

## See Also
- [First Principles](first-principles.md)
- [Outline](outline.md)
- [completion-system.md](completion-system.md) (for completion/parameter testing)
- [command-creation.md](command-creation.md)
