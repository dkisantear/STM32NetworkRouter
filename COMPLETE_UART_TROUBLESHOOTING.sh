#!/bin/bash
# ========================================
# Complete UART Troubleshooting - Step by Step
# Let's find the exact problem
# ========================================

echo "========================================"
echo "🔍 COMPLETE UART TROUBLESHOOTING"
echo "========================================"
echo ""
echo "We'll test each part step by step..."
echo ""

# Step 1: Verify Pi UART hardware works
echo "=========================================="
echo "STEP 1: Test Pi UART Hardware (Loopback)"
echo "=========================================="
echo ""
echo "First, let's verify Pi UART hardware works."
echo "If you have a jumper wire, connect:"
echo "  GPIO14 (TXD) → GPIO15 (RXD)"
echo ""
read -p "Do you want to test loopback? (y/n): " test_loopback

if [ "$test_loopback" = "y" ]; then
    echo "Testing loopback..."
    python3 << 'LOOPBACK_TEST'
import serial
import time

try:
    ser = serial.Serial('/dev/ttyAMA0', 38400, timeout=1)
    print("   ✅ Port opened")
    print("   Sending test message...")
    ser.write(b'TEST_LOOPBACK\n')
    time.sleep(0.1)
    
    if ser.in_waiting > 0:
        data = ser.read(ser.in_waiting)
        print(f"   ✅ Received: {data}")
        print("   ✅ Pi UART hardware works!")
    else:
        print("   ❌ No echo received")
        print("   → Check jumper wire connection")
    ser.close()
except Exception as e:
    print(f"   ❌ Error: {e}")
LOOPBACK_TEST
    echo ""
fi

# Step 2: Check STM32 is actually running
echo "=========================================="
echo "STEP 2: Verify STM32 is Running"
echo "=========================================="
echo ""
echo "Check your STM32 board:"
echo "  1. Is it POWERED ON? (LED indicator?)"
echo "  2. Do LEDs respond to DIP switches?"
echo ""
read -p "Are STM32 LEDs working? (y/n): " leds_work

if [ "$leds_work" != "y" ]; then
    echo "   ❌ STM32 code might not be running!"
    echo "   → Re-flash the STM32"
    echo "   → Check power supply"
    echo ""
fi

# Step 3: Verify wiring
echo "=========================================="
echo "STEP 3: Verify Wiring"
echo "=========================================="
echo ""
echo "Check your connections:"
echo ""
echo "STM32          Pi 5"
echo "-----          -----"
echo "PA2 (TX)  →    GPIO15 (RXD)  [Pin 10]"
echo "PA3 (RX)  →    GPIO14 (TXD)  [Pin 8]"
echo "GND       →    GND           [Any GND pin]"
echo ""
echo "⚠️  IMPORTANT: TX→RX, RX→TX (crossed!)"
echo ""
read -p "Is wiring correct? (y/n): " wiring_ok

if [ "$wiring_ok" != "y" ]; then
    echo "   ❌ Fix wiring first!"
    echo "   → Disconnect and reconnect"
    echo "   → Double-check TX→RX crossing"
    echo ""
    exit 1
fi

# Step 4: Test different baud rates
echo "=========================================="
echo "STEP 4: Test Multiple Baud Rates"
echo "=========================================="
echo ""
echo "Testing different baud rates to see if STM32 is sending at all..."
echo ""

python3 << 'BAUD_TEST'
import serial
import time

baud_rates = [9600, 19200, 38400, 57600, 115200]
received_anything = False

for baud in baud_rates:
    try:
        print(f"Testing {baud} baud...")
        ser = serial.Serial('/dev/ttyAMA0', baud, timeout=2)
        time.sleep(0.5)  # Wait for serial to stabilize
        
        # Listen for 3 seconds
        start = time.time()
        found = False
        while time.time() - start < 3:
            if ser.in_waiting > 0:
                data = ser.read(ser.in_waiting)
                decoded = data.decode('utf-8', errors='ignore')
                if decoded.strip():
                    print(f"   ✅ RECEIVED at {baud}: {repr(decoded)}")
                    received_anything = True
                    found = True
                    break
            time.sleep(0.1)
        
        ser.close()
        if not found:
            print(f"   ❌ No data at {baud}")
    except Exception as e:
        print(f"   ❌ Error at {baud}: {e}")

if not received_anything:
    print("")
    print("❌ NO DATA RECEIVED AT ANY BAUD RATE")
    print("   → STM32 might not be sending")
    print("   → Check wiring connections")
    print("   → Verify STM32 is powered and running")
else:
    print("")
    print("✅ Found working baud rate! Update your code to match.")
BAUD_TEST

echo ""

# Step 5: Check UART device permissions
echo "=========================================="
echo "STEP 5: Check UART Permissions"
echo "=========================================="
echo ""

if [ -e "/dev/ttyAMA0" ]; then
    echo "✅ /dev/ttyAMA0 exists"
    ls -l /dev/ttyAMA0 | sed 's/^/   /'
    
    if groups | grep -q dialout; then
        echo "   ✅ User is in 'dialout' group"
    else
        echo "   ❌ User NOT in 'dialout' group"
        echo "   Fix: sudo usermod -a -G dialout $USER"
        echo "   Then logout and login again"
    fi
else
    echo "❌ /dev/ttyAMA0 does not exist"
    echo "   → UART might not be enabled"
    echo "   → Run: sudo raspi-config"
fi
echo ""

# Step 6: Final recommendation
echo "=========================================="
echo "STEP 6: Recommendations"
echo "=========================================="
echo ""

echo "If you still see no messages:"
echo ""
echo "1. VERIFY STM32 CODE IS RUNNING:"
echo "   → Check LEDs respond to DIP switches"
echo "   → If not → Re-flash STM32"
echo ""
echo "2. CHECK WIRING PHYSICALLY:"
echo "   → Disconnect everything"
echo "   → Reconnect carefully:"
echo "     - STM32 PA2 (TX) → Pi GPIO15 (RXD)"
echo "     - STM32 PA3 (RX) → Pi GPIO14 (TXD)"
echo "     - GND to GND"
echo ""
echo "3. VERIFY BAUD RATE IN CODE:"
echo "   → Open STM32CubeMX"
echo "   → Check USART2 baud rate = 38400"
echo "   → Regenerate code and re-flash"
echo ""
echo "4. TEST WITH MULTIMETER (if available):"
echo "   → Probe STM32 PA2 pin"
echo "   → Should see voltage changes when STM32 sends"
echo ""

echo "=========================================="
echo "Troubleshooting complete!"
echo "=========================================="

