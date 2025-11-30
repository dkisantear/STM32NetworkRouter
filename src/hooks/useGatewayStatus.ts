import { useState, useEffect, useCallback } from 'react';

export type GatewayStatus = {
  gatewayId: string;
  status: 'online' | 'offline' | 'unknown';
  lastUpdated: string | null;
  loading: boolean;
  error: string | null;
};

const DEFAULT_GATEWAY_ID = 'pi5-main';

export const useGatewayStatus = (gatewayId: string = DEFAULT_GATEWAY_ID): GatewayStatus => {
  const [gatewayStatus, setGatewayStatus] = useState<GatewayStatus>({
    gatewayId: gatewayId,
    status: 'unknown',
    lastUpdated: null,
    loading: true,
    error: null,
  });

  const fetchStatus = useCallback(async () => {
    try {
      const response = await fetch(`/api/gateway-status?gatewayId=${encodeURIComponent(gatewayId)}`);
      
      if (!response.ok) {
        const errorText = await response.text().catch(() => 'Unknown error');
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }
      
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        throw new Error('Response is not JSON');
      }
      
      const json = await response.json();
      
      if (json.error) {
        throw new Error(json.error);
      }

      setGatewayStatus({
        gatewayId: json.gatewayId || gatewayId,
        status: json.status || 'unknown',
        lastUpdated: json.lastUpdated || null,
        loading: false,
        error: null,
      });
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch gateway status';
      
      setGatewayStatus(prev => ({
        ...prev,
        loading: false,
        error: errorMessage,
      }));
      
      if (!errorMessage.includes('Failed to fetch') && !errorMessage.includes('NetworkError')) {
        console.error('Failed to fetch gateway status:', err);
      }
    }
  }, [gatewayId]);

  useEffect(() => {
    fetchStatus();
    const interval = setInterval(fetchStatus, 8000);
    return () => clearInterval(interval);
  }, [fetchStatus]);

  return gatewayStatus;
};
