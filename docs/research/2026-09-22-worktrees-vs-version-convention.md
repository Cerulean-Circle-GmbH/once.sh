# Worktrees vs. the EAMD.ucp version convention — research: remove worktrees, or reconcile the naming?

**Written 2026-09-22 · Branch `dev` (`09020ba`) · Status: RESEARCH — no code changed. Verdicts in § 2, § 3; recommendation in § 5; hand-off in § 6.**
**Question (verbatim):** "What will it take to remove worktrees and use real folders only in the repository? If it doesn't make sense, how can we fix worktrees to be consistent with naming conventions like it would have been without worktrees?"

The leaf folder of this component is a git **branch name** (`dev`/`main`/`prod`), because git
worktrees are used — one directory per branch. The EAMD.ucp component convention says the leaf
should be a **version** (`.../Once.sh/2.0.0/`), with `latest`/`dev`/`test`/`prod` existing only as
**symlinks** to a version. Those two conventions have never been reconciled; worktrees simply took
over the leaf slot. This doc grounds both, decides whether removing worktrees is worth it, and — since
it is not — lays out how to make the worktree layout consistent with the convention instead.

Grounded by three read-only research passes over `oo`, `this`, `promote`, `user`, `config`,
`init/oosh`, the `docs/research/` item-7 + T7 notes, `docs/plans/auto-staging-pipeline.md`, and the
EAMD.ucp convention sources (`docs/plans/2026-03-05-web4pycomponent-design.md`, `docs/python.md`).
All citations are `file:line` within this worktree.

---

## 1. What is on disk, and the two conflicting conventions

```
Once.sh/
├── main/   ← the repository (real .git DIRECTORY). Load-bearing.
├── dev/    ← linked worktree  (.git is a FILE → main/.git/worktrees/dev)
└── prod/   ← linked worktree  (.git is a FILE → main/.git/worktrees/prod)
```

`main/` **is** the repository; `dev/` and `prod/` are linked worktrees registered under
`main/.git/worktrees/`. Remote: `git@github.com:Cerulean-Circle-GmbH/once.sh.git`.

| | EAMD.ucp component convention | Once.sh worktree layout (actual) |
|---|---|---|
| Leaf folder | a **version** — `.../Once.sh/2.0.0/` (cf. real sibling `me/hannesnortje/TestSuite/2.0.0/`, `docs/python.md:52`) | a **branch name** — `dev` / `main` / `prod` |
| `dev`/`test`/`prod`/`latest` | **symlinks** to a version dir (`docs/plans/2026-03-05-web4pycomponent-design.md:54-85`) | `dev`/`prod` are **real directories** (worktrees); no `latest`; `main` present (not in the semantic-symlink set) |
| Version carried as | folder name — 4-part semver, promoted by the `SemanticVersion` runtime component (`…design.md:359-386`) | git **tags** on the `prod` branch — `v1.0.0` (`docs/branching.md:40`) |

"Consistent with the convention it would have had without worktrees" therefore means:
`Once.sh/<semver>/` as a real directory **plus** `latest`/`dev`/`test`/`prod` as symlinks to it.

The worktree layout is itself a documented contract (`docs/oo.md:143-164`;
`docs/research/2026-09-16-item7-oo-mode-setup.md:36-51`: "`main` **is** the repository; a layout with
no `main` has nowhere for the repository to live"). So this is not drift against an undisputed rule —
it is two documented-ish conventions that genuinely conflict, and Once.sh deliberately chose the
worktree one.

### 1a. Why Once.sh is a legitimate special case (inference — confirm with Marcel)

The version-folder + semantic-symlink convention is resolved and promoted **by runtime EAMD
components** (a `SemanticVersion` component; `resolveLink(component, "latest")`;
`promote(component, "nextPatch")` — `…design.md:359-386`). Once.sh lives in `1_infrastructure`: it is
the bootstrap layer that must come up from bare git **before** any of those resolvers exist. It
therefore cannot use the runtime version-folder machinery to manage itself, and falls back to what
exists at bootstrap time — git branches, tags, and worktrees. This is a sound architectural reason for
the deviation, but it is nowhere stated verbatim; § 4.3 files the missing doc.

---

## 2. Q1 — What would it take to remove worktrees and use "real folders only"?

"Real folders only" resolves to one of two shapes. Both are large, install-path-critical refactors.

### Shape A — each branch as an independent full clone

Breaks:
- **`promote` assumes one repo holds all branch refs.** Every op runs against a single `$OOSH_DIR`:
  `checkout testing` + `merge dev` + `tag … prod` + `push origin testing/prod`
  (`promote:765`, `promote:264-265`, `promote:1008`). Separate clones do not carry each other's local
  branches, so merges/tags operate on missing or stale refs.
- **Single-fetch model.** `oo update` pulls only `$OOSH_DIR` (`oo:250`, `oo:273`); with a shared
  object store every worktree sees the result at once. Independent clones each need their own fetch.
- **Base detection dies.** 2 of 4 strategies in `oo.mode.base.get` depend on `git worktree list` and
  on the branch's `.git` being a *file* (`oo:643-665`); clones have `.git` directories.
- **Install state 31** sets `core.sharedRepository group` + setgid on `main/.git` for cross-worktree
  group writes (`oo:2352-2365`) — meaningless for separate clones.
- Partial precedent exists: `oo.checkout` already has a plain-clone fallback (`oo:1306-1345`) and
  Marcel's `oo.mode.sync` (`6685748`, 2026-09-08, "NEVER create worktrees") leans this way for
  component clones. But `promote` and `oo.mode` do not.

### Shape B — a single folder, switch branches in place

Breaks harder:
- **The `~/oosh` symlink flip *is* `oo mode`** (`oo:922-936`). With one folder there is nothing to
  re-point. The "`OOSH_DIR` is a constant because switching branches only moves what the symlink points
  at" doctrine (`boot:64-69`; `this.anchor.validate`, `this:271-316`) collapses.
- **Multi-user shared tree races (the killer).** State 31 builds one `/home/shared` tree that many
  dev-group users symlink into, each on their own branch. A single in-place checkout means one user
  running `promote` (which checks out `prod`) yanks the tree out from under another user sitting on
  `dev`.
- `promote`'s worktree-aware prod merge (`promote:907-935`) exists *specifically* so dev and prod can
  be checked out simultaneously; with one folder that logic is dead and merges disturb the live tree.

### Scope either way

Touches `oo` (base.get, mode, checkout, mode.setup, use), the whole `promote` merge model, `user`,
`config`, `this` (anchor doctrine), `init/oosh`, install state 31, and `docs/`. This is the most
install-critical surface in the repo.

### Verdict on Q1: removing worktrees does **not** make sense

The worktree layout is not incidental — it *is* the value:
1. non-destructive stage switching (flip a symlink, never `git checkout` a shared tree — origin
   commit `205bd40`, 2026-02-20);
2. all stages coexist and are independently runnable (`oo use <branch>` runs from another branch
   without switching — `docs/oo.md:229-250` — impossible with one checkout);
3. one shared `.git` for a whole dev-group team, cheap;
4. `promote` can merge into prod's worktree without disturbing anyone's dev checkout.

Shape B breaks the multi-user model outright; Shape A is a big rewrite that loses the shared object
store to land roughly where it started. Neither is worth it.

---

## 3. Q2 — How to make worktrees consistent with the naming convention

Name the impedance mismatch first: **a git worktree is inherently a real directory** — you cannot make
`dev` be both a worktree and a symlink-to-a-version — and the convention keys on **versions** (tags)
while worktrees key on **branches**. So the worktrees cannot conform *directly*; they conform via a
**compatibility layer**. Three options, cheapest first.

### F1 — Add the convention's symlinks alongside the worktrees (low effort, high payoff)

Keep branch worktrees as the source of truth; add the symlinks an EAMD resolver expects:
```
Once.sh/
├── main/  dev/  prod/        ← unchanged worktrees
├── latest  → prod            ← currently missing entirely
└── <semver>/ (e.g. 1.0.0/)   ← optional: a real checkout/worktree at tag v1.0.0
```
Smallest change that closes the most visible gap (`latest` and a version handle simply do not exist
today). Does **not** satisfy "leaf is a version dir", but makes Once.sh addressable the conventional
way.

### F2 — Full reconciliation: version dirs are the real content, stage names are symlinks

```
Once.sh/
├── .repo/ (or main/)         ← the .git holder
├── <semver>/                 ← real content per release (worktree at tag, or copy)
├── latest → <newest semver>
├── dev  → <a worktree/version>
└── prod → <a semver>
```
This is what "without worktrees" would have looked like — but it **requires the Q1-level refactor of
`oo.mode.base.get` / `promote`**, because every base-detection strategy demands a sibling directory
literally named `main` and branch-named sibling dirs (`oo:643-681`). High effort; only worth it if
external EAMD tooling must resolve Once.sh through the standard version resolver.

### F3 — Declare Once.sh an explicit, documented exception (near-zero effort)

Write the one missing paragraph: Once.sh is `1_infrastructure` and bootstraps before the version
resolver exists, therefore it uses the git branch/worktree layout instead of version folders;
`dev/test/prod` are worktrees, versions live as tags. Today the deviation is real but *undocumented as
a deliberate choice* — that is the actual defect.

### Verdict on Q2 (recommendation)

**F1 + F3 together; skip F2 unless external tooling forces it.** Add the missing `latest` (and
optionally a `<semver>`) symlink so Once.sh is addressable conventionally, and write the exception doc
so the branch-named leaves are a stated decision, not drift — without touching the install-critical
base-detection / promote machinery.

---

## 4. Cleanups worth doing regardless (the *real* inconsistencies)

Independent of the worktree question, and probably closer to what actually bites:

1. **`main`-hardcoding fragility.** 3 of 4 strategies in `oo.mode.base.get` require a dir literally
   named `main` (`oo:643-681`); a non-conforming layout is undetectable — the item-7 bug.
2. **`OOSH_MODE` drift.** `oo.mode` writes the branch name; `promote` wrote `OOSH_MODE=released` — a
   value with no worktree on disk (`docs/research/2026-09-16-t7-config-branch-variables.md:108-114`).
3. **`testing` vs `stage` naming drift** across `docs/branching.md` and the `oo stage` / `promote`
   dispatch.
4. **`promote` asymmetry.** dev→testing is *not* worktree-aware (`promote:765`) while testing→prod
   *is* (`promote:921`) — if `testing` is ever its own worktree, dev→testing breaks with "already used
   by worktree".
5. **Missing `latest` symlink** (the F1 item).

---

## 5. Recommendation

- **Do not** remove worktrees (Q1) — negative verdict; the multi-user shared-tree + promote model
  depends on them.
- **Do** the § 4 cleanups + **F1** (`latest` symlink) + **F3** (exception doc). Highest value, lowest
  risk; none touch base-detection or promote's merge logic.
- **Only if** external EAMD tooling must resolve Once.sh by version, scope **F2** as a
  base-detection + promote refactor (same surface as Q1).

---

## 6. Hand-off for the next agent

**Invariants any change must preserve:**
- `OOSH_DIR` / `CONFIG_PATH` stay the `~/oosh` / `~/config` symlink *literals* (`this.anchor.validate`,
  `this:271-316`; `boot:70,76`).
- `~/config` stays branch-**independent** — always the single `sharedConfig` (`config:254`, `user:995`)
  — while only `~/oosh` is branch-specific.
- `main/` remains the single `.git` holder; `dev`/`prod` remain linked worktrees.

**Primary source files / anchors:**
- `oo`: `oo.mode.base.get` `629-685`; `oo.mode` `816-986`; `oo.checkout` `1237-1348`;
  `private.oo.shared.tree.from.local` `1805`; `private.oo.shared.base.get` `1861-1891`; state-31 body
  `2279`, shared-repo perms `2352-2365`.
- `promote`: `private.promote.find.worktree` `656-664`; dev→testing `740-798`; testing→prod `895-965`;
  tag `1008`.
- `this`: anchor doctrine + validate `271-316`; symlink primitive `332-372`.
- `config`: `config.init.user` `233-343`.
- `user`: `user.oosh.install` `996-1043`.

**Open confirmation:** § 1a's "bootstraps before the resolver exists → legitimate exception" is
inference from the `1_infrastructure` layering + the convention being enforced by runtime components.
Well-supported, not stated verbatim — confirm with Marcel before F3's wording is finalized.

**Convention sources for F1/F2:** `docs/plans/2026-03-05-web4pycomponent-design.md:54-85,359-386`;
`docs/python.md:52`; real sibling example `me/hannesnortje/TestSuite/2.0.0/`.
