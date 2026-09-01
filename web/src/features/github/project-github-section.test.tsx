import { fireEvent, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'

import { useProjectGithub } from '../../hooks/use-project-github'
import type { GithubCommit, GithubIssue } from '../../types/domain'
import { GITHUB_REPOSITORY_PATTERN, ProjectGithubSection } from './project-github-section'

vi.mock('../../hooks/use-project-github', () => ({ useProjectGithub: vi.fn() }))

const commit: GithubCommit = {
  id: 'commit-1', github_link_id: 'link-1', sha: 'a'.repeat(40), message: 'Improve docs\n\nMore context', author_name: 'Builder', author_login: 'builder', committed_at: '2026-01-01T00:00:00Z', html_url: 'https://github.com/makko/web/commit/abc', synced_at: '2026-01-01T00:00:00Z',
}
const issue: GithubIssue = {
  id: 'issue-1', github_link_id: 'link-1', github_node_id: 'node-1', number: 12, title: 'Track release', state: 'open', author_login: 'builder', labels: ['release'], github_created_at: '2026-01-01T00:00:00Z', github_updated_at: '2026-01-02T00:00:00Z', html_url: 'https://github.com/makko/web/issues/12', synced_at: '2026-01-02T00:00:00Z',
}

function baseGithubState(overrides: Partial<ReturnType<typeof useProjectGithub>> = {}) {
  return {
    link: { id: 'link-1', project_id: 'project-1', repo_full_name: 'makko/web', last_synced_at: '2026-01-02T00:00:00Z', sync_lease_token: null, sync_lease_expires_at: null, created_at: '2026-01-01T00:00:00Z' },
    commits: [commit], issues: [issue], status: 'ready' as const, error: null, isMutating: false, refresh: vi.fn(async () => undefined), connect: vi.fn(async () => null), disconnect: vi.fn(async () => false), sync: vi.fn(async () => null), cooldownSeconds: 0,
    ...overrides,
  }
}

describe('ProjectGithubSection', () => {
  it('keeps synchronized GitHub data read-only and links safely outside Makko', () => {
    vi.mocked(useProjectGithub).mockReturnValue(baseGithubState())
    render(<ProjectGithubSection projectId="project-1" />)

    const commitLink = screen.getByRole('link', { name: 'Improve docs' })
    const issueLink = screen.getByRole('link', { name: '#12 Track release' })
    expect(commitLink).toHaveAttribute('target', '_blank')
    expect(commitLink).toHaveAttribute('rel', 'noreferrer')
    expect(issueLink).toHaveAttribute('target', '_blank')
    expect(screen.getByText('External / read-only')).toBeInTheDocument()
    expect(screen.getByText('External · read-only')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /edit/i })).not.toBeInTheDocument()
  })

  it('paginates the ten most recent commits five at a time', async () => {
    const commits = Array.from({ length: 10 }, (_, index) => ({ ...commit, id: `commit-${index + 1}`, message: `Commit ${index + 1}` }))
    vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ commits }))
    render(<ProjectGithubSection projectId="project-1" />)

    const user = userEvent.setup()
    const previous = screen.getByRole('button', { name: 'Previous' })
    const next = screen.getByRole('button', { name: 'Next' })
    expect(screen.getByText('Page 1 of 2')).toBeInTheDocument()
    expect(previous).toBeDisabled()
    expect(next).toBeEnabled()
    expect(screen.getByRole('link', { name: 'Commit 1' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Commit 5' })).toBeInTheDocument()
    expect(screen.queryByRole('link', { name: 'Commit 6' })).not.toBeInTheDocument()

    await user.click(next)
    expect(screen.getByText('Page 2 of 2')).toBeInTheDocument()
    expect(previous).toBeEnabled()
    expect(next).toBeDisabled()
    expect(screen.getByRole('link', { name: 'Commit 6' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Commit 10' })).toBeInTheDocument()
    expect(screen.queryByRole('link', { name: 'Commit 1' })).not.toBeInTheDocument()

    await user.click(previous)
    expect(screen.getByText('Page 1 of 2')).toBeInTheDocument()
    expect(previous).toBeDisabled()
    expect(next).toBeEnabled()
    expect(screen.getByRole('link', { name: 'Commit 1' })).toBeInTheDocument()
  })

  it('resets the commit page when a new snapshot has fewer results', async () => {
    const commits = Array.from({ length: 10 }, (_, index) => ({ ...commit, id: `commit-${index + 1}`, message: `Commit ${index + 1}` }))
    vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ commits }))
    const view = render(<ProjectGithubSection projectId="project-1" />)
    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: 'Next' }))
    expect(screen.getByText('Page 2 of 2')).toBeInTheDocument()

    const refreshedCommits = commits.slice(0, 5).map((item) => ({ ...item, synced_at: '2026-01-03T00:00:00Z' }))
    vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ commits: refreshedCommits }))
    view.rerender(<ProjectGithubSection projectId="project-1" />)

    expect(screen.queryByText(/Page/)).not.toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Commit 1' })).toBeInTheDocument()
    expect(screen.queryByRole('link', { name: 'Commit 6' })).not.toBeInTheDocument()
  })

  it('shows a connect form for an unlinked project', () => {
    vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ link: null, commits: [], issues: [] }))
    render(<ProjectGithubSection projectId="project-1" />)

    expect(screen.getByRole('textbox', { name: 'Repository' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Connect repository' })).toBeInTheDocument()
  })

  it('uses a browser-compatible repository pattern and submits valid repositories', async () => {
    const connect = vi.fn(async () => ({ id: 'link-2', project_id: 'project-1', repo_full_name: 'makko/phase-two', last_synced_at: null, sync_lease_token: null, sync_lease_expires_at: null, created_at: '2026-01-01T00:00:00Z' }))
    vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ link: null, commits: [], issues: [], connect }))
    render(<ProjectGithubSection projectId="project-1" />)

    const input = screen.getByRole('textbox', { name: 'Repository' })
    expect(input).toHaveAttribute('pattern', GITHUB_REPOSITORY_PATTERN)
    expect(() => new RegExp(GITHUB_REPOSITORY_PATTERN, 'v')).not.toThrow()

    const user = userEvent.setup()
    await user.type(input, 'makko/phase-two')
    expect(input).toBeValid()
    await user.click(screen.getByRole('button', { name: 'Connect repository' }))

    expect(connect).toHaveBeenCalledWith('makko/phase-two')
    expect(await screen.findByRole('status')).toHaveTextContent('Connected makko/phase-two.')
  })

  it('validates a replacement before disconnecting the current repository', async () => {
    const connect = vi.fn(async () => null)
    const disconnect = vi.fn(async () => true)
    vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ connect, disconnect }))
    render(<ProjectGithubSection projectId="project-1" />)

    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: 'Change repository' }))
    const input = screen.getByRole('textbox', { name: 'New repository' }) as HTMLInputElement
    await user.type(input, 'not a repository')
    const form = input.form
    expect(form).not.toBeNull()
    if (!form) throw new Error('replacement form is missing')
    fireEvent.submit(form)

    expect(await screen.findByRole('alert')).toHaveTextContent('owner/name')
    expect(disconnect).not.toHaveBeenCalled()
    expect(connect).not.toHaveBeenCalled()
    expect(screen.getByRole('button', { name: 'Disconnect' })).toBeInTheDocument()
  })

  it('shows connection failures without hiding the connection form', async () => {
    const connect = vi.fn(async () => null)
    vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ link: null, commits: [], issues: [], connect, error: 'Connection refused.' }))
    render(<ProjectGithubSection projectId="project-1" />)

    const user = userEvent.setup()
    await user.type(screen.getByRole('textbox', { name: 'Repository' }), 'makko/phase-two')
    await user.click(screen.getByRole('button', { name: 'Connect repository' }))

    expect(connect).toHaveBeenCalledWith('makko/phase-two')
    expect(screen.getByRole('alert')).toHaveTextContent('Connection refused.')
    expect(screen.getByRole('textbox', { name: 'Repository' })).toBeInTheDocument()
  })

  it('reports a successful sync and keeps the data boundary read-only', async () => {
    const sync = vi.fn(async () => ({ project_id: 'project-1', repo_full_name: 'makko/web', commits_synced: 2, issues_synced: 3, last_synced_at: '2026-01-03T00:00:00Z' }))
    vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ sync }))
    render(<ProjectGithubSection projectId="project-1" />)

    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: 'Sync now' }))

    expect(sync).toHaveBeenCalledOnce()
    expect(await screen.findByRole('status')).toHaveTextContent('Synced 2 commits and 3 open issues.')
    expect(screen.getByText('External · read-only')).toBeInTheDocument()
  })

  it('shows sync errors while leaving the cached read-only view available', async () => {
    const sync = vi.fn(async () => null)
    vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ sync, error: 'GitHub is temporarily unavailable.' }))
    render(<ProjectGithubSection projectId="project-1" />)

    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: 'Sync now' }))

    expect(sync).toHaveBeenCalledOnce()
    expect(screen.getByRole('alert')).toHaveTextContent('GitHub is temporarily unavailable.')
    expect(screen.getByRole('link', { name: 'Improve docs' })).toBeInTheDocument()
  })

  it('shows the initial GitHub loading state', () => {
    vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ link: null, commits: [], issues: [], status: 'loading' }))
    render(<ProjectGithubSection projectId="project-1" />)

    expect(screen.getByRole('status')).toHaveTextContent('Loading GitHub data')
  })

  it('requires confirmation before disconnecting and reports a successful disconnect', async () => {
    const disconnect = vi.fn(async () => true)
    const originalConfirm = window.confirm
    window.confirm = vi.fn(() => false)
    try {
      vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ disconnect }))
      const { unmount } = render(<ProjectGithubSection projectId="project-1" />)
      const user = userEvent.setup()
      await user.click(screen.getByRole('button', { name: 'Disconnect' }))
      expect(window.confirm).toHaveBeenCalledWith(expect.stringContaining('Cached commits and issues will be removed.'))
      expect(disconnect).not.toHaveBeenCalled()
      unmount()

      window.confirm = vi.fn(() => true)
      vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ disconnect }))
      render(<ProjectGithubSection projectId="project-1" />)
      await user.click(screen.getByRole('button', { name: 'Disconnect' }))
      expect(disconnect).toHaveBeenCalledWith()
      expect(await screen.findByRole('status')).toHaveTextContent('GitHub repository disconnected.')
    } finally {
      window.confirm = originalConfirm
    }
  })

  it('shows the never-synced state', () => {
    vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ link: { ...baseGithubState().link!, last_synced_at: null }, commits: [], issues: [] }))
    render(<ProjectGithubSection projectId="project-1" />)
    expect(screen.getByText('Sync this repository to load recent commits.')).toBeInTheDocument()
    expect(screen.getByText('Sync this repository to load open issues.')).toBeInTheDocument()
  })

  it('marks cached GitHub data as stale after a day', () => {
    const oldSync = new Date(Date.now() - 2 * 24 * 60 * 60 * 1_000).toISOString()
    vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ link: { ...baseGithubState().link!, last_synced_at: oldSync }, commits: [], issues: [] }))
    render(<ProjectGithubSection projectId="project-1" />)
    expect(screen.getByText(/Cached data may be stale/)).toBeInTheDocument()
    expect(screen.getByText('No commits in the latest snapshot.')).toBeInTheDocument()
    expect(screen.getByText('No open GitHub issues in the latest snapshot.')).toBeInTheDocument()
  })

  it('shows a cooldown and error state while keeping sync disabled', () => {
    vi.mocked(useProjectGithub).mockReturnValue(baseGithubState({ error: 'This repository was synchronized recently.', cooldownSeconds: 42 }))
    render(<ProjectGithubSection projectId="project-1" />)

    expect(screen.getByRole('alert')).toHaveTextContent('This repository was synchronized recently.')
    expect(screen.getByRole('button', { name: 'Available in 42s' })).toBeDisabled()
  })
})
