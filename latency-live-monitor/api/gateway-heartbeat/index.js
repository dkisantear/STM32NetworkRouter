module.exports = async function (context, req) {
  context.log("Gateway heartbeat called");
  const now = new Date().toISOString();

  context.res = {
    status: 200,
    headers: { "Content-Type": "application/json" },
    body: {
      status: "ok",
      source: "gateway-heartbeat",
      timestamp: now
    }
  };
};

