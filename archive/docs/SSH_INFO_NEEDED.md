# Information Needed for SSH Setup

To automatically set up your Raspberry Pi, I need the following information:

## Required Information

### 1. Raspberry Pi IP Address
**How to find it:**
- **Option A:** Check Pi's screen (if connected) - run: `hostname -I`
- **Option B:** Check your router admin page (look for "raspberrypi" device)
- **Option C:** Scan your network (I can help with this)

**Common IP addresses to try:**
- `192.168.1.100`
- `192.168.1.101`
- `192.168.0.100`
- `192.168.0.101`

### 2. SSH Username
- Usually: `pi`
- Or your custom username if you changed it

### 3. SSH Password
- Default: `raspberry`
- Or your custom password if you changed it

### 4. SSH Port (Optional)
- Default: `22`
- Usually only needed if you changed it

---

## What I'll Do Automatically

Once you provide this info, I will:

1. ✅ **Test SSH connection** to verify I can reach your Pi
2. ✅ **Transfer the heartbeat scripts** to your Pi
3. ✅ **Install Python dependencies** (requests library)
4. ✅ **Run the test script** to verify connection works
5. ✅ **Set up continuous heartbeat** to keep it running
6. ✅ **Verify on your dashboard** that it shows "Connected"

---

## Quick Checklist

Please provide:

```
Pi IP Address: _______________
Username: _______________ (usually "pi")
Password: _______________ (usually "raspberry")
```

**Or if you prefer not to share password:**
- I can give you commands to run manually
- Or you can run the setup script I created

---

## Finding Your Pi IP Address

### Method 1: From Your Computer (Windows PowerShell)

```powershell
# Scan your local network
arp -a | Select-String "192.168"

# Or try pinging common hostnames
ping raspberrypi.local
```

### Method 2: From Router Admin Page
1. Open browser: `http://192.168.1.1` or `http://192.168.0.1`
2. Look for "Connected Devices" or "DHCP Clients"
3. Find device named "raspberrypi" or similar
4. Note the IP address

### Method 3: From Pi Screen (if you have keyboard/screen)
```bash
hostname -I
```

---

## Security Note

If you prefer not to share your password:
- I can provide commands you can copy-paste
- You can run them manually in SSH session
- Or I can help you set up SSH key authentication (more secure)

---

## Ready to Start?

Just provide:
1. IP Address: `_________`
2. Username: `pi` (or your custom one)
3. Password: `_________` (I'll keep this secure)

Then I'll handle everything else! 🚀

