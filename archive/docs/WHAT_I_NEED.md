# What Information I Need to Automatically Set Up Your Pi

## Quick Answer: 3 Things Needed

```
1. Raspberry Pi IP Address:  _______________
   (e.g., 192.168.1.100)

2. SSH Username:            _______________
   (usually: pi)

3. SSH Password:            _______________
   (usually: raspberry)
```

---

## Step-by-Step: Getting This Information

### Step 1: Find Your Pi's IP Address

**Option A: Run this in PowerShell (I'll help you):**
```powershell
arp -a | Select-String "192.168"
```
This shows all devices on your network.

**Option B: Check your router:**
- Go to: `http://192.168.1.1` (or `192.168.0.1`)
- Look for "Connected Devices" or "DHCP Clients"
- Find device named "raspberrypi"

**Option C: If Pi has screen/keyboard:**
```bash
hostname -I
```

### Step 2: Test SSH Connection

Once you have the IP, try:
```powershell
ssh pi@<YOUR_PI_IP>
```

Default credentials:
- Username: `pi`
- Password: `raspberry`

---

## What I'll Do Once You Provide Info

I will automatically:

1. ✅ **Test SSH connection** - Verify I can reach your Pi
2. ✅ **Transfer files** - Copy heartbeat scripts to Pi
3. ✅ **Install dependencies** - Install Python and requests library
4. ✅ **Run test** - Send a test heartbeat to verify it works
5. ✅ **Start continuous mode** - Set up automatic heartbeats
6. ✅ **Verify dashboard** - Confirm it shows "Connected"

---

## Alternative: Manual Setup (If You Prefer)

If you'd rather not share credentials, I can provide you with:
- Copy-paste commands for each step
- Scripts you run manually
- Step-by-step instructions

Just let me know!

---

## Console Error Fix

I've also fixed the console error you mentioned. The frontend will now:
- ✅ Handle errors more gracefully
- ✅ Reduce console spam
- ✅ Show better error messages

This fix will be included in the next deployment.

---

## Ready to Start?

Just provide:
1. IP Address: `_________`
2. Username: `pi` (or tell me if different)
3. Password: `_________` (I'll keep secure)

Then I'll handle everything! 🚀

