#!/bin/bash
# Simple UART test - tries both devices automatically
# Copy/paste this into Pi terminal

echo "Testing UART devices..."

python3 << 'PYEOF'
import serial
import time
import sys

# Try both common devices
devices = ["/dev/serial0", "/dev/ttyAMA0"]
baudrate = 38400

for device in devices:
    print(f"\n{'='*50}")
    print(f"Testing {device} at {baudrate} baud...")
    print(f"{'='*50}\n")
    
    try:
        ser = serial.Serial(device, baudrate, timeout=1)
        print(f"✅ Opened {device} successfully!")
        print("👂 Listening for 10 seconds...")
        print("   (Make sure STM32 is powered on and running)\n")
        
        received = 0
        start_time = time.time()
        
        while time.time() - start_time < 10:
            if ser.in_waiting:
                try:
                    line = ser.readline().decode("utf-8", errors="ignore").strip()
                    if line:
                        received += 1
                        elapsed = time.time() - start_time
                        print(f"[+{elapsed:.1f}s] #{received}: {repr(line)}")
                        if line == "STM32_ALIVE":
                            print("   ✅ CORRECT! UART is working!")
                except Exception as e:
                    print(f"   ⚠️  Error decoding: {e}")
            time.sleep(0.1)
        
        ser.close()
        
        if received > 0:
            print(f"\n✅ SUCCESS! Received {received} message(s) on {device}")
            print(f"✅ USE THIS DEVICE: {device}")
            sys.exit(0)
        else:
            print(f"\n⚠️  No messages received on {device}")
            
    except FileNotFoundError:
        print(f"❌ Device {device} not found")
    except PermissionError:
        print(f"❌ Permission denied on {device}")
        print("   Run: sudo usermod -a -G dialout $USER")
    except Exception as e:
        print(f"❌ Error: {e}")

print("\n" + "="*50)
print("❌ No UART communication detected")
print("="*50)
print("\nTroubleshooting:")
print("  1. Check STM32 is powered on")
print("  2. Verify STM32 LEDs work (confirms code is running)")
print("  3. Check wiring: STM32 TX → Pi RX (Pin 10)")
print("  4. Try swapping TX/RX wires")
print("  5. Verify baudrate matches (38400)")
print("  6. Check STM32 USART2 pin assignment in CubeMX")
PYEOF

