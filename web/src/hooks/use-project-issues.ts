import { useCallback, useEffect, useRef, useState } from 'react'

import { getIssueService, ISSUE_PAGE_SIZE, type IssuePage, type IssueService } from '../services/issue.service'
import type { Issue, IssueInput } from '../types/domain'
import { DEFAULT_ISSUE_FILTERS, type IssueFilters } from '../utils/issue-filters'
import type { ResourceStatus } from './use-projects'

function getErrorMessage(error: unknown, fallback: string): string {
  return error instanceof Error && error.message ? error.message : fallback
}

function isIssueService(value: IssueFilters | IssueService | undefined): value is IssueService {
  return Boolean(value && 'listIssues' in value)
}

export function useProjectIssues(projectId: string | undefined, filters?: IssueFilters, service?: IssueService): IssueState
export function useProjectIssues(projectId: string | undefined, service?: IssueService): IssueState
export function useProjectIssues(projectId: string | undefined, filtersOrService?: IssueFilters | IssueService, maybeService?: IssueService): IssueState {
  const filters = isIssueService(filtersOrService) ? DEFAULT_ISSUE_FILTERS : filtersOrService ?? DEFAULT_ISSUE_FILTERS
  const injectedService = isIssueService(filtersOrService) ? filtersOrService : maybeService
  const [issueService] = useState<IssueService>(() => injectedService ?? getIssueService())
  const [issues, setIssues] = useState<Issue[]>([])
  const [total, setTotal] = useState(0)
  const [page, setCurrentPage] = useState(1)
  const [pageCount, setPageCount] = useState(0)
  const [status, setStatus] = useState<ResourceStatus>('loading')
  const [error, setError] = useState<string | null>(null)
  const [isMutating, setIsMutating] = useState(false)
  const requestId = useRef(0)

  const loadPage = useCallback(async (nextPage: number, nextFilters: IssueFilters): Promise<IssuePage | null> => {
    const currentRequest = ++requestId.current
    if (!projectId) {
      setIssues([])
      setTotal(0)
      setCurrentPage(1)
      setPageCount(0)
      setStatus('ready')
      setError(null)
      return null
    }

    setStatus('loading')
    setError(null)
    try {
      const result = await issueService.listIssues(projectId, { filters: nextFilters, page: nextPage })
      if (currentRequest !== requestId.current) return null
      setIssues(result.items)
      setTotal(result.total)
      setCurrentPage(result.page)
      setPageCount(result.pageCount)
      setStatus('ready')
      return result
    } catch (caught) {
      if (currentRequest !== requestId.current) return null
      setStatus('error')
      setError(getErrorMessage(caught, 'Unable to load issues.'))
      return null
    }
  }, [issueService, projectId])

  useEffect(() => {
    setIssues([])
    setTotal(0)
    setCurrentPage(1)
    setPageCount(0)
    void loadPage(1, filters)
  }, [filters, loadPage])

  const refresh = useCallback(async () => {
    const requestedPage = page
    const result = await loadPage(requestedPage, filters)
    if (!result || result.items.length > 0 || requestedPage <= 1 || result.pageCount >= requestedPage) return

    const fallbackPage = Math.min(requestedPage - 1, result.pageCount)
    if (fallbackPage < 1) return
    setCurrentPage(fallbackPage)
    await loadPage(fallbackPage, filters)
  }, [filters, loadPage, page])

  const setPage = useCallback((nextPage: number) => {
    if (!Number.isInteger(nextPage) || nextPage < 1 || (pageCount > 0 && nextPage > pageCount)) return
    if (nextPage === page) return
    setCurrentPage(nextPage)
    void loadPage(nextPage, filters)
  }, [filters, loadPage, page, pageCount])

  const createIssue = async (input: IssueInput): Promise<Issue | null> => {
    if (!projectId) return null
    setIsMutating(true)
    setError(null)
    try {
      const issue = await issueService.createIssue(projectId, input)
      setCurrentPage(1)
      await loadPage(1, filters)
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

  return { issues, total, page, pageCount, pageSize: ISSUE_PAGE_SIZE, status, error, isMutating, refresh, setPage, createIssue, updateIssue, deleteIssue }
}

export interface IssueState {
  issues: Issue[]
  total: number
  page: number
  pageCount: number
  pageSize: number
  status: ResourceStatus
  error: string | null
  isMutating: boolean
  refresh: () => Promise<void>
  setPage: (page: number) => void
  createIssue: (input: IssueInput) => Promise<Issue | null>
  updateIssue: (issueId: string, input: IssueInput) => Promise<Issue | null>
  deleteIssue: (issueId: string) => Promise<boolean>
}
