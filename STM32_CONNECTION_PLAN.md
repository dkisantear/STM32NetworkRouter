# STM32 Connection Plan

## 🎯 Goal
Show STM32 connection status on the **Main Server** card, replacing simulated data.

## 📊 Current Architecture

```
STM32 (Main Board)
    ↓ (UART @ 38400 baud)
Raspberry Pi 5
    ↓ (HTTP POST to Azure)
Azure Function (/api/stm32-status)
    ↓ (Stored in Azure Table Storage)
Frontend Dashboard
    ↓ (HTTP GET from Azure)
Main Server Card (shows STM32 status)
```

## ✅ What's Already Working

1. ✅ **STM32 Code**: Sends "STM32_ALIVE\n" every 1 second via UART2
2. ✅ **Pi Bridge Script**: `pi_stm32_bridge.py` reads UART and POSTs to Azure
3. ✅ **Azure Function**: `/api/stm32-status` stores status in Table Storage
4. ✅ **Frontend Hook**: `useStm32Status.ts` polls Azure every 8 seconds

## 🔧 Changes Needed

### 1. Update Main Server Card
- **File**: `src/components/LatencyCard.tsx`
- **Change**: When `server="main"`, show STM32 connection status instead of latency
- **Display**:
  - Status indicator (Online/Offline/Unknown)
  - "STM32 → Pi → Azure" connection path
  - Last updated timestamp
  - Remove latency chart/numbers for Main Server

### 2. Remove STM32 Hub Card
- **File**: `src/pages/Index.tsx`
- **Change**: Remove `<Stm32StatusPill />` component
- **Reason**: Status now shown in Main Server card

### 3. Keep Other Cards
- **UART Server 2** and **Serial Server 3**: Keep as-is (for future boards)
- **Raspberry Pi Gateway → Azure**: Keep (shows Pi connection status)

## 🧪 Testing Steps

### Step 1: Verify STM32 → Pi UART
```bash
# On Pi, test UART connection
python3 pi_uart_test.py
# Should see: "STM32_ALIVE" messages every second
```

### Step 2: Verify Pi → Azure
```bash
# On Pi, check bridge script is running
ps aux | grep pi_stm32_bridge

# Check logs
tail -f ~/stm32-bridge.log
# Should see: "Status sent to Azure: online"
```

### Step 3: Verify Azure → Frontend
```bash
# Test Azure Function directly
curl "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main"
# Should return: {"deviceId":"stm32-main","status":"online","lastUpdated":"..."}
```

### Step 4: Verify Frontend Display
1. Open dashboard in browser
2. **Main Server** card should show:
   - ✅ Green indicator if STM32 is online
   - ❌ Red indicator if STM32 is offline
   - "STM32 → Pi → Azure" label
   - Last updated time

## 📋 Final Layout

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
│  │ [Latency chart - for future]  │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ Serial Server 3               │  │
│  │ [Latency chart - for future]  │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## 🚀 Next Steps (After This Works)

Once STM32 connection is working:
1. Connect additional boards to STM32 (master)
2. Add status cards for each board
3. Implement communication protocol between boards

