# Raspberry Pi UART Setup

## Step 1: Enable UART on Pi 5

```bash
# Open configuration
sudo raspi-config
```

Navigate:
1. **Interface Options** → **Serial Port**
2. When asked "Login shell over serial?" → **No**
3. When asked "Enable serial port hardware?" → **Yes**
4. Exit and **reboot**:
   ```bash
   sudo reboot
   ```

---

## Step 2: Verify UART Device

After reboot:

```bash
# Check if serial device exists
ls -l /dev/serial0

# Should show something like: lrwxrwxrwx ... /dev/serial0 -> ttyAMA0
```

If it doesn't exist, you may need to use `/dev/ttyAMA0` directly.

---

## Step 3: Install Python Serial Library

```bash
# Install pyserial
python3 -m pip install pyserial --break-system-packages

# Or use system package
sudo apt-get install python3-serial
```

---

## Step 4: Run UART Test Script

Copy the `pi_uart_test.py` script to your Pi, then:

```bash
# Make executable
chmod +x pi_uart_test.py

# Run it
python3 pi_uart_test.py
```

**Expected output:**
```
[15:23:01] #1 | Message: 'STM32_ALIVE'
   ✅ Correct format!

[15:23:02] #2 | 1.003s since last | Message: 'STM32_ALIVE'
   ✅ Correct format!
```

---

## Troubleshooting

### Permission Denied Error

```bash
# Add your user to dialout group
sudo usermod -a -G dialout $USER

# Log out and back in (or reboot)
```

### Device Not Found

```bash
# Check available serial devices
ls -l /dev/tty*

# Try different devices:
# /dev/serial0 (recommended)
# /dev/ttyAMA0 (alternative)
# /dev/ttyS0 (some Pi models)
```

### No Data Received

1. **Check wiring:**
   - STM32 TX → Pi RX
   - STM32 RX → Pi TX
   - GND connected

2. **Verify baudrate:**
   - Both STM32 and Pi must use same baudrate (38400)

3. **Check STM32 is sending:**
   - Verify STM32 code is flashed correctly
   - Check with oscilloscope/logic analyzer if available

---

## Hardware Verification

**Pi 5 GPIO Header (40-pin):**
```
Pin 8  = GPIO14 = TXD (UART0)
Pin 10 = GPIO15 = RXD (UART0)
Pin 6  = GND
Pin 14 = GND
```

**STM32:**
- PA2 = USART2 TX
- PA3 = USART2 RX
- GND = Any ground pin

**Connection:**
```
STM32 PA2 (TX) → Pi Pin 10 (RXD)
STM32 PA3 (RX) → Pi Pin 8  (TXD)
STM32 GND      → Pi Pin 6  (GND)
```

---

## Testing Checklist

- [ ] UART enabled in raspi-config
- [ ] Pi rebooted after enabling UART
- [ ] `/dev/serial0` exists
- [ ] pyserial installed
- [ ] Hardware wired correctly (TX/RX crossed)
- [ ] GND connected
- [ ] STM32 flashed with heartbeat code
- [ ] STM32 running (LEDs working)
- [ ] Test script running and receiving messages

---

## Next: Once UART Works

After you see "STM32_ALIVE" messages:
1. ✅ UART communication confirmed
2. ✅ STM32 is sending correctly
3. ✅ Pi is receiving correctly
4. ✅ Ready to integrate with Azure!

