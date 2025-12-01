#!/bin/bash
# ========================================
# Start STM32 Bridge with Proper Error Handling
# Run this on Pi to start the bridge and verify it works
# ========================================

CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)

echo "========================================"
echo "🚀 Starting STM32 Bridge (Fixed Version)"
echo "========================================"
echo ""

# Step 1: Kill any existing bridge
echo "1. Stopping any existing bridge..."
pkill -f pi_stm32_bridge.py 2>/dev/null || true
sleep 2
echo "✅ Stopped existing processes"
echo ""

# Step 2: Verify script exists
if [ ! -f "$HOME_DIR/pi_stm32_bridge.py" ]; then
    echo "❌ Bridge script not found at $HOME_DIR/pi_stm32_bridge.py"
    echo "   Please copy pi_stm32_bridge.py to Pi first"
    exit 1
fi
echo "✅ Bridge script found"
echo ""

# Step 3: Test Azure connection
echo "2. Testing Azure connection..."
python3 << 'TEST_AZURE'
import requests
import sys

try:
    response = requests.post(
        "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status",
        json={"deviceId": "stm32-main", "status": "online"},
        headers={"Content-Type": "application/json"},
        timeout=10
    )
    response.raise_for_status()
    result = response.json()
    print(f"✅ Azure connection works!")
    print(f"   Status: {result.get('status')}")
    print(f"   Last Updated: {result.get('lastUpdated')}")
except Exception as e:
    print(f"❌ Azure connection failed: {e}")
    sys.exit(1)
TEST_AZURE

if [ $? -ne 0 ]; then
    echo "❌ Cannot connect to Azure. Check network."
    exit 1
fi
echo ""

# Step 4: Send initial online status
echo "3. Sending initial 'online' status to Azure..."
python3 << 'SEND_INITIAL'
import requests

response = requests.post(
    "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status",
    json={"deviceId": "stm32-main", "status": "online"},
    headers={"Content-Type": "application/json"},
    timeout=10
)
print(f"✅ Initial status sent: {response.json()}")
SEND_INITIAL
echo ""

# Step 5: Start bridge in background with logging
echo "4. Starting bridge script in background..."
cd "$HOME_DIR"
nohup python3 pi_stm32_bridge.py > "$HOME_DIR/bridge_output.log" 2>&1 &
BRIDGE_PID=$!

sleep 3

# Check if it's still running
if ps -p $BRIDGE_PID > /dev/null 2>&1; then
    echo "✅ Bridge started! (PID: $BRIDGE_PID)"
    echo ""
    echo "📋 Bridge Status:"
    echo "   Process ID: $BRIDGE_PID"
    echo "   Log file: $HOME_DIR/stm32-bridge.log"
    echo "   Output log: $HOME_DIR/bridge_output.log"
    echo ""
    
    # Show recent logs
    echo "📄 Recent bridge logs:"
    if [ -f "$HOME_DIR/stm32-bridge.log" ]; then
        tail -10 "$HOME_DIR/stm32-bridge.log" | sed 's/^/   /'
    else
        echo "   (Log file not created yet - check in 5 seconds)"
    fi
    echo ""
    
    # Wait a moment and check Azure status
    echo "5. Verifying status after 5 seconds..."
    sleep 5
    
    python3 << 'CHECK_STATUS'
import requests
import time

try:
    response = requests.get(
        "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main",
        timeout=5
    )
    result = response.json()
    status = result.get('status', 'unknown')
    last_updated = result.get('lastUpdated', 'N/A')
    
    print(f"📊 Current Azure Status:")
    print(f"   Status: {status}")
    print(f"   Last Updated: {last_updated}")
    
    if status == 'online':
        print("✅ SUCCESS! Status is online!")
    elif status == 'offline':
        print("⚠️  Status is offline - check bridge logs")
    else:
        print("❓ Status is unknown - bridge may not be running")
except Exception as e:
    print(f"❌ Error checking status: {e}")
CHECK_STATUS
    
    echo ""
    echo "========================================"
    echo "✅ Bridge Started Successfully!"
    echo "========================================"
    echo ""
    echo "📋 Useful Commands:"
    echo "   View logs:          tail -f ~/stm32-bridge.log"
    echo "   View output:        tail -f ~/bridge_output.log"
    echo "   Check if running:   ps aux | grep pi_stm32_bridge"
    echo "   Stop bridge:        pkill -f pi_stm32_bridge"
    echo "   Check Azure status: curl 'https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main'"
    echo ""
else
    echo "❌ Bridge failed to start!"
    echo ""
    echo "Check logs:"
    if [ -f "$HOME_DIR/bridge_output.log" ]; then
        cat "$HOME_DIR/bridge_output.log"
    fi
    exit 1
fi

