import { useState, type FormEvent } from 'react'
import { AlertTriangle, Clock3, GitBranch, RefreshCw, ShieldCheck } from 'lucide-react'

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

function SyncHealthBadge({ lastSyncedAt, isStale, isBusy = false }: { lastSyncedAt: string | null; isStale: boolean; isBusy?: boolean }) {
  const isSynced = Boolean(lastSyncedAt)
  const Icon = isBusy ? RefreshCw : isStale ? AlertTriangle : isSynced ? ShieldCheck : Clock3
  const label = isBusy ? 'Syncing…' : isStale ? 'Sync needs attention' : isSynced ? 'Sync healthy' : 'Not synced yet'
  const styles = isBusy || isStale
    ? 'border-amber-500/30 bg-amber-500/10 text-amber-800 dark:border-amber-400/25 dark:bg-amber-400/10 dark:text-amber-200'
    : isSynced
      ? 'border-emerald-500/25 bg-emerald-500/10 text-emerald-800 dark:border-emerald-400/25 dark:bg-emerald-400/10 dark:text-emerald-200'
      : 'border-slate-200/80 bg-slate-100/80 text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-300'

  return (
    <span className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-semibold ${styles}`}>
      <Icon className={`size-3.5 ${isBusy ? 'animate-spin' : ''}`} aria-hidden="true" />
      {label}
    </span>
  )
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
    return (
      <section className="makko-surface rounded-3xl p-6 sm:p-8" aria-labelledby="github-heading">
        <div className="flex flex-wrap items-center gap-2.5">
          <h2 id="github-heading" className="text-xl font-semibold text-slate-900 dark:text-white">GitHub repository</h2>
          <span className="inline-flex items-center gap-1.5 rounded-full border border-cyan-500/25 bg-cyan-500/10 px-2.5 py-1 text-xs font-semibold text-cyan-800 dark:border-cyan-400/25 dark:bg-cyan-400/10 dark:text-cyan-200">
            <GitBranch className="size-3.5" aria-hidden="true" />
            External / read-only
          </span>
        </div>
        <p className="mt-6 text-sm font-medium text-slate-600 dark:text-slate-400" role="status">Loading GitHub data…</p>
      </section>
    )
  }

  return (
    <section className="makko-surface rounded-3xl p-6 sm:p-8" aria-labelledby="github-heading">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-start">
        <div>
          <div className="flex flex-wrap items-center gap-2.5">
            <h2 id="github-heading" className="text-xl font-semibold text-slate-900 dark:text-white">GitHub repository</h2>
            <span className="inline-flex items-center gap-1.5 rounded-full border border-cyan-500/25 bg-cyan-500/10 px-2.5 py-1 text-xs font-semibold text-cyan-800 dark:border-cyan-400/25 dark:bg-cyan-400/10 dark:text-cyan-200">
              <GitBranch className="size-3.5" aria-hidden="true" />
              External / read-only
            </span>
          </div>
          <p className="mt-1 max-w-2xl text-sm font-normal leading-6 text-slate-600 dark:text-slate-400">
            Read-only commits and open issues from one connected repository. GitHub issues never affect Makko totals.
          </p>
        </div>
        {hasLink && (
          <div className="flex shrink-0 flex-wrap gap-2.5">
            <button
              type="button"
              onClick={() => { setShowConnectionForm((visible) => !visible); setRepository('') }}
              className="makko-control makko-secondary makko-focus px-4 text-sm font-semibold"
            >
              {showConnectionForm ? 'Cancel change' : 'Change repository'}
            </button>
            <button
              type="button"
              onClick={() => void handleDisconnect()}
              disabled={github.isMutating}
              className="makko-control makko-focus makko-danger px-4 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50"
            >
              Disconnect
            </button>
          </div>
        )}
      </div>

      {connectionValidationError && <div className="mt-6"><StatusMessage kind="error">{connectionValidationError}</StatusMessage></div>}
      {github.error && (
        <div className="mt-6">
          <StatusMessage kind="error">{github.error}</StatusMessage>
          <button
            type="button"
            onClick={() => void github.refresh()}
            className="makko-control makko-secondary makko-focus mt-3 px-4 text-sm font-semibold"
          >
            Retry GitHub data
          </button>
        </div>
      )}
      {success && <div className="mt-6"><StatusMessage kind="success">{success}</StatusMessage></div>}
      {github.status === 'loading' && github.link && <p className="mt-6 text-sm font-medium text-slate-600 dark:text-slate-400" role="status">Refreshing GitHub data…</p>}

      {(!hasLink || showConnectionForm) && (
        <form className="mt-6 rounded-3xl border border-cyan-500/25 bg-cyan-500/[0.05] p-5 shadow-sm dark:border-cyan-400/20 dark:bg-cyan-400/[0.05] sm:p-6" onSubmit={(event) => void handleConnect(event)}>
          <label htmlFor="github-repository" className="mb-2 block text-sm font-medium text-slate-800 dark:text-slate-200">{hasLink ? 'New repository' : 'Repository'}</label>
          <div className="flex flex-col gap-3 sm:flex-row">
            <input
              id="github-repository"
              value={repository}
              onChange={(event) => { setRepository(event.target.value); setConnectionValidationError(null) }}
              required
              pattern={GITHUB_REPOSITORY_PATTERN}
              maxLength={140}
              placeholder="owner/repository"
              aria-describedby="github-repository-help"
              aria-invalid={Boolean(connectionValidationError)}
              className="makko-field makko-readable min-w-0 flex-1 px-4 py-3 text-sm placeholder:text-slate-400 dark:placeholder:text-slate-500"
            />
            <button
              type="submit"
              disabled={github.isMutating}
              className="makko-control makko-primary makko-focus px-6 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50"
            >
              {github.isMutating ? 'Connecting…' : hasLink ? 'Connect replacement' : 'Connect repository'}
            </button>
          </div>
          <p id="github-repository-help" className="mt-2 text-xs font-normal leading-5 text-slate-500 dark:text-slate-400">Use the public GitHub owner/repository name. Makko checks the repository when you sync.</p>
        </form>
      )}

      {hasLink && !showConnectionForm && github.link && (
        <>
          <div className="makko-well mt-6 flex min-w-0 flex-col gap-4 rounded-3xl p-4 transition-all hover:border-slate-300 hover:bg-white dark:hover:border-white/20 dark:hover:bg-white/[0.04] sm:flex-row sm:items-center sm:justify-between sm:p-5">
            <div className="min-w-0">
              {isSafeGithubUrl(`https://github.com/${github.link.repo_full_name}`) ? (
                <a href={`https://github.com/${github.link.repo_full_name}`} target="_blank" rel="noreferrer" className="makko-focus makko-readable inline-flex min-h-11 max-w-full items-center break-all font-semibold text-cyan-700 underline decoration-cyan-500/30 underline-offset-4 transition hover:text-cyan-800 hover:decoration-cyan-600 dark:text-cyan-300 dark:decoration-cyan-300/30 dark:hover:decoration-cyan-100">
                  {github.link.repo_full_name}
                </a>
              ) : (
                <p className="break-all font-semibold text-slate-900 dark:text-white">{github.link.repo_full_name}</p>
              )}
              <div className="mt-2 flex flex-wrap items-center gap-2">
                <SyncHealthBadge lastSyncedAt={github.link.last_synced_at} isStale={isStale} isBusy={github.status === 'loading' || github.isMutating} />
                <p className="text-xs font-medium text-slate-500 dark:text-slate-400">
                  {github.link.last_synced_at ? `Last synced ${formatDate(github.link.last_synced_at)}` : 'Not synced yet'}
                  {isStale ? ' · Cached data may be stale' : ''}
                </p>
              </div>
            </div>
            <button
              type="button"
              onClick={() => void handleSync()}
              disabled={github.status === 'loading' || github.isMutating || github.cooldownSeconds > 0}
              className="makko-control makko-primary makko-focus shrink-0 px-5 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50"
            >
              {github.isMutating ? 'Syncing…' : github.cooldownSeconds > 0 ? `Available in ${github.cooldownSeconds}s` : 'Sync now'}
            </button>
          </div>

          <div className="mt-8 grid gap-8 xl:grid-cols-2">
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
      <div className="flex items-center justify-between gap-3">
        <h3 id="github-commits-heading" className="text-base font-semibold text-slate-900 dark:text-white">Recent commits</h3>
        <span className="inline-flex items-center gap-1.5 rounded-full border border-slate-200/70 bg-slate-100/80 px-2.5 py-0.5 text-xs font-medium text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-400">
          <ShieldCheck className="size-3.5" aria-hidden="true" />
          Read-only
        </span>
      </div>
      {commits.length === 0 ? (
        <p className="mt-4 rounded-2xl border border-dashed border-slate-200 p-6 text-center text-sm font-normal text-slate-500 dark:border-white/10 dark:text-slate-400">
          {neverSynced ? 'Sync this repository to load recent commits.' : 'No commits in the latest snapshot.'}
        </p>
      ) : (
        <>
          <ul className="mt-4 space-y-3">
            {visibleCommits.map((commit) => (
              <li key={commit.id} className="makko-well rounded-2xl p-4 transition-all hover:border-slate-300 hover:bg-white dark:hover:border-white/20 dark:hover:bg-white/[0.04]">
                <p className="makko-readable text-sm font-medium text-slate-800 dark:text-slate-200">
                  {isSafeGithubUrl(commit.html_url) ? (
                    <a href={commit.html_url} target="_blank" rel="noreferrer" className="makko-focus makko-readable inline-flex min-h-11 max-w-full items-center underline decoration-slate-300 underline-offset-4 transition hover:text-cyan-700 hover:decoration-cyan-600 dark:decoration-white/20 dark:hover:text-cyan-300 dark:hover:decoration-cyan-300">
                      {displayCommitMessage(commit)}
                    </a>
                  ) : (
                    displayCommitMessage(commit)
                  )}
                </p>
                <p className="mt-1.5 text-xs font-medium text-slate-500 dark:text-slate-400">
                  {commit.author_login ? `@${commit.author_login}` : commit.author_name ?? 'Unknown author'} · {formatDate(commit.committed_at)}
                </p>
              </li>
            ))}
          </ul>
          {hasPagination && (
            <nav className="mt-5 flex items-center justify-between gap-3" aria-label="Recent commits pagination">
              <button
                type="button"
                onClick={() => setRequestedPage((current) => Math.max(1, current - 1))}
                disabled={page === 1}
                className="makko-control makko-secondary makko-focus px-3.5 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50"
              >
                Previous
              </button>
              <span className="text-xs font-medium text-slate-500 dark:text-slate-400" aria-live="polite">
                Page {page} of {pageCount}
              </span>
              <button
                type="button"
                onClick={() => setRequestedPage((current) => Math.min(pageCount, current + 1))}
                disabled={page === pageCount}
                className="makko-control makko-secondary makko-focus px-3.5 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50"
              >
                Next
              </button>
            </nav>
          )}
        </>
      )}
    </section>
  )
}

function GithubIssueList({ issues, neverSynced }: { issues: GithubIssue[]; neverSynced: boolean }) {
  return (
    <section aria-labelledby="github-issues-heading">
      <div className="flex items-center justify-between gap-3">
        <h3 id="github-issues-heading" className="text-base font-semibold text-slate-900 dark:text-white">Open GitHub issues</h3>
        <span className="inline-flex items-center gap-1.5 rounded-full border border-cyan-500/30 bg-cyan-500/10 px-2.5 py-0.5 text-xs font-medium text-cyan-800 dark:border-cyan-400/25 dark:bg-cyan-400/10 dark:text-cyan-200">
          <ShieldCheck className="size-3.5" aria-hidden="true" />
          External · read-only
        </span>
      </div>
      {issues.length === 0 ? (
        <p className="mt-4 rounded-2xl border border-dashed border-slate-200 p-6 text-center text-sm font-normal text-slate-500 dark:border-white/10 dark:text-slate-400">
          {neverSynced ? 'Sync this repository to load open issues.' : 'No open GitHub issues in the latest snapshot.'}
        </p>
      ) : (
        <ul className="mt-4 space-y-3">
          {issues.map((issue) => (
              <li key={issue.id} className="makko-well rounded-2xl p-4 transition-all hover:border-slate-300 hover:bg-white dark:hover:border-white/20 dark:hover:bg-white/[0.04]">
              <p className="makko-readable text-sm font-medium text-slate-800 dark:text-slate-200">
                {isSafeGithubUrl(issue.html_url) ? (
                  <a href={issue.html_url} target="_blank" rel="noreferrer" className="makko-focus makko-readable inline-flex min-h-11 max-w-full items-center underline decoration-slate-300 underline-offset-4 transition hover:text-cyan-700 hover:decoration-cyan-600 dark:decoration-white/20 dark:hover:text-cyan-300 dark:hover:decoration-cyan-300">
                    #{issue.number} {issue.title}
                  </a>
                ) : (
                  `#${issue.number} ${issue.title}`
                )}
              </p>
              <div className="mt-2 flex flex-wrap items-center gap-2 text-xs font-medium text-slate-500 dark:text-slate-400">
                <span>Updated {formatDate(issue.github_updated_at)}</span>
                {issue.author_login && <span>· @{issue.author_login}</span>}
                {issue.labels.slice(0, 3).map((label) => (
                  <span key={label} className="rounded-full border border-slate-200/70 bg-slate-100/80 px-2.5 py-0.5 text-xs font-medium text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-300">
                    {label}
                  </span>
                ))}
              </div>
            </li>
          ))}
        </ul>
      )}
    </section>
  )
}
