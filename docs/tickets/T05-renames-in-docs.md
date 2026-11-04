# T05 — Rename tables in docs re-introduce retired `ossh` names

<!-- ossh-rename-history: allowed — this ticket quotes retired names on purpose -->

- **Type:** test bug (fixed) · **Priority:** P2 · **Area:** `docs/`, `test/test.ossh`
- **State:** fixed 2026-11-02, commit `70f84374`; marker exemption added 2026-11-03
- **Found by:** `core` failing at `T-OSSH-RENAMES-OBJECT-VERB`

## Symptom

```
✗ FAIL: an old name is still in the tree — the boss found them by searching
  renames: left=[docs/research/review-2026-10-28-test-suite-audit.md:404 …]
```

`T-OSSH-RENAMES-OBJECT-VERB` greps **every tracked file** (code and docs) for the retired names
(`private.ossh.push.key`, `private.ossh.get.config`, `private.push.init.oosh`,
`update.authorized_keys`, `ossh push.key`). The audit and comparison pages quoted them verbatim in
their rename tables, so they failed the very guard they were documenting.

## Fix

1. `70f84374` reworded the first offending report (the names appear without their dotted prefix:
   "the old `get.config` accessor under `private.ossh`").
2. The three later audit pages quoted whole tables of old names. Rather than mangle them, the
   test now **skips a file whose first five lines carry the marker**:

   ```bash
   hits=$(ogit.repo.grep "$pattern" "$OOSH_DIR" | while IFS=: read -r file line rest; do
     head -5 "$OOSH_DIR/$file" 2>/dev/null | grep -q 'ossh-rename-history: allowed' && continue
     printf '%s:%s ' "$file" "$line"
   done)
   ```

   The marker is `<!-- ossh-rename-history: allowed — … -->` and only the comparison/history pages
   use it (`docs/compare-ossh-dev-vs-mcdonges.md`, `docs/compare-user-dev-vs-mcdonges.md`).

## Verification

- with a marker: `test.ossh` **154/154**;
- without one: appending `private.push.init.oosh` to an unmarked doc fails the test and names the
  file and line (`docs/dev-gaps-vs-mcdonges.md:172`).

## Notes

The guard's intent is "no code uses the old names"; a history page must be able to name them. The
marker keeps the exemption explicit and local, instead of exempting `docs/` wholesale.
