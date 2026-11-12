import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-cron-secret",
};

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function createServiceClient(): SupabaseClient {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  return createClient(supabaseUrl, serviceKey);
}

/**
 * Verifies either:
 * 1) A valid Supabase user JWT whose uid owns `businessId`, OR
 * 2) An internal trusted caller bearing CRON_SECRET or SUPABASE_SERVICE_ROLE_KEY.
 */
export async function authorizeBusinessOrInternal(
  req: Request,
  supabaseAdmin: SupabaseClient,
  businessId?: string,
  allowInternalCron = false,
): Promise<{ ok: true; mode: "user" | "internal"; userId?: string } | { ok: false; response: Response }> {
  const authHeader = req.headers.get("Authorization") ?? "";
  const cronSecretHeader = req.headers.get("x-cron-secret") ?? "";
  const configuredCronSecret = Deno.env.get("CRON_SECRET") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (allowInternalCron) {
    if (configuredCronSecret && cronSecretHeader === configuredCronSecret) {
      return { ok: true, mode: "internal" };
    }
    if (serviceRoleKey && authHeader === `Bearer ${serviceRoleKey}`) {
      return { ok: true, mode: "internal" };
    }
  }

  if (!authHeader.startsWith("Bearer ")) {
    return { ok: false, response: jsonResponse({ error: "Missing bearer authorization token" }, 401) };
  }

  const token = authHeader.slice(7).trim();
  if (!token) {
    return { ok: false, response: jsonResponse({ error: "Empty bearer token" }, 401) };
  }

  const { data: userData, error: userErr } = await supabaseAdmin.auth.getUser(token);
  if (userErr || !userData?.user) {
    return { ok: false, response: jsonResponse({ error: "Invalid or expired user session" }, 401) };
  }

  const userId = userData.user.id;

  if (businessId) {
    const { data: biz, error: bizErr } = await supabaseAdmin
      .from("businesses")
      .select("id, owner_user_id")
      .eq("id", businessId)
      .maybeSingle();

    if (bizErr || !biz || biz.owner_user_id !== userId) {
      return {
        ok: false,
        response: jsonResponse({ error: "Forbidden: you do not own this business" }, 403),
      };
    }
  }

  return { ok: true, mode: "user", userId };
}

/**
 * Verifies server-side feature entitlement via `check_business_entitlement` RPC.
 */
export async function requireEntitlement(
  supabaseAdmin: SupabaseClient,
  businessId: string,
  featureKey: string,
): Promise<{ allowed: true } | { allowed: false; response: Response }> {
  const { data, error } = await supabaseAdmin.rpc("check_business_entitlement", {
    p_business_id: businessId,
    p_feature_key: featureKey,
  });

  if (error) {
    return {
      allowed: false,
      response: jsonResponse({ error: `Entitlement verification failed: ${error.message}` }, 500),
    };
  }

  const allowed = Boolean((data as Record<string, unknown> | null)?.allowed);
  if (!allowed) {
    const reason = String(
      (data as Record<string, unknown> | null)?.reason ?? "Active Pro subscription required.",
    );
    return {
      allowed: false,
      response: jsonResponse({ error: reason, code: "ENTITLEMENT_REQUIRED", feature: featureKey }, 403),
    };
  }

  return { allowed: true };
}

export async function sha256Hex(input: string): Promise<string> {
  const bytes = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/**
 * Verifies Meta X-Hub-Signature-256 HMAC signature when META_APP_SECRET is configured.
 */
export async function verifyMetaWebhookSignature(
  rawBody: string,
  signatureHeader: string | null,
): Promise<boolean> {
  const appSecret = Deno.env.get("META_APP_SECRET");
  if (!appSecret) {
    // Allow only when explicit webhook verification secret has not been provisioned in sandbox
    return Deno.env.get("ALLOW_UNSIGNED_WEBHOOKS") === "true";
  }
  if (!signatureHeader || !signatureHeader.startsWith("sha256=")) {
    return false;
  }
  const providedHex = signatureHeader.slice(7).toLowerCase();
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(appSecret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(rawBody));
  const expectedHex = Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  if (providedHex.length !== expectedHex.length) return false;
  let diff = 0;
  for (let i = 0; i < expectedHex.length; i++) {
    diff |= providedHex.charCodeAt(i) ^ expectedHex.charCodeAt(i);
  }
  return diff === 0;
}

