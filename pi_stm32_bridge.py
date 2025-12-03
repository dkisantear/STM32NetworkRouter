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
# GPIO14/15 typically map to /dev/serial0 (symlink) or /dev/ttyAMA0
# Try /dev/serial0 first (works on most Pi models), fallback to /dev/ttyAMA0
UART_DEVICE = "/dev/serial0"  # GPIO14/15 UART (symlink, works on most Pi models)
UART_BAUDRATE = 38400  # Must match STM32 baud rate
API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status"
COMMAND_API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-command"
MASTER_DEVICE_ID = "stm32-master"  # Master STM32 board
SLAVE_DEVICE_ID = "stm32-main"  # Slave STM32 board (if still connected)
TIMEOUT_SECONDS = 30  # If no UART message received in this time, mark as offline (increased for Master board)
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

def send_status_to_azure(device_id, status):
    """Send STM32 status to Azure Function"""
    payload = {
        "deviceId": device_id,
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
        logger.info(f"✅ Status sent to Azure for {device_id}: {status}")
        return True
    except Exception as e:
        logger.error(f"❌ Failed to send status to Azure for {device_id}: {e}")
        return False

def get_pending_commands():
    """Poll Azure for pending commands for Master board"""
    try:
        response = requests.get(
            COMMAND_API_URL,
            params={"deviceId": MASTER_DEVICE_ID},
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
        logger.info(f"📤 Sent command to Master STM32: {value} (mode: {mode})")
        
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
    logger.info(f"   UART Device: {UART_DEVICE} (Master STM32 UART2)")
    logger.info(f"   Baudrate: {UART_BAUDRATE}")
    logger.info(f"   API URL: {API_URL}")
    logger.info(f"   Master Device ID: {MASTER_DEVICE_ID}")
    logger.info(f"   Log File: {LOG_FILE}")
    logger.info("=" * 60)
    
    ser = None
    last_message_time = None
    last_master_status_sent = None
    last_heartbeat_time = time.time()
    last_command_poll_time = time.time()
    reconnect_delay = 5  # Seconds to wait before reconnecting
    last_received_value = None  # Track last value received from Master board
    
    while True:  # Outer loop for auto-recovery
        try:
            # Try to open serial port (with retry logic and device fallback)
            if ser is None or not ser.is_open:
                uart_devices = [UART_DEVICE, "/dev/ttyAMA0", "/dev/ttyS0"]
                device_opened = False
                
                for device in uart_devices:
                    try:
                        logger.info(f"📡 Trying to open {device}...")
                        ser = serial.Serial(
                            port=device,
                            baudrate=UART_BAUDRATE,
                            timeout=1.0,
                            bytesize=serial.EIGHTBITS,
                            parity=serial.PARITY_NONE,
                            stopbits=serial.STOPBITS_ONE
                        )
                        logger.info(f"✅ Serial port opened successfully on {device}!")
                        device_opened = True
                        break
                    except serial.SerialException as e:
                        logger.debug(f"   Failed to open {device}: {e}")
                        continue
                
                if not device_opened:
                    logger.error(f"❌ Failed to open any UART device. Tried: {uart_devices}")
                    logger.info("💡 Troubleshooting:")
                    logger.info("   1. Check UART is enabled: sudo raspi-config → Interface Options → Serial Port")
                    logger.info("   2. Verify device exists: ls -l /dev/serial0 /dev/ttyAMA0")
                    logger.info("   3. Check permissions: sudo usermod -a -G dialout $USER")
                    logger.info(f"⏳ Retrying in {reconnect_delay} seconds...")
                    # Send offline status if we can't open UART
                    if last_master_status_sent != "offline":
                        send_status_to_azure(MASTER_DEVICE_ID, "offline")
                        last_master_status_sent = "offline"
                    time.sleep(reconnect_delay)
                    continue
                
                # Send initial "online" status for Master board
                if send_status_to_azure(MASTER_DEVICE_ID, "online"):
                    last_master_status_sent = "online"
                    logger.info("✅ Initial Master board status sent!")
                
                # Initialize last_message_time so we can detect if messages stop
                # Use a time slightly in the past so we don't immediately timeout
                # For Master board, we'll keep it online initially even without messages
                last_message_time = time.time() - (TIMEOUT_SECONDS - 10)  # Allow grace period before timeout
                logger.info(f"⏱️  Timeout set to {TIMEOUT_SECONDS} seconds - Master board will stay online if connected")
            
            logger.info("👂 Listening for STM32 messages...")
            
            # Main read loop
            while True:
                try:
                    now = time.time()
                    
                    # Poll for pending commands from Azure
                    if now - last_command_poll_time > COMMAND_POLL_INTERVAL:
                        commands = get_pending_commands()
                        for cmd in commands:
                            command_id = cmd.get("commandId")
                            value = cmd.get("value")
                            mode = cmd.get("mode", "uart")
                            
                            logger.info(f"📨 Processing command: value={value} mode={mode}")
                            if send_command_to_stm32(ser, value, mode):
                                mark_command_sent(command_id)
                                logger.info(f"✅ Command {command_id} sent successfully to Master board")
                            else:
                                logger.error(f"❌ Failed to send command {command_id}")
                        last_command_poll_time = now
                    
                    # Send periodic heartbeat status (every 30 seconds) even if no UART messages
                    if now - last_heartbeat_time > 30:
                        if last_master_status_sent != "online":
                            logger.info("💓 Periodic heartbeat - sending Master board online status")
                            if send_status_to_azure(MASTER_DEVICE_ID, "online"):
                                last_master_status_sent = "online"
                        last_heartbeat_time = now
                    
                    # Read from UART - use same method as working test script (readline)
                    try:
                        # Use readline() which works in test script
                        # This blocks until a complete line is received (with timeout)
                        line = ser.readline().decode("utf-8", errors="ignore").strip()
                        
                        if line:
                            logger.info(f"📥 Received from Master: {repr(line)}")
                            
                            # Update last_message_time for ANY received message
                            # This proves UART is working
                            last_message_time = time.time()
                            
                            # Try to parse the received value (could be DIP switch value or heartbeat)
                            try:
                                # Check if it's a numeric value (DIP switch reading)
                                received_value = int(line.strip())
                                if 0 <= received_value <= 16:
                                    last_received_value = received_value
                                    logger.info(f"📊 Master board DIP switch value: {received_value}")
                            except ValueError:
                                # Not a number, could be heartbeat or other message
                                pass
                            
                            # Check if it's the expected heartbeat message
                            if HEARTBEAT_MESSAGE in line:
                                # Send "online" status when we receive heartbeat
                                if last_master_status_sent != "online":
                                    logger.info(f"✅ Received heartbeat - updating Master status to online")
                                if send_status_to_azure(MASTER_DEVICE_ID, "online"):
                                    last_master_status_sent = "online"
                            else:
                                # Received other message - UART is working, mark as online
                                if last_master_status_sent != "online":
                                    logger.info(f"📡 Receiving UART data from Master - marking online")
                                if send_status_to_azure(MASTER_DEVICE_ID, "online"):
                                    last_master_status_sent = "online"
                    
                    except OSError as e:
                        # Handle "device reports readiness but returned no data" error
                        if "returned no data" in str(e).lower():
                            # This is a common UART quirk - ignore it and continue
                            pass
                        else:
                            raise  # Re-raise other OSErrors
                    
                    # Check for timeout - if no message received in TIMEOUT_SECONDS, mark as offline
                    if last_message_time is not None:
                        time_since_last = time.time() - last_message_time
                        # Log timeout warning at 10 seconds (before actually timing out)
                        if 10 <= time_since_last <= 10.5:
                            logger.warning(f"⚠️  No STM32 message for {time_since_last:.1f}s...")
                        if time_since_last > TIMEOUT_SECONDS:
                            if last_master_status_sent != "offline":
                                logger.warning(f"⚠️  No Master STM32 message for {time_since_last:.1f}s, marking as offline")
                                if send_status_to_azure(MASTER_DEVICE_ID, "offline"):
                                    last_master_status_sent = "offline"
                            # Reset timeout check to avoid spamming logs
                            last_message_time = time.time() - TIMEOUT_SECONDS + 5
                    
                except UnicodeDecodeError:
                    # Handle garbage/partial data - ignore and continue
                    pass
                except serial.SerialException as e:
                    error_msg = str(e).lower()
                    if "returned no data" in error_msg:
                        # Common UART quirk - ignore
                        pass
                    else:
                        logger.error(f"❌ Serial port error during read: {e}")
                        # Close port and break to reconnect
                        try:
                            ser.close()
                        except:
                            pass
                        ser = None
                        break  # Break inner loop, reconnect in outer loop
                except OSError as e:
                    error_msg = str(e).lower()
                    if "returned no data" in error_msg:
                        # Common UART quirk - ignore
                        pass
                    else:
                        logger.error(f"❌ OS error: {e}")
                except Exception as e:
                    error_msg = str(e).lower()
                    if "returned no data" in error_msg:
                        # Common UART quirk - ignore
                        pass
                    else:
                        logger.error(f"❌ Error processing UART data: {e}")
                    # Continue running - don't crash on errors
                
                # Small delay to prevent CPU spinning
                time.sleep(0.1)
                
        except KeyboardInterrupt:
            logger.info("🛑 Shutting down...")
            # Send offline status before exiting
            try:
                send_status_to_azure(MASTER_DEVICE_ID, "offline")
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

