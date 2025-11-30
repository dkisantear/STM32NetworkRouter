# Automatic Timeout - Auto-Offline Feature

## Problem Solved

**Before:** When Pi is unplugged, status remains "Online" because it can't send a POST to mark itself offline.

**After:** API automatically detects when `lastUpdated` is too old (>90 seconds) and marks gateway as "offline" automatically.

---

## How It Works

### GET Endpoint Logic

1. **Reads status from Table Storage**
2. **Checks timestamp age**:
   - If status is "online" AND `lastUpdated` exists
   - Calculate: `age = now - lastUpdated`
   - If `age > 90 seconds` → Automatically return `status: "offline"`

3. **Returns computed status** (not just stored status)

### Timeout Threshold

- **90 seconds** (1.5 minutes)
- If Pi sends heartbeat every 60 seconds, 90s gives 30s buffer
- Accounts for network delays and occasional missed heartbeats

---

## Behavior

### Scenario 1: Pi Plugged In & Sending Heartbeats

```
Pi sends POST every 60s
  ↓
lastUpdated = current time
  ↓
GET checks: age < 90s → Status = "online" ✅
```

### Scenario 2: Pi Unplugged (No Heartbeats)

```
Pi stops sending POST
  ↓
lastUpdated stays at old timestamp
  ↓
GET checks: age > 90s → Status = "offline" ✅
  ↓
Dashboard shows "Offline" automatically
```

### Scenario 3: Pi Crashes/Network Issue

```
Pi can't send POST
  ↓
lastUpdated ages past 90s
  ↓
GET checks: age > 90s → Status = "offline" ✅
  ↓
Dashboard shows "Offline" (connection issue detected)
```

---

## Implementation

### API Code (`api/gateway-status/index.js`)

```javascript
// Automatic timeout detection
if (lastUpdated && finalStatus === "online") {
  const lastUpdatedDate = new Date(lastUpdated);
  const ageMs = now.getTime() - lastUpdatedDate.getTime();
  const TIMEOUT_MS = 90 * 1000; // 90 seconds
  
  if (ageMs > TIMEOUT_MS) {
    finalStatus = "offline"; // Auto-mark as offline
    context.log(`Gateway timeout: last updated ${Math.round(ageMs / 1000)}s ago`);
  }
}
```

---

## Testing

### Test 1: Normal Operation (Online)

1. Send POST: Mark Pi as online
2. Within 90 seconds: Send GET → Should return "online"
3. Dashboard: Shows "Online"

### Test 2: Timeout (Auto-Offline)

1. Send POST: Mark Pi as online
2. Wait 95 seconds (past timeout)
3. Send GET → Should return "offline" (automatic)
4. Dashboard: Shows "Offline" (Pi appears unplugged)

### Test 3: Real-World Unplug

1. Pi is sending heartbeats (every 60s)
2. Unplug Pi
3. Wait 90+ seconds
4. Dashboard automatically shows "Offline" ✅

---

## Recommended Pi Heartbeat Interval

**60 seconds** is perfect:
- Frequent enough for responsive status
- 90s timeout gives 30s buffer
- Quota-efficient (1,440 requests/day)

---

## Configuration

The timeout is hardcoded to **90 seconds**. To change it:

Edit `api/gateway-status/index.js`:
```javascript
const TIMEOUT_MS = 90 * 1000; // Change 90 to your desired seconds
```

Recommended values:
- **60 seconds**: Stricter (Pi must heartbeat every 60s)
- **90 seconds**: Balanced (recommended, works with 60s heartbeats)
- **120 seconds**: More lenient (works with 90s heartbeats)

---

## Benefits

✅ **Automatic detection** - No manual intervention needed  
✅ **Handles unplugged Pi** - Status updates automatically  
✅ **Handles crashes** - Detects when Pi stops responding  
✅ **Handles network issues** - Detects connectivity problems  
✅ **Reliable** - Works even if Pi can't send "offline" POST  

---

## Status States

- **"online"**: Last heartbeat < 90 seconds ago
- **"offline"**: Last heartbeat > 90 seconds ago (or explicit "offline" POST)
- **"unknown"**: Gateway has never checked in (no POST received yet)

---

## Next Steps

1. ✅ Timeout logic implemented
2. Deploy and test
3. Set up Pi to send heartbeats every 60 seconds
4. Test unplug scenario - should auto-mark offline after 90 seconds

