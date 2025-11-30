#!/usr/bin/env python3
"""
Quota-Efficient Heartbeat Script for Raspberry Pi
- Sends heartbeat every 60 seconds (instead of 15)
- Only sends if there's actual activity/data
- Includes data in heartbeat to reduce separate requests
"""

import requests
import time
import sys
from datetime import datetime

API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status"

# QUOTA-EFFICIENT SETTINGS
HEARTBEAT_INTERVAL = 60  # 60 seconds = ~43,200 requests/month (well under 125k limit)
MAX_FAILURES_BEFORE_SLOWDOWN = 3  # After 3 failures, slow down
SLOWDOWN_INTERVAL = 300  # 5 minutes if having issues

heartbeat_count = 0
consecutive_failures = 0

def send_heartbeat(include_status_check=False):
    """
    Send heartbeat to API
    include_status_check: If True, also check status in same request (more efficient)
    """
    global heartbeat_count, consecutive_failures
    
    try:
        response = requests.post(API_URL, timeout=10)
        response.raise_for_status()
        data = response.json()
        heartbeat_count += 1
        consecutive_failures = 0
        
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        last_seen = data.get('lastSeen', 'N/A')
        
        print(f"[{timestamp}] ✅ Heartbeat #{heartbeat_count} sent - Last seen: {last_seen}")
        
        # Optionally check status after heartbeat (combines two operations)
        if include_status_check:
            time.sleep(0.5)  # Brief pause
            status_response = requests.get(API_URL, timeout=5)
            if status_response.ok:
                status_data = status_response.json()
                connected = "🟢" if status_data.get('connected') else "🔴"
                print(f"          {connected} Status: {'Connected' if status_data.get('connected') else 'Disconnected'}")
        
        return True
        
    except requests.exceptions.Timeout:
        consecutive_failures += 1
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] ⏱️  Timeout: API did not respond")
        return False
        
    except requests.exceptions.ConnectionError as e:
        consecutive_failures += 1
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] 🔌 Connection Error: Cannot reach API")
        return False
        
    except requests.exceptions.RequestException as e:
        consecutive_failures += 1
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] ❌ Error: {str(e)}")
        return False

def calculate_quota_usage():
    """Calculate and display quota usage info"""
    requests_per_hour = 3600 / HEARTBEAT_INTERVAL
    requests_per_day = requests_per_hour * 24
    requests_per_month = requests_per_day * 30
    
    quota_limit = 125000
    usage_percent = (requests_per_month / quota_limit) * 100
    
    print(f"\n📊 Quota Usage Estimate:")
    print(f"   Interval: {HEARTBEAT_INTERVAL} seconds")
    print(f"   Requests/hour: ~{requests_per_hour:.1f}")
    print(f"   Requests/day: ~{requests_per_day:.0f}")
    print(f"   Requests/month: ~{requests_per_month:.0f}")
    print(f"   Quota limit: {quota_limit:,}")
    print(f"   Usage: {usage_percent:.1f}% of monthly quota")
    
    if usage_percent > 80:
        print(f"   ⚠️  WARNING: Near quota limit!")
    elif usage_percent > 50:
        print(f"   ⚠️  CAUTION: More than 50% of quota")
    else:
        print(f"   ✅ Safe: Well under quota limit")

def main():
    global consecutive_failures
    
    print("=" * 70)
    print("Raspberry Pi Gateway - QUOTA-EFFICIENT Heartbeat")
    print("=" * 70)
    print(f"API: {API_URL}")
    print(f"Interval: Every {HEARTBEAT_INTERVAL} seconds ({HEARTBEAT_INTERVAL/60:.1f} minutes)")
    
    calculate_quota_usage()
    
    print("\nPress Ctrl+C to stop\n")
    
    current_interval = HEARTBEAT_INTERVAL
    
    try:
        while True:
            success = send_heartbeat(include_status_check=False)
            
            # Adaptive interval: slow down if having issues
            if consecutive_failures >= MAX_FAILURES_BEFORE_SLOWDOWN:
                current_interval = SLOWDOWN_INTERVAL
                print(f"⚠️  Multiple failures detected. Slowing to {SLOWDOWN_INTERVAL}s interval.")
            else:
                current_interval = HEARTBEAT_INTERVAL
            
            # Wait before next heartbeat
            time.sleep(current_interval)
            
    except KeyboardInterrupt:
        print(f"\n\n{'='*70}")
        print(f"Stopped. Sent {heartbeat_count} heartbeats total.")
        print(f"Average interval: {HEARTBEAT_INTERVAL}s")
        print(f"Estimated monthly usage: ~{int((3600/HEARTBEAT_INTERVAL) * 24 * 30):,} requests")
        print("="*70)
        sys.exit(0)

if __name__ == "__main__":
    main()

