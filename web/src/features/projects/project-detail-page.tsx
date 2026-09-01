import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, Circle, CircleCheck, CircleDot, CirclePlus, FolderPen, FolderPlus, Pencil, Trash2 } from 'lucide-react'

import { ProjectIdentity } from '../../components/project-identity'
import { StatusMessage } from '../../components/status-message'
import { useProject } from '../../hooks/use-project'
import { useProjectActivity } from '../../hooks/use-project-activity'
import { useProjectIssues } from '../../hooks/use-project-issues'
import type { ActivityScope } from '../../services/activity.service'
import type { ActivityLog, Issue } from '../../types/domain'
import { DEFAULT_ISSUE_FILTERS, type IssueFilters, type IssueSort } from '../../utils/issue-filters'
import { IssueForm } from '../issues/issue-form'
import { ProjectGithubSection } from '../github/project-github-section'
import { ProjectForm } from './project-form'

function formatDate(value: string): string {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? 'Unknown date' : date.toLocaleString()
}

function actionLabel(action: ActivityLog['action']): string {
  return action.replace('.', ' · ')
}

function ActivityIcon({ action }: { action: ActivityLog['action'] }) {
  const Icon = action === 'project.created'
    ? FolderPlus
    : action === 'project.updated'
      ? FolderPen
      : action === 'issue.created'
        ? CirclePlus
        : action === 'issue.updated'
          ? Pencil
          : Trash2

  return <Icon className="size-3.5" aria-hidden="true" />
}

export function ProjectDetailPage() {
  const { projectId } = useParams<{ projectId: string }>()
  const navigate = useNavigate()
  const projectState = useProject(projectId)
  const [showProjectEdit, setShowProjectEdit] = useState(false)
  const [showIssueForm, setShowIssueForm] = useState(false)
  const [editingIssue, setEditingIssue] = useState<Issue | null>(null)
  const [filters, setFilters] = useState<IssueFilters>(DEFAULT_ISSUE_FILTERS)
  const issueState = useProjectIssues(projectId, filters)
  const activityState = useProjectActivity(projectId)

  if (!projectId) return <MissingProject />

  if (projectState.status === 'loading' && !projectState.project) {
    return <ProjectDetailSkeleton />
  }

  if (projectState.status === 'error') {
    return (
      <main className="makko-page">
        <StatusMessage kind="error">{projectState.error ?? 'Unable to load that project.'}</StatusMessage>
        <Link
          to="/app"
          className="makko-control makko-secondary makko-focus mt-6 inline-flex items-center px-4 text-sm font-semibold"
        >
          Back to projects
        </Link>
      </main>
    )
  }

  if (!projectState.project) return <MissingProject />
  const project = projectState.project
  const issueTotal = issueState.total ?? issueState.issues.length
  const issuePageSize = issueState.pageSize ?? 5
  const issuePageCount = issueState.pageCount ?? Math.ceil(issueTotal / issuePageSize)
  const issuePage = issueState.page ?? 1
  const hasActiveIssueFilters = filters.status !== 'all' || filters.type !== 'all' || filters.priority !== 'all'
  const issueStart = issueTotal > 0 ? (issuePage - 1) * issuePageSize + 1 : 0
  const issueEnd = issueTotal > 0 ? Math.min(issueTotal, issuePage * issuePageSize) : 0

  const handleDeleteProject = async () => {
    if (!window.confirm(`Delete “${project.name}” and all of its issues? This cannot be undone.`)) return
    if (await projectState.deleteProject()) navigate('/app', { replace: true })
  }

  const handleIssueDelete = async (issue: Issue) => {
    if (!window.confirm(`Delete “${issue.title}”? Its deletion will remain in the project activity.`)) return
    if (await issueState.deleteIssue(issue.id)) await activityState.refresh()
  }

  const handleIssueStatusChange = async (issue: Issue, status: Issue['status']) => {
    if (status === issue.status) return
    const updated = await issueState.updateIssue(issue.id, {
      title: issue.title,
      description: issue.description ?? '',
      type: issue.type,
      priority: issue.priority,
      status,
    })
    if (updated) await activityState.refresh()
  }

  return (
    <main className="makko-page">
      <div className="animate-fade-up">
        <Link
          to="/app"
          className="makko-focus inline-flex min-h-11 items-center gap-1.5 text-sm font-semibold text-slate-600 underline decoration-slate-300/80 underline-offset-4 transition hover:text-cyan-700 hover:decoration-cyan-600 dark:text-slate-400 dark:decoration-white/20 dark:hover:text-cyan-300 dark:hover:decoration-cyan-300"
        >
          <ArrowLeft className="size-4" aria-hidden="true" />
          <span>All projects</span>
        </Link>
      </div>

      <header className="makko-surface animate-fade-up delay-75 mt-6 rounded-3xl p-6 sm:p-8">
        {showProjectEdit ? (
          <>
            <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Edit project</h1>
            <div className="mt-6">
              <ProjectForm
                initialProject={project}
                isSubmitting={projectState.isMutating}
                error={projectState.error}
                onCancel={() => setShowProjectEdit(false)}
                onSubmit={async (input) => {
                  const updated = await projectState.updateProject(input)
                  if (updated) {
                    setShowProjectEdit(false)
                    await activityState.refresh()
                  }
                  return updated
                }}
              />
            </div>
          </>
        ) : (
          <>
            <div className="flex flex-col justify-between gap-5 sm:flex-row sm:items-start">
              <div className="flex min-w-0 items-start gap-3.5 sm:gap-4">
                <ProjectIdentity name={project.name} tags={project.tags} />
                <div className="min-w-0">
                  <h1 className="makko-readable text-3xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-4xl">{project.name}</h1>
                  <p className="makko-readable mt-3 max-w-2xl text-sm font-normal leading-6 text-slate-600 dark:text-slate-300">{project.description ?? 'No description yet.'}</p>
                  {project.tags.length > 0 && (
                    <ul className="mt-4 flex flex-wrap gap-1.5" aria-label="Project tags">
                      {project.tags.map((tag) => (
                        <li key={tag} className="rounded-full border border-slate-200/70 bg-slate-100/80 px-2.5 py-0.5 text-xs font-medium text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-300">
                          {tag}
                        </li>
                      ))}
                    </ul>
                  )}
                </div>
              </div>
              <div className="flex shrink-0 flex-wrap gap-2.5">
                <button
                  type="button"
                  onClick={() => setShowProjectEdit(true)}
                  className="makko-control makko-secondary makko-focus inline-flex items-center px-4 text-sm font-semibold"
                >
                  Edit project
                </button>
                <button
                  type="button"
                  onClick={() => void handleDeleteProject()}
                  disabled={projectState.isMutating}
                  className="makko-control makko-focus makko-danger px-4 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50"
                >
                  Delete
                </button>
              </div>
            </div>
          </>
        )}
      </header>

      <div className="mt-8 grid gap-8 md:grid-cols-[minmax(0,1.45fr)_minmax(18rem,0.75fr)]">
        <section className="makko-surface animate-fade-up delay-150 min-w-0 rounded-3xl p-6 sm:p-8" aria-labelledby="issues-heading">
          <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-start">
            <div>
              <h2 id="issues-heading" className="text-2xl font-semibold text-slate-900 dark:text-white">Issues</h2>
              <p className="mt-1 text-sm font-normal text-slate-600 dark:text-slate-400">Tasks and bugs for this project.</p>
            </div>
            <button
              type="button"
              onClick={() => { setEditingIssue(null); setShowIssueForm((open) => !open) }}
              aria-expanded={showIssueForm}
              className="makko-control makko-primary makko-focus inline-flex items-center justify-center px-5 text-sm font-semibold"
            >
              {showIssueForm ? 'Close form' : 'New issue'}
            </button>
          </div>

          {showIssueForm && (
            <div className="mt-7 rounded-3xl border border-cyan-500/25 bg-cyan-500/[0.05] p-5 shadow-sm dark:border-cyan-400/20 dark:bg-cyan-400/[0.05] sm:p-6">
              <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Create an issue</h3>
              <div className="mt-5">
                <IssueForm
                  isSubmitting={issueState.isMutating}
                  error={issueState.error}
                  onCancel={() => setShowIssueForm(false)}
                  onSubmit={async (input) => {
                    const created = await issueState.createIssue(input)
                    if (created) {
                      setShowIssueForm(false)
                      await activityState.refresh()
                    }
                    return created
                  }}
                />
              </div>
            </div>
          )}

          {issueState.error && !showIssueForm && <div className="mt-6"><StatusMessage kind="error">{issueState.error}</StatusMessage></div>}

          <IssueFilters filters={filters} onChange={setFilters} />

          {issueState.status === 'loading' && issueState.issues.length === 0 && (
            <p className="mt-7 text-sm font-medium text-slate-600 dark:text-slate-400" role="status">Loading issues…</p>
          )}

          {issueState.status === 'error' && issueState.issues.length === 0 && !issueState.error && (
            <div className="mt-7"><StatusMessage kind="error">Unable to load issues.</StatusMessage></div>
          )}

          {issueState.status === 'ready' && issueState.issues.length === 0 && (
            <div className="mt-7 rounded-3xl border border-dashed border-slate-200 p-8 text-center dark:border-white/10">
              <p className="text-sm font-semibold text-slate-800 dark:text-slate-200">{hasActiveIssueFilters ? 'No issues match these filters.' : 'No issues yet.'}</p>
              <p className="mt-1 text-sm font-normal text-slate-500 dark:text-slate-400">{hasActiveIssueFilters ? 'Try widening the filters.' : 'Capture the next piece of work when it arrives.'}</p>
            </div>
          )}

          {issueState.issues.length > 0 && <div className="mt-6 divide-y divide-slate-200/70 dark:divide-white/[0.06]">
            {issueState.issues.map((issue, index) => {
              const delays = ['delay-0', 'delay-75', 'delay-100', 'delay-150', 'delay-200', 'delay-250', 'delay-300']
              const delayClass = delays[index % delays.length]
              return (
                <article key={issue.id} className={`animate-fade-up ${delayClass} px-4 py-3 transition-colors hover:bg-white dark:hover:bg-white/[0.04] first:rounded-t-2xl last:rounded-b-2xl`}>
                  {editingIssue?.id === issue.id ? (
                    <div className="py-2">
                      <h3 className="text-base font-semibold text-slate-900 dark:text-white">Edit issue</h3>
                      <div className="mt-4">
                        <IssueForm
                          initialIssue={issue}
                          isSubmitting={issueState.isMutating}
                          error={issueState.error}
                          onCancel={() => setEditingIssue(null)}
                          onSubmit={async (input) => {
                            const updated = await issueState.updateIssue(issue.id, input)
                            if (updated) {
                              setEditingIssue(null)
                              await activityState.refresh()
                            }
                            return updated
                          }}
                        />
                      </div>
                    </div>
                  ) : (
                    <IssueRow
                      issue={issue}
                      onEdit={() => { setShowIssueForm(false); setEditingIssue(issue) }}
                      onStatusChange={(status) => void handleIssueStatusChange(issue, status)}
                      onDelete={() => void handleIssueDelete(issue)}
                      disabled={issueState.isMutating}
                    />
                  )}
                </article>
              )
            })}
          </div>}

          {issueTotal > 0 && (
            <div className="mt-5 flex flex-col gap-3 border-t border-slate-100/80 pt-4 text-sm text-slate-600 dark:border-white/[0.06] dark:text-slate-400 sm:flex-row sm:items-center sm:justify-between">
              <p aria-live="polite">Showing {issueStart}–{issueEnd} of {issueTotal}</p>
              {issuePageCount > 1 && (
                <div className="flex flex-wrap items-center gap-2.5">
                  <button
                    type="button"
                    onClick={() => issueState.setPage(issuePage - 1)}
                    disabled={issuePage <= 1 || issueState.status === 'loading'}
                    className="makko-control makko-secondary makko-focus px-3 text-xs font-semibold disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    Previous
                  </button>
                  <span className="min-w-20 text-center text-xs font-semibold text-slate-700 dark:text-slate-300">Page {issuePage} of {issuePageCount}</span>
                  <button
                    type="button"
                    onClick={() => issueState.setPage(issuePage + 1)}
                    disabled={issuePage >= issuePageCount || issueState.status === 'loading'}
                    className="makko-control makko-secondary makko-focus px-3 text-xs font-semibold disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    Next
                  </button>
                </div>
              )}
            </div>
          )}
        </section>

        <ProjectActivitySection
          activityState={activityState}
        />
      </div>

      <div className="animate-fade-up delay-300 mt-8">
        <ProjectGithubSection
          projectId={project.id}
        />
      </div>
    </main>
  )
}

type ActivityState = ReturnType<typeof useProjectActivity>

function ProjectActivitySection({ activityState }: { activityState: ActivityState }) {
  const activityScope = activityState.scope ?? 'last_30_days'
  return (
    <section className="makko-surface animate-fade-up delay-200 min-w-0 rounded-3xl p-6 sm:p-8" aria-labelledby="activity-heading">
      <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-start">
        <div>
          <h2 id="activity-heading" className="text-2xl font-semibold text-slate-900 dark:text-white">Activity</h2>
          <p className="mt-1 text-sm font-normal leading-6 text-slate-600 dark:text-slate-400">A read-only record of changes in this project.</p>
        </div>
      </div>
      <fieldset className="mt-5 min-w-0">
        <legend className="text-xs font-semibold text-slate-700 dark:text-slate-300">Timeline range</legend>
        <div className="makko-well mt-2 inline-flex max-w-full rounded-2xl p-1" role="group" aria-label="Timeline range">
          {([
            ['last_30_days', 'Last 30 days'],
            ['all_time', 'All time'],
          ] as const).map(([value, label]) => {
            const isActive = activityScope === value
            return (
              <button
                key={value}
                type="button"
                aria-pressed={isActive}
                onClick={() => activityState.setScope(value as ActivityScope)}
                className={`makko-control makko-focus min-h-10 whitespace-nowrap px-3 text-xs font-semibold sm:px-4 ${isActive ? 'bg-white text-cyan-800 shadow-xs ring-1 ring-black/5 dark:bg-white/10 dark:text-cyan-200 dark:ring-white/10' : 'makko-ghost'}`}
              >
                {label}
              </button>
            )
          })}
        </div>
      </fieldset>
      {activityState.error && <div className="mt-6"><StatusMessage kind="error">{activityState.error}</StatusMessage></div>}
      {activityState.status === 'loading' && activityState.activity.length === 0 && <p className="mt-7 text-sm font-medium text-slate-600 dark:text-slate-400" role="status">Loading activity…</p>}
      {activityState.status === 'ready' && activityState.activity.length === 0 && (
        <p className="mt-7 rounded-2xl border border-dashed border-slate-200 p-6 text-center text-sm font-normal text-slate-500 dark:border-white/10 dark:text-slate-400">
          {activityScope === 'last_30_days' ? 'No activity in the last 30 days.' : 'Activity will appear as you work.'}
        </p>
      )}
      {activityState.activity.length > 0 && (
        <div className="mt-7 min-w-0 max-h-[28rem] overflow-x-hidden overflow-y-auto rounded-2xl border border-slate-100/80 p-4 dark:border-white/[0.06] sm:p-5">
          <ol className="min-w-0 space-y-5">
            {activityState.activity.map((event) => (
              <li key={event.id} className="relative min-w-0 border-l border-cyan-500/30 pl-5 dark:border-cyan-400/20">
                <span className="absolute -left-[11px] top-0.5 grid size-5 place-items-center rounded-full border border-cyan-500/25 bg-white text-cyan-700 dark:border-cyan-400/25 dark:bg-[#0c1527] dark:text-cyan-300" aria-hidden="true">
                  <ActivityIcon action={event.action} />
                </span>
                <p className="makko-readable min-w-0 break-words text-sm font-normal leading-6 text-slate-800 dark:text-slate-200">{event.description}</p>
                <p className="mt-1 min-w-0 break-words text-xs font-medium text-slate-500 dark:text-slate-400"><span className="capitalize font-semibold">{actionLabel(event.action)}</span> · {formatDate(event.created_at)}</p>
              </li>
            ))}
          </ol>
        </div>
      )}
      {activityState.hasMore && (
        <button
          type="button"
          onClick={() => void activityState.loadMore()}
          disabled={activityState.isLoadingMore}
          className="makko-control makko-secondary makko-focus mt-5 w-full px-4 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50"
        >
          {activityState.isLoadingMore ? 'Loading more activity…' : 'Load more activity'}
        </button>
      )}
    </section>
  )
}

function MissingProject() {
  return (
    <main className="makko-page">
      <h1 className="text-3xl font-bold text-slate-900 dark:text-white">That project isn’t available.</h1>
      <p className="mt-2 max-w-lg text-sm font-normal leading-6 text-slate-600 dark:text-slate-400">It may have been deleted, or you may not have access to it.</p>
      <Link
        to="/app"
        className="makko-control makko-secondary makko-focus mt-7 inline-flex items-center px-4 text-sm font-semibold"
      >
        Back to projects
      </Link>
    </main>
  )
}

interface IssueFiltersProps { filters: IssueFilters; onChange: (filters: IssueFilters) => void }
function IssueFilters({ filters, onChange }: IssueFiltersProps) {
  const update = <K extends keyof IssueFilters,>(key: K, value: IssueFilters[K]) => onChange({ ...filters, [key]: value })
  return (
    <fieldset className="mt-6 grid gap-3 border-t border-slate-100/80 pt-5 dark:border-white/[0.06] sm:grid-cols-2 xl:grid-cols-4">
      <legend className="sr-only">Filter and sort issues</legend>
      <FilterSelect id="filter-status" label="Status" value={filters.status} onChange={(value) => update('status', value as IssueFilters['status'])} options={[['all', 'All statuses'], ['todo', 'To do'], ['in_progress', 'In progress'], ['done', 'Done']]} />
      <FilterSelect id="filter-type" label="Type" value={filters.type} onChange={(value) => update('type', value as IssueFilters['type'])} options={[['all', 'All types'], ['task', 'Tasks'], ['bug', 'Bugs']]} />
      <FilterSelect id="filter-priority" label="Priority" value={filters.priority} onChange={(value) => update('priority', value as IssueFilters['priority'])} options={[['all', 'All priorities'], ['high', 'High'], ['medium', 'Medium'], ['low', 'Low']]} />
      <FilterSelect id="filter-sort" label="Sort" value={filters.sort} onChange={(value) => update('sort', value as IssueSort)} options={[['newest', 'Newest'], ['oldest', 'Oldest'], ['updated', 'Recently updated'], ['title', 'Title'], ['priority', 'Priority']]} />
    </fieldset>
  )
}

interface FilterSelectProps { id: string; label: string; value: string; options: readonly [string, string][]; onChange: (value: string) => void }
function FilterSelect({ id, label, value, options, onChange }: FilterSelectProps) {
  return (
    <div>
      <label htmlFor={id} className="mb-1.5 block text-xs font-semibold text-slate-700 dark:text-slate-300">{label}</label>
      <select
        id={id}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="makko-field w-full px-3 py-3 text-sm font-medium"
      >
        {options.map(([optionValue, optionLabel]) => <option key={optionValue} value={optionValue} className="bg-white text-slate-900 dark:bg-slate-900 dark:text-white">{optionLabel}</option>)}
      </select>
    </div>
  )
}

interface IssueRowProps { issue: Issue; onEdit: () => void; onStatusChange: (status: Issue['status']) => void; onDelete: () => void; disabled: boolean }
function IssueRow({ issue, onEdit, onStatusChange, onDelete, disabled }: IssueRowProps) {
  const statusStyles = {
    done: 'border-emerald-500/30 bg-emerald-500/10 text-emerald-800 dark:border-emerald-400/25 dark:bg-emerald-400/10 dark:text-emerald-300',
    in_progress: 'border-cyan-500/30 bg-cyan-500/10 text-cyan-800 dark:border-cyan-400/25 dark:bg-cyan-400/10 dark:text-cyan-300',
    todo: 'border-slate-200/80 bg-slate-100/90 text-slate-700 dark:border-white/15 dark:bg-white/[0.05] dark:text-slate-300',
  }

  const priorityStyles = {
    high: 'border-rose-500/30 bg-rose-500/10 text-rose-700 dark:border-rose-400/25 dark:bg-rose-400/10 dark:text-rose-300',
    medium: 'border-amber-500/30 bg-amber-500/10 text-amber-700 dark:border-amber-400/25 dark:bg-amber-400/10 dark:text-amber-300',
    low: 'border-slate-200/80 bg-slate-100/90 text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-400',
  }

  const StatusIcon = issue.status === 'done' ? CircleCheck : issue.status === 'in_progress' ? CircleDot : Circle
  const statusIconColor = issue.status === 'done'
    ? 'text-emerald-600 dark:text-emerald-300'
    : issue.status === 'in_progress'
      ? 'text-cyan-600 dark:text-cyan-300'
      : 'text-slate-400 dark:text-slate-500'

  return (
    <div className="flex min-w-0 flex-col gap-3 py-0.5 sm:flex-row sm:items-start sm:justify-between">
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <StatusIcon className={`size-4 shrink-0 ${statusIconColor}`} aria-hidden="true" />
          <h3 className="makko-readable text-sm font-semibold text-slate-900 dark:text-white">{issue.title}</h3>
        </div>
        {issue.description && (
          <p className="makko-readable mt-1 text-xs leading-5 text-slate-500 dark:text-slate-400">{issue.description}</p>
        )}
      </div>

      <div className="flex shrink-0 flex-wrap items-center gap-2">
        <span className="rounded-full border border-slate-200/70 bg-slate-100/80 px-2 py-0.5 text-[11px] font-medium capitalize text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-400">
          {issue.type}
        </span>
        <span className={`rounded-full border px-2 py-0.5 text-[11px] font-medium capitalize ${priorityStyles[issue.priority]}`}>
          {issue.priority} priority
        </span>

        <label className={`inline-flex min-h-11 items-center rounded-full border px-2.5 py-1 text-xs font-medium transition-all focus-within:ring-2 focus-within:ring-cyan-500 dark:focus-within:ring-cyan-400 ${statusStyles[issue.status]}`}>
          <span className="sr-only">Status for {issue.title}</span>
          <select
            aria-label={`Status for ${issue.title}`}
            value={issue.status}
            onChange={(event) => onStatusChange(event.target.value as Issue['status'])}
            disabled={disabled}
            className="cursor-pointer bg-transparent text-xs font-medium outline-none disabled:cursor-not-allowed"
          >
            <option value="todo" className="bg-white text-slate-900 dark:bg-slate-900 dark:text-white">To do</option>
            <option value="in_progress" className="bg-white text-slate-900 dark:bg-slate-900 dark:text-white">In progress</option>
            <option value="done" className="bg-white text-slate-900 dark:bg-slate-900 dark:text-white">Done</option>
          </select>
        </label>

        <div className="flex items-center gap-1 pl-1">
          <button
            type="button"
            onClick={onEdit}
            className="makko-control makko-focus makko-ghost px-3 text-xs font-semibold"
          >
            Edit
          </button>
          <button
            type="button"
            onClick={onDelete}
            disabled={disabled}
            className="makko-control makko-focus makko-danger px-3 text-xs font-semibold disabled:cursor-not-allowed disabled:opacity-50"
          >
            Delete
          </button>
        </div>
      </div>
    </div>
  )
}

function ProjectDetailSkeleton() {
  return (
      <main className="makko-page" role="status" aria-label="Loading project">
      <span className="sr-only">Loading project…</span>

      {/* Back button placeholder */}
      <div className="h-5 w-24 rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />

      {/* Header skeleton */}
      <div className="mt-6 rounded-3xl border border-slate-200/80 bg-white/80 p-6 shadow-xs dark:border-white/10 dark:bg-[#0c1527]/75 sm:p-8">
        <div className="flex flex-col justify-between gap-5 sm:flex-row sm:items-start">
          <div className="space-y-3 flex-1">
            <div className="h-9 w-64 rounded-xl bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="h-4 w-96 max-w-full rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="flex gap-2 pt-1">
              <div className="h-5 w-16 rounded-full bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
              <div className="h-5 w-20 rounded-full bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            </div>
          </div>
          <div className="flex gap-2.5">
            <div className="h-9 w-28 rounded-2xl bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="h-9 w-20 rounded-2xl bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
          </div>
        </div>
      </div>

      {/* Issues and Activity grid skeleton */}
      <div className="mt-8 grid gap-8 md:grid-cols-[minmax(0,1.45fr)_minmax(18rem,0.75fr)]">
        {/* Issues list skeleton */}
        <div className="rounded-3xl border border-slate-200/80 bg-white/80 p-6 shadow-xs dark:border-white/10 dark:bg-[#0c1527]/70 sm:p-8">
          <div className="flex justify-between items-center">
            <div className="h-7 w-28 rounded-lg bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="h-10 w-28 rounded-2xl bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
          </div>
          <div className="mt-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4 border-t border-slate-100 pt-5 dark:border-white/5">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="h-9 rounded-2xl bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            ))}
          </div>
          <div className="mt-6 space-y-3">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="h-14 rounded-2xl bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            ))}
          </div>
        </div>

        {/* Activity skeleton */}
        <div className="rounded-3xl border border-slate-200/80 bg-white/80 p-6 shadow-xs dark:border-white/10 dark:bg-[#0c1527]/70 sm:p-8">
          <div className="h-7 w-28 rounded-lg bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
          <div className="mt-6 space-y-5">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="space-y-2 border-l border-slate-200 pl-5 dark:border-white/10">
                <div className="h-4 w-4/5 rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
                <div className="h-3 w-1/3 rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* GitHub section skeleton */}
      <div className="mt-8 rounded-3xl border border-slate-200/80 bg-white/80 p-6 shadow-xs dark:border-white/10 dark:bg-[#0c1527]/70 sm:p-8">
        <div className="h-6 w-44 rounded-lg bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
        <div className="mt-2 h-4 w-80 max-w-full rounded-md bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
        <div className="mt-6 h-14 w-full rounded-2xl bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
      </div>
    </main>
  )
}
