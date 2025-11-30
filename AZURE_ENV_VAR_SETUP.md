# Azure Static Web Apps - Environment Variable Setup

## ✅ YES - Use "Environment variables"!

In Azure Static Web Apps, environment variables are configured in **Settings → Environment variables**.

---

## Step-by-Step Instructions

### 1. Navigate to Your Static Web App
- Go to: https://portal.azure.com
- Search for: `blue-desert` or your Static Web App name
- Click on it to open

### 2. Find Environment Variables
- **Left sidebar** → Look under **"Settings"** section
- Click **"Environment variables"** (or "Configuration" → "Environment variables")
- You should see a list of existing environment variables (or it might be empty)

### 3. Add New Environment Variable
- Click **"+ Add"** button (usually at the top)
- A form will appear

### 4. Enter the Details
- **Name**: `TABLES_CONNECTION_STRING`
  - Must be exactly this (case-sensitive)
  
- **Value**: Paste your connection string
  - Get this from your Storage Account (see below)

### 5. Save
- Click **"Apply"** or **"Save"** button
- Wait 1-2 minutes for Azure to restart your app

---

## How to Get Your Connection String

### From Storage Account:

1. **Go to your Storage Account** (`latencynet storage`)
   - In Azure Portal, search for your storage account

2. **Access Keys**
   - Left sidebar → **"Access keys"** (under "Security + networking")

3. **Copy Connection String**
   - Find the **"Connection string"** row
   - Click **"Show"** next to "key1"
   - Copy the **entire connection string**
   - It looks like:
     ```
     DefaultEndpointsProtocol=https;AccountName=latencynetstorage;AccountKey=abc123...;EndpointSuffix=core.windows.net
     ```

4. **Paste into Environment Variable**
   - Paste this entire string as the **Value** for `TABLES_CONNECTION_STRING`

---

## Visual Path

```
Azure Portal
└── Static Web App (blue-desert-0c2a27e1e)
    └── Left Sidebar
        └── Settings
            └── Environment variables  ← CLICK HERE
                └── + Add  ← CLICK THIS
                    ├── Name: TABLES_CONNECTION_STRING
                    └── Value: [paste connection string]
                        └── Apply/Save
```

---

## Alternative: If You Don't See "Environment variables"

Sometimes it's under:

**Option A:**
- Settings → **Configuration** → **Environment variables** tab

**Option B:**
- **Configuration** (directly in sidebar) → **Environment variables**

**Option C:**
- **Application settings** (old name, same thing)

---

## Quick Test After Setup

Wait 1-2 minutes, then test:

```bash
curl -X POST "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status" \
  -H "Content-Type: application/json" \
  -d '{"gatewayId":"pi5-main","status":"online"}'
```

If you get an error about "TABLES_CONNECTION_STRING not set", wait another minute and try again (app is restarting).

---

## Using Azure CLI (Alternative Method)

If you can't find it in the portal, use Azure CLI:

```bash
az staticwebapp appsettings set \
  --name blue-desert-0c2a27e1e \
  --setting-names TABLES_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=latencynetstorage;AccountKey=...;EndpointSuffix=core.windows.net"
```

Replace the connection string with your actual one.

---

## Summary

✅ **Look for**: Settings → Environment variables  
✅ **Name**: `TABLES_CONNECTION_STRING`  
✅ **Value**: Your Storage Account connection string (from Access keys)  
✅ **Click**: Apply/Save  
✅ **Wait**: 1-2 minutes for app restart

That's it!

