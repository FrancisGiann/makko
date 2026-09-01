import type { PostgrestError, SupabaseClient } from '@supabase/supabase-js'
import { describe, expect, it, vi } from 'vitest'

import { ACTIVITY_PAGE_SIZE, createActivityService } from './activity.service'
import type { Database } from '../types/database'
import type { ActivityLog } from '../types/domain'

class FakeQuery {
  constructor(private readonly response: unknown) {}
  select = vi.fn(() => this)
  eq = vi.fn(() => this)
  gte = vi.fn(() => this)
  order = vi.fn(() => this)
  range = vi.fn(() => Promise.resolve(this.response))
}

function createClient(query: FakeQuery) {
  return { from: vi.fn(() => query) } as unknown as SupabaseClient<Database>
}

const event: ActivityLog = { id: 'event-1', project_id: 'project-1', issue_id: null, action: 'issue.deleted', description: 'Issue deleted: "Old auth bug"', created_at: '2026-01-01T00:00:00Z' }

describe('activity service', () => {
  it('reads only the selected project in newest-first order', async () => {
    const query = new FakeQuery({ data: [event], error: null })
    const service = createActivityService(createClient(query))
    await expect(service.listProjectActivity('project-1')).resolves.toEqual({ items: [event], page: 1, pageSize: ACTIVITY_PAGE_SIZE, hasMore: false })
    expect(query.eq).toHaveBeenCalledWith('project_id', 'project-1')
    expect(query.order).toHaveBeenCalledWith('created_at', { ascending: false })
    expect(query.order).toHaveBeenCalledWith('id', { ascending: false })
    expect(query.gte).toHaveBeenCalledWith('created_at', expect.any(String))
    expect(query.range).toHaveBeenCalledWith(0, ACTIVITY_PAGE_SIZE)
  })

  it('omits the date filter for all-time pages and reports more rows from the sentinel', async () => {
    const rows = Array.from({ length: ACTIVITY_PAGE_SIZE + 1 }, (_, index) => ({ ...event, id: `event-${index}` }))
    const query = new FakeQuery({ data: rows, error: null })
    const service = createActivityService(createClient(query))

    const result = await service.listProjectActivity('project-1', { scope: 'all_time', page: 2 })

    expect(result).toEqual({ items: rows.slice(0, ACTIVITY_PAGE_SIZE), page: 2, pageSize: ACTIVITY_PAGE_SIZE, hasMore: true })
    expect(query.gte).not.toHaveBeenCalled()
    expect(query.range).toHaveBeenCalledWith(ACTIVITY_PAGE_SIZE, ACTIVITY_PAGE_SIZE * 2)
  })

  it('validates project and page inputs before querying', async () => {
    const query = new FakeQuery({ data: [], error: null })
    const client = createClient(query)
    const service = createActivityService(client)

    await expect(service.listProjectActivity('project-1', { page: 0 })).rejects.toThrow('Activity page is invalid')
    expect(client.from).not.toHaveBeenCalled()
  })

  it('surfaces activity query errors', async () => {
    const error = { message: 'activity unavailable' } as PostgrestError
    const query = new FakeQuery({ data: null, error })
    const service = createActivityService(createClient(query))
    await expect(service.listProjectActivity('project-1')).rejects.toThrow('activity unavailable')
  })
})
