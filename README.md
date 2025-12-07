# STM32NetworkRouter

CPE185 Final Project - Real-time communication and monitoring system for STM32 boards with Raspberry Pi gateway and web dashboard.

## Project Structure

```
├── STM32Master/          # Master STM32 board code
├── STM32Uart/            # UART STM32 board code (add main.c)
├── STM32Serial/          # Serial STM32 board code (add main.c)
├── STM32Parallel/        # Parallel STM32 board code (add main.c)
├── RaspberryPi5/         # Raspberry Pi gateway scripts and services
├── Azure/                # Azure Functions API backend
├── LoveableWebsite/      # React frontend web application
├── api/                  # Azure Functions API (root level)
├── src/                  # Frontend source code (root level)
├── .gitignore
└── README.md
```

## Components

### STM32Master
Master STM32 board that coordinates communication with other boards. Handles UART communication with Raspberry Pi and manages switch state synchronization.

### STM32Uart, STM32Serial, STM32Parallel
Individual STM32 board implementations for different communication modes. Add `main.c` files for each board.

### RaspberryPi5
Gateway scripts running on Raspberry Pi 5:
- `pi_stm32_bridge.py` - Bridges UART communication between STM32 and Azure
- `pi_gateway_heartbeat.py` - Sends gateway status to Azure
- `setup_pi_services.sh` - Setup script for systemd services
- `gateway-heartbeat.service` - Systemd service for gateway heartbeat
- `stm32-bridge.service` - Systemd service for STM32 bridge

### Azure
Azure Functions API endpoints for:
- Gateway status tracking
- STM32 status monitoring
- Command handling
- Latency data collection

### LoveableWebsite
React + TypeScript frontend application for real-time monitoring and control.

## Setup

### Raspberry Pi Setup
1. Copy files from `RaspberryPi5/` to Raspberry Pi
2. Run `setup_pi_services.sh` to configure systemd services
3. Services will automatically start on boot

### Azure Deployment
Deploy via GitHub Actions workflow in `Azure/.github/workflows/` or manually through Azure Portal.

### Frontend Development
```bash
cd LoveableWebsite
npm install
npm run dev
```

## Architecture

- **STM32 Boards** → UART → **Raspberry Pi** → HTTP → **Azure Functions** → **Frontend**
- Real-time status monitoring and command control
- Switch state synchronization across all components
