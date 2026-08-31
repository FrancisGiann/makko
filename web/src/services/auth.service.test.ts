import { AuthError } from '@supabase/supabase-js'
import { describe, expect, it, vi } from 'vitest'

import { createAuthService } from './auth.service'
import { createSession } from '../test/test-auth'
import type { AuthClient } from '../types/auth'

function createClient(overrides: Partial<AuthClient['auth']> = {}): AuthClient {
  const subscription = { unsubscribe: vi.fn() }
  return {
    auth: {
      getSession: vi.fn(async () => ({ data: { session: null }, error: null })),
      signInWithPassword: vi.fn(async () => ({ data: { session: null, user: null }, error: null })),
      signUp: vi.fn(async () => ({ data: { session: null, user: null }, error: null })),
      signOut: vi.fn(async () => ({ error: null })),
      onAuthStateChange: vi.fn(() => ({ data: { subscription } })),
      ...overrides,
    },
  }
}

const session = createSession()

describe('auth service', () => {
  it('passes normalized credentials to Supabase and returns the session', async () => {
    const signInWithPassword = vi.fn(async () => ({ data: { session, user: null }, error: null }))
    const client = createClient({ signInWithPassword })
    const service = createAuthService(client)

    await expect(service.signIn('  builder@example.com ', 'correct horse')).resolves.toBe(session)
    expect(signInWithPassword).toHaveBeenCalledWith({ email: 'builder@example.com', password: 'correct horse' })
  })

  it('propagates a safe Error when Supabase rejects a request', async () => {
    const error = new AuthError('Invalid login credentials')
    const client = createClient({ signInWithPassword: vi.fn(async () => ({ data: { session: null, user: null }, error })) })
    const service = createAuthService(client)

    await expect(service.signIn('builder@example.com', 'wrong-password')).rejects.toThrow('Invalid login credentials')
  })

  it('reports when sign-up needs email confirmation', async () => {
    const client = createClient({
      signUp: vi.fn(async () => ({ data: { session: null, user: session.user }, error: null })),
    })
    const service = createAuthService(client)

    await expect(service.signUp('builder@example.com', 'correct horse')).resolves.toMatchObject({
      session: null,
      requiresEmailConfirmation: true,
    })
  })

  it('cleans up the auth state subscription', () => {
    const unsubscribe = vi.fn()
    const client = createClient({
      onAuthStateChange: vi.fn(() => ({ data: { subscription: { unsubscribe } } })),
    })
    const service = createAuthService(client)
    const listener = vi.fn()

    const cleanup = service.subscribe(listener)
    cleanup()

    expect(unsubscribe).toHaveBeenCalledOnce()
  })
})
