import type { PostgrestError, SupabaseClient } from '@supabase/supabase-js'
import { describe, expect, it, vi } from 'vitest'

import { createGithubService } from './github.service'
import type { Database } from '../types/database'

class FakeQuery {
  constructor(private readonly response: unknown) {}
  select = vi.fn(() => this)
  eq = vi.fn(() => this)
  order = vi.fn(() => this)
  limit = vi.fn(() => this)
  insert = vi.fn(() => this)
  delete = vi.fn(() => this)
  single = vi.fn(() => Promise.resolve(this.response))
  maybeSingle = vi.fn(() => Promise.resolve(this.response))
  then<TResult1 = unknown, TResult2 = never>(onfulfilled?: ((value: unknown) => TResult1 | PromiseLike<TResult1>) | null, onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null): PromiseLike<TResult1 | TResult2> {
    return Promise.resolve(this.response).then(onfulfilled, onrejected)
  }
}

function createClient(query: FakeQuery, invoke = vi.fn(), scopedQueries: Partial<Record<'github_links' | 'github_commits' | 'github_issues', FakeQuery>> = {}) {
  const queries: Record<string, FakeQuery> = { github_links: query, github_commits: query, github_issues: query, ...scopedQueries }
  return { from: vi.fn((table: string) => queries[table] ?? query), functions: { invoke } } as unknown as SupabaseClient<Database>
}

const link = { id: 'link-1', project_id: 'project-1', repo_full_name: 'makko/web', last_synced_at: null, sync_lease_token: null, sync_lease_expires_at: null, created_at: '2026-01-01T00:00:00Z' }

describe('github service', () => {
  it('validates the repository and inserts only the granted link fields', async () => {
    const query = new FakeQuery({ data: link, error: null })
    const service = createGithubService(createClient(query))

    await service.connect('project-1', '  makko/web  ')

    expect(query.insert).toHaveBeenCalledWith({ project_id: 'project-1', repo_full_name: 'makko/web' })
    await expect(service.connect('project-1', 'https://github.com/makko/web')).rejects.toThrow('owner/name')
    expect(query.insert).toHaveBeenCalledTimes(1)
  })

  it('queries commits and only open external issues', async () => {
    const linkQuery = new FakeQuery({ data: link, error: null })
    const commitQuery = new FakeQuery({ data: [], error: null })
    const issueQuery = new FakeQuery({ data: [], error: null })
    const service = createGithubService(createClient(linkQuery, vi.fn(), { github_commits: commitQuery, github_issues: issueQuery }))
    await service.getProjectData('project-1')

    expect(linkQuery.eq).toHaveBeenCalledWith('project_id', 'project-1')
    expect(commitQuery.eq).toHaveBeenCalledWith('github_link_id', 'link-1')
    expect(commitQuery.order).toHaveBeenCalledWith('committed_at', { ascending: false })
    expect(commitQuery.limit).toHaveBeenCalledWith(10)
    // A data refresh always uses the scoped link id, then filters external issues by state.
    expect(issueQuery.eq).toHaveBeenCalledWith('github_link_id', 'link-1')
    expect(issueQuery.eq).toHaveBeenCalledWith('state', 'open')
    expect(issueQuery.order).toHaveBeenCalledWith('github_updated_at', { ascending: false })
    expect(issueQuery.limit).toHaveBeenCalledWith(10)
  })

  it('invokes github-sync with the exact project body and maps cooldown errors', async () => {
    const invoke = vi.fn(async () => ({
      data: { data: { project_id: 'project-1', repo_full_name: 'makko/web', commits_synced: 2, issues_synced: 1, last_synced_at: '2026-01-01T00:00:00Z' } },
      error: null,
    }))
    const query = new FakeQuery({ data: link, error: null })
    const service = createGithubService(createClient(query, invoke))

    await expect(service.sync('project-1')).resolves.toMatchObject({ commits_synced: 2, issues_synced: 1 })
    expect(invoke).toHaveBeenCalledWith('github-sync', { body: { project_id: 'project-1' } })

    const cooldown = new Response(JSON.stringify({ error: { code: 'sync_cooldown', message: 'Try again shortly' } }), { status: 429, headers: { 'Retry-After': '60' } })
    const failedInvoke = vi.fn(async () => ({ data: null, error: { message: 'Edge Function returned a non-2xx status code', context: cooldown } }))
    await expect(createGithubService(createClient(query, failedInvoke)).sync('project-1')).rejects.toMatchObject({ code: 'sync_cooldown', status: 429, retryAfterSeconds: 60 })
  })

  it('surfaces cached commit and issue read failures', async () => {
    const linkQuery = new FakeQuery({ data: link, error: null })
    const commitQuery = new FakeQuery({ data: null, error: { message: 'commits unavailable' } as PostgrestError })
    const issueQuery = new FakeQuery({ data: [], error: null })
    const service = createGithubService(createClient(linkQuery, vi.fn(), { github_commits: commitQuery, github_issues: issueQuery }))

    await expect(service.getProjectData('project-1')).rejects.toThrow('commits unavailable')
  })

  it('scopes link deletion to the project and link without an update path', async () => {
    const query = new FakeQuery({ data: null, error: null })
    const service = createGithubService(createClient(query))

    await expect(service.disconnect('project-1', 'link-1')).resolves.toBeUndefined()

    expect(query.delete).toHaveBeenCalledOnce()
    expect(query.eq).toHaveBeenNthCalledWith(1, 'id', 'link-1')
    expect(query.eq).toHaveBeenNthCalledWith(2, 'project_id', 'project-1')
  })

  it('surfaces failed link reads', async () => {
    const query = new FakeQuery({ data: null, error: { message: 'RLS rejected' } as PostgrestError })
    await expect(createGithubService(createClient(query)).getProjectData('project-1')).rejects.toThrow('RLS rejected')
  })
})
