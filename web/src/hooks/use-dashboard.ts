import { useCallback, useEffect, useState } from 'react'

import { useAuth } from '../features/auth/use-auth'
import { getDashboardService, type DashboardService } from '../services/dashboard.service'
import type { DashboardStats } from '../services/dashboard.service'
import type { ResourceStatus } from './use-projects'

function getErrorMessage(error: unknown, fallback: string): string {
  return error instanceof Error && error.message ? error.message : fallback
}

export function useDashboard(service?: DashboardService) {
  const { state: authState } = useAuth()
  const ownerId = authState.session?.user.id ?? null
  const [dashboardService] = useState<DashboardService>(() => service ?? getDashboardService())
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [status, setStatus] = useState<ResourceStatus>('loading')
  const [error, setError] = useState<string | null>(null)

  const refresh = useCallback(async () => {
    if (!ownerId) {
      setStats(null)
      setStatus('ready')
      setError(null)
      return
    }
    setStatus('loading')
    setError(null)
    try {
      setStats(await dashboardService.getStats(ownerId))
      setStatus('ready')
    } catch (caught) {
      setStatus('error')
      setError(getErrorMessage(caught, 'Unable to load your dashboard.'))
    }
  }, [dashboardService, ownerId])

  useEffect(() => { void refresh() }, [refresh])

  return { stats, status, error, refresh }
}
