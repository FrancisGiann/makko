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
    <div className="makko-surface-raised rounded-3xl p-6 sm:p-8">
      <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">Sign in to Makko</h1>
      <p className="mt-2 text-sm font-normal leading-6 text-slate-600 dark:text-slate-400">Pick up where you left off, with your work kept private.</p>
      <form className="mt-7 space-y-5" onSubmit={(event) => void handleSubmit(event)} noValidate>
        <div>
          <label htmlFor="login-email" className="mb-2 block text-sm font-medium text-slate-800 dark:text-slate-200">Email</label>
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
            className="makko-field w-full px-4 py-3 text-sm placeholder:text-slate-400 dark:placeholder:text-slate-500"
          />
        </div>
        <div>
          <label htmlFor="login-password" className="mb-2 block text-sm font-medium text-slate-800 dark:text-slate-200">Password</label>
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
            className="makko-field w-full px-4 py-3 text-sm placeholder:text-slate-400 dark:placeholder:text-slate-500"
          />
        </div>
        {error && <div id="login-error"><StatusMessage kind="error">{error}</StatusMessage></div>}
        <button
          type="submit"
          disabled={isSubmitting}
          className="makko-control makko-primary makko-focus w-full px-5 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50"
        >
          {isSubmitting ? 'Signing in…' : 'Sign in'}
        </button>
      </form>
      <p className="mt-6 text-center text-sm font-normal text-slate-600 dark:text-slate-400">
        New to Makko?{' '}
        <Link to="/signup" state={{ from: destination }} className="makko-focus inline-flex min-h-11 items-center font-medium text-cyan-700 underline decoration-cyan-500/40 underline-offset-4 hover:text-cyan-800 dark:text-cyan-300 dark:decoration-cyan-300/40 dark:hover:text-cyan-200">
          Create an account
        </Link>
      </p>
    </div>
  )
}
