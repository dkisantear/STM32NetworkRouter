import { useState } from 'react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';
import { useMasterStatus } from '@/hooks/useMasterStatus';

type SendMode = 'serial' | 'uart';

export const SignalControl = () => {
  const [value, setValue] = useState<string>('');
  const [sendMode, setSendMode] = useState<SendMode>('uart');
  const [isSending, setIsSending] = useState(false);
  const [lastSentValue, setLastSentValue] = useState<number | null>(null);
  const { toast } = useToast();
  const masterStatus = useMasterStatus();

  const validateValue = (val: string): boolean => {
    const num = parseInt(val, 10);
    return !isNaN(num) && num >= 0 && num <= 16;
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const inputValue = e.target.value;
    // Allow empty input or valid numbers 0-16
    if (inputValue === '' || /^\d+$/.test(inputValue)) {
      const num = parseInt(inputValue, 10);
      if (inputValue === '' || (num >= 0 && num <= 16)) {
        setValue(inputValue);
      }
    }
  };

  const handleSend = async () => {
    if (value === '') {
      toast({
        title: 'Invalid Input',
        description: 'Please enter a value between 0 and 16',
        variant: 'destructive',
      });
      return;
    }

    const num = parseInt(value, 10);
    if (!validateValue(value)) {
      toast({
        title: 'Invalid Input',
        description: 'Value must be between 0 and 16',
        variant: 'destructive',
      });
      return;
    }

    setIsSending(true);
    try {
      const response = await fetch('/api/stm32-command', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          value: num,
          mode: sendMode,
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to send command');
      }

      const result = await response.json();
      setLastSentValue(num);
      toast({
        title: 'Command Sent',
        description: `Sent value ${num} via ${sendMode.toUpperCase()} to Master board`,
      });
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to send command. Please try again.',
        variant: 'destructive',
      });
    } finally {
      setIsSending(false);
    }
  };

  // Get status display info
  const getStatusDisplay = () => {
    if (masterStatus.loading) return 'Checking...';
    if (masterStatus.error) return 'Error';
    if (masterStatus.status === 'online') return 'Connected';
    if (masterStatus.status === 'offline') return 'Disconnected';
    return 'Unknown';
  };

  const getStatusColor = () => {
    if (masterStatus.loading) return 'bg-muted-foreground';
    if (masterStatus.error) return 'bg-destructive';
    if (masterStatus.status === 'online') return 'bg-primary';
    if (masterStatus.status === 'offline') return 'bg-destructive';
    return 'bg-muted-foreground';
  };

  return (
    <Card className="p-6 border border-border rounded-lg shadow-lg">
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-foreground mb-2">Send Signal to Master Board</p>
            <p className="text-xs text-muted-foreground">
              Enter a value (0-16) to replicate on Master STM32 DIP switch
            </p>
          </div>
          <div className="flex items-center gap-2">
            <div
              className={cn(
                'w-2 h-2 rounded-full transition-all',
                getStatusColor(),
                masterStatus.status === 'online' && 'shadow-[0_0_8px_hsl(var(--primary))]',
                masterStatus.loading && 'animate-pulse'
              )}
            />
            <span className="text-xs text-muted-foreground">{getStatusDisplay()}</span>
          </div>
        </div>

        {lastSentValue !== null && (
          <div className="px-3 py-2 bg-muted rounded-md">
            <p className="text-xs text-muted-foreground">
              Last sent: <span className="text-foreground font-medium">{lastSentValue}</span> via {sendMode.toUpperCase()}
            </p>
          </div>
        )}

        {/* Toggle Buttons */}
        <div className="flex gap-2">
          <Button
            variant={sendMode === 'serial' ? 'default' : 'outline'}
            className={cn(
              'flex-1',
              sendMode === 'serial' && 'bg-primary text-primary-foreground',
              sendMode !== 'serial' && 'opacity-50'
            )}
            onClick={() => setSendMode('serial')}
            disabled={isSending}
          >
            Serial
          </Button>
          <Button
            variant={sendMode === 'uart' ? 'default' : 'outline'}
            className={cn(
              'flex-1',
              sendMode === 'uart' && 'bg-primary text-primary-foreground',
              sendMode !== 'uart' && 'opacity-50'
            )}
            onClick={() => setSendMode('uart')}
            disabled={isSending}
          >
            UART
          </Button>
        </div>

        {/* Input Box */}
        <div className="flex gap-2">
          <Input
            type="text"
            inputMode="numeric"
            placeholder="0-16"
            value={value}
            onChange={handleInputChange}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                handleSend();
              }
            }}
            disabled={isSending}
            className="flex-1"
          />
          <Button
            onClick={handleSend}
            disabled={isSending || !validateValue(value)}
          >
            {isSending ? 'Sending...' : 'Send'}
          </Button>
        </div>
      </div>
    </Card>
  );
};

