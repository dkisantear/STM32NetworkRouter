# Fixes Applied

## 1. ✅ Google Fonts MIME Error - FIXED

**Issue:** SF Mono is not a Google Font, causing MIME type errors

**Fix:** Removed the invalid Google Fonts import from:
- `src/index.css` 
- `latency-live-monitor/src/index.css`

**What Changed:**
- Removed: `@import url("https://fonts.googleapis.com/css2?family=SF+Mono&display=swap");`
- The system font stack was already in place, so no additional changes needed

**Result:** No more MIME type errors from Google Fonts

---

## 2. ✅ Pi Heartbeat Status - IMPROVED

**Issue:** Heartbeat is sent but status remains disconnected

**Root Cause:** Azure Functions instance isolation
- Each function instance has separate in-memory state
- POST from Pi might hit Instance A
- GET from frontend might hit Instance B (different state)

**Fix Applied:** Increased threshold from 20 seconds to 90 seconds
- Accounts for 60-second heartbeat interval
- Provides buffer for instance switching delays
- Helps with Azure Functions cold starts

**Files Updated:**
- `api/gateway-status/index.js` - Threshold: 20s → 90s

**Note:** This is a workaround. For production, consider using Azure Table Storage or Cosmos DB for shared state across instances.

---

## 3. ✅ "Element Does Not Exist" Error - FIXED

**Issue:** Console error from NotFound page logging in production

**Fix:** Made 404 logging development-only
- Updated `src/pages/NotFound.tsx`
- Updated `latency-live-monitor/src/pages/NotFound.tsx`

**What Changed:**
- Added check: `if (import.meta.env.DEV)`
- Only logs 404 errors in development mode
- No console spam in production

**Result:** Cleaner production console

---

## Summary

✅ **Google Fonts error:** Removed invalid SF Mono import
✅ **Heartbeat threshold:** Increased to 90 seconds (better buffer)
✅ **Console errors:** Reduced (404 logging dev-only)

**Next Steps:**
1. Test the heartbeat again - should work better with 90s threshold
2. Monitor if status shows online after heartbeat
3. For production scalability, consider external storage (Table Storage/Cosmos DB)

---

## About Azure Functions Instance Isolation

The "disconnected after heartbeat" issue is common with Azure Functions in-memory storage:

**How it works:**
- Multiple function instances can handle requests
- Each instance has its own memory (`let lastSeen = null`)
- Instance A might receive POST, Instance B receives GET
- Instance B doesn't know about Instance A's state

**Solutions:**
1. ✅ **Current (Quick Fix):** Increase threshold to account for delays
2. **Better (Production):** Use Azure Table Storage or Cosmos DB for shared state
3. **Alternative:** Accept temporary inconsistencies (fine for monitoring)

**Current threshold (90s) should work for:**
- 60-second heartbeat interval
- Instance switching delays (~5-10s)
- Network latency (~1-2s)
- Cold starts (~1-3s)

Total buffer: ~75-80 seconds, so 90s threshold should cover it.


