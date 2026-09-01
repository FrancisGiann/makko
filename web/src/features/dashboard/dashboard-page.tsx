import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { Activity, ArrowRight, FolderOpen, RotateCw } from 'lucide-react'
import { GitHubCalendar } from 'react-github-calendar'

import { StatusMessage } from '../../components/status-message'
import { useAuth } from '../auth/use-auth'
import { useDashboard } from '../../hooks/use-dashboard'
import type { DashboardService, DashboardStats } from '../../services/dashboard.service'
import type { IssueStatus } from '../../types/domain'
import { getDisplayName } from '../../utils/display-name'
import { clearLegacyGithubUsername, GITHUB_USERNAME_PATTERN, githubUsernameStorageKey, loadGithubUsername, normalizeGithubUsername } from '../../utils/github-username'

function statusLabel(status: IssueStatus): string {
  return status === 'in_progress' ? 'In progress' : status === 'todo' ? 'To do' : 'Done'
}

function getTimeGreeting(): string {
  const hour = new Date().getHours()
  if (hour < 12) return 'Good morning'
  if (hour < 18) return 'Good afternoon'
  return 'Good evening'
}

function useActiveTheme(): 'light' | 'dark' {
  const [theme, setTheme] = useState<'light' | 'dark'>(() => {
    if (typeof document !== 'undefined') {
      if (document.documentElement.dataset.theme === 'light') return 'light'
      if (document.documentElement.dataset.theme === 'dark' || document.documentElement.classList.contains('dark')) {
        return 'dark'
      }
    }
    if (typeof window !== 'undefined' && window.matchMedia?.('(prefers-color-scheme: light)').matches) {
      return 'light'
    }
    return 'dark'
  })

  useEffect(() => {
    if (typeof MutationObserver === 'undefined' || typeof document === 'undefined') return
    const updateTheme = () => {
      if (document.documentElement.dataset.theme === 'light') {
        setTheme('light')
      } else if (document.documentElement.dataset.theme === 'dark' || document.documentElement.classList.contains('dark')) {
        setTheme('dark')
      } else if (typeof window !== 'undefined' && window.matchMedia?.('(prefers-color-scheme: light)').matches) {
        setTheme('light')
      } else {
        setTheme('dark')
      }
    }
    updateTheme()
    const observer = new MutationObserver(updateTheme)
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['data-theme', 'class', 'style'],
    })
    return () => observer.disconnect()
  }, [])

  return theme
}

const GITHUB_CALENDAR_THEME = {
  light: ['#f1f5f9', '#a5f3fc', '#67e8f9', '#06b6d4', '#0e7490'],
  dark: ['rgba(255,255,255,0.05)', '#164e63', '#0891b2', '#06b6d4', '#22d3ee'],
}

interface DashboardPageProps { service?: DashboardService }

export function DashboardPage({ service }: DashboardPageProps) {
  const { stats, status, error, refresh } = useDashboard(service)
  const { state: authState } = useAuth()
  const [animateBars, setAnimateBars] = useState(false)
  const userId = authState.session?.user.id ?? null
  const [githubUsername, setGithubUsername] = useState('')
  const [appliedUsername, setAppliedUsername] = useState('')
  const [isEditing, setIsEditing] = useState(false)
  const isLoading = status === 'loading' && !stats

  useEffect(() => {
    if (stats) {
      const frame = requestAnimationFrame(() => {
        setAnimateBars(true)
      })
      return () => cancelAnimationFrame(frame)
    }
  }, [stats])

  useEffect(() => {
    const storedUsername = loadGithubUsername(userId)
    setGithubUsername(storedUsername)
    setAppliedUsername(storedUsername)
    setIsEditing(false)
  }, [userId])

  return (
    <main className="makko-page">
      <section className="makko-surface-raised animate-fade-up rounded-3xl p-4 sm:p-6 lg:p-7" aria-labelledby="dashboard-heading">
        <div className="flex flex-col gap-1 border-b border-slate-200/70 pb-5 dark:border-white/[0.08] sm:flex-row sm:items-end sm:justify-between sm:gap-4">
          <div>
            <h1 id="dashboard-heading" className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-3xl">Dashboard</h1>
            <p className="mt-1 text-sm font-normal text-slate-600 dark:text-slate-400">A pulse on your internal Makko workspace.</p>
            <p className="sr-only">A small view of the work you are carrying. Counts below include internal Makko issues only.</p>
          </div>
          <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-cyan-700 dark:text-cyan-300">
            <Activity className="size-3.5" aria-hidden="true" />
            Workspace view
          </span>
        </div>
        <div className="grid grid-cols-[minmax(0,1fr)_auto] gap-4 md:grid-cols-[minmax(7rem,auto)_minmax(0,1fr)_auto] md:items-center lg:gap-6">
          <MakkoPetWidget
            stats={stats}
            isLoading={isLoading}
            userName={getDisplayName(authState.session?.user)}
          />
          <button
            type="button"
            onClick={() => void refresh()}
            disabled={status === 'loading'}
            className="makko-control makko-secondary makko-focus order-2 inline-flex w-fit shrink-0 items-center justify-center gap-2 justify-self-end px-4 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50 md:order-3"
          >
            <RotateCw className={`size-4 leading-none ${status === 'loading' ? 'animate-spin' : ''}`} aria-hidden="true" />
            <span>{status === 'loading' ? 'Refreshing…' : 'Refresh stats'}</span>
          </button>
        </div>
        {stats && <WorkspacePulse stats={stats} />}
      </section>

      {error && <div className="mt-6"><StatusMessage kind="error">{error}</StatusMessage></div>}

      {isLoading && <DashboardSkeleton />}

      {!isLoading && stats && (
        <>
          {/* Hero metric strip */}
          <section
            aria-label="Internal work totals"
            className="makko-surface animate-fade-up delay-200 mt-3 overflow-hidden rounded-3xl sm:mt-4"
          >
            <div className="grid grid-cols-2 sm:grid-cols-4">
              <div className="border-b border-r border-slate-200/70 p-4 dark:border-white/10 sm:border-b-0 sm:p-6 lg:p-7">
                <p className="text-2xl font-bold tabular-nums text-slate-900 dark:text-white sm:text-3xl">{stats.projectCount}</p>
                <p className="mt-1 text-sm font-medium text-slate-600 dark:text-slate-400">Projects</p>
                <p className="mt-0.5 text-xs text-slate-400 dark:text-slate-500">Owned projects</p>
              </div>
              <div className="border-b border-slate-200/70 p-4 dark:border-white/10 sm:border-b-0 sm:border-r sm:p-6 lg:p-7">
                <p className="text-2xl font-bold tabular-nums text-slate-900 dark:text-white sm:text-3xl">{stats.totalIssues}</p>
                <p className="mt-1 text-sm font-medium text-slate-600 dark:text-slate-400">All issues</p>
                <p className="mt-0.5 text-xs text-slate-400 dark:text-slate-500">Internal Makko issues</p>
              </div>
              <div className="border-r border-slate-200/70 p-4 dark:border-white/10 sm:p-6 lg:p-7">
                <p className="text-2xl font-bold tabular-nums text-cyan-600 dark:text-cyan-300 sm:text-3xl">{stats.openIssues}</p>
                <p className="mt-1 text-sm font-medium text-slate-600 dark:text-slate-400">Open</p>
                <p className="mt-0.5 text-xs text-slate-400 dark:text-slate-500">To do + in progress</p>
              </div>
              <div className="p-4 sm:p-6 lg:p-7">
                <p className="text-2xl font-bold tabular-nums text-emerald-600 dark:text-emerald-300 sm:text-3xl">{stats.completedIssues}</p>
                <p className="mt-1 text-sm font-medium text-slate-600 dark:text-slate-400">Completed</p>
                <p className="mt-0.5 text-xs text-slate-400 dark:text-slate-500">Done</p>
              </div>
            </div>
          </section>

          <div className="animate-fade-up delay-300 mt-6 grid gap-6 md:grid-cols-2 lg:gap-8">
            <BreakdownCard
              title="By status"
              animate={animateBars}
              items={(['todo', 'in_progress', 'done'] as const).map((key) => ({
                label: statusLabel(key),
                value: stats.byStatus[key],
                color: key === 'done' ? 'bg-emerald-500' : key === 'in_progress' ? 'bg-cyan-500' : 'bg-slate-400 dark:bg-slate-500',
              }))}
            />
            <BreakdownCard
              title="By type"
              animate={animateBars}
              items={(['task', 'bug'] as const).map((key) => ({
                label: key === 'bug' ? 'Bugs' : 'Tasks',
                value: stats.byType[key],
                color: key === 'bug' ? 'bg-rose-500' : 'bg-cyan-500',
              }))}
            />
            <BreakdownCard
              title="By priority"
              animate={animateBars}
              items={(['high', 'medium', 'low'] as const).map((key) => ({
                label: `${key[0].toUpperCase()}${key.slice(1)}`,
                value: stats.byPriority[key],
                color: key === 'high' ? 'bg-rose-500' : key === 'medium' ? 'bg-amber-500' : 'bg-slate-400 dark:bg-slate-500',
              }))}
            />
            <section
              className="makko-surface rounded-3xl p-5 sm:p-7 lg:p-8"
              aria-labelledby="workload-heading"
            >
              <h2 id="workload-heading" className="text-xl font-semibold tracking-tight text-slate-900 dark:text-white">Project workload</h2>
              {stats.projects.length === 0 ? (
              <p className="mt-5 rounded-2xl border border-dashed border-slate-200 p-5 text-center text-sm font-normal text-slate-500 dark:border-white/10 dark:text-slate-400 sm:p-6">Go to Projects to create a project and see its workload here.</p>
              ) : (
                <ul className="mt-5 space-y-3">
                  {stats.projects.map((project) => (
                    <li key={project.id} className="flex flex-col gap-2 rounded-2xl border border-slate-200/70 bg-white/80 p-3.5 transition-all hover:border-slate-300 hover:bg-white hover:shadow-xs dark:border-white/[0.06] dark:bg-white/[0.03] dark:hover:border-white/20 dark:hover:bg-white/[0.06] sm:flex-row sm:items-center sm:justify-between sm:p-4">
                      <Link to={`/app/projects/${project.id}`} className="makko-focus makko-readable inline-flex min-h-11 min-w-0 flex-1 items-center font-semibold text-slate-900 underline decoration-transparent underline-offset-4 transition hover:text-cyan-700 hover:decoration-cyan-600 dark:text-white dark:hover:text-cyan-200 dark:hover:decoration-cyan-300">{project.name}</Link>
                      <div className="flex flex-wrap items-center gap-2 text-xs font-medium">
                        <span className="rounded-full bg-cyan-500/10 px-2.5 py-1 text-cyan-800 dark:bg-cyan-400/10 dark:text-cyan-200">{project.open} open</span>
                        <span className="rounded-full bg-emerald-500/10 px-2.5 py-1 text-emerald-800 dark:bg-emerald-400/10 dark:text-emerald-300">{project.completed} done</span>
                      </div>
                    </li>
                  ))}
                </ul>
              )}
            </section>
          </div>

          {stats.projectCount === 0 && (
            <section className="animate-fade-up delay-300 mt-6 rounded-3xl border border-dashed border-cyan-500/30 bg-cyan-500/[0.04] p-6 text-center dark:border-cyan-400/20 dark:bg-cyan-400/[0.04] sm:p-12" aria-label="Empty dashboard">
              <div className="mx-auto mb-4 grid size-14 place-items-center rounded-3xl border border-cyan-500/25 bg-cyan-500/10 text-cyan-700 dark:border-cyan-400/30 dark:bg-cyan-400/10 dark:text-cyan-300">
                <FolderOpen className="size-6" />
              </div>
              <p className="text-lg font-semibold text-slate-900 dark:text-slate-100">Your dashboard is ready for its first project.</p>
              <p className="mx-auto mt-2 max-w-md text-sm font-normal leading-6 text-slate-600 dark:text-slate-400">Go to Projects to add the work that will appear in these totals.</p>
              <Link to="/app" className="makko-control makko-primary makko-focus mt-6 inline-flex items-center gap-2 px-5 text-sm font-semibold">
                <span>Go to projects</span>
                <ArrowRight className="size-4" aria-hidden="true" />
              </Link>
            </section>
          )}

          {/* GitHub Contributions */}
          <GithubContributionsSection
            githubUsername={githubUsername}
            setGithubUsername={setGithubUsername}
            appliedUsername={appliedUsername}
            setAppliedUsername={setAppliedUsername}
            isEditing={isEditing}
            setIsEditing={setIsEditing}
            userId={userId}
          />
        </>
      )}
    </main>

  )
}

interface GithubContributionsSectionProps {
  githubUsername: string
  setGithubUsername: (val: string) => void
  appliedUsername: string
  setAppliedUsername: (val: string) => void
  isEditing: boolean
  setIsEditing: (val: boolean) => void
  userId: string | null
}

function GithubContributionsSection({
  githubUsername,
  setGithubUsername,
  appliedUsername,
  setAppliedUsername,
  isEditing,
  setIsEditing,
  userId,
}: GithubContributionsSectionProps) {
  const activeTheme = useActiveTheme()
  const [validationError, setValidationError] = useState<string | null>(null)

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault()
    const trimmed = githubUsername.trim()
    if (trimmed) {
      const normalized = normalizeGithubUsername(trimmed)
      if (!normalized) {
        setValidationError('Use a GitHub username with 1–39 letters, numbers, or hyphens.')
        return
      }
      const storageKey = githubUsernameStorageKey(userId)
      try {
        clearLegacyGithubUsername()
        if (storageKey) localStorage.setItem(storageKey, normalized)
      } catch {
        // ignore storage errors
      }
      setValidationError(null)
      setGithubUsername(normalized)
      setAppliedUsername(normalized)
      setIsEditing(false)
    } else {
      try {
        clearLegacyGithubUsername()
        const storageKey = githubUsernameStorageKey(userId)
        if (storageKey) localStorage.removeItem(storageKey)
      } catch {
        // ignore storage errors
      }
      setValidationError(null)
      setGithubUsername('')
      setAppliedUsername('')
      setIsEditing(false)
    }
  }

  const handleStartEdit = () => {
    setGithubUsername(appliedUsername)
    setIsEditing(true)
  }

  const handleCancelEdit = () => {
    setGithubUsername(appliedUsername)
    setIsEditing(false)
  }

  return (
    <section
      aria-labelledby="github-contributions-heading"
      className="makko-surface animate-fade-up delay-300 mt-6 rounded-3xl p-5 sm:p-7 lg:p-8"
    >
      <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
        <div>
          <div className="flex items-center gap-2.5">
            <h2 id="github-contributions-heading" className="text-xl font-semibold tracking-tight text-slate-900 dark:text-white">
              GitHub Contributions
            </h2>
            {appliedUsername && !isEditing && (
              <span className="rounded-full border border-cyan-500/25 bg-cyan-500/10 px-2.5 py-0.5 text-xs font-medium text-cyan-800 dark:border-cyan-400/25 dark:bg-cyan-400/10 dark:text-cyan-200">
                @{appliedUsername}
              </span>
            )}
          </div>
          <p className="mt-1 text-sm font-normal text-slate-600 dark:text-slate-400">
            {appliedUsername && !isEditing
              ? 'Live contribution graph synced directly from your public GitHub profile.'
              : 'Enter your GitHub username to view your live contribution graph.'}
          </p>
        </div>

        {appliedUsername && !isEditing && (
          <div className="flex items-center gap-2 shrink-0">
            <button
              type="button"
              onClick={handleStartEdit}
              className="makko-control makko-secondary makko-focus px-3.5 text-sm font-semibold"
            >
              Edit
            </button>
          </div>
        )}
      </div>

      {(!appliedUsername || isEditing) && (
        <form onSubmit={handleSave} className="mt-5 rounded-2xl border border-cyan-500/20 bg-cyan-500/[0.05] p-4.5 shadow-xs dark:border-cyan-400/15 dark:bg-cyan-400/[0.05] sm:p-6">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
            <div className="relative flex-1">
              <label htmlFor="dashboard-github-username" className="sr-only">
                GitHub Username
              </label>
              <input
                id="dashboard-github-username"
                type="text"
                value={githubUsername}
                onChange={(e) => { setGithubUsername(e.target.value); setValidationError(null) }}
                placeholder="Enter GitHub username (e.g. torvalds)"
                pattern={GITHUB_USERNAME_PATTERN.source}
                maxLength={39}
                aria-invalid={Boolean(validationError)}
                aria-describedby={validationError ? 'dashboard-github-username-error' : undefined}
                className="makko-field w-full px-4 py-3 text-sm placeholder:text-slate-400 dark:placeholder:text-slate-500"
              />
            </div>
            <div className="flex items-center gap-2">
              <button
                type="submit"
                className="makko-control makko-primary makko-focus px-5 text-sm font-semibold"
              >
                Save
              </button>
              {isEditing && appliedUsername && (
                <button
                  type="button"
                  onClick={handleCancelEdit}
                  className="makko-control makko-secondary makko-focus px-4 text-sm font-semibold"
                >
                  Cancel
                </button>
              )}
            </div>
          </div>
          {validationError && <p id="dashboard-github-username-error" className="mt-3 text-sm font-medium text-rose-700 dark:text-rose-300" role="alert">{validationError}</p>}
        </form>
      )}

      {appliedUsername && !isEditing && (
        <div className="makko-scroll-x mt-6 py-1" aria-describedby="dashboard-github-scroll-hint">
          <p id="dashboard-github-scroll-hint" className="mb-2 text-xs text-slate-500 dark:text-slate-400">Scroll horizontally to view the full contribution year.</p>
          <div className="min-w-fit flex justify-center">
            <GitHubCalendar
              username={appliedUsername}
              theme={GITHUB_CALENDAR_THEME}
              colorScheme={activeTheme}
              fontSize={12}
              blockSize={12}
              blockMargin={4}
              blockRadius={2}
            />
          </div>
        </div>
      )}
    </section>
  )
}

function DashboardSkeleton() {
  return (
    <div className="mt-6 space-y-6" role="status" aria-label="Loading your dashboard">
      <span className="sr-only">Loading your dashboard…</span>

      {/* Metric Strip Skeleton */}
      <div className="makko-surface overflow-hidden rounded-3xl">
        <div className="grid grid-cols-2 sm:grid-cols-4">
          <div className="border-b border-r border-slate-200/70 p-4.5 dark:border-white/10 sm:border-b-0 sm:p-6 lg:p-7">
            <div className="h-8 w-14 rounded-xl bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="mt-2.5 h-4 w-20 rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="mt-1.5 h-3 w-28 max-w-full rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
          </div>
          <div className="border-b border-slate-200/70 p-4.5 dark:border-white/10 sm:border-b-0 sm:border-r sm:p-6 lg:p-7">
            <div className="h-8 w-14 rounded-xl bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="mt-2.5 h-4 w-20 rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="mt-1.5 h-3 w-28 max-w-full rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
          </div>
          <div className="border-r border-slate-200/70 p-4.5 dark:border-white/10 sm:p-6 lg:p-7">
            <div className="h-8 w-14 rounded-xl bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="mt-2.5 h-4 w-20 rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="mt-1.5 h-3 w-28 max-w-full rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
          </div>
          <div className="p-4.5 sm:p-6 lg:p-7">
            <div className="h-8 w-14 rounded-xl bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="mt-2.5 h-4 w-20 rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="mt-1.5 h-3 w-28 max-w-full rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
          </div>
        </div>
      </div>

      {/* Breakdown Cards Skeleton Grid */}
      <div className="grid gap-6 md:grid-cols-2 lg:gap-8">
        {[1, 2, 3, 4].map((card) => (
          <div key={card} className="makko-surface rounded-3xl p-5 sm:p-7 lg:p-8">
            <div className="h-6 w-32 rounded-lg bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="mt-5 space-y-4">
              {[1, 2, 3].map((row) => (
                <div key={row} className="space-y-2">
                  <div className="flex justify-between">
                    <div className="h-4 w-24 rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
                    <div className="h-4 w-8 rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
                  </div>
                  <div className="h-3 w-full rounded-full bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

interface MakkoPetWidgetProps {
  stats: DashboardStats | null
  isLoading: boolean
  userName: string
}

function MakkoPetWidget({ stats, isLoading, userName }: MakkoPetWidgetProps) {
  const greeting = getTimeGreeting()
  const name = userName

  let petMessage = "Checking the waters and gathering your workload stats…"
  let subtext = "Hang tight while we fetch your project metrics."
  let moodTag = "Scanning"
  let vibePill = "Syncing"

  if (!isLoading && stats) {
    if (stats.projectCount === 0) {
      petMessage = "Welcome to Makko! The ocean is calm and clear. Ready to create your first project and set sail?"
      subtext = "Go to Projects anytime to start mapping out your builds."
      moodTag = "Ready to launch"
      vibePill = "Calm Waters"
    } else if (stats.totalIssues === 0) {
      petMessage = `You've set up ${stats.projectCount} project${stats.projectCount === 1 ? '' : 's'}, with zero open issues. What's on your mind?`
      subtext = "Add tasks or bugs to start tracking your momentum."
      moodTag = "Smooth sailing"
      vibePill = "Clear Horizon"
    } else if (stats.openIssues === 0 && stats.completedIssues > 0) {
      petMessage = `All ${stats.completedIssues} issue${stats.completedIssues === 1 ? '' : 's'} completed across your workspace! The ocean is clear.`
      subtext = "Outstanding momentum! Take a breather or dive into something new."
      moodTag = "All clear!"
      vibePill = "100% Done"
    } else {
      const highPriority = stats.byPriority.high
      const inProgress = stats.byStatus.in_progress
      const completionRate = stats.totalIssues > 0 ? Math.round((stats.completedIssues / stats.totalIssues) * 100) : 0

      if (highPriority > 0) {
        petMessage = `You have ${stats.openIssues} open issue${stats.openIssues === 1 ? '' : 's'}, including ${highPriority} urgent high-priority item${highPriority === 1 ? '' : 's'}. Let's crush ${highPriority === 1 ? 'it' : 'them'}!`
        subtext = `${completionRate}% overall completion rate so far. Focus mode activated!`
        moodTag = "High Alert"
        vibePill = `${highPriority} urgent`
      } else if (inProgress > 0) {
        petMessage = `You're cruising with ${inProgress} issue${inProgress === 1 ? '' : 's'} in progress and ${stats.openIssues} open total. Keep up the strong flow!`
        subtext = `${stats.completedIssues} closed · ${stats.openIssues} remaining (${completionRate}% completed)`
        moodTag = "In the zone"
        vibePill = `${inProgress} active`
      } else {
        petMessage = `You have ${stats.openIssues} open issue${stats.openIssues === 1 ? '' : 's'} across ${stats.projectCount} project${stats.projectCount === 1 ? '' : 's'}. Let's crush them!`
        subtext = `${stats.completedIssues} closed · ${completionRate}% overall completion rate. Steady waters ahead!`
        moodTag = "On patrol"
        vibePill = `${stats.openIssues} open`
      }
    }
  }

  return (
    <>
      {/* Shark Avatar Column */}
      <div role="group" aria-label="Makko Companion" className="order-1 flex shrink-0 flex-col items-start gap-2 md:items-center">
          <div className="animate-pet-float relative size-20 sm:size-24">
            <img
              src="/makko-pet.png"
              alt="Makko the shark pet"
              width={96}
              height={96}
              loading="eager"
              className="h-full w-full object-contain transition-transform duration-300 hover:scale-105"
            />
            <span className="absolute bottom-1.5 right-1.5 size-3 rounded-full bg-emerald-400 ring-2 ring-white dark:ring-slate-900" aria-label="Active status" />
          </div>
          <div className="flex flex-col items-start text-left md:items-center md:text-center">
            <span className="inline-flex items-center gap-1 rounded-full border border-cyan-500/25 bg-cyan-500/10 px-2.5 py-0.5 text-[11px] font-medium text-cyan-800 dark:border-cyan-400/25 dark:bg-cyan-400/10 dark:text-cyan-200">
              <span className="size-1.5 rounded-full bg-cyan-500 animate-pulse" />
              <span>Makko</span>
            </span>
            <span className="mt-0.5 text-[10px] font-medium text-slate-500 dark:text-slate-400">{vibePill}</span>
          </div>
        </div>

      {/* Speech Bubble Column */}
      <div className="pet-speech-bubble animate-slide-in-right delay-100 makko-well relative order-3 col-span-2 w-full min-w-0 rounded-2xl p-3 sm:p-4 md:order-2 md:col-span-1" aria-live="polite">
        {isLoading ? (
              <div className="space-y-2 md:grid md:grid-cols-[minmax(12rem,0.82fr)_minmax(0,1.5fr)_minmax(10rem,0.72fr)] md:gap-x-5 md:gap-y-3 md:space-y-0">
              <div className="flex items-center justify-between gap-3 md:col-span-3">
                <div className="h-6 w-32 sm:w-44 rounded-lg bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
                <div className="h-5 w-16 sm:w-20 rounded-full bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
              </div>
              <div className="space-y-2 pt-1 md:col-span-2 md:pt-0">
                <div className="h-4 w-5/6 rounded bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
                <div className="h-4 w-3/5 rounded bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
              </div>
              <div className="flex flex-wrap justify-between gap-2 border-t border-slate-100 pt-2 dark:border-white/[0.06] md:col-span-1 md:border-l md:border-t-0 md:pl-4 md:pt-0">
                <div className="h-3.5 w-28 sm:w-36 rounded bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
                <div className="h-3.5 w-20 sm:w-28 rounded bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
              </div>
            </div>
          ) : (
            <div className="grid gap-3 md:grid-cols-[minmax(12rem,0.82fr)_minmax(0,1.5fr)_minmax(10rem,0.72fr)] md:gap-x-5 md:gap-y-3 md:items-center">
              <div className="flex min-w-0 items-center justify-between gap-3 md:col-span-3">
                <h2 className="makko-readable text-lg font-semibold tracking-tight text-slate-900 dark:text-white sm:text-xl">
                  {greeting}, {name}!
                </h2>
                <span className="shrink-0 rounded-full border border-slate-200/70 bg-slate-100/80 px-2.5 py-0.5 text-xs font-medium text-slate-700 dark:border-white/10 dark:bg-white/[0.06] dark:text-slate-300">
                  {moodTag}
                </span>
              </div>

              <p className="makko-readable mt-1.5 text-sm font-normal leading-6 text-slate-800 dark:text-slate-100 md:col-span-2 md:mt-0">
                {petMessage}
              </p>

              <div className="mt-2 flex min-w-0 flex-wrap items-center justify-between gap-2 border-t border-slate-100 pt-2 dark:border-white/[0.06] md:col-span-1 md:mt-0 md:border-l md:border-t-0 md:pl-4 md:pt-0">
                <p className="makko-readable text-xs font-normal leading-5 text-slate-500 dark:text-slate-400">
                  {subtext}
                </p>
              </div>
            </div>
          )}
      </div>
    </>
  )
}

function BreakdownCard({
  title,
  items,
  animate = true,
}: {
  title: string
  items: { label: string; value: number; color?: string }[]
  animate?: boolean
}) {
  const total = items.reduce((sum, item) => sum + item.value, 0)
  return (
    <section className="makko-surface rounded-3xl p-5 sm:p-7 lg:p-8" aria-labelledby={`${title.replaceAll(' ', '-')}-heading`}>
      <h2 id={`${title.replaceAll(' ', '-')}-heading`} className="text-xl font-semibold tracking-tight text-slate-900 dark:text-white">{title}</h2>
      <ul className="mt-5 space-y-4">
        {items.map((item) => {
          const targetWidth = total ? (item.value / total) * 100 : 0
          return (
            <li key={item.label}>
              <div className="flex items-center justify-between gap-3 text-sm">
                <span className="font-medium text-slate-700 dark:text-slate-300">{item.label}</span>
                <span className="font-semibold tabular-nums text-slate-900 dark:text-white">{item.value}</span>
              </div>
              <div className="mt-2 h-3 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-900" aria-hidden="true">
                <div
                  className={`h-full rounded-full transition-all duration-1000 ease-out ${item.color ?? 'bg-cyan-500'}`}
                  style={{ width: animate ? `${targetWidth}%` : '0%' }}
                />
              </div>
            </li>
          )
        })}
      </ul>
      {total === 0 && <p className="mt-4 text-sm font-normal text-slate-500 dark:text-slate-400">No internal issues yet.</p>}
    </section>
  )
}

function WorkspacePulse({ stats }: { stats: DashboardStats }) {
  const total = Math.max(0, stats.totalIssues)
  const completed = Math.max(0, Math.min(stats.completedIssues, total))
  const completionPercent = total > 0 ? Math.round((completed / total) * 100) : 0
  const filledSegments = Math.round((completionPercent / 100) * 12)
  const completionText = total > 0
    ? `${completed} of ${total} internal issue${total === 1 ? '' : 's'} complete`
    : 'No internal issues yet.'

  return (
    <div className="mt-5 border-t border-slate-200/70 pt-5 dark:border-white/[0.08]" aria-labelledby="workspace-pulse-heading">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 id="workspace-pulse-heading" className="text-sm font-semibold text-slate-900 dark:text-white">Workspace pulse</h2>
          <p className="mt-1 text-xs font-normal text-slate-600 dark:text-slate-400">{completionText}</p>
        </div>
        <span className="text-sm font-semibold tabular-nums text-cyan-700 dark:text-cyan-300">{completionPercent}% complete</span>
      </div>
      <div
        className="mt-3 flex h-2.5 gap-1"
        role="progressbar"
        aria-label="Internal issue completion"
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={completionPercent}
        aria-valuetext={`${completionText} (${completionPercent}%)`}
      >
        {Array.from({ length: 12 }, (_, index) => (
          <span
            key={index}
            aria-hidden="true"
            className={`min-w-0 flex-1 rounded-full ${index < filledSegments ? 'bg-cyan-500 dark:bg-cyan-300' : 'bg-slate-200/80 dark:bg-white/[0.1]'}`}
          />
        ))}
      </div>
    </div>
  )
}
