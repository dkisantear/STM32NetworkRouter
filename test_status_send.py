#!/usr/bin/env python3
"""
Quick test to verify status sending works
Run this on your Pi to test if Azure API is reachable
"""

import requests

API_URL = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status"
DEVICE_ID = "stm32-master"

print("Testing status send to Azure...")
print(f"Device ID: {DEVICE_ID}")
print(f"API URL: {API_URL}")
print()

payload = {
    "deviceId": DEVICE_ID,
    "status": "online"
}

try:
    print("📤 Sending status...")
    response = requests.post(
        API_URL,
        json=payload,
        headers={"Content-Type": "application/json"},
        timeout=10
    )
    response.raise_for_status()
    result = response.json()
    
    print("✅ SUCCESS!")
    print(f"Response: {result}")
    print()
    print("Status should now show as 'online' on frontend within 8 seconds")
    
except Exception as e:
    print(f"❌ FAILED: {e}")
    print()
    print("Check:")
    print("1. Pi has internet connection")
    print("2. API URL is correct")
    print("3. No firewall blocking requests")

