# Fix UART "Stuck on Listening" Issue

## 🔍 Problem
- UART test script gets stuck on "Listening..." (no messages received)
- Azure shows STM32 status as "offline"
- STM32 should be sending "STM32_ALIVE" every 1 second

## 🧪 Diagnostic Steps

### Step 1: Verify STM32 is Sending

**Check STM32 Hardware:**
1. Is STM32 powered on?
2. Is the code flashed correctly?
3. Are LEDs blinking? (if you have debug LEDs)

**Verify STM32 Code:**
- Check `main.c` - does it have the UART heartbeat code?
- Is it configured to send on USART2?
- Is baud rate set to 38400?

### Step 2: Verify UART Wiring

**STM32 → Pi 5 Wiring:**
```
STM32 USART2 TX (PA2)  →  Pi GPIO14 (TXD)  [Crossed!]
STM32 USART2 RX (PA3)  →  Pi GPIO15 (RXD)  [Crossed!]
STM32 GND              →  Pi GND           [Shared]
Both use 3.3V
```

**Common Issues:**
- ❌ TX→TX, RX→RX (should be TX→RX, RX→TX)
- ❌ No shared GND connection
- ❌ Wrong voltage levels (need 3.3V, not 5V)

### Step 3: Check Pi UART Configuration

**On Raspberry Pi:**
```bash
# Check if UART is enabled
sudo raspi-config
# Navigate to: Interface Options → Serial Port
# Should be: Serial Port → Enable (for hardware serial)

# Check if UART device exists
ls -l /dev/ttyAMA0
ls -l /dev/serial0

# Check if user is in dialout group
groups | grep dialout

# If not, add user:
sudo usermod -a -G dialout $USER
# Then logout and login again
```

### Step 4: Test UART Connection Directly

**Create a simple test script:**
```bash
# On Pi, create test_uart_simple.py
cat > test_uart_simple.py << 'EOF'
import serial
import time

try:
    ser = serial.Serial('/dev/ttyAMA0', 38400, timeout=1)
    print(f"✅ Port opened: {ser.name}")
    print("Reading for 5 seconds...")
    
    start = time.time()
    while time.time() - start < 5:
        if ser.in_waiting > 0:
            data = ser.read(ser.in_waiting)
            print(f"📥 Received: {data}")
        time.sleep(0.1)
    
    ser.close()
    print("✅ Test complete")
except Exception as e:
    print(f"❌ Error: {e}")
EOF

python3 test_uart_simple.py
```

### Step 5: Check for Other Processes Using UART

```bash
# Check if bridge script is holding the port
ps aux | grep pi_stm32_bridge
ps aux | grep pi_uart_test

# Kill any processes using UART
sudo pkill -f pi_stm32_bridge
sudo pkill -f pi_uart_test

# Check if port is in use
sudo lsof /dev/ttyAMA0
```

### Step 6: Verify Baud Rate Match

**STM32:** Should be 38400 baud  
**Pi Script:** Should be 38400 baud

**Test with different baud rates:**
```bash
# Try common baud rates
python3 << 'EOF'
import serial
import time

baud_rates = [9600, 19200, 38400, 57600, 115200]

for baud in baud_rates:
    try:
        ser = serial.Serial('/dev/ttyAMA0', baud, timeout=1)
        print(f"Testing {baud} baud...")
        
        start = time.time()
        received = False
        while time.time() - start < 2:
            if ser.in_waiting > 0:
                data = ser.read(ser.in_waiting)
                print(f"  ✅ Received at {baud}: {data}")
                received = True
                break
            time.sleep(0.1)
        
        ser.close()
        if received:
            print(f"🎯 FOUND WORKING BAUD RATE: {baud}")
            break
    except Exception as e:
        print(f"  ❌ {baud} failed: {e}")
EOF
```

## 🔧 Quick Fixes

### Fix 1: Reset UART Port
```bash
# Close all UART connections
sudo pkill -f python3

# Reset UART (may require reboot)
sudo systemctl stop serial-getty@ttyAMA0.service
sudo systemctl disable serial-getty@ttyAMA0.service
```

### Fix 2: Check STM32 TX Pin Voltage
```bash
# On Pi, check if TX line is active (should see voltage changes)
# Use multimeter or oscilloscope on PA2 (STM32 TX)
# Should see voltage transitions when STM32 sends data
```

### Fix 3: Loopback Test (Verify Pi UART Works)
```bash
# Connect Pi TX to Pi RX (loopback)
# GPIO14 (TXD) → GPIO15 (RXD) on Pi

python3 << 'EOF'
import serial
import time

ser = serial.Serial('/dev/ttyAMA0', 38400, timeout=1)
print("Loopback test - sending 'TEST'...")
ser.write(b'TEST\n')
time.sleep(0.1)

if ser.in_waiting > 0:
    data = ser.read(ser.in_waiting)
    print(f"✅ Received: {data}")
else:
    print("❌ No data received")

ser.close()
EOF
```

## 🎯 Most Likely Causes

1. **STM32 not sending** (code not running/flashed)
2. **Wrong wiring** (TX/RX not crossed, no GND)
3. **UART disabled on Pi** (need to enable in raspi-config)
4. **Wrong baud rate** (mismatch between STM32 and Pi)
5. **Port locked** (another process using UART)

## ✅ Verification Checklist

- [ ] STM32 is powered and running
- [ ] STM32 code is flashed and includes UART heartbeat
- [ ] UART wiring: TX→RX, RX→TX, GND shared
- [ ] Pi UART is enabled (raspi-config)
- [ ] User is in dialout group
- [ ] No other processes using /dev/ttyAMA0
- [ ] Baud rates match (38400 on both sides)
- [ ] Test script can open /dev/ttyAMA0 without errors

## 📞 Next Steps

1. Run diagnostic script on Pi
2. Verify STM32 is actually sending (use oscilloscope if available)
3. Test with loopback to verify Pi UART hardware works
4. Check STM32 code configuration matches Pi script settings

