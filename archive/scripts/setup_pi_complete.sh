#!/bin/bash
# Complete automated setup for Raspberry Pi
# This script will be run on the Pi to set everything up

set -e  # Exit on error

PI_HOST="raspberrypi.local"
PI_USER="pi"
PI_PASS="raspberry"
API_URL="https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status"

echo "=========================================="
echo "Raspberry Pi Gateway - Complete Setup"
echo "=========================================="
echo ""

# Update system
echo "Step 1: Updating package list..."
sudo apt-get update -qq

# Install Python and pip
echo "Step 2: Installing Python dependencies..."
sudo apt-get install -y python3 python3-pip -qq

# Install requests library
echo "Step 3: Installing requests library..."
pip3 install requests --quiet --break-system-packages 2>/dev/null || pip3 install requests --quiet || sudo pip3 install requests --quiet

# Create heartbeat test script
echo "Step 4: Creating heartbeat scripts..."
cat > /home/$PI_USER/pi_heartbeat_test.py << 'TEST_SCRIPT_EOF'
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
TEST_SCRIPT_EOF

# Create continuous heartbeat script
cat > /home/$PI_USER/pi_heartbeat_continuous.py << 'CONTINUOUS_SCRIPT_EOF'
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
CONTINUOUS_SCRIPT_EOF

# Make scripts executable
chmod +x /home/$PI_USER/pi_heartbeat_test.py
chmod +x /home/$PI_USER/pi_heartbeat_continuous.py

echo "✅ Scripts created and made executable"
echo ""

# Test connection
echo "Step 5: Testing connection..."
python3 /home/$PI_USER/pi_heartbeat_test.py

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "To run continuously in background:"
echo "  nohup python3 ~/pi_heartbeat_continuous.py > ~/heartbeat.log 2>&1 &"
echo ""
echo "Check logs:"
echo "  tail -f ~/heartbeat.log"
echo ""

