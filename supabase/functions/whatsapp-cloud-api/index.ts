import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  authorizeBusinessOrInternal,
  corsHeaders,
  createServiceClient,
  jsonResponse,
  requireEntitlement,
  verifyMetaWebhookSignature,
} from "../_shared/security.ts";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabase = createServiceClient();

  try {
    // 1. Meta Webhook Challenge Verification (GET)
    if (req.method === "GET") {
      const url = new URL(req.url);
      const mode = url.searchParams.get("hub.mode");
      const token = url.searchParams.get("hub.verify_token");
      const challenge = url.searchParams.get("hub.challenge");
      const webhookVerifyToken = Deno.env.get("WHATSAPP_WEBHOOK_VERIFY_TOKEN");

      if (!webhookVerifyToken) {
        return jsonResponse({ error: "WHATSAPP_WEBHOOK_VERIFY_TOKEN is not configured" }, 503);
      }

      if (mode === "subscribe" && token === webhookVerifyToken) {
        return new Response(challenge ?? "", { status: 200 });
      }
      return new Response("Forbidden", { status: 403 });
    }

    const rawBody = await req.text();
    const payload = rawBody ? JSON.parse(rawBody) : {};

    // 2. Meta Webhook Delivery Status Updates (POST from Meta)
    if (payload.object === "whatsapp_business_account") {
      const sigValid = await verifyMetaWebhookSignature(
        rawBody,
        req.headers.get("x-hub-signature-256"),
      );
      if (!sigValid) {
        return jsonResponse({ error: "Invalid webhook signature" }, 401);
      }

      const entries = payload.entry ?? [];
      for (const entry of entries) {
        for (const change of entry.changes ?? []) {
          for (const statusObj of change.value?.statuses ?? []) {
            const wamid = statusObj.id;
            const status = statusObj.status; // sent, delivered, read, failed
            if (!wamid || !status) continue;

            const mappedStatus =
              status === "read"
                ? "read"
                : status === "delivered"
                  ? "delivered"
                  : status === "failed"
                    ? "failed"
                    : "submitted";

            await supabase
              .from("communication_logs")
              .update({ status: mappedStatus })
              .contains("provider_response", { messages: [{ id: wamid }] });

            await supabase
              .from("campaign_recipients")
              .update({ submission_status: mappedStatus })
              .eq("provider_message_id", wamid);
          }
        }
      }
      return jsonResponse({ received: true }, 200);
    }

    // 3. Authorized Outbound WhatsApp Cloud API Message Send
    const {
      businessId,
      customerId,
      recipientPhone,
      recipientName,
      templateName,
      languageCode = "en",
      components = [],
      messageBody,
    } = payload;

    if (!businessId || !recipientPhone || !templateName) {
      return jsonResponse(
        { error: "businessId, recipientPhone, and templateName are required" },
        400,
      );
    }

    // Verify JWT & business ownership (or internal cron/service caller)
    const auth = await authorizeBusinessOrInternal(req, supabase, businessId, true);
    if (!auth.ok) return auth.response;

    // Enforce server-side Pro subscription entitlement + monthly quota
    const ent = await requireEntitlement(supabase, businessId, "can_use_whatsapp_api");
    if (!ent.allowed) return ent.response;

    const { data: config } = await supabase
      .from("provider_configurations")
      .select("phone_number_id, connection_status")
      .eq("business_id", businessId)
      .eq("provider_type", "meta_whatsapp_cloud")
      .maybeSingle();

    const phoneNumberId =
      config?.phone_number_id || Deno.env.get("DEFAULT_WHATSAPP_PHONE_NUMBER_ID");
    const accessToken = Deno.env.get("WHATSAPP_CLOUD_API_TOKEN");

    if (!phoneNumberId || !accessToken) {
      const { data: logEntry } = await supabase
        .from("communication_logs")
        .insert({
          business_id: businessId,
          customer_id: customerId ?? null,
          channel: "whatsapp",
          message_type: "cloud_api",
          recipient_phone: recipientPhone,
          recipient_name: recipientName ?? null,
          direction: "outbound",
          status: "failed",
          message_body: messageBody || `Template: ${templateName}`,
          error_message:
            "WhatsApp Cloud API credentials (WHATSAPP_CLOUD_API_TOKEN / phone_number_id) not configured",
        })
        .select()
        .single();

      return jsonResponse(
        {
          success: false,
          code: "AWAITING_WHATSAPP_CREDENTIALS",
          message: "WhatsApp Cloud API credentials are not configured on the server yet.",
          log: logEntry,
        },
        503,
      );
    }

    const metaResponse = await fetch(
      `https://graph.facebook.com/v21.0/${phoneNumberId}/messages`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          messaging_product: "whatsapp",
          recipient_type: "individual",
          to: String(recipientPhone).replace(/\D/g, ""),
          type: "template",
          template: {
            name: templateName,
            language: { code: languageCode },
            components,
          },
        }),
      },
    );

    const metaData = await metaResponse.json();
    const wamid = metaData.messages?.[0]?.id;

    const { data: logEntry } = await supabase
      .from("communication_logs")
      .insert({
        business_id: businessId,
        customer_id: customerId ?? null,
        channel: "whatsapp",
        message_type: "cloud_api",
        recipient_phone: recipientPhone,
        recipient_name: recipientName ?? null,
        direction: "outbound",
        status: metaResponse.ok ? "submitted" : "failed",
        message_body: messageBody || `Template: ${templateName}`,
        provider_response: metaData,
        cost: metaResponse.ok ? 0.85 : 0.0,
      })
      .select()
      .single();

    return jsonResponse(
      {
        success: metaResponse.ok,
        messageId: wamid,
        log: logEntry,
        providerResponse: metaData,
      },
      metaResponse.ok ? 200 : 400,
    );
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : String(error) },
      500,
    );
  }
});
