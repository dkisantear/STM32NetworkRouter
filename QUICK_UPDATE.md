# Quick Update - Copy/Paste These Commands

## SSH into your Pi first, then run these commands:

```bash
# Stop old bridge
pkill -f pi_stm32_bridge.py

# Go to home directory
cd ~

# Pull latest code (if you have repo cloned)
# If not, we'll download the file directly
if [ -d "LoveableRepo" ]; then
    cd LoveableRepo
    git pull
    cp pi_stm32_bridge.py ~/
    cd ~
else
    echo "Repository not found. Downloading script directly..."
fi

# Start updated bridge
python3 pi_stm32_bridge.py
```

## OR - If you don't have git repo on Pi, copy file directly:

From Windows PowerShell (in your project directory):
```powershell
scp pi_stm32_bridge.py pi5@192.168.1.160:~/
```

Then on Pi:
```bash
pkill -f pi_stm32_bridge.py
python3 ~/pi_stm32_bridge.py
```

## What to expect:

The script will now:
- ✅ Start as **"offline"**
- ✅ Wait for STM32 heartbeat
- ✅ Mark **"online"** only after receiving heartbeat
- ✅ Mark **"offline"** when STM32 disconnects (after 10 seconds)

Watch for these messages in the output!

