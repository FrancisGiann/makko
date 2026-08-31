import type { Session } from '@supabase/supabase-js'
import { vi } from 'vitest'

import type { AuthService, AuthSessionListener, SignUpResult } from '../types/auth'

export function createSession(email = 'builder@example.com'): Session {
  return {
    access_token: 'access-token',
    refresh_token: 'refresh-token',
    expires_in: 3600,
    expires_at: Math.floor(Date.now() / 1000) + 3600,
    token_type: 'bearer',
    user: {
      id: '00000000-0000-0000-0000-000000000001',
      aud: 'authenticated',
      role: 'authenticated',
      email,
      email_confirmed_at: new Date().toISOString(),
      phone: '',
      confirmed_at: new Date().toISOString(),
      last_sign_in_at: new Date().toISOString(),
      app_metadata: { provider: 'email', providers: ['email'] },
      user_metadata: {},
      identities: [],
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      is_anonymous: false,
    },
  }
}

export interface FakeAuthService extends AuthService {
  emit: (session: Session | null) => void
  unsubscribe: ReturnType<typeof vi.fn>
}

export function createFakeAuthService(
  initialSession: Session | null = null,
): FakeAuthService {
  let listener: AuthSessionListener | null = null
  const unsubscribe = vi.fn(() => { listener = null })
  const service: FakeAuthService = {
    getSession: vi.fn(async () => initialSession),
    subscribe: vi.fn((next: AuthSessionListener) => {
      listener = next
      return unsubscribe
    }),
    signIn: vi.fn(async () => initialSession ?? createSession()),
    signUp: vi.fn(async (): Promise<SignUpResult> => ({
      session: null,
      requiresEmailConfirmation: true,
    })),
    signOut: vi.fn(async () => undefined),
    emit: (session) => listener?.(session, session ? 'SIGNED_IN' : 'SIGNED_OUT'),
    unsubscribe,
  }
  return service
}
