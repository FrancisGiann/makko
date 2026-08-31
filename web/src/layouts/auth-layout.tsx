import { Link, Outlet, useLocation } from 'react-router-dom'

import { MakkoMark } from '../components/makko-mark'

export function AuthLayout() {
  const location = useLocation()
  const destination = location.state && typeof location.state === 'object' && 'from' in location.state
    ? { from: location.state.from }
    : undefined

  return (
    <main className="grid min-h-[calc(100vh-82px)] place-items-center px-5 py-12 sm:px-8">
      <section className="w-full max-w-md">
        <div className="mb-8 flex justify-center sm:hidden">
          <MakkoMark />
        </div>
        <nav aria-label="Account navigation" className="mb-4 grid grid-cols-2 rounded-2xl border border-white/10 bg-slate-900/70 p-1 text-sm">
          <Link
            to={{ pathname: '/login' }}
            state={destination}
            className={`rounded-xl px-4 py-3 text-center transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200 ${location.pathname === '/login' ? 'bg-white/10 text-white' : 'text-slate-400 hover:text-white'}`}
          >
            Sign in
          </Link>
          <Link
            to={{ pathname: '/signup' }}
            state={destination}
            className={`rounded-xl px-4 py-3 text-center transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200 ${location.pathname === '/signup' ? 'bg-white/10 text-white' : 'text-slate-400 hover:text-white'}`}
          >
            Create account
          </Link>
        </nav>
        <Outlet />
      </section>
    </main>
  )
}
