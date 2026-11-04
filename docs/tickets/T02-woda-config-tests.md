# T02 — WODA config tests: block-scoped and portable; `WODA.dev.root` stays root

- **Type:** test bug (fixed) · **Priority:** P1 · **Area:** `test/test.ssh.config.woda`,
  `test/test.platform.ssh.config.woda.portable`
- **State:** fixed 2026-11-02, commits `47058da8` and `f434760e`
- **Found by:** WODA audit, F6 (`docs/audit-woda.md`)

## Symptom

Two holes in the WODA assertions:

1. **One block satisfied another's requirement.** The test required `User root` for `WODA.test`
   but read it with `grep -Fq "User root" "$cfg"` over the whole file. After `WODA.test` moved to
   `User developking`, the test still passed on the `User root` line of `WODA.dev.root`.
2. **The portable check pinned one exact key.** `platform.ssh.config.woda.portable` required
   `IdentityFile ~/.ssh/id_ed25519` for every WODA host, although its own comment says the
   contract is "the portable `~/.ssh` form". The developking identity
   (`~/.ssh/ids/ssh.developking/id_rsa`) therefore failed it, 2/5.

## Fix

`test.ssh.config.woda` extracts the named Host block and greps inside it:

```bash
woda.block() {   # <host> → the lines of that Host block
  awk -v host="$1" '
    /^[[:space:]]*Host[[:space:]]/ { inside=0; for (i=2;i<=NF;i++) if ($i==host) inside=1
                                     if (inside) { print; next } }
    inside && /^[[:space:]]*Match[[:space:]]/ { inside=0 }
    inside { print }' "$cfg"
}
```

and expects `User developking` + `IdentityFile ~/.ssh/ids/ssh.developking/id_rsa` for
`WODA.test`/`WODA.dev`, and `User root` + `IdentityFile ~/.ssh/id_ed25519` for `WODA.dev.root`.

`platform.ssh.config.woda.portable` now accepts any `~/.ssh/...` path and still rejects
`/home/<user>/...`:

```diff
-  if echo "$block" | grep -Fq "IdentityFile ~/.ssh/id_ed25519"; then
+  case "$actual" in
+    "~/.ssh/"*) expect.pass "$host IdentityFile is portable ($actual)" ;;
+    *) expect.fail "$host IdentityFile not portable — got: '${actual:-<missing>}'" ;;
+  esac
```

## Verification

- red first: the old test failed with `missing: [WODA.test] User root` after the config change;
- green: `ssh.config.woda` **3/3** and `platform.ssh.config.woda.portable` **5/5** as `root`,
  `developking` and `shaan`;
- a mutated fixture with only `WODA.test`'s `User` line removed is reported by the block check
  even though the other blocks still carry it.

## Follow-up

The generator that writes the blocks must produce the same split — see T03. Without it, every new
user gets the old form and this test fails on a fresh host.
