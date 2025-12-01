# Testing Guide: STM32 Connection Status

## ✅ Changes Made

1. **Main Server Card** now shows STM32 connection status (instead of simulated latency)
2. **Removed** separate "STM32 Hub" card
3. **Kept** Raspberry Pi Gateway status card
4. **Kept** UART Server 2 and Serial Server 3 (for future boards)

## 🧪 Testing Checklist

### Step 1: Verify STM32 → Pi UART Connection

**On Raspberry Pi:**
```bash
# Test UART communication
python3 pi_uart_test.py
```

**Expected Output:**
```
Listening for STM32 messages on /dev/ttyAMA0 @ 38400 baud...
Received: STM32_ALIVE
Received: STM32_ALIVE
Received: STM32_ALIVE
...
```

**If you see messages:** ✅ UART is working  
**If no messages:** ❌ Check:
- STM32 is powered and running
- UART wiring (TX→RX, RX→TX, GND shared)
- UART enabled: `sudo raspi-config → Interface Options → Serial Port`

---

### Step 2: Verify Pi → Azure Bridge

**On Raspberry Pi:**
```bash
# Check if bridge script is running
ps aux | grep pi_stm32_bridge

# Check bridge logs
tail -f ~/stm32-bridge.log
```

**Expected Log Output:**
```
✅ Serial port opened successfully!
✅ Status sent to Azure: online
📥 Received: STM32_ALIVE
✅ Status sent to Azure: online
```

**If bridge is running:** ✅ Good  
**If not running:** Start it:
```bash
# Copy/paste KEEP_BRIDGE_RUNNING.sh into Pi terminal
```

---

### Step 3: Verify Azure Function

**From any computer (or Pi):**
```bash
# Test Azure Function directly
curl "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main"
```

**Expected Response:**
```json
{
  "deviceId": "stm32-main",
  "status": "online",
  "lastUpdated": "2025-01-30T20:30:00.000Z"
}
```

**If you get "online":** ✅ Azure is working  
**If you get "unknown":** ❌ Pi bridge hasn't sent status yet  
**If you get "offline":** ❌ No STM32 messages received in last 15 seconds

---

### Step 4: Verify Frontend Display

**Open dashboard in browser:**
```
https://blue-desert-0c2a27e1e.3.azurestaticapps.net
```

**Check Main Server Card:**
- ✅ **Green indicator** = STM32 is online
- ❌ **Red indicator** = STM32 is offline
- ⚪ **Gray indicator** = Status unknown (loading or error)

**Card should show:**
- "Main Server" title
- "STM32 → Pi → Azure" connection path
- Status: "Online" / "Offline" / "Unknown"
- "Last updated: Xs ago" (if status is known)

---

## 🔧 Troubleshooting

### Problem: Main Server shows "Unknown"

**Possible Causes:**
1. Pi bridge script not running
2. Azure Function not receiving POST requests
3. Frontend can't reach Azure API

**Fix:**
```bash
# On Pi, check bridge status
ps aux | grep pi_stm32_bridge
tail -f ~/stm32-bridge.log

# Restart bridge if needed
pkill -f pi_stm32_bridge
# Then run KEEP_BRIDGE_RUNNING.sh
```

---

### Problem: Main Server shows "Offline" but STM32 is connected

**Possible Causes:**
1. UART connection broken
2. STM32 stopped sending "STM32_ALIVE"
3. Pi bridge timeout (15 seconds)

**Fix:**
```bash
# Test UART directly
python3 pi_uart_test.py

# Check bridge logs for timeout warnings
tail -f ~/stm32-bridge.log | grep timeout
```

---

### Problem: Status flickers between Online/Offline

**Possible Causes:**
1. Intermittent UART connection
2. Network issues between Pi and Azure
3. STM32 sending messages too slowly

**Fix:**
- Check UART wiring connections
- Verify STM32 is sending "STM32_ALIVE" every 1 second
- Check Pi network connection

---

## 📊 Expected Dashboard Layout

```
┌─────────────────────────────────────┐
│  LatencyNet — Live View            │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐  │
│  │ Main Server                  │  │
│  │ 🟢 STM32 → Pi → Azure        │  │
│  │    Online                     │  │
│  │    Last updated: 5s ago      │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ Raspberry Pi Gateway → Azure │  │
│  │ 🟢 Online                     │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ UART Server 2                 │  │
│  │ [Latency chart - simulated]   │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ Serial Server 3               │  │
│  │ [Latency chart - simulated]   │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

## ✅ Success Criteria

You'll know it's working when:
1. ✅ STM32 sends "STM32_ALIVE" every second (visible in `pi_uart_test.py`)
2. ✅ Pi bridge script is running and logging status updates
3. ✅ Azure Function returns `{"status": "online"}` when queried
4. ✅ Main Server card shows **green indicator** and "Online" status
5. ✅ "Last updated" timestamp updates every 8 seconds

---

## 🚀 Next Steps (After This Works)

Once STM32 connection is verified:
1. Connect additional boards to STM32 (master)
2. Implement communication protocol between boards
3. Add status cards for each board
4. Replace simulated data for other servers

