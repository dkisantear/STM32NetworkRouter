// ADD THIS TO YOUR main.c
// This shows the changes needed to add periodic heartbeat

/* USER CODE BEGIN PV */
uint32_t lastHeartbeatTick = 0;  // Add this variable
#define HEARTBEAT_INTERVAL_MS 1000  // Send heartbeat every 1 second
/* USER CODE END PV */

// ... rest of your code ...

int main(void)
{
  /* MCU Configuration--------------------------------------------------------*/
  HAL_Init();
  SystemClock_Config();
  MX_GPIO_Init();
  MX_DMA_Init();
  MX_USART2_UART_Init();
  MX_USART1_UART_Init();

  /* USER CODE BEGIN 2 */
  lastHeartbeatTick = HAL_GetTick();  // Initialize heartbeat timer
  /* USER CODE END 2 */

  /* Infinite loop */
  while (1)
  {
    /* USER CODE BEGIN 3 */
    
    // ============================================
    // ADD THIS: Periodic heartbeat every 1 second
    // ============================================
    uint32_t now = HAL_GetTick();
    if (now - lastHeartbeatTick >= HEARTBEAT_INTERVAL_MS)
    {
        const char heartbeat[] = "STM32_ALIVE\n";
        HAL_UART_Transmit(&huart2, (uint8_t*)heartbeat, sizeof(heartbeat) - 1, HAL_MAX_DELAY);
        lastHeartbeatTick = now;
    }
    
    // Your existing button code (keep this as-is)
    if (HAL_GPIO_ReadPin(TX_BUTTON_GPIO_Port, TX_BUTTON_Pin) == GPIO_PIN_SET)
    {
      // ... your existing button code ...
      for (volatile int d = 0; d < 3000; d++) { __NOP(); }

      if (HAL_GPIO_ReadPin(TX_BUTTON_GPIO_Port, TX_BUTTON_Pin) == GPIO_PIN_SET)
      {
        uint8_t dipValue = ReadDipSwitch();
        uint8_t mode = ReadModeSwitch();

        if (mode == 0)
        {
            sendData(dipValue);
        }
        else
        {
            char msg[16];
            int len = snprintf(msg, sizeof(msg), "VAL:%X\r\n", dipValue & 0x0F);
            HAL_UART_Transmit(&huart2, (uint8_t*)msg, len, 100);
        }

        while (HAL_GPIO_ReadPin(TX_BUTTON_GPIO_Port, TX_BUTTON_Pin) == GPIO_PIN_SET)
        {
          for (volatile int d = 0; d < 3000; d++) { __NOP(); }
        }
      }
    }

    /* USER CODE END 3 */
  }
}

