# WODA audit — SSH/platform side

Date: 2026-11-02. Host audited: `ubuntu2404` (container, user `root`), tree
`/home/shared/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/Once.sh/dev` at `70f84374`.

"WODA" in this tree names two things: the three `WODA.*` SSH aliases every user gets, and the
Docker workspace scenario (`once docker.* woda`, `SCENARIO_MAP_VALUES` in `init/once`). This
audit covers the SSH/platform side — the aliases, the `~/.ssh` layout the repo's tests call
"canonical", and reachability. The Docker scenario was not audited.

Method: read `~/.ssh/config`, run the four WODA/ssh tests from `dev`'s suite, compare the live
layout against them, `ssh -G` for resolution, and one bounded, read-only login attempt per alias.
**No system change was made.**

## 1. Live configuration

| Alias | User | Host | Port | IdentityFile |
|---|---|---|---|---|
| `WODA.test` | root | 178.254.18.182 | 22 | `~/.ssh/id_ed25519` |
| `WODA.dev.root` | root | cerulean.it | 22 | `~/.ssh/id_ed25519` |
| `WODA.dev` | developking | cerulean.it | 22 | `~/.ssh/id_ed25519` |

Resolution (`ssh -G`) is correct for all three; `github.com` resolves to `git@github.com`
(system `ssh_config.d`), as the test expects.

`~/.ssh` permissions: `drwx------` root, `config` 600, `id_ed25519` 600, `id_ed25519.pub` 644,
`ids/` + `private_key/` 700. `authorized_keys` has 3 keys and all 3 have a file in
`public_keys/` — no orphan that a rebuild would drop.

## 2. Repo tests, run on this host

| Test | Result |
|---|---|
| `ssh.config.woda` (core) | **3/3 pass** |
| `platform.ssh.config.woda.portable` | **5/5 pass** |
| `ssh.config.invariant` | **6/6 pass** |
| `platform.ssh.layout.invariant` | **13/15 — 2 fail** |

The two failures are the findings F1 and F3 below.

## 3. Findings

### F1 — two public keys are 600, the layout says 644 (medium)

```
violations: [mode600:/root/.ssh/public_keys/adopted.shaan_shantanu.public_key]
            [mode600:/root/.ssh/public_keys/ssh.test.69f16a4b4c98.public_key]
```

Public keys are readable data; the repo's own invariant (and
`docs/osshLayout.md:29` `osshLayout.perms.tighten`: *700 dirs, 600 privkeys, 644 pubkeys*)
says 644. `ssh.root.ubuntu2404.public_key` is correctly 644, so this is a per-file drift, not a
blanket umask.

Likely origin: `private.this.file.write` deliberately leaves a **new** file at 600
(`this`, "a new file: 600, owner only"), and `private.user.authorized.keys.adopt`
(`user:445`) writes `public_keys/adopted.<comment>.public_key` through it without a following
`chmod 644`. `dev` fixed 644 for the remote-push path (`ossh:133`, `ossh:2502`), but the adopt
path has no such step. The second file (`ssh.test.<container>`) came from a key/install copy
that preserved a 600 source.

### F2 — no installer identity under `ids/` (medium)

```
✗ FAIL: ids/ has no installer identity (expected ssh.<installer> directory)
```

`ids/` contains only `ssh.developking`. The layout the test enforces
(`test/test.platform.ssh.layout.invariant:29-35`) wants `ids/ssh.<installer-id>/` as well, which
`osshLayout.role.installer` creates during an install/upgrade. This box was never given one —
consistent with an install from the deployed/test line, which has no `osshLayout` at all
(`osshLayout` exists only on `dev`).

Practical effect: the installer role of the identity model is unpopulated; `ossh config.create` /
`key.push` can still work from `ids/ssh.developking`, but anything that resolves "who installed
this host" finds nothing.

### F3 — WODA.test is reachable, this host's key is not authorized (high for ops)

```
WODA.test (178.254.18.182): root@…: Permission denied (publickey,password).
```

The alias is live and the host key is known, but the identity the config uses
(`~/.ssh/id_ed25519`, `SHA256:3XRHPz+wgdKg/K/lQ1DKFn4pyfZ/21kzvRDcLXXRizw`, `root@ubuntu2404`)
is not in that host's `authorized_keys` (or root login is disabled). Password auth is offered.

### F4 — `WODA.dev` / `WODA.dev.root` (cerulean.it) are unreachable on every tested port (medium)

`cerulean.it` resolves to **178.254.36.232** (PTR `v32109.1blu.de`; the same answer from the
local resolver and from `1.1.1.1`). DNS itself is healthy: `NS ns5/ns6.kasserver.com`,
`MX w0154f17.kasserver.com`, SOA serial `2606160033` (last change 2026-06-16), and only the web/ssh
host is the 1blu address.

Raw TCP probes, with the error text kept (this distinguishes *dropped* from *closed*):

| Probe | Result | Meaning |
|---|---|---|
| `178.254.36.232:22` | timeout after 6.2 s | SYN dropped, no reply |
| `178.254.36.232:80`, `443`, `2222`, `8022`, `9922` | timeout | dropped |
| `178.254.36.1:22` | timeout after 8 s | dropped |
| `v32109.1blu.de:80` | timeout | dropped |
| `178.254.18.182:22` (WODA.test) | connect in 165 ms, SSH answers | host up |
| `178.254.18.182:9922` | **Connection refused in 155 ms** | host up, port closed |
| `1.1.1.1:443`, `github.com:22` | connect in 26 / 105 ms | general egress fine |

So `cerulean.it` does not refuse — it **swallows** the SYN. A host that is up with a closed port
sends RST within milliseconds (the `:9922` control); a dropped packet produces exactly the 6–8 s
timeout seen on every `178.254.36.232` port. `curl -I https://cerulean.it` and
`openssl s_client -connect cerulean.it:443` time out for the same reason. Route:
`178.254.36.232 via 10.187.238.1 dev eth0`. ICMP is dropped by both hosts (normal), and there is
no `traceroute` on this box, so the hop where packets die cannot be named.

Correction to an earlier phrasing in this note: I wrote "the whole 178.254.36.0/24 looks dark".
That was **three addresses out of 254** (`.1`, `.232`, and the PTR name), not a scan, and `.1`
need not be a gateway at all. The defensible claim is: *every address tried in that /24 drops
TCP silently, while 1blu's 178.254.18.0/24 answers*.

What that rules in and out:

- **Ruled out:** the ssh config, the local key, sshd on the target and the DNS record being
  locally wrong — none of them can explain a silent drop on six ports while a neighbouring 1blu
  host answers.
- **Still possible:** the 1blu host or its /24 is down/decommissioned and the A record is stale;
  a filter on the path or at the far end dropping this container's egress IP; a provider-side
  outage. A `traceroute`/`mtr` from another network, or a check of the 1blu netblock, would settle
  which one.

Conclusion: **`WODA.dev` and `WODA.dev.root` cannot be used from here**; the failure is at the
network level (host/range down or filtered), not in `~/.ssh/config`. An external fetch of
`https://cerulean.it` from a different network also timed out in this session, which points away
from this container's egress alone.

`WODA.test` (PTR `linpio.de`) accepts the TCP connection on 22 and SSH answers
(*Permission denied*), while HTTP/HTTPS accept TCP and then return nothing within 10 s — a
half-open or heavily filtered service, not a normal web host.

Net effect: `WODA.dev` and `WODA.dev.root` cannot be used from here right now; `WODA.test` is
reachable but the key is not authorized (F3).

### F5 — no `known_hosts` entry for cerulean.it (low)

`ssh-keygen -F cerulean.it` finds nothing (only `178.254.18.182` is pinned, hashed, line 4).
Once F4 is resolved, a `StrictHostKeyChecking=yes` connection will refuse the host until its key
is added — expected, but worth knowing before scripting.

### F6 — one key serves all three aliases (info)

`WODA.dev` runs as `developking`, yet uses root's `id_ed25519`. `docs/ossh.md:538` ties the
`developking` account to the `ids/ssh.developking/id_rsa` identity. If `WODA.dev` is meant to
log in as `developking`, using the developking key would match the documented model; today it
works only if `developking` also authorizes root's key.

### F7 — the WODA checks exist only on `dev` (info)

`test.ssh.config.woda`, `test.platform.ssh.config.woda.portable`, `test.ssh.config.invariant`
and `test.platform.ssh.layout.invariant` are **absent on `mcdonges.latest`**
(`git cat-file -e origin/test/mcdonges.latest:<path>` → missing). A host provisioned from the
deployed/test line therefore has no WODA invariant at all, which is how F1/F2 could appear
without a red test.

## 4. Safe repairs

```bash
# F1 — make every public key 644 (idempotent, no content change)
chmod 644 ~/.ssh/public_keys/*.public_key

# or the repo's own tool, which also tightens the ids/ tree:
./osshLayout perms.tighten ~/.ssh      # dev-only script; 700 dirs, 600 priv, 644 pub

# F5 — pin the host key once cerulean.it answers
ssh-keyscan -t ed25519 cerulean.it >> ~/.ssh/known_hosts
```

F3 needs a key that is authorized on 178.254.18.182 (or root login enabled there); F2 needs
`osshLayout.role.installer` to run with the installer identity. Neither is fixable from this
tree alone.

## 5. Cross-branch note

The two mode violations are consistent with `mcdonges`' `ossh`, which has **no `chmod 644` at
all** (`git show origin/test/mcdonges.latest:ossh | grep -c 'chmod 644'` → 0; `dev` has 7 lines,
one of them a comment). So a host installed from the test line reproduces F1 by construction,
while `dev`'s tests would catch it — and `dev`'s adopt path in `user` still has the same gap for
adopted keys.

## 6. Not done

- No change to `~/.ssh`, no key generated or copied, no `known_hosts` written.
- No login to `WODA.test` beyond one BatchMode attempt; no password attempt. The further probes
  were read-only: DNS, TCP connect on six ports, one `curl -I` per host, one SSH banner read.
- The WODA Docker workspace scenario was audited separately in `docs/audit-woda-docker.md`.

## 7. Applied after this audit (2026-11-02)

- **F1, host:** `chmod 644 ~/.ssh/public_keys/*.public_key`. `platform.ssh.layout.invariant`
  went from 13/15 to **14/15**; only F2 remains.
- **F1, code:** `private.user.authorized.keys.adopt` (`user:445`) now `chmod 644`s the file it
  just wrote, and `test/test.user` (`T-USER-AUTHORIZED-KEYS-ADOPT`) asserts the mode. Proven
  red-first: without the patch the test reports `adoptedMode=…:-rw-------`; with it,
  `test.user` is 69/69.
- **F2:** not fixed — it needs `osshLayout.role.installer` with an installer identity.
- **F6, config:** `WODA.test` and `WODA.dev` log in as `developking` with
  `IdentityFile ~/.ssh/ids/ssh.developking/id_rsa`; `WODA.dev.root` keeps `User root` and the
  user's own `~/.ssh/id_ed25519`. All three carry `IdentitiesOnly yes`, applied with
  `./ossh config.set` (backups `~/.ssh/config.bak-*`, mode 600). The `mcstudio` Host and the
  `shaan` Host alias in root's config are untouched. Auth is still denied everywhere: the key is
  not authorized on `178.254.18.182`, and `cerulean.it` still times out (F4).
- **F6, test:** `test/test.ssh.config.woda` checks each expected line **inside its Host block**
  (awk block extraction): `User developking` + `IdentityFile ~/.ssh/ids/ssh.developking/id_rsa`
  for `WODA.test` and `WODA.dev`, `User root` + `IdentityFile ~/.ssh/id_ed25519` for
  `WODA.dev.root`. The old tree-wide `grep -Fq` let one block satisfy another's requirement — it
  is what let the WODA.test change pass silently on 2026-11-02. Verified red → green and with a
  mutated fixture (`WODA.test` without its `User` line is reported even though the other blocks
  have it).
- **F6, other users:** the same WODA settings (then `User root` + `~/.ssh/id_ed25519` for
  `WODA.dev.root`) were applied to `developking` and `shaan`
  (`CURRENT_SSH_DIR=/home/<u>/.ssh ./ossh config.set …`, then `chown <u>:<u>` + 600 because
  `private.this.file.write` replaces the file). Their extra Hosts (`ubuntu_24_04`,
  `alpine_3_19`) are untouched. `ssh -G` resolves as expected for both, and
  `test.suite run ssh.config.woda` is 3/3 as root, developking and shaan. Backups: one
  `~/.ssh/config.bak-*` (and `/home/<u>/.ssh/config.bak-*`) per change.
- **F6, platform test:** `test/platform.ssh.config.woda.portable` required exactly
  `IdentityFile ~/.ssh/id_ed25519` for every WODA host, which contradicted its own contract
  ("the portable `~/.ssh` form"). It now accepts any `~/.ssh/...` path and still rejects
  `/home/<user>/...`; 5/5 as root, developking and shaan.
- **F6, writers (fixed):** the per-alias canonical is now emitted and enforced everywhere —
  `user:379-410` writes `User developking` + `~/.ssh/ids/ssh.developking/id_rsa` for
  `WODA.test`/`WODA.dev` and `User root` + `~/.ssh/id_ed25519` for `WODA.dev.root` (plus
  `IdentitiesOnly yes`), and `private.ossh.folder.fix.config.normalize` (`ossh:1804-1812`)
  rewrites a WODA IdentityFile only when it differs from that per-alias value. Before this,
  `ossh folder.fix` reset **every** WODA IdentityFile to `~/.ssh/id_ed25519` — that is what
  silently reverted the developking key (config mtime 06:38, same run that rebuilt the owner key
  as `ssh.shantanusk.hotmail.com.public_key`). `test/test.ossh`
  (`T-FOLDER-FIX-CONFIG-NORMALIZE-WODA`) now pins the new mapping.
- **F6, generator:** `user init` on a fixture emits the three new blocks; `ossh folder.fix`
  leaves a correct config byte-identical and heals a reverted one.
- **F6, verification:** `test.ossh` 154/154, `test.ssh.config.woda` 3/3,
  `platform.ssh.config.woda.portable` 5/5, `test.user` 69/69.
- **F3, attempted:** `ssh-copy-id -i ~/.ssh/ids/ssh.developking/id_rsa.pub root@178.254.18.182`
  cannot complete — the host rejects both keys we hold (`root@ubuntu2404` and the developking
  RSA) and offers `publickey,password`; this environment has no ssh-agent, no stored credential
  and no console. Installing the key needs the root password or another authorized key.
- **F3/F4:** otherwise unchanged (remote side).
