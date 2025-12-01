# Complete UART Test Guide - STM32 ↔ Pi 5

## Overview

This guide will help you verify UART communication between your STM32 board and Raspberry Pi 5 before integrating with Azure.

---

## Part 1: STM32 Code Changes

### Files to Modify: `main.c`

#### Change 1: Add Timer Variable

**Location:** Find `/* USER CODE BEGIN PV */` section

**Add:**
```c
/* USER CODE BEGIN PV */
uint32_t stm32UartLastTick = 0;
/* USER CODE END PV */
```

#### Change 2: Update Main Loop

**Location:** Find your main loop in `/* USER CODE BEGIN 3 */` section

**Current code:**
```c
while (1)
{
    uint8_t pattern = ReadDipSwitch();
    DisplayOnLedBar(pattern);
    HAL_Delay(10);
}
```

**Replace with:**
```c
while (1)
{
    // Keep your existing DIP/LED code
    uint8_t pattern = ReadDipSwitch();
    DisplayOnLedBar(pattern);
    
    // Send UART heartbeat every 1000 ms
    uint32_t now = HAL_GetTick();
    if (now - stm32UartLastTick >= 1000)
    {
        const char msg[] = "STM32_ALIVE\n";
        HAL_UART_Transmit(&huart2,
                          (uint8_t*)msg,
                          sizeof(msg) - 1,  // -1 excludes null terminator
                          HAL_MAX_DELAY);
        stm32UartLastTick = now;
    }
    
    HAL_Delay(10);
}
```

### STM32 Configuration Checklist

- ✅ USART2 enabled in CubeMX
- ✅ PA2 = TX, PA3 = RX
- ✅ Baudrate = 38400
- ✅ Word Length = 8 bits
- ✅ Parity = None
- ✅ Stop Bits = 1

**Build and flash to STM32.**

---

## Part 2: Pi 5 Setup

### Step 1: Enable UART

```bash
sudo raspi-config
```

Navigate:
- **Interface Options** → **Serial Port**
- "Login shell over serial?" → **No**
- "Enable serial port hardware?" → **Yes**
- **Reboot**: `sudo reboot`

### Step 2: Verify Device

After reboot:
```bash
ls -l /dev/serial0
# Should show: lrwxrwxrwx ... /dev/serial0 -> ttyAMA0
```

### Step 3: Install Dependencies

```bash
# Install pyserial
python3 -m pip install pyserial --break-system-packages
# OR
sudo apt-get install python3-serial
```

---

## Part 3: Hardware Wiring

**STM32 ↔ Pi 5 Connections:**

```
STM32          →    Pi 5 (40-pin header)
----------------    --------------------
PA2 (TX)       →    Pin 10 (GPIO15, RXD)
PA3 (RX)       →    Pin 8  (GPIO14, TXD)
GND            →    Pin 6  or Pin 14 (GND)
```

**⚠️ Important:**
- **Cross TX/RX**: STM32 TX goes to Pi RX, STM32 RX goes to Pi TX
- **Use 3.3V pins**: Both STM32 and Pi 5 are 3.3V - safe to connect directly
- **DO NOT** use 5V pins on Pi header

---

## Part 4: Testing

### Copy Test Script to Pi

Copy `pi_uart_test.py` to your Pi (via SCP, USB drive, or copy/paste).

### Run Test

```bash
# Make executable
chmod +x pi_uart_test.py

# Run
python3 pi_uart_test.py
```

### Expected Output

```
============================================================
STM32 UART Test - Raspberry Pi
============================================================
Device: /dev/serial0
Baudrate: 38400
Timeout: 1.0s
============================================================

📡 Opening /dev/serial0...
✅ Serial port opened successfully!

👂 Listening for STM32 messages...
   (Expected: 'STM32_ALIVE' every ~1 second)
   Press Ctrl+C to stop

[15:23:01] #1 | Message: 'STM32_ALIVE'
   ✅ Correct format!

[15:23:02] #2 | 1.003s since last | Message: 'STM32_ALIVE'
   ✅ Correct format!

[15:23:03] #3 | 1.001s since last | Message: 'STM32_ALIVE'
   ✅ Correct format!
```

**If you see this:** ✅ **UART communication is working!**

---

## Troubleshooting

### No Messages Received

1. **Check wiring:**
   - Verify TX/RX are crossed correctly
   - Check GND is connected
   - Try swapping TX/RX (sometimes wiring is reversed)

2. **Check UART configuration:**
   - Verify baudrate matches (38400)
   - Check UART is enabled on Pi
   - Try different device: `/dev/ttyAMA0` instead of `/dev/serial0`

3. **Check STM32:**
   - Verify code is flashed correctly
   - Check LEDs still work (confirms STM32 is running)
   - Verify USART2 is enabled in CubeMX

### Garbage Characters

- **Baudrate mismatch**: Verify both STM32 and Pi use 38400
- **Wrong parity/stop bits**: Check UART configuration matches

### Permission Errors

```bash
# Add user to dialout group
sudo usermod -a -G dialout $USER
# Log out and back in, or reboot
```

---

## Success Criteria

✅ STM32 code compiled and flashed  
✅ DIP switch and LEDs still work (existing functionality preserved)  
✅ Pi UART enabled and configured  
✅ Hardware wired correctly  
✅ Test script receives "STM32_ALIVE" every ~1 second  
✅ No errors or garbage data  

---

## Next Steps (After UART Works)

Once you confirm UART communication is working:

1. ✅ UART verified
2. → Create Azure endpoint for STM32 status
3. → Create Pi bridge script (UART → Azure)
4. → Add frontend component to display STM32 status

But for now, let's just get UART working first!

