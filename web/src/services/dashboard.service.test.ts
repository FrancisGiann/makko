import type { PostgrestError, SupabaseClient } from '@supabase/supabase-js'
import { describe, expect, it, vi } from 'vitest'

import { calculateDashboardStats, createDashboardService } from './dashboard.service'
import type { Database } from '../types/database'

class FakeQuery {
  constructor(private readonly response: unknown) {}
  select = vi.fn(() => this)
  eq = vi.fn(() => this)
  then<TResult1 = unknown, TResult2 = never>(onfulfilled?: ((value: unknown) => TResult1 | PromiseLike<TResult1>) | null, onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null): PromiseLike<TResult1 | TResult2> {
    return Promise.resolve(this.response).then(onfulfilled, onrejected)
  }
}

describe('dashboard service', () => {
  it('calculates open and completed totals from internal issues only', () => {
    const stats = calculateDashboardStats(
      [{ id: 'project-1', name: 'Makko' }],
      [
        { project_id: 'project-1', type: 'task', priority: 'high', status: 'todo' },
        { project_id: 'project-1', type: 'bug', priority: 'medium', status: 'in_progress' },
        { project_id: 'project-1', type: 'task', priority: 'low', status: 'done' },
      ],
    )

    expect(stats.totalIssues).toBe(3)
    expect(stats.openIssues).toBe(2)
    expect(stats.completedIssues).toBe(1)
    expect(stats.byType).toEqual({ task: 2, bug: 1 })
    expect(stats.byStatus).toEqual({ todo: 1, in_progress: 1, done: 1 })
  })

  it('returns zeroed totals for an empty workspace and deterministically sorts project ties', () => {
    expect(calculateDashboardStats([], [])).toMatchObject({
      projectCount: 0,
      totalIssues: 0,
      openIssues: 0,
      completedIssues: 0,
      byStatus: { todo: 0, in_progress: 0, done: 0 },
      byType: { task: 0, bug: 0 },
      byPriority: { low: 0, medium: 0, high: 0 },
      projects: [],
    })

    const stats = calculateDashboardStats(
      [{ id: 'project-b', name: 'alpha' }, { id: 'project-a', name: 'Alpha' }, { id: 'project-c', name: 'Beta' }],
      [
        { project_id: 'project-a', type: 'task', priority: 'low', status: 'todo' },
        { project_id: 'project-b', type: 'bug', priority: 'high', status: 'in_progress' },
        { project_id: 'project-c', type: 'task', priority: 'medium', status: 'done' },
      ],
    )

    expect(stats.projects.map((project) => project.id)).toEqual(['project-a', 'project-b', 'project-c'])
    expect(stats.projects.map((project) => [project.total, project.open, project.completed])).toEqual([[1, 1, 0], [1, 1, 0], [1, 0, 1]])
  })

  it('reads projects and public.issues, without using GitHub issue rows', async () => {
    const projects = new FakeQuery({ data: [{ id: 'project-1', name: 'Makko' }], error: null })
    const issues = new FakeQuery({ data: [{ project_id: 'project-1', type: 'task', priority: 'low', status: 'done' }], error: null })
    const client = { from: vi.fn((table: string) => table === 'projects' ? projects : issues) } as unknown as SupabaseClient<Database>

    const stats = await createDashboardService(client).getStats('owner-1')

    expect(stats.completedIssues).toBe(1)
    expect(client.from).toHaveBeenCalledWith('projects')
    expect(client.from).toHaveBeenCalledWith('issues')
    expect(client.from).not.toHaveBeenCalledWith('github_issues')
    expect(projects.eq).toHaveBeenCalledWith('owner_id', 'owner-1')
  })

  it('surfaces an internal issue query failure', async () => {
    const projects = new FakeQuery({ data: [], error: null })
    const issues = new FakeQuery({ data: null, error: { message: 'RLS rejected' } as PostgrestError })
    const client = { from: vi.fn((table: string) => table === 'projects' ? projects : issues) } as unknown as SupabaseClient<Database>

    await expect(createDashboardService(client).getStats('owner-1')).rejects.toThrow('RLS rejected')
  })
})
