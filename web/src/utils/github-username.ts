const LEGACY_GITHUB_USERNAME_KEY = 'makko_github_username'

export const GITHUB_USERNAME_PATTERN = /^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$/

export function normalizeGithubUsername(value: string): string | null {
  const username = typeof value === 'string' ? value.trim() : ''
  return username && GITHUB_USERNAME_PATTERN.test(username) ? username : null
}

export function githubUsernameStorageKey(userId: string | null | undefined): string | null {
  if (!userId || !/^[0-9a-f-]{16,}$/i.test(userId)) return null
  return `makko_github_username:${userId}`
}

export function loadGithubUsername(userId: string | null | undefined): string {
  if (typeof window === 'undefined') return ''
  const storageKey = githubUsernameStorageKey(userId)
  try {
    // The old key was shared across accounts; remove it and never fall back to it.
    localStorage.removeItem(LEGACY_GITHUB_USERNAME_KEY)
    if (!storageKey) return ''
    return normalizeGithubUsername(localStorage.getItem(storageKey) ?? '') ?? ''
  } catch {
    return ''
  }
}

export function clearLegacyGithubUsername(): void {
  try {
    localStorage.removeItem(LEGACY_GITHUB_USERNAME_KEY)
  } catch {
    // Ignore storage errors; the username is still validated before use.
  }
}
