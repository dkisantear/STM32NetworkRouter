#!/bin/bash
# ========================================
# Keep STM32 Bridge Running Forever
# Starts bridge in background and auto-restarts on failure
# Copy/paste this ENTIRE block into Pi terminal
# ========================================

CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)

echo "========================================"
echo "🔄 Keep Bridge Running Forever"
echo "========================================"
echo ""

# Stop any existing bridge
pkill -f pi_stm32_bridge.py 2>/dev/null || true
sleep 2

# Check if script exists
if [ ! -f "$HOME_DIR/pi_stm32_bridge.py" ]; then
    echo "❌ Bridge script not found!"
    echo "Run SETUP_STM32_BRIDGE_AUTOMATIC.sh first"
    exit 1
fi

echo "✅ Starting bridge with auto-restart..."
echo ""

# Create a wrapper script that auto-restarts
cat > "$HOME_DIR/keep_bridge_alive.sh" << 'WRAPPER_EOF'
#!/bin/bash
CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)

while true; do
    echo "$(date): Starting STM32 bridge..."
    python3 "$HOME_DIR/pi_stm32_bridge.py"
    EXIT_CODE=$?
    echo "$(date): Bridge exited with code $EXIT_CODE"
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo "Bridge stopped normally (Ctrl+C). Exiting wrapper."
        break
    else
        echo "Bridge crashed or stopped unexpectedly. Restarting in 5 seconds..."
        sleep 5
    fi
done
WRAPPER_EOF

chmod +x "$HOME_DIR/keep_bridge_alive.sh"

# Start the wrapper script in background
cd "$HOME_DIR"
nohup "$HOME_DIR/keep_bridge_alive.sh" > "$HOME_DIR/bridge_wrapper.log" 2>&1 &
WRAPPER_PID=$!

sleep 3

# Check if running
if ps -p $WRAPPER_PID > /dev/null 2>&1; then
    echo "✅ Bridge wrapper started! (PID: $WRAPPER_PID)"
    echo ""
    echo "The bridge will automatically restart if it crashes."
    echo ""
    echo "Useful commands:"
    echo "  View bridge logs:      tail -f ~/stm32-bridge.log"
    echo "  View wrapper logs:     tail -f ~/bridge_wrapper.log"
    echo "  Check if running:      ps aux | grep pi_stm32_bridge"
    echo "  Stop bridge:           pkill -f keep_bridge_alive.sh"
    echo "  Stop all:              pkill -f pi_stm32_bridge"
    echo ""
    
    # Wait a moment and check status
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
    print(f"📊 Current status: {status}")
    if status == 'online':
        print("✅ SUCCESS! Bridge is working!")
except Exception as e:
    print(f"⚠️  Error checking status: {e}")
CHECK_STATUS
else
    echo "❌ Failed to start bridge wrapper!"
    echo "Check logs: cat ~/bridge_wrapper.log"
    exit 1
fi


