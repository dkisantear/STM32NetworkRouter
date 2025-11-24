import { cn } from '@/lib/utils';

interface StatusPillProps {
  connected: boolean;
}

export const StatusPill = ({ connected }: StatusPillProps) => {
  return (
    <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-border bg-card shadow-sm">
      <div
        className={cn(
          'w-2 h-2 rounded-full',
          connected ? 'bg-green-500' : 'bg-red-500'
        )}
      />
      <span className="text-sm font-medium text-foreground">
        Raspberry Pi Gateway: {connected ? 'Connected' : 'Disconnected'}
      </span>
    </div>
  );
};
