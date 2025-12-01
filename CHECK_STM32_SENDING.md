# Quick Check: Is STM32 Actually Sending?

## Current Situation

Your logs show:
- ✅ Bridge script running
- ✅ Bridge sent initial "online" status
- ❌ **Bridge NEVER received any "STM32_ALIVE" messages**
- ❌ UART test script stuck on "Listening..."

This means: **STM32 is NOT sending messages**

---

## Quick Diagnostic Steps

### Step 1: Verify STM32 Code Has Send Logic

Open your STM32 project's `main.c` file and check:

**Question 1:** Is there a variable for UART timing?
- Look for: `uint32_t stm32UartLastTick = 0;`
- Location: Should be in `/* USER CODE BEGIN PV */` section

**Question 2:** Does main loop send UART messages?
- Look for: `HAL_UART_Transmit(&huart2, ...)`
- Location: Should be in main `while(1)` loop

**If either is missing → That's the problem!**

---

### Step 2: Check STM32 is Running

**Test:** Do your LEDs respond to DIP switches?

- ✅ **YES** → STM32 code is running, problem is UART send code missing
- ❌ **NO** → STM32 code not running, re-flash

---

### Step 3: Verify Wiring (if code exists)

If you added the UART send code but still no messages:

**Check connections:**
```
STM32          Pi 5
-----          -----
PA2 (TX)  →    GPIO15 (RX)  [Crossed!]
PA3 (RX)  →    GPIO14 (TX)  [Crossed!]
GND       →    GND          [Shared]
```

**Common mistakes:**
- ❌ TX→TX, RX→RX (should be TX→RX, RX→TX)
- ❌ No shared GND
- ❌ Wrong pins

---

## Most Likely Issue

**90% chance:** Your `main.c` is missing the UART send code.

The MSP file (`stm32f3xx_hal_msp.c`) you flashed only sets up hardware. You still need to add the code that **sends** messages in your main loop.

---

## Solution

1. **Open `main.c` in STM32CubeIDE**
2. **Add the timer variable** (if missing):
   ```c
   /* USER CODE BEGIN PV */
   uint32_t stm32UartLastTick = 0;
   /* USER CODE END PV */
   ```

3. **Add UART send code in main loop:**
   ```c
   // In your while(1) loop:
   uint32_t now = HAL_GetTick();
   if (now - stm32UartLastTick >= 1000)
   {
       const char msg[] = "STM32_ALIVE\n";
       HAL_UART_Transmit(&huart2, (uint8_t*)msg, sizeof(msg) - 1, HAL_MAX_DELAY);
       stm32UartLastTick = now;
   }
   ```

4. **Build and flash**

5. **Test on Pi:**
   ```bash
   python3 pi_uart_test.py
   ```

You should now see messages!

---

## Why Status Shows "Online" Now

The bridge script sends an initial "online" status when it starts. That's why you see "online" even though no messages are being received. But it will timeout and go offline after ~10 seconds if STM32 doesn't send messages.

Add the UART send code and the status will stay online!

