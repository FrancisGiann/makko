import { useCallback, useEffect, useRef, useState } from 'react'

import { getGithubService, type GithubProjectData, type GithubService, GithubSyncError } from '../services/github.service'
import type { GithubLink, GithubSyncResult } from '../types/domain'
import type { ResourceStatus } from './use-projects'

const EMPTY_DATA: GithubProjectData = { link: null, commits: [], issues: [] }

function getErrorMessage(error: unknown, fallback: string): string {
  return error instanceof Error && error.message ? error.message : fallback
}

function cooldownFromLink(link: GithubLink | null): number {
  if (!link?.last_synced_at) return 0
  const remaining = Date.parse(link.last_synced_at) + 60_000 - Date.now()
  return remaining > 0 ? Date.now() + remaining : 0
}

export function useProjectGithub(projectId: string | undefined, service?: GithubService) {
  const enabled = Boolean(projectId)
  const [githubService] = useState<GithubService>(() => service ?? getGithubService())
  const [data, setData] = useState<GithubProjectData>(EMPTY_DATA)
  const [status, setStatus] = useState<ResourceStatus>('loading')
  const [error, setError] = useState<string | null>(null)
  const [isMutating, setIsMutating] = useState(false)
  const [syncCooldownUntil, setSyncCooldownUntil] = useState(0)
  const [, setCooldownTick] = useState(0)
  const syncCooldownRef = useRef(0)

  const refresh = useCallback(async () => {
    if (!enabled || !projectId) {
      setData(EMPTY_DATA)
      setStatus('ready')
      setError(null)
      setSyncCooldownUntil(0)
      syncCooldownRef.current = 0
      return
    }
    setStatus('loading')
    setError(null)
    try {
      const next = await githubService.getProjectData(projectId)
      setData(next)
      const linkCooldown = cooldownFromLink(next.link)
      setSyncCooldownUntil(linkCooldown)
      syncCooldownRef.current = linkCooldown
      setStatus('ready')
    } catch (caught) {
      setStatus('error')
      setError(getErrorMessage(caught, 'Unable to load GitHub data.'))
    }
  }, [enabled, githubService, projectId])

  useEffect(() => { void refresh() }, [refresh])

  useEffect(() => {
    if (!syncCooldownUntil) return
    const timer = window.setInterval(() => {
      if (Date.now() >= syncCooldownRef.current) {
        setSyncCooldownUntil(0)
        syncCooldownRef.current = 0
        setCooldownTick((tick) => tick + 1)
      } else {
        setCooldownTick((tick) => tick + 1)
      }
    }, 1_000)
    return () => window.clearInterval(timer)
  }, [syncCooldownUntil])

  const connect = async (repository: string): Promise<GithubLink | null> => {
    if (!projectId) return null
    setIsMutating(true)
    setError(null)
    try {
      const link = await githubService.connect(projectId, repository)
      await refresh()
      return link
    } catch (caught) {
      setError(getErrorMessage(caught, 'Unable to connect this GitHub repository.'))
      return null
    } finally {
      setIsMutating(false)
    }
  }

  const disconnect = async (): Promise<boolean> => {
    if (!projectId || !data.link) return false
    setIsMutating(true)
    setError(null)
    try {
      await githubService.disconnect(projectId, data.link.id)
      setData(EMPTY_DATA)
      setSyncCooldownUntil(0)
      syncCooldownRef.current = 0
      return true
    } catch (caught) {
      setError(getErrorMessage(caught, 'Unable to disconnect this GitHub repository.'))
      return false
    } finally {
      setIsMutating(false)
    }
  }

  const sync = async (): Promise<GithubSyncResult | null> => {
    if (!projectId || !data.link || status === 'loading' || isMutating || Date.now() < syncCooldownUntil) return null
    setIsMutating(true)
    setError(null)
    try {
      const result = await githubService.sync(projectId)
      await refresh()
      return result
    } catch (caught) {
      if (caught instanceof GithubSyncError && caught.retryAfterSeconds) {
        const until = Date.now() + caught.retryAfterSeconds * 1_000
        setSyncCooldownUntil(until)
        syncCooldownRef.current = until
      }
      setError(getErrorMessage(caught, 'Unable to synchronize this GitHub repository.'))
      return null
    } finally {
      setIsMutating(false)
    }
  }

  const cooldownSeconds = syncCooldownUntil > Date.now()
    ? Math.max(1, Math.ceil((syncCooldownUntil - Date.now()) / 1_000))
    : 0
  return {
    ...data,
    status,
    error,
    isMutating,
    refresh,
    connect,
    disconnect,
    sync,
    cooldownSeconds,
  }
}
