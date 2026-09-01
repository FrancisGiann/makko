import { useState, type FormEvent } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'

import { StatusMessage } from '../../components/status-message'
import { getRedirectFromState } from '../../lib/redirects'
import { useAuth } from './use-auth'

export function SignupPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const destination = getRedirectFromState(location.state)
  const { state, isSubmitting, clearError, signUp } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [validationError, setValidationError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)

  const error = validationError ?? state.error

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (isSubmitting) return

    setValidationError(null)
    setSuccessMessage(null)
    clearError()
    if (!email.trim() || !password || !confirmation) {
      setValidationError('Complete all fields to create your account.')
      return
    }
    if (password.length < 6) {
      setValidationError('Password must be at least 6 characters.')
      return
    }
    if (password !== confirmation) {
      setValidationError('Passwords do not match.')
      return
    }

    const result = await signUp(email.trim(), password)
    if (!result) return
    if (result.session) {
      navigate(destination, { replace: true })
      return
    }
    if (result.requiresEmailConfirmation) {
      setSuccessMessage('Account created. Check your email to confirm your address, then sign in.')
    } else {
      setSuccessMessage('Account created. You can now sign in.')
    }
  }

  return (
    <div className="makko-surface-raised rounded-3xl p-6 sm:p-8">
      <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">Create your Makko account</h1>
      <p className="mt-2 text-sm font-normal leading-6 text-slate-600 dark:text-slate-400">A private home for the projects you’re building.</p>
      <form className="mt-7 space-y-5" onSubmit={(event) => void handleSubmit(event)} noValidate>
        <div>
          <label htmlFor="signup-email" className="mb-2 block text-sm font-medium text-slate-800 dark:text-slate-200">Email</label>
          <input
            id="signup-email"
            name="email"
            type="email"
            autoComplete="email"
            value={email}
            onChange={(event) => { setEmail(event.target.value); setValidationError(null); setSuccessMessage(null); clearError() }}
            required
            aria-required="true"
            aria-invalid={Boolean(error)}
            aria-describedby={error ? 'signup-error' : undefined}
            className="makko-field w-full px-4 py-3 text-sm placeholder:text-slate-400 dark:placeholder:text-slate-500"
          />
        </div>
        <div>
          <label htmlFor="signup-password" className="mb-2 block text-sm font-medium text-slate-800 dark:text-slate-200">Password</label>
          <input
            id="signup-password"
            name="password"
            type="password"
            autoComplete="new-password"
            value={password}
            onChange={(event) => { setPassword(event.target.value); setValidationError(null); setSuccessMessage(null); clearError() }}
            required
            aria-required="true"
            aria-invalid={Boolean(error)}
            aria-describedby={error ? 'signup-error' : undefined}
            className="makko-field w-full px-4 py-3 text-sm placeholder:text-slate-400 dark:placeholder:text-slate-500"
          />
          <p className="mt-2 text-xs font-normal text-slate-500">Use at least 6 characters.</p>
        </div>
        <div>
          <label htmlFor="signup-confirmation" className="mb-2 block text-sm font-medium text-slate-800 dark:text-slate-200">Confirm password</label>
          <input
            id="signup-confirmation"
            name="confirmation"
            type="password"
            autoComplete="new-password"
            value={confirmation}
            onChange={(event) => { setConfirmation(event.target.value); setValidationError(null); setSuccessMessage(null); clearError() }}
            required
            aria-required="true"
            aria-invalid={Boolean(error)}
            aria-describedby={error ? 'signup-error' : undefined}
            className="makko-field w-full px-4 py-3 text-sm placeholder:text-slate-400 dark:placeholder:text-slate-500"
          />
        </div>
        {error && <div id="signup-error"><StatusMessage kind="error">{error}</StatusMessage></div>}
        {successMessage && <StatusMessage kind="success">{successMessage}</StatusMessage>}
        <button
          type="submit"
          disabled={isSubmitting}
          className="makko-control makko-primary makko-focus w-full px-5 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50"
        >
          {isSubmitting ? 'Creating account…' : 'Create account'}
        </button>
      </form>
      <p className="mt-6 text-center text-sm font-normal text-slate-600 dark:text-slate-400">
        Already have an account?{' '}
        <Link to="/login" state={{ from: destination }} className="makko-focus inline-flex min-h-11 items-center font-medium text-cyan-700 underline decoration-cyan-500/40 underline-offset-4 hover:text-cyan-800 dark:text-cyan-300 dark:decoration-cyan-300/40 dark:hover:text-cyan-200">
          Sign in
        </Link>
      </p>
    </div>
  )
}
