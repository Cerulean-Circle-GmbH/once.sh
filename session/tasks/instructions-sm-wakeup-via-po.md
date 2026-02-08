# PO Correction: Wake-Up Chain

The Orchestrator cannot wake itself from sleep. New rule:

## When tokens are available (five_hour < 50%):

1. Send wake-up to **ME (PO, 0.1)**: `./hiveMind send product-owner "Tokens available — wake team"`
2. I will wake the Orchestrator manually
3. Do NOT send wake-up to the Orchestrator directly — it's sleeping and won't see it

## Chain:
```
SM detects tokens available → tells PO → PO wakes Orchestrator → Orchestrator resumes
```

This replaces the previous instruction to send wake-up directly to Orchestrator.
