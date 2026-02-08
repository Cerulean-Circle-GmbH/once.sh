# PO Directive: Tasks 46, 47, 48 — From woda-writer Observations

Three new tasks from woda-writer's story research (Ch7-Ch8). Assign Expert to implement, Tester to validate.

## Priority Order

1. **Task 48** (Critical) — Bootstrap paradox. Move sweep.loop outside agent layer. This is architectural — the unblocker must not need unblocking. `session/tasks/Task.48.bootstrap-paradox-external-loop.md`

2. **Task 46** (High) — sweep.detect misses background tasks overlay. Sends Down+Enter when it should send Escape. `session/tasks/Task.46.sweep-detect-background-overlay.md`

3. **Task 47** (Medium) — ./ prefix mismatch causes extra permission prompts. `session/tasks/Task.47.path-prefix-permission-mismatch.md`

## Execution

- Task 48 first — it eliminates the root cause of the monitoring chain breaking
- Task 46 next — quick detection fix
- Task 47 last — permission cleanup

Expert can start immediately.
