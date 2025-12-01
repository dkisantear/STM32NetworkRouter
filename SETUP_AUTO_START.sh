#!/bin/bash
# ========================================
# Set Up Bridge to Start Automatically on Boot
# Creates systemd service for auto-start
# ========================================

CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)

echo "========================================"
echo "🔧 Set Up Auto-Start on Boot"
echo "========================================"
echo ""

# Step 1: Check script exists
if [ ! -f "$HOME_DIR/pi_stm32_bridge.py" ]; then
    echo "❌ Bridge script not found!"
    echo "Please copy pi_stm32_bridge.py to $HOME_DIR/"
    exit 1
fi

# Step 2: Create systemd service file
echo "1. Creating systemd service..."
sudo tee /etc/systemd/system/stm32-bridge.service > /dev/null << EOF
[Unit]
Description=STM32 UART Bridge to Azure
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$HOME_DIR
ExecStart=/usr/bin/python3 $HOME_DIR/pi_stm32_bridge.py
Restart=always
RestartSec=10
StandardOutput=append:$HOME_DIR/stm32-bridge.log
StandardError=append:$HOME_DIR/stm32-bridge.log

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Service file created"
echo ""

# Step 3: Reload systemd
echo "2. Reloading systemd..."
sudo systemctl daemon-reload
echo "✅ Reloaded"
echo ""

# Step 4: Enable service (start on boot)
echo "3. Enabling service (auto-start on boot)..."
sudo systemctl enable stm32-bridge.service
echo "✅ Enabled"
echo ""

# Step 5: Start service now
echo "4. Starting service now..."
sudo systemctl start stm32-bridge.service
sleep 2

if sudo systemctl is-active --quiet stm32-bridge.service; then
    echo "✅ Service started successfully!"
else
    echo "⚠️  Service may have issues starting"
    echo "Check status: sudo systemctl status stm32-bridge.service"
fi
echo ""

# Step 6: Show status
echo "5. Service status:"
sudo systemctl status stm32-bridge.service --no-pager -l | head -15
echo ""

echo "========================================"
echo "✅ Auto-Start Configured!"
echo "========================================"
echo ""
echo "The bridge will now:"
echo "  ✅ Start automatically on boot"
echo "  ✅ Restart automatically if it crashes"
echo ""
echo "📋 Useful commands:"
echo "   Check status:    sudo systemctl status stm32-bridge.service"
echo "   View logs:       tail -f ~/stm32-bridge.log"
echo "   Stop service:    sudo systemctl stop stm32-bridge.service"
echo "   Restart service: sudo systemctl restart stm32-bridge.service"
echo ""

