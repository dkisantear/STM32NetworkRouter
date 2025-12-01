#!/bin/bash
# ========================================
# Diagnose STM32 Bridge Issues
# Copy/paste into Pi terminal
# ========================================

CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)

echo "========================================"
echo "🔍 STM32 Bridge Diagnostics"
echo "========================================"
echo ""

# 1. Check script exists
echo "1. Checking bridge script..."
if [ -f "$HOME_DIR/pi_stm32_bridge.py" ]; then
    echo "   ✅ Script exists: $HOME_DIR/pi_stm32_bridge.py"
else
    echo "   ❌ Script NOT found: $HOME_DIR/pi_stm32_bridge.py"
    echo "   → Run SETUP_STM32_BRIDGE_AUTOMATIC.sh first"
fi
echo ""

# 2. Check if running
echo "2. Checking if bridge is running..."
if pgrep -f pi_stm32_bridge.py > /dev/null; then
    PID=$(pgrep -f pi_stm32_bridge.py)
    echo "   ✅ Bridge is running (PID: $PID)"
    ps aux | grep pi_stm32_bridge | grep -v grep
else
    echo "   ❌ Bridge is NOT running"
fi
echo ""

# 3. Check log file
echo "3. Checking log file..."
if [ -f "$HOME_DIR/stm32-bridge.log" ]; then
    echo "   ✅ Log file exists: $HOME_DIR/stm32-bridge.log"
    echo "   Last 10 lines:"
    tail -10 "$HOME_DIR/stm32-bridge.log" | sed 's/^/      /'
else
    echo "   ⚠️  Log file does NOT exist: $HOME_DIR/stm32-bridge.log"
    echo "   → Script may not have started successfully"
fi
echo ""

# 4. Check UART device
echo "4. Checking UART device..."
if [ -e "/dev/ttyAMA0" ]; then
    echo "   ✅ UART device exists: /dev/ttyAMA0"
    ls -l /dev/ttyAMA0 | sed 's/^/      /'
    
    # Check permissions
    if groups | grep -q dialout; then
        echo "   ✅ User is in 'dialout' group"
    else
        echo "   ⚠️  User NOT in 'dialout' group"
        echo "   → Fix: sudo usermod -a -G dialout $CURRENT_USER"
        echo "   → Then logout and login again"
    fi
else
    echo "   ❌ UART device NOT found: /dev/ttyAMA0"
    echo "   → Enable UART: sudo raspi-config → Interface Options → Serial Port"
fi
echo ""

# 5. Check Azure connection
echo "5. Testing Azure connection..."
python3 << 'AZURE_TEST'
import requests
try:
    response = requests.get(
        "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main",
        timeout=10
    )
    response.raise_for_status()
    result = response.json()
    print(f"   ✅ Azure connection works!")
    print(f"   Status: {result.get('status', 'unknown')}")
    print(f"   Last Updated: {result.get('lastUpdated', 'N/A')}")
except Exception as e:
    print(f"   ❌ Azure connection failed: {e}")
AZURE_TEST

echo ""

# 6. Test sending status
echo "6. Testing sending status to Azure..."
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
    print(f"   ✅ Successfully sent status!")
    print(f"   Response: {result}")
except Exception as e:
    print(f"   ❌ Failed to send status: {e}")
SEND_TEST

echo ""

# 7. Check Python dependencies
echo "7. Checking Python dependencies..."
python3 << 'DEP_CHECK'
try:
    import serial
    print("   ✅ pyserial installed")
except ImportError:
    print("   ❌ pyserial NOT installed")
    print("   → Fix: pip3 install pyserial --break-system-packages")

try:
    import requests
    print("   ✅ requests installed")
except ImportError:
    print("   ❌ requests NOT installed")
    print("   → Fix: pip3 install requests --break-system-packages")
DEP_CHECK

echo ""

echo "========================================"
echo "Diagnostics Complete"
echo "========================================"
echo ""
echo "If bridge is not running, try:"
echo "  ./START_BRIDGE_BACKGROUND.sh"
echo "  OR"
echo "  python3 ~/pi_stm32_bridge.py  (run in foreground to see errors)"
echo ""


