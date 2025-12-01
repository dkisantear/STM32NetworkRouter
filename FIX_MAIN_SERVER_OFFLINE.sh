#!/bin/bash
# ========================================
# Fix Main Server Offline Status
# Ensures bridge is running and sending to Azure
# ========================================

CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)

echo "========================================"
echo "🔧 Fix Main Server Offline Status"
echo "========================================"
echo ""

# Step 1: Check if bridge is running
echo "1. Checking if bridge is running..."
if pgrep -f pi_stm32_bridge.py > /dev/null; then
    BRIDGE_PID=$(pgrep -f pi_stm32_bridge.py)
    echo "   ✅ Bridge is running (PID: $BRIDGE_PID)"
    echo "   Checking recent logs..."
    if [ -f "$HOME_DIR/stm32-bridge.log" ]; then
        echo "   Last 5 lines from log:"
        tail -5 "$HOME_DIR/stm32-bridge.log" | sed 's/^/      /'
    fi
else
    echo "   ❌ Bridge is NOT running"
    echo "   Starting bridge now..."
    
    # Make sure script exists
    if [ ! -f "$HOME_DIR/pi_stm32_bridge.py" ]; then
        echo "   ❌ Bridge script not found!"
        echo "   Please copy pi_stm32_bridge.py to $HOME_DIR/"
        exit 1
    fi
    
    # Start bridge
    cd "$HOME_DIR"
    nohup python3 pi_stm32_bridge.py > "$HOME_DIR/bridge_output.log" 2>&1 &
    BRIDGE_PID=$!
    sleep 3
    
    if ps -p $BRIDGE_PID > /dev/null 2>&1; then
        echo "   ✅ Bridge started! (PID: $BRIDGE_PID)"
    else
        echo "   ❌ Failed to start bridge"
        echo "   Check: cat $HOME_DIR/bridge_output.log"
        exit 1
    fi
fi
echo ""

# Step 2: Wait a moment and check Azure status
echo "2. Checking Azure status..."
sleep 2

python3 << 'CHECK_AZURE'
import requests
import json

try:
    response = requests.get(
        "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main",
        timeout=5
    )
    result = response.json()
    status = result.get('status', 'unknown')
    last_updated = result.get('lastUpdated', None)
    
    print(f"   Status: {status}")
    print(f"   Last Updated: {last_updated}")
    
    if status == 'online':
        print("   ✅ SUCCESS! Azure shows online")
    elif status == 'offline':
        print("   ⚠️  Azure shows offline")
        print("   → Bridge may not be receiving UART messages")
    else:
        print("   ❓ Status is unknown")
        print("   → Bridge may not have sent any status yet")
        
except Exception as e:
    print(f"   ❌ Error checking Azure: {e}")
CHECK_AZURE
echo ""

# Step 3: Send manual status update
echo "3. Sending manual status update to Azure..."
python3 << 'SEND_STATUS'
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
    print(f"   ✅ Manual status sent: {result.get('status')}")
    print(f"   Last Updated: {result.get('lastUpdated')}")
except Exception as e:
    print(f"   ❌ Failed to send status: {e}")
SEND_STATUS
echo ""

# Step 4: Verify UART is receiving data
echo "4. Testing UART reception (5 seconds)..."
python3 << 'TEST_UART'
import serial
import time

try:
    ser = serial.Serial('/dev/ttyAMA0', 38400, timeout=1)
    print("   👂 Listening for 5 seconds...")
    
    received = False
    start = time.time()
    while time.time() - start < 5:
        if ser.in_waiting > 0:
            data = ser.read(ser.in_waiting)
            decoded = data.decode('utf-8', errors='ignore').strip()
            if 'STM32_ALIVE' in decoded:
                print(f"   ✅ Received: {repr(decoded)}")
                received = True
        time.sleep(0.1)
    
    ser.close()
    
    if received:
        print("   ✅ UART is receiving STM32 messages!")
        print("   → Bridge should be working now")
    else:
        print("   ⚠️  No UART messages received")
        print("   → Check STM32 is powered and sending")
        
except Exception as e:
    print(f"   ❌ UART test error: {e}")
TEST_UART
echo ""

# Step 5: Final status check
echo "5. Final Azure status check..."
sleep 2

python3 << 'FINAL_CHECK'
import requests
from datetime import datetime

try:
    response = requests.get(
        "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main",
        timeout=5
    )
    result = response.json()
    status = result.get('status', 'unknown')
    last_updated = result.get('lastUpdated', None)
    
    print(f"   📊 Final Status: {status}")
    if last_updated:
        print(f"   📅 Last Updated: {last_updated}")
    
    if status == 'online':
        print("   ✅ SUCCESS! Main Server should show 'Online' now")
        print("   → Refresh your browser to see the update")
    else:
        print("   ⚠️  Status is still not online")
        print("   → Check bridge logs: tail -f ~/stm32-bridge.log")
        
except Exception as e:
    print(f"   ❌ Error: {e}")
FINAL_CHECK
echo ""

echo "========================================"
echo "📋 Next Steps:"
echo "========================================"
echo ""
echo "1. Refresh your browser dashboard"
echo "2. Main Server card should show 'Online' if everything worked"
echo "3. If still offline, check bridge logs:"
echo "   tail -f ~/stm32-bridge.log"
echo ""
echo "4. To monitor bridge status:"
echo "   ps aux | grep pi_stm32_bridge"
echo ""

