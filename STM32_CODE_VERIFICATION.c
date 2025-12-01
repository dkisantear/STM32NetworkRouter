// ========================================
// STM32 Code Verification - Enhanced Version
// Add this LED blink to confirm code is running
// ========================================

// In your main loop (/* USER CODE BEGIN 3 */), replace with:

/* USER CODE BEGIN 3 */
uint8_t pattern = ReadDipSwitch();
DisplayOnLedBar(pattern);

// Get current time
uint32_t now = HAL_GetTick();

// BLINK LED1 every 500ms to verify code is running
static uint32_t ledBlinkTick = 0;
if (now - ledBlinkTick >= 500) {
    HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_0); // Toggle LED1 (PB0)
    ledBlinkTick = now;
}

// Send UART heartbeat every 1000ms (or try 100ms for testing)
if (now - stm32UartLastTick >= 1000)  // Try 100 for faster testing
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
// What to Check:
// ========================================
// 
// 1. After flashing this code:
//    → LED1 should blink every 0.5 seconds
//    → If LED1 blinks: Code is running ✅
//    → If LED1 doesn't blink: Code not running ❌
//
// 2. If LED1 blinks but Pi still gets no messages:
//    → Problem is UART hardware or wiring
//    → Check PA2 pin with multimeter
//    → Try different UART device on Pi
//
// 3. For faster UART testing:
//    → Change 1000 to 100 in the UART send condition
//    → Messages will send 10x faster (easier to detect)
//    → Remember to change back to 1000ms after testing

