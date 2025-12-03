import { LatencyCard } from '@/components/LatencyCard';
import { StatusPill } from '@/components/StatusPill';
import { SignalControl } from '@/components/SignalControl';
import { MasterStatusCard } from '@/components/MasterStatusCard';

const Index = () => {
  return (
    <div className="min-h-screen bg-background p-4 sm:p-8">
      <div className="max-w-2xl mx-auto space-y-8">
        {/* Header */}
        <header className="text-center space-y-2">
          <h1 className="text-3xl sm:text-4xl font-bold text-foreground">
            STM32 Signal Router
          </h1>
        </header>

        {/* Status Cards */}
        <div className="space-y-6">
          {/* Master STM32 status */}
          <MasterStatusCard />
          
          {/* Raspberry Pi Gateway status */}
          <StatusPill />
        </div>

        {/* Signal Control */}
        <SignalControl />

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
