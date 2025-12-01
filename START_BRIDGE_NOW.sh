#!/bin/bash
# ========================================
# Quick Start STM32 Bridge - Copy/paste into Pi terminal
# ========================================

CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)

echo "========================================"
echo "🚀 Starting STM32 Bridge NOW"
echo "========================================"
echo ""

# Step 1: Check if script exists
if [ ! -f "$HOME_DIR/pi_stm32_bridge.py" ]; then
    echo "❌ Bridge script not found at $HOME_DIR/pi_stm32_bridge.py"
    echo "   Please run SETUP_STM32_BRIDGE_AUTOMATIC.sh first"
    exit 1
fi

echo "✅ Bridge script found"

# Step 2: Stop any existing bridge
echo "Stopping any existing bridge processes..."
pkill -f pi_stm32_bridge.py 2>/dev/null || true
sleep 2
echo "✅ Stopped existing processes"
echo ""

# Step 3: Test Azure connection first
echo "Testing Azure connection..."
python3 << 'TEST_AZURE'
import requests
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
    exit(1)
TEST_AZURE

if [ $? -ne 0 ]; then
    echo "❌ Cannot connect to Azure. Check network."
    exit 1
fi

echo ""

# Step 4: Send immediate "online" status (in case UART has issues)
echo "Sending initial 'online' status..."
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

# Step 5: Start bridge script in foreground (so we can see errors)
echo "========================================"
echo "Starting bridge script..."
echo "========================================"
echo ""
echo "If you see errors, press Ctrl+C and check:"
echo "  - UART permissions: sudo usermod -a -G dialout $USER"
echo "  - UART enabled: sudo raspi-config → Interface Options → Serial Port"
echo ""
echo "Press Ctrl+C to stop the bridge"
echo "========================================"
echo ""

cd "$HOME_DIR"
python3 pi_stm32_bridge.py


