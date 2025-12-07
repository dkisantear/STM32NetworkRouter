const { TableClient } = require("@azure/data-tables");

const TABLE_NAME = "GatewayStatus";
const PARTITION_KEY = "stm32";
const TIMEOUT_MS = 90 * 1000;

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

      const deviceId = body.deviceId;
      const status = body.status;

      if (!deviceId || typeof deviceId !== "string") {
        context.res = {
          status: 400,
          headers: { "Content-Type": "application/json" },
          body: { error: "deviceId is required and must be a string" }
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
        rowKey: deviceId,
        status: status,
        lastUpdated: lastUpdated
      };

      const tableClient = getTableClient();
      await tableClient.upsertEntity(entity, "Replace");

      context.log(`STM32 status updated: ${deviceId} -> ${status}`);

      context.res = {
        status: 200,
        headers: { "Content-Type": "application/json" },
        body: {
          deviceId: deviceId,
          status: status,
          lastUpdated: lastUpdated
        }
      };
      return;
    }

    if (method === "GET") {
      const deviceId = req.query?.deviceId;

      if (!deviceId || typeof deviceId !== "string") {
        context.res = {
          status: 400,
          headers: { "Content-Type": "application/json" },
          body: { error: "deviceId query parameter is required" }
        };
        return;
      }

      const tableClient = getTableClient();

      try {
        const entity = await tableClient.getEntity(PARTITION_KEY, deviceId);

        const now = new Date();
        let finalStatus = entity.status || "unknown";
        const lastUpdated = entity.lastUpdated || null;

        // Automatic timeout: If lastUpdated is older than 90 seconds, mark as offline
        if (lastUpdated && finalStatus === "online") {
          const lastUpdatedDate = new Date(lastUpdated);
          const ageMs = now.getTime() - lastUpdatedDate.getTime();

          if (ageMs > TIMEOUT_MS) {
            finalStatus = "offline";
            context.log(`STM32 ${deviceId} timeout: last updated ${Math.round(ageMs / 1000)}s ago, marking as offline`);
          }
        }

        context.res = {
          status: 200,
          headers: { "Content-Type": "application/json" },
          body: {
            deviceId: deviceId,
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
              deviceId: deviceId,
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
    context.log.error("Error processing STM32 status:", error);
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

