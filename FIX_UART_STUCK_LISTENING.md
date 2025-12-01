# Fix: Pi Stuck on "Listening" - No Messages from STM32

## 🚨 Problem

When running `python3 pi_uart_test.py`, the Pi is stuck on "Listening" and never receives any messages from the STM32.

## 🔍 Diagnostic Steps

### Step 1: Test Multiple Baud Rates

The most common issue is a **baud rate mismatch**. Your STM32 might be using a different baud rate than the Pi scripts (38400).

**Run this on your Pi:**

```bash
# Copy TEST_ALL_BAUD_RATES.py to Pi first, then:
python3 TEST_ALL_BAUD_RATES.py
```

This will test: 115200, 38400, 9600, 57600, 19200, 230400, 4800

**If it finds data at a different baud rate:**
- ✅ UART is working!
- ❌ Baud rate mismatch - fix it (see below)

### Step 2: Verify STM32 Code

Check your STM32 `main.c` file:

1. **Is USART2 initialized?**
   ```c
   int main(void) {
       // ...
       MX_USART2_UART_Init();  // ← This must exist!
   ```

2. **What baud rate is it using?**
   ```c
   static void MX_USART2_UART_Init(void) {
       // ...
       huart2.Init.BaudRate = 38400;  // ← Should be 38400!
   ```

   **If it says `115200` or anything else, THAT'S YOUR PROBLEM!**

3. **Is UART send code in the main loop?**
   ```c
   while (1) {
       // ...
       if (now - stm32UartLastTick >= 1000) {
           const char msg[] = "STM32_ALIVE\n";
           HAL_UART_Transmit(&huart2, (uint8_t*)msg, sizeof(msg) - 1, HAL_MAX_DELAY);
           stm32UartLastTick = now;
       }
   }
   ```

### Step 3: Check Wiring

**Correct wiring (TX and RX must be crossed!):**

```
STM32 PA2 (TX) → Pi Pin 10 (RXD/GPIO15)  ← STM32 sends to Pi RX
STM32 PA3 (RX) → Pi Pin 8  (TXD/GPIO14)  ← Pi sends to STM32 RX
GND            → GND                      ← Shared ground
```

**Common mistakes:**
- ❌ TX→TX, RX→RX (not crossed)
- ❌ Only TX connected, no RX
- ❌ No GND connection
- ❌ Wrong Pi pins

### Step 4: Verify STM32 is Actually Running

- ✅ DIP switches work (LEDs change when you flip switches) → Code is running
- ❌ No LED activity → Code might not be running (re-flash STM32)

### Step 5: Check UART Device

```bash
# On Pi, check device exists:
ls -l /dev/ttyAMA0

# Should show something like:
# crw-rw---- 1 root dialout ... /dev/ttyAMA0
```

If it doesn't exist:
```bash
sudo raspi-config
# Interface Options → Serial Port → Enable
# Reboot
```

## 🔧 Solutions

### Solution 1: Fix Baud Rate Mismatch

**If STM32 is using 115200 but Pi expects 38400:**

**Option A: Change STM32 to 38400 (Recommended)**
1. Open STM32CubeMX (your `.ioc` file)
2. Connectivity → USART2
3. Set Baud Rate = **38400**
4. Save and Generate Code
5. Rebuild and flash STM32

**Option B: Change Pi scripts to match STM32**
- Update `pi_uart_test.py`: Change `BAUDRATE = 115200`
- Update `pi_stm32_bridge.py`: Change `UART_BAUDRATE = 115200`

### Solution 2: Fix Wiring

1. Disconnect all wires
2. Reconnect carefully:
   - STM32 TX → Pi RX (GPIO15/Pin 10)
   - STM32 RX → Pi TX (GPIO14/Pin 8)
   - GND → GND
3. Make sure connections are secure

### Solution 3: Verify STM32 CubeMX Configuration

1. Open your `.ioc` file in STM32CubeMX
2. Check **Pinout** view:
   - PA2 should show **USART2_TX**
   - PA3 should show **USART2_RX**
3. Check **Connectivity → USART2**:
   - Mode: **Asynchronous** (NOT Disabled!)
   - Baud Rate: **38400**
   - Word Length: **8 Bits**
   - Parity: **None**
   - Stop Bits: **1**

### Solution 4: Add Diagnostic to STM32

Add this to verify UART is actually sending:

```c
if (now - stm32UartLastTick >= 1000) {
    // Toggle LED before sending (proves code is executing)
    HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_0);  // Toggle LED1
    
    const char msg[] = "STM32_ALIVE\n";
    HAL_StatusTypeDef status = HAL_UART_Transmit(&huart2, 
                                                  (uint8_t*)msg, 
                                                  sizeof(msg) - 1, 
                                                  HAL_MAX_DELAY);
    
    if (status != HAL_OK) {
        // Blink LED twice to show error
        HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_0);
        HAL_Delay(100);
        HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_0);
    }
    
    stm32UartLastTick = now;
}
```

**Expected behavior:**
- LED1 toggles every 1 second → UART send is being called ✅
- LED1 blinks twice → UART transmission failed ❌

## ✅ Success Criteria

You'll know it's working when:

1. `pi_uart_test.py` shows:
   ```
   📥 Received: 'STM32_ALIVE'
   ✅ Correct format!
   ```

2. `TEST_ALL_BAUD_RATES.py` finds data at one of the baud rates

3. Bridge script logs:
   ```
   📥 Received: 'STM32_ALIVE'
   ✅ Status sent to Azure: online
   ```

## 📋 Checklist

- [ ] STM32 is powered on (LEDs visible)
- [ ] DIP switches work (proves code is running)
- [ ] Wiring: TX→RX, RX→TX, GND→GND (crossed!)
- [ ] `/dev/ttyAMA0` exists on Pi
- [ ] STM32 baud rate = 38400 (in `main.c` or CubeMX)
- [ ] Pi scripts baud rate = 38400
- [ ] `MX_USART2_UART_Init()` is called in `main()`
- [ ] UART send code is in the main loop
- [ ] STM32 was re-flashed after any code changes

## 🆘 Still Not Working?

If you've checked everything above and still no data:

1. **Try a different USART** (e.g., USART1 instead of USART2)
2. **Test with a known-good device** (another Pi, Arduino, etc.)
3. **Check STM32 datasheet** for correct pin assignments
4. **Use an oscilloscope/logic analyzer** to verify signals

