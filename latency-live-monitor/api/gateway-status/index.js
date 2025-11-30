let lastSeen = null;

module.exports = async function (context, req) {
  const method = (req.method || "GET").toUpperCase();
  
  if (method === "POST") {
    lastSeen = new Date().toISOString();
    
    context.res = {
      status: 200,
      headers: { "Content-Type": "application/json" },
      body: {
        ok: true,
        lastSeen: lastSeen
      }
    };
    return;
  }
  
  // GET request
  const now = new Date();
  let status = "offline";
  let msSinceLastSeen = null;
  
  if (lastSeen) {
    const last = new Date(lastSeen);
    msSinceLastSeen = now.getTime() - last.getTime();
    // Threshold: 3 minutes (180 seconds) - large buffer for instance isolation
    if (msSinceLastSeen <= 180000) {
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
};

