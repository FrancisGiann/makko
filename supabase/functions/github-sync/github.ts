export const GITHUB_API_VERSION = "2022-11-28";
export const GITHUB_USER_AGENT = "Makko-GitHub-Sync/1.0";
export const MAX_COMMITS = 30;
export const MAX_ISSUES = 500;
export const MAX_ISSUE_PAGES = 5;
export const DEFAULT_GITHUB_TIMEOUT_MS = 10_000;

const REPO_PATTERN = /^[A-Za-z0-9][A-Za-z0-9-]{0,38}\/[A-Za-z0-9._-]{1,100}$/;
const SHA_PATTERN = /^[0-9A-Fa-f]{40,64}$/;
const MAX_GITHUB_RESPONSE_BYTES = 8 * 1024 * 1024;

export interface GithubRepository {
  readonly owner: string;
  readonly name: string;
  readonly fullName: string;
}

export interface GithubCommitSnapshot {
  sha: string;
  message: string;
  author_name: string | null;
  author_login: string | null;
  committed_at: string;
  html_url: string;
}

export interface GithubIssueSnapshot {
  github_node_id: string;
  number: number;
  title: string;
  state: "open" | "closed";
  author_login: string | null;
  labels: string[];
  github_created_at: string;
  github_updated_at: string;
  html_url: string;
}

export interface GithubSnapshots {
  commits: GithubCommitSnapshot[];
  issues: GithubIssueSnapshot[];
}

export class GithubPayloadError extends Error {
  constructor(message = "GitHub returned an invalid response") {
    super(message);
    this.name = "GithubPayloadError";
  }
}

export class GithubPaginationError extends Error {
  constructor(message = "GitHub pagination exceeded the supported limit") {
    super(message);
    this.name = "GithubPaginationError";
  }
}

export class GithubHttpError extends Error {
  readonly status: number;
  readonly retryAfterSeconds: number | undefined;
  readonly rateLimited: boolean;

  constructor(
    status: number,
    retryAfterSeconds: number | undefined,
    rateLimited: boolean,
  ) {
    super("GitHub request failed");
    this.name = "GithubHttpError";
    this.status = status;
    this.retryAfterSeconds = retryAfterSeconds;
    this.rateLimited = rateLimited;
  }
}

export class GithubTimeoutError extends Error {
  constructor() {
    super("GitHub request timed out");
    this.name = "GithubTimeoutError";
  }
}

export class GithubNetworkError extends Error {
  constructor() {
    super("GitHub request could not be completed");
    this.name = "GithubNetworkError";
  }
}

export function parseRepoFullName(value: unknown): GithubRepository | null {
  if (typeof value !== "string" || !REPO_PATTERN.test(value)) return null;
  const separator = value.indexOf("/");
  if (separator <= 0 || separator !== value.lastIndexOf("/")) return null;
  return {
    owner: value.slice(0, separator),
    name: value.slice(separator + 1),
    fullName: value,
  };
}

export function isUuid(value: unknown): value is string {
  return typeof value === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}

export function buildGithubApiUrl(
  repository: GithubRepository,
  resource: "commits" | "issues",
): URL {
  const url = new URL(
    `https://api.github.com/repos/${encodeURIComponent(repository.owner)}/${encodeURIComponent(repository.name)}/${resource}`,
  );
  return url;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function requiredString(value: unknown, field: string, maxLength?: number): string {
  if (typeof value !== "string" || (maxLength !== undefined && value.length > maxLength)) {
    throw new GithubPayloadError(`GitHub response field ${field} is invalid`);
  }
  return value;
}

function optionalLogin(value: unknown, field: string): string | null {
  if (value === null || value === undefined) return null;
  return requiredString(value, field, 39);
}

function optionalString(value: unknown, field: string, maxLength: number): string | null {
  if (value === null || value === undefined) return null;
  return requiredString(value, field, maxLength);
}

function parseGithubTimestamp(value: unknown, field: string): string {
  const input = requiredString(value, field);
  const date = new Date(input);
  if (!Number.isFinite(date.getTime())) {
    throw new GithubPayloadError(`GitHub response field ${field} is invalid`);
  }
  return date.toISOString();
}

function validateGithubHtmlUrl(
  value: unknown,
  repository: GithubRepository,
  resource: "commit" | "issues",
): string {
  const raw = requiredString(value, "html_url");
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new GithubPayloadError("GitHub response URL is invalid");
  }
  const pathPrefix = `/${repository.owner}/${repository.name}/${resource === "commit" ? "commit" : "issues"}/`.toLowerCase();
  if (
    url.protocol !== "https:" ||
    url.hostname.toLowerCase() !== "github.com" ||
    url.port !== "" ||
    url.username !== "" ||
    url.password !== "" ||
    !url.pathname.toLowerCase().startsWith(pathPrefix) ||
    url.pathname.length <= pathPrefix.length
  ) {
    throw new GithubPayloadError("GitHub response URL is invalid");
  }
  return raw;
}

export function mapGithubCommit(
  value: unknown,
  repository: GithubRepository,
): GithubCommitSnapshot {
  if (!isRecord(value) || !isRecord(value.commit)) {
    throw new GithubPayloadError("GitHub commit shape is invalid");
  }
  const commit = value.commit;
  const commitAuthor = commit.author;
  if (commitAuthor !== null && commitAuthor !== undefined && !isRecord(commitAuthor)) {
    throw new GithubPayloadError("GitHub commit author shape is invalid");
  }
  const apiAuthor = value.author;
  if (apiAuthor !== null && apiAuthor !== undefined && !isRecord(apiAuthor)) {
    throw new GithubPayloadError("GitHub commit account shape is invalid");
  }
  const sha = requiredString(value.sha, "sha", 64);
  if (!SHA_PATTERN.test(sha)) {
    throw new GithubPayloadError("GitHub commit SHA is invalid");
  }
  return {
    sha,
    message: requiredString(commit.message, "message", 10_000),
    author_name: commitAuthor === null || commitAuthor === undefined
      ? null
      : optionalString(commitAuthor.name, "author.name", 255),
    author_login: apiAuthor === null || apiAuthor === undefined
      ? null
      : optionalLogin(apiAuthor.login, "author.login"),
    committed_at: parseGithubTimestamp(
      commitAuthor === null || commitAuthor === undefined ? undefined : commitAuthor.date,
      "commit.author.date",
    ),
    html_url: validateGithubHtmlUrl(value.html_url, repository, "commit"),
  };
}

export function mapGithubIssue(
  value: unknown,
  repository: GithubRepository,
): GithubIssueSnapshot | null {
  if (!isRecord(value)) {
    throw new GithubPayloadError("GitHub issue shape is invalid");
  }
  // GitHub's issues endpoint includes pull requests. The property itself is
  // the documented discriminator, even when its value is unexpectedly null.
  if (Object.prototype.hasOwnProperty.call(value, "pull_request")) return null;

  const user = value.user;
  if (user !== null && user !== undefined && !isRecord(user)) {
    throw new GithubPayloadError("GitHub issue author shape is invalid");
  }
  if (!Array.isArray(value.labels)) {
    throw new GithubPayloadError("GitHub issue labels shape is invalid");
  }
  const labels = value.labels.map((label) => {
    if (!isRecord(label)) throw new GithubPayloadError("GitHub issue label shape is invalid");
    return requiredString(label.name, "labels.name", 255);
  });
  const number = value.number;
  if (typeof number !== "number" || !Number.isSafeInteger(number) || number <= 0) {
    throw new GithubPayloadError("GitHub issue number is invalid");
  }
  const state = requiredString(value.state, "state");
  if (state !== "open" && state !== "closed") {
    throw new GithubPayloadError("GitHub issue state is invalid");
  }
  const nodeId = requiredString(value.node_id, "node_id", 255);
  const title = requiredString(value.title, "title", 500);
  if (nodeId.trim() === "" || title.trim() === "") {
    throw new GithubPayloadError("GitHub issue identity is invalid");
  }
  return {
    github_node_id: nodeId,
    number,
    title,
    state,
    author_login: user === null || user === undefined ? null : optionalLogin(user.login, "user.login"),
    labels,
    github_created_at: parseGithubTimestamp(value.created_at, "created_at"),
    github_updated_at: parseGithubTimestamp(value.updated_at, "updated_at"),
    html_url: validateGithubHtmlUrl(value.html_url, repository, "issues"),
  };
}

export function deduplicateSnapshots(snapshots: GithubSnapshots): GithubSnapshots {
  const commits = new Map<string, GithubCommitSnapshot>();
  for (const commit of snapshots.commits) {
    if (!commits.has(commit.sha)) commits.set(commit.sha, commit);
  }
  const issues = new Map<string, GithubIssueSnapshot>();
  for (const issue of snapshots.issues) {
    if (!issues.has(issue.github_node_id)) issues.set(issue.github_node_id, issue);
  }
  return { commits: [...commits.values()], issues: [...issues.values()] };
}

export function getRetryAfterSeconds(
  headers: Headers,
  nowMs = Date.now(),
): number | undefined {
  const retryAfter = headers.get("retry-after");
  if (retryAfter !== null) {
    const seconds = Number(retryAfter.trim());
    if (Number.isFinite(seconds) && seconds >= 0) return Math.max(1, Math.ceil(seconds));
    const date = Date.parse(retryAfter);
    if (Number.isFinite(date)) return Math.max(1, Math.ceil((date - nowMs) / 1000));
  }
  const reset = Number(headers.get("x-ratelimit-reset"));
  if (Number.isFinite(reset) && reset > 0) {
    return Math.max(1, Math.ceil(reset - nowMs / 1000));
  }
  return undefined;
}

function hasRateLimitHeaders(headers: Headers): boolean {
  return headers.get("x-ratelimit-remaining") === "0" ||
    headers.has("retry-after");
}

async function readGithubJson(response: Response): Promise<unknown> {
  const contentLength = Number(response.headers.get("content-length"));
  if (Number.isFinite(contentLength) && contentLength > MAX_GITHUB_RESPONSE_BYTES) {
    throw new GithubPayloadError("GitHub response is too large");
  }
  let body: string;
  try {
    body = await response.text();
  } catch {
    throw new GithubPayloadError();
  }
  if (new TextEncoder().encode(body).byteLength > MAX_GITHUB_RESPONSE_BYTES) {
    throw new GithubPayloadError("GitHub response is too large");
  }
  try {
    return JSON.parse(body) as unknown;
  } catch {
    throw new GithubPayloadError();
  }
}

async function requestGithub(
  url: URL,
  fetchImpl: typeof fetch,
  timeoutMs: number,
): Promise<{ payload: unknown; headers: Headers }> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  let response: Response;
  try {
    response = await fetchImpl(url, {
      method: "GET",
      headers: {
        Accept: "application/vnd.github+json",
        "X-GitHub-Api-Version": GITHUB_API_VERSION,
        "User-Agent": GITHUB_USER_AGENT,
      },
      redirect: "error",
      signal: controller.signal,
    });
  } catch (error) {
    if (controller.signal.aborted || (error instanceof DOMException && error.name === "AbortError")) {
      throw new GithubTimeoutError();
    }
    throw new GithubNetworkError();
  } finally {
    clearTimeout(timeout);
  }
  if (!response.ok) {
    const rateLimited = response.status === 429 ||
      (response.status === 403 && hasRateLimitHeaders(response.headers));
    throw new GithubHttpError(
      response.status,
      rateLimited ? getRetryAfterSeconds(response.headers) : undefined,
      rateLimited,
    );
  }
  return { payload: await readGithubJson(response), headers: response.headers };
}

export function parseNextGithubLink(
  linkHeader: string | null,
  repository?: GithubRepository,
): URL | null {
  if (linkHeader === null) return null;
  const match = /<([^>]+)>\s*;\s*rel\s*=\s*(?:"next"|next)(?:\s*[,;]|$)/i.exec(linkHeader);
  if (!match) return null;
  let url: URL;
  try {
    url = new URL(match[1]);
  } catch {
    throw new GithubPaginationError("GitHub next link is invalid");
  }
  if (
    url.protocol !== "https:" ||
    url.hostname.toLowerCase() !== "api.github.com" ||
    url.port !== "" ||
    url.username !== "" ||
    url.password !== ""
  ) {
    throw new GithubPaginationError("GitHub next link host is invalid");
  }
  if (repository !== undefined) {
    const expected = `/repos/${repository.owner}/${repository.name}/issues`;
    if (url.pathname.toLowerCase() !== expected.toLowerCase()) {
      throw new GithubPaginationError("GitHub next link resource is invalid");
    }
  }
  return url;
}

export interface GithubFetchOptions {
  fetchImpl?: typeof fetch;
  timeoutMs?: number;
}

export async function fetchGithubSnapshots(
  repository: GithubRepository,
  options: GithubFetchOptions = {},
): Promise<GithubSnapshots> {
  const fetchImpl = options.fetchImpl ?? fetch;
  const timeoutMs = options.timeoutMs ?? DEFAULT_GITHUB_TIMEOUT_MS;

  const commitsUrl = buildGithubApiUrl(repository, "commits");
  commitsUrl.searchParams.set("per_page", String(MAX_COMMITS));
  let commits: GithubCommitSnapshot[];
  try {
    const commitsResponse = await requestGithub(commitsUrl, fetchImpl, timeoutMs);
    if (!Array.isArray(commitsResponse.payload) || commitsResponse.payload.length > MAX_COMMITS) {
      throw new GithubPayloadError("GitHub commits response shape is invalid");
    }
    commits = commitsResponse.payload.map((entry) => mapGithubCommit(entry, repository));
  } catch (error) {
    // GitHub returns 409 for an empty repository whose initial branch has not
    // been created yet. It is a valid empty commit snapshot; issues can still
    // be fetched and synchronized normally.
    if (error instanceof GithubHttpError && error.status === 409) {
      commits = [];
    } else {
      throw error;
    }
  }

  const issues: GithubIssueSnapshot[] = [];
  let issuesUrl: URL | null = buildGithubApiUrl(repository, "issues");
  issuesUrl.searchParams.set("state", "open");
  issuesUrl.searchParams.set("per_page", "100");
  let page = 0;
  while (issuesUrl !== null) {
    page += 1;
    if (page > MAX_ISSUE_PAGES) throw new GithubPaginationError();
    const issueResponse = await requestGithub(issuesUrl, fetchImpl, timeoutMs);
    if (!Array.isArray(issueResponse.payload) || issueResponse.payload.length > 100) {
      throw new GithubPayloadError("GitHub issues response shape is invalid");
    }
    for (const entry of issueResponse.payload) {
      const issue = mapGithubIssue(entry, repository);
      if (issue !== null) issues.push(issue);
    }
    if (issues.length > MAX_ISSUES) throw new GithubPaginationError();
    const next = parseNextGithubLink(issueResponse.headers.get("link"), repository);
    if (next !== null && page === MAX_ISSUE_PAGES) throw new GithubPaginationError();
    issuesUrl = next;
  }

  return deduplicateSnapshots({ commits, issues });
}

export interface GithubErrorResponse {
  status: 404 | 429 | 502 | 504;
  code: string;
  message: string;
  retryAfterSeconds?: number;
}

export function mapGithubError(error: unknown): GithubErrorResponse {
  if (error instanceof GithubHttpError) {
    if (error.status === 404) {
      return { status: 404, code: "github_not_found", message: "GitHub repository not found" };
    }
    if (error.rateLimited || error.status === 429) {
      return {
        status: 429,
        code: "github_rate_limited",
        message: "GitHub rate limit reached",
        ...(error.retryAfterSeconds === undefined ? {} : { retryAfterSeconds: error.retryAfterSeconds }),
      };
    }
    return { status: 502, code: "github_unavailable", message: "GitHub request failed" };
  }
  if (error instanceof GithubTimeoutError) {
    return { status: 504, code: "github_timeout", message: "GitHub request timed out" };
  }
  if (error instanceof GithubNetworkError) {
    return { status: 502, code: "github_unavailable", message: "GitHub is unavailable" };
  }
  if (error instanceof GithubPayloadError || error instanceof GithubPaginationError) {
    return { status: 502, code: "github_invalid_response", message: "GitHub returned an invalid response" };
  }
  return { status: 502, code: "github_unavailable", message: "GitHub request failed" };
}
