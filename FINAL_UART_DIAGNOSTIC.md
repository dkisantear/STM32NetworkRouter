# Final UART Diagnostic - Step by Step

## ✅ Confirmed:
- STM32 pinout is correct (PA2 = TX, PA3 = RX)
- STM32 code has heartbeat
- STM32 is powered and running

## The Problem is on Pi Side

### Step 1: Check UART is Enabled on Pi

```bash
# Check if UART is enabled
vcgencmd get_config enable_uart
```

If it shows nothing or `enable_uart=0`, you need to enable it:

```bash
sudo nano /boot/config.txt
```

Add this line at the end:
```
enable_uart=1
```

Save and reboot:
```bash
sudo reboot
```

### Step 2: Run the Test Script

After reboot, copy and run this test:

```bash
python3 pi_check_all_uart_devices.py
```

This will test ALL possible UART devices and tell you which one works.

### Step 3: Check Wiring One More Time

**VERIFY:**
- Pi **GPIO15 (RX)** → STM32 **PA2 (TX)** ✅
- Pi **GPIO14 (TX)** → STM32 **PA3 (RX)** ✅
- **GND → GND** ✅ (CRITICAL - must be connected!)

### Step 4: Test with Simple Command

Try reading directly from the UART:

```bash
# Set permissions
sudo chmod 666 /dev/ttyAMA0

# Try reading
timeout 5 cat /dev/ttyAMA0
```

If you see any characters (even gibberish), the connection works!

### Step 5: Alternative - Use /dev/serial0

Try changing the device path:

```bash
# Check what serial0 points to
ls -l /dev/serial0

# If it exists, try using that instead
```

In your Python script, change:
```python
UART_DEVICE = "/dev/serial0"  # Instead of /dev/ttyAMA0
```

## Most Likely Issues:

1. **UART not enabled** - Check `enable_uart=1` in config.txt
2. **Wrong device path** - Use `/dev/serial0` instead
3. **Permissions** - Need to be in `dialout` group or use `sudo`
4. **Wiring** - GND not connected (most common!)

## Quick Test:

Run this on your Pi RIGHT NOW:

```bash
# Check UART status
vcgencmd get_config enable_uart

# Test all devices
python3 pi_check_all_uart_devices.py
```

Share the output!

