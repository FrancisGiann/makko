import { Link } from 'react-router-dom'

import { StatusMessage } from '../../components/status-message'
import { useDashboard } from '../../hooks/use-dashboard'
import type { DashboardService } from '../../services/dashboard.service'
import type { IssueStatus } from '../../types/domain'

function statusLabel(status: IssueStatus): string {
  return status === 'in_progress' ? 'In progress' : status === 'todo' ? 'To do' : 'Done'
}

interface DashboardPageProps { service?: DashboardService }

export function DashboardPage({ service }: DashboardPageProps) {
  const { stats, status, error, refresh } = useDashboard(service)
  const isLoading = status === 'loading' && !stats

  return (
    <main className="mx-auto max-w-6xl px-4 py-10 sm:px-8 sm:py-14">
      <header className="flex flex-col justify-between gap-5 sm:flex-row sm:items-end">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-200">Your workspace</p>
          <h1 className="mt-3 text-3xl font-semibold tracking-tight text-white sm:text-4xl">Dashboard</h1>
          <p className="mt-3 max-w-2xl text-sm leading-7 text-slate-400">A small view of the work you are carrying. Counts below include internal Makko issues only.</p>
        </div>
        <button
          type="button"
          onClick={() => void refresh()}
          disabled={status === 'loading'}
          className="rounded-xl border border-white/15 px-4 py-3 text-sm font-medium text-slate-200 transition hover:border-cyan-200/40 hover:text-white disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200"
        >
          {status === 'loading' ? 'Refreshing…' : 'Refresh stats'}
        </button>
      </header>

      {error && <div className="mt-8"><StatusMessage kind="error">{error}</StatusMessage></div>}

      {isLoading && (
        <div className="mt-10 rounded-3xl border border-white/10 bg-slate-900/50 px-6 py-12 text-center" role="status">
          <p className="text-sm text-slate-400">Loading your dashboard…</p>
        </div>
      )}

      {!isLoading && stats && (
        <>
          <section className="mt-10 grid gap-4 sm:grid-cols-2 xl:grid-cols-4" aria-label="Internal work totals">
            <StatCard label="Projects" value={stats.projectCount} detail="Owned projects" />
            <StatCard label="All issues" value={stats.totalIssues} detail="Internal Makko issues" />
            <StatCard label="Open" value={stats.openIssues} detail="To do + in progress" accent="cyan" />
            <StatCard label="Completed" value={stats.completedIssues} detail="Done" accent="emerald" />
          </section>

          <div className="mt-8 grid gap-8 lg:grid-cols-2">
            <BreakdownCard title="By status" items={(['todo', 'in_progress', 'done'] as const).map((key) => ({ label: statusLabel(key), value: stats.byStatus[key] }))} />
            <BreakdownCard title="By type" items={(['task', 'bug'] as const).map((key) => ({ label: key === 'bug' ? 'Bugs' : 'Tasks', value: stats.byType[key] }))} />
            <BreakdownCard title="By priority" items={(['high', 'medium', 'low'] as const).map((key) => ({ label: `${key[0].toUpperCase()}${key.slice(1)}`, value: stats.byPriority[key] }))} />
            <section className="rounded-3xl border border-white/10 bg-slate-900/50 p-6 sm:p-8" aria-labelledby="workload-heading">
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-200">Internal issues</p>
              <h2 id="workload-heading" className="mt-2 text-xl font-semibold text-white">Project workload</h2>
              {stats.projects.length === 0 ? (
                <p className="mt-6 rounded-2xl border border-dashed border-white/15 px-4 py-8 text-center text-sm text-slate-500">Create a project to see its workload here.</p>
              ) : (
                <ul className="mt-6 space-y-3">
                  {stats.projects.map((project) => (
                    <li key={project.id} className="flex flex-col gap-2 rounded-2xl border border-white/10 bg-slate-950/35 p-4 sm:flex-row sm:items-center sm:justify-between">
                      <Link to={`/app/projects/${project.id}`} className="min-w-0 truncate font-medium text-white underline decoration-transparent underline-offset-4 hover:decoration-cyan-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">{project.name}</Link>
                      <span className="text-sm text-slate-400">{project.open} open · {project.completed} done</span>
                    </li>
                  ))}
                </ul>
              )}
            </section>
          </div>

          {stats.projectCount === 0 && (
            <section className="mt-8 rounded-3xl border border-dashed border-white/15 bg-slate-900/40 px-6 py-12 text-center" aria-label="Empty dashboard">
              <p className="text-sm font-medium text-slate-200">Your dashboard is ready for its first project.</p>
              <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-slate-500">Projects and their internal issues will appear in these totals as you build.</p>
              <Link to="/app" className="mt-6 inline-flex rounded-xl border border-cyan-200/30 px-4 py-3 text-sm font-medium text-cyan-100 transition hover:border-cyan-200/60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">Go to projects</Link>
            </section>
          )}
        </>
      )}
    </main>
  )
}

function StatCard({ label, value, detail, accent = 'default' }: { label: string; value: number; detail: string; accent?: 'default' | 'cyan' | 'emerald' }) {
  const valueClass = accent === 'cyan' ? 'text-cyan-200' : accent === 'emerald' ? 'text-emerald-200' : 'text-white'
  return (
    <article className="rounded-3xl border border-white/10 bg-slate-900/65 p-5 sm:p-6">
      <p className="text-sm text-slate-400">{label}</p>
      <p className={`mt-3 text-3xl font-semibold tracking-tight ${valueClass}`}>{value}</p>
      <p className="mt-2 text-xs text-slate-500">{detail}</p>
    </article>
  )
}

function BreakdownCard({ title, items }: { title: string; items: { label: string; value: number }[] }) {
  const total = items.reduce((sum, item) => sum + item.value, 0)
  return (
    <section className="rounded-3xl border border-white/10 bg-slate-900/50 p-6 sm:p-8" aria-labelledby={`${title.replaceAll(' ', '-')}-heading`}>
      <p className="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-200">Internal issues</p>
      <h2 id={`${title.replaceAll(' ', '-')}-heading`} className="mt-2 text-xl font-semibold text-white">{title}</h2>
      <ul className="mt-6 space-y-4">
        {items.map((item) => (
          <li key={item.label}>
            <div className="flex items-center justify-between gap-3 text-sm"><span className="text-slate-300">{item.label}</span><span className="font-medium text-white">{item.value}</span></div>
            <div className="mt-2 h-2 overflow-hidden rounded-full bg-slate-950/70" aria-hidden="true"><div className="h-full rounded-full bg-cyan-200" style={{ width: total ? `${(item.value / total) * 100}%` : '0%' }} /></div>
          </li>
        ))}
      </ul>
      {total === 0 && <p className="mt-4 text-sm text-slate-500">No internal issues yet.</p>}
    </section>
  )
}
