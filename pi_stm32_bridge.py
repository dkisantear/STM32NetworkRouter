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
    """Main loop - reads UART and forwards to Azure with robust error recovery"""
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
    last_heartbeat_time = time.time()
    reconnect_delay = 5  # Seconds to wait before reconnecting
    
    while True:  # Outer loop for auto-recovery
        try:
            # Try to open serial port (with retry logic)
            if ser is None or not ser.is_open:
                try:
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
                    if send_status_to_azure("online"):
                        last_status_sent = "online"
                        logger.info("✅ Initial status sent!")
                    
                except serial.SerialException as e:
                    logger.error(f"❌ Failed to open serial port: {e}")
                    logger.info(f"⏳ Retrying in {reconnect_delay} seconds...")
                    # Send offline status if we can't open UART
                    if last_status_sent != "offline":
                        send_status_to_azure("offline")
                        last_status_sent = "offline"
                    time.sleep(reconnect_delay)
                    continue
            
            logger.info("👂 Listening for STM32 messages...")
            
            # Main read loop
            while True:
                try:
                    # Send periodic heartbeat status (every 30 seconds) even if no UART messages
                    now = time.time()
                    if now - last_heartbeat_time > 30:
                        if last_status_sent != "online":
                            logger.info("💓 Periodic heartbeat - sending online status")
                            if send_status_to_azure("online"):
                                last_status_sent = "online"
                        last_heartbeat_time = now
                    
                    # Read line from UART
                    if ser.in_waiting > 0:
                        line = ser.readline().decode("utf-8", errors="ignore").strip()
                        
                        if line:
                            logger.info(f"📥 Received: {repr(line)}")
                            
                            # Check if it's the expected heartbeat message
                            if HEARTBEAT_MESSAGE in line or line == HEARTBEAT_MESSAGE:
                                last_message_time = time.time()
                                
                                # Send "online" status when we receive a message
                                if send_status_to_azure("online"):
                                    last_status_sent = "online"
                    
                    # Check for timeout - if no message received in TIMEOUT_SECONDS, mark as offline
                    if last_message_time is not None:
                        time_since_last = time.time() - last_message_time
                        if time_since_last > TIMEOUT_SECONDS:
                            if last_status_sent != "offline":
                                logger.warning(f"⚠️  No STM32 message for {time_since_last:.1f}s, marking as offline")
                                if send_status_to_azure("offline"):
                                    last_status_sent = "offline"
                    
                except UnicodeDecodeError:
                    # Handle garbage/partial data - ignore and continue
                    pass
                except serial.SerialException as e:
                    logger.error(f"❌ Serial port error during read: {e}")
                    # Close port and break to reconnect
                    try:
                        ser.close()
                    except:
                        pass
                    ser = None
                    break  # Break inner loop, reconnect in outer loop
                except Exception as e:
                    logger.error(f"❌ Error processing UART data: {e}")
                    # Continue running - don't crash on errors
                
                # Small delay to prevent CPU spinning
                time.sleep(0.1)
                
        except KeyboardInterrupt:
            logger.info("🛑 Shutting down...")
            # Send offline status before exiting
            try:
                send_status_to_azure("offline")
            except:
                pass
            break  # Exit outer loop
            
        except Exception as e:
            logger.error(f"❌ Unexpected error: {e}")
            logger.info("⏳ Restarting in 5 seconds...")
            # Close serial port if open
            try:
                if ser and ser.is_open:
                    ser.close()
            except:
                pass
            ser = None
            time.sleep(5)
            # Continue outer loop to retry
        
        finally:
            # Only close if we're actually exiting (not restarting)
            if ser and ser.is_open:
                try:
                    ser.close()
                    logger.info("📡 Serial port closed")
                except:
                    pass

if __name__ == "__main__":
    main()

