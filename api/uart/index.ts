function getFakeLatencyStats(label: string) {
  const samples = Array.from({ length: 5 }, () =>
    20 + Math.round(Math.random() * 30)
  );

  const min = Math.min(...samples);
  const max = Math.max(...samples);
  const avg = Math.round(samples.reduce((a, b) => a + b, 0) / samples.length);

  return {
    label,
    status: "offline",
    samples,
    min,
    max,
    avg,
    updatedAt: new Date().toISOString(),
  };
}

export default async function (context: any, req: any): Promise<void> {
  const data = getFakeLatencyStats("UART Server 2");

  context.res = {
    status: 200,
    headers: {
      "Content-Type": "application/json",
    },
    body: data,
  };
}
