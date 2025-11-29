export interface GatewayHeartbeatState {
  lastHeartbeat: string | null;
  lastLatencyMs: number | null;
  lastDeviceId: string | null;
}

export const gatewayHeartbeatState: GatewayHeartbeatState = {
  lastHeartbeat: null,
  lastLatencyMs: null,
  lastDeviceId: null,
};

