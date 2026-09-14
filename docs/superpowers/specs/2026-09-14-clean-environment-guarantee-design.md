# Design: the clean-environment guarantee

**Date:** 2026-09-14 · **Branch:** `dev` · **Ticket:** T3 — `env -i sh. SAVETY...shall boot correctly`

## Context

`env -i` in this project was never a command you type at a prompt. It is two related things, both
about **starting from a clean environment**:

1. the shebang `init/oosh` carried from **2024-04-07** to **2026-03-09** —
   `#!/usr/bin/env -iS HOME=${HOME} sh`, introduced by Chris Daßler (`8c277f4`, `815d14d`) with the
   message *"Shebang for clean environment"*;
2. the commands the **README still documents** in its debugging section —
   `unbuffer env -i sh -xc "$(wget -O- …/init/oosh)" | tee install.log.txt`.

The shebang wiped the environment **but passed `HOME` through**, because `HOME` is the one thing
that cannot be derived from nothing. That is the "SAVETY" the card names.

It was removed by `075b4a3` (2026-03-09): *"BusyBox env doesn't support `-S` flag"* — Alpine
compatibility. A real constraint, not a mistake. But **nothing replaced the guarantee**, and `main`
(last touched 2026-03-12) is the only branch that still carries the shebang.

Today the documented command does not work: `env -i` drops `HOME`, and `init/oosh` computes
`OOSH_DIR=/oosh` and `INSTALL_LOG=/config/install.log`. `boot` refuses outright.

### The `-S` problem is avoidable

Measured on this host:

| | `env -i VAR=val cmd` | `env -S` |
|---|---|---|
| GNU env | ✅ | ✅ |
| **busybox env** | ✅ | ❌ `invalid option -- 'S'` |

`-S` was only ever needed because a **shebang** can pass a single argument. Moving the clean-exec
*inside* the script removes that constraint: `exec env -i HOME="$HOME" … "$0" "$@"` works on
busybox, keeps arguments, and needs no `-S`.

## The guarantee

**Starting oosh from a clean environment works, whichever way you got there — and `HOME` is
recovered rather than demanded.**

## Design

### 1 · Where it is enforced

Three entry paths. `$0` was measured in each:

| How it starts | `$0` | Needs |
|---|---|---|
| `./init/oosh`, `sh init/oosh` | the script's path | **re-exec clean**, then recover `HOME` |
| `sh -c "$(wget …)"` (the one-liner) | `sh` — not a file | **cannot re-exec**; recover `HOME` only |
| `. ~/oosh/boot` (sourced) | the shell's name | **must never re-exec**; recover `HOME` only |

The re-exec is guarded on two conditions: `$0` is a readable file, and an `OOSH_CLEAN_ENV` sentinel
is unset. The sentinel makes it fire exactly once and makes looping impossible.

```sh
# 1. recover HOME first, so the re-exec carries a GOOD value
# 2. then re-exec clean, once
if [ -z "$OOSH_CLEAN_ENV" ] && [ -f "$0" ]; then
  exec env -i HOME="$HOME" OOSH_CLEAN_ENV=1 "$0" "$@"
fi
```

**Order matters, so it is fixed here:** `HOME` is recovered **before** the re-exec, and the
recovered value is what `env -i HOME="$HOME"` carries across. The child then finds a usable `HOME`
and its own recovery is a no-op. (Re-execing first and recovering in the child also works —
`env -i HOME=` sets it empty, which the `-z` test still catches — but specifying one order removes
the ambiguity and keeps the recovery in a single place per run.)

### 2 · Recovering `HOME`

`getent passwd "$(id -un)"` → `dscl . -read /Users/<u> NFSHomeDirectory` (macOS; take the **first**
of the two paths it returns for `root`) → `/etc/passwd` via `awk`. The same three-way split the
tree already uses (`this:126-134`).

An explicitly set, usable `HOME` always wins — recovery fires only when `HOME` is empty **or not a
directory** (a removed user, or a container that inherited the builder's). If all three lookups come
up empty there is nothing safe to anchor to, so it refuses with one diagnostic — by `return` in
`boot` (sourced: `exit` would close the user's shell) and `exit` in `init/oosh`.

### 3 · Duplication is inherent, not a smell

`init/oosh` runs **before oosh exists**; `boot` runs **before `this` is loaded**. Neither may source
a shared helper. Both carry their own copy of the lookup, each commented as deliberate. Extracting
it would create exactly the dependency these two files exist to avoid.

### 4 · What must never happen

- **`boot` must never re-exec.** It is sourced; `exec` would replace the user's shell.
- **No loop.** The sentinel is set in the same `env -i` that performs the re-exec.
- **A working `HOME` is never overridden.**
- **Nothing may depend on `env -S`** — that is what broke Alpine and cost the guarantee in the first
  place.

### 5 · What is deliberately *not* restored

The shebang itself. `#!/usr/bin/env -i sh` would drop `HOME` (worse than today), and a shebang
cannot portably pass two words. The re-exec supersedes it and covers strictly more cases — the
shebang never protected the piped one-liner, because a shebang is not read when content is piped.

## Testing

Each entry path across `sh`, `dash`, `bash` and `busybox ash`:

| Test | Asserts |
|---|---|
| polluted environment, direct execution | the re-exec fires; the child sees a clean environment; arguments survive |
| `env -i` with no `HOME`, piped | `HOME` recovered from the password database; `OOSH_DIR` is `~/oosh`, not `/oosh` |
| explicit `HOME` | never overridden |
| stale `HOME` (set, not a directory) | recovered, not trusted |
| no home derivable at all | one diagnostic, non-zero; `boot` *returns*, `init/oosh` *exits* |
| sourced `boot` | never re-execs — the calling shell survives |
| `-S` free | no `env -S` anywhere in `init/oosh` or `boot`, so Alpine cannot regress |

Each guard proven able to **fail** before it is trusted — including against the current code, where
the recovery tests will fail until the change lands.

End to end: the README's own command, verbatim, against a scratch `HOME`.

## Prior art in this repository

The `HOME` recovery was written and verified earlier on 2026-09-14 (commit `5e44f2b`, since
reverted as collateral in `a8b6928`). It worked in all four shells. This is re-applying a known
quantity, not new invention — see also
[the boot-tickets tracker §4d](../../plans/2026-09-10-oosh-boot-tickets.md).

Two implementation lessons from that round, both learned the hard way:

- a host test that runs **with the oosh tree as its working directory** can mask a missing `PATH`,
  because bash's `source` falls back to the cwd. Tests must `cd` elsewhere first.
- `${var/$pattern/…}` needs its **pattern quoted**, or a leading `#` silently fails to match.
