#!/usr/bin/env python3
"""
Test ALL possible UART devices on Pi
Helps find which one STM32 is actually connected to
"""

import serial
import time
import sys

UART_DEVICES = ["/dev/ttyAMA0", "/dev/serial0", "/dev/ttyS0", "/dev/ttyUSB0"]
UART_BAUDRATE = 38400

print("=" * 60)
print("Testing ALL UART Devices on Pi")
print("=" * 60)
print(f"Baudrate: {UART_BAUDRATE}")
print("=" * 60)
print()

found_device = None

for device in UART_DEVICES:
    print(f"Testing: {device}")
    
    try:
        ser = serial.Serial(
            port=device,
            baudrate=UART_BAUDRATE,
            timeout=2.0,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE
        )
        
        print(f"  ✅ Device opened successfully!")
        print(f"  👂 Listening for 3 seconds...")
        
        start_time = time.time()
        message_count = 0
        
        while time.time() - start_time < 3:
            if ser.in_waiting > 0:
                try:
                    line = ser.readline().decode("utf-8", errors="ignore").strip()
                    if line:
                        message_count += 1
                        timestamp = time.strftime("%H:%M:%S")
                        print(f"  [{timestamp}] 📥 Message #{message_count}: {repr(line)}")
                except:
                    raw = ser.read(ser.in_waiting)
                    message_count += 1
                    print(f"  📥 Raw data: {raw.hex()[:20]}...")
            
            time.sleep(0.1)
        
        ser.close()
        
        if message_count > 0:
            print(f"  ✅ FOUND! Received {message_count} message(s) on {device}")
            found_device = device
            print()
            print("=" * 60)
            print(f"🎉 WORKING DEVICE: {device}")
            print("=" * 60)
            break
        else:
            print(f"  ⚠️  No messages received")
        
        print()
        
    except serial.SerialException as e:
        print(f"  ❌ Error: {e}")
        print()
    except FileNotFoundError:
        print(f"  ❌ Device not found")
        print()
    except Exception as e:
        print(f"  ❌ Error: {e}")
        print()

if found_device:
    print()
    print("=" * 60)
    print(f"✅ SUCCESS! Use this device in your scripts:")
    print(f"   UART_DEVICE = \"{found_device}\"")
    print("=" * 60)
else:
    print()
    print("=" * 60)
    print("❌ NO DEVICES RECEIVED DATA")
    print("=" * 60)
    print()
    print("Possible issues:")
    print("1. UART not enabled in /boot/config.txt (add enable_uart=1)")
    print("2. Wrong wiring")
    print("3. STM32 not sending (check with oscilloscope/multimeter)")
    print("4. Need to reboot Pi after enabling UART")

