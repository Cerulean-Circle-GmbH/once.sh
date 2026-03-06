# OOSH Branch Strategy

## Branches

| Branch | Purpose | Stability |
|--------|---------|-----------|
| `dev` | Active development. All feature branches merge here. | Unstable |
| `stage` | Staging / QA. Code promoted from `dev` after tests pass. | Semi-stable |
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

### Promotion: `dev` → `stage`

1. `test.suite all 1` passes on `dev`
2. Platform install tests pass on all supported platforms
3. Merge `dev` into `stage` (fast-forward or merge commit)
4. Tag the `stage` branch (e.g., `stage-2026-03-05`)

### Promotion: `stage` → `prod`

1. `stage` branch has passed all platform install tests
2. Merge `stage` into `prod`
3. Tag the `prod` branch (e.g., `v2.0.0`)

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
