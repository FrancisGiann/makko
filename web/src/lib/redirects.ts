export const DEFAULT_AUTHENTICATED_PATH = '/app'

export function getSafeRedirectPath(
  candidate: unknown,
  fallback = DEFAULT_AUTHENTICATED_PATH,
): string {
  if (typeof candidate !== 'string' || !candidate.startsWith('/') || candidate.startsWith('//')) {
    return fallback
  }

  try {
    const parsed = new URL(candidate, window.location.origin)
    if (parsed.origin !== window.location.origin || parsed.pathname.startsWith('//')) {
      return fallback
    }

    return `${parsed.pathname}${parsed.search}${parsed.hash}`
  } catch {
    return fallback
  }
}

export function getRedirectFromState(state: unknown): string {
  if (!state || typeof state !== 'object') return DEFAULT_AUTHENTICATED_PATH
  if (!('from' in state)) return DEFAULT_AUTHENTICATED_PATH
  return getSafeRedirectPath(state.from)
}
