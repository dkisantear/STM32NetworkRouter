#!/bin/bash
# ========================================
# Update STM32 Bridge Script on Pi
# ========================================
# Run this script on your Pi to update the bridge script

echo "========================================"
echo "🔄 Updating STM32 Bridge Script"
echo "========================================"
echo ""

# Step 1: Stop any running bridge
echo "1. Stopping existing bridge..."
pkill -f pi_stm32_bridge.py
sleep 2
echo "   ✅ Bridge stopped"
echo ""

# Step 2: Backup old script
echo "2. Backing up old script..."
if [ -f ~/pi_stm32_bridge.py ]; then
    cp ~/pi_stm32_bridge.py ~/pi_stm32_bridge.py.backup.$(date +%Y%m%d_%H%M%S)
    echo "   ✅ Backup created"
else
    echo "   ⚠️  No existing script found"
fi
echo ""

# Step 3: Instructions for copying new script
echo "3. Copy the updated script:"
echo "   ========================================="
echo "   ON YOUR WINDOWS COMPUTER:"
echo "   ========================================="
echo "   1. Open pi_stm32_bridge.py from this repo"
echo "   2. Copy ALL the contents (Ctrl+A, Ctrl+C)"
echo ""
echo "   ON YOUR PI (run these commands):"
echo "   ========================================="
echo "   nano ~/pi_stm32_bridge.py"
echo ""
echo "   3. Delete everything in nano (Ctrl+K repeatedly)"
echo "   4. Paste the new contents (right-click or Ctrl+Shift+V)"
echo "   5. Save (Ctrl+O, Enter, Ctrl+X)"
echo ""
echo "   OR use scp from Windows (PowerShell):"
echo "   ========================================="
echo "   scp pi_stm32_bridge.py pi5@192.168.1.160:~/"
echo ""
echo "========================================"
read -p "Press Enter after you've copied the file to continue..."

# Step 4: Verify script exists and is executable
echo ""
echo "4. Verifying script..."
if [ -f ~/pi_stm32_bridge.py ]; then
    chmod +x ~/pi_stm32_bridge.py
    echo "   ✅ Script found and made executable"
    
    # Check if it has readline() (the fix)
    if grep -q "ser.readline()" ~/pi_stm32_bridge.py; then
        echo "   ✅ Script contains readline() fix"
    else
        echo "   ❌ Script might be old - check that it has 'ser.readline()'"
    fi
else
    echo "   ❌ Script not found! Make sure you copied it."
    exit 1
fi
echo ""

# Step 5: Test UART connection first
echo "5. Testing UART connection..."
echo "   Run this command to verify STM32 is sending:"
echo "   python3 pi_uart_test.py"
echo ""
read -p "Does pi_uart_test.py receive 'STM32_ALIVE' messages? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "   ⚠️  UART test failed! Fix that first before running bridge."
    echo "   Check:"
    echo "      - STM32 is powered on"
    echo "      - UART wiring is correct"
    echo "      - STM32 baud rate is 38400"
    exit 1
fi
echo ""

# Step 6: Start the bridge
echo "6. Starting bridge..."
cd ~
nohup python3 pi_stm32_bridge.py > bridge_output.log 2>&1 &
sleep 2

if pgrep -f pi_stm32_bridge.py > /dev/null; then
    BRIDGE_PID=$(pgrep -f pi_stm32_bridge.py)
    echo "   ✅ Bridge started (PID: $BRIDGE_PID)"
else
    echo "   ❌ Bridge failed to start! Check bridge_output.log"
    exit 1
fi
echo ""

# Step 7: Monitor logs
echo "7. Monitoring logs (Ctrl+C to stop)..."
echo "   ========================================="
tail -f ~/stm32-bridge.log

