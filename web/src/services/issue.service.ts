import type { PostgrestError, SupabaseClient } from '@supabase/supabase-js'

import { getSupabaseClient } from '../lib/supabase'
import type { Database } from '../types/database'
import type { Issue, IssueInput } from '../types/domain'
import { DEFAULT_ISSUE_FILTERS, type IssueFilters } from '../utils/issue-filters'
import { normalizeIssueInput, requireId } from './validation'

const ISSUE_COLUMNS = 'id,project_id,title,description,type,priority,status,created_at,updated_at'
export const ISSUE_PAGE_SIZE = 5

export interface IssueListOptions {
  filters?: IssueFilters
  page?: number
}

export interface IssuePage {
  items: Issue[]
  total: number
  page: number
  pageSize: number
  pageCount: number
}

export interface IssueService {
  listIssues: (projectId: string, options?: IssueListOptions) => Promise<IssuePage>
  createIssue: (projectId: string, input: IssueInput) => Promise<Issue>
  updateIssue: (projectId: string, issueId: string, input: IssueInput) => Promise<Issue>
  deleteIssue: (projectId: string, issueId: string) => Promise<void>
}

function toError(error: PostgrestError | null, fallback: string): Error {
  return new Error(error?.message || fallback)
}

export function createIssueService(client: SupabaseClient<Database>): IssueService {
  return {
    async listIssues(projectId, options = {}) {
      const project = requireId(projectId, 'Project')
      const page = options.page ?? 1
      if (!Number.isInteger(page) || page < 1 || page > 10000) {
        throw new Error('Issue page is invalid.')
      }
      const filters = options.filters ?? DEFAULT_ISSUE_FILTERS
      if (!isValidIssueFilters(filters)) throw new Error('Issue filters are invalid.')

      let query = client.from('issues')
        .select(ISSUE_COLUMNS, { count: 'exact' })
        .eq('project_id', project)
      if (filters.status !== 'all') query = query.eq('status', filters.status)
      if (filters.type !== 'all') query = query.eq('type', filters.type)
      if (filters.priority !== 'all') query = query.eq('priority', filters.priority)

      switch (filters.sort) {
        case 'oldest':
          query = query.order('created_at', { ascending: true }).order('title', { ascending: true }).order('id', { ascending: true })
          break
        case 'updated':
          query = query.order('updated_at', { ascending: false }).order('title', { ascending: true }).order('id', { ascending: true })
          break
        case 'title':
          query = query.order('title', { ascending: true }).order('id', { ascending: true })
          break
        case 'priority':
          query = query.order('priority', { ascending: false }).order('title', { ascending: true }).order('id', { ascending: true })
          break
        case 'newest':
        default:
          query = query.order('created_at', { ascending: false }).order('title', { ascending: true }).order('id', { ascending: false })
          break
      }

      const { data, error, count } = await query
        .range((page - 1) * ISSUE_PAGE_SIZE, page * ISSUE_PAGE_SIZE - 1)
      if (error) throw toError(error, 'Unable to load issues.')
      const items = data ?? []
      const total = count ?? items.length
      return {
        items,
        total,
        page,
        pageSize: ISSUE_PAGE_SIZE,
        pageCount: Math.ceil(total / ISSUE_PAGE_SIZE),
      }
    },

    async createIssue(projectId, input) {
      const project = requireId(projectId, 'Project')
      const normalized = normalizeIssueInput(input)
      const { data, error } = await client.from('issues')
        .insert({
          project_id: project,
          title: normalized.title,
          description: normalized.description || null,
          type: normalized.type,
          priority: normalized.priority,
          status: normalized.status,
        })
        .select(ISSUE_COLUMNS)
        .single()
      if (error) throw toError(error, 'Unable to create the issue.')
      if (!data) throw new Error('Issue creation did not return an issue.')
      return data
    },

    async updateIssue(projectId, issueId, input) {
      const project = requireId(projectId, 'Project')
      const issue = requireId(issueId, 'Issue')
      const normalized = normalizeIssueInput(input)
      const { data, error } = await client.from('issues')
        .update({
          title: normalized.title,
          description: normalized.description || null,
          type: normalized.type,
          priority: normalized.priority,
          status: normalized.status,
        })
        .eq('id', issue)
        .eq('project_id', project)
        .select(ISSUE_COLUMNS)
        .single()
      if (error) throw toError(error, 'Unable to update the issue.')
      if (!data) throw new Error('Issue update did not return an issue.')
      return data
    },

    async deleteIssue(projectId, issueId) {
      const project = requireId(projectId, 'Project')
      const issue = requireId(issueId, 'Issue')
      const { error } = await client.from('issues')
        .delete()
        .eq('id', issue)
        .eq('project_id', project)
        .select('id')
        .single()
      if (error) throw toError(error, 'Unable to delete the issue.')
    },
  }
}

export function getIssueService(): IssueService {
  return {
    listIssues: (projectId, options) => createIssueService(getSupabaseClient()).listIssues(projectId, options),
    createIssue: (projectId, input) => createIssueService(getSupabaseClient()).createIssue(projectId, input),
    updateIssue: (projectId, issueId, input) => createIssueService(getSupabaseClient()).updateIssue(projectId, issueId, input),
    deleteIssue: (projectId, issueId) => createIssueService(getSupabaseClient()).deleteIssue(projectId, issueId),
  }
}

function isValidIssueFilters(filters: unknown): filters is IssueFilters {
  if (typeof filters !== 'object' || filters === null) return false
  const candidate = filters as Record<string, unknown>
  return (
    candidate.status === 'all' || candidate.status === 'todo' || candidate.status === 'in_progress' || candidate.status === 'done'
  ) && (
    candidate.type === 'all' || candidate.type === 'task' || candidate.type === 'bug'
  ) && (
    candidate.priority === 'all' || candidate.priority === 'low' || candidate.priority === 'medium' || candidate.priority === 'high'
  ) && (
    candidate.sort === 'newest' || candidate.sort === 'oldest' || candidate.sort === 'updated' || candidate.sort === 'title' || candidate.sort === 'priority'
  )
}
