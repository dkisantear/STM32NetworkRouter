#!/bin/bash
# Check if bridge script is running and showing status messages

echo "=========================================="
echo "Bridge Script Status Check"
echo "=========================================="
echo ""

# Check if bridge is running
if pgrep -f pi_stm32_bridge.py > /dev/null; then
    echo "✅ Bridge script IS running"
    echo ""
    echo "Process info:"
    ps aux | grep pi_stm32_bridge.py | grep -v grep
    echo ""
else
    echo "❌ Bridge script is NOT running"
    echo ""
    echo "Start it with: python3 pi_stm32_bridge.py"
    echo ""
fi

echo "=========================================="
echo "Recent Bridge Logs (last 20 lines)"
echo "=========================================="
if [ -f ~/stm32-bridge.log ]; then
    tail -20 ~/stm32-bridge.log
else
    echo "⚠️  Log file not found: ~/stm32-bridge.log"
    echo "   Bridge script may not have started yet"
fi

echo ""
echo "=========================================="
echo "What to look for:"
echo "=========================================="
echo "✅ Should see: 'Device ID: stm32-master'"
echo "✅ Should see: '✅ Initial status sent!'"
echo "✅ Should see: '💓 Periodic heartbeat' every 30 seconds"
echo "✅ Should see: '✅ Status sent to Azure: online'"
echo ""

