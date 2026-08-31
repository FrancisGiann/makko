import type { PostgrestError, SupabaseClient } from '@supabase/supabase-js'
import { describe, expect, it, vi } from 'vitest'

import { createActivityService } from './activity.service'
import type { Database } from '../types/database'
import type { ActivityLog } from '../types/domain'

class FakeQuery {
  constructor(private readonly response: unknown) {}
  select = vi.fn(() => this)
  eq = vi.fn(() => this)
  order = vi.fn(() => Promise.resolve(this.response))
}

function createClient(query: FakeQuery) {
  return { from: vi.fn(() => query) } as unknown as SupabaseClient<Database>
}

const event: ActivityLog = { id: 'event-1', project_id: 'project-1', issue_id: null, action: 'issue.deleted', description: 'Issue deleted: "Old auth bug"', created_at: '2026-01-01T00:00:00Z' }

describe('activity service', () => {
  it('reads only the selected project in newest-first order', async () => {
    const query = new FakeQuery({ data: [event], error: null })
    const service = createActivityService(createClient(query))
    await expect(service.listProjectActivity('project-1')).resolves.toEqual([event])
    expect(query.eq).toHaveBeenCalledWith('project_id', 'project-1')
    expect(query.order).toHaveBeenCalledWith('created_at', { ascending: false })
  })

  it('surfaces activity query errors', async () => {
    const error = { message: 'activity unavailable' } as PostgrestError
    const query = new FakeQuery({ data: null, error })
    const service = createActivityService(createClient(query))
    await expect(service.listProjectActivity('project-1')).rejects.toThrow('activity unavailable')
  })
})
