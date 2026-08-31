import { useCallback, useEffect, useState } from 'react'

import { getIssueService, type IssueService } from '../services/issue.service'
import type { Issue, IssueInput } from '../types/domain'
import type { ResourceStatus } from './use-projects'

function getErrorMessage(error: unknown, fallback: string): string {
  return error instanceof Error && error.message ? error.message : fallback
}
export function useProjectIssues(projectId: string | undefined, service?: IssueService) {
  const [issueService] = useState<IssueService>(() => service ?? getIssueService())
  const [issues, setIssues] = useState<Issue[]>([])
  const [status, setStatus] = useState<ResourceStatus>('loading')
  const [error, setError] = useState<string | null>(null)
  const [isMutating, setIsMutating] = useState(false)

  const refresh = useCallback(async () => {
    if (!projectId) {
      setIssues([])
      setStatus('ready')
      setError(null)
      return
    }
    setStatus('loading')
    setError(null)
    try {
      setIssues(await issueService.listIssues(projectId))
      setStatus('ready')
    } catch (caught) {
      setStatus('error')
      setError(getErrorMessage(caught, 'Unable to load issues.'))
    }
  }, [issueService, projectId])

  useEffect(() => { void refresh() }, [refresh])

  const createIssue = async (input: IssueInput): Promise<Issue | null> => {
    if (!projectId) return null
    setIsMutating(true)
    setError(null)
    try {
      const issue = await issueService.createIssue(projectId, input)
      await refresh()
      return issue
    } catch (caught) {
      setError(getErrorMessage(caught, 'Unable to create the issue.'))
      return null
    } finally {
      setIsMutating(false)
    }
  }

  const updateIssue = async (issueId: string, input: IssueInput): Promise<Issue | null> => {
    if (!projectId) return null
    setIsMutating(true)
    setError(null)
    try {
      const issue = await issueService.updateIssue(projectId, issueId, input)
      await refresh()
      return issue
    } catch (caught) {
      setError(getErrorMessage(caught, 'Unable to update the issue.'))
      return null
    } finally {
      setIsMutating(false)
    }
  }

  const deleteIssue = async (issueId: string): Promise<boolean> => {
    if (!projectId) return false
    setIsMutating(true)
    setError(null)
    try {
      await issueService.deleteIssue(projectId, issueId)
      await refresh()
      return true
    } catch (caught) {
      setError(getErrorMessage(caught, 'Unable to delete the issue.'))
      return false
    } finally {
      setIsMutating(false)
    }
  }

  return { issues, status, error, isMutating, refresh, createIssue, updateIssue, deleteIssue }
}
