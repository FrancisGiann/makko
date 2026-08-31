import { useState, type FormEvent } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'

import { StatusMessage } from '../../components/status-message'
import { useAuth } from './use-auth'
import { getRedirectFromState } from '../../lib/redirects'

export function LoginPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const destination = getRedirectFromState(location.state)
  const { state, isSubmitting, clearError, signIn } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [validationError, setValidationError] = useState<string | null>(null)

  const error = validationError ?? state.error

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (isSubmitting) return

    setValidationError(null)
    clearError()
    if (!email.trim() || !password) {
      setValidationError('Enter your email and password to continue.')
      return
    }

    const signedIn = await signIn(email.trim(), password)
    if (signedIn) navigate(destination, { replace: true })
  }

  return (
    <div className="rounded-3xl border border-white/10 bg-slate-900/80 p-6 shadow-2xl shadow-cyan-950/20 sm:p-8">
      <p className="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-200">Welcome back</p>
      <h1 className="mt-3 text-2xl font-semibold tracking-tight text-white">Sign in to Makko</h1>
      <p className="mt-3 text-sm leading-6 text-slate-400">Pick up where you left off, with your work kept private.</p>
      <form className="mt-8 space-y-5" onSubmit={(event) => void handleSubmit(event)} noValidate>
        <div>
          <label htmlFor="login-email" className="mb-2 block text-sm font-medium text-slate-200">Email</label>
          <input
            id="login-email"
            name="email"
            type="email"
            autoComplete="email"
            value={email}
            onChange={(event) => { setEmail(event.target.value); setValidationError(null); clearError() }}
            required
            aria-required="true"
            aria-invalid={Boolean(error)}
            aria-describedby={error ? 'login-error' : undefined}
            className="w-full rounded-xl border border-white/15 bg-slate-950/70 px-4 py-3 text-sm text-white outline-none transition placeholder:text-slate-600 focus:border-cyan-200/60 focus:ring-2 focus:ring-cyan-200/20"
          />
        </div>
        <div>
          <label htmlFor="login-password" className="mb-2 block text-sm font-medium text-slate-200">Password</label>
          <input
            id="login-password"
            name="password"
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(event) => { setPassword(event.target.value); setValidationError(null); clearError() }}
            required
            aria-required="true"
            aria-invalid={Boolean(error)}
            aria-describedby={error ? 'login-error' : undefined}
            className="w-full rounded-xl border border-white/15 bg-slate-950/70 px-4 py-3 text-sm text-white outline-none transition placeholder:text-slate-600 focus:border-cyan-200/60 focus:ring-2 focus:ring-cyan-200/20"
          />
        </div>
        {error && <div id="login-error"><StatusMessage kind="error">{error}</StatusMessage></div>}
        <button
          type="submit"
          disabled={isSubmitting}
          className="w-full rounded-xl bg-cyan-200 px-5 py-3 text-sm font-semibold text-slate-950 transition hover:bg-cyan-100 disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-100"
        >
          {isSubmitting ? 'Signing in…' : 'Sign in'}
        </button>
      </form>
      <p className="mt-6 text-center text-sm text-slate-400">
        New to Makko?{' '}
        <Link to="/signup" state={{ from: destination }} className="inline-flex min-h-6 items-center rounded font-medium text-cyan-200 underline decoration-cyan-200/40 underline-offset-4 hover:text-cyan-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">
          Create an account
        </Link>
      </p>
    </div>
  )
}
