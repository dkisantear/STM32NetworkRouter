# Azure Table Storage Implementation - Summary

## ✅ Files Changed

### Backend (API)

1. **`api/package.json`**
   - Added dependency: `"@azure/data-tables": "^13.2.2"`

2. **`api/gateway-status/index.js`** (COMPLETELY REWRITTEN)
   - Replaced in-memory storage with Azure Table Storage
   - GET: Reads from Table Storage using `gatewayId` query parameter
   - POST: Upserts to Table Storage with gateway status
   - Uses PartitionKey="gateways", RowKey=gatewayId
   - Table name: "GatewayStatus"
   - Connection string from: `TABLES_CONNECTION_STRING` environment variable

3. **`api/gateway-status/function.json`** (NO CHANGES - Already valid)
   - Valid JSON, supports GET and POST methods

### Frontend

4. **`src/hooks/useGatewayStatus.ts`** (COMPLETELY REWRITTEN)
   - Now polls: `/api/gateway-status?gatewayId=pi5-main`
   - Handles new response format: `{gatewayId, status, lastUpdated}`
   - Supports: "online" | "offline" | "unknown" status
   - Removed sticky online logic (no longer needed with shared storage)
   - Polling interval: 8 seconds

5. **`src/components/StatusPill.tsx`** (UPDATED)
   - Shows: "Online" / "Offline" / "Unknown" / "Checking status..." / "Error connecting to API"
   - Displays: "Last updated: <time>" instead of "Last seen"
   - Handles all status states gracefully

### Documentation

6. **`README.md`** (UPDATED)
   - Added Gateway Status Tracking section
   - Added GET and POST examples with curl
   - Added environment variable configuration instructions

### Consistency Updates (latency-live-monitor folder)

7. **`latency-live-monitor/src/hooks/useGatewayStatus.ts`** - Updated to match root
8. **`latency-live-monitor/src/components/StatusPill.tsx`** - Updated to match root

---

## 🔧 Configuration Required

### Azure Static Web App Environment Variable

**You MUST configure this in Azure Portal:**

1. Go to: Azure Portal → Your Static Web App → **Configuration** → **Application settings**
2. Click **+ New application setting**
3. Add:
   - **Name**: `TABLES_CONNECTION_STRING`
   - **Value**: Your Azure Storage Account connection string

### How to Get the Connection String

1. Go to Azure Portal → Your Storage Account (`latencynet storage`)
2. Click **Access keys** (in left sidebar)
3. Click **Show** next to "key1" connection string
4. Copy the entire connection string (looks like):
   ```
   DefaultEndpointsProtocol=https;AccountName=latencynetstorage;AccountKey=...;EndpointSuffix=core.windows.net
   ```
5. Paste into the `TABLES_CONNECTION_STRING` application setting

---

## 📊 Azure Table Storage Structure

### Table Name
- **Table**: `GatewayStatus`

### Entity Structure
- **PartitionKey**: `"gateways"` (fixed)
- **RowKey**: Gateway ID (e.g., `"pi5-main"`)
- **Properties**:
  - `status`: `"online"` or `"offline"`
  - `lastUpdated`: ISO timestamp string (e.g., `"2024-11-30T01:07:25.538Z"`)

---

## 🔄 API Endpoints

### GET /api/gateway-status?gatewayId=pi5-main

**Response (Found):**
```json
{
  "gatewayId": "pi5-main",
  "status": "online",
  "lastUpdated": "2024-11-30T01:07:25.538Z"
}
```

**Response (Not Found):**
```json
{
  "gatewayId": "pi5-main",
  "status": "unknown",
  "lastUpdated": null
}
```

### POST /api/gateway-status

**Request:**
```json
{
  "gatewayId": "pi5-main",
  "status": "online"
}
```

**Response:**
```json
{
  "gatewayId": "pi5-main",
  "status": "online",
  "lastUpdated": "2024-11-30T01:07:25.538Z"
}
```

---

## ✅ Verification Checklist

- ✅ No `gateway-heartbeat` folder exists (already removed)
- ✅ `api/gateway-status/function.json` is valid JSON (no comments, no trailing commas)
- ✅ API uses plain JavaScript (no TypeScript)
- ✅ Frontend hook polls with `gatewayId` query parameter
- ✅ StatusPill handles all states (online/offline/unknown/loading/error)
- ✅ README includes Pi usage examples

---

## 🚀 Next Steps

1. **Configure Environment Variable** (Required)
   - Add `TABLES_CONNECTION_STRING` to Azure Static Web App configuration

2. **Deploy**
   - Push to `main` branch
   - GitHub Actions will auto-deploy

3. **Test from Pi**
   ```bash
   curl -X POST "https://<your-swa-url>/api/gateway-status" \
     -H "Content-Type: application/json" \
     -d '{"gatewayId":"pi5-main","status":"online"}'
   ```

4. **Verify on Dashboard**
   - Check `https://<your-swa-url>`
   - Status should show "Online" within 8 seconds

---

## 📝 Notes

- **No instance isolation issues**: All Azure Functions instances read/write to the same Table Storage
- **Instant status changes**: Status updates within 8 seconds (polling interval)
- **Reliable**: Table Storage persists state across all instances
- **Cost**: Azure Table Storage free tier covers first 10GB/month (more than enough)

