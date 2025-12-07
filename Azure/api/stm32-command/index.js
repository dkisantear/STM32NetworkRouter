const { TableClient } = require("@azure/data-tables");

const TABLE_NAME = "GatewayStatus";
const PARTITION_KEY = "stm32-commands";
const CONNECTION_STRING = process.env.TABLES_CONNECTION_STRING;

function getTableClient() {
  if (!CONNECTION_STRING) {
    throw new Error("TABLES_CONNECTION_STRING environment variable is not set");
  }
  return TableClient.fromConnectionString(CONNECTION_STRING, TABLE_NAME);
}

module.exports = async function (context, req) {
  const method = (req.method || req.methods?.[0] || "GET").toUpperCase();

  try {
    const tableClient = getTableClient();

    // POST: Store a new command
    if (method === "POST") {
      const { value, mode } = req.body || {};

      if (typeof value !== "number" || value < 0 || value > 16) {
        context.res = {
          status: 400,
          body: { error: "Value must be a number between 0 and 16" },
          headers: { "Content-Type": "application/json" },
        };
        return;
      }

      if (mode !== "serial" && mode !== "uart" && mode !== "parallel") {
        context.res = {
          status: 400,
          body: { error: "Mode must be 'serial', 'uart', or 'parallel'" },
          headers: { "Content-Type": "application/json" },
        };
        return;
      }

      const rowKey = `cmd-${Date.now()}`;
      const entity = {
        partitionKey: PARTITION_KEY,
        rowKey: rowKey,
        value: value,
        mode: mode,
        timestamp: new Date().toISOString(),
        status: "pending", // pending, sent, completed
      };

      await tableClient.createEntity(entity);

      context.res = {
        status: 200,
        body: {
          success: true,
          commandId: rowKey,
          value: value,
          mode: mode,
        },
        headers: { "Content-Type": "application/json" },
      };
      return;
    }

    // GET: Retrieve pending commands (for Pi bridge to poll)
    if (method === "GET") {
      const deviceId = req.query?.deviceId || "stm32-main";
      
      // Query for pending commands
      const entities = [];
      const listEntities = tableClient.listEntities({
        queryOptions: {
          filter: `PartitionKey eq '${PARTITION_KEY}' and status eq 'pending'`,
        },
      });

      for await (const entity of listEntities) {
        entities.push({
          commandId: entity.rowKey,
          value: entity.value,
          mode: entity.mode,
          timestamp: entity.timestamp,
        });
      }

      // Sort by timestamp (oldest first)
      entities.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));

      context.res = {
        status: 200,
        body: {
          commands: entities,
          count: entities.length,
        },
        headers: { "Content-Type": "application/json" },
      };
      return;
    }

    // PUT: Mark command as sent/completed (for Pi bridge)
    if (method === "PUT") {
      const { commandId, status } = req.body || {};

      if (!commandId || !status) {
        context.res = {
          status: 400,
          body: { error: "commandId and status are required" },
          headers: { "Content-Type": "application/json" },
        };
        return;
      }

      if (!["sent", "completed"].includes(status)) {
        context.res = {
          status: 400,
          body: { error: "status must be 'sent' or 'completed'" },
          headers: { "Content-Type": "application/json" },
        };
        return;
      }

      try {
        const entity = await tableClient.getEntity(PARTITION_KEY, commandId);
        entity.status = status;
        await tableClient.updateEntity(entity, "Merge");

        context.res = {
          status: 200,
          body: {
            success: true,
            commandId: commandId,
            status: status,
          },
          headers: { "Content-Type": "application/json" },
        };
      } catch (error) {
        if (error.statusCode === 404) {
          context.res = {
            status: 404,
            body: { error: "Command not found" },
            headers: { "Content-Type": "application/json" },
          };
        } else {
          throw error;
        }
      }
      return;
    }

    context.res = {
      status: 405,
      body: { error: "Method not allowed" },
      headers: { "Content-Type": "application/json" },
    };
  } catch (error) {
    context.log.error("Error:", error);
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

