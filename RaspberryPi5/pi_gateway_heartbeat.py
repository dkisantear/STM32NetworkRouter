#!/usr/bin/env python3
"""
Pi Gateway Heartbeat - Sends status to Azure for frontend
Sends heartbeat every 30 seconds to keep Pi status visible on frontend
"""

import requests
import time
import sys
import logging
import os

# Configuration
API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status"
GATEWAY_ID = "pi5-main"
HEARTBEAT_INTERVAL = 30
MAX_RETRIES = 3
RETRY_DELAY = 5

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
    """Send heartbeat POST request to API"""
    payload = {
        "gatewayId": GATEWAY_ID,
        "status": "online"
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
        logger.info(f"Heartbeat sent: {result.get('status')} (updated: {result.get('lastUpdated')})")
        return True
        
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to send heartbeat: {e}")
        return False
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return False

def send_offline():
    """Send offline status before shutdown"""
    payload = {
        "gatewayId": GATEWAY_ID,
        "status": "offline"
    }
    
    try:
        response = requests.post(
            API_URL,
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=5
        )
        logger.info("Offline status sent")
    except:
        logger.warning("Failed to send offline status (non-critical)")

def main():
    """Main loop - sends heartbeat every HEARTBEAT_INTERVAL seconds"""
    logger.info("=" * 60)
    logger.info("Pi Gateway Heartbeat Starting")
    logger.info(f"Gateway ID: {GATEWAY_ID}")
    logger.info(f"API URL: {API_URL}")
    logger.info(f"Interval: {HEARTBEAT_INTERVAL} seconds")
    logger.info(f"Log File: {LOG_FILE}")
    logger.info("=" * 60)
    
    send_heartbeat()
    
    try:
        while True:
            time.sleep(HEARTBEAT_INTERVAL)
            
            success = False
            for attempt in range(MAX_RETRIES):
                if send_heartbeat():
                    success = True
                    break
                if attempt < MAX_RETRIES - 1:
                    logger.warning(f"Retry {attempt + 1}/{MAX_RETRIES} in {RETRY_DELAY}s...")
                    time.sleep(RETRY_DELAY)
            
            if not success:
                logger.error(f"Failed to send heartbeat after {MAX_RETRIES} attempts")
                
    except KeyboardInterrupt:
        logger.info("Shutting down...")
        send_offline()
        sys.exit(0)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        send_offline()
        sys.exit(1)

if __name__ == "__main__":
    main()

