#!/usr/bin/env python3
"""
Quick check to see if STM32 is sending any UART data
This will listen for ANY data coming from STM32
"""

import serial
import time
import sys

UART_DEVICE = "/dev/ttyAMA0"
UART_BAUDRATE = 38400

print("=" * 60)
print("STM32 UART Reception Test")
print("=" * 60)
print(f"Device: {UART_DEVICE}")
print(f"Baudrate: {UART_BAUDRATE}")
print("=" * 60)
print()
print("Listening for ANY data from STM32...")
print("(Will show raw data, heartbeat messages, numbers, anything)")
print("Press Ctrl+C to stop")
print()

try:
    ser = serial.Serial(
        port=UART_DEVICE,
        baudrate=UART_BAUDRATE,
        timeout=2.0,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE
    )
    print("✅ Serial port opened!")
    print()
    
    message_count = 0
    start_time = time.time()
    
    print("Listening for 10 seconds...")
    print()
    
    while time.time() - start_time < 10:
        # Check for any data available
        if ser.in_waiting > 0:
            try:
                # Try to read as text
                line = ser.readline().decode("utf-8", errors="ignore").strip()
                if line:
                    message_count += 1
                    timestamp = time.strftime("%H:%M:%S")
                    print(f"[{timestamp}] Message #{message_count}: {repr(line)}")
            except:
                # If text decode fails, show raw bytes
                raw = ser.read(ser.in_waiting)
                message_count += 1
                timestamp = time.strftime("%H:%M:%S")
                print(f"[{timestamp}] Message #{message_count} (raw bytes): {raw.hex()}")
        time.sleep(0.1)
    
    print()
    print("=" * 60)
    
    if message_count == 0:
        print("❌ NO MESSAGES RECEIVED from STM32")
        print()
        print("Possible issues:")
        print("1. STM32 is not sending data via UART2")
        print("2. Wiring issue: Check Pi GPIO14 (TX) → STM32 RX, Pi GPIO15 (RX) → STM32 TX")
        print("3. STM32 UART2 not enabled or configured correctly")
        print("4. Baud rate mismatch (STM32 must be 38400)")
        print("5. STM32 not powered on")
    else:
        print(f"✅ RECEIVED {message_count} message(s) from STM32!")
        print("UART communication is working!")
    
    ser.close()
    
except serial.SerialException as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
except KeyboardInterrupt:
    print("\n\n🛑 Interrupted")
    try:
        ser.close()
    except:
        pass
    sys.exit(0)

