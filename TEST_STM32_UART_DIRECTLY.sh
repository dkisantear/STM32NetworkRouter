#!/bin/bash
# ========================================
# Test STM32 UART Directly - Isolated Tests
# Copy/paste this ENTIRE block into Pi terminal
# ========================================

echo "========================================"
echo "🔍 ISOLATED UART TESTS"
echo "========================================"
echo ""

# Test 1: Verify Pi can READ anything at all
echo "TEST 1: Can Pi UART read ANY data?"
echo "----------------------------------------"
python3 << 'PYEOF'
import serial
import time

print("Opening /dev/serial0 and listening for ANY data...")
print("(This will catch ANYTHING, even garbage)")

try:
    ser = serial.Serial("/dev/serial0", 38400, timeout=1)
    print("✅ Port opened")
    
    print("\nListening for 15 seconds...")
    print("(Wiggle wires, try different connections, etc.)")
    
    any_data = False
    start = time.time()
    
    while time.time() - start < 15:
        if ser.in_waiting:
            raw = ser.read(ser.in_waiting)
            any_data = True
            print(f"\n📥 RAW BYTES RECEIVED: {raw.hex()}")
            print(f"   ASCII attempt: {repr(raw)}")
            
            # Try to decode
            try:
                decoded = raw.decode("utf-8")
                print(f"   Decoded: {repr(decoded)}")
            except:
                print(f"   (Not valid UTF-8 - might be baud rate mismatch)")
        
        time.sleep(0.05)
    
    ser.close()
    
    if not any_data:
        print("\n❌ NO DATA RECEIVED AT ALL")
        print("   → Pi UART is not receiving anything")
        print("   → Possible issues:")
        print("     1. STM32 not actually sending")
        print("     2. Wiring is wrong (despite appearing correct)")
        print("     3. Wrong UART device")
        print("     4. STM32 USART2 not working")
    else:
        print("\n✅ Pi UART IS receiving data!")
        print("   → Hardware path works, just need to decode correctly")
        
except Exception as e:
    print(f"❌ Error: {e}")

PYEOF

echo ""
echo "========================================"
echo "TEST 2: Test Pi UART Hardware (Loopback)"
echo "========================================"
echo ""
echo "⚠️  DISCONNECT STM32 wires"
echo "⚠️  TEMPORARILY connect: Pi Pin 8 (TXD) → Pi Pin 10 (RXD)"
echo ""
read -p "Press ENTER when loopback wires are connected..."

python3 << 'PYEOF'
import serial
import time

try:
    ser = serial.Serial("/dev/serial0", 38400, timeout=1)
    print("✅ Port opened")
    
    print("Sending test message...")
    ser.write(b"LOOPBACK_TEST_12345\n")
    time.sleep(0.2)
    
    if ser.in_waiting:
        received = ser.read(ser.in_waiting)
        print(f"📥 Received: {received}")
        
        if b"LOOPBACK" in received:
            print("✅ LOOPBACK WORKS - Pi UART hardware is functional!")
        else:
            print("⚠️  Received something, but not the expected message")
    else:
        print("❌ No loopback - Pi UART hardware issue")
    
    ser.close()
except Exception as e:
    print(f"❌ Error: {e}")

PYEOF

echo ""
read -p "Press ENTER after removing loopback and reconnecting STM32..."
echo ""

# Test 3: Try sending FROM Pi TO STM32
echo "========================================"
echo "TEST 3: Send FROM Pi TO STM32"
echo "========================================"
echo ""
echo "This tests if wiring works in reverse direction..."
echo ""

python3 << 'PYEOF'
import serial
import time

try:
    ser = serial.Serial("/dev/serial0", 38400, timeout=1)
    print("✅ Port opened")
    
    print("📤 Sending 5 test messages FROM Pi TO STM32...")
    print("   (If STM32 was listening, it would receive these)")
    
    for i in range(5):
        msg = f"PI_TEST_MESSAGE_{i}\n"
        ser.write(msg.encode())
        print(f"   Sent: {msg.strip()}")
        time.sleep(0.5)
    
    ser.close()
    print("\n✅ Sent successfully")
    print("   (If STM32 was programmed to read UART, you'd see it respond)")
    
except Exception as e:
    print(f"❌ Error sending: {e}")

PYEOF

echo ""
echo "========================================"
echo "TEST 4: Try Different UART Device"
echo "========================================"
echo ""

python3 << 'PYEOF'
import serial
import time

print("Trying /dev/ttyAMA0 instead of /dev/serial0...")

try:
    ser = serial.Serial("/dev/ttyAMA0", 38400, timeout=1)
    print("✅ /dev/ttyAMA0 opened")
    
    print("👂 Listening for 10 seconds...")
    
    received_any = False
    start = time.time()
    
    while time.time() - start < 10:
        if ser.in_waiting:
            raw = ser.read(ser.in_waiting)
            received_any = True
            print(f"📥 RAW: {raw.hex()} | ASCII: {repr(raw)}")
            
            try:
                decoded = raw.decode("utf-8")
                print(f"   Decoded: {repr(decoded)}")
            except:
                pass
        
        time.sleep(0.1)
    
    ser.close()
    
    if not received_any:
        print("❌ No data on /dev/ttyAMA0 either")
    else:
        print("✅ FOUND DATA ON /dev/ttyAMA0!")
        
except Exception as e:
    print(f"❌ Error with /dev/ttyAMA0: {e}")

PYEOF

