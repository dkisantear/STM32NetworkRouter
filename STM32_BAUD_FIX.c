// ========================================
// FIX: Change STM32 Baud Rate to Match Pi
// ========================================

// In your main.c file, find this function:

static void MX_USART2_UART_Init(void)
{
  // ... existing code ...
  
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;  // ❌ WRONG - Change this!
  
  // ... rest of code ...
}

// ========================================
// CHANGE TO:
// ========================================

static void MX_USART2_UART_Init(void)
{
  // ... existing code ...
  
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 38400;  // ✅ CORRECT - Matches Pi scripts
  
  // ... rest of code ...
}

// ========================================
// OR change in STM32CubeMX:
// ========================================
//
// 1. Open your .ioc file
// 2. Connectivity → USART2
// 3. Set Baud Rate = 38400
// 4. Save and Generate Code
// 5. Rebuild and flash
//
// ========================================

