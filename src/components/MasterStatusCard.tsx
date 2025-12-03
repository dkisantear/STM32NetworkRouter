import { Card } from '@/components/ui/card';
import { useMasterStatus } from '@/hooks/useMasterStatus';
import { cn } from '@/lib/utils';

export const MasterStatusCard = () => {
  const masterStatus = useMasterStatus();

  const formatRelativeTime = (timestamp: string | null): string => {
    if (!timestamp) return '';
    try {
      const lastTime = new Date(timestamp).getTime();
      const now = Date.now();
      const ageMs = now - lastTime;
      if (ageMs < 1000) return 'just now';
      const seconds = Math.round(ageMs / 1000);
      if (seconds < 60) return `${seconds}s ago`;
      const minutes = Math.round(seconds / 60);
      if (minutes < 60) return `${minutes}m ago`;
      const hours = Math.round(minutes / 60);
      return `${hours}h ago`;
    } catch {
      return '';
    }
  };

  const getStatusDisplay = (): string => {
    if (masterStatus.loading) return 'Checking status...';
    if (masterStatus.error) return 'Error connecting to API';
    if (masterStatus.status === 'online') return 'Online';
    if (masterStatus.status === 'offline') return 'Offline';
    return 'Unknown';
  };

  const getStatusColor = (): string => {
    if (masterStatus.loading) return 'bg-muted-foreground';
    if (masterStatus.error) return 'bg-destructive';
    if (masterStatus.status === 'online') return 'bg-primary';
    if (masterStatus.status === 'offline') return 'bg-destructive';
    return 'bg-muted-foreground';
  };

  const getStatusGlow = (): string => {
    if (masterStatus.loading || masterStatus.error || masterStatus.status === 'unknown') return '';
    if (masterStatus.status === 'online') return 'shadow-[0_0_12px_hsl(var(--primary))]';
    return 'shadow-[0_0_12px_hsl(var(--destructive))]';
  };

  return (
    <Card className="p-6 border border-border rounded-lg shadow-lg">
      <div className="flex items-center gap-3">
        <div
          className={cn(
            'w-3 h-3 rounded-full transition-all',
            getStatusColor(),
            getStatusGlow(),
            masterStatus.loading && 'animate-pulse'
          )}
        />
        <div className="flex-1">
          <p className="text-sm font-medium text-foreground">Master STM32</p>
          <p className="text-xs text-muted-foreground mt-1">
            {getStatusDisplay()}
          </p>
          {!masterStatus.loading && !masterStatus.error && masterStatus.lastUpdated && (
            <p className="text-xs text-muted-foreground mt-0.5">
              Last updated: {formatRelativeTime(masterStatus.lastUpdated)}
            </p>
          )}
        </div>
      </div>
    </Card>
  );
};

