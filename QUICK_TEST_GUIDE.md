# Quick Test Guide - Fix "Unknown" Status

## Why You See "Unknown"

The status shows **"Unknown"** because:
- ✅ The Pi hasn't sent a POST request yet to mark itself as online
- ✅ No data exists in Table Storage for `gatewayId="pi5-main"`
- ✅ This is **normal** - status will be "Unknown" until the Pi checks in

---

## Solution: Mark Pi as Online

You need to send a POST request to mark the Pi as online. Here's how:

### Option 1: Use PowerShell Script (Easiest)

Run this in PowerShell:

```powershell
.\test_gateway_status.ps1
```

This will:
1. Mark the Pi as "online" in Table Storage
2. Check the status
3. Tell you to check the dashboard

---

### Option 2: Manual PowerShell Command

```powershell
Invoke-RestMethod -Uri "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"gatewayId":"pi5-main","status":"online"}'
```

---

### Option 3: From Your Pi (if connected)

SSH into your Pi and run:

```bash
curl -X POST "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status" \
  -H "Content-Type: application/json" \
  -d '{"gatewayId":"pi5-main","status":"online"}'
```

---

## After Sending POST Request

1. **Wait 8 seconds** (polling interval)
2. **Refresh or watch the dashboard**
3. **Status should change**: "Unknown" → "Online" ✅

---

## Test the Full Flow

### Step 1: Mark as Online
```powershell
Invoke-RestMethod -Uri "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"gatewayId":"pi5-main","status":"online"}'
```

### Step 2: Verify Status (GET)
```powershell
Invoke-RestMethod -Uri "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status?gatewayId=pi5-main"
```

**Expected Response:**
```json
{
  "gatewayId": "pi5-main",
  "status": "online",
  "lastUpdated": "2024-11-30T02:29:45.123Z"
}
```

### Step 3: Watch Dashboard
- Open: https://blue-desert-0c2a27e1e.3.azurestaticapps.net
- Status should show "Online" within 8 seconds
- Should display "Last updated: just now"

---

## Troubleshooting

### If Status Still Shows "Unknown" After POST:

1. **Check API Response**
   - Did POST request return 200 OK?
   - Did you get a response with `"status": "online"`?

2. **Check Browser Console**
   - Press F12 → Console tab
   - Look for errors from the frontend hook
   - Should see successful GET requests every 8 seconds

3. **Verify Environment Variable**
   - Azure Portal → Static Web App → Settings → Environment variables
   - Confirm `TABLES_CONNECTION_STRING` is set
   - Wait 2-3 minutes if you just added it

4. **Check Table Storage**
   - Go to Azure Portal → Storage Account → Tables
   - Look for table named `GatewayStatus`
   - Should have an entity with PartitionKey="gateways", RowKey="pi5-main"

### If You Get Errors:

**"TABLES_CONNECTION_STRING environment variable is not set"**
- → Set the environment variable in Azure Portal (we did this)
- → Wait 2-3 minutes for app restart

**"Table does not exist"**
- → First POST request will create the table automatically
- → Retry the POST request

**400 Bad Request: "gatewayId query parameter is required"**
- → You're accessing the GET endpoint without query parameter
- → Use: `/api/gateway-status?gatewayId=pi5-main`

---

## Expected Behavior

### Before POST:
- Status: "Unknown" ✅ (normal - no data yet)

### After POST:
- Status: "Online" ✅
- Shows: "Last updated: just now" or "X seconds ago"
- Green dot with glow effect

### After 8 Seconds:
- Dashboard polls API
- Status updates to "Online" (if POST was successful)

---

## Next Steps

1. **Run the test script** or send POST request manually
2. **Watch dashboard** - status should change within 8 seconds
3. **From your Pi**: Set up a script to POST every 60 seconds to keep status updated

The Pi needs to continuously send POST requests to maintain "Online" status. The dashboard will automatically update as the Pi sends heartbeats.

