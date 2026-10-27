import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ALLOWED_ORIGINS = new Set(["https://ubnlord.github.io"]);
const headers = (origin: string | null) => ({
  "Access-Control-Allow-Origin": origin && ALLOWED_ORIGINS.has(origin) ? origin : "https://ubnlord.github.io",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Vary": "Origin",
  "Content-Type": "application/json",
});
const json = (body: unknown, status = 200, origin: string | null = null) =>
  new Response(JSON.stringify(body), { status, headers: headers(origin) });

Deno.serve(async (req: Request) => {
  const origin = req.headers.get("origin");
  if (req.method === "OPTIONS") return new Response("ok", { headers: headers(origin) });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405, origin);
  if (origin && !ALLOWED_ORIGINS.has(origin)) return json({ error: "Origin not allowed" }, 403, origin);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Sign in required" }, 401, origin);

  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) return json({ error: "Invalid session" }, 401, origin);
  // Admin status must be assigned by a trusted Supabase administrator in app_metadata.
  // Never accept a role from user_metadata or from the request body.
  const appMeta = user.app_metadata ?? {};
  if (appMeta.role !== "admin" && appMeta.is_admin !== true) {
    return json({ error: "Administrator access required" }, 403, origin);
  }

  const db = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  try {
    const body = await req.json();
    const action = String(body?.action ?? "");

    if (action === "list_support") {
      const { data: requests, error } = await db.from("support_requests")
        .select("id,user_id,subject,category,message,status,created_at")
        .order("created_at", { ascending: false }).limit(100);
      if (error) throw error;
      const ids = (requests ?? []).map((r: { id: string }) => r.id);
      const { data: replies, error: replyError } = ids.length
        ? await db.from("support_replies").select("id,support_request_id,author_user_id,author_role,message,created_at").in("support_request_id", ids).order("created_at", { ascending: true })
        : { data: [], error: null };
      if (replyError) throw replyError;
      return json({ requests: requests ?? [], replies: replies ?? [] }, 200, origin);
    }

    if (action === "reply_support") {
      const requestId = String(body?.request_id ?? "");
      const message = String(body?.message ?? "").trim();
      if (!/^[0-9a-f-]{36}$/i.test(requestId) || message.length < 1 || message.length > 3000) {
        return json({ error: "Provide a valid request ID and a reply of 1–3000 characters." }, 400, origin);
      }
      const { data: request, error: requestError } = await db.from("support_requests")
        .select("id,user_id,status,subject").eq("id", requestId).maybeSingle();
      if (requestError) throw requestError;
      if (!request) return json({ error: "Support request not found." }, 404, origin);
      if (request.status === "resolved" || request.status === "closed") {
        return json({ error: "Reopen the request through an authorized workflow before replying." }, 409, origin);
      }
      const { error: replyError } = await db.from("support_replies").insert({
        support_request_id: request.id, author_user_id: user.id, author_role: "admin", message,
      });
      if (replyError) throw replyError;
      const { error: statusError } = await db.from("support_requests").update({ status: "in_progress" }).eq("id", request.id);
      if (statusError) throw statusError;
      const { error: noticeError } = await db.from("customer_notifications").insert({
        user_id: request.user_id, title: "Support replied to your request",
        body: "There is a new reply to: " + request.subject,
        category: "support",
      });
      if (noticeError) throw noticeError;
      return json({ success: true }, 200, origin);
    }

    if (action === "resolve_support") {
      const requestId = String(body?.request_id ?? "");
      if (!/^[0-9a-f-]{36}$/i.test(requestId)) return json({ error: "Valid request ID required." }, 400, origin);
      const { data: request, error: readError } = await db.from("support_requests")
        .select("id,user_id,subject").eq("id", requestId).maybeSingle();
      if (readError) throw readError;
      if (!request) return json({ error: "Support request not found." }, 404, origin);
      const { error } = await db.from("support_requests").update({ status: "resolved" }).eq("id", requestId);
      if (error) throw error;
      const { error: noticeError } = await db.from("customer_notifications").insert({
        user_id: request.user_id, title: "Support request resolved",
        body: "Your request has been marked resolved: " + request.subject,
        category: "support",
      });
      if (noticeError) throw noticeError;
      return json({ success: true }, 200, origin);
    }

    if (action === "create_notification") {
      const userId = String(body?.user_id ?? "");
      const title = String(body?.title ?? "").trim();
      const message = String(body?.message ?? "").trim();
      const category = String(body?.category ?? "general");
      if (!/^[0-9a-f-]{36}$/i.test(userId) || title.length < 1 || title.length > 120 ||
          message.length < 1 || message.length > 1000 ||
          !["account", "security", "transaction", "support", "general"].includes(category)) {
        return json({ error: "Invalid recipient or notification fields." }, 400, origin);
      }
      const { error } = await db.from("customer_notifications").insert({
        user_id: userId, title, body: message, category,
      });
      if (error) throw error;
      return json({ success: true }, 200, origin);
    }

    return json({ error: "Unsupported action." }, 400, origin);
  } catch (error) {
    console.error("pledge-bank-admin error", error);
    return json({ error: "The request could not be completed. Check server logs or try again." }, 500, origin);
  }
});
