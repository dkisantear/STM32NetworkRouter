module.exports = async function (context, req) {
  context.log('UART endpoint called');
  
  try {
    // Generate mock latency samples (5 values between 20-50 ms)
    const samples = Array.from({ length: 5 }, () =>
      20 + Math.round(Math.random() * 30)
    );
    
    const min = Math.min(...samples);
    const max = Math.max(...samples);
    const avg = Math.round(samples.reduce((a, b) => a + b, 0) / samples.length);
    
    context.res = {
      status: 200,
      headers: { "Content-Type": "application/json" },
      body: {
        name: "UART Server 2",
        latency: samples[samples.length - 1], // latest sample
        min: min,
        max: max,
        avg: avg,
        samples: samples
      }
    };
  } catch (error) {
    context.log.error('Error in uart endpoint:', error);
    context.res = {
      status: 500,
      headers: { "Content-Type": "application/json" },
      body: { error: "Internal server error" }
    };
  }
};

