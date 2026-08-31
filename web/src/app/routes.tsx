import { Navigate, Outlet, Route, Routes, useLocation } from 'react-router-dom'

import { LoadingScreen } from '../components/loading-screen'
import { useAuth } from '../features/auth/use-auth'
import { LoginPage } from '../features/auth/login-page'
import { SignupPage } from '../features/auth/signup-page'
import { AppShell } from '../layouts/app-shell'
import { AuthLayout } from '../layouts/auth-layout'
import { PublicLayout } from '../layouts/public-layout'
import { getRedirectFromState } from '../lib/redirects'
import { AccountPage } from '../pages/account-page'
import { HomePage } from '../pages/home-page'
import { NotFoundPage } from '../pages/not-found-page'
import { SessionErrorPage } from '../pages/session-error-page'
import { ProjectsPage } from '../features/projects/projects-page'
import { ProjectDetailPage } from '../features/projects/project-detail-page'

export function ProtectedRoute() {
  const { state } = useAuth()
  const location = useLocation()

  if (state.status === 'loading') return <LoadingScreen />
  if (state.status === 'error') return <SessionErrorPage />
  if (!state.session) {
    const from = `${location.pathname}${location.search}${location.hash}`
    return <Navigate to="/login" replace state={{ from }} />
  }
  return <Outlet />
}

export function PublicOnlyRoute() {
  const { state } = useAuth()
  const location = useLocation()

  if (state.status === 'loading') return <LoadingScreen />
  if (state.status === 'error') return <SessionErrorPage />
  if (state.session) return <Navigate to={getRedirectFromState(location.state)} replace />
  return <Outlet />
}

export function AppRoutes() {
  return (
    <Routes>
      <Route element={<PublicLayout />}>
        <Route index element={<HomePage />} />
        <Route element={<AuthLayout />}>
          <Route element={<PublicOnlyRoute />}>
            <Route path="login" element={<LoginPage />} />
            <Route path="signup" element={<SignupPage />} />
          </Route>
        </Route>
      </Route>
      <Route element={<ProtectedRoute />}>
        <Route element={<AppShell />}>
          <Route path="app" element={<ProjectsPage />} />
          <Route path="app/projects" element={<ProjectsPage />} />
          <Route path="app/projects/:projectId" element={<ProjectDetailPage />} />
          <Route path="app/account" element={<AccountPage />} />
        </Route>
      </Route>
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  )
}

export function AuthenticatedApp() {
  const { state } = useAuth()

  if (state.status === 'loading') return <LoadingScreen />
  if (state.status === 'error') return <SessionErrorPage />
  return <AppRoutes />
}
