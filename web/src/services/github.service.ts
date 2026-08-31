import type { PostgrestError, SupabaseClient } from '@supabase/supabase-js'

import { getSupabaseClient } from '../lib/supabase'
import type { Database } from '../types/database'
import type { GithubCommit, GithubIssue, GithubLink, GithubSyncResult } from '../types/domain'
import { normalizeGithubRepository, requireId } from './validation'

const LINK_COLUMNS = 'id,project_id,repo_full_name,last_synced_at,created_at'
const COMMIT_COLUMNS = 'id,github_link_id,sha,message,author_name,author_login,committed_at,html_url,synced_at'
const ISSUE_COLUMNS = 'id,github_link_id,github_node_id,number,title,state,author_login,labels,github_created_at,github_updated_at,html_url,synced_at'

export interface GithubProjectData {
  link: GithubLink | null
  commits: GithubCommit[]
  issues: GithubIssue[]
}

export class GithubSyncError extends Error {
  readonly code: string | null
  readonly status: number | null
  readonly retryAfterSeconds: number | null

  constructor(message: string, options: { code?: string | null; status?: number | null; retryAfterSeconds?: number | null } = {}) {
    super(message)
    this.name = 'GithubSyncError'
    this.code = options.code ?? null
    this.status = options.status ?? null
    this.retryAfterSeconds = options.retryAfterSeconds ?? null
  }
}

export interface GithubService {
  getProjectData: (projectId: string) => Promise<GithubProjectData>
  connect: (projectId: string, repository: string) => Promise<GithubLink>
  disconnect: (projectId: string, linkId: string) => Promise<void>
  sync: (projectId: string) => Promise<GithubSyncResult>
}

function toError(error: PostgrestError | null, fallback: string): Error {
  return new Error(error?.message || fallback)
}

type GithubLinkProjection = Pick<GithubLink, 'id' | 'project_id' | 'repo_full_name' | 'last_synced_at' | 'created_at'>

function toGithubLink(value: GithubLinkProjection | null): GithubLink | null {
  if (!value) return null
  // Lease capabilities are server-only; the domain type still documents the
  // Phase 2 columns without selecting their values into the browser.
  return { ...value, sync_lease_token: null, sync_lease_expires_at: null }
}

function readRetryAfter(headers: Headers | null | undefined): number | null {
  const value = headers?.get('retry-after')
  if (!value) return null
  const seconds = Number.parseInt(value, 10)
  return Number.isFinite(seconds) && seconds > 0 ? seconds : null
}

async function responseError(error: unknown): Promise<GithubSyncError> {
  const candidate = error as { message?: unknown; context?: unknown; status?: unknown }
  const response = candidate.context instanceof Response ? candidate.context : null
  let payload: unknown = null
  if (response) {
    try { payload = await response.clone().json() } catch { payload = null }
  }
  const payloadError = typeof payload === 'object' && payload !== null && 'error' in payload
    ? (payload as { error?: unknown }).error
    : null
  const details = typeof payloadError === 'object' && payloadError !== null ? payloadError as { code?: unknown; message?: unknown } : {}
  const message = typeof details.message === 'string' && details.message
    ? details.message
    : typeof candidate.message === 'string' && candidate.message
      ? candidate.message
      : 'Unable to synchronize this GitHub repository.'
  const status = typeof candidate.status === 'number'
    ? candidate.status
    : response?.status ?? null
  return new GithubSyncError(message, {
    code: typeof details.code === 'string' ? details.code : null,
    status,
    retryAfterSeconds: readRetryAfter(response?.headers) ?? (details.code === 'sync_cooldown' ? 60 : null),
  })
}

function validSyncResult(value: unknown): GithubSyncResult | null {
  if (typeof value !== 'object' || value === null || !('data' in value)) return null
  const data = (value as { data?: unknown }).data
  if (typeof data !== 'object' || data === null) return null
  const result = data as Record<string, unknown>
  if (
    typeof result.project_id !== 'string' ||
    typeof result.repo_full_name !== 'string' ||
    typeof result.commits_synced !== 'number' ||
    typeof result.issues_synced !== 'number' ||
    typeof result.last_synced_at !== 'string'
  ) return null
  return {
    project_id: result.project_id,
    repo_full_name: result.repo_full_name,
    commits_synced: result.commits_synced,
    issues_synced: result.issues_synced,
    last_synced_at: result.last_synced_at,
  }
}

export function createGithubService(client: SupabaseClient<Database>): GithubService {
  const getLink = async (projectId: string): Promise<GithubLink | null> => {
    const project = requireId(projectId, 'Project')
    const { data, error } = await client.from('github_links')
      .select(LINK_COLUMNS)
      .eq('project_id', project)
      .maybeSingle()
    if (error) throw toError(error, 'Unable to load the GitHub connection.')
    return toGithubLink(data)
  }

  const listCommits = async (linkId: string): Promise<GithubCommit[]> => {
    const link = requireId(linkId, 'GitHub link')
    const { data, error } = await client.from('github_commits')
      .select(COMMIT_COLUMNS)
      .eq('github_link_id', link)
      .order('committed_at', { ascending: false })
      .limit(10)
    if (error) throw toError(error, 'Unable to load GitHub commits.')
    return data ?? []
  }

  const listIssues = async (linkId: string): Promise<GithubIssue[]> => {
    const link = requireId(linkId, 'GitHub link')
    const { data, error } = await client.from('github_issues')
      .select(ISSUE_COLUMNS)
      .eq('github_link_id', link)
      // GitHub issues are displayed as external, read-only open issues only.
      .eq('state', 'open')
      .order('github_updated_at', { ascending: false })
      .limit(10)
    if (error) throw toError(error, 'Unable to load GitHub issues.')
    return data ?? []
  }

  return {
    async getProjectData(projectId) {
      const link = await getLink(projectId)
      if (!link) return { link: null, commits: [], issues: [] }
      const [commits, issues] = await Promise.all([listCommits(link.id), listIssues(link.id)])
      return { link, commits, issues }
    },

    async connect(projectId, repository) {
      const project = requireId(projectId, 'Project')
      const repo = normalizeGithubRepository(repository)
      const { data, error } = await client.from('github_links')
        .insert({ project_id: project, repo_full_name: repo })
        .select(LINK_COLUMNS)
        .single()
      if (error) throw toError(error, 'Unable to connect this GitHub repository.')
      if (!data) throw new Error('GitHub connection did not return a link.')
      return toGithubLink(data) as GithubLink
    },

    async disconnect(projectId, linkId) {
      const project = requireId(projectId, 'Project')
      const link = requireId(linkId, 'GitHub link')
      const { error } = await client.from('github_links')
        .delete()
        .eq('id', link)
        .eq('project_id', project)
      if (error) throw toError(error, 'Unable to disconnect this GitHub repository.')
    },

    async sync(projectId) {
      const project = requireId(projectId, 'Project')
      const { data, error } = await client.functions.invoke('github-sync', {
        body: { project_id: project },
      })
      if (error) throw await responseError(error)
      const result = validSyncResult(data)
      if (!result) throw new GithubSyncError('GitHub synchronization returned an invalid response.', { code: 'invalid_response' })
      return result
    },
  }
}

export function getGithubService(): GithubService {
  return createGithubService(getSupabaseClient())
}
