export interface PublicSupabaseConfig {
  url: string
  publishableKey: string
}

export class ConfigurationError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ConfigurationError'
  }
}

interface PublicEnvironment {
  VITE_SUPABASE_URL?: string
  VITE_SUPABASE_PUBLISHABLE_KEY?: string
}

function isAllowedSupabaseUrl(value: URL): boolean {
  if (value.protocol === 'https:') return true

  return value.protocol === 'http:'
    && ['localhost', '127.0.0.1', '[::1]', '::1'].includes(value.hostname)
}

export function getPublicSupabaseConfig(
  environment: PublicEnvironment = import.meta.env,
): PublicSupabaseConfig {
  const rawUrl = environment.VITE_SUPABASE_URL?.trim()
  if (!rawUrl) {
    throw new ConfigurationError(
      'Supabase is not configured. Add VITE_SUPABASE_URL to web/.env.local.',
    )
  }

  let parsedUrl: URL
  try {
    parsedUrl = new URL(rawUrl)
  } catch {
    throw new ConfigurationError(
      'VITE_SUPABASE_URL must be a valid HTTPS Supabase project URL.',
    )
  }

  if (
    !isAllowedSupabaseUrl(parsedUrl)
    || parsedUrl.username
    || parsedUrl.password
    || parsedUrl.search
    || parsedUrl.hash
    || parsedUrl.pathname !== '/'
  ) {
    throw new ConfigurationError(
      'VITE_SUPABASE_URL must be an HTTPS Supabase project URL without credentials or a path.',
    )
  }

  const publishableKey = environment.VITE_SUPABASE_PUBLISHABLE_KEY?.trim()
  if (!publishableKey) {
    throw new ConfigurationError(
      'Supabase is not configured. Add VITE_SUPABASE_PUBLISHABLE_KEY to web/.env.local.',
    )
  }
  if (/\s/.test(publishableKey)) {
    throw new ConfigurationError(
      'VITE_SUPABASE_PUBLISHABLE_KEY must be a single public key without whitespace.',
    )
  }

  return {
    url: parsedUrl.origin,
    publishableKey,
  }
}
