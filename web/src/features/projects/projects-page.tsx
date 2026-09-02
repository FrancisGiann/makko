import { useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowRight, Bug, CircleCheck, CircleDot, FolderOpen, RotateCw } from 'lucide-react'

import { ProjectIdentity } from '../../components/project-identity'
import { StatusMessage } from '../../components/status-message'
import { useProjectIssues } from '../../hooks/use-project-issues'
import type { IssueService } from '../../services/issue.service'
import { useProjects } from '../../hooks/use-projects'
import type { ProjectService } from '../../services/project.service'
import type { Issue, IssuePriority, IssueStatus, Project } from '../../types/domain'
import { ProjectForm } from './project-form'

function formatDate(value: string): string {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? 'Recently updated' : `Updated ${date.toLocaleDateString()}`
}

interface ProjectsPageProps {
  service?: ProjectService
  issueService?: IssueService
}

export function ProjectsPage({ service, issueService }: ProjectsPageProps) {
  const { projects, status, error, isMutating, createProject, updateProject, deleteProject } = useProjects(service)
  const [showCreateForm, setShowCreateForm] = useState(false)
  const [editingProject, setEditingProject] = useState<Project | null>(null)

  const handleDelete = async (project: Project) => {
    if (!window.confirm(`Delete “${project.name}” and all of its issues? This cannot be undone.`)) return
    await deleteProject(project.id)
  }

  const isLoading = status === 'loading' && projects.length === 0

  return (
    <main className="makko-page">
      <header className="animate-fade-up flex flex-col justify-between gap-5 sm:flex-row sm:items-end">
        <div className="min-w-0">
          <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-4xl">Projects</h1>
          <p className="mt-2 max-w-xl text-sm font-normal leading-6 text-slate-600 dark:text-slate-400">Keep the shape of each thing you’re building close at hand.</p>
        </div>
        <button
          type="button"
          onClick={() => { setEditingProject(null); setShowCreateForm((open) => !open) }}
          aria-expanded={showCreateForm}
          className="makko-control makko-primary makko-focus inline-flex items-center justify-center px-5 text-sm font-semibold"
        >
          {showCreateForm ? 'Close form' : 'New project'}
        </button>
      </header>

      {showCreateForm && (
        <section className="animate-fade-up mt-8 rounded-3xl border border-cyan-500/25 bg-cyan-500/[0.06] p-6 shadow-sm dark:border-cyan-400/20 dark:bg-cyan-400/[0.06] sm:p-8" aria-labelledby="create-project-heading">
          <h2 id="create-project-heading" className="text-xl font-semibold text-slate-900 dark:text-white">Start a project</h2>
          <p className="mt-1 text-sm font-normal text-slate-600 dark:text-slate-400">Give it enough context that the next step feels obvious.</p>
          <div className="mt-6">
            <ProjectForm
              isSubmitting={isMutating}
              error={error}
              onCancel={() => setShowCreateForm(false)}
              onSubmit={async (input) => {
                const created = await createProject(input)
                if (created) setShowCreateForm(false)
                return created
              }}
            />
          </div>
        </section>
      )}

      {error && !showCreateForm && <div className="mt-8"><StatusMessage kind="error">{error}</StatusMessage></div>}

      {isLoading && <ProjectsSkeleton />}

      {!isLoading && status === 'error' && projects.length === 0 && !error && (
        <div className="mt-10"><StatusMessage kind="error">Unable to load your projects.</StatusMessage></div>
      )}

      {!isLoading && status !== 'error' && projects.length === 0 && (
        <section className="animate-fade-up delay-100 mt-10 rounded-3xl border border-dashed border-cyan-500/30 bg-cyan-500/[0.04] p-8 text-center dark:border-cyan-400/20 dark:bg-cyan-400/[0.04] sm:p-14">
          <div className="mx-auto mb-4 grid size-14 place-items-center rounded-3xl border border-cyan-500/25 bg-cyan-500/10 text-cyan-700 dark:border-cyan-400/30 dark:bg-cyan-400/10 dark:text-cyan-300">
            <FolderOpen className="size-6" />
          </div>
          <p className="text-lg font-semibold text-slate-900 dark:text-slate-100">No projects yet.</p>
          <p className="mx-auto mt-2 max-w-md text-sm font-normal leading-6 text-slate-600 dark:text-slate-400">Create a project to give your ideas a place to gather.</p>
          {!showCreateForm && (
            <button
              type="button"
              onClick={() => setShowCreateForm(true)}
              className="makko-control makko-primary makko-focus mt-6 inline-flex items-center gap-2 px-5 text-sm font-semibold"
            >
              <span>Create your first project</span>
              <ArrowRight className="size-4" aria-hidden="true" />
            </button>
          )}
        </section>
      )}

      <div className="mt-8 grid gap-6">
        {projects.map((project, index) => {
          const delays = ['delay-0', 'delay-100', 'delay-200', 'delay-300', 'delay-400', 'delay-500']
          const delayClass = delays[index % delays.length]
          return (
            <article
              key={project.id}
              className={`makko-surface animate-fade-up ${delayClass} group relative flex min-w-0 flex-col justify-between rounded-3xl p-6 transition-all duration-200 hover:border-slate-300 hover:shadow-md dark:hover:border-white/20 sm:p-7`}
            >
              {editingProject?.id === project.id ? (
                <div>
                  <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Edit project</h2>
                  <div className="mt-5">
                    <ProjectForm
                      initialProject={project}
                      isSubmitting={isMutating}
                      error={error}
                      onCancel={() => setEditingProject(null)}
                      onSubmit={async (input) => {
                        const updated = await updateProject(project.id, input)
                        if (updated) setEditingProject(null)
                        return updated
                      }}
                    />
                  </div>
                </div>
              ) : (
                <>
                  <div>
                    <div className="flex min-w-0 items-start gap-3">
                      <ProjectIdentity name={project.name} tags={project.tags} size="sm" />
                      <div className="min-w-0">
                        <Link
                          to={`/app/projects/${project.id}`}
                          className="makko-focus makko-readable inline-flex min-h-11 max-w-full items-center text-lg font-semibold text-slate-900 underline decoration-transparent underline-offset-4 transition hover:text-cyan-700 hover:decoration-cyan-600 dark:text-white dark:hover:text-cyan-200 dark:hover:decoration-cyan-300"
                        >
                          {project.name}
                        </Link>
                        <p className="mt-1.5 text-xs font-medium text-slate-500 dark:text-slate-400">{formatDate(project.updated_at)}</p>
                      </div>
                    </div>
                    <p className="makko-readable mt-4 min-h-12 text-sm font-normal leading-6 text-slate-600 dark:text-slate-300">{project.description ?? 'No description yet.'}</p>
                    {project.tags.length > 0 && (
                      <ul className="mt-4 flex flex-wrap gap-1.5" aria-label={`${project.name} tags`}>
                        {project.tags.map((tag) => (
                          <li key={tag} className="rounded-full border border-slate-200/70 bg-slate-100/80 px-2.5 py-0.5 text-xs font-medium text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-300">
                            {tag}
                          </li>
                        ))}
                      </ul>
                    )}
                    <ProjectIssuePreview projectId={project.id} projectName={project.name} service={issueService} />
                  </div>
                  <div className="mt-6 flex flex-wrap items-center gap-2.5 border-t border-slate-100/80 pt-5 dark:border-white/[0.06]">
                    <Link
                      to={`/app/projects/${project.id}`}
                      className="makko-control makko-secondary makko-focus inline-flex items-center px-4 text-sm font-semibold"
                    >
                      Open project
                    </Link>
                    <button
                      type="button"
                      onClick={() => { setShowCreateForm(false); setEditingProject(project) }}
                      className="makko-control makko-focus makko-ghost px-3.5 text-sm font-semibold"
                    >
                      Edit
                    </button>
                    <button
                      type="button"
                      onClick={() => void handleDelete(project)}
                      disabled={isMutating}
                      className="makko-control makko-focus makko-danger px-3.5 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50"
                    >
                      Delete
                    </button>
                  </div>
                </>
              )}
            </article>
          )
        })}
      </div>
    </main>
  )
}

function ProjectsSkeleton() {
  return (
    <div className="mt-8 grid gap-6" role="status" aria-label="Loading your projects">
      <span className="sr-only">Loading your projects…</span>
      {[1, 2, 3, 4].map((i) => (
        <div
          key={i}
          className="makko-surface flex flex-col justify-between rounded-3xl p-6 sm:p-7"
        >
          <div>
            <div className="flex items-start justify-between gap-4">
              <div className="space-y-2">
                <div className="h-6 w-44 rounded-lg bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
                <div className="h-3.5 w-24 rounded bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
              </div>
            </div>
            <div className="mt-5 space-y-2">
              <div className="h-4 w-5/6 rounded bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
              <div className="h-4 w-3/5 rounded bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            </div>
            <div className="mt-5 flex gap-2">
              <div className="h-5 w-16 rounded-full bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
              <div className="h-5 w-20 rounded-full bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            </div>
          </div>
          <div className="mt-6 flex items-center gap-3 border-t border-slate-100/80 pt-5 dark:border-white/[0.06]">
            <div className="h-9 w-28 rounded-2xl bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="h-9 w-16 rounded-2xl bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
            <div className="h-9 w-16 rounded-2xl bg-slate-200/80 dark:bg-white/5 animate-shimmer" />
          </div>
        </div>
      ))}
    </div>
  )
}

interface ProjectIssuePreviewProps {
  projectId: string
  projectName: string
  service?: IssueService
}

function issueStatusLabel(status: IssueStatus): string {
  return status === 'in_progress' ? 'In progress' : status === 'todo' ? 'To do' : 'Done'
}

function issuePriorityLabel(priority: IssuePriority): string {
  return `${priority[0].toUpperCase()}${priority.slice(1)} priority`
}

function issueStatusClass(status: IssueStatus): string {
  if (status === 'done') return 'border-emerald-500/25 bg-emerald-500/10 text-emerald-800 dark:border-emerald-400/25 dark:bg-emerald-400/10 dark:text-emerald-200'
  if (status === 'in_progress') return 'border-cyan-500/25 bg-cyan-500/10 text-cyan-800 dark:border-cyan-400/25 dark:bg-cyan-400/10 dark:text-cyan-200'
  return 'border-slate-200/80 bg-slate-100/80 text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-300'
}

function issueTypeClass(type: Issue['type']): string {
  return type === 'bug' ? 'text-rose-700 dark:text-rose-300' : 'text-cyan-700 dark:text-cyan-300'
}

function ProjectIssuePreview({ projectId, projectName, service }: ProjectIssuePreviewProps) {
  const issueState = useProjectIssues(projectId, service)
  const issueCount = issueState.total
  const previewLimit = issueState.pageSize > 0 ? issueState.pageSize : 5
  const previewIssues = issueState.issues.slice(0, previewLimit)
  const isInitialLoading = issueState.status === 'loading' && previewIssues.length === 0
  const issueHeadingId = `project-${projectId}-issues-heading`

  return (
    <section className="mt-7 border-t border-slate-200/70 pt-5 dark:border-white/[0.07]" aria-labelledby={issueHeadingId}>
      <div className="flex flex-wrap items-center justify-between gap-2.5">
        <div className="flex items-center gap-2.5">
          <h3 id={issueHeadingId} className="text-sm font-semibold text-slate-900 dark:text-white">Issue queue</h3>
          <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-600 dark:bg-white/[0.06] dark:text-slate-300">
            {issueCount} {issueCount === 1 ? 'issue' : 'issues'}
          </span>
        </div>
        <Link
          to={`/app/projects/${projectId}`}
          className="makko-focus inline-flex min-h-9 items-center gap-1 text-xs font-semibold text-cyan-700 underline decoration-cyan-500/40 underline-offset-4 transition hover:text-cyan-900 dark:text-cyan-300 dark:hover:text-cyan-100"
        >
          View all issues
          <ArrowRight className="size-3.5" aria-hidden="true" />
        </Link>
      </div>

      {isInitialLoading && <ProjectIssuesSkeleton projectName={projectName} />}

      {issueState.status === 'error' && (
        <div className="mt-4 flex flex-col gap-3 rounded-2xl border border-rose-500/25 bg-rose-500/[0.06] p-4 dark:border-rose-400/20 dark:bg-rose-400/[0.06] sm:flex-row sm:items-center sm:justify-between" role="alert">
          <p className="text-sm leading-6 text-rose-800 dark:text-rose-200">{issueState.error ?? 'Unable to load issues.'}</p>
          <button
            type="button"
            onClick={() => void issueState.refresh()}
            className="makko-control makko-secondary makko-focus inline-flex shrink-0 items-center justify-center gap-1.5 px-3.5 text-xs font-semibold"
          >
            <RotateCw className="size-3.5" aria-hidden="true" />
            Retry issues
          </button>
        </div>
      )}

      {issueState.status === 'ready' && issueState.issues.length === 0 && (
        <div className="mt-4 rounded-2xl border border-dashed border-slate-200 p-4 dark:border-white/10">
          <p className="text-sm font-medium text-slate-700 dark:text-slate-300">No issues yet.</p>
          <p className="mt-1 text-xs leading-5 text-slate-500 dark:text-slate-400">Tasks and bugs for this project will appear here.</p>
        </div>
      )}

      {previewIssues.length > 0 && (
        <>
          <ul className="mt-4 divide-y divide-slate-200/70 rounded-2xl border border-slate-200/70 dark:divide-white/[0.07] dark:border-white/[0.08]" aria-label={`${projectName} issue queue`}>
            {previewIssues.map((issue) => <ProjectIssueRow key={issue.id} issue={issue} />)}
          </ul>
          {issueCount > previewIssues.length && (
            <p className="mt-2 text-right text-xs text-slate-500 dark:text-slate-400">Showing {previewIssues.length} of {issueCount} issues</p>
          )}
        </>
      )}
    </section>
  )
}

function ProjectIssuesSkeleton({ projectName }: { projectName: string }) {
  return (
    <div className="mt-4 space-y-3" role="status" aria-label={`Loading issues for ${projectName}`}>
      <span className="sr-only">Loading issues for {projectName}…</span>
      {[1, 2].map((item) => (
        <div key={item} className="flex items-center gap-3 rounded-2xl border border-slate-200/60 p-3 dark:border-white/[0.06]">
          <div className="size-4 rounded-full bg-slate-200/80 animate-shimmer dark:bg-white/5" />
          <div className="min-w-0 flex-1 space-y-2">
            <div className="h-4 w-3/5 rounded bg-slate-200/80 animate-shimmer dark:bg-white/5" />
            <div className="h-3 w-2/5 rounded bg-slate-200/80 animate-shimmer dark:bg-white/5" />
          </div>
          <div className="h-6 w-16 rounded-full bg-slate-200/80 animate-shimmer dark:bg-white/5" />
        </div>
      ))}
    </div>
  )
}

function ProjectIssueRow({ issue }: { issue: Issue }) {
  const Icon = issue.type === 'bug' ? Bug : issue.status === 'done' ? CircleCheck : CircleDot
  return (
    <li className="flex min-w-0 items-center gap-3 px-3.5 py-3 transition-colors first:rounded-t-2xl last:rounded-b-2xl hover:bg-white dark:hover:bg-white/[0.04] sm:px-4">
      <Icon className={`size-4 shrink-0 ${issueTypeClass(issue.type)}`} aria-hidden="true" />
      <div className="min-w-0 flex-1">
        <p className="makko-readable truncate text-sm font-medium text-slate-800 dark:text-slate-200" title={issue.title}>{issue.title}</p>
        <div className="mt-1 flex flex-wrap items-center gap-x-2 gap-y-0.5 text-xs text-slate-500 dark:text-slate-400">
          <span className={issueTypeClass(issue.type)}>{issue.type === 'bug' ? 'Bug' : 'Task'}</span>
          <span aria-hidden="true">·</span>
          <span>{issuePriorityLabel(issue.priority)}</span>
        </div>
      </div>
      <span className={`shrink-0 rounded-full border px-2.5 py-1 text-xs font-medium ${issueStatusClass(issue.status)}`}>
        {issueStatusLabel(issue.status)}
      </span>
    </li>
  )
}
