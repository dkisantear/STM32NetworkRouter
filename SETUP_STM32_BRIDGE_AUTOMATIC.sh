#!/bin/bash
# ========================================
# Complete STM32 Bridge Automatic Setup
# Copy/paste this ENTIRE block into Pi terminal
# ========================================

echo "========================================"
echo "🚀 STM32 Bridge Automatic Setup"
echo "========================================"
echo ""

# Get current user
CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)

echo "User: $CURRENT_USER"
echo "Home: $HOME_DIR"
echo ""

# Step 1: Install dependencies
echo "Step 1: Installing dependencies..."
python3 -c "import serial, requests" 2>/dev/null || {
    echo "Installing pyserial and requests..."
    pip3 install pyserial requests --break-system-packages || {
        sudo apt-get update
        sudo apt-get install -y python3-serial python3-requests
    }
}
echo "✅ Dependencies installed"
echo ""

# Step 2: Create bridge script
echo "Step 2: Creating bridge script..."
mkdir -p "$HOME_DIR/stm32-bridge"

cat > "$HOME_DIR/pi_stm32_bridge.py" << 'SCRIPT_EOF'
#!/usr/bin/env python3
import serial
import requests
import time
import sys
import logging
import os

UART_DEVICE = "/dev/ttyAMA0"
UART_BAUDRATE = 38400
API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status"
DEVICE_ID = "stm32-main"
HEARTBEAT_MESSAGE = "STM32_ALIVE"
LOG_FILE = os.path.expanduser("~/stm32-bridge.log")

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

def send_status_to_azure(status):
    payload = {"deviceId": DEVICE_ID, "status": status}
    try:
        response = requests.post(API_URL, json=payload, headers={"Content-Type": "application/json"}, timeout=10)
        response.raise_for_status()
        result = response.json()
        logger.info(f"✅ Status sent to Azure: {status} (lastUpdated: {result.get('lastUpdated', 'N/A')})")
        return True
    except Exception as e:
        logger.error(f"❌ Failed to send status: {e}")
        return False

def main():
    logger.info("=" * 60)
    logger.info("🚀 STM32 UART Bridge Starting")
    logger.info(f"   UART Device: {UART_DEVICE}")
    logger.info(f"   Baudrate: {UART_BAUDRATE}")
    logger.info(f"   API URL: {API_URL}")
    logger.info(f"   Device ID: {DEVICE_ID}")
    logger.info(f"   Log File: {LOG_FILE}")
    logger.info("=" * 60)
    
    ser = None
    last_message_time = None
    last_status_sent = None
    
    try:
        ser = serial.Serial(UART_DEVICE, UART_BAUDRATE, timeout=1.0)
        logger.info("✅ Serial port opened")
        
        # Send initial online status
        logger.info("📤 Sending initial 'online' status to Azure...")
        if send_status_to_azure("online"):
            last_status_sent = "online"
            logger.info("✅ Initial status sent successfully!")
        else:
            logger.error("❌ Failed to send initial status")
        
        logger.info("👂 Listening for STM32 messages...")
        
        while True:
            try:
                line = ser.readline().decode("utf-8", errors="ignore").strip()
                
                if line:
                    logger.debug(f"Received: {repr(line)}")
                    
                    if HEARTBEAT_MESSAGE in line or line == HEARTBEAT_MESSAGE:
                        last_message_time = time.time()
                        
                        # Send online status every time we receive a message
                        if send_status_to_azure("online"):
                            last_status_sent = "online"
                
                # Timeout check
                if last_message_time:
                    time_since_last = time.time() - last_message_time
                    if time_since_last > 10:
                        if last_status_sent != "offline":
                            logger.warning(f"⚠️  No message for {time_since_last:.1f}s - marking offline")
                            if send_status_to_azure("offline"):
                                last_status_sent = "offline"
                        
            except Exception as e:
                logger.error(f"Error processing UART: {e}")
            
            time.sleep(0.1)
            
    except serial.SerialException as e:
        logger.error(f"❌ Serial error: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        logger.info("🛑 Shutting down...")
        send_status_to_azure("offline")
    except Exception as e:
        logger.error(f"❌ Fatal error: {e}")
        sys.exit(1)
    finally:
        if ser and ser.is_open:
            ser.close()

if __name__ == "__main__":
    main()
SCRIPT_EOF

chmod +x "$HOME_DIR/pi_stm32_bridge.py"
echo "✅ Bridge script created: $HOME_DIR/pi_stm32_bridge.py"
echo ""

# Step 3: Test UART
echo "Step 3: Testing UART connection..."
python3 << TEST_EOF
import serial
import time
try:
    ser = serial.Serial("/dev/ttyAMA0", 38400, timeout=1)
    print("✅ UART opened")
    print("Listening for 5 seconds...")
    messages = 0
    start = time.time()
    while time.time() - start < 5:
        if ser.in_waiting:
            line = ser.readline().decode("utf-8", errors="ignore").strip()
            if line:
                messages += 1
                print(f"   📥 {repr(line)}")
        time.sleep(0.1)
    ser.close()
    if messages > 0:
        print(f"✅ UART working! Received {messages} message(s)")
    else:
        print("⚠️  No messages - but continuing anyway")
except Exception as e:
    print(f"⚠️  UART test error: {e} - but continuing")
TEST_EOF

echo ""

# Step 4: Test sending to Azure
echo "Step 4: Testing Azure connection..."
python3 << AZURE_TEST_EOF
import requests
try:
    response = requests.post(
        "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status",
        json={"deviceId": "stm32-main", "status": "online"},
        headers={"Content-Type": "application/json"},
        timeout=10
    )
    response.raise_for_status()
    result = response.json()
    print(f"✅ Azure connection works!")
    print(f"   Response: {result}")
except Exception as e:
    print(f"❌ Azure connection failed: {e}")
    exit(1)
AZURE_TEST_EOF

if [ $? -ne 0 ]; then
    echo "❌ Azure test failed. Check network connection."
    exit 1
fi

echo ""

# Step 5: Stop any existing bridge process
echo "Step 5: Stopping any existing bridge processes..."
pkill -f pi_stm32_bridge.py 2>/dev/null || true
sleep 1
echo "✅ Stopped existing processes"
echo ""

# Step 6: Start bridge script in background
echo "Step 6: Starting bridge script..."
cd "$HOME_DIR"
nohup python3 pi_stm32_bridge.py > /dev/null 2>&1 &
BRIDGE_PID=$!
sleep 3

# Check if it's running
if ps -p $BRIDGE_PID > /dev/null; then
    echo "✅ Bridge script started (PID: $BRIDGE_PID)"
else
    echo "❌ Bridge script failed to start. Check logs:"
    echo "   tail -f ~/stm32-bridge.log"
    exit 1
fi

echo ""

# Step 7: Wait and verify status
echo "Step 7: Verifying status update..."
sleep 5

python3 << STATUS_CHECK_EOF
import requests
import time

for i in range(3):
    try:
        response = requests.get(
            "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main",
            timeout=5
        )
        response.raise_for_status()
        result = response.json()
        status = result.get('status', 'unknown')
        last_updated = result.get('lastUpdated', None)
        
        print(f"   Status: {status}")
        if last_updated:
            print(f"   Last Updated: {last_updated}")
        
        if status == 'online':
            print(f"✅ SUCCESS! Status is 'online'")
            exit(0)
        else:
            print(f"   Waiting... ({i+1}/3)")
            time.sleep(3)
    except Exception as e:
        print(f"   Error checking status: {e}")
        time.sleep(3)

print("⚠️  Status not 'online' yet. Check logs:")
print("   tail -f ~/stm32-bridge.log")
exit(1)
STATUS_CHECK_EOF

echo ""

# Step 8: Create systemd service
echo "Step 8: Creating systemd service for auto-start..."
sudo tee /etc/systemd/system/stm32-bridge.service > /dev/null << SERVICE_EOF
[Unit]
Description=STM32 UART Bridge Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$HOME_DIR
ExecStart=/usr/bin/python3 $HOME_DIR/pi_stm32_bridge.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF

sudo systemctl daemon-reload
echo "✅ Systemd service created"
echo ""

echo "========================================"
echo "✅ Setup Complete!"
echo "========================================"
echo ""
echo "Bridge script is running in background."
echo ""
echo "Useful commands:"
echo "  View logs:        tail -f ~/stm32-bridge.log"
echo "  Check status:     ps aux | grep pi_stm32_bridge"
echo "  Stop bridge:      pkill -f pi_stm32_bridge.py"
echo "  Start service:    sudo systemctl start stm32-bridge"
echo "  Enable on boot:   sudo systemctl enable stm32-bridge"
echo "  Check service:    sudo systemctl status stm32-bridge"
echo ""
echo "Enable auto-start on boot:"
echo "  sudo systemctl enable stm32-bridge"
echo ""



