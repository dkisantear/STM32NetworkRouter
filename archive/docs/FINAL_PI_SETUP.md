# 🚀 Final Pi Setup - Correct Credentials

## Your Pi Credentials
- **IP:** `192.168.1.160`
- **Hostname:** `raspberrypi.local`
- **Username:** `pi5`
- **Password:** `pi5`

---

## Quick Setup (2 Steps)

### Step 1: SSH into Pi

```powershell
ssh pi5@192.168.1.160
```

**When prompted, enter password:** `pi5`

---

### Step 2: Copy & Paste This ENTIRE Script

Once you're connected to the Pi, open the file `EXECUTE_THIS_ON_PI.sh` in this directory, copy **ALL** of its contents, and paste into the Pi terminal.

**OR** copy-paste this complete command block:

```bash
sudo apt-get update -qq && sudo apt-get install -y python3 python3-pip -qq && pip3 install requests --quiet --break-system-packages 2>/dev/null || pip3 install requests --quiet || sudo pip3 install requests --quiet && cat > pi_heartbeat_test.py << 'TESTEOF'
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
chmod +x pi_heartbeat_test.py && python3 pi_heartbeat_test.py
```

---

## What This Does

1. ✅ Installs Python 3 and pip
2. ✅ Installs requests library
3. ✅ Creates the test heartbeat script
4. ✅ Runs the test immediately
5. ✅ Shows you if it worked!

---

## Expected Result

After running, you should see:
- `✅ Heartbeat sent: {'ok': True, 'lastSeen': '...'}`
- `Status: 🟢 Connected | Last seen: ...`

**Then check your dashboard** - it should show **🟢 Connected**!

---

## Run Continuously (After Test Works)

```bash
# Create continuous script (or use the one from EXECUTE_THIS_ON_PI.sh)
nohup python3 pi_heartbeat_continuous.py > heartbeat.log 2>&1 &
```

---

## Summary

**Status:**
- ✅ Frontend error fixed (committed & pushed)
- ✅ Setup script ready (`EXECUTE_THIS_ON_PI.sh`)
- ✅ Credentials updated: `pi5` / `pi5`

**Action:** SSH in and paste the script!

