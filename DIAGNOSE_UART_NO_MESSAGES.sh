#!/bin/bash
# ========================================
# Diagnose Why Pi Isn't Receiving STM32 Messages
# ========================================
# Run this on your Pi to find the issue

echo "========================================"
echo "🔍 Diagnosing UART Connection Issue"
echo "========================================"
echo ""

# Step 1: Check if STM32 is powered on
echo "1. Check STM32 is powered:"
echo "   → Is the STM32 board powered on? (LEDs visible?)"
echo "   → Are DIP switches working? (LEDs change when you flip switches?)"
read -p "   STM32 is powered and LEDs work? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "   ❌ Power on STM32 first!"
    exit 1
fi
echo ""

# Step 2: Check UART device
echo "2. Checking UART device..."
if [ -e /dev/ttyAMA0 ]; then
    echo "   ✅ /dev/ttyAMA0 exists"
    ls -l /dev/ttyAMA0
else
    echo "   ❌ /dev/ttyAMA0 not found!"
    echo "   Try: sudo raspi-config → Interface Options → Serial Port"
    exit 1
fi
echo ""

# Step 3: Check permissions
echo "3. Checking permissions..."
if [ -r /dev/ttyAMA0 ] && [ -w /dev/ttyAMA0 ]; then
    echo "   ✅ Have read/write permissions"
else
    echo "   ⚠️  Permission issue - trying with sudo..."
    echo "   Run: sudo usermod -a -G dialout \$USER"
    echo "   Then log out and back in"
fi
echo ""

# Step 4: Check if another process is using UART
echo "4. Checking for other processes using UART..."
if lsof /dev/ttyAMA0 2>/dev/null | grep -v COMMAND; then
    echo "   ⚠️  Another process is using /dev/ttyAMA0!"
    echo "   Killing bridge processes..."
    pkill -f pi_stm32_bridge
    pkill -f pi_uart_test
    sleep 2
    echo "   ✅ Killed"
else
    echo "   ✅ No other processes using UART"
fi
echo ""

# Step 5: Test multiple baud rates
echo "5. Testing multiple baud rates..."
echo "   (STM32 might be set to wrong baud rate)"
echo ""

BAUDRATES=(115200 38400 9600 57600 19200)

for baud in "${BAUDRATES[@]}"; do
    echo "   Testing $baud baud (5 seconds)..."
    timeout 5 python3 << EOF 2>/dev/null | head -3
import serial
import time

try:
    ser = serial.Serial('/dev/ttyAMA0', $baud, timeout=1.0)
    start = time.time()
    while time.time() - start < 5:
        if ser.in_waiting > 0:
            data = ser.read(ser.in_waiting)
            print(f"   📥 Received at $baud: {data.hex()} / {data}")
            break
        time.sleep(0.1)
    ser.close()
except Exception as e:
    pass
EOF
    
    if [ $? -eq 0 ]; then
        echo "   → No data at $baud baud"
    fi
done

echo ""
echo "========================================"
echo "6. Manual Test - Try Each Baud Rate"
echo "========================================"
echo ""
echo "Run this command for EACH baud rate:"
echo ""
echo "   python3 -c \""
echo "   import serial, time"
echo "   ser = serial.Serial('/dev/ttyAMA0', 38400, timeout=2)"
echo "   print('Listening for 5 seconds...')"
echo "   start = time.time()"
echo "   while time.time() - start < 5:"
echo "       if ser.in_waiting > 0:"
echo "           print('RECEIVED:', ser.read(ser.in_waiting))"
echo "       time.sleep(0.1)"
echo "   ser.close()"
echo "   \""
echo ""
echo "Replace 38400 with: 115200, 38400, 9600, 57600, 19200"
echo ""

# Step 7: Check STM32 code
echo "========================================"
echo "7. Verify STM32 Code"
echo "========================================"
echo ""
echo "In your STM32 main.c, check:"
echo ""
echo "   ✅ MX_USART2_UART_Init() is called in main()?"
echo "   ✅ huart2.Init.BaudRate = 38400? (NOT 115200!)"
echo "   ✅ UART send code is in the main loop?"
echo "   ✅ STM32 is flashed with latest code?"
echo ""
echo "If baud rate is 115200, change it to 38400 and re-flash!"
echo ""

# Step 8: Check wiring
echo "========================================"
echo "8. Verify Wiring"
echo "========================================"
echo ""
echo "Correct wiring (crossed TX/RX):"
echo ""
echo "   STM32 PA2 (TX) → Pi Pin 10 (RXD/GPIO15)"
echo "   STM32 PA3 (RX) → Pi Pin 8  (TXD/GPIO14)"
echo "   GND            → GND"
echo ""
echo "⚠️  TX must connect to RX (crossed!)"
echo ""

