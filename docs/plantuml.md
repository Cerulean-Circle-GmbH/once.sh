# `plantuml` — dockerized PlantUML rendering

Render PlantUML `.puml` diagrams to `.svg` on any host with Docker — **no Java, no PlantUML install** needed. The tool runs the official `plantuml/plantuml` image as a throw-away one-shot container and validates the result so a broken diagram never gets shipped as a success.

You do not need to read the source to use it. This page is enough.

---

## TL;DR

```bash
plantuml install                 # one-time: make sure the image is present (idempotent)
plantuml render mydiagram.puml   # → mydiagram.svg next to it
plantuml render diagrams/        # → render every *.puml in the dir
plantuml status                  # is docker up? image present? which PlantUML version?
```

`plantuml` is on the OOSH PATH — run it directly, no `./`, no `cd`.

---

## Commands

### `plantuml render <fileOrDir>`
Renders a single `.puml` **or every `.puml` in a directory**. Each `.svg` is written **next to** its source `.puml`. A multi-`@startuml` file produces one `.svg` per named diagram (`@startuml <name>` → `<name>.svg`).

- Auto-installs the image first (self-healing) — you can call `render` without `install`.
- **Validates every output.** If a diagram has a syntax error, PlantUML still writes a tiny "contains errors" stub `.svg`. `plantuml render` **detects that**, prints which source file(s) failed, and **exits non-zero (rc=1)** — it never reports a broken render as success.
- On success: prints `plantuml render: OK …` and exits `0`.

```bash
plantuml render scrum.pmo/sprints/sprint-21-contact-identity/diagrams/sprint-21.puml
echo "rc=$?"      # 0 = all good; 1 = at least one diagram had errors
```

Example failure output (a mode-conflict diagram):
```
Error line 3 in file: /…/bad.puml
ERROR> plantuml render: FAILED — error-stubs detected, NOT shipping as success:
ERROR>   puml error: /…/bad.puml
```

### `plantuml install`
Ensures the pinned image is available locally (pulls if missing, no-op if present). Idempotent — safe to run anytime. `render` calls this for you, so you rarely need it directly.

### `plantuml status`
Diagnostics — prints the pinned image ref, whether it's present, and the PlantUML version (which also proves Docker + the seccomp workaround + the image all work end-to-end):
```
image ref : plantuml/plantuml@sha256:47870c…
image     : present
plantuml  : PlantUML version 1.2026.6 …
```

### `plantuml usage`
Short built-in help.

Tab-completion: `plantuml render <TAB>` completes `.puml` files and directories.

---

## Configuration — `PLANTUML_IMAGE` / `PLANTUML_TAG`

Two env vars control which image is used. Defaults are **pinned for reproducibility** (a given `.puml` renders identically regardless of when you run it):

| Var | Default | Meaning |
|-----|---------|---------|
| `PLANTUML_IMAGE` | `plantuml/plantuml` | The image repository (the **CLI** image — not the plantuml-*server* image). |
| `PLANTUML_TAG` | a pinned `sha256:` **digest** | The exact image version. A digest is used because `plantuml/plantuml` publishes no clean semver tags; a digest is the most reproducible, non-`:latest` pin. |

`PLANTUML_TAG` accepts **either** a tag or a digest — the tool picks the right ref form:
- digest → `plantuml/plantuml@sha256:…`
- tag    → `plantuml/plantuml:<tag>`

**Deliberate upgrade** (the point of pinning — upgrades are a conscious act, never accidental):
```bash
PLANTUML_TAG=latest plantuml render mydiagram.puml     # one-off with :latest
# or persist a new pin:
config set PLANTUML_TAG sha256:<new-digest>
```

Other tunable: `PLANTUML_STUB_MIN_BYTES` (default `1200`) — the size floor below which an `.svg` is treated as an error-stub (belt-and-suspenders with the "contains errors" text check).

---

## The layering — how it's built (why you never touch `docker`)

```
plantuml   →   odocker   →   docker
(domain)       (generic)     (runtime)
```

- **`plantuml`** owns only PlantUML specifics: the image name, `-tsvg`, which dir to mount, and the render-result validation. It contains **zero** direct `docker` calls.
- **`odocker`** is the generic Docker manager. `plantuml` delegates every container operation to two generic odocker primitives:
  - `odocker image.ensure <image>` — idempotent pull-if-missing (used by `plantuml install`).
  - `odocker run.ephemeral <image> <workdir> <args…>` — a one-shot `docker run --rm` in a mounted working dir. **All** docker-runtime concerns live here, not in `plantuml`: `--rm`, the `-v/-w` mount, and crucially `--security-opt seccomp=unconfined` (required on Docker 20.10.7 or the JVM dies with *"cannot create worker GC thread"*). You never pass these — they're baked into the `ephemeral` verb.

So as a user you call `plantuml render`; the seccomp flag, the `--rm` cleanup, and the volume mount are handled for you. If you ever want to run some *other* image as a one-shot, `odocker run.ephemeral <image> <workdir> <args…>` is the reusable primitive.

---

## Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| `plantuml status` shows `image: MISSING` | Run `plantuml install` (or just `plantuml render …`, which installs first). Needs network for the first pull. |
| `plantuml: unavailable (docker/image/seccomp issue)` | Docker not running, or the image can't start. Check `docker ps`; on Docker 20.10.7 the seccomp workaround is already applied by `odocker run.ephemeral`. |
| `render` exits `1` naming a `.puml` | That diagram has a **content error** — fix the source. Common classes: mixing `usecase`/`agent` with class `<|--` inheritance (diagram-mode conflict); `artifact`/`database` keywords inside a class diagram (wrong-mode keyword); `()<>{}` punctuation in multi-line labels. |
| SVG looks empty / tiny | It's an error-stub — `render` already flagged it and exited non-zero; don't ship it. |

---

## Quick worked example (copy-paste)

```bash
# 1. render a real diagram
plantuml render scrum.pmo/sprints/sprint-20-traceability-first/diagrams/r20-2-grab-bar-chain.puml
# → …/r20-2-grab-bar-chain.svg   (a real ~5 KB svg)   rc=0

# 2. confirm it's a real render, not a stub
ls -l scrum.pmo/sprints/sprint-20-traceability-first/diagrams/r20-2-grab-bar-chain.svg
grep -c 'contains errors' scrum.pmo/sprints/sprint-20-traceability-first/diagrams/r20-2-grab-bar-chain.svg   # → 0
```

*(Tool: `plantuml` OOSH script, sprint-2 task-s2-f.1. Delegates to `odocker` primitives `run.ephemeral` + `image.ensure`.)*
