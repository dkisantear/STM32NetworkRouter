#!/bin/bash
# Quick script to check what device ID the bridge script is using

echo "Checking bridge script device ID..."
echo ""

# Check the device ID in the script
if grep -q "DEVICE_ID = \"stm32-master\"" pi_stm32_bridge.py; then
    echo "✅ Device ID is correct: stm32-master"
elif grep -q "DEVICE_ID = \"stm32-main\"" pi_stm32_bridge.py; then
    echo "❌ Device ID is WRONG: stm32-main (should be stm32-master)"
else
    echo "⚠️  Could not find DEVICE_ID in script"
fi

echo ""
echo "Checking recent logs for device ID..."
grep "Device ID:" ~/stm32-bridge.log | tail -1

echo ""
echo "Frontend expects: stm32-master"
echo "Check if they match!"

