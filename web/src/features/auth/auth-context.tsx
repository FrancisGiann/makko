import {
  useEffect,
  useState,
  type ReactNode,
} from 'react'

import { getAuthService } from '../../services/auth.service'
import { AuthContext } from './auth-context-value'
import type { AuthService, AuthState, SignUpResult } from '../../types/auth'

interface AuthProviderProps {
  children: ReactNode
  service?: AuthService
}

function getErrorMessage(error: unknown, fallback: string): string {
  if (error instanceof Error && error.message) return error.message
  if (typeof error === 'object' && error !== null && 'message' in error) {
    const message = error.message
    if (typeof message === 'string' && message) return message
  }
  return fallback
}

function sessionState(session: AuthState['session']): AuthState {
  return {
    status: session ? 'authenticated' : 'unauthenticated',
    session,
    error: null,
  }
}

export function AuthProvider({ children, service }: AuthProviderProps) {
  const [authService] = useState<AuthService>(() => service ?? getAuthService())
  const [state, setState] = useState<AuthState>({
    status: 'loading',
    session: null,
    error: null,
  })
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [restoreAttempt, setRestoreAttempt] = useState(0)

  useEffect(() => {
    let mounted = true
    let unsubscribe: () => void = () => undefined
    let subscriptionReady = false

    try {
      unsubscribe = authService.subscribe((session) => {
        if (mounted) setState(sessionState(session))
      })
      subscriptionReady = true
    } catch (error) {
      if (mounted) {
        setState({
          status: 'error',
          session: null,
          error: getErrorMessage(error, 'Unable to listen for authentication changes.'),
        })
      }
    }

    if (!subscriptionReady) {
      return () => {
        mounted = false
        unsubscribe()
      }
    }

    void authService.getSession().then(
      (session) => {
        if (mounted) setState(sessionState(session))
      },
      (error: unknown) => {
        if (mounted) {
          setState({
            status: 'error',
            session: null,
            error: getErrorMessage(error, 'Unable to restore your session.'),
          })
        }
      },
    )

    return () => {
      mounted = false
      unsubscribe()
    }
  }, [authService, restoreAttempt])

  const clearError = () => {
    setState((current) => ({ ...current, error: null }))
  }

  const retrySession = async (): Promise<void> => {
    setState((current) => ({ ...current, status: 'loading', error: null }))
    setRestoreAttempt((attempt) => attempt + 1)
  }

  const signIn = async (email: string, password: string): Promise<boolean> => {
    setIsSubmitting(true)
    clearError()
    try {
      const session = await authService.signIn(email, password)
      setState(sessionState(session))
      return true
    } catch (error) {
      setState((current) => ({
        ...current,
        error: getErrorMessage(error, 'Unable to sign in.'),
      }))
      return false
    } finally {
      setIsSubmitting(false)
    }
  }

  const signUp = async (email: string, password: string): Promise<SignUpResult | null> => {
    setIsSubmitting(true)
    clearError()
    try {
      const result = await authService.signUp(email, password)
      setState(sessionState(result.session))
      return result
    } catch (error) {
      setState((current) => ({
        ...current,
        error: getErrorMessage(error, 'Unable to create your account.'),
      }))
      return null
    } finally {
      setIsSubmitting(false)
    }
  }

  const signOut = async (): Promise<boolean> => {
    setIsSubmitting(true)
    clearError()
    try {
      await authService.signOut()
      setState(sessionState(null))
      return true
    } catch (error) {
      setState((current) => ({
        ...current,
        error: getErrorMessage(error, 'Unable to sign out.'),
      }))
      return false
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <AuthContext.Provider
      value={{ state, isSubmitting, clearError, retrySession, signIn, signUp, signOut }}
    >
      {children}
    </AuthContext.Provider>
  )
}
