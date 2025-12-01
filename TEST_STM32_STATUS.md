# Test STM32 Status Integration

## Current Status: "Unknown"

This means Azure hasn't received any data from the Pi bridge script yet.

## Step-by-Step Testing

### Step 1: Verify UART is Still Working (on Pi)

```bash
# Run the test script
python3 pi_uart_test.py
```

**Expected:** Should see "STM32_ALIVE" messages every ~1 second

**If not working:** Fix UART connection first

---

### Step 2: Test Azure Function Directly

Test if the Azure Function is deployed and working:

```bash
# GET current status (should return "unknown")
curl "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main"

# POST a test status (should return "online")
curl -X POST "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status" \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"stm32-main","status":"online"}'

# GET again (should now return "online")
curl "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main"
```

**Expected:** 
- First GET: `{"deviceId":"stm32-main","status":"unknown","lastUpdated":null}`
- POST response: `{"deviceId":"stm32-main","status":"online","lastUpdated":"..."}`
- Second GET: `{"deviceId":"stm32-main","status":"online","lastUpdated":"..."}`

**If POST fails:** Azure Function might not be deployed yet

---

### Step 3: Start Pi Bridge Script

On your Raspberry Pi:

```bash
# Navigate to script location
cd ~/stm32-bridge  # or wherever you put the script

# Make sure dependencies are installed
pip3 install pyserial requests --break-system-packages

# Start the script
python3 pi_stm32_bridge.py
```

**Expected:** Should see:
- "Serial port opened successfully!"
- "Status sent to Azure: online"
- Receiving UART messages

**If errors:** Check logs or see troubleshooting below

---

### Step 4: Check Dashboard

After starting the Pi script, refresh your dashboard. Within 8 seconds (polling interval), you should see:
- Status change from "Unknown" to "Online"
- Green dot appear
- "Last updated" timestamp

---

## Troubleshooting

### Azure Function Returns 404

The function might not be deployed yet. Check:
1. GitHub Actions build succeeded
2. Function exists at: `/api/stm32-status`
3. Try waiting a few minutes for deployment

### UART Not Working

1. Check wiring: STM32 PA2 (TX) → Pi Pin 10 (RXD)
2. Verify device: `/dev/ttyAMA0` exists
3. Test with `pi_uart_test.py` first

### Pi Script Errors

Common issues:
1. **Permission denied**: `sudo usermod -a -G dialout $USER` (then logout/login)
2. **Module not found**: `pip3 install pyserial requests --break-system-packages`
3. **Serial port error**: Check UART is enabled in `raspi-config`

### Status Stays "Unknown"

1. Check Pi script is actually running
2. Check Pi script logs: `tail -f ~/stm32-bridge.log`
3. Verify API URL is correct in script
4. Check network connection from Pi to Azure

---

## Quick Commands

### On Pi:

```bash
# Test UART
python3 pi_uart_test.py

# Start bridge (foreground)
python3 pi_stm32_bridge.py

# Start bridge (background)
nohup python3 pi_stm32_bridge.py > /dev/null 2>&1 &

# Check if running
ps aux | grep pi_stm32_bridge

# View logs
tail -f ~/stm32-bridge.log

# Stop bridge
pkill -f pi_stm32_bridge.py
```

### On Your Computer:

```bash
# Test Azure Function
curl "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main"

# Send test status
curl -X POST "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status" \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"stm32-main","status":"online"}'
```



