# sweep.detect fixtures

Mock pane content samples for testing `private.hiveMind.sweep.detect`. Each
fixture feeds into the detector and should produce the expected
`status|action|severity[|detail]` output.

Wire into a test by setting up a scratch tmux pane, sending the fixture
content via `otmux send.raw`, then invoking sweep.detect (via hiveMind's
pane.sweep / team.sweep or direct function call).

## Fixtures

| Fixture | Expected status | Notes |
|---------|-----------------|-------|
| `permission.txt` | `permission\|enter\|blocker` | Standard "Do you want to run this command?" + ❯ menu |
| `permission-edit-variant.txt` | `permission\|enter\|blocker` | "Do you want to make this edit" variant |
| `permission-proceed-variant.txt` | `permission\|enter\|blocker` | "Do you want to proceed?" variant |
| `permission-false-positive-prose.txt` | **NOT permission** | Prose mentions "Do you want to run this?" but no live ❯ menu. Must fall through to active/idle. |
| `rate-limit.txt` | `rate-limit\|wait\|blocker\|in 45 seconds` | Standard throttle msg |
| `rate-limit-overloaded-variant.txt` | `rate-limit\|wait\|blocker\|...` | 529 Overloaded variant |
| `rate-limit-false-positive-source.txt` | **NOT rate-limit** | Source-code display of the grep pattern. prose-scrub should filter comments + `\| grep` lines. |
| `subscription-limit.txt` | `subscription-limit\|none\|critical` | Daily limit reached |
| `subscription-limit-billing-variant.txt` | `subscription-limit\|none\|critical` | Billing cap variant |
| `subscription-limit-false-positive-source.txt` | **NOT subscription-limit** | Source display with grep pattern |
| `accept-edits.txt` | `accept-edits\|enter\|blocker\|2` | `⏵⏵ accept` with 2 queued bashes |
| `fp-accept-edits-scrollback.txt` | **NOT accept-edits** (idle) | `⏵⏵ accept` text in scrollback; live status bar is `❯`. F2.2 — must match tail-only. |
| `context-warning.txt` | `context-warning\|none\|warning\|18%` | Auto-compact at 18% |
| `just-compacted.txt` | `just-compacted\|none\|warning` | "Compacted" marker |
| `queued.txt` | `queued\|enter\|blocker` | Text after ❯ prompt, not submitted |
| `overlay.txt` | `overlay\|escape\|blocker` | "Background tasks" panel |
| `panel.txt` | `panel\|escape\|blocker` | git diff panel with "Esc close" |
| `autocomplete.txt` | `autocomplete\|escape\|blocker` | /compact dropdown visible |
| `shell-escaped.txt` | `shell-escaped\|none\|critical` | Bare `$` prompt = agent left Claude |
| `crash.txt` | `crash\|none\|critical` | fatal + segfault + SIGKILL |
| `api-error.txt` | `api-error\|wait\|blocker\|...` | APIConnectionError / 503 |
| `mcp-error.txt` | `mcp-error\|wait\|warning` | MCP disconnect/timeout |
| `tool-confirm.txt` | `tool-confirm\|enter\|blocker` | Confirm tool use — single-line Enter |
| `active.txt` | `active\|none\|info` | Running tool, tokens flowing |
| `idle.txt` | `idle\|none\|info` | Clean `❯` prompt on last line |
| `unknown.txt` | `unknown\|none\|info` | Empty content |

## F2.2 — False-positive fixtures (comment-aware prose-scrub)

Source-code displays that mention trigger substrings only inside comments
of various languages. The F2.1 scrub strips comment lines before substring
matching — these must all fall through to `active|none|info`.

| Fixture | Comment style | Must NOT trigger |
|---------|---------------|------------------|
| `fp-js-slashslash-comment.txt` | `//` (JS/TS/Go/Rust/Java/C++/Swift/CSS) | rate-limit, subscription-limit |
| `fp-sql-dashdash-comment.txt` | `--` (SQL/Haskell/Lua/Ada/Elm) | subscription-limit |
| `fp-c-block-comment.txt` | `/* ... */` + `*` continuation | api-error |
| `fp-html-comment.txt` | `<!-- -->` (HTML/XML/Markdown) | mcp-error |
| `fp-python-docstring.txt` | `#` (Python/Ruby/YAML) | api-error, rate-limit |
| `fp-menu-text-not-live.txt` | n/a — prose describes menu | permission (needs live ❯) |

## Edge-case rationale (focus per PO directive)

### permission

False positives historically came from prose describing the prompt
without an actual menu visible. The detector requires BOTH:
- `Do you want to` (text match)
- `^\s*❯\s*[0-9]+\.\s*(Yes|No|Allow|Deny)` (live menu with arrow)

The false-positive fixture has the text but not the menu shape.

### rate-limit, subscription-limit

False positives came from source-code displays showing the grep regex
strings literally (self-referential match when viewing hiveMind source).

The detector uses `$prose` (scrubbed via):
```bash
grep -v '^[[:space:]]*#'              # drop shell comments
grep -vE "(grep|sed|awk|echo)[[:space:]]+-?[a-zA-Z]*[[:space:]]*['\"]"  # drop greps
grep -vE "^[[:space:]]*(if|elif|fi|then|...)[[:space:]]*[[(]"  # drop control flow
grep -vE "^[[:space:]]*\|[[:space:]]*(grep|sed|awk)|^[[:space:]]+\\\\$"
```

The three false-positive fixtures prove the scrub works.

## Usage (for C3.3 tester)

```bash
# Per-fixture roundtrip:
for fixture in /Users/donges/oosh/test/test.data/sweep.detect/*.txt; do
    name=$(basename "$fixture" .txt)
    expected_status=$(awk -F'|' '/^\|\s*'"$name"'\.txt/ {...}' README.md)

    # Setup a scratch pane, pipe fixture content, run detector
    otmux new scratch_sweep 2>/dev/null
    # Use cat -E or echo -n with fixture — but tmux capture may re-flow lines
    # so prefer an `echo` ladder OR use tmux load-buffer + paste-buffer

    # One approach: dump fixture via send.raw
    while IFS= read -r line; do
        otmux send.raw scratch_sweep "$line" Enter
    done < "$fixture"

    result=$(private.hiveMind.sweep.detect scratch_sweep)
    # compare ${result%%|*} with expected_status
    ...
done
```

A more robust test approach would be to expose a testable entry point in
sweep.detect that accepts content via stdin rather than captured from a
pane — consider refactoring in a later task. For now, pane-based test
covers the real-world flow.
