# STM32 Integration Summary

## ✅ What Was Created

### 1. Pi Script: `pi_stm32_bridge.py`
- Reads STM32 heartbeat messages from UART (`/dev/ttyAMA0` at 38400 baud)
- Forwards status to Azure Function `/api/stm32-status`
- Automatically marks STM32 as offline if no messages received for 10 seconds
- Logs to `~/stm32-bridge.log`

### 2. Azure Function: `/api/stm32-status`
- **Location**: `api/stm32-status/`
- **Files**: `function.json` and `index.js`
- Uses Azure Table Storage (same table as gateway-status, different partition)
- **Partition Key**: `"stm32"`
- **Row Key**: Device ID (e.g., `"stm32-main"`)
- Supports GET and POST methods
- Automatic timeout detection (90 seconds)

### 3. Frontend Hook: `useStm32Status.ts`
- **Location**: `src/hooks/useStm32Status.ts`
- Polls `/api/stm32-status?deviceId=stm32-main` every 8 seconds
- Returns: `{ deviceId, status, lastUpdated, loading, error }`

### 4. Frontend Component: `Stm32StatusPill.tsx`
- **Location**: `src/components/Stm32StatusPill.tsx`
- Displays STM32 status card with green indicator for online
- Shows "Last updated" timestamp
- Integrated into main dashboard

### 5. Test Script: `test_uart_connection.sh`
- Quick verification script to test UART connection
- Checks device exists and listens for messages

---

## 📋 Configuration

### Azure Environment Variable
- Uses existing `TABLES_CONNECTION_STRING` (same as gateway-status)
- No additional configuration needed!

### Pi Script Configuration
Edit `pi_stm32_bridge.py` if needed:
- `API_URL`: Azure Static Web App URL
- `DEVICE_ID`: Default is `"stm32-main"`
- `UART_DEVICE`: Default is `"/dev/ttyAMA0"`
- `UART_BAUDRATE`: Default is `38400`

---

## 🚀 Deployment Steps

### Step 1: Deploy Azure Function
The function is already in the repo and will be deployed automatically with the next push.

### Step 2: Deploy Frontend
Frontend changes will be deployed automatically with the next push.

### Step 3: Set Up Pi Script

1. **Copy script to Pi:**
   ```bash
   scp pi_stm32_bridge.py pi@<pi-ip>:~/stm32-bridge/
   ```

2. **Install dependencies on Pi:**
   ```bash
   pip3 install pyserial requests --break-system-packages
   ```

3. **Make executable:**
   ```bash
   chmod +x pi_stm32_bridge.py
   ```

4. **Test run:**
   ```bash
   python3 pi_stm32_bridge.py
   ```

5. **Run in background:**
   ```bash
   nohup python3 pi_stm32_bridge.py > /dev/null 2>&1 &
   ```

6. **Or create systemd service** (similar to gateway heartbeat service)

---

## 🧪 Testing

### Test UART Connection
Run on Pi:
```bash
bash test_uart_connection.sh
```

### Test Azure Function
```bash
# POST status
curl -X POST "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status" \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"stm32-main","status":"online"}'

# GET status
curl "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main"
```

### Test Frontend
1. Deploy changes
2. Visit the dashboard
3. Look for "STM32 Hub → Azure" status card
4. Should show "Online" when STM32 is sending

---

## 📊 Data Flow

```
STM32 (PA2 TX) → UART (/dev/ttyAMA0) → Pi Python Script → Azure Function → Table Storage
                                                                                ↓
                                                                    Frontend Hook (polls every 8s)
                                                                                ↓
                                                                    STM32 Status Card (displays)
```

---

## ✅ Files Created/Modified

### New Files:
- `pi_stm32_bridge.py` - Pi script to bridge UART to Azure
- `api/stm32-status/function.json` - Azure Function config
- `api/stm32-status/index.js` - Azure Function handler
- `src/hooks/useStm32Status.ts` - Frontend hook
- `src/components/Stm32StatusPill.tsx` - Frontend component
- `latency-live-monitor/src/hooks/useStm32Status.ts` - Hook (duplicate)
- `latency-live-monitor/src/components/Stm32StatusPill.tsx` - Component (duplicate)
- `test_uart_connection.sh` - Test script

### Modified Files:
- `src/pages/Index.tsx` - Added Stm32StatusPill component
- `latency-live-monitor/src/pages/Index.tsx` - Added Stm32StatusPill component

---

## 🎯 Next Steps

1. ✅ Code is ready
2. ⏳ Push to GitHub (will trigger Azure deployment)
3. ⏳ Test UART connection with `test_uart_connection.sh`
4. ⏳ Deploy Pi script and start bridge
5. ⏳ Verify status appears on frontend dashboard

---

## 📝 Notes

- Uses same Table Storage as gateway-status (different partition)
- 90-second timeout for automatic offline detection
- Pi script has 10-second timeout before marking offline
- Frontend polls every 8 seconds
- Green indicator for STM32 online status

