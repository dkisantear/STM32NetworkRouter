import { useState, useEffect, useCallback } from 'react';

export type SwitchState = {
  mode: 'serial' | 'uart' | 'parallel' | 'unknown';
  value: number | null;
  lastUpdated: string | null;
  loading: boolean;
  error: string | null;
};

export const useSwitchState = (): SwitchState => {
  const [switchState, setSwitchState] = useState<SwitchState>({
    mode: 'unknown',
    value: null,
    lastUpdated: null,
    loading: true,
    error: null,
  });

  const fetchSwitchState = useCallback(async () => {
    try {
      const response = await fetch('/api/stm32-switch-state');
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      
      const json = await response.json();
      
      setSwitchState({
        mode: json.mode || 'unknown',
        value: json.value || null,
        lastUpdated: json.lastUpdated || null,
        loading: false,
        error: null,
      });
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch switch state';
      setSwitchState(prev => ({
        ...prev,
        loading: false,
        error: errorMessage,
      }));
    }
  }, []);

  useEffect(() => {
    fetchSwitchState();
    const interval = setInterval(fetchSwitchState, 5000); // Poll every 5 seconds
    return () => clearInterval(interval);
  }, [fetchSwitchState]);

  return switchState;
};



