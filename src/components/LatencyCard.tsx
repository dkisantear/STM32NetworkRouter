import { Card } from '@/components/ui/card';
import { LineChart, Line, ResponsiveContainer } from 'recharts';
import { useLatency } from '@/hooks/useLatency';
import { cn } from '@/lib/utils';

interface LatencyCardProps {
  serverName: string;
  server: 'main' | 'uart' | 'serial';
}

export const LatencyCard = ({ serverName, server }: LatencyCardProps) => {
  const { latest, min, max, avg, samples, status } = useLatency(server);

  const chartData = samples.map((value, index) => ({ value, index }));
  
  const isOffline = status === 'offline';
  const isLoading = status === 'loading';

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
