# Quick Start: Pi Integration Setup

## Step 1: Transfer Files to Raspberry Pi

### Option A: Using USB Drive/SD Card
1. Copy these files to a USB drive or SD card:
   - `pi_heartbeat_test.py`
   - `pi_heartbeat_continuous.py`
   - `pi_setup.sh`
2. Plug into Pi
3. On Pi, copy files to home directory:
   ```bash
   cp /media/usb/*.py ~/
   cp /media/usb/*.sh ~/
   ```

### Option B: Using SCP (SSH File Transfer)
From your Windows computer (using PowerShell or WSL):
```powershell
# If you know the Pi's IP address (replace with actual IP)
scp pi_heartbeat*.py pi_setup.sh pi@<PI_IP_ADDRESS>:~/
```

### Option C: Direct Download on Pi
SSH into your Pi, then:
```bash
# Create the files directly on Pi using nano
nano pi_heartbeat_test.py
# Paste the contents, save with Ctrl+X, Y, Enter
```

---

## Step 2: Setup on Pi

### Quick Setup (Automated)
```bash
# Make setup script executable
chmod +x pi_setup.sh

# Run setup (installs dependencies)
./pi_setup.sh
```

### Manual Setup
```bash
# Install Python requests library
sudo apt-get update
sudo apt-get install python3-pip
pip3 install requests

# Make scripts executable
chmod +x pi_heartbeat_test.py
chmod +x pi_heartbeat_continuous.py
```

---

## Step 3: Test Connection

```bash
# Run the test script
python3 pi_heartbeat_test.py
```

**Expected Output:**
```
============================================================
Raspberry Pi Gateway Heartbeat Test
============================================================
API URL: https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status

1. Checking initial status...
[14:23:45] Status: 🔴 Disconnected | Last seen: Never

2. Sending heartbeat...
[14:23:46] ✅ Heartbeat sent: {'ok': True, 'lastSeen': '2025-01-15T14:23:46.123Z'}

3. Checking status after heartbeat...
[14:23:47] Status: 🟢 Connected | Last seen: 2025-01-15T14:23:46.123Z
```

**Then check your dashboard** - it should show "Connected"!

---

## Step 4: Run Continuously

### Run in Foreground (see output)
```bash
python3 pi_heartbeat_continuous.py
```

### Run in Background (keeps running after you disconnect)
```bash
nohup python3 pi_heartbeat_continuous.py > heartbeat.log 2>&1 &
```

### Check if it's running
```bash
ps aux | grep heartbeat
```

### View logs
```bash
tail -f heartbeat.log
```

### Stop background process
```bash
pkill -f pi_heartbeat_continuous
```

---

## Step 5: Verify on Dashboard

1. Open: https://blue-desert-0c2a27e1e.3.azurestaticapps.net
2. Look for "Raspberry Pi Gateway → Azure" card
3. Should show:
   - 🟢 Green dot = Connected
   - "Connected" status
   - "Last heartbeat: Xs ago"

---

## Troubleshooting

### "Module 'requests' not found"
```bash
pip3 install requests
# or
sudo pip3 install requests
```

### "Connection timeout" or "Cannot reach API"
```bash
# Test internet connection
ping google.com

# Test API directly
curl https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status
```

### Dashboard still shows "Disconnected"
- Wait a few seconds (frontend polls every 1 second)
- Refresh the page
- Check browser console (F12) for errors
- Verify script is actually running: `ps aux | grep heartbeat`

### Script stops after disconnecting SSH
Use screen or tmux:
```bash
# Install screen
sudo apt-get install screen

# Start screen session
screen -S heartbeat

# Run script
python3 pi_heartbeat_continuous.py

# Detach: Press Ctrl+A then D
# Reattach later: screen -r heartbeat
```

---

## Next Steps

Once this works:
1. ✅ You'll see "Connected" on dashboard
2. ✅ Heartbeats will keep it connected every 15 seconds
3. 🔄 Next: Add latency measurement
4. 🔄 Next: Set up auto-start on boot

