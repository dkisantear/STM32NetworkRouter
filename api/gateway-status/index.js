let lastSeen = null;

module.exports = async function (context, req) {
  const method = (req.method || "GET").toUpperCase();
  const now = new Date();
  
  if (method === "POST") {
    // Called by the Pi
    lastSeen = now.toISOString();
    
    context.log("Gateway heartbeat received at", lastSeen);
    
    context.res = {
      status: 200,
      headers: { "Content-Type": "application/json" },
      body: {
        message: "Heartbeat received",
        lastSeen: lastSeen
      }
    };
    return;
  }
  
  if (method === "GET") {
    // Called by the frontend
    let status = "offline";
    let msSinceLastSeen = null;
    
    if (lastSeen) {
      const last = new Date(lastSeen);
      msSinceLastSeen = now.getTime() - last.getTime();
      // Threshold: 90 seconds (accounts for 60s heartbeat interval + instance switching delays)
      if (msSinceLastSeen <= 90000) {
        status = "online";
      }
    }
    
    context.res = {
      status: 200,
      headers: { "Content-Type": "application/json" },
      body: {
        status: status,
        lastSeen: lastSeen,
        msSinceLastSeen: msSinceLastSeen
      }
    };
    return;
  }
  
  // Fallback for unsupported methods
  context.res = {
    status: 405,
    headers: { "Allow": "GET, POST" },
    body: { error: "Method not allowed" }
  };
};
