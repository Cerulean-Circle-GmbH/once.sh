# Python in OOSH

Inventory and OOSH-methodology audit of every place Python touches the OOSH codebase.

This is a living reference. When you add a new Python invocation, update the inventory + audit it against the methodology rubric below.

## TL;DR

- OOSH is bash-first. Python is reached for only when bash can't do the job cleanly: browser automation, JSON / YAML / Excel parsing, venv lifecycle.
- Six top-level scripts touch Python today: `otest`, `claudeCode`, `scrumMaster`, `debug`, `oo`, `ossh`. The first three carry the bulk of the lines.
- One managed venv exists: `$OTEST_DIR/venv`, lifecycle owned by `otest`'s `private.ensureVenv`. Everything else uses system `python3` directly.
- Five Python source files ship under `TestSuite/2.0.0/` (used by `otest`); one stand-alone reporting tool ships in-tree at `docs/reports/generate_almalinux_report.py`.
- Methodology fit is broadly good. Two smells stand out: `otest`'s 40 lines of inline Python for test-discovery, and `claudeCode`'s 116 lines of inline Python across three JSONL-parsing functions. Both are candidates to extract to dedicated `.py` helpers.

## Inventory

### Bash → Python invocations

| Location | Shape | Runtime | Required? | What it does |
| --- | --- | --- | --- | --- |
| `otest:96`, `:446` | `"$OTEST_DIR/venv/bin/python" run_tests.py …` | Managed venv (raw path) | Required for `otest run` | Runs the Python test runner |
| `otest:139–171` (uses `:162`, `:167`) | `private.python "$OTEST_DIR/browser.py" launch/navigate` | Managed venv (wrapper) | Required for `otest browser.open` | Launches/drives Chromium via Playwright |
| `otest:505` | `command -v python3` | System | Soft check | Existence guard before venv create |
| `otest:511` | `python3 -c "import ensurepip"` (one-liner) | System | Soft check | Module-presence probe |
| `otest:514` | `python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")'` | System | Soft | Version detection (drives package name `python${pyver}-venv`) |
| `otest:538` | `python3 -m venv "$venvDir"` | System | Required for venv create | Create venv |
| `otest:546`, `:549`, `:555`, `:561`, `:566` | `"$venvPython" -m {ensurepip,pip,playwright}` | Managed venv | Required for first run | venv bootstrap (pip, deps, browsers, setuptools) |
| `otest:572–575` | `private.python() { "$OTEST_DIR/venv/bin/python" "$@"; }` | — | — | Wrapper for the venv python |
| `otest:698–718` | 21-line inline Python (`private.python -c "…YAML walk…"`) | Managed venv | Required for `private.testExists` | Walks Components/, parses `otest.yaml`, derives test names |
| `otest:729–748` | 19-line inline Python (`private.python -c "…YAML walk…"`) | Managed venv | Required for `private.testNames` | Same as above; enumerates names instead of probing one |
| `claudeCode:1058–1079` | 22-line inline Python (`python3 -c "…JSON parse…"`) | System | Hard required (no fallback) | Reads context-% from a JSONL token-usage stream |
| `claudeCode:1281–1336` | 56-line inline Python (`python3 -c "…JSON parse + datetime…"`) | System | Hard required (no fallback) | Computes token-velocity + ETA-to-compaction |
| `claudeCode:1372–1409` | 38-line inline Python (`JSONL_FILE=… python3 -c "…"`) | System | Hard required (no fallback) | Per-session dashboard row |
| `scrumMaster:1226` | `python3 -c "import sys,json; print(json.load(sys.stdin)['claudeAiOauth']['accessToken'])"` (one-liner) | System | Soft (has `jq` fallback at `:1229`) | Extract OAuth token from macOS Keychain creds |
| `scrumMaster:1227` | One-liner, same shape, for `expiresAt` | System | Soft | Extract expiry timestamp |
| `scrumMaster:1244` | `python3 -c "import time; print('yes' if time.time() > ${expiresAt}/1000 else 'no')"` | System | Soft (epoch-vs-ms compare) | Token-expiry check |
| `scrumMaster:1272–1292` | 21-line inline Python (`python3 -c "…API JSON parse…"`) | System | Soft (has `jq` fallback at `:1294`) | Parse subscription-usage API response |
| `debug:280–284` | `python3 -c "import os, errno; …os.strerror(code)…"` (one-liner) | System | Soft (plain `EXIT N` fallback) | Map exit code → human errno name |
| `oo:2295` | `oo cmd python3 python3` | — | n/a (install dispatch) | Installs python3 when user runs `oo cmd errno` |
| `ossh:2573` | `compgen -W "bash curl git wget tree expect python3 jq" …` | — | n/a (completion list) | Lists `python3` as a known installable in tab-completion |

### Python source files (in-tree)

| Path | Lines | Purpose | Invoked by |
| --- | --- | --- | --- |
| `docs/reports/generate_almalinux_report.py` | 820 | Generates a 5-sheet AlmaLinux work report `.xlsx` via openpyxl | Manual: `/tmp/xlsx-venv/bin/python3 docs/reports/generate_almalinux_report.py` |

The reporting script is **stand-alone** — never invoked from any OOSH method. Out of methodology-audit scope.

### Python source files (TestSuite component, used by `otest`)

Component root: `$OTEST_DIR` → `/home/hannesn/WODA.2023/_var_dev/EAMD.ucp/Components/me/hannesnortje/TestSuite/2.0.0/` (auto-discovered by `otest:460–486`; secondary candidate `/var/dev/EAMD.ucp/...`).

| Path | Lines | Purpose |
| --- | --- | --- |
| `run_tests.py` | 199 | Self-re-execs into the venv (`_ensure_venv` at `:8–19`); discovers tests by walking Components/ for `otest.yaml`; runs each via `subprocess` |
| `browser.py` | 695 | Persistent Chrome controller built on Playwright; CLI verbs `launch / status / navigate / back / forward / reload / screenshot / click / fill / type / key / evaluate / text / html / find / tabs / new_tab / switch / close_tab / wait / close` |
| `ipad_browser.py` | 886 | Same idea for WebKit / iPad emulation |
| `utils/playwright_setup.py` | 69 | Browser context factory (headless, viewport, profile) |
| `utils/screenshot_manager.py` | 51 | Latest → golden → diff lifecycle |

Total: ~1,900 lines of Python that the OOSH-shipped `otest` script delegates to.

### Venv + dependency management

One managed venv. Lifecycle entirely in `otest:488–570` (`private.ensureVenv`):

1. Fast path: if `$venvDir/bin/python -m pip --version` works → return.
2. Broken venv (no `pip`) → `rm -rf "$venvDir"` and rebuild.
3. Pre-flight: `python3` present (`otest:505`); `ensurepip` importable (`otest:511`); else install via apt / dnf / yum with version-pinned package name (`otest:516–534`).
4. Build: `python3 -m venv` → `ensurepip --upgrade` → `pip install -r requirements.txt` → `playwright install chromium` → `playwright install webkit` (soft fail) → `pip install setuptools`.

`requirements.txt` (TestSuite component):

```
PyYAML>=6.0
playwright>=1.41.0
setuptools>=65.0.0
```

Looser pins than reproducibility-strict shops would use — see Out of Scope.

### OOSH methods that wrap Python

| Method | Signature | Delegates to |
| --- | --- | --- |
| `otest.run` | `<testName> <?headless> <?updateGolden> <?keepScreenshots> <?webkit>` | `venv/bin/python run_tests.py …` |
| `otest.here` | `<?headless> <?updateGolden> <?keepScreenshots> <?webkit>` | Detects test from cwd → `otest.run` |
| `otest.setup` | (no args) | Force-rebuild venv via `private.ensureVenv` |
| `otest.browser.open` | `<?url:https://test.wo-da.de/ide> <?profile:/tmp/browser-profile>` | `private.python browser.py launch` + `navigate` |
| `otest.newTest` | `<TestName> <?url>` | Scaffolds a Python test file with Playwright boilerplate |
| `claudeCode.context.read` | `<?pane>` | `private.claudeCode.context.from.jsonl` (inline Python) |
| `claudeCode.context.dashboard` | (no args) | 38-line inline Python per session row |
| `claudeCode.context.check` | `<pane>` | Calls `.context.read` (Python under the hood) |
| `scrumMaster.measure.subscription` | (varies) | `private.measure.subscription.api.parse` (Python or `jq`) |
| Various other `scrumMaster` OAuth methods | — | `python3 -c` for JSON extraction (`jq` fallback) |

### Tests that exercise the Python paths

`test/test.otest` is the only test file that walks the venv lifecycle. It uses the **skip-guard** pattern (per memory `feedback_real_env_tests_when_fixtures_miss`):

```bash
# test.otest:107
if [ -d "$OTEST_DIR/venv" ] && [ -f "$OTEST_DIR/venv/bin/python" ]; then
  # ...real assertions against testExists / completion / etc.
else
  expect.pass "testExists skipped (venv not available)"
fi
```

This is the right pattern — tests survive on a venv-less host (e.g. fresh container before `private.ensureVenv` has run) while still surfacing the real assertions when the venv exists. See `test.otest:52–53` for the venv-symlink trick that lets fixtures reuse the real `$OTEST_DIR/venv` instead of building one in the test sandbox.

### Required vs. optional

| Surface | Python policy |
| --- | --- |
| `otest run`, `otest browser.open`, `otest setup`, `otest here`, `otest newTest` | **Required.** `private.ensureVenv` fails loud and installs `python3-venv` if missing. |
| `claudeCode.context.{read, dashboard, check}` | **Required.** No fallback. Returns `unknown` / empty if `python3 -c` fails silently (via `2>/dev/null`). |
| `scrumMaster.measure.subscription` and OAuth helpers | **Soft.** `command -v python3` first, `command -v jq` second, hard error if neither. |
| `debug` exit-code labelling (`errno()`) | **Soft.** `if command -v python3` then friendly errno, else plain `EXIT N`. |
| `oo cmd errno` | **Installer.** Resolves "errno" to `oo cmd python3 python3`. |

## Methodology audit

Doctrine: `feedback_oosh_methodology` — *"prefer OOSH commands/templates over raw bash; create new methods via oo.new.method before writing inline bash; consult docs/"*. Applied to Python: prefer OOSH/bash primitives; reach for Python when it's the right tool; keep Python at arm's length (separate file or thin wrapper), not embedded as multi-line heredocs that hide from linters, tests, and code review.

Classification key:

- ✅ **Justified** — Python is genuinely the right tool; current shape is fine.
- ⚠️ **Smell** — Could plausibly be better (extract to a `.py` helper, use a more idiomatic tool, normalise the wrapper). Not urgent.
- ❌ **Drift** — Clearly off-doctrine; should be ticketed.

| # | Location | Lines | Verdict | Rationale |
| --- | --- | --- | --- | --- |
| 1 | `otest.browser.open` → `browser.py` | (whole) | ✅ | Playwright is Python; bash cannot drive a Chrome via CDP cleanly. The OOSH method is a thin bash shim — that's the right boundary. |
| 2 | `otest.run` → `run_tests.py` | (whole) | ✅ | Test runner needs YAML config, subprocess, screenshot diffs. Same reasoning: Python is the right tool; OOSH method is a thin shim. |
| 3 | `private.ensureVenv` venv lifecycle | `otest:488–570` | ✅ | Managing a Python venv with Python is canonical. The package-manager dispatch (`apt-get` / `dnf` / `yum`) is bash-idiomatic and correct. |
| 4 | `python3 -c "import ensurepip"` | `otest:511` | ✅ | Module-presence probe; only Python can answer. One-liner, self-documenting. |
| 5 | `python3 -c "import sys; print(f'{major}.{minor}')"` | `otest:514` | ✅ | Borderline (could be `python3 --version \| awk '{print $2}' \| cut -d. -f1,2`) but the Python form is shorter and avoids parsing assumptions. Keep. |
| 6 | `private.python` wrapper | `otest:572–575` | ✅ | Clean encapsulation; mirrors `private.ossh.ssh` style. Use it consistently (see #7). |
| 7 | `otest:446` raw `"$OTEST_DIR/venv/bin/python" run_tests.py …` | `otest:446` | ⚠️ | Bypasses the `private.python` wrapper at `:572`. Minor inconsistency; should be `private.python run_tests.py …`. One-line fix. |
| 8 | `private.testExists` inline Python | `otest:698–718` (21 lines) | ⚠️ | Heavy logic embedded in a bash heredoc: hard to lint, no unit tests, parameter passed by string interpolation (`'$target'` and `'$eamdRoot'` — both injected unescaped into a Python literal, fragile if either contains a `'`). Extract to `$OTEST_DIR/test_discovery.py exists <target>`. |
| 9 | `private.testNames` inline Python | `otest:729–748` (19 lines) | ⚠️ | Sibling of #8; share the same helper. `$OTEST_DIR/test_discovery.py names`. The two together become a clean ~50-line Python module with proper argparse, parametrised paths, and the heredocs collapse to two-line calls. |
| 10 | `private.claudeCode.context.from.jsonl` inline Python | `claudeCode:1058–1079` (22 lines) | ⚠️ | JSONL parsing logic; same smell as #8/#9 plus uses `$jsonlFile` injected unescaped. Extract to `$OOSH_DIR/private/claudeCode_jsonl.py context-from <file>`. |
| 11 | `private.claudeCode.velocity.calculate` inline Python | `claudeCode:1281–1336` (56 lines) | ⚠️ | The longest inline Python in OOSH. Has its own try / except, datetime parsing, rate math. **Most pressing extract candidate.** Should be a real `.py` helper with argparse. |
| 12 | `claudeCode.context.dashboard` inline Python | `claudeCode:1372–1409` (38 lines) | ⚠️ | Third JSONL-parsing function in `claudeCode` — overlaps logic with #10 and #11. Extract together with them; the three currently re-implement very similar JSONL message-walking code. |
| 13 | `scrumMaster:1226–1227` one-liners for OAuth | `scrumMaster:1226, 1227` | ✅ | One-liners, has `jq` fallback (`:1229`), idiomatic. Keep. |
| 14 | `scrumMaster:1244` token-expiry one-liner | `scrumMaster:1244` | ✅ | One-liner; arithmetic + epoch comparison is Python-natural. Keep. |
| 15 | `private.measure.subscription.api.parse` inline Python | `scrumMaster:1272–1292` (21 lines) | ⚠️ | Has a `jq` fallback (good), but the 21-line block is heavy. Lower priority than #10–#12 because the fallback exists. Could be extracted alongside #10–#12 if you ever consolidate JSON-parsing helpers. |
| 16 | `debug:280–284` errno labelling | `debug:280–284` | ✅ | One-line `python3 -c`, soft-fails to `EXIT N` text. Comment in source explicitly justifies the choice (avoids cascading installs from inside an `ERR` trap). Keep. |
| 17 | `oo:2295` `errno` → python3 install dispatch | `oo:2295` | ✅ | Standard `oo cmd` mechanism. Aligned. |
| 18 | `ossh:2573` `python3` in completion list | `ossh:2573` | ✅ | Completion only; no behavioural risk. |
| 19 | `docs/reports/generate_almalinux_report.py` | (whole) | ✅ | openpyxl XLSX generation; no bash equivalent. Stand-alone reporting tool, not OOSH surface. |

### Patterns worth calling out

- **Quoting safety**: items 8, 9, 10, 11, 12 all inject bash variables into Python source via direct string interpolation (`'$target'`, `'$jsonlFile'`). A path containing a `'` (single quote) breaks them. Extracting to `.py` helpers with `argparse` removes this class of bug entirely.
- **JSONL parsing duplication**: items 10, 11, 12 (and arguably 15) all read JSONL / JSON files and extract usage-style fields. A single small helper module could DRY them.
- **Wrapper symmetry**: `private.python` exists for venv calls; `private.ossh.ssh` exists for ssh; there is **no** wrapper for system `python3 -c` invocations. None is needed at present, but if items 10–12 stay inline, a `private.python.system "<code>"` helper would at least centralise the `2>/dev/null` and the `command -v python3` guard.

## Recommendations

Listed smallest-first.

1. **One-line fix — normalise `otest:446`** to `private.python run_tests.py "$testName" "${pythonArgs[@]}"` so all venv invocations route through `private.python`.
2. **Extract `otest`'s test-discovery heredocs** (items 8 + 9, 40 lines combined) to `$OTEST_DIR/test_discovery.py` with subcommands `exists` and `names`. Bash methods shrink to `private.python "$OTEST_DIR/test_discovery.py" exists "$target"` and `… names`.
3. **Extract `claudeCode`'s JSONL parsing** (items 10 + 11 + 12, 116 lines combined) to a single `$OOSH_DIR/private/claudeCode_jsonl.py` with subcommands `context-from <file>`, `velocity <file>`, `dashboard-row <file>`. Largest win: testability, quoting safety, no more cross-method copy-paste of the JSONL walk.
4. **Optional — apply same treatment to `scrumMaster:1272–1292`** (item 15) if and when #3 lands; consider whether the OAuth subscription parsing belongs alongside the claudeCode helpers or in its own `scrumMaster_oauth.py`.

None of these are urgent — the current code works. They're "before-the-next-feature" hygiene that pays off the moment any of those inline blocks needs to change.

### Pending hand-off — claudeCode python3 hard-dep

Recommendation #3 above (extract `claudeCode`'s JSONL parsing) has been narrowed and handed off to the original author, Marcel Donges. The driver is a related rule we've separately settled on:

> *"Apart from otest, python should not be a dependency, but nice to use if it is installed."*

`claudeCode`'s three inline-Python blocks (items #10, #11, #12 above — introduced in Marcel's commits `894a618` and `b2f6892`, Feb 2026) are the only remaining hard python3 deps outside otest. Hannes' own `debug` precedent (`d1c6ce0`, May 2026) is the canonical migration pattern. Ticket: `docs/handoffs/2026-05-27-handoff-marcel-claudeCode-python.md`.

## Out of scope (deliberate)

- **Code quality review** of the `.py` files themselves (e.g. `browser.py`'s 695 lines, `ipad_browser.py`'s 886) — flagged for separate follow-up if wanted.
- **Security / dependency hygiene** — `requirements.txt` uses `>=` floors (not exact pins). Reproducibility, supply-chain review, CVE history of Playwright/PyYAML — separate ticket.
- **`generate_almalinux_report.py` deep review** — stand-alone reporting tool, no OOSH surface, no methodology impact.
- **Performance** — most invocations are one-shot at user-command time; the venv start cost is the dominant factor and is well understood (`otest.setup` only).
- **`docs/plans/2026-03-05-web4pycomponent-*.md`** — design + implementation plan for a future Web4PyComponent (full Web4 implementation *in* Python). Not yet present in the codebase; out of scope for an audit of what exists today. Worth re-auditing when/if it lands.
