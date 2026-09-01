export interface DisplayNameUser {
  email?: string | null
  user_metadata?: Record<string, unknown> | null
}

function cleanName(value: string): string {
  return value.replace(/@.*$/, '').replace(/\s+/g, ' ').trim().slice(0, 80)
}

export function getDisplayName(user: DisplayNameUser | null | undefined): string {
  const metadataName = user?.user_metadata?.first_name
  if (typeof metadataName === 'string') {
    const name = cleanName(metadataName)
    if (name) return name
  }

  const localPart = typeof user?.email === 'string' ? user.email.split('@', 1)[0] : ''
  const localName = cleanName(localPart)
  if (localName) return localName.charAt(0).toUpperCase() + localName.slice(1)
  return 'Builder'
}
