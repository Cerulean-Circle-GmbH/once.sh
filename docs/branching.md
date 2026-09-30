# OOSH Branch Strategy

## Branches

| Branch | Purpose | Stability |
|--------|---------|-----------|
| `dev` | Active development. All feature branches merge here. | Unstable |
| `stage` | Testing / QA. Code promoted from `dev` after tests pass. | Semi-stable |
| `prod` | Production-ready releases. Promoted from `stage` after platform install tests pass. | Stable |
| `main` | Legacy. Not actively used — kept for historical reference. | Frozen |

## Flow

```
feature/xxx ──> dev ──> stage ──> prod
                 ^                 |
                 |    hotfix/xxx ──┘
                 |         |
                 └─────────┘
```

### Promotion: `dev` → `testing`

Run `oo stage dev` (or `promote dev.to.testing`):

1. Clean working tree (no uncommitted changes)
2. `test.suite core 1` passes on `dev`
3. User confirms merge (diff stats shown)
4. Merge `dev` into `stage` (fast-forward or merge commit)
5. Tag the `stage` branch (e.g., `stage-2026-03-05`)
6. Push `stage` branch and tags to origin

### Promotion: `testing` → `prod`

Run `oo stage testing` (or `promote testing.to.prod`):

1. `os platform.test.all` passes (all must-pass platforms)
2. User confirms merge
3. Merge `stage` into `prod`
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
