# Design: `user` surface and generated help

**Date:** 2026-11-17 · **Branch:** `dev` · **Status:** approved design

## Context

`user` has drifted in three places at once:

- **Help text**: `user.usage` hardcodes a method list that still advertises `ssh.status`, `ssh.init`,
  `ssh.rename.files`, `ssh.get.key.name`, `ssh.get.file.name`, `ssh.set.key.name`, `ssh.create.folders`
  and `ssh.rootkey.*`. Commit `996ee515` deliberately removed those so `ossh` owns SSH key
  management. The hardcoded block is now the only place they appear.
- **Descriptions**: `list`, `list.all`, `list.groups`, `start` and `usage` carry no signature comment,
  and `user.get` has an empty description, so `this.help` renders "please add a description".
- **Surface**: `linux.delete` puts the OS before the verb, `password.set.darwin`/`.linux` are public
  although a dispatcher already exists, `in` is a vague verb, and `list.groups` (all groups) versus
  `group.list` (members of one group) is easy to read the wrong way.

`this.help` builds its table from the `name() # params # description #` signature, but it has no
notion of grouping, ordering or "hidden". Fixing `user` without fixing that would mean either a
second, hand-maintained help list (the current problem) or a flat alphabetical table that hides the
new structure.

## Goals

- One generated, sectioned `user` reference whose entries always match the code.
- A public `user` surface that follows `object.object.verb` and hides OS variants and lifecycle methods.
- Grouping and hiding expressed **next to the method**, not in a separate manifest.
- Untagged scripts keep today's flat, sorted help byte for byte.

## Non-goals

- Migrating the other ~6,600 methods to tags.
- Changing `ossh` ownership of SSH keys; the WODA initialiser stays in `user` (renamed to
  `user ssh.init`) because it writes the WODA Host aliases, which `ossh` does not.
- YAML frontmatter, a new completion engine, or a rewrite of `this.help.table`.
- Regenerating the oosh-architect docs (`docs/user.md`, `docs/methods-index.md`,
  `docs/object-verb-index.md`) as part of this change.

## 1. Target public surface

Invocation stays `user <method>` (or `./user <method>`); `this.call` already expands
space-separated compounds (`user list all` → `user.list.all`).

| Group | Method | Was |
|---|---|---|
| Account | `user create <username> <?password> <?uid> <?gid>` | unchanged |
| Account | `user delete <username>` | `user linux.delete` |
| Account | `user password.set <username> <password>` | unchanged public API; the two OS bodies merge into it |
| Account | `user login <userName>` | unchanged |
| Account | `user as <username> <command...>` | unchanged |
| Account | `user oosh.install <username> <?branch:$OOSH_MODE>` | unchanged |
| Inspect | `user get <property> <username>` | unchanged |
| Inspect | `user info` | unchanged |
| Inspect | `user id <options="-u -n">` | unchanged |
| Inspect | `user list` | unchanged |
| Inspect | `user list.all` | unchanged |
| Groups | `user group.add <groupName> <?toUsername>` | unchanged |
| Groups | `user group.check <groupName>` | unchanged |
| Groups | `user group.list` (all groups) | `user list.groups` |
| Groups | `user group.member.list <groupName>` (members of one group) | `user group.list` |
| Groups | `user group.member.pending <group> <?user>` | unchanged |
| SSH | `user ssh.init <?sshDir:~/.ssh>` | `user init` |
| SSH | `user ssh.identity.current` | `user get.current.identity` |
| SSH | `user ssh.identity.list <?sshDir:~/.ssh>` | `user list.other.identities` |
| SSH | `user ssh.identity.use <sshId> <?sshDir:~/.ssh>` | `user in` |
| SSH | `user ssh.backup <?label:manual> <?sshDir:~/.ssh>` | unchanged |
| SSH | `user ssh.backup.list` | unchanged |
| SSH | `user ssh.restore <?archive:latest> <?sshDir:~/.ssh>` | unchanged |
| SSH | `user authorized.keys.update <?sshDir:~/.ssh>` | unchanged (already `object.verb`; `ossh authorized.keys.update` delegates to it) |
| Legacy | `user ssh.backup.legacy.status <?home:$HOME>` | `user ssh.backup.status` |
| Legacy | `user ssh.backup.legacy.migrate <?home:$HOME>` | `user ssh.backup.migrate` |
| Hidden | `user start`, `user usage`, `private.*`, `*.completion.*` | — |

### Rules

- **OS implementation sits behind the public method, split only where it earns its keep.**

  | Public | Implementation | Dispatch |
  |---|---|---|
  | `user.delete` | `private.user.delete.linux` (unchanged name/body) | `os.check private.user.delete` |
  | `user.password.set` | none — merged into the public body | `case "$OSTYPE"` inside `user.password.set` |

  `password.set` is **merged**, not made private: both OS bodies are one line and stable, so a suffix
  (public or private) would add names without adding behaviour. The merge also deletes the four
  duplicate per-OS completion hooks.

  `delete` keeps the facade + private body: the body is ~70 lines of guards and a darwin sibling is
  plausible, so `os.check` makes adding one a new function rather than an edit to a long `case`.

  On an OS without a branch, both report that the method is not supported on that OS and return 1.
- **`user ssh.*` is not a resurrection of the removed aliases.** `ssh.init` is the WODA-aware
  initialiser; `ssh.identity.*` selects identities; `ssh.backup`/`ssh.restore` archive and restore.
  Nothing here delegates to `ossh` key commands.
- **Already-normalized names stay put.** `user authorized.keys.update` is already `object.verb` and
  `ossh.authorized.keys.update` delegates to it, so it keeps its name and is tagged `@group:ssh`.
- **`user id` and `user info` stay no-verb on purpose.** `id` is a thin mirror of POSIX `id` and its
  `-u -n` options; renaming it would obscure what it wraps. The help description says so.
- **Parameter names stay stable** where a class-level completion already exists (`sshDir`, `sshId`,
  `username`, `groupName`, `group`, `property`) so the existing `user.parameter.completion.*`
  functions keep working.
- **`start` and `usage` remain callable;** only their help and completion visibility changes.

## 2. Signature tags (additive)

Tags go in the description field of the signature line, after the prose:

```bash
user.create()      # <username> <?password> <?uid> <?gid> # creates a new user ... # @group:account
user.group.list()  # # lists every group # @group:groups
user.start()       # # # @hidden
```

- `@group:<name>` assigns a section. `@hidden` omits the method from help and completion.
- Tags are optional. A script with no tags renders exactly as today.
- The signature line is the only valid location: `this.help` drops lines that start with `#`, and
  `line.table '#'` splits on `#`, so a separate tag line or a new field separator would be lost or
  would add a column.
- Tags are stripped before rendering, so they never appear in the table.

## 3. `this.help` behaviour

The pipeline keeps its existing filters and formatting. New steps:

1. Remove lines containing `@hidden` (same mechanism as the existing `line.filter "\.completion"`).
2. Extract `@group:<name>` with a regex, drop the token from the description, and bucket the method.
3. If no line carries `@group`, print today's flat sorted table. **Untagged scripts are unchanged.**
4. If any line carries `@group`, render sections:
   - order from `<script>.help.group.order` (one group per line, lower-case) when that function
     exists; otherwise alphabetical;
   - groups named in tags but absent from the order list follow the listed groups alphabetically;
   - untagged methods render last under `other`;
   - each section prints a blank line, the group name, then the same `FORMAT_HELP` rows.
5. A filter argument (`user help ssh`) keeps today's **flat, filtered** output; grouping is only for
   the unfiltered full listing. Tags are still stripped so the filter does not match them.

`user.help.group.order` echoes, in order:

```text
account
inspect
groups
ssh
legacy
```

The order function is itself a method, so it carries `@hidden` and therefore does not appear in the
table it orders. `<script>` in the lookup is the basename of the script being rendered, not the
`$This` path.

`this.help.table` is left untouched: it has no callers and folding it into `this.help` would widen
the kernel diff. Removing or privatising it is a follow-up.

## 4. Completion

`private.c2.get.functions` gains `line.filter '@hidden'` **before** `c2.function.completion` strips
everything after `()`. Hidden methods therefore disappear from completion as well as help.

Every renamed method reuses an existing class-level completion because parameter names do not change:
`sshDir`, `sshId`, `username`, `groupName`, `group`, `property`. No new `.completion.` helper is
required, including for `user delete` (`user.parameter.completion.username` already covers it).

The `password.set` merge deletes `user.password.set.darwin.completion.username/password` and
`user.password.set.linux.completion.username/password`; they were exact duplicates of
`user.password.set.completion.username/password`.

## 5. `user.usage`

`user.usage` becomes a one-line synopsis plus `this.help`; the hardcoded block is deleted. That
removes the stale `ssh.*`/`rootkey.*` lines and the duplicate maintenance point. Entry points:

- `user` (no arguments) → `user.usage`, as today.
- `user help [word]` → `this.help` filtered by `word`, as today.

Rendered shape:

```text
user — user, group, and SSH identity management

Account
  create        | <username> <?password> <?uid> <?gid> | creates a new user ...
  ...

Inspect
  ...

Run `user help <word>` for the flat, filtered list.
```

Methods with a missing description still render "please add a description"; this change fills the
current gaps, and the new test fails if a visible method is missing one.

## 6. Migration

| File | Change |
|---|---|
| `user` | rename the definitions and their `.completion.` helpers; merge `password.set` into one public body; keep `delete` as facade + private OS body; delete the four per-OS password completion hooks; add tags; replace `user.usage`; add `user.help.group.order` |
| `user` (internal refs) | `user.parameter.completion.sshId` → `user ssh.identity.list`; `user.group.add.completion.groupName` → `user group.list`; usage/error strings naming `user.ssh.backup.status`/`.migrate` and `user.group.list` |
| `this` | `this.help`: drop `@hidden`, extract/strip `@group`, grouped rendering, order function, flat filter path |
| `ng/c2` | `private.c2.get.functions`: filter `@hidden` |
| `init/deinstall.oosh:3` | `user linux.delete developking` → `user delete developking` |
| `test/test.install` | the `grep -q '^user\.linux\.delete()'` assertion and its message → `user.delete` |
| `test/test.user` | renamed invocations, header comment, and the new coverage below |
| `test/test.this` | help grouping/hiding/backward-compatibility cases |
| `test/test.completion.audit` | no change expected; rerun because signatures change |
| `config`, macOS workflow | unchanged (`user list`, `user get basehome`, `user create`) |

## 7. Tests

New or updated assertions:

1. **Backward compatibility:** an untagged fixture script produces the same output as before.
2. **Grouped output:** a fixture with `@group` renders group headers in `<script>.help.group.order`
   order; untagged methods land under `other`; unknown groups follow alphabetically.
3. **Hidden:** a `@hidden` method appears in neither `this.help` nor c2 completion, but is still callable.
4. **Filtered output:** a filter argument keeps the flat table and still strips tags.
5. **`user` completeness:** every visible (non-`@hidden`) public method appears exactly once in
   `user usage`, and every one has a non-empty description.
6. **`user` surface:** `user delete`, `user group.list`, `user group.member.list`,
   `user ssh.identity.*`, `user ssh.backup.legacy.*` behave as their predecessors did.
7. **`password.set` merge:** the public method runs the darwin/linux branch for `$OSTYPE`, rejects a
   missing username, still treats an empty password as a no-op, and reports an unsupported OS.
8. **Regression:** `test/test.install` deinstall check passes against `user delete`.

## 8. Docs and templates

- `templates/code/newMethod` and `docs/command-creation.md` document `@group:<name>` and `@hidden`.
- `docs/user.md`, `docs/methods-index.md` and `docs/object-verb-index.md` are generated by
  oosh-architect; they are flagged for regeneration, not hand-edited here.
- `CLAUDE.md` needs no change: `oo user.init` is a different method from `user ssh.init`.

## 9. Decisions and risks

| Decision | Why |
|---|---|
| Tags on the signature line | Only location that survives `this.help`'s `^#` filter and `line.table '#'` |
| Grouping only for the unfiltered listing | Keeps `user help <word>` behaviour and code path unchanged |
| Extend `this.help`, not a `user` manifest | One renderer, no drift, every future method gets grouping for free |
| Merge `password.set`, split `delete` | Short stable bodies collapse to one `case`; the long guarded delete body stays behind `os.check` so an OS sibling is a new function, not a `case` edit |
| `ssh.identity.*` rather than `identity.*` | Keeps the object chain explicit; `identity` alone is ambiguous on a multi-user host |
| Keep `user id` / `user info` | They mirror system nouns; the verb audit flags them, help explains them |
| Leave `this.help.table` alone | No callers; out of scope for this change |

**Risks.** The kernel change is shared; it is guarded by byte-identical output for untagged scripts
and by `test/test.this`. A method added without a tag is visible under `other`, never silently
hidden. The `ssh.identity.*` names are longer; the gain is an unambiguous object chain.

## 10. Follow-ups (not in this change)

- Fold `this.help.table` into `this.help` or make it private.
- Decide whether WODA initialisation belongs in `ossh` instead of `user ssh.init`.
- Teach oosh-architect to read `@group`/`@hidden` so generated docs match the CLI.
