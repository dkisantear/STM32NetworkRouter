# STM32 Setup Checklist - NO DATA RECEIVED

## ✅ CONFIRMED: STM32 is NOT sending data to Pi

Since `pi_check_stm32_sending.py` showed "NO MESSAGES RECEIVED", we need to verify:

## Checklist:

### 1. STM32 Code Verification

Check your `main.c` file:

- [ ] **UART2 is initialized**
  ```c
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 38400;  // Must match!
  ```

- [ ] **UART2 pins are configured**
  - PA2 = TX (must be configured as UART TX)
  - PA3 = RX (must be configured as UART RX)

- [ ] **UART2 is enabled in MX_GPIO_Init() or similar**
  - Check `MX_USART2_UART_Init()` is called

- [ ] **Code is sending data in a loop**
  ```c
  while (1) {
      const char msg[] = "STM32_ALIVE\n";
      HAL_UART_Transmit(&huart2, (uint8_t*)msg, sizeof(msg) - 1, HAL_MAX_DELAY);
      HAL_Delay(1000);  // Send every 1 second
  }
  ```

### 2. STM32 Hardware Configuration

- [ ] **STM32 is powered on** (LED on board should be on)
- [ ] **STM32 code is flashed** (check STM32CubeProgrammer shows successful flash)
- [ ] **Code is running** (check if any LEDs blink or board responds)

### 3. Wiring Verification

- [ ] **Pi GPIO15 (RX) → STM32 PA2 (TX)**
- [ ] **Pi GPIO14 (TX) → STM32 PA3 (RX)**
- [ ] **GND → GND** (shared ground is critical!)

### 4. UART Configuration

**On STM32:**
- [ ] UART2 baud rate = **38400**
- [ ] UART2 mode = **Asynchronous**
- [ ] Data bits = **8**
- [ ] Stop bits = **1**
- [ ] Parity = **None**

**On Pi:**
- [ ] UART device = `/dev/ttyAMA0`
- [ ] Baud rate = **38400** (matches STM32)

## Most Common Issues:

1. **STM32 code not actually sending data**
   - Check if you have `HAL_UART_Transmit()` in your main loop
   - Make sure it's called repeatedly (in a while loop)

2. **UART2 not enabled**
   - Check STM32CubeMX configuration
   - Verify `MX_USART2_UART_Init()` is called in `main()`

3. **Wrong pins**
   - PA2 must be TX (not PA3)
   - PA3 must be RX (not PA2)

4. **Baud rate mismatch**
   - Both must be exactly **38400**

5. **No shared GND**
   - GND from Pi must connect to GND on STM32

## Next Steps:

1. **Share your STM32 `main.c` file** - I can check if it's sending data
2. **Verify wiring** - Double-check all connections
3. **Check STM32CubeMX config** - Make sure UART2 is enabled
4. **Test with STM32CubeMonitor** - If available, verify STM32 is sending via serial monitor

## What to Check First:

**Paste your STM32 `main.c` here so I can verify:**
- Is UART2 initialized?
- Is it sending data?
- Are the pins correct?

