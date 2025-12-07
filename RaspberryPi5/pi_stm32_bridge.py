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
UART_DEVICE = "/dev/ttyAMA0"
UART_BAUDRATE = 38400
API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status"
COMMAND_API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-command"
DEVICE_ID = "stm32-master"
TIMEOUT_SECONDS = 10
HEARTBEAT_MESSAGE = "STM32_ALIVE"
COMMAND_POLL_INTERVAL = 2

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
        logger.info(f"Status sent to Azure: {status}")
        return True
    except Exception as e:
        logger.error(f"Failed to send status to Azure: {e}")
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
    """Send command to Master STM32 via UART2"""
    if not ser or not ser.is_open:
        logger.error("Cannot send command: serial port not open")
        return False
    
    try:
        command = f"{value}\n"
        ser.write(command.encode('utf-8'))
        logger.info(f"Sent command to Master STM32: value={value} mode={mode}")
        time.sleep(0.05)
        return True
    except Exception as e:
        logger.error(f"Failed to send command to STM32: {e}")
        return False

def main():
    """Main loop - reads UART and forwards to Azure with error recovery"""
    logger.info("=" * 60)
    logger.info("STM32 UART Bridge Starting")
    logger.info(f"UART Device: {UART_DEVICE}")
    logger.info(f"Baudrate: {UART_BAUDRATE}")
    logger.info(f"API URL: {API_URL}")
    logger.info(f"Device ID: {DEVICE_ID}")
    logger.info(f"Log File: {LOG_FILE}")
    logger.info("=" * 60)
    
    ser = None
    last_message_time = None
    last_status_sent = None
    last_command_poll_time = time.time()
    processed_command_ids = set()
    reconnect_delay = 5
    
    while True:
        try:
            if ser is None or not ser.is_open:
                try:
                    logger.info(f"Opening {UART_DEVICE}...")
                    ser = serial.Serial(
                        port=UART_DEVICE,
                        baudrate=UART_BAUDRATE,
                        timeout=0.5,
                        bytesize=serial.EIGHTBITS,
                        parity=serial.PARITY_NONE,
                        stopbits=serial.STOPBITS_ONE,
                        xonxoff=False,
                        rtscts=False,
                        dsrdtr=False
                    )
                    ser.reset_input_buffer()
                    ser.reset_output_buffer()
                    logger.info("Serial port opened successfully")
                    
                    if send_status_to_azure("offline"):
                        last_status_sent = "offline"
                        logger.info("Initial status sent: offline (waiting for STM32 heartbeat...)")
                    
                except serial.SerialException as e:
                    logger.error(f"Failed to open serial port: {e}")
                    logger.info(f"Retrying in {reconnect_delay} seconds...")
                    if last_status_sent != "offline":
                        send_status_to_azure("offline")
                        last_status_sent = "offline"
                    time.sleep(reconnect_delay)
                    continue
            
            logger.info("Listening for STM32 messages...")
            
            while True:
                try:
                    now = time.time()
                    
                    if now - last_command_poll_time > COMMAND_POLL_INTERVAL:
                        try:
                            commands = get_pending_commands()
                            
                            for cmd in commands:
                                command_id = cmd.get("commandId")
                                value = cmd.get("value")
                                mode = cmd.get("mode", "uart")
                                
                                if command_id in processed_command_ids:
                                    continue
                                
                                logger.info(f"Processing command from frontend: value={value} mode={mode}")
                                
                                if send_command_to_stm32(ser, value, mode):
                                    if mark_command_sent(command_id):
                                        logger.info(f"Command {command_id} sent and marked as sent")
                                        processed_command_ids.add(command_id)
                                    else:
                                        if command_id not in processed_command_ids:
                                            logger.warning(f"Command {command_id} sent but failed to mark in Azure")
                                            processed_command_ids.add(command_id)
                                else:
                                    logger.error(f"Failed to send command {command_id} to STM32")
                        except Exception as e:
                            logger.debug(f"Error polling commands: {e}")
                        
                        last_command_poll_time = now
                    
                    if ser.in_waiting > 0:
                        last_message_time = time.time()
                        
                        if last_status_sent != "online":
                            logger.info("Detected UART activity - marking as online")
                        if send_status_to_azure("online"):
                            last_status_sent = "online"
                        
                        try:
                            raw_data = ser.read(ser.in_waiting)
                            
                            try:
                                text = raw_data.decode("utf-8", errors="ignore").strip()
                                if text:
                                    display_text = text[:100] + "..." if len(text) > 100 else text
                                    logger.info(f"Received: {repr(display_text)}")
                                    
                                    if HEARTBEAT_MESSAGE in text:
                                        logger.debug("Heartbeat message detected")
                            except:
                                hex_preview = raw_data[:20].hex()
                                logger.debug(f"Received raw data: {hex_preview}...")
                                
                        except Exception as e:
                            logger.debug(f"Error reading UART data: {e}")
                    
                    if last_message_time is not None:
                        time_since_last = time.time() - last_message_time
                        if time_since_last > TIMEOUT_SECONDS:
                            if last_status_sent != "offline":
                                logger.warning(f"No STM32 activity for {time_since_last:.1f}s - marking as offline")
                                if send_status_to_azure("offline"):
                                    last_status_sent = "offline"
                                last_message_time = None
                    
                except UnicodeDecodeError:
                    if ser.in_waiting > 0:
                        last_message_time = time.time()
                        if last_status_sent != "online":
                            logger.info("Detected UART activity - marking as online")
                        if send_status_to_azure("online"):
                            last_status_sent = "online"
                except serial.SerialException as e:
                    logger.error(f"Serial port error during read: {e}")
                    try:
                        ser.close()
                    except:
                        pass
                    ser = None
                    break
                except Exception as e:
                    logger.error(f"Error processing UART data: {e}")
                
                time.sleep(0.05)
                
        except KeyboardInterrupt:
            logger.info("Shutting down...")
            try:
                send_status_to_azure("offline")
            except:
                pass
            break
            
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            logger.info("Restarting in 5 seconds...")
            try:
                if ser and ser.is_open:
                    ser.close()
            except:
                pass
            ser = None
            time.sleep(5)
        
        finally:
            if ser and ser.is_open:
                try:
                    ser.close()
                    logger.info("Serial port closed")
                except:
                    pass

if __name__ == "__main__":
    main()

