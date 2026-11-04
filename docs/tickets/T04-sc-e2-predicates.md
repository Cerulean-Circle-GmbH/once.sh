# T04 — 47 calls to five missing `this.is*` predicates

- **Type:** bug (fixed `6e54083a`) · **Priority:** P1 · **Area:** `this`, `otmux`,
  `claudeCode`, `hiveMind`, tests
- **State:** fixed 2026-11-03, committed `6e54083a`; full `extended` run still worth doing
- **Found by:** the private-method sweep (`docs/private-methods-burndown.md` §3, §6)

## Symptom

`claudeCode join.byID`, `join.byPane`, `fork`, `fork.byPane`, `fork.to`, `stop`, and the
`hiveMind` resolve/send/rewind paths rejected **every** input with "invalid …". The validators
reported, red first:

```
✗ FAIL: RED: join.byID REJECTED valid 'canonical uuid' (reached=0 invalid=1 command-not-found=1):
        /root/oosh/claudeCode: line 362: this.isUuid: command not found
```

## Root cause

`bf1ebe5a` ("updated agent tools from mcdonges", 2026-10-22) imported claudeCode/hiveMind/otmux
and **added the calls** to five SC-E.2 predicates, but not the definitions:

| Predicate | Calls on dev | Implementation before the fix |
|---|---:|---|
| `this.isPaneTarget` | 10 (claudeCode 4, hiveMind 6) | only a dead `otmux` `private.` copy |
| `this.isSessionName` | 13 (hiveMind) | only a dead `otmux` `private.` copy |
| `this.isPipeSafe` | 13 (hiveMind) | none |
| `this.isRoleName` | 8 (claudeCode 1, hiveMind 7) | none |
| `this.isUuid` | 3 (claudeCode 2, hiveMind 1) | none |

The definitions live in `1b759c5a` ("this: SC-E.2 ingress predicates"), which is **not an ancestor
of `dev`**; the test line had them commented out in `b745e766` and used per-script `private.*`
copies instead. Each guard is `if ! this.isX …`, so `command not found` (rc 127) made it true and
rejected everything. `core` stayed green because the pinning tests were mcdonges-only.

## Fix (applied)

- five predicates restored in `this`, right after `this.isEmpty` — one home;
- `otmux.fit` repointed from `private.isSessionName` to `this.isSessionName`;
- `private.isPaneTarget` and `private.isSessionName` deleted from `otmux`;
- `test/test.claudeCode-validators` and `test/test.hiveMind-validators` ported from mcdonges.

## Verification

| Suite | Result |
|---|---|
| `claudeCode-validators` | 33/33 |
| `hiveMind-validators` | 16/16 |
| `this` | 71/71 |
| `otmux` | 45/45 |
| `ossh` | 154/154 |
| `core` | 1341/1343 — intentional meta-test + the flaky T14 |

Red/green proof: comment any `this.is*` definition out and the corresponding validator fails with
`command not found` again.

## Notes

- `private.isSessionName` was **not** dead (one caller in `otmux.fit`); it was consolidated, not
  blindly deleted. The dead one was `private.isPaneTarget`.
- The validators carry no `TEST_CATEGORY`, so they run in `extended` (follow-up: decide core vs extended).
- The removal exposed that `oo method.delete` cannot address legacy `private.<verb>` names — T09.
