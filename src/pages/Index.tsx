import { LatencyCard } from '@/components/LatencyCard';
import { StatusPill } from '@/components/StatusPill';

const Index = () => {
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
          <LatencyCard serverName="Main Server" server="main" />
          <LatencyCard serverName="UART Server 2" server="uart" />
          <LatencyCard serverName="Serial Server 3" server="serial" />
          
          {/* Status Card */}
          <StatusPill connected={true} />
        </div>

        {/* Footer */}
        <footer className="text-center pt-4">
          <p className="text-sm text-muted-foreground">
            Live data from Azure Static Web Apps API
          </p>
        </footer>
      </div>
    </div>
  );
};

export default Index;
