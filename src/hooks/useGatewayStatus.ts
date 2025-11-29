import { useState, useEffect, useCallback } from 'react';

export type GatewayStatus = {
  connected: boolean;
  lastSeen: string | null;
  ageMs: number | null;
  loading: boolean;
  error?: string;
};

export const useGatewayStatus = (): GatewayStatus => {
  const [status, setStatus] = useState<GatewayStatus>({
    connected: false,
    lastSeen: null,
    ageMs: null,
    loading: true,
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
      
      if (!json.ok) {
        throw new Error('API returned error');
      }
      
      setStatus({
        connected: json.connected || false,
        lastSeen: json.lastSeen ? new Date(json.lastSeen).toISOString() : null,
        ageMs: json.ageMs ?? null,
        loading: false,
      });
    } catch (err) {
      console.error('Failed to fetch gateway status:', err);
      setStatus({
        connected: false,
        lastSeen: null,
        ageMs: null,
        loading: false,
        error: err instanceof Error ? err.message : 'Failed to fetch',
      });
    }
  }, []);

  useEffect(() => {
    // Initial fetch
    fetchStatus();

    // Poll every 5 seconds
    const interval = setInterval(fetchStatus, 5000);

    return () => clearInterval(interval);
  }, [fetchStatus]);

  return status;
};

