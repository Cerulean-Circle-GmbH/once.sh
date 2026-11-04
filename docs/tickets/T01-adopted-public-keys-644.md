# T01 — Adopted public keys are written 600 instead of 644

- **Type:** bug (fixed) · **Priority:** P1 · **Area:** `user`, `~/.ssh` layout
- **State:** fixed 2026-11-02, commit `171cbedb`; host repaired the same day
- **Files:** `user` (`private.user.authorized.keys.adopt`), `test/test.user`
- **Found by:** WODA audit, finding F1 (`docs/audit-woda.md`)

## Symptom

`test.suite run platform.ssh.layout.invariant 1` failed 2 of 15 with

```
violations: [mode600:/root/.ssh/public_keys/adopted.shaan_shantanu.public_key]
            [mode600:/root/.ssh/public_keys/ssh.test.69f16a4b4c98.public_key]
```

The layout invariant wants 700 dirs / 600 private keys / **644 public keys**; two public keys were
owner-only.

## Root cause

`private.user.authorized.keys.adopt` gives every key that exists only in `authorized_keys` a file
in `public_keys/`, and wrote it with `private.this.file.write`. That helper deliberately leaves a
**new** file at 600 (T-THIS-FILE-WRITE), and the adopt path never chmodded it afterwards. `dev`
had already fixed 644 for the remote-push path (`ossh:133`, `ossh:2502`); the adopt path was
missed. The second file came from a key/install copy that preserved a 600 source.

## Fix

```diff
   private.this.file.write "$sshDir/public_keys/$file.public_key" "$line" || return $(result)
+  # A public key is readable data, 644: private.this.file.write leaves a NEW
+  # file 600 (T-THIS-FILE-WRITE), and the layout invariant wants every
+  # public_keys/ file 644 (test.platform.ssh.layout.invariant, F1 2026-11-02).
+  if ! chmod 644 "$sshDir/public_keys/$file.public_key"; then
+    create.result 1 "cannot make $sshDir/public_keys/$file.public_key readable (644)"
+    return $(result)
+  fi
```

`test.user` (`T-USER-AUTHORIZED-KEYS-ADOPT`) now asserts `-rw-r--r--` on every
`adopted.*.public_key`.

## Verification

- red first: without the patch the test reports `adoptedMode=…:-rw-------`;
- with it: `test.user` **69/69**, `core` green;
- host side: `chmod 644 ~/.ssh/public_keys/*.public_key` → the layout invariant went 13/15 → 14/15
  (the remaining failure is T06).

## Follow-up

`mcdonges` has no `chmod 644` in `ossh` at all (0 sites vs 7 on `dev`), so any host installed from
the test line reproduces the mode drift by construction — covered by T11.
