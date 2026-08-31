import type { Issue } from '../types/domain'
import type { IssuePriority, IssueStatus, IssueType } from '../types/database'

export type IssueSort = 'newest' | 'oldest' | 'updated' | 'title' | 'priority'

export interface IssueFilters {
  status: IssueStatus | 'all'
  type: IssueType | 'all'
  priority: IssuePriority | 'all'
  sort: IssueSort
}
export const DEFAULT_ISSUE_FILTERS: IssueFilters = {
  status: 'all',
  type: 'all',
  priority: 'all',
  sort: 'newest',
}

const priorityRank: Record<IssuePriority, number> = { high: 3, medium: 2, low: 1 }

function compareText(left: string, right: string): number {
  return left.localeCompare(right, undefined, { sensitivity: 'base' })
}

function compareDate(left: string, right: string): number {
  const leftTime = Date.parse(left)
  const rightTime = Date.parse(right)
  if (Number.isNaN(leftTime) && Number.isNaN(rightTime)) return 0
  if (Number.isNaN(leftTime)) return 1
  if (Number.isNaN(rightTime)) return -1
  return leftTime - rightTime
}

export function filterAndSortIssues(issues: readonly Issue[], filters: IssueFilters): Issue[] {
  const filtered = issues.filter((issue) => (
    (filters.status === 'all' || issue.status === filters.status)
      && (filters.type === 'all' || issue.type === filters.type)
      && (filters.priority === 'all' || issue.priority === filters.priority)
  ))

  return [...filtered].sort((left, right) => {
    let comparison = 0
    switch (filters.sort) {
      case 'oldest':
        comparison = compareDate(left.created_at, right.created_at)
        break
      case 'updated':
        comparison = compareDate(right.updated_at, left.updated_at)
        break
      case 'title':
        comparison = compareText(left.title, right.title)
        break
      case 'priority':
        comparison = priorityRank[right.priority] - priorityRank[left.priority]
        break
      case 'newest':
      default:
        comparison = compareDate(right.created_at, left.created_at)
        break
    }

    if (comparison !== 0) return comparison
    const titleComparison = compareText(left.title, right.title)
    if (titleComparison !== 0) return titleComparison
    return left.id.localeCompare(right.id)
  })
}
