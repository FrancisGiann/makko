import { AuthProvider } from '../features/auth/auth-context'
import { AuthenticatedApp } from './routes'

export function App() {
  return (
    <AuthProvider>
      <AuthenticatedApp />
    </AuthProvider>
  )
}
