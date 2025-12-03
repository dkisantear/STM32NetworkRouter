#!/bin/bash
# Direct UART test - bypass Python serial library

echo "=========================================="
echo "Direct Pi UART Test"
echo "=========================================="
echo ""

# Test different UART devices
DEVICES=("/dev/ttyAMA0" "/dev/serial0" "/dev/ttyS0")

for DEV in "${DEVICES[@]}"; do
    if [ -e "$DEV" ]; then
        echo "Testing: $DEV"
        echo "Setting baud rate to 38400..."
        
        # Set baud rate using stty
        sudo stty -F "$DEV" 38400 cs8 -cstopb -parenb raw -echo
        
        echo "Listening for 5 seconds..."
        echo "---"
        
        # Read directly using cat
        timeout 5 sudo cat "$DEV" 2>&1 | head -20
        
        echo ""
        echo "---"
        echo ""
    else
        echo "$DEV: Not found"
        echo ""
    fi
done

echo "=========================================="
echo "If you saw any data above, that UART device works!"
echo "=========================================="

