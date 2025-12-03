#!/usr/bin/env python3
"""
UART Diagnostic Script for Raspberry Pi
Tests which UART device is available and working with GPIO14/15
"""

import serial
import time
import os
import sys

def test_device(device_path, baudrate=38400):
    """Test if a UART device can be opened and read from"""
    print(f"\n{'='*60}")
    print(f"Testing: {device_path}")
    print(f"{'='*60}")
    
    # Check if device exists
    if not os.path.exists(device_path):
        print(f"❌ Device does not exist: {device_path}")
        return False
    
    # Check if it's a symlink
    if os.path.islink(device_path):
        real_path = os.readlink(device_path)
        print(f"📎 Symlink points to: {real_path}")
    
    # Check permissions
    if not os.access(device_path, os.R_OK | os.W_OK):
        print(f"⚠️  Permission issue - may need: sudo usermod -a -G dialout $USER")
    
    try:
        print(f"📡 Opening {device_path} at {baudrate} baud...")
        ser = serial.Serial(
            port=device_path,
            baudrate=baudrate,
            timeout=2.0,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE
        )
        print(f"✅ Successfully opened {device_path}!")
        print(f"   Port settings: {ser.get_settings()}")
        
        # Try to read for 3 seconds
        print(f"\n👂 Listening for data (3 seconds)...")
        start_time = time.time()
        received_data = []
        
        while time.time() - start_time < 3:
            if ser.in_waiting > 0:
                try:
                    line = ser.readline().decode("utf-8", errors="ignore").strip()
                    if line:
                        received_data.append(line)
                        print(f"   📥 Received: {repr(line)}")
                except Exception as e:
                    print(f"   ⚠️  Error reading: {e}")
            time.sleep(0.1)
        
        ser.close()
        
        if received_data:
            print(f"\n✅ Device is working! Received {len(received_data)} message(s)")
            return True
        else:
            print(f"\n⚠️  Device opened but no data received (Master board may not be sending)")
            return True  # Still consider it working if we can open it
        
    except serial.SerialException as e:
        print(f"❌ Failed to open: {e}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

def main():
    print("="*60)
    print("Raspberry Pi UART Diagnostic Tool")
    print("GPIO14 (TX) / GPIO15 (RX) UART Detection")
    print("="*60)
    
    devices_to_test = [
        "/dev/serial0",  # Symlink (usually points to correct UART)
        "/dev/ttyAMA0",  # Hardware UART (Pi 3/4/5)
        "/dev/ttyS0",    # Mini UART (some Pi models)
    ]
    
    print("\n📋 Checking available UART devices...")
    working_devices = []
    
    for device in devices_to_test:
        if test_device(device):
            working_devices.append(device)
    
    print(f"\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    
    if working_devices:
        print(f"\n✅ Working devices found:")
        for dev in working_devices:
            print(f"   - {dev}")
        print(f"\n💡 Recommended device: {working_devices[0]}")
        print(f"   Update pi_stm32_bridge.py with: UART_DEVICE = \"{working_devices[0]}\"")
    else:
        print(f"\n❌ No working UART devices found!")
        print(f"\n💡 Troubleshooting steps:")
        print(f"   1. Enable UART: sudo raspi-config → Interface Options → Serial Port")
        print(f"   2. Check if device exists: ls -l /dev/serial* /dev/ttyAMA* /dev/ttyS*")
        print(f"   3. Add user to dialout group: sudo usermod -a -G dialout $USER")
        print(f"   4. Log out and log back in after step 3")
        print(f"   5. Verify wiring: GPIO14 (TX) → STM32 RX, GPIO15 (RX) → STM32 TX, GND → GND")
    
    print(f"\n{'='*60}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n🛑 Interrupted by user")
        sys.exit(0)

