import { useState, useEffect, useCallback } from 'react';

export type GatewayStatus = {
  status: 'online' | 'offline';
  lastSeen: string | null;
  msSinceLastSeen: number | null;
  loading: boolean;
  error: string | null;
};

export const useGatewayStatus = (): GatewayStatus => {
  const [gatewayStatus, setGatewayStatus] = useState<GatewayStatus>({
    status: 'offline',
    lastSeen: null,
    msSinceLastSeen: null,
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
      
      // Handle actual API errors (method not allowed, etc.)
      if (json.error) {
        throw new Error(json.error);
      }
      
      // Valid response format: { status: "online" | "offline", lastSeen: string | null, msSinceLastSeen: number | null }
      // Note: status === "offline" is NOT an error - it's a valid state!
      setGatewayStatus({
        status: (json.status === 'online' ? 'online' : 'offline') as 'online' | 'offline',
        lastSeen: json.lastSeen || null,
        msSinceLastSeen: json.msSinceLastSeen !== undefined ? json.msSinceLastSeen : null,
        loading: false,
        error: null,
      });
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch';
      
      // Only update error state, keep last known values if available
      setGatewayStatus(prev => ({
        ...prev,
        loading: false,
        error: errorMessage,
      }));
      
      // Only log actual errors (network failures, etc.) - not offline status
      if (errorMessage.includes('Failed to fetch') || errorMessage.includes('NetworkError')) {
        // Silently handle network errors (common, don't spam console)
      } else {
        console.error('Failed to fetch gateway status:', err);
      }
    }
  }, []);

  useEffect(() => {
    // Initial fetch
    fetchStatus();

    // QUOTA-EFFICIENT: Poll every 10 seconds
    const interval = setInterval(fetchStatus, 10000);

    return () => clearInterval(interval);
  }, [fetchStatus]);

  return gatewayStatus;
};
