#!/bin/bash
# Quick setup script for Raspberry Pi
# Run this on your Pi to set up the heartbeat system

echo "=========================================="
echo "Raspberry Pi Gateway Setup"
echo "=========================================="
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip
else
    echo "✅ Python 3 found: $(python3 --version)"
fi

# Install requests library
echo ""
echo "Installing requests library..."
pip3 install requests --quiet
if [ $? -eq 0 ]; then
    echo "✅ requests library installed"
else
    echo "❌ Failed to install requests. Trying with sudo..."
    sudo pip3 install requests
fi

# Make scripts executable
if [ -f "pi_heartbeat_test.py" ]; then
    chmod +x pi_heartbeat_test.py
    echo "✅ Made pi_heartbeat_test.py executable"
fi

if [ -f "pi_heartbeat_continuous.py" ]; then
    chmod +x pi_heartbeat_continuous.py
    echo "✅ Made pi_heartbeat_continuous.py executable"
fi

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Test connection: python3 pi_heartbeat_test.py"
echo "2. Run continuously: python3 pi_heartbeat_continuous.py"
echo ""

