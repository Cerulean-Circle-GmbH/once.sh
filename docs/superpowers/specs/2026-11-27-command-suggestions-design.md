# Design: command suggestions — fix, next, similar

**Status:** design, awaiting review.
**Date:** 2026-11-27
**Branch:** `dev`

## Context

OOSH dispatches a call in `this.call`: the script's own `<caller>.<method>` function first, then a
compound sub-method, then `<method>` as a script, then `this.methodNotFound`. Today that last stop
prints one line from a substring match:

```
Method 'cnfig' not found in otmux
  Did you mean: config
```

Tab completion (`c2`) helps only *while typing*, and only lists candidates. Nothing tells you the
closest correct command after a typo, nothing shows what the resolved method accepts next, and a
misspelled script name (`./otmxu`) is handled by bash, not by OOSH at all.

The user asked for suggestions that show the right command, what can be done next, and other
similar commands.

## Goals

1. One suggestion engine, one knowledge source (`c2`'s parse of the scripts), three surfaces:
   error-time method hint, error-time script hint, on-demand `c2 suggest`.
2. The block always answers three questions: **Fix** (what to type), **Next** (what that method
   accepts next), **Similar** (other near candidates).
3. Parameter mistakes (missing/extra arguments, invalid enumerated values) are reported after a
   failing call, never pre-validated.
4. Hints are advisory, cost nothing on the happy path, and never change exit codes.
5. Silent in scripts, tests and agent log capture unless explicitly enabled.

## Non-goals

- Inline as-you-type autosuggestion (ghost text). Separate spec; see §9.
- Curated per-command "workflow next steps" tables. The data stays derived from c2; a curated file
  can be added later without changing the engine.
- Replacing Tab completion or `this.help`.
- Suggesting arbitrary non-OOSH commands (`git`, `docker`, …).
- Changing `this.methodNotFound`'s existing message or its exit code 127.

## Decisions

| Decision | Choice |
|---|---|
| Engine location | `ng/c2` — public `c2 suggest`, private `c2.suggest.*` |
| Method-typo hook | `this.methodNotFound` calls the engine; falls back to today's substring line |
| Script-typo hook | `command_not_found_handle` in `templates/user/c2.install` |
| Parameter advice | after a failing call only, from `this.start`'s dispatch branch |
| Gating | `OOSH_SUGGEST=auto\|always\|never` (`auto` = stderr is a TTY) |
| "Next" source | child methods, else the parsed signature |
| Ranking | fixed tiers, cheap `grep` first, one `awk` pass last |
| Output | three labelled lines, top 3 beyond the fix |
| Inline mode | deferred to spec 2; it will call `c2 suggest` |

## 1. Entry points

### 1.1 `c2 suggest`

```bash
c2.suggest() # <commandLine...> # prints fix / next / similar hints for a (possibly wrong) command line
```

- Accepts the line either as one quoted argument (`c2 suggest './otmux cnfig list'`) or as words.
- Unquotes with `line.unquote`; rejects tabs and newlines.
- Always prints, regardless of `OOSH_SUGGEST`.
- Exit status: `0` when at least one hint line was printed, `1` when nothing could be suggested
  (a normal answer, not a failure), `2` for usage/input errors.

### 1.2 Method typo (error time)

`this.methodNotFound <method> <caller>` keeps its first line and its `return 127`, and asks the
engine for `<caller> <method>`. A `SUGGEST_SHOWN` flag records that a block was printed, so the
after-failure hook (§1.4) does not repeat it.

If `c2.suggest` is not loadable (bootstrap, broken `~/config`), the current substring fallback and
the `Run '<caller> usage'` line run unchanged.

### 1.3 Script typo (error time)

`templates/user/c2.install` — already sourced by the bashrc and already the file that wires
completion for every script — defines:

```bash
command_not_found_handle() { ... }
```

- It fires for any unknown command name. The engine is asked only for the **first word**; OOSH
  scripts are the candidate set (`c2.completion`).
- If the best candidate is within distance 2, it prints `name: command not found`, then the block,
  and returns 127.
- Otherwise it delegates to the handler that was in place when the oosh bashrc was sourced
  (captured with `declare -f`), and if there was none, prints the standard `command not found` line
  and returns 127. This keeps distro package hints ("but can be installed with …") intact.
- It is installed only in interactive shells, after `bash_completion`, so it wins.

### 1.4 Parameter mistakes (error time)

In `this.start`'s dispatch branch, immediately after `this.call "$@"` and `RETURN_VALUE=$?`, the
original words and the status are both still available:

```bash
*)  this.call "$@"
    RETURN_VALUE=$?
    private.this.suggest.after.failure "$@"   # guarded, non-zero only, no-op otherwise
```

The hook prints advice only when **all** hold: status is non-zero, `SUGGEST_SHOWN` is unset,
`OOSH_SUGGEST` allows output, and the engine can prove something (§4). The flag is reset once at the
top of `this.start`, so one invocation prints at most one block. The exit status is then re-returned
untouched.

## 2. The block

```
$ ./otmux cnfig list
Method 'cnfig' not found in otmux
  Fix:      otmux config list          (config.list)
  Next:     otmux config init | otmux config get <configItem> | otmux config list
  Similar:  otmux container.config | otmux session.config
```

- **Fix** — the best candidate substituted into the typed words. The tail (`list`) is kept only
  when it is a valid continuation of the candidate; otherwise it is dropped and the line ends at the
  last good word, with `<method>` where the next word belongs. The resolved method path is shown in
  parentheses (`(config.list)`) whenever the fixed line names a compound method.
- **Next** — the resolved method's own surface: up to 5 child methods, else its signature with
  `<required>` before `<?optional>` and `...` preserved. Omitted when Fix is a script name, which
  has no method surface.
- **Similar** — up to 3 further ranked candidates, never equal to Fix or to the typed word.

Script-typo variant:

```
$ ./otmxu list
otmxu: command not found
  Fix:      otmux list
  Similar:  otmux | odocker | ogit
```

A line that is only missing or carrying a wrong parameter has no Fix; it shows Next and the
parameter finding:

```
$ ./otmux config.get
  Next:     otmux config.get <configItem> <?section>
  Missing:  <configItem>
```

Labels are padded to one column so blocks line up. Colours reuse the existing `line`/`config`
palette (`GREEN` for Fix, `YELLOW` for labels) and only when a TTY and `NO_COLOR` is unset.

## 3. Candidates and ranking

Candidate set per trigger:

| Trigger | Set |
|---|---|
| method typo | `c2.function.completion <script>` — already excludes `private*`, `*.completion.*` and `@hidden` |
| script typo | `c2.completion` (scripts in `$OOSH_DIR`) |
| on demand | script set for word 1, method set for the rest |

Cheap tiers first (`grep`/globs and `case`), with the first matching tier deciding the score:

| Score | Test | Example |
|---|---|---|
| 100 | exact | `config` |
| 90 | candidate starts with input | `con` → `config` |
| 80 | input starts with candidate | `configs` → `config` |
| 70 | input is a case-insensitive substring | `nfig` → `config` |
| 60 | same object chain, last segment differs | `config.set` vs `config.get` |
| 50 | ordered subsequence | `cnfg` → `config` |
| 40 − 5d | Damerau-Levenshtein distance `d` ≤ max(1, len/3) | `cnofig` → `config` |

- Distance is a single `awk` pass over the candidates that survive the tiers above it (`awk` is
  already used in `this` and `line`).
- Sort by score descending, then alphabetically; keep the top 3 after Fix.
- Method names are compared without the `<script>.` prefix and with dots kept.

## 4. Next, arity and values

**Next**

- Children: candidates that start with `<method>.`; list the distinct next segment.
- Leaf: the signature parsed through `c2.get.function.parameter` (the same parser Tab completion
  uses), rendered `<required>` first, `<?optional>` after, `...` kept. That parser writes
  `current.method.env`/`result.env` into `$CONFIG_PATH`, so the engine runs it in a subshell with a
  scratch `CONFIG_PATH` — the technique `c2.signature.validate` already uses — and the live
  completion state is never touched.

**Arity** — counted from the same signature:

- required = parameters without a leading `?` and not variadic;
- fewer words than required → `Missing: <name>` (all missing names, comma separated);
- more words than declared parameters, with no variadic → `Unexpected: <word>`;
- a variadic parameter suppresses the "extra" finding.

**Value** — only when a completion exists for that parameter:

- ask the method-specific completion first, then the class-level one (the order pinned by
  `T-C2-PARAM-COMPLETION-ORDER`), once, with an empty input;
- if it yields 1–20 candidates and the typed value is not among them → `Invalid: '<value>' for
  <param> — expected one of: …`;
- free-form parameters and empty answers produce nothing.

Parameter findings are computed from the **typed** line, not from the Fix, so they also work for a
call whose method is correct.

## 5. Gating, safety, cost

- **Advisory only.** The engine reads script files and prints text. It never executes a suggested
  command, never writes the caller's `$CONFIG_PATH` (parser state runs in a scratch `CONFIG_PATH`,
  like `c2.signature.validate`), never touches the network.
- **Gating.** `OOSH_SUGGEST` is read as `${OOSH_SUGGEST:-auto}`:
  - `auto` — print only when stderr is a TTY;
  - `always` — print regardless;
  - `never` — print nothing (the on-demand command still prints).
  The value is read, never written; a user may set it in `user.env`.
- **Bootstrap-safe.** `this` and `c2.install` call the engine only if the function exists; otherwise
  behaviour is exactly today's.
- **Cost.** One method-list computation per invocation, one `grep` pass per tier, one `awk` pass for
  the survivors. Budget ~150 ms on a 300-method script; the test guards a loose 2 s ceiling only to
  catch accidental per-candidate process spawning.
- **No recursion.** The engine is not called from `c2 suggest`'s own paths, and `SUGGEST_SHOWN`
  prevents the method-typo block from being printed twice.
- **Input hygiene.** Tabs and newlines are rejected; quoting is undone with `line.unquote`; a line
  that names no script is treated as an unknown-script case, never as a glob.

## 6. Files

| File | Change |
|---|---|
| `ng/c2` | `c2.suggest` public; `private.c2.suggest.*` for candidates, rank, distance, fix, next, similar, values, render |
| `this` | guarded call in `this.methodNotFound`; after-failure hook in `this.start`'s dispatch branch |
| `templates/user/c2.install` | `command_not_found_handle` and the capture/delegation of the previous handler |
| `docs/completion-system.md` | new "Suggestions" section: triggers, block, ranking, gating |
| `docs/c2.md`, `docs/this.md` | regenerated by the existing docs tooling, not hand-edited |

## 7. Tests

New `test/test.suggest` (`TEST_CATEGORY=core`), using `test.data/parameterTestScript` plus the real
`otmux`/`oosh` method lists:

| Test id | Asserts |
|---|---|
| `T-SUGGEST-FIX` | `cnfig` → `config` |
| `T-SUGGEST-FIX-TAIL` | a valid tail is kept; an invalid tail is dropped |
| `T-SUGGEST-RANK-TIERS` | prefix > substring > subsequence > edit distance |
| `T-SUGGEST-NEXT-CHILDREN` | child methods listed for a parent |
| `T-SUGGEST-NEXT-SIGNATURE` | required before optional, `...` kept |
| `T-SUGGEST-SIMILAR-NO-DUP` | Similar never repeats Fix |
| `T-SUGGEST-HIDDEN-EXCLUDED` | `@hidden`, `private*`, `*.completion.*` never suggested |
| `T-SUGGEST-SCRIPT` | `otmxu` → `otmux` |
| `T-SUGGEST-GATING` | silent under `never` and when stderr is not a TTY; `always` forces output |
| `T-SUGGEST-EXIT` | `c2 suggest` returns 0/1/2 as specified |
| `T-SUGGEST-NO-CONFIG-WRITE` | no file is created or changed in the isolated `$CONFIG_PATH` |
| `T-SUGGEST-ARITY-MISSING` | missing required parameter named |
| `T-SUGGEST-ARITY-EXTRA` | unexpected word named, variadic suppresses it |
| `T-SUGGEST-VALUE` | invalid value listed against completion candidates |

`test/test.call` gains `T-METHODNOTFOUND-UNCHANGED` (message and 127) and
`T-METHODNOTFOUND-HINT` (block appended once). `test/test.c2` gains one interactive tmux case:
send a wrong method in a pane, capture it, assert the Fix line — following the existing
`_oo_completion` pattern.

## 8. Docs

`docs/completion-system.md` gets a "Suggestions" section covering the three triggers, the block,
the ranking tiers, `OOSH_SUGGEST`, and the phase-2 boundary. No generated doc is hand-edited.

## 9. Phase 2 — inline as-you-type

Separate spec, calling the same `c2 suggest`. The mechanism choice is deliberately left there:

- ghost text only when `ble.sh` is present (bash alone has no per-keystroke hook);
- otherwise a hint line triggered by a key (`\C-x\C-s`) or by space, printed under the prompt;
- binding every printable key to fake ghost text is rejected as fragile (multibyte input, IME,
  bracketed paste).

Curated per-command "what usually follows" hints are a later, optional data file consumed by the
same engine; they do not affect this design.
