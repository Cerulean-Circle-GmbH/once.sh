# oosh-tester context — macOS (ooshTeam:0.3)

## Identity
- **Role:** oosh-tester
- **Pane:** ooshTeam:0.3
- **Machine:** MacStudio (macOS)
- **Branch:** test/macos.latest
- **Anchor commit:** 8374cc5 (test.c2: fix T-COMPLETION-1)

## Team Layout (ooshTeam)
- 0.0: orchestrator (auto mode)
- 0.1: oosh-architect/expert (accept-edits)
- 0.2: scrum-master (active)
- 0.3: oosh-tester (me)

## Prior Work (Linux container, different branch)
- Wrote 30+ regression tests across hiveMind, otmux, claudeCode
- UUID integrity tests: discovered 3 agents running wrong sessions (forked with --fork-session)
- Key finding: process args UUID ≠ real UUID for forked agents. Real UUID = JSONL file sessionId
- DRY refactor: agents.discover extracted as shared method
- pane.lock plan-mode survival tests
- Registry invariant tests

## Current State
- Rewound to macOS context. No prior session/agents/ dir existed here.
- Need to verify: which tests from Linux work exist on this branch
- Stale test sessions visible: __test_dry_36376, __test_dry_4357, __test_hm_93053

## Rules (from memory)
- NEVER run test.suite run hiveMind from tester session (crashes)
- Use otmux wrappers, NEVER raw tmux
- OOSH on PATH — no ./ prefix
- Expert does not test; tester does not implement
- Run tests via external shell pane, capture with otmux pane.capture/pane.history

## Next Action
- Orient: check what tests exist on this branch
- Run test.suite run hiveMind 1 from expert shell or project-shell
- Report results
