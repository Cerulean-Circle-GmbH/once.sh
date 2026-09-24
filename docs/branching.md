# OOSH Branch Strategy

## Branches

| Branch | Purpose | Stability |
|--------|---------|-----------|
| `dev` | Active development. All feature branches merge here. | Unstable |
| `testing` | Testing / QA. Code promoted from `dev` after tests pass. | Semi-stable |
| `prod` | Production-ready releases. Promoted from `testing` after platform install tests pass. | Stable |
| `main` | Legacy. Not actively used — kept for historical reference. | Frozen |

## Flow

```
feature/xxx ──> dev ──> testing ──> prod
                 ^                   |
                 |    hotfix/xxx ────┘
                 |         |
                 └─────────┘
```

### One folder per branch — where merges happen

Every branch lives in its own clone under the components base (`<base>/main`, `<base>/dev`, `<base>/testing`, `<base>/prod`, feature folders — see [oo.md § The clone layout](oo.md#the-clone-layout)). A promotion merges **in the target's folder**: `dev → testing` in `<base>/testing`, `testing → prod` in `<base>/prod`. The folder you work in (`dev`) never checks out another branch.

**Prerequisite:** the target folder must exist. Create it once with

```bash
oo checkout testing     # → <base>/testing (likewise: oo checkout prod)
```

Without it `promote` refuses at the merge state with `no folder holds branch testing — run: oo checkout testing`; run that, then re-run `promote testing` — it resumes there. Details: [promote.md § Where the merge happens](promote.md#where-the-merge-happens--each-stage-in-its-own-folder).

### Promotion: `dev` → `testing`

Run `oo stage dev` (or `promote dev.to.testing`):

1. Clean working tree (no uncommitted changes)
2. `test.suite core 1` passes on `dev`
3. User confirms merge (diff stats shown)
4. Merge `dev` into `testing` in `<base>/testing` (fast-forward or merge commit)
5. Tag the `testing` branch (e.g., `testing-2026-03-05`)
6. Push `testing` branch and tags to origin

### Promotion: `testing` → `prod`

Run `oo stage testing` (or `promote testing.to.prod`):

1. `os platform.test.all` passes (all must-pass platforms)
2. User confirms merge
3. Merge `testing` into `prod` in `<base>/prod`
4. Tag the `prod` branch with semver (e.g., `v1.0.0`)
5. Push `prod` branch and tags to origin

See [Promotion Pipeline](promote.md) for full state machine details.

## Feature Branches

- Fork from: `dev`
- Naming: `feature/<description>` (e.g., `feature/tab-completion-fix`)
- Merge back into: `dev`
- Delete after merge

## Hotfix Branches

- Fork from: `prod`
- Naming: `hotfix/<description>` (e.g., `hotfix/install-crash`)
- Merge back into: **both** `prod` and `dev`
- Delete after merge

## Rules

- Never push directly to `prod` — always promote through the pipeline
- `dev` is the default working branch for all contributors
- Promotion is gated by automated tests — no manual overrides
- Every promotion to `prod` gets a version tag
