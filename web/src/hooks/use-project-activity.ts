import { useCallback, useEffect, useRef, useState } from 'react'

import { getActivityService, type ActivityScope, type ActivityService } from '../services/activity.service'
import type { ActivityLog } from '../types/domain'
import type { ResourceStatus } from './use-projects'

function getErrorMessage(error: unknown, fallback: string): string {
  return error instanceof Error && error.message ? error.message : fallback
}
export function useProjectActivity(projectId: string | undefined, service?: ActivityService) {
  const [activityService] = useState<ActivityService>(() => service ?? getActivityService())
  const [activity, setActivity] = useState<ActivityLog[]>([])
  const [status, setStatus] = useState<ResourceStatus>('loading')
  const [error, setError] = useState<string | null>(null)
  const [scope, setScope] = useState<ActivityScope>('last_30_days')
  const [page, setPage] = useState(1)
  const [hasMore, setHasMore] = useState(false)
  const [isLoadingMore, setIsLoadingMore] = useState(false)
  const requestId = useRef(0)
  const loadingMore = useRef(false)

  const loadPage = useCallback(async (nextPage: number, nextScope: ActivityScope, append: boolean) => {
    if (append && loadingMore.current) return
    const currentRequest = ++requestId.current
    if (!projectId) {
      setActivity([])
      setStatus('ready')
      setError(null)
      setPage(1)
      setHasMore(false)
      return
    }

    if (append) {
      loadingMore.current = true
      setIsLoadingMore(true)
    } else {
      loadingMore.current = false
      setIsLoadingMore(false)
      setStatus('loading')
      setError(null)
      setActivity([])
      setPage(1)
      setHasMore(false)
    }

    try {
      const result = await activityService.listProjectActivity(projectId, { scope: nextScope, page: nextPage })
      if (currentRequest !== requestId.current) return
      setActivity((existing) => append ? [...existing, ...result.items] : result.items)
      setPage(result.page)
      setHasMore(result.hasMore)
      setStatus('ready')
    } catch (caught) {
      if (currentRequest !== requestId.current) return
      setStatus('error')
      setError(getErrorMessage(caught, 'Unable to load project activity.'))
    } finally {
      if (append) {
        loadingMore.current = false
        setIsLoadingMore(false)
      }
    }
  }, [activityService, projectId])

  const refresh = useCallback(async () => {
    await loadPage(1, scope, false)
  }, [loadPage, scope])

  const loadMore = useCallback(async () => {
    if (!hasMore || isLoadingMore) return
    await loadPage(page + 1, scope, true)
  }, [hasMore, isLoadingMore, loadPage, page, scope])

  useEffect(() => { void loadPage(1, scope, false) }, [loadPage, scope])

  return { activity, status, error, scope, setScope, page, hasMore, isLoadingMore, refresh, loadMore }
}
