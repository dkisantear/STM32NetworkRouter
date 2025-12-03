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
COMMAND_API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-command"
DEVICE_ID = "stm32-master"  # Must match frontend useMasterStatus hook
TIMEOUT_SECONDS = 10  # If no UART message received in this time, mark as offline
HEARTBEAT_MESSAGE = "STM32_ALIVE"
COMMAND_POLL_INTERVAL = 2  # Poll for commands every 2 seconds

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

def get_pending_commands():
    """Poll Azure for pending commands for Master board"""
    try:
        response = requests.get(
            COMMAND_API_URL,
            params={"deviceId": DEVICE_ID},
            timeout=5
        )
        response.raise_for_status()
        data = response.json()
        return data.get("commands", [])
    except Exception as e:
        logger.debug(f"Failed to poll commands: {e}")
        return []

def mark_command_sent(command_id):
    """Mark a command as sent in Azure"""
    try:
        response = requests.put(
            COMMAND_API_URL,
            json={"commandId": command_id, "status": "sent"},
            timeout=5
        )
        response.raise_for_status()
        return True
    except Exception as e:
        logger.error(f"Failed to mark command as sent: {e}")
        return False

def send_command_to_stm32(ser, value, mode):
    """Send command to Master STM32 via UART2
    Format: Simple decimal value (0-16) matching DIP switch
    The Master board will replicate this value on its DIP switch output
    """
    if not ser or not ser.is_open:
        logger.error("❌ Cannot send command: serial port not open")
        return False
    
    try:
        # Send value as decimal string (0-16) matching DIP switch
        # Format: "{value}\n" - simple and matches DIP switch range
        command = f"{value}\n"
        ser.write(command.encode('utf-8'))
        logger.info(f"📤 Sent command to Master STM32: value={value} mode={mode} ({repr(command)})")
        
        # Small delay to ensure transmission completes
        time.sleep(0.05)
        return True
    except Exception as e:
        logger.error(f"❌ Failed to send command to STM32: {e}")
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
    last_command_poll_time = time.time()
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
                    now = time.time()
                    
                    # Poll for pending commands from Azure (from frontend)
                    if now - last_command_poll_time > COMMAND_POLL_INTERVAL:
                        commands = get_pending_commands()
                        for cmd in commands:
                            command_id = cmd.get("commandId")
                            value = cmd.get("value")
                            mode = cmd.get("mode", "uart")
                            
                            logger.info(f"📨 Processing command from frontend: value={value} mode={mode}")
                            if send_command_to_stm32(ser, value, mode):
                                mark_command_sent(command_id)
                                logger.info(f"✅ Command {command_id} sent successfully to Master STM32")
                            else:
                                logger.error(f"❌ Failed to send command {command_id}")
                        last_command_poll_time = now
                    
                    # Send periodic heartbeat status (every 30 seconds) - ALWAYS send, like Pi Gateway
                    # This ensures Master STM32 shows as "online" as long as bridge script is running
                    if now - last_heartbeat_time > 30:
                        logger.info("💓 Periodic heartbeat - sending online status to Azure")
                        if send_status_to_azure("online"):
                            last_status_sent = "online"
                            logger.info("✅ Heartbeat sent successfully")
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
                    
                    # Check for timeout - only mark offline if we've received messages before and they stop
                    # If Master board isn't sending data yet, we rely on heartbeat to keep status online
                    if last_message_time is not None:
                        time_since_last = time.time() - last_message_time
                        # Only timeout if we've actually received a message before (proving connection worked)
                        # If last_message_time was just initialized, don't timeout - rely on heartbeat
                        if time_since_last > TIMEOUT_SECONDS and (time.time() - last_message_time) < (TIMEOUT_SECONDS * 10):
                            # Only mark offline if we had messages and they stopped
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
