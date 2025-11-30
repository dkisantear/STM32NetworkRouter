#!/bin/bash
# Automated Pi Setup Script
# This will transfer files and run setup automatically

PI_HOST="192.168.1.160"
PI_USER="pi"
PI_PASS="raspberry"
SCRIPT_DIR="/mnt/c/Users/dkisa/Downloads/School/CPE185/Lab/FinalProject/LoveableRepo"

echo "=========================================="
echo "Automated Raspberry Pi Setup"
echo "=========================================="
echo ""

# Check if we can reach the Pi
echo "Step 1: Testing connection to $PI_HOST..."
if ping -c 1 -W 2 $PI_HOST > /dev/null 2>&1; then
    echo "✅ Pi is reachable!"
else
    echo "❌ Cannot reach Pi. Trying hostname..."
    PI_HOST="raspberrypi.local"
    if ping -c 1 -W 2 $PI_HOST > /dev/null 2>&1; then
        echo "✅ Pi is reachable via hostname!"
    else
        echo "❌ Cannot reach Pi. Please check connection."
        exit 1
    fi
fi

echo ""
echo "Step 2: Creating setup script to transfer..."

# Create the complete setup script that will run on Pi
SETUP_SCRIPT=$(cat << 'EOFSCRIPT'
#!/bin/bash
echo "=========================================="
echo "Installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y python3 python3-pip -qq
pip3 install requests --quiet --break-system-packages 2>/dev/null || pip3 install requests --quiet || sudo pip3 install requests --quiet

echo "✅ Dependencies installed"
EOFSCRIPT
)

# Save setup script temporarily
echo "$SETUP_SCRIPT" > /tmp/pi_setup.sh
chmod +x /tmp/pi_setup.sh

echo "✅ Setup script created"
echo ""
echo "Step 3: Attempting to transfer files..."
echo ""
echo "⚠️  Note: This requires password authentication."
echo "   You may be prompted for password: raspberry"
echo ""

# Try to transfer files using SCP
echo "Transferring heartbeat scripts..."

# Transfer test script
scp "$SCRIPT_DIR/pi_heartbeat_test.py" "$PI_USER@$PI_HOST:~/pi_heartbeat_test.py" 2>&1

# Transfer continuous script  
scp "$SCRIPT_DIR/pi_heartbeat_continuous.py" "$PI_USER@$PI_HOST:~/pi_heartbeat_continuous.py" 2>&1

# Transfer setup script
scp /tmp/pi_setup.sh "$PI_USER@$PI_HOST:~/setup.sh" 2>&1

echo ""
echo "Step 4: Running setup on Pi..."
echo "⚠️  You may be prompted for sudo password: raspberry"
echo ""

# Run setup script on Pi
ssh "$PI_USER@$PI_HOST" 'bash ~/setup.sh' 2>&1

echo ""
echo "Step 5: Making scripts executable..."
ssh "$PI_USER@$PI_HOST" 'chmod +x pi_heartbeat_test.py pi_heartbeat_continuous.py' 2>&1

echo ""
echo "Step 6: Running test heartbeat..."
ssh "$PI_USER@$PI_HOST" 'python3 pi_heartbeat_test.py' 2>&1

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "To run continuously in background, SSH into Pi and run:"
echo "  nohup python3 ~/pi_heartbeat_continuous.py > ~/heartbeat.log 2>&1 &"
echo ""
echo "Check your dashboard - it should show 'Connected'!"
echo ""

