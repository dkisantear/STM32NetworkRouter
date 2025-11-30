# Connect to Raspberry Pi - Step by Step

Since your Pi is "plugged in", let's get it connected!

---

## Option 1: SSH Connection (Most Common)

### Step 1: Find Your Pi's IP Address

**On Windows PowerShell:**
```powershell
# Scan your local network for Raspberry Pi
# Look for hostname containing "raspberry" or IP starting with 192.168
arp -a | Select-String "192.168"
```

**Or check your router's admin page:**
- Usually: http://192.168.1.1 or http://192.168.0.1
- Look for connected devices with name like "raspberrypi"

### Step 2: Connect via SSH

**If using PowerShell:**
```powershell
ssh pi@<PI_IP_ADDRESS>
# Default password is usually: raspberry
```

**If using WSL (Windows Subsystem for Linux):**
```bash
ssh pi@<PI_IP_ADDRESS>
```

**If using PuTTY:**
- Download PuTTY
- Enter IP address
- Port: 22
- Click "Open"
- Username: `pi`, Password: `raspberry`

---

## Option 2: Transfer Files via USB/SD Card

1. **Copy these files to USB drive:**
   - `pi_heartbeat_test.py`
   - `pi_heartbeat_continuous.py`
   - `pi_setup.sh`

2. **Plug USB into Pi**

3. **On Pi (if you have screen/keyboard connected):**
   ```bash
   # Mount USB (usually auto-mounts)
   ls /media/pi/
   
   # Copy files
   cp /media/pi/USB_DRIVE_NAME/*.py ~/
   cp /media/pi/USB_DRIVE_NAME/*.sh ~/
   ```

---

## Option 3: Direct Download on Pi

If you can access the Pi terminal:

```bash
# Create test script
nano pi_heartbeat_test.py
# Then paste the contents (I'll provide a way to copy easily)
```

---

## Quick Test: Can You Reach Your Pi?

Try these commands in PowerShell:

```powershell
# Test if Pi responds to ping (replace with actual IP)
Test-Connection -ComputerName 192.168.1.100 -Count 2

# Try to connect via SSH
ssh pi@192.168.1.100
```

**Common Pi IP addresses to try:**
- `192.168.1.100`
- `192.168.1.101`
- `192.168.0.100`
- `192.168.0.101`

---

## What's Your Pi's Connection Method?

Tell me:
1. ✅ Can you SSH into it? (What's the IP?)
2. ✅ Do you have physical access (keyboard/screen)?
3. ✅ Is it on the same network as your computer?
4. ✅ What's the hostname? (try: `ping raspberrypi.local`)

Once we know how to connect, I'll guide you through the exact steps!

