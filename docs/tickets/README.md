# Tickets — findings and fixes, 2026-11-02/03

One file per finding or fix from the branch comparison, the `ossh`/`user` audits, the WODA audit
and the private-method sweep. Each ticket is self-contained (symptom → root cause → fix →
verification) so it can be pasted into an issue tracker as is.

| # | Title | Type | Prio | State |
|---|---|---|---|---|
| [T01](T01-adopted-public-keys-644.md) | Adopted public keys are written 600 instead of 644 | bug | P1 | **fixed** `171cbedb` |
| [T02](T02-woda-config-tests.md) | WODA config tests: block-scoped and portable, `.root` stays root | test bug | P1 | **fixed** `47058da8`, `f434760e` |
| [T03](T03-woda-identity-split.md) | WODA identity split reverted by `ossh folder.fix` | bug | P1 | **fixed** `525ca5a8` |
| [T04](T04-sc-e2-predicates.md) | 47 calls to five missing `this.is*` predicates | bug | P1 | **fixed** `6e54083a` |
| [T05](T05-renames-in-docs.md) | Rename tables in docs re-introduce retired names | test bug | P2 | **fixed** `70f84374` + marker |
| [T06](T06-woda-installer-identity.md) | No `ids/ssh.<installer>` on installed hosts (WODA F2) | bug/design | P2 | open |
| [T07](T07-woda-test-auth-reachability.md) | WODA.test key rejected; cerulean.it unreachable (F3/F4/F5) | ops | P2 | open |
| [T08](T08-woda-docker-scenario.md) | WODA Docker scenario: 5 defects | bug | P3 | open |
| [T09](T09-method-delete-legacy-private.md) | `oo method.delete` / `replace block` cannot remove legacy `private.<verb>` | tooling | P2 | open |
| [T10](T10-private-methods-burndown.md) | 880 private methods, 21 dead, 295 cross-script | finding | P2 | open |
| [T11](T11-ossh-branch-divergence.md) | `ossh`: two incompatible naming/feature lines | finding | P1 | open |
| [T12](T12-user-branch-divergence.md) | `user`: authorized-keys model and key API diverged | finding | P1 | open |
| [T13](T13-dev-gaps.md) | Tools and gates `dev` never had (opy/osemvec/tronMonitor/claudeFlow, no-python, myId) | finding | P2 | open |
| [T14](T14-flaky-odocker-engine-wait.md) | `T-ODOCKER-ENGINE-START-WAIT` is flaky under `core` | test bug | P3 | observed |
| [T15](T15-collapse-private-twins.md) | Collapse the public/private method twins (7 of 10 resolved, 2 collapses + 1 keep left) | refactor | P3 | **in progress** `abe94542`, `ca008c60`, `da01a047`, `d76c8c69` |

## Not tickets

Fixed and verified before this list, or pure documentation:
`docs/*` audit pages, the host-side `chmod 644 ~/.ssh/public_keys/*` (recorded in
`docs/audit-woda.md` §7), and the per-user `ossh config.set` migration (recorded in the same
section). The branch comparison pages are evidence, not tickets.

## Conventions

- **P1** = correctness/release blocker, **P2** = planned, **P3** = cleanup.
- Every verification step is a command that exists in the tree; none needs an external service.
- Base commit for all hashes: `525ca5a8` unless stated.
