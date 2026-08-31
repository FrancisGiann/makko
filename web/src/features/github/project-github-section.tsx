import { useState, type FormEvent } from 'react'

import { StatusMessage } from '../../components/status-message'
import { useProjectGithub } from '../../hooks/use-project-github'
import type { GithubService } from '../../services/github.service'
import type { GithubCommit, GithubIssue } from '../../types/domain'
import { normalizeGithubRepository } from '../../services/validation'

export const GITHUB_REPOSITORY_PATTERN = String.raw`[A-Za-z0-9][A-Za-z0-9\-]{0,38}/[A-Za-z0-9._\-]{1,100}`

interface ProjectGithubSectionProps {
  projectId: string
  service?: GithubService
}

function formatDate(value: string | null): string {
  if (!value) return 'Never synced'
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? 'Unknown sync time' : date.toLocaleString()
}

function isSafeGithubUrl(value: string): boolean {
  try {
    const url = new URL(value)
    return url.protocol === 'https:' && (url.hostname === 'github.com' || url.hostname.endsWith('.github.com'))
  } catch {
    return false
  }
}

function displayCommitMessage(commit: GithubCommit): string {
  const firstLine = commit.message.split('\n')[0]?.trim() ?? ''
  return firstLine || 'Untitled commit'
}

export function ProjectGithubSection({ projectId, service }: ProjectGithubSectionProps) {
  const github = useProjectGithub(projectId, service)
  const [repository, setRepository] = useState('')
  const [showConnectionForm, setShowConnectionForm] = useState(false)
  const [success, setSuccess] = useState<string | null>(null)
  const [connectionValidationError, setConnectionValidationError] = useState<string | null>(null)

  const hasLink = Boolean(github.link)
  const isLoading = github.status === 'loading' && !github.link
  const isStale = Boolean(github.link?.last_synced_at && Date.parse(github.link.last_synced_at) < Date.now() - 24 * 60 * 60 * 1_000)

  const handleConnect = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (github.isMutating) return
    setSuccess(null)
    setConnectionValidationError(null)
    let normalizedRepository: string
    try {
      normalizedRepository = normalizeGithubRepository(repository)
    } catch (caught) {
      setConnectionValidationError(caught instanceof Error ? caught.message : 'Use a GitHub repository in owner/name format.')
      return
    }
    if (github.link) {
      const confirmed = window.confirm(`Disconnect “${github.link.repo_full_name}” and connect “${normalizedRepository}” instead?`)
      if (!confirmed) return
      if (!(await github.disconnect())) return
    }
    const connected = await github.connect(normalizedRepository)
    if (connected) {
      setRepository('')
      setShowConnectionForm(false)
      setSuccess(`Connected ${connected.repo_full_name}.`)
    }
  }

  const handleDisconnect = async () => {
    if (!github.link || github.isMutating) return
    if (!window.confirm(`Disconnect “${github.link.repo_full_name}”? Cached commits and issues will be removed.`)) return
    setSuccess(null)
    if (await github.disconnect()) setSuccess('GitHub repository disconnected.')
  }

  const handleSync = async () => {
    setSuccess(null)
    const result = await github.sync()
    if (result) setSuccess(`Synced ${result.commits_synced} commits and ${result.issues_synced} open issues.`)
  }

  if (isLoading) {
    return <section className="rounded-3xl border border-white/10 bg-slate-900/50 p-6 sm:p-8" aria-labelledby="github-heading"><p className="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-200">External activity</p><h2 id="github-heading" className="mt-2 text-xl font-semibold text-white">GitHub repository</h2><p className="mt-6 text-sm text-slate-400" role="status">Loading GitHub data…</p></section>
  }

  return (
    <section className="rounded-3xl border border-white/10 bg-slate-900/50 p-6 sm:p-8" aria-labelledby="github-heading">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-start">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-200">External activity</p>
          <h2 id="github-heading" className="mt-2 text-xl font-semibold text-white">GitHub repository</h2>
          <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-400">Read-only commits and open issues from one connected repository. GitHub issues never affect Makko totals.</p>
        </div>
        {hasLink && (
          <div className="flex shrink-0 flex-wrap gap-2">
            <button type="button" onClick={() => { setShowConnectionForm((visible) => !visible); setRepository('') }} className="rounded-lg border border-white/15 px-3 py-2 text-sm text-slate-200 transition hover:border-cyan-200/40 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">{showConnectionForm ? 'Cancel change' : 'Change repository'}</button>
            <button type="button" onClick={() => void handleDisconnect()} disabled={github.isMutating} className="rounded-lg px-3 py-2 text-sm text-rose-200/80 transition hover:text-rose-100 disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-rose-200">Disconnect</button>
          </div>
        )}
      </div>

      {connectionValidationError && <div className="mt-6"><StatusMessage kind="error">{connectionValidationError}</StatusMessage></div>}
      {github.error && <div className="mt-6"><StatusMessage kind="error">{github.error}</StatusMessage><button type="button" onClick={() => void github.refresh()} className="mt-3 rounded-lg border border-white/15 px-3 py-2 text-sm text-slate-200 hover:border-cyan-200/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">Retry GitHub data</button></div>}
      {success && <div className="mt-6"><StatusMessage kind="success">{success}</StatusMessage></div>}
      {github.status === 'loading' && github.link && <p className="mt-6 text-sm text-slate-400" role="status">Refreshing GitHub data…</p>}

      {(!hasLink || showConnectionForm) && (
        <form className="mt-6 rounded-2xl border border-cyan-200/15 bg-slate-950/40 p-4 sm:p-5" onSubmit={(event) => void handleConnect(event)}>
          <label htmlFor="github-repository" className="mb-2 block text-sm font-medium text-slate-200">{hasLink ? 'New repository' : 'Repository'}</label>
          <div className="flex flex-col gap-3 sm:flex-row">
            <input id="github-repository" value={repository} onChange={(event) => { setRepository(event.target.value); setConnectionValidationError(null) }} required pattern={GITHUB_REPOSITORY_PATTERN} maxLength={140} placeholder="owner/repository" aria-describedby="github-repository-help" aria-invalid={Boolean(connectionValidationError)} className="min-w-0 flex-1 rounded-xl border border-white/15 bg-slate-950/70 px-4 py-3 text-sm text-white outline-none transition placeholder:text-slate-600 focus:border-cyan-200/60 focus:ring-2 focus:ring-cyan-200/20" />
            <button type="submit" disabled={github.isMutating} className="rounded-xl bg-cyan-200 px-4 py-3 text-sm font-semibold text-slate-950 transition hover:bg-cyan-100 disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-100">{github.isMutating ? 'Connecting…' : hasLink ? 'Connect replacement' : 'Connect repository'}</button>
          </div>
          <p id="github-repository-help" className="mt-2 text-xs leading-5 text-slate-500">Use the public GitHub owner/repository name. Makko checks the repository when you sync.</p>
        </form>
      )}

      {hasLink && !showConnectionForm && github.link && (
        <>
          <div className="mt-6 flex flex-col gap-4 rounded-2xl border border-white/10 bg-slate-950/35 p-4 sm:flex-row sm:items-center sm:justify-between sm:p-5">
            <div className="min-w-0">
              {isSafeGithubUrl(`https://github.com/${github.link.repo_full_name}`) ? <a href={`https://github.com/${github.link.repo_full_name}`} target="_blank" rel="noreferrer" className="break-all font-medium text-cyan-100 underline decoration-cyan-200/30 underline-offset-4 hover:decoration-cyan-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">{github.link.repo_full_name}</a> : <p className="break-all font-medium text-white">{github.link.repo_full_name}</p>}
              <p className="mt-1 text-xs text-slate-500">{github.link.last_synced_at ? `Last synced ${formatDate(github.link.last_synced_at)}` : 'Not synced yet'}{isStale ? ' · Cached data may be stale' : ''}</p>
            </div>
            <button type="button" onClick={() => void handleSync()} disabled={github.status === 'loading' || github.isMutating || github.cooldownSeconds > 0} className="shrink-0 rounded-xl bg-cyan-200 px-4 py-3 text-sm font-semibold text-slate-950 transition hover:bg-cyan-100 disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-100">
              {github.isMutating ? 'Syncing…' : github.cooldownSeconds > 0 ? `Available in ${github.cooldownSeconds}s` : 'Sync now'}
            </button>
          </div>

          <div className="mt-7 grid gap-7 xl:grid-cols-2">
            <GithubCommitList key={`${github.link.id}:${github.link.repo_full_name}:${github.link.last_synced_at ?? 'never'}:${github.commits.map((commit) => `${commit.id}:${commit.synced_at}`).join('|')}`} commits={github.commits} neverSynced={!github.link.last_synced_at} />
            <GithubIssueList issues={github.issues} neverSynced={!github.link.last_synced_at} />
          </div>
        </>
      )}
    </section>
  )
}

const COMMITS_PER_PAGE = 5

function GithubCommitList({ commits, neverSynced }: { commits: GithubCommit[]; neverSynced: boolean }) {
  const [requestedPage, setRequestedPage] = useState(1)
  const pageCount = Math.max(1, Math.ceil(commits.length / COMMITS_PER_PAGE))
  const page = Math.min(requestedPage, pageCount)
  const pageStart = (page - 1) * COMMITS_PER_PAGE
  const visibleCommits = commits.slice(pageStart, pageStart + COMMITS_PER_PAGE)
  const hasPagination = pageCount > 1

  return (
    <section aria-labelledby="github-commits-heading">
      <div className="flex items-center justify-between gap-3"><h3 id="github-commits-heading" className="text-base font-semibold text-white">Recent commits</h3><span className="text-xs text-slate-500">Read-only</span></div>
      {commits.length === 0 ? <p className="mt-4 rounded-2xl border border-dashed border-white/15 px-4 py-7 text-center text-sm text-slate-500">{neverSynced ? 'Sync this repository to load recent commits.' : 'No commits in the latest snapshot.'}</p> : <><ul className="mt-4 space-y-3">{visibleCommits.map((commit) => <li key={commit.id} className="rounded-2xl border border-white/10 bg-slate-950/35 p-4"><p className="text-sm font-medium text-slate-200">{isSafeGithubUrl(commit.html_url) ? <a href={commit.html_url} target="_blank" rel="noreferrer" className="underline decoration-white/20 underline-offset-4 hover:decoration-cyan-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">{displayCommitMessage(commit)}</a> : displayCommitMessage(commit)}</p><p className="mt-2 text-xs text-slate-500">{commit.author_login ? `@${commit.author_login}` : commit.author_name ?? 'Unknown author'} · {formatDate(commit.committed_at)}</p></li>)}</ul>{hasPagination && <nav className="mt-5 flex items-center justify-between gap-3" aria-label="Recent commits pagination"><button type="button" onClick={() => setRequestedPage((current) => Math.max(1, current - 1))} disabled={page === 1} className="rounded-lg border border-white/15 px-3 py-2 text-xs font-medium text-slate-200 transition hover:border-cyan-200/40 hover:text-white disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">Previous</button><span className="text-xs text-slate-500" aria-live="polite">Page {page} of {pageCount}</span><button type="button" onClick={() => setRequestedPage((current) => Math.min(pageCount, current + 1))} disabled={page === pageCount} className="rounded-lg border border-white/15 px-3 py-2 text-xs font-medium text-slate-200 transition hover:border-cyan-200/40 hover:text-white disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">Next</button></nav>}</>}
    </section>
  )
}

function GithubIssueList({ issues, neverSynced }: { issues: GithubIssue[]; neverSynced: boolean }) {
  return (
    <section aria-labelledby="github-issues-heading">
      <div className="flex items-center justify-between gap-3"><h3 id="github-issues-heading" className="text-base font-semibold text-white">Open GitHub issues</h3><span className="text-xs text-slate-500">External · read-only</span></div>
      {issues.length === 0 ? <p className="mt-4 rounded-2xl border border-dashed border-white/15 px-4 py-7 text-center text-sm text-slate-500">{neverSynced ? 'Sync this repository to load open issues.' : 'No open GitHub issues in the latest snapshot.'}</p> : <ul className="mt-4 space-y-3">{issues.map((issue) => <li key={issue.id} className="rounded-2xl border border-white/10 bg-slate-950/35 p-4"><p className="text-sm font-medium text-slate-200">{isSafeGithubUrl(issue.html_url) ? <a href={issue.html_url} target="_blank" rel="noreferrer" className="underline decoration-white/20 underline-offset-4 hover:decoration-cyan-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">#{issue.number} {issue.title}</a> : `#${issue.number} ${issue.title}`}</p><div className="mt-2 flex flex-wrap gap-2 text-xs text-slate-500"><span>Updated {formatDate(issue.github_updated_at)}</span>{issue.author_login && <span>· @{issue.author_login}</span>}{issue.labels.slice(0, 3).map((label) => <span key={label} className="rounded-full border border-white/10 px-2 py-0.5">{label}</span>)}</div></li>)}</ul>}
    </section>
  )
}
