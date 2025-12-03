# STOP - Verify STM32 Connection First

## Your STM32 Info:
- **Board:** NUCLEO-F303K8
- **Device:** STM32F303x4-x6-x8
- **UART:** Should be UART2 (PA2/TX, PA3/RX)
- **Baud Rate:** 38400

## Step-by-Step Verification (NO CODE CHANGES)

### Step 1: Verify STM32 is Sending Data

On your Pi, run this simple test (NO bridge script):

```bash
# Stop any running bridge scripts first
pkill -f pi_stm32_bridge.py

# Run the simple receiver test
python3 pi_check_stm32_sending.py
```

**What to look for:**
- ✅ If you see messages → UART is working!
- ❌ If you see "NO MESSAGES RECEIVED" → STM32 is not sending

### Step 2: Check STM32 Code

Make sure your STM32 `main.c` has:
- UART2 initialized at 38400 baud
- Sending "STM32_ALIVE\n" or similar message
- Running in a loop

### Step 3: Verify Wiring

**Pi GPIO → STM32:**
- Pi GPIO14 (TX) → STM32 PA3 (RX)
- Pi GPIO15 (RX) → STM32 PA2 (TX)
- GND → GND

### Step 4: Check Pi UART Device

```bash
# On Pi, check which UART device is active
ls -l /dev/ttyAMA* /dev/serial0
```

Should show `/dev/ttyAMA0` is the active UART.

## Once Connection is Verified:

THEN we can:
1. Fix the bridge script to properly detect it
2. Fix any remaining issues

## Current Status:

**Don't run the bridge script yet!**

First, let's verify:
1. ✅ STM32 is powered on
2. ✅ STM32 code is flashed and running
3. ✅ STM32 is sending data via UART2
4. ✅ Pi can receive that data

Only after ALL of these are confirmed, we'll fix the bridge script.

