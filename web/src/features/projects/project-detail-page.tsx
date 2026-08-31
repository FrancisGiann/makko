import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'

import { StatusMessage } from '../../components/status-message'
import { useProject } from '../../hooks/use-project'
import { useProjectActivity } from '../../hooks/use-project-activity'
import { useProjectIssues } from '../../hooks/use-project-issues'
import type { ActivityLog, Issue } from '../../types/domain'
import { DEFAULT_ISSUE_FILTERS, filterAndSortIssues, type IssueFilters, type IssueSort } from '../../utils/issue-filters'
import { IssueForm } from '../issues/issue-form'
import { ProjectForm } from './project-form'

function formatDate(value: string): string {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? 'Unknown date' : date.toLocaleString()
}

function statusLabel(status: Issue['status']): string {
  return status === 'in_progress' ? 'In progress' : status === 'todo' ? 'To do' : 'Done'
}

function actionLabel(action: ActivityLog['action']): string {
  return action.replace('.', ' · ')
}

export function ProjectDetailPage() {
  const { projectId } = useParams<{ projectId: string }>()
  const navigate = useNavigate()
  const projectState = useProject(projectId)
  const issueState = useProjectIssues(projectId)
  const activityState = useProjectActivity(projectId)
  const [showProjectEdit, setShowProjectEdit] = useState(false)
  const [showIssueForm, setShowIssueForm] = useState(false)
  const [editingIssue, setEditingIssue] = useState<Issue | null>(null)
  const [filters, setFilters] = useState<IssueFilters>(DEFAULT_ISSUE_FILTERS)

  if (!projectId) return <MissingProject />

  if (projectState.status === 'loading' && !projectState.project) {
    return <main className="mx-auto max-w-6xl px-5 py-16 sm:px-8"><p className="text-sm text-slate-400" role="status">Loading project…</p></main>
  }

  if (projectState.status === 'error') {
    return <main className="mx-auto max-w-6xl px-5 py-16 sm:px-8"><StatusMessage kind="error">{projectState.error ?? 'Unable to load that project.'}</StatusMessage><Link to="/app" className="mt-6 inline-flex rounded-lg border border-white/15 px-3 py-2 text-sm text-slate-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">Back to projects</Link></main>
  }

  if (!projectState.project) return <MissingProject />
  const project = projectState.project
  const visibleIssues = filterAndSortIssues(issueState.issues, filters)

  const handleDeleteProject = async () => {
    if (!window.confirm(`Delete “${project.name}” and all of its issues? This cannot be undone.`)) return
    if (await projectState.deleteProject()) navigate('/app', { replace: true })
  }

  const handleIssueDelete = async (issue: Issue) => {
    if (!window.confirm(`Delete “${issue.title}”? Its deletion will remain in the project activity.`)) return
    if (await issueState.deleteIssue(issue.id)) await activityState.refresh()
  }

  return (
    <main className="mx-auto max-w-6xl px-5 py-10 sm:px-8 sm:py-14">
      <Link to="/app" className="text-sm text-slate-400 underline decoration-white/20 underline-offset-4 transition hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">← All projects</Link>
      <header className="mt-7 rounded-3xl border border-white/10 bg-slate-900/65 p-6 shadow-2xl shadow-cyan-950/10 sm:p-8">
        {showProjectEdit ? (
          <>
            <h1 className="text-2xl font-semibold text-white">Edit project</h1>
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
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-200">Project</p>
                <h1 className="mt-3 text-3xl font-semibold tracking-tight text-white sm:text-4xl">{project.name}</h1>
                <p className="mt-3 max-w-2xl text-sm leading-7 text-slate-400">{project.description ?? 'No description yet.'}</p>
                {project.tags.length > 0 && <ul className="mt-5 flex flex-wrap gap-2" aria-label="Project tags">{project.tags.map((tag) => <li key={tag} className="rounded-full border border-white/10 px-2.5 py-1 text-xs text-slate-400">{tag}</li>)}</ul>}
              </div>
              <div className="flex shrink-0 flex-wrap gap-2">
                <button type="button" onClick={() => setShowProjectEdit(true)} className="rounded-lg border border-white/15 px-3 py-2 text-sm text-slate-200 transition hover:border-cyan-200/40 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">Edit project</button>
                <button type="button" onClick={() => void handleDeleteProject()} disabled={projectState.isMutating} className="rounded-lg px-3 py-2 text-sm text-rose-200/80 transition hover:text-rose-100 disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-rose-200">Delete</button>
              </div>
            </div>
          </>
        )}
      </header>

      <div className="mt-8 grid gap-8 lg:grid-cols-[minmax(0,1.45fr)_minmax(18rem,0.75fr)]">
        <section className="min-w-0 rounded-3xl border border-white/10 bg-slate-900/50 p-6 sm:p-8" aria-labelledby="issues-heading">
          <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-start">
            <div><p className="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-200">Work queue</p><h2 id="issues-heading" className="mt-2 text-2xl font-semibold text-white">Issues</h2><p className="mt-2 text-sm text-slate-400">Tasks and bugs for this project.</p></div>
            <button type="button" onClick={() => { setEditingIssue(null); setShowIssueForm((open) => !open) }} aria-expanded={showIssueForm} className="rounded-xl bg-cyan-200 px-4 py-3 text-sm font-semibold text-slate-950 transition hover:bg-cyan-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-100">{showIssueForm ? 'Close form' : 'New issue'}</button>
          </div>

          {showIssueForm && <div className="mt-7 rounded-2xl border border-cyan-200/15 bg-slate-950/40 p-5"><h3 className="text-lg font-semibold text-white">Create an issue</h3><div className="mt-5"><IssueForm isSubmitting={issueState.isMutating} error={issueState.error} onCancel={() => setShowIssueForm(false)} onSubmit={async (input) => { const created = await issueState.createIssue(input); if (created) { setShowIssueForm(false); await activityState.refresh() } return created }} /></div></div>}
          {issueState.error && !showIssueForm && <div className="mt-6"><StatusMessage kind="error">{issueState.error}</StatusMessage></div>}
          <IssueFilters filters={filters} onChange={setFilters} />
          {issueState.status === 'loading' && issueState.issues.length === 0 && <p className="mt-7 text-sm text-slate-400" role="status">Loading issues…</p>}
          {issueState.status === 'error' && issueState.issues.length === 0 && !issueState.error && <div className="mt-7"><StatusMessage kind="error">Unable to load issues.</StatusMessage></div>}
          {issueState.status === 'ready' && visibleIssues.length === 0 && <div className="mt-7 rounded-2xl border border-dashed border-white/15 px-5 py-10 text-center"><p className="text-sm font-medium text-slate-200">{issueState.issues.length ? 'No issues match these filters.' : 'No issues yet.'}</p><p className="mt-2 text-sm text-slate-500">{issueState.issues.length ? 'Try widening the filters.' : 'Capture the next piece of work when it arrives.'}</p></div>}
          <div className="mt-7 space-y-3">
            {visibleIssues.map((issue) => (
              <article key={issue.id} className="rounded-2xl border border-white/10 bg-slate-950/35 p-4 sm:p-5">
                {editingIssue?.id === issue.id ? <><h3 className="text-lg font-semibold text-white">Edit issue</h3><div className="mt-5"><IssueForm initialIssue={issue} isSubmitting={issueState.isMutating} error={issueState.error} onCancel={() => setEditingIssue(null)} onSubmit={async (input) => { const updated = await issueState.updateIssue(issue.id, input); if (updated) { setEditingIssue(null); await activityState.refresh() } return updated }} /></div></> : <IssueRow issue={issue} onEdit={() => { setShowIssueForm(false); setEditingIssue(issue) }} onDelete={() => void handleIssueDelete(issue)} disabled={issueState.isMutating} />}
              </article>
            ))}
          </div>
        </section>

        <section className="rounded-3xl border border-white/10 bg-slate-900/50 p-6 sm:p-8" aria-labelledby="activity-heading">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-200">Project history</p><h2 id="activity-heading" className="mt-2 text-2xl font-semibold text-white">Activity</h2><p className="mt-2 text-sm leading-6 text-slate-400">A read-only record of changes in this project.</p>
          {activityState.error && <div className="mt-6"><StatusMessage kind="error">{activityState.error}</StatusMessage></div>}
          {activityState.status === 'loading' && activityState.activity.length === 0 && <p className="mt-7 text-sm text-slate-400" role="status">Loading activity…</p>}
          {activityState.status === 'ready' && activityState.activity.length === 0 && <p className="mt-7 rounded-2xl border border-dashed border-white/15 px-4 py-8 text-center text-sm text-slate-500">Activity will appear as you work.</p>}
          <ol className="mt-7 space-y-5">
            {activityState.activity.map((event) => <li key={event.id} className="relative border-l border-cyan-200/20 pl-5"><span className="absolute -left-1.5 top-1 size-2.5 rounded-full bg-cyan-200" aria-hidden="true" /><p className="text-sm leading-6 text-slate-200">{event.description}</p><p className="mt-1 text-xs text-slate-500"><span className="capitalize">{actionLabel(event.action)}</span> · {formatDate(event.created_at)}</p></li>)}
          </ol>
        </section>
      </div>
    </main>
  )
}

function MissingProject() {
  return <main className="mx-auto max-w-6xl px-5 py-16 sm:px-8"><p className="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-200">Project not found</p><h1 className="mt-4 text-3xl font-semibold text-white">That project isn’t available.</h1><p className="mt-3 max-w-lg text-sm leading-7 text-slate-400">It may have been deleted, or you may not have access to it.</p><Link to="/app" className="mt-7 inline-flex rounded-xl border border-white/15 px-4 py-3 text-sm text-slate-200 transition hover:border-cyan-200/40 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">Back to projects</Link></main>
}

interface IssueFiltersProps { filters: IssueFilters; onChange: (filters: IssueFilters) => void }
function IssueFilters({ filters, onChange }: IssueFiltersProps) {
  const update = <K extends keyof IssueFilters,>(key: K, value: IssueFilters[K]) => onChange({ ...filters, [key]: value })
  return <fieldset className="mt-7 grid gap-3 border-t border-white/10 pt-6 sm:grid-cols-2 xl:grid-cols-4"><legend className="sr-only">Filter and sort issues</legend><FilterSelect id="filter-status" label="Status" value={filters.status} onChange={(value) => update('status', value as IssueFilters['status'])} options={[['all', 'All statuses'], ['todo', 'To do'], ['in_progress', 'In progress'], ['done', 'Done']]} /><FilterSelect id="filter-type" label="Type" value={filters.type} onChange={(value) => update('type', value as IssueFilters['type'])} options={[['all', 'All types'], ['task', 'Tasks'], ['bug', 'Bugs']]} /><FilterSelect id="filter-priority" label="Priority" value={filters.priority} onChange={(value) => update('priority', value as IssueFilters['priority'])} options={[['all', 'All priorities'], ['high', 'High'], ['medium', 'Medium'], ['low', 'Low']]} /><FilterSelect id="filter-sort" label="Sort" value={filters.sort} onChange={(value) => update('sort', value as IssueSort)} options={[['newest', 'Newest'], ['oldest', 'Oldest'], ['updated', 'Recently updated'], ['title', 'Title'], ['priority', 'Priority']]} /></fieldset>
}

interface FilterSelectProps { id: string; label: string; value: string; options: readonly [string, string][]; onChange: (value: string) => void }
function FilterSelect({ id, label, value, options, onChange }: FilterSelectProps) { return <div><label htmlFor={id} className="mb-1.5 block text-xs font-medium text-slate-400">{label}</label><select id={id} value={value} onChange={(event) => onChange(event.target.value)} className="w-full rounded-lg border border-white/10 bg-slate-950/50 px-3 py-2.5 text-sm text-slate-200 outline-none transition focus:border-cyan-200/60 focus:ring-2 focus:ring-cyan-200/20">{options.map(([optionValue, optionLabel]) => <option key={optionValue} value={optionValue}>{optionLabel}</option>)}</select></div> }

interface IssueRowProps { issue: Issue; onEdit: () => void; onDelete: () => void; disabled: boolean }
function IssueRow({ issue, onEdit, onDelete, disabled }: IssueRowProps) { return <div><div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-start"><div className="min-w-0"><h3 className="font-medium text-white">{issue.title}</h3><p className="mt-1 text-sm leading-6 text-slate-400">{issue.description ?? 'No description.'}</p></div><span className={`shrink-0 self-start rounded-full border px-2.5 py-1 text-xs ${issue.status === 'done' ? 'border-emerald-300/20 bg-emerald-300/10 text-emerald-200' : issue.status === 'in_progress' ? 'border-cyan-300/20 bg-cyan-300/10 text-cyan-100' : 'border-white/15 text-slate-400'}`}>{statusLabel(issue.status)}</span></div><div className="mt-4 flex flex-wrap items-center gap-2 text-xs text-slate-500"><span className="rounded-full border border-white/10 px-2 py-1 capitalize">{issue.type}</span><span className="rounded-full border border-white/10 px-2 py-1 capitalize">{issue.priority} priority</span><span className="ml-auto flex gap-2"><button type="button" onClick={onEdit} className="rounded px-2 py-1 text-slate-400 transition hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">Edit</button><button type="button" onClick={onDelete} disabled={disabled} className="rounded px-2 py-1 text-rose-200/80 transition hover:text-rose-100 disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-rose-200">Delete</button></span></div></div> }
