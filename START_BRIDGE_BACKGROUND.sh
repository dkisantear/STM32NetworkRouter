#!/bin/bash
# ========================================
# Start STM32 Bridge in Background
# Copy/paste this ENTIRE block into Pi terminal
# ========================================

CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)

echo "========================================"
echo "🚀 Starting STM32 Bridge (Background)"
echo "========================================"
echo ""

# Check if script exists
if [ ! -f "$HOME_DIR/pi_stm32_bridge.py" ]; then
    echo "❌ Bridge script not found!"
    echo "Run SETUP_STM32_BRIDGE_AUTOMATIC.sh first"
    exit 1
fi

# Stop existing
pkill -f pi_stm32_bridge.py 2>/dev/null || true
sleep 2

# Send immediate status
echo "Sending initial 'online' status..."
python3 << 'EOF'
import requests
try:
    r = requests.post(
        "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status",
        json={"deviceId": "stm32-main", "status": "online"},
        headers={"Content-Type": "application/json"},
        timeout=10
    )
    print(f"✅ Initial status sent: {r.json()}")
except Exception as e:
    print(f"⚠️  Failed to send initial status: {e}")
EOF

echo ""

# Start bridge
echo "Starting bridge script in background..."
cd "$HOME_DIR"
nohup python3 pi_stm32_bridge.py > "$HOME_DIR/bridge_output.log" 2>&1 &
BRIDGE_PID=$!

sleep 3

# Check if running
if ps -p $BRIDGE_PID > /dev/null 2>&1; then
    echo "✅ Bridge started! (PID: $BRIDGE_PID)"
    echo ""
    echo "Checking logs..."
    sleep 2
    tail -20 "$HOME_DIR/stm32-bridge.log" 2>/dev/null || echo "   (Log file not created yet - waiting...)"
    echo ""
    echo "========================================"
    echo "✅ Bridge is running!"
    echo "========================================"
    echo ""
    echo "Useful commands:"
    echo "  View logs:     tail -f ~/stm32-bridge.log"
    echo "  View output:   tail -f ~/bridge_output.log"
    echo "  Check status:  ps aux | grep pi_stm32_bridge"
    echo "  Stop bridge:   pkill -f pi_stm32_bridge.py"
    echo ""
    
    # Verify status after 5 seconds
    echo "Verifying status update in 5 seconds..."
    sleep 5
    python3 << 'CHECK_STATUS'
import requests
try:
    r = requests.get(
        "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main",
        timeout=5
    )
    result = r.json()
    status = result.get('status', 'unknown')
    print(f"\n📊 Current status: {status}")
    if status == 'online':
        print("✅ SUCCESS! Status is 'online'")
    elif status == 'unknown':
        print("⚠️  Status is 'unknown' - bridge may still be starting")
        print("   Check logs: tail -f ~/stm32-bridge.log")
    else:
        print(f"⚠️  Status is '{status}'")
except Exception as e:
    print(f"❌ Error checking status: {e}")
CHECK_STATUS
    
else
    echo "❌ Bridge failed to start!"
    echo ""
    echo "Check error output:"
    cat "$HOME_DIR/bridge_output.log" 2>/dev/null || echo "   (No output file)"
    echo ""
    echo "Try running in foreground to see errors:"
    echo "  python3 ~/pi_stm32_bridge.py"
    exit 1
fi


