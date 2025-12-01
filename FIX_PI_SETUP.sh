#!/bin/bash
# Fixed Pi Setup Script - Handles newer Pi OS and user permissions

echo "========================================"
echo "🔧 Fixed Pi Heartbeat Setup"
echo "========================================"
echo ""

# Get current username
CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)

echo "Detected user: $CURRENT_USER"
echo "Home directory: $HOME_DIR"
echo ""

# Step 1: Create directory and script
echo "📁 Creating directory..."
mkdir -p $HOME_DIR/gateway-heartbeat
cd $HOME_DIR/gateway-heartbeat

echo "📝 Creating Python script..."
cat > pi_heartbeat_automated.py << 'PYTHON_EOF'
#!/usr/bin/env python3
import requests
import time
import sys
import logging
import os

API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status"
GATEWAY_ID = "pi5-main"
HEARTBEAT_INTERVAL = 60

# Use home directory for log file (no sudo needed)
LOG_FILE = os.path.expanduser("~/gateway-heartbeat.log")

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

def send_heartbeat():
    payload = {"gatewayId": GATEWAY_ID, "status": "online"}
    try:
        response = requests.post(API_URL, json=payload, headers={"Content-Type": "application/json"}, timeout=10)
        response.raise_for_status()
        result = response.json()
        logger.info(f"✅ Heartbeat sent: {result.get('status')}")
        return True
    except Exception as e:
        logger.error(f"❌ Failed: {e}")
        return False

def main():
    logger.info("🚀 Gateway Heartbeat Service Starting")
    while True:
        try:
            send_heartbeat()
            time.sleep(HEARTBEAT_INTERVAL)
        except KeyboardInterrupt:
            logger.info("🛑 Shutting down...")
            try:
                requests.post(API_URL, json={"gatewayId": GATEWAY_ID, "status": "offline"}, timeout=5)
            except:
                pass
            break
        except Exception as e:
            logger.error(f"❌ Error: {e}")
            time.sleep(HEARTBEAT_INTERVAL)

if __name__ == "__main__":
    main()
PYTHON_EOF

chmod +x pi_heartbeat_automated.py
echo "✅ Script created"

# Step 2: Install requests (handle newer Pi OS)
echo ""
echo "📦 Installing Python requests library..."
if python3 -c "import requests" 2>/dev/null; then
    echo "✅ requests already installed"
else
    echo "Attempting to install via pip3..."
    pip3 install requests --break-system-packages 2>/dev/null || {
        echo "pip3 failed, trying apt-get..."
        sudo apt-get update
        sudo apt-get install -y python3-requests || {
            echo "⚠️  Could not install requests automatically"
            echo "Please install manually: sudo apt-get install python3-requests"
        }
    }
fi

# Step 3: Create systemd service with correct user
echo ""
echo "⚙️  Creating systemd service..."
sudo tee /etc/systemd/system/gateway-heartbeat.service > /dev/null << SERVICE_EOF
[Unit]
Description=Gateway Heartbeat Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$HOME_DIR/gateway-heartbeat
ExecStart=/usr/bin/python3 $HOME_DIR/gateway-heartbeat/pi_heartbeat_automated.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF

echo "✅ Service file created"

# Step 4: Enable and start service
echo ""
echo "🚀 Starting service..."
sudo systemctl daemon-reload
sudo systemctl enable gateway-heartbeat.service
sudo systemctl start gateway-heartbeat.service

# Step 5: Wait a moment and check status
sleep 2
echo ""
echo "📊 Service Status:"
sudo systemctl status gateway-heartbeat.service --no-pager -l

echo ""
echo "========================================"
echo "✅ Setup Complete!"
echo "========================================"
echo ""
echo "📋 Check logs:"
echo "   tail -f ~/gateway-heartbeat.log"
echo ""
echo "📋 Or systemd logs:"
echo "   sudo journalctl -u gateway-heartbeat.service -f"
echo ""
echo "🌐 Check dashboard:"
echo "   https://blue-desert-0c2a27e1e.3.azurestaticapps.net"
echo ""
echo "   Status should show 'Online' within 60 seconds!"
echo ""

