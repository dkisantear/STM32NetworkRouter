# 🚀 FINAL SETUP STEPS - Copy & Paste Ready!

## Your Pi Information
- **Hostname:** `raspberrypi.local`
- **IP Address:** `192.168.1.160`
- **Username:** `pi`
- **Password:** `raspberry`

---

## Quick Setup (3 Steps)

### Step 1: SSH into Your Pi

**Open PowerShell and run:**
```powershell
ssh pi@raspberrypi.local
```

**Or use IP address:**
```powershell
ssh pi@192.168.1.160
```

**When prompted, enter password:** `raspberry`

---

### Step 2: Copy & Paste This ENTIRE Command Block

Once you're SSH'd into the Pi, copy and paste this **ENTIRE** block:

```bash
# Install dependencies
sudo apt-get update -qq && sudo apt-get install -y python3 python3-pip -qq && pip3 install requests --quiet --break-system-packages 2>/dev/null || pip3 install requests --quiet || sudo pip3 install requests --quiet

# Create test script
cat > pi_heartbeat_test.py << 'TESTEOF'
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
TESTEOF

# Create continuous script
cat > pi_heartbeat_continuous.py << 'CONTINUOUSEOF'
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
CONTINUOUSEOF

# Make scripts executable
chmod +x pi_heartbeat_test.py pi_heartbeat_continuous.py

# Run test immediately
echo ""
echo "=========================================="
echo "Running test heartbeat..."
echo "=========================================="
python3 pi_heartbeat_test.py

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "Check your dashboard - it should show 'Connected'!"
echo ""
echo "To run continuously in background:"
echo "  nohup python3 pi_heartbeat_continuous.py > heartbeat.log 2>&1 &"
echo ""
echo "To check logs:"
echo "  tail -f heartbeat.log"
echo ""
```

---

### Step 3: Start Continuous Heartbeat (Optional)

To keep sending heartbeats automatically:

```bash
nohup python3 pi_heartbeat_continuous.py > heartbeat.log 2>&1 &
```

This will:
- ✅ Run in the background
- ✅ Send heartbeats every 15 seconds
- ✅ Keep running even after you disconnect SSH

---

## Verify It's Working

1. **Check your dashboard:** https://blue-desert-0c2a27e1e.3.azurestaticapps.net
2. **Look for:** "Raspberry Pi Gateway → Azure" card
3. **Should show:** 🟢 **Connected** with "Last heartbeat: Xs ago"

---

## Troubleshooting

### Can't SSH?
```powershell
# Try IP address instead
ssh pi@192.168.1.160
```

### Script not working?
```bash
# Check Python is installed
python3 --version

# Install requests manually
pip3 install requests

# Run test again
python3 pi_heartbeat_test.py
```

### Dashboard still shows "Disconnected"?
- Wait a few seconds (frontend polls every 1 second)
- Refresh the page
- Check that the test script ran successfully

---

## That's It! 🎉

Once you complete Step 2, everything should be working!

