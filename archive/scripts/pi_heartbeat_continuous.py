#!/usr/bin/env python3
"""
Continuous heartbeat sender for Raspberry Pi
Sends heartbeats every 15 seconds to keep connection alive
Run this as a background service or with screen/tmux
"""

import requests
import time
import sys
from datetime import datetime

# Your Azure Static Web App URL
API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status"

# How often to send heartbeats (in seconds)
# QUOTA-EFFICIENT: 60 seconds = ~43,200 requests/month (34% of 125k limit)
HEARTBEAT_INTERVAL = 60  # 60 seconds (quota-efficient, well within 30-second timeout window)

def send_heartbeat():
    """Send a heartbeat and return success status"""
    try:
        response = requests.post(API_URL, timeout=10)
        response.raise_for_status()
        data = response.json()
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        last_seen = data.get('lastSeen', 'N/A')
        print(f"[{timestamp}] ✅ Heartbeat #{heartbeat_count} sent successfully - Last seen: {last_seen}")
        return True
    except requests.exceptions.Timeout:
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] ⏱️  Timeout: API did not respond within 10 seconds")
        return False
    except requests.exceptions.ConnectionError as e:
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] 🔌 Connection Error: Cannot reach API - {str(e)}")
        return False
    except requests.exceptions.RequestException as e:
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] ❌ Error sending heartbeat: {str(e)}")
        return False

def check_status():
    """Check current gateway status"""
    try:
        response = requests.get(API_URL, timeout=10)
        response.raise_for_status()
        data = response.json()
        connected = "🟢 Connected" if data.get('connected') else "🔴 Disconnected"
        last_seen = data.get('lastSeen', 'Never')
        return connected, last_seen
    except Exception as e:
        return "❓ Unknown", f"Error: {str(e)}"

def main():
    print("=" * 70)
    print("Raspberry Pi Gateway - Continuous Heartbeat Sender")
    print("=" * 70)
    print(f"API URL: {API_URL}")
    print(f"Interval: Every {HEARTBEAT_INTERVAL} seconds")
    print(f"Press Ctrl+C to stop\n")
    
    # Check initial status
    print("Checking initial connection status...")
    connected, last_seen = check_status()
    print(f"Status: {connected} | Last seen: {last_seen}\n")
    
    global heartbeat_count
    heartbeat_count = 0
    consecutive_failures = 0
    max_failures = 3
    
    try:
        while True:
            if send_heartbeat():
                heartbeat_count += 1
                consecutive_failures = 0
                
                # Every 10 heartbeats, check status
                if heartbeat_count % 10 == 0:
                    connected, last_seen = check_status()
                    print(f"📊 Status check: {connected} | Last seen: {last_seen}\n")
            else:
                consecutive_failures += 1
                if consecutive_failures >= max_failures:
                    print(f"\n⚠️  Warning: {consecutive_failures} consecutive failures.")
                    print("Checking internet connection...")
                    import subprocess
                    try:
                        result = subprocess.run(['ping', '-c', '1', '8.8.8.8'], 
                                              capture_output=True, timeout=5)
                        if result.returncode == 0:
                            print("✅ Internet connection is OK\n")
                        else:
                            print("❌ No internet connection\n")
                    except:
                        print("⚠️  Could not check internet connection\n")
                    consecutive_failures = 0  # Reset counter
            
            # Wait before next heartbeat
            time.sleep(HEARTBEAT_INTERVAL)
            
    except KeyboardInterrupt:
        print(f"\n\n{'='*70}")
        print(f"Stopped. Sent {heartbeat_count} heartbeats total.")
        print("Goodbye!")
        print("="*70)
        sys.exit(0)

if __name__ == "__main__":
    main()
