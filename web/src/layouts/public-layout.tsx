import { Link, Outlet } from 'react-router-dom'

import { MakkoMark } from '../components/makko-mark'

export function PublicLayout() {
  return (
    <div className="flex min-h-screen flex-col justify-between bg-[#f4f7fb] text-slate-900 transition-colors duration-200 dark:bg-[#070d18] dark:text-slate-100">
      <header className="sticky top-0 z-30 border-b border-slate-200/70 bg-white/95 shadow-sm transition-colors dark:border-white/[0.08] dark:bg-[#0c1527]/95">
        <div className="mx-auto flex w-full max-w-6xl flex-wrap items-center justify-between gap-3 px-5 py-3 sm:px-8 sm:py-3.5">
          <Link to="/" aria-label="Makko home" className="makko-control makko-focus inline-flex items-center">
            <MakkoMark />
          </Link>
          <nav aria-label="Primary navigation" className="flex basis-full items-center justify-end gap-2 text-sm sm:basis-auto sm:gap-3">
            <Link
              to="/login"
              className="makko-control makko-focus makko-ghost inline-flex items-center justify-center whitespace-nowrap px-3.5 text-sm font-medium sm:px-4"
            >
              Sign in
            </Link>
            <Link
              to="/signup"
              className="makko-control makko-focus makko-primary inline-flex items-center justify-center whitespace-nowrap px-4 text-sm font-semibold sm:px-5"
            >
              Create account
            </Link>
          </nav>
        </div>
      </header>
      <div className="flex-1">
        <Outlet />
      </div>
      <footer className="mx-auto w-full max-w-6xl border-t border-slate-200/60 px-5 py-7 text-xs font-normal text-slate-500 dark:border-white/[0.06] dark:text-slate-500 sm:px-8">
        Makko · a calm command center for independent builders
      </footer>
    </div>
  )
}
