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
        const errorText = await response.text().catch(() => 'Unknown error');
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }
      
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        throw new Error('Response is not JSON');
      }
      
      const json = await response.json();
      
      // Handle error responses from API
      if (json.error || json.ok === false) {
        throw new Error(json.error || json.message || 'API returned error');
      }
      
      // Map new API format: connected -> online, lastSeen -> lastHeartbeat
      setStatus({
        online: json.connected || false,
        lastHeartbeat: json.lastSeen || null,
        lastLatencyMs: null, // Not provided by simplified API
        lastDeviceId: null, // Not provided by simplified API
        loading: false,
        error: null,
      });
    } catch (err) {
      // Only log errors, don't spam console
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch';
      
      // Only set error state if it's a new error or after initial load
      setStatus(prev => ({
        online: false,
        lastHeartbeat: prev.lastHeartbeat, // Keep last known heartbeat
        lastLatencyMs: null,
        lastDeviceId: null,
        loading: false,
        error: errorMessage,
      }));
      
      // Only log to console if not a network error (to reduce spam)
      if (!errorMessage.includes('Failed to fetch') && !errorMessage.includes('NetworkError')) {
        console.error('Failed to fetch gateway status:', err);
      }
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

