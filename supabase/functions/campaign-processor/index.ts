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
    const { campaignId } = await req.json().catch(() => ({}));

    // Lookup target campaign first to authorize against its business_id when user-triggered
    let campaignQuery = supabase
      .from("communication_campaigns")
      .select("*, message_templates(*)")
      .in("status", ["queued", "processing"])
      .order("created_at", { ascending: true })
      .limit(1);

    if (campaignId) {
      campaignQuery = supabase
        .from("communication_campaigns")
        .select("*, message_templates(*)")
        .eq("id", campaignId);
    }

    const { data: campaigns, error: campErr } = await campaignQuery;
    if (campErr || !campaigns || campaigns.length === 0) {
      return jsonResponse({ message: "No active campaigns to process" }, 200);
    }

    const campaign = campaigns[0];

    // Authorize internal cron or authenticated business owner
    const auth = await authorizeBusinessOrInternal(
      req,
      supabase,
      campaign.business_id,
      true,
    );
    if (!auth.ok) return auth.response;

    // Enforce Pro entitlement + monthly quota
    const ent = await requireEntitlement(
      supabase,
      campaign.business_id,
      "can_use_bulk_messaging",
    );
    if (!ent.allowed) return ent.response;

    // Require live gateway credentials unless explicitly running in sandbox simulation
    const allowDryRun = Deno.env.get("ALLOW_CAMPAIGN_DRY_RUN") === "true";
    if (!allowDryRun) {
      if (campaign.channel === "whatsapp_api" && !Deno.env.get("WHATSAPP_CLOUD_API_TOKEN")) {
        return jsonResponse(
          {
            error: "WHATSAPP_CLOUD_API_TOKEN is not configured for bulk dispatch.",
            code: "AWAITING_WHATSAPP_CREDENTIALS",
          },
          503,
        );
      }
      if (campaign.channel === "sms_api" && !Deno.env.get("SMS_GATEWAY_API_KEY")) {
        return jsonResponse(
          {
            error: "SMS_GATEWAY_API_KEY is not configured for bulk SMS dispatch.",
            code: "AWAITING_SMS_CREDENTIALS",
          },
          503,
        );
      }
    }

    // Mark as processing
    await supabase
      .from("communication_campaigns")
      .update({
        status: "processing",
        started_at: campaign.started_at ?? new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq("id", campaign.id);

    const { data: recipients, error: recipErr } = await supabase
      .from("campaign_recipients")
      .select("*")
      .eq("campaign_id", campaign.id)
      .eq("submission_status", "pending")
      .eq("eligibility_status", "eligible")
      .limit(50);

    if (recipErr) throw recipErr;

    let processedCount = 0;
    let submittedBatch = 0;
    let failedBatch = 0;
    let skippedBatch = 0;

    const templateBody = campaign.message_templates?.body ?? "";
    const perMessageCost = campaign.channel === "whatsapp_api" ? 0.85 : 0.25;

    for (const recip of recipients ?? []) {
      processedCount++;

      // Re-verify opt-out consent right before send
      if (recip.customer_id) {
        const { data: pref } = await supabase
          .from("customer_messaging_preferences")
          .select("opted_out_all, whatsapp_opt_in, sms_opt_in")
          .eq("customer_id", recip.customer_id)
          .maybeSingle();

        const channelOptedIn =
          campaign.channel === "whatsapp_api"
            ? (pref?.whatsapp_opt_in ?? true)
            : (pref?.sms_opt_in ?? true);

        if (pref?.opted_out_all || !channelOptedIn) {
          await supabase
            .from("campaign_recipients")
            .update({
              eligibility_status: "opted_out",
              submission_status: "skipped",
              failure_reason: "Customer opted out before dispatch",
            })
            .eq("id", recip.id);
          skippedBatch++;
          continue;
        }
      }

      const personalized = templateBody
        .replace(/\{\{customer_name\}\}/g, recip.recipient_name ?? "Customer");

      // Dispatch through authenticated internal gateway endpoint or sandbox dry-run
      let dispatchOk = allowDryRun;
      let providerId: string | null = allowDryRun ? `dryrun_${crypto.randomUUID()}` : null;
      let dispatchErr: string | null = null;

      if (!allowDryRun) {
        const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
        const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
        const fnName =
          campaign.channel === "whatsapp_api" ? "whatsapp-cloud-api" : "sms-gateway";
        const fnRes = await fetch(`${supabaseUrl}/functions/v1/${fnName}`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${serviceKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            businessId: campaign.business_id,
            customerId: recip.customer_id,
            recipientPhone: recip.recipient_phone,
            recipientName: recip.recipient_name,
            templateName: campaign.message_templates?.name ?? "yaadibook_notice",
            messageBody: personalized,
          }),
        });
        const fnJson = await fnRes.json().catch(() => ({}));
        dispatchOk = fnRes.ok && Boolean(fnJson.success);
        providerId = fnJson.messageId ? String(fnJson.messageId) : null;
        if (!dispatchOk) {
          dispatchErr = String(fnJson.error ?? fnJson.message ?? "Gateway dispatch failed");
        }
      }

      await supabase
        .from("campaign_recipients")
        .update({
          submission_status: dispatchOk ? "submitted" : "failed",
          provider_message_id: providerId,
          failure_reason: dispatchErr,
        })
        .eq("id", recip.id);

      await supabase.from("communication_logs").insert({
        business_id: campaign.business_id,
        customer_id: recip.customer_id,
        channel: campaign.channel === "whatsapp_api" ? "whatsapp" : "sms",
        message_type: "bulk_campaign",
        recipient_phone: recip.recipient_phone,
        recipient_name: recip.recipient_name,
        direction: "outbound",
        status: dispatchOk ? "submitted" : "failed",
        message_body: personalized,
        error_message: dispatchErr,
        cost: dispatchOk ? perMessageCost : 0.0,
      });

      if (dispatchOk) submittedBatch++;
      else failedBatch++;
    }

    const newSubmitted = (campaign.submitted_count ?? 0) + submittedBatch;
    const newFailed = (campaign.failed_count ?? 0) + failedBatch;
    const newSkipped = (campaign.skipped_count ?? 0) + skippedBatch;
    const newTotalProcessed = newSubmitted + newFailed + newSkipped;
    const isCompleted =
      newTotalProcessed >= (campaign.eligible_recipients || campaign.total_recipients);
    const finalStatus = isCompleted
      ? newFailed > 0 && newSubmitted > 0
        ? "partially_completed"
        : newSubmitted === 0 && newFailed > 0
          ? "failed"
          : "completed"
      : "processing";

    await supabase
      .from("communication_campaigns")
      .update({
        submitted_count: newSubmitted,
        failed_count: newFailed,
        skipped_count: newSkipped,
        actual_cost: newSubmitted * perMessageCost,
        status: finalStatus,
        completed_at: isCompleted ? new Date().toISOString() : null,
        updated_at: new Date().toISOString(),
      })
      .eq("id", campaign.id);

    if (submittedBatch > 0) {
      await supabase.from("communication_usage").insert({
        business_id: campaign.business_id,
        channel: campaign.channel,
        provider: campaign.channel === "whatsapp_api" ? "meta_cloud" : "sms_dlt",
        message_category: "marketing",
        message_count: submittedBatch,
        estimated_cost: submittedBatch * perMessageCost,
        actual_cost: submittedBatch * perMessageCost,
        campaign_id: campaign.id,
      });
    }

    return jsonResponse(
      {
        campaignId: campaign.id,
        processed: processedCount,
        submitted: submittedBatch,
        failed: failedBatch,
        skipped: skippedBatch,
        status: finalStatus,
        isCompleted,
      },
      200,
    );
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : String(error) },
      500,
    );
  }
});
