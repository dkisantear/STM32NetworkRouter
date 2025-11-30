#!/usr/bin/env python3
"""
STM32 UART Reader - WORKING VERSION
Confirmed working with /dev/ttyAMA0
"""

import serial
import time
import sys

# Configuration - USE /dev/ttyAMA0 for Pi 5
UART_DEVICE = "/dev/ttyAMA0"  # Changed from /dev/serial0
BAUDRATE = 38400
TIMEOUT = 1.0

def main():
    print("=" * 60)
    print("STM32 UART Test - Raspberry Pi")
    print("=" * 60)
    print(f"Device: {UART_DEVICE}")
    print(f"Baudrate: {BAUDRATE}")
    print(f"Timeout: {TIMEOUT}s")
    print("=" * 60)
    print()
    
    try:
        # Open serial port
        print(f"📡 Opening {UART_DEVICE}...")
        ser = serial.Serial(
            port=UART_DEVICE,
            baudrate=BAUDRATE,
            timeout=TIMEOUT,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE
        )
        print(f"✅ Serial port opened successfully!")
        print()
        
        print("👂 Listening for STM32 messages...")
        print("   (Expected: 'STM32_ALIVE' every ~1 second)")
        print("   Press Ctrl+C to stop")
        print()
        
        message_count = 0
        last_message_time = None
        
        while True:
            try:
                # Read line from STM32
                line = ser.readline().decode("utf-8", errors="ignore").strip()
                
                if line:
                    message_count += 1
                    current_time = time.time()
                    timestamp = time.strftime("%H:%M:%S")
                    
                    # Calculate time since last message
                    if last_message_time:
                        time_diff = current_time - last_message_time
                        print(f"[{timestamp}] #{message_count} | {time_diff:.3f}s since last | Message: {repr(line)}")
                    else:
                        print(f"[{timestamp}] #{message_count} | Message: {repr(line)}")
                    
                    last_message_time = current_time
                    
                    # Verify it's the expected message
                    if line == "STM32_ALIVE":
                        print(f"   ✅ Correct format!")
                    else:
                        print(f"   ⚠️  Unexpected message format")
                    print()
                    
            except UnicodeDecodeError:
                # Handle garbage/partial data
                raw_data = ser.read(ser.in_waiting or 1)
                print(f"⚠️  Received garbage data: {raw_data.hex()}")
                print()
                
    except serial.SerialException as e:
        print(f"❌ Serial port error: {e}")
        print()
        print("Troubleshooting:")
        print("  1. Check if UART is enabled: sudo raspi-config → Interface Options → Serial Port")
        print("  2. Verify device exists: ls -l /dev/ttyAMA0")
        print("  3. Check permissions: sudo usermod -a -G dialout $USER (then log out/in)")
        sys.exit(1)
        
    except KeyboardInterrupt:
        print()
        print("=" * 60)
        print(f"🛑 Stopped after receiving {message_count} message(s)")
        print("=" * 60)
        
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)
        
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("📡 Serial port closed")

if __name__ == "__main__":
    main()

