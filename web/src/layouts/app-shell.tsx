import { NavLink, Outlet, Link, useLocation } from 'react-router-dom'
import { CircleUserRound, LogOut, Moon, Sun } from 'lucide-react'

import { MakkoMark } from '../components/makko-mark'
import { StatusMessage } from '../components/status-message'
import { useAuth } from '../features/auth/use-auth'
import { useTheme } from '../features/theme/theme-context'
import { getDisplayName } from '../utils/display-name'

const NAV_ITEM = 'makko-control makko-focus inline-flex items-center justify-center whitespace-nowrap px-3.5 text-sm font-semibold'

export function AppShell() {
  const { state, isSubmitting, signOut } = useAuth()
  const { theme, toggleTheme } = useTheme()
  const location = useLocation()
  const projectsActive = location.pathname === '/app' || location.pathname === '/app/projects' || location.pathname.startsWith('/app/projects/')
  const displayName = getDisplayName(state.session?.user)

  return (
    <div className="min-h-screen bg-[#f4f7fb] text-slate-900 transition-colors duration-200 dark:bg-[#070d18] dark:text-slate-100">
      <header className="sticky top-0 z-30 border-b border-slate-200/70 bg-white/95 shadow-sm transition-colors dark:border-white/[0.08] dark:bg-[#0c1527]/95">
        <div className="mx-auto w-full max-w-6xl px-5 py-3 sm:px-8 sm:py-3.5">
          <div className="flex min-w-0 items-center justify-between gap-3">
            <Link to="/app/dashboard" aria-label="Makko dashboard" className="makko-control makko-focus inline-flex shrink-0 items-center">
              <MakkoMark />
            </Link>
            <div className="flex items-center gap-1.5 sm:gap-2">
              <div
                className="makko-control makko-secondary inline-flex max-w-44 items-center justify-center gap-2 px-2.5 text-sm font-semibold sm:px-3.5"
                role="status"
                aria-label={`Signed in as ${displayName}`}
                title={`Signed in as ${displayName}`}
              >
                <CircleUserRound className="size-4" aria-hidden="true" />
                <span className="truncate">{displayName}</span>
              </div>
              <button
                type="button"
                onClick={toggleTheme}
                className="makko-control makko-secondary makko-focus inline-flex size-11 items-center justify-center px-0"
                aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
                title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
              >
                {theme === 'dark' ? <Sun className="size-4" aria-hidden="true" /> : <Moon className="size-4" aria-hidden="true" />}
                <span className="sr-only">Switch to {theme === 'dark' ? 'light' : 'dark'} mode</span>
              </button>
              <button
                type="button"
                onClick={() => void signOut()}
                disabled={isSubmitting}
                className="makko-control makko-focus makko-danger inline-flex items-center justify-center gap-2 px-2.5 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50 sm:px-3.5"
                title="Sign out"
              >
                <LogOut className="size-4" aria-hidden="true" />
                <span className="hidden sm:inline">{isSubmitting ? 'Signing out…' : 'Sign out'}</span>
                <span className="sr-only sm:hidden">{isSubmitting ? 'Signing out…' : 'Sign out'}</span>
              </button>
            </div>
          </div>
          <nav aria-label="Workspace navigation" className="makko-well mt-3 flex w-full items-center gap-1.5 overflow-x-auto rounded-2xl p-1">
            <NavLink
              end
              to="/app"
              className={`${NAV_ITEM} ${projectsActive ? 'bg-white text-cyan-800 shadow-xs ring-1 ring-black/5 dark:bg-white/10 dark:text-cyan-200 dark:ring-white/10' : 'makko-ghost'}`}
            >
              Projects
            </NavLink>
            <NavLink
              to="/app/dashboard"
              className={({ isActive }) => `${NAV_ITEM} ${isActive ? 'bg-white text-cyan-800 shadow-xs ring-1 ring-black/5 dark:bg-white/10 dark:text-cyan-200 dark:ring-white/10' : 'makko-ghost'}`}
            >
              Dashboard
            </NavLink>
          </nav>
        </div>
      </header>
      {state.error && (
        <div className="mx-auto w-full max-w-6xl px-5 pt-5 sm:px-8">
          <StatusMessage kind="error">{state.error}</StatusMessage>
        </div>
      )}
      <Outlet />
    </div>
  )
}
