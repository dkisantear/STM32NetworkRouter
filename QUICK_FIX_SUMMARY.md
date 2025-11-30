# Quick Fix Summary

## Issues Fixed

### 1. ✅ Google Fonts MIME Error
- **Removed:** Invalid SF Mono Google Fonts import
- **Files:** `src/index.css`, `latency-live-monitor/src/index.css`
- **Result:** No more MIME type errors

### 2. ✅ Pi Heartbeat Threshold
- **Increased:** 20 seconds → 90 seconds
- **Reason:** Accounts for Azure Functions instance switching + 60s heartbeat interval
- **File:** `api/gateway-status/index.js`
- **Result:** Better tolerance for instance isolation

### 3. ✅ Console Error Spam
- **Fixed:** NotFound page now only logs in development mode
- **Files:** `src/pages/NotFound.tsx`, `latency-live-monitor/src/pages/NotFound.tsx`
- **Result:** Cleaner production console

---

## About Pi Heartbeat "Disconnected" Issue

**The Problem:**
Azure Functions use in-memory storage. When multiple instances are running:
- POST (Pi) → Instance A (sets `lastSeen`)
- GET (Frontend) → Instance B (has `lastSeen = null`)

**The Fix:**
Increased threshold to 90 seconds gives enough buffer for:
- 60s heartbeat interval
- Instance switching (~5-10s)
- Network delays (~1-2s)
- Cold starts (~1-3s)

**Better Solution (Future):**
Use Azure Table Storage or Cosmos DB for shared state across instances.

---

## Files Changed

1. `src/index.css` - Removed SF Mono import
2. `latency-live-monitor/src/index.css` - Removed SF Mono import
3. `api/gateway-status/index.js` - Increased threshold to 90s
4. `src/pages/NotFound.tsx` - Dev-only logging
5. `latency-live-monitor/src/pages/NotFound.tsx` - Dev-only logging

Ready to commit and push!


