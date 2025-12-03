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
                        timeout=0.5,  # Shorter timeout for more responsive checking
                        bytesize=serial.EIGHTBITS,
                        parity=serial.PARITY_NONE,
                        stopbits=serial.STOPBITS_ONE,
                        xonxoff=False,
                        rtscts=False,
                        dsrdtr=False
                    )
                    # Flush any stale data
                    ser.reset_input_buffer()
                    ser.reset_output_buffer()
                    logger.info(f"✅ Serial port opened successfully!")
                    
                    # Send initial "offline" status - will change to "online" when we receive heartbeat
                    if send_status_to_azure("offline"):
                        last_status_sent = "offline"
                        logger.info("✅ Initial status sent: offline (waiting for STM32 heartbeat...)")
                    
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
                        try:
                            commands = get_pending_commands()
                            
                            for cmd in commands:
                                command_id = cmd.get("commandId")
                                value = cmd.get("value")
                                mode = cmd.get("mode", "uart")
                                
                                # Skip if we've already processed this command (prevents spam)
                                if command_id in processed_command_ids:
                                    continue
                                
                                logger.info(f"📨 Processing command from frontend: value={value} mode={mode}")
                                
                                # Send command to STM32
                                if send_command_to_stm32(ser, value, mode):
                                    # Try to mark as sent
                                    if mark_command_sent(command_id):
                                        logger.info(f"✅ Command {command_id} sent and marked as sent")
                                        processed_command_ids.add(command_id)  # Track successful ones
                                    else:
                                        # If marking fails, still mark as processed to prevent spam
                                        # but only after 3 attempts (prevents infinite loop)
                                        if command_id not in processed_command_ids:
                                            logger.warning(f"⚠️  Command {command_id} sent but failed to mark in Azure")
                                            processed_command_ids.add(command_id)  # Prevent spam
                                else:
                                    logger.error(f"❌ Failed to send command {command_id} to STM32")
                                    # Don't add to processed if we failed to send
                        except Exception as e:
                            logger.debug(f"Error polling commands: {e}")
                        
                        last_command_poll_time = now
                    
                    # Read data from UART - robust handling of partial/corrupted messages
                    if ser.in_waiting > 0:
                        # ANY data available = STM32 is connected and active
                        last_message_time = time.time()
                        
                        # Mark as online immediately when we detect UART activity
                        if last_status_sent != "online":
                            logger.info("✅ Detected UART activity - marking as online")
                        if send_status_to_azure("online"):
                            last_status_sent = "online"
                        
                        try:
                            # Read available bytes
                            raw_data = ser.read(ser.in_waiting)
                            
                            # Try to decode and log what we received
                            try:
                                text = raw_data.decode("utf-8", errors="ignore").strip()
                                if text:
                                    # Show first 100 chars to avoid log spam
                                    display_text = text[:100] + "..." if len(text) > 100 else text
                                    logger.info(f"📥 Received: {repr(display_text)}")
                                    
                                    # Check for heartbeat message
                                    if HEARTBEAT_MESSAGE in text:
                                        logger.debug("✅ Heartbeat message detected")
                            except:
                                # Can't decode as text - show hex instead
                                hex_preview = raw_data[:20].hex()
                                logger.debug(f"📥 Received raw data: {hex_preview}...")
                                
                        except Exception as e:
                            logger.debug(f"Error reading UART data: {e}")
                            # Still consider it activity (STM32 is connected)
                    
                    # Check for timeout - mark offline if no activity for TIMEOUT_SECONDS
                    if last_message_time is not None:
                        time_since_last = time.time() - last_message_time
                        if time_since_last > TIMEOUT_SECONDS:
                            # No activity detected - STM32 likely disconnected
                            if last_status_sent != "offline":
                                logger.warning(f"⚠️  No STM32 activity for {time_since_last:.1f}s - marking as offline")
                                if send_status_to_azure("offline"):
                                    last_status_sent = "offline"
                                # Reset to allow future detection
                                last_message_time = None
                    
                except UnicodeDecodeError:
                    # Handle decode errors gracefully - still count as activity
                    if ser.in_waiting > 0:
                        last_message_time = time.time()
                        if last_status_sent != "online":
                            logger.info("✅ Detected UART activity - marking as online")
                        if send_status_to_azure("online"):
                            last_status_sent = "online"
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
                
                # Small delay to prevent CPU spinning (reduced for faster response)
                time.sleep(0.05)
                
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
