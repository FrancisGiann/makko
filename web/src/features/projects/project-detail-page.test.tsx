import { render, screen, within } from '@testing-library/react'
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
vi.mock('../github/project-github-section', () => ({ ProjectGithubSection: () => null }))

const project: Project = { id: 'project-1', owner_id: 'owner-1', name: 'Makko', description: null, tags: [], created_at: '2026-01-01T00:00:00Z', updated_at: '2026-01-01T00:00:00Z' }
const issue: Issue = { id: 'issue-1', project_id: 'project-1', title: 'Fix auth', description: null, type: 'bug', priority: 'high', status: 'todo', created_at: '2026-01-01T00:00:00Z', updated_at: '2026-01-01T00:00:00Z' }
const event: ActivityLog = { id: 'event-1', project_id: 'project-1', issue_id: issue.id, action: 'issue.created', description: 'Issue created: "Fix auth"', created_at: '2026-01-01T00:00:00Z' }

describe('ProjectDetailPage', () => {
  it('closes the create form before opening an issue editor', async () => {
    vi.mocked(useProject).mockReturnValue({ project, status: 'ready', error: null, isMutating: false, refresh: vi.fn(async () => undefined), updateProject: vi.fn(async () => project), deleteProject: vi.fn(async () => false) })
    vi.mocked(useProjectIssues).mockReturnValue({ issues: [issue], total: 1, page: 1, pageSize: 5, pageCount: 1, status: 'ready', error: null, isMutating: false, refresh: vi.fn(async () => undefined), setPage: vi.fn(), createIssue: vi.fn(async () => issue), updateIssue: vi.fn(async () => issue), deleteIssue: vi.fn(async () => true) })
    vi.mocked(useProjectActivity).mockReturnValue({ activity: [event], scope: 'last_30_days', page: 1, hasMore: false, isLoadingMore: false, status: 'ready', error: null, refresh: vi.fn(async () => undefined), setScope: vi.fn(), loadMore: vi.fn(async () => undefined) })
    const user = userEvent.setup()
    render(<MemoryRouter initialEntries={['/app/projects/project-1']}><Routes><Route path="/app/projects/:projectId" element={<ProjectDetailPage />} /></Routes></MemoryRouter>)

    expect(screen.getByRole('img', { name: 'Makko project identity' })).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'New issue' }))
    expect(screen.getByRole('heading', { name: 'Create an issue' })).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'Edit' }))

    expect(screen.getByRole('heading', { name: 'Edit issue' })).toBeInTheDocument()
    expect(screen.queryByRole('heading', { name: 'Create an issue' })).not.toBeInTheDocument()
    expect(screen.getAllByLabelText('Title')).toHaveLength(1)
  })

  it('changes an issue status inline with its existing fields without entering edit mode', async () => {
    const openIssue: Issue = { ...issue, description: 'Keep the original context' }
    const updateIssue = vi.fn(async () => ({ ...openIssue, status: 'in_progress' as const }))
    const refresh = vi.fn(async () => undefined)
    vi.mocked(useProject).mockReturnValue({ project, status: 'ready', error: null, isMutating: false, refresh: vi.fn(async () => undefined), updateProject: vi.fn(async () => project), deleteProject: vi.fn(async () => false) })
    vi.mocked(useProjectIssues).mockReturnValue({ issues: [openIssue], total: 1, page: 1, pageSize: 5, pageCount: 1, status: 'ready', error: null, isMutating: false, refresh: vi.fn(async () => undefined), setPage: vi.fn(), createIssue: vi.fn(async () => openIssue), updateIssue, deleteIssue: vi.fn(async () => true) })
    vi.mocked(useProjectActivity).mockReturnValue({ activity: [event], scope: 'last_30_days', page: 1, hasMore: false, isLoadingMore: false, status: 'ready', error: null, refresh, setScope: vi.fn(), loadMore: vi.fn(async () => undefined) })

    const user = userEvent.setup()
    render(<MemoryRouter initialEntries={['/app/projects/project-1']}><Routes><Route path="/app/projects/:projectId" element={<ProjectDetailPage />} /></Routes></MemoryRouter>)

    const statusSelect = screen.getByRole('combobox', { name: 'Status for Fix auth' })
    expect(statusSelect).toHaveValue('todo')
    expect(within(statusSelect).getByRole('option', { name: 'To do' })).toBeInTheDocument()
    expect(within(statusSelect).getByRole('option', { name: 'In progress' })).toBeInTheDocument()
    expect(within(statusSelect).getByRole('option', { name: 'Done' })).toBeInTheDocument()

    await user.selectOptions(statusSelect, 'in_progress')

    expect(updateIssue).toHaveBeenCalledWith('issue-1', {
      title: 'Fix auth',
      description: 'Keep the original context',
      type: 'bug',
      priority: 'high',
      status: 'in_progress',
    })
    expect(refresh).toHaveBeenCalled()
    expect(screen.queryByRole('heading', { name: 'Edit issue' })).not.toBeInTheDocument()
  })

  it('shows project loading, unavailable, and empty issue states', async () => {
    vi.mocked(useProject).mockReturnValue({ project: null, status: 'loading', error: null, isMutating: false, refresh: vi.fn(async () => undefined), updateProject: vi.fn(async () => null), deleteProject: vi.fn(async () => false) })
    const loadingView = render(<MemoryRouter initialEntries={['/app/projects/project-1']}><Routes><Route path="/app/projects/:projectId" element={<ProjectDetailPage />} /></Routes></MemoryRouter>)
    expect(screen.getByRole('status')).toHaveTextContent('Loading project')
    loadingView.unmount()

    vi.mocked(useProject).mockReturnValue({ project: null, status: 'error', error: 'Project is unavailable.', isMutating: false, refresh: vi.fn(async () => undefined), updateProject: vi.fn(async () => null), deleteProject: vi.fn(async () => false) })
    const errorView = render(<MemoryRouter initialEntries={['/app/projects/project-1']}><Routes><Route path="/app/projects/:projectId" element={<ProjectDetailPage />} /></Routes></MemoryRouter>)
    expect(screen.getByRole('alert')).toHaveTextContent('Project is unavailable.')
    errorView.unmount()

    vi.mocked(useProject).mockReturnValue({ project, status: 'ready', error: null, isMutating: false, refresh: vi.fn(async () => undefined), updateProject: vi.fn(async () => project), deleteProject: vi.fn(async () => false) })
    vi.mocked(useProjectIssues).mockReturnValue({ issues: [], total: 0, page: 1, pageSize: 5, pageCount: 0, status: 'ready', error: null, isMutating: false, refresh: vi.fn(async () => undefined), setPage: vi.fn(), createIssue: vi.fn(async () => null), updateIssue: vi.fn(async () => null), deleteIssue: vi.fn(async () => false) })
    vi.mocked(useProjectActivity).mockReturnValue({ activity: [], scope: 'last_30_days', page: 1, hasMore: false, isLoadingMore: false, status: 'ready', error: null, refresh: vi.fn(async () => undefined), setScope: vi.fn(), loadMore: vi.fn(async () => undefined) })
    render(<MemoryRouter initialEntries={['/app/projects/project-1']}><Routes><Route path="/app/projects/:projectId" element={<ProjectDetailPage />} /></Routes></MemoryRouter>)
    expect(await screen.findByText('No issues yet.')).toBeInTheDocument()
    expect(screen.getByText('No activity in the last 30 days.')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Repository commits' })).not.toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Makko changes' })).not.toBeInTheDocument()
    expect(screen.queryByRole('img', { name: /activity heatmap/i })).not.toBeInTheDocument()

    const user = userEvent.setup()
    await user.selectOptions(screen.getByRole('combobox', { name: 'Priority' }), 'high')
    expect(screen.getByText('No issues match these filters.')).toBeInTheDocument()
    expect(screen.getByText('Try widening the filters.')).toBeInTheDocument()
  })

  it('keeps a failed issue create visible and reports the mutation error', async () => {
    const createIssue = vi.fn(async () => null)
    vi.mocked(useProject).mockReturnValue({ project, status: 'ready', error: null, isMutating: false, refresh: vi.fn(async () => undefined), updateProject: vi.fn(async () => project), deleteProject: vi.fn(async () => false) })
    vi.mocked(useProjectIssues).mockReturnValue({ issues: [], total: 0, page: 1, pageSize: 5, pageCount: 0, status: 'ready', error: 'Issue could not be created.', isMutating: false, refresh: vi.fn(async () => undefined), setPage: vi.fn(), createIssue, updateIssue: vi.fn(async () => null), deleteIssue: vi.fn(async () => false) })
    vi.mocked(useProjectActivity).mockReturnValue({ activity: [], scope: 'last_30_days', page: 1, hasMore: false, isLoadingMore: false, status: 'ready', error: null, refresh: vi.fn(async () => undefined), setScope: vi.fn(), loadMore: vi.fn(async () => undefined) })
    const user = userEvent.setup()
    render(<MemoryRouter initialEntries={['/app/projects/project-1']}><Routes><Route path="/app/projects/:projectId" element={<ProjectDetailPage />} /></Routes></MemoryRouter>)

    await user.click(screen.getByRole('button', { name: 'New issue' }))
    await user.type(screen.getByLabelText('Title'), 'Broken issue')
    await user.click(screen.getByRole('button', { name: 'Create issue' }))

    expect(createIssue).toHaveBeenCalledWith({ title: 'Broken issue', description: '', type: 'task', priority: 'medium', status: 'todo' })
    expect(screen.getByRole('heading', { name: 'Create an issue' })).toBeInTheDocument()
    expect(screen.getByRole('alert')).toHaveTextContent('Issue could not be created.')
  })

  it('exposes activity scope and server issue pagination controls', async () => {
    const setScope = vi.fn()
    const loadMore = vi.fn(async () => undefined)
    const setPage = vi.fn()
    vi.mocked(useProject).mockReturnValue({ project, status: 'ready', error: null, isMutating: false, refresh: vi.fn(async () => undefined), updateProject: vi.fn(async () => project), deleteProject: vi.fn(async () => false) })
    vi.mocked(useProjectIssues).mockReturnValue({ issues: [issue], total: 11, page: 1, pageSize: 5, pageCount: 3, status: 'ready', error: null, isMutating: false, refresh: vi.fn(async () => undefined), setPage, createIssue: vi.fn(async () => issue), updateIssue: vi.fn(async () => issue), deleteIssue: vi.fn(async () => true) })
    vi.mocked(useProjectActivity).mockReturnValue({ activity: [event], scope: 'last_30_days', page: 1, hasMore: true, isLoadingMore: false, status: 'ready', error: null, refresh: vi.fn(async () => undefined), setScope, loadMore })

    const user = userEvent.setup()
    render(<MemoryRouter initialEntries={['/app/projects/project-1']}><Routes><Route path="/app/projects/:projectId" element={<ProjectDetailPage />} /></Routes></MemoryRouter>)

    expect(screen.getByText('Showing 1–5 of 11')).toBeInTheDocument()
    expect(screen.getByText('Page 1 of 3')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'Next' }))
    expect(setPage).toHaveBeenCalledWith(2)
    await user.click(screen.getByRole('button', { name: 'All time' }))
    expect(setScope).toHaveBeenCalledWith('all_time')
    await user.click(screen.getByRole('button', { name: 'Load more activity' }))
    expect(loadMore).toHaveBeenCalled()
  })
})
