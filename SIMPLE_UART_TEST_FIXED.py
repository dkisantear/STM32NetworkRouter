#!/usr/bin/env python3
"""
Simplified UART Test - More Verbose
Tests UART with multiple methods
"""

import serial
import time
import sys

UART_DEVICE = "/dev/ttyAMA0"
BAUDRATE = 38400

print("=" * 60)
print("Simple UART Test - Enhanced")
print("=" * 60)
print(f"Device: {UART_DEVICE}")
print(f"Baudrate: {BAUDRATE}")
print("=" * 60)
print()

# Test 1: Try to open port
print("1. Opening serial port...")
try:
    ser = serial.Serial(
        port=UART_DEVICE,
        baudrate=BAUDRATE,
        timeout=1.0,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE
    )
    print(f"   ✅ Port opened: {ser.name}")
    print(f"   Settings: {BAUDRATE} baud, 8N1")
except Exception as e:
    print(f"   ❌ FAILED to open port: {e}")
    print("   Troubleshooting:")
    print("     - Check if UART is enabled: sudo raspi-config")
    print("     - Check permissions: sudo usermod -a -G dialout $USER")
    sys.exit(1)

print()

# Test 2: Check for immediate data
print("2. Checking for data already in buffer...")
if ser.in_waiting > 0:
    data = ser.read(ser.in_waiting)
    print(f"   📥 Found {len(data)} bytes in buffer: {data}")
else:
    print("   ⚪ No data in buffer (normal)")
print()

# Test 3: Listen for 10 seconds with progress
print("3. Listening for messages (10 seconds)...")
print("   Press Ctrl+C to stop early")
print()

message_count = 0
start_time = time.time()
last_progress = start_time

try:
    while True:
        current_time = time.time()
        elapsed = current_time - start_time
        
        # Show progress every 2 seconds
        if current_time - last_progress >= 2.0:
            print(f"   ⏳ Still listening... ({int(elapsed)}s elapsed, {message_count} messages)")
            last_progress = current_time
        
        # Check for data
        if ser.in_waiting > 0:
            # Read all available data
            data = ser.read(ser.in_waiting)
            
            # Try to decode
            try:
                decoded = data.decode('utf-8', errors='ignore').strip()
                
                if decoded:
                    message_count += 1
                    timestamp = time.strftime("%H:%M:%S")
                    print(f"   [{timestamp}] #{message_count}: {repr(decoded)}")
                    
                    # Check for our expected message
                    if "STM32_ALIVE" in decoded or "DATA:" in decoded:
                        print(f"      ✅ Found expected message!")
                    last_progress = current_time
            except Exception as e:
                print(f"   ⚠️  Decode error: {e}, raw: {data.hex()}")
        
        # Stop after 10 seconds
        if elapsed >= 10.0:
            break
        
        time.sleep(0.1)

except KeyboardInterrupt:
    print("\n   🛑 Stopped by user")
    elapsed = time.time() - start_time

finally:
    ser.close()
    print()
    print("=" * 60)
    print(f"Test complete! ({int(elapsed)}s elapsed)")
    print(f"Messages received: {message_count}")
    print("=" * 60)
    print()
    
    if message_count == 0:
        print("❌ NO MESSAGES RECEIVED")
        print()
        print("Possible issues:")
        print("  1. STM32 not powered or code not running")
        print("  2. Wrong baud rate (STM32 vs Pi mismatch)")
        print("  3. Wiring issue (TX→RX, RX→TX, GND)")
        print("  4. UART not enabled on Pi")
        print("  5. Wrong UART device (/dev/ttyAMA0 vs /dev/serial0)")
        print()
        print("Next steps:")
        print("  - Check STM32 LEDs respond to DIP switches")
        print("  - Verify wiring: STM32 TX→Pi RX, STM32 RX→Pi TX")
        print("  - Check baud rate in STM32 code matches Pi (38400)")
    else:
        print(f"✅ SUCCESS! Received {message_count} message(s)")
        print("   Your STM32 is sending data!")

