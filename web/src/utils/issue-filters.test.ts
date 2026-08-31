import { describe, expect, it } from 'vitest'

import type { Issue } from '../types/domain'
import { DEFAULT_ISSUE_FILTERS, filterAndSortIssues } from './issue-filters'

const issues: Issue[] = [
  { id: 'a', project_id: 'project', title: 'Zebra', description: null, type: 'task', priority: 'low', status: 'todo', created_at: '2026-01-01T00:00:00Z', updated_at: '2026-01-03T00:00:00Z' },
  { id: 'b', project_id: 'project', title: 'Alpha', description: null, type: 'bug', priority: 'high', status: 'in_progress', created_at: '2026-01-03T00:00:00Z', updated_at: '2026-01-04T00:00:00Z' },
  { id: 'c', project_id: 'project', title: 'Beta', description: null, type: 'task', priority: 'medium', status: 'done', created_at: '2026-01-02T00:00:00Z', updated_at: '2026-01-05T00:00:00Z' },
  { id: 'd', project_id: 'other-project', title: 'Other', description: null, type: 'bug', priority: 'high', status: 'todo', created_at: '2026-01-05T00:00:00Z', updated_at: '2026-01-05T00:00:00Z' },
]

describe('filterAndSortIssues', () => {
  it('composes status, type, and priority filters', () => {
    const result = filterAndSortIssues(issues, { ...DEFAULT_ISSUE_FILTERS, status: 'in_progress', type: 'bug', priority: 'high' })
    expect(result.map((issue) => issue.id)).toEqual(['b'])
  })

  it('sorts newest first with deterministic title and id tie breakers', () => {
    const tied = issues.map((issue) => ({ ...issue, created_at: '2026-02-01T00:00:00Z' }))
    expect(filterAndSortIssues(tied, DEFAULT_ISSUE_FILTERS).map((issue) => issue.title)).toEqual(['Alpha', 'Beta', 'Other', 'Zebra'])
  })

  it('supports oldest, recently updated, title, and priority ordering', () => {
    expect(filterAndSortIssues(issues, { ...DEFAULT_ISSUE_FILTERS, sort: 'oldest' }).map((issue) => issue.id)).toEqual(['a', 'c', 'b', 'd'])
    expect(filterAndSortIssues(issues, { ...DEFAULT_ISSUE_FILTERS, sort: 'updated' }).map((issue) => issue.id)).toEqual(['c', 'd', 'b', 'a'])
    expect(filterAndSortIssues(issues, { ...DEFAULT_ISSUE_FILTERS, sort: 'title' }).map((issue) => issue.id)).toEqual(['b', 'c', 'd', 'a'])
    expect(filterAndSortIssues(issues, { ...DEFAULT_ISSUE_FILTERS, sort: 'priority' }).map((issue) => issue.id)).toEqual(['b', 'd', 'c', 'a'])
  })

  it('sorts titles case-insensitively and uses ids for exact ties', () => {
    const tied = [
      { ...issues[0], id: 'z', title: 'alpha' },
      { ...issues[1], id: 'a', title: 'Alpha' },
      { ...issues[2], id: 'm', title: 'Alpha' },
    ]

    expect(filterAndSortIssues(tied, { ...DEFAULT_ISSUE_FILTERS, sort: 'title' }).map((issue) => issue.id)).toEqual(['a', 'm', 'z'])
  })

  it('places invalid dates after valid dates without mutating the input', () => {
    const dated = [
      { ...issues[0], id: 'invalid', created_at: 'not-a-date' },
      { ...issues[1], id: 'valid', created_at: '2026-04-01T00:00:00Z' },
    ]

    expect(filterAndSortIssues(dated, DEFAULT_ISSUE_FILTERS).map((issue) => issue.id)).toEqual(['valid', 'invalid'])
    expect(dated[0].id).toBe('invalid')
  })

  it('does not mutate the fetched list', () => {
    const original = [...issues]
    filterAndSortIssues(issues, { ...DEFAULT_ISSUE_FILTERS, sort: 'title' })
    expect(issues).toEqual(original)
  })
})
