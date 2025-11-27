import { AzureFunction, Context, HttpRequest } from "@azure/functions";

// In-memory storage for latency samples (max 5)
const samples: number[] = [];
const MAX_SAMPLES = 5;

const httpTrigger: AzureFunction = async function (
  context: Context,
  req: HttpRequest
): Promise<void> {
  const headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    context.res = { status: 204, headers };
    return;
  }

  if (req.method === "POST") {
    try {
      const body = req.body;
      const latency = typeof body?.latency === "number" ? body.latency : null;

      if (latency === null || latency < 0) {
        context.res = {
          status: 400,
          headers,
          body: { error: "Invalid latency value. Expected { latency: number }" },
        };
        return;
      }

      // Add new sample, keep only last 5
      samples.push(latency);
      if (samples.length > MAX_SAMPLES) {
        samples.shift();
      }

      context.res = {
        status: 200,
        headers,
        body: { success: true, recorded: latency, totalSamples: samples.length },
      };
    } catch (error) {
      context.res = {
        status: 500,
        headers,
        body: { error: "Failed to process request" },
      };
    }
    return;
  }

  // GET request - return stats
  if (samples.length === 0) {
    context.res = {
      status: 200,
      headers,
      body: {
        latest: 0,
        min: 0,
        max: 0,
        avg: 0,
        samples: [],
      },
    };
    return;
  }

  const latest = samples[samples.length - 1];
  const min = Math.min(...samples);
  const max = Math.max(...samples);
  const avg = Math.round(samples.reduce((a, b) => a + b, 0) / samples.length);

  context.res = {
    status: 200,
    headers,
    body: {
      latest,
      min,
      max,
      avg,
      samples: [...samples],
    },
  };
};

export default httpTrigger;
