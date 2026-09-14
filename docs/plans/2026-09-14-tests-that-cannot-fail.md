# Ticket: tests that cannot fail

**Created:** 2026-09-14 · **Branch:** `dev` · **Status:** 💡 proposed — not yet on the board
**Found while:** implementing T3 (a reviewer caught it in a single test; it generalises)

## The defect

A test whose function calls `create.result 1` — **a failure** — reports **PASS**, if two conditions
hold. Both are common in this suite.

**Condition 1: the function does not end with `return $(result)`.** Measured:

```
create.result 1 "deliberately failing"                    -> function exit status: 0
create.result 1 "deliberately failing"; return $(result)  -> function exit status: 1
```

`create.result` only *assigns* `RETURN_VALUE`; the function's own exit status is that of its last
command, which is `info.log`'s — always 0. `test.case` then does `RETURN_VALUE=$?` and overwrites
the real verdict with that 0.

**Condition 2: the assertion is `expect 0 "*"`.** `test.suite:523`:

```bash
if [ "$expectedresult" = "*" ]; then
  expectedresult=$RESULT
fi
```

The wildcard sets the expectation *to whatever the result was*, so the string comparison is
tautological.

Either condition alone leaves one working discriminator. **Together there is none** — the test
passes for any behaviour, including the behaviour it exists to forbid.

## How it was found

While hardening `test.config` T51, a reviewer ran a **negative control**: they forced `boot` to
recover instead of refuse — the exact thing T51 forbids — and T51 still reported PASS. Without that
control the test would have shipped looking green.

## Scope

**57 uses of `expect 0 "*"` across 26 test files:**

```
test.oo 15 · test.check 7 · test.this 5 · test.call 5 · test.promote 2 · test.loop 2
test.config 2 · and 19 files with 1 each
```

Sampled the first 8 in `test.oo` — **all 8** lack `return $(result)`, so all 8 satisfy both
conditions. The true count needs a proper audit; 57 is the upper bound and 8/8 is the sample.

## Why this matters more than it looks

The suite is the evidence base for every "green" claim made about this codebase. A test that cannot
fail is worse than no test: it occupies the space where a real one would go and reports success
while doing it. Today a regression reached a container and was only caught by a platform run —
worth asking how many unit tests were standing silently by.

## Definition of done

- [ ] Audit all 57 wildcard assertions: for each, does its function end with `return $(result)`?
- [ ] For every test that can be shown vacuous, either add `return $(result)` or replace
      `expect 0 "*"` with a real expectation — then **prove it can fail** with a negative control
- [ ] Decide the standing idiom. Options: require `return $(result)` in every test function;
      make `create.result` set the exit status itself; or have `test.case` warn when a function
      returns 0 while `RETURN_VALUE` is non-zero
- [ ] A guard so this cannot regress — e.g. a test that plants a deliberately-failing function and
      asserts the suite reports it as failed
- [ ] Standing verification bar passes

## Verification

```bash
# reproduce the core defect
create.result 1 "x"; echo $?          # prints 0 — the failure is discarded

# find the candidates
grep -rn 'expect 0 "\*"' test/

# for any given test, the only trustworthy check is a negative control:
# break what it claims to protect, and confirm it goes red
```

## Note on the fix

`create.result` setting its own exit status would fix every case at once — but it is called
everywhere, including outside tests, and its return value is currently ignored by design in places.
That change needs its own analysis; it is not a one-line fix.

---

## Third defect (2026-09-14): a file that asserts nothing inherits the previous file's score

Found while restoring `test/test.tilde`'s clean-environment guarantee (T3/T9 follow-on).

`test.tilde` declares **zero** assertions — no `test.case`, no `expect`, no `expect.pass`/`expect.fail`
— and never calls `test.suite.save.results`. Yet:

```
$ ./test.suite run tilde 1
  Results:   31 / 31 assertions passed
  ✓ All tests successful

$ ./test.suite run this 1
  Results:   31 / 31 assertions passed      # ← the same 31
```

Because the file never writes `testresult.env`, the runner re-sources the **previous** file's
results. In `core 1` ordering that is `test.this`, so `test.tilde` silently reports `test.this`'s
score as its own. It is not merely a test that cannot fail — it is a file that cannot even be
*evaluated*, reporting a pass it did not earn.

**Consequence:** every `core 1` total quoted anywhere (including in the T3 and T9 tickets) includes
**31 phantom assertions**. The number is stable, so before/after comparisons within a session stay
valid, but the absolute figure has been wrong for as long as this has been true.

**Why it went unnoticed:** it looks like a healthy file. Green summary, plausible count, and the
count moves when the suite grows, because the file it shadows grows.

**Two defects, not one:**
1. `test.tilde` makes assertions in prose (`Testing tilde expansion succeeds as expected ;)`) rather
   than through the framework. It should use real `expect`s — the behaviour it checks is genuine and
   worth pinning, especially now that it runs from a clean environment where `~` semantics are the
   whole point.
2. **`test.suite` should refuse to report a score a file did not produce.** A run that ends without
   `test.suite.save.results` should be an error, or at minimum report `0 / 0`, never the previous
   file's numbers. That is the general fix and it protects every future file.

- [ ] `test.suite` fails loudly (or reports 0/0) when a file produces no results of its own
- [x] `test.tilde` asserts through the framework instead of via `echo` (2026-09-14: T-TILDE-CLEAN-ENV, -HOME, -STRING, -FILE-TEST; the clean re-exec now carries OOSH_DIR/CONFIG_PATH/LOG_* so the framework can score it)
- [ ] Re-baseline the `core 1` totals in the T3 and T9 tickets once the phantom 31 is gone

## Related blind spot: `sh -n` does not catch `[[`

Also found 2026-09-14, by a negative control that was supposed to fail and didn't. `sh -n` accepts
`[[ -r x ]]` — to dash, `[[` is a valid *command name*, so the bashism is only caught at run time.
`test.config` **T40** lints `boot` with `sh -n`/`ash -n` and inherits exactly this blind spot: a
bashism could land in `boot` and T40 would stay green. The T9 drop-in lint now pairs `sh -n` with an
explicit bashism grep; T40 should do the same.

- [ ] T40 pairs its `sh -n` lint with an explicit bashism grep
