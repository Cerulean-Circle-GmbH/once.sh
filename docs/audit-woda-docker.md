# WODA Docker scenario audit

Date: 2026-11-02, host `ubuntu2404` (container), tree `.../Once.sh/dev` at `70f84374`.
Companion to `docs/audit-woda.md` (SSH/platform side).

Scope: everything the tree calls "WODA" on the Docker side — the `woda`/`woda2local` entries of
the scenario map in `init/once`, the deprecated `once docker.config woda` / `docker.build woda`
path it advertises, and the `once.docker.scenario.*` API that consumes the map. Read-only audit;
no container, image, network or file was changed.

## 1. Two different WODA paths, both missing

| Consumer | Path the code uses | On this disk |
|---|---|---|
| scenario map `woda` (`init/once:1300`) | `$ONCE_SCENARIO/EAM/2_systems/WODA.v4.3.0` | **missing** |
| scenario map `woda2local` (`init/once:1293`) | `$ONCE_SCENARIO/EAM/2_systems/WODA2local.v4.3.0` | **missing** |
| `deprecated.docker.config woda` (`init/once:3624`) | `$ONCE_SCENARIO/EAM/1_infrastructure/Docker/WODA/4.3.0` | **missing** |
| workspace actually on disk | `.../EAM/1_infrastructure/DockerWorkspaces/WODA/1.0.0` and `/2.0.0` | present |
| legacy workspaces | `.../DockerWorkspaces/old/WODA.localhost`, `WODA.2local`, `WODA.pip.localhost` | present |

`EAM/2_systems/` does not exist at all under `Components/com/ceruleanCircle/`, and neither does
`EAM/1_infrastructure/Docker/WODA/`. So `once docker.scenario.start woda` finds the name, then
`once.scenario.map` warns *"Sceanrio does not exist"* (sic) and leaves the shell in the previous
directory; `once docker.config woda` would create the directory tree first (`once.path.create`)
but then `cp` the missing `Components/tla/.../once.sh`.

## 2. The runtime is not installed

| Requirement | State |
|---|---|
| `once` in `PATH` | **absent** (the tree ships only `init/once`) |
| `docker` | 29.1.3, daemon reachable |
| `docker-compose` (v1) | **absent** |
| `docker compose` (v2 plugin) | **absent** (`docker: unknown command: docker compose`) |

Every WODA path in the tree shells out to `docker-compose` (`init/once:4315`, `:4320`, and the
`DockerWorkspaces/WODA/1.0.0/*` scripts). On this host all of them fail before touching Docker.

## 3. Images and networks the WODA blocks assume

| Expected | Present |
|---|---|
| image `woda-nodejs:16.x` (scenario map `SCENARIO_MAP_DI_NAME`, `docker.config`) | **no** |
| network `once-woda-network` (`external: name: once-woda-network`) | **no** (only `bridge`, `host`, `none`) |
| container `woda` | **no** (no container running) |
| a WODA image built earlier | `old_woda_localhost:latest`, created 2026-10-27 |

The only WODA artefact that exists is an image under the *old* name, so the deprecated compose
file would have to be re-pointed or the image rebuilt from
`DockerWorkspaces/WODA/2.0.0/Ubuntu/20.04/Nodejs/16/Dockerfile`.

## 4. Code-level defects found while tracing

1. **Scenario version index is wrong**: `SCENARIO_MAP_VALUES[10]` interpolates
   `${SCENARIO_MAP_VERSION[4]}` (the `woda2local` slot) instead of `[10]` (`init/once:1299`).
   Both happen to be `4.3.0` today, so the path is right by luck; changing one version silently
   breaks the other.
2. **Stray backup entry**: `SCENARIO_MAP_BACKUP[2]="/var/dev"` sits inside the `woda` block
   (`init/once:1301`). Index 2 is `pg`, whose backup is set separately as
   `SCENARIO_MAP_BACKUP[5]="/var/lib/postgresql/data"`; the `woda` slot (10) has no backup entry
   at all. A `docker.scenario.backup.volumes woda` reads an empty `SELECTED_SCENARIO_BACKUP`.
3. **Hardcoded repo root**: `DockerWorkspaces/WODA/1.0.0/buildDockerFileLocal` and
   `runDockerFileLocal` `cd /var/dev/EAMD.ucp/...` (9 and 10 times respectively). The repo lives
   at `/home/shared/EAMD.ucp` here, so both scripts `cd` into a non-existent directory.
4. **Deprecated block is still advertised**: `once.docker.usage` prints
   *"3. For WODA 'once docker.config woda'"* (`init/once:3947`), but the implementation is
   `deprecated.docker.config` (`:3508`) and its woda branch (`:3623`) is the 4.3.0 path in
   section 1.
5. **Missing image source**: that branch `cp`s
   `$ONCE_REPO_PREFIX/EAMD.ucp/Components/tla/EAM/layer1/Thinglish/Once/latestServer/src/sh/once.sh`
   into the build context. `Components/tla` does not exist here, so the `ADD ./once.sh` in the
   generated Dockerfile cannot be satisfied.

## 5. What is usable

- `DockerWorkspaces/WODA/1.0.0` — Alpine 3.13.2, Nodejs 14/15/16, Openjdk 8/Structr, Nginx/certbot;
  `buildDockerFile{Local,Server}` + `runDockerFile{Local,Server}` (hardcoded `/var/dev`).
- `DockerWorkspaces/WODA/2.0.0/Ubuntu/20.04/Nodejs/{14,16}` — Dockerfiles only, no run scripts.
- `old/WODA.localhost` — a self-contained Dockerfile + `install.eamd.sh`/`runDockerfile`.

## 6. Recommendations

1. Decide the single source of truth: the scenario map (`2_systems/WODA.v4.3.0`) or the
   workspace (`1_infrastructure/Docker/WODA/4.3.0`); the deprecated `docker.config woda` branch
   and the map currently disagree.
2. Fix `SCENARIO_MAP_VALUES[10]` to `${SCENARIO_MAP_VERSION[10]}` and move
   `SCENARIO_MAP_BACKUP[2]` to `[10]` (or delete it if WODA needs no backup).
3. Ship or install `docker-compose` (v2 as `docker compose`), or rewrite the six call sites to
   `docker compose`.
4. Build `woda-nodejs:16.x` from `2.0.0/Ubuntu/20.04/Nodejs/16/Dockerfile` and create
   `once-woda-network`, or retire the compose path and drive the image directly.
5. Replace `/var/dev/EAMD.ucp` with `$ONCE_REPO_PREFIX`/`$EAMD_DIR` in the 1.0.0 scripts.

## 7. Not done

No scenario directory created, no image built, no network created, no file outside this repo
changed. The Docker scenario was not exercised (it cannot be on this host — section 2).
