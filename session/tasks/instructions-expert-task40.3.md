# Expert: Task 40.3 — Tab Completion for Team Selection

**Parent**: Task 40 CMM4 | **Depends on**: 40.1 (done, 1fe680f)
**Your design plan**: session/tasks/task40-expert-plan.md (section 3)
**Priority**: Medium

## What to Build

Per your design plan, most completion already works. Fill the gaps:

### 1. Verify existing completions
- `hiveMind.sweep.completion.session()` — already lists tmux sessions via `tmux list-sessions`
- `hiveMind.send.completion.name()` — already completes agent names
- `hiveMind.unblock.completion.name()` — already completes agent names

### 2. Add missing completions
- `hiveMind.team.sweep.completion.session()` — if team.sweep alias was added in 40.1
- Any new methods from 40.1 that lack completion

### 3. Ensure OOSH positional arg convention
- No `--team` flags. OOSH uses positional: `./hiveMind sweep claudeWoda`
- All session-aware methods should complete session names as their first positional parameter

### 4. Test with c2
```bash
./c2 function.completion ./hiveMind team
./c2 function.completion ./hiveMind sweep
./c2 function.completion ./hiveMind send
```

## Acceptance Criteria
- [ ] All team-aware hiveMind methods offer session name completion
- [ ] `./c2 function.completion ./hiveMind team` lists team.list, team.status, etc.
- [ ] `./c2 function.completion ./hiveMind sweep` offers session names
- [ ] Follows OOSH `method.completion.parameter()` convention
- [ ] `bash -n hiveMind` passes

## When Done
Commit and report: `Task 40.3 done`
