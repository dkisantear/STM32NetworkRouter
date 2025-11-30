# LatencyNet — Live View

Real-time latency monitoring dashboard for CPE185 project.

## Project info

**URL**: https://lovable.dev/projects/d3d1d285-5cd8-4cef-a9fa-294facfba17f

## Architecture

- **Frontend**: Vite + React + TypeScript + Tailwind CSS
- **Backend**: Azure Static Web Apps API (serverless functions)
- **Data Flow**: Raspberry Pi → POST to API → Frontend polls GET

## API Endpoints

| Endpoint | Methods | Description |
|----------|---------|-------------|
| `/api/ping` | GET | Health check, returns `{ status: "OK", timestamp: ... }` |
| `/api/gateway-status` | GET, POST | Gateway status tracking (uses Azure Table Storage) |
| `/api/main` | GET, POST | Main Server latency data |
| `/api/uart` | GET, POST | UART Server 2 latency data |
| `/api/serial` | GET, POST | Serial Server 3 latency data |

### GET Response Format

```json
{
  "latest": 38,
  "min": 35,
  "max": 54,
  "avg": 44,
  "samples": [45, 47, 38, 55, 41]
}
```

### POST Request Format

```json
{
  "latency": 42
}
```

## Gateway Status Tracking

The `/api/gateway-status` endpoint uses Azure Table Storage to track gateway online/offline status across all Azure Functions instances.

### GET Gateway Status

```bash
curl "https://<YOUR-SWA-URL>/api/gateway-status?gatewayId=pi5-main"
```

**Response:**
```json
{
  "gatewayId": "pi5-main",
  "status": "online",
  "lastUpdated": "2024-11-30T01:07:25.538Z"
}
```

Possible status values: `"online"`, `"offline"`, or `"unknown"` (if gateway never checked in).

### POST Gateway Status (from Raspberry Pi)

Mark your Pi as online or offline:

```bash
curl -X POST "https://<YOUR-SWA-URL>/api/gateway-status" \
  -H "Content-Type: application/json" \
  -d '{"gatewayId":"pi5-main","status":"online"}'
```

**Response:**
```json
{
  "gatewayId": "pi5-main",
  "status": "online",
  "lastUpdated": "2024-11-30T01:07:25.538Z"
}
```

**Note:** The `status` field must be either `"online"` or `"offline"`.

### Environment Variable Required

For the gateway status endpoint to work, you must configure the Azure Table Storage connection string in your Azure Static Web App:

1. Go to Azure Portal → Your Static Web App → Configuration
2. Add application setting:
   - **Name**: `TABLES_CONNECTION_STRING`
   - **Value**: Your Azure Storage Account connection string (from "Access keys" section)

The connection string looks like:
```
DefaultEndpointsProtocol=https;AccountName=latencynetstorage;AccountKey=...;EndpointSuffix=core.windows.net
```

## Raspberry Pi Integration

### Python Example

```python
import requests

# Replace with your Azure Static Web App URL
SWA_URL = "https://<YOUR-SWA-URL>"

# Post latency to Main Server endpoint
response = requests.post(
    f"{SWA_URL}/api/main",
    json={"latency": 42}
)
print(response.json())

# Post to UART Server endpoint
requests.post(f"{SWA_URL}/api/uart", json={"latency": 35})

# Post to Serial Server endpoint
requests.post(f"{SWA_URL}/api/serial", json={"latency": 28})
```

### Bash/cURL Example

```bash
# Test the ping endpoint
curl https://<YOUR-SWA-URL>/api/ping

# POST latency to Main Server
curl -X POST https://<YOUR-SWA-URL>/api/main \
  -H "Content-Type: application/json" \
  -d '{"latency": 42}'

# POST latency to UART Server
curl -X POST https://<YOUR-SWA-URL>/api/uart \
  -H "Content-Type: application/json" \
  -d '{"latency": 35}'

# POST latency to Serial Server
curl -X POST https://<YOUR-SWA-URL>/api/serial \
  -H "Content-Type: application/json" \
  -d '{"latency": 28}'

# GET current stats
curl https://<YOUR-SWA-URL>/api/main
```

### Continuous Monitoring Script (Python)

```python
import requests
import time
import subprocess

SWA_URL = "https://<YOUR-SWA-URL>"

def measure_latency(host):
    """Measure ping latency to a host"""
    result = subprocess.run(
        ["ping", "-c", "1", host],
        capture_output=True,
        text=True
    )
    # Parse the output to get latency
    for line in result.stdout.split('\n'):
        if 'time=' in line:
            time_ms = float(line.split('time=')[1].split(' ')[0])
            return int(time_ms)
    return None

while True:
    # Measure and post Main Server latency
    latency = measure_latency("main-server.local")
    if latency:
        requests.post(f"{SWA_URL}/api/main", json={"latency": latency})
    
    # Measure and post UART Server latency
    latency = measure_latency("uart-server.local")
    if latency:
        requests.post(f"{SWA_URL}/api/uart", json={"latency": latency})
    
    # Measure and post Serial Server latency
    latency = measure_latency("serial-server.local")
    if latency:
        requests.post(f"{SWA_URL}/api/serial", json={"latency": latency})
    
    time.sleep(3)  # Wait 3 seconds between measurements
```

## Connection States

The dashboard handles three connection states automatically:

| State | Description | UI Behavior |
|-------|-------------|-------------|
| `loading` | Initial state while first fetch is in progress | Shows "Loading..." text |
| `online` | API is reachable and returning valid data | Shows real latency values with glowing sparkline |
| `offline` | API unreachable, non-JSON response, or errors | Shows "Offline" badge + simulated data (dimmed card) |

**Automatic Transition**: Once the Raspberry Pi starts POSTing real data to the API, the cards will automatically switch from `offline` → `online` without any frontend code changes.

## Local Development

```sh
# Install dependencies
npm install

# Start the development server
npm run dev
```

**Note**: API functions won't work locally without Azure Functions Core Tools. For local testing, the frontend will show the `offline` state with simulated data until connected to the deployed API.

## Deployment

This project is configured for Azure Static Web Apps:

1. Push to the `main` branch
2. GitHub Actions will automatically build and deploy:
   - Frontend (`dist/`) to static hosting
   - API functions (`api/`) to serverless functions

### Manual Deployment via Lovable

Open [Lovable](https://lovable.dev/projects/d3d1d285-5cd8-4cef-a9fa-294facfba17f) and click on Share → Publish.

## Files Structure

```
├── api/                    # Azure Functions API
│   ├── main/              # Main Server endpoint
│   │   ├── function.json
│   │   └── index.ts
│   ├── uart/              # UART Server endpoint
│   │   ├── function.json
│   │   └── index.ts
│   ├── serial/            # Serial Server endpoint
│   │   ├── function.json
│   │   └── index.ts
│   ├── ping/              # Health check endpoint
│   │   ├── function.json
│   │   └── index.ts
│   ├── host.json
│   ├── package.json
│   └── tsconfig.json
├── src/
│   ├── components/
│   │   ├── LatencyCard.tsx
│   │   └── StatusPill.tsx
│   ├── hooks/
│   │   └── useLatency.ts
│   └── pages/
│       └── Index.tsx
└── dist/                   # Built frontend (output)
```

## Technologies

- Vite
- TypeScript
- React
- shadcn-ui
- Tailwind CSS
- Azure Static Web Apps
- Azure Functions

## Azure Static Web Apps API status

- `/api/ping` returns a JSON health payload.
- `/api/main`, `/api/uart`, `/api/serial` return mock latency stats with fields:
  `label`, `status`, `samples`, `min`, `max`, `avg`, `updatedAt`.
- Frontend `useLatency` hook reads from these endpoints and falls back gracefully if offline.
- Ready for a future update where a Raspberry Pi can POST real latency data into these APIs.