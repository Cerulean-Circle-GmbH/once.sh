# T14 — `T-ODOCKER-ENGINE-START-WAIT` is flaky under `core`

- **Type:** test bug · **Priority:** P3 · **Area:** `test/test.odocker`
- **State:** observed 2026-11-03, not reproducible on rerun
- **Found by:** the `core` run after T04

## Symptom

```
✗ FAIL: an OpenRC start returned before dockerd made its socket: did not start
  Expected return: 0, got: 1
  Got result:      engine wait: no-socket=[rc=127]
```

`./test.suite run odocker 1` immediately afterwards: **171/171**, including that case. The `core`
run before this change (2026-10-30) also passed it.

## Suspected cause

`test.odocker.engineStartWait` starts `rc-service` as a stub that, when `LATE=1`, spawns

```sh
( sleep 1; : > "$ODOCKER_SOCKET" ) >/dev/null 2>&1 &
exit 0
```

Then it runs the same fixture **without** `LATE` and removes the socket first
(`rm -f "$fx/docker.sock"`). The background job from the first run can still fire during the
second run and race the "no socket ever" expectation; `rc=127` is a child that found no command on
the restricted `PATH` in that window. The test never waits for the background pid.

## Fix

- give each run its own socket path (`$fx/docker.sock.late`, `$fx/docker.sock.none`) or `wait`
  for the background job before the second run;
- keep the `rc=1` assertion for "no socket at all";
- add a comment naming the race, so the next reader does not "fix" it by lengthening the sleep.

## Acceptance

Ten consecutive `core` runs (or `run odocker` in a loop) without this failure; the test still
fails if the engine-wait logic stops treating a late socket as started (mutate the wait and see it
go red).

## Notes

It is unrelated to T04: `test/test.odocker` does not source `this` for these engine paths, and the
failure appears in a file whose tests passed before and after the predicate work. It is listed so
that a red `core` is not mis-attributed to the next change.
