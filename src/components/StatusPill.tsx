import { useState, useEffect } from 'react';
import { Card } from '@/components/ui/card';
import { cn } from '@/lib/utils';

export const StatusPill = () => {
  const [connected, setConnected] = useState<boolean | null>(null); // null = checking

  useEffect(() => {
    const checkConnection = async () => {
      try {
        const response = await fetch('/api/ping');
        if (!response.ok) {
          throw new Error('Not OK');
        }
        const data = await response.json();
        setConnected(data.status === 'OK');
      } catch {
        setConnected(false);
      }
    };

    // Initial check
    checkConnection();

    // Poll every 5 seconds
    const interval = setInterval(checkConnection, 5000);

    return () => clearInterval(interval);
  }, []);

  const isChecking = connected === null;

  return (
    <Card className="p-6 border border-border rounded-lg shadow-lg">
      <div className="flex items-center gap-3">
        <div
          className={cn(
            'w-3 h-3 rounded-full transition-all',
            isChecking && 'bg-muted-foreground animate-pulse',
            connected === true && 'bg-primary shadow-[0_0_12px_hsl(var(--primary))]',
            connected === false && 'bg-destructive shadow-[0_0_12px_hsl(var(--destructive))]'
          )}
        />
        <div>
          <p className="text-sm font-medium text-foreground">Raspberry Pi Gateway → Azure</p>
          <p className="text-xs text-muted-foreground mt-1">
            {isChecking ? 'Checking connection...' : connected ? 'Connected' : 'Disconnected'}
          </p>
        </div>
      </div>
    </Card>
  );
};
