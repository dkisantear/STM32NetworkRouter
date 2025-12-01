# STM32 Code Changes - UART Heartbeat

## Overview

Add a simple heartbeat message over UART2 every 1 second while keeping your existing DIP switch and LED functionality.

---

## Hardware Connections

**STM32 ↔ Pi 5 UART Wiring:**

```
STM32          Pi 5 (40-pin header)
-----          --------------------
PA2 (TX)  →    Pin 10 (GPIO15, RXD)
PA3 (RX)  →    Pin 8  (GPIO14, TXD)
GND       →    Any GND pin
```

**⚠️ Important:**
- Cross TX/RX (STM32 TX → Pi RX, STM32 RX → Pi TX)
- Use 3.3V UART pins on Pi (NOT 5V pins)
- Both STM32 and Pi 5 are 3.3V - safe to connect directly

---

## STM32 Code Changes

### Step 1: Add Timer Variable

In your `main.c` file, find:

```c
/* USER CODE BEGIN PV */

/* USER CODE END PV */
```

**Replace with:**

```c
/* USER CODE BEGIN PV */
uint32_t stm32UartLastTick = 0;
/* USER CODE END PV */
```

This tracks when we last sent the heartbeat.

---

### Step 2: Update Main Loop

Find your main loop (in the `/* USER CODE BEGIN 3 */` section):

```c
/* USER CODE BEGIN 3 */
while (1)
{
    uint8_t pattern = ReadDipSwitch();
    DisplayOnLedBar(pattern);
    HAL_Delay(10);
}
/* USER CODE END 3 */
```

**Replace with:**

```c
/* USER CODE BEGIN 3 */
while (1)
{
    // Your existing DIP switch and LED code (keep as-is)
    uint8_t pattern = ReadDipSwitch();
    DisplayOnLedBar(pattern);
    
    // Send UART heartbeat every 1000 ms
    uint32_t now = HAL_GetTick();
    if (now - stm32UartLastTick >= 1000)
    {
        const char msg[] = "STM32_ALIVE\n";
        HAL_UART_Transmit(&huart2,
                          (uint8_t*)msg,
                          sizeof(msg) - 1,  // -1 to exclude null terminator
                          HAL_MAX_DELAY);
        stm32UartLastTick = now;
    }
    
    HAL_Delay(10);
}
/* USER CODE END 3 */
```

---

## What This Does

1. ✅ **Keeps your existing code**: DIP switch and LED functionality unchanged
2. ✅ **Adds heartbeat**: Sends "STM32_ALIVE\n" every 1 second over UART2
3. ✅ **Non-blocking**: Uses `HAL_GetTick()` timing, doesn't block your main loop

---

## Verify UART2 Configuration

Make sure your STM32CubeMX setup has:

- **USART2** enabled
- **PA2** = TX
- **PA3** = RX
- **Baudrate**: 38400
- **Word Length**: 8 bits
- **Parity**: None
- **Stop Bits**: 1
- **Flow Control**: None

---

## Build & Flash

1. **Build** the project in STM32CubeIDE
2. **Flash** to your STM32 board
3. **Verify** the LEDs still work with DIP switches (existing functionality preserved)

---

## Testing

After flashing:
1. **Wire up** the UART connections (see Hardware section above)
2. **Run** the Pi test script: `python3 pi_uart_test.py`
3. **Expected output**: You should see "STM32_ALIVE" messages every ~1 second

---

## Troubleshooting

### No messages received on Pi:
- Check wiring (TX/RX crossed correctly?)
- Verify UART is enabled on Pi: `sudo raspi-config`
- Check baudrate matches (38400)
- Verify `/dev/serial0` exists: `ls -l /dev/serial0`

### Garbage characters:
- Baudrate mismatch - verify both are 38400
- Wrong UART device on Pi - try `/dev/ttyAMA0` instead of `/dev/serial0`

### STM32 not sending:
- Check USART2 is enabled in CubeMX
- Verify `huart2` handle exists
- Check PA2/PA3 pins are configured for USART2

---

## Next Steps

Once UART communication is confirmed working:
- ✅ STM32 sends "STM32_ALIVE" every second
- ✅ Pi receives and displays messages
- ✅ Then we'll integrate with Azure Functions

