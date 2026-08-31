import { createClient } from "@supabase/supabase-js";
import {
  fetchGithubSnapshots,
  isUuid,
  mapGithubError,
  parseRepoFullName,
  type GithubFetchOptions,
} from "./github.ts";

const MAX_REQUEST_BODY_BYTES = 32 * 1024;
const DEFAULT_ALLOWED_ORIGINS = new Set([
  "http://localhost:5173",
  "http://127.0.0.1:5173",
]);

interface Environment {
  get(name: string): string | undefined;
}

interface SupabaseQuery {
  select(columns: string): SupabaseQuery;
  eq(column: string, value: string): SupabaseQuery;
  maybeSingle(): Promise<{ data: unknown; error: unknown } | { data?: unknown; error?: unknown }>;
}

interface SupabaseClientLike {
  auth: {
    getUser(token: string): Promise<{
      data?: { user?: { id?: string } | null } | null;
      error?: unknown;
    }>;
  };
  from(table: string): SupabaseQuery;
  rpc(
    functionName: string,
    args: Record<string, unknown>,
  ): Promise<{ data: unknown; error: unknown }>;
}

type ClientFactory = (
  url: string,
  key: string,
  options: Record<string, unknown>,
) => SupabaseClientLike;

export interface HandlerDependencies {
  env?: Environment;
  fetchImpl?: typeof fetch;
  createClient?: ClientFactory;
}

class ConfigError extends Error {}

class RequestValidationError extends Error {}

function runtimeEnvironment(): Environment {
  const runtime = globalThis as typeof globalThis & {
    Deno?: { env: { get(name: string): string | undefined } };
  };
  return {
    get: (name: string) => runtime.Deno?.env.get(name),
  };
}

function defaultClientFactory(
  url: string,
  key: string,
  options: Record<string, unknown>,
): SupabaseClientLike {
  return createClient(url, key, options as Parameters<typeof createClient>[2]) as unknown as SupabaseClientLike;
}

function readJsonKeyMap(raw: string | undefined): string | undefined {
  if (raw === undefined || raw.trim() === "") return undefined;
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new ConfigError("Supabase key map is invalid");
  }
  if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
    throw new ConfigError("Supabase key map is invalid");
  }
  const entries = Object.entries(parsed as Record<string, unknown>)
    .filter((entry): entry is [string, string] => typeof entry[1] === "string" && entry[1].trim() !== "")
    .sort(([left], [right]) => left.localeCompare(right));
  if (entries.length === 0) throw new ConfigError("Supabase key map is empty");
  const preferred = ["service_role", "service-role", "secret", "default", "anon", "publishable"];
  for (const name of preferred) {
    const match = entries.find(([key]) => key === name);
    if (match) return match[1];
  }
  return entries[0][1];
}

function getSupabaseUrl(env: Environment): string {
  const raw = env.get("SUPABASE_URL")?.trim();
  if (!raw) throw new ConfigError("Supabase URL is not configured");
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new ConfigError("Supabase URL is invalid");
  }
  if (
    (url.protocol !== "https:" && url.protocol !== "http:") ||
    url.username !== "" ||
    url.password !== "" ||
    url.pathname !== "/" ||
    url.search !== "" ||
    url.hash !== ""
  ) {
    throw new ConfigError("Supabase URL is invalid");
  }
  return url.toString().replace(/\/$/, "");
}

function getPublishableKey(env: Environment): string {
  const key = readJsonKeyMap(env.get("SUPABASE_PUBLISHABLE_KEYS")) ?? env.get("SUPABASE_ANON_KEY")?.trim();
  if (!key) throw new ConfigError("Supabase publishable key is not configured");
  return key;
}

function getSecretKey(env: Environment): string {
  const key = readJsonKeyMap(env.get("SUPABASE_SECRET_KEYS")) ?? env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (!key) throw new ConfigError("Supabase secret key is not configured");
  return key;
}

export function parseAllowedOrigins(raw: string | undefined): Set<string> {
  if (raw === undefined || raw.trim() === "") return new Set(DEFAULT_ALLOWED_ORIGINS);
  const origins = new Set<string>();
  for (const value of raw.split(",")) {
    const origin = value.trim();
    if (origin === "" || origin === "*") continue;
    try {
      const parsed = new URL(origin);
      if ((parsed.protocol === "http:" || parsed.protocol === "https:") && parsed.origin === origin) {
        origins.add(origin);
      }
    } catch {
      // Invalid origins are ignored rather than widening authenticated CORS.
    }
  }
  return origins;
}

function corsHeaders(request: Request, env: Environment): Headers {
  const headers = new Headers({ Vary: "Origin" });
  const origin = request.headers.get("origin");
  if (origin !== null && parseAllowedOrigins(env.get("ALLOWED_ORIGINS")).has(origin)) {
    headers.set("Access-Control-Allow-Origin", origin);
  }
  return headers;
}

function jsonResponse(
  request: Request,
  env: Environment,
  status: number,
  body: unknown,
  extraHeaders: Record<string, string> = {},
): Response {
  const headers = corsHeaders(request, env);
  headers.set("Content-Type", "application/json; charset=utf-8");
  headers.set("Cache-Control", "no-store");
  for (const [name, value] of Object.entries(extraHeaders)) headers.set(name, value);
  return new Response(JSON.stringify(body), { status, headers });
}

function errorResponse(
  request: Request,
  env: Environment,
  status: number,
  code: string,
  message: string,
  extraHeaders: Record<string, string> = {},
): Response {
  return jsonResponse(request, env, status, { error: { code, message } }, extraHeaders);
}

function isAllowedOrigin(request: Request, env: Environment): boolean {
  const origin = request.headers.get("origin");
  return origin === null || parseAllowedOrigins(env.get("ALLOWED_ORIGINS")).has(origin);
}

function isJsonContentType(value: string | null): boolean {
  if (value === null) return false;
  const mediaType = value.split(";", 1)[0]?.trim().toLowerCase();
  return mediaType === "application/json" && value.split(",").length === 1;
}

function validJwtHeader(value: string | null): string | null {
  if (value === null) return null;
  const match = /^Bearer ([A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)$/.exec(value);
  return match?.[1] ?? null;
}

export function validateSyncRequest(body: unknown): { project_id: string } {
  if (typeof body !== "object" || body === null || Array.isArray(body)) {
    throw new RequestValidationError("Request body must be an object");
  }
  const keys = Object.keys(body);
  if (keys.length !== 1 || keys[0] !== "project_id") {
    throw new RequestValidationError("Request body has invalid fields");
  }
  const projectId = (body as { project_id?: unknown }).project_id;
  if (!isUuid(projectId)) throw new RequestValidationError("project_id must be a UUID");
  return { project_id: projectId };
}

async function readRequestJson(request: Request): Promise<unknown> {
  const contentLength = request.headers.get("content-length");
  if (contentLength !== null && /^\d+$/.test(contentLength.trim())) {
    const size = Number(contentLength);
    if (!Number.isSafeInteger(size) || size > MAX_REQUEST_BODY_BYTES) {
      throw new RequestValidationError("Request body is too large");
    }
  }
  let body: ArrayBuffer;
  try {
    body = await request.arrayBuffer();
  } catch {
    throw new RequestValidationError("Request body is invalid");
  }
  if (body.byteLength > MAX_REQUEST_BODY_BYTES) {
    throw new RequestValidationError("Request body is too large");
  }
  let text: string;
  try {
    text = new TextDecoder("utf-8", { fatal: true }).decode(body);
  } catch {
    throw new RequestValidationError("Request body is invalid");
  }
  try {
    return JSON.parse(text) as unknown;
  } catch {
    throw new SyntaxError("Request JSON is invalid");
  }
}

function responseData(value: unknown): Record<string, unknown> | null {
  if (Array.isArray(value)) value = value[0];
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

function validBeginResult(value: unknown): {
  github_link_id: string;
  project_id: string;
  repo_full_name: string;
  last_synced_at: string | null;
  sync_lease_token: string;
  sync_lease_expires_at: string;
} | null {
  const result = responseData(value);
  if (result === null) return null;
  if (
    !isUuid(result.github_link_id) ||
    !isUuid(result.project_id) ||
    typeof result.repo_full_name !== "string" ||
    (result.last_synced_at !== null && typeof result.last_synced_at !== "string") ||
    !isUuid(result.sync_lease_token) ||
    typeof result.sync_lease_expires_at !== "string" ||
    !Number.isFinite(Date.parse(result.sync_lease_expires_at))
  ) return null;
  return {
    github_link_id: result.github_link_id,
    project_id: result.project_id,
    repo_full_name: result.repo_full_name,
    last_synced_at: result.last_synced_at,
    sync_lease_token: result.sync_lease_token,
    sync_lease_expires_at: result.sync_lease_expires_at,
  };
}

function isLeaseBusyError(error: unknown): boolean {
  return typeof error === "object" && error !== null &&
    (error as { code?: unknown }).code === "55006";
}

function isAuthorizationError(error: unknown): boolean {
  return typeof error === "object" && error !== null &&
    (error as { code?: unknown }).code === "42501";
}

async function abortLease(
  admin: SupabaseClientLike,
  ownerId: string,
  linkId: string,
  leaseToken: string,
): Promise<void> {
  try {
    await admin.rpc("abort_github_sync", {
      p_owner_id: ownerId,
      p_github_link_id: linkId,
      p_sync_lease_token: leaseToken,
    });
  } catch {
    // The original upstream/database error is safer and more useful to return.
  }
}

function validSyncResult(value: unknown): {
  commits_synced: number;
  issues_synced: number;
  last_synced_at: string;
} | null {
  const result = responseData(value);
  if (result === null) return null;
  const commits = result.commits_synced;
  const issues = result.issues_synced;
  const timestamp = result.last_synced_at;
  if (
    typeof commits !== "number" || !Number.isSafeInteger(commits) || commits < 0 || commits > 30 ||
    typeof issues !== "number" || !Number.isSafeInteger(issues) || issues < 0 || issues > 500 ||
    typeof timestamp !== "string" || !Number.isFinite(Date.parse(timestamp))
  ) return null;
  return { commits_synced: commits, issues_synced: issues, last_synced_at: timestamp };
}

export function createGithubSyncHandler(
  dependencies: HandlerDependencies = {},
): (request: Request) => Promise<Response> {
  const env = dependencies.env ?? runtimeEnvironment();
  const fetchImpl = dependencies.fetchImpl ?? fetch;
  const clientFactory = dependencies.createClient ?? defaultClientFactory;

  return async (request: Request): Promise<Response> => {
    if (!isAllowedOrigin(request, env)) {
      return errorResponse(request, env, 403, "origin_not_allowed", "Origin is not allowed");
    }
    if (request.method === "OPTIONS") {
      const headers = corsHeaders(request, env);
      headers.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      headers.set("Access-Control-Allow-Headers", "authorization, content-type");
      headers.set("Access-Control-Max-Age", "600");
      return new Response(null, { status: 204, headers });
    }
    if (request.method !== "POST") {
      return errorResponse(
        request,
        env,
        405,
        "method_not_allowed",
        "Only POST is supported",
        { Allow: "POST, OPTIONS" },
      );
    }
    if (!isJsonContentType(request.headers.get("content-type"))) {
      return errorResponse(request, env, 415, "unsupported_media_type", "Content-Type must be application/json");
    }
    const token = validJwtHeader(request.headers.get("authorization"));
    if (token === null) {
      return errorResponse(request, env, 401, "unauthorized", "A valid bearer token is required");
    }

    let syncRequest: { project_id: string };
    try {
      const body = await readRequestJson(request);
      syncRequest = validateSyncRequest(body);
    } catch (error) {
      if (error instanceof RequestValidationError && error.message === "Request body is too large") {
        return errorResponse(request, env, 413, "payload_too_large", "Request body is too large");
      }
      if (error instanceof SyntaxError) {
        return errorResponse(request, env, 400, "invalid_json", "Request JSON is invalid");
      }
      return errorResponse(request, env, 422, "invalid_request", "Request body is invalid");
    }

    let supabaseUrl: string;
    let publishableKey: string;
    try {
      supabaseUrl = getSupabaseUrl(env);
      publishableKey = getPublishableKey(env);
    } catch {
      return errorResponse(request, env, 500, "configuration_error", "Service is not configured");
    }

    let userId: string;
    try {
      const authClient = clientFactory(supabaseUrl, publishableKey, {
        auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
      });
      const authResult = await authClient.auth.getUser(token);
      const candidate = authResult.data?.user?.id;
      if (authResult.error !== undefined && authResult.error !== null) throw new Error("auth failed");
      if (!isUuid(candidate)) throw new Error("auth failed");
      userId = candidate;
    } catch {
      return errorResponse(request, env, 401, "unauthorized", "The bearer token is invalid or expired");
    }

    let admin: SupabaseClientLike;
    try {
      // This is deliberately created only after auth.getUser has verified the
      // caller's session. The caller JWT is never used as the admin key.
      admin = clientFactory(supabaseUrl, getSecretKey(env), {
        auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
      });
    } catch {
      return errorResponse(request, env, 500, "configuration_error", "Service is not configured");
    }

    let project: Record<string, unknown> | null;
    let link: Record<string, unknown> | null;
    try {
      const projectResult = await admin.from("projects")
        .select("id")
        .eq("id", syncRequest.project_id)
        .eq("owner_id", userId)
        .maybeSingle();
      if (projectResult.error !== undefined && projectResult.error !== null) throw new Error("project query failed");
      project = responseData(projectResult.data);

      const linkResult = await admin.from("github_links")
        .select("id, project_id, repo_full_name, last_synced_at")
        .eq("project_id", syncRequest.project_id)
        .maybeSingle();
      if (linkResult.error !== undefined && linkResult.error !== null) throw new Error("link query failed");
      link = responseData(linkResult.data);
    } catch {
      return errorResponse(request, env, 500, "database_error", "Unable to load project");
    }
    if (project === null || project.id !== syncRequest.project_id || link === null) {
      return errorResponse(request, env, 404, "not_found", "Project or GitHub link not found");
    }
    if (!isUuid(link.id) || !isUuid(link.project_id) || link.project_id !== syncRequest.project_id) {
      return errorResponse(request, env, 500, "database_error", "Unable to load project");
    }
    let lease: ReturnType<typeof validBeginResult>;
    try {
      const beginResult = await admin.rpc("begin_github_sync", {
        p_owner_id: userId,
        p_github_link_id: link.id,
      });
      if (beginResult.error !== undefined && beginResult.error !== null) throw beginResult.error;
      lease = validBeginResult(beginResult.data);
      if (lease === null) throw new Error("begin result invalid");
    } catch (error) {
      if (isLeaseBusyError(error)) {
        return errorResponse(
          request,
          env,
          429,
          "sync_cooldown",
          "This repository was synchronized recently or is already syncing",
          { "Retry-After": "120" },
        );
      }
      if (isAuthorizationError(error)) {
        return errorResponse(request, env, 404, "not_found", "Project or GitHub link not found");
      }
      return errorResponse(request, env, 500, "database_error", "Unable to begin GitHub synchronization");
    }
    if (lease === null) {
      return errorResponse(request, env, 500, "database_error", "Unable to begin GitHub synchronization");
    }
    if (lease.github_link_id !== link.id || lease.project_id !== syncRequest.project_id) {
      await abortLease(admin, userId, link.id, lease.sync_lease_token);
      return errorResponse(request, env, 500, "database_error", "Unable to begin GitHub synchronization");
    }
    const repository = parseRepoFullName(lease.repo_full_name);
    if (repository === null) {
      await abortLease(admin, userId, link.id, lease.sync_lease_token);
      return errorResponse(request, env, 500, "database_error", "Stored repository configuration is invalid");
    }

    let snapshots: Awaited<ReturnType<typeof fetchGithubSnapshots>>;
    try {
      const options: GithubFetchOptions = { fetchImpl };
      snapshots = await fetchGithubSnapshots(repository, options);
    } catch (error) {
      await abortLease(admin, userId, link.id, lease.sync_lease_token);
      const mapped = mapGithubError(error);
      return errorResponse(
        request,
        env,
        mapped.status,
        mapped.code,
        mapped.message,
        mapped.retryAfterSeconds === undefined ? {} : { "Retry-After": String(mapped.retryAfterSeconds) },
      );
    }

    let syncResult: ReturnType<typeof validSyncResult>;
    try {
      const rpcResult = await admin.rpc("apply_github_sync", {
        p_owner_id: userId,
        p_github_link_id: link.id,
        p_sync_lease_token: lease.sync_lease_token,
        p_commits: snapshots.commits,
        p_issues: snapshots.issues,
      });
      if (rpcResult.error !== undefined && rpcResult.error !== null) throw rpcResult.error;
      syncResult = validSyncResult(rpcResult.data);
      if (syncResult === null) throw new Error("sync result invalid");
    } catch {
      await abortLease(admin, userId, link.id, lease.sync_lease_token);
      return errorResponse(request, env, 500, "database_error", "Unable to save GitHub synchronization");
    }
    if (syncResult === null) {
      return errorResponse(request, env, 500, "database_error", "Unable to save GitHub synchronization");
    }

    return jsonResponse(request, env, 200, {
      data: {
        project_id: syncRequest.project_id,
        repo_full_name: repository.fullName,
        commits_synced: syncResult.commits_synced,
        issues_synced: syncResult.issues_synced,
        last_synced_at: syncResult.last_synced_at,
      },
    });
  };
}

export const handler = createGithubSyncHandler();

if (import.meta.main) {
  Deno.serve(handler);
}
