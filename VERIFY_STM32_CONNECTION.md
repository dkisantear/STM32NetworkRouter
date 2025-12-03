# STOP - Verify STM32 Connection FIRST

## Your Board Info:
- **STM32F303K8** (NUCLEO-F303K8)
- **UART2:** PA2 (TX), PA3 (RX)
- **Baud Rate:** 38400

## STEP 1: Test Basic UART Connection (No Bridge Script)

**On your Pi, run this simple test:**

```bash
# Stop any bridge scripts
pkill -f pi_stm32_bridge.py

# Run simple receiver test
python3 pi_check_stm32_sending.py
```

**What should happen:**
- ✅ **If you see messages** → UART connection works! STM32 is sending data.
- ❌ **If you see "NO MESSAGES RECEIVED"** → STM32 is NOT sending data.

## STEP 2: Check STM32 Code

Your STM32 `main.c` should have:

1. **UART2 initialized at 38400 baud**
2. **Sending data in a loop** (like "STM32_ALIVE\n")
3. **UART2 TX configured on PA2**

## STEP 3: Verify Wiring

**Correct wiring:**
- Pi GPIO15 (RX) → STM32 PA2 (TX)
- Pi GPIO14 (TX) → STM32 PA3 (RX)  
- GND → GND

**Note:** RX connects to TX and vice versa!

## STEP 4: Check UART Device

```bash
# On Pi
ls -l /dev/ttyAMA0
```

Should show the device exists and is accessible.

## DO NOT PROCEED UNTIL:

✅ You can see messages from STM32 in Step 1
✅ STM32 code is confirmed sending via UART2
✅ Wiring is verified correct

## Once Connection Works:

THEN we can fix the bridge script to properly detect and handle the data.

---

## Questions to Answer:

1. **When you run `pi_check_stm32_sending.py`, do you see ANY messages?**
   - If YES → Connection works! Bridge script needs fixing.
   - If NO → STM32 is not sending. Check STM32 code/wiring.

2. **Is your STM32 code actually sending data via UART2?**
   - Check your `main.c` - does it have `HAL_UART_Transmit()` calls?

3. **What does your STM32 send?**
   - Is it "STM32_ALIVE\n"?
   - Is it something else?
   - How often does it send?

