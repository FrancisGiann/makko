import { Link } from 'react-router-dom'
import { Activity, ArrowRight, Bug, CircleCheck, CircleDot, FilePlus2, FolderKanban, GitBranch, GitCommitHorizontal, LayoutDashboard, ListChecks, LockKeyhole, ScanText, ShieldCheck, UserRound, type LucideIcon } from 'lucide-react'

import { ProjectIdentity } from '../components/project-identity'

export function HomePage() {
  return (
    <main className="makko-page">
      <section className="grid items-center gap-8 py-6 md:grid-cols-[minmax(0,0.9fr)_minmax(20rem,1.1fr)] md:gap-12 lg:gap-16" aria-labelledby="home-heading">
        <div className="min-w-0">
          <h1 id="home-heading" className="max-w-3xl text-4xl font-bold leading-tight tracking-tight text-slate-900 dark:text-white sm:text-6xl sm:leading-[1.15]">
            Keep every side project moving.
          </h1>
          <p className="mt-5 max-w-xl text-base font-normal leading-8 text-slate-600 dark:text-slate-300 sm:text-lg">
            Makko gives independent developers one quiet place to keep the work, the context, and the next step in sight.
          </p>
          <div className="mt-7 flex flex-col gap-3 sm:flex-row">
            <Link
              to="/signup"
              className="makko-control makko-primary makko-focus inline-flex items-center justify-center px-6 text-center text-sm font-semibold"
            >
              Create your workspace
            </Link>
            <Link
              to="/login"
              className="makko-control makko-secondary makko-focus inline-flex items-center justify-center px-6 text-center text-sm font-semibold"
            >
              Sign in
            </Link>
          </div>
        </div>

        <LandingPreview />
      </section>

      <ProductOverview />
      <WorkspaceShowcase />
      <GithubBoundary />
      <SoloPositioning />
      <FinalCallToAction />
    </main>
  )
}

function ProductOverview() {
  return (
    <section className="mt-24 grid gap-10 lg:grid-cols-[minmax(0,0.72fr)_minmax(0,1.28fr)] lg:items-start" aria-labelledby="overview-heading">
      <div className="max-w-md">
        <h2 id="overview-heading" className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-4xl">Everything around a build, in one current.</h2>
        <p className="mt-4 text-base leading-7 text-slate-600 dark:text-slate-300">Makko keeps the project context, internal work, and useful external signals close without blending their meaning.</p>
      </div>

      <div className="makko-surface rounded-3xl p-5 sm:p-7">
        <div className="relative">
          <span className="absolute bottom-5 left-4 top-5 w-px bg-cyan-500/20 dark:bg-cyan-400/20" aria-hidden="true" />
          <ol className="relative">
            <OverviewStep icon={FolderKanban} title="Projects" detail="Keep each build’s description, tags, and context together." tone="cyan" />
            <OverviewStep icon={ListChecks} title="Internal issues" detail="Tasks and bugs carry the status and priority of your own work." tone="emerald" />
            <OverviewStep icon={LayoutDashboard} title="Dashboard + Activity" detail="See internal totals and the changes that move a project forward." tone="sky" />
            <OverviewStep icon={GitBranch} title="GitHub context" detail="External commits and open issues stay read-only and distinct." tone="slate" last />
          </ol>
        </div>
      </div>
    </section>
  )
}

function OverviewStep({ icon: Icon, title, detail, tone, last = false }: { icon: LucideIcon; title: string; detail: string; tone: 'cyan' | 'emerald' | 'sky' | 'slate'; last?: boolean }) {
  const toneStyles = {
    cyan: 'border-cyan-500/25 bg-cyan-500/10 text-cyan-700 dark:border-cyan-400/25 dark:bg-cyan-400/10 dark:text-cyan-200',
    emerald: 'border-emerald-500/25 bg-emerald-500/10 text-emerald-700 dark:border-emerald-400/25 dark:bg-emerald-400/10 dark:text-emerald-200',
    sky: 'border-sky-500/25 bg-sky-500/10 text-sky-700 dark:border-sky-400/25 dark:bg-sky-400/10 dark:text-sky-200',
    slate: 'border-slate-200/80 bg-slate-100/80 text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-300',
  }

  return (
    <li className={`relative grid grid-cols-[2.25rem_minmax(0,1fr)] gap-4 ${last ? 'pb-0' : 'border-b border-slate-200/70 pb-5 dark:border-white/[0.07]'} ${last ? '' : 'mb-5'}`}>
      <span className={`relative z-10 grid size-9 place-items-center rounded-xl border ${toneStyles[tone]}`}>
        <Icon className="size-4" aria-hidden="true" />
      </span>
      <div className="min-w-0">
        <h3 className="text-base font-semibold text-slate-900 dark:text-white">{title}</h3>
        <p className="mt-1 text-sm leading-6 text-slate-600 dark:text-slate-400">{detail}</p>
      </div>
    </li>
  )
}

function WorkspaceShowcase() {
  return (
    <section className="mt-24" aria-labelledby="workspace-showcase-heading">
      <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-end">
        <div className="max-w-xl">
          <h2 id="workspace-showcase-heading" className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-4xl">A project has a shape, not just a title.</h2>
          <p className="mt-4 text-base leading-7 text-slate-600 dark:text-slate-300">Project context, the work queue, and the record of change stay readable in the same workspace.</p>
        </div>
        <span className="w-fit shrink-0 rounded-full border border-slate-200/80 bg-slate-100/80 px-3 py-1 text-xs font-semibold text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-300">Illustrative workspace</span>
      </div>

      <div className="mt-8 grid gap-6 lg:grid-cols-[minmax(0,1.3fr)_minmax(18rem,0.7fr)]">
        <article className="makko-surface-raised min-w-0 rounded-3xl p-5 sm:p-7" aria-label="Illustrative project and issue workspace">
          <div className="flex min-w-0 items-start gap-3">
            <ProjectIdentity name="Project workspace" tags={['web', 'personal']} size="sm" />
            <div className="min-w-0">
              <h3 className="makko-readable text-lg font-semibold text-slate-900 dark:text-white">Project workspace</h3>
              <p className="mt-1 text-sm leading-6 text-slate-600 dark:text-slate-400">Description, tags, and the next piece of work sit together.</p>
              <div className="mt-3 flex flex-wrap gap-1.5" aria-label="Illustrative project tags">
                <span className="rounded-full border border-slate-200/70 bg-slate-100/80 px-2.5 py-0.5 text-xs font-medium text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-300">web</span>
                <span className="rounded-full border border-slate-200/70 bg-slate-100/80 px-2.5 py-0.5 text-xs font-medium text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-300">personal</span>
              </div>
            </div>
          </div>

          <div className="mt-7 border-t border-slate-200/70 pt-5 dark:border-white/[0.07]">
            <div className="flex items-center justify-between gap-3">
              <h4 className="text-sm font-semibold text-slate-900 dark:text-white">Issue queue</h4>
              <span className="text-xs font-medium text-slate-500 dark:text-slate-400">Tasks and bugs</span>
            </div>
            <div className="mt-3 divide-y divide-slate-200/70 dark:divide-white/[0.07]">
              <ShowcaseIssue icon={CircleDot} title="Refine project notes" type="Task" status="In progress" tone="cyan" />
              <ShowcaseIssue icon={Bug} title="Check the empty state" type="Bug" status="To do" tone="slate" />
              <ShowcaseIssue icon={CircleCheck} title="Capture the next step" type="Task" status="Done" tone="emerald" />
            </div>
          </div>
        </article>

        <aside className="makko-well min-w-0 rounded-3xl p-5 sm:p-7" aria-labelledby="workspace-activity-heading">
          <div className="flex items-center gap-2.5">
            <Activity className="size-4 text-cyan-700 dark:text-cyan-300" aria-hidden="true" />
            <h3 id="workspace-activity-heading" className="text-lg font-semibold text-slate-900 dark:text-white">Activity</h3>
          </div>
          <p className="mt-1 text-sm leading-6 text-slate-600 dark:text-slate-400">A clear record of what changed.</p>
          <ol className="mt-6 space-y-5">
            <ShowcaseActivity icon={FilePlus2} title="Issue created" detail="The work queue gets a new next step." />
            <ShowcaseActivity icon={CircleCheck} title="Issue updated" detail="A status change stays visible in context." />
            <ShowcaseActivity icon={Activity} title="Project updated" detail="The project’s story keeps moving with the work." />
          </ol>
        </aside>
      </div>
    </section>
  )
}

function ShowcaseIssue({ icon: Icon, title, type, status, tone }: { icon: LucideIcon; title: string; type: string; status: string; tone: 'cyan' | 'emerald' | 'slate' }) {
  const toneStyles = {
    cyan: 'text-cyan-700 dark:text-cyan-300',
    emerald: 'text-emerald-700 dark:text-emerald-300',
    slate: 'text-slate-500 dark:text-slate-400',
  }
  const statusStyles = {
    cyan: 'border-cyan-500/25 bg-cyan-500/10 text-cyan-800 dark:border-cyan-400/25 dark:bg-cyan-400/10 dark:text-cyan-200',
    emerald: 'border-emerald-500/25 bg-emerald-500/10 text-emerald-800 dark:border-emerald-400/25 dark:bg-emerald-400/10 dark:text-emerald-200',
    slate: 'border-slate-200/80 bg-slate-100/80 text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-300',
  }

  return (
    <div className="flex min-w-0 items-center gap-3 py-3 first:pt-0 last:pb-0">
      <Icon className={`size-4 shrink-0 ${toneStyles[tone]}`} aria-hidden="true" />
      <div className="min-w-0 flex-1">
        <p className="makko-readable text-sm font-medium text-slate-800 dark:text-slate-200">{title}</p>
        <p className="mt-0.5 text-xs text-slate-500 dark:text-slate-400">{type}</p>
      </div>
      <span className={`shrink-0 rounded-full border px-2.5 py-1 text-xs font-medium ${statusStyles[tone]}`}>{status}</span>
    </div>
  )
}

function ShowcaseActivity({ icon: Icon, title, detail }: { icon: LucideIcon; title: string; detail: string }) {
  return (
    <li className="relative border-l border-cyan-500/25 pl-4 dark:border-cyan-400/20">
      <span className="absolute -left-[9px] top-0.5 grid size-4 place-items-center rounded-full border border-cyan-500/25 bg-slate-50 text-cyan-700 dark:border-cyan-400/25 dark:bg-[#080f1d] dark:text-cyan-300">
        <Icon className="size-2.5" aria-hidden="true" />
      </span>
      <p className="text-sm font-semibold text-slate-800 dark:text-slate-200">{title}</p>
      <p className="mt-1 text-xs leading-5 text-slate-500 dark:text-slate-400">{detail}</p>
    </li>
  )
}

function GithubBoundary() {
  return (
    <section className="mt-24 rounded-3xl border border-cyan-500/25 bg-cyan-500/[0.05] p-6 dark:border-cyan-400/20 dark:bg-cyan-400/[0.05] sm:p-8" aria-labelledby="github-boundary-heading">
      <div className="grid gap-8 lg:grid-cols-[minmax(0,0.85fr)_minmax(0,1.15fr)] lg:items-center">
        <div>
          <div className="flex items-center gap-2.5">
            <GitBranch className="size-5 text-cyan-700 dark:text-cyan-300" aria-hidden="true" />
            <h2 id="github-boundary-heading" className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-3xl">GitHub stays on its own current.</h2>
          </div>
          <p className="mt-4 max-w-xl text-sm leading-6 text-slate-700 dark:text-slate-300">Commits and open GitHub issues are external, read-only context. They never affect internal Makko dashboard statistics.</p>
          <span className="mt-5 inline-flex items-center gap-1.5 rounded-full border border-cyan-500/25 bg-cyan-500/10 px-2.5 py-1 text-xs font-semibold text-cyan-800 dark:border-cyan-400/25 dark:bg-cyan-400/10 dark:text-cyan-200">
            <ShieldCheck className="size-3.5" aria-hidden="true" />
            External / read-only
          </span>
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          <div className="border-t border-cyan-500/20 pt-4 dark:border-cyan-400/20">
            <GitCommitHorizontal className="size-4 text-cyan-700 dark:text-cyan-300" aria-hidden="true" />
            <h3 className="mt-3 text-base font-semibold text-slate-900 dark:text-white">Recent commits</h3>
            <p className="mt-1 text-sm leading-6 text-slate-600 dark:text-slate-400">Review repository activity without changing the project’s internal work.</p>
          </div>
          <div className="border-t border-cyan-500/20 pt-4 dark:border-cyan-400/20">
            <ListChecks className="size-4 text-cyan-700 dark:text-cyan-300" aria-hidden="true" />
            <h3 className="mt-3 text-base font-semibold text-slate-900 dark:text-white">Open GitHub issues</h3>
            <p className="mt-1 text-sm leading-6 text-slate-600 dark:text-slate-400">Keep external issue context visible without mixing it into Makko totals.</p>
          </div>
        </div>
      </div>
    </section>
  )
}

function SoloPositioning() {
  return (
    <section className="mt-24 grid gap-10 lg:grid-cols-[minmax(0,0.9fr)_minmax(0,1.1fr)] lg:items-end" aria-labelledby="solo-heading">
      <div className="max-w-lg">
        <h2 id="solo-heading" className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-4xl">Built for one builder’s line of sight.</h2>
        <p className="mt-4 text-base leading-7 text-slate-600 dark:text-slate-300">Makko is a private, owned workspace for independent developers who want the work close, the context legible, and the surface calm.</p>
      </div>

      <div className="makko-surface rounded-3xl p-5 sm:p-7">
        <ul className="divide-y divide-slate-200/70 dark:divide-white/[0.07]">
          <PositioningPoint icon={LockKeyhole} title="Owned workspace" detail="Your projects and internal issues stay in your personal workspace." />
          <PositioningPoint icon={ScanText} title="Focused information density" detail="The work, context, and next step remain close enough to scan." />
          <PositioningPoint icon={UserRound} title="Solo focus" detail="No team-management noise around the work of one developer." />
        </ul>
      </div>
    </section>
  )
}

function PositioningPoint({ icon: Icon, title, detail }: { icon: LucideIcon; title: string; detail: string }) {
  return (
    <li className="flex items-start gap-3 py-4 first:pt-0 last:pb-0">
      <span className="mt-0.5 grid size-8 shrink-0 place-items-center rounded-xl border border-slate-200/80 bg-slate-100/80 text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-300">
        <Icon className="size-4" aria-hidden="true" />
      </span>
      <div className="min-w-0">
        <h3 className="text-sm font-semibold text-slate-900 dark:text-white">{title}</h3>
        <p className="mt-1 text-sm leading-6 text-slate-600 dark:text-slate-400">{detail}</p>
      </div>
    </li>
  )
}

function FinalCallToAction() {
  return (
    <section className="mb-4 mt-24 rounded-3xl border border-cyan-500/25 bg-cyan-500/[0.05] p-7 text-center dark:border-cyan-400/20 dark:bg-cyan-400/[0.05] sm:p-12" aria-labelledby="final-cta-heading">
      <h2 id="final-cta-heading" className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-4xl">Make room for the next step.</h2>
      <p className="mx-auto mt-3 max-w-xl text-base leading-7 text-slate-600 dark:text-slate-300">Start with a place for your projects, internal issues, and the context that keeps them moving.</p>
      <div className="mt-7 flex flex-col justify-center gap-3 sm:flex-row">
        <Link to="/signup" className="makko-control makko-primary makko-focus inline-flex items-center justify-center gap-2 px-6 text-center text-sm font-semibold">
          Create your workspace
          <ArrowRight className="size-4" aria-hidden="true" />
        </Link>
        <Link to="/login" className="makko-control makko-secondary makko-focus inline-flex items-center justify-center px-6 text-center text-sm font-semibold">Sign in</Link>
      </div>
    </section>
  )
}

function LandingPreview() {
  return (
    <aside aria-label="Illustrative Makko command center preview" className="makko-surface-raised min-w-0 rounded-3xl p-4 sm:p-6">
      <div className="flex min-w-0 items-center justify-between gap-3">
        <div className="flex min-w-0 items-center gap-3">
          <div className="relative size-14 shrink-0 rounded-2xl border border-cyan-500/25 bg-cyan-500/10 p-1.5 dark:border-cyan-400/25 dark:bg-cyan-400/10">
            <img src="/makko-pet.png" alt="Makko the shark pet" width={56} height={56} className="size-full object-contain" />
            <span className="absolute bottom-0.5 right-0.5 size-2.5 rounded-full bg-emerald-400 ring-2 ring-white dark:ring-[#101c33]" aria-hidden="true" />
          </div>
          <div className="min-w-0">
            <p className="makko-readable text-sm font-semibold text-slate-900 dark:text-white">Makko command center</p>
            <p className="text-xs font-medium text-slate-500 dark:text-slate-400">Personal workspace</p>
          </div>
        </div>
        <span className="shrink-0 rounded-full border border-slate-200/70 bg-slate-100/80 px-2.5 py-1 text-[11px] font-semibold text-slate-600 dark:border-white/10 dark:bg-white/[0.05] dark:text-slate-300">Illustrative preview</span>
      </div>

      <div className="makko-well mt-5 rounded-2xl border-cyan-500/20 bg-cyan-500/[0.05] p-4 dark:border-cyan-400/15 dark:bg-cyan-400/[0.05]">
        <div className="flex items-center justify-between gap-3">
          <div className="flex min-w-0 items-center gap-2.5">
            <LayoutDashboard className="size-4 shrink-0 text-cyan-700 dark:text-cyan-300" aria-hidden="true" />
            <div className="min-w-0">
              <p className="text-sm font-semibold text-slate-900 dark:text-white">Dashboard</p>
              <p className="mt-0.5 text-xs font-normal text-slate-600 dark:text-slate-300">Internal work at a glance</p>
            </div>
          </div>
          <Activity className="size-4 shrink-0 text-cyan-700 dark:text-cyan-300" aria-hidden="true" />
        </div>
        <div className="mt-4 grid grid-cols-3 gap-2 border-t border-cyan-500/15 pt-3 dark:border-cyan-400/15">
          <PreviewSignal icon={FolderKanban} label="Projects" />
          <PreviewSignal icon={ListChecks} label="Issues" />
          <PreviewSignal icon={Activity} label="Activity" />
        </div>
      </div>

      <ul className="mt-4 space-y-1.5" aria-label="Illustrative workspace sections">
        <CapabilitySignal icon={FolderKanban} title="Projects" detail="Context for each build." tone="cyan" />
        <CapabilitySignal icon={ListChecks} title="Internal issues" detail="Tasks and bugs stay yours." tone="emerald" />
        <CapabilitySignal icon={GitBranch} title="GitHub activity" detail="External · read-only." tone="slate" />
      </ul>
    </aside>
  )
}

function PreviewSignal({ icon: Icon, label }: { icon: typeof FolderKanban; label: string }) {
  return (
    <div className="flex min-w-0 flex-col items-center gap-1 text-center">
      <Icon className="size-3.5 text-cyan-700 dark:text-cyan-300" aria-hidden="true" />
      <span className="truncate text-[11px] font-medium text-slate-600 dark:text-slate-300">{label}</span>
    </div>
  )
}

function CapabilitySignal({ icon: Icon, title, detail, tone }: { icon: typeof FolderKanban; title: string; detail: string; tone: 'cyan' | 'emerald' | 'slate' }) {
  const toneStyles = {
    cyan: 'text-cyan-700 dark:text-cyan-300',
    emerald: 'text-emerald-700 dark:text-emerald-300',
    slate: 'text-slate-500 dark:text-slate-400',
  }

  return (
    <li className="makko-well flex min-w-0 items-center gap-3 rounded-2xl px-3 py-2.5">
      <Icon className={`size-4 shrink-0 ${toneStyles[tone]}`} aria-hidden="true" />
      <div className="flex min-w-0 items-center gap-2.5">
        <div className="min-w-0">
          <p className="makko-readable text-sm font-medium text-slate-800 dark:text-slate-200">{title}</p>
          <p className="makko-readable text-xs font-normal text-slate-500 dark:text-slate-400">{detail}</p>
        </div>
      </div>
    </li>
  )
}
