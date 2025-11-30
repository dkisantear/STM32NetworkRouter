# Azure Table Storage Implementation Plan

## Current State
- ✅ `api/gateway-status/index.js` - Uses in-memory storage (instance isolation issue)
- ✅ `src/hooks/useGatewayStatus.ts` - Polls `/api/gateway-status` every 10s
- ✅ `src/components/StatusPill.tsx` - Shows Online/Offline status
- ✅ No `gateway-heartbeat` folder (already removed)

## Changes to Make

### 1. Backend (API)
- ✅ Add `@azure/data-tables` to `api/package.json`
- ✅ Rewrite `api/gateway-status/index.js` to use Azure Table Storage
  - GET: `/api/gateway-status?gatewayId=pi5-main` → Read from Table Storage
  - POST: `/api/gateway-status` → Upsert to Table Storage
  - Use PartitionKey="gateways", RowKey=gatewayId
- ✅ Keep `api/gateway-status/function.json` as-is (already correct)

### 2. Frontend
- ✅ Update `src/hooks/useGatewayStatus.ts`:
  - Poll `/api/gateway-status?gatewayId=pi5-main`
  - Handle new response format: `{gatewayId, status, lastUpdated}`
  - Support "online" | "offline" | "unknown" status
  - Remove sticky online logic (no longer needed with shared storage)
- ✅ Update `src/components/StatusPill.tsx`:
  - Show "Online" / "Offline" / "Unknown"
  - Display "Last updated: <time>" instead of "Last seen"

### 3. Documentation
- ✅ Add Pi usage example to README.md

### 4. Verification
- ✅ Check no old heartbeat code exists
- ✅ Ensure npm run build works
- ✅ Verify function.json is valid JSON

## Environment Variable Required
- `TABLES_CONNECTION_STRING` - Must be set in Azure Static Web App configuration

