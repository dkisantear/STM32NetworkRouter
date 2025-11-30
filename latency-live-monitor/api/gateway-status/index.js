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
  let connected = false;
  
  if (lastSeen) {
    const diffMs = now.getTime() - new Date(lastSeen).getTime();
    connected = diffMs < 90000; // 90 seconds (accounts for 60s heartbeat + instance switching)
  }
  
  context.res = {
    status: 200,
    headers: { "Content-Type": "application/json" },
    body: {
      connected: connected,
      lastSeen: lastSeen
    }
  };
};

