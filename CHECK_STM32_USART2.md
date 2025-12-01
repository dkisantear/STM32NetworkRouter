# Verify STM32 USART2 is Actually Working

## Critical Check: Is USART2 Actually Initialized?

Even though your code compiles and DIP switches work, USART2 might not be initialized correctly.

### Check 1: Verify MX_USART2_UART_Init() is Called

In your `main.c`, look for:

```c
int main(void)
{
  HAL_Init();
  SystemClock_Config();
  MX_GPIO_Init();
  MX_USART2_UART_Init();  // ← THIS MUST BE HERE!
  
  // ... rest of code
}
```

If `MX_USART2_UART_Init()` is **missing or commented out**, USART2 won't work!

### Check 2: Verify USART2 is Enabled in CubeMX

Open your STM32CubeMX `.ioc` file:

1. Go to **Connectivity** → **USART2**
2. Check **Mode**:
   - Should be: **Asynchronous**
   - NOT: **Disabled**
3. Check **Configuration** tab:
   - Baud Rate: **38400**
   - Word Length: **8 Bits**
   - Parity: **None**
   - Stop Bits: **1**

### Check 3: Verify Pin Assignment in CubeMX

In STM32CubeMX **Pinout** view:

1. Find **USART2**
2. Check pins show:
   - **USART2_TX** on **PA2**
   - **USART2_RX** on **PA3**

If different pins are assigned, that's your problem!

### Check 4: Add Error Checking

Add this to verify UART transmission succeeds:

```c
if (now - stm32UartLastTick >= 1000)
{
    const char msg[] = "STM32_ALIVE\n";
    HAL_StatusTypeDef status = HAL_UART_Transmit(&huart2,
                                                  (uint8_t*)msg,
                                                  sizeof(msg) - 1,
                                                  HAL_MAX_DELAY);
    
    // Check if transmission succeeded
    if (status != HAL_OK) {
        // Blink LED to show error
        HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_0);
    }
    
    stm32UartLastTick = now;
}
```

If LED blinks, transmission is failing!

### Check 5: Verify huart2 is Defined

Make sure this exists in `main.c`:

```c
UART_HandleTypeDef huart2;  // Must be defined globally
```

### Check 6: Try Different USART

If USART2 isn't working, try USART1 temporarily:

```c
// Change from USART2 to USART1
UART_HandleTypeDef huart1;  // Change handle name

// In MX_USART2_UART_Init(), change to USART1
huart1.Instance = USART1;  // Use USART1 instead
// ... configure USART1 pins ...

// In main loop:
HAL_UART_Transmit(&huart1, ...);  // Use USART1
```

Then wire to USART1 pins instead.

### Check 7: Verify Clock Configuration

USART2 needs the APB1 clock enabled. In STM32CubeMX:

1. Go to **Clock Configuration**
2. Make sure **APB1** clock is enabled and has a frequency
3. USART2 runs on APB1 clock

### Check 8: Use Oscilloscope/Multimeter

If you have access:

1. **Probe PA2 pin** (USART2_TX)
2. **Set scope to 38400 baud**
3. **Look for serial data** every 1 second
4. **If you see data**: STM32 is sending ✅
5. **If no data**: STM32 USART2 not working ❌

### Quick Test: Send Continuously

Change your code to send continuously (no delay):

```c
// Remove the 1-second delay - send as fast as possible
const char msg[] = "STM32_ALIVE\n";
HAL_UART_Transmit(&huart2,
                  (uint8_t*)msg,
                  sizeof(msg) - 1,
                  HAL_MAX_DELAY);
HAL_Delay(100);  // Just a small delay
```

If Pi sees a flood of messages, UART works! If still nothing, hardware issue.

## Most Likely Issues

1. **USART2 not initialized** → Add `MX_USART2_UART_Init()` call
2. **Wrong pins in CubeMX** → Verify PA2/PA3 assignment
3. **USART2 disabled in CubeMX** → Check Mode is Asynchronous
4. **Clock not configured** → Verify APB1 clock is enabled
5. **Hardware fault** → Try different USART (USART1)

