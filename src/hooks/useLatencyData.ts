import { useState, useEffect, useCallback } from 'react';

interface LatencyData {
  mainServer: number[];
  uartServer: number[];
  serialServer: number[];
  piConnected: boolean;
}

const generateRandomLatency = (base: number, variance: number) => {
  return Math.round(base + (Math.random() - 0.5) * variance);
};

const HISTORY_LENGTH = 20;

export const useLatencyData = () => {
  const [data, setData] = useState<LatencyData>({
    mainServer: Array(HISTORY_LENGTH).fill(0).map(() => generateRandomLatency(45, 20)),
    uartServer: Array(HISTORY_LENGTH).fill(0).map(() => generateRandomLatency(32, 15)),
    serialServer: Array(HISTORY_LENGTH).fill(0).map(() => generateRandomLatency(28, 12)),
    piConnected: true,
  });

  // Update latency values every 3 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      setData((prev) => ({
        ...prev,
        mainServer: [...prev.mainServer.slice(1), generateRandomLatency(45, 20)],
        uartServer: [...prev.uartServer.slice(1), generateRandomLatency(32, 15)],
        serialServer: [...prev.serialServer.slice(1), generateRandomLatency(28, 12)],
      }));
    }, 3000);

    return () => clearInterval(interval);
  }, []);

  // Toggle connection status randomly every 15-30 seconds
  useEffect(() => {
    const scheduleNextToggle = () => {
      const delay = 15000 + Math.random() * 15000;
      return setTimeout(() => {
        setData((prev) => ({ ...prev, piConnected: !prev.piConnected }));
        scheduleNextToggle();
      }, delay);
    };

    const timeout = scheduleNextToggle();
    return () => clearTimeout(timeout);
  }, []);

  // Function to wire real data later
  const updateFromAPI = useCallback((apiData: Partial<LatencyData>) => {
    setData((prev) => ({ ...prev, ...apiData }));
  }, []);

  return { data, updateFromAPI };
};
