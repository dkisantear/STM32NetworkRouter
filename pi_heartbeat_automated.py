#!/usr/bin/env python3
"""
Automated Gateway Heartbeat Script for Raspberry Pi
Sends heartbeat to Azure Static Web Apps API every 60 seconds
Runs continuously in the background
"""

import requests
import time
import sys
import logging
from datetime import datetime

# Configuration
API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status"
GATEWAY_ID = "pi5-main"
HEARTBEAT_INTERVAL = 60  # seconds
MAX_RETRIES = 3
RETRY_DELAY = 5  # seconds

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/gateway-heartbeat.log'),
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
        logger.info(f"✅ Heartbeat sent successfully: {result.get('status')} (updated: {result.get('lastUpdated')})")
        return True
        
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ Failed to send heartbeat: {e}")
        return False
    except Exception as e:
        logger.error(f"❌ Unexpected error: {e}")
        return False

def main():
    """Main loop - sends heartbeat every HEARTBEAT_INTERVAL seconds"""
    logger.info("=" * 60)
    logger.info(f"🚀 Gateway Heartbeat Service Starting")
    logger.info(f"   Gateway ID: {GATEWAY_ID}")
    logger.info(f"   API URL: {API_URL}")
    logger.info(f"   Interval: {HEARTBEAT_INTERVAL} seconds")
    logger.info("=" * 60)
    
    consecutive_failures = 0
    
    while True:
        try:
            # Send heartbeat
            success = send_heartbeat()
            
            if success:
                consecutive_failures = 0
            else:
                consecutive_failures += 1
                
                # If multiple failures, wait a bit longer before retry
                if consecutive_failures >= MAX_RETRIES:
                    logger.warning(f"⚠️  {consecutive_failures} consecutive failures. Waiting {RETRY_DELAY}s before retry...")
                    time.sleep(RETRY_DELAY)
                    consecutive_failures = 0  # Reset after retry delay
                    continue
            
            # Wait for next heartbeat interval
            time.sleep(HEARTBEAT_INTERVAL)
            
        except KeyboardInterrupt:
            logger.info("🛑 Received interrupt signal. Shutting down gracefully...")
            # Send final "offline" status before exiting
            try:
                payload = {"gatewayId": GATEWAY_ID, "status": "offline"}
                requests.post(API_URL, json=payload, timeout=5)
                logger.info("📤 Sent final 'offline' status")
            except:
                pass
            break
        except Exception as e:
            logger.error(f"❌ Unexpected error in main loop: {e}")
            time.sleep(HEARTBEAT_INTERVAL)

if __name__ == "__main__":
    main()

