# Update STM32 Bridge Script - Step by Step

## Option 1: Quick Update (Copy/Paste)

SSH into your Pi and run these commands one by one:

```bash
# 1. Stop the old bridge script
pkill -f pi_stm32_bridge.py

# 2. Navigate to your repo directory (or home if script is there)
cd ~

# 3. If you have the repo cloned, pull latest changes
# If not, skip this step or clone the repo first
git pull

# 4. Copy the updated bridge script to home directory (if needed)
cp pi_stm32_bridge.py ~/  # or wherever your script is

# 5. Start the updated bridge script
python3 pi_stm32_bridge.py
```

## Option 2: Manual Step-by-Step

### Step 1: SSH into your Pi
```bash
ssh pi5@192.168.1.160
# (or your Pi's IP address)
```

### Step 2: Stop the current bridge script
Press `Ctrl+C` if it's running in the terminal, OR:
```bash
pkill -f pi_stm32_bridge.py
```

### Step 3: Update the script
**If the script is in your git repo:**
```bash
cd ~/LoveableRepo  # or wherever your repo is
git pull
cp pi_stm32_bridge.py ~/
```

**If the script is already in your home directory:**
```bash
cd ~
# Download or copy the updated script manually
# Or pull from git if you have it there
```

### Step 4: Start the updated script
```bash
cd ~
python3 pi_stm32_bridge.py
```

### Step 5: Watch the logs
You should see:
```
✅ Initial status sent: offline (waiting for STM32 heartbeat...)
👂 Listening for STM32 messages...
```

When your STM32 sends a heartbeat, you'll see:
```
📥 Received: 'STM32_ALIVE'
✅ Received STM32 heartbeat - marking as online
```

## Option 3: Use the Update Script

1. Copy `update_bridge.sh` to your Pi:
   ```bash
   scp update_bridge.sh pi5@192.168.1.160:~/
   ```

2. SSH into Pi and run:
   ```bash
   chmod +x update_bridge.sh
   ./update_bridge.sh
   ```

## Verify It's Working

Watch the output - you should see:
- ✅ Starts with "offline" status
- 📥 Shows received messages when STM32 sends them
- ⚠️ Shows timeout warnings when STM32 disconnects

To check logs later:
```bash
tail -f ~/stm32-bridge.log
```

