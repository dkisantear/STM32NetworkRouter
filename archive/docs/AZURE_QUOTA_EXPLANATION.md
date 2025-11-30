# Azure Quota Limit - What's Happening?

## Your Situation

You mentioned hitting Azure quota limits and getting a message about:
- Can't send new messages
- Can't view device list
- Using free version

---

## Understanding Azure Static Web Apps Free Tier

### Quota Limits (Free Tier):
- **API Requests:** 125,000 per month
- **Bandwidth:** 100 GB per month
- **Build Minutes:** 100 per month
- **Custom Domains:** 2 per app
- **Functions:** 2 GB storage

---

## Is This The Issue?

### Possibly YES if:
- ❌ You've sent **>125,000 API requests** this month
- ❌ You've used **>100 GB bandwidth**
- ❌ API is now rate-limited or blocked

### Possibly NO if:
- ✅ Your heartbeat POST **still succeeded** (you got a response)
- ✅ The API responded with `{'ok': True, 'lastSeen': '...'}`

---

## What's Likely Happening

Your heartbeat **IS working** (the POST succeeded), but:

1. **If you hit quota limits**, Azure might:
   - Throttle requests (slow them down)
   - Return errors for some requests
   - Block new requests

2. **The "Disconnected" status** could be because:
   - The GET request was throttled/blocked
   - Different Azure Function instances (as mentioned before)
   - Or quota limits preventing the GET from working

---

## How to Check

### 1. Check Your Azure Portal

Go to your Azure Static Web App in the Azure Portal:
- Look for **"Usage"** or **"Quota"** section
- Check if you've hit any limits

### 2. Check API Response

Try calling the API directly:

```bash
# On your Pi or computer:
curl https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status
```

**If you get errors like:**
- `429 Too Many Requests`
- `403 Forbidden`
- `Quota exceeded`

Then you've hit quota limits.

---

## Solutions

### Option 1: Wait for Quota Reset

Azure quotas typically reset monthly. Check when your quota resets in the Azure Portal.

### Option 2: Upgrade Plan

If you need more capacity:
- Upgrade to **Standard Plan** ($9/month + usage)
- Gets you higher limits

### Option 3: Reduce Heartbeat Frequency

If heartbeats are too frequent:
- Change from every 15 seconds to every 60 seconds
- Reduces API requests by 75%

---

## Next Steps

1. **Check Azure Portal** - See your quota usage
2. **Try API directly** - See if it's blocked
3. **Wait for reset** - Or upgrade if needed
4. **Reduce frequency** - Send heartbeats less often

---

## Good News

If your heartbeat POST succeeded, the setup is **working correctly**! The issue is just Azure quota limits, not your Pi setup. 🎉

Once the quota resets (or you upgrade), everything should work perfectly!

