import { Card } from '@/components/ui/card';
import { LineChart, Line, ResponsiveContainer } from 'recharts';
import { useLatency } from '@/hooks/useLatency';
import { useStm32Status } from '@/hooks/useStm32Status';
import { cn } from '@/lib/utils';

interface LatencyCardProps {
  serverName: string;
  server: 'main' | 'uart' | 'serial';
}

export const LatencyCard = ({ serverName, server }: LatencyCardProps) => {
  // For Main Server, use STM32 status instead of latency
  const stm32Status = useStm32Status();
  const { latest, min, max, avg, samples, status } = useLatency(server);
  
  // If this is the Main Server, show STM32 connection status
  const isMainServer = server === 'main';

  const chartData = samples.map((value, index) => ({ value, index }));
  
  const isOffline = status === 'offline';
  const isLoading = status === 'loading';

  // Format relative time for STM32 status
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

  // STM32 status display for Main Server
  if (isMainServer) {
    const stm32IsOnline = stm32Status.status === 'online';
    const stm32IsOffline = stm32Status.status === 'offline';
    const stm32IsLoading = stm32Status.loading;
    const stm32HasError = stm32Status.error !== null;

    const getStatusDisplay = (): string => {
      if (stm32Status.loading) return 'Checking status...';
      if (stm32Status.error) return 'Error connecting to API';
      if (stm32Status.status === 'online') return 'Online';
      if (stm32Status.status === 'offline') return 'Offline';
      return 'Unknown';
    };

    const getStatusColor = (): string => {
      if (stm32Status.loading) return 'bg-muted-foreground';
      if (stm32Status.error) return 'bg-destructive';
      if (stm32Status.status === 'online') return 'bg-primary';
      if (stm32Status.status === 'offline') return 'bg-destructive';
      return 'bg-muted-foreground';
    };

    const getStatusGlow = (): string => {
      if (stm32Status.loading || stm32Status.error || stm32Status.status === 'unknown') return '';
      if (stm32Status.status === 'online') return 'shadow-[0_0_12px_hsl(var(--primary))]';
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
              stm32Status.loading && 'animate-pulse'
            )}
          />
          <div className="flex-1">
            <p className="text-sm font-medium text-foreground">{serverName}</p>
            <p className="text-xs text-muted-foreground mt-1">
              {getStatusDisplay()}
            </p>
            {!stm32Status.loading && !stm32Status.error && stm32Status.lastUpdated && (
              <p className="text-xs text-muted-foreground mt-0.5">
                Last updated: {formatRelativeTime(stm32Status.lastUpdated)}
              </p>
            )}
          </div>
        </div>
      </Card>
    );
  }

  // Regular latency display for other servers
  return (
    <Card className={cn(
      "p-6 border border-border rounded-lg shadow-lg transition-all",
      isOffline && "opacity-60",
      !isOffline && "hover:shadow-xl"
    )}>
      <div className="grid grid-cols-2 gap-6">
        {/* Left side - Stats */}
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <p className="text-sm font-medium text-foreground">{serverName}</p>
            {isOffline && (
              <span className="text-xs px-2 py-0.5 rounded bg-muted text-muted-foreground">
                Offline
              </span>
            )}
          </div>
          
          {isLoading ? (
            <div className="space-y-2">
              <div className="h-12 flex items-center">
                <span className="text-lg text-muted-foreground">Loading...</span>
              </div>
            </div>
          ) : (
            <>
              <div className="flex items-baseline gap-2">
                <span className="text-5xl font-bold text-foreground">
                  {latest ?? '--'}
                </span>
                <span className="text-xl text-muted-foreground">ms</span>
              </div>
              <div className="space-y-1 text-sm text-muted-foreground">
                <p>min (last 5): <span className="text-foreground">{min ?? '--'} ms</span></p>
                <p>max (last 5): <span className="text-foreground">{max ?? '--'} ms</span></p>
                <p>avg (last 5): <span className="text-foreground">{avg ?? '--'} ms</span></p>
              </div>
              <p className="text-xs text-muted-foreground mt-2">
                {isOffline 
                  ? 'No connection (showing simulated data)' 
                  : samples.length > 0 
                    ? `Last ${samples.length} pings` 
                    : 'No data yet'
                }
              </p>
            </>
          )}
        </div>

        {/* Right side - Sparkline */}
        <div className="flex items-center justify-center">
          <div className="h-32 w-full">
            {isLoading ? (
              <div className="h-full flex items-center justify-center text-muted-foreground text-sm">
                Waiting for data...
              </div>
            ) : samples.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={chartData}>
                  <Line
                    type="monotone"
                    dataKey="value"
                    stroke={isOffline ? "hsl(var(--muted-foreground))" : "hsl(var(--primary))"}
                    strokeWidth={3}
                    dot={false}
                    isAnimationActive={false}
                    filter={isOffline ? undefined : "drop-shadow(0 0 8px hsl(var(--primary)))"}
                  />
                </LineChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-full flex items-center justify-center text-muted-foreground text-sm">
                Waiting for data...
              </div>
            )}
          </div>
        </div>
      </div>
    </Card>
  );
};
