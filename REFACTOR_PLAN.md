# 🔧 Repository Refactor Plan

## Step 1: Analysis Summary

### Repository Structure

**Root Level:**
- `api/` - Azure Functions (active)
- `src/` - Frontend source (active)
- `latency-live-monitor/` - Duplicate structure (needs cleanup)
- `.github/workflows/` - Azure Static Web Apps CI/CD
- Many documentation/setup files (to archive)

**API Functions:**
- ✅ `api/gateway-status/` - EXISTS (needs format update)
- ✅ `api/ping/` - Valid function
- ✅ `api/main/` - Valid function
- ✅ `api/uart/` - Valid function
- ✅ `api/serial/` - Valid function
- ❌ `gateway-heartbeat/` - DOES NOT EXIST (already removed)

**Frontend:**
- `src/hooks/useGatewayStatus.ts` - EXISTS (needs fix)
- `src/components/StatusPill.tsx` - EXISTS (works with hook)

**Workflow Configuration:**
- `app_location: "/"` - Builds from repo root ✅
- `api_location: "api"` - Uses root `api/` folder ✅
- `output_location: "dist"` - Builds to root `dist/` ✅

### Issues Found

1. **Frontend Error**: Hook checks for `json.error || json.ok === false` but API returns `{connected: false, lastSeen: null}` which is valid, not an error
2. **API Format Mismatch**: API returns `connected` but should match user's spec format
3. **Duplicate Structures**: `latency-live-monitor/` folder duplicates root structure
4. **Documentation Clutter**: Many setup/docs files in root

---

## Step 2: Implementation Plan

### Files to KEEP:

✅ **Core Structure:**
- `api/` (root) - Azure Functions
- `src/` (root) - Frontend source
- `.github/workflows/` - CI/CD
- Root config files: `package.json`, `vite.config.ts`, `tsconfig.json`, etc.
- Essential editor configs

✅ **API Functions:**
- `api/gateway-status/` - Single gateway endpoint (to update)
- `api/ping/` - Health check
- `api/main/`, `api/uart/`, `api/serial/` - Latency endpoints

✅ **Frontend:**
- `src/hooks/useGatewayStatus.ts` - To fix
- `src/components/StatusPill.tsx` - To verify

### Files to ARCHIVE:

📦 **Move to `/archive/`:**
- All `*_SETUP*.md`, `*_PI_*.md` documentation files
- All `*.ps1`, `*.sh` setup scripts
- `latency-live-monitor/` duplicate folder structure
- Test/setup Python scripts in root

### Files to UPDATE:

🔧 **API:**
- `api/gateway-status/index.js` - Update to match user's spec format
- `api/gateway-status/function.json` - Verify correct

🔧 **Frontend:**
- `src/hooks/useGatewayStatus.ts` - Fix error handling, match API format

---

## Step 3: API Implementation

### `/api/gateway-status` Function

**POST Request (from Pi):**
- Updates `lastSeen` timestamp
- Returns: `{ message: "Heartbeat received", lastSeen: "2024-..." }`

**GET Request (from frontend):**
- Returns: `{ status: "online" | "offline", lastSeen: string | null, msSinceLastSeen: number | null }`
- `status = "online"` if `lastSeen` within 20 seconds
- `status = "offline"` otherwise

---

## Step 4: Frontend Updates

### `useGatewayStatus` Hook

- Poll every 10 seconds (quota-efficient)
- Handle API response format correctly
- Remove error spam (don't treat `connected: false` as error)
- Return: `{ status: "online" | "offline", lastSeen: string | null, ... }`

---

## Step 5: Cleanup Steps

1. Create `/archive/` folder
2. Move all documentation/setup files to `/archive/`
3. Move `latency-live-monitor/` to `/archive/` if not needed
4. Verify no broken references
5. Ensure build works

---

## Next Steps

Will implement in order:
1. ✅ Update API function format
2. ✅ Fix frontend hook
3. ✅ Archive unused files
4. ✅ Verify build


