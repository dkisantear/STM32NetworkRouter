#!/usr/bin/env python3
"""
STM32 UART Bridge for Raspberry Pi
Reads STM32 heartbeat messages from UART and forwards status to Azure
"""

import serial
import requests
import time
import sys
import logging
import os

# Configuration
UART_DEVICE = "/dev/ttyAMA0"  # Pi 5 UART device
UART_BAUDRATE = 38400
API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status"
DEVICE_ID = "stm32-main"
TIMEOUT_SECONDS = 10  # If no UART message received in this time, mark as offline
HEARTBEAT_MESSAGE = "STM32_ALIVE"

# Use home directory for log file (no sudo needed)
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
    """Send STM32 status to Azure Function"""
    payload = {
        "deviceId": DEVICE_ID,
        "status": status
    }
    
    try:
        response = requests.post(
            API_URL,
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        response.raise_for_status()
        result = response.json()
        logger.info(f"✅ Status sent to Azure: {status}")
        return True
    except Exception as e:
        logger.error(f"❌ Failed to send status to Azure: {e}")
        return False

def main():
    """Main loop - reads UART and forwards to Azure"""
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
        # Open serial port
        logger.info(f"📡 Opening {UART_DEVICE}...")
        ser = serial.Serial(
            port=UART_DEVICE,
            baudrate=UART_BAUDRATE,
            timeout=1.0,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE
        )
        logger.info(f"✅ Serial port opened successfully!")
        
        # Send initial "online" status
        send_status_to_azure("online")
        last_status_sent = "online"
        
        logger.info("👂 Listening for STM32 messages...")
        
        while True:
            try:
                # Read line from UART
                line = ser.readline().decode("utf-8", errors="ignore").strip()
                
                if line:
                    logger.debug(f"Received: {repr(line)}")
                    
                    # Check if it's the expected heartbeat message
                    if HEARTBEAT_MESSAGE in line or line == HEARTBEAT_MESSAGE:
                        last_message_time = time.time()
                        
                        # Send "online" status if we haven't recently
                        if last_status_sent != "online":
                            send_status_to_azure("online")
                            last_status_sent = "online"
                
                # Check for timeout - if no message received in TIMEOUT_SECONDS, mark as offline
                if last_message_time is not None:
                    time_since_last = time.time() - last_message_time
                    if time_since_last > TIMEOUT_SECONDS:
                        if last_status_sent != "offline":
                            logger.warning(f"⚠️  No STM32 message for {time_since_last:.1f}s, marking as offline")
                            send_status_to_azure("offline")
                            last_status_sent = "offline"
                
            except UnicodeDecodeError:
                # Handle garbage/partial data - ignore
                pass
            except Exception as e:
                logger.error(f"❌ Error processing UART data: {e}")
            
            # Small delay to prevent CPU spinning
            time.sleep(0.1)
            
    except serial.SerialException as e:
        logger.error(f"❌ Serial port error: {e}")
        logger.error("Troubleshooting:")
        logger.error("  1. Check if UART is enabled: sudo raspi-config → Interface Options → Serial Port")
        logger.error(f"  2. Verify device exists: ls -l {UART_DEVICE}")
        logger.error("  3. Check permissions: sudo usermod -a -G dialout $USER")
        sys.exit(1)
        
    except KeyboardInterrupt:
        logger.info("🛑 Shutting down...")
        # Send offline status before exiting
        try:
            send_status_to_azure("offline")
        except:
            pass
            
    except Exception as e:
        logger.error(f"❌ Unexpected error: {e}")
        sys.exit(1)
        
    finally:
        if ser and ser.is_open:
            ser.close()
            logger.info("📡 Serial port closed")

if __name__ == "__main__":
    main()

