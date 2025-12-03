import { useQuery } from '@tanstack/react-query';

export type MasterStatus = {
  deviceId: string;
  status: 'online' | 'offline' | 'unknown';
  lastUpdated: string | null;
};

const fetchMasterStatus = async (): Promise<MasterStatus> => {
  const response = await fetch(
    `/api/stm32-status?deviceId=stm32-master`
  );
  if (!response.ok) {
    throw new Error('Failed to fetch Master board status');
  }
  return response.json();
};

export const useMasterStatus = () => {
  const { data, isLoading, error } = useQuery<MasterStatus>({
    queryKey: ['masterStatus'],
    queryFn: fetchMasterStatus,
    refetchInterval: 8000, // Poll every 8 seconds
    staleTime: 5000,
  });

  return {
    status: data?.status || 'unknown',
    lastUpdated: data?.lastUpdated || null,
    loading: isLoading,
    error: error ? (error as Error).message : null,
  };
};

