# Pi UART Configuration Check - Most Likely Issue

## The Problem:
STM32 is correct, wiring is correct, but Pi isn't receiving. This is a **Pi UART configuration issue**.

## Step 1: Enable UART on Pi

Raspberry Pi UART might be disabled. Check `/boot/config.txt`:

```bash
# On Pi, check if UART is enabled
cat /boot/config.txt | grep -i uart
```

**If nothing shows up, add this to `/boot/config.txt`:**

```bash
sudo nano /boot/config.txt
```

Add these lines:
```
enable_uart=1
dtoverlay=uart5
```

For **Raspberry Pi 5**, you might need:
```
enable_uart=1
dtoverlay=uart0
```

**Then reboot:**
```bash
sudo reboot
```

## Step 2: Check Which UART Device is Active

On Pi 5, the UART might be on a different device:

```bash
# Check all UART devices
ls -l /dev/ttyAMA* /dev/serial0 /dev/ttyS* /dev/ttyUSB*

# See which one is serial0
ls -l /dev/serial0
```

## Step 3: Test with Simple Serial Monitor

Try using `minicom` or `screen` to test directly:

```bash
# Install if needed
sudo apt-get install minicom

# Try connecting
sudo minicom -D /dev/ttyAMA0 -b 38400

# Or try
sudo screen /dev/ttyAMA0 38400
```

Press `Ctrl+A` then `K` to exit screen.

## Step 4: Check Permissions

Make sure your user can access the serial port:

```bash
# Add user to dialout group
sudo usermod -a -G dialout $USER

# Logout and login again for changes to take effect
```

Or use `sudo` when running the script temporarily.

## Step 5: Verify UART is Not in Use

Check if another process is using the UART:

```bash
# Check what's using the UART
sudo lsof | grep ttyAMA
sudo fuser /dev/ttyAMA0
```

If something is using it, kill it:
```bash
sudo killall -9 <process-name>
```

