#!/bin/bash
# ========================================
# Complete UART Diagnostic Script
# Copy/paste this ENTIRE block into Pi terminal
# ========================================

echo "========================================"
echo "🔍 COMPLETE UART DIAGNOSTIC"
echo "========================================"
echo ""

# Step 1: Check UART devices
echo "1️⃣  Checking UART devices..."
echo "----------------------------------------"
for dev in "/dev/serial0" "/dev/ttyAMA0" "/dev/ttyS0"; do
    if [ -e "$dev" ]; then
        echo "✅ Found: $dev"
        ls -l "$dev" 2>/dev/null
    else
        echo "❌ Not found: $dev"
    fi
done
echo ""

# Step 2: Check permissions
echo "2️⃣  Checking permissions..."
echo "----------------------------------------"
echo "Current user: $(whoami)"
echo "User groups: $(groups)"
if groups | grep -q "dialout\|tty"; then
    echo "✅ User is in dialout/tty group"
else
    echo "⚠️  User NOT in dialout group"
    echo "   Run: sudo usermod -a -G dialout $USER"
fi
echo ""

# Step 3: Check UART configuration
echo "3️⃣  Checking UART configuration..."
echo "----------------------------------------"
if [ -f "/boot/firmware/config.txt" ]; then
    echo "Checking /boot/firmware/config.txt:"
    grep -i "uart\|serial" /boot/firmware/config.txt 2>/dev/null || echo "  (no uart config found)"
elif [ -f "/boot/config.txt" ]; then
    echo "Checking /boot/config.txt:"
    grep -i "uart\|serial" /boot/config.txt 2>/dev/null || echo "  (no uart config found)"
fi
echo ""

# Step 4: Test both devices with Python
echo "4️⃣  Testing UART devices (listening for 5 seconds each)..."
echo "----------------------------------------"
cat > /tmp/uart_test_devices.py << 'PYEOF'
#!/usr/bin/env python3
import serial
import time
import sys

devices_to_test = ["/dev/serial0", "/dev/ttyAMA0"]
baudrate = 38400

for device in devices_to_test:
    print(f"\n📡 Testing {device}...")
    try:
        ser = serial.Serial(device, baudrate, timeout=1)
        print(f"   ✅ Opened successfully")
        print(f"   👂 Listening for 5 seconds...")
        
        received_count = 0
        start_time = time.time()
        
        while time.time() - start_time < 5:
            if ser.in_waiting:
                try:
                    line = ser.readline().decode("utf-8", errors="ignore").strip()
                    if line:
                        received_count += 1
                        timestamp = time.strftime("%H:%M:%S")
                        print(f"   [{timestamp}] 📥 Received: {repr(line)}")
                        if line == "STM32_ALIVE":
                            print(f"      ✅ CORRECT MESSAGE FORMAT!")
                except:
                    pass
            time.sleep(0.1)
        
        ser.close()
        
        if received_count > 0:
            print(f"   ✅ SUCCESS! Received {received_count} message(s)")
            print(f"   ✅ Use this device: {device}")
            break
        else:
            print(f"   ⚠️  No data received (STM32 might not be sending)")
            
    except FileNotFoundError:
        print(f"   ❌ Device not found")
    except PermissionError:
        print(f"   ❌ Permission denied - run: sudo usermod -a -G dialout $USER")
    except Exception as e:
        print(f"   ❌ Error: {e}")

PYEOF

python3 /tmp/uart_test_devices.py

# Step 5: Check STM32 connection (optional - try to send data)
echo ""
echo "5️⃣  Testing reverse direction (Pi → STM32)..."
echo "----------------------------------------"
cat > /tmp/uart_send_test.py << 'PYEOF'
#!/usr/bin/env python3
import serial
import time

device = "/dev/serial0"
baudrate = 38400

try:
    ser = serial.Serial(device, baudrate, timeout=1)
    print(f"✅ Opened {device} for sending")
    print("📤 Sending 3 test messages...")
    
    for i in range(3):
        msg = f"PI_TEST_{i}\n"
        ser.write(msg.encode())
        print(f"   Sent: {msg.strip()}")
        time.sleep(1)
    
    ser.close()
    print("✅ Sent successfully")
    print("   (If STM32 is listening, it should see these)")
except Exception as e:
    print(f"❌ Error sending: {e}")
PYEOF

python3 /tmp/uart_send_test.py

# Step 6: Summary and recommendations
echo ""
echo "========================================"
echo "📋 DIAGNOSTIC SUMMARY"
echo "========================================"
echo ""
echo "If you saw NO messages:"
echo "  → Check STM32 is powered and running"
echo "  → Verify STM32 code is flashed correctly"
echo "  → Check wiring (STM32 TX → Pi RX)"
echo "  → Try swapping TX/RX wires"
echo "  → Verify baudrate matches (38400)"
echo ""
echo "If you saw permission errors:"
echo "  → Run: sudo usermod -a -G dialout $USER"
echo "  → Log out and back in"
echo ""
echo "If device not found:"
echo "  → Enable UART: sudo raspi-config"
echo "  → Reboot: sudo reboot"
echo ""
echo "Next steps:"
echo "  1. Verify STM32 LEDs are working (confirms code is running)"
echo "  2. Double-check wiring diagram"
echo "  3. Try slower baud rate (9600) as test"
echo ""

