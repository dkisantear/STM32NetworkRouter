import { useState, useEffect, useCallback } from 'react';

export type Stm32Status = {
  deviceId: string;
  status: 'online' | 'offline' | 'unknown';
  lastUpdated: string | null;
  loading: boolean;
  error: string | null;
};

const DEFAULT_DEVICE_ID = 'stm32-main';

export const useStm32Status = (deviceId: string = DEFAULT_DEVICE_ID): Stm32Status => {
  const [stm32Status, setStm32Status] = useState<Stm32Status>({
    deviceId: deviceId,
    status: 'unknown',
    lastUpdated: null,
    loading: true,
    error: null,
  });

  const fetchStatus = useCallback(async () => {
    try {
      const response = await fetch(`/api/stm32-status?deviceId=${encodeURIComponent(deviceId)}`);

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

      setStm32Status({
        deviceId: json.deviceId || deviceId,
        status: json.status || 'unknown',
        lastUpdated: json.lastUpdated || null,
        loading: false,
        error: null,
      });
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch STM32 status';

      setStm32Status(prev => ({
        ...prev,
        loading: false,
        error: errorMessage,
      }));

      if (!errorMessage.includes('Failed to fetch') && !errorMessage.includes('NetworkError')) {
        console.error('Failed to fetch STM32 status:', err);
      }
    }
  }, [deviceId]);

  useEffect(() => {
    fetchStatus();
    const interval = setInterval(fetchStatus, 8000);
    return () => clearInterval(interval);
  }, [fetchStatus]);

  return stm32Status;
};

