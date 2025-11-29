module.exports = async function (context, req) {
  context.log('Ping endpoint called');
  
  try {
    context.res = {
      status: 200,
      headers: { "Content-Type": "application/json" },
      body: {
        status: "ok",
        source: "latencynet-api",
        timestamp: new Date().toISOString()
      }
    };
  } catch (error) {
    context.log.error('Error in ping endpoint:', error);
    context.res = {
      status: 500,
      headers: { "Content-Type": "application/json" },
      body: { error: "Internal server error" }
    };
  }
};

