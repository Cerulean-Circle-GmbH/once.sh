# T07 — WODA.test key rejected; cerulean.it unreachable (F3/F4/F5)

- **Type:** ops · **Priority:** P2 · **Area:** ssh access to the WODA hosts
- **State:** open
- **Found by:** WODA audit F3/F4/F5 (`docs/audit-woda.md`)

## Symptom

```
WODA.test  (178.254.18.182)  → root/developking: Permission denied (publickey,password)
WODA.dev   (cerulean.it)     → ssh: connect to host cerulean.it port 22: Connection timed out
WODA.dev.root                → same timeout
```

With the developking key forced (`-i ~/.ssh/ids/ssh.developking/id_rsa`) the server still answers
`Permission denied`: the key is simply not authorized for the account. `cerulean.it` resolves to
`178.254.36.232` (PTR `v32109.1blu.de`) and every tested port (22/80/443/2222/8022/9922) drops the
SYN; the neighbouring `178.254.18.182` answers on 22/80/443, so this container's egress is not
blanket-blocked. `known_hosts` has no `cerulean.it` entry.

## What is needed

1. **WODA.test** — put the developking public key where the target account reads it:
   `authorized_keys` **and** `~/.ssh/public_keys/` (an oosh rebuild regenerates
   `authorized_keys` from `public_keys/`, so `authorized_keys` alone is not durable), then
   `user authorized.keys.update`. Or, from a working login: `ossh key.push WODA.test`.
2. **cerulean.it** — decide host-down vs path-filter/policy. `traceroute`/`mtr` from another
   network, or the provider's status, would settle it. Until then `WODA.dev`/`WODA.dev.root`
   cannot be used from here.
3. **known_hosts** — pin the host key once the host answers:
   `ssh-keyscan -t ed25519 cerulean.it >> ~/.ssh/known_hosts`.

## Acceptance

- `ssh -o BatchMode=yes WODA.test true` returns 0 for the intended account;
- a login as `WODA.dev` succeeds, or the reachability question is closed with an answer;
- `ssh-keygen -F cerulean.it` finds an entry if the host is reachable.

## Caution

Four failed auth attempts were already made on 2026-11-02/03. Check whether fail2ban
(`ossh.harden` installs it) has a `maxretry` of 5 before retrying blindly; a ban would look like
the same timeout.

## Notes

The client side is already correct: `ssh -G` resolves `user developking`, `identitiesonly yes`,
`identityfile ~/.ssh/ids/ssh.developking/id_rsa` for `WODA.test`/`WODA.dev` (T03).
