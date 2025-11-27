import { useState, useEffect, useCallback } from 'react';

type ServerType = 'main' | 'uart' | 'serial';

interface LatencyResponse {
  latest: number;
  min: number;
  max: number;
  avg: number;
  samples: number[];
}

interface UseLatencyResult {
  data: LatencyResponse | null;
  loading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
}

export const useLatency = (server: ServerType): UseLatencyResult => {
  const [data, setData] = useState<LatencyResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      const response = await fetch(`/api/${server}`);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const json: LatencyResponse = await response.json();
      setData(json);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch latency data');
    } finally {
      setLoading(false);
    }
  }, [server]);

  useEffect(() => {
    // Initial fetch
    fetchData();

    // Poll every 1 second
    const interval = setInterval(fetchData, 1000);

    return () => clearInterval(interval);
  }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
};
