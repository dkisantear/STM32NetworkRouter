import { useState, useEffect, useCallback } from 'react';

type ServerType = 'main' | 'uart' | 'serial';
type LatencyStatus = 'loading' | 'online' | 'offline';

// Simulated fallback data per server for offline state
const FALLBACK_DATA: Record<ServerType, number[]> = {
  main: [30, 35, 40, 32, 38],
  uart: [25, 28, 33, 27, 31],
  serial: [45, 42, 50, 48, 44],
};

interface LatencyData {
  latest: number | null;
  min: number | null;
  max: number | null;
  avg: number | null;
  samples: number[];
  status: LatencyStatus;
  errorMessage?: string;
}

interface UseLatencyResult extends LatencyData {
  refetch: () => Promise<void>;
}

const calculateStats = (samples: number[]) => {
  if (samples.length === 0) {
    return { latest: null, min: null, max: null, avg: null };
  }
  return {
    latest: samples[samples.length - 1],
    min: Math.min(...samples),
    max: Math.max(...samples),
    avg: Math.round(samples.reduce((a, b) => a + b, 0) / samples.length),
  };
};

export const useLatency = (server: ServerType): UseLatencyResult => {
  const [data, setData] = useState<LatencyData>({
    latest: null,
    min: null,
    max: null,
    avg: null,
    samples: [],
    status: 'loading',
  });

  const fetchData = useCallback(async () => {
    try {
      const response = await fetch(`/api/${server}`);
      
      if (!response.ok) {
        throw new Error(`HTTP error: ${response.status}`);
      }
      
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        throw new Error('Response is not JSON');
      }
      
      const json = await response.json();
      
      // Validate the response has expected structure
      if (typeof json.latest !== 'number' || !Array.isArray(json.samples)) {
        throw new Error('Invalid response structure');
      }
      
      setData({
        latest: json.latest,
        min: json.min,
        max: json.max,
        avg: json.avg,
        samples: json.samples,
        status: 'online',
      });
    } catch (err) {
      // Use fallback simulated data when offline
      const fallbackSamples = FALLBACK_DATA[server];
      const stats = calculateStats(fallbackSamples);
      
      setData({
        ...stats,
        samples: fallbackSamples,
        status: 'offline',
        errorMessage: err instanceof Error ? err.message : 'Failed to fetch',
      });
    }
  }, [server]);

  useEffect(() => {
    // Initial fetch
    fetchData();

    // Poll every 1 second
    const interval = setInterval(fetchData, 1000);

    return () => clearInterval(interval);
  }, [fetchData]);

  return { ...data, refetch: fetchData };
};
