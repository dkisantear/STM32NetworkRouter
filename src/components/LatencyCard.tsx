import { Card } from '@/components/ui/card';
import { LineChart, Line, ResponsiveContainer } from 'recharts';
import { useLatency } from '@/hooks/useLatency';

interface LatencyCardProps {
  serverName: string;
  server: 'main' | 'uart' | 'serial';
}

export const LatencyCard = ({ serverName, server }: LatencyCardProps) => {
  const { data, loading, error } = useLatency(server);

  const samples = data?.samples ?? [];
  const chartData = samples.map((value, index) => ({ value, index }));
  
  const latest = data?.latest ?? 0;
  const min = data?.min ?? 0;
  const max = data?.max ?? 0;
  const avg = data?.avg ?? 0;

  if (error) {
    return (
      <Card className="p-6 border border-border rounded-lg shadow-lg">
        <div className="text-center">
          <p className="text-sm font-medium text-foreground">{serverName}</p>
          <p className="text-sm text-destructive mt-2">Error: {error}</p>
        </div>
      </Card>
    );
  }

  return (
    <Card className="p-6 border border-border rounded-lg shadow-lg hover:shadow-xl transition-shadow">
      <div className="grid grid-cols-2 gap-6">
        {/* Left side - Stats */}
        <div className="space-y-3">
          <p className="text-sm font-medium text-foreground">{serverName}</p>
          <div className="flex items-baseline gap-2">
            <span className="text-5xl font-bold text-foreground">
              {loading ? '--' : latest}
            </span>
            <span className="text-xl text-muted-foreground">ms</span>
          </div>
          <div className="space-y-1 text-sm text-muted-foreground">
            <p>min (last 5): <span className="text-foreground">{loading ? '--' : min} ms</span></p>
            <p>max (last 5): <span className="text-foreground">{loading ? '--' : max} ms</span></p>
            <p>avg (last 5): <span className="text-foreground">{loading ? '--' : avg} ms</span></p>
          </div>
          <p className="text-xs text-muted-foreground mt-2">
            {samples.length > 0 ? `Last ${samples.length} pings` : 'No data yet'}
          </p>
        </div>

        {/* Right side - Sparkline */}
        <div className="flex items-center justify-center">
          <div className="h-32 w-full">
            {samples.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={chartData}>
                  <Line
                    type="monotone"
                    dataKey="value"
                    stroke="hsl(var(--primary))"
                    strokeWidth={3}
                    dot={false}
                    isAnimationActive={false}
                    filter="drop-shadow(0 0 8px hsl(var(--primary)))"
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
