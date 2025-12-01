# Verify STM32 Main Code Has UART Send Logic

## Critical Issue Found

Your bridge script is **running** but **NOT receiving** any UART messages. This means:

✅ Bridge script is working  
✅ Azure connection is working  
❌ **STM32 is NOT sending messages**

## Problem

The MSP code (`stm32f3xx_hal_msp.c`) you flashed only configures the **hardware** (GPIO pins). It does **NOT** contain the code that actually **sends** messages.

You need to check your `main.c` file has the UART send code in the main loop.

---

## Required STM32 Code

### Step 1: Check if Variable Exists

In your `main.c`, find this section:
```c
/* USER CODE BEGIN PV */

/* USER CODE END PV */
```

**It should have:**
```c
/* USER CODE BEGIN PV */
uint32_t stm32UartLastTick = 0;
/* USER CODE END PV */
```

If this variable is **missing**, add it!

---

### Step 2: Check Main Loop

In your `main.c`, find your main loop (usually in `/* USER CODE BEGIN 3 */` section):

**Current code might look like:**
```c
/* USER CODE BEGIN 3 */
while (1)
{
    uint8_t pattern = ReadDipSwitch();
    DisplayOnLedBar(pattern);
    HAL_Delay(10);
}
/* USER CODE END 3 */
```

**It MUST have the UART send code:**
```c
/* USER CODE BEGIN 3 */
while (1)
{
    uint8_t pattern = ReadDipSwitch();
    DisplayOnLedBar(pattern);
    
    // ADD THIS: Send UART heartbeat every 1000 ms
    uint32_t now = HAL_GetTick();
    if (now - stm32UartLastTick >= 1000)
    {
        const char msg[] = "STM32_ALIVE\n";
        HAL_UART_Transmit(&huart2,
                          (uint8_t*)msg,
                          sizeof(msg) - 1,  // -1 to exclude null terminator
                          HAL_MAX_DELAY);
        stm32UartLastTick = now;
    }
    
    HAL_Delay(10);
}
/* USER CODE END 3 */
```

---

## Quick Verification Checklist

- [ ] Variable `stm32UartLastTick` declared in `/* USER CODE BEGIN PV */`
- [ ] Main loop has `HAL_UART_Transmit(&huart2, ...)` code
- [ ] Message is `"STM32_ALIVE\n"` (with newline!)
- [ ] Interval is 1000ms (every 1 second)
- [ ] Code is compiled and flashed to STM32

---

## Test After Adding Code

1. **Flash the updated code** to your STM32
2. **Verify STM32 is powered** and running
3. **Check LEDs work** (if DIP switches control LEDs, they should respond)
4. **Run UART test** on Pi:
   ```bash
   python3 pi_uart_test.py
   ```
5. **You should see** messages every ~1 second

---

## If Still No Messages After Adding Code

1. **Check STM32 is running:**
   - Do LEDs respond to DIP switches?
   - If NO → Code not running, re-flash

2. **Check wiring:**
   - STM32 PA2 (TX) → Pi GPIO15 (RX)
   - STM32 PA3 (RX) → Pi GPIO14 (TX)  
   - Shared GND connection

3. **Check UART configuration:**
   - Baud rate: 38400
   - Verify in CubeMX or `.ioc` file

4. **Check STM32 PA2 pin:**
   - Use multimeter/oscilloscope
   - Should see voltage changes every ~1 second
   - If static → STM32 not sending

---

## Complete STM32 Main.c Template

If you're not sure, here's a complete template for the main loop:

```c
/* USER CODE BEGIN PV */
uint32_t stm32UartLastTick = 0;  // Timer for UART heartbeat
/* USER CODE END PV */

// ... rest of your code ...

/* USER CODE BEGIN 3 */
while (1)
{
    // Your existing DIP switch and LED code
    uint8_t pattern = ReadDipSwitch();
    DisplayOnLedBar(pattern);
    
    // UART heartbeat - send "STM32_ALIVE" every 1 second
    uint32_t now = HAL_GetTick();
    if (now - stm32UartLastTick >= 1000)
    {
        const char msg[] = "STM32_ALIVE\n";
        HAL_UART_Transmit(&huart2,
                          (uint8_t*)msg,
                          sizeof(msg) - 1,
                          HAL_MAX_DELAY);
        stm32UartLastTick = now;
    }
    
    HAL_Delay(10);
}
/* USER CODE END 3 */
```

---

## Next Steps

1. ✅ **Check your `main.c` has the UART send code**
2. ✅ **If missing, add it**
3. ✅ **Re-compile and flash**
4. ✅ **Test with `pi_uart_test.py`**

Once STM32 starts sending messages, the bridge script will automatically detect them and keep the status "online"!

