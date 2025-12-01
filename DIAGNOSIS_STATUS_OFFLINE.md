# Why Status Shows "Offline" - Diagnosis

## Current Situation

### ✅ What's Working:
- API is working correctly
- Frontend hook is correctly calling API with `gatewayId` parameter
- Timeout logic is working (correctly detecting stale heartbeat)

### ❌ What's the Problem:
- Last heartbeat was sent at: **2025-11-30 10:42:03** (hours ago)
- Current time is much later
- Since last heartbeat is **older than 90 seconds**, status correctly shows "offline"

---

## The Real Issue

**The Pi automation script hasn't been set up yet!**

You need to:
1. **SSH into your Pi**
2. **Run the setup script** (from `EXECUTE_ON_PI.txt`)
3. **Pi will start sending heartbeats automatically every 60 seconds**
4. **Status will change to "Online" automatically**

---

## About the "gateway id query parameter is required" Error

This error is **NORMAL** when you access the API URL directly in the browser:

- ❌ **Wrong**: `https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status`
- ✅ **Correct**: `https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status?gatewayId=pi5-main`

**The frontend is doing it correctly** - it includes the `gatewayId` parameter automatically.

You only see this error if you manually type the URL in the browser without the query parameter, which is expected behavior.

---

## Solution: Set Up Pi Automation

The status will show "offline" until the Pi starts sending heartbeats automatically.

### Quick Setup:

1. **SSH into your Pi**:
   ```bash
   ssh pi@<your-pi-ip>
   ```

2. **Copy and paste the entire contents of `EXECUTE_ON_PI.txt`** into the Pi terminal

3. **Wait 60 seconds** - Pi will send first heartbeat

4. **Check dashboard** - Status should show "Online"!

---

## Current Status Breakdown

| Component | Status | Notes |
|-----------|--------|-------|
| API Endpoint | ✅ Working | Returns correct response |
| Frontend Hook | ✅ Working | Correctly includes gatewayId |
| Timeout Logic | ✅ Working | Correctly detecting stale heartbeat |
| Pi Automation | ❌ Not Set Up | Need to run `EXECUTE_ON_PI.txt` |
| Gateway Status | ⚠️ Offline | Because no recent heartbeats |

---

## Why It Shows Offline

The timeout logic is working correctly:

```
Last heartbeat: 2025-11-30 10:42:03 (hours ago)
Current time:   [current time]
Age:            [many minutes/hours old]
Timeout:        90 seconds

Since age > 90 seconds → Status = "offline" ✅ (correct!)
```

This is **expected behavior** - the status correctly shows offline because:
- No recent heartbeat (Pi script not running)
- Last heartbeat is way too old
- Pi needs to send heartbeats every 60 seconds to stay online

---

## Next Steps

1. **Set up Pi automation** (run `EXECUTE_ON_PI.txt` on Pi)
2. **Wait 60 seconds** for first heartbeat
3. **Check dashboard** - should show "Online"
4. **Status will update automatically** as Pi sends heartbeats

Once the Pi script is running, you'll see:
- ✅ Status: "Online"
- ✅ Last Updated: "just now" or "X seconds ago"
- ✅ Updates automatically every 8 seconds (frontend polling)

---

## Testing the API Directly

If you want to test the API in the browser, use the full URL with query parameter:

```
https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status?gatewayId=pi5-main
```

This will work correctly and show the current status.

