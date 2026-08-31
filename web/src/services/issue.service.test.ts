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
  it('scopes issue lists to a project and returns an empty result', async () => {
    const query = new FakeQuery({ data: [], error: null })
    const service = createIssueService(createClient(query))

    await expect(service.listIssues('project-1')).resolves.toEqual([])

    expect(query.eq).toHaveBeenCalledWith('project_id', 'project-1')
    expect(query.order).toHaveBeenCalledWith('created_at', { ascending: false })
  })

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

  it('normalizes issue updates and surfaces failed mutations', async () => {
    const query = new FakeQuery({ data: issue, error: null })
    const service = createIssueService(createClient(query))
    await service.updateIssue('project-1', 'issue-1', { title: '  Fixed  ', description: '  Details  ', type: 'bug', priority: 'high', status: 'done' })
    expect(query.update).toHaveBeenCalledWith({ title: 'Fixed', description: 'Details', type: 'bug', priority: 'high', status: 'done' })

    const errorQuery = new FakeQuery({ data: null, error: { message: 'update denied' } as PostgrestError })
    await expect(createIssueService(createClient(errorQuery)).updateIssue('project-1', 'issue-1', input)).rejects.toThrow('update denied')
  })

  it('scopes successful issue deletes and rejects invalid input before querying', async () => {
    const query = new FakeQuery({ data: { id: 'issue-1' }, error: null })
    const service = createIssueService(createClient(query))
    await expect(service.deleteIssue('project-1', 'issue-1')).resolves.toBeUndefined()
    expect(query.eq).toHaveBeenNthCalledWith(1, 'id', 'issue-1')
    expect(query.eq).toHaveBeenNthCalledWith(2, 'project_id', 'project-1')

    const invalidQuery = new FakeQuery({ data: issue, error: null })
    const invalidClient = createClient(invalidQuery)
    await expect(createIssueService(invalidClient).createIssue('project-1', { ...input, title: '  ' })).rejects.toThrow('Issue title is required')
    expect(invalidClient.from).not.toHaveBeenCalled()
  })

  it('rejects invalid issue enum values before any request', async () => {
    for (const invalidInput of [
      { ...input, type: 'feature' as IssueInput['type'] },
      { ...input, priority: 'urgent' as IssueInput['priority'] },
      { ...input, status: 'blocked' as IssueInput['status'] },
    ]) {
      const query = new FakeQuery({ data: issue, error: null })
      const client = createClient(query)
      await expect(createIssueService(client).createIssue('project-1', invalidInput)).rejects.toThrow('Choose a valid issue')
      expect(client.from).not.toHaveBeenCalled()
    }
  })

  it('surfaces failed issue reads', async () => {
    const error = { message: 'RLS rejected the query' } as PostgrestError
    const query = new FakeQuery({ data: null, error })
    const service = createIssueService(createClient(query))
    await expect(service.listIssues('project-1')).rejects.toThrow('RLS rejected the query')
  })
})
