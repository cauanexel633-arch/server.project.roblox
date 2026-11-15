import Fastify from "fastify";
import sensible from "@fastify/sensible";
import cors from "@fastify/cors";
import { env } from "../../packages/shared/src/env.js";

export const app = Fastify({
  logger: { level: env.LOG_LEVEL },
  bodyLimit: 1_048_576,
});

await app.register(sensible);
await app.register(cors, { origin: false });

app.get("/health", async () => ({
  status: "ok",
  service: "forge3d-cloud",
  version: "0.1.0",
}));

app.get("/ready", async (_request, reply) => {
  // A prontidão completa será conectada ao Supabase em F1.
  return reply.code(200).send({ status: "ready", checks: { configuration: "ok" } });
});

if (process.env["VERCEL"] !== "1") {
  await app.listen({ port: env.PORT, host: "0.0.0.0" });
}
