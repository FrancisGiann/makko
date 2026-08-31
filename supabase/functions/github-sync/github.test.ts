import {
  fetchGithubSnapshots,
  GithubHttpError,
  GithubPaginationError,
  GithubPayloadError,
  mapGithubCommit,
  mapGithubError,
  mapGithubIssue,
  deduplicateSnapshots,
  parseNextGithubLink,
  parseRepoFullName,
} from "./github.ts";
import { createGithubSyncHandler, validateSyncRequest } from "./index.ts";

const REPOSITORY = parseRepoFullName("makko/phase-two");
if (REPOSITORY === null) throw new Error("test repository is invalid");

const commitPayload = (sha = "a".repeat(40), message = "Initial commit") => ({
  sha,
  commit: {
    message,
    author: { name: "Makko", date: "2026-01-01T00:00:00Z" },
  },
  author: { login: "makko" },
  html_url: `https://github.com/makko/phase-two/commit/${sha}`,
});

const issuePayload = (nodeId = "node-1", number = 1) => ({
  node_id: nodeId,
  number,
  title: "An issue",
  state: "open",
  user: { login: "makko" },
  labels: [{ name: "bug" }, { name: "triage" }],
  created_at: "2026-01-01T00:00:00Z",
  updated_at: "2026-01-02T00:00:00Z",
  html_url: `https://github.com/makko/phase-two/issues/${number}`,
});

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

function assertEquals<T>(actual: T, expected: T, message: string): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`${message}: ${JSON.stringify(actual)} !== ${JSON.stringify(expected)}`);
  }
}

function assertThrows(callback: () => unknown, ErrorType: new (...args: never[]) => Error): void {
  try {
    callback();
  } catch (error) {
    assert(error instanceof ErrorType, `expected ${ErrorType.name}`);
    return;
  }
  throw new Error(`expected ${ErrorType.name}`);
}

Deno.test("validates repository confinement and request UUID shape", () => {
  assert(parseRepoFullName("makko/phase-two") !== null, "valid repository should parse");
  assert(parseRepoFullName("https://evil.example/makko/phase-two") === null, "URL must not parse as repository");
  assert(parseRepoFullName("makko/phase-two/extra") === null, "nested repository must not parse");
  assertEquals(validateSyncRequest({ project_id: "10000000-0000-0000-0000-000000000001" }), {
    project_id: "10000000-0000-0000-0000-000000000001",
  }, "valid request");
  assertThrows(() => validateSyncRequest({ project_id: "not-a-uuid" }), Error);
  assertThrows(() => validateSyncRequest({ project_id: "10000000-0000-0000-0000-000000000001", extra: true }), Error);
});

Deno.test("maps commits, issues, labels, and excludes pull requests", () => {
  const commit = mapGithubCommit(commitPayload(), REPOSITORY);
  assertEquals(commit.author_name, "Makko", "commit author name");
  assertEquals(commit.author_login, "makko", "commit author login");
  assertEquals(commit.committed_at, "2026-01-01T00:00:00.000Z", "commit timestamp");
  const issue = mapGithubIssue(issuePayload(), REPOSITORY);
  assert(issue !== null, "issue should map");
  assertEquals(issue.labels, ["bug", "triage"], "issue labels");
  assertEquals(mapGithubIssue({ ...issuePayload(), pull_request: null }, REPOSITORY), null, "PR is excluded");
  assertThrows(() => mapGithubCommit({ ...commitPayload(), html_url: "https://evil.example/commit/x" }, REPOSITORY), GithubPayloadError);
  assertThrows(() => mapGithubIssue({ ...issuePayload(), labels: [{ name: 123 }] }, REPOSITORY), GithubPayloadError);
});

Deno.test("keeps the first occurrence when deduplicating mapped snapshots", () => {
  const firstCommit = mapGithubCommit(commitPayload("a".repeat(40), "first"), REPOSITORY);
  const secondCommit = mapGithubCommit(commitPayload("a".repeat(40), "second"), REPOSITORY);
  const firstIssue = mapGithubIssue(issuePayload("same-node", 1), REPOSITORY);
  const secondIssue = mapGithubIssue({ ...issuePayload("same-node", 1), title: "second" }, REPOSITORY);
  assert(firstIssue !== null && secondIssue !== null, "issue fixtures should map");
  const result = deduplicateSnapshots({
    commits: [firstCommit, secondCommit],
    issues: [firstIssue, secondIssue],
  });
  assertEquals(result.commits[0].message, "first", "first commit wins");
  assertEquals(result.issues[0].title, "An issue", "first issue wins");
});

Deno.test("treats an empty repository commit 409 as an empty snapshot", async () => {
  let issueFetched = false;
  const fetchImpl: typeof fetch = async (input) => {
    const url = new URL(String(input));
    if (url.pathname.endsWith("/commits")) return new Response("", { status: 409 });
    issueFetched = true;
    return new Response(JSON.stringify([issuePayload()]), { status: 200 });
  };
  const result = await fetchGithubSnapshots(REPOSITORY, { fetchImpl });
  assertEquals(result.commits, [], "empty repository has no commits");
  assert(issueFetched, "issues are fetched after an empty commit response");
  assertEquals(result.issues.length, 1, "issues still synchronize");
});

Deno.test("validates next links and caps issue pagination", async () => {
  const next = parseNextGithubLink(
    '<https://api.github.com/repos/makko/phase-two/issues?page=2>; rel="next"',
    REPOSITORY,
  );
  assert(next !== null && next.hostname === "api.github.com", "valid next link should parse");
  assertThrows(() => parseNextGithubLink('<https://evil.example/issues?page=2>; rel="next"', REPOSITORY), GithubPaginationError);

  let requests = 0;
  const fetchImpl: typeof fetch = async (input) => {
    requests += 1;
    const url = new URL(String(input));
    if (url.pathname.endsWith("/commits")) {
      return new Response(JSON.stringify([commitPayload()]), { status: 200 });
    }
    const page = Number(url.searchParams.get("page") ?? "1");
    const headers = page < 5
      ? { link: `<https://api.github.com/repos/makko/phase-two/issues?page=${page + 1}>; rel="next"` }
      : { link: '<https://api.github.com/repos/makko/phase-two/issues?page=6>; rel="next"' };
    return new Response(JSON.stringify([issuePayload(`node-${page}`, page)]), { status: 200, headers });
  };
  try {
    await fetchGithubSnapshots(REPOSITORY, { fetchImpl });
    throw new Error("pagination should have failed");
  } catch (error) {
    assert(error instanceof GithubPaginationError, "pagination cap error expected");
  }
  assertEquals(requests, 6, "five issue pages and one commit request");
});

Deno.test("maps GitHub errors without exposing upstream details", () => {
  const rateLimited = mapGithubError(new GithubHttpError(429, 12, true));
  assertEquals(rateLimited.status, 429, "rate limit status");
  assertEquals(rateLimited.retryAfterSeconds, 12, "rate limit retry delay");
  const notFound = mapGithubError(new GithubHttpError(404, undefined, false));
  assertEquals(notFound.code, "github_not_found", "not found maps without upstream body");
});

interface MockEnvironment {
  get(name: string): string | undefined;
}

function environment(): MockEnvironment {
  const values: Record<string, string> = {
    SUPABASE_URL: "https://makko.supabase.co",
    SUPABASE_PUBLISHABLE_KEYS: JSON.stringify({ default: "sb_publishable_test" }),
    SUPABASE_SECRET_KEYS: JSON.stringify({ default: "sb_secret_test" }),
    ALLOWED_ORIGINS: "http://localhost:5173",
  };
  return { get: (name) => values[name] };
}

Deno.test("handler enforces method, CORS, content type, and auth seams", async () => {
  const handler = createGithubSyncHandler({ env: environment(), createClient: () => {
    throw new Error("client should not be created for these failures");
  } });
  const methodResponse = await handler(new Request("https://function.example", { method: "GET" }));
  assertEquals(methodResponse.status, 405, "method status");
  assertEquals(methodResponse.headers.get("allow"), "POST, OPTIONS", "method allow header");
  const originResponse = await handler(new Request("https://function.example", {
    method: "OPTIONS",
    headers: { Origin: "https://evil.example" },
  }));
  assertEquals(originResponse.status, 403, "origin status");
  const typeResponse = await handler(new Request("https://function.example", {
    method: "POST",
    headers: { "Content-Type": "text/plain" },
    body: "{}",
  }));
  assertEquals(typeResponse.status, 415, "content type status");
  const authResponse = await handler(new Request("https://function.example", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ project_id: "10000000-0000-0000-0000-000000000001" }),
  }));
  assertEquals(authResponse.status, 401, "auth status");
});

Deno.test("handler verifies the caller before using the admin client", async () => {
  const calls: string[] = [];
  const userId = "00000000-0000-0000-0000-000000000001";
  const mockAuth = {
    auth: { getUser: async (token: string) => {
      calls.push(`auth:${token}`);
      return { data: { user: { id: userId } }, error: null };
    } },
    from: () => { throw new Error("not used"); },
    rpc: async () => ({ data: null, error: null }),
  };
  let clientNumber = 0;
  const handler = createGithubSyncHandler({
    env: environment(),
    createClient: () => {
      clientNumber += 1;
      calls.push(`client:${clientNumber}`);
      return mockAuth;
    },
  });
  const response = await handler(new Request("https://function.example", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: "Bearer a.b.c",
    },
    body: JSON.stringify({ project_id: "10000000-0000-0000-0000-000000000001" }),
  }));
  assertEquals(response.status, 500, "mock database failure is generic");
  assertEquals(calls.slice(0, 2), ["client:1", "auth:a.b.c"], "auth is called before second client");
});

Deno.test("handler fetches both snapshots before the atomic RPC and returns its result", async () => {
  const userId = "00000000-0000-0000-0000-000000000001";
  const projectId = "10000000-0000-0000-0000-000000000001";
  const linkId = "30000000-0000-0000-0000-000000000001";
  const calls: string[] = [];
  const query = (data: unknown) => ({
    select: () => query(data),
    eq: () => query(data),
    maybeSingle: async () => ({ data, error: null }),
  });
  const authClient = {
    auth: { getUser: async () => ({ data: { user: { id: userId } }, error: null }) },
    from: () => query(null),
    rpc: async () => ({ data: null, error: null }),
  };
  const adminClient = {
    auth: { getUser: async () => ({ data: null, error: new Error("unused") }) },
    from: (table: string) => table === "projects"
      ? query({ id: projectId })
      : query({ id: linkId, project_id: projectId, repo_full_name: "makko/phase-two", last_synced_at: null }),
    rpc: async (name: string, args: Record<string, unknown>) => {
      calls.push(`${name}:${Array.isArray(args.p_commits) && Array.isArray(args.p_issues)}`);
      if (name === "begin_github_sync") {
        return {
          data: {
            github_link_id: linkId,
            project_id: projectId,
            repo_full_name: "makko/phase-two",
            last_synced_at: null,
            sync_lease_token: "40000000-0000-0000-0000-000000000001",
            sync_lease_expires_at: "2026-01-03T00:02:00.000Z",
          },
          error: null,
        };
      }
      return {
        data: { commits_synced: 1, issues_synced: 1, last_synced_at: "2026-01-03T00:00:00.000Z" },
        error: null,
      };
    },
  };
  let clients = 0;
  const sha = "a".repeat(40);
  const fetchImpl: typeof fetch = async (input) => {
    const url = new URL(String(input));
    if (url.pathname.endsWith("/commits")) {
      return new Response(JSON.stringify([commitPayload(sha)]), { status: 200 });
    }
    return new Response(JSON.stringify([issuePayload()]), { status: 200 });
  };
  const handler = createGithubSyncHandler({
    env: environment(),
    fetchImpl,
    createClient: () => ++clients === 1 ? authClient : adminClient,
  });
  const response = await handler(new Request("https://function.example", {
    method: "POST",
    headers: {
      Origin: "http://localhost:5173",
      "Content-Type": "application/json",
      Authorization: "Bearer a.b.c",
    },
    body: JSON.stringify({ project_id: projectId }),
  }));
  assertEquals(response.status, 200, "success status");
  assertEquals(response.headers.get("access-control-allow-origin"), "http://localhost:5173", "CORS origin");
  assertEquals(calls, ["begin_github_sync:false", "apply_github_sync:true"], "RPC receives complete snapshots");
  const body = await response.json();
  assertEquals(body.data.repo_full_name, "makko/phase-two", "success repository");
});

function syncRequest(projectId: string): Request {
  return new Request("https://function.example", {
    method: "POST",
    headers: {
      Origin: "http://localhost:5173",
      "Content-Type": "application/json",
      Authorization: "Bearer a.b.c",
    },
    body: JSON.stringify({ project_id: projectId }),
  });
}

Deno.test("persisted lease allows only one concurrent invocation to reach GitHub", async () => {
  const userId = "00000000-0000-0000-0000-000000000001";
  const projectId = "10000000-0000-0000-0000-000000000001";
  const linkId = "30000000-0000-0000-0000-000000000001";
  const leaseToken = "40000000-0000-0000-0000-000000000001";
  let leaseActive = false;
  let fetchCalls = 0;
  let signalFetchStarted: (() => void) | undefined;
  const fetchStarted = new Promise<void>((resolve) => signalFetchStarted = resolve);
  let releaseFetch: (() => void) | undefined;
  const fetchRelease = new Promise<void>((resolve) => releaseFetch = resolve);
  const query = (data: unknown) => ({
    select: () => query(data),
    eq: () => query(data),
    maybeSingle: async () => ({ data, error: null }),
  });
  const client = {
    auth: { getUser: async () => ({ data: { user: { id: userId } }, error: null }) },
    from: (table: string) => table === "projects"
      ? query({ id: projectId })
      : query({ id: linkId, project_id: projectId, repo_full_name: "makko/phase-two", last_synced_at: null }),
    rpc: async (name: string) => {
      if (name === "begin_github_sync") {
        if (leaseActive) return { data: null, error: { code: "55006" } };
        leaseActive = true;
        return {
          data: {
            github_link_id: linkId,
            project_id: projectId,
            repo_full_name: "makko/phase-two",
            last_synced_at: null,
            sync_lease_token: leaseToken,
            sync_lease_expires_at: "2026-01-03T00:02:00.000Z",
          },
          error: null,
        };
      }
      if (name === "apply_github_sync") {
        leaseActive = false;
        return { data: { commits_synced: 1, issues_synced: 1, last_synced_at: "2026-01-03T00:00:00.000Z" }, error: null };
      }
      leaseActive = false;
      return { data: true, error: null };
    },
  };
  const fetchImpl: typeof fetch = async (input) => {
    fetchCalls += 1;
    const url = new URL(String(input));
    if (url.pathname.endsWith("/commits")) {
      signalFetchStarted?.();
      await fetchRelease;
      return new Response(JSON.stringify([commitPayload()]), { status: 200 });
    }
    return new Response(JSON.stringify([issuePayload()]), { status: 200 });
  };
  const handler = createGithubSyncHandler({ env: environment(), fetchImpl, createClient: () => client });
  const firstPromise = handler(syncRequest(projectId));
  await fetchStarted;
  const secondResponse = await handler(syncRequest(projectId));
  assertEquals(secondResponse.status, 429, "active lease blocks the second invocation");
  releaseFetch?.();
  const firstResponse = await firstPromise;
  assertEquals(firstResponse.status, 200, "first invocation completes");
  assertEquals(fetchCalls, 2, "only first invocation reaches both GitHub requests");
});

Deno.test("handler aborts a lease when GitHub fetching fails", async () => {
  const userId = "00000000-0000-0000-0000-000000000001";
  const projectId = "10000000-0000-0000-0000-000000000001";
  const linkId = "30000000-0000-0000-0000-000000000001";
  const leaseToken = "40000000-0000-0000-0000-000000000001";
  let leaseActive = false;
  let aborts = 0;
  const query = (data: unknown) => ({
    select: () => query(data),
    eq: () => query(data),
    maybeSingle: async () => ({ data, error: null }),
  });
  const client = {
    auth: { getUser: async () => ({ data: { user: { id: userId } }, error: null }) },
    from: (table: string) => table === "projects"
      ? query({ id: projectId })
      : query({ id: linkId, project_id: projectId, repo_full_name: "makko/phase-two", last_synced_at: null }),
    rpc: async (name: string) => {
      if (name === "begin_github_sync") {
        leaseActive = true;
        return {
          data: {
            github_link_id: linkId,
            project_id: projectId,
            repo_full_name: "makko/phase-two",
            last_synced_at: null,
            sync_lease_token: leaseToken,
            sync_lease_expires_at: "2026-01-03T00:02:00.000Z",
          },
          error: null,
        };
      }
      if (name === "abort_github_sync") {
        aborts += 1;
        leaseActive = false;
        return { data: true, error: null };
      }
      return { data: null, error: null };
    },
  };
  const handler = createGithubSyncHandler({
    env: environment(),
    fetchImpl: async () => { throw new TypeError("network failure"); },
    createClient: () => client,
  });
  const response = await handler(syncRequest(projectId));
  assertEquals(response.status, 502, "GitHub failure is mapped to bad gateway");
  assertEquals(aborts, 1, "failed fetch aborts the persisted lease");
  assert(!leaseActive, "failed fetch does not leave the lease active");
});
