# Verify UART Communication is Working

## Current Status
✅ Bridge script is working - sending status to Azure
❌ No UART messages received from STM32 yet

## Test If STM32 is Sending

On your Pi, run this test script:

```bash
# Copy the test script to Pi first (from Windows):
# scp pi_check_stm32_sending.py pi5@192.168.1.160:~/

# Then on Pi:
python3 pi_check_stm32_sending.py
```

This will:
- Listen for 10 seconds for ANY data from STM32
- Show raw bytes if text decode fails
- Tell you if STM32 is sending anything

## What Should Happen

### If STM32 is sending:
```
✅ RECEIVED X message(s) from STM32!
UART communication is working!
```

### If STM32 is NOT sending:
```
❌ NO MESSAGES RECEIVED from STM32
```

## Next Steps Based on Results

### If STM32 IS sending:
✅ UART works! You can now:
1. Test sending commands from frontend
2. Verify STM32 receives and processes them
3. Implement LED/DIP switch output logic

### If STM32 is NOT sending:
Check:
1. STM32 is powered on
2. UART2 is enabled and configured correctly
3. Wiring: Pi GPIO14 (TX) → STM32 RX, Pi GPIO15 (RX) → STM32 TX
4. Baud rate matches (38400)
5. STM32 code is actually sending data via UART2

## For Now - Status is Working!

Even if STM32 isn't sending messages yet, your bridge script is:
- ✅ Sending heartbeats to Azure
- ✅ Frontend should show "Online" status
- ✅ Ready to receive commands from frontend

Once UART is confirmed working, commands from frontend will flow:
Frontend → Azure → Pi Bridge → STM32 → LED Output

