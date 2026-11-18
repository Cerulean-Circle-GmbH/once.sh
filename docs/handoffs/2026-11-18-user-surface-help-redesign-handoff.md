# Hand-off: regenerate the generated docs after the `user` surface redesign

**Owner:** oosh-architect (next run)
**Origin:** implementation on `dev`, 2026-11-18, commits `f01bab33..aeece0c9`
**Status:** Open — generated docs are stale
**Reference:** `docs/superpowers/specs/2026-11-17-user-surface-help-redesign-design.md` ·
`docs/superpowers/plans/2026-11-17-user-surface-help-redesign.md`

## Summary

The public `user` surface was normalized and `this.help` now renders sections from signature tags.
The generated method references still describe the pre-change surface (their header is dated
2026-10-20). This hand-off lists the delta so the next oosh-architect run does not have to
rediscover it.

`oosh-architect` is not on PATH and has no implementation in this repository, so the generated files
were deliberately **not** hand-edited.

## Rename map

| Old | New |
|---|---|
| `user linux.delete` | `user delete` |
| `user password.set.darwin` / `.linux` | merged into `user password.set` (no separate OS methods) |
| `user list.groups` | `user group.list` |
| `user group.list` | `user group.member.list` |
| `user init` | `user ssh.init` |
| `user in` | `user ssh.identity.use` |
| `user get.current.identity` | `user ssh.identity.current` |
| `user list.other.identities` | `user ssh.identity.list` |
| `user ssh.backup.status` | `user ssh.backup.legacy.status` |
| `user ssh.backup.migrate` | `user ssh.backup.legacy.migrate` |
| `user start`, `user usage` | unchanged, now `@hidden` |

`user.authorized.keys.update` keeps its name (`ossh.authorized.keys.update` delegates to it).

## New help metadata

- `# @group:<name>` and `# @hidden` live in the description field of the signature line.
- `this.help` renders sections only when a script uses `@group`; untagged scripts keep the flat,
  sorted table.
- Section order for `user`: `account`, `inspect`, `groups`, `ssh`, `legacy`, defined by
  `user.help.group.order`.
- `c2 function.completion` omits `@hidden` methods.
- The convention is documented in `docs/command-creation.md` and `templates/code/newMethod`.

## Files to regenerate

- `docs/user.md`
- `docs/methods-index.md`
- `docs/object-verb-index.md`

The `user` matrix will change shape in two ways the generator must expect: renamed methods, and the
retired `user.password.set.*` methods. `user start`/`user usage` remain in the source but should stay
out of user-facing lists.

## Follow-ups (not part of this change)

- Fold `this.help.table` into `this.help`, or make it private. It has no callers in this repository.
- Candidate new methods, never approved in this cycle: `user exists`, `user group.member.is`,
  `user sudo.add`, `user get uid|gid|groups`, `user group.member.remove`,
  `user ssh.identity.create`, `user ssh.identity.delete`.

## Verification at hand-off

| Suite | Result |
|---|---|
| `test.this` | 80/80 |
| `test.c2` | 32/32 |
| `test.user` | 88/88 |
| `test.install` | 51/51 |
| `test.completion.audit` | 7/7 |

`dev` is 15 commits ahead of `origin/dev`; nothing was pushed.
