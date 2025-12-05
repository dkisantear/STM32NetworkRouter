const { TableClient } = require("@azure/data-tables");

const TABLE_NAME = "GatewayStatus";
const PARTITION_KEY = "stm32-switch-state";
const CONNECTION_STRING = process.env.TABLES_CONNECTION_STRING;

function getTableClient() {
  if (!CONNECTION_STRING) {
    throw new Error("TABLES_CONNECTION_STRING environment variable is not set");
  }
  return TableClient.fromConnectionString(CONNECTION_STRING, TABLE_NAME);
}

module.exports = async function (context, req) {
  const method = (req.method || "GET").toUpperCase();

  try {
    const tableClient = getTableClient();
    const DEVICE_ID = "stm32-master";

    // POST: Update switch state (from Pi bridge when STM32 reports it)
    if (method === "POST") {
      const { mode, value } = req.body || {};

      if (mode !== "serial" && mode !== "uart" && mode !== "parallel") {
        context.res = {
          status: 400,
          body: { error: "Mode must be 'serial', 'uart', or 'parallel'" },
          headers: { "Content-Type": "application/json" },
        };
        return;
      }

      const lastUpdated = new Date().toISOString();
      const entity = {
        partitionKey: PARTITION_KEY,
        rowKey: DEVICE_ID,
        mode: mode,
        value: value || null,
        lastUpdated: lastUpdated,
      };

      await tableClient.upsertEntity(entity, "Replace");

      context.res = {
        status: 200,
        body: {
          success: true,
          deviceId: DEVICE_ID,
          mode: mode,
          value: value,
          lastUpdated: lastUpdated,
        },
        headers: { "Content-Type": "application/json" },
      };
      return;
    }

    // GET: Retrieve current switch state (for frontend to poll)
    if (method === "GET") {
      try {
        const entity = await tableClient.getEntity(PARTITION_KEY, DEVICE_ID);

        context.res = {
          status: 200,
          body: {
            deviceId: DEVICE_ID,
            mode: entity.mode || "unknown",
            value: entity.value || null,
            lastUpdated: entity.lastUpdated || null,
          },
          headers: { "Content-Type": "application/json" },
        };
        return;
      } catch (error) {
        if (error.statusCode === 404) {
          context.res = {
            status: 200,
            body: {
              deviceId: DEVICE_ID,
              mode: "unknown",
              value: null,
              lastUpdated: null,
            },
            headers: { "Content-Type": "application/json" },
          };
          return;
        }
        throw error;
      }
    }

    context.res = {
      status: 405,
      body: { error: "Method not allowed" },
      headers: { "Content-Type": "application/json" },
    };
  } catch (error) {
    context.log.error("Error processing switch state:", error);
    context.res = {
      status: 500,
      body: {
        error: "Internal server error",
        message: error.message,
      },
      headers: { "Content-Type": "application/json" },
    };
  }
};

