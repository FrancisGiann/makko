import { Link, Outlet } from 'react-router-dom'

import { MakkoMark } from '../components/makko-mark'

export function PublicLayout() {
  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      <header className="border-b border-white/10 bg-slate-950/90">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-5 py-5 sm:px-8">
          <Link to="/" aria-label="Makko home" className="rounded-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">
            <MakkoMark />
          </Link>
          <nav aria-label="Primary navigation" className="flex items-center gap-2 text-sm">
            <Link
              to="/login"
              className="rounded-lg px-3 py-2 text-slate-300 transition hover:bg-white/5 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200"
            >
              Sign in
            </Link>
            <Link
              to="/signup"
              className="rounded-lg border border-cyan-200/30 bg-cyan-300/10 px-3 py-2 font-medium text-cyan-100 transition hover:bg-cyan-300/20 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200"
            >
              Create account
            </Link>
          </nav>
        </div>
      </header>
      <Outlet />
      <footer className="mx-auto max-w-6xl px-5 py-8 text-xs text-slate-500 sm:px-8">
        Makko · a calm command center for independent builders
      </footer>
    </div>
  )
}
