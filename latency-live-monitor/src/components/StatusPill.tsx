import { Card } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { useGatewayStatus } from '@/hooks/useGatewayStatus';

export const StatusPill = () => {
  const { online, lastHeartbeat, lastLatencyMs, lastDeviceId, loading } = useGatewayStatus();

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

  return (
    <Card className="p-6 border border-border rounded-lg shadow-lg">
      <div className="flex items-center gap-3">
        <div
          className={cn(
            'w-3 h-3 rounded-full transition-all',
            loading && 'bg-muted-foreground animate-pulse',
            online === true && 'bg-primary shadow-[0_0_12px_hsl(var(--primary))]',
            online === false && 'bg-destructive shadow-[0_0_12px_hsl(var(--destructive))]'
          )}
        />
        <div className="flex-1">
          <p className="text-sm font-medium text-foreground">Raspberry Pi Gateway → Azure</p>
          <p className="text-xs text-muted-foreground mt-1">
            {loading ? 'Checking connection...' : online ? 'Connected' : 'Disconnected'}
          </p>
          {!loading && lastHeartbeat && (
            <p className="text-xs text-muted-foreground mt-0.5">
              Last heartbeat: {formatRelativeTime(lastHeartbeat)}
            </p>
          )}
          {!loading && lastLatencyMs !== null && (
            <p className="text-xs text-muted-foreground mt-0.5">
              Last latency: {lastLatencyMs} ms
            </p>
          )}
        </div>
      </div>
    </Card>
  );
};
