#!/usr/bin/env python3
"""
Simple script to test sending heartbeats to Azure Static Web App
Run this on your Raspberry Pi to verify connection works
"""

import requests
import time
from datetime import datetime

# Your Azure Static Web App URL
API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status"

def send_heartbeat():
    """Send a single heartbeat"""
    try:
        response = requests.post(API_URL, timeout=5)
        response.raise_for_status()
        data = response.json()
        print(f"[{datetime.now().strftime('%H:%M:%S')}] ✅ Heartbeat sent: {data}")
        return True
    except requests.exceptions.RequestException as e:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] ❌ Error: {e}")
        return False

def check_status():
    """Check current gateway status"""
    try:
        response = requests.get(API_URL, timeout=5)
        response.raise_for_status()
        data = response.json()
        connected = "🟢 Connected" if data.get('connected') else "🔴 Disconnected"
        last_seen = data.get('lastSeen', 'Never')
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Status: {connected} | Last seen: {last_seen}")
        return data
    except requests.exceptions.RequestException as e:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] ❌ Error checking status: {e}")
        return None

if __name__ == "__main__":
    print("=" * 60)
    print("Raspberry Pi Gateway Heartbeat Test")
    print("=" * 60)
    print(f"API URL: {API_URL}\n")
    
    # Check initial status
    print("1. Checking initial status...")
    check_status()
    print()
    
    # Send a heartbeat
    print("2. Sending heartbeat...")
    if send_heartbeat():
        print()
        time.sleep(1)  # Wait a moment
        print("3. Checking status after heartbeat...")
        check_status()
    
    print("\n" + "=" * 60)
    print("Test complete! Check your dashboard to see if it shows 'Connected'")
    print("=" * 60)

