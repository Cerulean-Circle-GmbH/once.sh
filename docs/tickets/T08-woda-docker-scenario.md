# T08 — WODA Docker scenario: five defects

- **Type:** bug · **Priority:** P3 · **Area:** `init/once`, `DockerWorkspaces/WODA`
- **State:** open
- **Found by:** `docs/audit-woda-docker.md`

## Findings

1. **Two path conventions, both missing.**
   - scenario map `woda` (`init/once:1300`) → `EAM/2_systems/WODA.v4.3.0` (absent);
   - `deprecated.docker.config woda` (`init/once:3624`) → `EAM/1_infrastructure/Docker/WODA/4.3.0`
     (absent);
   - on disk only `EAM/1_infrastructure/DockerWorkspaces/WODA/{1.0.0,2.0.0}` and
     `DockerWorkspaces/old/WODA.*` exist.
2. **Wrong version index.** `SCENARIO_MAP_VALUES[10]` interpolates
   `${SCENARIO_MAP_VERSION[4]}` (`init/once:1299`).
3. **Stray backup entry.** `SCENARIO_MAP_BACKUP[2]="/var/dev"` sits inside the woda block
   (`init/once:1301`); index 2 is `pg`, and `woda` (10) has no backup entry.
4. **Hardcoded repo root.** `DockerWorkspaces/WODA/1.0.0/{build,run}DockerFileLocal` `cd
   /var/dev/EAMD.ucp/...` (9 and 10 times); the repo lives at `/home/shared/EAMD.ucp`.
5. **Runtime prerequisites missing.**
   - no `docker-compose` and no `docker compose` plugin → every `docker-compose` call fails;
   - image `woda-nodejs:16.x` not built (only `old_woda_localhost:latest`);
   - network `once-woda-network` absent (compose declares it `external`);
   - the deprecated woda branch `cp`s `Components/tla/.../once.sh`, which does not exist.

## Acceptance

- one path convention for WODA (map or workspace), used by both the scenario map and
  `docker.config`;
- `[10]` uses `VERSION[10]`; the backup entry is on `[10]` or removed;
- the 1.0.0 scripts derive the repo root from the environment, not `/var/dev`;
- `once docker.scenario.start woda` builds and starts on a host with compose, or the deprecated
  block is removed and de-advertised in `once.docker.usage`.

## Notes

`once` itself is not installed on the audited host (`init/once` only), so none of this is
runnable there today — the ticket is about consistency and a working path, not a live outage.
