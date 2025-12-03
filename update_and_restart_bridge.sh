#!/bin/bash
# Script to update and restart the STM32 bridge on Raspberry Pi

echo "=========================================="
echo "STM32 Bridge Update & Restart Script"
echo "=========================================="
echo ""

# Stop existing bridge if running
echo "1. Stopping existing bridge script..."
pkill -f pi_stm32_bridge.py
sleep 2
echo "   ✅ Stopped"
echo ""

# Check if bridge script exists
if [ ! -f "pi_stm32_bridge.py" ]; then
    echo "❌ Error: pi_stm32_bridge.py not found in current directory"
    echo "   Please make sure you're in the directory with the bridge script"
    exit 1
fi

# Make sure script is executable
chmod +x pi_stm32_bridge.py

# Start bridge script in background
echo "2. Starting bridge script..."
nohup python3 pi_stm32_bridge.py > /dev/null 2>&1 &
sleep 2
echo "   ✅ Started"
echo ""

# Check if it's running
if pgrep -f pi_stm32_bridge.py > /dev/null; then
    echo "✅ Bridge script is running!"
    echo ""
    echo "📋 Process info:"
    ps aux | grep pi_stm32_bridge.py | grep -v grep
    echo ""
    echo "📄 View logs with: tail -f ~/stm32-bridge.log"
    echo ""
    echo "✅ Done! Master STM32 should show as 'Online' within 30 seconds"
else
    echo "❌ Error: Bridge script failed to start"
    echo "   Check logs: cat ~/stm32-bridge.log"
    exit 1
fi

