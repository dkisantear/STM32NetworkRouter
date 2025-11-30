# 🧪 How to Test Your Pi Setup

## Quick Test Steps

### Step 1: Check if Script Ran

Look at your terminal - you should see:
- `Installing Python dependencies...`
- `✅ Dependencies installed`
- `Running test heartbeat...`
- Output showing heartbeat status

**If you see those messages, the script ran! ✅**

---

### Step 2: Run Test Manually

If the script already ran, or to test again, run:

```bash
python3 pi_heartbeat_test.py
```

**Expected output:**
- Shows initial status (probably "🔴 Disconnected")
- Sends a heartbeat
- Shows "🟢 Connected" after heartbeat

---

### Step 3: Check Your Dashboard

Open your browser and go to:
**https://blue-desert-0c2a27e1e.3.azurestaticapps.net**

Look for the **"Raspberry Pi Gateway → Azure"** card.

**You should see:**
- 🟢 **Connected** (if heartbeat worked)
- **Last heartbeat: Xs ago** (showing time since last heartbeat)

---

### Step 4: Check Status Directly

On the Pi, you can also check the API directly:

```bash
curl https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status
```

**Expected response:**
```json
{"connected":true,"lastSeen":"2024-..."}
```

---

## If It Didn't Work

### Check if Python is installed:
```bash
python3 --version
```

### Check if requests library is installed:
```bash
pip3 list | grep requests
```

### Install requests if missing:
```bash
pip3 install requests
```

---

## Run Continuous Heartbeat

Once the test works, run it continuously:

```bash
nohup python3 pi_heartbeat_continuous.py > heartbeat.log 2>&1 &
```

This will keep sending heartbeats every 15 seconds in the background.

---

## Quick Commands Summary

```bash
# Test heartbeat
python3 pi_heartbeat_test.py

# Check status via API
curl https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status

# Run continuously in background
nohup python3 pi_heartbeat_continuous.py > heartbeat.log 2>&1 &

# Check if continuous script is running
ps aux | grep heartbeat

# View logs
tail -f heartbeat.log
```

