import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  authorizeBusinessOrInternal,
  corsHeaders,
  createServiceClient,
  jsonResponse,
} from "../_shared/security.ts";

/**
 * Initiates permanent account and business data deletion for the authenticated owner.
 * Purges Storage objects belonging to the owner's businesses, logs an audit record,
 * and deletes the Supabase Auth user (cascading business tables via FK constraints).
 */
serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = createServiceClient();
    const body = await req.json();
    const confirmationPhrase = String(body.confirmationPhrase ?? "").trim();
    const reason = body.reason ? String(body.reason).trim() : null;

    if (confirmationPhrase !== "DELETE MY ACCOUNT") {
      return jsonResponse(
        { error: 'Please confirm deletion with exact phrase "DELETE MY ACCOUNT".' },
        400,
      );
    }

    const auth = await authorizeBusinessOrInternal(req, supabaseAdmin, undefined, false);
    if (!auth.ok || !auth.userId) {
      return auth.ok ? jsonResponse({ error: "Unauthorized" }, 401) : auth.response;
    }

    const userId = auth.userId;

    // Fetch user's businesses before cascade deletion to clean Storage buckets
    const { data: businesses } = await supabaseAdmin
      .from("businesses")
      .select("id")
      .eq("owner_user_id", userId);

    const { data: userRecord } = await supabaseAdmin.auth.admin.getUserById(userId);
    const email = userRecord?.user?.email ?? null;
    const primaryBusinessId = businesses?.[0]?.id ?? null;

    // Record audit entry prior to user deletion
    const { data: auditRow } = await supabaseAdmin
      .from("account_deletion_requests")
      .insert({
        user_id: userId,
        business_id: primaryBusinessId,
        email,
        reason,
        status: "processing",
        scheduled_purge_at: new Date().toISOString(),
      })
      .select()
      .single();

    // Clean private storage buckets scoped by business_id folder prefix
    const buckets = [
      "business-assets",
      "customer-attachments",
      "service-attachments",
      "amc-documents",
    ];

    for (const biz of businesses ?? []) {
      for (const bucket of buckets) {
        const { data: files } = await supabaseAdmin.storage
          .from(bucket)
          .list(String(biz.id), { limit: 1000 });
        if (files && files.length > 0) {
          const paths = files.map((f) => `${biz.id}/${f.name}`);
          await supabaseAdmin.storage.from(bucket).remove(paths);
        }
      }
    }

    // Delete business rows explicitly (cascades CRM, services, AMCs, reminders, logs, subscriptions)
    if (businesses && businesses.length > 0) {
      await supabaseAdmin
        .from("businesses")
        .delete()
        .eq("owner_user_id", userId);
    }

    // Delete auth user via Admin API
    const { error: deleteErr } = await supabaseAdmin.auth.admin.deleteUser(userId);
    if (deleteErr) {
      if (auditRow?.id) {
        await supabaseAdmin
          .from("account_deletion_requests")
          .update({ status: "failed", metadata: { error: deleteErr.message } })
          .eq("id", auditRow.id);
      }
      return jsonResponse({ error: `Account deletion failed: ${deleteErr.message}` }, 500);
    }

    if (auditRow?.id) {
      await supabaseAdmin
        .from("account_deletion_requests")
        .update({ status: "completed", completed_at: new Date().toISOString() })
        .eq("id", auditRow.id);
    }

    return jsonResponse(
      {
        success: true,
        message: "Your Yaadibook account and business data have been permanently deleted.",
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

