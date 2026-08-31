import { createContext } from 'react'

import type { AuthState, SignUpResult } from '../../types/auth'

export interface AuthContextValue {
  state: AuthState
  isSubmitting: boolean
  clearError: () => void
  retrySession: () => Promise<void>
  signIn: (email: string, password: string) => Promise<boolean>
  signUp: (email: string, password: string) => Promise<SignUpResult | null>
  signOut: () => Promise<boolean>
}

export const AuthContext = createContext<AuthContextValue | undefined>(undefined)
