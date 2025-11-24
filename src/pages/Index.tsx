import { LatencyCard } from '@/components/LatencyCard';
import { StatusPill } from '@/components/StatusPill';
import { useLatencyData } from '@/hooks/useLatencyData';

const Index = () => {
  const { data } = useLatencyData();

  return (
    <div className="min-h-screen bg-background p-4 sm:p-8">
      <div className="max-w-2xl mx-auto space-y-8">
        {/* Header */}
        <header className="text-center space-y-2">
          <h1 className="text-3xl sm:text-4xl font-bold text-foreground">
            LatencyNet — Live View
          </h1>
        </header>

        {/* Latency Cards - Vertical Stack */}
        <div className="space-y-6">
          <LatencyCard
            serverName="Main Server"
            latency={data.mainServer[data.mainServer.length - 1]}
            history={data.mainServer}
          />
          <LatencyCard
            serverName="UART Server 2"
            latency={data.uartServer[data.uartServer.length - 1]}
            history={data.uartServer}
          />
          <LatencyCard
            serverName="Serial Server 3"
            latency={data.serialServer[data.serialServer.length - 1]}
            history={data.serialServer}
          />
          
          {/* Status Card */}
          <StatusPill connected={data.piConnected} />
        </div>

        {/* Footer */}
        <footer className="text-center pt-4">
          <p className="text-sm text-muted-foreground">
            Data is simulated. Hook to API later.
          </p>
        </footer>
      </div>
    </div>
  );
};

export default Index;
