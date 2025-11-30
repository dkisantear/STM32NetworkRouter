# Raspberry Pi Setup Steps - Easy Progression

## Current Status ✅
- Build is successful
- `/api/gateway-status` endpoint is working
- You can see `connected: false` and `lastSeen: null` (expected, no heartbeat yet)

---

## Step 1: Manual Test (Right Now) 🧪

### Test from Browser Console
1. Go to your deployed site: `https://blue-desert-0c2a27e1e.3.azurestaticapps.net`
2. Open Developer Tools (F12)
3. Go to Console tab
4. Run this:

```javascript
// Send a heartbeat
fetch('/api/gateway-status', { method: 'POST' })
  .then(r => r.json())
  .then(data => console.log('✅ POST Response:', data));

// Wait 1 second, then check status
setTimeout(() => {
  fetch('/api/gateway-status')
    .then(r => r.json())
    .then(data => console.log('✅ GET Response:', data));
}, 1000);
```

**Expected Result:** You should see `connected: true` and a timestamp!

---

## Step 2: Test with Python Script (On Your Computer First) 💻

### On Windows/Mac/Linux:
1. Install requests library (if not already):
   ```bash
   pip install requests
   ```

2. Run the test script:
   ```bash
   python pi_heartbeat_test.py
   ```

3. Check your dashboard - it should show "Connected"!

---

## Step 3: Transfer to Raspberry Pi 📦

### Option A: Copy via USB/SD Card
1. Copy `pi_heartbeat_test.py` to your Pi
2. On Pi, install requests:
   ```bash
   pip3 install requests
   ```

### Option B: Download directly on Pi
1. SSH into your Pi
2. Create the file:
   ```bash
   nano pi_heartbeat_test.py
   ```
3. Paste the contents from `pi_heartbeat_test.py`
4. Save (Ctrl+X, then Y, then Enter)
5. Make it executable:
   ```bash
   chmod +x pi_heartbeat_test.py
   ```

---

## Step 4: Test on Pi 🔌

1. Run the test script:
   ```bash
   python3 pi_heartbeat_test.py
   ```

2. Check your dashboard - you should see "Connected"!

---

## Step 5: Set Up Continuous Heartbeats (Keep It Running) 🔄

### Quick Test Run:
```bash
python3 pi_heartbeat_continuous.py
```

### Run in Background (so it keeps going):
```bash
nohup python3 pi_heartbeat_continuous.py > heartbeat.log 2>&1 &
```

### Or use screen/tmux:
```bash
screen -S heartbeat
python3 pi_heartbeat_continuous.py
# Press Ctrl+A then D to detach
# Type 'screen -r heartbeat' to reattach later
```

---

## Step 6: Make It Auto-Start on Boot (Optional) 🚀

Create a systemd service (most reliable):

1. Create service file:
   ```bash
   sudo nano /etc/systemd/system/gateway-heartbeat.service
   ```

2. Paste this:
   ```ini
   [Unit]
   Description=Gateway Heartbeat Service
   After=network.target

   [Service]
   Type=simple
   User=pi
   WorkingDirectory=/home/pi
   ExecStart=/usr/bin/python3 /home/pi/pi_heartbeat_continuous.py
   Restart=always
   RestartSec=10

   [Install]
   WantedBy=multi-user.target
   ```

3. Enable and start:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable gateway-heartbeat.service
   sudo systemctl start gateway-heartbeat.service
   ```

4. Check status:
   ```bash
   sudo systemctl status gateway-heartbeat.service
   ```

---

## Troubleshooting 🔧

### "Module 'requests' not found"
```bash
pip3 install requests
```

### "Connection timeout" or "Cannot reach API"
- Check Pi has internet: `ping google.com`
- Verify API URL is correct in the script
- Check firewall settings

### Dashboard still shows "Disconnected"
- Wait a few seconds - frontend polls every 1 second
- Refresh the page
- Check browser console for errors

### Heartbeat stops working
- Check Pi is still running the script
- Check Pi internet connection
- Verify API endpoint is still accessible

---

## Next Steps After This Works ✨

1. **Add latency measurement**: Modify the heartbeat to measure actual network latency
2. **Add device ID**: Send Pi's hostname or ID with heartbeat
3. **Add error handling**: Better logging for production use
4. **Add monitoring**: Set up alerts if heartbeat fails
5. **Optimize**: Adjust heartbeat interval based on needs

---

## Quick Commands Reference 📝

```bash
# Test once
python3 pi_heartbeat_test.py

# Run continuously (foreground)
python3 pi_heartbeat_continuous.py

# Run in background
nohup python3 pi_heartbeat_continuous.py > heartbeat.log 2>&1 &

# Check if running
ps aux | grep heartbeat

# Stop background process
pkill -f pi_heartbeat_continuous

# View logs
tail -f heartbeat.log
```

