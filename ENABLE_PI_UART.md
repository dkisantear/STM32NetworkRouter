# Enable UART on Raspberry Pi 5

## Quick Fix - Enable UART:

**1. Edit config.txt:**
```bash
sudo nano /boot/config.txt
```

**2. Add these lines (at the end):**
```
enable_uart=1
```

**For Pi 5 specifically, you might also need:**
```
dtoverlay=uart0
```

**3. Save and reboot:**
```bash
sudo reboot
```

**4. After reboot, verify:**
```bash
# Check if UART is enabled
dmesg | grep -i uart
dmesg | grep -i tty

# Check if device exists
ls -l /dev/ttyAMA* /dev/serial0
```

## Alternative: Use /dev/serial0

If `/dev/ttyAMA0` doesn't work, try `/dev/serial0`:

```bash
# /dev/serial0 is a symlink to the active UART
ls -l /dev/serial0

# Use this in your Python script instead
# Change: UART_DEVICE = "/dev/ttyAMA0"
# To:     UART_DEVICE = "/dev/serial0"
```

## Check Current Status:

```bash
# Check UART status
vcgencmd get_config enable_uart

# Should output: enable_uart=1
# If it outputs nothing or 0, UART is disabled
```

