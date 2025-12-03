# Diagnose Master STM32 Status Issue

## Current Situation
- ✅ Frontend expects: `stm32-master`
- ✅ API has entry for: `stm32-master`
- ❌ Status shows: `offline` (last updated at 10:41:40)
- ✅ Your logs show heartbeats sending every 30 seconds

## Problem
The bridge script might be sending status with wrong device ID OR it stopped running.

## Quick Diagnosis Commands (Run on Pi)

### 1. Check what device ID the script is using:
```bash
grep "DEVICE_ID" pi_stm32_bridge.py
```

**Should show:** `DEVICE_ID = "stm32-master"`

### 2. Check if script is still running:
```bash
ps aux | grep pi_stm32_bridge
```

### 3. Check startup logs for device ID:
```bash
grep "Device ID:" ~/stm32-bridge.log | tail -1
```

**Should show:** `Device ID: stm32-master`

### 4. Check recent heartbeat logs:
```bash
tail -20 ~/stm32-bridge.log | grep "heartbeat\|Status sent"
```

## If Device ID is Wrong

Edit the file:
```bash
nano pi_stm32_bridge.py
```

Change line 18:
- FROM: `DEVICE_ID = "stm32-main"`  
- TO: `DEVICE_ID = "stm32-master"`

Save and restart:
```bash
pkill -f pi_stm32_bridge.py
python3 pi_stm32_bridge.py
```

## Expected Behavior
After fixing, within 30 seconds you should see:
- Frontend shows: "Online" with green indicator
- API shows: `status: "online"` with recent timestamp

