# Critical Fixes Applied

## Problems Fixed:

### 1. ✅ Command API 404 Error
**Problem:** `/api/stm32-command` was returning 404 when trying to mark commands as "sent"

**Root Cause:** The `function.json` was missing the `PUT` method - only had `GET` and `POST`

**Fix:** Added `"put"` to the methods array in `api/stm32-command/function.json`

### 2. ✅ Command Spam (Infinite Loop)
**Problem:** Same commands were being fetched and processed repeatedly, creating log spam

**Root Cause:** When marking commands failed (404 error), they weren't being tracked as processed, so they kept being fetched

**Fix:** 
- Added command tracking to prevent duplicate processing
- Commands are now tracked after sending (even if marking fails)
- Prevents infinite loops

### 3. ⚠️ STM32 Not Detected as Online
**Problem:** No "📥 Received" messages, so STM32 status stays offline

**Possible Causes:**
- STM32 not sending data via UART
- UART wiring issue
- Baud rate mismatch
- STM32 UART not enabled/configured correctly

**Next Steps to Debug:**
1. Test if STM32 is sending: `python3 pi_check_stm32_sending.py`
2. Verify wiring: Pi GPIO14 (TX) → STM32 RX, Pi GPIO15 (RX) → STM32 TX
3. Check baud rate matches (38400)
4. Verify STM32 code is sending heartbeat messages

## What You Need to Do:

### 1. Deploy the Fixed API
The Azure Function needs to be redeployed to include the PUT method:

```bash
# From your repo directory
# Deploy the updated function.json
```

### 2. Update Bridge Script on Pi
```bash
# Copy updated script
scp pi_stm32_bridge.py pi5@192.168.1.160:~/

# SSH and restart
ssh pi5@192.168.1.160
pkill -f pi_stm32_bridge.py
python3 ~/pi_stm32_bridge.py
```

### 3. Test Command Spam is Fixed
- Commands should only be processed once
- No more infinite loops of the same commands
- Logs should be much cleaner

### 4. Debug STM32 Connection
Run the test script to see if STM32 is sending data:
```bash
python3 pi_check_stm32_sending.py
```

## Expected Behavior After Fixes:

✅ Commands processed once (no spam)
✅ Commands can be marked as "sent" (PUT method works)
✅ Clean logs without repetition
✅ STM32 will show "online" when it actually sends data

