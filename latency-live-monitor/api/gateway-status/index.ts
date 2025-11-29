import { gatewayHeartbeatState } from "../heartbeatStore";

export default async function (context: any, req: any): Promise<void> {
  context.log("Gateway status endpoint called");

  try {
    const HEARTBEAT_TIMEOUT_MS = 30000; // 30 seconds

    let online = false;

    if (gatewayHeartbeatState.lastHeartbeat) {
      const lastHeartbeatTime = new Date(gatewayHeartbeatState.lastHeartbeat).getTime();
      const now = Date.now();
      const ageMs = now - lastHeartbeatTime;
      online = ageMs <= HEARTBEAT_TIMEOUT_MS;
    }

    context.res = {
      status: 200,
      headers: { "Content-Type": "application/json" },
      body: {
        online: online,
        lastHeartbeat: gatewayHeartbeatState.lastHeartbeat,
        lastLatencyMs: gatewayHeartbeatState.lastLatencyMs,
        lastDeviceId: gatewayHeartbeatState.lastDeviceId
      }
    };
  } catch (error) {
    context.log.error("Error in gateway status endpoint:", error);
    context.res = {
      status: 500,
      headers: { "Content-Type": "application/json" },
      body: {
        online: false,
        error: error instanceof Error ? error.message : "Internal server error"
      }
    };
  }
}

