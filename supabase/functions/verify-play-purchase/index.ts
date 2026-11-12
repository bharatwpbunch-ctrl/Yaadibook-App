import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  authorizeBusinessOrInternal,
  corsHeaders,
  createServiceClient,
  jsonResponse,
  sha256Hex,
} from "../_shared/security.ts";

/**
 * Verifies a Google Play purchase token server-side against Google Play Developer API v3
 * and grants/updates business_subscriptions + subscription_transactions idempotently.
 *
 * External Configuration Required:
 * - GOOGLE_PLAY_PACKAGE_NAME (defaults to com.yaadibook.yaadibook)
 * - GOOGLE_PLAY_SERVICE_ACCOUNT_JSON (Service Account JSON with androidpublisher scope)
 */
serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = createServiceClient();
    const body = await req.json();

    const businessId = String(body.businessId ?? "").trim();
    const productId = String(body.productId ?? "").trim();
    const purchaseToken = String(body.purchaseToken ?? "").trim();
    const orderId = body.orderId ? String(body.orderId).trim() : null;
    const isRestore = Boolean(body.isRestore ?? false);

    if (!businessId || !productId || !purchaseToken) {
      return jsonResponse(
        { error: "businessId, productId, and purchaseToken are required." },
        400,
      );
    }

    const auth = await authorizeBusinessOrInternal(req, supabaseAdmin, businessId, false);
    if (!auth.ok) return auth.response;

    const { data: plan, error: planErr } = await supabaseAdmin
      .from("subscription_plans")
      .select("*")
      .eq("play_product_id", productId)
      .eq("is_active", true)
      .maybeSingle();

    if (planErr || !plan) {
      return jsonResponse({ error: `Unknown subscription product: ${productId}` }, 400);
    }

    const serviceAccountJson = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");
    const packageName = Deno.env.get("GOOGLE_PLAY_PACKAGE_NAME") ?? "com.yaadibook.yaadibook";

    if (!serviceAccountJson) {
      return jsonResponse(
        {
          error:
            "Google Play Developer API credentials (GOOGLE_PLAY_SERVICE_ACCOUNT_JSON) are not configured on the server yet.",
          code: "AWAITING_PLAY_CONSOLE_CREDENTIALS",
        },
        503,
      );
    }

    // Exchange Google Play Service Account JWT for OAuth2 access token
    const sa = JSON.parse(serviceAccountJson);
    const accessToken = await getGooglePlayAccessToken(sa);

    const playUrl =
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
      `${encodeURIComponent(packageName)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`;

    const playRes = await fetch(playUrl, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!playRes.ok) {
      const errText = await playRes.text();
      return jsonResponse(
        { error: `Google Play verification failed (${playRes.status})`, details: errText },
        400,
      );
    }

    const playData = await playRes.json();
    const subscriptionState = String(playData.subscriptionState ?? "");
    const lineItems = Array.isArray(playData.lineItems) ? playData.lineItems : [];
    const primaryItem = lineItems[0] ?? {};
    const expiryTimeIso = primaryItem.expiryTime ? String(primaryItem.expiryTime) : null;
    const autoRenew = Boolean(primaryItem.autoRenewingPlan?.autoRenewEnabled ?? false);
    const playOrderId = String(playData.latestOrderId ?? orderId ?? "").trim();

    let status = "active";
    if (subscriptionState === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD") {
      status = "grace_period";
    } else if (subscriptionState === "SUBSCRIPTION_STATE_ON_HOLD") {
      status = "pending";
    } else if (subscriptionState === "SUBSCRIPTION_STATE_PAUSED") {
      status = "cancelled";
    } else if (subscriptionState === "SUBSCRIPTION_STATE_CANCELED") {
      status = "cancelled";
    } else if (subscriptionState === "SUBSCRIPTION_STATE_EXPIRED") {
      status = "expired";
    } else if (subscriptionState !== "SUBSCRIPTION_STATE_ACTIVE") {
      return jsonResponse(
        { error: `Purchase state is not valid for entitlement: ${subscriptionState}` },
        400,
      );
    }

    const tokenHash = await sha256Hex(purchaseToken);
    const externalTxId = playOrderId || `gp_${tokenHash.slice(0, 32)}`;

    const { data: upsertedSub, error: subErr } = await supabaseAdmin
      .from("business_subscriptions")
      .upsert(
        {
          business_id: businessId,
          plan_code: plan.code,
          status,
          store_provider: "google_play",
          product_id: productId,
          purchase_token_hash: tokenHash,
          order_id: playOrderId || null,
          current_period_start: new Date().toISOString(),
          current_period_end: expiryTimeIso,
          auto_renew: autoRenew,
          last_verified_at: new Date().toISOString(),
          metadata: { subscriptionState },
        },
        { onConflict: "business_id" },
      )
      .select()
      .single();

    if (subErr) {
      return jsonResponse({ error: subErr.message }, 500);
    }

    // Idempotent ledger write using unique external_transaction_id
    await supabaseAdmin.from("subscription_transactions").upsert(
      {
        business_id: businessId,
        subscription_id: upsertedSub.id,
        plan_code: plan.code,
        transaction_type: isRestore ? "restore" : "purchase",
        store_provider: "google_play",
        product_id: productId,
        external_transaction_id: externalTxId,
        purchase_token_hash: tokenHash,
        amount_inr: plan.price_inr,
        currency: "INR",
        status: "verified",
        verified_at: new Date().toISOString(),
        raw_metadata: { subscriptionState, expiryTimeIso },
      },
      { onConflict: "external_transaction_id" },
    );

    const { data: snapshot } = await supabaseAdmin.rpc("get_business_entitlements", {
      p_business_id: businessId,
    });

    return jsonResponse({ success: true, subscription: upsertedSub, snapshot }, 200);
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : String(error) },
      500,
    );
  }
});

async function getGooglePlayAccessToken(sa: {
  client_email: string;
  private_key: string;
  token_uri?: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlEncode(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = base64UrlEncode(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/androidpublisher",
      aud: sa.token_uri ?? "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
    }),
  );
  const unsigned = `${header}.${claim}`;
  const key = await importPrivateKey(sa.private_key);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64UrlEncodeBytes(new Uint8Array(signature))}`;

  const tokenRes = await fetch(sa.token_uri ?? "https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const tokenJson = await tokenRes.json();
  if (!tokenRes.ok || !tokenJson.access_token) {
    throw new Error(`Failed to fetch Google Play OAuth token: ${JSON.stringify(tokenJson)}`);
  }
  return String(tokenJson.access_token);
}

function base64UrlEncode(str: string): string {
  return base64UrlEncodeBytes(new TextEncoder().encode(str));
}

function base64UrlEncodeBytes(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const cleaned = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const raw = Uint8Array.from(atob(cleaned), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    raw.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

