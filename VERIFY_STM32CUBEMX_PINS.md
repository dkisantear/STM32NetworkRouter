# CRITICAL: Verify STM32CubeMX Pin Configuration

## Most Common Issue: PA2 Not Set as UART2_TX

Your STM32 code is correct, but if **PA2 is not configured as USART2_TX** in STM32CubeMX, it won't send data!

## How to Check in STM32CubeMX:

1. **Open your STM32CubeMX project**
2. **Look at the pinout view** (the chip diagram)
3. **Find PA2 pin**
4. **Verify it shows:**
   - **USART2_TX** (should be highlighted/colored)
   - NOT just "GPIO_Input" or something else

5. **Find PA3 pin**
6. **Verify it shows:**
   - **USART2_RX**

## If PA2 is NOT set as USART2_TX:

1. In STM32CubeMX:
   - Click on **PA2** pin
   - Select **USART2_TX** from the dropdown
   - Click on **PA3** pin
   - Select **USART2_RX** from the dropdown

2. **Generate code again** (click "Generate Code" button)

3. **Re-flash** your STM32

## Visual Check:

In STM32CubeMX pinout view, you should see:
- **PA2** → Green/colored with label "USART2_TX"
- **PA3** → Green/colored with label "USART2_RX"

## Alternative: Check in Generated Code

Open `stm32f3xx_hal_msp.c` and look for:

```c
void HAL_UART_MspInit(UART_HandleTypeDef* uartHandle)
{
    // Should see PA2 and PA3 configured here
    // Look for GPIO_AF7_USART2 or similar
}
```

If PA2/PA3 aren't configured for UART2 in the MSP init, that's the problem!

