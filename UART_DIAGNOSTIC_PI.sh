#!/bin/bash
# ========================================
# Complete UART Diagnostic Script
# Run this on Raspberry Pi to diagnose UART issues
# ========================================

echo "========================================"
echo "🔍 UART Diagnostic Tool"
echo "========================================"
echo ""

# 1. Check UART device exists
echo "1. Checking UART device..."
if [ -e "/dev/ttyAMA0" ]; then
    echo "   ✅ /dev/ttyAMA0 exists"
    ls -l /dev/ttyAMA0 | sed 's/^/      /'
else
    echo "   ❌ /dev/ttyAMA0 NOT FOUND"
fi

if [ -e "/dev/serial0" ]; then
    echo "   ✅ /dev/serial0 exists (symlink)"
    ls -l /dev/serial0 | sed 's/^/      /'
    ACTUAL_DEVICE=$(readlink -f /dev/serial0)
    echo "      → Points to: $ACTUAL_DEVICE"
else
    echo "   ❌ /dev/serial0 NOT FOUND"
fi
echo ""

# 2. Check user permissions
echo "2. Checking user permissions..."
CURRENT_USER=$(whoami)
if groups | grep -q dialout; then
    echo "   ✅ User '$CURRENT_USER' is in 'dialout' group"
else
    echo "   ❌ User '$CURRENT_USER' NOT in 'dialout' group"
    echo "      Fix: sudo usermod -a -G dialout $CURRENT_USER"
    echo "      Then logout and login again"
fi
echo ""

# 3. Check for processes using UART
echo "3. Checking for processes using UART..."
UART_PROCESSES=$(lsof /dev/ttyAMA0 2>/dev/null | grep -v COMMAND)
if [ -z "$UART_PROCESSES" ]; then
    echo "   ✅ No processes using /dev/ttyAMA0"
else
    echo "   ⚠️  Processes using UART:"
    echo "$UART_PROCESSES" | sed 's/^/      /'
    echo "   → Kill with: sudo pkill -f <process_name>"
fi
echo ""

# 4. Check UART configuration
echo "4. Checking UART configuration..."
if command -v raspi-config &> /dev/null; then
    echo "   ✅ raspi-config available"
    echo "   → Check: sudo raspi-config → Interface Options → Serial Port"
else
    echo "   ⚠️  raspi-config not found"
fi

# Check boot config
if [ -f "/boot/config.txt" ]; then
    if grep -q "enable_uart=1" /boot/config.txt; then
        echo "   ✅ UART enabled in /boot/config.txt"
    else
        echo "   ❌ UART not enabled in /boot/config.txt"
        echo "      Add: enable_uart=1"
    fi
fi
echo ""

# 5. Test port opening
echo "5. Testing port opening..."
python3 << 'PYTEST'
import serial
import sys

try:
    print("   Attempting to open /dev/ttyAMA0 at 38400 baud...")
    ser = serial.Serial('/dev/ttyAMA0', 38400, timeout=1)
    print("   ✅ Port opened successfully!")
    print(f"      Port: {ser.name}")
    print(f"      Baud: {ser.baudrate}")
    print(f"      Timeout: {ser.timeout}")
    
    # Check if data is waiting
    if ser.in_waiting > 0:
        data = ser.read(ser.in_waiting)
        print(f"   📥 Data waiting: {data}")
    else:
        print("   👂 No data waiting, listening...")
    
    ser.close()
    print("   ✅ Port closed successfully")
except PermissionError:
    print("   ❌ PERMISSION DENIED")
    print("      → User needs to be in 'dialout' group")
    print("      → Fix: sudo usermod -a -G dialout $USER")
    sys.exit(1)
except serial.SerialException as e:
    print(f"   ❌ SERIAL ERROR: {e}")
    if "Device or resource busy" in str(e):
        print("      → Another process is using the port")
        print("      → Kill it with: sudo pkill -f python3")
    sys.exit(1)
except Exception as e:
    print(f"   ❌ UNEXPECTED ERROR: {e}")
    sys.exit(1)
PYTEST

PYTEST_EXIT=$?
echo ""

# 6. Test reading for 3 seconds
if [ $PYTEST_EXIT -eq 0 ]; then
    echo "6. Testing data reception (3 seconds)..."
    python3 << 'PYREAD'
import serial
import time

try:
    ser = serial.Serial('/dev/ttyAMA0', 38400, timeout=1)
    print("   👂 Listening for 3 seconds...")
    
    received_anything = False
    start = time.time()
    while time.time() - start < 3:
        if ser.in_waiting > 0:
            data = ser.read(ser.in_waiting)
            decoded = data.decode('utf-8', errors='ignore').strip()
            print(f"   📥 Received: {repr(decoded)}")
            received_anything = True
        time.sleep(0.1)
    
    ser.close()
    
    if received_anything:
        print("   ✅ Received data from STM32!")
    else:
        print("   ❌ NO DATA RECEIVED")
        print("      → STM32 may not be sending")
        print("      → Check wiring (TX→RX, RX→TX, GND)")
        print("      → Verify STM32 code is running")
except Exception as e:
    print(f"   ❌ Error: {e}")
PYREAD
    echo ""
fi

# 7. Summary
echo "========================================"
echo "📋 Summary"
echo "========================================"
echo ""
echo "If you see 'NO DATA RECEIVED':"
echo "  1. Verify STM32 is powered and running"
echo "  2. Check wiring: STM32 TX→Pi RX, STM32 RX→Pi TX, GND shared"
echo "  3. Verify STM32 code sends 'STM32_ALIVE' every 1 second"
echo "  4. Check baud rates match (38400)"
echo "  5. Try different baud rates if needed"
echo ""
echo "If you see 'PERMISSION DENIED':"
echo "  1. Run: sudo usermod -a -G dialout $USER"
echo "  2. Logout and login again"
echo ""
echo "If you see 'DEVICE BUSY':"
echo "  1. Kill other processes: sudo pkill -f pi_stm32_bridge"
echo "  2. Try again"
echo ""

