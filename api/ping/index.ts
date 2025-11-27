// api/ping/index.ts

export default async function (context: any, req: any): Promise<void> {
  context.res = {
    status: 200,
    headers: { "Content-Type": "application/json" },
    body: {
      status: "ok",
      source: "Azure Static Web Apps mock API",
      ts: new Date().toISOString(),
    },
  };
}
