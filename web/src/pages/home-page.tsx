import { Link } from 'react-router-dom'

export function HomePage() {
  return (
    <main>
      <section className="relative isolate overflow-hidden">
        <div className="pointer-events-none absolute -right-24 top-10 -z-10 size-72 rounded-full bg-cyan-400/10 blur-3xl" aria-hidden="true" />
        <div className="mx-auto grid max-w-6xl gap-12 px-5 py-20 sm:px-8 sm:py-28 lg:grid-cols-[1.1fr_0.9fr] lg:items-center">
          <div>
            <p className="mb-5 text-xs font-semibold uppercase tracking-[0.24em] text-cyan-200">A clearer current</p>
            <h1 className="max-w-3xl text-4xl font-semibold leading-tight tracking-[-0.04em] text-white sm:text-6xl">
              Keep every side project moving.
            </h1>
            <p className="mt-6 max-w-xl text-base leading-8 text-slate-300 sm:text-lg">
              Makko gives independent developers one quiet place to keep the work, the context, and the next step in sight.
            </p>
            <div className="mt-9 flex flex-col gap-3 sm:flex-row">
              <Link
                to="/signup"
                className="rounded-xl bg-cyan-200 px-5 py-3 text-center text-sm font-semibold text-slate-950 transition hover:bg-cyan-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-100 focus-visible:ring-offset-2 focus-visible:ring-offset-slate-950"
              >
                Create your workspace
              </Link>
              <Link
                to="/login"
                className="rounded-xl border border-white/15 px-5 py-3 text-center text-sm font-medium text-slate-200 transition hover:border-cyan-200/40 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200"
              >
                Sign in
              </Link>
            </div>
          </div>
          <aside aria-label="Makko focus" className="rounded-3xl border border-white/10 bg-slate-900/70 p-6 shadow-2xl shadow-cyan-950/20 sm:p-8">
            <div className="mb-8 flex items-center justify-between">
              <span className="text-sm font-medium text-slate-200">Today’s focus</span>
              <span className="rounded-full border border-emerald-200/20 bg-emerald-300/10 px-3 py-1 text-xs text-emerald-200">steady</span>
            </div>
            <div className="space-y-4">
              <div className="rounded-2xl border border-cyan-200/15 bg-cyan-300/5 p-4">
                <p className="text-xs text-cyan-200">One place</p>
                <p className="mt-2 text-lg font-medium text-white">Your work, at your pace.</p>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="rounded-2xl border border-white/10 bg-slate-950/50 p-4">
                  <p className="text-2xl font-semibold text-white">01</p>
                  <p className="mt-1 text-xs text-slate-500">workspace</p>
                </div>
                <div className="rounded-2xl border border-white/10 bg-slate-950/50 p-4">
                  <p className="text-2xl font-semibold text-white">∞</p>
                  <p className="mt-1 text-xs text-slate-500">possibilities</p>
                </div>
              </div>
            </div>
          </aside>
        </div>
      </section>
    </main>
  )
}
