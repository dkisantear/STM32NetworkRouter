# Azure Static Web Apps - Environment Variable Configuration Guide

## Where to Set TABLES_CONNECTION_STRING

Azure Static Web Apps uses **"Configuration"** for environment variables. The exact location depends on the Azure Portal interface version, but here are the common paths:

---

## Method 1: Configuration → Application Settings (Most Common)

1. **Go to Azure Portal**: https://portal.azure.com
2. **Find your Static Web App**: Search for "blue-desert" or "latency"
3. **In the left sidebar**, look for one of these:
   - **"Configuration"** (under Settings section)
   - **"Environment variables"** (newer interface)
   - **"Settings" → "Configuration"**
   - **"Application settings"** (legacy name)

4. **You should see tabs or sections**:
   - **Application settings** tab (this is what you need!)
   - Or just a list of environment variables

5. **Click "+ Add" or "+ New application setting"**

6. **Enter**:
   - **Name**: `TABLES_CONNECTION_STRING`
   - **Value**: [Your connection string from Storage Account]
   
7. **Click "OK" or "Save"**

8. **IMPORTANT**: Click **"Save"** at the top of the Configuration page

---

## Method 2: If You See "Environment Variables" Instead

Some Azure Portal interfaces show "Environment variables" instead of "Application settings". They're the same thing:

1. Go to your Static Web App
2. Left sidebar → **"Configuration"** or **"Environment variables"**
3. Click **"+ Add"** or **"+ New"**
4. Enter:
   - **Name**: `TABLES_CONNECTION_STRING`
   - **Value**: [Your connection string]
5. Click **"Save"**

---

## Method 3: Using Azure CLI (Alternative)

If you can't find it in the portal, you can use Azure CLI:

```bash
az staticwebapp appsettings set \
  --name blue-desert-0c2a27e1e \
  --resource-group <your-resource-group> \
  --settings TABLES_CONNECTION_STRING="<your-connection-string>"
```

---

## Visual Guide - What to Look For

### In Azure Portal Left Sidebar:
```
Your Static Web App
├── Overview
├── Configuration  ← LOOK HERE
│   ├── Application settings  ← THIS TAB
│   └── (other tabs)
├── Custom domains
├── Deployment
└── ...
```

### Or Under Settings:
```
Your Static Web App
├── Overview
├── Settings
│   ├── Configuration  ← OR HERE
│   │   └── Application settings
│   └── ...
└── ...
```

---

## How to Get Your Connection String

1. **Go to your Storage Account** (`latencynet storage` in Azure Portal)
2. **Left sidebar** → **"Access keys"** (under Security + networking)
3. Click **"Show"** next to "key1" connection string
4. **Copy the entire connection string** (starts with `DefaultEndpointsProtocol=...`)
5. **Paste it** into the `TABLES_CONNECTION_STRING` value field

---

## After Setting the Environment Variable

1. **Save** the configuration
2. **Wait 1-2 minutes** for Azure to restart your app
3. **Test** your API:
   ```bash
   curl -X POST "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status" \
     -H "Content-Type: application/json" \
     -d '{"gatewayId":"pi5-main","status":"online"}'
   ```

---

## Still Can't Find It?

Try these steps:

1. **Check if you're in the right resource**:
   - Make sure you're looking at "Static Web App" (not App Service, Function App, etc.)
   - Resource type should be "Static Web App"

2. **Try the search bar**:
   - In Azure Portal, use the search bar at the top
   - Search for: "Configuration" or "Application settings"
   - Select your Static Web App

3. **Check permissions**:
   - Make sure you have "Contributor" or "Owner" role on the resource

4. **Try direct URL**:
   - `https://portal.azure.com/#@<your-tenant>/resource/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Web/staticSites/<app-name>/configuration`

---

## Quick Check: Did It Work?

After setting the environment variable, you can verify:

1. Go back to Configuration → Application settings
2. You should see `TABLES_CONNECTION_STRING` in the list
3. The value should be masked (shows as dots for security)

---

## Troubleshooting

**If you get "Connection string not set" error:**
- Make sure you clicked "Save" at the top of the Configuration page
- Wait 2-3 minutes for the app to restart
- The app needs to restart to pick up new environment variables

**If the variable doesn't appear:**
- Check spelling: `TABLES_CONNECTION_STRING` (exactly as shown, case-sensitive)
- Make sure you're setting it on the correct Static Web App resource

