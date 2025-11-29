import { useState, useEffect, useCallback } from 'react';

export type GatewayStatus = {
  online: boolean;
  lastHeartbeat: string | null;
  lastLatencyMs: number | null;
  lastDeviceId: string | null;
  loading: boolean;
  error: string | null;
};

export const useGatewayStatus = (): GatewayStatus => {
  const [status, setStatus] = useState<GatewayStatus>({
    online: false,
    lastHeartbeat: null,
    lastLatencyMs: null,
    lastDeviceId: null,
    loading: true,
    error: null,
  });

  const fetchStatus = useCallback(async () => {
    try {
      const response = await fetch('/api/gateway-status');
      
      if (!response.ok) {
        throw new Error(`HTTP error: ${response.status}`);
      }
      
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        throw new Error('Response is not JSON');
      }
      
      const json = await response.json();
      
      setStatus({
        online: json.online || false,
        lastHeartbeat: json.lastHeartbeat || null,
        lastLatencyMs: json.lastLatencyMs ?? null,
        lastDeviceId: json.lastDeviceId || null,
        loading: false,
        error: null,
      });
    } catch (err) {
      console.error('Failed to fetch gateway status:', err);
      setStatus({
        online: false,
        lastHeartbeat: null,
        lastLatencyMs: null,
        lastDeviceId: null,
        loading: false,
        error: err instanceof Error ? err.message : 'Failed to fetch',
      });
    }
  }, []);

  useEffect(() => {
    // Initial fetch
    fetchStatus();

    // Poll every 1 second
    const interval = setInterval(fetchStatus, 1000);

    return () => clearInterval(interval);
  }, [fetchStatus]);

  return status;
};

