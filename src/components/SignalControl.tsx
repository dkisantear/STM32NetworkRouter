import { useState } from 'react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';

type SendMode = 'serial' | 'uart';

export const SignalControl = () => {
  const [value, setValue] = useState<string>('');
  const [sendMode, setSendMode] = useState<SendMode>('uart');
  const [isSending, setIsSending] = useState(false);
  const { toast } = useToast();

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

      toast({
        title: 'Command Sent',
        description: `Sent value ${num} via ${sendMode.toUpperCase()}`,
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

  return (
    <Card className="p-6 border border-border rounded-lg shadow-lg">
      <div className="space-y-4">
        <div>
          <p className="text-sm font-medium text-foreground mb-2">Send Signal</p>
          <p className="text-xs text-muted-foreground mb-4">
            Enter a value (0-16) to send to STM32
          </p>
        </div>

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

