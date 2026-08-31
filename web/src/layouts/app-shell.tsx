import { NavLink, Outlet } from 'react-router-dom'

import { MakkoMark } from '../components/makko-mark'
import { StatusMessage } from '../components/status-message'
import { useAuth } from '../features/auth/use-auth'

export function AppShell() {
  const { state, isSubmitting, signOut } = useAuth()

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      <header className="border-b border-white/10 bg-slate-950/90">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4 px-5 py-5 sm:px-8">
          <div className="flex items-center gap-8">
            <MakkoMark />
            <nav aria-label="Workspace navigation" className="flex items-center gap-1">
              <NavLink to="/app" className={({ isActive }) => `rounded-lg px-3 py-2 text-sm transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200 ${isActive ? 'bg-cyan-300/10 text-cyan-100' : 'text-slate-400 hover:text-white'}`}>Projects</NavLink>
            </nav>
          </div>
          <div className="flex items-center gap-3">
            <p className="hidden max-w-48 truncate text-sm text-slate-400 sm:block" title={state.session?.user.email ?? undefined}>
              {state.session?.user.email ?? 'Signed in'}
            </p>
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
