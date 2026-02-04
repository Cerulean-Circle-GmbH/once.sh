# Instruction: Task Agent — Stop Sending Garbled Messages

**From**: Orchestrator (PO directive)
**To**: Task Agent (0.3)
**Priority**: CRITICAL — PO flagged your message as a violation

## Problem

You sent this garbled message:
```
TASK.28UPDATEDwithfullPOspec.Taskfileisself-contained
```

This is unreadable. The `./otmux send` and `./hiveMind send` commands lose spaces between words.

## Mandatory Rule

**NEVER send multi-word messages via otmux send or hiveMind send.**

Instead:
1. Write your update to a file in `session/tasks/`
2. Send ONLY a short reference like: `Read session/tasks/<filename>.md`

## Example

WRONG:
```
./otmux send 0.0 'TASK.28 UPDATED with full PO spec. Task file is self-contained.' Enter
```

RIGHT:
1. The task file itself IS the communication: `session/tasks/Task.28.202602040926.md`
2. Send only: `Task.28 updated` (3 words max — short enough to survive)

## Action Required

From now on, all your notifications must be 3 words or fewer. The task file contains the details — agents read the file, not your message.
