import { useState } from 'react'
import { Link } from 'react-router-dom'

import { StatusMessage } from '../../components/status-message'
import { useProjects } from '../../hooks/use-projects'
import type { ProjectService } from '../../services/project.service'
import type { Project } from '../../types/domain'
import { ProjectForm } from './project-form'

function formatDate(value: string): string {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? 'Recently updated' : `Updated ${date.toLocaleDateString()}`
}

interface ProjectsPageProps { service?: ProjectService }

export function ProjectsPage({ service }: ProjectsPageProps) {
  const { projects, status, error, isMutating, createProject, updateProject, deleteProject } = useProjects(service)
  const [showCreateForm, setShowCreateForm] = useState(false)
  const [editingProject, setEditingProject] = useState<Project | null>(null)

  const handleDelete = async (project: Project) => {
    if (!window.confirm(`Delete “${project.name}” and all of its issues? This cannot be undone.`)) return
    await deleteProject(project.id)
  }

  const isLoading = status === 'loading' && projects.length === 0

  return (
    <main className="mx-auto max-w-6xl px-5 py-10 sm:px-8 sm:py-14">
      <div className="flex flex-col justify-between gap-5 sm:flex-row sm:items-end">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-200">Your workspace</p>
          <h1 className="mt-3 text-3xl font-semibold tracking-tight text-white sm:text-4xl">Projects</h1>
          <p className="mt-3 max-w-xl text-sm leading-7 text-slate-400">Keep the shape of each thing you’re building close at hand.</p>
        </div>
        <button
          type="button"
          onClick={() => { setEditingProject(null); setShowCreateForm((open) => !open) }}
          aria-expanded={showCreateForm}
          className="rounded-xl bg-cyan-200 px-4 py-3 text-sm font-semibold text-slate-950 transition hover:bg-cyan-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-100"
        >
          {showCreateForm ? 'Close form' : 'New project'}
        </button>
      </div>

      {showCreateForm && (
        <section className="mt-8 rounded-3xl border border-cyan-200/15 bg-slate-900/70 p-6 shadow-2xl shadow-cyan-950/10 sm:p-8" aria-labelledby="create-project-heading">
          <h2 id="create-project-heading" className="text-xl font-semibold text-white">Start a project</h2>
          <p className="mt-2 text-sm text-slate-400">Give it enough context that the next step feels obvious.</p>
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

      {isLoading && (
        <div className="mt-10 rounded-3xl border border-white/10 bg-slate-900/50 px-6 py-12 text-center" role="status">
          <p className="text-sm text-slate-400">Loading your projects…</p>
        </div>
      )}

      {!isLoading && status === 'error' && projects.length === 0 && !error && (
        <div className="mt-10"><StatusMessage kind="error">Unable to load your projects.</StatusMessage></div>
      )}

      {!isLoading && status !== 'error' && projects.length === 0 && (
        <section className="mt-10 rounded-3xl border border-dashed border-white/15 bg-slate-900/40 px-6 py-14 text-center">
          <p className="text-sm font-medium text-slate-200">No projects yet.</p>
          <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-slate-500">Create a project to give your ideas a place to gather.</p>
          {!showCreateForm && (
            <button type="button" onClick={() => setShowCreateForm(true)} className="mt-6 rounded-xl border border-cyan-200/30 px-4 py-3 text-sm font-medium text-cyan-100 transition hover:border-cyan-200/60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">
              Create your first project
            </button>
          )}
        </section>
      )}

      <div className="mt-10 grid gap-5 md:grid-cols-2">
        {projects.map((project) => (
          <article key={project.id} className="rounded-3xl border border-white/10 bg-slate-900/65 p-6 transition hover:border-cyan-200/25 sm:p-7">
            {editingProject?.id === project.id ? (
              <>
                <h2 className="text-xl font-semibold text-white">Edit project</h2>
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
              </>
            ) : (
              <>
                <div className="flex items-start justify-between gap-4">
                  <div className="min-w-0">
                    <Link to={`/app/projects/${project.id}`} className="text-xl font-semibold text-white underline decoration-transparent underline-offset-4 transition hover:decoration-cyan-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">
                      {project.name}
                    </Link>
                    <p className="mt-2 text-xs text-slate-500">{formatDate(project.updated_at)}</p>
                  </div>
                  <span className="shrink-0 rounded-full border border-cyan-200/15 bg-cyan-300/5 px-3 py-1 text-xs text-cyan-100">Project</span>
                </div>
                <p className="mt-5 min-h-12 text-sm leading-6 text-slate-400">{project.description ?? 'No description yet.'}</p>
                {project.tags.length > 0 && (
                  <ul className="mt-5 flex flex-wrap gap-2" aria-label={`${project.name} tags`}>
                    {project.tags.map((tag) => <li key={tag} className="rounded-full border border-white/10 px-2.5 py-1 text-xs text-slate-400">{tag}</li>)}
                  </ul>
                )}
                <div className="mt-7 flex flex-wrap gap-3 border-t border-white/10 pt-5">
                  <Link to={`/app/projects/${project.id}`} className="rounded-lg border border-white/15 px-3 py-2 text-sm font-medium text-slate-200 transition hover:border-cyan-200/40 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">Open project</Link>
                  <button type="button" onClick={() => { setShowCreateForm(false); setEditingProject(project) }} className="rounded-lg px-3 py-2 text-sm text-slate-400 transition hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">Edit</button>
                  <button type="button" onClick={() => void handleDelete(project)} disabled={isMutating} className="rounded-lg px-3 py-2 text-sm text-rose-200/80 transition hover:text-rose-100 disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-rose-200">Delete</button>
                </div>
              </>
            )}
          </article>
        ))}
      </div>
    </main>
  )
}
