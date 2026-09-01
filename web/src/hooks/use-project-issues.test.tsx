import { act, renderHook, waitFor } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'

import { ISSUE_PAGE_SIZE, type IssueService } from '../services/issue.service'
import type { Issue } from '../types/domain'
import { useProjectIssues } from './use-project-issues'

const issue: Issue = {
  id: 'issue-1',
  project_id: 'project-1',
  title: 'Fix auth',
  description: null,
  type: 'bug',
  priority: 'high',
  status: 'todo',
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
}

describe('useProjectIssues', () => {
  it('requests filtered pages and exposes server pagination metadata', async () => {
    const service: IssueService = {
      listIssues: vi.fn(async (_projectId, options) => ({
        items: options?.page === 2 ? [{ ...issue, id: 'issue-2' }] : [issue],
        total: 21,
        page: options?.page ?? 1,
        pageSize: ISSUE_PAGE_SIZE,
        pageCount: 2,
      })),
      createIssue: vi.fn(async () => issue),
      updateIssue: vi.fn(async () => issue),
      deleteIssue: vi.fn(async () => undefined),
    }
    const filters = { status: 'done' as const, type: 'bug' as const, priority: 'high' as const, sort: 'priority' as const }
    const { result } = renderHook(() => useProjectIssues('project-1', filters, service))

    await waitFor(() => expect(result.current.status).toBe('ready'))
    expect(service.listIssues).toHaveBeenCalledWith('project-1', { filters, page: 1 })
    expect(result.current.total).toBe(21)
    expect(result.current.pageCount).toBe(2)

    act(() => result.current.setPage(2))
    await waitFor(() => expect(service.listIssues).toHaveBeenLastCalledWith('project-1', { filters, page: 2 }))
    await waitFor(() => expect(result.current.page).toBe(2))
    expect(result.current.issues[0]?.id).toBe('issue-2')
  })
})
