#!/bin/bash
# ========================================
# STM32 UART Debug - Step by Step
# Copy/paste this ENTIRE block into Pi terminal
# ========================================

echo "========================================"
echo "🔍 STM32 UART DEBUG - Step by Step"
echo "========================================"
echo ""

# Step 1: Verify STM32 code is running
echo "STEP 1: Verify STM32 Code is Actually Running"
echo "----------------------------------------"
echo ""
echo "On your STM32 board, check:"
echo "  ☐ Do LEDs respond when you change DIP switches?"
echo "  ☐ Do you see any LED activity?"
echo ""
echo "If LEDs DON'T work:"
echo "  → STM32 code is NOT running!"
echo "  → Re-flash the STM32 board"
echo "  → Check power/reset button"
echo ""
read -p "Press ENTER when you've verified LEDs work (or confirm they don't)..."
echo ""

# Step 2: Check UART device exists
echo "STEP 2: Check UART Device"
echo "----------------------------------------"
for dev in "/dev/serial0" "/dev/ttyAMA0"; do
    if [ -e "$dev" ]; then
        echo "✅ Found: $dev"
        ls -l "$dev"
    fi
done
echo ""

# Step 3: Check permissions
echo "STEP 3: Check Permissions"
echo "----------------------------------------"
echo "User: $(whoami)"
if groups | grep -q "dialout\|tty"; then
    echo "✅ User is in dialout/tty group"
else
    echo "⚠️  Adding user to dialout group..."
    sudo usermod -a -G dialout $(whoami)
    echo "⚠️  You may need to log out/in for this to take effect"
fi
echo ""

# Step 4: Test Pi UART hardware with loopback
echo "STEP 4: Test Pi UART Hardware (Loopback)"
echo "----------------------------------------"
echo "⚠️  TEMPORARY: Connect Pi Pin 8 (TXD) to Pi Pin 10 (RXD)"
echo "   (This tests if Pi UART hardware works)"
echo ""
read -p "Press ENTER when wires are connected for loopback test..."

python3 << 'PYEOF'
import serial
import time

try:
    ser = serial.Serial("/dev/serial0", 38400, timeout=1)
    print("✅ Opened /dev/serial0")
    print("📤 Sending test message...")
    
    ser.write(b"LOOPBACK_TEST\n")
    time.sleep(0.1)
    
    if ser.in_waiting:
        data = ser.read(ser.in_waiting)
        print(f"📥 Received: {data}")
        print("✅ LOOPBACK WORKS - Pi UART hardware is OK!")
    else:
        print("❌ No loopback - Pi UART might have hardware issue")
    
    ser.close()
except Exception as e:
    print(f"❌ Error: {e}")

PYEOF

echo ""
read -p "Press ENTER after removing loopback wires and reconnecting STM32..."
echo ""

# Step 5: Try both UART devices and different baud rates
echo "STEP 5: Comprehensive UART Test"
echo "----------------------------------------"
python3 << 'PYEOF'
import serial
import time

devices = ["/dev/serial0", "/dev/ttyAMA0"]
baudrates = [38400, 9600]  # Try both baud rates

found_working = False

for device in devices:
    for baudrate in baudrates:
        print(f"\n{'='*60}")
        print(f"Testing: {device} at {baudrate} baud")
        print(f"{'='*60}")
        
        try:
            ser = serial.Serial(device, baudrate, timeout=1)
            print(f"✅ Opened successfully")
            print("👂 Listening for 10 seconds...")
            print("   (Make sure STM32 is powered on)")
            print()
            
            received_count = 0
            start = time.time()
            
            while time.time() - start < 10:
                if ser.in_waiting:
                    try:
                        line = ser.readline().decode("utf-8", errors="ignore").strip()
                        if line:
                            received_count += 1
                            elapsed = time.time() - start
                            print(f"[+{elapsed:.1f}s] #{received_count}: {repr(line)}")
                            if "STM32" in line or "ALIVE" in line:
                                print("   ✅ STM32 MESSAGE RECEIVED!")
                    except:
                        pass
                time.sleep(0.1)
            
            ser.close()
            
            if received_count > 0:
                print(f"\n✅✅✅ SUCCESS! ✅✅✅")
                print(f"✅ Device: {device}")
                print(f"✅ Baudrate: {baudrate}")
                print(f"✅ Received {received_count} message(s)")
                found_working = True
                break
            else:
                print(f"⚠️  No messages received")
                
        except Exception as e:
            print(f"❌ Error: {e}")
    
    if found_working:
        break

if not found_working:
    print("\n" + "="*60)
    print("❌ NO UART COMMUNICATION DETECTED")
    print("="*60)
    print("\nNext steps to debug:")
    print("  1. Verify STM32 code is running (check LEDs)")
    print("  2. Check STM32 PA2 pin with multimeter (should pulse every 1s)")
    print("  3. Verify wiring is correct:")
    print("     STM32 PA2 (TX) → Pi Pin 10 (RXD)")
    print("     STM32 PA3 (RX) → Pi Pin 8  (TXD)")
    print("     GND → GND")
    print("  4. Try slower baud rate (9600) on STM32")
    print("  5. Check STM32 USART2 is enabled and configured correctly")

PYEOF

