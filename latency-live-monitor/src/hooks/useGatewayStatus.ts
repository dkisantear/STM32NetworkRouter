import { useState, useEffect, useCallback, useRef } from 'react';

export type GatewayStatus = {
  status: 'online' | 'offline';
  lastSeen: string | null;
  msSinceLastSeen: number | null;
  loading: boolean;
  error: string | null;
};

// Sticky online: once we see online, stay online for 5 minutes even if API says offline
// This prevents flickering due to Azure Functions instance isolation
const STICKY_ONLINE_DURATION_MS = 5 * 60 * 1000; // 5 minutes

export const useGatewayStatus = (): GatewayStatus => {
  const [gatewayStatus, setGatewayStatus] = useState<GatewayStatus>({
    status: 'offline',
    lastSeen: null,
    msSinceLastSeen: null,
    loading: true,
    error: null,
  });
  
  // Track when we last saw "online" status for sticky behavior
  const lastOnlineTimeRef = useRef<number | null>(null);

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
      
      // Determine actual status from API
      const apiStatus = (json.status === 'online' ? 'online' : 'offline') as 'online' | 'offline';
      
      // Update last online time if API says online
      if (apiStatus === 'online') {
        lastOnlineTimeRef.current = Date.now();
      }
      
      // Apply sticky online logic: if we've seen online recently, keep showing online
      let finalStatus = apiStatus;
      if (apiStatus === 'offline' && lastOnlineTimeRef.current !== null) {
        const timeSinceLastOnline = Date.now() - lastOnlineTimeRef.current;
        if (timeSinceLastOnline < STICKY_ONLINE_DURATION_MS) {
          // Still within sticky window, keep showing online
          finalStatus = 'online';
        } else {
          // Sticky window expired, truly offline (Pi hasn't been seen in 5+ minutes)
          lastOnlineTimeRef.current = null;
        }
      }
      
      // Valid response format: { status: "online" | "offline", lastSeen: string | null, msSinceLastSeen: number | null }
      setGatewayStatus({
        status: finalStatus,
        lastSeen: json.lastSeen || null,
        msSinceLastSeen: json.msSinceLastSeen !== undefined ? json.msSinceLastSeen : null,
        loading: false,
        error: null,
      });
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch';
      
      // On network errors, apply sticky logic if we've seen online recently
      let finalStatus: 'online' | 'offline' = 'offline';
      if (lastOnlineTimeRef.current !== null) {
        const timeSinceLastOnline = Date.now() - lastOnlineTimeRef.current;
        if (timeSinceLastOnline < STICKY_ONLINE_DURATION_MS) {
          finalStatus = 'online';
        }
      }
      
      // Only update error state, keep last known values if available
      setGatewayStatus(prev => ({
        ...prev,
        status: finalStatus,
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

