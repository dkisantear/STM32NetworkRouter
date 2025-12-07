#!/bin/bash
# Complete Pi Setup Script
# Sets up Gateway Heartbeat and STM32 Bridge services

set -e

echo "=========================================="
echo "Pi Service Setup"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Get the user who ran sudo
PI_USER=${SUDO_USER:-pi5}
HOME_DIR=$(eval echo ~$PI_USER)

echo "Setting up for user: $PI_USER"
echo "Home directory: $HOME_DIR"
echo ""

# 1. Create scripts directory
SCRIPTS_DIR="$HOME_DIR/pi-scripts"
mkdir -p "$SCRIPTS_DIR"
chown $PI_USER:$PI_USER "$SCRIPTS_DIR"
echo -e "${GREEN}✅ Created scripts directory${NC}"

# 2. Copy scripts (assuming they're in current directory)
if [ -f "pi_gateway_heartbeat.py" ]; then
    cp pi_gateway_heartbeat.py "$SCRIPTS_DIR/"
    chown $PI_USER:$PI_USER "$SCRIPTS_DIR/pi_gateway_heartbeat.py"
    chmod +x "$SCRIPTS_DIR/pi_gateway_heartbeat.py"
    echo -e "${GREEN}✅ Copied gateway heartbeat script${NC}"
else
    echo -e "${YELLOW}⚠️  pi_gateway_heartbeat.py not found in current directory${NC}"
fi

if [ -f "pi_stm32_bridge.py" ]; then
    cp pi_stm32_bridge.py "$SCRIPTS_DIR/"
    chown $PI_USER:$PI_USER "$SCRIPTS_DIR/pi_stm32_bridge.py"
    chmod +x "$SCRIPTS_DIR/pi_stm32_bridge.py"
    echo -e "${GREEN}✅ Copied STM32 bridge script${NC}"
else
    echo -e "${YELLOW}⚠️  pi_stm32_bridge.py not found in current directory${NC}"
fi

# 3. Install Python dependencies
echo ""
echo "Installing Python dependencies..."
pip3 install --user requests pyserial || {
    echo -e "${YELLOW}⚠️  pip3 install failed, trying apt-get${NC}"
    apt-get update && apt-get install -y python3-requests python3-serial || {
        echo -e "${RED}❌ Failed to install dependencies${NC}"
    }
}
echo -e "${GREEN}✅ Dependencies installed${NC}"

# 4. Create systemd service for Gateway Heartbeat
cat > /etc/systemd/system/gateway-heartbeat.service << EOF
[Unit]
Description=Pi Gateway Heartbeat - Sends status to Azure
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$PI_USER
WorkingDirectory=$SCRIPTS_DIR
ExecStart=/usr/bin/python3 $SCRIPTS_DIR/pi_gateway_heartbeat.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Graceful shutdown
ExecStop=/bin/sh -c '/usr/bin/python3 -c "import requests; requests.post(\"https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status\", json={\"gatewayId\":\"pi5-main\",\"status\":\"offline\"}, timeout=5)" || true'

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✅ Created gateway-heartbeat.service${NC}"

# 5. Create systemd service for STM32 Bridge
cat > /etc/systemd/system/stm32-bridge.service << EOF
[Unit]
Description=STM32 UART Bridge - Connects STM32 to Azure
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$PI_USER
WorkingDirectory=$SCRIPTS_DIR
ExecStart=/usr/bin/python3 $SCRIPTS_DIR/pi_stm32_bridge.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Send offline status before stopping
ExecStop=/bin/sh -c '/usr/bin/python3 -c "import requests; requests.post(\"https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status\", json={\"deviceId\":\"stm32-master\",\"status\":\"offline\"}, timeout=5)" || true'

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✅ Created stm32-bridge.service${NC}"

# 6. Enable and start services
echo ""
echo "Enabling services..."
systemctl daemon-reload
systemctl enable gateway-heartbeat.service
systemctl enable stm32-bridge.service

echo -e "${GREEN}✅ Services enabled${NC}"

# 7. Start services
echo ""
echo "Starting services..."
systemctl start gateway-heartbeat.service
systemctl start stm32-bridge.service

echo -e "${GREEN}✅ Services started${NC}"

# 8. Check status
echo ""
echo "Service status:"
echo "--- Gateway Heartbeat ---"
systemctl status gateway-heartbeat.service --no-pager -l | head -10
echo ""
echo "--- STM32 Bridge ---"
systemctl status stm32-bridge.service --no-pager -l | head -10

echo ""
echo -e "${GREEN}=========================================="
echo "✅ Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Services are now running and will auto-start on boot."
echo ""
echo "To check logs:"
echo "  journalctl -u gateway-heartbeat.service -f"
echo "  journalctl -u stm32-bridge.service -f"
echo ""
echo "To restart services:"
echo "  sudo systemctl restart gateway-heartbeat.service"
echo "  sudo systemctl restart stm32-bridge.service"
