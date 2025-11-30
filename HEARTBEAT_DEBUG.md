# Pi Heartbeat Debugging

## Issue: Heartbeat sent but status remains disconnected

### Possible Causes:

1. **Azure Functions Instance Isolation** (Most Likely)
   - Each Azure Function instance has separate in-memory state
   - POST from Pi might hit Instance A (updates `lastSeen`)
   - GET from frontend might hit Instance B (has `lastSeen = null`)
   - This is a known limitation of serverless functions

2. **Timing/Threshold Issue**
   - Current threshold: 20 seconds
   - If Pi sends heartbeat but frontend checks >20 seconds later, shows offline

3. **API Response Format Mismatch**
   - Frontend expects: `{status: "online"|"offline", lastSeen: ..., msSinceLastSeen: ...}`
   - API returns: This format ✅

### Solutions:

**Option 1: Increase Threshold (Quick Fix)**
- Change from 20 seconds to 60 seconds
- Gives more buffer for instance switching

**Option 2: Use External Storage (Proper Fix)**
- Store `lastSeen` in Azure Table Storage or Cosmos DB
- All instances can read/write same state

**Option 3: Accept Limitation**
- In-memory storage works for single-instance scenarios
- Multiple instances will have temporary inconsistencies

### Current Implementation:

The API uses:
```javascript
let lastSeen = null; // Module-scoped variable
```

This is per-instance. When Azure scales to multiple instances, each has its own `lastSeen`.

### Recommendation:

For now, increase the threshold to 60 seconds to account for:
- Instance switching delays
- Network latency
- Function cold starts


