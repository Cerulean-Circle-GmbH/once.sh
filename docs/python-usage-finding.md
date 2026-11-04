# Python usage in this tree — fresh finding (2026-11-03)

Measured from scratch on the working tree (`HEAD 525ca5a8` plus local changes), tracked files
only. No number from an earlier analysis is reused; `docs/python.md` was read only to compare
against the tree.

Method: `git ls-files` → files containing `python` (case-insensitive) → read every non-comment
line → classify as **invocation** (python runs code), **guard** (`command -v python3`),
**mention** (string/comment/permission) or **tool** (a `.py` program or a Python-backed CLI).
Line numbers are the current ones.

## TL;DR

- **12 non-doc files carry Python**: 4 scripts with **22 inline invocations** (`claudeCode`,
  `scrumMaster`, `hiveMind`, `debug`), 1 Python-backed tool (`otest`), 1 standalone `.py` report
  generator, and 6 files that only mention it or grant it (`oo`, `ossh`, `odocker`,
  `.claude/settings.local.json`, `test/test.otest`, `test/test.log`).
- **22 inline invocation sites** in four scripts: `claudeCode` 7, `scrumMaster` 8, `hiveMind` 6,
  `debug` 1.
- **14 of the 22 are hard dependencies** — no `jq` fallback, no guard: `claudeCode` 4,
  `scrumMaster` 4, `hiveMind` 6.
- **The worst one is silent**: `scrumMaster`'s token-expiry check is skipped when `python3` is
  absent (`scrumMaster:1828`), so an expired OAuth token is returned as valid — fail-open.
- **`otest` is the biggest Python consumer** (52 lines mention python/venv): a managed venv,
  `run_tests.py`, a Playwright `browser.py`, and the external `test_discovery.py`; only the
  `ensurepip`/version probes are still inline. Its Python sources are **not in this repository**.
- **`docs/python.md` is stale**: it documents six scripts (misses `hiveMind`), its line numbers
  have drifted 2–3×, and it claims five `.py` files "ship under `TestSuite/2.0.0/`" — there is no
  `TestSuite` directory in this tree.

## Inventory — inline invocations

| Script | Site | Shape | Purpose | Hard? | Fallback |
|---|---|---|---|---|---|
| `claudeCode` | `:271` | `python3 -c` (multi-line) | `list.json`: sessions-index walk | soft | `jq` branch at `:293` |
| `claudeCode` | `:1347` | `python3 -c` one-liner | session `customTitle` | soft | `jq` tried **first** (`:1345`) |
| `claudeCode` | `:1370` | `python3 -c` | title from `sessions-index.json` | soft | `jq` tried first |
| `claudeCode` | `:1680` | `tail -200 \| python3 -c` | observed max tokens | **hard** | — |
| `claudeCode` | `:1749` | `tail -50 \| python3 -c` | remaining context % | **hard** | — |
| `claudeCode` | `:2023` | `python3 -c` | context window of a session | **hard** | — |
| `claudeCode` | `:2114` | `python3 -c` | dashboard row info | **hard** | — |
| `scrumMaster` | `:715` | `python3 - "$session" <<'SM_PULSE_PY'` | deprecated `pulse` (parity oracle) | **hard** | — |
| `scrumMaster` | `:923` | `python3 -c` | `swipe.ctx`: usage + pct | **hard** | — |
| `scrumMaster` | `:1812` | `python3 -c` | OAuth access token | soft | guarded; `jq` at `:1814` |
| `scrumMaster` | `:1813` | `python3 -c` | `expiresAt` | soft | guarded; `jq` |
| `scrumMaster` | `:1830` | `python3 -c` | token expiry compare | soft → **fail-open** | skipped without python3 |
| `scrumMaster` | `:1858` | `python3 -c` | subscription API JSON | soft | guarded; `jq` at `:1879` |
| `scrumMaster` | `:2466` | `python3 -c` | `resets.in` datetime math | **hard** | — |
| `scrumMaster` | `:2668` | `python3 -c` | remaining minutes in window | **hard** | — |
| `hiveMind` | `:3085` | `python3 <<'EOF'` | role prompt build | **hard** | — |
| `hiveMind` | `:3247` | `python3 <<'EOF'` | role prompt pick | **hard** | — |
| `hiveMind` | `:7593` | `python3 -c "$hasNonZero"` | pane usage non-zero probe | **hard** | — |
| `hiveMind` | `:7605` | `\| python3 -c` | newest non-zero JSONL | **hard** | — |
| `hiveMind` | `:7678` | `python3 -c` | observed usage | **hard** | — |
| `hiveMind` | `:7756` | `python3 -c` | context reading | **hard** | — |
| `debug` | `:288` | `python3 -c` | errno code → name/message | soft | plain `EXIT N` |

Counts: `claudeCode` 7 (4 hard), `scrumMaster` 8 (4 hard), `hiveMind` 6 (6 hard), `debug` 1
(0 hard) — **22 sites, 14 hard**.

## Mentions, not invocations

| Site | What it is |
|---|---|
| `ossh:3646` | a package name in `ossh.cmd.completion.pkg`'s `compgen -W` list |
| `oo:3132` | `oo cmd python3 python3` — installs/starts the package, not a parser |
| `.claude/settings.local.json:164` | `"Bash(python3:*)"` — a broad tool permission |
| `odocker:233` | comment: the naked images have no Python |
| `test/test.log:989` | comment pointing at `docs/python.md` |
| `test/test.otest:52,105,107` | venv presence/symlink checks |

## Tool-level Python

| Tool | Dependency |
|---|---|
`otest` | a managed venv at `$OTEST_DIR/src/py/venv` (`otest:96`, wrapper `:582`), `run_tests.py` (`:456`), `browser.py` with Playwright/Chromium (`:165`, `:170`), the external `test_discovery.py` (`:706`, `:716`), and inline `python3 -c` only for `ensurepip`/version (`:521`, `:524`); `python3 -m venv` when the venv is missing (`:538`). `OTEST_DIR` must point at an **external** `TestSuite/2.0.0`; this repo has no such directory. |
`docs/reports/generate_almalinux_report.py` | standalone: needs `openpyxl`; the header says "run with /tmp/xlsx-venv/bin/python3" |
`docs/python.md` | manual inventory, "living reference" — see the drift below |

`test/test.otest` skips the venv-dependent checks when the venv is absent, so `otest` can look
green without ever exercising its Python paths.

## What breaks without `python3`

| Method | Behaviour |
|---|---|
| `claudeCode.context.read` / `.dashboard` / `.check` | hard failure (the `python3` call is the only implementation) |
| `claudeCode.list.json`, session naming | falls back to `jq`; errors only if neither exists (`:306`) |
| `scrumMaster.pulse`, `swipe.ctx` | hard failure |
| `scrumMaster.measure.subscription` | falls back to `jq`, errors if neither |
| `scrumMaster` OAuth helpers | token still returned **with the expiry check silently skipped** (`:1828`) — fail-open |
| `scrumMaster` `resets.in` / remaining minutes | hard failure (`:2466`, `:2668`) |
| `hiveMind` usage/context/role paths | hard failure (6 sites) |
| `debug` errno labels | degrades to `EXIT N` |
| `otest` | cannot run its Python runner/browser; skips without a venv |

## Findings

**F1 — the inventory is stale.** `docs/python.md` says "Six top-level scripts touch Python:
`otest`, `claudeCode`, `scrumMaster`, `debug`, `oo`, `ossh`" — the tree has **seven**; `hiveMind`
is missing entirely, and it is the second-largest inline consumer (6 sites, all hard). Its line
references are from an older revision (`claudeCode:1058–1079` vs `:1680` today,
`scrumMaster:1226` vs `:1811`, `oo:2295` vs `:3132`, `ossh:2573` vs `:3646`). Its "40 lines of
inline Python for test-discovery" in `otest:698–729` no longer exist — that logic moved to the
external `test_discovery.py` (`otest:706`, `:716`). It also says five `.py` files "ship under
`TestSuite/2.0.0/`", but that directory is not in this repo.

**F2 — no consistent policy.** `claudeCode.list.json` prefers Python and falls back to `jq`;
the two session-name paths prefer `jq` and fall back to Python; four `claudeCode` and six
`hiveMind` sites have no fallback at all. Nothing states which is the intended order.

**F3 — the same parser is written repeatedly.** Token-usage/JSONL walking exists in `claudeCode`
(4 hard sites), `hiveMind` (4 sites) and `scrumMaster` (pulse + `swipe.ctx` + subscription).
The mcdonges line solved this with one shared `claudeCode jsonl.usage` reader; **this tree has no
such helper** — every site re-parses.

**F4 — fail-open expiry.** `scrumMaster:1828` only checks expiry "if python3 exists". A host
without Python hands out an expired token.

**F5 — a hardcoded home in a Python heredoc.** `scrumMaster:715` (pulse) uses
`os.environ.get("OOSH_DIR", "/root/oosh")` — a root-only default inside shipped code.

**F6 — broad permission.** `.claude/settings.local.json` allows `Bash(python3:*)`, i.e. arbitrary
Python execution, not the specific scripts the tree needs.

**F7 — no accounting.** Nothing counts or lists Python sites automatically; `docs/python.md` is
hand-maintained and already wrong. There is no gate in this tree.

## How to remove the Python dependency

Goal: **no `python3` invocation in the tree**. Six batches, cheapest first; each one is
independently shippable and testable. The hard/soft column from the inventory decides the
replacement.

### A. Replacement per site

| Site | Replace with | Effort | Risk |
|---|---|---|---|
| `claudeCode:271` `list.json` | keep the existing `jq` branch (`:293`), delete the Python branch | S | low |
| `claudeCode:1347`, `:1370` session name | `jq` is already first; delete the Python fallback | S | low |
| `scrumMaster:1812`, `:1813` OAuth token/expiry | keep the `jq` branch (`:1814`), delete Python | S | low |
| `scrumMaster:1858` subscription JSON | keep the `jq` branch (`:1879`), delete Python | S | low |
| `scrumMaster:1830` expiry compare | bash: `now=$(date +%s); [ "$now" -gt "$((expires_at / 1000))" ]` — and **fail closed** when the token is expired | S | medium (security) |
| `debug:288` errno label | drop the friendly label; keep the existing `EXIT N` | S | low |
| `ossh:3646` completion list | remove `python3` from the `compgen -W` list | S | none |
| `oo:3131-3132` `oo cmd errno` | it installs and starts `python3`; delete the case, or point it at a small bash errno table | S | low |
| `.claude/settings.local.json:164` | remove `Bash(python3:*)` | S | none |
| `claudeCode:1680`, `:1749`, `:2023`, `:2114` | one shared **awk** JSONL reader (see C) | M | medium (parity) |
| `scrumMaster:923` `swipe.ctx` | same reader | M | medium (parity) |
| `hiveMind:7593`, `:7605`, `:7678`, `:7756` | same reader | M | medium (live behaviour) |
| `scrumMaster:2466`, `:2668` ISO-8601 math | a `date` helper per OS (GNU `date -d` / BSD `date -j -f`) or `jq` `strptime`/`fromdateiso8601` | M | medium |
| `scrumMaster:715` `pulse` | **delete `pulse`** (it is deprecated; `swipe` is the successor) after recording its parity goldens | L | medium (tests still reference it) |
| `hiveMind:3085`, `:3247` role prompts | bash + `ps`/`awk`, or reuse `private.hiveMind.live.tupleset`; the 300-line Python heredocs are the hardest port | L | high |
| `otest` (venv, runner, `browser.py`, `test_discovery.py`) | keep it as an **optional add-on** outside the core gates, or port discovery to awk and drop the Playwright tests | L | high |
| `docs/reports/generate_almalinux_report.py` | delete it (historical report, not runtime) or move it out of the repo | S | none |

### B. Order of work

1. **Delete the sites that already have a `jq` fallback** — `claudeCode` 3, `scrumMaster` 3.
   Pure deletion; the fallback is already tested.
2. **Replace the arithmetic/datetime one-liners** — expiry, `resets.in`, remaining minutes (3).
   Do the expiry fix **first**; it is also the fail-open bug.
3. **One shared awk JSONL reader** — `claudeCode` 4, `hiveMind` 4, `swipe.ctx` (9), plus `pulse`
   if it survives step 4. This is the volume reduction: ~10 sites, 3 scripts, one implementation.
4. **Retire `pulse`** — record its output as goldens, then delete the method and its parity tests
   (or repoint them at `swipe`).
5. **Port the two hiveMind role-prompt heredocs** — either reuse `live.tupleset` or write the
   `ps`/`awk` equivalent. Last because it is the most behaviour-sensitive.
6. **Tooling and cleanup** — `otest` decision, report generator, `docs/python.md` rewritten,
   mentions/permission removed (A's S rows).

### C. The shared reader (the one implementation)

A JSONL file is one JSON object per line, and the fields are simple, so one POSIX `awk` pass can
do what the five Python snippets each re-do:

- iterate lines, match an **unescaped** `"type":"assistant"` and `"usage":{`;
- take the first unescaped `input_tokens`, `cache_creation_input_tokens`,
  `cache_read_input_tokens` after `usage` (the `ephemeral_*` fields are excluded by the leading
  quote);
- sum them into `total`; only `total > 0` counts;
- modes: `last`, `max`, `first`, `lag` (bytes since the last positive record), `all`.

An implementation of exactly this shape already exists on the test line
(`claudeCode jsonl.usage`, 5bbe6289/95507d59) and is faster than the Python it replaced on a
616 MB session; porting it is cheaper than re-deriving the escaping rules.

**Parity gate before deleting Python:** run the old `python3` snippet and the new reader over a
fixture corpus (including the big real sessions), compare every number, and keep the corpus as a
test. The reader is the only place where a silent arithmetic difference would change a dashboard
number.

### D. Acceptance — "no Python dependency"

- `git grep -nE 'python3?[[:space:]]+(-|<<)' -- .` returns no invocation in tracked files;
- no `.py` file in the tree except an optional add-on;
- the hard rows in the behaviour table have a non-Python implementation, and removing `python3`
  from `PATH` changes no test result;
- `test.suite core` and the extended suites are green without `python3`;
- `docs/python.md` says "none" (or points at the add-on), and a small report (`python.sites`)
  fails when a new invocation appears.

### E. What cannot be removed cheaply

- **`otest`'s browser automation** (Playwright/Chromium) has no bash equivalent. If "zero" is
  literal, `otest` must live outside this tree as an optional add-on, and `test/test.otest` must
  skip explicitly (not silently) when it is absent.
- **The AlmaLinux report generator** is a one-off historical asset; deleting it removes the only
  other `.py` file with no runtime impact.

### F. Risks

- **jq is still an external dependency.** If the goal is "no external tool at all", only the awk
  path qualifies; decide per row whether `jq` is acceptable.
- Deleting the Python fallback changes the failure mode on a host with **neither** interpreter nor
  `jq`; every such site needs an explicit error (as `claudeCode:306` already has).
- The awk reader is valid only because each JSONL line is one object and the keys are shallow;
  do not extend it to nested payloads.
- `pulse` and the role prompts are behaviour-sensitive; goldens first, deletion second.

## Caveats

- Counts are **invocation lines**, not lines of code: several sites are multi-line heredocs
  (`claudeCode`, `hiveMind`, `scrumMaster` pulse), so the code volume is larger than the count.
- "Soft" means a fallback exists *or* the guard degrades; the exact degradation is in the
  behaviour table.
- Line numbers are the working tree's; they drift with every refactor — regenerate rather than
  cite them long-term.
