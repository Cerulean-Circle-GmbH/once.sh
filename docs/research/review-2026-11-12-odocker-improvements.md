# Review: `odocker` — naming and improvement plan

**Status:** research — report only, nothing changed.
**Date:** 2026-11-12
**Scope:** the `odocker` script (3281 lines, 85 public methods, 64 private helpers) and its test/docs.
**Triggered by:** “how can we improve odocker” / “how can we improve this naming”, after the 2026-10-28 repo and test-suite audits.
**Baseline:** `test/test.odocker` is **171/171** and `test.completion.audit` is **0 failures** on `dev`. These are quality, security and API-clarity improvements, not red-test fixes.
**Related:** [repo audit 2026-10-28](review-2026-10-28-repo-audit.md) · [test-suite audit 2026-10-28](review-2026-10-28-test-suite-audit.md)

---

## 1. What is already good

Do not churn these; they follow `script.object.verb` and read clearly:

```
odocker.workspace.init / seed / push / install / get / set / list
odocker.support.check
odocker.socket.group.ensure
odocker.prereqs.install
odocker.container.ip.get
odocker.container.ssh.start / prune
odocker.container.oosh.install
odocker.image.list
odocker.usage / start   (documented dispatcher exceptions)
```

---

## 2. Naming: what to fix

The rule is `script.<object>.<object>.verb[.<more.words>]` — camelCase, dots, no dashes/underscores, verb after the object. `script.verb` is legal but ambiguous when the object is not obvious.

### 2.1 Nouns with no verb

| Current | Problem | Proposed |
|---|---|---|
| `odocker.status` | noun only | `odocker.status.show` |
| `odocker.lifecycle` | noun only | `odocker.health.check` |
| `odocker.disk` | noun only | `odocker.disk.show` |
| `odocker.list` | noun/verb, and it means images | drop it; `odocker.image.list` exists |
| `odocker.ps` | abbreviation | `odocker.container.list.running` |
| `odocker.list.running` | generic object | `odocker.container.list.running` |

### 2.2 Root verbs without an explicit object

Legal as `odocker.verb`, but the reader cannot tell what is acted on.

| Current | Proposed |
|---|---|
| `odocker.run <image>` | `odocker.container.run <image>` |
| `odocker.run.sshd` | `odocker.container.run.sshd` |
| `odocker.build <workspace>` | `odocker.workspace.build <workspace>` |
| `odocker.build.all` | `odocker.workspace.build.all` |
| `odocker.rebuild <workspace>` | `odocker.workspace.rebuild` |
| `odocker.reset <image>` | `odocker.container.reset` |
| `odocker.clone <container>` | `odocker.container.clone` |
| `odocker.stop` | `odocker.container.stop` (already exists) |
| `odocker.prune <container>` | `odocker.container.prune` |
| `odocker.prune.all` | `odocker.system.prune` — it removes images, volumes and networks too |
| `odocker.exec <container>` | `odocker.container.exec` |
| `odocker.exec.command` | `odocker.container.command.run` (or `container.exec.run`) |
| `odocker.enter <container>` | `odocker.container.enter`, or fold into `container.exec` |
| `odocker.log <container>` | `odocker.container.log.show` |
| `odocker.install <container>` | `odocker.container.docker.install` (it installs the Docker CLI there) |
| `odocker.image.command <image> <cmd>` | `odocker.image.command.run` |
| `odocker.compose <?service>` | `odocker.compose.status.show` |
| `odocker.up` / `odocker.down` | `odocker.compose.start` / `odocker.compose.stop` |

`odocker.container.list` is also ambiguous (all or running?) — use `container.list.all` and `container.list.running`.

### 2.3 Aliases and deprecated names

| Current | Verdict |
|---|---|
| `odocker.create` | remove; `container.create` is the name |
| `odocker.rm` | remove; `container.remove` |
| `odocker.rmi` | remove; `image.remove` |
| `odocker.list` | remove; `image.list` |
| `odocker.ps` | alias only, or remove; `container.list.running` |
| `odocker.stop` | alias only; `container.stop` |
| `odocker.list.running` | alias only; `container.list.running` |

### 2.4 Parameter names

| Current | Proposed | Why |
|---|---|---|
| `<?docker>` (`run`, `run.sshd`, `reset`, `clone`, `up`) | `<?withDocker:no>` | “docker” does not say mount the socket / install the CLI |
| `<?lines:50>` (`log`) | `<?lineCount:50>` | camelCase, explicit |
| `<?from>` (`workspace.seed`) | `<?source>` | clearer |
| `<?path>` (`workspace.*`) | `<?workspacePath>` | distinguishes from other paths |
| `<container>`, `<image>`, `<portOrOffset:0>`, `<?toHost>` | keep | clear |

### 2.5 Migration

1. Add the canonical name as the implementation, keep the old name as a one-line alias.
2. Mark the old one `# @DEPRECATED — use …` in the docstring; `c2`/help then says so.
3. Update `test/test.odocker`, completions and `docs/odocker.md` in the same commit.
4. Remove an alias with `oo method.delete` when nothing calls it; one release is enough.

---

## 3. Correctness and security

### 3.1 `odocker.run` ignores its `<?docker>` and always mounts the host socket — **fix first**

`odocker.run` (`odocker:1861`) declares `<?docker>` but never reads it, then always adds:

```bash
-v /var/run/docker.sock:/var/run/docker.sock   # odocker:1871
docker run -it $nameOpt $dockerOpt "$image" bash
```

Mounting the host socket is root-equivalent host access. Either:

- honour the argument — mount only when `odocker run <image> <name> docker`, as `run.sshd` does; or
- remove the parameter and document that the socket is always mounted.

Today the signature promises a choice the code does not give.

### 3.2 Password handling in `private.odocker.container.sudo.nopasswd`

`odocker:2236`:

```bash
ossh exec "$name" "echo '$password' | sudo -S sh -c '…'"
```

- the password appears in the remote process list/argv;
- a `'` in the password breaks the command;
- it is echoed into the remote shell.

Use stdin instead:

```bash
printf '%s\n' "$password" | ossh exec "$name" 'sudo -S sh -c …'
```

and test a password containing spaces and quotes.

Also `container.ssh.start` defaults `password="${5:-$user}"` (`odocker:2284`) — a password equal to the username is a weak default. Generate one and print it, or require it.

### 3.3 Port allocation is check-then-run

`container.ssh.start` checks `private.odocker.ports.get` (`odocker:2295–2302`) and starts at `:2305`. Two terminals choosing the same offset both pass the check. Add a per-offset lock or retry on Docker’s `port is already allocated`, then re-check.

### 3.4 `prune.all` is host-wide

`odocker.prune.all` already asks for confirmation (`odocker:3135`), but it runs `docker system prune -a --volumes`, affecting containers/images/volumes/networks **not created by odocker**. Add:

- labels on containers odocker creates (`--label odocker=1`, `--label odocker.workspace=<name>`), then prune only odocker-owned objects;
- `--force` / `OOSH_YES` for non-interactive use, so the destructive path can be tested.

Today only build labels exist (`odocker:1848`), not runtime labels.

### 3.5 Docker failure propagation

32 `docker exec` calls and many `2>/dev/null` sites; `docker stop`/`rm` in `container.ssh.start` (`odocker:2303`, `:2305`) ignore failures. Return `RESULT`/rc, and keep the existing partial cleanup for half-created containers.

---

## 4. Portability, remote engines, performance

### 4.1 `DOCKER_HOST` / rootless is not supported

`private.odocker.socket.get` (`odocker:513`) hardcodes `/var/run/docker.sock`; `DOCKER_HOST` has 0 hits. `DOCKER_HOST=ssh://…` or `unix:///run/user/…/docker.sock` is ignored, while `-v /var/run/docker.sock` assumes a local engine. Either support the standard env or document “local socket only”.

### 4.2 Table parsing and `column`

18 uses of `column`; `container.list` does one `private.odocker.container.ports` per container (`odocker:1545–1556`) and parses `docker ps` text. Prefer one `docker ps --format '{{json .}}'` / `docker inspect`, format in bash, and make `jq` optional (it is only used for auth at `odocker:1756`). The GNU `stat -c %g` inside a container (`odocker:801`) has no BSD/BusyBox fallback — use `this.path.stat.get` or a `stat -f` branch.

### 4.3 Build options

`build.all` has no `--platform`, `--build-arg`, `--pull`, cache control or proxy pass-through. Add:

```
ODOCKER_PLATFORM, ODOCKER_BUILD_ARGS,
HTTP_PROXY / HTTPS_PROXY build args, docker build --pull
```

This also answers the proxy question for images.

### 4.4 Security defaults for started containers

No `--cap-drop`, `--security-opt no-new-privileges`, `--init`, memory/CPU limits. For `sshd` containers add at least `--security-opt no-new-privileges` and the minimal capability set; for interactive `run`, add `--init` and consider `--rm` (today an interactive container is left behind).

### 4.5 Performance / structure

3281 lines, 85 public / 64 private. Batch `docker ps`/`inspect`, cache image/container lists per call, and avoid `docker exec` in loops (32 sites). Extract the repeated “container → name/ports/status” parsing into one private helper. Keeping one script per class is the OOSH convention; the private family is large enough to justify shared helpers.

---

## 5. Docs and tests

### 5.1 `docs/odocker.md` is stale

It documents **20 methods that no longer exist** (`odocker.container.ip`, `odocker.env`, `odocker.socket.access`, …) and **omits 10 public methods** that do:

```
workspace.push, support.check, socket.group.ensure,
container.ssh.start, container.oosh.install, container.ssh.prune,
container.stop, container.create, usage, start
```

Regenerate the matrix from the code (or hand-fix it); the doc is not a reliable API reference today.

### 5.2 Nine public methods have no named test

```
file.find, build.all, stop, container.stop, log,
status, disk, prune.all, usage
```

Add stubbed-`docker` tests, especially `stop`, `prune.all`, `status`, `disk`, `log` (destructive and parsing paths). `prune.all` needs `--force`/`OOSH_YES` first.

### 5.3 Run the suite in the container too

`test.odocker` passes on the host. The socket-group changes, `/var/run/docker.sock` mount, `sshpass` login and `prune` paths differ inside a container; run `test.odocker` in the platform container as well, not only on the host.

### 5.4 Small cleanups

- `# @TODO [ ] odocker.workspace.seed.completion.from()` at `odocker:222` is stale; the function below it is `odocker.parameter.completion.from`.
- `sshpass` is fetched on demand (`oo cmd sshpass`, `odocker:2203`) but is not in `prereqs.ensure` (only `docker`/`column`, `:398`). Document it or add it.
- `jq` is only optional for the auth path (`:1756`); say so.

---

## 6. Suggested order

1. `run` socket opt-in, password over stdin + quoting, port race.
2. Runtime labels + Docker failure propagation; make `prune.all` forceable and odocker-scoped.
3. Regenerate `docs/odocker.md`; add tests for the 9 untested commands.
4. `DOCKER_HOST`/rootless, batched `docker inspect`/JSON parsing, `column`/`stat` portability.
5. Build platform/proxy args, security defaults, compose project names.
6. Naming migration: fix aliases first (`ps`, `list`, `rm`, `rmi`, `create`), then give `status`/`lifecycle`/`disk` a verb, then qualify the root verbs with `container`/`workspace`.

The naming changes are API-breaking; keep the old names as deprecated one-line aliases for one release and update tests/docs/completions in the same commit.

---

## 7. Full public surface (51 commands, excluding completions)

**Workspaces:** `workspace.init`, `workspace.seed`, `workspace.push`, `workspace.install`, `workspace.get`, `workspace.set`, `workspace.list`

**Prerequisites/socket:** `support.check`, `socket.group.ensure`, `prereqs.install`

**Images/build:** `build`, `build.all`, `rebuild`, `image.list`, `list`, `image.command`, `image.remove`, `rmi`, `file.find`

**Containers:** `ps`, `list.running`, `container.list`, `run`, `run.sshd`, `container.create`, `create`, `reset`, `clone`, `stop`, `container.stop`, `container.remove`, `rm`, `prune`, `prune.all`, `exec`, `exec.command`, `enter`, `log`, `status`, `lifecycle`, `disk`, `install`, `container.ip.get`

**SSH-ready containers:** `container.ssh.start`, `container.oosh.install`, `container.ssh.prune`

**Compose:** `compose`, `up`, `down`

**Entry/help:** `usage`, `start`

---

## 8. Other Docker entry points (outside `odocker`)

The list above is the complete **odocker** command surface, not every Docker operation in the application. These commands also drive Docker:

| Command | Signature | Docker role |
|---|---|---|
| `platform.test` | `<platform> <?terminal> <?notests>` | Linux platforms: `odocker reset` / `run.sshd`, install oosh in the container, run `test.suite gate 1` as four users; `terminal` opens a shell in the container. macOS uses the GitHub workflow instead |
| `platform.test.all` | — | `platform.test` for every must-pass platform, with a summary |
| `platform.parse.check` | `<?platform:almalinux_9> <?dir:$OOSH_DIR>` | `bash -n` on every tracked shell file inside a throwaway container (`odocker image.command`) |
| `platform.list` | — | Lists the platform images/tiers (inventory, no container lifecycle) |
| `setup.docker` | `<?user:$SUDO_USER>` | Installs the Docker engine/client and joins the socket group, via `odocker prereqs.install`; skipped where Docker cannot run |
| `setup.all` | `<?user:$SUDO_USER>` | Includes `setup.docker` with the other install-state-50 steps |
| `user group.member.pending` | `<group> <?user>` | Socket-group precondition check `odocker` calls (group DB vs current process) |
| `ossh login` / `ossh exec` | `<host> …` | Not Docker itself, but the supported way into containers started by `odocker.container.ssh.start` |
| raw `docker` / `docker compose` | — | Unwrapped; `odocker` uses them internally, and anything outside the wrapper needs the plain CLI |

So:

- **All `odocker` commands:** 51, listed in §7.
- **All Docker-related commands in the application:** those 51 **plus** `platform.test`, `platform.test.all`, `platform.parse.check`, `platform.list`, `setup.docker`, `setup.all`, and the `user` / `ossh` helpers above.

The 64 `private.*` helpers and 34 `*.completion.*` functions are not commands and are intentionally excluded.


---

## 9. Proposed names — public and private

### 9.1 Public canonical set (45 commands)

| Command | Parameters | Detail |
|---|---|---|
| `odocker.workspace.init` | `<?workspacePath>` | Create the Docker workspaces root if absent, share it with group dev, and set it for every user of the host |
| `odocker.workspace.seed` | `<?source> <?workspacePath>` | Fill the workspace root from a folder, an ossh Host or a URL; missing units are added, differing ones replaced only after a yes |
| `odocker.workspace.push` | `<?toHost> <?image> <?workspacePath>` | Bring all workspaces, or one image's workspace, to another host |
| `odocker.workspace.install` | `<?workspacePath>` | Give this host its workspace root and the shared `odocker.env` that names it |
| `odocker.workspace.get` | `<?workspacePath>` | Report the workspace root and whether it is usable |
| `odocker.workspace.set` | `<?workspacePath>` | Set and persist the workspace root for every user of the host |
| `odocker.workspace.list` | — | List all Dockerfile workspaces and their build status |
| `odocker.workspace.build` | `<workspace>` | Build the image of one workspace from its Dockerfile |
| `odocker.workspace.build.all` | — | Build every workspace that has a Dockerfile |
| `odocker.workspace.rebuild` | `<workspace>` | Remove the old image and rebuild it from its Dockerfile |
| `odocker.support.check` | — | rc 0 when Docker can work here; rc 1 and the reason on stdout when it cannot |
| `odocker.socket.group.ensure` | `<?socket>` | Echo the group owning the Docker socket, creating it when no group has its number |
| `odocker.prereqs.install` | `<?user>` | Install `docker`/`column` and join the user, or every eligible user, to the socket group |
| `odocker.image.list` | — | List all images |
| `odocker.image.remove` | `<image>` | Remove an image |
| `odocker.image.command.run` | `<image> <command...>` | Run one command in a throwaway container of the image, stdin passed in, removed afterwards |
| `odocker.dockerfile.find` | `<?containerOrImage>` | Find the Dockerfile that built a container or image; no arg lists containers and images as a discovery aid |
| `odocker.container.create` | `<image> <?name>` | Create a container without starting it |
| `odocker.container.remove` | `<container>` | Remove a stopped container and the SSH Host that `container.ssh.start` made for it |
| `odocker.container.ip.get` | `<container>` | Echo the IP address of a running container on its first network |
| `odocker.container.list.all` | — | List all containers, running and stopped |
| `odocker.container.list.running` | — | List running containers |
| `odocker.container.run` | `<image> <?name> <?withDocker:no>` | Run an interactive container from an image; `withDocker` mounts the host Docker socket |
| `odocker.container.run.sshd` | `<image> <?name> <?portOrOffset:0> <?withDocker:no>` | Run a detached container with SSH and HTTP ports mapped |
| `odocker.container.reset` | `<image> <?portOrOffset:0> <?withDocker:no> <?name>` | Stop and remove the container on the ports, clear its host key, and start a fresh one |
| `odocker.container.clone` | `<container> <?portOrOffset:0> <?withDocker:no>` | Clone a container's filesystem state onto different ports |
| `odocker.container.stop` | `<container>` | Stop a running container |
| `odocker.container.prune` | `<container>` | Remove a stopped container and its image |
| `odocker.container.exec` | `<container> <?shell>` | Open an interactive shell inside a running container |
| `odocker.container.command.run` | `<container> <command...>` | Run a non-interactive command inside a running container, without a TTY |
| `odocker.container.enter` | `<container> <?shell:bash>` | Enter a running container (interactive shell); kept as the human-facing name for exec |
| `odocker.container.log.show` | `<container> <?lineCount:50>` | Show the container's logs, at most the given number of lines |
| `odocker.container.docker.install` | `<container>` | Install the Docker CLI inside a running container |
| `odocker.container.ssh.start` | `<image> <?name> <?portOrOffset:0> <?user> <?password>` | Start a container with sshd, create its SSH Host, and push your key; ready for `ossh login` |
| `odocker.container.oosh.install` | `<image> <?name> <?portOrOffset:0> <?user> <?password>` | `container.ssh.start`, then install oosh for the user so `ossh login` lands in the oosh shell |
| `odocker.container.ssh.prune` | — | Remove SSH Hosts of containers that no longer exist |
| `odocker.system.prune` | `<?force:no>` | Remove unused containers, images, volumes and networks system-wide; asks unless `force` is given |
| `odocker.status.show` | — | Show a Docker overview: images, containers and disk usage |
| `odocker.health.check` | — | Check the health of containers, images and compose services |
| `odocker.disk.show` | — | Show Docker disk usage details |
| `odocker.compose.status.show` | `<?service>` | Show compose status, or the details of one service |
| `odocker.compose.start` | `<container> <?portOrOffset:0> <?withDocker:no>` | Start a container, run an image, or start a compose service |
| `odocker.compose.stop` | `<container>` | Stop a container or compose service |
| `odocker.usage` | — | Print the odocker usage table |
| `odocker.start` | — | Dispatcher: source `this`, `os`, `ossh` and route the method |

### 9.2 Old names to keep as deprecated aliases for one release

```
odocker.ps                 → odocker.container.list.running
odocker.list.running       → odocker.container.list.running
odocker.container.list     → odocker.container.list.all
odocker.list               → odocker.image.list
odocker.create             → odocker.container.create
odocker.rm                 → odocker.container.remove
odocker.rmi                → odocker.image.remove
odocker.run                → odocker.container.run
odocker.run.sshd           → odocker.container.run.sshd
odocker.build              → odocker.workspace.build
odocker.build.all          → odocker.workspace.build.all
odocker.rebuild            → odocker.workspace.rebuild
odocker.reset              → odocker.container.reset
odocker.clone              → odocker.container.clone
odocker.stop               → odocker.container.stop
odocker.prune              → odocker.container.prune
odocker.prune.all          → odocker.system.prune
odocker.exec               → odocker.container.exec
odocker.exec.command       → odocker.container.command.run
odocker.enter              → odocker.container.enter
odocker.log                → odocker.container.log.show
odocker.install            → odocker.container.docker.install
odocker.image.command      → odocker.image.command.run
odocker.file.find          → odocker.dockerfile.find
odocker.compose            → odocker.compose.status.show
odocker.up                 → odocker.compose.start
odocker.down               → odocker.compose.stop
odocker.status             → odocker.status.show
odocker.lifecycle          → odocker.health.check
odocker.disk               → odocker.disk.show
```

### 9.3 Private helpers

No private *rename* is proposed: private helpers stay `private.odocker.<same path>`, and a new helper for a renamed public method takes the same suffix (for example `private.odocker.container.run`, `private.odocker.container.log.show`).

The 64 existing private helpers, grouped:

```
compose.file.find
compose.file.in
compose.services
container.list.all
container.list.findable
container.list.running
container.name
container.name.new
container.ports
container.prereqs.install
container.repo.add
container.ssh.config
container.ssh.forget
container.ssh.host.is
container.ssh.master
container.ssh.port.get
container.ssh.undo
container.sshd.reload
container.sudo.nopasswd
docker.config.keyless
docker.registry
docker.repo.add
docker.repo.download
docker.repo.get
docker.socket.opt
engine.start
engine.supported
env.chained
image.list
image.list.findable
image.list.sshd
image.local.ensure
image.resolve.from.workspace
image.sshd.is
image.user.get
passwd.users.get
port.offset
port.user.get
ports.get
prereq.package.get
prereqs.ensure
resolve.image
socket.access.ensure
socket.get
socket.gid.check
socket.group.ensure
ssh.hosts.local.get
terminal.is
workspace.list
workspaces.default.get
workspaces.entry.same
workspaces.fetch.ssh
workspaces.fetch.url
workspaces.host.path.get
workspaces.legacy.path.get
workspaces.merge
workspaces.merge.answer.get
workspaces.mine
workspaces.push.files.get
workspaces.push.filter
workspaces.push.image.get
workspaces.push.select
workspaces.source.host.get
workspaces.source.url.get
```

(All are prefixed with `private.odocker.`.)
