import { useCallback, useEffect, useState } from 'react'

import { getActivityService, type ActivityService } from '../services/activity.service'
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

  const refresh = useCallback(async () => {
    if (!projectId) {
      setActivity([])
      setStatus('ready')
      setError(null)
      return
    }
    setStatus('loading')
    setError(null)
    try {
      setActivity(await activityService.listProjectActivity(projectId))
      setStatus('ready')
    } catch (caught) {
      setStatus('error')
      setError(getErrorMessage(caught, 'Unable to load project activity.'))
    }
  }, [activityService, projectId])

  useEffect(() => { void refresh() }, [refresh])

  return { activity, status, error, refresh }
}
