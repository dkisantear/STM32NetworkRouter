#!/bin/bash
# ========================================
# Quick UART Connection Test
# Copy/paste this into Pi terminal to verify UART is still working
# ========================================

echo "========================================"
echo "🔍 Quick UART Connection Test"
echo "========================================"
echo ""

# Test 1: Check device exists
echo "1. Checking UART device..."
if [ -e "/dev/ttyAMA0" ]; then
    echo "   ✅ /dev/ttyAMA0 exists"
    ls -l /dev/ttyAMA0
else
    echo "   ❌ /dev/ttyAMA0 not found"
    exit 1
fi
echo ""

# Test 2: Quick listen test
echo "2. Listening for STM32 messages (10 seconds)..."
echo "   (Make sure STM32 is powered on and running)"
echo ""

python3 << 'PYEOF'
import serial
import time

try:
    ser = serial.Serial("/dev/ttyAMA0", 38400, timeout=1)
    print("   ✅ Port opened")
    
    messages_received = 0
    start_time = time.time()
    
    while time.time() - start_time < 10:
        if ser.in_waiting:
            line = ser.readline().decode("utf-8", errors="ignore").strip()
            if line:
                messages_received += 1
                elapsed = time.time() - start_time
                print(f"   [{elapsed:.1f}s] 📥 Received: {repr(line)}")
                if "STM32" in line or "ALIVE" in line:
                    print(f"      ✅ Correct message format!")
        
        time.sleep(0.1)
    
    ser.close()
    
    if messages_received > 0:
        print(f"\n   ✅ SUCCESS! Received {messages_received} message(s)")
        print(f"   ✅ UART connection is working!")
    else:
        print(f"\n   ⚠️  No messages received")
        print(f"   → Check STM32 is powered on")
        print(f"   → Check wiring is connected")
        print(f"   → Check STM32 is sending messages")
        
except Exception as e:
    print(f"   ❌ Error: {e}")

PYEOF

echo ""
echo "========================================"
echo "✅ Test complete!"
echo "========================================"

