# Raspberry Pi Automated Heartbeat Setup

This guide will set up your Pi to automatically send heartbeats every 60 seconds and start on boot.

---

## Prerequisites

- Raspberry Pi with internet connection
- SSH access to your Pi
- Python 3 installed (usually pre-installed)

---

## Quick Setup (Copy-Paste Commands)

### Step 1: SSH into Your Pi

```bash
ssh pi@<your-pi-ip>
```

### Step 2: Create Directory and Download Script

```bash
# Create directory
mkdir -p ~/gateway-heartbeat
cd ~/gateway-heartbeat

# Create the Python script
cat > pi_heartbeat_automated.py << 'EOF'
#!/usr/bin/env python3
"""
Automated Gateway Heartbeat Script for Raspberry Pi
Sends heartbeat to Azure Static Web Apps API every 60 seconds
Runs continuously in the background
"""

import requests
import time
import sys
import logging
from datetime import datetime

# Configuration
API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status"
GATEWAY_ID = "pi5-main"
HEARTBEAT_INTERVAL = 60  # seconds
MAX_RETRIES = 3
RETRY_DELAY = 5  # seconds

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/gateway-heartbeat.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

def send_heartbeat():
    """Send heartbeat POST request to API"""
    payload = {
        "gatewayId": GATEWAY_ID,
        "status": "online"
    }
    
    try:
        response = requests.post(
            API_URL,
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        response.raise_for_status()
        
        result = response.json()
        logger.info(f"✅ Heartbeat sent successfully: {result.get('status')} (updated: {result.get('lastUpdated')})")
        return True
        
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ Failed to send heartbeat: {e}")
        return False
    except Exception as e:
        logger.error(f"❌ Unexpected error: {e}")
        return False

def main():
    """Main loop - sends heartbeat every HEARTBEAT_INTERVAL seconds"""
    logger.info("=" * 60)
    logger.info(f"🚀 Gateway Heartbeat Service Starting")
    logger.info(f"   Gateway ID: {GATEWAY_ID}")
    logger.info(f"   API URL: {API_URL}")
    logger.info(f"   Interval: {HEARTBEAT_INTERVAL} seconds")
    logger.info("=" * 60)
    
    consecutive_failures = 0
    
    while True:
        try:
            # Send heartbeat
            success = send_heartbeat()
            
            if success:
                consecutive_failures = 0
            else:
                consecutive_failures += 1
                
                # If multiple failures, wait a bit longer before retry
                if consecutive_failures >= MAX_RETRIES:
                    logger.warning(f"⚠️  {consecutive_failures} consecutive failures. Waiting {RETRY_DELAY}s before retry...")
                    time.sleep(RETRY_DELAY)
                    consecutive_failures = 0  # Reset after retry delay
                    continue
            
            # Wait for next heartbeat interval
            time.sleep(HEARTBEAT_INTERVAL)
            
        except KeyboardInterrupt:
            logger.info("🛑 Received interrupt signal. Shutting down gracefully...")
            # Send final "offline" status before exiting
            try:
                payload = {"gatewayId": GATEWAY_ID, "status": "offline"}
                requests.post(API_URL, json=payload, timeout=5)
                logger.info("📤 Sent final 'offline' status")
            except:
                pass
            break
        except Exception as e:
            logger.error(f"❌ Unexpected error in main loop: {e}")
            time.sleep(HEARTBEAT_INTERVAL)

if __name__ == "__main__":
    main()
EOF

# Make script executable
chmod +x pi_heartbeat_automated.py
```

### Step 3: Install Python Dependencies

```bash
# Install requests library
pip3 install requests

# Verify installation
python3 -c "import requests; print('✅ requests library installed')"
```

### Step 4: Test the Script (Optional - Run Manually First)

```bash
# Run in foreground to test
python3 pi_heartbeat_automated.py
```

Press `Ctrl+C` to stop it. Check your dashboard - it should show "Online"!

### Step 5: Create Systemd Service (Auto-Start on Boot)

```bash
# Create service file
sudo tee /etc/systemd/system/gateway-heartbeat.service > /dev/null << 'EOF'
[Unit]
Description=Gateway Heartbeat Service - Sends status to Azure Static Web Apps
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/gateway-heartbeat
ExecStart=/usr/bin/python3 /home/pi/gateway-heartbeat/pi_heartbeat_automated.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Graceful shutdown - send offline status before stopping
ExecStop=/bin/sh -c 'curl -X POST https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status -H "Content-Type: application/json" -d "{\"gatewayId\":\"pi5-main\",\"status\":\"offline\"}" || true'

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable service (starts on boot)
sudo systemctl enable gateway-heartbeat.service

# Start service now
sudo systemctl start gateway-heartbeat.service

# Check status
sudo systemctl status gateway-heartbeat.service
```

### Step 6: Verify It's Working

```bash
# Check if service is running
sudo systemctl status gateway-heartbeat.service

# Check logs
sudo journalctl -u gateway-heartbeat.service -f

# Or check log file
tail -f /var/log/gateway-heartbeat.log
```

---

## Testing

1. **Check Service Status:**
   ```bash
   sudo systemctl status gateway-heartbeat.service
   ```
   Should show: `Active: active (running)`

2. **Check Dashboard:**
   - Go to: https://blue-desert-0c2a27e1e.3.azurestaticapps.net
   - Status should show "Online" within 60 seconds

3. **Check Logs:**
   ```bash
   tail -f /var/log/gateway-heartbeat.log
   ```
   Should see heartbeat messages every 60 seconds

4. **Test Unplug:**
   - Unplug Pi
   - Wait 90+ seconds
   - Dashboard should show "Offline" automatically

5. **Test Plug Back In:**
   - Plug Pi back in
   - Service starts automatically
   - Dashboard should show "Online" within 60 seconds

---

## Service Management Commands

```bash
# Start service
sudo systemctl start gateway-heartbeat.service

# Stop service
sudo systemctl stop gateway-heartbeat.service

# Restart service
sudo systemctl restart gateway-heartbeat.service

# Check status
sudo systemctl status gateway-heartbeat.service

# View logs (live)
sudo journalctl -u gateway-heartbeat.service -f

# View logs (last 50 lines)
sudo journalctl -u gateway-heartbeat.service -n 50

# Disable auto-start on boot
sudo systemctl disable gateway-heartbeat.service

# Enable auto-start on boot
sudo systemctl enable gateway-heartbeat.service
```

---

## Troubleshooting

### Service Won't Start

```bash
# Check for errors
sudo journalctl -u gateway-heartbeat.service -n 50

# Check if Python script is executable
ls -l /home/pi/gateway-heartbeat/pi_heartbeat_automated.py

# Test script manually
cd /home/pi/gateway-heartbeat
python3 pi_heartbeat_automated.py
```

### Status Still Shows Offline

1. Check if service is running:
   ```bash
   sudo systemctl status gateway-heartbeat.service
   ```

2. Check logs for errors:
   ```bash
   sudo journalctl -u gateway-heartbeat.service -n 20
   ```

3. Verify network connectivity:
   ```bash
   curl https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/ping
   ```

4. Test API manually:
   ```bash
   curl -X POST https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status \
     -H "Content-Type: application/json" \
     -d '{"gatewayId":"pi5-main","status":"online"}'
   ```

### Service Keeps Restarting

Check logs for the error:
```bash
sudo journalctl -u gateway-heartbeat.service -n 100
```

Common issues:
- Missing `requests` library → `pip3 install requests`
- Network not ready → Service waits for network-online.target (already configured)
- Permission issues → Check file permissions

---

## File Locations

- **Script**: `/home/pi/gateway-heartbeat/pi_heartbeat_automated.py`
- **Service File**: `/etc/systemd/system/gateway-heartbeat.service`
- **Log File**: `/var/log/gateway-heartbeat.log`
- **Systemd Logs**: `journalctl -u gateway-heartbeat.service`

---

## What Happens Now

✅ **On Boot**: Service starts automatically  
✅ **Every 60s**: Sends heartbeat POST request  
✅ **Dashboard**: Shows "Online" within 60 seconds  
✅ **On Unplug**: After 90 seconds, status auto-changes to "Offline"  
✅ **On Plug Back In**: Service starts automatically, status becomes "Online" again  
✅ **Zero Manual Work**: Fully automated!

---

## Next Steps

After this is set up and working:
1. ✅ Gateway status is fully automated
2. Ready to implement main server communication
3. Ready to add latency data collection

Let me know when the service is running and status shows "Online"!

