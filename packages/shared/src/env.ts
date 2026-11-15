import "dotenv/config";
import { z } from "zod";

const EnvSchema = z.object({
  APP_ENV: z.enum(["development", "test", "production"]).default("development"),
  LOG_LEVEL: z.enum(["fatal", "error", "warn", "info", "debug", "trace", "silent"]).default("info"),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  SUPABASE_URL: z.string().url().optional(),
  SUPABASE_ANON_KEY: z.string().min(1).optional(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1).optional(),
  SUPABASE_DB_URL: z.string().min(1).optional(),
  OPENROUTER_API_KEY: z.string().min(1).optional(),
  OPENROUTER_BASE_URL: z.string().url().default("https://openrouter.ai/api/v1"),
  ROBLOX_UNIVERSE_ID: z.string().optional(),
  ROBLOX_OPEN_CLOUD_API_KEY: z.string().optional(),
  FORGE_HMAC_SECRET: z.string().min(32).optional(),
  FORGE_HMAC_KEY_ID: z.string().optional(),
  ED25519_PRIVATE_KEY: z.string().optional(),
  ED25519_PUBLIC_KEY: z.string().optional(),
  CRON_SECRET: z.string().min(32).optional(),
});

export const env = EnvSchema.parse(process.env);
export type Environment = z.infer<typeof EnvSchema>;
