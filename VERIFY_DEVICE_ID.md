# Verify Device ID is Correct

Your logs show heartbeats are working, but we need to verify the device ID matches.

## Quick Check on Your Pi

SSH into your Pi and run:

```bash
# Check what device ID the script is using
grep "DEVICE_ID" pi_stm32_bridge.py
```

**Should show:**
```
DEVICE_ID = "stm32-master"
```

**If it shows:**
```
DEVICE_ID = "stm32-main"
```

Then you need to update it!

## Also Check Recent Logs

```bash
# Check what device ID was logged when script started
grep "Device ID:" ~/stm32-bridge.log | tail -1
```

**Should show:**
```
Device ID: stm32-master
```

## If Device ID is Wrong

Edit the file:
```bash
nano pi_stm32_bridge.py
```

Find line 18 and change:
- FROM: `DEVICE_ID = "stm32-main"`
- TO: `DEVICE_ID = "stm32-master"`

Save (Ctrl+X, Y, Enter) and restart:
```bash
pkill -f pi_stm32_bridge.py
python3 pi_stm32_bridge.py
```

## Frontend Expects

The frontend is looking for: `stm32-master`

Make sure your bridge script uses the same!

