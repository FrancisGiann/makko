import { act, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { describe, expect, it, vi } from 'vitest'

import { AuthProvider } from '../auth/auth-context'
import { createFakeAuthService, createSession } from '../../test/test-auth'
import type { DashboardService, DashboardStats } from '../../services/dashboard.service'
import { DashboardPage } from './dashboard-page'

const stats = {
  projectCount: 1,
  totalIssues: 3,
  openIssues: 2,
  completedIssues: 1,
  byStatus: { todo: 1, in_progress: 1, done: 1 },
  byType: { task: 2, bug: 1 },
  byPriority: { low: 1, medium: 1, high: 1 },
  projects: [{ id: 'project-1', name: 'Makko', total: 3, open: 2, completed: 1 }],
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
    expect(screen.getByText('To do + in progress')).toBeInTheDocument()
    expect(screen.queryByText('External · read-only')).not.toBeInTheDocument()
  })

  it('shows a useful empty state', async () => {
    const service: DashboardService = { getStats: vi.fn(async () => ({ ...stats, projectCount: 0, totalIssues: 0, openIssues: 0, completedIssues: 0, byStatus: { todo: 0, in_progress: 0, done: 0 }, byType: { task: 0, bug: 0 }, byPriority: { low: 0, medium: 0, high: 0 }, projects: [] })) }
    renderPage(service)

    expect(await screen.findByText('Your dashboard is ready for its first project.')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Go to projects' })).toHaveAttribute('href', '/app')
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
})
