#!/bin/bash
# Complete UART Test Script for Pi
# Run this to set up and test UART communication

echo "========================================"
echo "STM32 UART Test Setup"
echo "========================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo "⚠️  Don't run as root/sudo"
   exit 1
fi

# Step 1: Check if UART is enabled
echo "1. Checking UART configuration..."
if [ -e /dev/serial0 ]; then
    echo "   ✅ /dev/serial0 exists"
    ls -l /dev/serial0
else
    echo "   ❌ /dev/serial0 not found"
    echo "   → Run: sudo raspi-config"
    echo "   → Interface Options → Serial Port → Enable"
    echo "   → Then reboot"
    exit 1
fi
echo ""

# Step 2: Check permissions
echo "2. Checking permissions..."
if groups | grep -q dialout; then
    echo "   ✅ User is in dialout group"
else
    echo "   ⚠️  Adding user to dialout group..."
    sudo usermod -a -G dialout $USER
    echo "   → Please log out and back in, or reboot"
    echo "   → Then run this script again"
    exit 1
fi
echo ""

# Step 3: Install pyserial
echo "3. Installing pyserial..."
python3 -c "import serial" 2>/dev/null || {
    echo "   Installing pyserial..."
    pip3 install pyserial --break-system-packages || sudo apt-get install -y python3-serial
}
python3 -c "import serial" && echo "   ✅ pyserial installed" || {
    echo "   ❌ Failed to install pyserial"
    exit 1
}
echo ""

# Step 4: Check if test script exists
echo "4. Checking test script..."
if [ -f "pi_uart_test.py" ]; then
    echo "   ✅ pi_uart_test.py found"
    chmod +x pi_uart_test.py
else
    echo "   ❌ pi_uart_test.py not found"
    echo "   → Make sure the script is in current directory"
    exit 1
fi
echo ""

# Step 5: Ready to test
echo "========================================"
echo "✅ Setup Complete!"
echo "========================================"
echo ""
echo "📋 Hardware Checklist:"
echo "   ☐ STM32 PA2 (TX) → Pi Pin 10 (RXD)"
echo "   ☐ STM32 PA3 (RX) → Pi Pin 8  (TXD)"
echo "   ☐ STM32 GND      → Pi GND"
echo ""
echo "🚀 Ready to test!"
echo "   Run: python3 pi_uart_test.py"
echo ""
echo "Expected: You should see 'STM32_ALIVE' messages every ~1 second"
echo ""

