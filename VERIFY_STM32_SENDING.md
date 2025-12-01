# Verify STM32 is Actually Sending Data

## Critical Check: Is STM32 Code Running?

### Test 1: Check LEDs Work

Your STM32 code has DIP switch and LED logic. If the LEDs **don't respond** to DIP switches:
- ❌ STM32 code is **NOT running**
- ✅ **Fix:** Re-flash the STM32 board

### Test 2: Check UART Pin Activity

If you have a **multimeter** or **oscilloscope**:

1. **Probe STM32 PA2 pin** (USART2_TX)
2. **Set multimeter to DC voltage** (or use oscilloscope)
3. **You should see:**
   - Voltage changing every ~1 second when STM32 sends "STM32_ALIVE"
   - If completely static → STM32 is NOT sending

### Test 3: Add LED Blink to Confirm Code Execution

Add this to your STM32 main loop to verify code is running:

```c
// In USER CODE BEGIN 3, add before UART send:
uint8_t pattern = ReadDipSwitch();
DisplayOnLedBar(pattern);

// ADD THIS: Blink LED1 every 500ms to confirm code runs
static uint32_t ledBlinkTick = 0;
uint32_t now = HAL_GetTick();
if (now - ledBlinkTick >= 500) {
    HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_0); // Toggle LED1
    ledBlinkTick = now;
}

// Send UART heartbeat
if (now - stm32UartLastTick >= 1000) {
    const char msg[] = "STM32_ALIVE\n";
    HAL_UART_Transmit(&huart2,
                      (uint8_t*)msg,
                      sizeof(msg) - 1,
                      HAL_MAX_DELAY);
    stm32UartLastTick = now;
}
```

**If LED1 blinks every 0.5 seconds:**
- ✅ Code is running
- ✅ Problem is UART hardware or wiring

**If LED1 doesn't blink:**
- ❌ Code is not running
- ✅ Re-flash STM32

## Check STM32 UART Configuration

Verify in STM32CubeMX or your `.ioc` file:

### USART2 Settings Must Match:

```
Mode: Asynchronous
Baud Rate: 38400
Word Length: 8 Bits
Parity: None
Stop Bits: 1
Hardware Flow Control: None
```

### Pin Assignment:

Verify USART2 is actually configured on:
- **TX:** PA2
- **RX:** PA3

If different pins are assigned, update your wiring accordingly.

## Common Issues

### Issue 1: HAL_UART_Transmit Blocks Forever

If `HAL_MAX_DELAY` is causing issues, try:

```c
// Instead of HAL_MAX_DELAY, use timeout:
HAL_UART_Transmit(&huart2,
                  (uint8_t*)msg,
                  sizeof(msg) - 1,
                  100);  // 100ms timeout
```

### Issue 2: UART Not Initialized

Make sure `MX_USART2_UART_Init()` is called in `main()`:

```c
MX_GPIO_Init();
MX_USART2_UART_Init();  // ← Must be here!
```

### Issue 3: Wrong UART Handle

Verify `huart2` is defined and matches USART2:

```c
UART_HandleTypeDef huart2;  // Must exist
```

## Quick Test: Send More Frequent Messages

Try sending every 100ms to make it easier to detect:

```c
// Change from 1000ms to 100ms
if (now - stm32UartLastTick >= 100) {
    const char msg[] = "TEST\n";
    HAL_UART_Transmit(&huart2,
                      (uint8_t*)msg,
                      sizeof(msg) - 1,
                      HAL_MAX_DELAY);
    stm32UartLastTick = now;
}
```

Then Pi should see messages every 100ms instead of 1 second.

