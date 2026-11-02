# `ossh` deep dive — `origin/dev` vs `origin/test/mcdonges.latest`

Generated 2026-11-02. Companion to `docs/method-differences-dev-vs-mcdonges.md`.
Everything is measured on the two branch tips: `dev` = `7ab831d9`, `mcdonges.latest` = `760552c7`.

## 1. Size and vintage

| | merge base `1604e3ed` | `mcdonges.latest` | `dev` |
|---|---:|---:|---:|
| Lines in `ossh` | 1 461 | 1 770 | 4 125 |
| Top-level methods | 94 | 160 | 230 |
| … of which public | — | 108 | 144 |
| Last commit touching `ossh` | 2026-02-17 | 2026-08-29 | 2026-10-22 |

So `dev`'s `ossh` is **2.3× the size** of mcdonges' and was still being changed two months
later. Of the methods that exist on both sides, 78 differ; 59 exist only on mcdonges and
129 only on dev.

## 2. Verdict in one paragraph

The two lines forked at the March merge base and then ran **the same object.verb rename
campaign twice, two days apart, with different outcomes** (dev `2fe51334` 2026-03-16,
mcdonges `17ab53d9` 2026-03-18). mcdonges then added a generic `ossh get/set`
dispatcher and two small fixes, and **froze `ossh` on 2026-08-29**. dev kept going:
hardening, shared SSH config, remote prereqs, key revocation, install split, ProxyJump-aware
identity staging, and a second rename in October (`dc7aa950`, `e169601f`) that produced the
`private.ossh.key.push` / `ossh.authorized.keys.update` names its test now enforces.
Most of the 59-vs-129 "different methods" is therefore **naming drift, not competing
behaviour** — but dev also carries ~100 methods of real feature work that mcdonges never had.

## 3. Where each side's additions come from

**mcdonges-only (59):**

| Group | Count | Introduced by |
|---|---:|---|
| Generic verb dispatchers `ossh.get` / `ossh.set` (+ completions, `private.ossh.dispatch(.objects)`) | 8 | `549395d1`, `acf2a27f`, `e479443d` — 2026-03-27 |
| Names chosen by the T-69 rename (`ossh.key.folder.create`, `ossh.server.ip.get`, `ossh.id.public.get`, `ossh.permission.fix`, `ossh.authorized_keys.update`, `ossh.install.create`, …) | 13 | `17ab53d9` — 2026-03-18 |
| `private.ossh.config.*.completion.configItem` hooks for the 14 per-field accessors | 14 | `a537368d` — 2026-03-20 |
| Filesystem completions (`*.completion.dir`, `*.completion.sshDir`) | 6 | `01c868f5` — 2026-03-31 |
| `config.pull` validation helpers `private.ossh.hostKnown`, `private.ossh.validConfigBlock` | 2 | `15012c42` — 2026-07-15 |
| `private.ossh.config.deploy.write` (config.create appends the Host block to `~/.ssh/config`) | 1 | `c3a905bc` — 2026-08-29 |
| Legacy 2022 helpers that dev deleted (`ossh.push.*`, `ossh.pull.*`, `ossh.scp`, `private.push.init.oosh`, …) | 15 | pre-history |

**dev-only (129), by feature** (buckets sum to 129):

| Feature | Methods | Since |
|---|---:|---|
| `ossh.harden` — fail2ban, firewall, packages, sshd, AllowUsers, unattended-upgrades | 17 | 2026-04-21 (`290b1958`) |
| Shared SSH config + GitHub hosting (`ossh.config.shared.*`, `private.ossh.github.*`, `private.ossh.shared.ssh.legacy.remove`) | 16 | 2026-04-01 … 2026-10-19 |
| `ossh.folder.fix` / `folder.fix.check` — repair and diagnose `~/.ssh` drift | 10 | 2026-05-12 (`716fc38d`) |
| `ossh.cmd` + `ossh.prereqs.install` + `ossh.pm.discover` — remote package-manager work | 7 | 2026-04-24 (`867dba9e`) |
| Install split/logging (`ossh.install.log`, `ossh.install.user.remote`, `private.ossh.oosh.init.push`) | 5 | 2026-02-27 … 2026-10-20 |
| `ossh.exec.tty`, `ossh.known.hosts.remove`, `ossh.remote.prelude.get`, control-path helpers | 7 | 2026-03-09 … 2026-09-30 |
| Config / Host-block editing (`ossh.config.delete`, `private.ossh.config.field.keyword.get`, last-file readers) | 11 | 2026-10-14 (`ab699fdb`) |
| Key & identity: `ossh.key.revoke`, `private.ossh.remote.public.key.put`, `private.ossh.install.key.authorize`, `private.ossh.key.push.identity.get`, `private.ossh.identity.stage*` | 25 | 2026-10-15 … 2026-10-20 |
| Old names dev keeps under the post-October naming (`ossh.server.get.ip`, `ossh.rights.fix`, `ossh.publicId.get`, …) and transport helpers (`private.ossh.dir.*`, `user.homes.get`, `basehome`) | 31 | 2022 … 2026-05 |

## 4. The rename collision

Same concept, different name — body similarity ≥ 0.73 (code-only comparison):

| mcdonges name | dev name | Similarity |
|---|---|---:|
| `ossh.parameter.completion.formHost` | `ossh.parameter.completion.fromHost` | 0.98 |
| `ossh.id.public.get` | `private.ossh.get.public.id` | 0.97 |
| `ossh.server.ip.get.darwin` | `ossh.server.get.ip.darwin` | 0.97 |
| `ossh.server.ip.get` | `ossh.server.get.ip` | 0.96 |
| `ossh.key.folder.create` | `private.ossh.create.key.folders` | 0.95 |
| `ossh.key.folder.delete` | `private.ossh.delete.key.folders` | 0.95 |
| `ossh.server.ip.get.linux` | `ossh.server.get.ip.linux` | 0.93 |
| `ossh.key.name.set` | `private.ossh.set.key.name` | 0.92 |
| `ossh.install.create` | `ossh.create.and.install` | 0.77 |
| `ossh.key.name.get` | `private.ossh.get.key.name` | 0.73 |
| `ossh.get.public.id` | `ossh.publicId.get` | 0.63 |

Note `formHost` vs `fromHost` — mcdonges kept a typo that dev fixed.

mcdonges also keeps **thin verb-first aliases** that dev deleted outright:

| Alias (mcdonges only) | Delegates to |
|---|---|
| `ossh.push.key`, `ossh.pull.key` | `ossh.key.push` / `ossh.key.pull` |
| `ossh.push.config`, `ossh.pull.config` | `ossh.config.push` / `ossh.config.pull` |
| `ossh.push.dir`, `ossh.pull.dir` | `ossh.dir.push` / `ossh.dir.pull` |
| `ossh.push.id`, `ossh.pull.id` | `ossh.id.push` / `ossh.id.pull` |
| `private.push.init.oosh` | remote installer (dev renamed it `private.ossh.oosh.init.push`) |

All of them are marked `DEPRECATED — use …` in their own docstring; dev deleted the wrappers
instead of keeping both names. `ossh.scp` is the exception: it is a real method (ControlMaster
scp) that dev dropped rather than an alias.

and a **caller-visible dispatcher** dev never had:

```bash
ossh get <object> <field>     # e.g. ossh get config.2c user
ossh set <object> <field> <value>
```

implemented by `private.ossh.dispatch.objects` (2026-03-27). dev instead names each field
explicitly: `ossh config.field.get <configItem> <field>`, `ossh config.set <configItem> <field> <value>`.
`ossh get …` does not run on dev. `ossh config.field.get` exists on both branches, with
different implementations.

## 5. Behaviour that genuinely differs (the 78 changed methods)

| Area | Changed | What actually changed |
|---|---:|---|
| Config | 41 | dev: field keyword validation, `create.result`/`RESULT` contract, per-field get/set split; mcdonges: a simpler `type -t` setter dispatch |
| Connection / exec | 10 | dev routes through `private.ossh.ssh` + `ossh.remote.prelude.get`; mcdonges calls raw `ssh` and `source config/user.env` |
| Key / id | 5 | dev pushes the Host's `IdentityFile` key, verifies the login, enforces 644; mcdonges rsyncs a named key and runs `user update.authorized_keys` |
| Install | 5 | dev: `install → config.parse → private.ossh.oosh.init.push`, log level, target user; mcdonges: one-shot `private.push.init.oosh` |
| Dir/id transfer | 5 | shared `private.ossh.rsync` refactor on both sides, different argument handling |
| List/status/usage/other | 12 | new verbs in `--help`, status detail, `ossh.test`, `ossh.url.get` |

Four representative diffs:

**`ossh.exec`** — mcdonges assumes the remote has a config:

```bash
# mcdonges
ssh -o ControlPath="$OSSH_CONTROL_PATH" $toHost "source config/user.env; $@"
# dev
private.ossh.ssh "$toHost" "$(ossh.remote.prelude.get) $@"
```
dev's prelude falls back to `~/oosh` on `PATH`, so the command still resolves on a host
that is mid-install. mcdonges fails there.

**`ossh.config.set`** — mcdonges builds a method name and calls it; dev validates the field
name first (the field literally called `field` used to shift arguments into
`private.ossh.config.field.set`), answers `create.result` + `RESULT`, and lists the legal
fields on error.

**`ossh.isInstalled`** — mcdonges repairs the key folders by calling
`user ssh.create.folders`; that method no longer exists on dev (removed 2026-10-20), so dev
creates the folders itself and copies the key pair, with a comment saying why.

**`ossh.key.push`** — mcdonges is a 26-line inline push (rsync + remote
`user update.authorized_keys`, no login check). dev is a 9-line wrapper over
`private.ossh.key.push`, which pushes the key the Host entry actually logs in with and then
verifies the login.

## 6. Caller compatibility matrix

| Call | dev | mcdonges |
|---|:--:|:--:|
| `ossh key.push` / `key.pull` | Y | Y |
| `ossh push.key` / `pull.key` (legacy) | – | Y |
| `ossh key.revoke` | Y | – |
| `ossh authorized.keys.update` | Y | – |
| `ossh authorized_keys.update` | – | Y |
| `ossh server.get.ip` | Y | – |
| `ossh server.ip.get` | – | Y |
| `ossh rights.fix` | Y | – |
| `ossh permission.fix` | – | Y |
| `ossh get` / `ossh set` (dispatcher) | – | Y |
| `ossh config.field.get` | Y | Y |
| `ossh config.set` | Y | Y |
| `ossh config.delete` | Y | – |
| `ossh harden`, `folder.fix`, `cmd`, `prereqs.install`, `install.log` | Y | – |
| `ossh install.create` | – | Y |
| `ossh create.and.install` | Y | – |
| `ossh scp` | – | Y |

## 7. What to take from where

- **dev is the feature superset.** Merging mcdonges into dev should not take `ossh` over:
  mcdonges' file would delete hardening, shared config, folder.fix, prereqs, key.revoke, the
  install split and the October key/identity work — 2 355 lines.
- **Nothing in mcdonges' `ossh` is a capability dev lacks** in kind; the differences are naming,
  the dispatcher, and three design choices:
  1. `ossh get/set` generic dispatcher vs dev's explicit `ossh config.field.get` / `ossh config.set`.
     Keep whichever the callers use — they are not interchangeable.
  2. `config.pull` validation: mcdonges does it with `private.ossh.hostKnown` +
     `private.ossh.validConfigBlock` (`15012c42`, 2026-07-15); dev does it inline (Host-name
     `case` check, "already present" probe, atomic whole-file write via `private.this.file.write`).
     Two implementations of the same guard, not a missing one.
  3. `config.create` wiring: mcdonges appends the new Host block straight into `~/.ssh/config`
     through the `private.ossh.config.deploy.write` callback (`c3a905bc`, 2026-08-29); dev writes
     the block to its own "last" file and leaves the append to `ossh config.save.last`.
- **Port the mcdonges tests forward too**: `test/test.ossh` on mcdonges has no
  `T-OSSH-RENAMES-OBJECT-VERB` guard, which is why legacy names still live there. dev's guard
  (and the core suite) is what keeps the rename from drifting back.
- If a script of yours still calls `ossh push.key`, `ossh pull.*`, `ossh server.ip.get`,
  `ossh authorized_keys.update` or `ossh get …`, it works on mcdonges and breaks on dev —
  that is the only class of breakage hiding in this diff.

## 8. Caveats

- "Changed" is byte comparison of the method block; reformatting or a docstring edit counts as
  a change (3 of the 78 are doc-only: `ossh.usage`, `ossh.test`,
  `ossh.parameter.completion.dir`).
- Rename pairs come from body similarity; a pair below 0.7 is left in added/removed even if it
  is a rename.
- The line/method counts use `name()` and `function name` definitions at column 1; `ossh` uses
  only the first form.
- Commit attribution uses `git log -S "<name>()" -- ossh`; for names that existed before the
  merge base it reports the last commit that introduced the string on that line, which can be
  a 2022 commit even though the method was renamed later.
