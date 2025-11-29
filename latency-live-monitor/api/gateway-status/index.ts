let lastSeen: string | null = null;

export default async function (context: any, req: any): Promise<void> {
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
    connected = diffMs < 30000; // 30 seconds window
  }
  
  context.res = {
    status: 200,
    headers: { "Content-Type": "application/json" },
    body: {
      connected: connected,
      lastSeen: lastSeen
    }
  };
}

