import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { env } from "../../shared/src/env.js";

let adminClient: SupabaseClient | undefined;

export function getAdminSupabase(): SupabaseClient {
  if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error("Supabase server credentials are not configured.");
  }

  adminClient ??= createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: { headers: { "X-Application-Name": "forge3d-cloud-v2" } },
  });

  return adminClient;
}
