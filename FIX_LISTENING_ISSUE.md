# Fix: Bridge Script Stuck on "Listening"

## Problem Found

The bridge script was using a different UART reading method than the working test script:

- **Test script (WORKS):** Uses `ser.readline()` - blocks until complete line received
- **Bridge script (DIDN'T WORK):** Uses `ser.in_waiting > 0` then `ser.read()` - only reads if data already waiting

## Fix Applied

Changed bridge script to use `ser.readline()` just like the working test script.

## What Changed

**Before:**
```python
if ser.in_waiting > 0:
    raw_data = ser.read(bytes_available)
    # Process data...
```

**After:**
```python
line = ser.readline().decode("utf-8", errors="ignore").strip()
if line:
    # Process line...
```

## Why This Works

`readline()`:
- ✅ Blocks and waits for complete line (with timeout)
- ✅ Reads until newline character `\n`
- ✅ Works with your STM32 sending `"STM32_ALIVE\n"`
- ✅ Same method as your working test script

## Next Steps

1. **Copy updated `pi_stm32_bridge.py` to your Pi**
2. **Restart the bridge:**
   ```bash
   pkill -f pi_stm32_bridge
   cd ~
   nohup python3 pi_stm32_bridge.py > bridge_output.log 2>&1 &
   ```
3. **Check logs:**
   ```bash
   tail -f ~/stm32-bridge.log
   ```

**You should now see:**
```
📥 Received: 'STM32_ALIVE'
✅ Status sent to Azure: online
```

## Expected Result

- ✅ Bridge receives messages every ~1 second
- ✅ Status stays "online" continuously
- ✅ Disconnect detection works (15 second timeout)
- ✅ No more "stuck on listening" issue

The bridge script now uses the **exact same reading method** as your working test script!

