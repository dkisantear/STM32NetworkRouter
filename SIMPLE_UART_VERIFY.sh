#!/bin/bash
# Simple script to verify STM32 UART connection
# Run this FIRST before worrying about bridge script

echo "=========================================="
echo "STM32 UART Connection Verification"
echo "=========================================="
echo ""

# Stop any running bridge scripts
echo "🛑 Stopping any running bridge scripts..."
pkill -f pi_stm32_bridge.py
sleep 1

echo ""
echo "📡 Checking UART device..."
ls -l /dev/ttyAMA* /dev/serial0 2>/dev/null

echo ""
echo "=========================================="
echo "Testing UART Reception (10 seconds)"
echo "=========================================="
echo ""
echo "Make sure:"
echo "1. STM32 is powered ON"
echo "2. STM32 is flashed with code that sends UART data"
echo "3. Wiring: Pi GPIO15(RX) → STM32 PA2(TX)"
echo ""

python3 pi_check_stm32_sending.py

echo ""
echo "=========================================="
echo "Results:"
echo "- If you saw messages above → UART WORKS!"
echo "- If you saw 'NO MESSAGES' → Check STM32 code/wiring"
echo "=========================================="

