import { act, renderHook, waitFor } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'

import type { ActivityService } from '../services/activity.service'
import type { ActivityLog } from '../types/domain'
import { useProjectActivity } from './use-project-activity'

const event: ActivityLog = {
  id: 'event-1',
  project_id: 'project-1',
  issue_id: null,
  action: 'project.created',
  description: 'Project created',
  created_at: '2026-01-01T00:00:00Z',
}

describe('useProjectActivity', () => {
  it('loads one default page, appends a page, and resets on scope changes', async () => {
    const service: ActivityService = {
      listProjectActivity: vi.fn(async (_projectId, options) => ({
        items: options?.page === 2 ? [{ ...event, id: 'event-2' }] : [event],
        page: options?.page ?? 1,
        pageSize: 30,
        hasMore: options?.page !== 2,
      })),
    }
    const { result } = renderHook(() => useProjectActivity('project-1', service))

    await waitFor(() => expect(result.current.status).toBe('ready'))
    expect(service.listProjectActivity).toHaveBeenCalledWith('project-1', { scope: 'last_30_days', page: 1 })
    expect(result.current.hasMore).toBe(true)

    await act(async () => { await result.current.loadMore() })
    expect(result.current.activity.map((item) => item.id)).toEqual(['event-1', 'event-2'])
    expect(service.listProjectActivity).toHaveBeenLastCalledWith('project-1', { scope: 'last_30_days', page: 2 })

    act(() => result.current.setScope('all_time'))
    await waitFor(() => expect(service.listProjectActivity).toHaveBeenLastCalledWith('project-1', { scope: 'all_time', page: 1 }))
    await waitFor(() => expect(result.current.activity).toEqual([event]))
  })

  it('clears loading-more state when a scope change supersedes an append request', async () => {
    let resolveAppend: ((value: Awaited<ReturnType<ActivityService['listProjectActivity']>>) => void) | undefined
    const appendResult = new Promise<Awaited<ReturnType<ActivityService['listProjectActivity']>>>((resolve) => {
      resolveAppend = resolve
    })
    const allTimeEvent = { ...event, id: 'all-time-event' }
    const service: ActivityService = {
      listProjectActivity: vi.fn(async (_projectId, options) => {
        if (options?.page === 2) return appendResult
        return {
          items: options?.scope === 'all_time' ? [allTimeEvent] : [event],
          page: 1,
          pageSize: 30,
          hasMore: options?.scope !== 'all_time',
        }
      }),
    }
    const { result } = renderHook(() => useProjectActivity('project-1', service))

    await waitFor(() => expect(result.current.status).toBe('ready'))
    act(() => { void result.current.loadMore() })
    await waitFor(() => expect(result.current.isLoadingMore).toBe(true))

    act(() => result.current.setScope('all_time'))
    await waitFor(() => expect(result.current.activity).toEqual([allTimeEvent]))
    expect(result.current.isLoadingMore).toBe(false)

    await act(async () => {
      resolveAppend?.({ items: [{ ...event, id: 'stale-page' }], page: 2, pageSize: 30, hasMore: false })
      await appendResult
    })
    expect(result.current.activity).toEqual([allTimeEvent])
    expect(result.current.isLoadingMore).toBe(false)
  })
})
