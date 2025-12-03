#!/bin/bash
# Test all possible UART devices on Pi

echo "=========================================="
echo "Testing All UART Devices"
echo "=========================================="
echo ""

UART_DEVICES=("/dev/ttyAMA0" "/dev/serial0" "/dev/ttyS0")

for device in "${UART_DEVICES[@]}"; do
    if [ -e "$device" ]; then
        echo "Testing: $device"
        echo "Listening for 5 seconds..."
        
        timeout 5 cat "$device" 2>&1 | head -20 &
        CAT_PID=$!
        
        sleep 5
        kill $CAT_PID 2>/dev/null
        
        echo "---"
    else
        echo "$device: Not found"
    fi
    echo ""
done

echo "=========================================="
echo "Done!"
echo "=========================================="

