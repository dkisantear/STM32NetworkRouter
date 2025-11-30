#!/bin/bash
# Complete automated Pi setup - Run this in WSL or bash

PI_IP="192.168.1.160"
PI_USER="pi"
PI_PASS="raspberry"
SCRIPT_DIR="/mnt/c/Users/dkisa/Downloads/School/CPE185/Lab/FinalProject/LoveableRepo"

cd "$SCRIPT_DIR" || exit 1

echo "=========================================="
echo "Automated Raspberry Pi Setup"
echo "=========================================="
echo "Pi: $PI_USER@$PI_IP"
echo ""

# Test connection
echo "Testing connection..."
if ping -c 1 -W 2 $PI_IP > /dev/null 2>&1; then
    echo "✅ Pi is reachable!"
else
    echo "⚠️  Could not ping, but continuing..."
fi

echo ""
echo "Transferring files (password: $PI_PASS)..."
echo ""

# Transfer files using SCP (will prompt for password)
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SCRIPT_DIR/pi_heartbeat_test.py" "$PI_USER@$PI_IP:~/pi_heartbeat_test.py"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SCRIPT_DIR/pi_heartbeat_continuous.py" "$PI_USER@$PI_IP:~/pi_heartbeat_continuous.py"

echo ""
echo "Running setup on Pi (password: $PI_PASS)..."
echo ""

# SSH and run setup (auto-accept host key)
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$PI_USER@$PI_IP" << 'ENDSSH'
sudo apt-get update -qq
sudo apt-get install -y python3 python3-pip -qq
pip3 install requests --quiet --break-system-packages 2>/dev/null || pip3 install requests --quiet || sudo pip3 install requests --quiet
chmod +x pi_heartbeat_test.py pi_heartbeat_continuous.py
python3 pi_heartbeat_test.py
ENDSSH

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo "Check your dashboard - it should show 'Connected'!"
echo ""

