#!/bin/bash
# ========================================
# Start Bridge and Keep It Running
# This will start the bridge and ensure it stays running
# ========================================

CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)

echo "========================================"
echo "🚀 Start Bridge and Keep Running"
echo "========================================"
echo ""

# Step 1: Kill any existing bridge
echo "1. Stopping any existing bridge processes..."
pkill -f pi_stm32_bridge.py 2>/dev/null || true
sleep 2
echo "✅ Stopped"
echo ""

# Step 2: Check script exists
if [ ! -f "$HOME_DIR/pi_stm32_bridge.py" ]; then
    echo "❌ Bridge script not found at $HOME_DIR/pi_stm32_bridge.py"
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
    print("✅ Azure connection works!")
except Exception as e:
    print(f"⚠️  Azure connection test failed: {e}")
    print("   Continuing anyway...")
TEST_AZURE
echo ""

# Step 4: Start bridge script
echo "3. Starting bridge script..."
cd "$HOME_DIR"
nohup python3 pi_stm32_bridge.py > bridge_output.log 2>&1 &
BRIDGE_PID=$!

sleep 3

# Verify it's running
if ps -p $BRIDGE_PID > /dev/null 2>&1; then
    echo "✅ Bridge started! (PID: $BRIDGE_PID)"
else
    echo "❌ Bridge failed to start!"
    echo "Check logs: cat $HOME_DIR/bridge_output.log"
    exit 1
fi
echo ""

# Step 5: Check logs after a moment
echo "4. Checking initial activity..."
sleep 5

if [ -f "$HOME_DIR/stm32-bridge.log" ]; then
    echo "Recent log entries:"
    tail -10 "$HOME_DIR/stm32-bridge.log" | tail -5 | sed 's/^/   /'
else
    echo "⚠️  Log file not created yet"
fi
echo ""

# Step 6: Verify it's still running
if ps -p $BRIDGE_PID > /dev/null 2>&1; then
    echo "✅ Bridge is still running"
else
    echo "❌ Bridge stopped unexpectedly!"
    echo "Check: cat $HOME_DIR/bridge_output.log"
fi
echo ""

echo "========================================"
echo "✅ Bridge Started!"
echo "========================================"
echo ""
echo "The bridge should now be running and keeping status online."
echo ""
echo "📋 Useful commands:"
echo "   Check if running:  ps aux | grep pi_stm32_bridge"
echo "   View logs:         tail -f ~/stm32-bridge.log"
echo "   Stop bridge:       pkill -f pi_stm32_bridge"
echo ""

