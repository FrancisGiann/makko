import { Link, Outlet, useLocation } from 'react-router-dom'

export function AuthLayout() {
  const location = useLocation()
  const destination = location.state && typeof location.state === 'object' && 'from' in location.state
    ? { from: location.state.from }
    : undefined

  return (
    <main className="mx-auto flex min-h-[70dvh] w-full max-w-6xl items-start justify-center px-5 py-6 sm:px-8 sm:py-10 lg:items-center">
      <section className="w-full max-w-md">
        <nav aria-label="Account navigation" className="makko-well mb-3 grid w-full grid-cols-2 rounded-2xl p-1.5 text-sm">
          <Link
            to={{ pathname: '/login' }}
            state={destination}
            className={`makko-focus flex h-12 min-h-12 w-full min-w-0 items-center justify-center rounded-xl px-4 text-center font-medium ${
              location.pathname === '/login'
                ? 'bg-white text-cyan-800 shadow-xs ring-1 ring-black/5 dark:bg-white/10 dark:text-cyan-200 dark:ring-white/10'
                : 'text-slate-600 hover:bg-slate-200/60 hover:text-slate-900 dark:text-slate-400 dark:hover:bg-white/[0.06] dark:hover:text-white'
            }`}
          >
            Sign in
          </Link>
          <Link
            to={{ pathname: '/signup' }}
            state={destination}
            className={`makko-focus flex h-12 min-h-12 w-full min-w-0 items-center justify-center rounded-xl px-4 text-center font-medium ${
              location.pathname === '/signup'
                ? 'bg-white text-cyan-800 shadow-xs ring-1 ring-black/5 dark:bg-white/10 dark:text-cyan-200 dark:ring-white/10'
                : 'text-slate-600 hover:bg-slate-200/60 hover:text-slate-900 dark:text-slate-400 dark:hover:bg-white/[0.06] dark:hover:text-white'
            }`}
          >
            Create account
          </Link>
        </nav>
        <Outlet />
      </section>
    </main>
  )
}
