#!/bin/bash
# ========================================
# Diagnose Why Status Goes Offline
# ========================================

echo "========================================"
echo "🔍 Diagnosing Offline Status Issue"
echo "========================================"
echo ""

# Step 1: Check if bridge is running
echo "1. Checking bridge process..."
if pgrep -f pi_stm32_bridge.py > /dev/null; then
    BRIDGE_PID=$(pgrep -f pi_stm32_bridge.py)
    echo "   ✅ Bridge is running (PID: $BRIDGE_PID)"
else
    echo "   ❌ Bridge is NOT running"
    echo "   → This explains why status is offline!"
    exit 1
fi
echo ""

# Step 2: Check recent bridge logs for received messages
echo "2. Checking if bridge is receiving messages..."
if [ -f ~/stm32-bridge.log ]; then
    RECEIVED_COUNT=$(grep -c "📥 Received" ~/stm32-bridge.log 2>/dev/null || echo "0")
    RECENT_RECEIVED=$(grep "📥 Received" ~/stm32-bridge.log | tail -5)
    
    echo "   Total messages received: $RECEIVED_COUNT"
    
    if [ "$RECEIVED_COUNT" -gt "0" ]; then
        echo "   ✅ Bridge HAS received messages"
        echo "   Last 5 received messages:"
        echo "$RECENT_RECEIVED" | tail -5 | sed 's/^/      /'
    else
        echo "   ❌ Bridge has NOT received any messages"
        echo "   → STM32 might not be sending, or UART errors preventing reception"
    fi
else
    echo "   ⚠️  Log file not found"
fi
echo ""

# Step 3: Check for errors
echo "3. Checking for errors in logs..."
if [ -f ~/stm32-bridge.log ]; then
    ERROR_COUNT=$(grep -c "ERROR" ~/stm32-bridge.log 2>/dev/null || echo "0")
    RECENT_ERRORS=$(grep "ERROR" ~/stm32-bridge.log | tail -5)
    
    if [ "$ERROR_COUNT" -gt "0" ]; then
        echo "   ⚠️  Found $ERROR_COUNT error(s) in logs"
        echo "   Recent errors:"
        echo "$RECENT_ERRORS" | tail -5 | sed 's/^/      /'
    else
        echo "   ✅ No errors in logs"
    fi
fi
echo ""

# Step 4: Check Azure status
echo "4. Checking current Azure status..."
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
            
            if status == 'offline' and age < 20:
                print("   → Status just went offline (recently updated)")
            elif status == 'offline' and age > 90:
                print("   → Status offline due to Azure timeout (90s)")
        except:
            pass
    
    if status == 'online':
        print("   ✅ Azure shows online")
    elif status == 'offline':
        print("   ❌ Azure shows offline")
        print("   → Check if bridge is receiving messages")
    else:
        print("   ❓ Azure shows unknown")
        
except Exception as e:
    print(f"   ❌ Error checking Azure: {e}")
CHECK_AZURE
echo ""

# Step 5: Test UART directly (if bridge not reading properly)
echo "5. Quick UART test (5 seconds)..."
python3 << 'TEST_UART'
import serial
import time

try:
    # Only test if port is not in use
    ser = serial.Serial('/dev/ttyAMA0', 38400, timeout=1)
    print("   👂 Testing UART reception...")
    
    received = False
    start = time.time()
    while time.time() - start < 5:
        if ser.in_waiting > 0:
            data = ser.read(ser.in_waiting)
            decoded = data.decode('utf-8', errors='ignore').strip()
            if decoded:
                print(f"   ✅ Received: {repr(decoded)}")
                received = True
        time.sleep(0.1)
    
    ser.close()
    
    if received:
        print("   ✅ UART is receiving data!")
        print("   → Bridge script should be receiving too")
    else:
        print("   ❌ UART test received nothing")
        print("   → STM32 might not be sending, or wiring issue")
        
except serial.SerialException as e:
    if "could not open port" in str(e).lower() or "device or resource busy" in str(e).lower():
        print("   ⚠️  Port is busy (bridge script is using it)")
        print("   → This is normal - bridge script should be reading")
    else:
        print(f"   ❌ UART error: {e}")
except Exception as e:
    print(f"   ❌ Error: {e}")
TEST_UART
echo ""

# Step 6: Summary
echo "========================================"
echo "📋 Summary"
echo "========================================"
echo ""
echo "If bridge is running but status is offline:"
echo "  1. Check logs for '📥 Received' messages"
echo "  2. If no messages → STM32 not sending or UART issue"
echo "  3. If messages but offline → Bridge not POSTing to Azure"
echo ""
echo "If bridge is not running:"
echo "  → Start it: nohup python3 ~/pi_stm32_bridge.py > bridge_output.log 2>&1 &"
echo ""

