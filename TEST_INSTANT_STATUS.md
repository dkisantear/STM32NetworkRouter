# Testing Instant Status Updates

## ✅ Deployment Status

**Commit**: `a1a0bc6`  
**Status**: Pushed to `main` branch  
**Next**: GitHub Actions will auto-deploy (takes 2-5 minutes)

---

## 🧪 Testing Instant Status Updates

Once deployment completes (check GitHub Actions tab), we can test if status updates are instantaneous.

---

## Test 1: Mark Pi as Online (from Terminal/Browser)

### Option A: Using curl (from your computer or Pi)

```bash
curl -X POST "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status" \
  -H "Content-Type: application/json" \
  -d '{"gatewayId":"pi5-main","status":"online"}'
```

**Expected Response:**
```json
{
  "gatewayId": "pi5-main",
  "status": "online",
  "lastUpdated": "2024-11-30T01:07:25.538Z"
}
```

### Option B: Using PowerShell (from your computer)

```powershell
Invoke-RestMethod -Uri "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"gatewayId":"pi5-main","status":"online"}'
```

---

## Test 2: Check Status (GET Request)

```bash
curl "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status?gatewayId=pi5-main"
```

**Expected Response:**
```json
{
  "gatewayId": "pi5-main",
  "status": "online",
  "lastUpdated": "2024-11-30T01:07:25.538Z"
}
```

---

## Test 3: Watch Dashboard Update in Real-Time

1. **Open Dashboard**: https://blue-desert-0c2a27e1e.3.azurestaticapps.net
2. **Watch the "Raspberry Pi Gateway → Azure" card**
3. **Send POST request** (from Test 1 above)
4. **Watch status change**:
   - Should change to "Online" within **8 seconds** (polling interval)
   - Should show "Last updated: just now" or "X seconds ago"

---

## Test 4: Mark Pi as Offline

```bash
curl -X POST "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status" \
  -H "Content-Type: application/json" \
  -d '{"gatewayId":"pi5-main","status":"offline"}'
```

**Expected:**
- Dashboard should show "Offline" within 8 seconds

---

## Test 5: Check Unknown Status

If you query a gateway ID that doesn't exist:

```bash
curl "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status?gatewayId=non-existent"
```

**Expected Response:**
```json
{
  "gatewayId": "non-existent",
  "status": "unknown",
  "lastUpdated": null
}
```

---

## What to Verify

### ✅ Instant Updates (Within 8 Seconds)
- POST request succeeds
- GET request returns correct status immediately
- Dashboard updates within 8 seconds (polling interval)

### ✅ Consistency Across Requests
- Multiple GET requests return the same status (no instance isolation issues)
- Status persists across different requests

### ✅ Status Values
- `"online"` - When Pi is connected
- `"offline"` - When Pi is disconnected
- `"unknown"` - When gateway has never checked in

---

## Troubleshooting

### If Status Doesn't Update:

1. **Check Deployment**
   - Go to GitHub → Actions tab
   - Verify latest workflow run succeeded
   - Wait for deployment to complete (green checkmark)

2. **Check Environment Variable**
   - Azure Portal → Static Web App → Settings → Environment variables
   - Verify `TABLES_CONNECTION_STRING` exists and is correct
   - App needs restart after adding env var (wait 2-3 minutes)

3. **Check API Response**
   - Test GET request directly (see Test 2)
   - Check if you get valid JSON response
   - Look for error messages

4. **Check Browser Console**
   - Open dashboard in browser
   - Press F12 → Console tab
   - Look for errors or warnings

### Common Errors:

**"TABLES_CONNECTION_STRING environment variable is not set"**
- → Environment variable not configured correctly
- → Wait 2-3 minutes after setting it (app restart)

**"Table does not exist"**
- → First POST request will create the table automatically
- → This is normal, just retry

**404 or 500 errors**
- → Check if deployment completed
- → Check GitHub Actions for build errors

---

## Success Criteria

✅ POST request succeeds (200 OK)  
✅ GET request returns correct status immediately  
✅ Dashboard shows correct status within 8 seconds  
✅ Status persists across multiple requests (no flickering)  
✅ No instance isolation issues (consistent status)

---

## Next Steps

1. **Wait for deployment** (2-5 minutes)
   - Check: https://github.com/dkisantear/latency-live-monitor/actions

2. **Test POST** (mark Pi as online)
   - Use curl command from Test 1

3. **Watch dashboard** (within 8 seconds)
   - Status should change to "Online"

4. **Test POST again** (mark Pi as offline)
   - Status should change to "Offline" within 8 seconds

5. **Verify consistency**
   - Send multiple GET requests
   - All should return the same status (proves Table Storage works!)

---

## Expected Timeline

- **0 seconds**: Send POST request
- **< 1 second**: API receives request, writes to Table Storage
- **0-8 seconds**: Frontend polls API (random time within polling interval)
- **8 seconds max**: Dashboard updates with new status

**Result**: Status updates are effectively instant (within 8 seconds max, usually faster)

