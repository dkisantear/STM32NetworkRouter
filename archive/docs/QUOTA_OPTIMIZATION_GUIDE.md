# 🎯 Quota Optimization Guide

## The Problem

**Azure Static Web Apps Free Tier Limits:**
- **125,000 API requests/month**
- **100 GB bandwidth/month**

**Current Setup (if heartbeat every 15 seconds):**
- 5,760 requests/day
- 172,800 requests/month ❌ **EXCEEDS LIMIT!**

---

## Solution: Efficient Heartbeat Strategy

### Option 1: Increase Heartbeat Interval (Easiest)

**Every 60 seconds:**
- 1,440 requests/day
- 43,200 requests/month ✅ **Well under limit (34.6% usage)**

**Every 2 minutes (120 seconds):**
- 720 requests/day  
- 21,600 requests/month ✅ **Very safe (17.3% usage)**

**Every 5 minutes (300 seconds):**
- 288 requests/day
- 8,640 requests/month ✅ **Extremely safe (6.9% usage)**

---

### Option 2: Event-Driven Heartbeats (Smart)

Only send heartbeat when:
- ✅ Actual data/events occur
- ✅ Status changes (from disconnected to connected)
- ✅ Important events happen

This can reduce requests by **80-90%**!

---

### Option 3: Combined Data + Heartbeat (Efficient)

Instead of:
- Heartbeat POST
- Status GET (separate)
- Data POST (separate)

Do:
- Single POST with heartbeat + data together
- Reduces 3 requests to 1 request

---

## Recommended Settings

### For Active Monitoring (30-day window):
```python
HEARTBEAT_INTERVAL = 60  # 1 minute
# Usage: 43,200/month (34.6% of quota)
# Dashboard updates every 60 seconds
```

### For Basic Monitoring (just need to know if Pi is alive):
```python
HEARTBEAT_INTERVAL = 300  # 5 minutes
# Usage: 8,640/month (6.9% of quota)
# Dashboard updates every 5 minutes
```

### For Event-Driven (when you have actual data):
```python
# Only send when data/events occur
# Can reduce to <1,000/month
```

---

## Frontend Polling Optimization

Currently, your frontend polls every **1 second** - that's also using quota!

**Recommended changes:**
- Poll every **5-10 seconds** instead of 1 second
- Or use WebSockets/Server-Sent Events (if available)

---

## Implementation

### 1. Use the Efficient Heartbeat Script

I've created `pi_heartbeat_efficient.py` that:
- Uses 60-second intervals by default
- Shows quota usage calculations
- Has adaptive slowdown on failures
- Efficient and quota-aware

**On your Pi, run:**
```bash
python3 pi_heartbeat_efficient.py
```

Or in background:
```bash
nohup python3 pi_heartbeat_efficient.py > heartbeat.log 2>&1 &
```

### 2. Reduce Frontend Polling

Update `useGatewayStatus.ts` to poll less frequently:
- Change from 1 second to 5-10 seconds
- Saves significant quota

---

## Quota Calculation Formula

```
Requests/month = (3600 / interval_seconds) × 24 × 30

Examples:
- 15s: (3600/15) × 24 × 30 = 172,800 ❌
- 60s: (3600/60) × 24 × 30 = 43,200 ✅
- 120s: (3600/120) × 24 × 30 = 21,600 ✅
- 300s: (3600/300) × 24 × 30 = 8,640 ✅
```

---

## Recommendations

### ✅ Best for Most Users:
- **60-second heartbeat** (43k/month = 34% quota)
- **5-second frontend polling** (518k/month, but that's separate)
- Total: ~34% of API quota for heartbeats

### ✅ Most Efficient:
- **5-minute heartbeat** (8.6k/month = 7% quota)
- **10-second frontend polling**
- Total: ~7% of API quota for heartbeats

### ✅ Ultra Efficient (Event-Driven):
- Only send when data/events occur
- Could be <1,000/month
- Requires more code changes

---

## Next Steps

1. **Switch to efficient heartbeat script** (`pi_heartbeat_efficient.py`)
2. **Adjust interval** based on your needs (60s recommended)
3. **Monitor quota usage** in Azure Portal
4. **Reduce frontend polling** if needed

Would you like me to:
1. ✅ Update the heartbeat script to use 60-second intervals?
2. ✅ Reduce frontend polling frequency?
3. ✅ Create an event-driven version?

