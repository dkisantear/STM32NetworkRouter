const state = require("../gatewayState");

module.exports = async function (context, req) {
  context.log('Gateway status endpoint called');
  
  try {
    const status = state.getStatus();

    context.res = {
      status: 200,
      headers: { "Content-Type": "application/json" },
      body: {
        ok: true,
        ...status
      }
    };
  } catch (error) {
    context.log.error('Error in gateway status endpoint:', error);
    context.res = {
      status: 500,
      headers: { "Content-Type": "application/json" },
      body: { error: "Internal server error" }
    };
  }
};

