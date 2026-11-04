# T03 — WODA identity split reverted by `ossh folder.fix`

- **Type:** bug (fixed) · **Priority:** P1 · **Area:** `user`, `ossh`, WODA aliases
- **State:** fixed 2026-11-02, commit `525ca5a8`
- **Files:** `user:379-410` (`user.init`), `ossh:1787+`
  (`private.ossh.folder.fix.config.normalize`), both WODA tests
- **Found by:** the WODA audit follow-up — "we added the key, it still asks for a password"

## Symptom

After setting `WODA.test`/`WODA.dev` to `IdentityFile ~/.ssh/ids/ssh.developking/id_rsa` and
`WODA.dev.root` to `~/.ssh/id_ed25519`, ssh fell back to the password prompt and the config was
back on `~/.ssh/id_ed25519` for **all three** aliases. `~/.ssh/config` mtime matched the minute
the owner key was rebuilt (`ssh.shantanusk.hotmail.com.public_key`), i.e. a `folder.fix`-style run.

## Root cause

Two writers disagreed with the intended policy:

1. `private.ossh.folder.fix.config.normalize` rewrote **every** WODA `IdentityFile` that was not
   `~/.ssh/id_ed25519` back to it:

   ```awk
   if (in_woda && $1 == "IdentityFile" && $2 != "~/.ssh/id_ed25519") {
     print " IdentityFile ~/.ssh/id_ed25519"
   }
   ```

   So any `ossh folder.fix` (or repair that calls it) silently undid the change.

2. `user.init`'s generator wrote `User root` + `~/.ssh/id_ed25519` for all three blocks, so new
   users and fresh installs got the old form.

## Fix

One canonical per alias, in both writers:

| Alias | User | IdentityFile |
|---|---|---|
| `WODA.test` | developking | `~/.ssh/ids/ssh.developking/id_rsa` |
| `WODA.dev.root` | root | `~/.ssh/id_ed25519` |
| `WODA.dev` | developking | `~/.ssh/ids/ssh.developking/id_rsa` |

plus `IdentitiesOnly yes` on all three.

```awk
/^Host WODA\.(test|dev\.root|dev)$/ { in_woda = 1; woda_host = $2 }
...
want = (woda_host == "WODA.dev.root") ? "~/.ssh/id_ed25519" : "~/.ssh/ids/ssh.developking/id_rsa"
```

`user.init` emits the same blocks; `test.ssh.config.woda` asserts them per block (T02);
`test.ossh`'s `T-FOLDER-FIX-CONFIG-NORMALIZE-WODA` pins the mapping.

## Verification

- `ossh folder.fix` on a copy of a correct config leaves it **byte-identical**;
- on a copy with `WODA.test` reverted to `id_ed25519`, it heals to the developking key and keeps
  `WODA.dev.root` on `id_ed25519`;
- `test.ossh` **154/154**, `test.user` **69/69**, `ssh.config.woda` **3/3**,
  `platform.ssh.config.woda.portable` **5/5**;
- applied to `root`, `developking` and `shaan` (`chown <user>`, 600).

## Deployment

`docs/audit-woda.md` §7 carries the prod runbook: deploy this commit, then
per user `ossh config.set` (or a fresh `user init`), then `ossh folder.fix`.

## Caveat

`ossh folder.fix` and `osshLayout` are `dev`-only; a host on the deployed line has no
`ids/ssh.developking` unless it was provisioned another way (see T13).
