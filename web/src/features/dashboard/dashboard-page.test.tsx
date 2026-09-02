import { act, render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { describe, expect, it, vi } from 'vitest'

import { AuthProvider } from '../auth/auth-context'
import { createFakeAuthService, createSession } from '../../test/test-auth'
import type { DashboardService, DashboardStats } from '../../services/dashboard.service'
import { DashboardPage } from './dashboard-page'
import { githubUsernameStorageKey, loadGithubUsername, normalizeGithubUsername } from '../../utils/github-username'

vi.mock('react-github-calendar', () => ({
  GitHubCalendar: () => <div data-testid="github-calendar" />,
}))

const stats: DashboardStats = {
  projectCount: 1,
  totalIssues: 3,
  openIssues: 2,
  completedIssues: 1,
  byStatus: { todo: 1, in_progress: 1, done: 1 },
  byType: { task: 2, bug: 1 },
  byPriority: { low: 1, medium: 1, high: 1 },
  projects: [{ id: 'project-1', name: 'Makko', total: 3, open: 2, completed: 1 }],
  issues: [
    { id: 'issue-1', title: 'Fix launch bug', project_id: 'project-1', projectName: 'Makko', type: 'task', priority: 'high', status: 'todo', updated_at: '2026-01-03T00:00:00Z' },
    { id: 'issue-2', title: 'Document release', project_id: 'project-1', projectName: 'Makko', type: 'bug', priority: 'medium', status: 'in_progress', updated_at: '2026-01-02T00:00:00Z' },
    { id: 'issue-3', title: 'Check auth flow', project_id: 'project-1', projectName: 'Makko', type: 'task', priority: 'low', status: 'done', updated_at: '2026-01-01T00:00:00Z' },
  ],
}

function renderPage(service: DashboardService) {
  return render(<AuthProvider service={createFakeAuthService(createSession())}><MemoryRouter><DashboardPage service={service} /></MemoryRouter></AuthProvider>)
}

describe('DashboardPage', () => {
  it('renders internal issue totals and labels the source boundary', async () => {
    const service: DashboardService = { getStats: vi.fn(async () => stats) }
    renderPage(service)

    expect(await screen.findByRole('heading', { name: 'Dashboard' })).toBeInTheDocument()
    expect(screen.getByText(/Counts below include internal Makko issues only/)).toBeInTheDocument()
    expect(await screen.findByText('Internal Makko issues')).toBeInTheDocument()
    expect(screen.getByRole('progressbar', { name: 'Internal issue completion' })).toHaveAttribute('aria-valuenow', '33')
    expect(screen.getByRole('progressbar', { name: 'Internal issue completion' })).toHaveAttribute('aria-valuetext', '1 of 3 internal issues complete (33%)')
    expect(screen.getByText('To do + in progress')).toBeInTheDocument()
    expect(screen.getByText('External · read-only')).toBeInTheDocument()
    expect(screen.getByText(/never affects internal dashboard stats/)).toBeInTheDocument()
  })

  it('shows a useful empty state', async () => {
    const service: DashboardService = { getStats: vi.fn(async () => ({ ...stats, projectCount: 0, totalIssues: 0, openIssues: 0, completedIssues: 0, byStatus: { todo: 0, in_progress: 0, done: 0 }, byType: { task: 0, bug: 0 }, byPriority: { low: 0, medium: 0, high: 0 }, projects: [], issues: [] })) }
    renderPage(service)

    expect(await screen.findByText('Your dashboard is ready for its first project.')).toBeInTheDocument()
    expect(screen.getByRole('progressbar', { name: 'Internal issue completion' })).toHaveAttribute('aria-valuetext', 'No internal issues yet. (0%)')
    expect(screen.getByRole('link', { name: 'Go to projects' })).toHaveAttribute('href', '/app')
  })

  it('opens matching internal issue and project details from a breakdown row', async () => {
    const user = userEvent.setup()
    const service: DashboardService = { getStats: vi.fn(async () => stats) }
    renderPage(service)

    const highPriority = await screen.findByRole('button', { name: /High, 1 internal issue, show issue details/i })
    expect(highPriority).toHaveAttribute('aria-pressed', 'false')
    await user.click(highPriority)

    const panel = screen.getByRole('region', { name: 'High priority' })
    expect(panel).toHaveTextContent('Internal Makko issues from your projects')
    expect(panel).toHaveTextContent('Fix launch bug')
    expect(panel).toHaveTextContent('Project: Makko')
    expect(panel).not.toHaveTextContent('Document release')
    expect(panel).not.toHaveTextContent('Check auth flow')
    expect(within(panel).getByRole('link', { name: 'Open project issues' })).toHaveAttribute('href', '/app/projects/project-1#issues-heading')
    expect(highPriority).toHaveAttribute('aria-pressed', 'true')
  })

  it('updates drill-down details when selecting status and type', async () => {
    const user = userEvent.setup()
    const service: DashboardService = { getStats: vi.fn(async () => stats) }
    renderPage(service)

    await user.click(await screen.findByRole('button', { name: /In progress, 1 internal issue, show issue details/i }))
    let panel = screen.getByRole('region', { name: 'In progress' })
    expect(panel).toHaveTextContent('Document release')
    expect(panel).not.toHaveTextContent('Fix launch bug')

    await user.click(screen.getByRole('button', { name: /Bugs, 1 internal issue, show issue details/i }))
    panel = screen.getByRole('region', { name: 'Bugs' })
    expect(panel).toHaveTextContent('Document release')
    expect(panel).toHaveTextContent('Bug')
  })

  it('toggles or closes selected breakdown details and disables zero-count rows', async () => {
    const user = userEvent.setup()
    const service: DashboardService = { getStats: vi.fn(async () => stats) }
    renderPage(service)

    const highPriority = await screen.findByRole('button', { name: /High, 1 internal issue, show issue details/i })
    await user.click(highPriority)
    expect(screen.getByRole('region', { name: 'High priority' })).toBeInTheDocument()
    await user.click(highPriority)
    expect(screen.queryByRole('region', { name: 'High priority' })).not.toBeInTheDocument()

    const emptyStats = { ...stats, totalIssues: 0, openIssues: 0, completedIssues: 0, byStatus: { todo: 0, in_progress: 0, done: 0 }, byType: { task: 0, bug: 0 }, byPriority: { low: 0, medium: 0, high: 0 }, issues: [] }
    const emptyService: DashboardService = { getStats: vi.fn(async () => emptyStats) }
    const emptyView = renderPage(emptyService)
    const zeroHighPriority = await screen.findByRole('button', { name: /High, 0 internal issues/i })
    expect(zeroHighPriority).toBeDisabled()
    expect(screen.queryByRole('region', { name: 'High priority' })).not.toBeInTheDocument()
    emptyView.unmount()
  })

  it('shows loading, then recovers from an error after retry', async () => {
    let resolveStats: ((value: typeof stats) => void) | undefined
    const service: DashboardService = { getStats: vi.fn(() => new Promise<DashboardStats>((resolve) => { resolveStats = resolve })) }
    const firstView = renderPage(service)

    await waitFor(() => expect(service.getStats).toHaveBeenCalled())
    expect(screen.getByRole('status')).toHaveTextContent('Loading your dashboard')
    await act(async () => { resolveStats?.(stats) })
    expect(await screen.findByText('All issues')).toBeInTheDocument()
    firstView.unmount()

    let attempts = 0
    const retryService: DashboardService = { getStats: vi.fn(async () => { attempts += 1; if (attempts === 1) throw new Error('Dashboard unavailable'); return stats }) }
    const { unmount } = renderPage(retryService)
    expect(await screen.findByRole('alert')).toHaveTextContent('Dashboard unavailable')
    await userEvent.click(screen.getByRole('button', { name: 'Refresh stats' }))
    await waitFor(() => expect(retryService.getStats).toHaveBeenCalledTimes(2))
    expect(await screen.findByText('All issues')).toBeInTheDocument()
    unmount()
  })

  it('validates GitHub usernames and scopes persisted values to the signed-in user', () => {
    localStorage.clear()
    const userA = createSession('alice@example.com').user.id
    const userB = '00000000-0000-0000-0000-000000000002'
    const userAKey = githubUsernameStorageKey(userA)

    expect(normalizeGithubUsername(' octocat ')).toBe('octocat')
    expect(normalizeGithubUsername('bad/name')).toBeNull()
    expect(userAKey).toBeTruthy()

    localStorage.setItem('makko_github_username', 'legacy-user')
    localStorage.setItem(userAKey!, ' octocat ')
    expect(loadGithubUsername(userA)).toBe('octocat')
    expect(loadGithubUsername(userB)).toBe('')
    expect(localStorage.getItem('makko_github_username')).toBeNull()

    localStorage.setItem(userAKey!, 'bad/name')
    expect(loadGithubUsername(userA)).toBe('')
    localStorage.clear()
  })

  it('shows the public GitHub source and clears the saved username', async () => {
    localStorage.clear()
    const user = createSession().user.id
    localStorage.setItem(githubUsernameStorageKey(user)!, 'octocat')
    const service: DashboardService = { getStats: vi.fn(async () => stats) }
    const userEventInstance = userEvent.setup()
    renderPage(service)

    expect(await screen.findByText('Public GitHub profile activity')).toBeInTheDocument()
    const profileLink = screen.getByRole('link', { name: 'View @octocat on GitHub' })
    expect(profileLink).toHaveAttribute('href', 'https://github.com/octocat')
    expect(profileLink).toHaveAttribute('target', '_blank')
    expect(profileLink).toHaveAttribute('rel', 'noreferrer')
    await userEventInstance.click(screen.getByRole('button', { name: 'Remove GitHub username' }))

    expect(localStorage.getItem(githubUsernameStorageKey(user)!)).toBeNull()
    expect(screen.queryByRole('link', { name: 'View @octocat on GitHub' })).not.toBeInTheDocument()
    expect(screen.getByRole('textbox', { name: 'GitHub Username' })).toHaveValue('')
    localStorage.clear()
  })
})
