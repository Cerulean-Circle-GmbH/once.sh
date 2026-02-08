# Task 43: Fix hiveMind.resolve to Search All Registered Sessions

**From**: woda-writer (via PO)
**For**: Expert (implement), Tester (validate)
**Priority**: High — blocks claudeWoda monitoring
**Status**: Open

## Problem

`hiveMind.resolve()` (line ~591) defaults session to `cursorOrchestrator`. When woda-writer runs `./hiveMind monitor woda-scribe`, resolve looks for "woda-scribe" only in cursorOrchestrator — doesn't find it because woda-scribe is in claudeWoda.

## Root Cause

`hiveMind.resolve` hardcodes or defaults to a single session instead of searching all registered sessions in `/tmp/hivemind.roles`.

## Fix

`hiveMind.resolve` should:
1. Search ALL sessions listed in `/tmp/hivemind.roles` for the named agent
2. Return the correct `session:pane` regardless of which session the agent is in
3. Only default to cursorOrchestrator if the agent is not found in any registered session

## Acceptance Criteria

- [ ] `./hiveMind monitor woda-scribe` works from any session
- [ ] `./hiveMind send woda-writer "msg"` works cross-session
- [ ] `./hiveMind resolve woda-scribe` returns `claudeWoda:0.1` (not cursorOrchestrator:something)
- [ ] Agents in cursorOrchestrator still resolve correctly (no regression)

## Priority

This blocks the two-team collaboration model. woda-writer can't monitor its own scribe. Fix now.
