import { Link } from 'react-router-dom'

export function NotFoundPage() {
  return (
    <main className="grid min-h-[calc(100vh-82px)] place-items-center px-5 py-16 text-center sm:px-8">
      <section>
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-200">404 · off course</p>
        <h1 className="mt-4 text-4xl font-semibold tracking-tight text-white">That page isn’t in the current.</h1>
        <p className="mx-auto mt-4 max-w-md text-sm leading-7 text-slate-400">The link may be old, or the page may have moved.</p>
        <Link
          to="/"
          className="mt-8 inline-flex rounded-xl border border-white/15 px-5 py-3 text-sm font-medium text-slate-200 transition hover:border-cyan-200/40 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200"
        >
          Return home
        </Link>
      </section>
    </main>
  )
}
