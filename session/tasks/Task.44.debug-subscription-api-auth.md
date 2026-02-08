# Task 44: Debug Subscription API Authentication Failure

**From**: Product Owner (Tron directive)
**For**: Expert (diagnose + fix)
**Priority**: High — blocks velocity measurement (Task 40.4 depends on this)
**Status**: Open

## Problem

`scrumMaster measure.subscription.api` returns `authentication_error`. The OAuth usage API at `https://api.anthropic.com/api/oauth/usage` no longer accepts our token.

## Debug Steps (run these in order)

```bash
# 1. Can we read the keychain entry?
security find-generic-password -s 'Claude Code-credentials' -w 2>&1 | head -1

# 2. Does the JSON path still exist?
security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(list(d.keys()))"

# 3. Can we extract the token?
security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('claudeAiOauth',{}).get('accessToken','MISSING')[:20]+'...')"

# 4. Does the API accept it?
TOKEN=$(security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['claudeAiOauth']['accessToken'])")
curl -v -H "Authorization: Bearer $TOKEN" -H "anthropic-beta: oauth-2025-04-20" https://api.anthropic.com/api/oauth/usage 2>&1 | tail -20
```

## Possible Fixes

1. **Token expired**: Need to refresh — check if Claude Code stores a refresh token
2. **Beta header outdated**: Try without the `anthropic-beta` header or with a newer date
3. **Keychain path changed**: Dump the JSON keys and find the new token location
4. **API removed**: If the endpoint no longer exists, fall back to alternative velocity source (commit rate, task timestamps)

## Acceptance Criteria

- [ ] Root cause identified
- [ ] Fix implemented OR alternative velocity source documented
- [ ] `./scrumMaster measure.subscription.api` returns data (or graceful fallback)
