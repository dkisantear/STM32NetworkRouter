#!/bin/bash
# ========================================
# Verify Complete STM32 Pipeline
# Checks STM32 → Pi → Azure → Frontend
# ========================================

CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)

echo "========================================"
echo "🔍 Verifying STM32 Pipeline"
echo "========================================"
echo ""

# Step 1: Test STM32 UART directly
echo "1. Testing STM32 UART reception (5 seconds)..."
python3 << 'TEST_UART'
import serial
import time

try:
    ser = serial.Serial('/dev/ttyAMA0', 38400, timeout=1)
    print("   👂 Listening for STM32 messages...")
    
    received_count = 0
    start = time.time()
    while time.time() - start < 5:
        if ser.in_waiting > 0:
            data = ser.read(ser.in_waiting)
            decoded = data.decode('utf-8', errors='ignore').strip()
            if 'STM32_ALIVE' in decoded or decoded:
                received_count += 1
                print(f"   📥 #{received_count}: {repr(decoded)}")
        time.sleep(0.1)
    
    ser.close()
    
    if received_count > 0:
        print(f"   ✅ Received {received_count} message(s) from STM32!")
    else:
        print("   ❌ NO MESSAGES RECEIVED")
        print("      → STM32 may not be sending")
        print("      → Check STM32 is powered and code is flashed")
        
except Exception as e:
    print(f"   ❌ UART error: {e}")
TEST_UART
echo ""

# Step 2: Check if bridge script is running
echo "2. Checking bridge script status..."
if pgrep -f pi_stm32_bridge.py > /dev/null; then
    BRIDGE_PID=$(pgrep -f pi_stm32_bridge.py)
    echo "   ✅ Bridge is running (PID: $BRIDGE_PID)"
    
    # Show recent logs
    if [ -f "$HOME_DIR/stm32-bridge.log" ]; then
        echo "   Recent bridge activity:"
        tail -10 "$HOME_DIR/stm32-bridge.log" | grep -E "(Received|Status sent|ERROR|online|offline)" | tail -5 | sed 's/^/      /'
    fi
else
    echo "   ❌ Bridge is NOT running"
    echo "   → Starting bridge now..."
    
    if [ ! -f "$HOME_DIR/pi_stm32_bridge.py" ]; then
        echo "   ❌ Bridge script not found!"
        exit 1
    fi
    
    cd "$HOME_DIR"
    nohup python3 pi_stm32_bridge.py > "$HOME_DIR/bridge_output.log" 2>&1 &
    sleep 3
    
    if ps -p $! > /dev/null 2>&1; then
        echo "   ✅ Bridge started!"
    else
        echo "   ❌ Failed to start bridge"
        echo "   Check: cat $HOME_DIR/bridge_output.log"
        exit 1
    fi
fi
echo ""

# Step 3: Wait and check bridge is receiving
echo "3. Waiting 5 seconds for bridge to process messages..."
sleep 5

if [ -f "$HOME_DIR/stm32-bridge.log" ]; then
    echo "   Checking bridge logs for received messages:"
    RECEIVED_COUNT=$(grep -c "Received:" "$HOME_DIR/stm32-bridge.log" 2>/dev/null || echo "0")
    if [ "$RECEIVED_COUNT" -gt "0" ]; then
        echo "   ✅ Bridge has received messages (total: $RECEIVED_COUNT)"
        echo "   Last received message:"
        grep "Received:" "$HOME_DIR/stm32-bridge.log" | tail -1 | sed 's/^/      /'
    else
        echo "   ⚠️  Bridge has NOT received any messages yet"
    fi
fi
echo ""

# Step 4: Check Azure status
echo "4. Checking Azure Function status..."
python3 << 'CHECK_AZURE'
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
    
    print(f"   Status: {status}")
    if last_updated:
        print(f"   Last Updated: {last_updated}")
        try:
            last_time = datetime.fromisoformat(last_updated.replace('Z', '+00:00'))
            now = datetime.now(last_time.tzinfo)
            age = (now - last_time).total_seconds()
            print(f"   Age: {int(age)} seconds ago")
        except:
            pass
    
    if status == 'online':
        print("   ✅ Azure shows ONLINE")
    elif status == 'offline':
        print("   ❌ Azure shows OFFLINE")
        print("      → Bridge may not be sending status")
        print("      → Or STM32 messages not received")
    else:
        print("   ❓ Azure shows UNKNOWN")
        
except Exception as e:
    print(f"   ❌ Error checking Azure: {e}")
CHECK_AZURE
echo ""

# Step 5: Send manual test status
echo "5. Sending manual test status to Azure..."
python3 << 'SEND_TEST'
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
    print(f"   → This should make frontend show 'Online' temporarily")
except Exception as e:
    print(f"   ❌ Failed: {e}")
SEND_TEST
echo ""

# Step 6: Final verification
echo "6. Final status check..."
sleep 2

python3 << 'FINAL_CHECK'
import requests

try:
    response = requests.get(
        "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main",
        timeout=5
    )
    result = response.json()
    status = result.get('status', 'unknown')
    
    print(f"   📊 Final Azure Status: {status}")
    
    if status == 'online':
        print("   ✅ SUCCESS! Frontend should show 'Online' now")
        print("   → Refresh your browser to see the update")
    else:
        print("   ⚠️  Status is still not online")
        print("   → Check bridge logs: tail -f ~/stm32-bridge.log")
        print("   → Verify STM32 is continuously sending messages")
        
except Exception as e:
    print(f"   ❌ Error: {e}")
FINAL_CHECK
echo ""

echo "========================================"
echo "📋 Summary & Next Steps"
echo "========================================"
echo ""
echo "If STM32 UART test received messages but bridge didn't:"
echo "  1. Make sure bridge script is running"
echo "  2. Check bridge logs: tail -f ~/stm32-bridge.log"
echo "  3. Verify STM32 sends continuously (not just when test runs)"
echo ""
echo "If bridge received messages but Azure shows offline:"
echo "  1. Check network connectivity from Pi"
echo "  2. Check bridge logs for 'Status sent' messages"
echo "  3. Verify Azure Function endpoint is correct"
echo ""
echo "To monitor bridge in real-time:"
echo "  tail -f ~/stm32-bridge.log"
echo ""

