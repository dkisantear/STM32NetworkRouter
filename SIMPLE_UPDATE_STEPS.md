# Simple Update Steps - Do This Now!

## Method 1: Automatic (Easiest)

Run this PowerShell script from your repo directory:

```powershell
.\update_pi_bridge.ps1
```

It will:
- Copy the updated script to your Pi
- Show you what to do next

## Method 2: Manual Copy/Paste

### Step 1: Copy file to Pi (from Windows PowerShell)

```powershell
scp pi_stm32_bridge.py pi5@192.168.1.160:~/
```

### Step 2: SSH into Pi and update

```bash
ssh pi5@192.168.1.160
```

### Step 3: Stop old bridge and start new one

```bash
# Stop old version
pkill -f pi_stm32_bridge.py

# Start new version  
python3 pi_stm32_bridge.py
```

## What You Should See:

✅ **When bridge starts:**
```
✅ Initial status sent: offline (waiting for STM32 heartbeat...)
👂 Listening for STM32 messages...
```

✅ **When STM32 sends heartbeat:**
```
📥 Received: 'STM32_ALIVE'
✅ Received STM32 heartbeat - marking as online
```

✅ **When STM32 disconnects:**
```
⚠️  No STM32 message for 10.5s - marking as offline
```

## Quick Test:

1. Start bridge → Should show "offline"
2. Connect STM32 → Should change to "online" 
3. Unplug STM32 → Should change to "offline" after ~10 seconds

That's it! The status will now accurately reflect your STM32 connection.

