import { Card } from '@/components/ui/card';
import { cn } from '@/lib/utils';

interface StatusPillProps {
  connected: boolean;
}

export const StatusPill = ({ connected }: StatusPillProps) => {
  return (
    <Card className="p-6 border border-border rounded-lg shadow-lg">
      <div className="flex items-center gap-3">
        <div
          className={cn(
            'w-3 h-3 rounded-full',
            connected ? 'bg-primary shadow-[0_0_12px_hsl(var(--primary))]' : 'bg-destructive shadow-[0_0_12px_hsl(var(--destructive))]'
          )}
        />
        <div>
          <p className="text-sm font-medium text-foreground">Raspberry Pi Gateway → Azure</p>
          <p className="text-xs text-muted-foreground mt-1">
            {connected ? 'Connected' : 'Disconnected'}
          </p>
        </div>
      </div>
    </Card>
  );
};
