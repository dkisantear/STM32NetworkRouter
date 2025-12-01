#!/usr/bin/env python3
"""
Test UART at Multiple Baud Rates
Helps find if STM32 is using a different baud rate than expected
"""

import serial
import time
import sys

UART_DEVICE = "/dev/ttyAMA0"
BAUDRATES = [115200, 38400, 9600, 57600, 19200, 230400, 4800]

def test_baud_rate(baud):
    """Test a single baud rate for 5 seconds"""
    try:
        print(f"\n{'='*60}")
        print(f"Testing {baud} baud...")
        print(f"{'='*60}")
        
        ser = serial.Serial(
            port=UART_DEVICE,
            baudrate=baud,
            timeout=1.0,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE
        )
        
        print(f"✅ Port opened")
        print("👂 Listening for 5 seconds...")
        print("   (Watch for any data - even garbage counts!)")
        print()
        
        received_any = False
        start_time = time.time()
        
        while time.time() - start_time < 5:
            try:
                # Try readline first (waits for complete line)
                if ser.in_waiting > 0:
                    # Got data! Try to decode
                    try:
                        line = ser.readline().decode("utf-8", errors="ignore").strip()
                        if line:
                            received_any = True
                            timestamp = time.strftime("%H:%M:%S")
                            print(f"[{timestamp}] ✅ RECEIVED TEXT: {repr(line)}")
                    except:
                        # Try raw read if decode fails
                        raw = ser.read(ser.in_waiting)
                        received_any = True
                        timestamp = time.strftime("%H:%M:%S")
                        print(f"[{timestamp}] ✅ RECEIVED RAW: {raw.hex()} / {raw}")
                else:
                    time.sleep(0.1)
                    
            except Exception as e:
                print(f"⚠️  Error reading: {e}")
                break
        
        ser.close()
        
        if received_any:
            print(f"\n✅ SUCCESS! Received data at {baud} baud")
            print(f"   → Your STM32 is using {baud} baud rate!")
            return True
        else:
            print(f"\n❌ No data received at {baud} baud")
            return False
            
    except serial.SerialException as e:
        print(f"❌ Error: {e}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

def main():
    print("="*60)
    print("UART Baud Rate Test")
    print("="*60)
    print()
    print("This script will test multiple baud rates")
    print("to find which one your STM32 is using.")
    print()
    print("Make sure:")
    print("  - STM32 is powered on")
    print("  - UART wires are connected")
    print("  - No other process is using /dev/ttyAMA0")
    print()
    input("Press Enter to start...")
    print()
    
    for baud in BAUDRATES:
        if test_baud_rate(baud):
            print()
            print("="*60)
            print(f"🎉 FOUND IT! STM32 is using {baud} baud")
            print("="*60)
            print()
            print("Next steps:")
            print(f"  1. If baud is NOT 38400, update STM32 code to use 38400")
            print("  2. OR update Pi scripts to use the correct baud rate")
            print()
            sys.exit(0)
    
    print()
    print("="*60)
    print("❌ No data received at any baud rate!")
    print("="*60)
    print()
    print("Possible issues:")
    print("  1. STM32 not powered on")
    print("  2. Wiring incorrect (TX→RX, RX→TX, GND→GND)")
    print("  3. STM32 UART not initialized (check MX_USART2_UART_Init())")
    print("  4. STM32 code not running (re-flash STM32)")
    print("  5. Wrong UART pins on STM32 (check CubeMX)")
    print()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n🛑 Stopped by user")
        sys.exit(0)

