import type { PostgrestError, SupabaseClient } from '@supabase/supabase-js'

import { getSupabaseClient } from '../lib/supabase'
import type { Database } from '../types/database'
import type { Issue, IssuePriority, IssueStatus, IssueType } from '../types/domain'
import { requireId } from './validation'

export interface DashboardProjectSummary {
  id: string
  name: string
  total: number
  open: number
  completed: number
}

export interface DashboardIssueSummary {
  id: string
  title: string
  project_id: string
  projectName: string | null
  type: IssueType
  priority: IssuePriority
  status: IssueStatus
  updated_at: string
}

export interface DashboardStats {
  projectCount: number
  totalIssues: number
  openIssues: number
  completedIssues: number
  byStatus: Record<IssueStatus, number>
  byType: Record<IssueType, number>
  byPriority: Record<IssuePriority, number>
  projects: DashboardProjectSummary[]
  issues: DashboardIssueSummary[]
}

export interface DashboardProject {
  id: string
  name: string
}

const EMPTY_STATS: DashboardStats = {
  projectCount: 0,
  totalIssues: 0,
  openIssues: 0,
  completedIssues: 0,
  byStatus: { todo: 0, in_progress: 0, done: 0 },
  byType: { task: 0, bug: 0 },
  byPriority: { low: 0, medium: 0, high: 0 },
  projects: [],
  issues: [],
}

export function calculateDashboardStats(
  projects: readonly DashboardProject[],
  issues: readonly Pick<Issue, 'id' | 'title' | 'project_id' | 'type' | 'priority' | 'status' | 'updated_at'>[],
): DashboardStats {
  const projectSummaries = new Map<string, DashboardProjectSummary>(
    projects.map((project) => [project.id, { id: project.id, name: project.name, total: 0, open: 0, completed: 0 }]),
  )
  const stats: DashboardStats = {
    ...EMPTY_STATS,
    byStatus: { ...EMPTY_STATS.byStatus },
    byType: { ...EMPTY_STATS.byType },
    byPriority: { ...EMPTY_STATS.byPriority },
    projects: [],
    issues: [],
  }

  for (const issue of issues) {
    stats.totalIssues += 1
    stats.byStatus[issue.status] += 1
    stats.byType[issue.type] += 1
    stats.byPriority[issue.priority] += 1

    if (issue.status === 'done') stats.completedIssues += 1
    else stats.openIssues += 1

    const summary = projectSummaries.get(issue.project_id)
    if (summary) {
      summary.total += 1
      if (issue.status === 'done') summary.completed += 1
      else summary.open += 1
    }

    stats.issues.push({
      id: issue.id,
      title: issue.title,
      project_id: issue.project_id,
      projectName: summary?.name ?? null,
      type: issue.type,
      priority: issue.priority,
      status: issue.status,
      updated_at: issue.updated_at,
    })
  }

  stats.projectCount = projects.length
  stats.projects = [...projectSummaries.values()].sort((first, second) => {
    if (second.open !== first.open) return second.open - first.open
    const nameComparison = first.name.localeCompare(second.name, undefined, { sensitivity: 'base' })
    return nameComparison !== 0 ? nameComparison : first.id.localeCompare(second.id)
  })
  stats.issues.sort((first, second) => {
    const firstDate = Date.parse(first.updated_at)
    const secondDate = Date.parse(second.updated_at)
    const firstTimestamp = Number.isFinite(firstDate) ? firstDate : 0
    const secondTimestamp = Number.isFinite(secondDate) ? secondDate : 0
    if (secondTimestamp !== firstTimestamp) return secondTimestamp - firstTimestamp
    const titleComparison = first.title.localeCompare(second.title, undefined, { sensitivity: 'base' })
    return titleComparison !== 0 ? titleComparison : first.id.localeCompare(second.id)
  })
  return stats
}

function toError(error: PostgrestError | null, fallback: string): Error {
  return new Error(error?.message || fallback)
}

export interface DashboardService {
  getStats: (ownerId: string) => Promise<DashboardStats>
}

export function createDashboardService(client: SupabaseClient<Database>): DashboardService {
  return {
    async getStats(ownerId) {
      const owner = requireId(ownerId, 'Owner')
      const [projectsResult, issuesResult] = await Promise.all([
        client.from('projects').select('id,name').eq('owner_id', owner),
        // RLS scopes this read to internal issues belonging to the current user.
        // Deliberately do not query github_issues: GitHub data is external and read-only.
        client.from('issues').select('id,title,project_id,type,priority,status,updated_at'),
      ])
      if (projectsResult.error) throw toError(projectsResult.error, 'Unable to load dashboard projects.')
      if (issuesResult.error) throw toError(issuesResult.error, 'Unable to load dashboard issues.')

      return calculateDashboardStats(
        (projectsResult.data ?? []) as DashboardProject[],
        (issuesResult.data ?? []) as Pick<Issue, 'id' | 'title' | 'project_id' | 'type' | 'priority' | 'status' | 'updated_at'>[],
      )
    },
  }
}

export function getDashboardService(): DashboardService {
  return {
    getStats: (ownerId) => createDashboardService(getSupabaseClient()).getStats(ownerId),
  }
}
