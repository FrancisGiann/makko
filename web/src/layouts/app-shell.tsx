import { NavLink, Outlet, useLocation } from 'react-router-dom'

import { MakkoMark } from '../components/makko-mark'
import { StatusMessage } from '../components/status-message'
import { useAuth } from '../features/auth/use-auth'
import { useTheme } from '../features/theme/theme-context'

export function AppShell() {
  const { state, isSubmitting, signOut } = useAuth()
  const { theme, toggleTheme } = useTheme()
  const location = useLocation()
  const projectsActive = location.pathname === '/app' || location.pathname === '/app/projects' || location.pathname.startsWith('/app/projects/')

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      <header className="border-b border-white/10 bg-slate-950/90">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4 px-4 py-4 sm:px-8 sm:py-5">
          <div className="flex min-w-0 flex-1 items-center gap-4 sm:gap-8">
            <MakkoMark />
            <nav aria-label="Workspace navigation" className="flex min-w-0 items-center gap-1 overflow-x-auto">
              <NavLink end to="/app" className={`rounded-lg px-2.5 py-2 text-sm transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200 sm:px-3 ${projectsActive ? 'bg-cyan-300/10 text-cyan-100' : 'text-slate-400 hover:text-white'}`}>Projects</NavLink>
              <NavLink to="/app/dashboard" className={({ isActive }) => `rounded-lg px-2.5 py-2 text-sm transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200 sm:px-3 ${isActive ? 'bg-cyan-300/10 text-cyan-100' : 'text-slate-400 hover:text-white'}`}>Dashboard</NavLink>
            </nav>
          </div>
          <div className="flex items-center gap-3">
            <p className="hidden max-w-48 truncate text-sm text-slate-400 sm:block" title={state.session?.user.email ?? undefined}>
              {state.session?.user.email ?? 'Signed in'}
            </p>
            <button
              type="button"
              onClick={toggleTheme}
              className="rounded-lg border border-white/15 px-2.5 py-2 text-sm text-slate-200 transition hover:border-cyan-200/40 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200 sm:px-3"
              aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
              title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
            >
              <span aria-hidden="true">{theme === 'dark' ? '☼' : '☾'}</span>
              <span className="sr-only">Switch to {theme === 'dark' ? 'light' : 'dark'} mode</span>
            </button>
            <button
              type="button"
              onClick={() => void signOut()}
              disabled={isSubmitting}
              className="rounded-lg border border-white/15 px-3 py-2 text-sm text-slate-200 transition hover:border-cyan-200/40 hover:text-white disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200"
            >
              {isSubmitting ? 'Signing out…' : 'Sign out'}
            </button>
          </div>
        </div>
      </header>
      {state.error && (
        <div className="mx-auto max-w-6xl px-5 pt-5 sm:px-8">
          <StatusMessage kind="error">{state.error}</StatusMessage>
        </div>
      )}
      <Outlet />
    </div>
  )
}
