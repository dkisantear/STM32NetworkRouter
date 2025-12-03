# Verify Bridge Script is Sending Status Messages

## The Issue
You're not seeing status messages (online/offline) when running the bridge.

## Quick Check on Your Pi

Run these commands to see what's happening:

```bash
# 1. Check if bridge script is actually running
ps aux | grep pi_stm32_bridge

# 2. Check the log file for status messages
tail -30 ~/stm32-bridge.log | grep -i "status\|heartbeat\|device id"

# 3. Check if status was sent recently
tail -30 ~/stm32-bridge.log
```

## Expected Output

When the bridge script starts, you should see:
```
============================================================
🚀 STM32 UART Bridge Starting
   UART Device: /dev/ttyAMA0
   Baudrate: 38400
   API URL: https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status
   Device ID: stm32-master  ← MUST show this!
   Log File: /home/pi5/stm32-bridge.log
============================================================
📡 Opening /dev/ttyAMA0...
✅ Serial port opened successfully!
✅ Status sent to Azure: online  ← Should see this!
✅ Initial status sent!
👂 Listening for STM32 messages...
```

Every 30 seconds you should see:
```
💓 Periodic heartbeat - sending online status to Azure
✅ Status sent to Azure: online
✅ Heartbeat sent successfully
```

## If You Don't See Status Messages

1. **Check which script you're running:**
   - Bridge script: `pi_stm32_bridge.py` (sends status to Azure)
   - Test script: `pi_uart_test.py` (just tests UART, doesn't send status)

2. **Verify the script has the right device ID:**
   ```bash
   grep "DEVICE_ID" pi_stm32_bridge.py
   ```
   Should show: `DEVICE_ID = "stm32-master"`

3. **Check for errors in logs:**
   ```bash
   grep -i "error\|failed" ~/stm32-bridge.log | tail -10
   ```

4. **Test Azure API manually:**
   ```bash
   curl -X POST "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status" \
     -H "Content-Type: application/json" \
     -d '{"deviceId":"stm32-master","status":"online"}'
   ```

