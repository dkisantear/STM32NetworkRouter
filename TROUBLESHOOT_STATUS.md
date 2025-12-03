# Troubleshoot: Not Seeing Status Messages

## Which Script Are You Running?

The output you showed:
```
📡 Opening /dev/serial0...
✅ Serial port opened successfully!
👂 Listening for STM32 messages...
   Expected: 'STM32_ALIVE' every ~1 second
```

This is from `pi_uart_test.py` (test script) - it does NOT send status to Azure.

## The Bridge Script Should Show:

When you run `pi_stm32_bridge.py`, you should see:

```
============================================================
🚀 STM32 UART Bridge Starting
   UART Device: /dev/ttyAMA0
   Baudrate: 38400
   API URL: https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status
   Device ID: stm32-master  ← IMPORTANT!
   Log File: /home/pi5/stm32-bridge.log
============================================================
📡 Opening /dev/ttyAMA0...
✅ Serial port opened successfully!
✅ Status sent to Azure: online  ← Should see this!
✅ Initial status sent!
👂 Listening for STM32 messages...
```

Every 30 seconds:
```
💓 Periodic heartbeat - sending online status to Azure
✅ Status sent to Azure: online
✅ Heartbeat sent successfully
```

## Check Your Bridge Script Status

On your Pi, run:

```bash
# 1. Check if bridge is running
ps aux | grep pi_stm32_bridge

# 2. Check the log file
tail -50 ~/stm32-bridge.log

# 3. Look for status messages
grep -i "status\|heartbeat\|device id" ~/stm32-bridge.log | tail -10
```

## If Status Messages Are Missing

1. **Verify device ID:**
   ```bash
   grep "DEVICE_ID" pi_stm32_bridge.py
   ```
   Must show: `DEVICE_ID = "stm32-master"`

2. **Check for errors:**
   ```bash
   grep -i "error\|failed" ~/stm32-bridge.log | tail -10
   ```

3. **Verify Azure API is reachable:**
   ```bash
   curl -X POST "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status" \
     -H "Content-Type: application/json" \
     -d '{"deviceId":"stm32-master","status":"online"}'
   ```

