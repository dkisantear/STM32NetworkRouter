const { TableClient } = require("@azure/data-tables");

const TABLE_NAME = "GatewayStatus";
const PARTITION_KEY = "gateways";

function getTableClient() {
  const connectionString = process.env.TABLES_CONNECTION_STRING;
  if (!connectionString) {
    throw new Error("TABLES_CONNECTION_STRING environment variable is not set");
  }
  return TableClient.fromConnectionString(connectionString, TABLE_NAME);
}

module.exports = async function (context, req) {
  const method = (req.method || "GET").toUpperCase();

  try {
    if (method === "POST") {
      const body = req.body;
      
      if (!body || typeof body !== "object") {
        context.res = {
          status: 400,
          headers: { "Content-Type": "application/json" },
          body: { error: "Request body must be JSON" }
        };
        return;
      }

      const gatewayId = body.gatewayId;
      const status = body.status;

      if (!gatewayId || typeof gatewayId !== "string") {
        context.res = {
          status: 400,
          headers: { "Content-Type": "application/json" },
          body: { error: "gatewayId is required and must be a string" }
        };
        return;
      }

      if (status !== "online" && status !== "offline") {
        context.res = {
          status: 400,
          headers: { "Content-Type": "application/json" },
          body: { error: "status must be 'online' or 'offline'" }
        };
        return;
      }

      const lastUpdated = new Date().toISOString();

      const entity = {
        partitionKey: PARTITION_KEY,
        rowKey: gatewayId,
        status: status,
        lastUpdated: lastUpdated
      };

      const tableClient = getTableClient();
      await tableClient.upsertEntity(entity, "Replace");

      context.log(`Gateway status updated: ${gatewayId} -> ${status}`);

      context.res = {
        status: 200,
        headers: { "Content-Type": "application/json" },
        body: {
          gatewayId: gatewayId,
          status: status,
          lastUpdated: lastUpdated
        }
      };
      return;
    }

    if (method === "GET") {
      const gatewayId = req.query?.gatewayId;

      if (!gatewayId || typeof gatewayId !== "string") {
        context.res = {
          status: 400,
          headers: { "Content-Type": "application/json" },
          body: { error: "gatewayId query parameter is required" }
        };
        return;
      }

      const tableClient = getTableClient();

      try {
        const entity = await tableClient.getEntity(PARTITION_KEY, gatewayId);
        
        const now = new Date();
        let finalStatus = entity.status || "unknown";
        const lastUpdated = entity.lastUpdated || null;
        
        // Automatic timeout: If lastUpdated is older than 90 seconds, mark as offline
        // This handles cases where Pi is unplugged/crashed and can't send POST
        if (lastUpdated && finalStatus === "online") {
          const lastUpdatedDate = new Date(lastUpdated);
          const ageMs = now.getTime() - lastUpdatedDate.getTime();
          const TIMEOUT_MS = 90 * 1000; // 90 seconds timeout
          
          if (ageMs > TIMEOUT_MS) {
            finalStatus = "offline";
            context.log(`Gateway ${gatewayId} timeout: last updated ${Math.round(ageMs / 1000)}s ago, marking as offline`);
          }
        }

        context.res = {
          status: 200,
          headers: { "Content-Type": "application/json" },
          body: {
            gatewayId: gatewayId,
            status: finalStatus,
            lastUpdated: lastUpdated
          }
        };
        return;
      } catch (error) {
        if (error.statusCode === 404) {
          context.res = {
            status: 200,
            headers: { "Content-Type": "application/json" },
            body: {
              gatewayId: gatewayId,
              status: "unknown",
              lastUpdated: null
            }
          };
          return;
        }
        throw error;
      }
    }

    context.res = {
      status: 405,
      headers: { "Allow": "GET, POST", "Content-Type": "application/json" },
      body: { error: "Method not allowed" }
    };
  } catch (error) {
    context.log.error("Error processing gateway status:", error);
    context.res = {
      status: 500,
      headers: { "Content-Type": "application/json" },
      body: {
        error: "Internal server error",
        message: error.message
      }
    };
  }
};
