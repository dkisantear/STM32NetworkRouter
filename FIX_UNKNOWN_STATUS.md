# Fix "Unknown" Status Issue

## Why Status Shows "Unknown"

The status is "unknown" because:
1. ✅ Azure Function is working (returns "unknown" correctly)
2. ❌ Pi bridge script hasn't sent any data yet, OR
3. ❌ Script sent data but there's a connection issue

## Quick Diagnosis

### Check if Bridge Script is Running

On Pi, run:
```bash
ps aux | grep pi_stm32_bridge
```

If nothing shows, the script isn't running.

### Check Bridge Script Logs

```bash
tail -f ~/stm32-bridge.log
```

Look for:
- "Status sent to Azure: online" ✅ Good!
- "Failed to send status" ❌ Problem
- "Serial port error" ❌ UART problem

### Manually Test Azure Connection

On Pi:
```bash
python3 << 'EOF'
import requests
response = requests.post(
    "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status",
    json={"deviceId": "stm32-main", "status": "online"},
    headers={"Content-Type": "application/json"},
    timeout=10
)
print(response.json())
EOF
```

Should return: `{"deviceId": "stm32-main", "status": "online", "lastUpdated": "..."}`

## Common Fixes

### Fix 1: Script Not Running

Start it:
```bash
nohup python3 ~/pi_stm32_bridge.py > /dev/null 2>&1 &
```

### Fix 2: UART Not Working

Test UART first:
```bash
python3 pi_uart_test.py
```

### Fix 3: Network Issue

Test from Pi:
```bash
curl "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main"
```

### Fix 4: Send Initial Status

The bridge script should send an "online" status immediately when it starts. If it doesn't, restart it:
```bash
pkill -f pi_stm32_bridge.py
python3 ~/pi_stm32_bridge.py
```

## Complete Automatic Setup

Run the automatic setup script:
```bash
# Copy/paste SETUP_STM32_BRIDGE_AUTOMATIC.sh into Pi terminal
```

This will:
1. ✅ Install dependencies
2. ✅ Create bridge script
3. ✅ Test UART
4. ✅ Test Azure connection
5. ✅ Start bridge script
6. ✅ Verify status updates
7. ✅ Create systemd service for auto-start



