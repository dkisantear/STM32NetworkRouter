# Problem Found: STM32 Only Sends on Button Press

## Issue Identified:

Your STM32 code **only sends data when the button is pressed**. It doesn't send a continuous heartbeat that the bridge script can detect.

Looking at your code:
- ✅ UART2 is initialized correctly (38400 baud)
- ✅ UART2 is configured properly
- ❌ **NO periodic heartbeat** - only sends when `TX_BUTTON_Pin` is pressed

## Solution: Add Periodic Heartbeat

Add this to your `main.c` to send a heartbeat every 1 second:

```c
/* USER CODE BEGIN PV */
uint32_t lastHeartbeatTick = 0;
#define HEARTBEAT_INTERVAL_MS 1000  // 1 second
/* USER CODE END PV */
```

Then in your `while(1)` loop, add:

```c
while (1)
{
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
    
    // Send periodic heartbeat via UART2
    uint32_t now = HAL_GetTick();
    if (now - lastHeartbeatTick >= HEARTBEAT_INTERVAL_MS)
    {
        const char heartbeat[] = "STM32_ALIVE\n";
        HAL_UART_Transmit(&huart2, (uint8_t*)heartbeat, sizeof(heartbeat) - 1, HAL_MAX_DELAY);
        lastHeartbeatTick = now;
    }

    // Your existing button code here...
    if (HAL_GPIO_ReadPin(TX_BUTTON_GPIO_Port, TX_BUTTON_Pin) == GPIO_PIN_SET)
    {
        // ... existing button code ...
    }

    /* USER CODE END 3 */
}
```

This will:
1. Send "STM32_ALIVE\n" every 1 second via UART2
2. Keep your button functionality intact
3. Allow the bridge script to detect the STM32 is online

