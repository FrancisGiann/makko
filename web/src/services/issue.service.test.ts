import type { PostgrestError, SupabaseClient } from '@supabase/supabase-js'
import { describe, expect, it, vi } from 'vitest'

import { createIssueService } from './issue.service'
import type { Database } from '../types/database'
import type { Issue, IssueInput } from '../types/domain'

class FakeQuery {
  constructor(private readonly response: unknown) {}
  select = vi.fn(() => this)
  eq = vi.fn(() => this)
  order = vi.fn(() => this)
  insert = vi.fn(() => this)
  update = vi.fn(() => this)
  delete = vi.fn(() => this)
  single = vi.fn(() => Promise.resolve(this.response))
  then<TResult1 = unknown, TResult2 = never>(onfulfilled?: ((value: unknown) => TResult1 | PromiseLike<TResult1>) | null, onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null): PromiseLike<TResult1 | TResult2> {
    return Promise.resolve(this.response).then(onfulfilled, onrejected)
  }
}

function createClient(query: FakeQuery) {
  return { from: vi.fn(() => query) } as unknown as SupabaseClient<Database>
}

const input: IssueInput = { title: 'Fix auth', description: '', type: 'bug', priority: 'high', status: 'todo' }
const issue: Issue = { id: 'issue-1', project_id: 'project-1', title: 'Fix auth', description: null, type: 'bug', priority: 'high', status: 'todo', created_at: '2026-01-01T00:00:00Z', updated_at: '2026-01-01T00:00:00Z' }

describe('issue service', () => {
  it('scopes issue reads and writes to the project', async () => {
    const query = new FakeQuery({ data: issue, error: null })
    const service = createIssueService(createClient(query))
    await service.createIssue('project-1', input)
    expect(query.insert).toHaveBeenCalledWith({ project_id: 'project-1', title: 'Fix auth', description: null, type: 'bug', priority: 'high', status: 'todo' })
  })

  it('keeps project_id out of update payloads and filters by issue id', async () => {
    const query = new FakeQuery({ data: issue, error: null })
    const service = createIssueService(createClient(query))
    await service.updateIssue('project-1', 'issue-1', input)
    expect(query.update).toHaveBeenCalledWith({ title: 'Fix auth', description: null, type: 'bug', priority: 'high', status: 'todo' })
    expect(query.eq).toHaveBeenNthCalledWith(1, 'id', 'issue-1')
    expect(query.eq).toHaveBeenNthCalledWith(2, 'project_id', 'project-1')
  })

  it('surfaces failed issue reads', async () => {
    const error = { message: 'RLS rejected the query' } as PostgrestError
    const query = new FakeQuery({ data: null, error })
    const service = createIssueService(createClient(query))
    await expect(service.listIssues('project-1')).rejects.toThrow('RLS rejected the query')
  })
})
