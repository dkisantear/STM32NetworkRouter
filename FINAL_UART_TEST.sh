#!/bin/bash
# ========================================
# FINAL UART TEST - Tries Everything
# Copy/paste this ENTIRE block into Pi terminal
# ========================================

echo "========================================"
echo "🔍 FINAL UART TEST - Comprehensive"
echo "========================================"
echo ""

# First, verify STM32 is running
echo "⚠️  IMPORTANT: Before running this test..."
echo "   → Check STM32 LEDs respond to DIP switches"
echo "   → If LEDs don't work, STM32 code isn't running!"
echo ""
read -p "Press ENTER to continue..."
echo ""

python3 << 'PYEOF'
import serial
import time
import sys

print("="*70)
print("Testing ALL combinations of device and baud rate...")
print("="*70)
print()

devices = ["/dev/serial0", "/dev/ttyAMA0"]
baudrates = [38400, 9600, 115200]  # Try common baud rates
test_duration = 8  # seconds per test

found_any = False

for device in devices:
    for baudrate in baudrates:
        print(f"\n{'='*70}")
        print(f"TEST: {device} @ {baudrate} baud")
        print(f"{'='*70}")
        
        try:
            ser = serial.Serial(device, baudrate, timeout=1)
            print(f"✅ Port opened")
            
            print(f"👂 Listening for {test_duration} seconds...")
            print("   (Make sure STM32 is powered on)")
            print()
            
            messages = []
            start = time.time()
            last_print = 0
            
            while time.time() - start < test_duration:
                elapsed = time.time() - start
                
                # Print progress every 2 seconds
                if elapsed - last_print >= 2:
                    print(f"   [{elapsed:.0f}s] Still listening...")
                    last_print = elapsed
                
                if ser.in_waiting:
                    try:
                        # Try to read a line
                        raw = ser.read(ser.in_waiting)
                        decoded = raw.decode("utf-8", errors="ignore")
                        
                        # Split by newlines
                        for line in decoded.split('\n'):
                            line = line.strip()
                            if line:
                                messages.append(line)
                                print(f"\n   ✅ RECEIVED: {repr(line)}")
                                found_any = True
                    except Exception as e:
                        # Try reading raw bytes
                        raw = ser.read(ser.in_waiting)
                        if raw:
                            print(f"\n   ⚠️  RAW DATA: {raw.hex()}")
                            print(f"      (Could be baud rate mismatch)")
                
                time.sleep(0.1)
            
            ser.close()
            
            if messages:
                print(f"\n{'='*70}")
                print(f"✅ SUCCESS! Found {len(messages)} message(s)")
                print(f"✅ WORKING CONFIGURATION:")
                print(f"   Device: {device}")
                print(f"   Baudrate: {baudrate}")
                print(f"   Messages: {messages}")
                print(f"{'='*70}")
                sys.exit(0)
            else:
                print(f"\n   ⚠️  No messages received")
                
        except FileNotFoundError:
            print(f"   ❌ Device not found")
        except PermissionError:
            print(f"   ❌ Permission denied")
            print(f"   → Run: sudo usermod -a -G dialout $USER")
        except Exception as e:
            print(f"   ❌ Error: {e}")

print(f"\n{'='*70}")
print("❌ NO UART COMMUNICATION DETECTED")
print(f"{'='*70}")

print("\n🔍 DIAGNOSIS:")
print()

if not found_any:
    print("Possible issues:")
    print()
    print("1. STM32 code not running:")
    print("   → Check LEDs respond to DIP switches")
    print("   → If LEDs don't work, re-flash STM32")
    print("   → Add LED blink to STM32 code to verify")
    print()
    print("2. Wiring issue:")
    print("   → Double-check: STM32 PA2 (TX) → Pi Pin 10 (RXD)")
    print("   → Try swapping TX/RX wires")
    print("   → Verify GND is connected")
    print()
    print("3. Hardware issue:")
    print("   → Test Pi UART with loopback (Pin 8 → Pin 10)")
    print("   → Check STM32 PA2 pin with multimeter")
    print("   → Verify STM32 USART2 is actually enabled")
    print()
    print("4. Configuration mismatch:")
    print("   → Verify STM32 baud rate in CubeMX matches test")
    print("   → Check USART2 pin assignment in CubeMX")
    print("   → Make sure UART is enabled on Pi (raspi-config)")
    print()
    
    print("Next steps:")
    print("  1. Add LED blink to STM32 code to verify it's running")
    print("  2. Run loopback test on Pi to verify UART hardware")
    print("  3. Check STM32 PA2 pin voltage with multimeter")
    print("  4. Verify all connections are secure")

PYEOF

