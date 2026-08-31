import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { describe, expect, it, vi } from 'vitest'

import { useProject } from '../../hooks/use-project'
import { useProjectActivity } from '../../hooks/use-project-activity'
import { useProjectIssues } from '../../hooks/use-project-issues'
import type { ActivityLog, Issue, Project } from '../../types/domain'
import { ProjectDetailPage } from './project-detail-page'

vi.mock('../../hooks/use-project', () => ({ useProject: vi.fn() }))
vi.mock('../../hooks/use-project-activity', () => ({ useProjectActivity: vi.fn() }))
vi.mock('../../hooks/use-project-issues', () => ({ useProjectIssues: vi.fn() }))

const project: Project = { id: 'project-1', owner_id: 'owner-1', name: 'Makko', description: null, tags: [], created_at: '2026-01-01T00:00:00Z', updated_at: '2026-01-01T00:00:00Z' }
const issue: Issue = { id: 'issue-1', project_id: 'project-1', title: 'Fix auth', description: null, type: 'bug', priority: 'high', status: 'todo', created_at: '2026-01-01T00:00:00Z', updated_at: '2026-01-01T00:00:00Z' }
const event: ActivityLog = { id: 'event-1', project_id: 'project-1', issue_id: issue.id, action: 'issue.created', description: 'Issue created: "Fix auth"', created_at: '2026-01-01T00:00:00Z' }

describe('ProjectDetailPage', () => {
  it('closes the create form before opening an issue editor', async () => {
    vi.mocked(useProject).mockReturnValue({ project, status: 'ready', error: null, isMutating: false, refresh: vi.fn(async () => undefined), updateProject: vi.fn(async () => project), deleteProject: vi.fn(async () => false) })
    vi.mocked(useProjectIssues).mockReturnValue({ issues: [issue], status: 'ready', error: null, isMutating: false, refresh: vi.fn(async () => undefined), createIssue: vi.fn(async () => issue), updateIssue: vi.fn(async () => issue), deleteIssue: vi.fn(async () => true) })
    vi.mocked(useProjectActivity).mockReturnValue({ activity: [event], status: 'ready', error: null, refresh: vi.fn(async () => undefined) })
    const user = userEvent.setup()
    render(<MemoryRouter initialEntries={['/app/projects/project-1']}><Routes><Route path="/app/projects/:projectId" element={<ProjectDetailPage />} /></Routes></MemoryRouter>)

    await user.click(screen.getByRole('button', { name: 'New issue' }))
    expect(screen.getByRole('heading', { name: 'Create an issue' })).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'Edit' }))

    expect(screen.getByRole('heading', { name: 'Edit issue' })).toBeInTheDocument()
    expect(screen.queryByRole('heading', { name: 'Create an issue' })).not.toBeInTheDocument()
    expect(screen.getAllByLabelText('Title')).toHaveLength(1)
  })
})
