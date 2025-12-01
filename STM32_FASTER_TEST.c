// ========================================
// STM32 Faster UART Test Code
// Send messages every 100ms instead of 1000ms
// This makes it MUCH easier to detect on Pi
// ========================================

// Replace your UART send code with this:

/* USER CODE BEGIN 3 */
uint8_t pattern = ReadDipSwitch();
DisplayOnLedBar(pattern);

uint32_t now = HAL_GetTick();

// Send UART heartbeat every 100ms (10x faster for testing)
if (now - stm32UartLastTick >= 100)  // Changed from 1000 to 100
{
    const char msg[] = "STM32_ALIVE\n";
    HAL_UART_Transmit(&huart2,
                      (uint8_t*)msg,
                      sizeof(msg) - 1,
                      HAL_MAX_DELAY);
    stm32UartLastTick = now;
}

HAL_Delay(10);
/* USER CODE END 3 */

// ========================================
// ALSO TRY: Add LED blink when UART sends
// ========================================

// This will blink LED1 every time UART sends (every 100ms)
// You should see LED1 blinking rapidly - confirms UART send is being called

/* USER CODE BEGIN 3 */
uint8_t pattern = ReadDipSwitch();
DisplayOnLedBar(pattern);

uint32_t now = HAL_GetTick();

// Send UART heartbeat every 100ms
if (now - stm32UartLastTick >= 100)
{
    const char msg[] = "STM32_ALIVE\n";
    HAL_UART_Transmit(&huart2,
                      (uint8_t*)msg,
                      sizeof(msg) - 1,
                      HAL_MAX_DELAY);
    stm32UartLastTick = now;
    
    // BLINK LED1 to show UART send was called
    HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_0); // Toggle LED1
}

HAL_Delay(10);
/* USER CODE END 3 */

// ========================================
// DIAGNOSTIC: What to look for
// ========================================
//
// After flashing this:
// 1. LED1 should blink rapidly (every 100ms)
//    → If YES: UART send function is being called ✅
//    → If NO: Code not reaching UART send ❌
//
// 2. Pi should see messages 10x faster (every 100ms)
//    → Much easier to detect
//
// 3. If LED1 blinks but Pi sees nothing:
//    → STM32 USART2 hardware issue
//    → Wiring problem
//    → Wrong pins

