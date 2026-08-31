import { act, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'

import { AuthProvider } from './auth-context'
import { useAuth } from './use-auth'
import { createFakeAuthService, createSession } from '../../test/test-auth'

function AuthProbe() {
  const { state, isSubmitting, retrySession, signOut } = useAuth()
  return (
    <div>
      <p>status: {state.status}</p>
      <p>email: {state.session?.user.email ?? 'none'}</p>
      {state.error && <p role="alert">{state.error}</p>}
      <button type="button" onClick={() => void retrySession()}>Retry session</button>
      <button type="button" disabled={isSubmitting} onClick={() => void signOut()}>Sign out</button>
    </div>
  )
}

describe('AuthProvider', () => {
  it('restores the session and reacts to auth events', async () => {
    const service = createFakeAuthService(createSession())
    const user = userEvent.setup()
    render(<AuthProvider service={service}><AuthProbe /></AuthProvider>)

    expect(await screen.findByText('status: authenticated')).toBeInTheDocument()
    expect(screen.getByText('email: builder@example.com')).toBeInTheDocument()

    act(() => service.emit(null))
    expect(await screen.findByText('status: unauthenticated')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'Sign out' }))
    expect(service.signOut).toHaveBeenCalledOnce()
  })

  it('unsubscribes when the provider unmounts', async () => {
    const service = createFakeAuthService()
    const view = render(<AuthProvider service={service}><AuthProbe /></AuthProvider>)
    await waitFor(() => expect(service.getSession).toHaveBeenCalledOnce())

    view.unmount()
    expect(service.unsubscribe).toHaveBeenCalledOnce()
  })

  it('does not mask subscription setup failures and retries the full auth setup', async () => {
    const service = createFakeAuthService(createSession())
    let subscriptionAttempts = 0
    service.subscribe = vi.fn(() => {
      subscriptionAttempts += 1
      if (subscriptionAttempts === 1) throw new Error('subscription unavailable')
      return service.unsubscribe
    })
    const user = userEvent.setup()
    render(<AuthProvider service={service}><AuthProbe /></AuthProvider>)

    expect(await screen.findByText('status: error')).toBeInTheDocument()
    expect(screen.getByRole('alert')).toHaveTextContent('subscription unavailable')
    expect(service.getSession).not.toHaveBeenCalled()

    await user.click(screen.getByRole('button', { name: 'Retry session' }))
    expect(await screen.findByText('status: authenticated')).toBeInTheDocument()
    expect(service.subscribe).toHaveBeenCalledTimes(2)
    expect(service.getSession).toHaveBeenCalledOnce()
  })
})
