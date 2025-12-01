# Project Summary & Next Steps Prompt

## Current Status & Changes Made

I'm working on a latency monitoring system with STM32 → Raspberry Pi → Azure → Frontend architecture. Here's what we've accomplished and what needs to be done:

### ✅ Completed Changes

1. **Frontend Refactoring:**
   - Updated Main Server card to display STM32 connection status (instead of simulated latency)
   - Removed separate "STM32 Hub" status card for cleaner layout
   - Matched Main Server styling to Pi Gateway status pill (same colors, simple format)
   - Layout: Main Server (STM32 status) → Pi Gateway → Other servers

2. **Backend Architecture:**
   - Azure Function `/api/stm32-status` with Azure Table Storage integration
   - Handles GET (query by deviceId) and POST (update status)
   - 15-second timeout to automatically mark devices offline
   - PartitionKey: "stm32-devices", RowKey: deviceId

3. **Pi Infrastructure:**
   - UART communication verified working (`pi_uart_test.py` receives "STM32_ALIVE" messages)
   - Bridge script (`pi_stm32_bridge.py`) created to read UART and POST to Azure
   - Improved error handling with auto-recovery
   - Diagnostic scripts for troubleshooting

4. **Pi Scripts Created:**
   - `pi_stm32_bridge.py` - Reads UART, forwards status to Azure
   - `pi_uart_test.py` - Tests UART connection
   - `FIX_MAIN_SERVER_OFFLINE.sh` - Diagnoses and fixes bridge issues
   - `UART_DIAGNOSTIC_PI.sh` - Comprehensive UART diagnostic

### 🔧 Current Issue

**Problem:** Bridge script is not receiving UART messages from STM32, even though `pi_uart_test.py` successfully receives "STM32_ALIVE" messages.

**Possible Causes:**
1. Bridge script not running when STM32 is connected
2. Bridge script reading logic differs from test script
3. STM32 UART configuration mismatch
4. Timing/initialization issues

### 📋 What Needs to Be Done

#### 1. STM32 Code Integration
The STM32 is currently only set up for UART communication (hardware wiring complete), but we need to ensure:

**Verify STM32 Code:**
- STM32 should send "STM32_ALIVE\n" every 1 second via USART2
- Baud rate: 38400
- TX: PA2, RX: PA3
- Check if code is actually flashed and running
- Verify no errors in STM32 code compilation

**STM32 Code Requirements:**
```c
// Should have:
uint32_t stm32UartLastTick = 0;
// In main loop:
if (now - stm32UartLastTick >= 1000) {
    const char msg[] = "STM32_ALIVE\n";
    HAL_UART_Transmit(&huart2, (uint8_t*)msg, sizeof(msg) - 1, HAL_MAX_DELAY);
    stm32UartLastTick = now;
}
```

#### 2. Bridge Script Verification

**Check if bridge script is running:**
```bash
# On Pi
ps aux | grep pi_stm32_bridge
tail -f ~/stm32-bridge.log
```

**If not running, start it:**
```bash
cd ~
nohup python3 pi_stm32_bridge.py > bridge_output.log 2>&1 &
```

**Expected behavior:**
- Bridge opens `/dev/ttyAMA0` at 38400 baud
- Sends initial "online" status to Azure
- Reads UART continuously
- When "STM32_ALIVE" received → POST "online" to Azure
- If no message for 10 seconds → POST "offline" to Azure

#### 3. Verify Complete Pipeline

**Test each link:**
1. STM32 → Pi UART: `python3 pi_uart_test.py` (✅ Working - receives messages)
2. Pi → Azure: Bridge script should POST status updates
3. Azure → Frontend: Frontend polls `/api/stm32-status?deviceId=stm32-main` every 8 seconds

#### 4. Debugging Steps

**If bridge script is running but not receiving:**
1. Check if test script and bridge script can both access UART (maybe need to kill test first)
2. Compare `pi_uart_test.py` reading logic with `pi_stm32_bridge.py` reading logic
3. Check bridge script logs for errors
4. Verify STM32 is continuously sending (not just when test script runs)

**If bridge script receives but doesn't post to Azure:**
1. Check network connectivity from Pi
2. Verify Azure Function endpoint is correct
3. Check bridge script error logs
4. Test Azure connection manually from Pi

### 🎯 Success Criteria

The system will be working when:
1. ✅ STM32 sends "STM32_ALIVE" every 1 second (verified via test script)
2. ✅ Bridge script runs continuously in background
3. ✅ Bridge script receives UART messages and logs them
4. ✅ Bridge script POSTs "online" status to Azure when receiving messages
5. ✅ Azure Function stores status in Table Storage
6. ✅ Frontend Main Server card shows "Online" status with green indicator
7. ✅ Status updates in real-time (within 8-10 seconds)

### 📝 Files Reference

**Frontend:**
- `src/components/LatencyCard.tsx` - Main Server card (shows STM32 status)
- `src/components/StatusPill.tsx` - Pi Gateway status pill
- `src/hooks/useStm32Status.ts` - Hook to poll STM32 status
- `src/pages/Index.tsx` - Dashboard page

**Backend:**
- `api/stm32-status/index.js` - Azure Function
- `api/stm32-status/function.json` - Function config

**Pi Scripts:**
- `pi_stm32_bridge.py` - Bridge script (UART → Azure)
- `pi_uart_test.py` - UART test script
- `FIX_MAIN_SERVER_OFFLINE.sh` - Diagnostic/fix script

**Documentation:**
- `STM32_CONNECTION_PLAN.md` - Architecture overview
- `TESTING_GUIDE.md` - Testing instructions
- `FIX_UART_LISTENING_ISSUE.md` - UART troubleshooting

### 🚀 Next Immediate Steps

1. **Verify STM32 Code:**
   - Check if STM32 code includes UART heartbeat
   - Verify code is flashed to STM32
   - Confirm STM32 is powered and running

2. **Start Bridge Script:**
   - Run `FIX_MAIN_SERVER_OFFLINE.sh` on Pi
   - Or manually: `nohup python3 ~/pi_stm32_bridge.py > bridge_output.log 2>&1 &`
   - Monitor logs: `tail -f ~/stm32-bridge.log`

3. **Verify Pipeline:**
   - Check bridge logs show "📥 Received: 'STM32_ALIVE'"
   - Check bridge logs show "✅ Status sent to Azure: online"
   - Check Azure: `curl "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main"`
   - Check frontend Main Server card shows "Online"

4. **Debug if Needed:**
   - Compare bridge script reading logic with test script
   - Check for port conflicts (test script vs bridge script)
   - Verify STM32 sends continuously, not just when test runs

---

**Please help me:**
1. Review the bridge script's UART reading logic vs the test script
2. Identify why bridge script might not be receiving messages (even though test script does)
3. Suggest improvements to ensure bridge script reliably receives STM32 messages
4. Verify the complete pipeline works end-to-end

