import { Card } from '@/components/ui/card';
import { LineChart, Line, ResponsiveContainer } from 'recharts';

interface LatencyCardProps {
  serverName: string;
  latency: number;
  history: number[];
}

export const LatencyCard = ({ serverName, latency, history }: LatencyCardProps) => {
  const chartData = history.map((value, index) => ({ value, index }));
  
  const min = Math.min(...history);
  const max = Math.max(...history);
  const avg = Math.round(history.reduce((sum, val) => sum + val, 0) / history.length);

  return (
    <Card className="p-6 border border-border rounded-lg shadow-lg hover:shadow-xl transition-shadow">
      <div className="grid grid-cols-2 gap-6">
        {/* Left side - Stats */}
        <div className="space-y-3">
          <p className="text-sm font-medium text-foreground">{serverName}</p>
          <div className="flex items-baseline gap-2">
            <span className="text-5xl font-bold text-foreground">{latency}</span>
            <span className="text-xl text-muted-foreground">ms</span>
          </div>
          <div className="space-y-1 text-sm text-muted-foreground">
            <p>min (last 5): <span className="text-foreground">{min} ms</span></p>
            <p>max (last 5): <span className="text-foreground">{max} ms</span></p>
            <p>avg (last 5): <span className="text-foreground">{avg} ms</span></p>
          </div>
          <p className="text-xs text-muted-foreground mt-2">Last 5 pings</p>
        </div>

        {/* Right side - Sparkline */}
        <div className="flex items-center justify-center">
          <div className="h-32 w-full">
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
          </div>
        </div>
      </div>
    </Card>
  );
};
