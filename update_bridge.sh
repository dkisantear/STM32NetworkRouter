#!/bin/bash
# Quick script to update and restart the STM32 bridge on Pi

echo "=========================================="
echo "Updating STM32 Bridge Script"
echo "=========================================="
echo ""

# Navigate to home directory (where bridge script should be)
cd ~

# Kill any existing bridge processes
echo "🛑 Stopping existing bridge script..."
pkill -f pi_stm32_bridge.py
sleep 2

# Check if git repo exists, if not clone it
if [ ! -d "LoveableRepo" ]; then
    echo "📥 Cloning repository..."
    # Update this URL with your actual repo URL if different
    git clone https://github.com/YOUR_USERNAME/LoveableRepo.git
    cd LoveableRepo
else
    echo "📥 Pulling latest changes..."
    cd LoveableRepo
    git pull
fi

# Copy bridge script to home directory
echo "📋 Copying bridge script..."
cp pi_stm32_bridge.py ~/

# Go back to home
cd ~

# Start the bridge script in background
echo "🚀 Starting updated bridge script..."
echo ""
nohup python3 pi_stm32_bridge.py > /dev/null 2>&1 &
sleep 2

# Check if it's running
if pgrep -f pi_stm32_bridge.py > /dev/null; then
    echo "✅ Bridge script is running!"
    echo ""
    echo "To view logs, run:"
    echo "  tail -f ~/stm32-bridge.log"
    echo ""
    echo "To stop the bridge, run:"
    echo "  pkill -f pi_stm32_bridge.py"
else
    echo "❌ Failed to start bridge script"
    echo "Try running manually: python3 pi_stm32_bridge.py"
fi

