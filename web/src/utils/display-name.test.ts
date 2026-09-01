import { describe, expect, it } from 'vitest'

import { getDisplayName } from './display-name'

describe('getDisplayName', () => {
  it('prefers a trimmed first name from user metadata', () => {
    expect(getDisplayName({ email: 'private@example.com', user_metadata: { first_name: '  Ana  ' } })).toBe('Ana')
    expect(getDisplayName({ user_metadata: { first_name: 'ana@example.com' } })).toBe('ana')
  })

  it('uses only the email local-part when no first name is present', () => {
    expect(getDisplayName({ email: 'indie.builder@example.com', user_metadata: {} })).toBe('Indie.builder')
    expect(getDisplayName({ email: 'indie.builder@example.com' })).not.toContain('@')
  })

  it('falls back safely when identity data is unavailable', () => {
    expect(getDisplayName(null)).toBe('Builder')
    expect(getDisplayName({ email: '@example.com', user_metadata: { first_name: '   ' } })).toBe('Builder')
  })
})
