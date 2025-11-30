# 🚀 Automatic Pi Setup - Complete Instructions

## Status: Frontend Error Fixed ✅

I've already committed and pushed the frontend error fix. The console errors should be resolved after the next deployment.

---

## Automated Pi Setup

Since SSH password authentication requires interactive input, here's the **simplest automated approach**:

### Option 1: Single Command (Easiest)

**Step 1:** SSH into your Pi:
```powershell
ssh pi@raspberrypi.local
# Password: raspberry
```

**Step 2:** Once connected, run this single command:

```bash
curl -sSL https://raw.githubusercontent.com/dkisantear/latency-live-monitor/main/EXECUTE_THIS_ON_PI.sh | bash
```

**OR** if that doesn't work, copy the entire contents of `EXECUTE_THIS_ON_PI.sh` and paste it into the Pi terminal.

---

### Option 2: Transfer File and Execute

**Step 1:** Transfer the setup script:
```powershell
scp EXECUTE_THIS_ON_PI.sh pi@raspberrypi.local:~/
# Password: raspberry
```

**Step 2:** SSH into Pi:
```powershell
ssh pi@raspberrypi.local
# Password: raspberry
```

**Step 3:** Run the script:
```bash
chmod +x EXECUTE_THIS_ON_PI.sh
./EXECUTE_THIS_ON_PI.sh
```

---

### Option 3: Manual Copy-Paste (Most Reliable)

**Step 1:** SSH into Pi:
```powershell
ssh pi@raspberrypi.local
# Password: raspberry
```

**Step 2:** Open `EXECUTE_THIS_ON_PI.sh` file in your editor, copy the entire contents, and paste into Pi terminal.

---

## What the Setup Does

The script will automatically:
1. ✅ Install Python 3 and pip
2. ✅ Install requests library
3. ✅ Create both heartbeat scripts
4. ✅ Run a test heartbeat immediately
5. ✅ Show you the results

**Expected output:** You should see "🟢 Connected" and your dashboard will update!

---

## After Setup Works

To keep heartbeats running continuously:
```bash
nohup python3 pi_heartbeat_continuous.py > heartbeat.log 2>&1 &
```

This runs in background and keeps sending heartbeats every 15 seconds.

---

## Quick Summary

1. ✅ **Frontend error fixed** - Committed and pushed
2. ✅ **Setup script ready** - `EXECUTE_THIS_ON_PI.sh`
3. 🎯 **Next:** SSH into Pi and run the setup script

The easiest path: SSH into Pi, then copy-paste the entire `EXECUTE_THIS_ON_PI.sh` file content.

