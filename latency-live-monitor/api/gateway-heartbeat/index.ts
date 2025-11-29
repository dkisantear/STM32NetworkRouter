import { gatewayHeartbeatState } from "../heartbeatStore";

export default async function (context: any, req: any): Promise<void> {
  context.log("Gateway heartbeat endpoint called");

  try {
    let body: any = {};
    
    // Parse body safely
    if (req.body) {
      if (typeof req.body === "string") {
        try {
          body = JSON.parse(req.body);
        } catch (e) {
          context.res = {
            status: 400,
            headers: { "Content-Type": "application/json" },
            body: { ok: false, error: "Invalid JSON in request body" }
          };
          return;
        }
      } else {
        body = req.body;
      }
    }

    const deviceId = body.deviceId || "raspi";
    const latencyMs = typeof body.latencyMs === "number" ? body.latencyMs : null;
    const timestamp = new Date().toISOString();

    // Update shared state
    gatewayHeartbeatState.lastHeartbeat = timestamp;
    gatewayHeartbeatState.lastLatencyMs = latencyMs;
    gatewayHeartbeatState.lastDeviceId = deviceId;

    context.res = {
      status: 200,
      headers: { "Content-Type": "application/json" },
      body: {
        ok: true,
        message: "Gateway heartbeat received",
        deviceId: deviceId,
        latencyMs: latencyMs,
        timestamp: timestamp
      }
    };
  } catch (error) {
    context.log.error("Error in gateway heartbeat endpoint:", error);
    context.res = {
      status: 500,
      headers: { "Content-Type": "application/json" },
      body: { ok: false, error: "Internal server error" }
    };
  }
}

