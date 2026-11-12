import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  authorizeBusinessOrInternal,
  corsHeaders,
  createServiceClient,
  jsonResponse,
  requireEntitlement,
} from "../_shared/security.ts";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createServiceClient();
    const {
      businessId,
      customerId,
      recipientPhone,
      recipientName,
      messageBody,
      dltTemplateId,
    } = await req.json();

    if (!businessId || !recipientPhone || !messageBody) {
      return jsonResponse(
        { error: "businessId, recipientPhone, and messageBody are required" },
        400,
      );
    }

    // Verify JWT & business ownership (or internal cron/service caller)
    const auth = await authorizeBusinessOrInternal(req, supabase, businessId, true);
    if (!auth.ok) return auth.response;

    // Enforce server-side Pro subscription entitlement + monthly quota
    const ent = await requireEntitlement(supabase, businessId, "can_use_sms_api");
    if (!ent.allowed) return ent.response;

    const { data: config } = await supabase
      .from("provider_configurations")
      .select("sender_id, entity_id, connection_status")
      .eq("business_id", businessId)
      .eq("provider_type", "sms_india_dlt")
      .maybeSingle();

    const apiKey = Deno.env.get("SMS_GATEWAY_API_KEY");
    const senderId = config?.sender_id || Deno.env.get("DEFAULT_SMS_SENDER_ID") || "YDBOOK";
    const entityId = config?.entity_id || Deno.env.get("DEFAULT_DLT_ENTITY_ID");

    if (!apiKey) {
      const { data: logEntry } = await supabase
        .from("communication_logs")
        .insert({
          business_id: businessId,
          customer_id: customerId ?? null,
          channel: "sms",
          message_type: "sms_api",
          recipient_phone: recipientPhone,
          recipient_name: recipientName ?? null,
          direction: "outbound",
          status: "failed",
          message_body: messageBody,
          error_message:
            "India DLT SMS Gateway API key (SMS_GATEWAY_API_KEY) not configured",
        })
        .select()
        .single();

      return jsonResponse(
        {
          success: false,
          code: "AWAITING_SMS_CREDENTIALS",
          message: "SMS Gateway credentials are not configured on the server yet.",
          log: logEntry,
        },
        503,
      );
    }

    const cleanPhone = String(recipientPhone).replace(/\D/g, "").replace(/^91/, "");
    if (cleanPhone.length !== 10) {
      return jsonResponse(
        { error: "Invalid Indian mobile number for SMS gateway" },
        400,
      );
    }

    const smsEndpoint =
      Deno.env.get("SMS_GATEWAY_URL") || "https://api.sms-gateway.in/v1/send";
    const smsRes = await fetch(smsEndpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        sender_id: senderId,
        entity_id: entityId,
        template_id: dltTemplateId,
        to: `91${cleanPhone}`,
        message: messageBody,
      }),
    });

    const smsData = await smsRes.json();

    const { data: logEntry } = await supabase
      .from("communication_logs")
      .insert({
        business_id: businessId,
        customer_id: customerId ?? null,
        channel: "sms",
        message_type: "sms_api",
        recipient_phone: recipientPhone,
        recipient_name: recipientName ?? null,
        direction: "outbound",
        status: smsRes.ok ? "submitted" : "failed",
        message_body: messageBody,
        provider_response: smsData,
        cost: smsRes.ok ? 0.25 : 0.0,
      })
      .select()
      .single();

    return jsonResponse(
      {
        success: smsRes.ok,
        log: logEntry,
        providerResponse: smsData,
      },
      smsRes.ok ? 200 : 400,
    );
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : String(error) },
      500,
    );
  }
});
