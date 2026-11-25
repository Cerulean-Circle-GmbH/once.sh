# odocker Manual Test Plan

**Goal:** Verify every public `odocker` method by hand on a real Docker host, with no leftovers and no damage to existing containers, images, SSH config or shared oosh config.

**Architecture:** One pass per object family — system → inventory → image → container → workspace/build → network/volume → context/registry/buildx → ssh → compose → negative cases. Anything destructive runs on throwaway `odt-*` objects; read-only checks run on containers and images the tester already has, chosen through `$C_*` variables so the plan is not tied to one machine. Every step records the exit code and observed output against an expected result, and the destructive `force=yes` prunes are fenced off on shared hosts.

**Tech Stack:** `odocker` (bash/OOSH), Docker CLI (Engine 20.10+; examples use 29.x), `ossh` (for the SSH flow), tmux (interactive methods), `test.suite` (cross-check).

**Estimated time:** 60–90 min without compose/ssh/build; +45 min for the optional tasks.

---

## Rules (read before starting)

This plan must run on any teammate's machine, so **no container name is hardcoded**. Where a test needs an existing container, it uses `$C_RUN1`, `$C_RUN2` or `$C_STOPPED`, which you fill in once from your own Docker. Everything the plan creates is prefixed `odt-` and removed at the end.

1. **Fixtures vs. scratch.**
   - **Fixtures** = containers that already exist on your machine and that you use for read-only methods (and, if you accept the interruption, start/stop/restart/pause/rename). They are chosen in the Fixtures section below and must be left in the state you recorded.
   - **Scratch** = anything named `odt-*`. Anything that removes, resets, clones or prunes uses scratch only. A plan handed to teammates must not destroy their fixtures. If you explicitly want `remove`/`reset` on a fixture, do it on a copy (Task 5 Step 7) and say so in the report.
   - Leave every container that is neither your fixture nor your scratch alone — it belongs to someone else.
2. **Never run on a shared host:** `container.prune.all force=yes`, `system.prune force=yes`, `image.prune force=yes`, `network.prune force=yes`, `volume.prune force=yes`. They remove *everyone's* stopped containers/images/networks/volumes, including other teammates' work. Test the prompt only, and answer `n`.
3. **Back up before the tasks that mutate shared state:**
   ```bash
   cp ~/.ssh/config /tmp/odt-manual/ssh.config.bak 2>/dev/null
   cp "$CONFIG_PATH/odocker.env" /tmp/odt-manual/odocker.env.bak 2>/dev/null
   ```
4. **Interactive methods** (`container.run`, `container.exec`, `container.enter`) need a TTY. Run them in the tmux lower pane, not in a captured shell.
5. **Log level:** every command below assumes `LOG_LEVEL=3` (the default). Raise to `4`/`5` when you need to see what odocker passes to docker.
6. **PATH:** the commands use `odocker` and `test.suite` as oosh installs them. Check `command -v odocker`; if it is not on PATH, prefix the commands with `./` from the checkout.
7. Record each result in the [results table](#results-table). A step without a recorded verdict did not happen.

### Fixtures — choose on your machine

List what you have, then pick two running and one stopped container that you own:

```bash
docker ps     --format '{{.Names}}\t{{.Image}}\t{{.Status}}'
docker ps -a --filter status=exited --format '{{.Names}}\t{{.Image}}\t{{.Status}}'
```

```bash
# replace with names from the lists above
export C_RUN1=<a container you own that is Up>
export C_RUN2=<another container you own that is Up>
export C_STOPPED=<a container you own that is Exited>
```

| Variable | What to pick | Used by |
|---|---|---|
| `C_RUN1` | any running container you own | read-only checks, pause/unpause |
| `C_RUN2` | another running container you own | read-only checks, restart, rename |
| `C_STOPPED` | a stopped container you own | negative cases, start/stop |

If you have fewer than two running or no stopped container, skip the affected steps and rely on the `odt-*` scratch containers — the plan says where. Never pick a container you did not create: `docker inspect -f '{{index .Config.Labels "odocker.container"}}' <name>` and the container's owner are not always obvious.

### Images — choose on your machine

Same rule for images: nothing is hardcoded beyond the examples. List what you have and pick three:

```bash
docker image ls --format '{{.Repository}}:{{.Tag}}\t{{.Size}}'
```

```bash
export C_SMALL_IMAGE=<small image with sh>       # e.g. naked_alpine_3_19 or alpine:3.20
export C_BASH_IMAGE=<image with bash>            # e.g. naked_ubuntu_24_04 or ubuntu:24.04
export C_SSHD_IMAGE=<image exposing 22/tcp>      # e.g. naked_ubuntu_20_04_sshd
```

| Variable | Requirement | Used by |
|---|---|---|
| `C_SMALL_IMAGE` | `sh` present, fast to start | image lifecycle, container lifecycle, network/volume, prune |
| `C_BASH_IMAGE` | `bash` present | `container.run`/`exec`/`enter` (they start `bash`) |
| `C_SSHD_IMAGE` | publishes `22/tcp`, sshd starts | SSH flow |

If a suitable image is missing, `odocker image.pull alpine:3.20` / `ubuntu:24.04` works for the first two; the SSH flow can be skipped and recorded as such.

---

## Task 0: Setup and baseline

- [ ] **Step 1: Go to the dev checkout and set a known log level**

```bash
cd ~/oosh                     # your once.sh checkout (dev branch)
export LOG_LEVEL=3
CONFIG_PATH="${CONFIG_PATH:-$HOME/config}"; export CONFIG_PATH
mkdir -p /tmp/odt-manual
# fill these from the Fixtures and Images sections above
export C_RUN1=<running-container> C_RUN2=<running-container> C_STOPPED=<stopped-container>
export C_SMALL_IMAGE=<small-image> C_BASH_IMAGE=<bash-image> C_SSHD_IMAGE=<sshd-image>
command -v odocker
echo "CONFIG_PATH=$CONFIG_PATH"
```

Expected: the checkout path, `/…/oosh/odocker`, `CONFIG_PATH=/…/config` (`~/config` in a normal install), no other output. If `command -v odocker` prints nothing, use `./odocker` for the rest of the plan.

- [ ] **Step 2: Record the environment and the fixtures**

```bash
docker --version
docker info --format '{{.ServerVersion}}'
docker compose version; echo "compose rc=$?"
docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | tee /tmp/odt-manual/containers.before
docker image ls --format '{{.Repository}}:{{.Tag}}' | sort | tee /tmp/odt-manual/images.before
for c in "$C_RUN1" "$C_RUN2" "$C_STOPPED"; do
  printf '=== %s\n' "$c"
  docker inspect -f '{{.State.Status}}|{{.Config.Image}}|{{.Config.Hostname}}|{{range $p,$v := .NetworkSettings.Ports}}{{$p}}={{$v}} {{end}}' "$c" \
    | tee -a /tmp/odt-manual/fixtures.before
  docker inspect -f '{{json .Config.Labels}}' "$c" | tee -a /tmp/odt-manual/fixtures.before
done
```

Record, not assert:
- client and server Docker versions (they must match, or note the mismatch)
- whether `docker compose` exists: if it prints `unknown command: docker compose`, **the compose group in Task 11 is expected to be blocked** for you — that is a host gap, not an odocker bug
- the containers you listed, and for each fixture: `status|image|hostname|ports` plus the label JSON. Whether `odocker=1` is present tells you which odocker build created it; record it, do not change it.

- [ ] **Step 3: Record the automated-suite baseline**

In the tmux lower pane:

```bash
test.suite run odocker 1
test.suite run completion.audit 1
```

Expected: both finish; note the pass/fail counts. `completion.audit` is the automated check for method and parameter completion (it includes `odocker`), so completion is **not** re-tested by hand in this plan. A pre-existing failure here makes a later manual failure ambiguous — record it now.

- [ ] **Step 4: Snapshot the shared config**

```bash
cp ~/.ssh/config /tmp/odt-manual/ssh.config.bak 2>/dev/null; echo "ssh rc=$?"
cp "$CONFIG_PATH/odocker.env" /tmp/odt-manual/odocker.env.bak 2>/dev/null; echo "env rc=$?"
cat "$CONFIG_PATH/odocker.env" 2>/dev/null
```

Expected: `ODOCKER_WORKSPACES=...`. Keep the file content in your notes; Task 7 must leave it unchanged unless you test `workspace.set` deliberately.

---

## Task 1: Help and usage (no docker)

- [ ] **Step 1: No-argument usage**

```bash
odocker
```

Expected: `You started`, `odocker`, `Usage:`, a colourised METHOD/PARAMETER/DESCRIPTION table, the Examples block, rc 0. Spot-check that every family you will test below appears: `container`, `image`, `volume`, `network`, `context`, `workspace`, `compose`, `system`.

Completion is **not** tested here — `test.suite run completion.audit 1` in Task 0 covers it automatically. Do not use `c2 function.completion odocker` as a method count: it is the completion engine's inventory, it filters private helpers, and it tells you nothing about whether the method actually works.

---

## Task 2: Preflight and system (read-only)

- [ ] **Step 1: Support check**

```bash
odocker support.check; echo "rc=$?"
```

Expected: **no output**, `rc=0` when a Docker socket exists (default `/var/run/docker.sock`, or `$ODOCKER_SOCKET`). `rc=1` prints the reason on stdout.

- [ ] **Step 2: Installed check**

```bash
odocker system.installed; echo "rc=$?"
odocker system.installed docker; echo "docker rc=$?"
odocker system.installed compose; echo "compose rc=$?"
```

Expected: `missing: compose` + `rc=1`; `docker rc=0`; `compose rc=1` with `missing: compose`.

- [ ] **Step 3: Engine facts**

```bash
odocker system.info | head -8
odocker system.version | head -12
odocker socket.group.ensure; echo "rc=$?"
```

Expected: `OSType: linux`, `Architecture: x86_64`, `CPUs`, `Total Memory`, `Name`, `ID`; Client and Server blocks with the same version; the socket's group name from `socket.group.ensure`.

- [ ] **Step 4: Disk and container-detection**

```bash
odocker disk.show
odocker system.container.is; echo "rc=$?"
timeout 3 odocker system.events; echo "events rc=$?"
```

Expected: `TYPE TOTAL ACTIVE SIZE RECLAIMABLE` table (Images / Containers / Local Volumes / Build Cache), rc 0; `not a container` + `rc=1` on a normal machine (inside a container it says `inside a container (docker)` and rc 0); `system.events` streams JSON events until `timeout` kills it (rc 124).

- [ ] **Step 5: Do NOT install**

Skip `odocker prereqs.install` on a shared or test machine — it installs packages, adds Docker's apt repo and joins users to the socket group. It is covered by the platform/install tests, not by manual QA.

---

## Task 3: Inventory (read-only)

Run each, confirm rc 0 and a sane table/JSON shape:

- [ ] **Step 1: Containers**

```bash
odocker container.list.running
odocker container.list.all
```

Expected: header `CONTAINER ID NAMES IMAGE STATUS PORTS`; `list.running` shows only `Up` containers (your fixtures), `list.all` also the exited ones.

- [ ] **Step 2: Images, volumes, networks, contexts**

```bash
odocker image.list
odocker volume.list
odocker network.list
odocker context.list
```

Expected: image table with `REPOSITORY TAG SIZE CREATED`; volume table (currently header only); at least `bridge`, `host`, `none` networks; `default *` context.

- [ ] **Step 3: Status / health**

```bash
odocker status.show
odocker health.check
```

Expected: `=== Running Containers ===`, `=== Stopped Containers ===`, `=== Images ===`, and for `health.check` additionally `=== Container Health ===`, `=== Dangling Images ===`, `=== Compose Services ===` (`(no compose file found)` or the `docker compose ps` error), `=== Disk Usage ===`.

- [ ] **Step 4: Discovery aid**

```bash
odocker dockerfile.find
odocker dockerfile.find "$C_RUN1"
odocker dockerfile.find "$C_RUN2"
odocker dockerfile.find "$C_STOPPED"
odocker dockerfile.find $C_BASH_IMAGE
```

Expected: no arg prints `Usage:` plus the container/image list; with a container prints `Image:`, `Dockerfile: <workspaces>/<workspace>/Dockerfile`, `Directory: <workspaces>/<workspace>`; the container's image and the workspace that built it should name the same workspace. An image that was not built by a workspace prints an explanatory message (record which).

- [ ] **Step 5: Fixtures — low-level observation (read-only; skip any fixture you did not set)**

These are the methods teammates will run against their own containers, so run them against all three fixtures.

```bash
for c in "$C_RUN1" "$C_RUN2"; do
  echo "### $c"
  odocker container.inspect "$c" | head -5
  odocker container.port.show "$c"
  odocker container.ip.get "$c"
  odocker container.top "$c" | head -4
  odocker container.log.show "$c" 10
  timeout 3 odocker container.stats --no-stream "$c"; echo "stats rc=$?"
  odocker container.command.run "$c" 'id -un; hostname'
done
```

Expected: JSON array from `inspect`; the port table from `port.show` (empty is normal when the container publishes no ports); an address on the container's first network (e.g. `172.17.0.x`) from `ip.get`; PID/CMD table from `top`; the last ten log lines; a one-shot stats table (`--no-stream`) with rc 0; the image's login user + the container's **ID** as `hostname` (not its name — the documented behaviour).

- [ ] **Step 6: Fixtures — stopped container must fail cleanly**

```bash
odocker container.ip.get "$C_STOPPED"; echo "ip rc=$?"
odocker container.top "$C_STOPPED"; echo "top rc=$?"
odocker container.command.run "$C_STOPPED" true; echo "exec rc=$?"
odocker container.log.show "$C_STOPPED" 10; echo "log rc=$?"
odocker container.stats --no-stream "$C_STOPPED"; echo "stats rc=$?"
```

Expected: `log.show` works on a stopped container (rc 0, the last lines of its old output); `top` and `command.run` fail with docker's `is not running` error and rc 1; `stats --no-stream` still prints a zeroed row and rc 0 (docker's behaviour); `ip.get` is the exception — on Docker 29 it prints the literal `invalid` and **exits 0** (older or newer engines may print nothing or another string), although its docstring promises rc 1 when no address is available. **Record that as a finding** (it is reproduced below in Task 12).

- [ ] **Step 7: Fixtures — copy out (read-only on the container)**

```bash
odocker container.copy "$C_RUN1:/etc/hostname" /tmp/odt-manual/hostname.$C_RUN1; echo "running rc=$?"
cat /tmp/odt-manual/hostname.$C_RUN1
odocker container.copy "$C_STOPPED:/etc/hostname" /tmp/odt-manual/hostname.$C_STOPPED; echo "stopped rc=$?"
cat /tmp/odt-manual/hostname.$C_STOPPED
```

Expected: rc 0 for both — `docker cp` works on a stopped container — and each file holds the container's host name (its ID). If a fixture has no `/etc/hostname`, pick another small file and note it.

---

## Task 4: Image lifecycle (local image, no registry)

Use any small local image that has `sh` — the plan calls it `$C_SMALL_IMAGE` (e.g. `naked_alpine_3_19` or `alpine:3.20`).

- [ ] **Step 1: Tag and inspect**

```bash
odocker image.tag $C_SMALL_IMAGE odt/alpine:test; echo "rc=$?"
odocker image.inspect odt/alpine:test | head -5
odocker image.history $C_SMALL_IMAGE | head -5
```

Expected: tag rc 0 (silent); inspect prints a JSON array starting `[ { "Architecture": "amd64"`; history prints an `IMAGE CREATED CREATED BY SIZE COMMENT` table.

- [ ] **Step 2: Pull from a registry (network)**

```bash
odocker image.pull alpine:3.20; echo "rc=$?"
```

Expected: `3.20: Pulling from library/alpine`, `Status: Downloaded newer image…`, rc 0. Skip if the host has no registry access; record as skipped.

- [ ] **Step 3: Remove and negative case**

```bash
odocker image.remove odt/alpine:test; echo "rc=$?"
odocker image.remove no_such_image_odt; echo "rc=$?"
```

Expected: `Untagged: odt/alpine:test` + `SUCCESS> Image odt/alpine:test removed`, rc 0; the second prints an error and rc 1.

- [ ] **Step 4: Prune prompt only (destructive)**

```bash
odocker image.prune
```

Expected: docker's interactive `WARNING! This will remove all dangling images. Are you sure? [y/N]`. **Answer `n`.** Confirm rc 0 and that `image.list` is unchanged. Never pass `force=yes` here.

- [ ] **Step 5: Image command**

```bash
odocker image.command.run $C_SMALL_IMAGE echo odt-image-ok; echo "rc=$?"
```

Expected: `odt-image-ok`, rc 0, and no container left (`docker ps -a | grep -c odt` → 0).

- [ ] **Step 6: Build from a scratch context**

```bash
mkdir -p /tmp/odt-manual/build
printf 'FROM %s\nRUN echo odt > /odt.txt\n' "$C_SMALL_IMAGE" > /tmp/odt-manual/build/Dockerfile
odocker image.build /tmp/odt-manual/build odt/built:test; echo "rc=$?"
odocker image.command.run odt/built:test cat /odt.txt
odocker image.remove odt/built:test
```

Expected: build output ending `Successfully tagged odt/built:test` (classic builder) or `naming to …odt/built:test` (BuildKit), rc 0; `odt` from the file; remove rc 0. `image.push` is **skipped** — no registry credentials; record it as skipped.

---

## Task 5: Container lifecycle (the main path)

- [ ] **Step 1: Create**

```bash
odocker container.create $C_SMALL_IMAGE odt-smoke; echo "rc=$?"
docker inspect -f '{{index .Config.Labels "odocker"}}|{{index .Config.Labels "odocker.container"}}|{{range .Mounts}}{{.Source}} {{end}}' odt-smoke
```

Expected: `SUCCESS> Container odt-smoke (<12-hex>) created from $C_SMALL_IMAGE`, rc 0; labels `1|odt-smoke|` and **no mount** (socket is opt-in).

- [ ] **Step 2: Start, inspect, addresses**

```bash
odocker container.start odt-smoke; echo "rc=$?"
odocker container.inspect odt-smoke | head -3
odocker container.ip.get odt-smoke
odocker container.port.show odt-smoke
odocker container.top odt-smoke | head -3
```

Expected: container name echoed; JSON array; `172.17.0.x`; port table (empty for this image); UID/PID/CMD table.

- [ ] **Step 3: Non-interactive command**

```bash
odocker container.command.run odt-smoke echo odt-ok; echo "rc=$?"
odocker container.command.run odt-smoke 'echo $((6*7))'
```

Expected: `odt-ok` rc 0; `42` (the whole argument is passed through `sh -c`).

- [ ] **Step 4: Copy out**

```bash
docker exec odt-smoke sh -c 'echo hi > /tmp/odt.txt'
odocker container.copy odt-smoke:/tmp/odt.txt /tmp/odt-manual/odt-copy.txt; echo "rc=$?"
cat /tmp/odt-manual/odt-copy.txt
```

Expected: rc 0, `hi`.

- [ ] **Step 5: Logs, pause, unpause, rename, restart, kill**

```bash
odocker container.log.show odt-smoke 10
odocker container.pause odt-smoke;   echo "pause rc=$?"
odocker container.unpause odt-smoke; echo "unpause rc=$?"
odocker container.rename odt-smoke odt-smoke2; echo "rename rc=$?"
odocker container.command.run odt-smoke2 echo still-ok
odocker container.restart odt-smoke2; echo "restart rc=$?"
odocker container.kill odt-smoke2;    echo "kill rc=$?"
```

Expected: last 10 log lines; each step echoes the name and rc 0; `still-ok` after rename; after kill `container.list.running` no longer shows it.

- [ ] **Step 6: Remove and negative cases**

```bash
odocker container.remove odt-smoke2; echo "rc=$?"
odocker container.remove odt-smoke2; echo "second rc=$?"
odocker container.remove; echo "noarg rc=$?"
odocker container.stop; echo "stop noarg rc=$?"
odocker container.start no_such_container_odt; echo "rc=$?"
```

Expected: `SUCCESS> Container odt-smoke2 removed`, rc 0; second remove rc 1 with an error; no-arg calls print `Usage: …` and rc 1.

- [ ] **Step 7: Clone, reset, update**

```bash
odocker container.create $C_SMALL_IMAGE odt-base >/dev/null
odocker container.start odt-base >/dev/null
docker exec odt-base sh -c 'echo state > /odt-state.txt'
odocker container.clone odt-base 30; echo "clone rc=$?"
clone=$(docker ps -q --filter ancestor=clone_odt-base | head -1)
docker exec "$clone" cat /odt-state.txt
docker ps --format '{{.Names}}\t{{.Ports}}' | grep -E '8052|odt-'
odocker container.update odt-base --cpus 0.5; echo "update rc=$?"
docker inspect -f '{{.HostConfig.NanoCpus}}' odt-base
odocker container.reset $C_SMALL_IMAGE 30 no odt-base; echo "reset rc=$?"
```

Expected: clone commits `odt-base` to `clone_odt-base` and starts a second container with the same filesystem state (`state`). If the image exposes `22/tcp` (the usual `naked_*` images do), the clone is launched with the six mappings of offset 30 — `8052->22/tcp`, `8110->8080/tcp`, `8513->8443/tcp`, `5031/5032/5035`; if not, it is a plain detached container with no ports. `update` rc 0 and `500000000` for NanoCpus. `reset $C_SMALL_IMAGE 30 no odt-base` stops any container on 8052, clears the host key and starts a fresh named `odt-base` there — rc 0. The clone has a random Docker name and stays (with `clone_odt-base`) until Task 13.

- [ ] **Step 8: Non-destructive lifecycle on the fixtures (skip if you could not pick all three)**

Stop/start/restart/pause/rename the real containers, leaving them exactly as Task 0 recorded. **Skip this step if you are not willing to interrupt them** (a teammate may be working inside).

```bash
# stop + start the stopped fixture ($C_STOPPED ends stopped)
odocker container.start "$C_STOPPED"; echo "start rc=$?"
odocker container.port.show "$C_STOPPED"          # the six mappings are bound now
odocker container.stop "$C_STOPPED"; echo "stop rc=$?"

# restart the second running fixture — returns to running
odocker container.restart "$C_RUN2"; echo "restart rc=$?"

# pause/unpause the first running fixture
odocker container.pause "$C_RUN1"; echo "pause rc=$?"
odocker container.top "$C_RUN1"; echo "top while paused rc=$?"   # expect a docker error
odocker container.unpause "$C_RUN1"; echo "unpause rc=$?"

# rename round-trip on the second fixture
odocker container.rename "$C_RUN2" odt-renamed; echo "rename rc=$?"
odocker container.rename odt-renamed "$C_RUN2"; echo "rename back rc=$?"
```

Expected: `start`/`stop` echo `$C_STOPPED` and rc 0; `restart` echoes `$C_RUN2`, rc 0; `pause` echoes the name, `top` on a paused container either lists the frozen processes or fails with a docker error (Docker's own behaviour — record which), `unpause` rc 0; both renames rc 0 and `docker ps -a` shows the original name again. **Verify the fixtures match Task 0 afterwards:**

```bash
for c in "$C_RUN1" "$C_RUN2" "$C_STOPPED"; do docker inspect -f '{{.Name}} {{.State.Status}}' "$c"; done
```

Expected: each fixture in the state you recorded in Task 0. If a fixture's ports are already taken (it was running, or another container holds them), `start` fails cleanly — record the message, don't retry with `force`.

- [ ] **Step 9: Stats stream (bounded)**

```bash
odocker container.create $C_SMALL_IMAGE odt-stats >/dev/null
odocker container.start odt-stats >/dev/null
timeout 3 odocker container.stats odt-stats; echo "stats rc=$?"
odocker container.stop odt-stats >/dev/null && odocker container.remove odt-stats >/dev/null
```

Expected: a live CPU/MEM/NET/IO table, killed by `timeout` (rc 124). No `odt-stats` left afterwards.

---

## Task 6: `container.run` — socket opt-in and host name (interactive)

Run these in the tmux lower pane.

- [ ] **Step 1: Run without the socket**

```bash
odocker container.run $C_BASH_IMAGE odt-run
```

Expected: `Running image: $C_BASH_IMAGE`, then a bash prompt inside the container. Type `exit`.

```bash
docker inspect -f '{{range .Mounts}}{{.Source}} {{end}}' odt-run
docker inspect -f '{{.Config.Hostname}}|{{.Name}}' odt-run
```

Expected: **empty mounts**; the hostname is the container ID, not `odt-run` (`<id>|/odt-run`).

- [ ] **Step 2: Run with the socket**

```bash
odocker container.run $C_BASH_IMAGE odt-run2 docker
docker inspect -f '{{range .Mounts}}{{.Source}}{{end}}' odt-run2
```

Expected: `/var/run/docker.sock` in the mounts. Inside the container `docker ps` works. Type `exit`.

- [ ] **Step 3: Remove both**

```bash
odocker container.remove odt-run
odocker container.remove odt-run2
```

Expected: both rc 0.

- [ ] **Step 4: Exec and enter (interactive)**

```bash
odocker container.create $C_BASH_IMAGE odt-tty >/dev/null
odocker container.start odt-tty >/dev/null
odocker container.exec odt-tty        # expect a bash prompt; run `echo $0`; exit
odocker container.enter odt-tty sh    # expect a sh prompt; exit
odocker container.exec odt-tty sh -c 'uname -s'
```

Expected: interactive prompts; `bash`; `sh`; the last command works non-interactively only if your shell passes it through — `container.command.run` is the supported way for that. Record the behaviour either way.

---

## Task 7: Workspaces and Dockerfile builds (mostly read-only)

- [ ] **Step 1: Inspect the root**

```bash
odocker workspace.get; echo "rc=$?"
odocker workspace.get /nope/odt; echo "bad rc=$?"
odocker workspace.list
odocker workspace.list | wc -l
```

Expected: the workspaces root that `workspace.get` reports (whatever `$ODOCKER_WORKSPACES` resolves to on this machine); the bad path prints `ERROR> odocker.workspace.get: /nope/odt is not a directory …` + `INVALID: not a directory: /nope/odt`, rc 1; the list is a `WORKSPACE IMAGE TAG BUILT` table (`DockerImageTemplate`, `minimalLinux`, `nakedDebian9.12`, `plantuml`, …).

- [ ] **Step 2: Build one workspace (optional, minutes)**

```bash
odocker workspace.get
odocker workspace.list
odocker workspace.build <workspace-you-picked>; echo "rc=$?"
odocker image.list | grep -i <its-image-tag>
```

Expected: docker build output ending `SUCCESS`/`naming to …`, rc 0, the image tag from the workspace table. Pick any workspace whose directory has a Dockerfile and that you are willing to rebuild; record which. Skip if none has one.

- [ ] **Step 3: `workspace.set` / `init` (mutates shared config — optional)**

Only if you accept changing the host-wide `$CONFIG_PATH/odocker.env`:

```bash
mkdir -p /tmp/odt-manual/ws
odocker workspace.set /tmp/odt-manual/ws; echo "set rc=$?"
cat "$CONFIG_PATH/odocker.env"
odocker workspace.get
odocker workspace.init /tmp/odt-manual/ws2; echo "init rc=$?"
```

Expected: `set` refuses a missing dir, accepts the existing one and persists `export ODOCKER_WORKSPACES=/tmp/odt-manual/ws`; `init` creates the dir and then sets it. **Restore** afterwards:

```bash
cp /tmp/odt-manual/odocker.env.bak "$CONFIG_PATH/odocker.env"
unset ODOCKER_WORKSPACES
```

Expected: `workspace.get` back to the original path in a fresh shell.

- [ ] **Step 4: `rebuild` / `install` / `build.all` / `seed` / `push`**

Run only the ones whose side effects you accept:

```bash
odocker workspace.rebuild nakedAlpine/3.19; echo "rebuild rc=$?"
odocker workspace.install; echo "install rc=$?"
odocker workspace.build.all; echo "build.all rc=$?"      # long: every workspace with a Dockerfile
```

Expected: `rebuild` removes the old image and rebuilds it, rc 0; `install` keeps an existing root (or creates the default) and writes `$CONFIG_PATH/odocker.env`, rc 0 — verify `workspace.get` is unchanged/expected; `build.all` builds every workspace and reports per-workspace results.

**Skipped, record as such:**
- `workspace.seed` — fills the root from `WODA.test` over ossh or from `test.wo-da.de`; network + remote host. Run only if you are willing to download a workspace tree: `odocker workspace.seed /tmp/odt-manual/seed-source` (a local folder is the safe form).
- `workspace.push` — pushes workspaces to a remote host; needs a reachable ossh Host.

---

## Task 8: Volumes and networks

- [ ] **Step 1: Volume**

```bash
odocker volume.create odt-vol; echo "rc=$?"
odocker volume.list | grep odt-vol
odocker volume.inspect odt-vol | head -5
odocker volume.remove odt-vol; echo "rc=$?"
odocker volume.remove odt-vol; echo "second rc=$?"
```

Expected: name echoed; the volume appears in the table; JSON array with `"Name": "odt-vol"`; first remove rc 0, second rc 1.

- [ ] **Step 2: Network + connect/disconnect**

```bash
odocker container.create $C_SMALL_IMAGE odt-netbox >/dev/null
odocker container.start odt-netbox >/dev/null
odocker network.create odt-net; echo "create rc=$?"
odocker network.inspect odt-net | head -3
odocker network.connect odt-net odt-netbox; echo "connect rc=$?"
docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}' odt-netbox
odocker network.disconnect odt-net odt-netbox; echo "disconnect rc=$?"
odocker network.remove odt-net; echo "remove rc=$?"
odocker container.stop odt-netbox >/dev/null && odocker container.remove odt-netbox >/dev/null
```

Expected: sha256 network ID; `"Name": "odt-net"`; connect/disconnect rc 0; both `bridge odt-net` appear while connected; remove rc 0; `network.list` back to the three defaults.

- [ ] **Step 3: Prune prompts (answer `n`)**

```bash
odocker network.prune
odocker volume.prune
```

Expected: docker's interactive confirmation for each; answer `n`; nothing removed.

---

## Task 9: Contexts, registry, buildx

- [ ] **Step 1: Context round-trip**

```bash
odocker context.create odt-ctx; echo "rc=$?"
odocker context.list | grep odt-ctx
odocker context.use odt-ctx; echo "use rc=$?"
odocker context.list | grep '\*'
odocker context.use default
odocker context.remove odt-ctx; echo "remove rc=$?"
odocker context.list | grep -c odt-ctx
```

Expected: `Successfully created context "odt-ctx"`; create/use/remove rc 0; `*` moves to `odt-ctx` and back to `default`; count 0 at the end.

- [ ] **Step 2: Registry search (network)**

```bash
odocker registry.search alpine | head -5; echo "rc=$?"
```

Expected: a `NAME DESCRIPTION STARS OFFICIAL AUTOMATED` table containing `alpine`, rc 0. Skip `registry.login`/`logout` without credentials — record as skipped.

- [ ] **Step 3: Buildx (read-only)**

```bash
odocker buildx.list
odocker buildx.inspect 2>&1 | head -5
mkdir -p /tmp/odt-manual/build
printf 'FROM %s\nRUN echo odt > /odt.txt\n' "$C_SMALL_IMAGE" > /tmp/odt-manual/build/Dockerfile
odocker buildx.build --load -t odt/buildx:test /tmp/odt-manual/build; echo "rc=$?"
odocker image.command.run odt/buildx:test cat /odt.txt    # expect: odt
odocker image.remove odt/buildx:test
```

Expected: a builder table with `default`; inspect prints the builder description; `buildx.build --load` ends with the build result, rc 0, and the image is in `image.list`; remove rc 0. `buildx.create`/`use`/`remove` mutate Docker's builder state — only run them if you accept that, and remove what you create.

---

## Task 10: SSH flow (mutates `~/.ssh/config`; optional)

Requires an image that exposes `22/tcp` and runs sshd — `$C_SSHD_IMAGE` (e.g. `naked_ubuntu_20_04_sshd`). Backup from Task 0 must exist.

**Ports:** the fixtures publish `8022`, `8080`, `8443`, `5001`, `5002`, `5005` while `$C_STOPPED` runs, so these steps use **offset 70** (`8092`, `8150`, `8513`, `5071`, `5072`, `5075`) to stay clear. Check first:

```bash
docker ps --format '{{.Names}}\t{{.Ports}}'
```

- [ ] **Step 1: Start**

```bash
odocker container.ssh.start $C_SSHD_IMAGE odt-ssh 70 test test; echo "rc=$?"
```

Expected: `odt-ssh is ready: ssh -p 8092 test@localhost — now ossh login odt-ssh, ossh install odt-ssh or odocker container.enter odt-ssh`, rc 0. `~/.ssh/config` gains a `Host odt-ssh` with `Port 8092`, `User test`.

- [ ] **Step 2: Login and inspect**

```bash
ossh login odt-ssh 'echo odt-ssh-ok'      # or: ssh -p 8092 test@localhost 'echo odt-ssh-ok'
odocker container.port.show odt-ssh
```

Expected: `odt-ssh-ok`; port table with `8092->22/tcp` plus the other mapped ports.

- [ ] **Step 3: Replace / port-busy guard**

```bash
odocker container.ssh.start $C_SSHD_IMAGE odt-ssh 70 test test; echo "again rc=$?"
odocker container.ssh.start $C_SSHD_IMAGE odt-ssh-other 70 test test; echo "busy rc=$?"
```

Expected: the same name is replaced, rc 0; the second name on the same offset is refused with `port 8092 is used by container odt-ssh …`, rc 1, and no `odt-ssh-other` container remains.

- [ ] **Step 4: Prune and clean up**

```bash
odocker container.remove odt-ssh; echo "remove rc=$?"
odocker container.ssh.prune
grep -c 'Host odt-ssh' ~/.ssh/config
```

Expected: remove forgets the Host (rc 0); `ssh.prune` reports `removed 0: every localhost Host has its container` or a positive count for stale entries; grep returns 0.

- [ ] **Step 5: Restore SSH config**

```bash
diff <(sort ~/.ssh/config) <(sort /tmp/odt-manual/ssh.config.bak) && echo "ssh config unchanged"
```

Expected: identical, or only intended `odt-*` removals.

- [ ] **Step 6: `container.run.sshd` directly**

```bash
odocker container.run.sshd $C_SSHD_IMAGE odt-sshd 40; echo "rc=$?"
odocker container.port.show odt-sshd
odocker container.run.sshd $C_SSHD_IMAGE odt-sshd-docker 50 docker; echo "rc=$?"
docker inspect -f '{{range .Mounts}}{{.Source}}{{end}}' odt-sshd-docker
docker exec odt-sshd-docker docker version --format '{{.Client.Version}}' 2>&1 | head -2
```

Expected: `Container odt-sshd (…) started (SSH: ssh -p 8062 root@localhost)`, rc 0, ports `8062->22/tcp, 8120->8080/tcp, 8483->8443/tcp, 5041/5042/5045->…`; with `docker` the socket is mounted **and** `container.docker.install` runs inside the container (needs network; note the result either way). Clean up both:

```bash
odocker container.stop odt-sshd odt-sshd-docker >/dev/null 2>&1
odocker container.remove odt-sshd >/dev/null; odocker container.remove odt-sshd-docker >/dev/null
```

---

## Task 11: Compose (host-dependent)

- [ ] **Step 1: Confirm the expected failure**

```bash
odocker compose.service.list; echo "rc=$?"
odocker compose.service.version; echo "rc=$?"
odocker compose.status.show; echo "rc=$?"
odocker compose.raw version; echo "rc=$?"
```

Expected when the plugin is absent: `ERROR> Docker Compose is not installed — install the docker-compose plugin for this package manager`, rc 1 for every one. This is the correct graceful failure; record it as **pass (expected blocked)**.

- [ ] **Step 2: Install the plugin (optional, needs sudo)**

Ubuntu/Debian:
```bash
sudo apt-get install -y docker-compose-v2      # or docker-compose-plugin from Docker's repo
docker compose version
```

Then repeat Step 1 — expected: `Docker Compose version v2.x`, rc 0.

- [ ] **Step 3: Exercise compose against a scratch project**

Only after the plugin is installed. Create `/tmp/odt-manual/compose/compose.yaml`:

```yaml
services:
  web:
    image: $C_SMALL_IMAGE
    command: sh -c 'sleep 300'
    ports:
      - "8080:80"
```

then:
```bash
cd /tmp/odt-manual/compose
odocker compose.service.up.detached web; echo "up rc=$?"
odocker compose.service.list
odocker compose.service.logs web
odocker compose.service.restart web; echo "restart rc=$?"
odocker compose.service.stop web;    echo "stop rc=$?"
odocker compose.status.show
odocker compose.service.down;        echo "down rc=$?"
```

Expected: `up -d` creates `compose-web-1`; list/status show it `running`; restart/stop rc 0; `down` removes the container and network. If `compose.file.find` does not look in `/tmp`, note it as a finding.

- [ ] **Step 4: Remaining compose methods (smoke after install)**

With the same scratch project:

```bash
odocker compose.service.build web;        echo "build rc=$?"
odocker compose.service.config | head -5; echo "config rc=$?"
odocker compose.service.create web;       echo "create rc=$?"
odocker compose.service.start web;        echo "start rc=$?"
odocker compose.service.pause web;        echo "pause rc=$?"
odocker compose.service.unpause web;      echo "unpause rc=$?"
odocker compose.service.port web 80;      echo "port rc=$?"       # expect 0.0.0.0:8080
odocker compose.service.top;              echo "top rc=$?"
odocker compose.service.images;           echo "images rc=$?"
odocker compose.service.copy web:/etc/hostname /tmp/odt-manual/hostname; echo "copy rc=$?"
odocker compose.service.kill web;         echo "kill rc=$?"
timeout 5 odocker compose.service.wait web; echo "wait rc=$?"      # 124: the service is still up
odocker compose.service.remove web;       echo "remove rc=$?"
odocker compose.service.pull;             echo "pull rc=$?"
odocker compose.service.push;             echo "push rc=$?"        # expected to fail without creds
timeout 3 odocker compose.service.events; echo "events rc=$?"      # 124
odocker compose.service.exec web 'echo $0'; echo "exec rc=$?"      # needs a TTY: run in tmux
odocker compose.start web;                echo "compose.start rc=$?"
odocker compose.stop web;                 echo "compose.stop rc=$?"
odocker compose.raw ps;                   echo "raw rc=$?"
```

Expected: each rc 0 except `push` (no credentials — record the exact refusal), `wait` and `events` (timeout, rc 124); `compose.start`/`stop` route to the service by name. Add `compose.service.run web 'echo $0'` and `compose.service.up web` if you want the foreground variants — both need a TTY, so run them in tmux and exit the shell they give you. Record per-method verdicts — a compose method that silently succeeds without doing anything is a finding.

---

## Task 12: Negative cases and safety behaviours

- [ ] **Step 1: Missing parameters**

```bash
for m in container.run container.create image.remove image.pull image.tag volume.create network.create context.create workspace.build dockerfile.find raw; do
  odocker $m >/dev/null 2>&1; printf "%-22s rc=%s\n" "$m" "$?"
done
```

Expected: `rc=1` for every method whose signature requires a parameter, **except**:
- `dockerfile.find` — `rc=0` by design (no arg is a discovery aid that lists containers/images)
- `raw` — passes through to `docker`, so the rc is docker's own (`0` for no args)

**Known finding to reproduce:** `volume.create` with no name currently returns `rc=0` and creates an **anonymous volume** (`docker volume create` with no name). Its signature says `<name>`. Record it as a finding and clean up:

```bash
docker volume ls --format '{{.Name}}' | grep -v '^$' | tail -n +1   # find the 64-hex anonymous name
docker volume rm <the-64-hex-name>
```

- [ ] **Step 2: Unknown image / container**

```bash
odocker container.create no_such_image_odt odt-bad; echo "rc=$?"
odocker container.run no_such_image_odt odt-bad; echo "rc=$?"
odocker container.command.run no_such_container_odt echo hi; echo "rc=$?"
odocker container.inspect no_such_container_odt; echo "inspect rc=$?"
odocker container.port.show no_such_container_odt; echo "port rc=$?"
```

Expected: clear docker error (`Unable to find image … pull access denied` / `No such container`), rc non-zero, and **no half-created `odt-bad` container**.

- [ ] **Step 3: Fixture edge cases (skip the parts whose fixture is unset)**

```bash
odocker container.ip.get "$C_STOPPED"; echo "stopped ip rc=$?"
odocker container.rename "$C_RUN1" same-name; odocker container.rename same-name "$C_RUN1"
```

Expected: the stopped `ip.get` prints `invalid` and rc 0 (the finding from Task 3 Step 6 — record it again with this Docker version); rename to a name already in use fails with docker's `Conflict` error and rc 1, then the second rename restores the name (it is a no-op if the first failed).

- [ ] **Step 4: Prune force guard (prompt only)**

```bash
odocker container.prune.all
```

Expected: `WARNING! This will remove all stopped containers.` and a `[y/N]` prompt. Answer `n`. Confirm the fixtures are still there:

```bash
for c in "$C_RUN1" "$C_RUN2" "$C_STOPPED"; do docker inspect -f '{{.Name}} {{.State.Status}}' "$c"; done
```

```bash
odocker container.prune.all force=yes; echo "DID NOT RUN rc=$?"
```

**Do not run this on a shared host** — it removes every stopped container, including fixtures and other users' containers. Record it as *verified by inspection only* (`force=yes` maps to `docker container prune -f`).

- [ ] **Step 5: Single-container prune (safe, scratch only)**

```bash
odocker container.create $C_SMALL_IMAGE odt-prune >/dev/null
odocker container.start odt-prune >/dev/null && odocker container.stop odt-prune >/dev/null
odocker container.prune odt-prune; echo "rc=$?"
docker inspect odt-prune >/dev/null 2>&1; echo "gone rc=$?"
```

Expected: rc 0, and `gone rc=1` (container and its image reference removed).

- [ ] **Step 6: `raw`**

```bash
odocker raw version | head -3
odocker raw ps --format '{{.Names}}'
odocker raw no-such-command; echo "rc=$?"
```

Expected: docker's own output for the first two; docker's unknown-command error and rc 125/1 for the third.

---

## Task 13: Cleanup and sign-off

- [ ] **Step 1: Remove every `odt-*` object**

The clone from Task 5 Step 7 has a random Docker name and leaves a `clone_odt-base` image, so it needs its own cleanup before the prefix sweep:

```bash
docker ps -aq --filter ancestor=clone_odt-base | xargs -r docker rm -f
docker rmi -f clone_odt-base 2>/dev/null
docker ps -a  --format '{{.Names}}'        | grep '^odt-' | xargs -r docker rm -f
docker images --format '{{.Repository}}:{{.Tag}}' | grep 'odt/' | cut -d: -f1 | xargs -r docker rmi -f
docker volume ls --format '{{.Name}}'      | grep '^odt-' | xargs -r docker volume rm
docker network ls --format '{{.Name}}'     | grep '^odt-' | xargs -r docker network rm
docker context ls --format '{{.Name}}'     | grep '^odt-' | xargs -r docker context rm
```

Expected: all silent or only the intended names.

- [ ] **Step 2: Verify the baseline and the fixtures are restored**

```bash
docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}' > /tmp/odt-manual/containers.after
docker image ls --format '{{.Repository}}:{{.Tag}}' | sort > /tmp/odt-manual/images.after
diff /tmp/odt-manual/containers.before /tmp/odt-manual/containers.after
diff /tmp/odt-manual/images.before /tmp/odt-manual/images.after
docker ps -a --format '{{.Names}}' | grep -c '^odt-'
for c in "$C_RUN1" "$C_RUN2" "$C_STOPPED"; do docker inspect -f '{{.Name}} {{.State.Status}}' "$c"; done
```

Expected: `odt-` count 0; images diff empty except images you deliberately pulled or built (the Task 4 pull, the Task 4/9 builds, the Task 7 workspace image); fixtures in the state recorded in Task 0. Remove those with `docker image rm` before the final diff if you want a byte-identical baseline.

The **containers diff may show the fixtures' changed uptime** if you ran Task 5 Step 8 (`Up 2 seconds` instead of the recorded value). That is expected from a deliberate restart, not a leftover — compare name + image and the three `inspect` lines, not the `Status` text, for the fixtures.

- [ ] **Step 3: Restore shared config and SSH**

```bash
diff <(sort ~/.ssh/config) <(sort /tmp/odt-manual/ssh.config.bak) && echo "ssh ok"
[ -f /tmp/odt-manual/odocker.env.bak ] && diff "$CONFIG_PATH/odocker.env" /tmp/odt-manual/odocker.env.bak && echo "odocker.env ok"
rm -rf /tmp/odt-manual/ws /tmp/odt-manual/ws2 /tmp/odt-manual/compose
```

Expected: `ssh ok`, `odocker.env ok` (skip the second if Task 7 Step 3 was not run).

- [ ] **Step 4: Cross-check the automated suite**

```bash
test.suite run odocker 1
```

Expected: same pass/fail picture as the Task 0 baseline. Any new failure is a regression to investigate.

- [ ] **Step 5: Write the report**

```bash
git status --short
```

Expected: no changes under `odocker`, `test/`, or `$CONFIG_PATH`. The only new file should be this plan (and your results, if you keep them).

---

## Results table

Copy this into your report; one row per task step.

| Task | Step | Command | Expected | Actual | rc | Verdict |
|---|---|---|---|---|---|---|
| 0.3 | automated baseline | `test.suite run odocker 1` / `completion.audit 1` | recorded | | | |
| 1.1 | usage | `odocker` | usage table | | | |
| 2.1 | support | `support.check` | silent, 0 | | | |
| 2.2 | installed | `system.installed` | `missing: compose`, 1 | | | |
| 3.x | inventory | … | tables | | | |
| 3.5 | fixtures observe | `inspect/port/ip/top/log/stats/command.run` on `$C_*` | sane tables | | | |
| 3.6 | fixture stopped | `top`/`command.run` fail, `log`/`stats` work, `ip.get` finding | mixed | | | |
| 3.7 | fixture copy | `copy $C_RUN1:/etc/hostname …` | hostname file | | | |
| 4.x | image | … | … | | | |
| 5.x | container | … | … | | | |
| 5.8 | fixture lifecycle | `start/stop/restart/pause/rename` on `$C_*` | as found | | | |
| 6.x | run/socket | … | … | | | |
| 7.x | workspace | … | … | | | |
| 8.x | net/vol | … | … | | | |
| 9.x | ctx/registry/buildx | … | … | | | |
| 10.x | ssh | … | … | | | |
| 11.x | compose | … | blocked | | | |
| 12.x | negative | … | rc 1 | | | |
| 13.x | cleanup | … | empty diffs | | | |

## Findings template

```
### Finding N — <one line>
Task/step:
Command:
Expected:
Actual (paste, no filtering):
rc:
Reproduce: deterministic / intermittent
Severity: blocker / major / minor / docs
Suspected area (method + line if known):
```

## Known gaps to watch (from `2026-11-16-odocker-safety-and-naming.md`)

Confirm these while testing; they are recent behaviour, not accidents:

- `container.run` mounts the Docker socket **only** with the `docker` argument (Task 6).
- Containers created by odocker carry `odocker=1` and `odocker.container=<name>` labels (Task 5 Step 1). Check the fixtures too in Task 0 Step 2 — they show what the odocker build that created them left behind.
- `container.run`/`create` pass **only** `--name`; the container's host name stays its ID (Task 3 Step 5 on the fixtures, Task 6 Step 1 on scratch).
- `ssh.start` takes the password as a parameter without echoing it (Task 10).
- `prune.all`/`system.prune` are interactive unless `force=yes` (Task 12 Step 4).
- Canonical names `container.list.running`, `container.list.all`, `status.show`, `health.check`, `disk.show` exist and delegate to the old root verbs (see `docs/odocker.md`).

**Reproduced while writing this plan (record your own result):**
- `container.ip.get` on a **stopped** container prints `invalid` and exits **0** on Docker 29, although its docstring promises rc 1. (Task 3 Step 6, Task 12 Step 3.)
- `volume.create` with **no name** exits 0 and creates an anonymous volume, although the signature says `<name>`. (Task 12 Step 1.)

---

## Appendix: method coverage matrix

All public methods of `odocker` on the dev branch (121 at the time of writing) mapped to a task step. `skip` entries state why.

| Method | Where | Method | Where |
|---|---|---|---|
| `buildx.build` | 9.3 | `image.prune` | 4.4 (prompt only) |
| `buildx.create` | 9.3 (optional) | `image.pull` | 4.2 |
| `buildx.inspect` | 9.3 | `image.push` | **skip** — no registry creds |
| `buildx.list` | 9.3 | `image.remove` | 4.3 |
| `buildx.remove` | 9.3 (optional) | `image.tag` | 4.1 |
| `buildx.use` | 9.3 (optional) | `network.connect` | 8.2 |
| `compose.raw` | 11.1, 11.4 | `network.create` | 8.2 |
| `compose.service.build` | 11.4 | `network.disconnect` | 8.2 |
| `compose.service.config` | 11.4 | `network.inspect` | 8.2 |
| `compose.service.copy` | 11.4 | `network.list` | 3.2 |
| `compose.service.create` | 11.4 | `network.prune` | 8.3 (prompt only) |
| `compose.service.down` | 11.3 | `network.remove` | 8.2 |
| `compose.service.events` | 11.4 | `prereqs.install` | **skip** — installs packages; platform tests |
| `compose.service.exec` | 11.4 | `raw` | 12.6 |
| `compose.service.images` | 11.4 | `registry.login` | **skip** — no creds |
| `compose.service.kill` | 11.4 | `registry.logout` | **skip** — no creds |
| `compose.service.list` | 11.1 | `registry.search` | 9.2 |
| `compose.service.logs` | 11.3 | `socket.group.ensure` | 2.3 |
| `compose.service.pause` | 11.4 | `status.show` | 3.3 |
| `compose.service.port` | 11.4 | `support.check` | 2.1 |
| `compose.service.pull` | 11.4 | `system.container.is` | 2.4 |
| `compose.service.push` | 11.4 (expected fail) | `system.events` | 2.4 |
| `compose.service.remove` | 11.4 | `system.info` | 2.3 |
| `compose.service.restart` | 11.3 | `system.installed` | 2.2 |
| `compose.service.run` | 11.4 (TTY) | `system.prune` | 12.3 (**do not run**) |
| `compose.service.start` | 11.4 | `system.version` | 2.3 |
| `compose.service.stop` | 11.3 | `volume.create` | 8.1 |
| `compose.service.top` | 11.4 | `volume.inspect` | 8.1 |
| `compose.service.unpause` | 11.4 | `volume.list` | 3.2 |
| `compose.service.up` | 11.4 (TTY) | `volume.prune` | 8.3 (prompt only) |
| `compose.service.up.detached` | 11.3 | `volume.remove` | 8.1 |
| `compose.service.version` | 11.1 | `workspace.build` | 7.2 |
| `compose.service.wait` | 11.4 | `workspace.build.all` | 7.4 (long) |
| `compose.start` | 11.4 | `workspace.get` | 7.1 |
| `compose.status.show` | 11.1, 11.3 | `workspace.init` | 7.3 |
| `compose.stop` | 11.4 | `workspace.install` | 7.4 |
| `container.clone` | 5.7 | `workspace.list` | 7.1 |
| `container.command.run` | 3.5, 3.6, 5.3 | `workspace.push` | **skip** — remote Host |
| `container.copy` | 3.7, 5.4 | `workspace.rebuild` | 7.4 |
| `container.create` | 5.1, 12.2 | `workspace.seed` | **skip** — network/remote |
| `container.docker.install` | 10.6 (side effect) | `workspace.set` | 7.3 |
| `container.enter` | 6.4 | `context.create` | 9.1 |
| `container.exec` | 6.4 | `context.list` | 3.2, 9.1 |
| `container.inspect` | 3.5, 5.2 | `context.remove` | 9.1 |
| `container.ip.get` | 3.5, 3.6, 12.3 | `context.use` | 9.1 |
| `container.kill` | 5.5, 5.8 | `disk.show` | 2.4 |
| `container.list.all` | 3.1 | `dockerfile.find` | 3.4 |
| `container.list.running` | 3.1 | `health.check` | 3.3 |
| `container.log.show` | 3.5, 3.6, 5.5 | `image.build` | 4.6 |
| `container.oosh.install` | **skip** — installs oosh; platform tests | `image.command.run` | 4.5 |
| `container.pause` | 5.5, 5.8 | `image.history` | 4.1 |
| `container.port.show` | 3.5, 5.2 | `image.inspect` | 4.1 |
| `container.prune` | 12.5 | `image.list` | 3.2 |
| `container.prune.all` | 12.4 (prompt only) | | |
| `container.remove` | 5.6 | | |
| `container.rename` | 5.5, 5.8, 12.3 | | |
| `container.reset` | 5.7 | | |
| `container.restart` | 5.5, 5.8 | | |
| `container.run` | 6.1–6.2 | | |
| `container.run.sshd` | 10.6 | | |
| `container.ssh.prune` | 10.4 | | |
| `container.ssh.start` | 10.1 | | |
| `container.start` | 5.2, 5.8 | | |
| `container.stats` | 3.5, 5.9 | | |
| `container.stop` | 5.6, 5.8 | | |
| `container.top` | 3.5, 5.2 | | |
| `container.unpause` | 5.5, 5.8 | | |
| `container.update` | 5.7 | | |

