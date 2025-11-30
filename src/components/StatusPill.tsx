import { Card } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { useGatewayStatus } from '@/hooks/useGatewayStatus';

export const StatusPill = () => {
  const { status, lastSeen, msSinceLastSeen, loading } = useGatewayStatus();

  const formatRelativeTime = (msSinceLastSeen: number | null): string => {
    if (msSinceLastSeen === null) return '';
    
    if (msSinceLastSeen < 1000) return 'just now';
    const seconds = Math.round(msSinceLastSeen / 1000);
    if (seconds < 60) return `${seconds}s ago`;
    const minutes = Math.round(seconds / 60);
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.round(minutes / 60);
    return `${hours}h ago`;
  };

  const isOnline = status === 'online';

  return (
    <Card className="p-6 border border-border rounded-lg shadow-lg">
      <div className="flex items-center gap-3">
        <div
          className={cn(
            'w-3 h-3 rounded-full transition-all',
            loading && 'bg-muted-foreground animate-pulse',
            !loading && isOnline && 'bg-primary shadow-[0_0_12px_hsl(var(--primary))]',
            !loading && !isOnline && 'bg-destructive shadow-[0_0_12px_hsl(var(--destructive))]'
          )}
        />
        <div className="flex-1">
          <p className="text-sm font-medium text-foreground">Raspberry Pi Gateway → Azure</p>
          <p className="text-xs text-muted-foreground mt-1">
            {loading ? 'Checking connection...' : isOnline ? 'Online' : 'Offline'}
          </p>
          {!loading && lastSeen && msSinceLastSeen !== null && (
            <p className="text-xs text-muted-foreground mt-0.5">
              Last seen: {formatRelativeTime(msSinceLastSeen)}
            </p>
          )}
        </div>
      </div>
    </Card>
  );
};
