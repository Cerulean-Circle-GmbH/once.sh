# T06 — No `ids/ssh.<installer>` on installed hosts (WODA F2)

- **Type:** bug / design decision · **Priority:** P2 · **Area:** `osshLayout`, `~/.ssh/ids`,
  `test/platform.ssh.layout.invariant`
- **State:** open (the one remaining failure of that invariant: 14/15)
- **Found by:** WODA audit F2 (`docs/audit-woda.md`)

## Symptom

```
✗ FAIL: ids/ has no installer identity (expected ssh.<installer> directory)
```

`~/.ssh/ids/` contains only `ssh.developking`; the canonical layout also expects
`ids/ssh.<installer-id>/`.

## Root cause

`osshLayout.role.installer` records the identity of a **controlling** installer: it reads
`/tmp/oosh.installer.email` + `/tmp/oosh.installer.id_ed25519` (staged by `ossh install <host>`),
or explicit args, or discovers an existing non-role dir. With none of those it logs

> no installer identity staged (self-service install) — skipping installer role

and returns 0 — by design since `4d41ab7e` (2026-09-08). The test predates that
(`fa3e7565`, 2026-05-08) and assumes every host was installed by someone else. A self-service
install therefore fails an invariant that the product calls normal.

## Options

1. **Treat self-service as canonical** — gate the check on "an installer was staged"
   (`/tmp/oosh.installer.*` present, or an explicit `OOSH_INSTALLER_EMAIL`), and pass with a
   message otherwise. Matches `osshLayout.role.installer`.
2. **Require an installer identity on every host** — run
   `osshLayout role.installer <email> <keydir>` during install even for self-service, recording the
   human who ran it.

## Acceptance

- the invariant is green for both install shapes (or explicitly marks the self-service one);
- `docs/install-bootstrap.md` states which shape records what;
- if option 2: `ossh folder.fix` can create the dir from an email (`osshLayout.id.from.email`,
   lowercased, `@`→`.`), and the test asserts the contents (600 key, 644 pub).

## Notes

`osshLayout` is `dev`-only; hosts installed from the deployed line cannot create this dir at all —
which is why the one host audited looks self-service. That is T13's decision.
