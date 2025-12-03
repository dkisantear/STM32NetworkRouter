#!/usr/bin/env python3
"""
Bidirectional UART Test - Verify Pi can send commands to STM32 and receive responses
This test verifies the Master STM32 can receive commands from the frontend
"""

import serial
import time
import sys

# Configuration
UART_DEVICE = "/dev/ttyAMA0"
UART_BAUDRATE = 38400
TIMEOUT = 2.0

def main():
    print("=" * 60)
    print("Bidirectional UART Test - Pi ↔ STM32")
    print("=" * 60)
    print(f"Device: {UART_DEVICE}")
    print(f"Baudrate: {UART_BAUDRATE}")
    print("=" * 60)
    print()
    
    try:
        # Open serial port
        print(f"📡 Opening {UART_DEVICE}...")
        ser = serial.Serial(
            port=UART_DEVICE,
            baudrate=UART_BAUDRATE,
            timeout=TIMEOUT,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE
        )
        print(f"✅ Serial port opened!")
        print()
        
        # Test 1: Send a test value (0-16) to STM32
        print("=" * 60)
        print("TEST 1: Sending command to STM32")
        print("=" * 60)
        
        test_value = 5
        print(f"📤 Sending value: {test_value}")
        command = f"{test_value}\n"
        ser.write(command.encode('utf-8'))
        print(f"✅ Sent: {repr(command)}")
        
        # Wait for response
        print("\n👂 Waiting for STM32 response (2 seconds)...")
        time.sleep(2)
        
        if ser.in_waiting > 0:
            response = ser.readline().decode("utf-8", errors="ignore").strip()
            print(f"📥 Received: {repr(response)}")
        else:
            print("⚠️  No response received (STM32 may not be configured to respond)")
        print()
        
        # Test 2: Send multiple test values
        print("=" * 60)
        print("TEST 2: Sending multiple values")
        print("=" * 60)
        
        test_values = [0, 5, 10, 15, 16]
        for value in test_values:
            print(f"\n📤 Sending value: {value}")
            command = f"{value}\n"
            ser.write(command.encode('utf-8'))
            print(f"   Sent: {repr(command)}")
            time.sleep(0.5)  # Small delay between commands
            
            # Check for any response
            if ser.in_waiting > 0:
                response = ser.readline().decode("utf-8", errors="ignore").strip()
                print(f"   📥 Received: {repr(response)}")
            else:
                print(f"   ⏳ No immediate response")
        
        print()
        print("=" * 60)
        print("TEST 3: Listen for incoming STM32 messages")
        print("=" * 60)
        print("👂 Listening for 5 seconds (STM32 may send heartbeat/data)...")
        print()
        
        start_time = time.time()
        message_count = 0
        while time.time() - start_time < 5:
            if ser.in_waiting > 0:
                try:
                    line = ser.readline().decode("utf-8", errors="ignore").strip()
                    if line:
                        message_count += 1
                        timestamp = time.strftime("%H:%M:%S")
                        print(f"[{timestamp}] 📥 #{message_count} Received: {repr(line)}")
                except Exception as e:
                    print(f"⚠️  Error reading: {e}")
            time.sleep(0.1)
        
        if message_count == 0:
            print("⚠️  No messages received from STM32")
            print("   (This is OK if STM32 isn't sending data yet)")
        else:
            print(f"\n✅ Received {message_count} message(s) from STM32")
        
        ser.close()
        print()
        print("=" * 60)
        print("✅ Test Complete!")
        print("=" * 60)
        print()
        print("Next Steps:")
        print("1. If STM32 received commands, verify LED/DIP switch output")
        print("2. If no response, check STM32 UART2 RX is configured correctly")
        print("3. Verify wiring: Pi GPIO14 (TX) → STM32 PA3 (RX)")
        print()
        
    except serial.SerialException as e:
        print(f"❌ Serial port error: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n\n🛑 Test interrupted by user")
        try:
            ser.close()
        except:
            pass
        sys.exit(0)

if __name__ == "__main__":
    main()

