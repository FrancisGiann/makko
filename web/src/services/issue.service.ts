import type { PostgrestError, SupabaseClient } from '@supabase/supabase-js'

import { getSupabaseClient } from '../lib/supabase'
import type { Database } from '../types/database'
import type { Issue, IssueInput } from '../types/domain'
import { normalizeIssueInput, requireId } from './validation'

const ISSUE_COLUMNS = 'id,project_id,title,description,type,priority,status,created_at,updated_at'

export interface IssueService {
  listIssues: (projectId: string) => Promise<Issue[]>
  createIssue: (projectId: string, input: IssueInput) => Promise<Issue>
  updateIssue: (projectId: string, issueId: string, input: IssueInput) => Promise<Issue>
  deleteIssue: (projectId: string, issueId: string) => Promise<void>
}

function toError(error: PostgrestError | null, fallback: string): Error {
  return new Error(error?.message || fallback)
}

export function createIssueService(client: SupabaseClient<Database>): IssueService {
  return {
    async listIssues(projectId) {
      const project = requireId(projectId, 'Project')
      const { data, error } = await client.from('issues')
        .select(ISSUE_COLUMNS)
        .eq('project_id', project)
        .order('created_at', { ascending: false })
      if (error) throw toError(error, 'Unable to load issues.')
      return data ?? []
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
    listIssues: (projectId) => createIssueService(getSupabaseClient()).listIssues(projectId),
    createIssue: (projectId, input) => createIssueService(getSupabaseClient()).createIssue(projectId, input),
    updateIssue: (projectId, issueId, input) => createIssueService(getSupabaseClient()).updateIssue(projectId, issueId, input),
    deleteIssue: (projectId, issueId) => createIssueService(getSupabaseClient()).deleteIssue(projectId, issueId),
  }
}
