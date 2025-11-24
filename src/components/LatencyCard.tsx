import { Card } from '@/components/ui/card';
import { LineChart, Line, ResponsiveContainer } from 'recharts';

interface LatencyCardProps {
  serverName: string;
  latency: number;
  history: number[];
}

export const LatencyCard = ({ serverName, latency, history }: LatencyCardProps) => {
  const chartData = history.map((value, index) => ({ value, index }));

  return (
    <Card className="p-6 border border-border rounded-lg shadow-sm hover:shadow-md transition-shadow">
      <div className="space-y-3">
        <p className="text-sm font-medium text-muted-foreground">{serverName}</p>
        <div className="flex items-baseline gap-2">
          <span className="text-4xl font-bold text-foreground">{latency}</span>
          <span className="text-lg text-muted-foreground">ms</span>
        </div>
        <div className="h-12 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={chartData}>
              <Line
                type="monotone"
                dataKey="value"
                stroke="hsl(var(--primary))"
                strokeWidth={2}
                dot={false}
                isAnimationActive={false}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>
    </Card>
  );
};
