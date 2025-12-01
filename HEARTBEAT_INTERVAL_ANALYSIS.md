# Heartbeat Interval Analysis - Quota Impact

## Current Configuration

- **Pi Heartbeat**: Every 60 seconds (POST requests)
- **Frontend Polling**: Every 8 seconds (GET requests)
- **Timeout**: 90 seconds (auto-offline detection)

---

## Quota Calculations

### Azure Static Web Apps Free Tier Limits:
- **Function Executions**: 125,000 per month
- **Data Transfer**: 100 GB per month

### Current Setup (60s heartbeat):
- Pi POST requests: 60/hour = 1,440/day = **43,200/month** ✅
- Frontend GET requests: 450/hour = 10,800/day = **324,000/month** ⚠️
- **Total**: ~367,200 requests/month
- **Status**: ⚠️ Exceeds quota (but GET requests might be cheaper/uncounted differently)

### If Changed to 15s heartbeat:
- Pi POST requests: 240/hour = 5,760/day = **172,800/month** ❌
- Frontend GET requests: 450/hour = 10,800/day = **324,000/month** ⚠️
- **Total**: ~496,800 requests/month
- **Status**: ❌ Definitely exceeds quota

---

## Better Options

### Option 1: 30 Seconds (Recommended Balance)
- Pi POST requests: 120/hour = 2,880/day = **86,400/month** ✅
- Status updates: Faster (15-30s delay max)
- Still within quota comfortably

### Option 2: 45 Seconds (Good Balance)
- Pi POST requests: 80/hour = 1,920/day = **57,600/month** ✅
- Status updates: Moderate speed (45-53s delay max)
- Very safe for quota

### Option 3: 20 Seconds (Fast Updates)
- Pi POST requests: 180/hour = 4,320/day = **129,600/month** ⚠️
- Status updates: Very fast (20-28s delay max)
- Close to quota limit (risky if running 24/7)

---

## Recommendations

**Best Balance**: **30 seconds**
- ✅ Faster than current (60s)
- ✅ Still quota-safe (86k/month vs 125k limit)
- ✅ Good user experience (updates within 30-38s)
- ✅ Works well with 90s timeout (gives 60s buffer)

**If You Want Faster**: **20 seconds**
- ✅ Very responsive
- ⚠️ Close to quota (129k/month)
- ✅ Still works with 90s timeout

**15 seconds is NOT recommended** - would exceed quota limit!

---

## How to Change It

Just update one number in the Python script on your Pi:

```python
HEARTBEAT_INTERVAL = 30  # Change from 60 to 30 (or 20, or 45)
```

Then restart the service:
```bash
sudo systemctl restart gateway-heartbeat.service
```

---

## Accuracy Impact

- **60s**: Status updates within 60-68 seconds (60s heartbeat + 8s polling)
- **30s**: Status updates within 30-38 seconds (30s heartbeat + 8s polling)
- **20s**: Status updates within 20-28 seconds (20s heartbeat + 8s polling)
- **15s**: Status updates within 15-23 seconds (15s heartbeat + 8s polling)

**All are accurate!** The timeout logic ensures status is always correct regardless of interval.

---

## My Recommendation

**Use 30 seconds** - best balance of speed and quota efficiency.

Want me to update the script to 30 seconds?

