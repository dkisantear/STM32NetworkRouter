# Fix Main Server Offline Status

## Current Situation

✅ **STM32 MSP Code Flashed** - UART hardware configured  
❌ **Frontend shows "Offline"** - Status not updating  

## Quick Diagnosis Steps

### Step 1: Verify STM32 is Sending Messages

**On Pi, run:**
```bash
python3 pi_uart_test.py
```

**Expected:** Should see "STM32_ALIVE" messages every ~1 second

**If NO messages:**
- ❌ STM32 code might not have the UART send logic in main.c
- ❌ STM32 might not be powered/running
- ❌ Wiring issue

**If YES messages:**
- ✅ STM32 is working
- ⚠️ Continue to Step 2

---

### Step 2: Check Bridge Script is Running

**On Pi:**
```bash
ps aux | grep pi_stm32_bridge
```

**If NOT running:**
```bash
# Start it:
cd ~
nohup python3 pi_stm32_bridge.py > bridge_output.log 2>&1 &
```

**Check logs:**
```bash
tail -f ~/stm32-bridge.log
```

**Look for:**
- ✅ "📥 Received: 'STM32_ALIVE'" - Bridge is receiving messages
- ✅ "✅ Status sent to Azure: online" - Status is being posted
- ❌ "❌ Failed to send status" - Network/Azure issue

---

### Step 3: Verify Azure Status

**Test Azure Function:**
```bash
curl "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main"
```

**Expected response:**
```json
{
  "deviceId": "stm32-main",
  "status": "online",
  "lastUpdated": "2025-01-30T..."
}
```

**If shows "offline" or "unknown":**
- Bridge script may not be sending status
- Check bridge logs for errors

---

### Step 4: Manual Status Test

**Send manual status to Azure:**
```bash
python3 << 'EOF'
import requests
response = requests.post(
    "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status",
    json={"deviceId": "stm32-main", "status": "online"},
    headers={"Content-Type": "application/json"},
    timeout=10
)
print(f"Status: {response.json()}")
EOF
```

**After running this:**
- Refresh your browser
- Main Server should show "Online" temporarily
- If it does → Problem is bridge script not running
- If it doesn't → Problem is frontend or Azure

---

## Most Likely Issues

### Issue 1: Bridge Script Not Running

**Symptom:** UART test works, but Azure shows offline

**Fix:**
```bash
# Kill any existing bridge
pkill -f pi_stm32_bridge

# Start bridge
cd ~
nohup python3 pi_stm32_bridge.py > bridge_output.log 2>&1 &

# Check it started
ps aux | grep pi_stm32_bridge

# Monitor logs
tail -f ~/stm32-bridge.log
```

---

### Issue 2: STM32 Not Sending Continuously

**Symptom:** UART test works when you run it, but bridge doesn't receive

**Possible cause:** STM32 only sends when Pi is "listening" (unlikely, but possible)

**Fix:** Verify STM32 code sends every 1 second regardless of receiver:
```c
// In main loop, should have:
if (now - stm32UartLastTick >= 1000) {
    const char msg[] = "STM32_ALIVE\n";
    HAL_UART_Transmit(&huart2, (uint8_t*)msg, sizeof(msg) - 1, HAL_MAX_DELAY);
    stm32UartLastTick = now;
}
```

---

### Issue 3: Bridge Script Reading Logic

**Symptom:** Test script receives, bridge doesn't

**Check:** Bridge script uses same UART device and baud rate:
- Device: `/dev/ttyAMA0`
- Baud: `38400`
- Both scripts should use identical serial.Serial() parameters

---

## Complete Verification Script

Run the comprehensive verification script:

```bash
# Copy VERIFY_STM32_PIPELINE.sh to Pi and run it
```

This script will:
1. ✅ Test STM32 UART reception
2. ✅ Check if bridge is running
3. ✅ Verify bridge is receiving messages
4. ✅ Check Azure status
5. ✅ Send test status
6. ✅ Provide diagnostics

---

## Quick Fix Command

If bridge script isn't running, use this one-liner:

```bash
pkill -f pi_stm32_bridge; cd ~ && nohup python3 pi_stm32_bridge.py > bridge_output.log 2>&1 & sleep 3 && tail -20 ~/stm32-bridge.log
```

This will:
- Stop any existing bridge
- Start bridge script
- Wait 3 seconds
- Show recent logs

---

## Next Steps

1. **Run verification script:** `VERIFY_STM32_PIPELINE.sh` on Pi
2. **Check bridge logs:** `tail -f ~/stm32-bridge.log`
3. **Verify Azure:** Check status via curl
4. **Refresh frontend:** After fixing, refresh browser

If still offline after all checks, the issue is likely:
- Bridge script not running
- Bridge script not receiving messages (even though test does)
- Network issue preventing Azure POST requests

