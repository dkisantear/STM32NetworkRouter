// Minimal STM32 code to test UART2 transmission
// This is a template - verify it matches your STM32 configuration

#include "main.h"
#include "usart.h"  // Make sure this includes UART2

// Assuming you have: extern UART_HandleTypeDef huart2;

int main(void) {
    // Initialize HAL and UART2
    HAL_Init();
    SystemClock_Config();
    MX_GPIO_Init();
    MX_USART2_UART_Init();  // <-- CRITICAL: Must initialize UART2
    
    // Main loop - send heartbeat every 1 second
    while (1) {
        const char msg[] = "STM32_ALIVE\n";
        
        // Send via UART2
        HAL_UART_Transmit(&huart2, (uint8_t*)msg, sizeof(msg) - 1, HAL_MAX_DELAY);
        
        // Wait 1 second before sending again
        HAL_Delay(1000);
    }
}

/*
IMPORTANT CHECKS:

1. In STM32CubeMX:
   - Enable USART2
   - Configure PA2 as USART2_TX
   - Configure PA3 as USART2_RX
   - Set baud rate to 38400

2. In main.h or usart.h:
   - Must have: extern UART_HandleTypeDef huart2;

3. In main.c:
   - Must call: MX_USART2_UART_Init();

4. Verify:
   - Baud rate = 38400 (not 115200 or other)
   - PA2 = TX (sends data)
   - PA3 = RX (receives data)
*/

