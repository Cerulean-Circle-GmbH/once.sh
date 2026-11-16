# odocker Safety and Naming — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the highest-value `odocker` safety/correctness gaps and start the naming migration without changing behaviour for existing callers.

**Architecture:** `odocker` stays one script (one class) with `private.odocker.*` helpers. Each task adds a test to `test/test.odocker`, makes the smallest code change, and keeps the old public names working. Naming migration is additive: canonical names are new thin wrappers over the existing implementation; old names stay until a later phase deletes them.

**Tech Stack:** bash 4+, OOSH (`this`, `log`, `config`), `test.suite` (`test.case`, `expect`, `create.result`, fixtures), Docker CLI (stubbed in tests), `git`.

**Scope:** Phase 1 = run socket opt-in, password over stdin, runtime labels, `prune.all` force, and five safe naming aliases. Phase 2 (separate plan): port-allocation lock, `DOCKER_HOST`/rootless, batched inspect/JSON parsing, build platform/proxy, security defaults, compose project names, the rest of the naming aliases, and the docs regeneration.

**Reference:** `docs/research/review-2026-11-12-odocker-improvements.md` §2–§9.

---

## File structure

- Modify: `odocker` — `odocker.run` (~1861), `private.odocker.container.sudo.nopasswd` (~2226), `odocker.create`/`odocker.run`/`odocker.run.sshd` (labels), `odocker.prune.all` (~3118), new canonical wrappers near the existing methods.
- Modify: `test/test.odocker` — one test function + `test.case`/`expect` per task.
- No new files. `docs/odocker.md` is left to Phase 2 (it needs the full regeneration, not a hand edit).

---

### Task 1: `odocker.run` mounts the host Docker socket only when asked

**Files:**
- Modify: `odocker` — `odocker.run()` at ~1861-1886
- Test: `test/test.odocker` — insert after the `T-ODOCKER-RUN-NO-HOSTNAME` block (~1640)

- [x] **Step 1: Write the failing test**

```bash
# T-ODOCKER-RUN-SOCKET-OPT: `docker run` mounts the host socket only with the
# docker argument; the optional parameter promised that choice and ignored it.
test.odocker.runSocketOpt() {
  local fx bad="" out
  fx=$(test.suite.fixture.make odockerrun) || { create.result 1 "mktemp failed"; return $(result); }

  out=$(FX="$fx" bash -c '
    source "$OOSH_DIR/this" >/dev/null 2>&1
    source "$OOSH_DIR/odocker" >/dev/null 2>&1
    private.odocker.image.local.ensure() { return 0; }
    private.odocker.container.name.new() { :; }
    docker() { echo "$*" >> "$FX/calls"; return 0; }
    odocker.run naked_ubuntu_24_04 box
    odocker.run naked_ubuntu_24_04 box docker
  ' 2>/dev/null)

  sed -n '1p' "$fx/calls" | grep -q -- '-v /var/run/docker.sock:/var/run/docker.sock' \
    && bad="$bad plain-mounted"
  sed -n '2p' "$fx/calls" | grep -q -- '-v /var/run/docker.sock:/var/run/docker.sock' \
    || bad="$bad docker-missing"
  rm -rf "$fx"

  if [ -z "$bad" ]; then
    create.result 0 "socket mounted only with docker"
  else
    create.result 1 "run socket:$bad"
  fi
  return $(result)
}
test.case $level "T-ODOCKER-RUN-SOCKET-OPT: the host docker socket is mounted only when run is told to" test.odocker.runSocketOpt
expect 0 "socket mounted only with docker" "odocker run always mounted the host docker socket, ignoring its <?docker>"
```

Insert the block after the `expect 0 "run, run.sshd and create pass only --name" "a container's host name was its name, not its ID"` line in `test/test.odocker`.

- [x] **Step 2: Run the test to verify it fails**

```bash
./test.suite run odocker 1
```

Expected: `T-ODOCKER-RUN-SOCKET-OPT` fails with `run socket: plain-mounted` (both calls contain `-v /var/run/docker.sock`).

- [x] **Step 3: Implement**

Replace `odocker.run` with:

```bash
odocker.run() # <image> <?name> <?withDocker:no> # run container from image; withDocker=docker mounts the host Docker socket
{
  local image="$1"
  if [ -z "$image" ]; then
    echo "Usage: odocker run <image> <?name> <?withDocker:no>"
    return 1
  fi
  shift
  local name="$1"
  shift 2>/dev/null
  # `docker` is the old word; withDocker accepts it for compatibility.
  local withDocker="$1"
  local dockerOpt=""
  if [ "$withDocker" = "docker" ] || [ "$withDocker" = "yes" ]; then
    dockerOpt=$(private.odocker.docker.socket.opt)
  fi

  # A missing image first, through the keychain-aware helper: name.new below
  # already creates a container of it (T-ODOCKER-IMAGE-LOCAL-ENSURE).
  private.odocker.image.local.ensure "$image" || return $?
  # Unnamed: odocker names it. Only --name: the host name stays the ID, the
  # name reaches the container through the socket (T-ODOCKER-RUN-NO-HOSTNAME).
  [ -n "$name" ] || name=$(private.odocker.container.name.new "$image")
  local nameOpt=""
  if [ -n "$name" ]; then
    nameOpt="--name $name"
  fi

  console.log "Running image: $image"
  docker run -it $nameOpt $dockerOpt "$image" bash
}
```

Add the completion for the renamed parameter next to the existing `docker` one:

```bash
odocker.parameter.completion.withDocker() { printf '%s\n' no docker; }
```

- [x] **Step 4: Run the test to verify it passes**

```bash
./test.suite run odocker 1
```

Expected: `T-ODOCKER-RUN-SOCKET-OPT` passes; the rest of `test.odocker` stays green.

- [x] **Step 5: Verify the completion audit**

```bash
./test.suite run completion.audit 1
```

Expected: pass (the new `withDocker` parameter has its completion).

- [x] **Step 6: Commit**

```bash
git add odocker test/test.odocker
git commit -m "fix(odocker): run mounts the docker socket only when asked"
```

---

### Task 2: Container sudo password goes over stdin, not the remote command line

**Files:**
- Modify: `odocker` — `private.odocker.container.sudo.nopasswd()` at ~2226-2241
- Test: `test/test.odocker` — insert after the container-SSH test block (~2995)

- [x] **Step 1: Write the failing test**

```bash
# T-ODOCKER-SUDO-PASSWORD-STDIN: the install password is sent on stdin, never
# in the remote argv (where ps and a quote in the password can see it).
test.odocker.sudoPasswordStdin() {
  local fx bad="" out
  fx=$(test.suite.fixture.make odockersudo) || { create.result 1 "mktemp failed"; return $(result); }

  out=$(PASS="p@ss w0rd'quote" FX="$fx" bash -c '
    source "$OOSH_DIR/this" >/dev/null 2>&1
    source "$OOSH_DIR/odocker" >/dev/null 2>&1
    ossh() { printf "%s\n" "$*" >> "$FX/argv"; cat > "$FX/stdin"; return 0; }
    private.odocker.container.sudo.nopasswd box test "$PASS"
  ' 2>/dev/null)

  grep -q 'p@ss' "$fx/argv" && bad="$bad password-in-argv"
  grep -qx "p@ss w0rd'quote" "$fx/stdin" || bad="$bad password-not-on-stdin"
  grep -q 'NOPASSWD' "$fx/argv" || bad="$bad rule-missing"
  rm -rf "$fx"

  if [ -z "$bad" ]; then
    create.result 0 "password on stdin, rule on argv"
  else
    create.result 1 "sudo password:$bad"
  fi
  return $(result)
}
test.case $level "T-ODOCKER-SUDO-PASSWORD-STDIN: the sudo password is not in the remote command" test.odocker.sudoPasswordStdin
expect 0 "password on stdin, rule on argv" "the password was echoed into the remote shell and broke on a quote"
```

- [x] **Step 2: Run the test to verify it fails**

```bash
./test.suite run odocker 1
```

Expected: `T-ODOCKER-SUDO-PASSWORD-STDIN` fails with `password-in-argv` and `password-not-on-stdin`.

- [x] **Step 3: Implement**

Replace the append block in `private.odocker.container.sudo.nopasswd`:

```bash
  # Appended, so it is the last rule: it must win over %wheel on Alpine.
  local rule="$user ALL=(ALL) NOPASSWD: ALL"
  if ! printf '%s\n' "$password" | ossh exec "$name" "sudo -S sh -c 'echo \"$rule\" >> /etc/sudoers'" >/dev/null 2>&1; then
    create.result 1 "could not give $user sudo without a password on $name"
    return $(result)
  fi
```

- [x] **Step 4: Run the test to verify it passes**

```bash
./test.suite run odocker 1
```

Expected: pass, including the existing `NOPASSWD` assertion in `test.odocker.containerSshStart`.

- [x] **Step 5: Commit**

```bash
git add odocker test/test.odocker
git commit -m "fix(odocker): send the container sudo password on stdin"
```

---

### Task 3: Label every container odocker creates

**Files:**
- Modify: `odocker` — `odocker.create()` (~2558), `odocker.run()` (~1861), `odocker.run.sshd()` (~1888)
- Test: `test/test.odocker` — insert after Task 1's test

- [x] **Step 1: Write the failing test**

```bash
# T-ODOCKER-RUNTIME-LABELS: odocker-created containers carry an ownership
# label, so list/prune can tell them from unrelated containers.
test.odocker.runtimeLabels() {
  local fx bad="" out
  fx=$(test.suite.fixture.make odockerlabels) || { create.result 1 "mktemp failed"; return $(result); }

  out=$(FX="$fx" bash -c '
    source "$OOSH_DIR/this" >/dev/null 2>&1
    source "$OOSH_DIR/odocker" >/dev/null 2>&1
    private.odocker.image.local.ensure() { return 0; }
    private.odocker.container.name() { echo box; }
    docker() { echo "$*" >> "$FX/calls"; [ "$1" = create ] && echo cid0; return 0; }
    odocker.create naked_ubuntu_24_04 box
  ' 2>/dev/null)

  grep -q -- '--label odocker=1' "$fx/calls" || bad="$bad no-owner-label"
  grep -q -- '--label odocker.container=box' "$fx/calls" || bad="$bad no-name-label"
  declare -f odocker.run | grep -q -- '--label odocker=1' || bad="$bad run"
  declare -f odocker.run.sshd | grep -q -- '--label odocker=1' || bad="$bad run-sshd"
  rm -rf "$fx"

  if [ -z "$bad" ]; then
    create.result 0 "labels on create, run and run.sshd"
  else
    create.result 1 "labels:$bad"
  fi
  return $(result)
}
test.case $level "T-ODOCKER-RUNTIME-LABELS: every container odocker creates is labelled" test.odocker.runtimeLabels
expect 0 "labels on create, run and run.sshd" "odocker containers were indistinguishable from unrelated ones"
```

- [x] **Step 2: Run the test to verify it fails**

```bash
./test.suite run odocker 1
```

Expected: `T-ODOCKER-RUNTIME-LABELS` fails with `no-owner-label`.

- [x] **Step 3: Implement**

In `odocker.create`, after `nameOpt`:

```bash
  local labelOpt="--label odocker=1"
  [ -n "$name" ] && labelOpt="$labelOpt --label odocker.container=$name"
```

and change the create call:

```bash
  cid=$(docker create $nameOpt $labelOpt "$image")
```

In `odocker.run`, after `nameOpt`:

```bash
  local labelOpt="--label odocker=1"
  [ -n "$name" ] && labelOpt="$labelOpt --label odocker.container=$name"
```

and change the run call:

```bash
  docker run -it $nameOpt $labelOpt $dockerOpt "$image" bash
```

In `odocker.run.sshd`, after `nameOpt`:

```bash
  local labelOpt="--label odocker=1"
  [ -n "$name" ] && labelOpt="$labelOpt --label odocker.container=$name"
```

and add `$labelOpt` to the inner `docker run -d`:

```bash
    docker run -d \
      $nameOpt \
      $labelOpt \
      $dockerOpt \
```

- [x] **Step 4: Run the test to verify it passes**

```bash
./test.suite run odocker 1
```

Expected: pass.

- [x] **Step 5: Commit**

```bash
git add odocker test/test.odocker
git commit -m "feat(odocker): label every container it creates"
```

---

### Task 4: `prune.all` can run non-interactively with `force`

**Files:**
- Modify: `odocker` — `odocker.prune.all()` at ~3118-3144
- Test: `test/test.odocker` — insert after Task 3's test

- [x] **Step 1: Write the failing test**

```bash
# T-ODOCKER-PRUNE-FORCE: force=yes skips the prompt for scripts; no input
# still aborts, so the destructive path is both testable and safe.
test.odocker.pruneForce() {
  local fx bad="" out
  fx=$(test.suite.fixture.make odockerprune) || { create.result 1 "mktemp failed"; return $(result); }

  out=$(FX="$fx" bash -c '
    source "$OOSH_DIR/this" >/dev/null 2>&1
    source "$OOSH_DIR/odocker" >/dev/null 2>&1
    docker() { echo "$*" >> "$FX/calls"; return 0; }
    odocker.prune.all yes
  ' 2>/dev/null)
  grep -qx 'system prune -a --volumes -f' "$fx/calls" || bad="$bad forced-did-not-prune"

  out=$(printf 'n\n' | FX="$fx" bash -c '
    source "$OOSH_DIR/this" >/dev/null 2>&1
    source "$OOSH_DIR/odocker" >/dev/null 2>&1
    docker() { echo "$*" >> "$FX/calls"; return 0; }
    odocker.prune.all
  ' 2>/dev/null)
  case "$out" in *Aborted*) ;; *) bad="$bad no-abort" ;; esac
  rm -rf "$fx"

  if [ -z "$bad" ]; then
    create.result 0 "forced prune runs, unforced still asks"
  else
    create.result 1 "prune force:$bad"
  fi
  return $(result)
}
test.case $level "T-ODOCKER-PRUNE-FORCE: prune.all runs non-interactively with force" test.odocker.pruneForce
expect 0 "forced prune runs, unforced still asks" "prune.all could not run from a script without hanging or skipping the prompt"
```

- [x] **Step 2: Run the test to verify it fails**

```bash
./test.suite run odocker 1
```

Expected: `T-ODOCKER-PRUNE-FORCE` fails with `forced-did-not-prune` (the first call still reads the prompt and aborts on EOF).

- [x] **Step 3: Implement**

Change the signature and the prompt:

```bash
odocker.prune.all() # <?force:no> # full system prune including unused images and volumes; force=yes skips the confirmation
{
  local force="${1:-no}"
  console.log "WARNING: This will remove ALL unused data:"
  console.log "  - All stopped containers"
  console.log "  - All unused images (not just dangling)"
  console.log "  - All unused volumes"
  console.log "  - All unused networks"
  console.log "  - Build cache"
  echo ""
  console.log "Current usage before prune:"
  docker system df 2>/dev/null
  echo ""

  if [ "$force" != "yes" ]; then
    read -p "Continue? (y/N) " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
      console.log "Aborted"
      return 0
    fi
  fi
```

Add the completion next to the other class-level completions:

```bash
odocker.parameter.completion.force() { printf '%s\n' no yes; }
```

- [x] **Step 4: Run the test to verify it passes**

```bash
./test.suite run odocker 1
```

Expected: pass; the completion audit stays green.

- [x] **Step 5: Commit**

```bash
git add odocker test/test.odocker
git commit -m "feat(odocker): prune.all force=yes for non-interactive use"
```

---

### Task 5: Add the first canonical aliases

**Files:**
- Modify: `odocker` — add wrappers after `odocker.disk()` (~3100)
- Test: `test/test.odocker` — insert after Task 4's test

- [x] **Step 1: Write the failing test**

```bash
# T-ODOCKER-CANONICAL-LIST: the first block of canonical object.verb names
# exists and delegates to the old implementation.
test.odocker.canonicalList() {
  local m bad=""
  for m in odocker.container.list.running odocker.container.list.all \
           odocker.status.show odocker.health.check odocker.disk.show; do
    [ "$(type -t "$m")" = function ] || bad="$bad missing:$m"
  done
  declare -f odocker.container.list.running | grep -q 'odocker.ps' || bad="$bad running-not-delegated"
  declare -f odocker.container.list.all | grep -q 'odocker.container.list' || bad="$bad all-not-delegated"
  declare -f odocker.status.show | grep -q 'odocker.status' || bad="$bad status-not-delegated"
  declare -f odocker.health.check | grep -q 'odocker.lifecycle' || bad="$bad health-not-delegated"
  declare -f odocker.disk.show | grep -q 'odocker.disk' || bad="$bad disk-not-delegated"
  if [ -z "$bad" ]; then
    create.result 0 "canonical listing/status names exist"
  else
    create.result 1 "canonical:$bad"
  fi
  return $(result)
}
test.case $level "T-ODOCKER-CANONICAL-LIST: listing, status, health and disk use object.verb names" test.odocker.canonicalList
expect 0 "canonical listing/status names exist" "the old root verbs were the only way to list or inspect"
```

- [x] **Step 2: Run the test to verify it fails**

```bash
./test.suite run odocker 1
```

Expected: `T-ODOCKER-CANONICAL-LIST` fails with `missing:odocker.container.list.running`.

- [x] **Step 3: Implement**

Add after `odocker.disk()`:

```bash
# Canonical object.verb names (Phase 1 naming aliases). The old names stay
# until Phase 2 removes them.
odocker.container.list.running() # # list running containers
{ odocker.ps "$@"; }
odocker.container.list.all() # # list all containers, running and stopped
{ odocker.container.list "$@"; }
odocker.status.show() # # show the Docker overview: images, containers and disk usage
{ odocker.status "$@"; }
odocker.health.check() # # check the health of containers, images and compose services
{ odocker.lifecycle "$@"; }
odocker.disk.show() # # show Docker disk usage details
{ odocker.disk "$@"; }
```

- [x] **Step 4: Run the test to verify it passes**

```bash
./test.suite run odocker 1
./test.suite run completion.audit 1
```

Expected: both pass.

- [x] **Step 5: Commit**

```bash
git add odocker test/test.odocker
git commit -m "feat(odocker): add canonical listing/status aliases"
```

---

## Self-review

- Spec coverage: Phase 1 covers the four safety/correctness items from the review (socket opt-in, password stdin, labels, prune force) and starts the naming migration with five zero-risk aliases.
- No placeholders: every step has exact code, commands and expected output.
- Type consistency: `<?withDocker:no>` is used in `odocker.run`; the old `docker` word remains accepted; `force` is `yes`/`no` in `prune.all` and its completion; canonical wrappers call the existing public names.
- Out of scope, deliberately: port-allocation lock, `DOCKER_HOST`/rootless, batched inspect, build platform/proxy, security defaults, compose project names, the remaining 25 aliases, and `docs/odocker.md` regeneration — Phase 2.

## Final verification after all tasks

```bash
./test.suite run odocker 1
./test.suite run completion.audit 1
bash -n odocker test/test.odocker
git diff --check
```

Expected: `test.odocker` green (176 assertions), completion audit green, no syntax/whitespace errors.

## Execution options

1. **Subagent-driven (recommended)** — a fresh subagent per task, review between tasks; use `superpowers:subagent-driven-development`.
2. **Inline execution** — run the tasks in this session with `superpowers:executing-plans`, with checkpoints after each task.
