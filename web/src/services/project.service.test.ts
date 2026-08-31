import type { PostgrestError, SupabaseClient } from '@supabase/supabase-js'
import { describe, expect, it, vi } from 'vitest'

import { createProjectService } from './project.service'
import type { Database } from '../types/database'
import type { Project } from '../types/domain'

class FakeQuery {
  constructor(private readonly response: unknown) {}
  select = vi.fn(() => this)
  eq = vi.fn(() => this)
  order = vi.fn(() => this)
  insert = vi.fn(() => this)
  update = vi.fn(() => this)
  delete = vi.fn(() => this)
  single = vi.fn(() => Promise.resolve(this.response))
  maybeSingle = vi.fn(() => Promise.resolve(this.response))
  then<TResult1 = unknown, TResult2 = never>(
    onfulfilled?: ((value: unknown) => TResult1 | PromiseLike<TResult1>) | null,
    onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null,
  ): PromiseLike<TResult1 | TResult2> {
    return Promise.resolve(this.response).then(onfulfilled, onrejected)
  }
}

function createClient(query: FakeQuery) {
  return { from: vi.fn(() => query) } as unknown as SupabaseClient<Database>
}

const project: Project = {
  id: 'project-1', owner_id: 'owner-1', name: 'Makko', description: null, tags: ['web'],
  created_at: '2026-01-01T00:00:00Z', updated_at: '2026-01-01T00:00:00Z',
}

describe('project service', () => {
  it('scopes list reads to the authenticated owner', async () => {
    const query = new FakeQuery({ data: [project], error: null })
    const service = createProjectService(createClient(query))
    await expect(service.listProjects('owner-1')).resolves.toEqual([project])
    expect(query.eq).toHaveBeenCalledWith('owner_id', 'owner-1')
    expect(query.order).toHaveBeenCalledWith('updated_at', { ascending: false })
  })

  it('returns an empty list and a null result for missing projects', async () => {
    const emptyQuery = new FakeQuery({ data: [], error: null })
    const emptyService = createProjectService(createClient(emptyQuery))
    await expect(emptyService.listProjects('owner-1')).resolves.toEqual([])

    const missingQuery = new FakeQuery({ data: null, error: null })
    const missingService = createProjectService(createClient(missingQuery))
    await expect(missingService.getProject('owner-1', 'project-missing')).resolves.toBeNull()
    expect(missingQuery.eq).toHaveBeenNthCalledWith(1, 'id', 'project-missing')
    expect(missingQuery.eq).toHaveBeenNthCalledWith(2, 'owner_id', 'owner-1')
  })

  it('normalizes create input before inserting', async () => {
    const query = new FakeQuery({ data: project, error: null })
    const service = createProjectService(createClient(query))
    await service.createProject('owner-1', { name: '  Makko  ', description: '  A place  ', tags: [' web '] })
    expect(query.insert).toHaveBeenCalledWith({ owner_id: 'owner-1', name: 'Makko', description: 'A place', tags: ['web'] })
  })

  it('normalizes updates and scopes them to both project and owner', async () => {
    const query = new FakeQuery({ data: project, error: null })
    const service = createProjectService(createClient(query))

    await service.updateProject('owner-1', 'project-1', { name: '  Renamed  ', description: '  Updated  ', tags: [' web '] })

    expect(query.update).toHaveBeenCalledWith({ name: 'Renamed', description: 'Updated', tags: ['web'] })
    expect(query.eq).toHaveBeenNthCalledWith(1, 'id', 'project-1')
    expect(query.eq).toHaveBeenNthCalledWith(2, 'owner_id', 'owner-1')
  })

  it('scopes successful deletes to both project and owner', async () => {
    const query = new FakeQuery({ data: { id: 'project-1' }, error: null })
    const service = createProjectService(createClient(query))

    await expect(service.deleteProject('owner-1', 'project-1')).resolves.toBeUndefined()

    expect(query.eq).toHaveBeenNthCalledWith(1, 'id', 'project-1')
    expect(query.eq).toHaveBeenNthCalledWith(2, 'owner_id', 'owner-1')
  })

  it('surfaces Supabase errors instead of treating failed writes as success', async () => {
    const error = { message: 'permission denied' } as PostgrestError
    const query = new FakeQuery({ data: null, error })
    const service = createProjectService(createClient(query))
    await expect(service.deleteProject('owner-1', 'project-1')).rejects.toThrow('permission denied')
  })

  it('rejects invalid project input before making a request', async () => {
    const query = new FakeQuery({ data: project, error: null })
    const client = createClient(query)
    const service = createProjectService(client)
    await expect(service.createProject('owner-1', { name: '  ', description: '', tags: [] })).rejects.toThrow('Project name is required')
    expect(client.from).not.toHaveBeenCalled()
  })

  it('keeps tag validation meaningful for blank, duplicate, and oversized lists', async () => {
    const query = new FakeQuery({ data: project, error: null })
    const client = createClient(query)
    const service = createProjectService(client)
    await expect(service.createProject('owner-1', { name: 'Makko', description: '', tags: ['web', '', 'mobile'] })).rejects.toThrow('Tags cannot be blank')
    await expect(service.createProject('owner-1', { name: 'Makko', description: '', tags: ['web', 'WEB'] })).rejects.toThrow('Tags must be unique')
    await expect(service.createProject('owner-1', { name: 'Makko', description: '', tags: Array.from({ length: 21 }, (_, index) => `tag-${index}`) })).rejects.toThrow('at most 20 tags')
    expect(client.from).not.toHaveBeenCalled()
  })
})
