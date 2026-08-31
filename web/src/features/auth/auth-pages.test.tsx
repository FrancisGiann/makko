import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { describe, expect, it, vi } from 'vitest'

import type { AuthService } from '../../types/auth'
import { AuthProvider } from './auth-context'
import { LoginPage } from './login-page'
import { SignupPage } from './signup-page'
import { createFakeAuthService, createSession } from '../../test/test-auth'

function renderAuthPage(page: React.ReactElement, service: AuthService, initialEntries: Parameters<typeof MemoryRouter>[0]['initialEntries'] = ['/login']) {
  return render(
    <AuthProvider service={service}>
      <MemoryRouter initialEntries={initialEntries}>
        <Routes>
          <Route path="/login" element={page} />
          <Route path="/signup" element={<SignupPage />} />
          <Route path="/app/dashboard" element={<p>Workspace dashboard</p>} />
          <Route path="/app" element={<p>Workspace projects</p>} />
        </Routes>
      </MemoryRouter>
    </AuthProvider>,
  )
}

async function fillLogin(user: ReturnType<typeof userEvent.setup>) {
  await user.type(screen.getByLabelText('Email'), '  builder@example.com  ')
  await user.type(screen.getByLabelText('Password'), 'correct horse')
}

async function fillSignup(user: ReturnType<typeof userEvent.setup>) {
  await user.type(screen.getByLabelText('Email'), '  builder@example.com  ')
  await user.type(screen.getByLabelText('Password'), 'correct horse')
  await user.type(screen.getByLabelText('Confirm password'), 'correct horse')
}

describe('authentication pages', () => {
  it('submits normalized login credentials, disables while pending, and navigates safely', async () => {
    const service = createFakeAuthService()
    let resolveSignIn: ((session: ReturnType<typeof createSession>) => void) | undefined
    service.signIn = vi.fn(() => new Promise<ReturnType<typeof createSession>>((resolve) => { resolveSignIn = resolve }))
    const user = userEvent.setup()
    renderAuthPage(<LoginPage />, service, [{ pathname: '/login', state: { from: '/app/dashboard' } }])

    await fillLogin(user)
    const submit = screen.getByRole('button', { name: 'Sign in' })
    await user.click(submit)
    await waitFor(() => expect(submit).toBeDisabled())
    expect(submit).toHaveTextContent('Signing in…')
    expect(service.signIn).toHaveBeenCalledWith('builder@example.com', 'correct horse')

    resolveSignIn?.(createSession())
    expect(await screen.findByText('Workspace dashboard')).toBeInTheDocument()
  })

  it('shows login validation and service errors without navigating', async () => {
    const service = createFakeAuthService()
    const user = userEvent.setup()
    renderAuthPage(<LoginPage />, service)

    await user.click(screen.getByRole('button', { name: 'Sign in' }))
    expect(screen.getByRole('alert')).toHaveTextContent('Enter your email and password to continue.')
    expect(service.signIn).not.toHaveBeenCalled()

    service.signIn = vi.fn(async () => { throw new Error('Invalid login credentials') })
    await fillLogin(user)
    await user.click(screen.getByRole('button', { name: 'Sign in' }))
    expect(await screen.findByRole('alert')).toHaveTextContent('Invalid login credentials')
    expect(screen.getByRole('heading', { name: 'Sign in to Makko' })).toBeInTheDocument()
  })

  it('shows email confirmation after successful account creation', async () => {
    const service = createFakeAuthService()
    service.signUp = vi.fn(async () => ({ session: null, requiresEmailConfirmation: true }))
    const user = userEvent.setup()
    renderAuthPage(<SignupPage />, service, ['/signup'])

    await fillSignup(user)
    await user.click(screen.getByRole('button', { name: 'Create account' }))

    expect(service.signUp).toHaveBeenCalledWith('builder@example.com', 'correct horse')
    expect(await screen.findByRole('status')).toHaveTextContent('Check your email to confirm your address')
  })

  it('keeps signup errors visible and rejects mismatched passwords before the service', async () => {
    const service = createFakeAuthService()
    service.signUp = vi.fn(async () => { throw new Error('Signup unavailable') })
    const user = userEvent.setup()
    renderAuthPage(<SignupPage />, service, ['/signup'])

    await user.type(screen.getByLabelText('Email'), 'builder@example.com')
    await user.type(screen.getByLabelText('Password'), 'correct horse')
    await user.type(screen.getByLabelText('Confirm password'), 'different horse')
    await user.click(screen.getByRole('button', { name: 'Create account' }))
    expect(screen.getByRole('alert')).toHaveTextContent('Passwords do not match.')
    expect(service.signUp).not.toHaveBeenCalled()

    await user.clear(screen.getByLabelText('Confirm password'))
    await user.type(screen.getByLabelText('Confirm password'), 'correct horse')
    await user.click(screen.getByRole('button', { name: 'Create account' }))
    expect(await screen.findByRole('alert')).toHaveTextContent('Signup unavailable')
    expect(screen.queryByRole('status')).not.toBeInTheDocument()
  })
})
