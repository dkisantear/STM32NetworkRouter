# Fixed Bridge Script - Quick Update

## What Was Fixed:

✅ **Detects ANY UART activity** - marks "online" immediately when data detected (not just perfect messages)
✅ **Handles gibberish/partial messages** - no more splitting errors
✅ **More responsive** - faster detection (50ms loop)
✅ **Flushes stale data** - clean connection on startup
✅ **Better timeout** - accurately detects when STM32 disconnects

## Quick Update (One Command)

From your **Windows PowerShell** (in this repo directory):

```powershell
scp pi_stm32_bridge.py pi5@192.168.1.160:~/
```

Then SSH into Pi and run:
```bash
ssh pi5@192.168.1.160
pkill -f pi_stm32_bridge.py
python3 ~/pi_stm32_bridge.py
```

## What You Should See Now:

**When STM32 is unplugged:**
```
✅ Initial status sent: offline (waiting for STM32 heartbeat...)
```

**When you plug in STM32:**
```
✅ Detected UART activity - marking as online
📥 Received: 'STM32_ALIVE' (or whatever data it sends)
```

**When you unplug STM32:**
```
⚠️  No STM32 activity for 10.0s - marking as offline
```

## The Fix:

The script now:
- Marks "online" as soon as it detects ANY data on UART (even partial/corrupted)
- No longer requires perfect message parsing
- Handles gibberish gracefully without crashing
- More responsive connection detection

