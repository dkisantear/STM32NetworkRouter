# Files Changed - Azure Table Storage Implementation

## Summary

Replaced in-memory gateway heartbeat system with Azure Table Storage for reliable, instant status tracking across all Azure Functions instances.

---

## Files Changed (7 files + 2 documentation)

### Backend API (3 files)

1. **`api/package.json`**
   - ✅ Added: `"@azure/data-tables": "^13.2.2"` dependency

2. **`api/gateway-status/index.js`**
   - ✅ COMPLETELY REWRITTEN
   - Removed: In-memory `let lastSeen = null` storage
   - Added: Azure Table Storage integration
   - GET: Reads from Table Storage using `gatewayId` query parameter
   - POST: Upserts to Table Storage
   - Error handling for missing connection string

3. **`api/gateway-status/function.json`**
   - ✅ NO CHANGES (already valid JSON with GET/POST support)

### Frontend (4 files)

4. **`src/hooks/useGatewayStatus.ts`**
   - ✅ COMPLETELY REWRITTEN
   - Changed: Polls `/api/gateway-status?gatewayId=pi5-main` (was `/api/gateway-status`)
   - Changed: Response format now `{gatewayId, status, lastUpdated}` (was `{status, lastSeen, msSinceLastSeen}`)
   - Changed: Supports "unknown" status (in addition to online/offline)
   - Removed: Sticky online logic (no longer needed with shared storage)
   - Changed: Polling interval 10s → 8s

5. **`src/components/StatusPill.tsx`**
   - ✅ UPDATED
   - Changed: Shows "Last updated: <time>" (was "Last seen: <time>")
   - Added: Support for "Unknown" status
   - Added: Error state display ("Error connecting to API")
   - Improved: Status color/glow logic for all states

6. **`latency-live-monitor/src/hooks/useGatewayStatus.ts`**
   - ✅ UPDATED (for consistency, matches root version)

7. **`latency-live-monitor/src/components/StatusPill.tsx`**
   - ✅ UPDATED (for consistency, matches root version)

### Documentation (2 files)

8. **`README.md`**
   - ✅ UPDATED
   - Added: "Gateway Status Tracking" section
   - Added: GET endpoint documentation
   - Added: POST endpoint documentation with curl examples
   - Added: Environment variable configuration instructions

9. **`IMPLEMENTATION_SUMMARY.md`** (new)
   - ✅ Created comprehensive implementation summary

---

## Where to Configure TABLES_CONNECTION_STRING

### Azure Portal Steps:

1. **Navigate to Static Web App**
   - Go to: https://portal.azure.com
   - Find your Static Web App (blue-desert-0c2a27e1e)

2. **Open Configuration**
   - Left sidebar → **Configuration**
   - Click **Application settings** tab

3. **Add Environment Variable**
   - Click **+ New application setting**
   - **Name**: `TABLES_CONNECTION_STRING`
   - **Value**: [Paste your connection string here]
   - Click **OK**
   - Click **Save** at the top

4. **Get Connection String**
   - Go to your Storage Account (`latencynet storage`)
   - Left sidebar → **Access keys**
   - Click **Show** next to "key1"
   - Copy the **Connection string** (full string, looks like):
     ```
     DefaultEndpointsProtocol=https;AccountName=latencynetstorage;AccountKey=abc123...;EndpointSuffix=core.windows.net
     ```

5. **Restart Required**
   - After saving, Azure Static Web App will automatically restart
   - Changes take effect within 1-2 minutes

---

## Verification

### Check if Environment Variable is Set:

You can verify in Azure Portal:
- Static Web App → Configuration → Application settings
- Look for `TABLES_CONNECTION_STRING` in the list

### Test the API:

```bash
# Test POST (from Pi)
curl -X POST "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status" \
  -H "Content-Type: application/json" \
  -d '{"gatewayId":"pi5-main","status":"online"}'

# Test GET (from browser or curl)
curl "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status?gatewayId=pi5-main"
```

---

## Build & Deploy

✅ All changes are ready to commit and push.

1. **Local build** (frontend only, API doesn't need build):
   ```bash
   npm run build
   ```

2. **Commit and push**:
   ```bash
   git add -A
   git commit -m "Implement Azure Table Storage for gateway status tracking"
   git push origin main
   ```

3. **Auto-deploy**:
   - GitHub Actions will automatically deploy
   - Takes 2-5 minutes

4. **After deployment**:
   - Configure `TABLES_CONNECTION_STRING` environment variable (if not done yet)
   - Test from Pi with curl command
   - Check dashboard for status updates

---

## No Breaking Changes

✅ All existing endpoints remain unchanged:
- `/api/ping` - Still works
- `/api/main` - Still works
- `/api/uart` - Still works
- `/api/serial` - Still works

Only `/api/gateway-status` was updated (improved with Table Storage).

