# 🚀 START HERE: Pi Integration Setup

## ✅ What's Ready
- ✅ API is working (tested and confirmed!)
- ✅ Python scripts created and ready
- ✅ All files prepared in this directory

## 🎯 Next Steps (Choose One Method)

---

## Method 1: Copy-Paste on Pi (Easiest if you have SSH)

### Step 1: Connect to Your Pi
```bash
# Find your Pi's IP, then:
ssh pi@<YOUR_PI_IP>
# Password is usually: raspberry
```

### Step 2: Create and Run Test Script
Copy and paste this ENTIRE block into your Pi terminal:

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y python3-pip
pip3 install requests

# Create test script
cat > pi_heartbeat_test.py << 'EOF'
#!/usr/bin/env python3
import requests
import time
from datetime import datetime

API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status"

def send_heartbeat():
    try:
        response = requests.post(API_URL, timeout=5)
        response.raise_for_status()
        data = response.json()
        print(f"[{datetime.now().strftime('%H:%M:%S')}] ✅ Heartbeat sent: {data}")
        return True
    except Exception as e:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] ❌ Error: {e}")
        return False

def check_status():
    try:
        response = requests.get(API_URL, timeout=5)
        response.raise_for_status()
        data = response.json()
        connected = "🟢 Connected" if data.get('connected') else "🔴 Disconnected"
        last_seen = data.get('lastSeen', 'Never')
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Status: {connected} | Last seen: {last_seen}")
        return data
    except Exception as e:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] ❌ Error: {e}")
        return None

print("=" * 60)
print("Raspberry Pi Gateway Heartbeat Test")
print("=" * 60)
print(f"API URL: {API_URL}\n")

print("1. Checking initial status...")
check_status()
print()

print("2. Sending heartbeat...")
if send_heartbeat():
    print()
    time.sleep(1)
    print("3. Checking status after heartbeat...")
    check_status()

print("\n" + "=" * 60)
print("Test complete! Check your dashboard!")
print("=" * 60)
EOF

# Make it executable and run
chmod +x pi_heartbeat_test.py
python3 pi_heartbeat_test.py
```

**Then check your dashboard** - it should show "Connected"!

---

## Method 2: Transfer Files (If you prefer file transfer)

### Using SCP from Windows PowerShell:
```powershell
# First, install OpenSSH Client if needed:
# Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Then transfer files (replace with your Pi IP):
scp pi_heartbeat_test.py pi@192.168.1.100:~/
scp pi_heartbeat_continuous.py pi@192.168.1.100:~/

# SSH into Pi and run:
ssh pi@192.168.1.100
pip3 install requests
python3 pi_heartbeat_test.py
```

### Using USB Drive:
1. Copy `pi_heartbeat_test.py` and `pi_heartbeat_continuous.py` to USB
2. Plug into Pi
3. Copy to Pi: `cp /media/pi/USB/*.py ~/`
4. Run setup: `pip3 install requests && python3 pi_heartbeat_test.py`

---

## Method 3: Use the PowerShell Helper Script

Run this in PowerShell from the project directory:

```powershell
.\setup_pi_files.ps1
```

It will guide you through transferring files!

---

## 🎯 Once Test Works - Run Continuously

After the test works, run this on your Pi:

```bash
# Create continuous heartbeat script
cat > pi_heartbeat_continuous.py << 'EOF'
#!/usr/bin/env python3
import requests
import time
import sys
from datetime import datetime

API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status"
HEARTBEAT_INTERVAL = 15
heartbeat_count = 0

def send_heartbeat():
    global heartbeat_count
    try:
        response = requests.post(API_URL, timeout=10)
        response.raise_for_status()
        data = response.json()
        heartbeat_count += 1
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] ✅ Heartbeat #{heartbeat_count} - Last seen: {data.get('lastSeen', 'N/A')}")
        return True
    except Exception as e:
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] ❌ Error: {str(e)}")
        return False

print("=" * 70)
print("Raspberry Pi Gateway - Continuous Heartbeat")
print("=" * 70)
print(f"API: {API_URL}")
print(f"Interval: Every {HEARTBEAT_INTERVAL} seconds")
print("Press Ctrl+C to stop\n")

try:
    while True:
        send_heartbeat()
        time.sleep(HEARTBEAT_INTERVAL)
except KeyboardInterrupt:
    print(f"\n\nStopped. Sent {heartbeat_count} heartbeats total.")
    sys.exit(0)
EOF

# Run it in background
chmod +x pi_heartbeat_continuous.py
nohup python3 pi_heartbeat_continuous.py > heartbeat.log 2>&1 &
```

---

## 🔍 Find Your Pi's IP Address

**On Windows PowerShell:**
```powershell
# Scan network
arp -a | Select-String "192.168"
```

**Or try common Pi hostnames:**
```powershell
ping raspberrypi.local
```

**Or check your router admin page** - look for "raspberrypi" in connected devices

---

## ✅ Quick Verification

Once script is running, check your dashboard:
- URL: https://blue-desert-0c2a27e1e.3.azurestaticapps.net
- Look for "Raspberry Pi Gateway → Azure" card
- Should show: 🟢 Connected with "Last heartbeat: Xs ago"

---

## 🆘 Need Help?

**Can't find Pi IP?**
- Check router admin page
- Check Pi's screen (if connected) - run `hostname -I`

**Can't SSH?**
- Make sure SSH is enabled: `sudo systemctl enable ssh`
- Try different ports: `ssh -p 22 pi@<IP>`

**Script not working?**
- Check internet: `ping google.com`
- Check API: `curl https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status`
- Check Python: `python3 --version`

