# 🚀 DO THIS NOW - Simplest Setup

## ✅ Frontend Error Fixed
I've already committed and pushed the fix. Your console errors should be resolved after deployment redeploys.

---

## Pi Setup - 3 Simple Steps

Since SSH password authentication requires interactive input, here's the **absolute simplest** way:

### Step 1: Open PowerShell and SSH into Pi

```powershell
ssh pi@raspberrypi.local
```

**Enter password when prompted:** `raspberry`

---

### Step 2: Copy & Paste This ONE Command

Once you're SSH'd into the Pi, copy and paste **this entire block** (it's all one command):

```bash
sudo apt-get update -qq && sudo apt-get install -y python3 python3-pip -qq && pip3 install requests --quiet --break-system-packages 2>/dev/null || pip3 install requests --quiet || sudo pip3 install requests --quiet && curl -o pi_heartbeat_test.py https://raw.githubusercontent.com/dkisantear/latency-live-monitor/main/pi_heartbeat_test.py 2>/dev/null || (cat > pi_heartbeat_test.py << 'TESTEOF'
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
) && chmod +x pi_heartbeat_test.py && python3 pi_heartbeat_test.py
```

**This will:**
- Install everything needed
- Create the test script
- Run the test immediately
- Show you if it worked!

---

### Step 3: Check Your Dashboard

Open: https://blue-desert-0c2a27e1e.3.azurestaticapps.net

You should see: **🟢 Connected** on the "Raspberry Pi Gateway → Azure" card!

---

## That's It! 🎉

If the test works, you're done! The heartbeat will show on your dashboard.

**Want it to run continuously?** Run this on the Pi:
```bash
nohup python3 pi_heartbeat_continuous.py > heartbeat.log 2>&1 &
```

But first, let's get the test working! 🚀

