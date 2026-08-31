import type {
  AuthChangeEvent,
  AuthError,
  Session,
  User,
} from '@supabase/supabase-js'

export type AuthSessionListener = (
  session: Session | null,
  event: AuthChangeEvent,
) => void

export interface AuthClient {
  auth: {
    getSession: () => Promise<{
      data: { session: Session | null }
      error: AuthError | null
    }>
    signInWithPassword: (credentials: { email: string; password: string }) => Promise<{
      data: { session: Session | null; user: User | null }
      error: AuthError | null
    }>
    signUp: (credentials: { email: string; password: string }) => Promise<{
      data: { session: Session | null; user: User | null }
      error: AuthError | null
    }>
    signOut: () => Promise<{ error: AuthError | null }>
    onAuthStateChange: (
      callback: (event: AuthChangeEvent, session: Session | null) => void,
    ) => { data: { subscription: { unsubscribe: () => void } } }
  }
}

export interface SignUpResult {
  session: Session | null
  requiresEmailConfirmation: boolean
}

export interface AuthService {
  getSession: () => Promise<Session | null>
  subscribe: (listener: AuthSessionListener) => () => void
  signIn: (email: string, password: string) => Promise<Session>
  signUp: (email: string, password: string) => Promise<SignUpResult>
  signOut: () => Promise<void>
}

export interface AuthState {
  status: 'loading' | 'authenticated' | 'unauthenticated' | 'error'
  session: Session | null
  error: string | null
}
