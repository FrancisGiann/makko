import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'

import { App } from './app/app'
import { ConfigurationErrorView } from './components/configuration-error'
import { ConfigurationError, getPublicSupabaseConfig } from './lib/config'
import './index.css'

let configurationError: ConfigurationError | null = null
try {
  getPublicSupabaseConfig()
} catch (error) {
  configurationError = error instanceof ConfigurationError
    ? error
    : new ConfigurationError('Unable to read the public Supabase configuration.')
}

const rootElement = document.getElementById('root')
if (!rootElement) throw new Error('Makko root element is missing.')

createRoot(rootElement).render(
  <StrictMode>
    {configurationError ? (
      <ConfigurationErrorView error={configurationError} />
    ) : (
      <BrowserRouter>
        <App />
      </BrowserRouter>
    )}
  </StrictMode>,
)
