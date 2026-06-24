# oosh-tester learnings

## UUID Discovery (critical)
- Process args UUID is WRONG for `--fork-session` agents (shows parent UUID)
- Real UUID = JSONL file `sessionId` field (line 1 of the .jsonl)
- sessions.env can also be stale — must verify against JSONL
- Three sources must agree: process args, sessions.env, JSONL file

## Test Execution
- NEVER run `test.suite run hiveMind` from own pane — crashes session
- Run via external shell pane (project-shell or expert-shell)
- Use `otmux pane.history` for full scrollback, `otmux pane.capture` for visible area

## Tool Usage
- NEVER use raw tmux commands — always otmux wrappers
- OOSH scripts on PATH — no `./` prefix ever
- Tab completion: send Tab keys via `otmux send.raw pane Tab`

## Test Design
- Tests must be self-contained — create own test sessions, don't depend on live agents
- Live measurement tests must skip gracefully when no agents running
- Use LIVE_SESSION guard for tests requiring running agents
- Budget-based grep tests (count allowed occurrences) better than fragile line-matching
- Different test session names to avoid collision (__test_lifecycle vs __test_hm)
