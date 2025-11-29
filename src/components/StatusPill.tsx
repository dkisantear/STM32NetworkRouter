import { Card } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { useGatewayStatus } from '@/hooks/useGatewayStatus';

export const StatusPill = () => {
  const { connected, lastSeen, ageMs, loading } = useGatewayStatus();

  const formatAge = (ageMs: number | null): string => {
    if (ageMs === null) return '';
    if (ageMs < 1000) return `${Math.round(ageMs)}ms ago`;
    const seconds = Math.round(ageMs / 1000);
    if (seconds < 60) return `${seconds}s ago`;
    const minutes = Math.round(seconds / 60);
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.round(minutes / 60);
    return `${hours}h ago`;
  };

  return (
    <Card className="p-6 border border-border rounded-lg shadow-lg">
      <div className="flex items-center gap-3">
        <div
          className={cn(
            'w-3 h-3 rounded-full transition-all',
            loading && 'bg-muted-foreground animate-pulse',
            connected === true && 'bg-primary shadow-[0_0_12px_hsl(var(--primary))]',
            connected === false && 'bg-destructive shadow-[0_0_12px_hsl(var(--destructive))]'
          )}
        />
        <div className="flex-1">
          <p className="text-sm font-medium text-foreground">Raspberry Pi Gateway → Azure</p>
          <p className="text-xs text-muted-foreground mt-1">
            {loading ? 'Checking connection...' : connected ? 'Connected' : 'Disconnected'}
          </p>
          {!loading && lastSeen && ageMs !== null && (
            <p className="text-xs text-muted-foreground mt-0.5">
              Last seen: {formatAge(ageMs)}
            </p>
          )}
        </div>
      </div>
    </Card>
  );
};
