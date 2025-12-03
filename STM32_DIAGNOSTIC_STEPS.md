# STM32 Still Not Sending - Diagnostic Steps

## Your Code Looks Correct!

Your STM32 code has:
- ✅ Heartbeat added correctly
- ✅ UART2 initialized at 38400 baud
- ✅ Sends "STM32_ALIVE\n" every 1 second

But still no messages received. Let's diagnose:

## Step 1: Verify STM32 is Actually Running

**Check:**
- Is the STM32 powered on? (LED should be on)
- Did the flash succeed? (Check STM32CubeProgrammer)
- Is the code actually running? (Try pressing the button - does it do anything?)

## Step 2: Verify UART2 Pins in STM32CubeMX

**Critical Check:**
- In STM32CubeMX, verify:
  - **PA2** is configured as **USART2_TX** (this is the pin that sends data)
  - **PA3** is configured as **USART2_RX** (this is the pin that receives data)

**Common mistake:** PA2 might not be set as UART TX in CubeMX!

## Step 3: Verify Wiring

**Correct wiring:**
- Pi **GPIO15 (RX)** → STM32 **PA2 (TX)** ⚠️ **RX receives from TX**
- Pi **GPIO14 (TX)** → STM32 **PA3 (RX)** ⚠️ **TX sends to RX**
- **GND → GND** (MUST be connected!)

**Double-check:**
- Are the wires actually connected?
- Is GND shared?
- Are RX/TX crossed (not straight through)?

## Step 4: Test with Multimeter/Oscilloscope (if available)

If you have a multimeter or scope:
- Check if PA2 has any voltage changes (should see activity when sending)
- Verify the pin is actually configured as UART output

## Step 5: Alternative Test - Use Different UART

If available, test if STM32 UART1 works:
- Connect Pi to STM32 UART1 instead
- Temporarily change code to use `huart1` instead of `huart2`
- See if that works

## Step 6: Check Pi UART Device

On Pi, verify which UART device is correct:

```bash
# Check available UART devices
ls -l /dev/ttyAMA* /dev/serial0 /dev/ttyS*

# Try reading from different devices
timeout 2 cat /dev/ttyAMA0
timeout 2 cat /dev/serial0
```

## Most Likely Issues:

1. **PA2 not configured as UART2_TX in STM32CubeMX**
   - Most common issue!
   - Check CubeMX pinout view

2. **Wrong wiring**
   - RX/TX not crossed
   - GND not connected

3. **Wrong UART device on Pi**
   - Try `/dev/serial0` instead of `/dev/ttyAMA0`

4. **Code not actually running**
   - Flash might have failed
   - STM32 might not be powered

## Next Steps:

1. **Check STM32CubeMX pinout** - Verify PA2 = USART2_TX
2. **Double-check wiring** - Especially GND connection
3. **Try different UART device** on Pi if available

