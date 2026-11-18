# Fix: log output loses its formatting (colours and bold level labels)

**Status:** implemented on `dev` (working tree), tests added and green.
**Date:** 2026-11-18
**Scope:** `log` (colour loading, `log.init.colors`), `line` (`line.init`'s derived colour files), `test/test.log`, `test/test.line`, `docs/log.md`.
**Triggered by:** "Log output sometimes loses its formatting (including the log level display) — identify the cause."
**Diagnosis first:** the symptom was reproduced and traced before any change (systematic debugging); the tests were written red first, then the fix was applied.

---

## 1. Symptom

Log output was colourless **sometimes** — same machine, same `LOG_LEVEL`, depending on which command produced it:

| command | before |
|---|---|
| `./oo v` | `^[[31mERROR> …^[[0m` ✔ |
| `./user v` | coloured ✔ |
| `./ossh v` | coloured ✔ |
| `./odocker v` | coloured ✔ |
| `./config v` | `ERROR> …` ✘ |
| `./state v` | `ERROR> …` ✘ |
| `source os; important.log hi` | `IMPORTANT> hi` ✘ |

The level words (`ERROR>`, `IMPORTANT>`) survived; their colour — and the bold
of every `BOLD_*` level — was missing.

---

## 2. Root cause 1 — colours were loaded only by `line`

Every log function writes pre-formatted strings built from `${BOLD_*}`,
`${NORMAL}` and `${GRAY}` (e.g. `log:263` `private.log.emit "${BOLD_CYAN}IMPORTANT> $*${NORMAL}"`).
Those variables are defined **only** in `$CONFIG_PATH/setup.color.env`.

Who read that file?

| reader | when |
|---|---|
| `line.init` (`line:775`) | whenever the `line` script is sourced/executed, via `line.start` (`line:802`) |
| `templates/user/bashrcTemplate:203` | interactive shells only (the file returns early for non-interactive shells at line 37) |
| `log.init.colors` | effectively dead: called only from `log.init`'s `[ -z "$CONFIG" ]` arm (`log:93`), unreachable because `log` sources `this` which cold-starts first; `log.start`'s call is commented out (`log:836`) |

So colours existed in a process only if `line` had been loaded. That is why the
set of coloured scripts looked arbitrary:

```
user.start → ossh.start → source line      → coloured
oo.start   → source user   → …             → coloured
odocker    → source ossh   → …             → coloured
config     → source this   (no line)       → plain
os         → source this   (no line)       → plain
state      → source this   (no line)       → plain
```

`this` itself only sources `line` through `this.path.add`, which runs only for
the `$0` basenames `init|oosh|log|this` (`this:2124-2155`), not for normal
commands. Because the colour variables are also **not exported**, every child
process had to load them again — and the scripts above never did.

A second, ordering effect inside a run: log lines emitted before `line` is
sourced (e.g. `source this` boot, `this.init`, cold-start warnings) are plain;
lines after it are coloured.

**Why it was "sometimes":** it depended on the script's `source` graph and on
startup order, not on `LOG_LEVEL` or the log call.

---

## 3. Root cause 2 — `BOLD_*` was never bold

Even where colours loaded, `bold.color.names.env` held the plain colours:

```
color.env          COLOR_RED=^[[31m
bold…names.env     BOLD_RED=^[[31m      # would be BOLD_RED=^[[1;31m
```

`line.init`'s old derived-file block generated it with

```bash
… | line.replace "{ESC}" "{ESC}1;"
```

but `color.env` holds **real escape bytes** (`^[[31m`), not the text `{ESC}`,
so the replacement matched nothing. The file was written only when
`color.env` was missing, so an install that already had one kept the wrong
text for good — another "sometimes" (old installs vs fresh ones).

While fixing it, a second trap surfaced: inserting `1;` into the unquoted
assignment `BOLD_RED=ESC[1;31m` makes the shell treat `;` as a command
separator — it assigned `BOLD_RED=ESC[1`, ran `31m` and printed
`31m: command not found`, rendering every bold level as a bare bold with no
colour. The values must be quoted.

---

## 4. Root cause 3 — an empty `CONFIG_PATH` read `/color.env`

Sourcing `setup.color.env` before `this.init` set the anchor made its own
chain lines resolve to the filesystem root:

```
source $CONFIG_PATH/color.env        # CONFIG_PATH empty → /color.env
source $CONFIG_PATH/color.names.env  # → /color.names.env
source $CONFIG_PATH/bold…names.env   # → /bold.color.names.env
```

This machine had stale `/color.env`, `/color.names.env` and
`/bold.color.names.env` (old, non-bold) left by an earlier empty-anchor run,
which silently overrode the correct values. They were removed.

---

## 5. What was done, and why

### `log`

| Change | Why |
|---|---|
| new `private.log.colors.ensure` — source `$CONFIG_PATH/setup.color.env` once per process, skip when `BOLD_CYAN` is set, no write, no error, rc 0 when colours are present | one reader for the colour file, usable by anything that logs |
| `: ${CONFIG_PATH:=$HOME/config}` + `export CONFIG_PATH` inside it | the anchor default `this.init` uses; keeps the nested `$CONFIG_PATH/…` sources inside `setup.color.env` from resolving to `/` |
| called at `log` file scope | every process that sources `log` gets colours, whether or not it ever sources `line` |
| called again from `seq.puml.log` (every level calls it first) | a process that started before `setup.color.env` existed (fresh install, cold start) picks colours up as soon as the file is there — one place, not ten functions |
| `log.init.colors` delegates to `private.log.colors.ensure` and returns its rc | one reader; the public method keeps working for `otmux`, `hiveMind`, `test.suite` and manual use |

The log functions themselves were not touched: with the variables present they
already produce the right formatting.

### `line`

| Change | Why |
|---|---|
| new `private.line.color.names.write` — build `color.names.env` and `bold.color.names.env` from `color.env` | one place that derives both files, no `line.find`/`line.replace` pipeline |
| bold attribute inserted with a **quoted** bash substitution: `boldNames="${boldNames//"$ESC"/"${ESC}1;"}"` | literal ESC is not a regex; the old `"{ESC}"` pattern could never match the real escape byte |
| values written **quoted** (`BOLD_RED="ESC[1;31m"`) | `1;` is a shell command separator; unquoted it truncated the value and ran `31m` |
| called on **every** `line.init`, rewriting only when the text differs | old non-bold files heal on the next shell start / `oo update`; an unchanged file is not rewritten, so no write race between shells |
| removed the duplicate `color.names.env` generation from the `color.env`-missing branch | the helper now owns both derived files |

### Tests (written first — both failed before the fix)

| Test | Where | What it pins |
|---|---|---|
| `T-LOG-COLOURS-WITHOUT-LINE` | `test/test.log` | a child that sources `config` (never `line`) emits ANSI-coloured `important.log`; before the fix: `plain=[IMPORTANT> colour-probe]` |
| `T-LINE-BOLD-COLOR-NAMES` | `test/test.line` | generated `BOLD_*` carries the bold attribute; an old plain file heals; an unchanged file is not rewritten (inode kept); before the fix: `generated=[BOLD_RED=[31m] unhealed=…` |

### Docs

`docs/log.md` § Colors now says that `log` loads the colours itself and that
the derived names files are rebuilt when their text differs.

---

## 6. Verification

Command output after the fix (all bold, all coloured):

```
./config v  → ^[[1;31mERROR> …^[[0m
./os v      → ^[[1;31mERROR> …^[[0m
./state v   → ^[[1;31mERROR> …^[[0m
./oo v      → ^[[1;31mERROR> …^[[0m
./user v    → ^[[1;31mERROR> …^[[0m
```

Test suites (all green):

| suite | result |
|---|---|
| `./test.suite run log 1` | 68/68 |
| `./test.suite run line 1` | 17/17 |
| `./test.suite run this 1` | 80/80 |
| `./test.suite run config 1` | 146/146 |
| `./test.suite run os 1` | 7/7 |
| `./test.suite run state 1` | 29/29 |
| `./test.suite run user 1` | 88/88 |
| `./test.suite run oo 1` | 190/190 |

Manual idempotence check: a second `line.init` against the same config leaves
`bold.color.names.env`'s inode unchanged; a file written in the old format is
rewritten once and then left alone.

---

## 7. Rollout / healing

- Every process that sources `log` gets colours immediately — no action needed.
- A machine with an old `bold.color.names.env` heals the next time `line` is
  sourced (every shell start, `oo update`, `oo user.fix`); both files are
  content-compared, not existence-checked.
- Stale `/color.env`, `/color.names.env`, `/bold.color.names.env` (from an
  empty-anchor run before this fix) should be deleted if present; the
  `CONFIG_PATH` default in `private.log.colors.ensure` prevents new ones.

---

## 8. Deliberately not changed (follow-ups)

- **Colour variables are still not exported.** Child processes re-load them via
  `log`; exporting them would also change what non-oosh children (and
  colour-sensitive tools such as Claude Code) see. That is a separate decision.
  Note that `setup.color.env` sets `NO_COLOR` to a reset escape; it is not
  exported today, and exporting it would disable colour in tools that honour
  [no-color.org](https://no-color.org) — see `docs/tmux.claude.code.color.issue.md`.
- **`console.log` has no level word** and uses only a reset prefix. That is by
  design; a message moved from `important.log` to `console.log` loses its label,
  which is a call-site choice, not a formatting bug.
- **`log:288` emits `"${XXXX}${BOLD_CYAN}- …"`** — `XXXX` is an undefined
  leftover placeholder (harmless, renders empty). Left as is to keep this
  change scoped.
