import { render, screen } from '@testing-library/react'
import { MemoryRouter, useLocation } from 'react-router-dom'
import userEvent from '@testing-library/user-event'
import { describe, expect, it } from 'vitest'

import { AppRoutes } from './routes'
import { AuthProvider } from '../features/auth/auth-context'
import { createFakeAuthService, createSession } from '../test/test-auth'

function LocationProbe() {
  const location = useLocation()
  return <p>current route: {location.pathname}{location.search}{location.hash}</p>
}

function renderRoutes(path: string, authenticated = false) {
  const service = createFakeAuthService(authenticated ? createSession() : null)
  return render(
    <AuthProvider service={service}>
      <MemoryRouter initialEntries={[path]}>
        <LocationProbe />
        <AppRoutes />
      </MemoryRouter>
    </AuthProvider>,
  )
}

describe('application routes', () => {
  it('redirects unauthenticated users to login with their internal destination', async () => {
    const user = userEvent.setup()
    renderRoutes('/app?view=account#details')

    expect(await screen.findByRole('heading', { name: 'Sign in to Makko' })).toBeInTheDocument()
    expect(screen.getByText('current route: /login')).toBeInTheDocument()

    await user.type(screen.getByLabelText('Email'), 'builder@example.com')
    await user.type(screen.getByLabelText('Password'), 'correct horse')
    await user.click(screen.getByRole('button', { name: 'Sign in' }))

    expect(await screen.findByRole('heading', { name: /you’re in/i })).toBeInTheDocument()
    expect(screen.getByText('current route: /app?view=account#details')).toBeInTheDocument()
  })

  it('does not show public auth forms to an authenticated user', async () => {
    renderRoutes('/login', true)

    expect(await screen.findByRole('heading', { name: /you’re in/i })).toBeInTheDocument()
  })

  it('rejects an external redirect target', async () => {
    render(
      <AuthProvider service={createFakeAuthService(createSession())}>
        <MemoryRouter initialEntries={[{ pathname: '/login', state: { from: 'https://evil.example/phish' } }]}>
          <AppRoutes />
        </MemoryRouter>
      </AuthProvider>,
    )

    expect(await screen.findByRole('heading', { name: /you’re in/i })).toBeInTheDocument()
  })
})
