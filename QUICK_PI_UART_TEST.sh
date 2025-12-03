#!/bin/bash
# Quick Pi UART diagnostic - run this first!

echo "=========================================="
echo "Quick Pi UART Diagnostic"
echo "=========================================="
echo ""

echo "1. Checking if UART is enabled..."
UART_STATUS=$(vcgencmd get_config enable_uart 2>/dev/null)
if [ -z "$UART_STATUS" ] || [ "$UART_STATUS" = "enable_uart=0" ]; then
    echo "   ❌ UART is DISABLED or not set"
    echo ""
    echo "   Fix: Add 'enable_uart=1' to /boot/config.txt and reboot"
    echo "   Run: sudo nano /boot/config.txt"
else
    echo "   ✅ $UART_STATUS"
fi

echo ""
echo "2. Checking UART devices..."
ls -l /dev/ttyAMA* /dev/serial0 /dev/ttyS* 2>/dev/null

echo ""
echo "3. Checking permissions..."
if [ -e "/dev/ttyAMA0" ]; then
    PERMS=$(stat -c "%a" /dev/ttyAMA0 2>/dev/null)
    echo "   /dev/ttyAMA0 permissions: $PERMS"
    if [ "$PERMS" != "666" ] && [ "$PERMS" != "660" ]; then
        echo "   ⚠️  Might need to add user to dialout group"
        echo "   Run: sudo usermod -a -G dialout \$USER"
    fi
fi

echo ""
echo "4. Testing UART devices for 3 seconds each..."
echo ""

for DEV in "/dev/ttyAMA0" "/dev/serial0" "/dev/ttyS0"; do
    if [ -e "$DEV" ]; then
        echo "Testing: $DEV"
        timeout 3 cat "$DEV" 2>&1 | head -5 &
        CAT_PID=$!
        sleep 3
        kill $CAT_PID 2>/dev/null
        echo "---"
        echo ""
    fi
done

echo "=========================================="
echo "If you saw any data above, note which device!"
echo "=========================================="

