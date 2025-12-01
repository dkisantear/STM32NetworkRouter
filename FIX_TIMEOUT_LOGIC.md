# Fix: Status Going Offline Unexpectedly

## Problem

Status went offline even though STM32 is still connected. This happens because:

1. **Bridge script timeout is too short** (10 seconds)
2. **UART read errors** might prevent message detection
3. **Timeout logic** only works if at least one message was received

## Fix Applied

### Changes Made:

1. **Increased timeout** from 10 to 15 seconds (gives more buffer)
2. **Initialize `last_message_time`** when port opens (so timeout works even if no messages received initially)
3. **Better logging** to see when messages are received

### Why It Happens:

The bridge script checks if `last_message_time is not None` before timing out. If the script:
- Never receives a message (due to UART errors)
- Or receives errors that prevent setting `last_message_time`

Then it won't timeout properly.

## Verify Bridge is Receiving Messages

**On Pi, check logs:**
```bash
tail -f ~/stm32-bridge.log
```

**Look for:**
- ✅ `📥 Received: 'STM32_ALIVE'` - Messages are being received!
- ❌ Only `ERROR` messages - Bridge isn't receiving properly

**If you see messages but status still goes offline:**
- Check timeout value (should be 15 seconds now)
- Check if bridge script is running continuously
- Check Azure Function timeout (90 seconds)

## Expected Behavior After Fix

1. **When STM32 is connected:**
   - Bridge receives messages every ~1 second
   - `last_message_time` gets updated
   - Status stays "online"

2. **When STM32 disconnects:**
   - No messages for 15 seconds
   - Bridge marks as "offline"
   - Frontend shows "Offline" within ~20 seconds

## Test Again

1. **Restart bridge** with updated script:
   ```bash
   pkill -f pi_stm32_bridge
   cd ~
   nohup python3 pi_stm32_bridge.py > bridge_output.log 2>&1 &
   ```

2. **Monitor logs**:
   ```bash
   tail -f ~/stm32-bridge.log
   ```

3. **Watch for**: `📥 Received: 'STM32_ALIVE'` messages

If you're still seeing messages but status goes offline, the issue might be:
- Bridge script crashing/restarting
- Azure Function timeout (90 seconds)
- Network issues preventing POST requests

