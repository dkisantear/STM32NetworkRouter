const state = require("../gatewayState");

module.exports = async function (context, req) {
  context.log('Gateway heartbeat endpoint called');
  
  try {
    const body = req.body || {};

    // Optional simple shared secret for the Pi
    const expectedSecret = process.env.PI_HEARTBEAT_SECRET;
    if (expectedSecret && body.secret !== expectedSecret) {
      context.res = {
        status: 401,
        headers: { "Content-Type": "application/json" },
        body: { ok: false, error: "unauthorized" }
      };
      return;
    }

    state.update();

    const status = state.getStatus();

    context.res = {
      status: 200,
      headers: { "Content-Type": "application/json" },
      body: {
        ok: true,
        source: body.source || "raspberry-pi",
        ...status
      }
    };
  } catch (error) {
    context.log.error('Error in gateway heartbeat endpoint:', error);
    context.res = {
      status: 500,
      headers: { "Content-Type": "application/json" },
      body: { error: "Internal server error" }
    };
  }
};

