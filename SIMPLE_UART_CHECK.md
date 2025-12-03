# Quick UART Communication Check

## Current Status from Your Logs:
✅ Bridge script is working perfectly
✅ Device ID: stm32-master (correct!)
✅ Status being sent to Azure every 30 seconds
❌ No "📥 Received:" messages = STM32 not sending data yet

## Good News:
Your frontend should now show Master STM32 as **"Online"** because:
- Heartbeats are sending every 30 seconds
- Device ID matches frontend (`stm32-master`)
- Status is being stored in Azure

## Verify UART Communication Works

### Test 1: Can STM32 Receive Commands? (Most Important)

On your Pi, run the bidirectional test:

```bash
# Stop bridge script temporarily
pkill -f pi_stm32_bridge.py

# Run bidirectional test (sends commands, listens for responses)
python3 pi_uart_bidirectional_test.py
```

This will:
- Send test values (0, 5, 10, 15, 16) to your STM32
- Show if STM32 receives them
- Listen for any responses

**Watch your STM32 LEDs/DIP switch** - they should change when values are sent!

### Test 2: Is STM32 Sending Anything?

```bash
python3 pi_check_stm32_sending.py
```

This listens for 10 seconds to see if STM32 sends any data.

## What to Check

If STM32 receives commands:
✅ UART RX is working!
✅ You can send commands from frontend
✅ Implement LED logic based on received values

If STM32 doesn't receive commands:
- Check wiring: Pi GPIO14 (TX) → STM32 PA3 (RX)
- Verify STM32 UART2 RX is enabled
- Check baud rate matches (38400)

## Next: Test From Frontend!

Once UART is verified:
1. Keep bridge script running
2. Open frontend dashboard
3. Enter a value (0-16) and click Send
4. Watch bridge logs on Pi - should see command being sent
5. Watch STM32 - LEDs/DIP should update

