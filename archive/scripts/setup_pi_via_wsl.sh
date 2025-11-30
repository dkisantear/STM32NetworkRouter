#!/bin/bash
# Setup script that will be run via WSL
# This handles file transfer and Pi setup

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
echo "=========================================="
echo "Creating single setup command..."
echo "=========================================="

# Create a comprehensive setup script that can be run on Pi
cat > /tmp/pi_full_setup.sh << 'ENDOFSCRIPT'
#!/bin/bash
set -e

echo "=========================================="
echo "Raspberry Pi Gateway Setup"
echo "=========================================="
echo ""

# Install dependencies
echo "Installing Python dependencies..."
sudo apt-get update -qq
sudo apt-get install -y python3 python3-pip -qq
pip3 install requests --quiet --break-system-packages 2>/dev/null || pip3 install requests --quiet || sudo pip3 install requests --quiet

echo "✅ Dependencies installed"
echo ""

# Scripts will be created from transferred files or heredoc
echo "✅ Setup complete!"
ENDOFSCRIPT

chmod +x /tmp/pi_full_setup.sh

echo ""
echo "Files are ready. Next steps:"
echo ""
echo "1. Transfer files using SCP (you'll need to enter password):"
echo "   scp pi_heartbeat_test.py pi_heartbeat_continuous.py pi@$PI_IP:~/"
echo ""
echo "2. SSH into Pi and run setup:"
echo "   ssh pi@$PI_IP"
echo "   Then run: bash <(cat << 'EOF'"
echo "   [setup commands here]"
echo "   EOF"
echo ""

