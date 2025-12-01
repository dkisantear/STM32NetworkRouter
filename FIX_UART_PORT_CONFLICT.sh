#!/bin/bash
# ========================================
# Fix UART Port Conflict
# Stop all processes using UART, then start bridge cleanly
# ========================================

echo "========================================"
echo "🔧 Fixing UART Port Conflict"
echo "========================================"
echo ""

# Step 1: Kill ALL processes using UART
echo "1. Stopping all processes using UART..."
pkill -f pi_stm32_bridge.py
pkill -f pi_uart_test.py
pkill -f python3.*uart
sleep 2
echo "✅ All UART processes stopped"
echo ""

# Step 2: Check what's using the port
echo "2. Checking what's using /dev/ttyAMA0..."
if lsof /dev/ttyAMA0 2>/dev/null; then
    echo "   ⚠️  Something is still using the port"
    echo "   Killing it..."
    sudo fuser -k /dev/ttyAMA0 2>/dev/null || true
    sleep 1
else
    echo "   ✅ Port is free"
fi
echo ""

# Step 3: Verify port is accessible
echo "3. Testing port access..."
python3 << 'TEST_PORT'
import serial
try:
    ser = serial.Serial('/dev/ttyAMA0', 38400, timeout=1)
    print("   ✅ Port can be opened")
    ser.close()
except Exception as e:
    print(f"   ❌ Port error: {e}")
TEST_PORT
echo ""

# Step 4: Start bridge script cleanly
echo "4. Starting bridge script..."
cd ~
if [ -f "pi_stm32_bridge.py" ]; then
    nohup python3 pi_stm32_bridge.py > bridge_output.log 2>&1 &
    BRIDGE_PID=$!
    sleep 3
    
    if ps -p $BRIDGE_PID > /dev/null 2>&1; then
        echo "   ✅ Bridge started (PID: $BRIDGE_PID)"
    else
        echo "   ❌ Bridge failed to start"
        echo "   Check: cat ~/bridge_output.log"
        exit 1
    fi
else
    echo "   ❌ Bridge script not found at ~/pi_stm32_bridge.py"
    exit 1
fi
echo ""

# Step 5: Monitor logs briefly
echo "5. Checking initial logs (5 seconds)..."
sleep 5

if [ -f ~/stm32-bridge.log ]; then
    echo "   Recent log entries:"
    tail -10 ~/stm32-bridge.log | grep -E "(Received|ERROR|online|offline)" | tail -5 | sed 's/^/      /'
fi
echo ""

echo "========================================"
echo "✅ Setup Complete!"
echo "========================================"
echo ""
echo "The bridge is now running. DO NOT run:"
echo "  ❌ python3 pi_uart_test.py (will conflict!)"
echo ""
echo "Instead, monitor bridge logs:"
echo "  tail -f ~/stm32-bridge.log"
echo ""
echo "Look for:"
echo "  ✅ '📥 Received: STM32_ALIVE' (success!)"
echo "  ❌ 'ERROR' messages (still problems)"

