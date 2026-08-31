import type { AuthError, Session } from '@supabase/supabase-js'

import { getSupabaseClient } from '../lib/supabase'
import type {
  AuthClient,
  AuthService,
  AuthSessionListener,
  SignUpResult,
} from '../types/auth'

function toError(error: AuthError | null, fallbackMessage: string): Error {
  if (error?.message) return new Error(error.message)
  return new Error(fallbackMessage)
}

function validateCredentials(email: string, password: string): string {
  const normalizedEmail = email.trim()
  if (!normalizedEmail) throw new Error('Email is required.')
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
    throw new Error('Enter a valid email address.')
  }
  if (!password) throw new Error('Password is required.')
  if (password.length < 6) throw new Error('Password must be at least 6 characters.')
  return normalizedEmail
}

export function createAuthService(client: AuthClient): AuthService {
  return {
    async getSession(): Promise<Session | null> {
      const { data, error } = await client.auth.getSession()
      if (error) throw toError(error, 'Unable to restore your session.')
      return data.session
    },

    subscribe(listener: AuthSessionListener): () => void {
      const { data } = client.auth.onAuthStateChange((event, session) => {
        listener(session, event)
      })
      return () => data.subscription.unsubscribe()
    },

    async signIn(email: string, password: string): Promise<Session> {
      const normalizedEmail = validateCredentials(email, password)
      const { data, error } = await client.auth.signInWithPassword({
        email: normalizedEmail,
        password,
      })
      if (error) throw toError(error, 'Unable to sign in.')
      if (!data.session) throw new Error('Sign in did not return a session.')
      return data.session
    },

    async signUp(email: string, password: string): Promise<SignUpResult> {
      const normalizedEmail = validateCredentials(email, password)
      const { data, error } = await client.auth.signUp({
        email: normalizedEmail,
        password,
      })
      if (error) throw toError(error, 'Unable to create your account.')

      return {
        session: data.session,
        requiresEmailConfirmation: data.user !== null && data.session === null,
      }
    },

    async signOut(): Promise<void> {
      const { error } = await client.auth.signOut()
      if (error) throw toError(error, 'Unable to sign out.')
    },
  }
}

export function getAuthService(): AuthService {
  return createAuthService(getSupabaseClient())
}
