# STM32 USART2 Pin Verification

## Critical Check: Verify USART2 Pin Assignment

Your STM32 code uses **USART2**, but we need to verify which pins it's actually connected to.

### Step 1: Check CubeMX Configuration

1. Open your STM32CubeMX project
2. Look at the **Pinout** view
3. Find **USART2** in the peripheral list
4. Check which pins show:
   - **USART2_TX** (transmit)
   - **USART2_RX** (receive)

### Common STM32 USART2 Pin Assignments:

| STM32 Board | USART2_TX | USART2_RX |
|------------|-----------|-----------|
| STM32F4 Discovery | PA2 | PA3 |
| STM32F0/F1 | PA2 | PA3 |
| STM32F3 | PA2 | PA3 |
| STM32L4 | PA2 | PA3 |
| Some variants | PD5 | PD6 |
| Some variants | PA9 | PA10 |

### Step 2: Verify in main.h or .ioc file

Look for pin definitions like:
```c
#define USART2_TX_Pin GPIO_PIN_2
#define USART2_TX_GPIO_Port GPIOA
#define USART2_RX_Pin GPIO_PIN_3
#define USART2_RX_GPIO_Port GPIOA
```

### Step 3: Double-Check Your Wiring

Based on your code, USART2 is likely:
- **TX** = PA2 (STM32 sends data from here)
- **RX** = PA3 (STM32 receives data here)

**Correct Wiring:**
```
STM32 PA2 (TX) → Pi Pin 10 (RXD/GPIO15)  ← STM32 sends TO Pi
STM32 PA3 (RX) → Pi Pin 8  (TXD/GPIO14)  ← Pi sends TO STM32
GND            → GND
```

### Step 4: Alternative - Check with STM32CubeIDE

If you're using STM32CubeIDE:
1. Open the `.ioc` file
2. Go to **Connectivity → USART2**
3. Check **Mode** → should be "Asynchronous"
4. Check **Parameters**:
   - Baud Rate: 38400
   - Word Length: 8 Bits
   - Parity: None
   - Stop Bits: 1
   - Hardware Flow Control: None
5. Check **Pinout** tab to see exact pin assignments

### Troubleshooting: Add LED Blink to Verify Code is Running

Add this to your STM32 main loop to confirm the code is executing:

```c
// In USER CODE BEGIN 3:
uint8_t pattern = ReadDipSwitch();
DisplayOnLedBar(pattern);

// BLINK LED1 to show code is running
static uint32_t ledBlinkTick = 0;
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

If LED1 blinks every 0.5 seconds, your code is running. If not, there's a flash/debug issue.

### Debug: Check UART with Oscilloscope/Logic Analyzer

If you have access:
- Probe PA2 (USART2_TX) on STM32
- You should see pulses every ~1 second when message is sent
- Verify 38400 baud rate matches

### Quick Fix: Try Different Baud Rates

Sometimes baud rate mismatch causes silent failures. Try:

```c
// In MX_USART2_UART_Init(), change:
huart2.Init.BaudRate = 9600;  // Try slower first
```

Then update Pi script to match:
```python
BAUDRATE = 9600  # Match STM32
```

